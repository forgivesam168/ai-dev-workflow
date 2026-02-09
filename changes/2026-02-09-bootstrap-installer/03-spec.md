# Spec: Bootstrap Installer for AI Workflow Template

## Overview
建立一套跨平台的 bootstrap 安裝工具，讓團隊成員（Windows 為主）與外部使用者能透過簡單指令將 AI 開發工作流初始化到任何專案中。

## Goals
1. **簡化初始化流程**：一個指令完成專案設定
2. **跨平台支援**：Windows（主）、macOS、Linux
3. **最小化依賴**：僅需 Git + Python 3.x
4. **公開分發**：任何人可使用（GitHub public repo）
5. **自動同步**：將 `.github/` 內容部署到專案

## Non-Goals
- ❌ 強制安裝依賴（PowerShell 7+、Node.js）
- ❌ 支援離線安裝
- ❌ 企業級配置管理
- ❌ IDE 插件開發

## Target Users

### 主要使用者（內部團隊）
- **角色**：公司開發團隊成員
- **環境**：Windows 10/11, VS Code
- **技能**：熟悉 Git 基本操作
- **需求**：快速初始化專案並開始使用 AI 工作流

### 次要使用者（外部貢獻者）
- **角色**：開源社群開發者
- **環境**：混合（Windows/macOS/Linux）
- **技能**：有經驗的開發者
- **需求**：了解工作流運作方式並貢獻改進

## User Stories

### Story 1: 新專案初始化
**As a** 團隊成員  
**I want to** 透過一個指令初始化新專案並載入工作流  
**So that** 我可以立即開始使用標準化的開發流程

**Acceptance Criteria**:
- [ ] 執行 `.\bootstrap.ps1` 後，`.github/` 內容自動同步到專案
- [ ] 檢測 Git 是否初始化，未初始化則自動執行 `git init`
- [ ] 顯示環境檢測結果（Git、Python、pwsh 版本）
- [ ] 提示可選依賴安裝連結（GitHub CLI、PowerShell 7+）
- [ ] 執行時間 < 30 秒（正常網路環境）

---

### Story 2: 現有專案加入工作流
**As a** 團隊成員  
**I want to** 在現有專案中加入 AI 工作流  
**So that** 舊專案也能受益於標準化流程

**Acceptance Criteria**:
- [ ] 檢測專案是否已有 `.github/copilot-instructions.md`
- [ ] 如果存在，詢問是否覆蓋（`--force` 強制覆蓋）
- [ ] 不會刪除現有的 `.github/workflows/`（保留 CI/CD）
- [ ] 顯示變更摘要（新增/覆蓋的檔案清單）

---

### Story 3: 跨平台使用（Python Fallback）
**As a** macOS/Linux 使用者  
**I want to** 使用 Python 腳本初始化專案  
**So that** 我不需要安裝 PowerShell

**Acceptance Criteria**:
- [ ] `python bootstrap.py` 提供相同功能
- [ ] 自動檢測 Python 版本（需 3.7+）
- [ ] 顯示與 PowerShell 版本一致的輸出格式
- [ ] 錯誤訊息友善且可操作

---

### Story 4: 版本更新
**As a** 使用者  
**I want to** 更新工作流到最新版本  
**So that** 我的專案能使用最新的 prompts 和 skills

**Acceptance Criteria**:
- [ ] 執行 `.\bootstrap.ps1 --update` 同步最新內容
- [ ] 顯示版本差異（如果有版本檢測機制）
- [ ] 備份現有 `.github/` 為 `.github.backup/`（可選）
- [ ] 保留客製化修改（提示衝突檔案）

---

### Story 5: GitHub Template 使用
**As a** GitHub 使用者  
**I want to** 使用 "Use this template" 建立新專案  
**So that** 我可以快速複製整個工作流結構

**Acceptance Criteria**:
- [ ] Repo 標記為 GitHub Template
- [ ] Template 包含 `.github/template.yml` 設定
- [ ] 初始化後自動執行 bootstrap（透過 Actions 或手動）
- [ ] README 包含完整的 template 使用指引

---

## Functional Requirements

### FR1: 環境檢測
**必需檢查**：
- Git 是否安裝（版本 ≥ 2.0）
- Python 是否可用（版本 ≥ 3.7）
- 當前目錄是否為 Git repo

**可選檢查**：
- PowerShell 版本（建議 7+）
- GitHub CLI 是否安裝
- Node.js 是否安裝（供 skills 使用）

**輸出範例**：
```
✅ Git 2.43.0 detected
✅ Python 3.11.5 detected
⚠️  PowerShell 5.1 (建議升級到 7+)
ℹ️  GitHub CLI 未安裝（可選，用於 template 功能）
```

---

### FR2: 檔案同步
**來源**：`ai-workflow-template/.github/`  
**目標**：`<project-root>/.github/`

**同步規則**：
- 複製所有 `.github/` 內容到專案根目錄
- 保留現有 `.github/workflows/`（不覆蓋 CI/CD）
- 如果檔案已存在且內容不同，詢問使用者（或用 `--force`）

**排除清單**（不覆蓋）：
- `.github/workflows/` 中的自訂 Actions
- `.github/CODEOWNERS`（如果已存在）
- `.github/dependabot.yml`（如果已存在）

---

### FR3: Git 初始化
**條件**：如果當前目錄不是 Git repo

**執行**：
```powershell
git init
git add .
git commit -m "chore: initialize AI workflow"
```

**可選**：設定 Git hooks
- Pre-commit: 檢查 secrets（可選）
- Commit-msg: 驗證 conventional commits（可選）

---

### FR4: 更新機制
**指令**：`.\bootstrap.ps1 --update`

**行為**：
1. 檢測本地 `.github/` 是否有修改
2. 如果有，警告並詢問是否備份
3. 從遠端拉取最新 `.github/` 內容
4. 顯示變更摘要

---

### FR5: 錯誤處理
**情境 1：Git 未安裝**
```
❌ Git is required but not found.
Please install Git: https://git-scm.com/downloads
```

**情境 2：Python 版本過舊**
```
⚠️  Python 3.6 detected. Python 3.7+ is recommended.
Continue anyway? (y/n)
```

**情境 3：網路錯誤**
```
❌ Failed to fetch remote content.
Please check your internet connection or try:
  git clone https://github.com/your-org/ai-workflow
```

---

## Technical Considerations

### Security Requirements
- ✅ 不提交任何 secrets 到 repo
- ✅ 範例配置檔案不包含真實 API keys
- ✅ 腳本不執行任何提升權限的操作
- ✅ 所有下載來源使用 HTTPS
- ✅ 驗證下載內容的完整性（可選：SHA-256）

### Performance Requirements
- 初始化時間 < 30 秒（正常網路）
- 腳本大小 < 100 KB（單檔案）
- 記憶體使用 < 50 MB

### Compatibility Requirements
| 平台 | 最低版本 | 建議版本 |
|------|---------|---------|
| Windows | 10 | 11 |
| PowerShell | 5.1 | 7.4+ |
| Python | 3.7 | 3.11+ |
| Git | 2.0 | 2.40+ |

---

## Success Metrics
1. **安裝成功率** ≥ 95%（首次執行）
2. **使用者滿意度** ≥ 4/5（內部調查）
3. **文件完整度**：所有使用情境有範例
4. **錯誤回報率** < 5%（執行失敗需人工介入）

---

## Open Questions
1. **版本號管理**：是否需要在腳本中加入版本檢測？
2. **備份機制**：`--update` 時是否自動備份？
3. **衝突解決**：如何處理客製化修改與上游更新的衝突？
4. **離線支援**：是否需要支援離線安裝包？（目前：No）

---

## Acceptance Criteria (Summary)
- [ ] PowerShell 腳本可在 Windows 執行並完成初始化
- [ ] Python 腳本可在所有平台執行並提供相同功能
- [ ] Bash 腳本可在 Linux/macOS 執行（基本功能）
- [ ] 環境檢測完整且輸出友善
- [ ] 檔案同步正確，不破壞現有 CI/CD
- [ ] 錯誤處理完善，訊息可操作
- [ ] README 包含完整安裝與故障排除指引
- [ ] 所有 user stories 的 acceptance criteria 通過

---

## Next Steps
1. 執行 `/plan` 建立詳細實施計畫
2. 確認測試策略（單元測試 + 整合測試）
3. 開始 TDD 開發（`/tdd`）
