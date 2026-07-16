# AI 開發工作流範本（繁體中文）

本範本供團隊迅速部署一致的 AI 開發工作流程，適用於各類軟體系統（金融、人資、法遵、稽核、企劃、小工具等），包含團隊憲章、Agent 人物、指令/提示庫、技能（Skills）與 Bootstrap 部署安裝器。

你會得到：

- `copilot-instructions.md`：團隊憲法與行為準則（繁中說明 + 英文程式碼範例）
- `agents/`：9 個專業 Agent 角色（Brainstorm、Architect、Spec、Plan、Coder、Code Reviewer、PM、Frontend Designer、DBA）定義
- `instructions/`：語言與領域規則（例如 Python / C# / SQL / API）
- `prompts/`：標準化 prompt 與工作流程範例
- `skills/`：35 個可插拔技能（TDD、規格、計畫、測試、視覺、CI/CD、DB 等）
- `bootstrap.ps1`：將範本部署到任何專案的安裝器（支援首次部署與版本更新）

## Multi-CLI Runtime

Bootstrap 現在除了保留 `.github/**` 相容層，也會安裝可攜的多 CLI runtime：

- `skills/`：共享 skill source of truth
- `.agents/skills/`、`.claude/skills/`、`.agent/skills/`：指向共享 skill 庫
- `agents/`：角色定義的 canonical source
- `.codex/agents/`、`.claude/agents/`：由 `agents/*.agent.md` 產生的 custom agents
- `AGENTS.md`：專案共用指令來源；`CLAUDE.md`、`GEMINI.md` 為薄包裝

既有專案第一次升級到這個版本時，請把新增的受管路徑一起納入版控：
`skills/`、`agents/`、`.agents/`、`.agent/`、`.claude/`、`.codex/`、`CLAUDE.md`、`GEMINI.md`、`.ai-workflow-install.json`。
如果你的專案原本已有 `AGENTS.md`，bootstrap 會保留它，不會自動覆寫；若要採用新版模板 wording，請手動 merge。

adopter repo 的 ownership 規則：

- `skills/` 與 `agents/` 是 template-managed baseline。要客製就改這裡，並把修改一起 commit。
- `.github/skills/`、`.github/agents/`、`.codex/agents/`、`.claude/agents/`，以及各 CLI 的 skill mount 都屬於 derived runtime。bootstrap 會從頂層 source 自動重新產生。
- `AGENTS.md`、`CLAUDE.md`、`GEMINI.md` 屬於 project-owned。bootstrap 只在第一次建立，之後保留你的本地修改。
- `bootstrap --update` 只會更新那些仍然和 `.ai-workflow-install.json` 記錄的最後受管版本一致的檔案；如果某個檔案已經被你的專案 fork，會保留現況。只有在你明確要用模板版本蓋掉 fork 時，才用 `--force`。

快速上手

前往目標專案目錄，執行以下指令（自動從 GitHub 拉取範本）：

```powershell
Invoke-WebRequest -Uri "https://raw.githubusercontent.com/forgivesam168/ai-dev-workflow/main/scripts/bootstrap.ps1" -OutFile "bootstrap.ps1"
pwsh -ExecutionPolicy Bypass -File .\bootstrap.ps1
Remove-Item bootstrap.ps1
```

若要更新既有專案至最新版本：

```powershell
Invoke-WebRequest -Uri "https://raw.githubusercontent.com/forgivesam168/ai-dev-workflow/main/scripts/bootstrap.ps1" -OutFile "bootstrap.ps1"
pwsh -ExecutionPolicy Bypass -File .\bootstrap.ps1 -Update
Remove-Item bootstrap.ps1
```

更新後請重新開一個新的 Codex / Claude session，讓新安裝的 skills 與 custom agents 重新載入。
在 Codex CLI 內，請用 `/skills` 檢視技能，明確呼叫則用 `$skill-name`。

詳細參數說明請見 [BOOTSTRAP-GUIDE.md](./BOOTSTRAP-GUIDE.md)。

目錄說明

- `copilot-instructions.md`：團隊憲章與指令優先權（閱讀以瞭解互動語言）
- `agents/`：Agent 人物與工作流程
- `instructions/`：技術、流程與安全規範
- `prompts/`：可重複使用的 prompt 範例
- `skills/`：技能說明、腳本與參考資料
- `.codex/agents/`：adopter repo 內產生的 Codex custom agents
- `.claude/agents/`：adopter repo 內產生的 Claude custom agents
- `scripts/bootstrap.ps1`：部署與更新安裝器

注意事項

- 請勿將敏感資訊（API 金鑰、密碼等）提交到版本控制，務必使用環境變數或專用的密鑰管理服務。
- 本範本以「通用性」與「保守配置」為原則；新增或移除 skills 應由各團隊依技術棧裁剪。
- 使用說明與註解建議採繁體中文撰寫以符合團隊內部溝通習慣，程式碼與範例仍以英文為主。

---

## 🤖 九大 Agent 角色與主要技能

每個 Agent 有明確職責邊界、主要技能配對與交接協議。

| Agent | 角色定位 | 主要技能 | 觸發關鍵字 |
|-------|---------|---------|-----------|
| **brainstorm-agent** | 需求探索與風險分類 | `brainstorming` | brainstorm, 釐清需求, 我有個想法, 探索方案 |
| **architect-agent** | 跨階段架構品質仲裁 | `brainstorming`（ADR）+ `agentic-eval` | design, architect, ADR, 系統設計, 架構決策 |
| **spec-agent** | 規格撰寫專家 | `specification` | write spec, create PRD, 規格文件, 需求文件 |
| **plan-agent** | 實作計畫制定 | `implementation-planning` | create plan, task breakdown, 規劃實作, spec to plan |
| **coder-agent** | TDD 實作專家 | `tdd-workflow` | TDD, implement, 開始 TDD, test-driven |
| **code-reviewer** | 程式碼品質與安全審查 | `code-security-review` | review, audit, 審核程式碼, code review |
| **pm-agent** | 跨 Session 工作流程守護 | `workflow-orchestrator` + `prd` | project status, what's next, 我們在哪, 工作流程 |
| **frontend-designer-agent** | UI/UX 設計與 Component Spec | `frontend-patterns` + `excalidraw-diagram-generator` | design UI, wireframe, component spec, 前端設計 |
| **dba-agent** | 資料庫 Schema 設計與審查 | `sql.instructions.md` | design schema, ERD, migration, 資料庫設計 |

### 各 Agent 一句話說明

- **PM**：*「我們在哪？」*——掃描 `changes/` 判斷階段、建議下一步，是唯一可主動建議切換 Agent 的角色
- **Brainstorm**：*「我們要做什麼？」*——寫任何程式碼前先釐清需求、分類風險
- **Architect**：*「設計方向對嗎？」*——跨階段仲裁，任何階段均可 Consult
- **Spec**：*「確切要做什麼？」*——需求轉為可測試的驗收標準（`03-spec.md`）
- **Plan**：*「怎麼一步一步做？」*——產出含 TDD 策略的可執行計畫（`04-plan.md`）
- **Coder**：*「寫程式碼。」*——Red-Green-Refactor；Financial Precision 是強制停止條件
- **DBA** *(顧問)*：*「Schema 設計正確嗎？」*——最佳介入時機是 Spec/Plan 階段而非 coding 階段
- **Frontend Designer** *(顧問)*：*「UI/UX 設計正確嗎？」*——最佳介入時機是 Spec/Plan 階段
- **Code Reviewer**：*「程式碼可以出貨嗎？」*——多視角稽核；通過後交給 work-archiving

---

## 🧠 Repo Memory（選擇性啟用）

為 AI 跨 session 保留專案記憶，初始化時加上 `-EnableMemory`：

```powershell
Invoke-WebRequest -Uri "https://raw.githubusercontent.com/forgivesam168/ai-dev-workflow/main/scripts/bootstrap.ps1" -OutFile "bootstrap.ps1"
pwsh -ExecutionPolicy Bypass -File .\bootstrap.ps1 -EnableMemory
Remove-Item bootstrap.ps1
```

這會在目標專案建立 `.ai-workflow-memory/` 骨架：
- `PROJECT_CONTEXT.md`：專案背景（納入版控，跨 session 共享）
- `CURRENT_STATE.md`：當前進度（納入版控，跨 session 共享）
- `session-journal/`：單次 session 紀錄（加入 .gitignore）

AI 在每次 session 開始會自動讀取這兩份文件，無需重複解釋技術棧或工作進度。

## 🧰 35 技能分類總覽

技能（Skill）提供方法論與工具箱，依關鍵字自動載入至當前 Agent 的執行環境中。

### 核心工作流技能（10 個）

| 技能 | 說明 | 觸發關鍵字 | 推薦 Agent |
|------|------|-----------|-----------|
| `workflow-orchestrator` | 流程協調：偵測當前階段、建議下一步 | workflow, what's next | pm-agent |
| `brainstorming` | 結構化需求探索與風險分類（五題最低、Pre-Mortem） | brainstorm, explore options | brainstorm-agent |
| `specification` | 規格/PRD 產出（AC 可測性、詞彙鎖定、Specialist Lens 審查） | spec, PRD, requirements | spec-agent |
| `implementation-planning` | TDD 整合計畫制定（Vertical Slice 強制、plan-from-spec） | plan, task breakdown, spec to plan | plan-agent |
| `tdd-workflow` | TDD 方法論（Red-Green-Refactor、Three-Strike Rule、Subagent Status Protocol） | TDD, test-driven | coder-agent |
| `code-security-review` | 程式碼品質與安全稽核（財務精度、TDD 合規、4 Specialist Lens） | review, audit | code-reviewer |
| `work-archiving` | 變更包封存（ADR section、三條件 guard）| archive, finalize | — |
| `explore` | 唯讀程式庫探索（承諾修改前先觀察） | explore, investigate, scan risks | — |
| `shipping-and-launch` | 生產部署與上線管理（Staged Rollout、Rollback Plan、Go/No-Go checklist） | deploy, launch, rollout, go-live | — |
| `ci-cd-and-automation` | CI/CD 管線設計（Shift Left、4 Stage Pipeline、Anti-Pattern Guard） | CI/CD, pipeline, quality gate | — |

### 品質與脈絡技能（2 個）

| 技能 | 說明 | 觸發關鍵字 |
|------|------|-----------|
| `execution-guardrails` | 共享品質底盤：假設顯性化、簡潔優先、精準修改、可驗證完成條件 | /execution-guardrails |
| `context-engineering` | **新** 5 層脈絡架構：詞彙衝突偵測、CONTEXT.md 管理、對抗 AI 幻覺 | context engineering, vocabulary conflict, CONTEXT.md |

### 開發模式技能（5 個）

| 技能 | 說明 | 觸發關鍵字 |
|------|------|-----------|
| `coding-standards` | TypeScript / JavaScript / React / Node.js 通用標準 | coding standards, best practices |
| `backend-patterns` | 後端架構、API 設計、DB 優化 | backend, API design |
| `frontend-patterns` | React / Next.js、狀態管理、UI 最佳實踐 | frontend, React patterns |
| `python-patterns` | PEP 8、型別提示、pytest、TDD | Python, pytest |
| `refactor` | 精準重構（Chesterton's Fence、Performance Mode 先量測）| refactor, code smells |

### 測試與品質技能（4 個）

| 技能 | 說明 | 觸發關鍵字 |
|------|------|-----------|
| `agentic-eval` | AI 輸出品質評估（自評 rubric、Tier 2 外部批評、Pre-Decision Mode） | evaluate agent, quality loop |
| `debug` | **新** 系統化除錯（build/test 失敗、drift 錯誤；2 次失敗循環後升級人工） | debug, fix build, tests failing |
| `webapp-testing` | Playwright 本地網頁測試 | test webapp, Playwright |
| `scoutqa-test` | 探索性 QA（Smoke、無障礙、電商流程） | test website, accessibility |

> 完整技能清單請見 `AGENTS.md` → Skills（共 35 個：34 個部署至 adopter 專案，另 1 個 maintainer-only `gate-check`）。

---

## 📚 文件導覽與閱讀路徑

### 🆕 第一次使用？按以下順序閱讀：

| 步驟 | 文件 | 說明 |
|------|------|------|
| 1 | [ONBOARDING.md](./ONBOARDING.md) | 環境準備 checklist（Codex / Claude / Copilot 工具、CLI 安裝、PowerShell 執行策略）|
| 2 | [INSTALL.zh-TW.md](./INSTALL.zh-TW.md) | 詳細安裝指南（含遠端模式、常見問題排查）|
| 3 | [QUICKSTART.md](./QUICKSTART.md) | **5 分鐘上手**：六階段流程 + CLI 心流示範 + Skills 對照 |
| 4 | [WORKFLOW.md](./WORKFLOW.md) | **完整工作流參考**：兩條路徑、Skills 完整對照表、判斷準則、CLI 技巧 |

### 📖 進階參考（依需求查閱）：

| 文件 | 說明 |
|------|------|
| [BOOTSTRAP-GUIDE.md](./BOOTSTRAP-GUIDE.md) | Bootstrap 進階參數與部署模式詳解 |
| [REMOTE-INSTALL.md](./REMOTE-INSTALL.md) | 一鍵遠端安裝流程 |
| [SECURITY.md](./SECURITY.md) | 金融系統安全規範與 hooks 說明 |

---


## 建議流程（Brainstorm → Spec → Plan → Implement）

本範本建議在中高風險變更時採用以下順序：

1. `/brainstorm`：預設先問至少五題釐清需求、限制與替代方案，再產出決策紀錄（Decision Log）與 specs 起始檔案
2. `specs/<YYYY-MM-DD>-<slug>/`：沉澱 `proposal.md / tasks.md / decision-log.md`
3. `/create-plan`：由 `plan-agent` 讀取 specs 後，輸出可執行計畫（每步含驗收方式）
4. Implement（TDD）→ PR review

完整流程與判斷準則請見：`WORKFLOW.md`。


## 工作流程摘要（建議給新手看）

- **Simple**：局部、可逆且有可靠 targeted verification；不要求 repository Change Package、Review 或 Archive artifact。
- **Standard**：只維護一個 plan/lifecycle SSOT；cross-session、cross-component、contract-change、independent-review、migration/audit 或 escalation-prone trigger 成立時才要求 compact package。自願建立的 package 依其 Compact／Full 宣告驗證。
- **High-Risk**：完整 `00`–`06` evidence，加上 canonical `07-review.md` 與 pre-merge `99-archive.md` Closeout。

Triggered Standard／High-Risk package 使用 `changes/<YYYY-MM-DD>-<slug>/`。檔名存在不代表完成；legacy `05-review.md` 仍可讀，`99-closeout.md` 僅可作 pointer-only alias。

詳見：
- `WORKFLOW.md`
- `changes/README.md`

---

## 🔀 CLI 與 VS Code 使用差異

本專案的 AI 工作流程現在支援 **Codex CLI**、**Claude Code**、**Antigravity** 與 **VS Code Copilot**。不同工具的觸發面略有差異，但共享同一套 `skills/` 與 `AGENTS.md`。

### Codex CLI 使用方式
- **Skills 自動載入**: 輸入包含關鍵字的自然語言，系統會自動載入對應 skill
  - 範例：「我要產生 spec」→ 載入 specification skill
- **Skills 直接引用**: 使用 `$skill-name` 明確指定 skill
  - 範例：`$web-design-reviewer`
- **Agent 選擇**: 使用 `/agent` 命令手動選擇 agent
- **檢視 skills**: 使用 `/skills` 查看已安裝的 skills
- ⚠️ **CLI 不支援工作流程 Prompt 的斜線指令**（如 `/spec`、`/create-plan`）——這些是 VS Code prompt 捷徑
- CLI 有獨立的內建斜線指令：`/plan`（啟動計畫模式, Shift+Tab 亦可切換）、`/review`（內建 Code Review Agent）

### Claude Code / Antigravity / VS Code 使用方式
- **共通點**: 以自然語言觸發 skill；工具會讀取共享 `skills/` 與專案 guidance。
- **Claude Code**: 讀取 `CLAUDE.md`、`.claude/skills/`、`.claude/agents/`
- **Antigravity**: 讀取 `GEMINI.md`、`.agents/skills/`（另保留 `.agent/skills/` 相容入口）
- **VS Code Copilot Chat**: 可用工作流程 Prompt 捷徑 `/spec`、`/tdd`、`/code-review`、`/create-plan`
- **提示**: `/skill-name` 這種手動 skill 呼叫主要是 Copilot / VS Code 的使用習慣；Codex CLI 請改用 `$skill-name`

### 通用規則
- **Agents** 定義「誰來做」（角色與專長）
- **Skills** 定義「怎麼做」（方法論與工具）
- **Guardrails** 定義「如何避免 LLM 常見失誤」（顯性 assumptions、簡潔優先、精準修改、成功條件可驗證）
- **Instructions** 定義「遵守什麼規範」（coding standards）

### 推薦工作流程
1. 使用自然語言描述需求（觸發對應 skill）
2. 根據 skill 推薦選擇合適的 agent
3. 讓 agent 依 skill 指引執行任務

---

## 📖 六階段工作流程使用指南

### 階段 0: 流程協調（Workflow Orchestrator）
**觸發關鍵字**: "workflow", "what's next", "工作流程", "下一步"

**CLI 使用**:
```
> 我想知道目前在哪個階段
[系統載入 workflow-orchestrator skill]
→ 偵測到 01-brainstorm.md，建議進行 Spec
→ 推薦使用 spec-agent
```

**VS Code 使用**:
- 方式 1: 輸入「workflow 狀態」
- 方式 2: 使用 `/workflow` 指令（快捷）

---

### 階段 1: Brainstorm
**觸發關鍵字**: "brainstorm", "討論需求", "探索方案"

**CLI 使用**:
```
> 我要開始一個新功能的 brainstorming
[系統載入 brainstorming skill]
→ 建議使用 brainstorm-agent
→ /agent → 選擇 brainstorm-agent
→ 預設先問至少五題；若你明說可直接假設，才改走 assumption-driven brainstorming
```

**VS Code 使用**:
- 方式 1: 輸入「brainstorm 新功能」
- 方式 2: 使用 `/brainstorm` 指令

**產出**: `changes/<date>-<slug>/01-brainstorm.md`

---

### 階段 2: Spec（規格文件）
**觸發關鍵字**: "spec", "PRD", "requirements", "規格", "需求文件"

**CLI 使用**:
```
> 產生 spec 文件
[系統載入 specification skill]
→ 建議使用 spec-agent
→ /agent → 選擇 spec-agent
> 繼續對話以產生完整 spec
```

**VS Code 使用**:
- 方式 1: 輸入「產生 spec」
- 方式 2: 使用 `/spec` 指令

**產出**: `changes/.../03-spec.md`

---

### 階段 3: Plan（實作計畫）
**觸發關鍵字**: "plan", "implementation plan", "任務拆解", "執行計畫"

**CLI 使用**:
```
> 幫我規劃實作計畫
[系統載入 implementation-planning skill]
→ 建議使用 plan-agent
→ /agent → 選擇 plan-agent
```

**VS Code 使用**:
- 方式 1: 輸入「規劃實作計畫」
- 方式 2: 使用 `/create-plan` 指令

**產出**: `changes/.../04-plan.md`

---

### 階段 4: TDD 實作
**觸發關鍵字**: "TDD", "test-driven", "寫測試", "implement"

**CLI 使用**:
```
> 開始 TDD 實作
[系統載入 tdd-workflow skill]
→ 建議使用 coder-agent
→ /agent → 選擇 coder-agent
```

**VS Code 使用**:
- 方式 1: 輸入「TDD 開發」
- 方式 2: 使用 `/tdd` 指令

**產出**: 測試程式碼 + 實作程式碼

---

### 階段 5: Review（審核）
**觸發關鍵字**: "review", "code review", "審核", "檢查程式碼"

**CLI 使用**:
```
> review 我的 code
[系統載入 code-security-review skill]
→ 建議使用 code-reviewer-agent
→ /agent → 選擇 code-reviewer-agent
```

**VS Code 使用**:
- 方式 1: 輸入「review code」
- 方式 2: 使用 `/code-review` 指令

**產出**: 新 package 使用 `changes/.../07-review.md`；legacy `05-review.md` 仍可辨識

---

### 階段 6: Archive（歸檔）
**觸發關鍵字**: "archive", "finalize", "完成", "歸檔"

**CLI 使用**:
```
> 我要 archive 這個 change package
[系統載入 work-archiving skill]
→ 產生 work log entry
→ 在原 implementation PR 內建立 pre-merge `99-archive.md` Closeout
```

**VS Code 使用**:
- 方式 1: 輸入「archive」
- 方式 2: 使用 `/archive` 指令

**產出**: mode-required `changes/.../99-archive.md`；其他 local documentation 僅在目前任務明確要求時更新

---

### 快速參考表

| 階段 | CLI 關鍵字 | VS Code 快捷 | 推薦 Agent | 品質閘門 |
|------|-----------|-------------|-----------|---------|
| 0. Orchestrator | "workflow", "下一步" | - | - | - |
| 1. Brainstorm | "brainstorm", "探索" | `/brainstorm` | brainstorm-agent | - |
| 2. Spec | "spec", "PRD", "規格" | `/spec` | spec-agent | ✅ 自評（AC 可測性）|
| 3. Plan | "plan", "規劃" | `/create-plan` | plan-agent | ✅ 交叉驗證 + 可請 architect 仲裁 |
| 4. TDD | "TDD", "實作" | `/tdd` | coder-agent | ✅ 自評（🔴 Financial Precision 強制）|
| 5. Review | "review", "審核" | `/code-review` | code-reviewer-agent | - |
| 6. Archive | "archive", "歸檔" | `/archive` | - | - |

### ✅ 品質閘門（agentic-eval）

各 agent 在完成主技能後，會自動觸發 `agentic-eval` 在階段交接前做一道品質驗證，**防止有缺陷的產出物流入下一階段**。使用者不需要手動觸發—agent 自動執行並告知結果。

| 觸發時機 | 執行 Agent | 使用者會看到什麼 |
|---------|-----------|----------------|
| Spec 完成後 → 交給 plan-agent 前 | spec-agent 自評 | AC 可測性評分 + 自動修正（或警告）|
| Plan 開始前 → 收到 spec 後 | plan-agent 交叉驗證 | spec gap 標記於 04-plan.md 頂部，繼續執行 |
| Code 完成後 → Review 前 | coder-agent 自評 | 品質分數 + Financial Precision 檢查 |
| Plan 完成後（中高風險）| architect-agent 外部仲裁 | 架構合規報告（需使用者手動請求）|

> ⚠️ **唯一強制阻擋**：coder-agent 偵測到 float/double 處理金額 → 強制停止，不得進入 Review，必須修正後再繼續。
>
> 💡 **architect-agent 仲裁**是唯一需要使用者主動請求的品質閘門。Plan 完成後，切換到 architect-agent 並輸入：
> 「請對這份 plan 做架構仲裁」或「請審查 04-plan.md 的架構合規性」。

### 🧭 Shared Guardrails（共享品質底盤）

除了每個階段的主技能，現在工作流還多了一層 **shared guardrails**。它的定位是：

- **不是新的 workflow stage**
- **不是新的 primary skill**
- **不改變你原本的使用方式**

它專門約束常見 AI 失誤：

- 不可默默猜測需求或邊界
- 不可把小需求做成過度抽象的大工程
- 不可順手修改無關程式碼、註解或格式
- 不可用不可驗證的方式定義完成條件

這層 guardrails 大多數情況會透過 constitution 與 core agents **自動生效**。  
若你想顯式要求 agent 重新套用這層品質底盤，可手動輸入：

`/execution-guardrails`

---

## ❓ 常見問題 FAQ

### Q1: 為什麼我在 CLI 中輸入 `/spec` 沒反應？
A: CLI 不支援斜線指令（那是 VS Code 專用）。請改用自然語言：「產生 spec」或「我要寫規格文件」。

### Q2: 如何知道哪個 skill 被載入了？
A: CLI 會在回應中提示載入的 skill。Codex CLI 也可以使用 `/skills` 查看所有已安裝的 skills。

### Q3: 我一定要切換到推薦的 agent 嗎？
A: 不一定。預設 agent 也能執行，但專用 agent 會更精準且符合角色定位。

### Q4: Skill 和 Prompt 有什麼差別？
A: 
- **Skill**: CLI + VS Code 通用，依關鍵字自動載入
- **Prompt**: VS Code 專用的斜線指令快捷方式

### Q5: 如何在 CLI 中使用 workflow？
A: 輸入「我想知道目前在哪個階段」或「what's next」，系統會載入 workflow-orchestrator skill 並提供指引。

### Q6: 可以跳過某些階段嗎？
A: 低風險變更可跳過 Spec，直接從 Brainstorm → Plan。但 Med/High 風險必須完整走完所有階段。

### Q7: 如何同步 skills 到 .github 目錄？
A: 一般 adopter 專案不需要手動同步，`bootstrap` 會自動建立 `.github/**` 相容層。只有在你維護這個 template repo 本身、修改了頂層 source-of-truth 後，才需要執行 `pwsh -File .\tools\sync-dotgithub.ps1` 更新本 repo 的 `.github/**` mirror。

### Q8: CLI 和 VS Code 可以混用嗎？
A: 可以！兩者共享相同的 agents、skills 和 instructions。選擇你習慣的工具即可。

### Q9: 品質閘門是什麼？我需要手動做什麼嗎？
A: 品質閘門是 agent 在階段交接前的自動品質驗證（由 `agentic-eval` skill 驅動）。大多數情況下你什麼都不用做—agent 自動執行並告知結果。你只需要注意兩件事：
- **🔴 Financial Precision FAIL**：coder-agent 偵測到 float/double 處理金額時，會拒絕進入 Review，你必須修正後再繼續
- **🟡 Architect 仲裁（中高風險）**：這是唯一需要你主動請求的閘門。Plan 完成後，切換到 architect-agent 並說「請對這份 plan 做架構仲裁」

### Q10: `execution-guardrails` 是不是新的 workflow skill？我需要每次都手動叫嗎？
A: 不是。它是 **共享品質底盤**，不是新的 stage，也不會取代 brainstorm / spec / plan / tdd / review 這些主技能。大部分情況它已經透過 constitution 與 core agents 自動生效。你只有在想明確提醒 agent「不要亂猜、不要過度工程、不要亂改、把成功條件說清楚」時，才需要手動輸入 `/execution-guardrails`。
