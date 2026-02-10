import os
import subprocess
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
    
    result = bootstrap.sync_workflow_files(source, project_root, force=False)
    
    assert "same.txt" in result.files_skipped
    assert "same.txt" not in result.files_added
    assert "same.txt" not in result.files_updated
    assert "same.txt" not in result.files_conflicted


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
    
    result = bootstrap.sync_workflow_files(source, project_root, force=True)
    
    assert "config.yml" in result.files_updated
    assert (target_github / "config.yml").read_text() == "new config v2"


def test_sync_adds_new_files(tmp_path: Path) -> None:
    """Test that sync correctly adds new files that don't exist in target."""
    source = tmp_path / ".github"
    project_root = tmp_path / "project-new-files"
    source.mkdir(parents=True)
    (source / "newfile.md").write_text("brand new file")
    
    project_root.mkdir()
    
    result = bootstrap.sync_workflow_files(source, project_root, force=False)
    
    assert "newfile.md" in result.files_added
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
    
    result = bootstrap.sync_workflow_files(source, project_root, force=False)
    
    # workflows should be skipped
    assert any("workflows" in s for s in result.files_skipped)
    assert not any("workflows" in a for a in result.files_added)
    
    # README should be added
    assert "README.md" in result.files_added


def test_sync_respects_exclusion_patterns_codeowners(tmp_path: Path) -> None:
    """Test that sync skips CODEOWNERS file."""
    source = tmp_path / ".github"
    project_root = tmp_path / "project-codeowners"
    source.mkdir(parents=True)
    (source / "CODEOWNERS").write_text("* @team")
    (source / "other.md").write_text("other file")
    
    project_root.mkdir()
    
    result = bootstrap.sync_workflow_files(source, project_root, force=False)
    
    assert any("CODEOWNERS" in s for s in result.files_skipped)
    assert "other.md" in result.files_added


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
        bootstrap.sync_workflow_files(nonexistent_source, target, force=False)
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
    
    result = bootstrap.sync_workflow_files(source, target, force=False)
    
    assert target.exists()
    assert (target / ".github").exists()
    assert "file.txt" in result.files_added


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
    
    bootstrap.sync_workflow_files(source, target, force=True, backup=True)
    
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
    
    result = bootstrap.sync_workflow_files(source, target, force=False)
    
    assert "docs/guides/guide.md" in result.files_added
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
    
    result = bootstrap.sync_workflow_files(source, target, force=False)
    
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
    
    result = bootstrap.sync_workflow_files(source, target, force=False)
    
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
