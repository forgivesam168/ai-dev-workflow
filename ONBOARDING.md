# 新手環境檢查清單

## 🎯 給新同事的完整環境設置指南

這份文件幫助新加入團隊的同事快速設置開發環境，避免常見問題。

---

## ✅ 環境檢查清單

請依序檢查以下項目，確保全部通過後再執行 Bootstrap 安裝。

### 1. Git 安裝與版本檢查

```powershell
# 檢查 Git 是否已安裝
git --version

# 預期輸出: git version 2.x.x 或更高
```

**如果未安裝：**
```powershell
# Windows (推薦使用 winget)
winget install Git.Git

# 或下載安裝包
# https://git-scm.com/downloads
```

---

### 2. PowerShell 版本檢查 (Windows)

```powershell
# 檢查 PowerShell 版本
$PSVersionTable.PSVersion

# 預期輸出: 
# Major  Minor  Patch  PreReleaseLabel BuildLabel
# -----  -----  -----  --------------- ----------
# 7      5      0
```

**如果版本過舊（< 7.0）：**
```powershell
# 安裝 PowerShell 7.x
winget install Microsoft.PowerShell

# 或下載安裝包
# https://aka.ms/powershell
```

**注意**：Windows 內建的 PowerShell 5.1 也可以使用，但建議升級到 7.x 以獲得更好的體驗。

---

### 3. PowerShell 執行策略檢查

```powershell
# 檢查當前執行策略
Get-ExecutionPolicy -Scope CurrentUser

# 預期輸出: RemoteSigned 或 Unrestricted
# 如果是 Restricted 或 Undefined，需要修改
```

**如果顯示 `Restricted`：**

你有兩個選擇：

**選項 A：不修改系統設定（推薦新手）**
```powershell
# 執行腳本時使用 Bypass 模式
powershell -ExecutionPolicy Bypass -File .\bootstrap.ps1
```

**選項 B：一次性修改執行策略**
```powershell
# 設定為 RemoteSigned（最安全的選擇）
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser

# 確認設定
Get-ExecutionPolicy -Scope CurrentUser
```

---

### 4. Node.js 安裝（MCP 伺服器需要）

```powershell
# 檢查 Node.js 版本
node --version

# 預期輸出: v16.x.x 或更高 (建議 v18 LTS 或 v20 LTS)
```

**如果未安裝：**
```powershell
# Windows (推薦 LTS 版本)
winget install OpenJS.NodeJS.LTS

# 或下載安裝包
# https://nodejs.org (選擇 LTS 版本)
```

**驗證 npx 可用：**
```powershell
npx --version
```

---

### 5. Python 安裝（選用，跨平台備選方案）

```powershell
# 檢查 Python 版本
python --version

# 預期輸出: Python 3.7.x 或更高
```

**如果未安裝：**
```powershell
# Windows
winget install Python.Python.3

# 或下載安裝包
# https://www.python.org/downloads/
```

---

### 6. 網路連線檢查

```powershell
# 測試是否能連上 GitHub
Test-NetConnection -ComputerName github.com -Port 443

# 預期輸出: TcpTestSucceeded : True
```

**如果無法連線：**
- 檢查防火牆設定
- 確認是否需要設定 Proxy
- 聯絡 IT 部門確認網路政策

**設定 Git Proxy（如果需要）：**
```powershell
# 設定 HTTP Proxy
git config --global http.proxy http://proxy.company.com:8080

# 設定 HTTPS Proxy
git config --global https.proxy https://proxy.company.com:8080

# 取消 Proxy 設定
git config --global --unset http.proxy
git config --global --unset https.proxy
```

---

### 7. 路徑檢查（避免中文路徑）

```powershell
# 檢查當前路徑
Get-Location
```

**建議使用英文路徑：**
- ✅ 好的範例：`C:\Projects\MyProject`
- ✅ 好的範例：`D:\Work\hr-system`
- ❌ 避免範例：`C:\專案\我的項目`
- ❌ 避免範例：`D:\工作\人資系統`

**原因**：某些工具對非 ASCII 字元支援不佳，可能導致不可預期的錯誤。

---

## 🚀 環境設置完成後的安裝步驟

確認以上所有項目都通過後，執行以下指令：

### Windows (PowerShell) - 推薦方式

```powershell
# 1. 進入你的專案目錄
cd C:\Projects\YourProject

# 2. 下載 bootstrap 腳本
Invoke-WebRequest -Uri "https://raw.githubusercontent.com/forgivesam168/ai-dev-workflow/main/scripts/bootstrap.ps1" -OutFile "bootstrap.ps1"

# 3. 執行安裝（使用 Bypass 模式）
powershell -ExecutionPolicy Bypass -File .\bootstrap.ps1

# 4. 清理
Remove-Item bootstrap.ps1
```

### 預期安裝結果

```
🚀 Bootstrap AI Workflow Installer

環境檢測:
✅ Git 2.49.0 detected
✅ Python 3.11.9 detected
✅ PowerShell 7.5.0 detected
✅ Node.js 22.22.0 detected
✅ GitHub CLI 2.86.0 detected

ℹ️  自動啟用遠端模式（腳本不在模板 repo 內）
   將從 https://github.com/forgivesam168/ai-dev-workflow.git 下載模板

📥 從遠端下載模板...
   來源: https://github.com/forgivesam168/ai-dev-workflow.git
   暫存: C:\Users\...\Temp\ai-workflow-bootstrap-20260211-XXXXXX

✅ 遠端模板下載完成

同步工作流檔案...

✅ 新增 104 個檔案

🧹 清理臨時目錄...
✅ 臨時目錄已清理

✅ Bootstrap completed!
```

---

## 🔍 安裝後驗證

```powershell
# 檢查 .github 目錄是否建立
ls .github

# 應該看到以下目錄：
# - agents/
# - instructions/
# - prompts/
# - skills/
# - copilot-instructions.md
# - mcp.json

# 檢查檔案數量
(Get-ChildItem -Path .github -Recurse -File).Count
# 應該約為 104 個檔案
```

---

## ⚠️ 常見錯誤與解決方案

### 錯誤 1: 「無法載入，因為在此系統上已停用指令碼執行」

**解決方法**：使用 Bypass 模式
```powershell
powershell -ExecutionPolicy Bypass -File .\bootstrap.ps1
```

### 錯誤 2: 「Source path not found」

**原因**：使用了舊版本的腳本（2026-02-11 之前）

**解決方法**：重新下載最新版本
```powershell
Remove-Item bootstrap.ps1 -Force
Invoke-WebRequest -Uri "https://raw.githubusercontent.com/forgivesam168/ai-dev-workflow/main/scripts/bootstrap.ps1" -OutFile "bootstrap.ps1"
```

### 錯誤 3: 「Git clone failed」

**可能原因**：
1. 網路連線問題
2. 防火牆阻擋
3. Proxy 設定問題

**檢查方法**：
```powershell
# 測試 Git 連線
git ls-remote https://github.com/forgivesam168/ai-dev-workflow.git

# 如果失敗，設定 Proxy（詢問 IT 部門）
git config --global http.proxy http://proxy.company.com:8080
```

### 錯誤 4: 「npx: command not found」

**原因**：Node.js 未正確安裝或不在 PATH 中

**解決方法**：
```powershell
# 重新安裝 Node.js
winget install OpenJS.NodeJS.LTS

# 重新開啟 PowerShell 視窗（刷新 PATH）
# 驗證安裝
node --version
npx --version
```

---

## 📞 需要協助？

如果遇到以上清單沒有涵蓋的問題：

1. **檢查完整文件**：
   - `INSTALL.md` - 完整安裝指南
   - `INSTALL.zh-TW.md` - 中文版安裝指南
   - `REMOTE-INSTALL.md` - 遠端安裝快速指南

2. **聯絡團隊**：
   - 詢問資深同事
   - 在內部 Slack/Teams 頻道求助
   - 聯絡專案的 AI Workflow 維護者

3. **回報問題**：
   - 在專案 repo 開 issue
   - 提供完整的錯誤訊息
   - 說明你的作業系統和版本

---

## 🎓 延伸閱讀

安裝完成後，建議閱讀以下文件：

1. **QUICKSTART.md** - 5 分鐘快速入門
2. **WORKFLOW.md** - 完整的 6 階段工作流程
3. **BOOTSTRAP-GUIDE.md** - Bootstrap 進階用法
4. **AGENTS.md** - AI 代理使用說明

---

**版本**: 2026-02-11  
**維護者**: AI Dev Workflow Team  
**最後更新**: 新增 PowerShell 執行策略詳細說明
