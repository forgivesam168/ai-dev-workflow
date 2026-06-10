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
from typing import Dict, List, Optional, Sequence, Tuple, Union

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
    ".ai-workflow-install.json",
]
PORTABLE_BACKUP_PATHS = [path for path in PORTABLE_RUNTIME_PATHS if path != ".github"]
PORTABLE_SKILL_LINKS = [
    Path(".agents/skills"),
    Path(".claude/skills"),
    Path(".agent/skills"),
]
MANIFEST_FILENAME = ".ai-workflow-install.json"


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
    return str(path).replace("\\", "/").lstrip("./")


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


def load_install_manifest(target_root: Path) -> Dict[str, dict]:
    manifest_path = target_root / MANIFEST_FILENAME
    if not manifest_path.exists():
        return {}

    try:
        data = json.loads(manifest_path.read_text(encoding="utf-8"))
    except (OSError, json.JSONDecodeError):
        return {}

    components = data.get("components", [])
    if not isinstance(components, list):
        return {}

    manifest_entries: Dict[str, dict] = {}
    for component in components:
        if not isinstance(component, dict):
            continue
        name = component.get("name")
        if isinstance(name, str) and name:
            manifest_entries[name] = component
    return manifest_entries


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

    result = sync_tree_with_policy(
        source,
        target_root,
        Path(".github"),
        manifest_entries,
        ownership="legacy-compat",
        source_label_prefix="template:.github",
        force=force,
        excludes=LEGACY_RUNTIME_EXCLUDES,
    )

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
    args = parser.parse_args()

    force_mode = args.force
    backup_mode = args.backup or args.update  # Always backup in update mode

    if args.update and not args.force:
        safe_print("ℹ️  Running --update mode (will preserve project customizations and create backup).")

    repo_root = Path(__file__).resolve().parent.parent
    current_path = Path.cwd()
    template_source = repo_root / ".github"

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

    manifest_entries = load_install_manifest(current_path)

    try:
        sync_result = sync_workflow_files(
            template_source,
            current_path,
            force_mode,
            manifest_entries,
            backup_mode,
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
