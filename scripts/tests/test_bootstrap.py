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


def test_sync_detects_conflicts_without_force(tmp_path: Path) -> None:
    """Test that sync detects conflicts when files differ and force=False."""
    source = tmp_path / ".github"
    project_root = tmp_path / "project-conflict"
    source.mkdir(parents=True)
    (source / "config.yml").write_text("new config")
    
    project_root.mkdir()
    target_github = project_root / ".github"
    target_github.mkdir(parents=True)
    (target_github / "config.yml").write_text("old config")
    
    result = bootstrap.sync_workflow_files(source, project_root, force=False)
    
    assert "config.yml" in result.files_conflicted
    assert "config.yml" not in result.files_updated
    assert "config.yml" not in result.files_added


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
    
    result = bootstrap.sync_workflow_files(source, project_root, force=True, backup=True)
    
    # Check that backup was created
    backup_dirs = list(project_root.glob(".github.backup-*"))
    assert len(backup_dirs) == 1
    assert (backup_dirs[0] / "old.txt").exists()
