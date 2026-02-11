# Quick Remote Installation Guide

## ⚠️ 新手必讀：環境前置檢查

### 1. PowerShell 執行策略問題 (Windows)

**問題症狀**：
```
.\bootstrap.ps1 : 無法載入，因為在此系統上已停用指令碼執行。
File cannot be loaded because running scripts is disabled on this system.
```

**解決方案（三選一）**：

#### 方案 A：Bypass 模式執行（推薦，無需修改系統設定）
```powershell
# 單次繞過執行策略，不改變系統設定
powershell -ExecutionPolicy Bypass -File .\bootstrap.ps1
```

#### 方案 B：修改當前使用者執行策略（永久生效）
```powershell
# 只需執行一次（需要一般使用者權限）
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser

# 然後正常執行
.\bootstrap.ps1
```

#### 方案 C：使用 Python 或 Bash（跨平台備選方案）
```bash
# Python 版本（Windows/macOS/Linux 都可用）
curl -sO https://raw.githubusercontent.com/forgivesam168/ai-dev-workflow/main/scripts/bootstrap.py
python bootstrap.py
```

---

### 2. 其他常見環境問題

| 問題 | 檢查方式 | 解決方案 |
|------|----------|----------|
| **Git 未安裝** | `git --version` | [下載 Git](https://git-scm.com/downloads) |
| **PowerShell 版本過舊** | `$PSVersionTable.PSVersion` | [下載 PowerShell 7+](https://aka.ms/powershell) (建議) |
| **Node.js 未安裝** | `node --version` | [下載 Node.js 16+](https://nodejs.org) (MCP 伺服器需要) |
| **網路代理/防火牆** | 測試 `curl https://github.com` | 設定 Git 代理或使用企業內網鏡像 |
| **中文路徑問題** | 專案路徑包含中文 | 建議使用英文路徑（如 `C:\Projects\`） |

---

## 🚀 推薦安裝方式

### Windows (PowerShell) - 使用 Bypass 模式 ⭐

```powershell
# 進入你的專案目錄
cd C:\Projects\YourProject

# 下載腳本
Invoke-WebRequest -Uri "https://raw.githubusercontent.com/forgivesam168/ai-dev-workflow/main/scripts/bootstrap.ps1" -OutFile "bootstrap.ps1"

# 使用 Bypass 模式執行（不需要修改系統設定）
powershell -ExecutionPolicy Bypass -File .\bootstrap.ps1

# 清理
Remove-Item bootstrap.ps1
```

### Windows (PowerShell) - 一鍵安裝（需要先設定執行策略）

如果已經設定過 `Set-ExecutionPolicy RemoteSigned`：
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
