# Brainstorm：Copilot CLI 官方文件對齊 + 指令架構重構

> **日期**：2026-04-08
> **發起者**：專案維護者
> **風險等級**：🟡 Medium（涉及多檔案更新、安全機制整合、指令架構重構）
> **工作流路徑**：Standard（Brainstorm → Spec → Plan → Implement → Review → Archive）
> **範圍擴展**：Phase 2 新增「指令架構重構」— 分析 copilot-instructions.md / agents / skills 的層級疊加問題

---

## Phase 0 — 進場與風險分類

### 目標
深度對比 Copilot CLI 官方文件（截至 2026-04-08）與本專案 `ai-dev-workflow` 的現有實作，識別功能缺口、過時配置、安全風險，並提出具體改善建議。

### 非目標
- 不重寫整個專案架構
- 不更換 6-Stage 工作流核心設計
- 不移除已有的 Skills/Agents/Instructions

### 風險分類：Medium
- 涉及安全機制（Hooks）的新增
- 涉及多份文件的更新（README、INSTALL、WORKFLOW、copilot-instructions）
- 涉及新功能整合（Copilot Memory、ACP、Custom Model Providers）
- 不涉及程式碼邏輯變更，主要為配置與文件

---

## Phase 1 — 研究發現：官方功能 vs 專案現狀

### 研究來源
1. **Copilot CLI README**（`github-copilot/copilot-cli`）
2. **官方文件**：`docs.github.com/copilot/concepts/agents/about-copilot-cli`
3. **官方文件**：`docs.github.com/copilot/how-tos/use-copilot-agents/use-copilot-cli`
4. **自訂指令文件**：`docs.github.com/copilot/how-tos/copilot-cli/customize-copilot/add-custom-instructions`
5. **Skills 文件**：`docs.github.com/copilot/concepts/agents/about-agent-skills`
6. **Hooks 文件**：`docs.github.com/copilot/concepts/agents/cloud-agent/about-hooks`
7. **Copilot Memory**：`docs.github.com/copilot/concepts/agents/copilot-memory`
8. **客製化速查表**：`docs.github.com/copilot/reference/customization-cheat-sheet`

### 功能對照表

| 官方功能 | 狀態 | 專案支援 | 嚴重程度 | 說明 |
|----------|------|----------|----------|------|
| Custom Instructions (`.github/copilot-instructions.md`) | ✅ GA | ✅ 完整 | — | 已正確實作 |
| Path-specific Instructions (`.github/instructions/*.instructions.md`) | ✅ GA | ✅ 完整 | — | 10 個 instruction 檔案 |
| AGENTS.md | ✅ GA | ✅ 完整 | — | 已配置 |
| Custom Agents (`.github/agents/`) | ✅ GA | ✅ 完整 | — | 5 個 Agent |
| Agent Skills (`.github/skills/`) | ✅ GA | ✅ 完整 | — | 28 個 Skills |
| Prompt Files (`.github/prompts/`) | ✅ GA | ✅ 完整 | — | 10 個 Prompt |
| MCP Servers | ✅ GA | ⚠️ 部分 | 中 | 僅 context7 + memory；缺 GitHub MCP 說明 |
| **Hooks** (`.github/hooks/*.json`) | ✅ GA | ❌ 缺失 | **高** | 完全未實作，對金融系統至關重要 |
| **Copilot Memory** | ✅ Preview | ❌ 未提及 | **高** | 無文件說明，可能與現有 instructions 衝突 |
| **ACP (Agent Client Protocol)** | ✅ GA | ❌ 未提及 | 低 | 進階整合功能，暫非核心需求 |
| **Custom Model Providers** | ✅ GA | ❌ 未提及 | **中** | Azure OpenAI 對金融合規有重要意義 |
| `allowed-tools` (SKILL.md frontmatter) | ✅ GA | ⚠️ 僅 2/28 | 低 | git-commit、make-skill-template 有用 |
| `excludeAgent` (instruction frontmatter) | ✅ GA | ⚠️ 僅 1 檔 | 低 | 僅 code-review.instructions.md 使用 |
| `.agents/skills/` (新 Skills 位置) | ✅ GA | ❌ 未支援 | 低 | 新增的第三方位置，文件未提及 |
| `COPILOT_CUSTOM_INSTRUCTIONS_DIRS` | ✅ GA | ❌ 未提及 | 低 | 多 repo 設定時有用 |
| **Autopilot Mode** | 🧪 Experimental | ❌ 未提及 | 中 | 新模式，影響工作流效率 |
| **Fleet Mode** (`/fleet`) | ✅ GA | ❌ 未提及 | 低 | 平行子代理執行 |
| **Plan Mode** (Shift+Tab) | ✅ GA | ⚠️ 不完整 | 中 | 文件僅提及 `/plan` 指令，未說明內建模式切換 |
| Session Management (`/resume`, `--continue`) | ✅ GA | ❌ 未提及 | 中 | 長工作流的 session 管理 |
| Programmatic CLI (`-p`, `--allow-tool`) | ✅ GA | ❌ 未提及 | 低 | CI/CD 自動化整合 |

---

## Phase 2 — 選項分析

### 選項 A：最小修補（Low Effort）
**複雜度**：Low ｜ **風險**：Low ｜ **覆蓋率**：~40%

- 更新 README 數字（Skills 24 → 28）
- 補充 Plan Mode (Shift+Tab) 文件
- 更新 WORKFLOW.md 補充 CLI 互動模式
- 修正 SECURITY.md placeholder

**優點**：快速、低風險
**缺點**：未解決核心安全缺口（Hooks、Memory）

### 選項 B：安全優先升級（Recommended）⭐
**複雜度**：Medium ｜ **風險**：Medium ｜ **覆蓋率**：~80%

- **新增 Hooks 配置**（`.github/hooks/security-hooks.json`）
  - `preToolUse`：禁止危險命令、secret scanning
  - `postToolUse`：稽核日誌
  - `sessionStart/End`：session 追蹤
- **新增 Copilot Memory 說明文件**
- **新增 Custom Model Provider 指引**（Azure OpenAI 合規）
- **更新所有現有文件**修正數字與缺漏
- **補充 Session Management 文件**
- **補充 Autopilot / Fleet Mode 文件**

**優點**：解決最重要的安全缺口、提升金融合規能力
**缺點**：需較多時間、Hooks 需要測試

### 選項 C：全面升級（High Effort）
**複雜度**：High ｜ **風險**：Medium-High ｜ **覆蓋率**：~95%

包含選項 B 的所有內容，額外：
- 所有 28 個 Skills 補充 `allowed-tools` 評估
- 所有 Instructions 補充 `excludeAgent` 評估
- 新增 `.agents/skills/` 位置支援
- 新增 ACP 整合文件
- 新增 Programmatic CLI CI/CD 範例
- 新增 `COPILOT_CUSTOM_INSTRUCTIONS_DIRS` 多 repo 指引
- 重構 INSTALL.md 納入模型提供者配置
- 建立 Hooks 測試框架

**優點**：全面對齊官方最新功能
**缺點**：工作量大、部分功能尚在 Preview

---

## Phase 3 — 建議與決策

### 推薦：選項 B（安全優先升級）

**理由**：
1. **金融系統的安全底線**：Hooks 是 Copilot CLI 提供的原生安全機制，可在 `preToolUse` 階段攔截危險操作、掃描 secrets。本專案定位為「金融等級 AI 開發工作流」，缺少此機制是顯著的安全缺口。
2. **Copilot Memory 衝突風險**：Memory 會自動學習 repo 的模式，可能與本專案精心設計的 instructions 產生衝突。必須明確文件化如何共存或控制。
3. **Azure OpenAI 合規需求**：金融團隊經常需要控制資料流向，Custom Model Provider 讓團隊可以使用 Azure OpenAI（資料不出境），這對合規至關重要。
4. **投入產出比最佳**：覆蓋 80% 的功能缺口，但僅需中等工作量。

---

## 具體建議清單（按優先順序）

### 🔴 HIGH — 安全與合規（必須處理）

#### H1. 新增 Hooks 安全配置
- 建立 `.github/hooks/security-hooks.json`
- 實作 `preToolUse` hook：
  - 禁止 `rm -rf`、`git push --force`、`DROP TABLE` 等危險命令
  - 整合 secret scanning（掃描輸出中的 API keys、tokens）
- 實作 `sessionStart` hook：稽核日誌記錄
- 實作 `postToolUse` hook：記錄所有工具執行結果
- **新增 skill**：`hooks-security` 讓團隊了解如何配置

#### H2. 新增 Copilot Memory 共存指引
- 在 WORKFLOW.md 或新文件中說明：
  - Copilot Memory 是什麼、如何運作
  - 與現有 custom instructions 的關係（互補而非取代）
  - 如何檢視 / 刪除 Memory（管理者操作）
  - 建議的 Memory 策略（啟用但搭配 instructions 作為 SSOT）
  - Memory 28 天自動過期的特性

#### H3. 新增 Custom Model Provider 配置指引
- 在 INSTALL.md 新增章節：
  - Azure OpenAI 配置（`COPILOT_PROVIDER_BASE_URL`、`COPILOT_PROVIDER_TYPE=azure`）
  - 資料駐留（data residency）說明
  - Ollama 本地模型配置（開發/離線使用）
  - 模型選擇建議（128k+ context window、需支援 tool calling + streaming）

### 🟡 MEDIUM — 功能完整性（強烈建議）

#### M1. 更新 WORKFLOW.md 補充 CLI 互動模式
- Plan Mode (Shift+Tab) 的使用說明
- Autopilot Mode (experimental) 的說明與風險提示
- Session 管理：`/resume`、`--continue`、`/compact`
- Context 管理：`/context`、auto-compaction（95% 自動壓縮）

#### M2. 修正文件數字不一致
- README.md：Skills 24 → 28
- INSTALL.md 驗證步驟：Skills 24 → 28
- 確認所有文件中的數字一致

#### M3. 補充 MCP 配置說明
- 說明 GitHub MCP server 是 Copilot CLI 內建的（不需額外配置）
- 但 VS Code 使用者可能需要手動配置
- 更新 `.github/mcp.json` 加入說明註解

#### M4. 充實 SECURITY.md
- 目前僅是 placeholder（3 行）
- 應補充：
  - Copilot CLI 安全考量（trusted directories、tool approval）
  - Hooks 安全策略
  - Secrets 管理規範
  - `--allow-all-tools` / `--yolo` 的風險說明

### 🟢 LOW — 錦上添花（未來迭代）

#### L1. `.agents/skills/` 新位置支援
- 在 agent-skills.instructions.md 中補充此新位置
- 更新 make-skill-template 的 SKILL.md

#### L2. Programmatic CLI 整合
- 新增 CI/CD 範例：`copilot -p "..." --allow-tool='shell(npm)'`
- 說明 `--allow-tool`、`--deny-tool` 的使用

#### L3. `COPILOT_CUSTOM_INSTRUCTIONS_DIRS` 文件
- 多 repo 共享 instructions 的進階場景

#### L4. Fleet Mode 文件
- `/fleet` 平行子代理執行的使用場景

#### L5. 全面審查 `allowed-tools`
- 評估 28 個 Skills 是否需要 `allowed-tools` frontmatter
- 對安全敏感的 Skills 應保守（不預設允許 shell）

---

## Phase 2-B — 指令架構重構審計（Pointer-Style Guidance）

> 此章節源自三個平行審計代理的完整分析結果。
> 核心問題：copilot-instructions.md + agents + skills 三層疊加導致 **56% 以上內容重複**，浪費 LLM context window、注意力稀釋、行為不確定。

### 🏗️ 架構原則（已確認）

| 層級 | 檔案 | 角色 | 載入行為 | 目標 |
|------|------|------|---------|------|
| **Constitution** | `copilot-instructions.md` | 安全紅線 + 語言規範 + 財務精度 | **每次互動都載入** | ≤40 行 |
| **Role (WHO)** | `agents/*.agent.md` | 人格定義、專注領域、核心原則 | 選擇 agent 時載入 | 每個 ≤30 行 |
| **Playbook (HOW)** | `skills/*/SKILL.md` | 詳細流程、模板、腳本 | 漸進式載入（相關時才載入） | 不限（按需載入） |
| **Code Style (WHAT)** | `instructions/*.instructions.md` | 語言/框架特定編碼規範 | `applyTo` glob 匹配時載入 | 已良好設計 |

### 📊 copilot-instructions.md 審計結果

**現況**：131 行 ≈ 1,965 tokens（每次互動都消耗）

| 區段 | 行數 | KEEP | POINTER | REMOVE | 說明 |
|------|------|------|---------|--------|------|
| 標題 & SSOT 聲明 | 6 | 1 | 0 | 5 | SSOT 內容已在其他文件 |
| §1 Rule of Law | 17 | 2 | 14 | 1 | 用指標替代詳細列表 |
| §2 Agent Personas | 34 | 2 | 3 | 29 | 與 agent 檔案大量重複 |
| §3 6-Stage Workflow | 61 | 4 | 14 | 43 | 與 WORKFLOW.md 重複 |
| §4 Communication Style | 8 | 8 | 0 | 0 | ✅ 全部保留（核心行為規範）|
| Final Reminder | 2 | 2 | 0 | 0 | ✅ 全部保留（安全提醒）|
| **合計** | **131** | **19 (15%)** | **31 (24%)** | **78 (60%)** | **目標：≤40 行** |

**關鍵發現**：
- §2 Agent Personas（34行）完全複製 5 個 agent 檔案的內容 → **全部刪除，用 1 行指標替代**
- §3 6-Stage Workflow（61行）完全複製 WORKFLOW.md 和 workflow-orchestrator skill → **全部刪除，用 2 行指標替代**
- §1 Rule of Law 的詳細列表可精簡為「遵循 instructions/ 目錄下的對應規範」

### 📊 Agent 檔案審計結果

| Agent | 現有行數 | 目標行數 | 重疊程度 | 主要重疊對象 | 處置 |
|-------|---------|---------|---------|-------------|------|
| `plan.agent.md` | **77** | ≤25 | 🔴 Very High | implementation-planning, brainstorming, specification, tdd-workflow, code-security-review | 大幅精簡 |
| `spec.agent.md` | 50 | ≤25 | 🟡 Medium | specification skill | 移除 discovery process 細節 |
| `architect.agent.md` | 48 | ≤25 | 🟡 Medium | specification, implementation-planning | 移除 3-step process 細節 |
| `coder.agent.md` | 36 | ≤25 | 🟡 Medium | tdd-workflow skill | 保留環境設定，移除 R-G-R 步驟 |
| `code-reviewer.agent.md` | 35 | ≤25 | 🟡 Medium | code-security-review skill | 保留 persona，移除 4-section 流程 |

**最大問題**：`plan.agent.md` 共 77 行，橫跨 5 個 skills 的重疊內容。

### 📊 Skills 交叉比對結果

| # | Skill | 對應 Agent | 狀態 | 建議 |
|---|-------|-----------|------|------|
| 1 | brainstorming | (orchestrator) | ✅ 良好 | Skill 為主，orchestrator 僅路由 |
| 2 | specification | spec.agent.md | ✅ 良好 | 分工明確（agent=人格, skill=流程）|
| 3 | implementation-planning | plan.agent.md | ⚠️ 失配 | Agent 輸出格式過於簡化 |
| 4 | **plan-from-spec** | plan.agent.md | ❌ **重複** | **合併至 implementation-planning** |
| 5 | tdd-workflow | coder.agent.md | ✅ 良好 | 環境設定移入 skill prerequisites |
| 6 | code-security-review | code-reviewer.agent.md | ✅ 良好 | 在 skill 中加入 agent 角色引用 |
| 7 | workflow-orchestrator | copilot-instructions.md §3 | ⚠️ 重複 | 從 §3 移入 skill，§3 僅保留指標 |
| 8 | work-archiving | (none) | ✅ 獨立 | 完整且無重複 |

### 🎯 重構行動清單

#### 🔴 Critical（必須處理）

| ID | 行動 | 影響檔案 | 說明 |
|----|------|---------|------|
| R1 | **精簡 copilot-instructions.md** | `copilot-instructions.md` | 從 131 行精簡至 ≤40 行，保留 constitution + 指標 |
| R2 | **精簡 plan.agent.md** | `agents/plan.agent.md` | 從 77 行精簡至 ≤25 行，保留角色定義 |
| R3 | **合併 plan-from-spec** | `skills/plan-from-spec/` | 合併至 implementation-planning，刪除獨立 skill |

#### 🟡 High（強烈建議）

| ID | 行動 | 影響檔案 | 說明 |
|----|------|---------|------|
| R4 | 精簡 spec.agent.md | `agents/spec.agent.md` | 從 50 行精簡至 ≤25 行 |
| R5 | 精簡 architect.agent.md | `agents/architect.agent.md` | 從 48 行精簡至 ≤25 行 |
| R6 | 精簡 coder.agent.md | `agents/coder.agent.md` | 保留環境設定，移除 R-G-R 程序 |
| R7 | 精簡 code-reviewer.agent.md | `agents/code-reviewer.agent.md` | 保留 persona，移除程序性內容 |
| R8 | 更新 AGENTS.md | `AGENTS.md` | 同步新架構說明 |

#### 🟢 Medium（建議處理）

| ID | 行動 | 影響檔案 | 說明 |
|----|------|---------|------|
| R9 | 移環境設定到 tdd-workflow prerequisites | `skills/tdd-workflow/` | 從 coder.agent.md 移入 |
| R10 | 統一 severity 命名 | agent + skill | BLOCKER/WARNING/NIT vs Critical/High/Medium |

### 📐 重構前後對比（預估）

| 檔案 | 重構前 (tokens) | 重構後 (tokens) | 節省 |
|------|----------------|----------------|------|
| copilot-instructions.md | ~1,965 | ~600 | **69%** |
| plan.agent.md | ~1,155 | ~375 | **68%** |
| spec.agent.md | ~750 | ~375 | **50%** |
| architect.agent.md | ~720 | ~375 | **48%** |
| coder.agent.md | ~540 | ~375 | **31%** |
| code-reviewer.agent.md | ~525 | ~375 | **29%** |
| **每次互動的固定開銷** | **~1,965** | **~600** | **69%** |

> **關鍵指標**：copilot-instructions.md 是唯一「每次互動都載入」的檔案。
> 從 1,965 tokens 降到 600 tokens，等於每次對話多出 ~1,365 tokens 給實際工作內容。

---

## 假設與限制

### 假設
1. 團隊使用 Copilot CLI v1.0+ 或 VS Code 最新版
2. 團隊有 Copilot Pro/Pro+ 或 Enterprise 訂閱
3. 部分成員可能使用 Azure OpenAI（合規需求）
4. Hooks 功能在 CLI 和 Cloud Agent 中均為 GA

### 限制
1. Copilot Memory 仍在 Public Preview，行為可能變更
2. ACP 是較新功能，穩定性待觀察
3. Hooks 的 `preToolUse` 執行是同步的，可能影響效能
4. 部分功能（如 Autopilot Mode）仍標記為 Experimental
