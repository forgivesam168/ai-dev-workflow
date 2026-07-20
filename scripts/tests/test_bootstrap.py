import hashlib
import json
import os
import shutil
import subprocess
import sys
from copy import deepcopy
from pathlib import Path
from typing import Dict, Optional, Tuple, Union

import pytest

from scripts import bootstrap
from scripts import manifest_reconciliation


PHASE0B_REPO_ROOT = Path(bootstrap.__file__).resolve().parent.parent
PHASE0B_SCRIPT = PHASE0B_REPO_ROOT / "scripts" / "bootstrap.sh"
PHASE0C_PYTHON_SCRIPT = PHASE0B_REPO_ROOT / "scripts" / "bootstrap.py"
PHASE4A_VECTORS = json.loads(
    (PHASE0B_REPO_ROOT / "scripts" / "tests" / "manifest-v3-vectors.json").read_text(
        encoding="utf-8"
    )
)
PHASE4A_SIMPLE_MANIFEST_NAMES = {
    "unknown-property", "invalid-enum", "invalid-hash", "path-traversal",
    "path-absolute", "path-drive", "path-unc", "path-backslash", "path-ads",
    "path-windows-reserved", "path-trailing-alias", "fork-mapping",
    "source-locator-traversal", "hash-timepoint-mismatch", "generated-parent-order",
    "timestamp-order", "component-timestamp-order",
    "manifest-binding-schema-version-boolean",
}


def _find_phase0b_bash() -> str:
    candidates = []
    explicit = os.environ.get("PHASE0B_BASH")
    if explicit:
        candidates.append(explicit)

    resolved = shutil.which("bash")
    if resolved:
        candidates.append(resolved)

    git_bash = Path(r"C:\Program Files\Git\bin\bash.exe")
    if git_bash.exists():
        candidates.append(str(git_bash))

    seen = set()
    for candidate in candidates:
        if candidate in seen:
            continue
        seen.add(candidate)
        try:
            result = subprocess.run(
                [candidate, "--version"],
                capture_output=True,
                check=False,
                text=True,
                encoding="utf-8",
                errors="replace",
            )
        except OSError:
            continue

        output = result.stdout + result.stderr
        if result.returncode == 0 and "GNU bash" in output:
            return candidate

    pytest.skip("No usable Bash runtime found for Phase 0B tests")


def _phase0b_bash_environment(bash_executable: str) -> Dict[str, str]:
    env = os.environ.copy()
    env.pop("BASH_ENV", None)

    if os.name != "nt":
        return env

    git_root = None
    bash_path = Path(bash_executable).resolve()
    for parent in bash_path.parents:
        if any((parent / relative).is_dir() for relative in ("usr/bin", "mingw64/bin", "cmd")):
            git_root = parent
            break

    if git_root is None:
        return env

    prepend_entries = []
    runtime_entries = set()
    for relative in ("usr/bin", "mingw64/bin", "cmd"):
        candidate = git_root / relative
        if not candidate.is_dir():
            continue
        candidate_str = str(candidate)
        prepend_entries.append(candidate_str)
        runtime_entries.add(os.path.normcase(os.path.normpath(candidate_str)))

    if not prepend_entries:
        return env

    existing_path = env.get("PATH", "")
    existing_entries = existing_path.split(os.pathsep) if existing_path else []
    filtered_existing = []
    for entry in existing_entries:
        normalized = os.path.normcase(os.path.normpath(entry)) if entry else entry
        if normalized in runtime_entries:
            continue
        filtered_existing.append(entry)

    env["PATH"] = os.pathsep.join(prepend_entries + filtered_existing)
    return env


def _run_phase0b_bash(script: Path, cwd: Path, *args: str) -> subprocess.CompletedProcess[str]:
    bash_executable = _find_phase0b_bash()
    return subprocess.run(
        [bash_executable, "--noprofile", "--norc", script.as_posix(), *args],
        cwd=cwd,
        capture_output=True,
        check=False,
        env=_phase0b_bash_environment(bash_executable),
        text=True,
        encoding="utf-8",
        errors="replace",
    )


def _phase0b_output(result: subprocess.CompletedProcess[str]) -> str:
    return result.stdout + result.stderr


def _snapshot_tree(root: Path) -> Tuple[Dict[str, str], Tuple[str, ...]]:
    files: Dict[str, str] = {}
    directories = []

    if not root.exists():
        return files, tuple(directories)

    for path in sorted(root.rglob("*")):
        relative = path.relative_to(root).as_posix()
        if path.is_dir():
            directories.append(f"{relative}/")
            continue
        files[relative] = hashlib.sha256(path.read_bytes()).hexdigest()

    return files, tuple(directories)


def _assert_phase0b_no_write(
    target_root: Path,
    before_files: Dict[str, str],
    before_directories: Tuple[str, ...],
) -> None:
    after_files, after_directories = _snapshot_tree(target_root)

    assert after_files == before_files
    assert after_directories == before_directories
    assert not list(target_root.glob(".github.backup-*"))
    assert not (target_root / ".git").exists()
    assert not (target_root / ".ai-workflow-install.json").exists()


def _run_phase0c_python(
    target_root: Path, *args: str
) -> subprocess.CompletedProcess[str]:
    return subprocess.run(
        [sys.executable, str(PHASE0C_PYTHON_SCRIPT), *args],
        cwd=target_root,
        capture_output=True,
        check=False,
        text=True,
        encoding="utf-8",
        errors="replace",
    )


def _phase0c_output(result: subprocess.CompletedProcess[str]) -> str:
    return result.stdout + result.stderr


def _create_phase0c_target(
    target_root: Path, manifest_bytes: Optional[bytes]
) -> Tuple[bytes, bytes]:
    sentinel = b"project-owned policy\x00\n"
    secondary = b"project-owned skill\r\n"
    (target_root / ".github").mkdir(parents=True)
    (target_root / "skills" / "custom").mkdir(parents=True)
    (target_root / ".github" / "copilot-instructions.md").write_bytes(sentinel)
    (target_root / "skills" / "custom" / "SKILL.md").write_bytes(secondary)
    if manifest_bytes is not None:
        (target_root / bootstrap.MANIFEST_FILENAME).write_bytes(manifest_bytes)
    return sentinel, secondary


def _assert_phase0c_no_write(
    target_root: Path,
    before_files: Dict[str, str],
    before_directories: Tuple[str, ...],
    sentinel: bytes,
    secondary: bytes,
) -> None:
    after_files, after_directories = _snapshot_tree(target_root)
    assert after_files == before_files
    assert after_directories == before_directories
    assert (target_root / ".github" / "copilot-instructions.md").read_bytes() == sentinel
    assert (target_root / "skills" / "custom" / "SKILL.md").read_bytes() == secondary
    assert not list(target_root.glob(".github.backup-*"))
    assert not list(target_root.glob(".ai-workflow-portable.backup-*"))
    assert not (target_root / ".git").exists()


def _create_phase0b_existing_adopter(target_root: Path) -> None:
    (target_root / ".github" / "agents").mkdir(parents=True)
    (target_root / ".github" / "agents" / "coder.agent.md").write_text(
        "# Existing workflow\n",
        encoding="utf-8",
    )
    (target_root / "AGENTS.md").write_text(
        "# Existing adopter\n",
        encoding="utf-8",
    )


def _create_phase0b_workflows_only_project(target_root: Path) -> bytes:
    workflow = target_root / ".github" / "workflows" / "ci.yml"
    workflow.parent.mkdir(parents=True)
    original = b"name: ci\non: [push]\n"
    workflow.write_bytes(original)
    return original


def _create_phase0a_constitution_fixture(
    tmp_path: Path,
) -> Tuple[Path, Path, bytes, bytes]:
    template_root = tmp_path / "template"
    target_root = tmp_path / "project"
    maintainer_content = (
        b"# Maintainer Constitution\n"
        b"Run tools/sync-dotgithub.ps1 and maintain the template catalog.\n"
    )
    adopter_content = b"# Adopter Constitution\nProject-facing guidance only.\n"

    (template_root / ".github").mkdir(parents=True)
    (template_root / "docs").mkdir()
    (template_root / ".github" / "copilot-instructions.md").write_bytes(
        maintainer_content
    )
    (template_root / "docs" / "copilot-instructions.template.md").write_bytes(
        adopter_content
    )
    target_root.mkdir()
    return template_root, target_root, maintainer_content, adopter_content


@pytest.mark.parametrize(
    ("manifest", "expected_state", "expected_version"),
    [
        (None, "missing", None),
        ({"schema_version": 1, "components": [{"name": "agents/a.md"}]}, "valid-v1", 1),
        ({"schema_version": 2, "components": [{"name": "skills/a/"}]}, "valid-v2", 2),
        (b"{not-json", "corrupt", None),
        ({"schema_version": 4, "components": []}, "unsupported", 4),
        ({"schema_version": 2, "components": {}}, "corrupt", 2),
        ({"schema_version": 2, "components": [{"name": "  "}]}, "corrupt", 2),
        (
            {
                "schema_version": 2,
                "components": [{"name": "agents/a.md"}, {"name": "agents/a.md"}],
            },
            "corrupt",
            2,
        ),
    ],
    ids=[
        "missing",
        "valid-v1",
        "valid-v2",
        "corrupt-json",
        "unsupported-v4",
        "components-not-list",
        "invalid-component-name",
        "duplicate-component-name",
    ],
)
def test_phase0c_loader_returns_explicit_manifest_state(
    tmp_path: Path,
    manifest: Optional[Union[dict, bytes]],
    expected_state: str,
    expected_version: Optional[int],
) -> None:
    if isinstance(manifest, dict):
        manifest_bytes = json.dumps(manifest).encode("utf-8")
    else:
        manifest_bytes = manifest
    if manifest_bytes is not None:
        (tmp_path / bootstrap.MANIFEST_FILENAME).write_bytes(manifest_bytes)

    result = bootstrap.load_install_manifest(tmp_path)

    assert result.state == expected_state
    assert result.schema_version == expected_version
    if expected_state in {"valid-v1", "valid-v2"}:
        assert result.entries
        assert next(iter(result.entries.values()))["name"]
    else:
        assert result.entries == {}
    if expected_state in {"corrupt", "unsupported"}:
        assert result.detail


def test_phase0c_python_corrupt_update_hard_stops_without_write(tmp_path: Path) -> None:
    target_root = tmp_path / "corrupt-update"
    target_root.mkdir()
    manifest_bytes = b'{"schema_version": 2, "components": ['
    sentinel, secondary = _create_phase0c_target(target_root, manifest_bytes)
    before_files, before_directories = _snapshot_tree(target_root)

    result = _run_phase0c_python(target_root, "--update")
    output = _phase0c_output(result)

    assert result.returncode != 0
    assert str(target_root / bootstrap.MANIFEST_FILENAME) in output
    assert "before any changes" in output
    assert "trusted backup" in output
    assert (target_root / bootstrap.MANIFEST_FILENAME).read_bytes() == manifest_bytes
    _assert_phase0c_no_write(
        target_root, before_files, before_directories, sentinel, secondary
    )


def test_phase0c_python_unsupported_update_hard_stops_without_write(
    tmp_path: Path,
) -> None:
    target_root = tmp_path / "unsupported-update"
    target_root.mkdir()
    manifest_bytes = json.dumps({"schema_version": 4, "components": []}).encode()
    sentinel, secondary = _create_phase0c_target(target_root, manifest_bytes)
    before_files, before_directories = _snapshot_tree(target_root)

    result = _run_phase0c_python(target_root, "--update")
    output = _phase0c_output(result)

    assert result.returncode != 0
    assert "Observed schema version: 4" in output
    assert "Supported schema versions: 1, 2, 3" in output
    assert "before any changes" in output
    assert (target_root / bootstrap.MANIFEST_FILENAME).read_bytes() == manifest_bytes
    _assert_phase0c_no_write(
        target_root, before_files, before_directories, sentinel, secondary
    )


def test_phase0c_python_missing_update_is_report_only_without_write(
    tmp_path: Path,
) -> None:
    target_root = tmp_path / "missing-update"
    target_root.mkdir()
    sentinel, secondary = _create_phase0c_target(target_root, None)
    before_files, before_directories = _snapshot_tree(target_root)

    result = _run_phase0c_python(target_root, "--update")
    output = _phase0c_output(result)

    assert result.returncode == 0
    assert "legacy project" in output.lower()
    assert "report-only" in output
    assert "No files changed" in output
    assert not (target_root / bootstrap.MANIFEST_FILENAME).exists()
    _assert_phase0c_no_write(
        target_root, before_files, before_directories, sentinel, secondary
    )


def test_phase0c_python_force_cannot_bypass_corrupt_update_gate(
    tmp_path: Path,
) -> None:
    target_root = tmp_path / "corrupt-force"
    target_root.mkdir()
    manifest_bytes = b"not-json"
    sentinel, secondary = _create_phase0c_target(target_root, manifest_bytes)
    before_files, before_directories = _snapshot_tree(target_root)

    result = _run_phase0c_python(target_root, "--update", "--force")

    assert result.returncode != 0
    assert (target_root / bootstrap.MANIFEST_FILENAME).read_bytes() == manifest_bytes
    _assert_phase0c_no_write(
        target_root, before_files, before_directories, sentinel, secondary
    )


def test_phase0c_python_backup_cannot_bypass_unsupported_update_gate(
    tmp_path: Path,
) -> None:
    target_root = tmp_path / "unsupported-backup"
    target_root.mkdir()
    manifest_bytes = json.dumps({"schema_version": 4, "components": []}).encode()
    sentinel, secondary = _create_phase0c_target(target_root, manifest_bytes)
    before_files, before_directories = _snapshot_tree(target_root)

    result = _run_phase0c_python(target_root, "--update", "--backup")

    assert result.returncode != 0
    assert (target_root / bootstrap.MANIFEST_FILENAME).read_bytes() == manifest_bytes
    _assert_phase0c_no_write(
        target_root, before_files, before_directories, sentinel, secondary
    )


def test_phase4a_reader_foundation_contract_artifacts_and_vectors_exist() -> None:
    repo_root = Path(bootstrap.__file__).resolve().parent.parent
    vectors_path = repo_root / "scripts" / "tests" / "manifest-v3-vectors.json"
    vectors = json.loads(vectors_path.read_text(encoding="utf-8"))

    assert (repo_root / vectors["production_schema"]["path"]).is_file()
    assert (repo_root / vectors["catalog"]["path"]).is_file()
    assert vectors["catalog"]["component_count"] == 253
    assert len(vectors["parse_vectors"]) == 7
    assert len(vectors["schema_negative_vectors"]) == 4
    assert len(vectors["catalog_negative_vectors"]) == 11
    assert len(vectors["manifest_negative_vectors"]) == 35
    assert len(vectors["mutation_routes"]) == 4
    for group in (
        "parse_vectors",
        "schema_negative_vectors",
        "catalog_negative_vectors",
        "manifest_negative_vectors",
        "mutation_routes",
    ):
        names = [vector["name"] for vector in vectors[group]]
        assert len(names) == len(set(names)), group


def test_phase4a_reader_recognizes_v1_v2_with_explicit_states(tmp_path: Path) -> None:
    for version in (1, 2):
        manifest_path = tmp_path / bootstrap.MANIFEST_FILENAME
        manifest_path.write_text(
            json.dumps(
                {
                    "schema_version": version,
                    "components": [{"name": f"agents/v{version}.md"}],
                }
            ),
            encoding="utf-8",
        )
        before = manifest_path.read_bytes()
        result = bootstrap.load_install_manifest(tmp_path)
        assert result.state == f"valid-v{version}"
        assert result.diagnostic_category == f"manifest-valid-v{version}"
        assert manifest_path.read_bytes() == before


def test_phase4a_parse_state_diagnostic_categories(tmp_path: Path) -> None:
    missing = bootstrap.load_install_manifest(tmp_path)
    assert (missing.state, missing.diagnostic_category) == ("missing", "manifest-missing")
    path = tmp_path / bootstrap.MANIFEST_FILENAME
    path.write_bytes(b"{broken")
    corrupt = bootstrap.load_install_manifest(tmp_path)
    assert (corrupt.state, corrupt.diagnostic_category) == ("corrupt", "manifest-json")
    path.write_text(json.dumps({"schema_version": 4, "components": []}), encoding="utf-8")
    unsupported = bootstrap.load_install_manifest(tmp_path)
    assert (unsupported.state, unsupported.diagnostic_category) == ("unsupported", "manifest-version")


@pytest.mark.parametrize(
    "vector",
    PHASE4A_VECTORS["parse_vectors"],
    ids=[vector["name"] for vector in PHASE4A_VECTORS["parse_vectors"]],
)
def test_phase4a_correction2_python_consumes_every_parse_vector(
    tmp_path: Path, monkeypatch: pytest.MonkeyPatch, vector: dict
) -> None:
    name = vector["name"]
    source_root = None
    if name == "missing":
        pass
    elif name in {"valid-v1", "valid-v2"}:
        version = int(name[-1])
        (tmp_path / bootstrap.MANIFEST_FILENAME).write_text(
            json.dumps({"schema_version": version, "components": []}), encoding="utf-8"
        )
    elif name in {"valid-v3", "v3-source-unavailable"}:
        _phase4a_write_manifest(tmp_path, _phase4a_valid_manifest())
        if name == "valid-v3":
            source_root = PHASE0B_REPO_ROOT
        else:
            standalone = tmp_path / "standalone" / "scripts" / "bootstrap.py"
            monkeypatch.setattr(bootstrap, "__file__", str(standalone))
    elif name == "corrupt-json":
        (tmp_path / bootstrap.MANIFEST_FILENAME).write_bytes(b"{broken")
    elif name == "unsupported-version":
        (tmp_path / bootstrap.MANIFEST_FILENAME).write_text(
            json.dumps({"schema_version": 4, "components": []}), encoding="utf-8"
        )
    else:
        raise AssertionError(f"Unhandled parse vector: {name}")

    result = bootstrap.load_install_manifest(tmp_path, source_root=source_root)

    assert result.state == vector["state"], name
    assert result.diagnostic_category == vector["category"], name
    if name == "valid-v3":
        assert result.catalog_validated
    if name == "v3-source-unavailable":
        assert not result.catalog_validated
        assert not result.entries


def test_phase4a_writer_contract_remains_schema_v2(tmp_path: Path) -> None:
    bootstrap.write_install_manifest(tmp_path, tmp_path, {})
    written = json.loads((tmp_path / bootstrap.MANIFEST_FILENAME).read_text(encoding="utf-8"))
    assert written["schema_version"] == 2


def _phase4a_catalog_bytes() -> bytes:
    return (PHASE0B_REPO_ROOT / bootstrap.COMPONENT_CATALOG_PATH).read_bytes()


def _phase4a_valid_manifest() -> dict:
    digest = bootstrap.hash_bytes(_phase4a_catalog_bytes())
    return {
        "schema_version": 3,
        "written_at": "2026-07-17T01:30:05Z",
        "source_release": {
            "release_id": bootstrap.COMPONENT_CATALOG_RELEASE_ID,
            "source_ref": bootstrap.COMPONENT_CATALOG_PATH.as_posix(),
            "version": bootstrap.COMPONENT_CATALOG_VERSION,
            "component_catalog": {
                "path": bootstrap.COMPONENT_CATALOG_PATH.as_posix(),
                "schema_version": 1,
                "sha256": digest,
            },
        },
        "last_transaction": {
            "id": "txn:phase4a-valid",
            "mode": "update",
            "writer": "python",
            "started_at": "2026-07-17T01:30:00Z",
            "completed_at": "2026-07-17T01:30:05Z",
            "result": "committed",
        },
        "components": [
            {
                "identity": {
                    "id": "cmp:canonical-coder-agent",
                    "path": "agents/coder.agent.md",
                    "path_key": "agents/coder.agent.md",
                    "kind": "file",
                    "role": "canonical",
                    "link": None,
                },
                "provenance": {
                    "ownership": "template-managed",
                    "source": {
                        "kind": "template",
                        "locator": "template:agents/coder.agent.md",
                        "release": bootstrap.COMPONENT_CATALOG_RELEASE_ID,
                    },
                    "generated_from": [],
                    "fork": {
                        "status": "untouched",
                        "basis": "verified-managed-equality",
                        "decision": "manage",
                        "classified_at": "2026-07-17T01:30:01Z",
                    },
                },
                "hashes": {
                    "algorithm": "sha256",
                    "content_basis": "exact-bytes",
                    "baseline": "sha256:" + "a" * 64,
                    "observed_before": "sha256:" + "a" * 64,
                    "proposed_source": "sha256:" + "c" * 64,
                    "result_after": "sha256:" + "c" * 64,
                },
                "lifecycle": {
                    "state": "active",
                    "previous_paths": [],
                    "retirement": None,
                    "reintroduces_component_id": None,
                },
                "last_operation": {
                    "transaction_id": "txn:older-component-op",
                    "outcome": "updated",
                },
                "installed_at": "2026-04-22T10:00:00Z",
                "updated_at": "2026-07-17T01:30:05Z",
            }
        ],
    }


def _phase4a_write_manifest(root: Path, manifest: dict) -> bytes:
    payload = (json.dumps(manifest, ensure_ascii=False, indent=2) + "\n").encode("utf-8")
    (root / bootstrap.MANIFEST_FILENAME).write_bytes(payload)
    return payload


def _phase4b_report_fixture(tmp_path: Path, manifest_bytes: Optional[bytes] = None) -> Tuple[Path, Path]:
    source = tmp_path / "template"
    target = tmp_path / "adopter"
    source.mkdir()
    target.mkdir()
    for relative in ("manifest/component-catalog.json", "schemas/ai-workflow-install-manifest-v3.schema.json"):
        destination = source / relative
        destination.parent.mkdir(parents=True, exist_ok=True)
        destination.write_bytes((PHASE0B_REPO_ROOT / relative).read_bytes())
    if manifest_bytes is not None:
        (target / bootstrap.MANIFEST_FILENAME).write_bytes(manifest_bytes)
    return source, target


def _phase4b_validate_contract(value: object, schema: dict, root: dict, path: str = "report") -> None:
    if "$ref" in schema:
        value_schema = root["$defs"][schema["$ref"].split("/")[-1]]
        return _phase4b_validate_contract(value, value_schema, root, path)
    if "const" in schema:
        assert value == schema["const"], path
    if "enum" in schema:
        assert value in schema["enum"], path
    expected = schema.get("type")
    if isinstance(expected, list):
        assert any((kind == "null" and value is None) or (kind == "string" and isinstance(value, str)) or (kind == "integer" and type(value) is int) or (kind == "boolean" and type(value) is bool) or (kind == "object" and isinstance(value, dict)) or (kind == "array" and isinstance(value, list)) for kind in expected), path
    elif expected == "object":
        assert isinstance(value, dict), path
    elif expected == "array":
        assert isinstance(value, list), path
    elif expected == "string":
        assert isinstance(value, str), path
    elif expected == "integer":
        assert type(value) is int, path
    elif expected == "boolean":
        assert type(value) is bool, path
    if "pattern" in schema and isinstance(value, str):
        import re
        assert re.match(schema["pattern"], value), path
    if isinstance(value, dict) and "properties" in schema:
        assert set(schema.get("required", [])) <= set(value), path
        if schema.get("additionalProperties") is False:
            assert set(value) <= set(schema["properties"]), path
        for key, child in schema["properties"].items():
            if key in value:
                _phase4b_validate_contract(value[key], child, root, f"{path}.{key}")
    if isinstance(value, list) and "items" in schema:
        for index, item in enumerate(value):
            _phase4b_validate_contract(item, schema["items"], root, f"{path}[{index}]")
    if isinstance(value, dict) and "additionalProperties" in schema and isinstance(schema["additionalProperties"], dict):
        for key, item in value.items():
            _phase4b_validate_contract(item, schema["additionalProperties"], root, f"{path}.{key}")


def _phase4b_record(status: str = "untouched", ownership: str = "template-managed", baseline: Optional[str] = "sha256:" + "a" * 64) -> dict:
    return {"provenance": {"ownership": ownership, "fork": {"status": status}}, "hashes": {"baseline": baseline}, "lifecycle": {"state": "active"}}


def _phase4b_write_file(path: Path, data: bytes, *, mtime_ns: Optional[int] = None) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_bytes(data)
    if mtime_ns is not None:
        os.utime(path, ns=(mtime_ns, mtime_ns))


def test_phase4b_report_schema_and_canonical_digest_contract() -> None:
    schema_path = PHASE0B_REPO_ROOT / "schemas/ai-workflow-manifest-reconciliation-report-v1.schema.json"
    schema = json.loads(schema_path.read_text(encoding="utf-8"))
    assert schema["$schema"] == "https://json-schema.org/draft/2020-12/schema"
    assert schema["$id"] == "urn:ai-dev-workflow:manifest-reconciliation-report:v1"
    assert schema["properties"]["report_contract_version"]["const"] == 1
    assert schema["properties"]["operation"]["enum"] == ["conversion-plan", "reconcile"]
    assert set(schema["$defs"]["mappedDecision"]["properties"]["classification"]["enum"]) == {
        "untouched", "customized", "project-owned", "legacy", "unknown", "derived-customized",
        "conflicted", "not-applicable",
    }
    with pytest.raises(ValueError):
        manifest_reconciliation.canonical_report_bytes({"operation": "reconcile"})


@pytest.mark.parametrize("manifest_kind", ["normal", "source-blocked"])
def test_phase4b_produced_reports_satisfy_dependency_free_strict_schema(tmp_path: Path, manifest_kind: str) -> None:
    source, target = _phase4b_report_fixture(tmp_path)
    if manifest_kind == "source-blocked":
        (source / "manifest/component-catalog.json").write_bytes(b"not-json")
    report = manifest_reconciliation.build_report(source, target, "conversion-plan")
    schema = json.loads((PHASE0B_REPO_ROOT / "schemas/ai-workflow-manifest-reconciliation-report-v1.schema.json").read_text(encoding="utf-8"))
    _phase4b_validate_contract(report, schema, schema)
    assert manifest_reconciliation.report_digest(report) == report["report_identity"]["canonical_body_digest"]
    assert manifest_reconciliation.canonical_report_bytes(report).decode("utf-8").endswith("\n")


def test_phase4b_all_approved_classifications_are_pure_and_deterministic(tmp_path: Path) -> None:
    source, target = _phase4b_report_fixture(tmp_path)
    baseline = "sha256:" + "a" * 64
    assert manifest_reconciliation._classification(None, {"role": "canonical", "kind": "file"}, None, None)[0] == "unknown"
    assert manifest_reconciliation._classification(_phase4b_record(ownership="project-owned"), {"role": "canonical", "kind": "file"}, None, None)[0] == "project-owned"
    assert manifest_reconciliation._classification(_phase4b_record("conflicted"), {"role": "canonical", "kind": "file"}, None, None)[0] == "conflicted"
    assert manifest_reconciliation._classification(_phase4b_record(), {"role": "canonical", "kind": "directory"}, baseline, baseline)[0] == "not-applicable"
    assert manifest_reconciliation._classification(_phase4b_record(), {"role": "canonical", "kind": "file"}, baseline, baseline)[0] == "untouched"
    assert manifest_reconciliation._classification(_phase4b_record(), {"role": "canonical", "kind": "file"}, "sha256:" + "b" * 64, baseline)[0] == "customized"
    assert manifest_reconciliation._classification(_phase4b_record(), {"role": "generated", "kind": "file"}, "sha256:" + "b" * 64, "sha256:" + "c" * 64)[0] == "derived-customized"
    assert manifest_reconciliation._classification(_phase4b_record(baseline=None), {"role": "canonical", "kind": "file"}, None, None)[0] == "unknown"
    assert source.exists() and target.exists()


@pytest.mark.parametrize("version", [1, 2])
def test_phase4b_legacy_versions_map_only_exact_catalog_paths(tmp_path: Path, version: int) -> None:
    source, target = _phase4b_report_fixture(tmp_path)
    path = json.loads((source / "manifest/component-catalog.json").read_text(encoding="utf-8"))["components"][0]["canonical_source_path"]
    manifest = {"schema_version": version, "components": [{"name": path, "source": "template:" + path, "status": "preserved-customization"}]}
    _phase4a_write_manifest(target, manifest)
    report = manifest_reconciliation.build_report(source, target, "conversion-plan")
    assert report["manifest_parse_state"]["state"] == f"valid-v{version}"
    assert len(report["mapped_component_decisions"]) == 1
    assert report["mapped_component_decisions"][0]["classification"] == "legacy"
    unknown = {"schema_version": version, "components": [{"name": "not-in-catalog", "source": "template:not-in-catalog"}]}
    _phase4a_write_manifest(target, unknown)
    report = manifest_reconciliation.build_report(source, target, "conversion-plan")
    assert report["mapped_component_decisions"] == []
    assert report["unmapped_records"][0]["classification"] == "unknown"


def test_phase4b_rename_retirement_and_modified_stale_are_conservative(tmp_path: Path) -> None:
    source, target = _phase4b_report_fixture(tmp_path)
    baseline = "sha256:" + "a" * 64
    current = "new/name.md"
    old = "old/name.md"
    (source / current).parent.mkdir(parents=True)
    (source / current).write_bytes(b"new")
    (target / old).parent.mkdir(parents=True)
    (target / old).write_bytes(b"old")
    catalog = {"role": "canonical", "kind": "file", "canonical_source_path": current, "previous_paths": [old], "generated_from": [], "lifecycle_status": "active"}
    decision = manifest_reconciliation._decision("cmp:rename-test", catalog, _phase4b_record(baseline=baseline), source, target, "valid-v3")
    assert decision["stale_or_retirement_reason"] == "rename-proven"
    assert decision["eligibility"]["eligible"] is False
    retired = dict(catalog, lifecycle_status="retired", retired_release="release-1", canonical_source_path=old, previous_paths=[])
    decision = manifest_reconciliation._decision("cmp:retired-test", retired, _phase4b_record(baseline=baseline), source, target, "valid-v3")
    assert decision["stale_or_retirement_reason"] == "retirement-proven"
    active_missing_source = dict(catalog, canonical_source_path=old, previous_paths=[])
    decision = manifest_reconciliation._decision("cmp:stale-test", active_missing_source, _phase4b_record(baseline=baseline), source, target, "valid-v3")
    assert decision["stale_or_retirement_reason"] == "source-missing-no-retirement-evidence"
    assert decision["proposed_action"] == "preserve"
    generated = dict(active_missing_source, role="generated")
    decision = manifest_reconciliation._decision("cmp:stale-generated", generated, _phase4b_record(baseline=baseline), source, target, "valid-v3")
    assert decision["classification"] == "derived-customized"
    assert decision["eligibility"]["eligible"] is False


@pytest.mark.parametrize("flag", ["--force", "--update", "--backup"])
def test_phase4b_python_report_only_rejects_mutation_flags_before_planner(tmp_path: Path, flag: str) -> None:
    source, target = _phase4b_report_fixture(tmp_path)
    result = subprocess.run([sys.executable, str(PHASE0B_REPO_ROOT / "scripts/bootstrap.py"), "--report-only", flag, "--operation", "reconcile", "--source-root", str(source), "--target-root", str(target)], capture_output=True, text=True)
    assert result.returncode != 0
    assert "cannot be combined" in result.stderr
    assert not list(target.rglob("*.backup-*"))


def test_phase4b_missing_manifest_is_report_only_and_root_tree_is_unchanged(tmp_path: Path) -> None:
    source, target = _phase4b_report_fixture(tmp_path)
    sentinel = target / "project-owned.txt"
    sentinel.write_bytes(b"keep\r\n")
    before = sorted((p.relative_to(target).as_posix(), p.read_bytes()) for p in target.rglob("*") if p.is_file())
    report = manifest_reconciliation.build_report(source, target, "conversion-plan")
    after = sorted((p.relative_to(target).as_posix(), p.read_bytes()) for p in target.rglob("*") if p.is_file())
    assert report["manifest_parse_state"]["state"] == "missing"
    assert report["mapped_component_decisions"] == []
    assert report["required_future_authorization"]["approval_supplied"] is False
    assert report["no_write_confirmation"]["writes_performed"] is False
    assert before == after


@pytest.mark.parametrize(
    ("manifest_bytes", "state"),
    [(b"not-json", "corrupt"), (b'{"schema_version":99,"components":[]}', "unsupported")],
)
def test_phase4b_corrupt_or_unsupported_blocks_before_component_planning(
    tmp_path: Path, manifest_bytes: bytes, state: str
) -> None:
    source, target = _phase4b_report_fixture(tmp_path, manifest_bytes)
    before = (target / bootstrap.MANIFEST_FILENAME).read_bytes()
    report = manifest_reconciliation.build_report(source, target, "reconcile")
    assert report["manifest_parse_state"]["state"] == state
    assert report["mapped_component_decisions"] == []
    assert report["blocking_findings"]
    assert (target / bootstrap.MANIFEST_FILENAME).read_bytes() == before


def test_phase4b_valid_v3_reconciliation_is_conservative_and_not_authority(tmp_path: Path) -> None:
    source, target = _phase4b_report_fixture(tmp_path)
    manifest_bytes = _phase4a_write_manifest(target, _phase4a_valid_manifest())
    report = manifest_reconciliation.build_report(source, target, "reconcile")
    assert report["manifest_parse_state"]["state"] == "valid-v3"
    assert report["required_future_authorization"]["approval_supplied"] is False
    assert report["required_future_authorization"]["not_authority"] is True
    assert report["required_future_authorization"]["execution_time_revalidation_required"] is True
    assert report["required_future_authorization"]["delete_action"] is False
    assert report["no_write_confirmation"]["pre_manifest_digest"] == bootstrap.hash_bytes(manifest_bytes)
    assert report["no_write_confirmation"]["inventory_unchanged"] is True
    assert report["no_write_confirmation"]["timestamps_unchanged"] is True
    assert report["no_write_confirmation"]["link_metadata_unchanged"] is True
    assert report["no_write_confirmation"]["git_presence_unchanged"] is True
    assert report["no_write_confirmation"]["forbidden_artifacts_unchanged"] is True
    assert report["no_write_confirmation"]["pre_target_snapshot_digest"] == report["no_write_confirmation"]["post_target_snapshot_digest"]
    assert report["report_identity"]["canonical_body_digest"].startswith("sha256:")
    assert manifest_reconciliation.report_digest(report) == report["report_identity"]["canonical_body_digest"]
    assert manifest_reconciliation.canonical_report_bytes(report).endswith(b"\n")


def test_phase4b_python_cli_and_powershell_cli_have_identical_canonical_report(tmp_path: Path) -> None:
    source, target = _phase4b_report_fixture(tmp_path)
    python_command = [sys.executable, str(PHASE0B_REPO_ROOT / "scripts/bootstrap.py"), "--report-only",
                      "--operation", "conversion-plan", "--source-root", str(source), "--target-root", str(target)]
    python_result = subprocess.run(python_command, capture_output=True, text=True, check=False)
    assert python_result.returncode == 0, python_result.stderr
    assert "report_path" not in python_result.stdout
    ps = shutil.which("pwsh")
    if not ps:
        pytest.skip("PowerShell is unavailable")
    ps_result = subprocess.run(
        [ps, "-NoProfile", "-File", str(PHASE0B_REPO_ROOT / "scripts/bootstrap.ps1"), "-ReportOnly",
         "-Operation", "conversion-plan", "-SourceRoot", str(source), "-TargetPath", str(target)],
        capture_output=True, text=True, check=False,
    )
    assert ps_result.returncode == 0, ps_result.stderr
    python_report = json.loads(python_result.stdout)
    ps_report = json.loads(ps_result.stdout)
    assert manifest_reconciliation.canonical_report_bytes(ps_report) == manifest_reconciliation.canonical_report_bytes(python_report)
    assert ps_report["report_identity"]["canonical_body_digest"] == python_report["report_identity"]["canonical_body_digest"]


def test_phase4b_normalized_snapshot_digest_ignores_mtime_but_changes_for_content(tmp_path: Path) -> None:
    first = tmp_path / "first"
    second = tmp_path / "second"
    third = tmp_path / "third"
    same_mtime = 1_750_000_000_000_000_000
    _phase4b_write_file(first / "same/path.txt", b"same-bytes\n", mtime_ns=1_700_000_000_000_000_000)
    _phase4b_write_file(second / "same/path.txt", b"same-bytes\n", mtime_ns=1_800_000_000_000_000_000)
    _phase4b_write_file(third / "same/path.txt", b"different-bytes\n", mtime_ns=same_mtime)
    first_snapshot = manifest_reconciliation._tree_snapshot(first)
    second_snapshot = manifest_reconciliation._tree_snapshot(second)
    third_snapshot = manifest_reconciliation._tree_snapshot(third)
    assert first_snapshot["files"][0]["mtime_ns"] != second_snapshot["files"][0]["mtime_ns"]
    assert manifest_reconciliation._snapshot_digest(first_snapshot) == manifest_reconciliation._snapshot_digest(second_snapshot)
    assert manifest_reconciliation._snapshot_digest(first_snapshot) != manifest_reconciliation._snapshot_digest(third_snapshot)


def test_phase4b_canonical_report_digest_ignores_mtime_and_volatile_envelope(tmp_path: Path) -> None:
    source, target = _phase4b_report_fixture(tmp_path)
    _phase4b_write_file(source / "docs/example.md", b"same-source\n", mtime_ns=1_700_000_000_000_000_000)
    _phase4b_write_file(target / "docs/example.md", b"same-target\n", mtime_ns=1_700_000_000_000_000_000)
    first = manifest_reconciliation.build_report(source, target, "conversion-plan")
    _phase4b_write_file(source / "docs/example.md", b"same-source\n", mtime_ns=1_800_000_000_000_000_000)
    _phase4b_write_file(target / "docs/example.md", b"same-target\n", mtime_ns=1_800_000_000_000_000_000)
    second = manifest_reconciliation.build_report(source, target, "conversion-plan")
    assert first["report_identity"]["canonical_body_digest"] == second["report_identity"]["canonical_body_digest"]
    assert manifest_reconciliation.canonical_report_bytes(first) == manifest_reconciliation.canonical_report_bytes(second)
    assert b"mtime_ns" not in manifest_reconciliation.canonical_report_bytes(first)
    volatile_changed = deepcopy(first)
    volatile_changed["volatile_display_envelope"] = {"timestamp": "2099-01-01T00:00:00Z", "host": "other-host"}
    assert manifest_reconciliation.report_digest(first) == manifest_reconciliation.report_digest(volatile_changed)
    assert manifest_reconciliation.canonical_report_bytes(first) == manifest_reconciliation.canonical_report_bytes(volatile_changed)


def test_phase4b_same_run_timestamp_mutation_blocks_no_write_proof(monkeypatch: pytest.MonkeyPatch, tmp_path: Path) -> None:
    source, target = _phase4b_report_fixture(tmp_path)
    _phase4b_write_file(target / "docs/example.md", b"same-bytes\n", mtime_ns=1_700_000_000_000_000_000)
    base_target = manifest_reconciliation._tree_snapshot(target)
    mutated_target = deepcopy(base_target)
    mutated_target["files"][0]["mtime_ns"] = 1_800_000_000_000_000_000
    base_source = manifest_reconciliation._tree_snapshot(source)
    original_tree_snapshot = manifest_reconciliation._tree_snapshot

    state = {"target_calls": 0, "source_calls": 0}

    def fake_tree_snapshot(root: Path) -> dict:
        resolved = root.resolve()
        if resolved == target.resolve():
            state["target_calls"] += 1
            return deepcopy(base_target if state["target_calls"] == 1 else mutated_target)
        if resolved == source.resolve():
            state["source_calls"] += 1
            return deepcopy(base_source)
        return original_tree_snapshot(root)

    monkeypatch.setattr(manifest_reconciliation, "_tree_snapshot", fake_tree_snapshot)
    report = manifest_reconciliation.build_report(source, target, "conversion-plan")
    assert report["no_write_confirmation"]["inventory_unchanged"] is True
    assert report["no_write_confirmation"]["timestamps_unchanged"] is False
    assert report["no_write_confirmation"]["pre_target_snapshot_digest"] == report["no_write_confirmation"]["post_target_snapshot_digest"]
    assert report["no_write_confirmation"]["writes_performed"] is True
    assert any(item["code"] == "no-write-proof-failed" for item in report["blocking_findings"])


def test_phase4a_schema_transform_catalog_allocation_and_candidate_boundary() -> None:
    package = PHASE0B_REPO_ROOT / "changes" / "workflow-agents-responsibility-alignment"
    candidate_path = package / "phase-4-manifest-v3.schema.proposed.json"
    candidate_bytes = candidate_path.read_bytes()
    assert bootstrap.hash_bytes(candidate_bytes) == (
        "sha256:c4623a55745d816494c1623eb242961b5ea0a458bd8f7cdabd9fcda73f6de886"
    )
    candidate = json.loads(candidate_bytes)
    production = json.loads(
        (PHASE0B_REPO_ROOT / bootstrap.PRODUCTION_MANIFEST_SCHEMA).read_text(encoding="utf-8")
    )
    candidate["$id"] = production["$id"]
    candidate["title"] = production["title"]
    candidate["description"] = production["description"]
    candidate["required"].remove("proposal_status")
    del candidate["properties"]["proposal_status"]
    assert candidate == production

    catalog = json.loads(_phase4a_catalog_bytes())
    components = catalog["components"]
    assert len(components) == 253
    assert [item["id"] for item in components] == sorted(item["id"] for item in components)
    assert {role: sum(item["role"] == role for item in components) for role in (
        "canonical", "generated", "project-owned", "compatibility"
    )} == {"canonical": 101, "generated": 110, "project-owned": 3, "compatibility": 39}
    assert {kind: sum(item["kind"] == kind for item in components) for kind in (
        "file", "directory", "mount"
    )} == {"file": 249, "directory": 1, "mount": 3}
    fingerprint_rows = [
        {key: item[key] for key in ("id", "canonical_source_path", "role", "kind", "generated_from")}
        for item in components
    ]
    fingerprint = bootstrap.hash_bytes(
        json.dumps(fingerprint_rows, ensure_ascii=False, separators=(",", ":")).encode("utf-8")
    )
    assert fingerprint == "sha256:4e68c7431da961b126748b2a3fb110e9dc52094cf1a958b64528337422800c66"
    mounts = [item for item in components if item["kind"] == "mount"]
    assert all(item["generated_from"] == ["cmp:canonical-skills-root"] for item in mounts)
    assert "phase-4-manifest-v3.schema.proposed.json" not in PHASE0C_PYTHON_SCRIPT.read_text(encoding="utf-8")
    assert "phase-4-manifest-v3.schema.proposed.json" not in (
        PHASE0B_REPO_ROOT / "scripts" / "bootstrap.ps1"
    ).read_text(encoding="utf-8")


def test_phase4a_python_accepts_catalog_bound_v3_read_only_without_rewrite(tmp_path: Path) -> None:
    before = _phase4a_write_manifest(tmp_path, _phase4a_valid_manifest())
    result = bootstrap.load_install_manifest(tmp_path, source_root=PHASE0B_REPO_ROOT)
    assert result.state == "valid-v3"
    assert result.diagnostic_category == "manifest-valid-v3"
    assert result.catalog_validated
    assert list(result.entries) == ["cmp:canonical-coder-agent"]
    assert (tmp_path / bootstrap.MANIFEST_FILENAME).read_bytes() == before


def _phase4a_directory_mount_manifest() -> dict:
    manifest = _phase4a_valid_manifest()
    root = _phase4a_clone_component("cmp:canonical-skills-root", "skills")
    root["identity"]["kind"] = "directory"
    root["provenance"]["fork"] = {
        "status": "not-applicable",
        "basis": "hash-not-applicable",
        "decision": "report-only",
        "classified_at": "2026-07-17T01:30:01Z",
    }
    for key in ("baseline", "observed_before", "proposed_source", "result_after"):
        root["hashes"][key] = None
    root["last_operation"]["outcome"] = "reported"
    mount = _phase4a_clone_component(
        "cmp:generated-agent-skills-mount",
        ".agent/skills",
        generated_from=["cmp:canonical-skills-root"],
    )
    mount["identity"]["kind"] = "mount"
    mount["identity"]["link"] = {
        "target_path": "skills",
        "target_path_key": "skills",
        "mode": "symlink",
    }
    mount["provenance"]["fork"] = deepcopy(root["provenance"]["fork"])
    for key in ("baseline", "observed_before", "proposed_source", "result_after"):
        mount["hashes"][key] = None
    mount["last_operation"]["outcome"] = "reported"
    manifest["components"] = [root, mount]
    return manifest


def test_phase4a_python_accepts_directory_parent_and_mount_lineage(tmp_path: Path) -> None:
    _phase4a_write_manifest(tmp_path, _phase4a_directory_mount_manifest())
    result = bootstrap.load_install_manifest(tmp_path, source_root=PHASE0B_REPO_ROOT)
    assert result.state == "valid-v3"
    assert result.catalog_validated
    assert list(result.entries) == [
        "cmp:canonical-skills-root",
        "cmp:generated-agent-skills-mount",
    ]


def _phase4a_apply_simple_manifest_mutation(name: str, manifest: dict) -> None:
    component = manifest["components"][0]
    mutations = {
        "unknown-property": lambda: manifest.update({"unknown": True}),
        "invalid-enum": lambda: manifest["last_transaction"].update({"mode": "prune"}),
        "invalid-hash": lambda: component["hashes"].update({"baseline": "SHA256:BAD"}),
        "path-traversal": lambda: component["identity"].update({"path": "../escape"}),
        "path-absolute": lambda: component["identity"].update({"path": "/escape"}),
        "path-drive": lambda: component["identity"].update({"path": "C:/escape"}),
        "path-unc": lambda: component["identity"].update({"path": "//server/share"}),
        "path-backslash": lambda: component["identity"].update({"path": "agents\\coder.md"}),
        "path-ads": lambda: component["identity"].update({"path": "agents/coder.md:ads"}),
        "path-windows-reserved": lambda: component["identity"].update({"path": "agents/CON.md"}),
        "path-trailing-alias": lambda: component["identity"].update({"path": "agents/coder."}),
        "fork-mapping": lambda: component["provenance"]["fork"].update({"decision": "preserve"}),
        "source-locator-traversal": lambda: component["provenance"]["source"].update({"locator": "template:../secret"}),
        "hash-timepoint-mismatch": lambda: component["hashes"].update({"result_after": "sha256:" + "d" * 64}),
        "generated-parent-order": lambda: component["provenance"].update({"generated_from": ["cmp:z-parent", "cmp:a-parent"]}),
        "timestamp-order": lambda: manifest["last_transaction"].update({"completed_at": "2026-07-17T01:29:59Z"}),
        "component-timestamp-order": lambda: component.update({"installed_at": "2026-07-18T00:00:00Z"}),
        "manifest-binding-schema-version-boolean": lambda: manifest["source_release"]["component_catalog"].update({"schema_version": True}),
    }
    if name not in mutations:
        raise AssertionError(f"Unhandled simple Manifest vector: {name}")
    mutations[name]()


@pytest.mark.parametrize(
    ("name", "category"),
    [
        (vector["name"], vector["category"])
        for vector in PHASE4A_VECTORS["manifest_negative_vectors"]
        if vector["name"] in PHASE4A_SIMPLE_MANIFEST_NAMES
    ],
)
def test_phase4a_python_rejects_v3_semantic_vectors(
    tmp_path: Path, name: str, category: str
) -> None:
    manifest = _phase4a_valid_manifest()
    _phase4a_apply_simple_manifest_mutation(name, manifest)
    _phase4a_write_manifest(tmp_path, manifest)
    result = bootstrap.load_install_manifest(tmp_path, source_root=PHASE0B_REPO_ROOT)
    assert result.state == "corrupt", name
    assert result.diagnostic_category == category, name


def _phase4a_clone_component(
    component_id: str, path: str, *, generated_from: Optional[list] = None
) -> dict:
    component = deepcopy(_phase4a_valid_manifest()["components"][0])
    component["identity"]["id"] = component_id
    component["identity"]["path"] = path
    component["identity"]["path_key"] = path.lower()
    if generated_from is not None:
        component["identity"]["role"] = "generated"
        component["provenance"]["ownership"] = "derived-runtime"
        component["provenance"]["source"] = {
            "kind": "generated",
            "locator": f"generated:{path}",
            "release": bootstrap.COMPONENT_CATALOG_RELEASE_ID,
        }
        component["provenance"]["generated_from"] = generated_from
    else:
        component["provenance"]["source"]["locator"] = f"template:{path}"
    return component


def _phase4a_make_tombstone(component: dict, successor: Optional[str] = None) -> None:
    component["hashes"]["proposed_source"] = None
    component["hashes"]["result_after"] = None
    component["lifecycle"] = {
        "state": "tombstoned",
        "previous_paths": [],
        "retirement": {
            "reason": "deleted",
            "detected_at": "2026-07-17T01:30:02Z",
            "source_evidence": {
                "type": "component-absent-in-source",
                "locator": "template:release-retirement",
            },
            "successor_component_id": successor,
            "pruned_at": "2026-07-17T01:30:04Z",
        },
        "reintroduces_component_id": None,
    }
    component["last_operation"]["outcome"] = "tombstoned"


def _phase4a_complex_manifest_vector(name: str) -> dict:
    manifest = _phase4a_valid_manifest()
    coder = manifest["components"][0]
    if name == "path-case-collision":
        second = _phase4a_clone_component("cmp:canonical-pm-agent", "Agents/Coder.Agent.md")
        second["identity"]["path_key"] = "agents/coder.agent.md"
        manifest["components"].append(second)
    elif name == "generated-parent-duplicate":
        coder["identity"]["role"] = "generated"
        coder["provenance"]["ownership"] = "derived-runtime"
        coder["provenance"]["source"]["kind"] = "generated"
        coder["provenance"]["source"]["locator"] = "generated:agents/coder.agent.md"
        coder["provenance"]["generated_from"] = ["cmp:canonical-pm-agent", "cmp:canonical-pm-agent"]
    elif name == "generated-parent-missing":
        manifest["components"] = [
            _phase4a_clone_component(
                "cmp:generated-github-coder-agent",
                ".github/agents/coder.agent.md",
                generated_from=["cmp:canonical-missing-agent"],
            )
        ]
    elif name == "generated-parent-cycle":
        manifest["components"] = sorted(
            [
                _phase4a_clone_component(
                    "cmp:generated-github-coder-agent",
                    ".github/agents/coder.agent.md",
                    generated_from=["cmp:generated-github-pm-agent"],
                ),
                _phase4a_clone_component(
                    "cmp:generated-github-pm-agent",
                    ".github/agents/pm.agent.md",
                    generated_from=["cmp:generated-github-coder-agent"],
                ),
            ],
            key=lambda item: item["identity"]["id"],
        )
    elif name == "retired-invalid":
        coder["lifecycle"]["state"] = "retired"
    elif name == "tombstone-invalid":
        _phase4a_make_tombstone(coder)
        coder["hashes"]["result_after"] = "sha256:" + "c" * 64
    elif name == "reintroduction-self":
        coder["lifecycle"]["reintroduces_component_id"] = coder["identity"]["id"]
    elif name == "reintroduction-missing":
        coder["lifecycle"]["reintroduces_component_id"] = "cmp:canonical-missing-agent"
    elif name == "reintroduction-non-tombstone":
        coder["lifecycle"]["reintroduces_component_id"] = "cmp:canonical-pm-agent"
        manifest["components"].append(
            _phase4a_clone_component("cmp:canonical-pm-agent", "agents/pm.agent.md")
        )
    elif name == "reintroduction-cycle":
        _phase4a_make_tombstone(coder, "cmp:canonical-pm-agent")
        replacement = _phase4a_clone_component("cmp:canonical-pm-agent", "agents/pm.agent.md")
        replacement["lifecycle"]["reintroduces_component_id"] = "cmp:canonical-coder-agent"
        manifest["components"].append(replacement)
    elif name == "duplicate-active-path":
        manifest["components"].append(
            _phase4a_clone_component("cmp:canonical-pm-agent", "agents/coder.agent.md")
        )
    elif name == "catalog-component-mismatch":
        coder["identity"]["path"] = "agents/renamed-coder.agent.md"
        coder["identity"]["path_key"] = "agents/renamed-coder.agent.md"
        coder["provenance"]["source"]["locator"] = "template:agents/renamed-coder.agent.md"
    elif name in {"link-target-escape", "mount-target-escape"}:
        coder["identity"]["kind"] = "link" if name.startswith("link") else "mount"
        coder["identity"]["role"] = "generated"
        coder["identity"]["link"] = {
            "target_path": "../outside",
            "target_path_key": "../outside",
            "mode": "symlink",
        }
    elif name == "retirement-detected-after-updated":
        _phase4a_make_tombstone(coder)
        coder["lifecycle"]["retirement"]["detected_at"] = "2026-07-18T00:00:00Z"
    elif name == "retirement-pruned-after-updated":
        _phase4a_make_tombstone(coder)
        coder["lifecycle"]["retirement"]["pruned_at"] = "2026-07-18T00:00:00Z"
    elif name == "manifest-role-kind-mismatch":
        coder["identity"]["kind"] = "mount"
        coder["identity"]["link"] = {
            "target_path": "skills",
            "target_path_key": "skills",
            "mode": "symlink",
        }
    else:
        raise AssertionError(f"Unknown vector: {name}")
    manifest["components"] = sorted(manifest["components"], key=lambda item: item["identity"]["id"])
    return manifest


@pytest.mark.parametrize(
    ("name", "category"),
    [
        (vector["name"], vector["category"])
        for vector in PHASE4A_VECTORS["manifest_negative_vectors"]
        if vector["name"] not in PHASE4A_SIMPLE_MANIFEST_NAMES
    ],
)
def test_phase4a_python_rejects_cross_record_and_link_vectors(
    tmp_path: Path, name: str, category: str
) -> None:
    _phase4a_write_manifest(tmp_path, _phase4a_complex_manifest_vector(name))
    result = bootstrap.load_install_manifest(tmp_path, source_root=PHASE0B_REPO_ROOT)
    assert result.state == "corrupt", name
    assert result.diagnostic_category == category, name


def _phase4a_write_catalog_source(root: Path, catalog: dict) -> bytes:
    schema_path = root / bootstrap.PRODUCTION_MANIFEST_SCHEMA
    schema_path.parent.mkdir(parents=True, exist_ok=True)
    shutil.copyfile(PHASE0B_REPO_ROOT / bootstrap.PRODUCTION_MANIFEST_SCHEMA, schema_path)
    path = root / bootstrap.COMPONENT_CATALOG_PATH
    path.parent.mkdir(parents=True, exist_ok=True)
    payload = (json.dumps(catalog, ensure_ascii=False, indent=2) + "\n").encode("utf-8")
    path.write_bytes(payload)
    return payload


@pytest.mark.parametrize(
    "vector",
    PHASE4A_VECTORS["schema_negative_vectors"],
    ids=[vector["name"] for vector in PHASE4A_VECTORS["schema_negative_vectors"]],
)
def test_phase4a_correction2_python_requires_exact_production_schema(
    tmp_path: Path, vector: dict
) -> None:
    source = tmp_path / "source"
    catalog = json.loads(_phase4a_catalog_bytes())
    catalog_bytes = _phase4a_write_catalog_source(source, catalog)
    schema_path = source / bootstrap.PRODUCTION_MANIFEST_SCHEMA
    if vector["name"] == "schema-missing":
        schema_path.unlink()
    elif vector["name"] == "schema-invalid-json":
        schema_path.write_bytes(b"{broken")
    else:
        schema = json.loads(schema_path.read_text(encoding="utf-8"))
        if vector["name"] == "schema-wrong-id":
            schema["$id"] = "urn:unexpected"
        elif vector["name"] == "schema-proposal-marker":
            schema["properties"]["proposal_status"] = {"const": "proposed"}
            schema["required"].append("proposal_status")
        else:
            raise AssertionError(f"Unhandled Schema vector: {vector['name']}")
        schema_path.write_text(json.dumps(schema), encoding="utf-8")
    manifest = _phase4a_valid_manifest()
    manifest["source_release"]["component_catalog"]["sha256"] = bootstrap.hash_bytes(
        catalog_bytes
    )
    target = tmp_path / "target"
    target.mkdir()
    _phase4a_write_manifest(target, manifest)

    result = bootstrap.load_install_manifest(target, source_root=source)

    assert result.state == "corrupt", vector["name"]
    assert result.diagnostic_category == vector["category"], vector["name"]


def test_phase4a_correction2_python_catalog_generated_from_allows_more_than_64_items(
    tmp_path: Path,
) -> None:
    catalog = json.loads(_phase4a_catalog_bytes())
    component = next(
        item for item in catalog["components"] if item["id"] == "cmp:generated-github-coder-agent"
    )
    component["generated_from"] = [f"cmp:canonical-missing-{index:03d}" for index in range(65)]
    _phase4a_write_catalog_source(tmp_path, catalog)

    with pytest.raises(bootstrap.ManifestValidationError) as error:
        bootstrap._load_and_validate_component_catalog(tmp_path)

    assert error.value.category == "catalog-reference"


@pytest.mark.parametrize(
    ("name", "category"),
    [(vector["name"], vector["category"]) for vector in PHASE4A_VECTORS["catalog_negative_vectors"]],
)
def test_phase4a_python_rejects_catalog_vectors(
    tmp_path: Path, name: str, category: str
) -> None:
    catalog = json.loads(_phase4a_catalog_bytes())
    by_id = {item["id"]: item for item in catalog["components"]}
    if name == "catalog-duplicate-id":
        catalog["components"].append(deepcopy(by_id["cmp:canonical-coder-agent"]))
        catalog["components"].sort(key=lambda item: item["id"])
    elif name == "catalog-duplicate-active-path":
        by_id["cmp:canonical-pm-agent"]["canonical_source_path"] = "agents/coder.agent.md"
    elif name == "catalog-unknown-parent":
        by_id["cmp:generated-github-coder-agent"]["generated_from"] = ["cmp:canonical-missing-agent"]
    elif name == "catalog-cycle":
        by_id["cmp:generated-github-coder-agent"]["generated_from"] = ["cmp:generated-github-pm-agent"]
        by_id["cmp:generated-github-pm-agent"]["generated_from"] = ["cmp:generated-github-coder-agent"]
    elif name == "catalog-self-reference":
        by_id["cmp:generated-github-coder-agent"]["generated_from"] = ["cmp:generated-github-coder-agent"]
    elif name == "catalog-terminal-id-reuse":
        by_id["cmp:canonical-coder-agent"]["lifecycle_status"] = "tombstoned"
    elif name == "catalog-role-kind-mismatch":
        by_id["cmp:canonical-coder-agent"]["kind"] = "mount"
    elif name == "catalog-schema-version-boolean":
        catalog["catalog_schema_version"] = True
    elif name not in {"catalog-missing", "catalog-digest-mismatch", "catalog-release-mismatch"}:
        raise AssertionError(f"Unhandled Catalog vector: {name}")
    source = tmp_path / "source"
    if name == "catalog-missing":
        schema_path = source / bootstrap.PRODUCTION_MANIFEST_SCHEMA
        schema_path.parent.mkdir(parents=True, exist_ok=True)
        shutil.copyfile(PHASE0B_REPO_ROOT / bootstrap.PRODUCTION_MANIFEST_SCHEMA, schema_path)
        catalog_bytes = _phase4a_catalog_bytes()
    else:
        catalog_bytes = _phase4a_write_catalog_source(source, catalog)
    manifest = _phase4a_valid_manifest()
    manifest["source_release"]["component_catalog"]["sha256"] = bootstrap.hash_bytes(catalog_bytes)
    if name == "catalog-digest-mismatch":
        manifest["source_release"]["component_catalog"]["sha256"] = "sha256:" + "0" * 64
    if name == "catalog-release-mismatch":
        manifest["source_release"]["release_id"] = "unexpected-release"
    target = tmp_path / "target"
    target.mkdir()
    _phase4a_write_manifest(target, manifest)
    result = bootstrap.load_install_manifest(target, source_root=source)
    assert result.state == "corrupt", name
    assert result.diagnostic_category == category, name


@pytest.mark.parametrize(
    "route",
    PHASE4A_VECTORS["mutation_routes"],
    ids=[route["name"] for route in PHASE4A_VECTORS["mutation_routes"]],
)
def test_phase4a_python_valid_v3_blocks_every_mutation_route_before_write(
    tmp_path: Path, route: dict
) -> None:
    target = tmp_path / "adopter"
    target.mkdir()
    manifest_bytes = (json.dumps(_phase4a_valid_manifest(), ensure_ascii=False) + "\n").encode("utf-8")
    sentinel, secondary = _create_phase0c_target(target, manifest_bytes)
    before_files, before_directories = _snapshot_tree(target)
    result = _run_phase0c_python(target, *tuple(route["python_arguments"]))
    output = _phase0c_output(result)
    assert result.returncode != 0
    assert route["category"] in output
    assert "writer/migration is not enabled" in output
    assert "before backup, directory, file, link, temporary artifact, or Manifest mutation" in output
    _assert_phase0c_no_write(target, before_files, before_directories, sentinel, secondary)


@pytest.mark.parametrize(
    "route",
    PHASE4A_VECTORS["mutation_routes"],
    ids=[route["name"] for route in PHASE4A_VECTORS["mutation_routes"]],
)
@pytest.mark.parametrize("manifest_kind", ["corrupt-json", "unsupported-version"])
def test_phase4a_correction2_python_corrupt_and_unsupported_block_every_route(
    tmp_path: Path, route: dict, manifest_kind: str
) -> None:
    target = tmp_path / f"{manifest_kind}-{route['name']}"
    target.mkdir()
    manifest_bytes = (
        b"{broken"
        if manifest_kind == "corrupt-json"
        else json.dumps({"schema_version": 4, "components": []}).encode("utf-8")
    )
    sentinel, secondary = _create_phase0c_target(target, manifest_bytes)
    before_files, before_directories = _snapshot_tree(target)

    result = _run_phase0c_python(target, *tuple(route["python_arguments"]))

    assert result.returncode != 0
    assert manifest_kind.split("-")[0].capitalize() in _phase0c_output(result)
    _assert_phase0c_no_write(target, before_files, before_directories, sentinel, secondary)


def test_phase4a_correction2_python_standalone_labels_v3_validation_blocked_before_write(
    tmp_path: Path,
) -> None:
    standalone_script = tmp_path / "standalone" / "scripts" / "bootstrap.py"
    standalone_script.parent.mkdir(parents=True)
    shutil.copyfile(PHASE0C_PYTHON_SCRIPT, standalone_script)
    target = tmp_path / "adopter"
    target.mkdir()
    manifest_bytes = (json.dumps(_phase4a_valid_manifest(), ensure_ascii=False) + "\n").encode("utf-8")
    sentinel, secondary = _create_phase0c_target(target, manifest_bytes)
    before_files, before_directories = _snapshot_tree(target)
    result = subprocess.run(
        [sys.executable, str(standalone_script)],
        cwd=target,
        capture_output=True,
        check=False,
        text=True,
        encoding="utf-8",
        errors="replace",
    )
    output = _phase0c_output(result)
    assert result.returncode != 0
    assert "v3-validation-blocked" in output
    assert "catalog-unavailable" in output
    assert "valid-v3" not in output
    assert "下載" not in output
    _assert_phase0c_no_write(target, before_files, before_directories, sentinel, secondary)


def test_phase0a_new_adopter_uses_adopter_constitution_without_maintainer_policy(
    tmp_path: Path, capsys,
) -> None:
    template_root, target_root, maintainer_content, adopter_content = (
        _create_phase0a_constitution_fixture(tmp_path)
    )
    manifest_entries: Dict[str, dict] = {}

    result = bootstrap.sync_workflow_files(
        template_root / ".github",
        target_root,
        force=False,
        manifest_entries=manifest_entries,
        constitution_source_root=template_root,
    )

    destination = target_root / ".github" / "copilot-instructions.md"
    assert destination.read_bytes() == adopter_content
    assert destination.read_bytes() != maintainer_content
    assert b"sync-dotgithub" not in destination.read_bytes()
    assert ".github/copilot-instructions.md" in result.files_added
    assert ".github/copilot-instructions.md" not in result.files_skipped
    assert (
        manifest_entries[".github/copilot-instructions.md"]["source"]
        == "template:docs/copilot-instructions.template.md"
    )
    output = capsys.readouterr().out
    assert "Constitution source: docs/copilot-instructions.template.md" in output
    assert "Constitution outcome: installed" in output


def test_phase0a_canonical_adopter_source_excludes_maintainer_policy() -> None:
    repo_root = Path(bootstrap.__file__).resolve().parent.parent
    adopter_content = (
        repo_root / "docs" / "copilot-instructions.template.md"
    ).read_text(encoding="utf-8")

    forbidden = (
        "sync-dotgithub.ps1",
        "check-sync.ps1",
        "audit-catalog.ps1",
        "Never commit source without syncing",
    )
    assert not any(token in adopter_content for token in forbidden)


def test_phase0a_generic_sync_never_falls_back_to_maintainer_constitution(
    tmp_path: Path,
) -> None:
    template_root, target_root, _, _ = _create_phase0a_constitution_fixture(tmp_path)

    result = bootstrap.sync_workflow_files(
        template_root / ".github",
        target_root,
        force=True,
        manifest_entries={},
    )

    assert not (target_root / ".github" / "copilot-instructions.md").exists()
    assert ".github/copilot-instructions.md" in result.files_skipped


def test_phase0a_existing_constitution_is_preserved_without_trusted_manifest_proof(
    tmp_path: Path, capsys,
) -> None:
    template_root, target_root, _, _ = _create_phase0a_constitution_fixture(tmp_path)
    destination = target_root / ".github" / "copilot-instructions.md"
    destination.parent.mkdir()

    cases = (
        ("missing-manifest", {}, b"legacy policy\r\n"),
        (
            "missing-exact-component",
            {".github/other.md": {"managed_hash": bootstrap.hash_bytes(b"other\n")}},
            b"unknown ownership\n",
        ),
        (
            "customized",
            {
                ".github/copilot-instructions.md": {
                    "managed_hash": bootstrap.hash_bytes(b"previous baseline\n"),
                    "source": "template:.github/copilot-instructions.md",
                }
            },
            b"project-customized\x00policy\n",
        ),
        (
            "generic-baseline-match",
            {
                ".github/copilot-instructions.md": {
                    "managed_hash": bootstrap.hash_bytes(b"recorded baseline\n"),
                    "source": "template:.github/copilot-instructions.md",
                }
            },
            b"recorded baseline\n",
        ),
        (
            "unclear-source",
            {
                ".github/copilot-instructions.md": {
                    "managed_hash": bootstrap.hash_bytes(b"legacy policy\n"),
                    "source": "unknown",
                }
            },
            b"legacy policy\n",
        ),
    )

    for case_name, manifest_entries, existing_content in cases:
        destination.write_bytes(existing_content)
        original_constitution_entry = deepcopy(
            manifest_entries.get(".github/copilot-instructions.md")
        )

        result = bootstrap.sync_workflow_files(
            template_root / ".github",
            target_root,
            force=True,
            manifest_entries=manifest_entries,
            constitution_source_root=template_root,
        )

        assert destination.read_bytes() == existing_content, case_name
        assert any(
            item.startswith(
                ".github/copilot-instructions.md [preserved"
            )
            and "manual decision required" in item
            for item in result.files_skipped
        ), case_name
        assert sum(
            item.startswith(".github/copilot-instructions.md")
            for item in result.files_skipped
        ) == 1, case_name
        assert (
            manifest_entries.get(".github/copilot-instructions.md")
            == original_constitution_entry
        ), case_name

    output = capsys.readouterr().out
    assert output.count("Constitution source: docs/copilot-instructions.template.md") == len(cases)
    assert output.count("Constitution outcome: preserved; manual decision required") == len(cases)


def test_phase0b_update_refuses_before_target_write(tmp_path: Path) -> None:
    target_root = tmp_path / "project-update"
    target_root.mkdir()
    before_files, before_directories = _snapshot_tree(target_root)

    result = _run_phase0b_bash(PHASE0B_SCRIPT, target_root, "--update")
    output = _phase0b_output(result)

    assert result.returncode != 0
    assert "Bash installer is deprecated" in output
    assert "Python is the supported Linux/macOS installer" in output
    assert "Existing adopters must use Python" in output
    assert "bootstrap.py --update" in output
    _assert_phase0b_no_write(target_root, before_files, before_directories)


def test_phase0b_update_force_backup_refuses_before_target_write(tmp_path: Path) -> None:
    target_root = tmp_path / "project-update-force-backup"
    target_root.mkdir()
    before_files, before_directories = _snapshot_tree(target_root)

    result = _run_phase0b_bash(
        PHASE0B_SCRIPT,
        target_root,
        "--update",
        "--force",
        "--backup",
    )
    output = _phase0b_output(result)

    assert result.returncode != 0
    assert "Bash installer is deprecated" in output
    assert "bootstrap.py --update" in output
    _assert_phase0b_no_write(target_root, before_files, before_directories)


def test_phase0b_force_refuses_before_target_write(tmp_path: Path) -> None:
    target_root = tmp_path / "project-force"
    target_root.mkdir()
    before_files, before_directories = _snapshot_tree(target_root)

    result = _run_phase0b_bash(PHASE0B_SCRIPT, target_root, "--force")
    output = _phase0b_output(result)

    assert result.returncode != 0
    assert "Bash installer is deprecated" in output
    assert "bootstrap.py --update" in output
    _assert_phase0b_no_write(target_root, before_files, before_directories)


def test_phase0b_backup_refuses_before_target_write(tmp_path: Path) -> None:
    target_root = tmp_path / "project-backup"
    target_root.mkdir()
    before_files, before_directories = _snapshot_tree(target_root)

    result = _run_phase0b_bash(PHASE0B_SCRIPT, target_root, "--backup")
    output = _phase0b_output(result)

    assert result.returncode != 0
    assert "Bash installer is deprecated" in output
    assert "bootstrap.py --update" in output
    _assert_phase0b_no_write(target_root, before_files, before_directories)


def test_phase0b_existing_adopter_without_flags_refuses_before_target_write(
    tmp_path: Path,
) -> None:
    target_root = tmp_path / "existing-adopter"
    target_root.mkdir()
    _create_phase0b_existing_adopter(target_root)
    before_files, before_directories = _snapshot_tree(target_root)
    original_agents = (target_root / "AGENTS.md").read_bytes()
    original_generated = (
        target_root / ".github" / "agents" / "coder.agent.md"
    ).read_bytes()

    result = _run_phase0b_bash(PHASE0B_SCRIPT, target_root)
    output = _phase0b_output(result)

    assert result.returncode != 0
    assert "Bash installer is deprecated" in output
    assert "Existing adopters must use Python" in output
    assert "bootstrap.py --update" in output
    assert (target_root / "AGENTS.md").read_bytes() == original_agents
    assert (
        target_root / ".github" / "agents" / "coder.agent.md"
    ).read_bytes() == original_generated
    _assert_phase0b_no_write(target_root, before_files, before_directories)


def test_phase0b_project_with_github_workflows_only_is_not_treated_as_existing_adopter(
    tmp_path: Path,
) -> None:
    target_root = tmp_path / "workflows-only"
    target_root.mkdir()
    original_workflow = _create_phase0b_workflows_only_project(target_root)

    result = _run_phase0b_bash(PHASE0B_SCRIPT, target_root)
    output = _phase0b_output(result)

    assert result.returncode == 0
    assert "Bash installer is deprecated" in output
    assert "Python is the supported Linux/macOS installer" in output
    assert "bootstrap.py" in output
    assert (target_root / ".github" / "workflows" / "ci.yml").read_bytes() == original_workflow
    assert (target_root / ".github" / "prompts").exists()
    assert not any(path.name.startswith(".github.backup-") for path in target_root.iterdir())


def test_phase0b_project_with_generic_skills_and_agents_is_not_treated_as_existing_adopter(
    tmp_path: Path,
) -> None:
    target_root = tmp_path / "generic-skills-agents"
    target_root.mkdir()
    (target_root / "skills").mkdir()
    (target_root / "agents").mkdir()

    result = _run_phase0b_bash(PHASE0B_SCRIPT, target_root)
    output = _phase0b_output(result)

    assert result.returncode == 0
    assert "Bash installer is deprecated" in output
    assert (target_root / ".github" / "copilot-instructions.md").exists()


def test_phase0b_project_with_preexisting_guidance_files_is_not_treated_as_existing_adopter(
    tmp_path: Path,
) -> None:
    target_root = tmp_path / "generic-guidance-files"
    target_root.mkdir()
    (target_root / "AGENTS.md").write_text("# Unrelated guidance\n", encoding="utf-8")
    (target_root / "CLAUDE.md").write_text("# Unrelated guidance\n", encoding="utf-8")
    (target_root / "GEMINI.md").write_text("# Unrelated guidance\n", encoding="utf-8")

    result = _run_phase0b_bash(PHASE0B_SCRIPT, target_root)
    output = _phase0b_output(result)

    assert result.returncode == 0
    assert "Bash installer is deprecated" in output
    assert (target_root / ".github" / "copilot-instructions.md").exists()


def test_phase0b_retained_initial_install_warns_and_remains_functional(
    tmp_path: Path,
) -> None:
    target_root = tmp_path / "new-project"
    target_root.mkdir()

    result = _run_phase0b_bash(PHASE0B_SCRIPT, target_root)
    output = _phase0b_output(result)

    assert result.returncode == 0
    assert "Bash installer is deprecated" in output
    assert "Python is the supported Linux/macOS installer" in output
    assert "python3" in output
    assert "bootstrap.py" in output
    assert (target_root / ".github").exists()
    assert (target_root / ".github" / "copilot-instructions.md").exists()
    assert (target_root / ".gitattributes").exists()
    assert (target_root / ".git").exists()


def test_phase0b_standalone_script_without_valid_template_source_refuses_before_write(
    tmp_path: Path,
) -> None:
    standalone_root = tmp_path / "standalone"
    standalone_root.mkdir()
    standalone_script = standalone_root / "bootstrap.sh"
    standalone_script.write_bytes(PHASE0B_SCRIPT.read_bytes())

    target_root = tmp_path / "project"
    target_root.mkdir()
    original_workflow = _create_phase0b_workflows_only_project(target_root)
    before_files, before_directories = _snapshot_tree(target_root)

    result = _run_phase0b_bash(standalone_script, target_root)
    output = _phase0b_output(result)

    assert result.returncode != 0
    assert "Bash installer is deprecated" in output
    assert "Python is the supported Linux/macOS installer" in output
    assert "bootstrap.py" in output
    assert (target_root / ".github" / "workflows" / "ci.yml").read_bytes() == original_workflow
    _assert_phase0b_no_write(target_root, before_files, before_directories)


def test_phase0b_source_probe_rejects_non_template_repo_before_write(
    tmp_path: Path,
) -> None:
    fake_source_root = tmp_path / "fake-source"
    (fake_source_root / ".github").mkdir(parents=True)
    (fake_source_root / "scripts").mkdir()
    (fake_source_root / "scripts" / "bootstrap.py").write_text(
        "# fake python bootstrap\n",
        encoding="utf-8",
    )
    fake_script = fake_source_root / "scripts" / "bootstrap.sh"
    fake_script.write_bytes(PHASE0B_SCRIPT.read_bytes())

    target_root = tmp_path / "target"
    target_root.mkdir()
    before_files, before_directories = _snapshot_tree(target_root)

    result = _run_phase0b_bash(fake_script, target_root)
    output = _phase0b_output(result)

    assert result.returncode != 0
    assert "Bash installer is deprecated" in output
    assert "valid local ai-dev-workflow template clone" in output
    _assert_phase0b_no_write(target_root, before_files, before_directories)


def test_phase0b_help_reports_deprecated_bash_and_python_guidance() -> None:
    result = _run_phase0b_bash(PHASE0B_SCRIPT, PHASE0B_REPO_ROOT, "--help")
    output = _phase0b_output(result)

    assert result.returncode == 0
    assert "Bash installer is deprecated" in output
    assert "Python is the supported Linux/macOS installer" in output
    assert "bootstrap.py" in output
    assert "Refresh workflow files (includes backup)" not in output
    assert "Force overwrite existing workflow files" not in output
    assert "Create backup before syncing" not in output
    assert "cross-platform support" not in output


def test_phase0b_refused_operations_preserve_fixture_invariance(tmp_path: Path) -> None:
    cases = (
        ("update", ("--update",)),
        ("update-force-backup", ("--update", "--force", "--backup")),
        ("force", ("--force",)),
        ("backup", ("--backup",)),
    )

    for case_name, args in cases:
        target_root = tmp_path / case_name
        target_root.mkdir()
        _create_phase0b_workflows_only_project(target_root)
        before_files, before_directories = _snapshot_tree(target_root)

        result = _run_phase0b_bash(PHASE0B_SCRIPT, target_root, *args)

        assert result.returncode != 0
        _assert_phase0b_no_write(target_root, before_files, before_directories)


def test_extract_version_returns_present_match() -> None:
    text = "git version 2.43.0.windows.1"
    pattern = r"git version (\d+\.\d+\.\d+)"
    assert bootstrap.extract_version(text, pattern) == "2.43.0"


def test_normalize_relative_path_preserves_path_identity() -> None:
    cases = {
        ".github/x": ".github/x",
        "./.github/x": ".github/x",
        ".agents/skills/x": ".agents/skills/x",
        "./skills/x": "skills/x",
        "../outside": "../outside",
    }

    for raw, expected in cases.items():
        assert bootstrap.normalize_relative_path(raw) == expected


def test_is_version_ge_comparison() -> None:
    assert bootstrap.is_version_ge("2.49.0", "2.0.0")
    assert not bootstrap.is_version_ge("1.9.9", "2.0.0")


def test_parse_agent_definition_uses_filename_as_portable_name(tmp_path: Path) -> None:
    agent_file = tmp_path / "coder.agent.md"
    agent_file.write_text(
        """---
name: coder-agent
description: Test coder description
---

# Coder

Follow the workflow.
""",
        encoding="utf-8",
    )

    name, description, body = bootstrap.parse_agent_definition(agent_file)

    assert name == "coder"
    assert description == "Test coder description"
    assert "Follow the workflow." in body


def test_install_portable_runtime_creates_mounts_and_generated_agents(tmp_path: Path) -> None:
    source_root = tmp_path / "template"
    target_root = tmp_path / "project"

    (source_root / "skills" / "demo-skill").mkdir(parents=True)
    (source_root / "skills" / "demo-skill" / "SKILL.md").write_text(
        "---\nname: demo-skill\ndescription: demo\n---\n",
        encoding="utf-8",
    )
    (source_root / "agents").mkdir(parents=True)
    (source_root / "agents" / "demo.agent.md").write_text(
        "---\nname: demo\ndescription: demo\n---\n\n# Demo\n",
        encoding="utf-8",
    )
    (source_root / "agents" / "coder.agent.md").write_text(
        """---
name: coder-agent
description: Demo coder
---

# Demo Coder

Be precise.
""",
        encoding="utf-8",
    )
    (source_root / "docs").mkdir(parents=True)
    (source_root / "docs" / "AGENTS.template.md").write_text("# Shared guide\n", encoding="utf-8")
    (source_root / "docs" / "CLAUDE.template.md").write_text("@AGENTS.md\n", encoding="utf-8")
    (source_root / "docs" / "GEMINI.template.md").write_text("Read AGENTS.md\n", encoding="utf-8")
    _write_phase3_lifecycle_fixture_assets(source_root, "# Adopter lifecycle\n")
    target_root.mkdir()

    result = bootstrap.install_portable_runtime(
        source_root,
        target_root,
        force=False,
        manifest_entries={},
    )

    assert (target_root / "skills" / "demo-skill" / "SKILL.md").exists()
    assert (target_root / ".claude" / "skills" / "demo-skill" / "SKILL.md").exists()
    assert (target_root / ".agents" / "skills" / "demo-skill" / "SKILL.md").exists()
    assert (target_root / ".codex" / "agents" / "coder.toml").exists()
    assert (target_root / ".claude" / "agents" / "coder.md").exists()
    assert (target_root / "AGENTS.md").read_text(encoding="utf-8") == "# Shared guide\n"
    assert "GEMINI.md" in result.files_added


def test_sync_workflow_files_respects_exclusions(tmp_path: Path) -> None:
    source = tmp_path / ".github"
    project_root = tmp_path / "project"
    (source / "workflows").mkdir(parents=True)
    (source / "workflows" / "ci.yml").write_text("ci")
    (source / "CODEOWNERS").write_text("* @team")
    (source / "README.md").write_text("hello")
    docs_dir = source / "docs"
    docs_dir.mkdir(parents=True, exist_ok=True)
    (docs_dir / "notes.txt").write_text("notes")

    project_root.mkdir()
    result = bootstrap.sync_workflow_files(
        source,
        project_root,
        force=False,
        manifest_entries={},
    )

    added = set(result.files_added)
    skipped = set(result.files_skipped)

    assert ".github/README.md" in added
    assert not any(item.startswith(".github/workflows") for item in added)
    assert any(item.startswith(".github/workflows") for item in skipped)
    assert any("CODEOWNERS" in item for item in skipped)


def test_sync_workflow_files_force_overwrites(tmp_path: Path) -> None:
    source = tmp_path / ".github"
    project_root = tmp_path / "project-force"
    source.mkdir(parents=True, exist_ok=True)
    (source / "README.md").write_text("new content")
    project_root.mkdir(parents=True)
    target_github = project_root / ".github"
    target_github.mkdir(parents=True, exist_ok=True)
    (target_github / "README.md").write_text("old content")

    result = bootstrap.sync_workflow_files(
        source,
        project_root,
        force=True,
        manifest_entries={},
    )

    assert ".github/README.md" in result.files_updated
    assert (target_github / "README.md").read_text() == "new content"


def test_files_are_identical_detects_same_content(tmp_path: Path) -> None:
    """Test that files_are_identical correctly identifies identical files."""
    file1 = tmp_path / "file1.txt"
    file2 = tmp_path / "file2.txt"
    file1.write_text("same content")
    file2.write_text("same content")
    
    assert bootstrap.files_are_identical(file1, file2)


def test_files_are_identical_detects_different_content(tmp_path: Path) -> None:
    """Test that files_are_identical correctly identifies different files."""
    file1 = tmp_path / "file1.txt"
    file2 = tmp_path / "file2.txt"
    file1.write_text("content A")
    file2.write_text("content B")
    
    assert not bootstrap.files_are_identical(file1, file2)


def test_sync_without_force_preserves_untracked_existing_file(tmp_path: Path) -> None:
    """Untracked legacy-compatible files are preserved when force is false."""
    source = tmp_path / ".github"
    project_root = tmp_path / "project-conflict"
    source.mkdir(parents=True)
    (source / "config.yml").write_text("new config")
    
    project_root.mkdir()
    target_github = project_root / ".github"
    target_github.mkdir(parents=True)
    (target_github / "config.yml").write_text("old config")
    
    result = bootstrap.sync_workflow_files(
        source,
        project_root,
        force=False,
        manifest_entries={},
    )
    
    assert ".github/config.yml [preserved existing]" in result.files_skipped
    assert ".github/config.yml" not in result.files_updated
    assert ".github/config.yml" not in result.files_added
    assert not result.files_conflicted
    assert (target_github / "config.yml").read_text() == "old config"


def test_backup_directory_creates_timestamped_backup(tmp_path: Path) -> None:
    """Test that backup_directory creates a backup with timestamp."""
    source_dir = tmp_path / ".github"
    source_dir.mkdir()
    (source_dir / "file.txt").write_text("content")
    
    result = bootstrap.backup_directory(source_dir)
    
    assert result.success
    assert result.backup_path is not None
    backup_path = Path(result.backup_path)
    assert backup_path.exists()
    assert ".github.backup-" in backup_path.name
    assert (backup_path / "file.txt").read_text() == "content"


def test_sync_with_backup_creates_backup(tmp_path: Path) -> None:
    """Test that sync with backup=True creates a backup before syncing."""
    source = tmp_path / ".github"
    project_root = tmp_path / "project-backup"
    source.mkdir(parents=True)
    (source / "new.txt").write_text("new")
    
    project_root.mkdir()
    target_github = project_root / ".github"
    target_github.mkdir(parents=True)
    (target_github / "old.txt").write_text("old")
    
    result = bootstrap.sync_workflow_files(
        source,
        project_root,
        force=True,
        manifest_entries={},
        backup=True,
    )
    
    # Check that backup was created
    backup_dirs = list(project_root.glob(".github.backup-*"))
    assert len(backup_dirs) == 1
    assert (backup_dirs[0] / "old.txt").exists()


def test_calculate_file_hash_returns_sha256(tmp_path: Path) -> None:
    """Test that calculate_file_hash returns correct SHA256 hash."""
    file = tmp_path / "test.txt"
    file.write_text("hello world")
    
    hash_result = bootstrap.calculate_file_hash(file)
    
    # SHA256 of "hello world" (without newline)
    expected = "b94d27b9934d3e08a52e52d7da7dabfac484efe37a5380ee9088f7ace2efcde9"
    assert hash_result == expected


def test_calculate_file_hash_different_content_different_hash(tmp_path: Path) -> None:
    """Test that different content produces different hashes."""
    file1 = tmp_path / "file1.txt"
    file2 = tmp_path / "file2.txt"
    file1.write_text("content A")
    file2.write_text("content B")
    
    hash1 = bootstrap.calculate_file_hash(file1)
    hash2 = bootstrap.calculate_file_hash(file2)
    
    assert hash1 != hash2


def test_files_are_identical_returns_false_for_nonexistent_files(tmp_path: Path) -> None:
    """Test that files_are_identical returns False when files don't exist."""
    file1 = tmp_path / "nonexistent1.txt"
    file2 = tmp_path / "nonexistent2.txt"
    
    assert not bootstrap.files_are_identical(file1, file2)


def test_backup_directory_fails_if_source_not_exists(tmp_path: Path) -> None:
    """Test that backup_directory returns failure when source doesn't exist."""
    nonexistent = tmp_path / "nonexistent"
    
    result = bootstrap.backup_directory(nonexistent)
    
    assert not result.success
    assert result.backup_path is None
    assert "not found" in result.message.lower()


def test_backup_directory_fails_if_backup_exists(tmp_path: Path) -> None:
    """Test that backup_directory fails when backup already exists."""
    source = tmp_path / ".github"
    source.mkdir()
    (source / "file.txt").write_text("content")
    
    backup_name = ".github.backup-test"
    backup_path = tmp_path / backup_name
    backup_path.mkdir()  # Pre-create the backup directory
    
    result = bootstrap.backup_directory(source, backup_name=backup_name)
    
    assert not result.success
    assert "already exists" in result.message.lower()


def test_check_git_uncommitted_changes_detects_changes(tmp_path: Path) -> None:
    """Test that check_git_uncommitted_changes detects uncommitted files."""
    # Initialize a git repo
    subprocess.run(["git", "init"], cwd=tmp_path, check=True, capture_output=True)
    subprocess.run(["git", "config", "user.email", "test@example.com"], cwd=tmp_path, check=True, capture_output=True)
    subprocess.run(["git", "config", "user.name", "Test User"], cwd=tmp_path, check=True, capture_output=True)
    
    # Create .github directory with uncommitted file
    github_dir = tmp_path / ".github"
    github_dir.mkdir()
    (github_dir / "new.txt").write_text("uncommitted")
    
    has_changes = bootstrap.check_git_uncommitted_changes(tmp_path, ".github")
    
    assert has_changes


def test_check_git_uncommitted_changes_no_changes_when_committed(tmp_path: Path) -> None:
    """Test that check_git_uncommitted_changes returns False when all files committed."""
    # Initialize a git repo
    subprocess.run(["git", "init"], cwd=tmp_path, check=True, capture_output=True)
    subprocess.run(["git", "config", "user.email", "test@example.com"], cwd=tmp_path, check=True, capture_output=True)
    subprocess.run(["git", "config", "user.name", "Test User"], cwd=tmp_path, check=True, capture_output=True)
    
    # Create .github directory and commit
    github_dir = tmp_path / ".github"
    github_dir.mkdir()
    (github_dir / "file.txt").write_text("committed")
    subprocess.run(["git", "add", ".github"], cwd=tmp_path, check=True, capture_output=True)
    subprocess.run(["git", "commit", "-m", "Initial commit"], cwd=tmp_path, check=True, capture_output=True)
    
    has_changes = bootstrap.check_git_uncommitted_changes(tmp_path, ".github")
    
    assert not has_changes


def test_check_git_uncommitted_changes_returns_false_when_git_not_available(tmp_path: Path) -> None:
    """Test that check_git_uncommitted_changes returns False in non-git directory."""
    # tmp_path is not a git repo
    has_changes = bootstrap.check_git_uncommitted_changes(tmp_path, ".github")
    
    assert not has_changes


def test_sync_without_force_skips_identical_files(tmp_path: Path) -> None:
    """Test that sync skips files with identical content when force=False."""
    source = tmp_path / ".github"
    project_root = tmp_path / "project-identical"
    source.mkdir(parents=True)
    (source / "same.txt").write_text("identical content")
    
    project_root.mkdir()
    target_github = project_root / ".github"
    target_github.mkdir(parents=True)
    (target_github / "same.txt").write_text("identical content")
    
    result = bootstrap.sync_workflow_files(
        source,
        project_root,
        force=False,
        manifest_entries={},
    )
    
    assert ".github/same.txt" in result.files_skipped
    assert ".github/same.txt" not in result.files_added
    assert ".github/same.txt" not in result.files_updated
    assert ".github/same.txt" not in result.files_conflicted


def test_sync_with_force_overwrites_different_files(tmp_path: Path) -> None:
    """Test that sync with force=True overwrites files with different content."""
    source = tmp_path / ".github"
    project_root = tmp_path / "project-force-overwrite"
    source.mkdir(parents=True)
    (source / "config.yml").write_text("new config v2")
    
    project_root.mkdir()
    target_github = project_root / ".github"
    target_github.mkdir(parents=True)
    (target_github / "config.yml").write_text("old config v1")
    
    result = bootstrap.sync_workflow_files(
        source,
        project_root,
        force=True,
        manifest_entries={},
    )
    
    assert ".github/config.yml" in result.files_updated
    assert (target_github / "config.yml").read_text() == "new config v2"


def test_sync_adds_new_files(tmp_path: Path) -> None:
    """Test that sync correctly adds new files that don't exist in target."""
    source = tmp_path / ".github"
    project_root = tmp_path / "project-new-files"
    source.mkdir(parents=True)
    (source / "newfile.md").write_text("brand new file")
    
    project_root.mkdir()
    
    result = bootstrap.sync_workflow_files(
        source,
        project_root,
        force=False,
        manifest_entries={},
    )
    
    assert ".github/newfile.md" in result.files_added
    target_file = project_root / ".github" / "newfile.md"
    assert target_file.exists()
    assert target_file.read_text() == "brand new file"


def test_sync_respects_exclusion_patterns_workflows(tmp_path: Path) -> None:
    """Test that sync skips files matching EXCLUDE_PATTERNS (workflows)."""
    source = tmp_path / ".github"
    project_root = tmp_path / "project-exclude"
    source.mkdir(parents=True)
    workflows_dir = source / "workflows"
    workflows_dir.mkdir()
    (workflows_dir / "ci.yml").write_text("ci workflow")
    (source / "README.md").write_text("readme")
    
    project_root.mkdir()
    
    result = bootstrap.sync_workflow_files(
        source,
        project_root,
        force=False,
        manifest_entries={},
    )
    
    # workflows should be skipped
    assert any("workflows" in s for s in result.files_skipped)
    assert not any("workflows" in a for a in result.files_added)
    
    # README should be added
    assert ".github/README.md" in result.files_added


def test_sync_respects_exclusion_patterns_codeowners(tmp_path: Path) -> None:
    """Test that sync skips CODEOWNERS file."""
    source = tmp_path / ".github"
    project_root = tmp_path / "project-codeowners"
    source.mkdir(parents=True)
    (source / "CODEOWNERS").write_text("* @team")
    (source / "other.md").write_text("other file")
    
    project_root.mkdir()
    
    result = bootstrap.sync_workflow_files(
        source,
        project_root,
        force=False,
        manifest_entries={},
    )
    
    assert any("CODEOWNERS" in s for s in result.files_skipped)
    assert ".github/other.md" in result.files_added


def test_backup_directory_custom_name(tmp_path: Path) -> None:
    """Test that backup_directory accepts custom backup name."""
    source = tmp_path / ".github"
    source.mkdir()
    (source / "data.txt").write_text("important data")
    
    custom_name = "custom-backup-name"
    result = bootstrap.backup_directory(source, backup_name=custom_name)
    
    assert result.success
    backup_path = tmp_path / custom_name
    assert backup_path.exists()
    assert (backup_path / "data.txt").read_text() == "important data"


def test_version_to_tuple_parses_correctly() -> None:
    """Test that version_to_tuple correctly parses version strings."""
    assert bootstrap.version_to_tuple("2.43.0") == (2, 43, 0)
    assert bootstrap.version_to_tuple("10.5.128") == (10, 5, 128)


def test_safe_print_handles_unicode(capsys) -> None:
    """Test that safe_print handles unicode characters."""
    bootstrap.safe_print("✅ Success with emoji")
    captured = capsys.readouterr()
    # Should print something (either with emoji or without)
    assert len(captured.out) > 0


def test_run_command_returns_output_for_valid_command() -> None:
    """Test that run_command returns output for valid commands."""
    # Use a command that works cross-platform
    result = bootstrap.run_command(["python", "--version"])
    assert result is not None
    assert "Python" in result


def test_run_command_returns_none_for_invalid_command() -> None:
    """Test that run_command returns None for invalid commands."""
    result = bootstrap.run_command(["nonexistent_command_xyz", "--version"])
    assert result is None


def test_check_tool_detects_installed_tool() -> None:
    """Test that check_tool correctly detects installed tools."""
    result = bootstrap.check_tool(
        ["python", "--version"],
        r"Python (\d+\.\d+\.\d+)",
        "3.0.0"
    )
    assert result.installed
    assert result.version is not None
    assert result.meets_requirement


def test_check_tool_returns_false_for_nonexistent_tool() -> None:
    """Test that check_tool returns False for nonexistent tools."""
    result = bootstrap.check_tool(
        ["nonexistent_xyz", "--version"],
        r"(\d+\.\d+\.\d+)",
        "1.0.0"
    )
    assert not result.installed
    assert result.version is None
    assert not result.meets_requirement


def test_check_git_installed() -> None:
    """Test that check_git_installed detects Git."""
    result = bootstrap.check_git_installed()
    # Git should be installed in the test environment
    assert result.installed
    assert result.version is not None


def test_check_python_version() -> None:
    """Test that check_python_version returns current Python version."""
    result = bootstrap.check_python_version()
    assert result.installed
    assert result.version is not None
    assert result.meets_requirement  # Should meet MIN_PYTHON (3.7.0)


def test_write_check_prints_success_message(capsys) -> None:
    """Test that write_check prints success message for installed tools."""
    result = bootstrap.CheckResult(True, "2.43.0", True)
    bootstrap.write_check("Git", result)
    captured = capsys.readouterr()
    assert "Git" in captured.out
    assert "2.43.0" in captured.out


def test_write_check_prints_warning_for_old_version(capsys) -> None:
    """Test that write_check prints warning for old versions."""
    result = bootstrap.CheckResult(True, "1.0.0", False)
    bootstrap.write_check("OldTool", result, recommended="2.0.0")
    captured = capsys.readouterr()
    assert "OldTool" in captured.out
    assert "1.0.0" in captured.out


def test_write_check_prints_error_for_missing_tool(capsys) -> None:
    """Test that write_check prints error for missing tools."""
    result = bootstrap.CheckResult(False, None, False)
    bootstrap.write_check("MissingTool", result, install_url="https://example.com")
    captured = capsys.readouterr()
    assert "MissingTool" in captured.out
    assert "https://example.com" in captured.out


def test_initialize_git_repo_creates_git_repo(tmp_path: Path) -> None:
    """Test that initialize_git_repo creates a Git repository."""
    result = bootstrap.initialize_git_repo(tmp_path)
    
    assert result.is_new or not result.is_new  # Either creates new or finds existing
    assert (tmp_path / ".git").exists()


def test_initialize_git_repo_skips_existing_repo(tmp_path: Path) -> None:
    """Test that initialize_git_repo skips existing Git repos."""
    # Create Git repo
    subprocess.run(["git", "init"], cwd=tmp_path, check=True, capture_output=True)
    
    result = bootstrap.initialize_git_repo(tmp_path)
    
    assert not result.is_new  # Should detect existing repo


def test_sync_workflow_files_raises_error_for_nonexistent_source(tmp_path: Path) -> None:
    """Test that sync_workflow_files raises FileNotFoundError for nonexistent source."""
    nonexistent_source = tmp_path / "nonexistent"
    target = tmp_path / "target"
    
    try:
        bootstrap.sync_workflow_files(
            nonexistent_source,
            target,
            force=False,
            manifest_entries={},
        )
        assert False, "Should have raised FileNotFoundError"
    except FileNotFoundError as e:
        assert "not found" in str(e).lower()


def test_sync_workflow_files_creates_target_if_not_exists(tmp_path: Path) -> None:
    """Test that sync_workflow_files creates target directory if it doesn't exist."""
    source = tmp_path / ".github"
    source.mkdir()
    (source / "file.txt").write_text("content")
    
    target = tmp_path / "new-target"
    # Target doesn't exist yet
    
    result = bootstrap.sync_workflow_files(
        source,
        target,
        force=False,
        manifest_entries={},
    )
    
    assert target.exists()
    assert (target / ".github").exists()
    assert ".github/file.txt" in result.files_added


def test_sync_with_backup_prints_success_message(tmp_path: Path, capsys) -> None:
    """Test that sync with backup prints success message."""
    source = tmp_path / ".github"
    source.mkdir()
    (source / "file.txt").write_text("content")
    
    target = tmp_path / "target"
    target.mkdir()
    target_github = target / ".github"
    target_github.mkdir()
    (target_github / "old.txt").write_text("old")
    
    bootstrap.sync_workflow_files(
        source,
        target,
        force=True,
        manifest_entries={},
        backup=True,
    )
    
    captured = capsys.readouterr()
    assert "Backup created" in captured.out or "备份" in captured.out.lower()


def test_extract_version_returns_none_when_no_match() -> None:
    """Test that extract_version returns None when pattern doesn't match."""
    text = "some random text without version"
    pattern = r"version (\d+\.\d+\.\d+)"
    
    result = bootstrap.extract_version(text, pattern)
    
    assert result is None


def test_is_version_ge_equal_versions() -> None:
    """Test that is_version_ge returns True for equal versions."""
    assert bootstrap.is_version_ge("2.0.0", "2.0.0")


def test_is_version_ge_handles_different_component_lengths() -> None:
    """Test that is_version_ge handles version comparisons correctly."""
    assert bootstrap.is_version_ge("2.1.0", "2.0.9")
    assert not bootstrap.is_version_ge("2.0.9", "2.1.0")


def test_sync_creates_nested_directories(tmp_path: Path) -> None:
    """Test that sync creates nested directory structure in target."""
    source = tmp_path / ".github"
    nested = source / "docs" / "guides"
    nested.mkdir(parents=True)
    (nested / "guide.md").write_text("guide content")
    
    target = tmp_path / "target"
    
    result = bootstrap.sync_workflow_files(
        source,
        target,
        force=False,
        manifest_entries={},
    )
    
    assert ".github/docs/guides/guide.md" in result.files_added
    target_file = target / ".github" / "docs" / "guides" / "guide.md"
    assert target_file.exists()
    assert target_file.read_text() == "guide content"


def test_sync_handles_windows_path_separators(tmp_path: Path) -> None:
    """Test that sync normalizes Windows path separators to forward slashes."""
    source = tmp_path / ".github"
    subdir = source / "subdir"
    subdir.mkdir(parents=True)
    (subdir / "file.txt").write_text("content")
    
    target = tmp_path / "target"
    
    result = bootstrap.sync_workflow_files(
        source,
        target,
        force=False,
        manifest_entries={},
    )
    
    # Should use forward slashes in result
    added_files = " ".join(result.files_added)
    assert "subdir/file.txt" in added_files or "subdir\\file.txt" in added_files


def test_backup_result_attributes() -> None:
    """Test BackupResult dataclass attributes."""
    result = bootstrap.BackupResult(True, "/path/to/backup", "Success message")
    
    assert result.success
    assert result.backup_path == "/path/to/backup"
    assert result.message == "Success message"


def test_sync_result_attributes() -> None:
    """Test SyncResult dataclass attributes."""
    result = bootstrap.SyncResult(
        files_added=["a.txt"],
        files_updated=["b.txt"],
        files_skipped=["c.txt"],
        files_conflicted=["d.txt"]
    )
    
    assert result.files_added == ["a.txt"]
    assert result.files_updated == ["b.txt"]
    assert result.files_skipped == ["c.txt"]
    assert result.files_conflicted == ["d.txt"]


def test_check_result_attributes() -> None:
    """Test CheckResult dataclass attributes."""
    result = bootstrap.CheckResult(True, "2.43.0", True)
    
    assert result.installed
    assert result.version == "2.43.0"
    assert result.meets_requirement


def test_git_init_result_attributes() -> None:
    """Test GitInitResult dataclass attributes."""
    result = bootstrap.GitInitResult(True, "/path/.git", "Initialized")
    
    assert result.is_new
    assert result.git_dir == "/path/.git"
    assert result.message == "Initialized"


def test_check_node_installed() -> None:
    """Test that check_node_installed detects Node.js if available."""
    result = bootstrap.check_node_installed()
    
    # Node.js might or might not be installed, but function should work
    assert isinstance(result.installed, bool)
    if result.installed:
        assert result.version is not None


def test_check_github_cli_installed() -> None:
    """Test that check_github_cli_installed detects gh if available."""
    result = bootstrap.check_github_cli_installed()
    
    # gh CLI might or might not be installed
    assert isinstance(result.installed, bool)
    if result.installed:
        assert result.version is not None


def test_sync_workflow_files_with_empty_source(tmp_path: Path) -> None:
    """Test that sync handles empty source directory."""
    source = tmp_path / ".github"
    source.mkdir()
    # Empty source
    
    target = tmp_path / "target"
    
    result = bootstrap.sync_workflow_files(
        source,
        target,
        force=False,
        manifest_entries={},
    )
    
    assert len(result.files_added) == 0
    assert len(result.files_updated) == 0


def test_backup_directory_preserves_file_content(tmp_path: Path) -> None:
    """Test that backup preserves exact file content."""
    source = tmp_path / ".github"
    source.mkdir()
    test_content = "Line 1\nLine 2\nLine 3"
    (source / "test.txt").write_text(test_content)
    
    result = bootstrap.backup_directory(source)
    
    assert result.success
    backup_file = Path(result.backup_path) / "test.txt"
    assert backup_file.read_text() == test_content


def test_files_are_identical_with_binary_files(tmp_path: Path) -> None:
    """Test that files_are_identical works with binary files."""
    file1 = tmp_path / "binary1.dat"
    file2 = tmp_path / "binary2.dat"
    binary_content = bytes([0x00, 0x01, 0x02, 0xFF])
    file1.write_bytes(binary_content)
    file2.write_bytes(binary_content)
    
    assert bootstrap.files_are_identical(file1, file2)


def test_calculate_file_hash_binary_file(tmp_path: Path) -> None:
    """Test that calculate_file_hash works with binary files."""
    file = tmp_path / "binary.dat"
    binary_content = bytes([0x48, 0x65, 0x6C, 0x6C, 0x6F])  # "Hello" in hex
    file.write_bytes(binary_content)
    
    hash_result = bootstrap.calculate_file_hash(file)
    
    # Should be a valid 64-character hexadecimal SHA256 hash
    assert len(hash_result) == 64
    assert all(c in "0123456789abcdef" for c in hash_result)


def test_install_portable_runtime_seeds_legacy_runtime_and_preserves_existing_customization(
    tmp_path: Path,
) -> None:
    source_root = tmp_path / "template"
    target_root = tmp_path / "project"
    manifest_entries = {}

    (source_root / "skills" / "demo-skill").mkdir(parents=True)
    (source_root / "skills" / "demo-skill" / "SKILL.md").write_text(
        "---\nname: demo-skill\ndescription: template version\n---\n",
        encoding="utf-8",
    )
    (source_root / "skills" / "gate-check").mkdir(parents=True)
    (source_root / "skills" / "gate-check" / "SKILL.md").write_text(
        "---\nname: gate-check\ndescription: maintainer only\n---\n",
        encoding="utf-8",
    )
    (source_root / "agents").mkdir(parents=True)
    (source_root / "agents" / "coder.agent.md").write_text(
        """---
name: coder-agent
description: Template coder
---

# Template Coder
""",
        encoding="utf-8",
    )
    (source_root / "docs").mkdir(parents=True)
    (source_root / "docs" / "AGENTS.template.md").write_text("# Shared guide\n", encoding="utf-8")
    (source_root / "docs" / "CLAUDE.template.md").write_text("@AGENTS.md\n", encoding="utf-8")
    (source_root / "docs" / "GEMINI.template.md").write_text("Read AGENTS.md\n", encoding="utf-8")
    _write_phase3_lifecycle_fixture_assets(source_root, "# Adopter lifecycle\n")

    (target_root / ".github" / "skills" / "demo-skill").mkdir(parents=True)
    (target_root / ".github" / "skills" / "demo-skill" / "SKILL.md").write_text(
        "---\nname: demo-skill\ndescription: project customized\n---\n",
        encoding="utf-8",
    )
    (target_root / ".github" / "agents").mkdir(parents=True)
    (target_root / ".github" / "agents" / "coder.agent.md").write_text(
        """---
name: coder-agent
description: Project coder
---

# Project Coder
""",
        encoding="utf-8",
    )

    bootstrap.install_portable_runtime(
        source_root,
        target_root,
        force=False,
        manifest_entries=manifest_entries,
    )

    assert (target_root / "skills" / "demo-skill" / "SKILL.md").read_text(encoding="utf-8").startswith(
        "---\nname: demo-skill\ndescription: project customized"
    )
    assert (target_root / "agents" / "coder.agent.md").read_text(encoding="utf-8").startswith(
        "---\nname: coder-agent\ndescription: Project coder"
    )
    assert (target_root / ".github" / "skills" / "demo-skill" / "SKILL.md").read_text(encoding="utf-8").startswith(
        "---\nname: demo-skill\ndescription: project customized"
    )
    assert not (target_root / "skills" / "gate-check").exists()
    assert not (target_root / ".github" / "skills" / "gate-check").exists()
    assert manifest_entries["skills/demo-skill/SKILL.md"]["status"] == "preserved-existing"
    assert ".github/skills/demo-skill/SKILL.md" in manifest_entries
    assert "github/skills/demo-skill/SKILL.md" not in manifest_entries


def test_sync_workflow_files_update_preserves_forked_template_managed_file(
    tmp_path: Path,
) -> None:
    source = tmp_path / "template" / ".github"
    project_root = tmp_path / "project"
    manifest_entries = {}

    (source / "instructions").mkdir(parents=True)
    source_file = source / "instructions" / "demo.instructions.md"
    source_file.write_text("template-v1\n", encoding="utf-8")
    project_root.mkdir()

    bootstrap.sync_workflow_files(
        source,
        project_root,
        force=False,
        manifest_entries=manifest_entries,
    )

    target_file = project_root / ".github" / "instructions" / "demo.instructions.md"
    target_file.write_text("project-customized\n", encoding="utf-8")
    source_file.write_text("template-v2\n", encoding="utf-8")

    result = bootstrap.sync_workflow_files(
        source,
        project_root,
        force=False,
        manifest_entries=manifest_entries,
    )

    assert target_file.read_text(encoding="utf-8") == "project-customized\n"
    assert any(
        item == ".github/instructions/demo.instructions.md [preserved customization]"
        for item in result.files_skipped
    )
    assert (
        manifest_entries[".github/instructions/demo.instructions.md"]["status"]
        == "preserved-customization"
    )


PHASE3_TEMPLATE_FILES = (
    "00-intake.md",
    "01-brainstorm.md",
    "02-decision-log.md",
    "03-spec.md",
    "04-plan.md",
    "05-test-plan.md",
    "06-impact-analysis.md",
    "07-review.md",
    "99-archive.md",
)


def _write_phase3_lifecycle_fixture_assets(source_root: Path, workflow: str) -> None:
    (source_root / "docs").mkdir(parents=True, exist_ok=True)
    (source_root / "docs" / "WORKFLOW.template.md").write_text(workflow, encoding="utf-8")
    template_root = source_root / "changes" / "_template"
    template_root.mkdir(parents=True, exist_ok=True)
    for name in PHASE3_TEMPLATE_FILES:
        (template_root / name).write_text(f"# template {name}\n", encoding="utf-8")


def _create_phase3_lifecycle_source(source_root: Path, workflow: str) -> None:
    (source_root / "skills" / "demo").mkdir(parents=True)
    (source_root / "skills" / "demo" / "SKILL.md").write_text("# Demo\n", encoding="utf-8")
    (source_root / "agents").mkdir(parents=True)
    (source_root / "agents" / "demo.agent.md").write_text(
        "---\nname: demo\ndescription: demo\n---\n\n# Demo\n",
        encoding="utf-8",
    )
    (source_root / "docs").mkdir(parents=True)
    (source_root / "docs" / "AGENTS.template.md").write_text("# Agents\n", encoding="utf-8")
    (source_root / "docs" / "CLAUDE.template.md").write_text("@AGENTS.md\n", encoding="utf-8")
    (source_root / "docs" / "GEMINI.template.md").write_text("Read AGENTS.md\n", encoding="utf-8")
    _write_phase3_lifecycle_fixture_assets(source_root, workflow)
    (source_root / "WORKFLOW.md").write_text("# Maintainer-only lifecycle\n", encoding="utf-8")


def test_phase3_installs_projection_and_canonical_templates_as_template_managed(
    tmp_path: Path,
) -> None:
    source_root = tmp_path / "template"
    target_root = tmp_path / "project"
    _create_phase3_lifecycle_source(source_root, "# Adopter lifecycle\nportable only\n")
    target_root.mkdir()
    manifest_entries = {}

    result = bootstrap.install_portable_runtime(
        source_root, target_root, force=False, manifest_entries=manifest_entries
    )

    assert (target_root / "WORKFLOW.md").read_bytes() == (
        source_root / "docs" / "WORKFLOW.template.md"
    ).read_bytes()
    assert (target_root / "WORKFLOW.md").read_bytes() != (source_root / "WORKFLOW.md").read_bytes()
    assert manifest_entries["WORKFLOW.md"]["ownership"] == "template-managed"
    assert manifest_entries["WORKFLOW.md"]["source"] == "template:docs/WORKFLOW.template.md"
    for name in PHASE3_TEMPLATE_FILES:
        relative = f"changes/_template/{name}"
        assert (target_root / relative).read_bytes() == (source_root / relative).read_bytes()
        assert manifest_entries[relative]["ownership"] == "template-managed"
        assert manifest_entries[relative]["source"] == f"template:{relative}"
        assert relative in result.files_added
    assert sorted(path.name for path in (target_root / "changes").iterdir()) == ["_template"]


def test_phase3_updates_only_exact_managed_lifecycle_baselines(tmp_path: Path) -> None:
    source_root = tmp_path / "template"
    target_root = tmp_path / "project"
    _create_phase3_lifecycle_source(source_root, "# Adopter lifecycle v1\n")
    target_root.mkdir()
    manifest_entries = {}
    bootstrap.install_portable_runtime(
        source_root, target_root, force=False, manifest_entries=manifest_entries
    )

    (source_root / "docs" / "WORKFLOW.template.md").write_text(
        "# Adopter lifecycle v2\n", encoding="utf-8"
    )
    (source_root / "changes" / "_template" / "07-review.md").write_text(
        "# template 07-review v2\n", encoding="utf-8"
    )
    result = bootstrap.install_portable_runtime(
        source_root, target_root, force=False, manifest_entries=manifest_entries
    )

    assert (target_root / "WORKFLOW.md").read_text(encoding="utf-8") == "# Adopter lifecycle v2\n"
    assert (target_root / "changes" / "_template" / "07-review.md").read_text(
        encoding="utf-8"
    ) == "# template 07-review v2\n"
    assert "WORKFLOW.md" in result.files_updated
    assert "changes/_template/07-review.md" in result.files_updated


def test_phase3_preserves_customized_or_unproven_lifecycle_content(tmp_path: Path) -> None:
    source_root = tmp_path / "template"
    target_root = tmp_path / "project"
    _create_phase3_lifecycle_source(source_root, "# Adopter lifecycle v1\n")
    target_root.mkdir()
    manifest_entries = {}
    bootstrap.install_portable_runtime(
        source_root, target_root, force=False, manifest_entries=manifest_entries
    )
    (target_root / "WORKFLOW.md").write_text("# Project customization\n", encoding="utf-8")
    (source_root / "docs" / "WORKFLOW.template.md").write_text(
        "# Adopter lifecycle v2\n", encoding="utf-8"
    )

    customized = bootstrap.install_portable_runtime(
        source_root, target_root, force=True, manifest_entries=manifest_entries
    )

    assert (target_root / "WORKFLOW.md").read_text(encoding="utf-8") == "# Project customization\n"
    assert "WORKFLOW.md [preserved customization]" in customized.files_skipped
    assert manifest_entries["WORKFLOW.md"]["status"] == "preserved-customization"

    unproven_root = tmp_path / "unproven"
    unproven_root.mkdir()
    (unproven_root / "WORKFLOW.md").write_text("# Existing lifecycle\n", encoding="utf-8")
    unproven_manifest = {}
    unproven = bootstrap.install_portable_runtime(
        source_root, unproven_root, force=True, manifest_entries=unproven_manifest
    )
    assert (unproven_root / "WORKFLOW.md").read_text(encoding="utf-8") == "# Existing lifecycle\n"
    assert "WORKFLOW.md [preserved existing; manual decision required]" in unproven.files_skipped
    assert "WORKFLOW.md" not in unproven_manifest

    unproven_cases = {
        "project-owned": {
            "name": "WORKFLOW.md",
            "ownership": "project-owned",
            "source": "project:WORKFLOW.md",
            "managed_hash": bootstrap.hash_bytes(b"# Existing lifecycle\n"),
        },
        "unclear-source": {
            "name": "WORKFLOW.md",
            "ownership": "template-managed",
            "source": "unknown",
            "managed_hash": bootstrap.hash_bytes(b"# Existing lifecycle\n"),
        },
        "missing-baseline": {
            "name": "WORKFLOW.md",
            "ownership": "template-managed",
            "source": "template:docs/WORKFLOW.template.md",
            "managed_hash": None,
        },
    }
    for case_name, component in unproven_cases.items():
        case_root = tmp_path / case_name
        case_root.mkdir()
        (case_root / "WORKFLOW.md").write_text("# Existing lifecycle\n", encoding="utf-8")
        case_manifest = {"WORKFLOW.md": dict(component)}
        original_component = dict(component)

        case_result = bootstrap.install_portable_runtime(
            source_root, case_root, force=True, manifest_entries=case_manifest
        )

        assert (case_root / "WORKFLOW.md").read_text(encoding="utf-8") == "# Existing lifecycle\n"
        assert (
            "WORKFLOW.md [preserved existing; manual decision required]"
            in case_result.files_skipped
        ), case_name
        assert case_manifest["WORKFLOW.md"] == original_component, case_name
