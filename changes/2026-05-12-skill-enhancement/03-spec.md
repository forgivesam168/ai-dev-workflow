# Specification: ai-dev-workflow Skill Enhancement — Phase 1

## Overview

本次強化旨在全面升級 ai-dev-workflow 模板的 Skill 品質與 Agent 協作架構。核心目標有三：
（1）將 Skill 格式標準化，為每個工作流程 Skill 加入 Anti-Rationalization Table 與 Verification Checklist，強化 AI 行為約束；
（2）為每個 Agent 加入 Composition Block 與明確的 Handoff 區塊，防止跨 Agent 呼叫失控並優化工作流程引導；
（3）移植 agent-skills 的高價值 Skill（淨新增 3 個、5 項整併/擴充），補齊建置、部署、簡化、文件等流程缺口。

- 淨新增 3 個（KEEP NEW）：context-engineering、shipping-and-launch、ci-cd-and-automation
- 5 項整併/擴充（MERGED / EXTENDED）：
  - incremental-implementation → 拆分為 implementation-planning（計畫層）+ tdd-workflow（執行層）
  - doubt-driven-development → 合併入 agentic-eval（Pre-Decision Mode）
  - code-simplification → 合併入 refactor（Simplification Mode）
  - performance-optimization → 合併入 refactor（Performance Mode）
  - documentation-and-adrs → 合併入 work-archiving（ADR section）

## Context

### 背景

ai-dev-workflow 是一個部署於 GitHub Copilot（VS Code Extension + Copilot CLI）的 AI 開發工作流程模板，設計目標是讓任何領域的開發者都能透過 SDD（Spec-Driven Development）+ TDD 完成高品質、可稽核的開發週期。目前系統包含 9 個 Agent、32 個 Skill、10 個 Prompt。

### 觸發本次強化的原因

對比 addyosmani/agent-skills 的設計分析後，發現以下可改善方向：

1. **Skill 格式缺乏標準化**：現有 Skill 不含 Anti-Rationalization Table（AI 行為強制機制），也沒有 hardened Verification Checklist，AI 可以輕易找藉口跳過流程。
2. **Agent 協作邊界不清**：9 個 Agent 之間沒有明確的「不得互相呼叫」規則，也缺乏統一的進/退場 Handoff 提示，使用者無法清楚知道何時切換 Agent。
3. **Skill 缺口**：缺少 incremental-implementation（建置策略）、context-engineering（AI context 管理）、doubt-driven-development（對抗性審查）等核心技術 Skill。
4. **agentic-eval 設計漂移**：原本以 Rubber Duck 精神設計的自我審查 Skill，後來被深度綁入 Agent 階段閘門，偏離了核心價值。
5. **gate-check 定位混淆**：包含 Template 自身維護腳本（sync-dotgithub.ps1），但被列為工作流程 Skill，讓使用者誤認為一般開發流程的必要步驟。
6. **workflow-orchestrator 功能分散**：同時承擔「狀態偵測」和「流程引導」兩種不同層次的職責，且引導邏輯應屬於各 Agent 的個性設計。

### 平台範圍限制

**僅支援 GitHub Copilot 生態系**：
- VS Code Copilot Chat Extension（`@workspace` 模式）
- GitHub Copilot CLI（指令列模式）

不在此次範圍：Claude Code、Cursor、Gemini Code Assist、JetBrains AI、其他平台。

---

## Goals

1. **Skill 格式標準化**：為 9 個核心工作流程 Skill 加入 Anti-Rationalization Table + Verification Checklist，使 AI 在每個 Skill 執行結束時都有可驗證的完成標準。
2. **Agent Composition Block**：為全部 9 個 Agent 加入 Composition Block（禁止跨 Agent 呼叫規則）與標準化 Handoff 區塊（進入信號、退出條件、下一步建議）。
3. **agentic-eval 重聚焦**：回歸 Rubber Duck 精神，拆除與 Agent 階段閘門的深度綁定，使其成為「任何情境可自行呼叫的對抗性自我審查工具」。
4. **gate-check 重新標記**：從工作流程 Skill 分類移出，標記為「Template Maintenance Tool」，並從 bootstrap 部署排除。
5. **workflow-orchestrator 精簡**：大幅削減，只保留純狀態偵測邏輯，詳細流程引導職責移轉至各 Agent 的 Handoff 區塊。
6. **新增 3 個 Skill + 擴充 5 個現有 Skill**：引入 context-engineering、shipping-and-launch、ci-cd-and-automation（新建）；擴充 implementation-planning、tdd-workflow、agentic-eval、refactor、work-archiving + security-review（新增模式）。Skill 總數 32 → 35。
7. **更新 AGENTS.md + bootstrap 部署**：所有新增/調整的 Skill 與 Agent 完整更新到目錄文件並維持一致性。

## Non-Goals

- 不支援 GitHub Copilot 以外的 AI 平台
- 不縮減 Agent 數量（保留 9 個）
- 不建置自動化 Session Recovery 機制（hooks + `.ai-workflow-memory` 自動讀取列為未來方向，本次不實作）
- 不更改 `changes/` 目錄結構或 change package 命名規則
- 不修改 bootstrap.ps1 的安裝邏輯（只調整部署清單，排除 gate-check）
- 不新增金融或法規領域特定規則（現有規則維持不變）

## Assumptions

- `[ASSUMED]` 新建的 3 個 Skill 採用與現有 Skill 相同的目錄結構（`skills/<name>/SKILL.md`）；擴充現有 Skill 時以新增區塊（`## Mode Name`）的方式加入，不建立獨立 SKILL.md
- `[ASSUMED]` Verification Checklist 格式：Markdown checkbox（`- [ ]`），不使用外部工具
- `[ASSUMED]` Anti-Rationalization Table 格式與 agent-skills 的 Rationalization/Reality 二欄表一致
- `[ASSUMED]` Composition Block 加在每個 `.agent.md` 的 `## Skill Integration` 之後

> 以上假設若有疑問請於 Plan 階段前確認。

---

## User Stories

### Story 1：開發者執行 Skill 後知道自己做了什麼、沒做什麼

**As a** 使用 ai-dev-workflow 的開發者  
**I want** 每個 Skill 執行結束時有明確的 Verification Checklist  
**So that** 我可以確認 AI 沒有跳過流程、偷懶產出不完整的結果

**Acceptance Criteria**:
- [ ] 9 個核心工作流程 Skill（brainstorming、specification、implementation-planning、tdd-workflow、code-security-review、work-archiving、explore、execution-guardrails、refactor）各自包含 `## Verification` 區塊，含至少 5 個 checkbox 項目
- [ ] 每個 checkbox 都是可觀察的 pass/fail 狀態（不允許「感覺上對了」這類主觀描述）
- [ ] **每個 Skill 的 Verification Checklist 第一條必須是可執行的命令**（例如 `npm test`、`pytest`、`dotnet test`），不得是描述性文字（例如「確認測試通過」），確保 AI 沒有執行驗證就聲稱完成
- [ ] 現有 Skill 中若已有 Checklist，需統一格式為新標準

**Edge Cases**:
- 若 Skill 中既有 `## Validation & Handoff Gate` 且新增 `## Verification`，兩者需明確分工（Validation Gate = 交付前閘門；Verification = 自我完成確認）
- **brainstorming HARD-GATE**（來自 superpowers 設計哲學）：brainstorming Skill 的 Anti-Rationalization Table 必須包含一條：「⛔ 在設計批准前，任何實作程式碼均為違規——無論使用者要求多迫切」。此規則確保 AI 不以「先嘗試看看」為由跳過設計階段

---

### Story 2：開發者面對 AI 找藉口跳過流程時有明確的反制機制

**As a** 使用 ai-dev-workflow 的開發者  
**I want** 每個工作流程 Skill 包含 Anti-Rationalization Table  
**So that** AI 無法用「時間不夠」「這個情況例外」等理由略過標準流程

**Acceptance Criteria**:
- [ ] 9 個核心工作流程 Skill 各自包含 `## Common Rationalizations` 表格，格式為 `| AI 理由 | 實際情況 |` 二欄
- [ ] 每個 Skill 的 Anti-Rationalization 至少涵蓋 3 個常見場景
- [ ] 與 Skill 的核心步驟一致（若 Skill 有 5 個步驟，至少有 1 個理由對應到「跳過某步驟」的情境）
- [ ] **`code-security-review` Anti-Rationalization 加入多角色條目**（來自 gstack）：新增一條：「不能只從程式碼作者視角審查——必須依序切換至少 3 個 Specialist Lens（Security、Performance、Future Maintainer）再完成審查，否則視為不完整審查」

**Edge Cases**:
- 如果 Skill 已有類似的「Red Flags」區塊，需整合或明確說明兩者差異（Red Flags = 操作警示；Rationalizations = AI 行為約束）

---

### Story 3：使用者切換 Agent 時知道何時進入、何時離開

**As a** 在工作流程中切換不同 Agent 的使用者  
**I want** 每個 Agent 的回應中都有清楚的「你現在應該在這個 Agent」提示和「完成後請切換到 X」指引  
**So that** 即使被打斷（會議、電話）後回來，也能快速找回工作流程的位置

**Acceptance Criteria**:
- [ ] 每個 Agent 的 `.agent.md` 包含 `## Handoff` 區塊，格式統一：`### 進入信號`（觸發詞）+ `### 完成條件`（輸出產物）+ `### 下一步`（建議切換的 Agent）
- [ ] 每個 Agent 的 `## Core Principles` 或開場說明中包含一句明確的自我定位（「你現在和 X Agent 對話，我的職責是...」）
- [ ] 9 個 Agent 的 Handoff 區塊資訊彼此一致（brainstorm → spec → plan → coder → code-reviewer 的鏈路不能斷）

**Edge Cases**:
- architect-agent 和 pm-agent 可能在多個階段都有效，需說明「多階段可用」而非「只在 X 階段」
- dba-agent 和 frontend-designer-agent 需說明在 spec/plan 階段就應介入，不只是 coder 階段

---

### Story 4：AI 不會在工作流程中自行呼叫另一個 Agent

**As a** 依賴 ai-dev-workflow 指導 AI 行為的開發者  
**I want** 每個 Agent 明確知道「不得呼叫其他 Agent」的邊界  
**So that** AI 不會擅自 fan-out 到其他 Agent 造成混亂或無法預期的行為

**Acceptance Criteria**:
- [ ] 每個 Agent 包含 `## Composition Rules` 區塊，明確聲明：「不得指示使用者立即切換到另一個 Agent；只能在 Handoff 區塊建議下一步」
- [ ] 唯一例外：pm-agent 可建議使用者切換（因其職責是跨 Agent 協調），但需說明是「建議」而非「命令」
- [ ] 規則在 Agent 的 description YAML frontmatter 中也有對應的觸發關鍵詞說明，不與其他 Agent 觸發詞重疊

**Edge Cases**:
- `/ship` 類型的 fan-out 模式（同時啟動多個 Agent 審查）是否允許？本次 spec 決策：**不引入 /ship fan-out 模式**，工作流程維持線性進行

---

### Story 5：agentic-eval 可在任何情境被呼叫做對抗性自我審查

**As a** 在任何工作流程階段的使用者  
**I want** agentic-eval 是一個獨立的、通用的對抗性審查工具  
**So that** 我可以在任何時候用它來挑戰 AI 的輸出，不需要等到特定的 Stage Gate

**Acceptance Criteria**:
- [ ] agentic-eval SKILL.md 重寫 `## When to Use This Skill` 為通用情境（不與特定 Stage 綁定）
- [ ] 移除 agentic-eval 對各 Agent 的強制性「您必須在此階段呼叫 agentic-eval」文字（改為 Optional 建議）
- [ ] 保留 Tier 1 自我審查（必要）；Tier 2（外部批評模式）和 Tier 3（追蹤評估）設為 `Optional`
- [ ] SKILL.md 加入明確的 `## Rubber Duck Spirit` 區塊，說明核心精神：「用相反論點挑戰自己的輸出，直到找不到反駁為止」
- [ ] agentic-eval 的觸發關鍵詞更新，移除階段性觸發詞，改為情境性觸發詞（如「挑戰這個決策」「扮演反對者」「devil's advocate」）

**Edge Cases**:
- AGENTS.md 中的 `agentic-eval 品質閘門` 表格需同步更新，標記哪些是強制（Financial Precision）哪些是建議
- 各 Agent `.agent.md` 中提到 agentic-eval 的部分需改為 Optional 語氣

---

### Story 6：gate-check 清楚標示為 Template Maintenance Tool

**As a** 使用 bootstrap 將 ai-dev-workflow 部署到新專案的開發者  
**I want** gate-check 不出現在我的工作流程 Skill 清單中  
**So that** 我不會誤以為需要在開發流程中執行 Template 維護腳本

**Acceptance Criteria**:
- [ ] gate-check 的 SKILL.md frontmatter 的 `description` 更新，明確標示「僅適用於 ai-dev-workflow 模板本身的維護」
- [ ] AGENTS.md 中 gate-check 從「Core Workflow Skills」分類移至新分類「Template Maintenance Tools」
- [ ] bootstrap.ps1 / install-apply.ps1 的部署清單中排除 gate-check（不複製到目標專案的 `.github/skills/`）
- [ ] SKILL.md 加入 `## ⚠️ Scope` 區塊：說明此工具只適合 ai-dev-workflow Template Repo 本身的維護者使用
- [ ] **加入遷移說明**：INSTALL.md 或 QUICKSTART.md 中加入一段：「若你的 `.github/skills/` 已包含 `gate-check`（舊版 bootstrap 部署），可安全刪除該目錄，它是 Template 維護工具，不屬於開發工作流程」

**Edge Cases**:
- 若目標專案恰好也需要 sync-dotgithub 類型的工具，應引導使用者自行建立，而非依賴此 gate-check

---

### Story 7：workflow-orchestrator 精簡為純狀態偵測

**As a** 剛開始使用 ai-dev-workflow 的使用者  
**I want** workflow-orchestrator 快速告訴我「現在在哪個階段」  
**So that** 不需要記住複雜的流程，也能快速回到工作狀態

**Acceptance Criteria**:
- [ ] workflow-orchestrator SKILL.md 保留 `changes/` 目錄狀態偵測邏輯（掃描 01/02/03/04/05/06 文件的存在與否）
- [ ] 移除 SKILL.md 中所有「切換到 X Agent」的詳細說明（這些移至各 Agent 的 Handoff 區塊）
- [ ] SKILL.md 輸出格式精簡為：當前階段 + 下一步建議（2-3 行），不再列出每個 Agent 的完整說明
- [ ] AGENTS.md 更新描述，反映精簡後的新定位

**Edge Cases**:
- 若 `changes/` 目錄不存在（全新專案），需給出「從頭開始」的建議（觸發 brainstorm-agent）

---

### Story 8：垂直切片策略整合至 implementation-planning 與 tdd-workflow

> **整併說明**：水平切片反模式的根源在於**計畫結構**，因此防線主力設在 implementation-planning（計畫時就切對）；tdd-workflow 負責執行時的切片紀律與停損規則。不另建獨立 Skill。

**As a** 使用 plan-agent + coder-agent 開發功能的開發者  
**I want** 規劃時就強制垂直切片，coding 時也有明確的切片執行與停損規則  
**So that** 水平切片反模式從計畫源頭就被阻止，不依賴開發者記憶

**Acceptance Criteria**:

**[implementation-planning Skill 擴充]**
- [ ] `skills/implementation-planning/SKILL.md` 加入 `## Vertical Slice Strategy` 區塊：定義垂直切片（從接口到資料層的完整功能薄片）、切片大小標準（每個切片的工作量不超過 1 個 commit）、純後端 / DB migration 情境的說明（UI 層可選，但 Task 仍需完整涵蓋一個可獨立驗證的功能單元）
- [ ] 加入 `## Anti-Pattern: Horizontal Slicing` 警告：「Task 1: 所有測試 / Task 2: 所有實作」是計畫層面的水平切片。plan-agent 不得產出此結構，若某個 Task 只包含測試或只包含實作（無對應完整功能），必須標記為 Spec Gap 並要求重新切分
- [ ] plan-agent 的 Skill Integration 更新：加入「每個 Task = 一個完整垂直切片」的 plan-level enforcement 說明

**[tdd-workflow Skill 擴充]**
- [ ] `skills/tdd-workflow/SKILL.md` 加入切片執行提醒：每個 Red-Green 循環 = 一個垂直切片，不得在同一循環中批量寫多個測試再一次實作
- [ ] 加入**三次修復停止法則**（來自 superpowers）：若同一個錯誤連續 3 次修復失敗，停止修復行為，向使用者報告根本原因假設清單，不得繼續嘗試
- [ ] 加入**可調試反饋循環前置條件**（來自 mattpocock）：若沒有快速反饋循環（測試觀察模式 / hot-reload / REPL），先建立反饋循環才能開始實作；無法建立則暫停並說明原因
- [ ] coder-agent 的 Skill Integration 更新：說明 Red-Green 循環 = 一個垂直切片，計畫層切片規則見 implementation-planning

---

### Story 9：AI 在提出技術選擇時必須引用可信來源（context-engineering）

**As a** 依賴 AI 做技術決策的開發者  
**I want** 有一個 Skill 指導 AI 如何系統性地組織和提供 context  
**So that** AI 的回答基於正確的專案資訊，而非通用假設

**Acceptance Criteria**:
- [ ] 新增 `skills/context-engineering/SKILL.md`
- [ ] 定義 5 層 Context 架構（Project context、Codebase context、Task context、Conversation context、External docs）
- [ ] 包含「Context 污染」的 Anti-Rationalization（AI 使用過時/無關資訊的常見情境）
- [ ] 包含可操作的 Verification（使用者可驗證 AI 的回答是否有明確的 context 來源）
- [ ] **執行後產出 `CONTEXT.md` 可交付文件**：記錄專案領域術語（Ubiquitous Language）與核心架構決策摘要，供後續所有 Agent session 引用。若 `.ai-workflow-memory/` 存在則存入其中，否則存至 `docs/CONTEXT.md`
- [ ] **詞彙衝突偵測步驟**（來自 mattpocock/grill-with-docs）：SKILL.md 的 Process 加入步驟：「比較使用者在此次對話中使用的術語與 CONTEXT.md 的詞彙定義，若發現衝突或模糊，立即釐清，不得假設對方意圖」
- [ ] 適用於所有使用 AI 進行技術決策的 Agent（architect-agent 優先）

**Edge Cases**:
- 若專案沒有 `.ai-workflow-memory/`，如何提供 Project context？備用路徑：產出 `docs/CONTEXT.md`，並在 SKILL.md 說明「至少在對話開頭貼上 CONTEXT.md 內容」的 fallback 機制
- `CONTEXT.md` 的術語應與程式碼中的命名一致（避免 AI 使用「20 個詞解釋 1 個概念」的冗長回應）

---

### Story 10：agentic-eval 擴充 Pre-Decision Mode（整併 doubt-driven-development）

> **整併說明**：agentic-eval 已有 Post-Output Rubber Duck（產出後審查）。Pre-Decision Mode 是同一「對抗性思維」的另一個時機（決策前）。兩者合一，讓使用者只需記住 agentic-eval 即可，不需再認識一個新 Skill。

**As a** 需要 AI 做高風險技術決策的開發者  
**I want** agentic-eval 同時提供「決策前的系統性懷疑」和「輸出後的對抗性驗證」  
**So that** 重要決策不會因為 AI 的確認偏誤而在沒有審查的情況下執行

**Acceptance Criteria**:
- [ ] `skills/agentic-eval/SKILL.md` 加入 `## Pre-Decision Mode（決策前懷疑模式）` 區塊，與現有 Post-Output Rubber Duck Mode 並列
- [ ] Pre-Decision Mode 包含 CLAIM → EXTRACT → DOUBT → RECONCILE → STOP 五步驟流程，每個步驟有具體操作說明（不是模糊的「質疑你的假設」）
- [ ] 包含觸發條件：High Risk 決策、架構選擇、不可逆操作 → 必須執行 Pre-Decision Mode
- [ ] **Sequential Specialist Lens** 整合：DOUBT 步驟依序以 Security / Performance / Architecture / Maintainability / Accessibility 五個視角審查，每個視角至少產出 1 個質疑或確認，不得只從「提案者視角」審查
- [ ] **設計評審打分制**（來自 gstack）：RECONCILE 步驟加入「0-10 分自評 → 描述 10 分長什麼樣（理想標準）→ 編輯直到達到目標分數」機制
- [ ] `## When to Use` 更新：加入「High Risk 決策前（Pre-Decision）」和「輸出完成後（Post-Output）」兩個明確觸發場景，避免使用者混淆兩種模式
- [ ] architect-agent 的 Skill Integration 更新：說明高風險架構決策時優先使用 Pre-Decision Mode

---

### Story 11：refactor Skill 擴充 Simplification Mode 與 Performance Mode（整併 code-simplification 與 performance-optimization）

> **整併說明**：refactor 原本專注於「結構重組」。Simplification（可讀性改善，不改結構）和 Performance（效能優化）本質上都是「改善程式碼，不改行為」的一類工作，與 refactor 目標一致，加入為不同模式而非獨立 Skill，減少使用者的認知負擔。

**As a** 需要改善程式碼可讀性或效能的開發者  
**I want** refactor Skill 能處理從結構重組到可讀性改善再到效能優化的完整範圍  
**So that** 不需要記住多個 Skill，refactor 就能提供完整的「改善程式碼，不改行為」指引

**Acceptance Criteria**:

**[Simplification Mode]**
- [ ] `skills/refactor/SKILL.md` 加入 `## Simplification Mode（輕量模式）` 區塊，與現有 Structural Refactor Mode 並列
- [ ] 明確說明兩種模式的差異：Structural Refactor（函式拆解、模組重組）vs Simplification（變數命名、inline、可讀性，不改結構）
- [ ] Simplification Mode 包含 **Chesterton's Fence** 原則：在移除任何程式碼前，必須先理解「為何有這段程式碼」，不理解不移除
- [ ] Simplification Mode 包含 **Rule of 500**：單一函式超過 500 行需要自動化工具協助分析，不得人工粗暴刪減
- [ ] Simplification Mode 的 Verification Checklist：所有既有測試通過、build 成功、沒有混入 feature 變更或結構變更
- [ ] 若專案沒有測試：說明「先加對應覆蓋，再簡化」的前置步驟

**[Performance Mode]**
- [ ] 加入 `## Performance Mode（效能優化模式）` 區塊
- [ ] 硬性前置條件：**Measure First**——任何效能優化必須先有量測數據（profiler 輸出、benchmark baseline），禁止基於直覺進行優化
- [ ] 包含效能優化後的 Verification：量測數據改善（量化）、所有既有測試通過
- [ ] 加入 Anti-Pattern 說明：premature optimization、無量測基線的優化

**[模式選擇指引]**
- [ ] 更新 `## When to Use`：說明三種模式的選擇指引——結構問題選 Structural Refactor，可讀性問題選 Simplification，效能問題選 Performance Mode

---

### Story 12：新增 shipping-and-launch、ci-cd-and-automation Skill；擴充 work-archiving、security-review

> **整併說明**：performance-optimization → refactor（Performance Mode）；documentation-and-adrs → work-archiving（ADR Section）。shipping-and-launch 和 ci-cd-and-automation 無對應現有 Skill，保留為獨立新建。

**As a** 完成開發後需要上線的開發者  
**I want** 工作流程涵蓋「建置完成到上線」的完整指引  
**So that** 不需要依賴記憶或外部清單，ai-dev-workflow 就能引導完整的 Ship 流程

**Acceptance Criteria**:

**[新建 Skill]**
- [ ] 新增 `skills/shipping-and-launch/SKILL.md`：涵蓋 staged rollout、rollback plan、production checklist；與 work-archiving 明確分工（work-archiving = 內部收尾，shipping-and-launch = 外部部署上線）
- [ ] 新增 `skills/ci-cd-and-automation/SKILL.md`：Shift Left 原則、quality gate pipeline 設計
- [ ] 以上兩個新 Skill 都包含 Verification Checklist 和 Anti-Rationalization Table

**[擴充現有 Skill]**
- [ ] `skills/work-archiving/SKILL.md` 加入 `## ADR Section` 區塊：**ADR 三條件寫作法**（來自 mattpocock）——僅在以下三個條件全為真時才寫 ADR：（1）難以反轉的決策、（2）未來的人會對此感到困惑、（3）真正的折衷取捨存在。三條件作為寫 ADR 前的前置確認步驟，AI 必須逐條確認，不得跳過
- [ ] **`security-review` Skill 加入 CSO 雙模式**（來自 gstack CSO 角色設計）：**Quick Gate 模式**（每次 PR：自評信心分數，低於 8/10 則強制列出具體擔憂項目，不得放行）和 **Deep Scan 模式**（週期性或高風險功能：完整 OWASP 威脅模型掃描）。使用者在呼叫時選擇模式，預設為 Quick Gate

**[目錄更新]**
- [ ] AGENTS.md 更新，加入 shipping-and-launch、ci-cd-and-automation 至 Skill 目錄

---

### Story 13：spec-agent 撰寫 AC 時強制品質機制

> **來源整合**：Observable Outcome AC 格式（mattpocock）、Sequential Specialist Lens AC 缺口審查（gstack）、grill-with-docs 詞彙鎖定步驟（mattpocock）、spec-specific Anti-Rationalization（superpowers）。

**As a** 使用 spec-agent 產出規格文件的開發者  
**I want** spec-agent 在撰寫 AC 時遵循可觀察輸出格式，並從多個視角主動找覆蓋缺口  
**So that** 規格文件不會因為模糊的 AC 或詞彙衝突，在計畫和實作階段製造誤解

**Acceptance Criteria**:

**[AC 格式強制 — Observable Outcome，來自 mattpocock]**
- [ ] `skills/specification/SKILL.md` 的 AC 範本格式更新：每條 AC 必須是「Observable Outcome」（描述可觀察的系統行為或狀態），不得是「Intention Statement」（描述意圖但無法直接驗證）
- [ ] 加入正確 vs 錯誤範例：
  - ❌ `使用者能夠成功登入`（意圖陳述，無法直接測試）
  - ✅ `POST /api/auth/login 回傳 200 和有效 JWT，當 email/password 正確時`（可觀察的系統回應）
  - ❌ `系統應該要快`（意圖，無量化標準）
  - ✅ `GET /api/items 在 p99 延遲 < 200ms，1000 QPS 負載下`（可量化的觀察結果）

**[Sequential Specialist Lens AC 缺口審查 — 來自 gstack]**
- [ ] `skills/specification/SKILL.md` 在 Step 3 Validation 加入 `### Specialist Lens Review`（在 agentic-eval 閘門之前執行）：spec-agent 完成所有 Story 後，依序以下列視角掃描 AC 覆蓋缺口，每個視角必須產出至少 1 個「確認已覆蓋」或「補充新 AC」的結論：
  - 🔒 **Security Lens**：有沒有未被 AC 覆蓋的認證/授權/資料保護場景？
  - ⚡ **Performance Lens**：有沒有未被 AC 覆蓋的吞吐量/延遲/容量限制場景？
  - 🧪 **QA Lens**：有沒有可能讓既有 AC 失敗、但尚未被文件化的錯誤條件？
  - 👤 **UX Lens**：有沒有未被 AC 覆蓋的使用者回饋/錯誤訊息/空狀態場景？
- [ ] Specialist Lens Review 的輸出格式：每個視角一行，格式為「🔒 Security: [確認已覆蓋 / 新增 AC：...]」

**[grill-with-docs 詞彙鎖定步驟 — 來自 mattpocock]**
- [ ] `skills/specification/SKILL.md` 在 Step 2（撰寫 User Stories）開始前，加入「詞彙鎖定」前置步驟：spec-agent 列出本次 spec 中所有領域術語（至少 3 個）→ 對每個術語確認其在現有程式碼/文件中的用法是否一致
- [ ] 若術語是 spec 中新創的（現有程式碼/文件不存在此詞），必須標記 `[NEW TERM]` 並在 Assumptions 區塊說明其定義
- [ ] spec-agent 的完成條件更新：「無未標記的 [NEW TERM]」列為交付前的必要確認項目

**[spec-specific Anti-Rationalization 內容 — 來自 superpowers]**
- [ ] `skills/specification/SKILL.md` 的 `## Common Rationalizations`（FR-1 將建立此區塊）加入 spec-specific 條目：

  | AI 常見理由 | 實際情況 |
  |------------|---------|
  | 「這是技術決定，spec 不該管」 | spec 定義行為邊界和約束；實作細節是 plan 的責任，但約束必須在 spec 定義 |
  | 「Edge case 機率很低，可以跳過」 | 機率低不代表影響低；edge case 正是 spec 的核心責任，低機率高影響最需要文件化 |
  | 「細節之後再補，先交出 spec」 | 帶 [ASSUMED] 的 spec 不得交付；計畫不能從未確認的假設出發 |
  | 「這個 AC 太技術性了不用在 spec 寫」 | AC 描述行為，不描述實作；技術性的行為邊界（如延遲上限、並行衝突）必須在 spec 定義 |

**Edge Cases**:
- UX Lens 對純後端 API spec 的適用性：仍適用，聚焦在「API 消費者的錯誤處理體驗」（錯誤碼是否清楚、錯誤訊息是否可操作）
- 詞彙鎖定步驟若找不到現有文件可比對：退回到 brainstorm 輸出的術語定義為基準，無基準則必須在 Assumptions 定義

**[Token 預算與檔案結構 — 官方 Skill 規範]**
- [ ] `skills/specification/SKILL.md` 主體保持在 **500 行以內**（官方上限）；Story 13 新增的詳細內容（範例庫、審查清單、顧問審查協議）移至 `skills/specification/references/` 子資料夾：
  - `references/ac-format-guide.md`：Observable Outcome 正反範例庫
  - `references/specialist-lens-review.md`：4 視角審查完整清單與輸出範本
  - `references/consult-review-protocol.md`：dba-agent / frontend-designer-agent 顧問審查流程
- [ ] SKILL.md 主體只保留各步驟的「入口說明」和「references/ 連結」，不直接內嵌所有細節

---

### FR-1: Skill 格式標準化（Anti-Rationalization + Verification）
**Description**: 為以下 9 個核心工作流程 Skill 加入統一格式的 Anti-Rationalization Table 和 Verification Checklist：brainstorming、specification、implementation-planning、tdd-workflow、code-security-review、work-archiving、explore、execution-guardrails、refactor。workflow-orchestrator 因本次精簡，格式調整隨 FR-5 一併處理。  
**Priority**: Must-Have  
**Dependencies**: 無

**Anti-Rationalization Table 格式**:
```markdown
## Common Rationalizations

| AI 常見理由 | 實際情況 |
|------------|--------|
| "這個情況比較特殊，可以跳過..." | 特殊情況正是最需要遵循流程的時候 |
```

**Verification Checklist 格式**:
```markdown
## Verification

After completing this skill:
- [ ] [可觀察的完成標準 1]
- [ ] [可觀察的完成標準 2]
```

---

### FR-2: Agent Composition Block 與 Handoff 區塊
**Description**: 為全部 9 個 Agent（brainstorm、architect、spec、plan、coder、code-reviewer、pm、frontend-designer、dba）加入 Composition Block 和標準化 Handoff 區塊。  
**Priority**: Must-Have  
**Dependencies**: 無

**Composition Block 格式**:
```markdown
## Composition Rules

- **No cross-agent invocation**: Do NOT instruct the user to immediately switch to another agent mid-task. Complete your current responsibility first.
- **Handoff only**: When your task is done, suggest the next agent in the `## Handoff` section — as a recommendation, not a command.
- **Exception (pm-agent only)**: pm-agent may coordinate agent suggestions as part of its cross-project tracking role.
```

**Handoff 區塊格式**:
```markdown
## Handoff

### Entry Signals
Triggers that indicate the user should engage this agent:
- [觸發詞/情境 1]
- [觸發詞/情境 2]

### Completion Conditions
This agent's work is done when:
- [ ] [產出物 1 存在且通過品質閘門]
- [ ] [產出物 2 完成]

### Next Step
- **Standard Path** → [下一個 Agent]
- **Fast Path** (low-risk only) → [快速路徑選項]
```

---

### FR-3: agentic-eval 重新聚焦
**Description**: 重寫 agentic-eval SKILL.md，回歸 Rubber Duck 精神，解除與 Agent 階段閘門的強制綁定。  
**Priority**: Must-Have  
**Dependencies**: FR-1 完成後確認各 Skill 已有 Verification Checklist（agentic-eval 成為補充而非主要閘門）

**具體變更**:
- 新增 `## Rubber Duck Spirit` 區塊（核心精神說明）
- `## When to Use` 改為通用情境（任何決策、任何輸出都可呼叫）
- Tier 2（外部批評）和 Tier 3（追蹤評估）加上 `(Optional)` 標記
- 移除「Agent X 在 Y 階段必須呼叫 agentic-eval」的強制文字
- 更新觸發關鍵詞（移除階段性觸發，改為情境性觸發）

---

### FR-4: gate-check 重新標記
**Description**: 將 gate-check 重新定位為 Template Maintenance Tool，並從 bootstrap 部署排除。  
**Priority**: Must-Have  
**Dependencies**: 無

**具體變更**:
- SKILL.md frontmatter description 更新
- SKILL.md 加入 `## ⚠️ Scope` 區塊（明確說明適用範圍）
- AGENTS.md 中移至 `Template Maintenance Tools` 分類
- `bootstrap.ps1` 和 `tools/install-apply.ps1` 的部署 Skill 清單排除 gate-check

---

### FR-5: workflow-orchestrator 精簡
**Description**: 大幅精簡 workflow-orchestrator SKILL.md，只保留狀態偵測邏輯，移除詳細的 Agent 引導說明。  
**Priority**: Must-Have  
**Dependencies**: FR-2 完成（各 Agent 的 Handoff 區塊已建立，才能安全移除 workflow-orchestrator 的引導職責）

> ⛔ **強制前置確認**：本 FR 必須在 FR-2 完整驗收通過（9 個 Agent 的 Handoff 區塊全部建立）後才能執行。若 Plan 階段的任務排序將 FR-5 排在 FR-2 之前，視為 Plan 錯誤，需重新排序。

**具體變更**:
- 保留：`changes/` 目錄文件存在偵測邏輯（01/02/03/04/05/06 文件）
- 移除：每個 Agent 的詳細功能說明（已移至各 Agent 的 Handoff 區塊）
- 輸出格式：精簡為「當前階段：X → 下一步：Y」（2-3 行，不超過）
- 加入：若 `changes/` 不存在的初始狀態處理（建議 brainstorm-agent）

---

### FR-6: 新增 3 個 Skill + 擴充 5 個現有 Skill
**Description**: 依整併決策（Story 8/10/11/12），3 個新 Skill 獨立建立，5 個現有 Skill 以模式擴充方式加入新能力，Skill 總數從 32 增至 35。  
**Priority**: Must-Have（P1）/ Should-Have（P2）  
**Dependencies**: FR-1 完成（標準格式確立後，新 Skill 才能套用一致格式）

**新建 Skill（3 個）**：

| 優先序 | Skill 名稱 | 分類 | 對應 Agent |
|--------|-----------|------|-----------|
| P1 | context-engineering | Cross-Cutting | 所有 Agent |
| P2 | shipping-and-launch | Core Workflow | code-reviewer-agent、pm-agent |
| P2 | ci-cd-and-automation | Core Workflow | coder-agent、code-reviewer |

**擴充現有 Skill（5 個）**：

| 優先序 | 目標 Skill | 加入內容 | 整併來源 |
|--------|-----------|---------|---------|
| P1 | implementation-planning | Vertical Slice Strategy + Anti-Pattern: Horizontal Slicing | incremental-implementation（計畫層） |
| P1 | tdd-workflow | 切片執行提醒 + 三次修復停止法則 + 可調試反饋循環前置條件 | incremental-implementation（執行層） |
| P1 | agentic-eval | Pre-Decision Mode（DDD 五步驟 + Sequential Specialist Lens + 打分制） | doubt-driven-development |
| P1 | refactor | Simplification Mode + Performance Mode | code-simplification + performance-optimization |
| P2 | work-archiving | ADR Section（三條件寫作法） | documentation-and-adrs |
| P2 | security-review | CSO 雙模式（Quick Gate / Deep Scan） | 來自 gstack CSO 角色設計 |

> **結果：32 → 35 個 Skill（+3 新建，+5 擴充，不增加 Skill 數量）**

---

### FR-8: 新 Skill 行為驗收協議（新增）
**Description**: 每個新建 Skill（共 3 個）在合併前必須通過至少 1 個 adversarial pressure session；擴充現有 Skill 的新增區塊也需各通過 1 個對應的壓力場景，驗證新規則能有效反制常見的 rationalization 行為。  
**Priority**: Must-Have（配合 FR-6 同時完成）  
**Dependencies**: FR-6（Skill 初稿完成後才能驗收）

**驗收範圍**:
- 新建 Skill（3 個）：context-engineering、shipping-and-launch、ci-cd-and-automation → 各 1 個壓力場景
- 擴充現有 Skill 的新模式/區塊（6 個）：Vertical Slice + 三次修復 / Pre-Decision Mode / Simplification Mode / Performance Mode / ADR Section / CSO 雙模式 → 各 1 個壓力場景

**驗收方式**:
1. 對每個目標撰寫 1 個「壓力場景」（pressure scenario）：描述一個 AI 想跳過該規則的具體情境
2. 以 rubber-duck agent 執行該場景，確認文字能引導 AI 拒絕跳過
3. 驗收記錄寫入 `changes/2026-05-12-skill-enhancement/skill-pressure-tests.md`（每個目標一段落）

**失敗條件**:
- 文字含糊到讓 AI「合理化」跳過規則 → 必須修訂 Anti-Rationalization Table
- 連續 2 次壓力測試失敗 → 升級為 rubber-duck agent 全面審查

---

### FR-7: AGENTS.md 與 bootstrap 同步更新
**Description**: 所有 Skill 新增/調整/分類變更後，同步更新 AGENTS.md 的 Skill 目錄表格，並執行 `pwsh -File .\tools\sync-dotgithub.ps1` 同步到 `.github/`。  
**Priority**: Must-Have  
**Dependencies**: FR-1 至 FR-6 全部完成

**具體變更**:
- AGENTS.md Skill 目錄：32 個 → 35 個（+3 新建，+5 擴充現有 Skill）
- Core Workflow Skills：新增 shipping-and-launch、ci-cd-and-automation
- Cross-Cutting Quality Skills：新增 context-engineering
- 現有 Skill 描述更新（implementation-planning、tdd-workflow、agentic-eval、refactor、work-archiving、security-review 加入新模式說明）
- 新分類「Template Maintenance Tools」：移入 gate-check
- 各 Agent 的 `## Skill Integration` 更新，加入新模式的對應引用

---

## Technical Considerations

### Skill 格式規範

#### Frontmatter 欄位規範（官方確認，來自 AgentSkills.io 規範 + VS Code Docs 2026/05）

| 欄位 | 必要 | 規格 | 注意事項 |
|------|------|------|---------|
| `name` | **必要** | 最多 64 字元，只能用小寫英文、數字、連字號；**必須與父目錄名稱完全一致** | ⚠️ 含斜線、冒號、命名空間前綴（如 `myorg/name`）→ **靜默失敗，不載入** |
| `description` | **必要** | 最多 1024 字元 | 主要 auto-load 觸發機制，見下方撰寫規則 |
| `user-invocable` | 選填 | `false` = 隱藏 slash menu，但仍可 auto-load | 適用於跨切面背景 Skill（如 execution-guardrails） |
| `disable-model-invocation` | 選填 | `true` = 只能手動呼叫，不 auto-load | 適用於重量級 Skill（如 gate-check） |

**description 撰寫規則（官方 best practice）**：
- 用**祈使語氣**：`"Use this skill when..."` 而非 `"This skill does..."`
- 明確加入**負向觸發條件**：`"Do not trigger when..."` 防止錯誤 auto-load
- 聚焦**使用者意圖**，而非內部機制
- 範例（官方 before/after）：
  ```yaml
  # ❌ 太模糊
  description: 'Process CSV files.'
  
  # ✅ 有效
  description: >
    Use this skill when the user has a CSV, TSV, or Excel file and wants to
    explore, transform, or visualize data. Do not trigger for routine feature
    implementation or code edits unless the user explicitly asks for data analysis.
  ```

**靜默失敗防護清單**（實作前必須確認）：
- [ ] `name` 值只含小寫英文、數字、連字號
- [ ] `name` 值與 `skills/` 下的目錄名稱完全一致
- [ ] `name` 值不含 `/`、`:`、`.`、命名空間前綴

**Progressive Loading 規則**（L1/L2/L3）：
- **L1（Discovery）**：`name` + `description` 在所有 Skill 啟動時全部載入（~100 tokens）
- **L2（Instructions）**：完整 SKILL.md body，description 符合任務時才載入（< 5000 tokens 上限）
- **L3（Resources）**：`references/`、`scripts/`、`assets/` 下的檔案，**只在 SKILL.md body 明確引用（含觸發條件）時才載入**

> ⚠️ **L3 關鍵原則**：`references/` 下的檔案必須在 SKILL.md body 中用明確語句引用並說明觸發條件，例如：`"Read references/ac-format-guide.md when the user asks for AC format examples."`。未被引用的 references/ 檔案**永遠不會被載入**。

所有新 Skill 和修改後的 Skill 必須符合以下結構順序：

```markdown
---
name: skill-name
description: 'Use this skill when... Do not trigger when...'
---

# Skill Title

> 💡 **Recommended Agent**: [agent-name]

## When to Use This Skill

## Prerequisites (optional)

## Process / Step-by-Step Workflow

## Common Rationalizations  ← 新標準區塊

| AI 常見理由 | 實際情況 |
|------------|--------|

## Red Flags (optional)

## Verification  ← 新標準區塊

- [ ] checkbox items

## Next Step
```

### Agent 格式規範

#### Frontmatter 欄位規範（官方確認，來自 VS Code Docs 2026/05）

| 欄位 | 必要 | 規格 | 注意事項 |
|------|------|------|---------|
| `description` | **建議** | 無字元上限（與 Skill 不同） | 顯示為 chat input 的 placeholder 文字 |
| `name` | 選填 | **人類可讀格式**（`"Plan Mode - Strategic Planning"` 而非 kebab-case） | 省略時用檔名 |
| `tools` | 選填 | YAML 陣列 | 限制 Agent 可用工具，planning agent 不得含 `edit` |
| `agents` | 選填 | YAML 陣列（`*` = 全部，`[]` = 禁止子 Agent） | 控制可調用的 sub-agent 範圍 |
| `model` | 選填 | 單一模型名稱或優先序陣列 | 陣列格式：依序嘗試，前者不可用才用下一個 |
| `handoffs` | **建議加入** | YAML 陣列（見下方範例） | 正式化跨 Agent 工作流程轉移點 |
| `user-invocable` | 選填 | `false` = 只能作為 sub-agent | 不出現在使用者 dropdown |

> ⚠️ **Agent 官方無行數限制**。本 repo 的 ≤25 non-empty lines 是**設計目標**，非官方規範。  
> **設計理由**：Agent body 在被選中後全程佔用 context window，Skill 的 L2 body 則按需載入。因此 Agent 應只保留 persona 和 orchestration 指令，詳細流程邏輯移至配對 Skill（L2 按需載入）。超出 25 行時，先判斷能否將內容移至 `## Skill Integration` 引用的 Skill。

**`handoffs` 欄位範例（Consult Review 形式化機制）**：

```yaml
handoffs:
  - label: "🔍 DB 設計審查"
    agent: dba
    prompt: "請以 DBA 視角審查上方 spec 文件，列出資料庫設計缺口清單。"
    send: false    # false = 預填 prompt，等使用者確認後送出
  - label: "🎨 前端設計審查"
    agent: frontend-designer
    prompt: "請以 Frontend Designer 視角審查上方 spec 文件，列出 UI/UX 設計缺口清單。"
    send: false
```

> 這讓 spec-agent 完成初稿後，介面自動出現「DB 設計審查」和「前端設計審查」按鈕，使用者點擊後觸發對應的 Consult Review，**形式化取代口頭約定**。

所有修改後的 Agent 必須包含（依此順序）：

```markdown
---
name: "Agent Title - Subtitle"   # 人類可讀格式
description: '...'
tools: [...]
handoffs:                          # 選填，但建議加入明確的工作流程出口
  - label: "..."
    agent: next-agent
    prompt: "..."
    send: false
---

# Agent Title

[Self-introduction sentence: "你現在和 X Agent 對話，我的職責是..."]

## Core Principles

## Composition Rules  ← 新標準區塊

## Skill Integration

## Handoff  ← 新標準區塊（取代或擴充現有 ## Handoff）
### Entry Signals
### Completion Conditions
### Next Step
```

### 一致性約束

- 所有 Skill 和 Agent 的 source-of-truth 在 `agents/` 和 `skills/` 根目錄
- 每次修改後必須執行 `pwsh -File .\tools\sync-dotgithub.ps1`
- 不得直接修改 `.github/agents/` 或 `.github/skills/`（由 sync 腳本負責）
- AGENTS.md 和 `.github/copilot-instructions.md` 需同步更新 Skill 計數

### bootstrap 部署清單修改

`tools/install-apply.ps1` 的 Skill 複製邏輯需排除 `gate-check`：
```powershell
# 排除 template-only skills
$excludedSkills = @('gate-check')
```

### Token 預算約束

為避免新增格式後大幅增加 context window 負擔，所有 Skill 的新格式區塊需遵守以下上限：

| 格式區塊 | 最大條目數 | 估計 token 增量 |
|---------|---------|----------------|
| Anti-Rationalization Table | 最多 5 條 | ~120 tokens |
| Verification Checklist | 最多 7 個 checkbox | ~80 tokens |
| Composition Rules | 最多 3 條規則 | ~60 tokens |
| Handoff 區塊（Entry + Completion + Next Step）| — | ~100 tokens |

**目標**：每個 Skill 新增格式後 token 增量不超過 400 tokens。超過者需重新精簡或拆分 Skill。

> **驗證方式**：以 `tiktoken` 或 VS Code LLM Token Counter 實測，格式調整前後差值 ≤ 400。

### 參考專案品質機制整理（Research Findings）

以下機制來自對 obra/superpowers、mattpocock/skills、garrytan/gstack 的深入研究，已分散整合至各相關 User Story AC；此處彙整作為實作參考。

#### 降低 AI 幻覺

| 機制 | 來源 | 落地位置 |
|------|------|--------|
| `verification-before-completion` 鐵律：沒有執行命令就不能聲稱完成 | superpowers | Story 1 AC（Verification 第一條必須是可執行命令） |
| Anti-Rationalization Table：主動列舉並逐一反駁 AI 藉口 | superpowers | Story 2 AC（全部 9 個核心 Skill） |
| brainstorming HARD-GATE：設計批准前禁止任何實作程式碼 | superpowers | Story 2 Edge Cases（brainstorming Skill 強制條目） |
| 詞彙衝突偵測（grill-with-docs）：即時比對使用者術語 vs CONTEXT.md | mattpocock | Story 9 AC（context-engineering Process） |

#### 提升文件品質

| 機制 | 來源 | 落地位置 |
|------|------|--------|
| ADR 三條件寫作法（難以反轉 + 未來困惑 + 真正折衷）| mattpocock | Story 12 AC（documentation-and-adrs Process 第一步） |
| CONTEXT.md 共享語言：讓 AI 用「1 詞」代替「20 詞」| mattpocock | Story 9 AC（context-engineering 可交付產物） |
| 設計評審打分制：先打分 → 定義 10 分標準 → 改到目標分 | gstack | Story 10 AC（doubt-driven-development Process） |
| **Sequential Specialist Lens**：依序切換專家視角（Security / Performance / Architecture / Maintainability / Accessibility）| gstack | Story 10 AC（doubt-driven-development DOUBT 步驟）+ Story 2 AC（code-security-review） |
| **CSO 雙模式**：Quick Gate（信心 < 8/10 則強制列擔憂）+ Deep Scan（深度 OWASP 掃描）| gstack | Story 12 AC（security-review Skill 雙模式） |

#### 降低程式碼出錯率

| 機制 | 來源 | 落地位置 |
|------|------|--------|
| 三次修復停止法則：連續 3 次失敗 → 停止，質疑架構假設 | superpowers | Story 8 Edge Cases（incremental-implementation） |
| 可調試反饋循環前置條件：沒有循環就不能開始調試/實作 | mattpocock | Story 8 Edge Cases（incremental-implementation Prerequisites） |
| adversarial pressure session：subagent 壓力測試 Skill 文字抵抗力 | superpowers | FR-8（新 Skill 行為驗收協議） |
| 垂直切片 vs 水平切片的明確反模式警告 | mattpocock | Story 8 AC（Anti-Pattern: Horizontal Slicing 區塊） |

#### Phase 2 候選（本次不實作）

| 機制 | 來源 | 說明 |
|------|------|------|
| 動態 handoff Skill（對話壓縮為可執行交付文件）| mattpocock | Open Question 4；與 Copilot session checkpoint 相容性待確認 |
| canary 部署後持續監控 | gstack | ci-cd-and-automation Skill 可包含，但屬 Phase 2 |

#### gstack 多角色機制的正確詮釋與落地

> **先前的分析錯誤**：將 gstack 的多角色評審定性為「fan-out 平行執行 → 不適用」。這是誤判。gstack 的核心洞察不是「平行」，而是**順序切換不同專家視角（Sequential Specialist Lens）**——同一個 AI 依序戴上不同的「角色帽子」進行審查，每個角色的盲點和關注點本質上不同，因此能發現單一角色看不見的問題。這個機制在 GitHub Copilot 單 session 中完全可實作。

**gstack 多角色機制的三個核心價值**：

1. **Sequential Specialist Lens**：評審時依序切換角色（安全官 → 效能工程師 → 架構師 → 可及性專家），每個角色帶著不同的假設和關注點，覆蓋不同的盲點
2. **CSO 雙模式**：安全官（CSO）有兩種模式——daily 模式（信心門控，信心低於 8/10 則阻擋）和 monthly 模式（深度掃描），頻率決定深度
3. **設計評審打分制**：已在 Story 10 AC 納入

**ai-dev-workflow 的適配方案**（已有基礎設施，只需形式化）：

ai-dev-workflow 已有 9 個 Agent，其中包含多個專家視角（architect、dba、frontend-designer、code-reviewer），但目前這些角色只在被明確呼叫時才介入，沒有形式化的「順序多角色審查」模式。

**落地方式**：

- **`agentic-eval` Skill Pre-Decision Mode（Story 10）**：在 DOUBT 步驟加入「Sequential Lens 清單」——AI 依序以 Security / Performance / Architecture / Maintainability / Accessibility 五個視角審查同一個決策，每個視角必須至少產出 1 個問題或確認
- **`code-security-review` Skill（FR-1 格式標準化）**：Anti-Rationalization Table 新增一條：「不能只從程式碼作者視角審查——必須依序切換至少 3 個 Specialist Lens（如 Security、Performance、Future Maintainer）再完成審查」
- **`security-review` Skill（FR-6 或現有 Skill 更新）**：引入 CSO 雙模式概念——在 SKILL.md 加入「輕量模式（Quick Gate）」和「深度模式（Deep Scan）」兩種呼叫路徑，使用者依風險選擇深度

---

## Success Metrics

1. **Skill 格式一致性**：9 個核心工作流程 Skill 100% 包含 Anti-Rationalization Table 和 Verification Checklist
2. **Agent Handoff 完整性**：9 個 Agent 的 Handoff 鏈路可完整追蹤（brainstorm → spec → plan → coder → code-reviewer 無斷層）
3. **新 Skill 完整性**：3 個新建 Skill 各自包含 Process、Anti-Rationalization、Verification 三個必要區塊；5 個擴充現有 Skill 的新增區塊各包含觸發條件、步驟說明、Verification
4. **Skill 行為驗收**：3 個新建 Skill + 6 個擴充區塊各至少通過 1 個 adversarial pressure session，驗收記錄存於 `skill-pressure-tests.md`
5. **bootstrap 乾淨性**：使用 bootstrap 部署的新專案中，`gate-check` 不出現在 `.github/skills/` 目錄
6. **sync 一致性**：`agents/` + `skills/` + `AGENTS.md` 與 `.github/` 下的對應檔案 diff 為零
7. **Token 預算合規**：每個修改/新增 Skill 的 token 增量 ≤ 400 tokens（以實測為準）
8. **spec-agent AC 品質**（Story 13）：specification SKILL.md 更新後，任意抽取 3 個 AC 範例驗證：（a）格式為 Observable Outcome（b）Specialist Lens Review 有 4 個視角輸出（c）詞彙鎖定步驟可正常觸發

---

## Open Questions

1. **workflow-orchestrator 最終去留**：精簡後若功能高度重疊 pm-agent，未來是否應完全刪除並讓 pm-agent 承擔？本次保留但精簡，留待觀察使用頻率後決定。
2. **Session Recovery 機制**：使用者提到的「hooks + .ai-workflow-memory 自動讀取」需求已確認為重要方向，但本次不實作。建議在本次完成後開一個獨立的 change package 專門設計此機制。
3. **idea-refine Skill 引入**：agent-skills 的 `idea-refine` 與現有 `brainstorming` Skill 有部分重疊，是否需要引入？本次不引入，由使用者日後評估。
4. **動態 Handoff Skill**：mattpocock/skills 的 `handoff` skill 可動態壓縮對話為可執行的交付文件，使跨 session / 跨 agent 的上下文切換更可靠。此機制與 GitHub Copilot CLI 的 session checkpoint 機制是否衝突？是否需要在 Phase 2 引入為獨立 Skill？本次不引入，列為後續評估項目。
5. ~~**`handoffs` frontmatter 優先序**：官方 `handoffs` 欄位（YAML frontmatter）可在 Agent 回應後顯示跨 Agent 轉移按鈕，直接形式化 Consult Review 機制（spec-agent 完成後自動出現「DB 審查」「前端審查」按鈕）。本次 FR-2 規劃的 Handoff 是否應同步在 Agent frontmatter 中宣告 `handoffs`？還是僅在 Markdown body（`## Handoff`）中說明文字即可？建議：兩者並存，frontmatter 給工具使用，body 給人類閱讀。~~ **→ 已決定：兩者並存。**

---

## Assumptions 確認清單

在交付至 plan-agent 前，請確認以下假設：

- [ ] `[ASSUMED]` 新 Skill 採用 `skills/<name>/SKILL.md` 結構 → 確認 / 修正
- [ ] `[ASSUMED]` Verification Checklist 使用 Markdown checkbox 格式 → 確認 / 修正
- [ ] `[ASSUMED]` Anti-Rationalization 使用二欄表格格式 → 確認 / 修正
- [ ] `[ASSUMED]` Composition Block 加在 `## Skill Integration` 之後 → 確認 / 修正

---

## References

- 原始比較分析：本次對話 checkpoint `001-spec.md`
- agent-skills 參考：`forgivesam168/agent-skills`（GitHub fork）
- 現有 Skill 目錄：`D:\Project\ai-dev-workflow\skills\`
- 現有 Agent 目錄：`D:\Project\ai-dev-workflow\agents\`
- AGENTS.md（完整系統目錄）：`D:\Project\ai-dev-workflow\AGENTS.md`
- bootstrap 部署腳本：`D:\Project\ai-dev-workflow\tools\install-apply.ps1`
- sync 腳本：`D:\Project\ai-dev-workflow\tools\sync-dotgithub.ps1`
- Specification Skill 指引：`.github/skills/specification/SKILL.md`
- Changes instructions：`.github/instructions/changes.instructions.md`
- **官方 Skill 規範**（VS Code Docs 2026/05）：`https://code.visualstudio.com/docs/copilot/customization/agent-skills`
- **官方 Agent 規範**（VS Code Docs 2026/05）：`https://code.visualstudio.com/docs/copilot/customization/custom-agents`
- **AgentSkills.io 開放標準**：`https://agentskills.io/specification`（Skill name/description 欄位限制、Progressive Loading L1/L2/L3、references/ 使用指引）
- **github/awesome-copilot**：`https://github.com/github/awesome-copilot`（community example：`acquire-codebase-knowledge` 展示 negative trigger + conditional L3 loading 模式）
