# 安裝指南

本指南協助新加入的團隊成員在專案中安裝與設定 AI 開發工作流程。

## 📋 前置需求

### 必需
- **Git**: 版本 2.0 或更高
- **PowerShell 7+** (Windows) 或 **Python 3.7+** (macOS/Linux)

### 可選
- **Node.js**: 版本 16+ (MCP 伺服器功能需要，如 context7、memory)
- **GitHub CLI**: 版本 2.0+ (可選，用於 template 功能)

### 檢查你的環境

```bash
# Windows (PowerShell)
git --version
pwsh --version
node --version

# macOS/Linux
git --version
python3 --version
node --version
```

---

## 🚀 安裝情境

### 情境 A：將工作流加入現有專案（推薦）

這是最常見的使用情境：將 AI 工作流加入現有專案而不影響既有設定。

#### 方式 1：自動遠端模式 Bootstrap（最快）⭐ NEW

Bootstrap 腳本現在會自動偵測是否在模板 repo 內，並自動從 GitHub 下載檔案。

**Windows (PowerShell):**
```powershell
# 進入你的專案目錄
cd C:\Projects\YourProject

# 下載並執行 bootstrap（自動從 GitHub 下載模板）
Invoke-WebRequest -Uri "https://raw.githubusercontent.com/forgivesam168/ai-dev-workflow/main/scripts/bootstrap.ps1" -OutFile "bootstrap.ps1"
.\bootstrap.ps1

# 清理
Remove-Item bootstrap.ps1
```

**明確指定遠端 Repo（自訂模板）:**
```powershell
# 如果你有 fork 或自訂的模板 repository
.\bootstrap.ps1 -RemoteRepo "https://github.com/your-org/your-template.git"
```

**macOS/Linux (Python):**
```bash
# 進入你的專案目錄
cd ~/Projects/YourProject

# 下載並執行 bootstrap
curl -O https://raw.githubusercontent.com/forgivesam168/ai-dev-workflow/main/scripts/bootstrap.py
python3 bootstrap.py

# 清理
rm bootstrap.py
```

**Linux/macOS (Bash):**
```bash
# 進入你的專案目錄
cd ~/Projects/YourProject

# 下載並執行 bootstrap
curl -O https://raw.githubusercontent.com/forgivesam168/ai-dev-workflow/main/scripts/bootstrap.sh
chmod +x bootstrap.sh
./bootstrap.sh

# 清理
rm bootstrap.sh
```

#### 方式 2：Clone 模板後執行 Bootstrap

```bash
# Clone 模板 repository（一次性設定）
git clone https://github.com/forgivesam168/ai-dev-workflow.git ~/ai-dev-workflow

# 進入你的專案目錄
cd ~/Projects/YourProject

# 從模板執行 bootstrap
pwsh ~/ai-dev-workflow/scripts/bootstrap.ps1
# 或: python3 ~/ai-dev-workflow/scripts/bootstrap.py
# 或: bash ~/ai-dev-workflow/scripts/bootstrap.sh
```

**會安裝什麼：**
- `.github/` 目錄，包含 agents、instructions、prompts、skills
- `.github/mcp.json` MCP 伺服器配置
- `.gitattributes` 跨平台行尾標準化設定
- Git repository 初始化（如果尚未存在）

**會保留什麼：**
- `.github/workflows/` (你的 CI/CD 管線)
- `.github/CODEOWNERS` (你的 code owners 設定)
- `.github/dependabot.yml` (你的依賴管理設定)

---

### 情境 B：從模板建立新專案

#### 方式 1：GitHub Template（最簡單）

1. 訪問 https://github.com/forgivesam168/ai-dev-workflow
2. 點擊 **"Use this template"** → **"Create a new repository"**
3. 填寫 repository 詳細資訊並建立
4. Clone 你的新 repository:
   ```bash
   git clone https://github.com/your-org/your-new-project.git
   cd your-new-project
   ```

#### 方式 2：手動 Clone 並初始化

```bash
# Clone 模板
git clone https://github.com/forgivesam168/ai-dev-workflow.git my-new-project
cd my-new-project

# 移除原始 git 歷史記錄（可選）
rm -rf .git
git init

# 部署工作流到 .github/
pwsh .\Init-Project.ps1

# 提交初始設定
git add .
git commit -m "chore: initialize project with AI workflow"
```

---

### 情境 C：僅參考學習（不安裝）

如果你只是想學習或參考工作流：

```bash
git clone https://github.com/forgivesam168/ai-dev-workflow.git
cd ai-dev-workflow

# 瀏覽文件
cat README.md          # 專案概覽
cat QUICKSTART.md      # 5分鐘快速上手
cat WORKFLOW.md        # 完整工作流文件
cat BOOTSTRAP-GUIDE.md # Bootstrap 使用指南
```

---

## ✅ 安裝後驗證

### 步驟 1：檢查檔案結構

```bash
# 驗證 .github 目錄
ls .github/agents/      # 應有 5 個 agent 檔案
ls .github/skills/      # 應有 24 個 skill 目錄
ls .github/instructions/ # 應有 instruction 檔案
ls .github/prompts/     # 應有 10 個 prompt 檔案

# 驗證根目錄檔案
cat .gitattributes      # 行尾標準化設定
cat .github/mcp.json    # MCP 伺服器設定
```

### 步驟 2：驗證 Agent 檔案

```bash
# 應存在以下檔案：
# .github/agents/architect.agent.md
# .github/agents/coder.agent.md
# .github/agents/code-reviewer.agent.md
# .github/agents/plan.agent.md
# .github/agents/spec.agent.md
```

### 步驟 3：初次提交

```bash
# 暫存所有工作流檔案
git add .github/ .gitattributes

# 提交
git commit -m "chore: initialize AI development workflow

- 新增 agents (architect, coder, code-reviewer, plan, spec)
- 新增 24 個 skills 提供專業能力
- 新增 instructions 定義編碼標準
- 新增 MCP 配置 (context7, memory)
- 新增 .gitattributes 標準化行尾"

# 推送到遠端
git push origin main
```

---

## 🔧 MCP 伺服器配置（可選）

工作流包含 MCP (Model Context Protocol) 伺服器配置以增強 AI 能力。

### 內建的 MCP 伺服器

| 伺服器 | 用途 | 需求 |
|--------|------|------|
| `context7` | 函式庫文件查詢 | Node.js + npx |
| `memory` | 跨對話記憶持久化 | Node.js + npx |

### 配置檔案

- **GitHub Copilot CLI**: `.github/mcp.json` (自動使用)
- **VS Code**: `.vscode/mcp.json` (需手動複製)

### VS Code 使用者設定

```bash
# 複製 MCP 設定到 VS Code 目錄
cp .github/mcp.json .vscode/mcp.json

# 注意：.vscode/ 已被 gitignore，此設定為開發者個人設定
```

### 驗證 MCP 伺服器

**Copilot CLI:**
```bash
copilot
> /mcp show
```

**VS Code:**
- 重新啟動 VS Code
- 開啟 Copilot Chat
- MCP 工具應自動出現

### 新增自訂 MCP 伺服器

編輯 `.github/mcp.json`（如使用 VS Code 也要編輯 `.vscode/mcp.json`）:

```json
{
  "mcpServers": {
    "context7": { /* 現有設定 */ },
    "memory": { /* 現有設定 */ },
    "your-custom-server": {
      "type": "stdio",
      "command": "npx",
      "args": ["-y", "@your-org/your-mcp-server"],
      "tools": ["*"]
    }
  }
}
```

對於需要 API key 的伺服器，使用環境變數：

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

設定環境變數：

```powershell
# Windows
$env:BRAVE_API_KEY = "your-api-key-here"

# macOS/Linux
export BRAVE_API_KEY="your-api-key-here"
```

---

## 📚 安裝後開始使用

### 1. 閱讀快速上手指南

```bash
cat QUICKSTART.md
```

此 5 分鐘指南涵蓋核心工作流程。

### 2. 測試工作流程協調器

**Copilot CLI:**
```bash
copilot
> /workflow
```

**VS Code:**
```
開啟 Copilot Chat 並輸入:
@workspace /workflow
```

這會顯示你目前的工作流程階段並建議下一步。

### 3. 開始你的第一個功能

**Copilot CLI:**
```bash
copilot
> 我要開始一個新功能的 brainstorming
```

**VS Code:**
```
在 Copilot Chat 輸入:
@workspace /brainstorm
```

系統會引導你完成 6 階段工作流程。

---

## 🔄 更新工作流程

更新到最新工作流程版本：

```bash
# 進入你的專案目錄
cd ~/Projects/YourProject

# 以更新模式執行 bootstrap（自動建立備份）
pwsh ~/ai-dev-workflow/scripts/bootstrap.ps1 --update

# 檢視變更
git diff .github/

# 若滿意則提交
git add .github/
git commit -m "chore: update AI workflow to latest version"
git push
```

**更新模式功能：**
- 自動建立備份 (`.github.backup-YYYYMMDD-HHMMSS/`)
- 更新前檢查未提交的變更
- 若偵測到變更會提示確認
- 強制覆蓋衝突的檔案

---

## 🆘 疑難排解

### 問題：「Git is required but not found」

**解決方法：**
```bash
# 安裝 Git
# Windows: winget install Git.Git
# macOS: brew install git
# Linux: sudo apt-get install git
```

### 問題：「Python version too old」

**解決方法：**
```bash
# 升級 Python 至 3.7+
# Windows: winget install Python.Python.3
# macOS: brew install python@3.11
# Linux: sudo apt-get install python3.11
```

### 問題：「MCP servers not loading」

**解決方法：**
```bash
# 安裝 Node.js
# Windows: winget install OpenJS.NodeJS
# macOS: brew install node
# Linux: sudo apt-get install nodejs npm

# 驗證安裝
node --version  # 應為 >= 16.0
npx --version
```

### 問題：「Permission denied」(macOS/Linux)

**解決方法：**
```bash
# 讓腳本可執行
chmod +x bootstrap.sh

# 或使用明確的直譯器執行
bash bootstrap.sh
```

### 問題：「.github/workflows/ 被覆蓋了」

**說明：** 這不應該發生。Bootstrap 明確排除 `workflows/`、`CODEOWNERS` 和 `dependabot.yml`。

**若真的發生：**
```bash
# 從備份還原
mv .github.backup-YYYYMMDD-HHMMSS/workflows/ .github/

# 或從 Git 還原
git checkout HEAD -- .github/workflows/
```

### 問題：「偵測到衝突但未覆蓋」

**說明：** Bootstrap 偵測到內容不同的檔案但未覆蓋（安全模式）。

**解決方法：**
```bash
# 方式 1：檢視衝突並手動決定
git diff .github/

# 方式 2：強制覆蓋（會先建立備份）
pwsh bootstrap.ps1 --force --backup

# 方式 3：更新模式（會先檢查 Git 狀態）
pwsh bootstrap.ps1 --update
```

---

## 🎯 下一步

成功安裝後：

1. **檢視工作流程**: 閱讀 `WORKFLOW.md` 了解詳細工作流程文件
2. **探索 Skills**: 瀏覽 `.github/skills/` 了解可用功能
3. **客製化 Instructions**: 編輯 `.github/instructions/` 以符合你的技術堆疊
4. **試用 Agents**: 使用 `/workflow` 開始你的第一個功能
5. **分享給團隊**: 將此指南傳送給新團隊成員

---

## 📞 支援

如有問題或疑問：

1. 先檢查本指南
2. 檢視 `BOOTSTRAP-GUIDE.md` 了解技術細節
3. 檢查 `QUICKSTART.md` 了解工作流程基礎
4. 在 repository 開啟 issue
5. 聯絡你的團隊 AI 工作流程維護者

---

**版本**: 2026 年 2 月  
**相容於**: Windows 10+、macOS 12+、Linux (Ubuntu 20.04+)  
**需求**: Git 2.0+、PowerShell 7+ 或 Python 3.7+  
**Repository**: https://github.com/forgivesam168/ai-dev-workflow
