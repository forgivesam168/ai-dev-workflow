# 🚀 Quick Start Guide

## 5 分鐘上手 AI 工作流程

### Step 1: 選擇你的環境

- **Codex CLI**: 終端機主力使用者 → 使用自然語言、`/skills`、`$skill-name`
- **Claude Code / Antigravity**: 終端機或 IDE 使用者 → 使用自然語言 + 共享 `skills/`
- **VS Code Copilot**: 編輯器內使用者 → 可用 workflow prompt 斜線指令快捷

### Step 2: 開始一個新功能

**CLI**:
```bash
codex
> 我要開始一個新功能的 brainstorming
```

**VS Code**:
```
在 Copilot Chat 輸入：
/brainstorm 或「我要開始 brainstorming」
```

### Step 3: 依 selected execution mode 完成必要階段

```
1. Brainstorm → 2. Spec → 3. Plan → 4. TDD → 5. Review → 6. Archive
```

> 💡 **三種 execution modes**：
>
> 🟢 **Simple**：局部、可逆且有可靠 targeted verification；不要求 repository package、Review artifact 或 Archive。
>
> 🟡 **Standard**：一個 plan/lifecycle SSOT；canonical trigger 成立時要求 compact package，自願建立的 package 依其宣告驗證。
>
> 🔴 **High-Risk**：完整 Workflow 與 full package，包含 independent Review 與 pre-merge Closeout。

每個階段完成後，輸入「what's next」查看下一步。

### Step 4: 使用推薦的 Agent

系統會推薦合適的 agent（例如：spec-agent）

**CLI**: `/agent` → 選擇推薦的 agent

**VS Code**: `@workspace #spec-agent`

---

## 📋 快速參考

### Lifecycle stage 指令對照（High-Risk 全部使用；Standard 依 selected stages）

| 階段 | CLI 輸入（自然語言） | VS Code 輸入（斜線指令） | 推薦 Agent |
|------|---------------------|--------------------------|-----------|
| 0. 流程狀態 | what's next / 我想知道目前在哪個階段 | - | - |
| 1. Brainstorm | 我想開始 brainstorming / 我要開始一個新功能的 brainstorming | `/brainstorm` | brainstorm-agent |
| 2. Spec | 產生 spec / 幫我寫規格文件 | `/spec` | spec-agent |
| 3. Plan | 規劃實作計畫 / 幫我拆解任務 | `/create-plan` | plan-agent |
| 4. TDD | 開始 TDD 實作 / 寫測試並實作 | `/tdd` | coder-agent |
| 5. Review | review 我的 code / 幫我審核程式碼 | `/code-review` | code-reviewer-agent；package 使用 `07-review.md` |
| 6. Closeout / Archive | closeout 這個 package / 幫我歸檔 | `/archive` | mode-required pre-merge `99-archive.md` |

---

## 💡 重要概念

### Agents（角色）
定義「誰來做」，目前共 9 個角色：

**工作流核心角色：**
- **pm-agent**: 跨 session 專案狀態追蹤、工作流程路由、PRD 起草（策略型專案）
- **brainstorm-agent**: 需求探索與風險分類
- **architect-agent**: 系統設計與架構（跨階段技術顧問）
- **spec-agent**: 規格文件撰寫
- **plan-agent**: 實作計畫規劃
- **coder-agent**: TDD 實作
- **code-reviewer**: 程式碼品質與安全審核

**專業角色（依需求引用）：**
- **frontend-designer-agent**: UI/UX 設計規格、Component spec、無障礙設計（WCAG 2.1 AA）
- **dba-agent**: Schema 設計、Migration 安全、資料庫查詢效能優化

### Skills（方法論）
定義「怎麼做」，每個階段有對應 skill 自動載入：

| 階段 | 自動載入 | 代表 Skills |
|------|----------|------------|
| Brainstorm | `brainstorming` | 結構化需求探索（預設先問至少五題）、風險分類、決策紀錄 |
| Spec | `specification`, `prd` | PRD / 規格文件生成、驗收標準 |
| Plan | `implementation-planning` | 任務拆解、測試策略、影響分析 |
| Implement | `tdd-workflow` + 語言 patterns | Red-Green-Refactor + `coding-standards`, `backend-patterns`, `frontend-patterns`, `python-patterns` |
| Review | `code-security-review`, `security-review` | 程式碼品質 + 安全審核 |
| Closeout / Archive | `work-archiving` | pre-merge lifecycle evidence；不授權 Git 或 remote action |

> 💡 **Skill 沒自動載入？**
> - Codex CLI：用 `$brainstorming`、`$implementation-planning`，或先輸入 `/skills`
> - VS Code / Copilot：可用 `/brainstorming`、`/implementation-planning`
> 每個 Agent 的 Skill Integration 區塊也會提示對應的 skill 指令。
> Brainstorm 預設會先問至少五題再收斂方案；只有在你明確表示可直接假設時，才會改走 assumption-driven 模式。

### Guardrails（共享品質底盤）

除了各階段的主技能，現在工作流還有一層 **shared guardrails**：

- **不是新階段**
- **不是新的主技能**
- **不會改變你原本怎麼用 workflow**

它的作用是橫向約束所有 agent：
- 假設要顯性化，不可默默猜測
- 解法保持簡潔，避免過度工程
- diff 要精準，避免無關修改
- 成功條件要可驗證

大部分 guardrails 會透過 constitution 與 core agents **自動生效**。若你想手動要求 agent 重新套用這層品質底盤，可用：

`/execution-guardrails`

**品質閘門（agentic-eval）— 風險自適應的 self-evaluation：**

`agentic-eval` 是 self-evaluation，不是 independent review，也不能覆蓋 test、build 或其他 deterministic failure。Simple 不要求；Standard 只在風險條件觸發時使用；High-Risk 只使用 `WORKFLOW.md` 的 named rule-based gates，並保留 independent review。

| 觸發時機 | 執行 Agent | 驗證內容 | FAIL 時的行為 |
|---------|-----------|---------|-------------|
| Spec 完成 → handoff 前 | spec-agent（自評）| AC 是否可測試、需求是否可追溯 | 自動修正後再 handoff；嚴重問題直接阻擋 |
| Plan 開始前（收到 spec）| plan-agent（交叉驗證）| spec 從規劃者視角能否寫出具體步驟 | 在 04-plan.md 頂部標記 gap，繼續執行 |
| Code 完成 → Review 前 | coder-agent（自評）| Green Build、Financial Precision、AC 覆蓋 | **Financial Precision FAIL = 強制停止**，不得進入 Review |
| Plan/Spec 完成後（中高風險）| architect-agent（外部仲裁）| 架構合規、依賴順序、規格覆蓋 | 啟動子代理對抗批評，修正後再進行 |

> ⚠️ **Financial Precision 是唯一的強制阻擋規則**：若 coder-agent 偵測到使用 float/double 處理金額，
> 會明確拒絕進入 Review 並要求修正。其他 FAIL 維度則標記後繼續執行。
>
> 💡 **中高風險變更**：Plan 完成後可主動請 architect-agent 做架構仲裁：
> 輸入「請 architect-agent 審查這份 plan」或切換到 `/agent architect-agent`。

**隨時可引用的輔助 Skills：**
`execution-guardrails` / `excalidraw-diagram-generator` / `web-design-reviewer` / `webapp-testing` / `gh-cli` / `github-issues` / `refactor` / `chrome-devtools` / `microsoft-docs`

### Instructions（規範）
定義「遵守什麼標準」，例如：
- C# coding standards
- API design principles
- Financial precision rules (no floats for money!)

---

## 🎯 使用範例

### 範例 1: 新功能開發（完整流程）

```
1. CLI 輸入: "我要開發一個新的交易功能"
   → 系統載入 brainstorming skill
   → 推薦切換到 brainstorm-agent
   → 預設先問至少五題釐清需求
   → 風險判定為「High」→ 走標準路徑

2. 產出 01-brainstorm.md 後，輸入: "產生 spec"
   → 系統載入 specification skill
   → 推薦切換到 spec-agent
   → 產出 03-spec.md
   → ✅ [風險觸發時] spec-agent 執行 AC 可測性自評
      若 Testability FAIL → 自動修正後再 handoff

3. 產出 03-spec.md 後，輸入: "規劃實作計畫"
   → plan-agent 先從規劃者視角交叉驗證 spec
      發現無法寫出具體步驟的需求 → 在 04-plan.md 頂部標記 gap
   → 系統載入 implementation-planning skill
   → 推薦切換到 plan-agent
   → 產出 04-plan.md
   → ✅ [品質閘門] 可請 architect-agent 做架構仲裁（高風險強烈建議）
      輸入：「請 architect-agent 審查這份 plan」

4. 產出 04-plan.md 後，輸入: "開始 TDD 實作"
   → 系統載入 tdd-workflow skill
   → 推薦切換到 coder-agent
   → 完成實作
   → ✅ [風險觸發時] coder-agent 執行 Pre-Review 自評
      🔴 Financial Precision FAIL → 強制停止，不得進入 Review
      其他 FAIL → 修正後繼續

5. 品質自評通過後，輸入: "review 我的 code"
   → 系統載入 code-security-review skill
   → 推薦切換到 code-reviewer-agent

6. Review 通過後，輸入: "archive"
   → package flow 在原 implementation PR 內產生 pre-merge `99-archive.md`
   → Simple 不要求 Archive；其他 local documentation 僅在目前任務明確要求時更新
```

### 範例 2: 檢查當前進度

```
輸入: "我現在在哪個階段？"
或: "what's next?"

系統回應:
→ 偵測到 03-spec.md 已存在
→ 建議下一步: 規劃實作計畫
→ 推薦使用 plan-agent
→ CLI: /agent → 選擇 plan-agent
```

### 範例 3: 低風險局部修復（Simple）

```
1. 輸入: "我要修一個小 bug"
   → 系統詢問風險等級
   → 確認範圍局部、可逆，且有可靠的 targeted verification
   → 選擇 Simple；不強制六階段流程或 Change Package
   
2. 先定義可驗證成功條件
   → 需要時使用 inline plan 或既有 project plan
   
3. 輸入: "開始 TDD"
   → 寫測試 → 實作 → 重構
   
4. 輸入: "review"
   → 審核通過
   
5. 準確回報 targeted verification 與交付狀態
   → Simple 不強制 Archive
```

---

## ⚠️ 常見錯誤

### ❌ 錯誤 1: 在 CLI 使用工作流程 Prompt 的斜線指令
```
> /spec
[系統無反應]
```
**正確方式**: 使用自然語言 → `產生 spec`，或使用 skill 引用語法 → `Use the /specification skill`

> 📌 `/spec`、`/create-plan`、`/code-review` 等是 VS Code prompt 捷徑，非 CLI 斜線指令。
> CLI 內建斜線指令（如 `/plan` 計畫模式、`/review` Code Review）與這些不同。

### ❌ 錯誤 2: 忘記切換 Agent
```
> 產生 spec
[系統推薦 spec-agent]
[使用者繼續對話但未切換 agent]
```
**正確方式**: 輸入 `/agent` 並選擇推薦的 agent

### ❌ 錯誤 3: 跳過必要階段
```
高風險變更直接跳到 TDD（跳過 Brainstorm + Spec）
```
**正確方式**: 
- 低風險才能跳 Spec
- 中高風險必須完整流程

---

## 🔧 進階技巧

### 技巧 1: 查看已安裝的 Skills

CLI（自然語言）:

輸入："列出已安裝的 skills" 或 "show installed skills"，系統會回應可用或已載入的 skills。

VS Code（斜線指令快捷）:
```bash
/skills
```

### 技巧 2: 同步最新設定
```powershell
# 僅限 template 維護者：將 source 同步到本 repo 的 .github/ mirror
pwsh -File .\tools\sync-dotgithub.ps1
```

### 技巧 3: 平行使用 CLI 與 VS Code
- CLI: 用於探索、brainstorm、規劃
- VS Code: 用於實作、review、除錯
- 兩者共享相同的 agents、skills、instructions

### 技巧 4: 啟用 Repo Memory（跨 Session 記憶）

讓 AI 在每次 session 開始前自動讀取專案背景與當前工作狀態，不必重複解釋你的技術棧或進度：

```powershell
# 新專案初始化時啟用
pwsh -File .\scripts\bootstrap.ps1 -EnableMemory

# 現有專案也直接用 bootstrap
pwsh -File .\scripts\bootstrap.ps1 -EnableMemory

# 若同時要更新到最新 workflow baseline
pwsh -File .\scripts\bootstrap.ps1 -Update -EnableMemory
```

啟用後，`.ai-workflow-memory/` 目錄會建立 `PROJECT_CONTEXT.md`（技術棧/架構摘要）與 `CURRENT_STATE.md`（當前工作狀態）。AI 會在開始任何分析前自動讀取這些檔案，並在 session 結束時更新。

> 詳見 `docs/repo-memory-design.md`。

---

想深入了解更多？查看這些文檔：

1. **[README.zh-TW.md](./README.zh-TW.md)** - 完整專案說明
   - CLI vs VS Code 使用差異
   - 六階段詳細指南
   - 常見問題 FAQ

2. **[WORKFLOW.md](./WORKFLOW.md)** - 工作流程詳細說明
   - Simple / Standard / High-Risk execution modes
   - Change Package 結構
   - 驗收與歸檔

3. **[AGENTS.md](./AGENTS.md)** - Agents 與 Skills 對照表
   - 9 個 Agents 說明（含 PM、Frontend Designer、DBA）
   - 核心與工具 Skills
   - 觸發關鍵字參考

4. **[copilot-instructions.md](./copilot-instructions.md)** - 團隊憲章
   - 開發原則與標準
   - Agent 與 Workflow 規則
   - 金融系統特殊要求

---

## 🎉 開始使用

1. **確保環境設置完成**:
   - Codex CLI / Claude Code / Antigravity / Copilot 其中至少一套已安裝
   - 若使用 VS Code，已安裝對應擴充功能

2. **同步最新設定**:
   ```powershell
   pwsh -File .\tools\sync-dotgithub.ps1
   ```

3. **啟動 CLI（如使用 CLI）**:
   ```bash
   codex
   ```

4. **開始你的第一個工作流程**:
   ```
   > 我要開始一個新功能的 brainstorming
   ```

5. **遇到問題？**
   - 輸入「help」或查看 [常見問題 FAQ](./README.zh-TW.md)
   - 使用「what's next」隨時檢查當前階段

---

**祝開發順利！** 🚀

有任何問題或建議，歡迎在專案中建立 issue。
