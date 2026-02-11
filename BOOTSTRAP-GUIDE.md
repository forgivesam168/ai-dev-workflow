# Bootstrap Installer User Guide

## Overview
The bootstrap installer is a cross-platform tool that initializes the AI development workflow into your project. It supports Windows (PowerShell), Linux, and macOS (Python).

## Quick Start

### Windows (PowerShell)
```powershell
# Standard installation
.\scripts\bootstrap.ps1

# Force overwrite existing files
.\scripts\bootstrap.ps1 -Force

# Update mode with backup
.\scripts\bootstrap.ps1 -Update

# Manual backup before sync
.\scripts\bootstrap.ps1 -Backup
```

### Linux/macOS (Python)
```bash
# Standard installation
python3 scripts/bootstrap.py

# Force overwrite existing files
python3 scripts/bootstrap.py --force

# Update mode with backup
python3 scripts/bootstrap.py --update

# Manual backup before sync
python3 scripts/bootstrap.py --backup
```

## Phase 2 Features

### 1. Conflict Detection (衝突檢測)

**What it does**: Detects when local files differ from template files.

**Example**:
```bash
$ python3 scripts/bootstrap.py

環境檢測:
✅ Git 2.52.0 detected
✅ Python 3.12.3 detected

同步工作流檔案...

✅ 新增 96 個檔案
⏭️  跳過 3 個檔案（workflows/CODEOWNERS 或內容相同）
⚠️  偵測到 1 個衝突檔案（內容不同但未覆蓋）

提示：使用 --force 或 --update 參數強制覆蓋衝突檔案
```

**Use cases**:
- Preventing accidental overwrites of customized files
- Reviewing changes before applying updates
- Safe initial setup in existing projects

### 2. Backup Mechanism (備份機制)

**What it does**: Creates timestamped backups before overwriting files.

**Example**:
```bash
$ python3 scripts/bootstrap.py --force --backup

同步工作流檔案...

✅ Backup created: /path/to/project/.github.backup-20260209-101936
✅ 更新 2 個檔案
⏭️  跳過 98 個檔案
```

**Backup format**:
```
.github.backup-YYYYMMDD-HHMMSS/
  ├── agents/
  ├── instructions/
  ├── prompts/
  └── ... (complete directory structure)
```

**Use cases**:
- Rollback capability after updates
- Testing workflow changes safely
- Preserving customizations before major updates

### 3. Update Mode (更新模式)

**What it does**: Complete workflow update with safety checks.

**Features**:
- Detects uncommitted Git changes
- Prompts for user confirmation
- Automatically creates backup
- Force overwrites conflicting files

**Example**:
```bash
$ python3 scripts/bootstrap.py --update

ℹ️  執行 --update 模式（將檢查衝突並建立備份）

環境檢測:
✅ Git 2.52.0 detected
...

⚠️  檢測到 .github/ 目錄有未提交的變更
   建議先提交變更後再執行 --update
是否繼續更新? (y/n): y

同步工作流檔案...

✅ Backup created: .github.backup-20260209-102530
✅ 更新 5 個檔案
...
```

**Use cases**:
- Upgrading to latest workflow version
- Synchronizing team standards
- Applying security patches

### 4. Smart Merge Strategy (智慧合併)

**Decision Logic**:

| Scenario | force=False | force=True | --update | --backup |
|----------|-------------|------------|----------|----------|
| File doesn't exist | ✅ Add | ✅ Add | ✅ Add | ✅ Add |
| Identical content | ⏭️ Skip | ⏭️ Skip | ⏭️ Skip | ⏭️ Skip |
| Different content | ⚠️ Conflict | ✅ Overwrite | ✅ Overwrite | 🔄 Backup first |
| Excluded pattern | ⏭️ Skip | ⏭️ Skip | ⏭️ Skip | ⏭️ Skip |

**Exclusion patterns** (always preserved):
- `.github/workflows/*` - Your CI/CD pipelines
- `.github/CODEOWNERS` - Your code ownership rules
- `.github/dependabot.yml` - Your dependency config

## Command Reference

### PowerShell Parameters

| Parameter | Type | Description |
|-----------|------|-------------|
| `-Force` | Switch | Force overwrite all files (no conflict detection) |
| `-Update` | Switch | Update mode: checks Git status, creates backup, overwrites |
| `-Backup` | Switch | Create backup before sync |
| `-SkipHooks` | Switch | Skip Git hooks installation |
| `-Verbose` | Switch | Show detailed file lists |
| `-Quiet` | Switch | Minimal output (errors only) |

### Python Arguments

| Argument | Type | Description |
|----------|------|-------------|
| `--force` | Flag | Force overwrite all files (no conflict detection) |
| `--update` | Flag | Update mode: checks Git status, creates backup, overwrites |
| `--backup` | Flag | Create backup before sync |
| `--verbose` | Flag | Show detailed file lists |

## Common Workflows

### First-Time Setup
```bash
# Clone your project
git clone https://github.com/your-org/your-project
cd your-project

# Run bootstrap
python3 /path/to/ai-workflow/scripts/bootstrap.py

# Commit the workflow
git add .github/
git commit -m "chore: initialize AI workflow"
git push
```

### Updating Existing Workflow
```bash
# Check for uncommitted changes first
git status .github/

# If clean, run update
python3 /path/to/ai-workflow/scripts/bootstrap.py --update

# Review changes
git diff .github/

# Commit if satisfied
git add .github/
git commit -m "chore: update AI workflow"
```

### Safe Testing of Updates
```bash
# Create backup manually
python3 scripts/bootstrap.py --backup

# Check what would be updated (no force)
python3 scripts/bootstrap.py --verbose

# Review conflicts
# ... decide which files to keep/update ...

# Apply updates
python3 scripts/bootstrap.py --force

# Or rollback if needed
rm -rf .github/
mv .github.backup-YYYYMMDD-HHMMSS/ .github/
```

### Custom Installation (Selective Files)
```bash
# Standard approach: bootstrap installs everything except workflows
python3 scripts/bootstrap.py

# Your workflows remain intact in .github/workflows/
# Your CODEOWNERS remains intact
# Your dependabot.yml remains intact

# Only workflow templates are installed to:
# - .github/agents/
# - .github/instructions/
# - .github/prompts/
# - .github/skills/
# - etc.
```

## Troubleshooting

### Issue: "Git is required but not found"
**Solution**: Install Git from https://git-scm.com/downloads

### Issue: "Python version too old"
**Solution**: Upgrade to Python 3.7+ from https://www.python.org/downloads/

### Issue: Backup creation fails
**Symptoms**:
```
⚠️  Backup failed: Permission denied
```
**Solution**: 
- Check disk space
- Verify write permissions on target directory
- Run with elevated privileges if needed

### Issue: Uncommitted changes warning
**Symptoms**:
```
⚠️  檢測到 .github/ 目錄有未提交的變更
```
**Solution**:
1. Commit your changes: `git add .github/ && git commit -m "save changes"`
2. Or stash them: `git stash`
3. Or force update: `python3 scripts/bootstrap.py --update` and answer 'y'

### Issue: Conflicts detected but not overwritten
**Symptoms**:
```
⚠️  偵測到 3 個衝突檔案（內容不同但未覆蓋）
```
**Solution**:
- Review conflicted files manually
- Backup important customizations
- Use `--force` or `--update` to overwrite:
  ```bash
  python3 scripts/bootstrap.py --force --backup
  ```

## FAQ

**Q: Will bootstrap overwrite my CI/CD workflows?**  
A: No. Bootstrap specifically excludes `.github/workflows/` to preserve your pipelines.

**Q: Can I rollback after running --update?**  
A: Yes. Update mode automatically creates a backup. Find it at `.github.backup-YYYYMMDD-HHMMSS/`.

**Q: What's the difference between --force and --update?**  
A: 
- `--force`: Overwrites files immediately (no Git checks, no auto-backup)
- `--update`: Checks Git status, prompts for confirmation, creates backup, then overwrites

**Q: How do I clean up old backups?**  
A: Manually delete backup directories:
```bash
rm -rf .github.backup-*
```

**Q: Can I customize which files are excluded?**  
A: Yes, but requires code modification. Edit the `excludePatterns` array in:
- PowerShell: `scripts/bootstrap.ps1` (line ~293)
- Python: `scripts/bootstrap.py` (line ~27)

**Q: Does bootstrap work with GitHub Codespaces?**  
A: Yes. Use the Python version:
```bash
python3 scripts/bootstrap.py
```

**Q: How do I verify bootstrap completed successfully?**  
A: Check for:
1. ✅ markers in output
2. `.github/` directory exists
3. Files match expected count (typically 97-100 files)
4. Git repository initialized (if it was a new project)

## Security Notes

- Bootstrap never commits or pushes changes (you control Git operations)
- Backups are stored locally (never uploaded)
- No network requests except for Git operations
- SHA256 hashing for file comparison (secure, collision-resistant)
- User confirmation required for destructive operations in update mode

## Performance

- **Typical runtime**: 2-5 seconds for first install
- **Update runtime**: 1-3 seconds (only changed files processed)
- **Backup overhead**: +1-2 seconds (one-time copy operation)
- **File comparison**: Near-instant (SHA256 hash caching)

## MCP Server Configuration

The workflow includes Model Context Protocol (MCP) server configurations for enhanced AI capabilities.

### Included MCP Servers

**Configuration files**: `.github/mcp.json` and `.vscode/mcp.json`

The following MCP servers are pre-configured:

| Server | Purpose | Requirements |
|--------|---------|--------------|
| `context7` | Library documentation lookup | Node.js + npx |
| `memory` | Conversation memory across sessions | Node.js + npx |

### Installation

MCP configuration files are automatically installed by bootstrap:

```bash
# After running bootstrap, this file will exist:
.github/mcp.json    # For GitHub Copilot CLI

# For VS Code users: manually copy to .vscode/ if needed
cp .github/mcp.json .vscode/mcp.json
```

**Note**: `.vscode/mcp.json` is not tracked in Git (excluded by `.gitignore`). VS Code users should manually create this file or rely on the VS Code Copilot extension's global configuration.

### Configuration

The configuration file (`.github/mcp.json`) uses this JSON structure:

```json
{
  "mcpServers": {
    "context7": {
      "type": "stdio",
      "command": "npx",
      "args": ["-y", "@upstash/context7-mcp"],
      "tools": ["*"]
    },
    "memory": {
      "type": "stdio",
      "command": "npx",
      "args": ["-y", "@modelcontextprotocol/server-memory"],
      "tools": ["*"]
    }
  }
}
```

**For VS Code users**: Copy `.github/mcp.json` to `.vscode/mcp.json` for editor integration.

### Customization

To add additional MCP servers (e.g., Brave Search, Filesystem):

1. Edit `.github/mcp.json` (and `.vscode/mcp.json` if using VS Code)
2. Add server configuration following the pattern above
3. For servers requiring API keys, use environment variables:
   ```json
   {
     "mcpServers": {
       "brave-search": {
         "type": "stdio",
         "command": "npx",
         "args": ["-y", "@modelcontextprotocol/server-brave-search"],
         "env": {
           "BRAVE_API_KEY": "${BRAVE_API_KEY}"
         },
         "tools": ["*"]
       }
     }
   }
   ```
4. Set environment variables in your shell:
   ```bash
   # Windows PowerShell
   $env:BRAVE_API_KEY = "your-api-key"
   
   # Linux/macOS
   export BRAVE_API_KEY="your-api-key"
   ```

### Verification

After bootstrap completes:

1. **VS Code**: Restart VS Code, MCP tools should appear in Copilot Chat
2. **CLI**: Run `copilot` and use `/mcp show` to verify servers are loaded
3. Check logs if servers fail to start (typically missing Node.js/npx)

### Troubleshooting MCP

**Issue: MCP servers not loading**
- Ensure Node.js and npx are installed: `node --version && npx --version`
- Check MCP logs in VS Code: Output → GitHub Copilot Chat
- Verify JSON syntax: `cat .github/mcp.json | jq .`

**Issue: API key not recognized**
- Verify environment variable is set: `echo $env:BRAVE_API_KEY` (Windows) or `echo $BRAVE_API_KEY` (Unix)
- Restart terminal/VS Code after setting environment variables
- Use absolute paths for sensitive environment files (avoid committing keys)

## Support

For issues or questions:
1. Check this guide first
2. Review PHASE2-SUMMARY.md for technical details
3. Open an issue in the repository
4. Contact your team's AI workflow maintainer

---

**Version**: Phase 2 (February 2026)  
**Compatible with**: Windows 10+, macOS 12+, Linux (Ubuntu 20.04+)  
**Requirements**: Git 2.0+, Python 3.7+ (for Python version), PowerShell 5.1+ (for PowerShell version)
