"""Reference conversion utilities for the Phase 4C Windows rehearsal.

The supported Windows entry point is ``manifest-migration-rehearsal.ps1``.
This module performs deterministic in-memory conversion and validation only;
it does not publish manifests or operate on adopter projects.
"""

from __future__ import annotations

import hashlib
import json
import os
import re
import stat
import sys
from pathlib import Path
from typing import Any, Dict, List, Optional, Tuple, Union


SCRIPTS_ROOT = Path(__file__).resolve().parent
if str(SCRIPTS_ROOT) not in sys.path:
    sys.path.insert(0, str(SCRIPTS_ROOT))

import bootstrap  # noqa: E402


FIXED_TIMESTAMP = "1970-01-01T00:00:00Z"
HASH_PATTERN = re.compile(r"^sha256:[0-9a-f]{64}$")
ROLE_OWNERSHIP = {
    "canonical": "template-managed",
    "generated": "derived-runtime",
    "project-owned": "project-owned",
    "compatibility": "legacy-compat",
}
ROLE_SOURCE_KIND = {
    "canonical": "template",
    "generated": "generated",
    "project-owned": "project",
    "compatibility": "legacy",
}


def canonical_json_bytes(value: Dict[str, Any]) -> bytes:
    """Return deterministic UTF-8 JSON with LF and no BOM."""

    return (
        json.dumps(
            value,
            ensure_ascii=False,
            separators=(",", ":"),
            sort_keys=False,
        )
        + "\n"
    ).encode("utf-8")


def canonical_candidate_bytes(candidate_manifest: Dict[str, Any]) -> bytes:
    return canonical_json_bytes(candidate_manifest)


def sha256_digest(value: bytes) -> str:
    return "sha256:" + hashlib.sha256(value).hexdigest()


def classify_manifest_bytes(payload: Optional[bytes]) -> Dict[str, Any]:
    """Classify a legacy manifest without treating invalid input as missing."""

    if payload is None:
        return {"state": "missing", "version": None, "can_write": False}
    try:
        value = json.loads(payload.decode("utf-8"))
    except (UnicodeDecodeError, json.JSONDecodeError):
        return {"state": "corrupt", "version": None, "can_write": False}
    if not isinstance(value, dict):
        return {"state": "wrong-top-level", "version": None, "can_write": False}
    version = value.get("schema_version")
    if type(version) is not int:
        return {"state": "corrupt", "version": None, "can_write": False}
    if version not in (1, 2):
        return {"state": "unsupported", "version": version, "can_write": False}
    components = value.get("components")
    if not isinstance(components, list):
        return {"state": "corrupt", "version": version, "can_write": False}
    names = set()
    for component in components:
        if not isinstance(component, dict):
            return {"state": "corrupt", "version": version, "can_write": False}
        name = component.get("name")
        if not isinstance(name, str) or not name.strip():
            return {"state": "corrupt", "version": version, "can_write": False}
        try:
            bootstrap._validate_relative_path(
                name.replace("\\", "/"),
                "legacy-path",
                "Legacy component path",
            )
        except ValueError:
            return {"state": "corrupt", "version": version, "can_write": False}
        if name in names:
            return {"state": "corrupt", "version": version, "can_write": False}
        names.add(name)
    return {"state": "valid-v{}".format(version), "version": version, "can_write": True}


def _load_catalog(
    source_root: Path,
) -> Tuple[Dict[str, Any], Dict[str, Dict[str, Any]], bytes]:
    return bootstrap._load_and_validate_component_catalog(source_root)


def _normalized_hash(value: Any) -> Optional[str]:
    if value is None:
        return None
    if isinstance(value, str) and HASH_PATTERN.fullmatch(value):
        return value
    return None


def _legacy_path(entry: Dict[str, Any]) -> Optional[str]:
    value = entry.get("name")
    if not isinstance(value, str):
        return None
    try:
        return bootstrap._validate_relative_path(
            value.replace("\\", "/"),
            "legacy-path",
            "Legacy component path",
        )
    except ValueError:
        return None


def _is_reparse_point(path: Path) -> bool:
    metadata = os.lstat(str(path))
    attributes = getattr(metadata, "st_file_attributes", 0)
    reparse_flag = getattr(stat, "FILE_ATTRIBUTE_REPARSE_POINT", 0x400)
    return path.is_symlink() or bool(attributes & reparse_flag)


def _current_source_hash(
    source_root: Path, catalog_component: Dict[str, Any]
) -> Optional[str]:
    root = source_root.absolute()
    relative = catalog_component["canonical_source_path"]
    candidate = root.joinpath(*relative.split("/"))
    try:
        if os.path.commonpath((str(root), str(candidate.absolute()))) != str(root):
            return None
        chain = []
        current = candidate
        while True:
            chain.append(current)
            if current == current.parent:
                break
            current = current.parent
        for item in reversed(chain):
            if item.exists() and _is_reparse_point(item):
                return None
        metadata = os.lstat(str(candidate))
        if not stat.S_ISREG(metadata.st_mode):
            return None
        return sha256_digest(candidate.read_bytes())
    except (OSError, ValueError):
        return None


def _trusted_entry(
    entry: Dict[str, Any],
    catalog_component: Dict[str, Any],
    source_root: Path,
) -> Tuple[bool, str, Optional[str]]:
    role = catalog_component["role"]
    path = catalog_component["canonical_source_path"]
    if (
        role != "canonical"
        or catalog_component["kind"] != "file"
        or catalog_component["lifecycle_status"] != "active"
    ):
        return False, "unsupported-legacy-role", None
    if entry.get("ownership") != "template-managed" or entry.get("kind") != "file":
        return False, "missing-or-untrusted-lineage", None
    if entry.get("source") != "template:" + path:
        return False, "source-locator-not-exact", None
    baseline = _normalized_hash(entry.get("managed_hash"))
    observed = _normalized_hash(entry.get("observed_hash"))
    legacy_source = _normalized_hash(entry.get("source_hash"))
    if baseline is None or observed is None or legacy_source != baseline:
        return False, "source-hash-not-baseline", None
    proposed = _current_source_hash(source_root, catalog_component)
    if proposed is None:
        return False, "current-source-unavailable", None
    return True, "", proposed


def _fork(entry: Dict[str, Any], role: str, kind: str) -> Dict[str, str]:
    if role == "project-owned":
        return {
            "status": "project-owned",
            "basis": "explicit-project-ownership",
            "decision": "preserve",
            "classified_at": FIXED_TIMESTAMP,
        }
    if role == "compatibility":
        return {
            "status": "legacy",
            "basis": "legacy-import",
            "decision": "report-only",
            "classified_at": FIXED_TIMESTAMP,
        }
    if kind != "file":
        return {
            "status": "not-applicable",
            "basis": "hash-not-applicable",
            "decision": "report-only",
            "classified_at": FIXED_TIMESTAMP,
        }
    baseline = entry["managed_hash"]
    observed = entry["observed_hash"]
    if baseline == observed:
        return {
            "status": "untouched",
            "basis": "verified-managed-equality",
            "decision": "manage",
            "classified_at": FIXED_TIMESTAMP,
        }
    if role == "generated":
        return {
            "status": "derived-customized",
            "basis": "derived-hash-divergence",
            "decision": "preserve",
            "classified_at": FIXED_TIMESTAMP,
        }
    return {
        "status": "customized",
        "basis": "hash-divergence",
        "decision": "preserve",
        "classified_at": FIXED_TIMESTAMP,
    }


def _component_record(
    entry: Dict[str, Any],
    catalog_component: Dict[str, Any],
    transaction_id: str,
    candidate_timestamp: str,
    proposed_source_hash: str,
) -> Dict[str, Any]:
    role = catalog_component["role"]
    kind = catalog_component["kind"]
    source_kind = ROLE_SOURCE_KIND[role]
    path = catalog_component["canonical_source_path"]
    source_release = (
        bootstrap.COMPONENT_CATALOG_RELEASE_ID
        if role in {"canonical", "generated"}
        else None
    )
    baseline = _normalized_hash(entry.get("managed_hash")) if kind == "file" else None
    observed = _normalized_hash(entry.get("observed_hash")) if kind == "file" else None
    proposed = proposed_source_hash if kind == "file" else None
    installed_at = entry.get("installed_at")
    if not isinstance(installed_at, str) or not installed_at.endswith("Z"):
        installed_at = None
    return {
        "identity": {
            "id": catalog_component["id"],
            "path": path,
            "path_key": path.lower(),
            "kind": kind,
            "role": role,
            "link": None,
        },
        "provenance": {
            "ownership": ROLE_OWNERSHIP[role],
            "source": {
                "kind": source_kind,
                "locator": "{}:{}".format(source_kind, path),
                "release": source_release,
            },
            "generated_from": list(catalog_component["generated_from"]),
            "fork": _fork(entry, role, kind),
        },
        "hashes": {
            "algorithm": "sha256",
            "content_basis": "exact-bytes",
            "baseline": baseline,
            "observed_before": observed,
            "proposed_source": proposed,
            "result_after": observed,
        },
        "lifecycle": {
            "state": "active",
            "previous_paths": list(catalog_component["previous_paths"]),
            "retirement": None,
            "reintroduces_component_id": catalog_component[
                "reintroduces_component_id"
            ],
        },
        "last_operation": {
            "transaction_id": transaction_id,
            "outcome": "reported",
        },
        "installed_at": installed_at,
        "updated_at": candidate_timestamp,
    }


def _candidate_timestamp(legacy_manifest: Dict[str, Any]) -> str:
    candidates = [FIXED_TIMESTAMP]
    values = [legacy_manifest.get("installed_at")]
    for entry in legacy_manifest.get("components", []):
        if isinstance(entry, dict):
            values.extend((entry.get("installed_at"), entry.get("updated_at")))
    for value in values:
        if not isinstance(value, str):
            continue
        try:
            bootstrap._timestamp_key(value, "legacy-timestamp", "Legacy timestamp")
        except bootstrap.ManifestValidationError:
            continue
        candidates.append(value)
    return max(
        candidates,
        key=lambda value: bootstrap._timestamp_key(
            value, "legacy-timestamp", "Legacy timestamp"
        ),
    )


def convert_legacy_manifest(
    legacy_manifest: Dict[str, Any],
    source_root: Union[Path, str],
    *,
    writer: str = "python",
    include_decisions: bool = False,
) -> Union[Dict[str, Any], Dict[str, Any]]:
    """Convert trusted v1/v2 records and report every ambiguous record."""

    if writer not in {"python", "powershell"}:
        raise ValueError("writer must be python or powershell")
    encoded_legacy = canonical_json_bytes(legacy_manifest)
    classification = classify_manifest_bytes(encoded_legacy)
    if classification["state"] not in {"valid-v1", "valid-v2"}:
        raise ValueError("Legacy manifest must be valid schema v1 or v2.")

    root = Path(source_root)
    catalog, catalog_records, catalog_bytes = _load_catalog(root)
    by_path = {
        record["canonical_source_path"]: record
        for record in catalog_records.values()
    }
    transaction_id = "txn:phase4c.{}".format(
        hashlib.sha256(encoded_legacy + catalog_bytes).hexdigest()[:24]
    )
    candidate_timestamp = _candidate_timestamp(legacy_manifest)
    eligible: List[Tuple[Dict[str, Any], Dict[str, Any], str]] = []
    decisions: List[Dict[str, str]] = []
    seen_paths = set()
    for raw_entry in legacy_manifest["components"]:
        if not isinstance(raw_entry, dict):
            decisions.append({"path": "<invalid>", "reason": "invalid-component-record"})
            continue
        path = _legacy_path(raw_entry)
        if path is None:
            decisions.append({"path": "<invalid>", "reason": "unsafe-component-path"})
            continue
        if path in seen_paths:
            decisions.append({"path": path, "reason": "duplicate-component-path"})
            continue
        seen_paths.add(path)
        catalog_component = by_path.get(path)
        if catalog_component is None:
            decisions.append({"path": path, "reason": "not-in-component-catalog"})
            continue
        trusted, reason, proposed_source_hash = _trusted_entry(
            raw_entry, catalog_component, root
        )
        if not trusted:
            decisions.append({"path": path, "reason": reason})
            continue
        assert proposed_source_hash is not None
        eligible.append((raw_entry, catalog_component, proposed_source_hash))

    eligible_ids = {
        catalog_component["id"] for _, catalog_component, _ in eligible
    }
    components = []
    for entry, catalog_component, proposed_source_hash in eligible:
        if any(
            parent not in eligible_ids
            for parent in catalog_component["generated_from"]
        ):
            decisions.append(
                {
                    "path": catalog_component["canonical_source_path"],
                    "reason": "generated-parent-not-migrated",
                }
            )
            continue
        components.append(
            _component_record(
                entry,
                catalog_component,
                transaction_id,
                candidate_timestamp,
                proposed_source_hash,
            )
        )
    components.sort(key=lambda item: item["identity"]["id"])
    decisions.sort(key=lambda item: (item["path"], item["reason"]))

    candidate = {
        "schema_version": 3,
        "written_at": candidate_timestamp,
        "source_release": {
            "release_id": catalog["source_release"]["release_id"],
            "source_ref": catalog["source_release"]["source_ref"],
            "version": catalog["source_release"]["version"],
            "component_catalog": {
                "path": "manifest/component-catalog.json",
                "schema_version": catalog["catalog_schema_version"],
                "sha256": sha256_digest(catalog_bytes),
            },
        },
        "last_transaction": {
            "id": transaction_id,
            "mode": "migration",
            "writer": writer,
            "started_at": candidate_timestamp,
            "completed_at": candidate_timestamp,
            "result": "committed",
        },
        "components": components,
    }
    validate_candidate(candidate, root)
    if include_decisions:
        return {"manifest": candidate, "manual_decisions": decisions}
    return candidate


def validate_candidate(
    candidate_manifest: Dict[str, Any], source_root: Union[Path, str]
) -> None:
    """Use the Production Schema/Catalog semantic validator."""

    try:
        _, catalog_validated, detail = bootstrap._validate_manifest_v3(
            candidate_manifest, Path(source_root)
        )
    except bootstrap.ManifestValidationError as error:
        raise ValueError(str(error)) from error
    if not catalog_validated:
        raise ValueError(detail or "Production catalog validation was not completed.")
    if canonical_candidate_bytes(json.loads(canonical_candidate_bytes(candidate_manifest))) != (
        canonical_candidate_bytes(candidate_manifest)
    ):
        raise ValueError("Candidate canonical serialization is unstable.")
