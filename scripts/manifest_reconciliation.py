"""Deterministic, report-only Manifest conversion and reconciliation planner."""

from __future__ import annotations

import copy
import hashlib
import json
import os
import socket
import fnmatch
import sys
from datetime import datetime, timezone
from pathlib import Path
from typing import Any, Dict, Iterable, Optional, Tuple

if __package__ in {None, ""}:
    sys.path.insert(0, str(Path(__file__).resolve().parent.parent))
from scripts import bootstrap


REPORT_CONTRACT_VERSION = 1
TOOL_VERSION = "phase4b-report-planner-v1"
OPERATIONS = ("conversion-plan", "reconcile")
CLASSIFICATIONS = (
    "untouched", "customized", "project-owned", "legacy", "unknown",
    "derived-customized", "conflicted", "not-applicable",
)


def _digest_bytes(value: bytes) -> str:
    return "sha256:" + hashlib.sha256(value).hexdigest()


def _canonical(value: Any) -> bytes:
    if not isinstance(value, dict):
        raise ValueError("canonical report must be an object")
    if "volatile_display_envelope" not in value:
        raise ValueError("report must contain volatile_display_envelope")
    body = copy.deepcopy(value)
    body.pop("volatile_display_envelope", None)
    body.pop("report_identity", None)
    return (json.dumps(body, ensure_ascii=False, separators=(",", ":"), sort_keys=False) + "\n").encode("utf-8")


def canonical_report_bytes(report: Dict[str, Any]) -> bytes:
    """Return the deterministic decision-body bytes, excluding volatile/self fields."""
    return _canonical(report)


def report_digest(report: Dict[str, Any]) -> str:
    return _digest_bytes(canonical_report_bytes(report))


def _safe_path(root: Path, relative: str) -> Optional[Path]:
    if not relative or "\\" in relative or relative.startswith("/") or ":" in relative:
        return None
    candidate = (root / Path(relative)).resolve()
    try:
        candidate.relative_to(root.resolve())
    except ValueError:
        return None
    return candidate


def _path_digest(root: Path, relative: str) -> Optional[str]:
    path = _safe_path(root, relative)
    if path is None or not path.is_file():
        return None
    return _digest_bytes(path.read_bytes())


def _read_json(path: Path) -> Tuple[Optional[Any], Optional[str]]:
    try:
        return json.loads(path.read_text(encoding="utf-8")), None
    except FileNotFoundError:
        return None, "missing"
    except (OSError, UnicodeError, json.JSONDecodeError):
        return None, "corrupt"


def _source_evidence(source_root: Path) -> Tuple[Dict[str, dict], Optional[bytes], Optional[bytes], Optional[str]]:
    schema_path = source_root / bootstrap.PRODUCTION_MANIFEST_SCHEMA
    catalog_path = source_root / bootstrap.COMPONENT_CATALOG_PATH
    try:
        schema_bytes = schema_path.read_bytes()
    except (OSError, UnicodeError):
        return {}, None, None, "schema-missing"
    try:
        catalog_bytes = catalog_path.read_bytes()
    except (OSError, UnicodeError):
        return {}, schema_bytes, None, "catalog-missing"
    try:
        schema_bytes.decode("utf-8")
        catalog_bytes.decode("utf-8")
        bootstrap._load_and_validate_production_schema(source_root)
        catalog, records, _ = bootstrap._load_and_validate_component_catalog(source_root)
    except UnicodeError:
        return {}, schema_bytes, catalog_bytes, "source-utf8"
    except (json.JSONDecodeError, bootstrap.ManifestValidationError):
        return {}, schema_bytes, catalog_bytes, "source-invalid"
    except (OSError, KeyError, TypeError, ValueError):
        return {}, schema_bytes, catalog_bytes, "source-invalid"
    return records, schema_bytes, catalog_bytes, None


def _tree_snapshot(root: Path) -> dict:
    files = []
    directories = []
    links = []
    if root.exists():
        for path in sorted(root.rglob("*"), key=lambda item: item.relative_to(root).as_posix()):
            relative = path.relative_to(root).as_posix()
            try:
                stat = path.lstat()
            except OSError:
                continue
            if path.is_symlink():
                links.append({"path": relative, "target": os.readlink(path)})
            elif path.is_dir():
                directories.append(relative)
            elif path.is_file():
                files.append({"path": relative, "digest": _digest_bytes(path.read_bytes()), "size": stat.st_size, "mtime_ns": stat.st_mtime_ns})
    return {"files": files, "directories": directories, "links": links, "git_present": (root / ".git").exists()}


def _stable_snapshot(snapshot: Any) -> Any:
    if isinstance(snapshot, dict):
        stable: Dict[str, Any] = {}
        for key, value in snapshot.items():
            if key == "mtime_ns":
                continue
            stable[key] = _stable_snapshot(value)
        return stable
    if isinstance(snapshot, list):
        return [_stable_snapshot(item) for item in snapshot]
    return snapshot


def _snapshot_digest(snapshot: dict) -> str:
    stable = _stable_snapshot(snapshot)
    return _digest_bytes((json.dumps(stable, ensure_ascii=False, separators=(",", ":"), sort_keys=True) + "\n").encode("utf-8"))


def _timestamp_index(snapshot: dict) -> dict:
    return {item["path"]: item["mtime_ns"] for item in snapshot["files"]}


def _forbidden_artifacts(snapshot: dict) -> list:
    names = ("*.backup-*", "*.lock", "*.journal", "*.tmp", "*.temp", "*report*.json")
    return sorted(item["path"] for item in snapshot["files"] if any(fnmatch.fnmatch(item["path"], pattern) for pattern in names))


def _manifest_state(source_root: Path, target_root: Path) -> Tuple[bootstrap.ManifestLoadResult, Optional[bytes]]:
    path = target_root / bootstrap.MANIFEST_FILENAME
    try:
        raw = path.read_bytes()
    except FileNotFoundError:
        return bootstrap.load_install_manifest(target_root, source_root=source_root), None
    return bootstrap.load_install_manifest(target_root, source_root=source_root), raw


def _classification(record: Optional[dict], catalog_record: dict, target_hash: Optional[str], source_hash: Optional[str]) -> Tuple[str, str, str]:
    if record is None:
        return "unknown", "missing-v3-lineage", "report"
    if catalog_record["role"] == "project-owned" or record["provenance"]["ownership"] == "project-owned":
        return "project-owned", "catalog-project-owned", "preserve"
    fork = record["provenance"]["fork"]
    status = fork["status"]
    if status == "conflicted":
        return "conflicted", "manifest-conflict", "preserve"
    if catalog_record["kind"] != "file":
        return "not-applicable", "kind-has-no-single-byte-stream", "report"
    baseline = record["hashes"]["baseline"]
    if status == "untouched" and target_hash == baseline and source_hash is not None:
        return "untouched", "verified-managed-equality", "report"
    if catalog_record["role"] == "generated" and target_hash not in (None, source_hash):
        return "derived-customized", "derived-output-bytes-differ", "preserve"
    if target_hash is not None and baseline is not None and target_hash != baseline:
        return "customized", "observed-bytes-differ-from-baseline", "preserve"
    return "unknown", "insufficient-byte-proof", "report"


def _decision(component_id: str, catalog_record: dict, record: Optional[dict], source_root: Path, target_root: Path, state: str) -> dict:
    relative = catalog_record["canonical_source_path"]
    source_hash = _path_digest(source_root, relative)
    target_hash = _path_digest(target_root, relative)
    previous_hashes = {old: _path_digest(target_root, old) for old in sorted(catalog_record.get("previous_paths", []))}
    classification, basis, action = _classification(record, catalog_record, target_hash, source_hash) if state == "valid-v3" else ("legacy", "compatibility-reader", "report")
    rename_proven = bool(source_hash and target_hash is None and any(previous_hashes.values()))
    retirement_proven = catalog_record.get("lifecycle_status") == "retired" and bool(catalog_record.get("retired_release"))
    stale = source_hash is None and target_hash is not None
    if rename_proven:
        action = "report"
        basis = "catalog-previous-path-history"
    elif retirement_proven:
        action = "report"
        basis = "catalog-typed-retirement-release"
    elif stale:
        action = "preserve"
        basis = "source-missing-no-retirement-evidence"
        if record is not None and record["hashes"]["baseline"] not in (None, target_hash):
            classification = "customized" if catalog_record["role"] == "canonical" else "derived-customized"
            basis = "modified-stale-output"
    eligibility = {
        "eligible": False,
        "computation_version": "d05-v1",
        "not_authority": True,
        "reason": "report-only-no-delete-authority",
    }
    return {
        "component_identity": {
            "id": component_id, "path": relative, "path_key": relative.lower(),
            "kind": catalog_record["kind"], "role": catalog_record["role"],
        },
        "ownership": record["provenance"]["ownership"] if record else "unknown",
        "observed_hash": target_hash,
        "baseline": record["hashes"]["baseline"] if record else None,
        "proposed_source_hash": source_hash,
        "source": {"path": relative, "release": bootstrap.COMPONENT_CATALOG_RELEASE_ID},
        "generated_from": sorted(catalog_record["generated_from"]),
        "classification": classification,
        "classification_basis": basis,
        "lifecycle_state": record["lifecycle"]["state"] if record else "unknown",
        "stale_or_retirement_reason": "rename-proven" if rename_proven else ("retirement-proven" if retirement_proven else ("source-missing-no-retirement-evidence" if stale else "not-stale")),
        "previous_path_hashes": previous_hashes,
        "proposed_action": action,
        "eligibility": eligibility,
    }


def _inventory(root: Path) -> list:
    if not root.exists():
        return []
    return sorted(p.relative_to(root).as_posix() for p in root.rglob("*") if p.is_file())


def build_report(source_root: Path, target_root: Path, operation: str) -> Dict[str, Any]:
    if operation not in OPERATIONS:
        raise ValueError("operation must be conversion-plan or reconcile")
    source_root = Path(source_root).resolve()
    target_root = Path(target_root).resolve()
    target_before = _tree_snapshot(target_root)
    source_before = _tree_snapshot(source_root)
    manifest_path = target_root / bootstrap.MANIFEST_FILENAME
    try:
        manifest_bytes = manifest_path.read_bytes()
    except FileNotFoundError:
        manifest_bytes = None
    catalog_records, schema_bytes, catalog_bytes, source_error = _source_evidence(source_root)
    if source_error:
        manifest_result = bootstrap.ManifestLoadResult("source-blocked", {}, None, source_error, manifest_path, source_error, False)
    else:
        manifest_result, manifest_bytes = _manifest_state(source_root, target_root)
    state = manifest_result.state
    blocking = []
    if source_error:
        blocking.append({"code": source_error, "detail": "source schema or catalog validation blocked planning"})
    if state in {"corrupt", "unsupported", "v3-validation-blocked"}:
        blocking.append({"code": manifest_result.diagnostic_category or "manifest-blocked", "detail": "manifest cannot be planned"})
    records = manifest_result.entries if state in {"valid-v3", "valid-v1", "valid-v2"} else {}
    mapped = []
    unmapped = []
    if state in {"valid-v3", "valid-v1", "valid-v2"}:
        if state == "valid-v3":
            for cid in sorted(catalog_records):
                mapped.append(_decision(cid, catalog_records[cid], records.get(cid), source_root, target_root, state))
        else:
            catalog_by_path = {item["canonical_source_path"]: (cid, item) for cid, item in catalog_records.items()}
            for name in sorted(records):
                if name in catalog_by_path:
                    cid, item = catalog_by_path[name]
                    mapped.append(_decision(cid, item, None, source_root, target_root, state))
                else:
                    unmapped.append({"record": name, "classification": "unknown", "reason": "no-exact-catalog-path"})
    before_inventory = [item["path"] for item in target_before["files"]]
    source_after = _tree_snapshot(source_root)
    target_after = _tree_snapshot(target_root)
    inventory_unchanged = _stable_snapshot(target_before) == _stable_snapshot(target_after)
    timestamps_unchanged = _timestamp_index(target_before) == _timestamp_index(target_after)
    link_metadata_unchanged = target_before.get("links") == target_after.get("links")
    git_presence_unchanged = target_before.get("git_present") == target_after.get("git_present")
    forbidden_before = _forbidden_artifacts(target_before)
    forbidden_after = _forbidden_artifacts(target_after)
    forbidden_artifacts_unchanged = forbidden_before == forbidden_after
    no_write_proved = (
        inventory_unchanged
        and timestamps_unchanged
        and link_metadata_unchanged
        and git_presence_unchanged
        and forbidden_artifacts_unchanged
        and _snapshot_digest(source_before) == _snapshot_digest(source_after)
        and _snapshot_digest(target_before) == _snapshot_digest(target_after)
    )
    if not no_write_proved:
        blocking.append({"code": "no-write-proof-failed", "detail": "pre/post snapshots changed during report-only execution"})
    snapshot = {
        "manifest_digest": _digest_bytes(manifest_bytes) if manifest_bytes is not None else None,
        "source_schema_digest": _digest_bytes(schema_bytes) if schema_bytes is not None else None,
        "source_catalog_digest": _digest_bytes(catalog_bytes) if catalog_bytes is not None else None,
        "target_inventory": before_inventory,
        "target_hashes": {d["component_identity"]["path"]: d["observed_hash"] for d in mapped},
    }
    snapshot["source_snapshot"] = source_before
    snapshot["target_snapshot"] = target_before
    snapshot_digest = _snapshot_digest(snapshot)
    report: Dict[str, Any] = {
        "report_contract_version": REPORT_CONTRACT_VERSION,
        "operation": operation,
        "manifest_parse_state": {"state": state, "schema_version": manifest_result.schema_version, "diagnostic_category": manifest_result.diagnostic_category},
        "plan_identity": {"report_contract_version": REPORT_CONTRACT_VERSION, "tool_version": TOOL_VERSION, "operation": operation, "input_manifest_digest": snapshot["manifest_digest"], "source_release_id": bootstrap.COMPONENT_CATALOG_RELEASE_ID if not source_error else None, "selected_component_ids": [d["component_identity"]["id"] for d in mapped], "normalized_input_snapshot_identity": snapshot_digest},
        "report_identity": {"report_id": None, "canonical_body_digest": None},
        "source": {"source_release_id": bootstrap.COMPONENT_CATALOG_RELEASE_ID if not source_error else None, "schema_path": bootstrap.PRODUCTION_MANIFEST_SCHEMA.as_posix(), "schema_digest": _digest_bytes(schema_bytes) if schema_bytes is not None else None, "catalog_path": bootstrap.COMPONENT_CATALOG_PATH.as_posix(), "catalog_digest": _digest_bytes(catalog_bytes) if catalog_bytes is not None else None},
        "normalized_input_snapshot_identity": {"digest": snapshot_digest, "inventory": before_inventory},
        "mapped_component_decisions": sorted(mapped, key=lambda item: item["component_identity"]["id"]),
        "unmapped_records": sorted(unmapped, key=lambda item: item["record"]),
        "blocking_findings": blocking,
        "required_future_authorization": {"not_authority": True, "approval_supplied": False, "future_current_task_action_specific_approval_required": True, "execution_time_revalidation_required": True, "delete_action": False},
        "no_write_confirmation": {"writes_performed": not no_write_proved, "pre_manifest_digest": snapshot["manifest_digest"], "post_manifest_digest": snapshot["manifest_digest"], "pre_catalog_digest": snapshot["source_catalog_digest"], "post_catalog_digest": snapshot["source_catalog_digest"], "pre_source_snapshot_digest": _snapshot_digest(source_before), "post_source_snapshot_digest": _snapshot_digest(source_after), "pre_target_snapshot_digest": _snapshot_digest(target_before), "post_target_snapshot_digest": _snapshot_digest(target_after), "inventory_unchanged": inventory_unchanged, "timestamps_unchanged": timestamps_unchanged, "link_metadata_unchanged": link_metadata_unchanged, "git_presence_unchanged": git_presence_unchanged, "forbidden_artifacts_before": forbidden_before, "forbidden_artifacts_after": forbidden_after, "forbidden_artifacts_unchanged": forbidden_artifacts_unchanged, "pre_inventory": before_inventory, "post_inventory": [item["path"] for item in target_after["files"]], "selected_target_hashes": snapshot["target_hashes"]},
        "volatile_display_envelope": {"timestamp": datetime.now(timezone.utc).isoformat().replace("+00:00", "Z"), "host": socket.gethostname() if os.environ.get("AI_WORKFLOW_REPORT_HOST", "") else None},
    }
    digest = report_digest(report)
    report["report_identity"] = {"report_id": "report:" + digest[7:19], "canonical_body_digest": digest}
    return report


def emit_report(source_root: Path, target_root: Path, operation: str) -> int:
    report = build_report(source_root, target_root, operation)
    sys.stdout.buffer.write(json.dumps(report, ensure_ascii=False, separators=(",", ":"), sort_keys=False).encode("utf-8") + b"\n")
    return 0


if __name__ == "__main__":
    import argparse
    parser = argparse.ArgumentParser()
    parser.add_argument("--operation", choices=OPERATIONS, required=True)
    parser.add_argument("--source-root", required=True)
    parser.add_argument("--target-root", required=True)
    args = parser.parse_args()
    raise SystemExit(emit_report(Path(args.source_root), Path(args.target_root), args.operation))
