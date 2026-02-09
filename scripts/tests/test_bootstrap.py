import os
from pathlib import Path

from scripts import bootstrap


def test_extract_version_returns_present_match() -> None:
    text = "git version 2.43.0.windows.1"
    pattern = r"git version (\d+\.\d+\.\d+)"
    assert bootstrap.extract_version(text, pattern) == "2.43.0"


def test_is_version_ge_comparison() -> None:
    assert bootstrap.is_version_ge("2.49.0", "2.0.0")
    assert not bootstrap.is_version_ge("1.9.9", "2.0.0")


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
    result = bootstrap.sync_workflow_files(source, project_root, force=False)

    added = set(result.files_added)
    skipped = set(result.files_skipped)

    assert "README.md" in added
    assert not any(item.startswith("workflows") for item in added)
    assert any(item.startswith("workflows") for item in skipped)
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

    result = bootstrap.sync_workflow_files(source, project_root, force=True)

    assert "README.md" in result.files_updated
    assert (target_github / "README.md").read_text() == "new content"
