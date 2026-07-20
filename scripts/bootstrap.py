#!/usr/bin/env python3
"""
Python fallback bootstrap installer for the AI development workflow.

This script mirrors the PowerShell version: it detects required tooling,
copies workflow files from the template repository, and initializes Git if
needed. It is intended for macOS and Linux environments where PowerShell may
not be available.
"""

from __future__ import annotations

import argparse
import hashlib
import json
import os
import re
import shutil
import subprocess
import sys
from dataclasses import dataclass
from datetime import datetime
from pathlib import Path
from typing import Any, Dict, List, Optional, Sequence, Set, Tuple, Union

if __package__ in {None, ""}:
    sys.path.insert(0, str(Path(__file__).resolve().parent.parent))

MIN_GIT = "2.0.0"
MIN_PYTHON = "3.7.0"
MIN_POWERSHELL = "5.1.0"
MIN_NODE = "16.0.0"
MIN_GHCLI = "2.0.0"
EXCLUDE_PATTERNS = {"workflows", "CODEOWNERS", "dependabot.yml"}
LEGACY_RUNTIME_EXCLUDES = EXCLUDE_PATTERNS | {"skills", "agents"}
PORTABLE_RUNTIME_PATHS = [
    ".github",
    "skills",
    "agents",
    ".claude",
    ".codex",
    ".agent",
    ".agents",
    "AGENTS.md",
    "CLAUDE.md",
    "GEMINI.md",
    "WORKFLOW.md",
    "changes/_template",
    ".ai-workflow-install.json",
]
PORTABLE_BACKUP_PATHS = [path for path in PORTABLE_RUNTIME_PATHS if path != ".github"]
PORTABLE_SKILL_LINKS = [
    Path(".agents/skills"),
    Path(".claude/skills"),
    Path(".agent/skills"),
]
MANIFEST_FILENAME = ".ai-workflow-install.json"
SUPPORTED_MANIFEST_SCHEMA_VERSIONS = (1, 2, 3)
PRODUCTION_MANIFEST_SCHEMA = Path("schemas/ai-workflow-install-manifest-v3.schema.json")
COMPONENT_CATALOG_PATH = Path("manifest/component-catalog.json")
COMPONENT_CATALOG_SCHEMA_VERSION = 1
COMPONENT_CATALOG_RELEASE_ID = "ai-dev-workflow:component-catalog:1"
COMPONENT_CATALOG_VERSION = "1"
LIFECYCLE_TEMPLATE_FILES = (
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


@dataclass
class CheckResult:
    installed: bool
    version: Optional[str]
    meets_requirement: bool


@dataclass
class SyncResult:
    files_added: List[str]
    files_updated: List[str]
    files_skipped: List[str]
    files_conflicted: List[str]


@dataclass
class BackupResult:
    success: bool
    backup_path: Optional[str]
    message: str


@dataclass
class GitInitResult:
    is_new: bool
    git_dir: str
    message: str


@dataclass
class ManifestLoadResult:
    state: str
    entries: Dict[str, dict]
    schema_version: Optional[int]
    detail: Optional[str]
    manifest_path: Path
    diagnostic_category: Optional[str] = None
    catalog_validated: bool = False


class ManifestValidationError(ValueError):
    def __init__(self, category: str, detail: str) -> None:
        super().__init__(detail)
        self.category = category
        self.detail = detail


def version_to_tuple(version: str) -> Tuple[int, int, int]:
    parts = [int(part) for part in version.split(".") if part.isdigit()]
    while len(parts) < 3:
        parts.append(0)
    return tuple(parts[:3])


def is_version_ge(current: str, minimum: str) -> bool:
    return version_to_tuple(current) >= version_to_tuple(minimum)


def extract_version(text: str, pattern: str) -> Optional[str]:
    match = re.search(pattern, text)
    return match.group(1) if match else None


def run_command(command: Sequence[str]) -> Optional[str]:
    try:
        result = subprocess.run(
            command, capture_output=True, text=True, check=False
        )
        output = result.stdout.strip() or result.stderr.strip()
        return output or None
    except (OSError, FileNotFoundError):
        return None


def check_tool(command: Sequence[str], regex: str, minimum: str) -> CheckResult:
    output = run_command(command)
    if not output:
        return CheckResult(False, None, False)
    version = extract_version(output, regex)
    if not version:
        return CheckResult(False, None, False)
    meets = is_version_ge(version, minimum)
    return CheckResult(True, version, meets)


def check_git_installed() -> CheckResult:
    return check_tool(["git", "--version"], r"git version (\d+\.\d+\.\d+)", MIN_GIT)


def check_python_version() -> CheckResult:
    version = f"{sys.version_info.major}.{sys.version_info.minor}.{sys.version_info.micro}"
    meets = is_version_ge(version, MIN_PYTHON)
    return CheckResult(True, version, meets)


def check_powershell_version() -> CheckResult:
    output = run_command(["pwsh", "--version"])
    if not output:
        output = run_command(
            ["powershell", "-NoLogo", "-Command", "$PSVersionTable.PSVersion.ToString()"]
        )
    if not output:
        return CheckResult(False, None, False)
    version = extract_version(output, r"(\d+\.\d+\.\d+)")
    if not version:
        return CheckResult(False, None, False)
    meets = is_version_ge(version, MIN_POWERSHELL)
    return CheckResult(True, version, meets)


def check_node_installed() -> CheckResult:
    return check_tool(["node", "--version"], r"v?(\d+\.\d+\.\d+)", MIN_NODE)


def check_github_cli_installed() -> CheckResult:
    output = run_command(["gh", "--version"])
    if not output:
        return CheckResult(False, None, False)
    first_line = output.splitlines()[0]
    version = extract_version(first_line, r"gh version (\d+\.\d+\.\d+)")
    if not version:
        return CheckResult(False, None, False)
    meets = is_version_ge(version, MIN_GHCLI)
    return CheckResult(True, version, meets)


def write_check(
    name: str,
    result: CheckResult,
    install_url: Optional[str] = None,
    recommended: Optional[str] = None,
) -> None:
    """Print environment check result with safe encoding."""
    if result.installed and result.version:
        if result.meets_requirement:
            safe_print(f"✅ {name} {result.version} detected")
        else:
            suffix = f" (建議 >= {recommended})" if recommended else ""
            safe_print(f"⚠️  {name} {result.version}{suffix}")
            if install_url:
                print(f"   Install: {install_url}")
    else:
        safe_print(f"❌ {name} 未安裝")
        if install_url:
            print(f"   請安裝: {install_url}")


def merge_sync_results(*results: SyncResult) -> SyncResult:
    merged = SyncResult([], [], [], [])
    for result in results:
        merged.files_added.extend(result.files_added)
        merged.files_updated.extend(result.files_updated)
        merged.files_skipped.extend(result.files_skipped)
        merged.files_conflicted.extend(result.files_conflicted)
    return merged


def normalize_relative_path(path: Union[Path, str]) -> str:
    """Normalize separators and complete leading ./ segments.

    This function normalizes representation only. It is not a path traversal
    sanitizer and intentionally preserves parent segments such as ../.
    """
    normalized = str(path).replace("\\", "/")
    while normalized.startswith("./"):
        normalized = normalized[2:]
    return normalized


def should_exclude_relative(relative: Path, excludes: Sequence[str]) -> bool:
    normalized = normalize_relative_path(relative).lower()
    parts = normalized.split("/")
    for pattern in excludes:
        candidate = normalize_relative_path(pattern).lower().strip("/")
        if "/" in candidate:
            if normalized.startswith(candidate):
                return True
        elif candidate in {"codeowners", "dependabot.yml"}:
            if parts[-1] == candidate:
                return True
        elif candidate in parts:
            return True
    return False


def hash_bytes(content: bytes) -> str:
    return f"sha256:{hashlib.sha256(content).hexdigest()}"


def normalize_text_content(content: str) -> str:
    return content if content.endswith("\n") else f"{content}\n"


def get_path_hash(path: Path) -> Optional[str]:
    if not path.exists() or path.is_dir():
        return None
    return f"sha256:{calculate_file_hash(path)}"


_COMPONENT_ID_PATTERN = re.compile(r"^cmp:[a-z0-9][a-z0-9._-]{2,127}$")
_TRANSACTION_ID_PATTERN = re.compile(r"^txn:[a-z0-9][a-z0-9._-]{2,127}$")
_HASH_PATTERN = re.compile(r"^sha256:[0-9a-f]{64}$")
_TIMESTAMP_PATTERN = re.compile(
    r"^(\d{4})-(\d{2})-(\d{2})T(\d{2}):(\d{2}):(\d{2})(?:\.(\d{1,9}))?Z$"
)
_RELATIVE_PATH_PATTERN = re.compile(r"^[A-Za-z0-9@+_.-]+(?:/[A-Za-z0-9@+_.-]+)*$")
_WINDOWS_RESERVED_NAMES = {
    "con", "prn", "aux", "nul",
    *(f"com{index}" for index in range(1, 10)),
    *(f"lpt{index}" for index in range(1, 10)),
}
_FORK_MAPPING = {
    "untouched": ("verified-managed-equality", "manage"),
    "customized": ("hash-divergence", "preserve"),
    "project-owned": ("explicit-project-ownership", "preserve"),
    "legacy": ("legacy-import", "report-only"),
    "unknown": ("missing-lineage", "report-only"),
    "derived-customized": ("derived-hash-divergence", "preserve"),
    "conflicted": ("conflicting-evidence", "block"),
    "not-applicable": ("hash-not-applicable", "report-only"),
}
_ROLE_OWNERSHIP = {
    "canonical": "template-managed",
    "generated": "derived-runtime",
    "project-owned": "project-owned",
    "compatibility": "legacy-compat",
}


def _validation_error(category: str, detail: str) -> None:
    raise ManifestValidationError(category, detail)


def _exact_object(
    value: Any, expected_keys: Set[str], category: str, label: str
) -> Dict[str, Any]:
    if not isinstance(value, dict):
        _validation_error(category, f"{label} must be an object.")
    observed = set(value)
    if observed != expected_keys:
        missing = sorted(expected_keys - observed)
        unknown = sorted(observed - expected_keys)
        _validation_error(
            category,
            f"{label} has invalid properties; missing={missing}, unknown={unknown}.",
        )
    return value


def _validate_component_id(value: Any, category: str, label: str) -> str:
    if not isinstance(value, str) or not _COMPONENT_ID_PATTERN.fullmatch(value):
        _validation_error(category, f"{label} is not a valid component ID.")
    return value


def _validate_optional_component_id(value: Any, category: str, label: str) -> Optional[str]:
    if value is None:
        return None
    return _validate_component_id(value, category, label)


def _validate_relative_path(value: Any, category: str, label: str) -> str:
    if not isinstance(value, str) or not value or len(value) > 512:
        _validation_error(category, f"{label} must be a non-empty relative path.")
    if (
        not _RELATIVE_PATH_PATTERN.fullmatch(value)
        or value.startswith("/")
        or "\\" in value
        or ":" in value
        or "//" in value
    ):
        _validation_error(category, f"{label} contains unsafe path syntax.")
    for segment in value.split("/"):
        if segment in {".", ".."} or segment.endswith((".", " ")):
            _validation_error(category, f"{label} contains an unsafe path segment.")
        base_name = segment.split(".", 1)[0].lower()
        if base_name in _WINDOWS_RESERVED_NAMES:
            _validation_error(category, f"{label} contains a Windows reserved name.")
    return value


def _validate_hash(value: Any, category: str, label: str) -> Optional[str]:
    if value is None:
        return None
    if not isinstance(value, str) or not _HASH_PATTERN.fullmatch(value):
        _validation_error(category, f"{label} must be null or a lowercase SHA-256 digest.")
    return value


def _timestamp_key(value: Any, category: str, label: str) -> Tuple[int, ...]:
    if not isinstance(value, str):
        _validation_error(category, f"{label} must be a UTC timestamp.")
    match = _TIMESTAMP_PATTERN.fullmatch(value)
    if not match:
        _validation_error(category, f"{label} must use canonical UTC Z syntax.")
    parts = [int(part) for part in match.groups()[:6]]
    fraction = (match.group(7) or "").ljust(9, "0")
    try:
        datetime(*parts)
    except ValueError:
        _validation_error(category, f"{label} is not a real calendar timestamp.")
    return tuple(parts + [int(fraction or "0")])


def _validate_sorted_unique_strings(
    value: Any,
    category: str,
    label: str,
    *,
    component_ids: bool = False,
    paths: bool = False,
    max_items: int = 64,
) -> List[str]:
    if not isinstance(value, list) or len(value) > max_items:
        _validation_error(category, f"{label} must be an array with at most {max_items} items.")
    if any(not isinstance(item, str) for item in value):
        _validation_error(category, f"{label} must contain only strings.")
    if value != sorted(value) or len(set(value)) != len(value):
        _validation_error(category, f"{label} must be sorted and duplicate-free.")
    for item in value:
        if component_ids:
            _validate_component_id(item, category, label)
        if paths:
            _validate_relative_path(item, category, label)
    return value


def _reject_relationship_cycles(
    records: Dict[str, Dict[str, Any]], category: str, *, catalog: bool
) -> None:
    graph: Dict[str, List[str]] = {}
    for component_id, record in records.items():
        if catalog:
            edges = list(record["generated_from"])
            edges.extend(
                candidate
                for candidate in (
                    record["successor_component_id"],
                    record["reintroduces_component_id"],
                )
                if candidate is not None
            )
        else:
            edges = list(record["provenance"]["generated_from"])
            lifecycle = record["lifecycle"]
            if lifecycle["reintroduces_component_id"] is not None:
                edges.append(lifecycle["reintroduces_component_id"])
            retirement = lifecycle["retirement"]
            if retirement is not None and retirement["successor_component_id"] is not None:
                edges.append(retirement["successor_component_id"])
        graph[component_id] = edges

    visiting: Set[str] = set()
    visited: Set[str] = set()

    def visit(node: str) -> None:
        if node in visiting:
            _validation_error(category, "Component relationship graph contains a cycle.")
        if node in visited:
            return
        visiting.add(node)
        for child in graph.get(node, []):
            visit(child)
        visiting.remove(node)
        visited.add(node)

    for component_id in sorted(graph):
        visit(component_id)


def _load_and_validate_component_catalog(
    source_root: Path,
) -> Tuple[Dict[str, Any], Dict[str, Dict[str, Any]], bytes]:
    catalog_path = source_root / COMPONENT_CATALOG_PATH
    try:
        catalog_bytes = catalog_path.read_bytes()
    except OSError:
        _validation_error("catalog-missing", f"Component Catalog is unavailable: {catalog_path}")
    try:
        catalog = json.loads(catalog_bytes.decode("utf-8"))
    except (UnicodeDecodeError, json.JSONDecodeError):
        _validation_error("catalog-json", "Component Catalog is not valid UTF-8 JSON.")

    catalog = _exact_object(
        catalog,
        {"catalog_schema_version", "catalog_version", "source_release", "components"},
        "catalog-schema",
        "Component Catalog",
    )
    if (
        type(catalog["catalog_schema_version"]) is not int
        or catalog["catalog_schema_version"] != COMPONENT_CATALOG_SCHEMA_VERSION
    ):
        _validation_error("catalog-schema", "Unsupported Component Catalog schema version.")
    if catalog["catalog_version"] != COMPONENT_CATALOG_VERSION:
        _validation_error("catalog-release", "Unexpected Component Catalog version.")
    source_release = _exact_object(
        catalog["source_release"],
        {"release_id", "source_ref", "version"},
        "catalog-schema",
        "Component Catalog source_release",
    )
    if source_release != {
        "release_id": COMPONENT_CATALOG_RELEASE_ID,
        "source_ref": COMPONENT_CATALOG_PATH.as_posix(),
        "version": COMPONENT_CATALOG_VERSION,
    }:
        _validation_error("catalog-release", "Unexpected Component Catalog release identity.")
    if not isinstance(catalog["components"], list) or len(catalog["components"]) > 10000:
        _validation_error("catalog-schema", "Component Catalog components must be an array.")

    records: Dict[str, Dict[str, Any]] = {}
    active_path_keys: Set[str] = set()
    component_order: List[str] = []
    required = {
        "id", "canonical_source_path", "role", "kind", "lifecycle_status",
        "previous_paths", "generated_from", "successor_component_id",
        "reintroduces_component_id", "introduced_release", "retired_release",
    }
    for index, raw_component in enumerate(catalog["components"]):
        component = _exact_object(
            raw_component, required, "catalog-schema", f"Catalog component {index}"
        )
        component_id = _validate_component_id(component["id"], "catalog-schema", "Catalog component ID")
        if component_id in records:
            _validation_error("catalog-duplicate-id", f"Duplicate Catalog ID: {component_id}")
        component_order.append(component_id)
        path = _validate_relative_path(
            component["canonical_source_path"], "catalog-schema", "Catalog canonical_source_path"
        )
        if component["role"] not in _ROLE_OWNERSHIP:
            _validation_error("catalog-schema", "Catalog component role is invalid.")
        if component["kind"] not in {"file", "directory", "mount", "link"}:
            _validation_error("catalog-schema", "Catalog component kind is invalid.")
        if component["lifecycle_status"] not in {"active", "retired", "tombstoned"}:
            _validation_error("catalog-lifecycle", "Catalog lifecycle_status is invalid.")
        _validate_sorted_unique_strings(
            component["previous_paths"], "catalog-schema", "Catalog previous_paths", paths=True
        )
        _validate_sorted_unique_strings(
            component["generated_from"], "catalog-schema", "Catalog generated_from",
            component_ids=True, max_items=10000,
        )
        _validate_optional_component_id(
            component["successor_component_id"], "catalog-reference", "Catalog successor_component_id"
        )
        _validate_optional_component_id(
            component["reintroduces_component_id"], "catalog-reference", "Catalog reintroduces_component_id"
        )
        if component["introduced_release"] != COMPONENT_CATALOG_RELEASE_ID:
            _validation_error("catalog-release", "Catalog introduced_release is invalid.")
        if component["lifecycle_status"] == "active":
            if component["retired_release"] is not None:
                _validation_error("catalog-lifecycle", "Active Catalog identity cannot be retired.")
            if component["successor_component_id"] is not None:
                _validation_error("catalog-lifecycle", "Active Catalog identity cannot declare a successor.")
            path_key = path.lower()
            if path_key in active_path_keys:
                _validation_error("catalog-duplicate-active-path", f"Duplicate active Catalog path: {path}")
            active_path_keys.add(path_key)
        elif not isinstance(component["retired_release"], str) or not component["retired_release"]:
            _validation_error("catalog-lifecycle", "Retired Catalog identity needs retired_release.")
        if component["lifecycle_status"] != "active" and component["reintroduces_component_id"] is not None:
            _validation_error("catalog-lifecycle", "Terminal Catalog identity cannot reintroduce another ID.")
        if component["role"] == "generated":
            if not component["generated_from"]:
                _validation_error("catalog-reference", "Generated Catalog identity needs a parent.")
        elif component["generated_from"]:
            _validation_error("catalog-reference", "Non-generated Catalog identity cannot have parents.")
        if component["kind"] in {"mount", "link"} and component["role"] != "generated":
            _validation_error(
                "catalog-role-kind",
                "Catalog mount/link identities must be generated and parent-bound.",
            )
        records[component_id] = component

    if component_order != sorted(component_order):
        _validation_error("catalog-schema", "Component Catalog records must be sorted by ID.")
    for component_id, component in records.items():
        references = list(component["generated_from"])
        references.extend(
            value
            for value in (
                component["successor_component_id"], component["reintroduces_component_id"]
            )
            if value is not None
        )
        for reference in references:
            if reference == component_id:
                _validation_error("catalog-self-reference", f"Catalog ID self-references: {component_id}")
            if reference not in records:
                _validation_error("catalog-reference", f"Unknown Catalog reference: {reference}")
        reintroduced = component["reintroduces_component_id"]
        if reintroduced is not None:
            if component["lifecycle_status"] != "active" or records[reintroduced]["lifecycle_status"] != "tombstoned":
                _validation_error("catalog-lifecycle", "Catalog reintroduction must target a tombstone.")
    _reject_relationship_cycles(records, "catalog-cycle", catalog=True)
    return catalog, records, catalog_bytes


def _validate_v3_source_release(value: Any) -> Dict[str, Any]:
    source_release = _exact_object(
        value,
        {"release_id", "source_ref", "version", "component_catalog"},
        "manifest-schema",
        "Manifest source_release",
    )
    for key, maximum in (("release_id", 128), ("source_ref", 256), ("version", 64)):
        observed = source_release[key]
        if not isinstance(observed, str) or not observed or len(observed) > maximum:
            _validation_error("manifest-schema", f"Manifest source_release.{key} is invalid.")
    binding = _exact_object(
        source_release["component_catalog"],
        {"path", "schema_version", "sha256"},
        "manifest-schema",
        "Manifest component_catalog binding",
    )
    if binding["path"] != COMPONENT_CATALOG_PATH.as_posix():
        _validation_error("catalog-release", "Manifest binds an unexpected Component Catalog path.")
    if (
        type(binding["schema_version"]) is not int
        or binding["schema_version"] != COMPONENT_CATALOG_SCHEMA_VERSION
    ):
        _validation_error("catalog-release", "Manifest binds an unsupported Component Catalog schema.")
    _validate_hash(binding["sha256"], "catalog-digest", "Manifest Component Catalog digest")
    return source_release


def _validate_v3_transaction(value: Any) -> Dict[str, Any]:
    transaction = _exact_object(
        value,
        {"id", "mode", "writer", "started_at", "completed_at", "result"},
        "manifest-schema",
        "Manifest last_transaction",
    )
    transaction_id = transaction["id"]
    if not isinstance(transaction_id, str) or not _TRANSACTION_ID_PATTERN.fullmatch(transaction_id):
        _validation_error("manifest-schema", "Manifest transaction ID is invalid.")
    if transaction["mode"] not in {"install", "update", "migration"}:
        _validation_error("manifest-schema", "Manifest transaction mode is invalid.")
    if transaction["writer"] not in {"python", "powershell"}:
        _validation_error("manifest-schema", "Manifest transaction writer is invalid.")
    if transaction["result"] != "committed":
        _validation_error("manifest-schema", "Manifest transaction must be committed.")
    started = _timestamp_key(transaction["started_at"], "manifest-timestamp", "Transaction started_at")
    completed = _timestamp_key(transaction["completed_at"], "manifest-timestamp", "Transaction completed_at")
    if started > completed:
        _validation_error("manifest-timestamp", "Transaction completed_at precedes started_at.")
    return transaction


def _validate_v3_link(value: Any, kind: str) -> Optional[Dict[str, Any]]:
    if kind not in {"mount", "link"}:
        if value is not None:
            _validation_error("manifest-link", "Only mount/link identities may contain link metadata.")
        return None
    link = _exact_object(
        value,
        {"target_path", "target_path_key", "mode"},
        "manifest-link",
        "Manifest identity.link",
    )
    target_path = _validate_relative_path(
        link["target_path"], "manifest-link", "Manifest link target_path"
    )
    if link["target_path_key"] != target_path.lower():
        _validation_error("manifest-link", "Manifest link target_path_key does not match target_path.")
    if link["mode"] not in {"symlink", "junction", "copy-fallback"}:
        _validation_error("manifest-link", "Manifest link mode is invalid.")
    if kind == "link" and link["mode"] != "symlink":
        _validation_error("manifest-link", "A link identity must use symlink mode.")
    return link


def _validate_v3_fork(value: Any) -> Dict[str, Any]:
    fork = _exact_object(
        value,
        {"status", "basis", "decision", "classified_at"},
        "manifest-schema",
        "Manifest provenance.fork",
    )
    expected = _FORK_MAPPING.get(fork["status"])
    if expected is None or (fork["basis"], fork["decision"]) != expected:
        _validation_error("manifest-fork", "Manifest fork status/basis/decision mapping is invalid.")
    _timestamp_key(fork["classified_at"], "manifest-timestamp", "Fork classified_at")
    return fork


def _validate_v3_provenance(value: Any, role: str, kind: str) -> Dict[str, Any]:
    provenance = _exact_object(
        value,
        {"ownership", "source", "generated_from", "fork"},
        "manifest-schema",
        "Manifest provenance",
    )
    if provenance["ownership"] != _ROLE_OWNERSHIP[role]:
        _validation_error("manifest-provenance", "Manifest role and ownership disagree.")
    source = _exact_object(
        provenance["source"],
        {"kind", "locator", "release"},
        "manifest-schema",
        "Manifest provenance.source",
    )
    source_kind = source["kind"]
    expected_source_kind = {
        "canonical": "template",
        "generated": "generated",
        "project-owned": "project",
        "compatibility": "legacy",
    }[role]
    if source_kind != expected_source_kind:
        _validation_error("manifest-provenance", "Manifest role and source kind disagree.")
    locator = source["locator"]
    if (
        not isinstance(locator, str)
        or len(locator) < 3
        or len(locator) > 512
        or not re.fullmatch(r"(?:template|project|generated|legacy|unknown):[A-Za-z0-9@+_.:/#-]+", locator)
        or not locator.startswith(f"{source_kind}:")
        or "\\" in locator
        or locator.split(":", 1)[1].startswith("/")
        or re.match(r"^[A-Za-z]:/", locator.split(":", 1)[1])
        or "://" in locator.split(":", 1)[1]
        or any(part in {".", ".."} for part in locator.split(":", 1)[1].split("/"))
    ):
        _validation_error("manifest-provenance", "Manifest source locator is unsafe or inconsistent.")
    if source["release"] is not None and (
        not isinstance(source["release"], str) or not source["release"] or len(source["release"]) > 128
    ):
        _validation_error("manifest-schema", "Manifest source release is invalid.")
    generated_from = _validate_sorted_unique_strings(
        provenance["generated_from"],
        "manifest-provenance",
        "Manifest generated_from",
        component_ids=True,
    )
    if role == "generated" and not generated_from:
        _validation_error("manifest-provenance", "Generated Manifest component needs a parent.")
    if role != "generated" and generated_from:
        _validation_error("manifest-provenance", "Non-generated Manifest component cannot have parents.")
    fork = _validate_v3_fork(provenance["fork"])
    if fork["status"] == "project-owned" and role != "project-owned":
        _validation_error("manifest-fork", "Project-owned fork status requires project-owned role.")
    if fork["status"] == "legacy" and role != "compatibility":
        _validation_error("manifest-fork", "Legacy fork status requires compatibility role.")
    if fork["status"] == "derived-customized" and role != "generated":
        _validation_error("manifest-fork", "Derived customization requires generated role.")
    if fork["status"] == "customized" and role != "canonical":
        _validation_error("manifest-fork", "Canonical customization requires canonical role.")
    if fork["status"] == "not-applicable" and kind == "file":
        _validation_error("manifest-fork", "A regular file cannot use not-applicable hash status.")
    return provenance


def _validate_v3_hashes(value: Any, fork: Dict[str, Any], kind: str) -> Dict[str, Any]:
    hashes = _exact_object(
        value,
        {"algorithm", "content_basis", "baseline", "observed_before", "proposed_source", "result_after"},
        "manifest-schema",
        "Manifest hashes",
    )
    if hashes["algorithm"] != "sha256" or hashes["content_basis"] != "exact-bytes":
        _validation_error("manifest-hash", "Manifest hash algorithm/content basis is invalid.")
    for key in ("baseline", "observed_before", "proposed_source", "result_after"):
        _validate_hash(hashes[key], "manifest-hash", f"Manifest hashes.{key}")
    status = fork["status"]
    if status == "untouched":
        if hashes["baseline"] is None or hashes["baseline"] != hashes["observed_before"]:
            _validation_error("manifest-fork", "Untouched classification needs equal known baseline and observation.")
    if status in {"customized", "derived-customized"}:
        if (
            hashes["baseline"] is None
            or hashes["observed_before"] is None
            or hashes["baseline"] == hashes["observed_before"]
        ):
            _validation_error("manifest-fork", "Customization classification needs known divergent hashes.")
    if kind in {"mount", "directory", "link"} and status == "not-applicable":
        if any(hashes[key] is not None for key in hashes if key not in {"algorithm", "content_basis"}):
            _validation_error("manifest-hash", "Non-hashable component cannot claim content hashes.")
    return hashes


def _validate_v3_retirement(value: Any) -> Dict[str, Any]:
    retirement = _exact_object(
        value,
        {"reason", "detected_at", "source_evidence", "successor_component_id", "pruned_at"},
        "manifest-schema",
        "Manifest retirement",
    )
    if retirement["reason"] not in {"renamed", "deleted", "source-retired", "superseded"}:
        _validation_error("manifest-lifecycle", "Manifest retirement reason is invalid.")
    _timestamp_key(retirement["detected_at"], "manifest-timestamp", "Retirement detected_at")
    evidence = _exact_object(
        retirement["source_evidence"],
        {"type", "locator"},
        "manifest-schema",
        "Manifest retirement source_evidence",
    )
    if evidence["type"] not in {"rename-map", "component-absent-in-source", "release-retirement-record"}:
        _validation_error("manifest-lifecycle", "Manifest retirement evidence type is invalid.")
    if not isinstance(evidence["locator"], str) or not re.fullmatch(
        r"(?:template|release):[A-Za-z0-9@+_.:/#-]+", evidence["locator"]
    ):
        _validation_error("manifest-lifecycle", "Manifest retirement evidence locator is invalid.")
    _validate_optional_component_id(
        retirement["successor_component_id"], "manifest-lifecycle", "Retirement successor_component_id"
    )
    if retirement["pruned_at"] is not None:
        _timestamp_key(retirement["pruned_at"], "manifest-timestamp", "Retirement pruned_at")
    return retirement


def _validate_v3_lifecycle(value: Any, hashes: Dict[str, Any], outcome: str) -> Dict[str, Any]:
    lifecycle = _exact_object(
        value,
        {"state", "previous_paths", "retirement", "reintroduces_component_id"},
        "manifest-schema",
        "Manifest lifecycle",
    )
    state = lifecycle["state"]
    if state not in {"active", "retired", "tombstoned"}:
        _validation_error("manifest-lifecycle", "Manifest lifecycle state is invalid.")
    _validate_sorted_unique_strings(
        lifecycle["previous_paths"], "manifest-path", "Manifest previous_paths", paths=True
    )
    reintroduces = _validate_optional_component_id(
        lifecycle["reintroduces_component_id"],
        "manifest-reintroduction",
        "Manifest reintroduces_component_id",
    )
    if state == "active":
        if lifecycle["retirement"] is not None:
            _validation_error("manifest-lifecycle", "Active Manifest component cannot have retirement data.")
    else:
        if not isinstance(lifecycle["retirement"], dict):
            _validation_error("manifest-lifecycle", "Terminal Manifest component needs retirement data.")
        retirement = _validate_v3_retirement(lifecycle["retirement"])
        if reintroduces is not None:
            _validation_error("manifest-reintroduction", "Terminal Manifest component cannot reintroduce an ID.")
        if hashes["proposed_source"] is not None:
            _validation_error("manifest-lifecycle", "Terminal Manifest component cannot have proposed source bytes.")
        if state == "retired":
            if retirement["pruned_at"] is not None or outcome != "retired":
                _validation_error("manifest-lifecycle", "Retired Manifest component has invalid terminal evidence.")
        elif retirement["pruned_at"] is None or hashes["result_after"] is not None or outcome != "tombstoned":
            _validation_error("manifest-lifecycle", "Tombstoned Manifest component has invalid terminal evidence.")
    return lifecycle


def _validate_v3_component(value: Any, index: int) -> Dict[str, Any]:
    component = _exact_object(
        value,
        {"identity", "provenance", "hashes", "lifecycle", "last_operation", "installed_at", "updated_at"},
        "manifest-schema",
        f"Manifest component {index}",
    )
    identity = _exact_object(
        component["identity"],
        {"id", "path", "path_key", "kind", "role", "link"},
        "manifest-schema",
        "Manifest identity",
    )
    _validate_component_id(identity["id"], "manifest-schema", "Manifest component ID")
    path = _validate_relative_path(identity["path"], "manifest-path", "Manifest identity.path")
    if identity["path_key"] != path.lower():
        _validation_error("manifest-path", "Manifest identity.path_key does not match identity.path.")
    if identity["kind"] not in {"file", "directory", "mount", "link"}:
        _validation_error("manifest-schema", "Manifest identity kind is invalid.")
    if identity["role"] not in _ROLE_OWNERSHIP:
        _validation_error("manifest-schema", "Manifest identity role is invalid.")
    if identity["kind"] in {"mount", "link"} and identity["role"] != "generated":
        _validation_error(
            "manifest-role-kind",
            "Manifest mount/link identities must be generated and parent-bound.",
        )
    _validate_v3_link(identity["link"], identity["kind"])
    provenance = _validate_v3_provenance(component["provenance"], identity["role"], identity["kind"])
    hashes = _validate_v3_hashes(component["hashes"], provenance["fork"], identity["kind"])
    operation = _exact_object(
        component["last_operation"],
        {"transaction_id", "outcome"},
        "manifest-schema",
        "Manifest last_operation",
    )
    if not isinstance(operation["transaction_id"], str) or not _TRANSACTION_ID_PATTERN.fullmatch(operation["transaction_id"]):
        _validation_error("manifest-schema", "Manifest component transaction ID is invalid.")
    if operation["outcome"] not in {
        "installed", "updated", "preserved-existing", "preserved-customization",
        "conflicted", "reported", "retired", "tombstoned",
    }:
        _validation_error("manifest-schema", "Manifest component outcome is invalid.")
    lifecycle = _validate_v3_lifecycle(component["lifecycle"], hashes, operation["outcome"])
    outcome = operation["outcome"]
    fork_status = provenance["fork"]["status"]
    if outcome in {"installed", "updated"}:
        if hashes["proposed_source"] is None or hashes["result_after"] != hashes["proposed_source"]:
            _validation_error("manifest-hash", "Installed/updated result must equal proposed source bytes.")
    elif outcome == "preserved-customization":
        if fork_status not in {"customized", "derived-customized"} or hashes["result_after"] != hashes["observed_before"]:
            _validation_error("manifest-fork", "Preserved customization evidence is inconsistent.")
    elif outcome == "preserved-existing":
        if hashes["result_after"] != hashes["observed_before"]:
            _validation_error("manifest-hash", "Preserved existing result must equal observed bytes.")
    elif outcome == "conflicted" and fork_status != "conflicted":
        _validation_error("manifest-fork", "Conflicted outcome requires conflicted fork evidence.")
    elif outcome == "retired" and hashes["result_after"] != hashes["observed_before"]:
        _validation_error("manifest-hash", "Retired result must preserve observed bytes.")
    installed = None
    if component["installed_at"] is not None:
        installed = _timestamp_key(component["installed_at"], "manifest-timestamp", "Component installed_at")
    updated = _timestamp_key(component["updated_at"], "manifest-timestamp", "Component updated_at")
    if installed is not None and installed > updated:
        _validation_error("manifest-timestamp", "Component updated_at precedes installed_at.")
    if _timestamp_key(provenance["fork"]["classified_at"], "manifest-timestamp", "Fork classified_at") > updated:
        _validation_error("manifest-timestamp", "Fork classification postdates component update.")
    if lifecycle["retirement"] is not None:
        retirement = lifecycle["retirement"]
        if _timestamp_key(retirement["detected_at"], "manifest-timestamp", "Retirement detected_at") > updated:
            _validation_error("manifest-timestamp", "Retirement detection postdates component update.")
        if retirement["pruned_at"] is not None and _timestamp_key(
            retirement["pruned_at"], "manifest-timestamp", "Retirement pruned_at"
        ) > updated:
            _validation_error("manifest-timestamp", "Prune timestamp postdates component update.")
    return component


def _load_and_validate_production_schema(source_root: Path) -> Dict[str, Any]:
    schema_path = source_root / PRODUCTION_MANIFEST_SCHEMA
    try:
        schema_bytes = schema_path.read_bytes()
    except OSError:
        _validation_error("schema-missing", f"Production Schema is unavailable: {schema_path}")
    try:
        schema = json.loads(schema_bytes.decode("utf-8"))
    except (UnicodeDecodeError, json.JSONDecodeError):
        _validation_error("schema-json", "Production Schema is not valid UTF-8 JSON.")

    def contains_proposal_marker(value: Any) -> bool:
        if isinstance(value, dict):
            return "proposal_status" in value or any(
                contains_proposal_marker(item) for item in value.values()
            )
        if isinstance(value, list):
            return any(contains_proposal_marker(item) for item in value)
        return value == "proposal_status"

    if contains_proposal_marker(schema):
        _validation_error(
            "schema-proposal-marker",
            "Production Schema must not contain proposal_status markers.",
        )
    schema = _exact_object(
        schema,
        {
            "$schema", "$id", "title", "description", "type",
            "additionalProperties", "required", "properties", "$defs",
        },
        "schema-structure",
        "Production Schema",
    )
    if (
        schema["$schema"] != "https://json-schema.org/draft/2020-12/schema"
        or schema["$id"] != "urn:ai-dev-workflow:manifest-schema:v3"
    ):
        _validation_error("schema-identity", "Production Schema identity is invalid.")
    required = [
        "schema_version", "written_at", "source_release", "last_transaction", "components"
    ]
    if (
        schema["type"] != "object"
        or schema["additionalProperties"] is not False
        or schema["required"] != required
        or not isinstance(schema["properties"], dict)
        or set(schema["properties"]) != set(required)
        or not isinstance(schema["$defs"], dict)
    ):
        _validation_error("schema-structure", "Production Schema root structure is invalid.")
    properties = schema["properties"]
    if (
        not isinstance(properties["schema_version"], dict)
        or type(properties["schema_version"].get("const")) is not int
        or properties["schema_version"].get("const") != 3
        or not isinstance(properties["components"], dict)
        or type(properties["components"].get("maxItems")) is not int
        or properties["components"].get("maxItems") != 10000
    ):
        _validation_error("schema-structure", "Production Schema constraints are invalid.")
    required_defs = {
        "timestamp", "hash", "componentId", "relativePath", "pathKey", "sourceRelease",
        "componentCatalogBinding", "transaction", "identity", "link", "source", "fork",
        "provenance", "hashes", "retirement", "lifecycle", "operation", "component",
    }
    if set(schema["$defs"]) != required_defs or any(
        not isinstance(definition, dict) for definition in schema["$defs"].values()
    ):
        _validation_error("schema-structure", "Production Schema definitions are invalid.")
    return schema


def _validate_manifest_v3(
    data: Dict[str, Any], source_root: Optional[Path]
) -> Tuple[Dict[str, dict], bool, Optional[str]]:
    manifest = _exact_object(
        data,
        {"schema_version", "written_at", "source_release", "last_transaction", "components"},
        "manifest-schema",
        "Manifest",
    )
    if manifest["schema_version"] != 3:
        _validation_error("manifest-schema", "Manifest schema version is not 3.")
    written_at = _timestamp_key(manifest["written_at"], "manifest-timestamp", "Manifest written_at")
    source_release = _validate_v3_source_release(manifest["source_release"])
    transaction = _validate_v3_transaction(manifest["last_transaction"])
    if _timestamp_key(transaction["completed_at"], "manifest-timestamp", "Transaction completed_at") > written_at:
        _validation_error("manifest-timestamp", "Manifest was written before its transaction completed.")
    if not isinstance(manifest["components"], list) or len(manifest["components"]) > 10000:
        _validation_error("manifest-schema", "Manifest components must be an array.")

    records: Dict[str, Dict[str, Any]] = {}
    ordered_ids: List[str] = []
    for index, raw_component in enumerate(manifest["components"]):
        component = _validate_v3_component(raw_component, index)
        component_id = component["identity"]["id"]
        if component_id in records:
            _validation_error("manifest-schema", f"Manifest contains duplicate component ID: {component_id}")
        if _timestamp_key(component["updated_at"], "manifest-timestamp", "Component updated_at") > written_at:
            _validation_error("manifest-timestamp", "Component update postdates Manifest write.")
        ordered_ids.append(component_id)
        records[component_id] = component
    if ordered_ids != sorted(ordered_ids):
        _validation_error("manifest-schema", "Manifest components must be sorted by component ID.")

    active_paths: Dict[str, str] = {}
    terminal_paths: Dict[str, List[str]] = {}
    for component_id, component in records.items():
        identity = component["identity"]
        lifecycle = component["lifecycle"]
        path_key = identity["path_key"]
        references = list(component["provenance"]["generated_from"])
        if lifecycle["reintroduces_component_id"] is not None:
            references.append(lifecycle["reintroduces_component_id"])
        if lifecycle["retirement"] is not None and lifecycle["retirement"]["successor_component_id"] is not None:
            references.append(lifecycle["retirement"]["successor_component_id"])
        for reference in references:
            if reference == component_id:
                category = "manifest-reintroduction" if lifecycle["reintroduces_component_id"] == reference else "manifest-provenance"
                _validation_error(category, f"Manifest component self-references: {component_id}")
            if reference not in records:
                category = "manifest-reintroduction" if lifecycle["reintroduces_component_id"] == reference else "manifest-provenance"
                _validation_error(category, f"Manifest reference does not resolve: {reference}")
        reintroduced = lifecycle["reintroduces_component_id"]
        if reintroduced is not None and records[reintroduced]["lifecycle"]["state"] != "tombstoned":
            _validation_error("manifest-reintroduction", "Manifest reintroduction must target a tombstone.")
        if lifecycle["state"] == "active":
            if path_key in active_paths:
                _validation_error("manifest-path-collision", f"Duplicate active Manifest path: {identity['path']}")
            active_paths[path_key] = component_id
        else:
            terminal_paths.setdefault(path_key, []).append(component_id)
    for path_key, active_id in active_paths.items():
        for terminal_id in terminal_paths.get(path_key, []):
            active = records[active_id]
            terminal = records[terminal_id]
            if (
                terminal["lifecycle"]["state"] != "tombstoned"
                or active["lifecycle"]["reintroduces_component_id"] != terminal_id
                or terminal["hashes"]["result_after"] is not None
            ):
                _validation_error("manifest-path-collision", "Manifest path collision lacks valid reintroduction evidence.")
    provenance_only: Dict[str, Dict[str, Any]] = {}
    for component_id, component in records.items():
        projected = dict(component)
        projected_lifecycle = dict(component["lifecycle"])
        projected_lifecycle["reintroduces_component_id"] = None
        if projected_lifecycle["retirement"] is not None:
            projected_retirement = dict(projected_lifecycle["retirement"])
            projected_retirement["successor_component_id"] = None
            projected_lifecycle["retirement"] = projected_retirement
        projected["lifecycle"] = projected_lifecycle
        provenance_only[component_id] = projected
    _reject_relationship_cycles(provenance_only, "manifest-provenance", catalog=False)
    _reject_relationship_cycles(records, "manifest-reintroduction", catalog=False)

    catalog_validated = False
    detail: Optional[str] = None
    if source_root is None:
        inferred = Path(__file__).resolve().parent.parent
        if (
            (inferred / COMPONENT_CATALOG_PATH).is_file()
            and (inferred / PRODUCTION_MANIFEST_SCHEMA).is_file()
        ):
            source_root = inferred
        else:
            detail = "Production Schema and Component Catalog validation are unavailable."
    if source_root is not None:
        _load_and_validate_production_schema(source_root)
        catalog, catalog_records, catalog_bytes = _load_and_validate_component_catalog(source_root)
        binding = source_release["component_catalog"]
        observed_digest = hash_bytes(catalog_bytes)
        if binding["sha256"] != observed_digest:
            _validation_error("catalog-digest", "Manifest Component Catalog digest does not match exact Catalog bytes.")
        if any(source_release[key] != catalog["source_release"][key] for key in ("release_id", "source_ref", "version")):
            _validation_error("catalog-release", "Manifest source release does not match Component Catalog.")
        for component_id, component in records.items():
            catalog_component = catalog_records.get(component_id)
            if catalog_component is None:
                _validation_error("catalog-agreement", f"Manifest component is absent from Catalog: {component_id}")
            identity = component["identity"]
            lifecycle = component["lifecycle"]
            if (
                identity["path"] != catalog_component["canonical_source_path"]
                or identity["role"] != catalog_component["role"]
                or identity["kind"] != catalog_component["kind"]
                or lifecycle["state"] != catalog_component["lifecycle_status"]
                or lifecycle["previous_paths"] != catalog_component["previous_paths"]
                or component["provenance"]["generated_from"] != catalog_component["generated_from"]
                or lifecycle["reintroduces_component_id"] != catalog_component["reintroduces_component_id"]
                or (
                    lifecycle["retirement"] is not None
                    and lifecycle["retirement"]["successor_component_id"] != catalog_component["successor_component_id"]
                )
                or (lifecycle["retirement"] is None and catalog_component["successor_component_id"] is not None)
            ):
                _validation_error("catalog-agreement", f"Manifest component disagrees with Catalog: {component_id}")
            if component["provenance"]["source"]["release"] not in {None, source_release["release_id"]}:
                _validation_error("catalog-agreement", f"Manifest component release disagrees with source release: {component_id}")
        catalog_validated = True
    return records, catalog_validated, detail


def load_install_manifest(
    target_root: Path, source_root: Optional[Path] = None
) -> ManifestLoadResult:
    manifest_path = target_root / MANIFEST_FILENAME
    if not manifest_path.exists():
        return ManifestLoadResult(
            "missing", {}, None, None, manifest_path, "manifest-missing"
        )

    try:
        data = json.loads(manifest_path.read_text(encoding="utf-8"))
    except OSError:
        return ManifestLoadResult(
            "corrupt",
            {},
            None,
            "Manifest could not be read.",
            manifest_path,
            "manifest-read",
        )
    except json.JSONDecodeError:
        return ManifestLoadResult(
            "corrupt",
            {},
            None,
            "Manifest contains invalid JSON syntax.",
            manifest_path,
            "manifest-json",
        )

    if not isinstance(data, dict):
        return ManifestLoadResult(
            "corrupt", {}, None, "Manifest top level must be an object.", manifest_path,
            "manifest-schema",
        )

    schema_version = data.get("schema_version")
    if type(schema_version) is not int:
        return ManifestLoadResult(
            "corrupt",
            {},
            None,
            "Manifest schema_version must be an integer.",
            manifest_path,
            "manifest-schema",
        )
    if schema_version not in SUPPORTED_MANIFEST_SCHEMA_VERSIONS:
        return ManifestLoadResult(
            "unsupported",
            {},
            schema_version,
            f"Schema version {schema_version} is not supported.",
            manifest_path,
            "manifest-version",
        )

    if schema_version == 3:
        try:
            entries, catalog_validated, detail = _validate_manifest_v3(data, source_root)
        except ManifestValidationError as error:
            return ManifestLoadResult(
                "corrupt",
                {},
                schema_version,
                error.detail,
                manifest_path,
                error.category,
            )
        if not catalog_validated:
            return ManifestLoadResult(
                "v3-validation-blocked",
                {},
                schema_version,
                detail,
                manifest_path,
                "catalog-unavailable",
                False,
            )
        return ManifestLoadResult(
            "valid-v3", entries, schema_version, detail, manifest_path,
            "manifest-valid-v3", True,
        )

    components = data.get("components")
    if not isinstance(components, list):
        return ManifestLoadResult(
            "corrupt",
            {},
            schema_version,
            "Manifest components must be an array.",
            manifest_path,
            "manifest-schema",
        )

    manifest_entries: Dict[str, dict] = {}
    for component in components:
        if not isinstance(component, dict):
            return ManifestLoadResult(
                "corrupt",
                {},
                schema_version,
                "Every manifest component must be an object.",
                manifest_path,
                "manifest-schema",
            )
        name = component.get("name")
        if not isinstance(name, str) or not name.strip():
            return ManifestLoadResult(
                "corrupt",
                {},
                schema_version,
                "Every manifest component must have a non-empty string name.",
                manifest_path,
                "manifest-schema",
            )
        if name in manifest_entries:
            return ManifestLoadResult(
                "corrupt",
                {},
                schema_version,
                f"Manifest contains duplicate component name: {name}",
                manifest_path,
                "manifest-schema",
            )
        manifest_entries[name] = component
    return ManifestLoadResult(
        f"valid-v{schema_version}",
        manifest_entries,
        schema_version,
        None,
        manifest_path,
        f"manifest-valid-v{schema_version}",
    )


def enforce_update_manifest_safety(result: ManifestLoadResult) -> bool:
    if result.state in {"valid-v1", "valid-v2"}:
        return True
    if result.state == "valid-v3":
        safe_print(f"❌ Manifest v3 writer/migration is not enabled: {result.manifest_path}")
        print("   The v3 Manifest was recognized read-only and will not be downgraded or overwritten.")
        print("   Operation aborted before backup, directory, file, link, temporary artifact, or Manifest mutation.")
        raise SystemExit(1)
    if result.state == "missing":
        safe_print(
            f"⚠️  Legacy project manifest is missing: {result.manifest_path}"
        )
        print("   Update is report-only because managed-file provenance is unavailable.")
        print("   No files changed; no ownership was inferred and no manifest was created.")
        return False
    if result.state == "unsupported":
        safe_print(f"❌ Unsupported install manifest: {result.manifest_path}")
        print(f"   Observed schema version: {result.schema_version}")
        print(
            "   Supported schema versions: "
            + ", ".join(str(version) for version in SUPPORTED_MANIFEST_SCHEMA_VERSIONS)
        )
        print("   Update aborted before any changes; the manifest was not downgraded or rebuilt.")
        raise SystemExit(1)

    safe_print(f"❌ Corrupt install manifest: {result.manifest_path}")
    print(f"   {result.detail}")
    print("   Update aborted before any changes; the manifest was not deleted or rebuilt.")
    print("   Inspect the manifest manually or restore it from a trusted backup.")
    raise SystemExit(1)


def write_install_manifest(
    target_root: Path,
    source_root: Path,
    manifest_entries: Dict[str, dict],
) -> None:
    source_ref = run_command(
        ["git", "-C", str(source_root), "rev-parse", "--short", "HEAD"]
    )
    ordered_components = [manifest_entries[name] for name in sorted(manifest_entries)]
    manifest = {
        "schema_version": 2,
        "installed_at": datetime.now().astimezone().isoformat(),
        "source_ref": source_ref or "unknown",
        "components": ordered_components,
    }
    (target_root / MANIFEST_FILENAME).write_text(
        json.dumps(manifest, ensure_ascii=False, indent=2) + "\n",
        encoding="utf-8",
    )


def update_manifest_entry(
    manifest_entries: Dict[str, dict],
    relative_path: Path,
    *,
    ownership: str,
    source_label: str,
    kind: str,
    managed_hash: Optional[str],
    observed_hash: Optional[str],
    status: str,
) -> None:
    name = normalize_relative_path(relative_path)
    previous = dict(manifest_entries.get(name, {}))
    previous_installed_at = previous.get("installed_at")
    manifest_entries[name] = {
        "name": name,
        "installed_at": previous_installed_at or datetime.now().astimezone().isoformat(),
        "updated_at": datetime.now().astimezone().isoformat(),
        "source_hash": managed_hash,
        "managed_hash": managed_hash,
        "observed_hash": observed_hash,
        "ownership": ownership,
        "kind": kind,
        "source": source_label,
        "status": status,
    }


def sync_managed_bytes(
    target_file: Path,
    relative_path: Path,
    desired_bytes: bytes,
    result: SyncResult,
    manifest_entries: Dict[str, dict],
    *,
    ownership: str,
    source_label: str,
    force: bool = False,
    always_overwrite: bool = False,
    preserve_untracked: bool = True,
) -> None:
    previous = manifest_entries.get(normalize_relative_path(relative_path), {})
    previous_managed_hash = previous.get("managed_hash") or previous.get("source_hash")
    current_hash = get_path_hash(target_file) if target_file.exists() else None
    desired_hash = hash_bytes(desired_bytes)

    if not target_file.exists():
        target_file.parent.mkdir(parents=True, exist_ok=True)
        target_file.write_bytes(desired_bytes)
        record_managed_path(result, relative_path, "added")
        update_manifest_entry(
            manifest_entries,
            relative_path,
            ownership=ownership,
            source_label=source_label,
            kind="file",
            managed_hash=desired_hash,
            observed_hash=desired_hash,
            status="managed",
        )
        return

    if current_hash == desired_hash:
        record_managed_path(result, relative_path, "skipped")
        update_manifest_entry(
            manifest_entries,
            relative_path,
            ownership=ownership,
            source_label=source_label,
            kind="file",
            managed_hash=desired_hash,
            observed_hash=desired_hash,
            status="in-sync",
        )
        return

    if always_overwrite or force or (
        previous_managed_hash is not None and current_hash == previous_managed_hash
    ):
        target_file.parent.mkdir(parents=True, exist_ok=True)
        target_file.write_bytes(desired_bytes)
        record_managed_path(result, relative_path, "updated")
        update_manifest_entry(
            manifest_entries,
            relative_path,
            ownership=ownership,
            source_label=source_label,
            kind="file",
            managed_hash=desired_hash,
            observed_hash=desired_hash,
            status="managed",
        )
        return

    if preserve_untracked:
        suffix = "[preserved customization]" if previous_managed_hash else "[preserved existing]"
        manifest_status = (
            "preserved-customization" if previous_managed_hash else "preserved-existing"
        )
        record_managed_path(result, relative_path, "skipped", suffix)
        update_manifest_entry(
            manifest_entries,
            relative_path,
            ownership=ownership,
            source_label=source_label,
            kind="file",
            managed_hash=previous_managed_hash,
            observed_hash=current_hash,
            status=manifest_status,
        )
        return

    record_managed_path(result, relative_path, "conflicted")
    update_manifest_entry(
        manifest_entries,
        relative_path,
        ownership=ownership,
        source_label=source_label,
        kind="file",
        managed_hash=previous_managed_hash,
        observed_hash=current_hash,
        status="conflicted",
    )


def install_adopter_constitution(
    source_root: Path,
    target_root: Path,
    manifest_entries: Dict[str, dict],
) -> SyncResult:
    relative_path = Path(".github/copilot-instructions.md")
    source_relative = Path("docs/copilot-instructions.template.md")
    source_path = source_root / source_relative
    target_path = target_root / relative_path
    result = SyncResult([], [], [], [])

    if not source_path.is_file():
        raise FileNotFoundError(f"Source path not found: {source_path}")

    safe_print(f"ℹ️  Constitution source: {normalize_relative_path(source_relative)}")

    if target_path.exists():
        # Phase 0A cannot prove manifest trust state, so every existing
        # constitution requires an explicit adoption decision.
        previous = manifest_entries.get(normalize_relative_path(relative_path), {})
        previous_managed_hash = (
            previous.get("managed_hash") or previous.get("source_hash")
            if isinstance(previous, dict)
            else None
        )
        previous_source = previous.get("source") if isinstance(previous, dict) else None
        current_hash = get_path_hash(target_path)

        if not previous_managed_hash or not previous_source or previous_source == "unknown":
            preservation_class = "legacy/unknown"
        elif current_hash != previous_managed_hash:
            preservation_class = "customization"
        else:
            preservation_class = "existing-unproven"

        record_managed_path(
            result,
            relative_path,
            "skipped",
            f"[preserved {preservation_class}; manual decision required]",
        )
        safe_print("⚠️  Constitution outcome: preserved; manual decision required")
        return result

    sync_managed_bytes(
        target_path,
        relative_path,
        source_path.read_bytes(),
        result,
        manifest_entries,
        ownership="template-managed",
        source_label="template:docs/copilot-instructions.template.md",
    )
    safe_print("✅ Constitution outcome: installed")
    return result


def install_lifecycle_asset(
    source_file: Path,
    target_root: Path,
    relative_path: Path,
    source_label: str,
    manifest_entries: Dict[str, dict],
) -> SyncResult:
    """Install one lifecycle asset without inferring or overriding ownership."""
    if not source_file.is_file():
        raise FileNotFoundError(f"Source path not found: {source_file}")

    result = SyncResult([], [], [], [])
    normalized = normalize_relative_path(relative_path)
    target_file = target_root / relative_path
    desired_bytes = source_file.read_bytes()
    previous = manifest_entries.get(normalized)

    if not target_file.is_file():
        sync_managed_bytes(
            target_file,
            relative_path,
            desired_bytes,
            result,
            manifest_entries,
            ownership="template-managed",
            source_label=source_label,
        )
        return result

    valid_previous = (
        isinstance(previous, dict)
        and previous.get("ownership") == "template-managed"
        and previous.get("source") == source_label
        and bool(previous.get("managed_hash") or previous.get("source_hash"))
    )
    previous_managed_hash = (
        previous.get("managed_hash") or previous.get("source_hash")
        if valid_previous
        else None
    )
    current_hash = get_path_hash(target_file)

    if valid_previous and current_hash == previous_managed_hash:
        sync_managed_bytes(
            target_file,
            relative_path,
            desired_bytes,
            result,
            manifest_entries,
            ownership="template-managed",
            source_label=source_label,
        )
        return result

    if valid_previous:
        record_managed_path(result, relative_path, "skipped", "[preserved customization]")
        update_manifest_entry(
            manifest_entries,
            relative_path,
            ownership="template-managed",
            source_label=source_label,
            kind="file",
            managed_hash=previous_managed_hash,
            observed_hash=current_hash,
            status="preserved-customization",
        )
        return result

    record_managed_path(
        result,
        relative_path,
        "skipped",
        "[preserved existing; manual decision required]",
    )
    return result


def install_lifecycle_assets(
    source_root: Path,
    target_root: Path,
    manifest_entries: Dict[str, dict],
) -> SyncResult:
    result = install_lifecycle_asset(
        source_root / "docs" / "WORKFLOW.template.md",
        target_root,
        Path("WORKFLOW.md"),
        "template:docs/WORKFLOW.template.md",
        manifest_entries,
    )
    for name in LIFECYCLE_TEMPLATE_FILES:
        relative_path = Path("changes/_template") / name
        result = merge_sync_results(
            result,
            install_lifecycle_asset(
                source_root / relative_path,
                target_root,
                relative_path,
                f"template:{normalize_relative_path(relative_path)}",
                manifest_entries,
            ),
        )
    return result


def sync_tree_with_policy(
    source: Path,
    target_root: Path,
    base_relative: Path,
    manifest_entries: Dict[str, dict],
    *,
    ownership: str,
    source_label_prefix: str,
    force: bool = False,
    always_overwrite: bool = False,
    preserve_untracked: bool = True,
    excludes: Optional[Sequence[str]] = None,
) -> SyncResult:
    if not source.exists():
        raise FileNotFoundError(f"Source path not found: {source}")

    excludes = excludes or ()
    result = SyncResult([], [], [], [])
    for item in source.rglob("*"):
        if item.is_dir():
            continue
        relative = item.relative_to(source)
        record_path = base_relative / relative
        if should_exclude_relative(relative, excludes):
            record_managed_path(result, record_path, "skipped")
            continue
        sync_managed_bytes(
            target_root / record_path,
            record_path,
            item.read_bytes(),
            result,
            manifest_entries,
            ownership=ownership,
            source_label=f"{source_label_prefix}/{normalize_relative_path(relative)}",
            force=force,
            always_overwrite=always_overwrite,
            preserve_untracked=preserve_untracked,
        )
    return result


def seed_directory_from_legacy_runtime(
    target_root: Path,
    relative_dir: Path,
    excludes: Optional[Sequence[str]] = None,
) -> SyncResult:
    legacy_source = target_root / ".github" / relative_dir
    target_dir = target_root / relative_dir
    if target_dir.exists() or not legacy_source.exists():
        return SyncResult([], [], [], [])
    return sync_tree(legacy_source, target_dir, force=False, excludes=excludes)


def sync_tree(
    source: Path,
    destination: Path,
    force: bool,
    excludes: Optional[Sequence[str]] = None,
) -> SyncResult:
    if not source.exists():
        raise FileNotFoundError(f"Source path not found: {source}")

    excludes = excludes or ()
    destination.mkdir(parents=True, exist_ok=True)

    result = SyncResult([], [], [], [])
    for item in source.rglob("*"):
        if item.is_dir():
            continue
        relative = item.relative_to(source)
        normalized = normalize_relative_path(relative)
        if should_exclude_relative(relative, excludes):
            result.files_skipped.append(normalized)
            continue

        target_file = destination / relative
        target_file.parent.mkdir(parents=True, exist_ok=True)

        if target_file.exists():
            if files_are_identical(item, target_file):
                result.files_skipped.append(normalized)
            elif force:
                shutil.copy2(item, target_file)
                result.files_updated.append(normalized)
            else:
                result.files_conflicted.append(normalized)
        else:
            shutil.copy2(item, target_file)
            result.files_added.append(normalized)

    return result


def record_managed_path(
    result: SyncResult,
    path: Path,
    status: str,
    suffix: str = "",
) -> None:
    normalized = path.as_posix()
    if suffix:
        normalized = f"{normalized} {suffix}"

    if status == "added":
        result.files_added.append(normalized)
    elif status == "updated":
        result.files_updated.append(normalized)
    elif status == "skipped":
        result.files_skipped.append(normalized)
    elif status == "conflicted":
        result.files_conflicted.append(normalized)


def write_managed_text_file(path: Path, content: str, force: bool) -> str:
    normalized_content = content if content.endswith("\n") else f"{content}\n"
    if path.exists():
        existing = path.read_text(encoding="utf-8")
        if existing == normalized_content:
            return "skipped"
        if not force:
            return "conflicted"
        status = "updated"
    else:
        status = "added"

    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(normalized_content, encoding="utf-8")
    return status


def remove_path(path: Path) -> None:
    if not path.exists() and not path.is_symlink():
        return
    if path.is_symlink() or path.is_file():
        path.unlink()
    else:
        shutil.rmtree(path)


def ensure_skill_link(link_path: Path, target_dir: Path, force: bool) -> Tuple[str, str]:
    label_suffix = ""
    if link_path.exists() or link_path.is_symlink():
        if link_path.is_symlink():
            try:
                if link_path.resolve() == target_dir.resolve():
                    return "skipped", label_suffix
            except OSError:
                pass
        if not force:
            return "conflicted", label_suffix
        remove_path(link_path)
        status = "updated"
    else:
        status = "added"

    link_path.parent.mkdir(parents=True, exist_ok=True)
    relative_target = os.path.relpath(target_dir, link_path.parent)
    try:
        os.symlink(relative_target, link_path, target_is_directory=True)
        return status, label_suffix
    except OSError:
        shutil.copytree(target_dir, link_path, dirs_exist_ok=False)
        return status, "[copy fallback]"


def unquote_frontmatter_value(value: str) -> str:
    value = value.strip()
    if len(value) >= 2 and value[0] == value[-1] and value[0] in {"'", '"'}:
        return value[1:-1]
    return value


def parse_agent_definition(agent_file: Path) -> Tuple[str, str, str]:
    raw = agent_file.read_text(encoding="utf-8")
    match = re.match(r"^---\r?\n(.*?)\r?\n---\r?\n?(.*)$", raw, re.S)
    if not match:
        raise ValueError(f"Invalid agent file: {agent_file}")

    frontmatter = match.group(1)
    body = match.group(2).strip()
    description_match = re.search(r"^description:\s*(.+)$", frontmatter, re.M)
    description = unquote_frontmatter_value(description_match.group(1)) if description_match else ""
    name = agent_file.name.replace(".agent.md", "")
    return name, description, body


def build_claude_agent_content(name: str, description: str, body: str) -> str:
    return (
        "---\n"
        f"name: {json.dumps(name, ensure_ascii=False)}\n"
        f"description: {json.dumps(description, ensure_ascii=False)}\n"
        "---\n\n"
        f"{body.rstrip()}\n"
    )


def build_codex_agent_content(name: str, description: str, body: str) -> str:
    escaped_body = body.rstrip().replace('"""', '\\"""')
    return (
        f"name = {json.dumps(name, ensure_ascii=False)}\n"
        f"description = {json.dumps(description, ensure_ascii=False)}\n"
        'developer_instructions = """\n'
        f"{escaped_body}\n"
        '"""\n'
    )


def install_portable_runtime(
    source_root: Path,
    target_root: Path,
    force: bool,
    manifest_entries: Dict[str, dict],
) -> SyncResult:
    result = SyncResult([], [], [], [])
    skills_source = source_root / "skills"
    agents_source = source_root / "agents"
    top_level_skill_excludes: Sequence[str] = ()
    if source_root.resolve() != target_root.resolve():
        top_level_skill_excludes = ("gate-check",)

    result = merge_sync_results(
        result,
        seed_directory_from_legacy_runtime(target_root, Path("skills"), excludes=top_level_skill_excludes),
        seed_directory_from_legacy_runtime(target_root, Path("agents")),
        sync_tree_with_policy(
            skills_source,
            target_root,
            Path("skills"),
            manifest_entries,
            ownership="template-managed",
            source_label_prefix="template:skills",
            force=force,
            excludes=top_level_skill_excludes,
        ),
        sync_tree_with_policy(
            agents_source,
            target_root,
            Path("agents"),
            manifest_entries,
            ownership="template-managed",
            source_label_prefix="template:agents",
            force=force,
        ),
    )

    guide_templates = {
        Path("AGENTS.md"): source_root / "docs" / "AGENTS.template.md",
        Path("CLAUDE.md"): source_root / "docs" / "CLAUDE.template.md",
        Path("GEMINI.md"): source_root / "docs" / "GEMINI.template.md",
    }
    for relative_path, template_path in guide_templates.items():
        if not template_path.exists():
            continue
        normalized_content = normalize_text_content(template_path.read_text(encoding="utf-8"))
        target_file = target_root / relative_path
        if target_file.exists():
            record_managed_path(result, relative_path, "skipped", "[project-owned]")
            update_manifest_entry(
                manifest_entries,
                relative_path,
                ownership="project-owned",
                source_label=f"template:docs/{template_path.name}",
                kind="file",
                managed_hash=hash_bytes(normalized_content.encode("utf-8")),
                observed_hash=get_path_hash(target_file),
                status="project-owned",
            )
            continue
        target_file.parent.mkdir(parents=True, exist_ok=True)
        target_file.write_text(normalized_content, encoding="utf-8")
        record_managed_path(result, relative_path, "added")
        update_manifest_entry(
            manifest_entries,
            relative_path,
            ownership="project-owned",
            source_label=f"template:docs/{template_path.name}",
            kind="file",
            managed_hash=hash_bytes(normalized_content.encode("utf-8")),
            observed_hash=get_path_hash(target_file),
            status="project-owned",
        )

    result = merge_sync_results(
        result,
        install_lifecycle_assets(source_root, target_root, manifest_entries),
    )

    shared_skills = target_root / "skills"
    for relative_link in PORTABLE_SKILL_LINKS:
        status, suffix = ensure_skill_link(target_root / relative_link, shared_skills, True)
        record_managed_path(result, relative_link, status, suffix)
        update_manifest_entry(
            manifest_entries,
            relative_link,
            ownership="derived-runtime",
            source_label="project:skills",
            kind="mount",
            managed_hash=None,
            observed_hash=None,
            status="derived-runtime",
        )

    target_agents_dir = target_root / "agents"
    if target_agents_dir.exists():
        for agent_file in sorted(target_agents_dir.glob("*.agent.md")):
            name, description, body = parse_agent_definition(agent_file)
            claude_relative = Path(".claude/agents") / f"{name}.md"
            claude_bytes = normalize_text_content(
                build_claude_agent_content(name, description, body)
            ).encode("utf-8")
            sync_managed_bytes(
                target_root / claude_relative,
                claude_relative,
                claude_bytes,
                result,
                manifest_entries,
                ownership="derived-runtime",
                source_label=f"project:agents/{agent_file.name}",
                always_overwrite=True,
                preserve_untracked=False,
            )
            codex_relative = Path(".codex/agents") / f"{name}.toml"
            codex_bytes = normalize_text_content(
                build_codex_agent_content(name, description, body)
            ).encode("utf-8")
            sync_managed_bytes(
                target_root / codex_relative,
                codex_relative,
                codex_bytes,
                result,
                manifest_entries,
                ownership="derived-runtime",
                source_label=f"project:agents/{agent_file.name}",
                always_overwrite=True,
                preserve_untracked=False,
            )

    result = merge_sync_results(
        result,
        sync_tree_with_policy(
            target_root / "skills",
            target_root,
            Path(".github/skills"),
            manifest_entries,
            ownership="derived-runtime",
            source_label_prefix="project:skills",
            always_overwrite=True,
            preserve_untracked=False,
        ),
        sync_tree_with_policy(
            target_root / "agents",
            target_root,
            Path(".github/agents"),
            manifest_entries,
            ownership="derived-runtime",
            source_label_prefix="project:agents",
            always_overwrite=True,
            preserve_untracked=False,
        ),
    )

    return result


def sync_workflow_files(
    source: Path,
    target_root: Path,
    force: bool,
    manifest_entries: Dict[str, dict],
    backup: bool = False,
    constitution_source_root: Optional[Path] = None,
) -> SyncResult:
    if not source.exists():
        raise FileNotFoundError(f"Source path not found: {source}")
    target_root.mkdir(parents=True, exist_ok=True)
    target_github = target_root / ".github"
    
    # Create backup if requested and target exists
    if backup and target_github.exists():
        backup_result = backup_directory(target_github)
        if backup_result.success:
            safe_print(f"✅ {backup_result.message}")
        else:
            safe_print(f"⚠️  {backup_result.message}")
    
    target_github.mkdir(parents=True, exist_ok=True)

    legacy_excludes = set(LEGACY_RUNTIME_EXCLUDES) | {"copilot-instructions.md"}

    result = sync_tree_with_policy(
        source,
        target_root,
        Path(".github"),
        manifest_entries,
        ownership="legacy-compat",
        source_label_prefix="template:.github",
        force=force,
        excludes=legacy_excludes,
    )

    if constitution_source_root is not None:
        constitution_result = install_adopter_constitution(
            constitution_source_root,
            target_root,
            manifest_entries,
        )
        result.files_skipped = [
            item
            for item in result.files_skipped
            if item != ".github/copilot-instructions.md"
        ]
        result = merge_sync_results(result, constitution_result)

    # Also copy root-level template files (e.g. .gitattributes, .editorconfig) into project root
    root_files = [".gitattributes", ".editorconfig"]
    for rf in root_files:
        src_root = source.parent / rf
        if src_root.exists():
            sync_managed_bytes(
                target_root / rf,
                Path(rf),
                src_root.read_bytes(),
                result,
                manifest_entries,
                ownership="legacy-compat",
                source_label=f"template:{rf}",
                force=force,
            )

    return result


def initialize_git_repo(target_root: Path) -> GitInitResult:
    git_dir = target_root / ".git"
    if git_dir.exists():
        return GitInitResult(False, str(git_dir), "Git repository already exists")
    try:
        subprocess.run(
            ["git", "init"],
            cwd=target_root,
            check=True,
            capture_output=True,
            text=True,
        )
    except subprocess.CalledProcessError as error:
        raise RuntimeError(
            f"Failed to initialize Git repository: {error.stderr.strip()}"
        ) from error
    if git_dir.exists():
        return GitInitResult(True, str(git_dir), "Git repository initialized successfully")
    raise RuntimeError("git init executed but .git directory not found")


def calculate_file_hash(file_path: Path) -> str:
    """Calculate SHA256 hash of a file."""
    sha256 = hashlib.sha256()
    with open(file_path, "rb") as f:
        while True:
            chunk = f.read(8192)
            if not chunk:
                break
            sha256.update(chunk)
    return sha256.hexdigest()


def files_are_identical(file1: Path, file2: Path) -> bool:
    """Check if two files have identical content."""
    if not file1.exists() or not file2.exists():
        return False
    return calculate_file_hash(file1) == calculate_file_hash(file2)


def backup_directory(source: Path, backup_name: Optional[str] = None) -> BackupResult:
    """Create a timestamped backup of a directory."""
    if not source.exists():
        return BackupResult(False, None, f"Source directory not found: {source}")
    
    if backup_name is None:
        timestamp = datetime.now().strftime("%Y%m%d-%H%M%S")
        backup_name = f"{source.name}.backup-{timestamp}"
    
    backup_path = source.parent / backup_name
    
    try:
        shutil.copytree(source, backup_path, dirs_exist_ok=False)
        return BackupResult(True, str(backup_path), f"Backup created: {backup_path}")
    except FileExistsError:
        return BackupResult(False, None, f"Backup already exists: {backup_path}")
    except Exception as error:
        return BackupResult(False, None, f"Backup failed: {error}")


def backup_managed_paths(
    target_root: Path,
    relative_paths: Sequence[str],
    backup_prefix: str = ".ai-workflow-portable",
) -> BackupResult:
    existing_paths = [target_root / relative for relative in relative_paths if (target_root / relative).exists()]
    if not existing_paths:
        return BackupResult(True, None, "No portable runtime paths to backup")

    timestamp = datetime.now().strftime("%Y%m%d-%H%M%S")
    backup_root = target_root / f"{backup_prefix}.backup-{timestamp}"

    try:
        backup_root.mkdir(parents=True, exist_ok=False)
        for source_path in existing_paths:
            relative_path = source_path.relative_to(target_root)
            destination_path = backup_root / relative_path
            destination_path.parent.mkdir(parents=True, exist_ok=True)

            if source_path.is_dir():
                shutil.copytree(source_path, destination_path, symlinks=True)
            else:
                shutil.copy2(source_path, destination_path)

        return BackupResult(True, str(backup_root), f"Backup created: {backup_root}")
    except FileExistsError:
        return BackupResult(False, None, f"Backup already exists: {backup_root}")
    except Exception as error:
        return BackupResult(False, None, f"Backup failed: {error}")


def check_git_uncommitted_changes(target_root: Path, directory: str = ".github") -> bool:
    """Check if there are uncommitted changes in a directory."""
    try:
        result = subprocess.run(
            ["git", "status", "--porcelain", directory],
            cwd=target_root,
            capture_output=True,
            text=True,
            check=False,
        )
        # If output is not empty, there are uncommitted changes
        return bool(result.stdout.strip())
    except (subprocess.CalledProcessError, FileNotFoundError):
        return False


def safe_print(text: str) -> None:
    """Print with fallback for encoding errors."""
    try:
        print(text)
    except UnicodeEncodeError:
        # Fallback: remove emojis and special Unicode characters
        ascii_text = text.encode('ascii', errors='ignore').decode('ascii')
        print(ascii_text)


def main() -> None:
    parser = argparse.ArgumentParser(
        description="Initialize the AI workflow into the current project."
    )
    parser.add_argument("--force", action="store_true", help="Force overwrite existing workflow files")
    parser.add_argument("--update", action="store_true", help="Refresh workflow files")
    parser.add_argument("--backup", action="store_true", help="Create backup before syncing")
    parser.add_argument("--verbose", action="store_true", help="Verbose output")
    parser.add_argument("--report-only", action="store_true", help="Emit a deterministic no-write reconciliation report")
    parser.add_argument("--operation", choices=("conversion-plan", "reconcile"), help="Report-only operation")
    parser.add_argument("--source-root", help="Template root for report-only planning")
    parser.add_argument("--target-root", help="Adopter root for report-only planning")
    args = parser.parse_args()

    if args.report_only:
        if args.force or args.update or args.backup:
            parser.error("--report-only cannot be combined with --force, --update, or --backup")
        if not args.operation or not args.source_root or not args.target_root:
            parser.error("--report-only requires --operation, --source-root, and --target-root")
        from scripts import manifest_reconciliation
        raise SystemExit(
            manifest_reconciliation.emit_report(
                Path(args.source_root), Path(args.target_root), args.operation
            )
        )

    force_mode = args.force
    backup_mode = args.backup or args.update  # Always backup in update mode

    repo_root = Path(__file__).resolve().parent.parent
    current_path = Path.cwd()
    template_source = repo_root / ".github"
    catalog_source_root = repo_root if (repo_root / COMPONENT_CATALOG_PATH).is_file() else None
    manifest_result = load_install_manifest(current_path, source_root=catalog_source_root)
    if manifest_result.state == "v3-validation-blocked":
        safe_print(f"❌ v3-validation-blocked: {manifest_result.manifest_path}")
        print(f"   catalog-unavailable: {manifest_result.detail}")
        print("   The Manifest cannot be classified as valid without the exact Production Schema and Component Catalog.")
        print("   Operation aborted before backup, directory, file, link, temporary artifact, or Manifest mutation.")
        raise SystemExit(1)
    if manifest_result.state == "valid-v3":
        safe_print(f"❌ manifest-v3-writer-disabled: {manifest_result.manifest_path}")
        print("   Manifest v3 writer/migration is not enabled.")
        print("   The v3 Manifest was recognized read-only and will not be downgraded or overwritten.")
        if not manifest_result.catalog_validated and manifest_result.detail:
            print(f"   {manifest_result.detail}")
        print("   Operation aborted before backup, directory, file, link, temporary artifact, or Manifest mutation.")
        raise SystemExit(1)
    if manifest_result.state in {"corrupt", "unsupported"}:
        enforce_update_manifest_safety(manifest_result)
    if args.update and not enforce_update_manifest_safety(manifest_result):
        return
    manifest_entries = manifest_result.entries

    if args.update and not args.force:
        safe_print("ℹ️  Running --update mode (will preserve project customizations and create backup).")

    safe_print("🚀 Bootstrap AI Workflow Installer")
    print()

    print("環境檢測:")
    git_result = check_git_installed()
    write_check("Git", git_result, "https://git-scm.com/downloads", MIN_GIT)
    python_result = check_python_version()
    write_check("Python", python_result, "https://www.python.org/downloads/", MIN_PYTHON)
    ps_result = check_powershell_version()
    write_check("PowerShell", ps_result, "https://aka.ms/powershell", MIN_POWERSHELL)
    node_result = check_node_installed()
    write_check("Node.js", node_result, "https://nodejs.org", MIN_NODE)
    gh_result = check_github_cli_installed()
    write_check("GitHub CLI", gh_result, "https://cli.github.com/", MIN_GHCLI)
    print()

    if not git_result.installed:
        safe_print("❌ Git is required but not found.")
        print("Please install Git and try again.")
        sys.exit(1)
    if not git_result.meets_requirement:
        safe_print("⚠️  Git version too old. Recommended: >= 2.0")
        answer = input("Continue anyway? (y/n): ").strip().lower()
        if answer != "y":
            print("Aborted.")
            sys.exit(0)
        print()

    if ps_result.version and not ps_result.meets_requirement:
        safe_print(f"⚠️  PowerShell {ps_result.version} (建議 >= 5.1)")
        print("   Some features may not work.")
        print()

    if current_path.resolve() == repo_root:
        safe_print("⚠️  警告：正在模板 repo 內執行 bootstrap")
        response = input("是否繼續（會複製到目前目錄）? (y/n): ").strip().lower()
        if response != "y":
            print("已取消。")
            sys.exit(0)

    # Check for uncommitted changes if in update mode
    if args.update:
        managed_paths = [
            path for path in PORTABLE_RUNTIME_PATHS if (current_path / path).exists()
        ]
        has_changes = any(
            check_git_uncommitted_changes(current_path, path)
            for path in managed_paths
        )
        if has_changes:
            safe_print("⚠️  檢測到 AI workflow 管理目錄有未提交的變更")
            print("   建議先提交變更後再執行 --update")
            response = input("是否繼續更新? (y/n): ").strip().lower()
            if response != "y":
                print("已取消。")
                sys.exit(0)
            print()

    print()
    print("同步工作流檔案...")
    print()

    try:
        sync_result = sync_workflow_files(
            template_source,
            current_path,
            force_mode,
            manifest_entries,
            backup_mode,
            constitution_source_root=repo_root,
        )
    except FileNotFoundError as error:
        safe_print(f"❌ 檔案同步失敗: {error}")
        sys.exit(1)

    if backup_mode:
        portable_backup_result = backup_managed_paths(current_path, PORTABLE_BACKUP_PATHS)
        if portable_backup_result.backup_path:
            if portable_backup_result.success:
                safe_print(f"✅ {portable_backup_result.message}")
            else:
                safe_print(f"⚠️  {portable_backup_result.message}")

    try:
        portable_result = install_portable_runtime(
            repo_root,
            current_path,
            force_mode,
            manifest_entries,
        )
    except (FileNotFoundError, ValueError) as error:
        safe_print(f"❌ Portable runtime 安裝失敗: {error}")
        sys.exit(1)

    sync_result = merge_sync_results(sync_result, portable_result)

    if current_path.resolve() != repo_root.resolve():
        write_install_manifest(current_path, repo_root, manifest_entries)

    if sync_result.files_added:
        safe_print(f"✅ 新增 {len(sync_result.files_added)} 個檔案")
    if sync_result.files_updated:
        safe_print(f"✅ 更新 {len(sync_result.files_updated)} 個檔案")
    if sync_result.files_skipped:
        safe_print(
            f"⏭️  跳過 {len(sync_result.files_skipped)} 個檔案（保留既有客製、排除項或內容相同）"
        )
    if sync_result.files_conflicted:
        safe_print(f"⚠️  偵測到 {len(sync_result.files_conflicted)} 個衝突檔案（內容不同但未覆蓋）")
        if args.verbose:
            for file in sync_result.files_conflicted:
                print(f"   - {file}")
        print()
        print("提示：使用 --force 參數強制覆蓋模板管理的衝突檔案")
    print()

    if args.verbose:
        if sync_result.files_added:
            print("新增的檔案:")
            for item in sync_result.files_added:
                print(f"  + {item}")
            print()
        if sync_result.files_updated:
            print("更新的檔案:")
            for item in sync_result.files_updated:
                print(f"  ~ {item}")
            print()

    print("檢查 Git 初始化...")
    print()

    try:
        git_init = initialize_git_repo(current_path)
        if git_init.is_new:
            safe_print("✅ Git repository 已初始化")
        else:
            safe_print("ℹ️  Git repository 已存在")
        print()
    except RuntimeError as error:
        safe_print(f"⚠️  Git 初始化失敗: {error}")
        print("   您可以稍後手動執行 'git init'")
        print()

    safe_print("✅ Bootstrap completed!")


if __name__ == "__main__":
    main()
