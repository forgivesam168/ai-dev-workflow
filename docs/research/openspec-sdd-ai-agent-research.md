# OpenSpec / Superpowers / SDD + AI Agent 協作專案研究：`ai-dev-workflow` 可強化方向

## Executive Summary

你的 `ai-dev-workflow` 已經有很強的骨架：**可稽核的 change package、六階段流程、pointer-style 載入、source-of-truth 與 `.github/**` runtime 同步規則**，這些都是很多同類專案沒有做好的地方。[^1][^2][^3][^5]

外部專案大致分成三派：**OpenSpec** 把重點放在「artifact / schema / delta spec」；**Superpowers** 把重點放在「工程方法論 + 子代理執行紀律」；**everything-claude-code（ECC）** 則把重點放在「hooks、記憶、安裝器、跨 harness 營運面」。[^8][^9][^13][^18]

如果你的目標是把這個 repo 打造成**可長期維護、可部署到不同專案、可在 Copilot/Claude/Codex 類工具之間移植**的 AI workflow template，最高槓桿的強化點不是再多加 agent，而是補上四個缺口：**可規劃的安裝/更新層、repo-persisted session memory、deterministic gate-check、以及 catalog drift 自動校驗**。[^6][^7][^19][^20][^23][^31]

另外，我在本 repo 內部也看到幾個值得先修正的訊號：`README.md` 與 `AGENTS.md` 的 agent / prompt 數量不同，`WORKFLOW.md` 的 change package 結構也和 `instructions/changes.instructions.md` 不一致。這代表你已經需要一個比「sync `.github/**`」更高一層的 **catalog truth / doc drift guard**。[^1][^2][^3][^4][^7]

## 研究範圍與定位

這次重點研究了：

| 類別 | 專案 | 我認為最值得看的點 |
|---|---|---|
| Spec-first 核心 | [Fission-AI/OpenSpec](https://github.com/Fission-AI/OpenSpec) | delta spec、schema-driven artifact flow、`/opsx:explore` |
| 方法論核心 | [obra/superpowers](https://github.com/obra/superpowers) | TDD / subagent / review / worktree 紀律 |
| Copilot 移植層 | [DwainTR/superpowers-copilot](https://github.com/DwainTR/superpowers-copilot) | 如何把 Superpowers 包成 Copilot 可用表面 |
| Harness/ops 核心 | [affaan-m/everything-claude-code](https://github.com/affaan-m/everything-claude-code) | selective install、hooks、continuous learning、state store |
| SDD 流程模板 | [Ataden/SDD_Flow](https://github.com/Ataden/SDD_Flow) | 全流程文件化、prompt/template 對應 |
| SDD 執行環境 | [vtomasv/sdd-dev](https://github.com/vtomasv/sdd-dev) | Docker + OpenSpec + task orchestrator + multi-agent roles |
| SDD + deterministic gates | [nesquikm/dev-process-toolkit](https://github.com/nesquikm/dev-process-toolkit) | bounded self-review、gate-check、spec archive |
| GitHub 官方工具包 | [github/spec-kit](https://github.com/github/spec-kit) | `specify init`、slash scaffolding、extension ecosystem |
| OpenSpec + Superpowers 混血模板 | [SYZ-Coder/superpowers-openspec-team-skills](https://github.com/SYZ-Coder/superpowers-openspec-team-skills) | source/dist 分層、repo-persisted memory、顯式 opt-in workflow |

這些專案不是互斥關係，而是分別解不同層的問題：**artifact layer、execution layer、memory layer、distribution layer**。[^8][^11][^13][^18][^28][^29][^30][^31][^32]

## 你的模板目前最有價值的地方

### 1. 你已經比多數 repo 更重視「可稽核」

你的 README、WORKFLOW、以及 `changes.instructions.md` 明確把流程收斂到 **Brainstorm → Spec → Plan → TDD → Review → Archive**，而且 change package 是 repo 內可版控產物，不是只存在聊天紀錄裡。這一點比 Superpowers 與 ECC 都更接近真正的 team process。[^1][^3][^4]

### 2. 你有明確的 progressive loading 架構

`AGENTS.md` 已經把 context 載入切成 Constitution / Repo rules / Agent persona / Language-domain / Skills 五層，這是很好的 token-budget 設計，也比很多把所有規則堆進單一大檔案的做法健康。[^2]

### 3. 你有 source-of-truth 與 runtime mirror 的清楚分界

`copilot-instructions.md` 與 `AGENTS.md` 都很清楚地把 top-level source 與 `.github/**` mirror 分開，並要求 sync 後同 commit。這種紀律很重要，因為它讓模板 repo 自身可以維護，又能輸出工具可讀的 runtime 形態。[^2][^5]

## 外部專案真正帶來的啟發

## 1. OpenSpec：最值得借的是 schema / delta / explore，不是整套照搬

[OpenSpec](https://github.com/Fission-AI/OpenSpec) 最核心的設計不是「先寫 spec」這麼簡單，而是把工作拆成 **`specs/`（current truth）** 與 **`changes/`（proposed modifications）** 兩個世界；change folder 內再放 `proposal.md`、`design.md`、`tasks.md`、delta specs 與可選 metadata。[^9]

它的 brownfield 競爭力來自 **delta spec**：不是重寫整份規格，而是只表達 `ADDED / MODIFIED / REMOVED` requirements，讓 archive 時再合併回主規格。這對既有系統特別友善。[^10]

OpenSpec 另一個很強的點是 **schema-driven workflow**。`openspec/config.yaml` 可注入 project context 與 per-artifact rules，而 `openspec/schemas/<name>/schema.yaml` 可以定義 artifact graph、template 與 dependency。也就是說，workflow 本身是可組態、可 fork、可版本控制的。[^11]

另外，`/opsx:explore` 很值得借。它把「先研究、先釐清、先比較方案」當成一級命令，而且**不先生成 artifacts**；只有洞見收斂後才轉 `/opsx:propose`。這對你的模板很有價值，因為你現在的 Stage 1 偏向一開始就進 `brainstorm/change package`，對某些探索型需求稍重。[^8][^12]

**我不建議直接複製的部分**：OpenSpec 刻意走「fluid not rigid」，弱化 phase gates；你的模板反而是靠 stage gates 建立治理強度。這是哲學差異，不要為了學 OpenSpec 把你現有的 gate 感打散。[^8][^9]

## 2. Superpowers：最值得借的是 execution protocol

如果說 OpenSpec 擅長定義 artifact，Superpowers 擅長定義 **agent 該怎麼工作**。它把 brainstorming、planning、worktree isolation、subagent execution、TDD、code review、branch finishing 變成強制技能，而不是「建議」。[^13]

最值錢的部分是兩個：

1. **subagent status protocol**：`DONE / DONE_WITH_CONCERNS / NEEDS_CONTEXT / BLOCKED`，讓主控 agent 能處理失敗與不確定，而不是默默吞掉。[^14]
2. **two-stage review ordering**：先 spec compliance，再 code quality，不能反過來。[^14]

再來，Superpowers 對 **parallel dispatch** 與 **git worktree isolation** 的操作很具體：什麼時候可以平行、什麼時候不能；worktree 目錄怎麼挑、要不要先驗證 `.gitignore`、baseline tests 要不要先跑。這比多數 AI workflow repo 的「你可以用 subagents」實用得多。[^15][^16]

對你來說，Superpowers 最值得移植的不是整個 skill 庫，而是：

- 子代理回報狀態協定
- review stage ordering
- worktree-based isolation 規範
- 系統化 debug skill（你現在明顯還缺這一塊）[^13][^14][^15][^16]

而 [DwainTR/superpowers-copilot](https://github.com/DwainTR/superpowers-copilot) 也證明了一件事：**方法論本體** 和 **某個 harness 的包裝層** 應該分開。它幾乎就是把原始 skill 套到 Copilot CLI 的 plugin / symlink / instructions 表面上。[^17]

## 3. ECC：最值得借的是「營運層」

[everything-claude-code](https://github.com/affaan-m/everything-claude-code) 的真正價值不在技能數量，而在它把 workflow 做成了**可安裝、可修復、可觀測、可演進**的系統。README 明講它已經不是單純 config pack，而是 harness performance system；`agent.yaml`、`WORKING-CONTEXT.md`、installer scripts、observer hooks、state store 一起構成營運層。[^18][^21][^22]

其中最值得你學的四塊：

### 3.1 selective install / install plan

ECC 有 `install-plan.js` 和 `install-apply.js`，可以列 profile、module、component、target，做 dry-run、JSON output、target filtering，再把計畫實際套用。這比你現在 `Init-Project.ps1` 的 `Include/Exclude` 粗粒度高很多，也更容易做升級與 doctor/repair。[^19][^20][^6]

### 3.2 project-scoped continuous learning

ECC 的 `continuous-learning-v2` 不是抽象概念，而是 hook 實際捕捉 tool use、用 project hash 隔離 observations / instincts，再讓 background observer 抽樣分析、寫回 instinct files；`observer-sessions.js` 又補上 session lease 與 project registry。這是一個完整的 **repo-aware memory substrate**。[^23][^24][^25][^26]

### 3.3 queryable state store

`tests/lib/state-store.test.js` 可以看出它的 state store 不只是 session 記錄，還包含 skill runs、install state、governance events、decisions。也就是說，ECC 把「代理系統自己的狀態」做成可查詢資料，而不是散落的 markdown 與 shell 狀態。[^27]

### 3.4 catalog truth / parity discipline

`WORKING-CONTEXT.md` 明確要求保持 `agent.yaml` 與實際 `commands/`、`skills/` 目錄 parity；README 也反覆刷新 catalog counts 與 release surface。這種 discipline 正好是你目前需要補的。[^18][^21][^22]

## 4. SDD 類模板：最值得借的是 deterministic governance

[SDD_Flow](https://github.com/Ataden/SDD_Flow) 的價值在於把 AI-assisted delivery 看成**整個產品生命週期**，從 discovery、architecture、roadmap、foundation、design 到 implementation，而不是只有 coding 階段。它對 prompt/template/document 對應得很完整。[^28]

[sdd-dev](https://github.com/vtomasv/sdd-dev) 則更像執行環境：把 OpenSpec、VibeKanban、multi-agent roles、Dockerized workspace 綁成一個操作系統，強調 task orchestration 與 agent role separation。[^29]

最值得你注意的是 [dev-process-toolkit](https://github.com/nesquikm/dev-process-toolkit)。它把三件事做得非常清楚：

1. **Specs are source of truth**
2. **Deterministic gates override LLM judgment**
3. **Self-review loop 必須 bounded，最多兩輪，之後升級給人**[^31]

而且它把這三件事真正寫進 `/implement` 與 `/gate-check`：先 gate，再 review；review 分成 Stage A spec compliance、Stage B delegated review、Stage C hardening；任何 gate failure 都是 hard stop。[^31]

這其實比你現有的 `agentic-eval` 更像「生產系統保險絲」：`agentic-eval` 很適合做 rubric-based quality loop，但 **compiler / lint / tests / drift check** 這類 deterministic evidence，最好有獨立 skill 或 command 做 kill switch。[^2][^31]

## 5. spec-kit：最值得借的是 scaffold 與 ecosystem

[github/spec-kit](https://github.com/github/spec-kit) 值得研究，不是因為它一定比 OpenSpec 更適合你，而是它把 SDD 做成了 **`specify init` CLI + agent-specific slash scaffolding + extension ecosystem**。它能初始化既有專案、建立 constitution、再走 `/speckit.specify` → `/speckit.plan` → `/speckit.tasks` → `/speckit.implement`。[^32]

更關鍵的是它已經形成一個 **extension market**：brownfield bootstrap、CI guard、memory loader、multi-agent QA、project status、retro、review、issue integrations 都以 extension 形式存在。這意味著模板本體可以保持收斂，而進階能力靠 extension 化。[^32]

這個思路對你很有幫助：你的 repo 現在已經有 skills，但**還沒有清楚的 extension / preset / profile layer**。未來如果你要支援不同團隊（金融、一般 Web、內部平台），不要只靠修改核心 constitution，最好引入「preset/profile」層。[^32]

## 6. 混血模板：最值得借的是 source / dist / memory 三分法

[superpowers-openspec-team-skills](https://github.com/SYZ-Coder/superpowers-openspec-team-skills) 這類 repo 很貼近你的目標。它明確把：

- `team-skills/` 視為 maintainer-facing source
- `dist/` 視為 tool-adapted bundles
- `.superpowers-memory/` 視為 repo-persisted memory interface[^30]

這個分層非常適合你：你目前只有 top-level source + `.github/**` mirror，未來若要支援 Copilot CLI、VS Code prompt、Claude Code、Codex，最好再多一層 **dist/bundle surface**，不要讓 source 直接承擔所有工具相容性。[^2][^30]

## 對 `ai-dev-workflow` 的具體建議（依優先級）

### Priority 1 — 補一個 manifest-driven installer / updater / doctor

你現在的 `Init-Project.ps1` 已經有 `Include/Exclude`，但仍是高度互動式流程：會 `Read-Host` 問要不要裝 node / git / gh / pwsh、要不要搬目錄、要不要清空資料夾。這對一次性 bootstrap 可以，但對**升級、repair、CI 驗證、dry-run** 不夠。[^6]

建議直接新增：

1. `install-plan`：列出會寫哪些檔、覆蓋哪些 surface、需要哪些依賴
2. `install-apply`：真正執行寫入
3. `install-state.json` 或 SQLite state：記錄目前已安裝哪些 component / profile
4. `doctor`：檢查 source vs `.github/**` vs deployed target 是否 drift[^19][^20][^27]

這一層做完，你的模板才會從「初始化腳本」升級成「可運維產品」。

### Priority 2 — 新增 repo-persisted session memory / handoff surface

你現在對跨 session 記憶的描述主要依賴 Copilot Memory，以及初始化時寫一份 `docs/WORK_LOG.md`。這對「偏好記憶」有幫助，但對「這個 repo 目前做到哪、有哪些未完上下文、哪些決策剛剛改了」還不夠。[^3][^6]

建議新增一個類似：

```text
.ai-workflow-memory/
├── PROJECT_CONTEXT.md
├── CURRENT_STATE.md
└── session-journal/
```

讓 agent 在長任務結束時更新 `CURRENT_STATE.md`，並寫一條短 journal。這一點可以同時參考 ECC 的 project-scoped instincts 與 `superpowers-openspec-team-skills` 的 `.superpowers-memory/`。[^23][^26][^30]

### Priority 3 — 新增 artifact-free `explore` 模式

OpenSpec 的 `/opsx:explore` 很值得借。你目前的 orchestrator 會把「未開始」導向 brainstorming，而 brainstorming 在你的流程語境裡偏向要留下產物。對需求還沒收斂的情境，最好有一個**明確不產檔的研究模式**。[^12][^2]

我建議新增：

- `skills/exploration/` 或擴充 `workflow-orchestrator`
- 用於：需求不清、要先看 codebase、要做方案比較、要先做 risk scan
- 明確規定：**除非使用者說 proceed / create change package，否則不寫 `changes/**`**[^12]

### Priority 4 — 新增 deterministic `gate-check`

你現在的品質閘門很大一部分是 `agentic-eval` 自評 / 仲裁，這很好，但仍屬於模型判斷層。建議再補一個獨立的 `gate-check` skill 或 prompt，固定跑 typecheck / lint / tests / build / drift summary，並回傳 `GATE PASSED / GATE PASSED WITH NOTES / GATE FAILED`。[^2][^31]

理由很簡單：**deterministic checks 永遠比 LLM judgment 更適合當 merge 前保險絲**。這能明確區分：

- model-based rubric loop
- evidence-based hard stop[^31]

### Priority 5 — 把子代理回報協定制度化

Superpowers 的 `DONE / DONE_WITH_CONCERNS / NEEDS_CONTEXT / BLOCKED` 很值得直接納入你的 `coder-agent` / `plan-agent` / `architect-agent` 執行規約。[^14]

這會大幅降低兩種常見摩擦：

1. agent 看起來完成了，但其實心裡有疑問
2. agent 卡住了，卻沒有標準化地向上游要 context[^14]

### Priority 6 — 做 catalog truth / doc drift guard

目前 repo 已經有明顯 drift：

- `README.md` 寫 **5 agents / 9 commands**，`AGENTS.md` 寫 **6 agents / 10 prompts**。[^1][^2]
- `WORKFLOW.md` 的 change package 檔案結構，和 `instructions/changes.instructions.md` 的 required set 不一致。[^3][^4]
- `tools/sync-dotgithub.ps1` 目前只驗證 **skills count**，沒有驗證 agents / prompts / docs catalog。[^7]

這是我認為你現在最值得先修的一個「自家狗糧」問題。建議新增一個 catalog audit 腳本，自動比對：

- agent count
- prompt count
- skill count
- README / AGENTS / WORKFLOW 中的宣告數量與實際目錄是否一致
- change package contract 是否一致[^7][^18][^21]

### Priority 7 — 將 workflow 定義再抽象成 schema / preset / profile

你現在已有固定六階段流程，這很好；但若未來想服務不同團隊，建議不要直接 fork constitution，而是增加：

- `profiles/finance`
- `profiles/general-web`
- `profiles/internal-platform`
- `profiles/research-heavy`

做法可以參考 OpenSpec schema 與 spec-kit preset / extension 思路：**核心流程不變，artifact 規則與 install surface 可換**。[^11][^32]

### Priority 8 — 引入 source / bundle / runtime 三層面

你目前是：

- source：top-level
- runtime：`.github/**`

未來建議再加：

- `dist/`：對特定 harness 的 bundle（例如 Copilot CLI, VS Code prompts, Claude Code, Codex）[^30]

這會讓你之後要支援更多工具時，不必把工具相容性邏輯污染 source-of-truth。

## 我不建議你現在就照抄的東西

1. **不要追 ECC 的規模。** 183+ skills/79 commands 的運營成本非常高；你的模板目前最大的優勢是收斂、清楚、可治理。[^18][^21]
2. **不要把 OpenSpec 的 fluid philosophy 全盤搬進來。** 你目前的 stage gates 是優勢，不是負擔。[^8][^9]
3. **不要讓 memory 變成外部依賴先行。** 先做 repo-persisted handoff，比先做複雜 observer daemon 更划算。[^23][^30]
4. **不要先加更多 agent。** 先把 installer、gates、memory、catalog audit 補齊，再決定 agent roster 是否要擴張。[^1][^2][^21]

## 建議你接下來的實作順序

1. **先修內部 drift**：README / AGENTS / WORKFLOW / changes.instructions 對齊。[^1][^2][^3][^4]
2. **做 catalog audit script**：把數量與 contract 檢查自動化。[^7]
3. **做 install-plan / install-apply / doctor**：把 bootstrap 升級成可運維安裝面。[^6][^19][^20]
4. **補 repo memory surface**：`PROJECT_CONTEXT.md` / `CURRENT_STATE.md` / session-journal。[^23][^30]
5. **補 `explore` 與 `gate-check`**：一個服務前期探索，一個服務後期 hard stop。[^12][^31]
6. **最後再考慮 profile/schema 化**：讓這個模板能針對不同團隊有不同預設。[^11][^32]

## Confidence Assessment

**高信心**

- OpenSpec 最強的是 `specs/` vs `changes/` 分離、delta specs、schema/customization、`/opsx:explore`。[^9][^10][^11][^12]
- Superpowers 最強的是 execution discipline：TDD、subagent protocol、parallel dispatch、worktree isolation、two-stage review。[^13][^14][^15][^16]
- ECC 最強的是營運層：selective install、hooks、continuous learning、queryable state、catalog parity discipline。[^18][^19][^20][^21][^23][^24][^25][^26][^27]
- 你目前 repo 的最大 immediate gap 是 installer / memory / gate-check / catalog drift guard，而不是 agent 數量。[^6][^7][^23][^31]

**中信心**

- 若你真的要跨 Copilot CLI / VS Code / Claude Code / Codex 同時維護，未來大概率會需要 `dist/` / bundle 層，而不只 `.github/**` mirror。這是基於 `superpowers-openspec-team-skills` 與 spec-kit ecosystem 的模式推論。[^30][^32]

**低信心 / 推論成分較高**

- 若你未來把 repo memory、gate-check、catalog audit 補齊後，是否還需要更多 agent，取決於你的實際團隊分工與使用頻率；目前證據足以支持「先不要急著擴 agent roster」，但不足以直接決定最後 roster 應該長什麼樣。[^2][^21]

## Footnotes

[^1]: `E:\projects\ai-dev-workflow\README.md:3-11,39-57,76-80`
[^2]: `E:\projects\ai-dev-workflow\AGENTS.md:3-10,12-27,29-47,67-104`
[^3]: `E:\projects\ai-dev-workflow\WORKFLOW.md:10-40,130-143,191-240`
[^4]: `E:\projects\ai-dev-workflow\instructions\changes.instructions.md:8-23`
[^5]: `E:\projects\ai-dev-workflow\copilot-instructions.md:7-39`
[^6]: `E:\projects\ai-dev-workflow\Init-Project.ps1:5-9,17-39,56-65,70-99,101-115,117-177,235-249`
[^7]: `E:\projects\ai-dev-workflow\tools\sync-dotgithub.ps1:12-18,20-38,47-54`
[^8]: `C:\Users\forgi\.copilot\session-state\210c32ba-f014-4a16-a69e-f81ef2a6b854\files\research-sources\OpenSpec\README.md:26-40,47-69,80-115,118-156`
[^9]: `C:\Users\forgi\.copilot\session-state\210c32ba-f014-4a16-a69e-f81ef2a6b854\files\research-sources\OpenSpec\docs\concepts.md:28-50,182-229`
[^10]: `C:\Users\forgi\.copilot\session-state\210c32ba-f014-4a16-a69e-f81ef2a6b854\files\research-sources\OpenSpec\docs\concepts.md:346-406`
[^11]: `C:\Users\forgi\.copilot\session-state\210c32ba-f014-4a16-a69e-f81ef2a6b854\files\research-sources\OpenSpec\docs\customization.md:3-20,48-91,94-132,149-239`
[^12]: `C:\Users\forgi\.copilot\session-state\210c32ba-f014-4a16-a69e-f81ef2a6b854\files\research-sources\OpenSpec\docs\workflows.md:31-55,99-147,222-260`; `C:\Users\forgi\.copilot\session-state\210c32ba-f014-4a16-a69e-f81ef2a6b854\files\research-sources\OpenSpec\docs\commands.md:9-31,73-124`
[^13]: `C:\Users\forgi\.copilot\session-state\210c32ba-f014-4a16-a69e-f81ef2a6b854\files\research-sources\superpowers\README.md:3-16,119-170`
[^14]: `C:\Users\forgi\.copilot\session-state\210c32ba-f014-4a16-a69e-f81ef2a6b854\files\research-sources\superpowers\skills\subagent-driven-development\SKILL.md:6-39,87-124,221-259`
[^15]: `C:\Users\forgi\.copilot\session-state\210c32ba-f014-4a16-a69e-f81ef2a6b854\files\research-sources\superpowers\skills\dispatching-parallel-agents\SKILL.md:8-18,36-65,126-182`
[^16]: `C:\Users\forgi\.copilot\session-state\210c32ba-f014-4a16-a69e-f81ef2a6b854\files\research-sources\superpowers\skills\using-git-worktrees\SKILL.md:8-18,51-77,120-172,194-219`
[^17]: `C:\Users\forgi\.copilot\session-state\210c32ba-f014-4a16-a69e-f81ef2a6b854\files\research-sources\superpowers-copilot\README.md:7-21,47-103`; `C:\Users\forgi\.copilot\session-state\210c32ba-f014-4a16-a69e-f81ef2a6b854\files\research-sources\superpowers-copilot\install.sh:45-99`
[^18]: `C:\Users\forgi\.copilot\session-state\210c32ba-f014-4a16-a69e-f81ef2a6b854\files\research-sources\everything-claude-code\README.md:35-40,72-80,83-116,164-254`; `C:\Users\forgi\.copilot\session-state\210c32ba-f014-4a16-a69e-f81ef2a6b854\files\research-sources\everything-claude-code\the-shortform-guide.md:13-25,38-72,76-96,99-147,157-185,200-248`
[^19]: `C:\Users\forgi\.copilot\session-state\210c32ba-f014-4a16-a69e-f81ef2a6b854\files\research-sources\everything-claude-code\scripts\install-plan.js:1-45,140-185,188-260`
[^20]: `C:\Users\forgi\.copilot\session-state\210c32ba-f014-4a16-a69e-f81ef2a6b854\files\research-sources\everything-claude-code\scripts\install-apply.js:1-47,55-97,99-150`
[^21]: `C:\Users\forgi\.copilot\session-state\210c32ba-f014-4a16-a69e-f81ef2a6b854\files\research-sources\everything-claude-code\WORKING-CONTEXT.md:7-20,34-45,78-90`
[^22]: `C:\Users\forgi\.copilot\session-state\210c32ba-f014-4a16-a69e-f81ef2a6b854\files\research-sources\everything-claude-code\agent.yaml:1-11,12-145,146-234`
[^23]: `C:\Users\forgi\.copilot\session-state\210c32ba-f014-4a16-a69e-f81ef2a6b854\files\research-sources\everything-claude-code\skills\continuous-learning-v2\SKILL.md:2-45,47-79,80-124,126-145,211-260`
[^24]: `C:\Users\forgi\.copilot\session-state\210c32ba-f014-4a16-a69e-f81ef2a6b854\files\research-sources\everything-claude-code\skills\continuous-learning-v2\hooks\observe.sh:1-18,22-28,59-76,96-130,148-160,243-260`
[^25]: `C:\Users\forgi\.copilot\session-state\210c32ba-f014-4a16-a69e-f81ef2a6b854\files\research-sources\everything-claude-code\skills\continuous-learning-v2\agents\observer-loop.sh:1-20,50-84,86-123,184-223,236-259`
[^26]: `C:\Users\forgi\.copilot\session-state\210c32ba-f014-4a16-a69e-f81ef2a6b854\files\research-sources\everything-claude-code\scripts\lib\observer-sessions.js:7-17,42-74,76-99,102-175`
[^27]: `C:\Users\forgi\.copilot\session-state\210c32ba-f014-4a16-a69e-f81ef2a6b854\files\research-sources\everything-claude-code\tests\lib\state-store.test.js:11-19,55-99,136-149,192-250`
[^28]: `C:\Users\forgi\.copilot\session-state\210c32ba-f014-4a16-a69e-f81ef2a6b854\files\research-sources\SDD_Flow\README.md:9-16,17-30,40-76`; `C:\Users\forgi\.copilot\session-state\210c32ba-f014-4a16-a69e-f81ef2a6b854\files\research-sources\SDD_Flow\sdd-workflow.md:4-25,27-80,170-225,228-260`
[^29]: `C:\Users\forgi\.copilot\session-state\210c32ba-f014-4a16-a69e-f81ef2a6b854\files\research-sources\sdd-dev\README.md:3-18,53-80,113-173`; `C:\Users\forgi\.copilot\session-state\210c32ba-f014-4a16-a69e-f81ef2a6b854\files\research-sources\sdd-dev\AGENTS.md:5-18,52-88,129-149,189-213`; `C:\Users\forgi\.copilot\session-state\210c32ba-f014-4a16-a69e-f81ef2a6b854\files\research-sources\sdd-dev\docs\OPENSPEC_VIBEKANBAN_GUIDE.md:3-18,57-98,206-260`
[^30]: `C:\Users\forgi\.copilot\session-state\210c32ba-f014-4a16-a69e-f81ef2a6b854\files\research-sources\superpowers-openspec-team-skills\README.md:13-25,34-57,65-107,163-205`
[^31]: `C:\Users\forgi\.copilot\session-state\210c32ba-f014-4a16-a69e-f81ef2a6b854\files\research-sources\dev-process-toolkit\README.md:3-18,20-42,67-75`; `C:\Users\forgi\.copilot\session-state\210c32ba-f014-4a16-a69e-f81ef2a6b854\files\research-sources\dev-process-toolkit\plugins\dev-process-toolkit\docs\sdd-methodology.md:3-18,20-27,42-75,76-123`; `C:\Users\forgi\.copilot\session-state\210c32ba-f014-4a16-a69e-f81ef2a6b854\files\research-sources\dev-process-toolkit\plugins\dev-process-toolkit\skills\implement\SKILL.md:25-48,56-99,101-201,233-260`; `C:\Users\forgi\.copilot\session-state\210c32ba-f014-4a16-a69e-f81ef2a6b854\files\research-sources\dev-process-toolkit\plugins\dev-process-toolkit\skills\gate-check\SKILL.md:7-31,33-74,96-122`
[^32]: `C:\Users\forgi\.copilot\session-state\210c32ba-f014-4a16-a69e-f81ef2a6b854\files\research-sources\spec-kit\README.md:43-93,119-161,169-245`
