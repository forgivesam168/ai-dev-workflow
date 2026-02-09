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
import re
import shutil
import subprocess
import sys
from dataclasses import dataclass
from pathlib import Path
from typing import List, Optional, Sequence, Tuple

MIN_GIT = "2.0.0"
MIN_PYTHON = "3.7.0"
MIN_POWERSHELL = "5.1.0"
MIN_NODE = "16.0.0"
MIN_GHCLI = "2.0.0"
EXCLUDE_PATTERNS = {"workflows", "CODEOWNERS", "dependabot.yml"}


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


def sync_workflow_files(
    source: Path, target_root: Path, force: bool
) -> SyncResult:
    if not source.exists():
        raise FileNotFoundError(f"Source path not found: {source}")
    target_root.mkdir(parents=True, exist_ok=True)
    target_github = target_root / ".github"
    target_github.mkdir(parents=True, exist_ok=True)

    files_added: List[str] = []
    files_updated: List[str] = []
    files_skipped: List[str] = []

    for item in source.rglob("*"):
        if item.is_dir():
            continue
        relative = item.relative_to(source)
        normalized = str(relative).replace("\\", "/")
        normalized_lower = normalized.lower()
        if any(pattern.lower() in normalized_lower for pattern in EXCLUDE_PATTERNS):
            files_skipped.append(normalized)
            continue
        destination = target_github / relative
        destination.parent.mkdir(parents=True, exist_ok=True)
        if destination.exists():
            if force:
                shutil.copy2(item, destination)
                files_updated.append(normalized)
            else:
                files_skipped.append(normalized)
        else:
            shutil.copy2(item, destination)
            files_added.append(normalized)

    return SyncResult(files_added, files_updated, files_skipped)


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
    parser.add_argument("--verbose", action="store_true", help="Verbose output")
    args = parser.parse_args()

    force_mode = args.force or args.update
    if args.update and not args.force:
        safe_print("ℹ️  Running --update (will overwrite workflow files).")

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

    print()
    print("同步工作流檔案...")
    print()

    try:
        sync_result = sync_workflow_files(template_source, current_path, force_mode)
    except FileNotFoundError as error:
        safe_print(f"❌ 檔案同步失敗: {error}")
        sys.exit(1)

    if sync_result.files_added:
        safe_print(f"✅ 新增 {len(sync_result.files_added)} 個檔案")
    if sync_result.files_updated:
        safe_print(f"✅ 更新 {len(sync_result.files_updated)} 個檔案")
    if sync_result.files_skipped:
        safe_print(f"⏭️  跳過 {len(sync_result.files_skipped)} 個檔案（workflows/CODEOWNERS 等）")
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
