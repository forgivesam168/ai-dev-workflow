from __future__ import annotations

import hashlib
import importlib.util
import json
from pathlib import Path
from typing import Optional

import pytest


REPO_ROOT = Path(__file__).resolve().parents[2]
HELPER_PATH = REPO_ROOT / "scripts" / "manifest_migration_rehearsal.py"
SCHEMA_PATH = REPO_ROOT / "schemas" / "ai-workflow-install-manifest-v3.schema.json"
CATALOG_PATH = REPO_ROOT / "manifest" / "component-catalog.json"


def load_helper():
    spec = importlib.util.spec_from_file_location("phase4c_helper", HELPER_PATH)
    assert spec is not None and spec.loader is not None
    module = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(module)
    return module


@pytest.fixture(scope="module")
def helper():
    return load_helper()


@pytest.fixture(scope="module")
def catalog() -> dict:
    return json.loads(CATALOG_PATH.read_text(encoding="utf-8"))


def sha256(value: bytes) -> str:
    return "sha256:" + hashlib.sha256(value).hexdigest()


def trusted_legacy_manifest(version: int) -> dict:
    payload = b"architect fixture\n"
    digest = sha256(payload)
    return {
        "schema_version": version,
        "installed_at": "2026-01-01T00:00:00Z",
        "source_ref": "fixture-ref",
        "components": [
            {
                "name": "agents/architect.agent.md",
                "installed_at": "2026-01-01T00:00:00Z",
                "updated_at": "2026-01-01T00:00:00Z",
                "source_hash": digest,
                "managed_hash": digest,
                "observed_hash": digest,
                "ownership": "template-managed",
                "kind": "file",
                "source": "template:agents/architect.agent.md",
                "status": "synced",
            }
        ],
    }


@pytest.mark.parametrize("version", [1, 2])
def test_valid_legacy_manifest_converts_deterministically_to_v3(
    helper, version: int
) -> None:
    legacy = trusted_legacy_manifest(version)

    first = helper.convert_legacy_manifest(legacy, REPO_ROOT, writer="python")
    second = helper.convert_legacy_manifest(legacy, REPO_ROOT, writer="python")

    assert first == second
    assert first["schema_version"] == 3
    assert first["last_transaction"]["result"] == "committed"
    assert first["last_transaction"]["mode"] == "migration"
    assert first["components"][0]["identity"]["id"] == "cmp:canonical-architect-agent"
    assert first["components"][0]["provenance"]["ownership"] == "template-managed"
    assert first["components"][0]["hashes"]["baseline"].startswith("sha256:")


def test_canonical_candidate_bytes_are_stable_lf_utf8(helper) -> None:
    candidate = helper.convert_legacy_manifest(
        trusted_legacy_manifest(2), REPO_ROOT, writer="python"
    )

    first = helper.canonical_candidate_bytes(candidate)
    second = helper.canonical_candidate_bytes(json.loads(first))

    assert first == second
    assert first.endswith(b"\n")
    assert not first.startswith(b"\xef\xbb\xbf")
    assert b"\r\n" not in first


@pytest.mark.parametrize(
    ("payload", "state"),
    [
        (b"", "missing"),
        (b"{", "corrupt"),
        (b"[]", "wrong-top-level"),
        (b"null", "wrong-top-level"),
        (b'{"schema_version":4,"components":[]}', "unsupported"),
        (b'{"schema_version":2,"components":[]}', "valid-v2"),
    ],
)
def test_manifest_classification_is_structured(helper, payload: bytes, state: str) -> None:
    result = helper.classify_manifest_bytes(payload if payload else None)

    assert result["state"] == state
    assert result["can_write"] is (state == "valid-v2")


@pytest.mark.parametrize(
    "payload",
    [
        b'{"schema_version":2,"components":[null]}',
        b'{"schema_version":2,"components":[{}]}',
        b'{"schema_version":2,"components":[{"name":"  "}]}',
        b'{"schema_version":2,"components":[{"name":"../outside"}]}',
        b'{"schema_version":2,"components":[{"name":"agents/a.md"},{"name":"agents/a.md"}]}',
    ],
)
def test_manifest_classification_rejects_invalid_component_records(
    helper, payload: bytes
) -> None:
    result = helper.classify_manifest_bytes(payload)

    assert result == {"state": "corrupt", "version": 2, "can_write": False}


def test_manifest_classification_uses_case_sensitive_duplicate_names(helper) -> None:
    result = helper.classify_manifest_bytes(
        b'{"schema_version":2,"components":[{"name":"agents/A.md"},{"name":"agents/a.md"}]}'
    )

    assert result == {"state": "valid-v2", "version": 2, "can_write": True}


def test_legacy_without_explicit_trusted_ownership_is_not_claimed(helper) -> None:
    legacy = trusted_legacy_manifest(1)
    del legacy["components"][0]["ownership"]

    converted = helper.convert_legacy_manifest(
        legacy, REPO_ROOT, writer="python", include_decisions=True
    )

    assert converted["manifest"]["components"] == []
    assert converted["manual_decisions"] == [
        {
            "path": "agents/architect.agent.md",
            "reason": "missing-or-untrusted-lineage",
        }
    ]


def test_unknown_catalog_path_is_reported_for_manual_decision(helper) -> None:
    legacy = trusted_legacy_manifest(2)
    legacy["components"][0]["name"] = "unknown/file.txt"

    converted = helper.convert_legacy_manifest(
        legacy, REPO_ROOT, writer="python", include_decisions=True
    )

    assert converted["manifest"]["components"] == []
    assert converted["manual_decisions"][0]["path"] == "unknown/file.txt"
    assert converted["manual_decisions"][0]["reason"] == "not-in-component-catalog"


@pytest.mark.parametrize(
    ("source", "source_hash"),
    [
        ("template:agents/coder.agent.md", None),
        ("template:Agents/architect.agent.md", None),
        ("", None),
        ("template:any/arbitrary.md", None),
        ("template:agents/architect.agent.md", "sha256:" + ("0" * 64)),
    ],
)
def test_unproven_legacy_source_evidence_remains_manual(
    helper, source: str, source_hash: Optional[str]
) -> None:
    legacy = trusted_legacy_manifest(2)
    legacy["components"][0]["source"] = source
    if source_hash is not None:
        legacy["components"][0]["source_hash"] = source_hash

    converted = helper.convert_legacy_manifest(
        legacy, REPO_ROOT, writer="python", include_decisions=True
    )

    assert converted["manifest"]["components"] == []
    assert converted["manual_decisions"][0]["path"] == "agents/architect.agent.md"


def test_candidate_binds_exact_production_catalog(helper, catalog: dict) -> None:
    candidate = helper.convert_legacy_manifest(
        trusted_legacy_manifest(2), REPO_ROOT, writer="python"
    )
    binding = candidate["source_release"]["component_catalog"]

    assert binding == {
        "path": "manifest/component-catalog.json",
        "schema_version": catalog["catalog_schema_version"],
        "sha256": sha256(CATALOG_PATH.read_bytes()),
    }
    assert candidate["components"][0]["hashes"]["proposed_source"] == sha256(
        (REPO_ROOT / "agents" / "architect.agent.md").read_bytes()
    )
    assert (
        candidate["components"][0]["hashes"]["proposed_source"]
        != trusted_legacy_manifest(2)["components"][0]["source_hash"]
    )
    helper.validate_candidate(candidate, REPO_ROOT)


def test_customized_legacy_record_preserves_fresh_observed_hash(helper) -> None:
    legacy = trusted_legacy_manifest(2)
    customized_hash = sha256(b"customized adopter bytes\n")
    legacy["components"][0]["observed_hash"] = customized_hash

    candidate = helper.convert_legacy_manifest(
        legacy, REPO_ROOT, writer="python"
    )
    component = candidate["components"][0]

    assert component["provenance"]["fork"]["status"] == "customized"
    assert component["provenance"]["fork"]["decision"] == "preserve"
    assert component["hashes"]["observed_before"] == customized_hash
    assert component["hashes"]["result_after"] == customized_hash
    assert component["hashes"]["proposed_source"] == sha256(
        (REPO_ROOT / "agents" / "architect.agent.md").read_bytes()
    )


def test_tampered_catalog_binding_is_rejected(helper) -> None:
    candidate = helper.convert_legacy_manifest(
        trusted_legacy_manifest(2), REPO_ROOT, writer="python"
    )
    candidate["source_release"]["component_catalog"]["sha256"] = "sha256:" + ("0" * 64)

    with pytest.raises(ValueError, match="(?i)catalog"):
        helper.validate_candidate(candidate, REPO_ROOT)


def test_normal_writers_remain_v2_and_do_not_dispatch_rehearsal() -> None:
    python_bootstrap = (REPO_ROOT / "scripts" / "bootstrap.py").read_text(encoding="utf-8")
    powershell_bootstrap = (REPO_ROOT / "scripts" / "bootstrap.ps1").read_text(
        encoding="utf-8-sig"
    )

    assert '"schema_version": 2' in python_bootstrap
    assert "schema_version = 2" in powershell_bootstrap
    assert "manifest_migration_rehearsal" not in python_bootstrap
    assert "manifest-migration-rehearsal" not in powershell_bootstrap


def test_python_helper_is_not_a_windows_rehearsal_launcher() -> None:
    source = HELPER_PATH.read_text(encoding="utf-8")

    assert "subprocess" not in source
    assert "powershell.exe" not in source.lower()
    assert "pwsh.exe" not in source.lower()
