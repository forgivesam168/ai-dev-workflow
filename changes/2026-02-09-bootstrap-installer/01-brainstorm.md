# Brainstorm: Bootstrap Installer for Team Workflow

## Risk Classification
**Level**: Medium ⚠️
- 跨平台兼容性（Windows 為主，但需支援其他 OS）
- 依賴管理（最小化依賴，Python 作為 fallback）
- 使用者體驗一致性（公開 repo，需考慮外部使用者）

## Workflow Path
**Standard Path** (Medium risk):
```
Brainstorm → Spec → Plan → Implement (TDD) → Review → Archive
```

## Goals
1. **核心目標**：
   - 讓團隊成員（Windows 為主）透過簡單指令初始化專案
   - 最小化依賴：僅需 Git + Python 3.x
   - 支援公開分發（任何人可使用）
   - 自動同步 `.github/` 工作流內容

2. **使用情境**：
   - 新專案初始化
   - 現有專案加入工作流
   - 工作流版本更新

3. **非目標**：
   - 不強制安裝 PowerShell 7+（雖然推薦）
   - 不依賴 Node.js（可選）
   - 不支援離線安裝（需 Git clone）

## Non-Goals
- 自動安裝所有依賴（僅檢測並提示）
- 支援 IDE 插件（專注於腳本分發）
- 企業級配置管理（簡單為主）

## Target Users
- **主要**：公司內部團隊（Windows 為主，使用 VS Code）
- **次要**：外部開源貢獻者（公開 repo）

## Constraints
- 僅依賴 Git 和 Python 3.x
- PowerShell 優先，Python 作為 fallback
- 腳本必須可獨立執行（無外部服務依賴）
- 支援 GitHub Template 機制

## Assumptions
- 團隊成員已安裝 Git
- Windows 系統通常有 PowerShell 5.1+（內建）
- Python 3.x 在開發環境中普遍存在
- 使用者有 GitHub 帳號（公開 repo）

## Questions Answered
1. **作業系統**：Windows 為主
2. **分發方式**：公開 GitHub Repo
3. **必備工具**：Git（必備），Python 3.x（fallback）
4. **初始化流程**：3 種方式（PowerShell 一鍵、Clone 執行、GitHub Template）
5. **版本更新**：手動執行更新腳本
6. **依賴處理**：檢測並提示，不強制安裝

## Options Analysis

### Option 1: PowerShell 優先 + Python Fallback（推薦）✅
**描述**：
- 主腳本：`bootstrap.ps1`（Windows 最佳體驗）
- 備用腳本：`bootstrap.py`（跨平台兼容）
- 額外腳本：`bootstrap.sh`（Linux/macOS 用戶）

**使用流程**：
```powershell
# Windows (推薦)
irm https://raw.githubusercontent.com/user/repo/main/install.ps1 | iex

# 或 Clone 後執行
git clone https://github.com/user/ai-workflow my-project
cd my-project
.\bootstrap.ps1
```

**腳本功能**：
- 檢測環境（OS、Git、Python、pwsh 版本）
- 同步 `.github/` 內容到專案根目錄
- 初始化 Git（如果尚未初始化）
- 可選：設定 Git hooks
- 顯示後續步驟指引

**優點**：
- ✅ Windows 原生體驗最佳（PowerShell）
- ✅ Python fallback 確保跨平台
- ✅ 無需 Node.js
- ✅ 支援公開分發

**缺點**：
- ⚠️ 需維護 3 個腳本版本（ps1/py/sh）
- ⚠️ 更新機制較手動

**複雜度**：Low-Medium  
**依賴**：Git, Python 3.x (fallback)

---

### Option 2: GitHub Template + Actions Auto-Sync
**描述**：
- 將 repo 設定為 GitHub Template
- 使用 GitHub Actions 自動同步上游更新

**使用流程**：
```bash
# 1. 在 GitHub 點擊 "Use this template"
# 2. Clone 到本地
gh repo create my-project --template user/ai-workflow --private
cd my-project

# 3. 自動同步（GitHub Actions）
# 或手動觸發
gh workflow run sync-upstream.yml
```

**優點**：
- ✅ GitHub 原生機制
- ✅ 支援自動更新（Actions）
- ✅ 適合組織內分發

**缺點**：
- ⚠️ 需要 GitHub Actions（公開 repo 免費）
- ⚠️ 仍需 bootstrap 腳本初始化

**複雜度**：Medium  
**依賴**：GitHub, GitHub CLI (可選)

---

### Option 3: NPM Package（不推薦）❌
**理由**：
- 需要 Node.js（與需求衝突）
- 對非 Node.js 用戶不友善
- 過度設計（簡單需求）

---

## Recommendation

**採用：Option 1 (PowerShell + Python) + Option 2 (GitHub Template) 混合**

**實施策略**：
1. **Phase 1**：建立 3 個 bootstrap 腳本
   - `bootstrap.ps1` (Windows 主力)
   - `bootstrap.py` (跨平台 fallback)
   - `bootstrap.sh` (Linux/macOS 用戶)

2. **Phase 2**：設定 GitHub Template
   - 標記 repo 為 template
   - 建立 `.github/template.yml`
   - （可選）設定 sync-upstream Actions

3. **Phase 3**：文件化
   - 更新 README.md（安裝指引）
   - 建立 INSTALLATION.md（詳細步驟）
   - 錄製示範影片（供團隊參考）

**為什麼這個方案**：
- 滿足「Windows 為主」需求（PowerShell 優先）
- Python fallback 確保兼容性
- 公開 repo 適用（無商業依賴）
- 簡單易用（3 種安裝方式）

## Decision Rationale
- **零依賴優先**：僅需 Git + Python
- **Windows 優化**：PowerShell 原生支援
- **公開友善**：外部使用者可直接使用
- **可維護性**：腳本簡單，易於維護

## Rollback Plan
- 如果 bootstrap 腳本失敗 → 提供手動安裝指引
- 如果 Python 不可用 → 顯示 Python 安裝連結
- 如果 Git 未安裝 → 終止並提示安裝 Git

## Next Steps
1. 執行 `/spec` 生成詳細規格文件
2. 執行 `/plan` 建立實施計畫
3. 執行 `/tdd` 實作 bootstrap 腳本
