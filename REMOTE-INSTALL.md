# Quick Remote Installation Guide

## 🚀 One-Line Installation

The bootstrap script now supports **automatic remote mode** - download and run directly without cloning the template repository.

### Windows (PowerShell)

```powershell
cd YourProject
Invoke-WebRequest -Uri "https://raw.githubusercontent.com/forgivesam168/ai-dev-workflow/main/scripts/bootstrap.ps1" -OutFile "bootstrap.ps1"; .\bootstrap.ps1; Remove-Item bootstrap.ps1
```

### macOS/Linux (Python)

```bash
cd YourProject
curl -sO https://raw.githubusercontent.com/forgivesam168/ai-dev-workflow/main/scripts/bootstrap.py && python3 bootstrap.py && rm bootstrap.py
```

### Linux/macOS (Bash)

```bash
cd YourProject
curl -sO https://raw.githubusercontent.com/forgivesam168/ai-dev-workflow/main/scripts/bootstrap.sh && bash bootstrap.sh && rm bootstrap.sh
```

---

## 📋 What Gets Installed

| Location | Files/Directories | Purpose |
|----------|-------------------|---------|
| `.github/` | `agents/` | AI agent role definitions |
| | `instructions/` | Coding standards and guidelines |
| | `prompts/` | Slash command prompt templates |
| | `skills/` | AI skill modules |
| | `mcp.json` | MCP server configuration |
| | `copilot-instructions.md` | Global Copilot instructions |
| **Root** | `.gitattributes` | Cross-platform line ending normalization |
| | `.editorconfig` | Editor formatting settings |

**Total**: 104 files (~2-3 MB)

### Protected Files (Never Overwritten)

- `.github/workflows/` - Your existing CI/CD pipelines
- `.github/CODEOWNERS` - Your existing code review rules
- `.github/dependabot.yml` - Your existing dependency update settings

---

## 🔧 Custom Template Repository

If you have a fork or custom template:

```powershell
# Windows
.\bootstrap.ps1 -RemoteRepo "https://github.com/your-org/custom-template.git"

# macOS/Linux
python3 bootstrap.py --remote-repo "https://github.com/your-org/custom-template.git"
```

---

## 🆕 How Remote Mode Works

1. **Auto-Detection**: Script detects it's not in the template repository
2. **Temporary Clone**: Creates `%TEMP%\ai-workflow-bootstrap-<timestamp>`
3. **Sparse Checkout**: Downloads only necessary files (`.github/`, `.gitattributes`, `.editorconfig`)
4. **File Sync**: Copies files to your project with conflict detection
5. **Cleanup**: Automatically removes temporary directory

**Example Output:**

```
ℹ️  自動啟用遠端模式（腳本不在模板 repo 內）
   將從 https://github.com/forgivesam168/ai-dev-workflow.git 下載模板

📥 從遠端下載模板...
   來源: https://github.com/forgivesam168/ai-dev-workflow.git
   暫存: C:\Users\...\Temp\ai-workflow-bootstrap-20260211-060000

✅ 遠端模板下載完成

同步工作流檔案...
✅ 新增 104 個檔案

🧹 清理臨時目錄...
✅ 臨時目錄已清理

✅ Bootstrap completed!
```

---

## 📚 Additional Resources

- [Full Installation Guide](./INSTALL.md) - Comprehensive installation documentation
- [Bootstrap User Guide](./BOOTSTRAP-GUIDE.md) - All parameters and features
- [Quick Start](./QUICKSTART.md) - Getting started with the workflow
- [Workflow Guide](./WORKFLOW.md) - 6-stage development workflow

---

## ⚠️ Troubleshooting

### "Source path not found" Error

**Old behavior** (before remote mode):
```
❌ 檔案同步失敗: Source path not found: D:\Project\.github
```

**New behavior** (auto remote mode):
```
ℹ️  自動啟用遠端模式（本地模板目錄不存在）
📥 從遠端下載模板...
✅ 遠端模板下載完成
```

### Git Clone Fails

If the remote download fails, check:
- Internet connection
- Git is installed (`git --version`)
- GitHub repository URL is correct
- Repository is public or you have access

**Fallback**: Use the [traditional method](./INSTALL.md#option-2-clone-template-first) by cloning the template repository first.

---

## 🔐 Security Note

The remote mode uses:
- Shallow clone (`--depth 1`) - downloads only the latest commit
- Sparse checkout - downloads only necessary directories
- No credentials required for public repositories
- Temporary directory auto-cleanup

**Total download**: ~2-3 MB (vs ~10+ MB for full repo)
