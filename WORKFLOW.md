# AI 開發工作流（團隊標準 v2）
> 目標：讓「新手也能穩定交付」——把需求釐清、規格、計畫、測試與審查 **變成可版控的產物**，降低反覆溝通成本，並在 MVP 很快變棕地時仍能安全演進。

本工作流整合：
- **Superpowers 精神**：先 brainstorm / 再 plan / 再 TDD / 再 review / 再重構與驗證
- **OpenSpec 精神（輕量版）**：把需求/決策/計畫留在 repo，形成長期上下文（可稽核）

## Lifecycle SSOT and ownership

This maintainer `WORKFLOW.md` is the canonical lifecycle SSOT for this template repository. Agents, Skills, and Prompts route to it and must not redefine execution modes, stage entry/exit rules, or artifact semantics.

The adopter-facing lifecycle source remains open. Phase 3 requires a maintainer/adopter difference review and separate user approval before selecting or distributing any adopter source; root `WORKFLOW.md` must not be presumed directly installable.

The Phase 4 Manifest schema is not approved. This lifecycle contract does not authorize a schema design, migration, prune, or real-adopter execution.

Every task selects exactly one execution mode: Simple, Standard, or High-Risk. These are the only execution modes; workflow paths, optional PRD use, and tool UX are not additional modes.

### Simple

Use Simple only for localized, reversible work that does not cross auth, security, financial, migration, deployment, destructive, or public-breaking boundaries and has one reliable targeted verification path.

Simple uses lightweight Understand, Implement, Prove, and Deliver checkpoints with targeted verification. It does not require the six-stage lifecycle or a Change Package. An inline plan or an existing project plan is optional when useful.

### Standard

Use Standard for normal feature work, multiple files or components, meaningful design choices, bounded contract/config changes, or moderate regression risk. Declare exactly one plan/lifecycle SSOT and use only the stages needed to meet their exit criteria.

A compact Change Package is required when Standard work is cross-session, cross-component, contract-change, independent-review, migration/audit-sensitive, or escalation-prone. Otherwise the one declared plan/lifecycle SSOT is sufficient. Independent review is required when the risk calls for it.

### High-Risk

Use High-Risk for security, auth, permission, financial, migration, public breaking changes, irreversible data work, deployment or production operations, or major architecture decisions.

High-Risk requires the full Workflow, a complete Change Package, explicit approvals, independent review, rollback/migration evidence, and operational evidence appropriate to the change. The named High-Risk gates below are rule-based and must pass in order.

If Simple or Standard work crosses a higher-risk boundary, stop and reclassify or escalate before further implementation. Missing reliable verification prevents Simple classification.

---

## 1) High-Risk full lifecycle and selected Standard stages

```
┌─────────────┐    ┌─────────────┐    ┌─────────────┐
│ 1.Brainstorm│ -> │   2.Spec    │ -> │   3.Plan    │
│  釐清需求   │    │  規格文件   │    │  任務拆解   │
│  風險判定   │    │  安全需求   │    │  測試策略   │
│ 執行模式    │    │  驗收標準   │    │  影響分析   │
└─────────────┘    └─────────────┘    └─────────────┘
                                            │
        ┌───────────────────────────────────┘
        v
┌─────────────┐    ┌─────────────┐    ┌─────────────┐
│ 4.Implement │ -> │  5.Review   │ -> │  6.Archive  │
│     TDD     │    │ Code Review │    │    驗收     │
│ Red-Green-  │    │   +並行+    │    │    歸檔     │
│  Refactor   │    │Security Rev │    │    紀錄     │
└─────────────┘    └─────────────┘    └─────────────┘
```

### 對應指令

| 階段 | 指令 | 說明 |
|------|------|------|
| 1 | `/brainstorm` | 風險分類、先問至少五題釐清需求；只在 selected mode 要求時建立 Change Package |
| 2 | `/spec` | 產出規格文件 |
| 3 | `/create-plan` | 產出可執行計畫（含測試策略、影響分析） |
| 4 | `/tdd` | TDD 實作（Red-Green-Refactor） |
| 5 | `/code-review` | Code Review + Security Review（並行） |
| 6 | `/archive` | 驗收歸檔 |

### Skills 自動對應（CLI 開發心流）

在 Copilot CLI 輸入自然語言，系統**自動載入**對應 skill：

| 階段 | 自動載入 Skills | 推薦 Agent | CLI 觸發語句（範例） | 產出物 |
|------|----------------|-----------|---------------------|--------|
| 0. 流程狀態 | `workflow-orchestrator` | `pm-agent` | `我現在在哪個階段？所有專案進度？` | 現況偵測 + 下一步建議 + 跨 session 狀態追蹤 |
| 1. Brainstorm | `brainstorming` | `brainstorm-agent` | `我要 brainstorm 新功能` | inline summary，或 mode-required `01-brainstorm.md` / `02-decision-log.md` |
| 1.5. PRD（選用）| `prd` | `pm-agent` | `幫我起草 PRD` | `00-prd.md`（策略型專案）|
| 2. Spec | `specification`, `prd` | `spec-agent` | `幫我寫規格文件` | `03-spec.md` |
| 2. Spec（技術架構）| — | `architect-agent` | `幫我設計系統架構` | ADR, 設計文件 |
| 3. Plan | `implementation-planning` | `plan-agent` | `規劃實作計畫` | `04-plan.md` |
| 4. Implement | `tdd-workflow` + 語言 patterns | `coder-agent` | `開始 TDD 實作` | 測試 + 程式碼 |
| 5. Review | `code-security-review`, `security-review` | `code-reviewer` | `review 我的 code` | Review report |
| 6. Archive | `work-archiving` | Default | `archive 這個 change` | `99-archive.md` |

> Archive does not grant Git or remote authorization; protected actions require separate current-task approval.

**共享 Guardrails（always-on + manual fallback）**：

- 維持既有 **Agent → Primary Skill** 主結構，不新增 workflow stage
- 把常見 LLM 失誤前置約束：假設要顯性化、簡潔優先、精準修改、成功標準可驗證
- 平常由 constitution + core agents **隱性生效**
- 若要顯式重載這層品質底盤，可手動引用：`/execution-guardrails`

## Named High-Risk Gates

`agentic-eval` is risk-adaptive self-evaluation, not independent review. It cannot override test, build, or other deterministic failures and never replaces the independent review required for High-Risk work.

### Architecture Decision Exit

Apply before an irreversible or high-cost architecture, security, permission, data, or public-contract decision enters downstream commitment.

**Blocking conditions:**

- unresolved safety or authorization boundary;
- fabricated, unverified, or materially unsupported source or assumption;
- irreversible decision without a viable rollback, migration, or compensation path;
- unresolved material contract conflict.

**Warning-only findings:**

- maintainability preferences that do not affect correctness, security, reversibility, or contract behavior;
- optional documentation or naming improvements that do not affect correctness, security, reversibility, or contract behavior.

### Pre-Implementation Readiness

Apply before every High-Risk implementation.

**Blocking conditions:**

- unresolved required AC, scope, decision, or prerequisite;
- missing protected-action approval;
- missing or non-executable applicable migration, rollback, or recovery plan;
- no reliable RED/GREEN or other verifiable path;
- unclear ownership or affected-system boundary.

**Warning-only findings:**

- optional documentation, presentation, or wording improvements that do not affect safe or verifiable implementation.

### Pre-Delivery Verification

Apply before every High-Risk commit, push, PR, or merge.

**Blocking conditions:**

- known red test or build, lint, static check, or required gate;
- material requirement or AC without evidence;
- security, authorization, financial, data-integrity, or migration invariant failure;
- scope leakage, unreviewed generated drift, or invalid working-tree state;
- missing required independent review or unresolved Critical or High finding.

**Warning-only findings:**

- style, presentation, or low-impact clarity issues that do not affect correctness or auditability.

### Migration / Deployment Readiness

Apply only when migration, deployment, production operation, or irreversible data execution is in scope and separately authorized.

**Blocking conditions:**

- missing explicit, current-task, action-specific execution approval;
- unbounded scope, target, batch, or affected population;
- missing rollback, restore, compensation, or safe-stop path;
- missing rehearsal, recovery validation, or required operational signal;
- unclear ownership, backup, reversibility, or failure handling.

**Warning-only findings:**

- non-critical presentation, report-formatting, or optional-observability improvements.

When this gate is not applicable, record exactly: `N/A — no migration or deployment execution is authorized in this Phase.`

### Cross-gate semantics

- Deterministic failure is always blocking.
- Warning-only findings must be recorded but cannot be promoted to blocking unless new evidence matches an approved blocking condition.
- Resolve every blocking finding before entering the next gate.
- N/A requires an auditable reason.
- High-Risk work always retains independent review after self-evaluation.
- These gates use rule-based conditions and introduce no aggregate score or numeric threshold. General-purpose `agentic-eval` scoring does not apply to the named High-Risk gates.
- New gates, blocking dimensions, or aggregate thresholds require separate approval.

> Detailed non-lifecycle evaluation patterns and supporting rubrics live in [`skills/agentic-eval/SKILL.md`](./skills/agentic-eval/SKILL.md) and [`skills/agentic-eval/references/stage-rubrics.md`](./skills/agentic-eval/references/stage-rubrics.md).

**輔助 Skills（任何階段，依需求引用）：**

| 情境 | Skill | CLI 引用方式 |
|------|-------|-------------|
| 架構 / 流程圖 | `excalidraw-diagram-generator` | `幫我畫架構圖` |
| UI 設計審核 | `web-design-reviewer` | `/web-design-reviewer` |
| UI/UX 設計規格 | `frontend-patterns` | `請 frontend-designer-agent 設計 component spec` |
| 資料庫設計 / Schema 審閱 | — | `請 dba-agent 設計 schema / 優化查詢` |
| 前端 patterns | `frontend-patterns` | `React 最佳實踐` |
| 後端 patterns | `backend-patterns` | `API 設計原則` |
| Python patterns | `python-patterns` | `Python 最佳實踐` |
| 共享品質約束 | `execution-guardrails` | `/execution-guardrails` |
| 重構 | `refactor` | `幫我重構這段 code` |
| 前端功能測試 | `webapp-testing`, `scoutqa-test` | `測試這個網頁` |
| 瀏覽器除錯 | `chrome-devtools` | `幫我 debug 瀏覽器問題` |
| GitHub 操作 | `gh-cli`, `github-issues` | `幫我建立 issue` |
| Microsoft 文件 | `microsoft-docs`, `microsoft-code-reference` | `查 Azure SDK 文件` |

**⚠️ 環境差異說明**:

本工作流程在 **Copilot CLI** 和 **VS Code** 中略有不同：

**Copilot CLI**:
- 使用**自然語言**觸發 skills（例：「產生 spec」、「幫我寫規格文件」）
- 可用 `/skill-name` 直接引用 skill（例：`/web-design-reviewer`）
- 使用 `/agent` 選擇角色；`/skills list` 查看已安裝 skills
- ⚠️ **不支援 Prompt 型斜線指令**（如 `/spec`、`/create-plan`——這些是 VS Code prompt 快捷鍵，非 skill 引用語法）
- CLI 內建斜線指令（與工作流程 prompts 無關）：`/plan`（啟動計畫模式）、`/review`（內建 Code Review Agent）

**VS Code Copilot Chat**:
- 可使用**斜線指令**快速觸發工作流程 prompts（例：`/spec`、`/create-plan`）
- 也支援自然語言與 `/skill-name` 引用（同 CLI）
- Agent 選擇：`@workspace #agent-name`

**詳細使用指南請參考** [README.zh-TW.md - CLI vs VS Code 使用差異](./README.zh-TW.md)

---

## 2) Representative mode selection

| Scenario | Selected mode | Required lifecycle behavior |
|---|---|---|
| Localized documentation correction with a reliable targeted check | Simple | Lightweight A/B/C/D; no mandatory six-stage flow or Change Package. |
| Multi-file feature with one bounded plan and no package trigger | Standard | One declared plan/lifecycle SSOT and selected stages with explicit verification. |
| Cross-session contract change requiring independent review | Standard | Compact Change Package because the Standard package trigger applies. |
| Auth, financial, migration, breaking API, production, or major architecture work | High-Risk | Full Workflow and Change Package with explicit approvals, independent review, rollback/migration, and operational evidence. |

Optional PRD use is a lifecycle stage choice, not a fourth execution mode. For cross-department or multi-stakeholder work, `pm-agent` may draft `changes/<slug>/00-prd.md` and `architect-agent` may review technical feasibility before Spec when the selected mode and plan require it.

---

## 3) Change Package requirements

A Change Package is a lifecycle evidence container, decision trace, and implementation/verification record. Simple does not require one. Standard requires a compact package only when a listed trigger applies. High-Risk requires the complete package.

When required, place the versioned package under:

`changes/<YYYY-MM-DD>-<slug>/`

檔案結構（詳見 `instructions/changes.instructions.md` 為準）：
- `00-intake.md`（初始評估）
- `01-brainstorm.md`（需求釐清 + 選項分析）
- `02-decision-log.md`（關鍵決策與理由，**append-only**）
- `03-spec.md`（規格、安全需求、驗收標準）
- `04-plan.md`（可執行步驟 + 測試策略 + 影響分析）
- `05-test-plan.md`（測試計畫）
- `06-impact-analysis.md`（棕地 / 高風險）
- `99-archive.md`（驗收 + 歸檔）

Every work item declares exactly one task/status SSOT. With an external tracker, the package stores only the tracker pointer, decisions, and evidence; without one, `04-plan.md` may explicitly declare itself the task/status SSOT.

> **核心原則：** 需求變動時，更新 spec；決策變動時，追加 decision log（不要覆寫歷史）。

---

## 4) Definition of Ready（DoR）：什麼才准進開發？

所有 mode 都必須先明確目標／非目標、選擇唯一 execution mode，並定義至少一個可靠驗證方式。

- **Simple**: inline 記錄目標、重大假設與 targeted verification 即可；不要求 lifecycle files。
- **Standard / High-Risk**: mode-required artifacts 必須存在且達到 selected stage exit criteria。Standard 只在 trigger 成立時要求 compact Change Package；High-Risk 要求 complete Change Package。
- Brownfield 影響分析、rollback／migration 或 operational evidence 依 mode 與實際風險提供，不得用缺少文件作為降級理由。

---

## 5) Definition of Done（DoD）：什麼才算做完？

所有 mode 都必須完成批准 scope、保留適用驗證證據，並準確回報 delivery state；任何 deterministic failure 都是 blocking。

- **Simple**: does not require a PR or Change Package；targeted verification 通過且 inline completion evidence 足夠。
- **Standard**: 完成 selected stage exits；觸發 compact package 或 independent review 時，必須附相應 evidence。
- **High-Risk**: 完成 full Workflow、complete Change Package、named gates、explicit approvals 與 independent review，並提供 rollback／migration／operational evidence。
- 只有已獲 current-task authorization 的 PR 才需記錄 package／plan pointer、驗證方式、風險與回滾。
- 改動涉及「危險區」時需適用的獨立審核：
  - `.github/workflows/**`
  - 權限/驗證/授權
  - 資料輸入輸出（API、檔案、DB）

---

## 6) 棕地防呆（MVP → Brownfield 的安全演進）
- **分批 PR**：重構與功能不要混在同一支 PR
- **先保行為，再改內部**：必要時用 feature flag / toggle
- **回歸清單**：列出最重要的 5～10 條使用路徑（在 `04-plan.md`）
- **可回滾**：至少寫「怎麼回到上一版」或「為何不需要回滾」（在 `04-plan.md`）

---

## 7) Standard / High-Risk 團隊節奏範例（適合 5 人小隊）
- 新需求：先開 Issue（或一張 task）
- 先 `/brainstorm`（產出 01/02/03 草稿）
- `/spec`（完善 03-spec.md）
- `/create-plan`（產出 04-plan.md）
- 進入 TDD 實作 → `/code-review` → Merge
- 合併後 `/archive`（5 分鐘完成）

---

## 8) 快速開始（模板）
請參考 `changes/README.md` 與 `changes/_template/`。

---

## 9) Copilot Memory 共存策略

### 什麼是 Copilot Memory

Copilot CLI 的 **Memory** 功能會自動從 session 中學習你的偏好與 pattern，並在未來 session 中自動應用。記憶有效期為 **28 天**，到期後自動失效。

### Memory vs Instructions 的定位

| 面向 | Memory | Instructions |
|------|--------|-------------|
| 來源 | AI 自動學習 | 人工維護、版本控制 |
| 確定性 | 非確定性（AI 判斷是否套用） | 確定性（每次載入都生效） |
| 生命週期 | 28 天過期 | 永久（直到手動刪除） |
| 範圍 | 個人帳號層級 | 專案 / 組織層級 |

> **衝突優先序**：當 Memory 與 instructions 內容矛盾時，**instructions 優先**。
> Instructions（`copilot-instructions.md` + `agents/` + `skills/`）是本專案的 **SSOT（單一真實來源）**。

### 管理者操作

```bash
# 檢視所有 Memory
gh copilot memory list

# 刪除特定 Memory
gh copilot memory delete <id>

# 清空全部 Memory
gh copilot memory clear
```

也可在 [GitHub Copilot 設定頁面](https://github.com/settings/copilot) 中管理 Memory。

### 建議策略

1. **啟用 Memory**：讓 Copilot 自動學習個人習慣（如偏好的變數命名、慣用框架）
2. **以 Instructions 為 SSOT**：團隊標準、架構規範、安全規則一律寫在 `copilot-instructions.md`、`agents/`、`skills/`
3. **定期檢視**：每月檢查 Memory 清單，刪除過時或與團隊規範衝突的項目

---

## 10) Repo Memory — 跨 Session 記憶功能

### 什麼是 Repo Memory

**Repo Memory** 是本工作流程範本提供的**專案層記憶機制**，讓 AI 在每次 session 開始前自動讀取專案背景與當前工作狀態，無需每次重新解釋技術棧或進度。

與 Copilot 內建 Memory（個人帳號層、28 天過期）不同，Repo Memory 是**版本控制的、團隊共享的**。

### 啟用方式

```powershell
# 新專案初始化時啟用
pwsh -File .\scripts\bootstrap.ps1 -EnableMemory

# 現有專案也直接用 bootstrap
pwsh -File .\scripts\bootstrap.ps1 -EnableMemory

# 若同時要更新到最新 workflow baseline
pwsh -File .\scripts\bootstrap.ps1 -Update -EnableMemory
```

### 建立的目錄結構

```
.ai-workflow-memory/
├── PROJECT_CONTEXT.md    # 技術棧、架構決策摘要（納入版控，全團隊共享）
├── CURRENT_STATE.md      # 當前工作狀態，每 session 結束後更新（納入版控）
└── session-journal/      # 逐 session 流水帳記錄（預設 gitignore）
```

### Repo Memory vs Copilot Memory

| 面向 | Repo Memory | Copilot Memory |
|------|-------------|----------------|
| 來源 | 人工維護（AI 協助更新）| AI 自動學習 |
| 確定性 | 高（每次 session 載入）| 非確定性 |
| 生命週期 | 永久（版本控制）| 28 天 |
| 範圍 | 專案層（團隊共享）| 個人帳號層 |

### 運作原理

1. `copilot-instructions.md` 指示 AI：若 `.ai-workflow-memory/` 存在，在開始任何分析/規劃/實作前，**優先讀取** `PROJECT_CONTEXT.md` 和 `CURRENT_STATE.md`。
2. AI 在 session 結束時更新 `CURRENT_STATE.md`，記錄當前階段與下一步。

> 詳細設計說明請見 `docs/repo-memory-design.md`。

---

## 11) Copilot CLI 互動模式

### Plan Mode（計畫模式）

- **觸發**：在 CLI 中按 `Shift+Tab` 切換進入
- **用途**：AI 只規劃、不直接執行操作，適合複雜任務的設計階段
- **離開**：再按 `Shift+Tab` 或輸入 `/exit-plan`

> 💡 建議在 `/brainstorm` 和 `/create-plan` 階段使用 Plan Mode，確保 AI 先規劃再行動。

### Autopilot Mode（自動駕駛模式，experimental）

- **觸發**：啟動時加上 `--autopilot` 或 `-y` 旗標
- **行為**：AI 自動批准所有操作，不請求使用者確認
- **⚠️ 風險**：不建議在 production 環境使用
- **適用**：完全信任的自動化 CI/CD 場景

```bash
# 自動駕駛模式（謹慎使用）
gh copilot chat --autopilot
```

### Session 管理

| 操作 | 指令 | 說明 |
|------|------|------|
| 繼續上次 session | `gh copilot chat --continue` 或 `/resume` | 恢復上次未完成的對話 |
| 壓縮 context | `/compact` | 節省 token，適合長 session |
| 清除 session | `/clear` | 清空對話歷史，重新開始 |

### Context 管理

| 操作 | 指令 | 說明 |
|------|------|------|
| 查看當前 context | `/context` | 顯示已載入的檔案與工具 |
| 手動加入檔案 | `/add <file>` | 將特定檔案加入 context |
| 自動壓縮 | （自動） | 當 context 接近上限時自動觸發 |

> 💡 長時間工作時，善用 `/compact` 壓縮 context，避免 token 超限導致回應品質下降。

---

## 12) MCP 配置說明

### GitHub MCP Server（內建）

Copilot CLI **預設內建** GitHub MCP Server，無需額外配置即可直接使用 GitHub API 功能：

- Issues / Pull Requests 管理
- Repository 搜尋與瀏覽
- Code Search
- Actions / Workflows 操作

確認已登入即可使用：

```bash
gh auth status
```

### 自訂 MCP Server 配置

除內建的 GitHub MCP Server 外，可透過配置檔新增自訂 MCP Server。

**配置檔位置**（依優先序）：

| 位置 | 範圍 | 說明 |
|------|------|------|
| `.github/copilot-mcp.json` | 專案層級 | 隨 repo 版控，團隊共用 |
| `~/.config/gh/copilot-mcp.json` | 使用者層級 | 個人全域設定 |

### 配置格式範例

```json
{
  "mcpServers": {
    "context7": {
      "command": "npx",
      "args": ["-y", "@upstash/context7-mcp@latest"],
      "env": {}
    },
    "sequential-thinking": {
      "command": "npx",
      "args": ["-y", "@modelcontextprotocol/server-sequential-thinking"]
    }
  }
}
```

### 常見 MCP Server 範例

| Server | 用途 | 安裝方式 |
|--------|------|----------|
| `context7` | 函式庫文件即時查詢 | `npx -y @upstash/context7-mcp@latest` |
| `sequential-thinking` | 結構化思考輔助 | `npx -y @modelcontextprotocol/server-sequential-thinking` |
| `brave-search` | 網路搜尋 | 需要 `BRAVE_API_KEY` 環境變數 |

### 驗證 MCP Server

```bash
# 在 Copilot CLI 中檢視已載入的 MCP Server
/mcp
```

> 💡 新增或修改 MCP 配置後，需重新啟動 Copilot CLI 才會生效。
