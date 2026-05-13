# Implementation Plan: ai-dev-workflow Skill Enhancement — Phase 1

## Overview

本計畫依據 `03-spec.md` 將 ai-dev-workflow 的 Skill 格式標準化、Agent 協作架構強化、新增/擴充共 9 個 Skill，並建立行為驗收協議。

**Spec Reference**: `changes/2026-05-12-skill-enhancement/03-spec.md`  
**Change Package**: `changes/2026-05-12-skill-enhancement/`

---

## Implementation Strategy

### Approach

**Content-First, Format-Before-Content**：先建立格式標準（Phase 1），再讓後續所有新建/擴充 Skill 直接套用。Agent 架構（Phase 2/3）與格式標準化可部分並行。

```
Phase 1: Skill 格式標準化（FR-1）
Phase 2: Agent Handoff Architecture（FR-2a → FR-2b）
Phase 3: Tool Reorientation（FR-3/FR-4/FR-5，部分與 Phase 2 並行）
Phase 4: P1 Skill 擴充（FR-6 P1）
Phase 5: P2 Skill 擴充 + specification 強化（FR-6 P2 + Story 13）
Phase 6: 目錄同步 + 行為驗收（FR-7 + FR-8）
```

### Parallelism

- Phase 2（FR-2a + FR-2b）與 Phase 3（FR-4）可同時進行，無依賴
- FR-5（workflow-orchestrator 精簡）必須等 FR-2a 完成後執行
- Phase 4 必須等 Phase 1 完成（格式標準確立）

### First TDD Slice

> 🎯 **Start here**: Task 1.1 — brainstorming SKILL.md 格式標準化（Pilot）  
> 最小可測增量：以 brainstorming 為試點，驗證 Anti-Rationalization + Verification 新格式可正確套用，再批次推廣至其餘 8 個 Skill。

---

### Phases Overview

6 個 Phase，共 25 個 Task，30+ 個文件異動

| Phase | 任務數 | 依賴 | 預估時間 |
|-------|--------|------|---------|
| 1. Skill 格式標準化 | 5 tasks | 無 | 4–6 h |
| 2. Agent Handoff Architecture | 5 tasks | Phase 1 完成後可加速，FR-2a 先行 | 4–6 h |
| 3. Tool Reorientation | 3 tasks | Task 2.1（FR-5 依賴）| 2–3 h |
| 4. P1 Skill 擴充 | 5 tasks | Phase 1 完成 | 5–7 h |
| 5. P2 Skill 擴充 + specification | 4 tasks | Phase 4 完成 | 4–6 h |
| 6. 目錄同步 + 行為驗收 | 3 tasks | Phase 1–5 完成 | 2–4 h |
| **Total** | **25 tasks** | — | **21–32 h** |

---

## Phase 1: Skill 格式標準化（FR-1）

**Status**: ⏳ Pending  
**Depends on**: 無  
**目標**: 為 9 個核心工作流程 Skill 加入 `## Common Rationalizations` 和 `## Verification` 區塊，建立統一格式基準。

---

### Task 1.1: brainstorming SKILL.md — Pilot（First TDD Slice）

**Status**: ⏳ Pending  
**Depends on**: 無  
**Test Tier**: L1（靜態 grep 驗證）

**Test Strategy (RED)**:
- `rg "## Common Rationalizations" skills/brainstorming/SKILL.md` → 目前應 FAIL（區塊不存在）
- `rg "## Verification" skills/brainstorming/SKILL.md` → 目前應 FAIL
- `rg "⛔" skills/brainstorming/SKILL.md` → 目前應 FAIL（HARD-GATE 標記不存在）
- 修改前確認以上三條均 FAIL，才算合法的 RED

**Implementation (GREEN)**:
- 檔案: `skills/brainstorming/SKILL.md`
- 在現有內容末端（Next Step 之前）加入 `## Common Rationalizations` 表格，至少 3 條，含 HARD-GATE 條目：
  ```
  | "我只是先試試，不是真的要實作" | ⛔ 在設計批准前，任何實作程式碼均為違規——無論使用者要求多迫切 |
  ```
- 加入 `## Verification` 區塊，至少 5 個 checkbox，第一條為機械可驗證步驟：
  ```
  - [ ] `Test-Path changes/<slug>/01-brainstorm.md` 回傳 True
  ```
- 若現有 `## Validation & Handoff Gate` 存在，保留並明確分工（Gate = 交付前閘門；Verification = 自我完成確認）

**Refactor (REFACTOR)**:
- 確認兩個區塊之間的語意無重疊
- 確認 HARD-GATE 條目的措辭足夠強硬（不能被「理解」為可選）

**Acceptance Criteria**:
- [ ] `rg "## Common Rationalizations" skills/brainstorming/SKILL.md` 回傳匹配
- [ ] `rg "## Verification" skills/brainstorming/SKILL.md` 回傳匹配
- [ ] Verification 第一條為 `Test-Path` 或 `rg` 等可執行命令
- [ ] `rg "⛔" skills/brainstorming/SKILL.md` 有匹配（HARD-GATE 標記存在）
- [ ] `rg "Test-Path\|rg " skills/brainstorming/SKILL.md` 確認 Verification 第一條含可執行命令

**Estimated Time**: 1 h

---

### Task 1.2: specification + code-security-review — 格式標準化

**Status**: ⏳ Pending  
**Depends on**: Task 1.1（確認格式範本可行）  
**Test Tier**: L1

**Implementation (GREEN)**:
- 檔案 A: `skills/specification/SKILL.md`
  - 加入 `## Common Rationalizations`（含 Story 13 spec-specific 四條目）
  - 加入 `## Verification`（第一條: `Test-Path changes/<slug>/03-spec.md`）
  - ⚠️ 注意：specification SKILL.md 後續 Phase 5 還會擴充，本次只加格式區塊
  - ⚠️ 檔案目前 ~392 行，加入後需確認 ≤ 500 行上限
- 檔案 B: `skills/code-security-review/SKILL.md`
  - 加入 `## Common Rationalizations`，**必須含多角色條目**：
    ```
    | "我已從作者角度完整審查" | 不能只從程式碼作者視角審查——必須依序切換至少 3 個 Specialist Lens（Security、Performance、Future Maintainer）再完成審查 |
    ```
  - 加入 `## Verification`（第一條: `rg "## Specialist Lens" output` 或「切換了 3 個 Lens 並記錄輸出」）

**Acceptance Criteria**:
- [ ] 兩個檔案各有 `## Common Rationalizations`（≥3 條）和 `## Verification`（≥5 checkbox）
- [ ] `code-security-review` 的 Rationalization 含多角色 Lens 條目
- [ ] `specification/SKILL.md` 行數 ≤ 500
- [ ] specification 的 Rationalization 含四條 spec-specific 條目（來自 Story 13）

**Estimated Time**: 1–1.5 h

---

### Task 1.3: implementation-planning + tdd-workflow — 格式標準化

**Status**: ⏳ Pending  
**Depends on**: Task 1.1  
**Test Tier**: L1

**Implementation (GREEN)**:
- 檔案 A: `skills/implementation-planning/SKILL.md`
  - 加入 `## Common Rationalizations`（含「水平切片是合理起點」的反制條目）
  - 加入 `## Verification`（第一條: `Test-Path changes/<slug>/04-plan.md`）
- 檔案 B: `skills/tdd-workflow/SKILL.md`
  - 加入 `## Common Rationalizations`（含「先把所有測試寫完再實作效率更高」的反制條目）
  - 加入 `## Verification`（第一條: `dotnet test` / `npm test` / `pytest` 命令，視專案技術棧）

**Acceptance Criteria**:
- [ ] 兩個檔案各有格式區塊（各 ≥3 條 + ≥5 checkbox）
- [ ] tdd-workflow 的 Verification 第一條為可執行測試命令
- [ ] implementation-planning 的 Rationalization 含水平切片反制

**Estimated Time**: 1 h

---

### Task 1.4: work-archiving + explore — 格式標準化

**Status**: ⏳ Pending  
**Depends on**: Task 1.1  
**Test Tier**: L1

**Implementation (GREEN)**:
- 檔案 A: `skills/work-archiving/SKILL.md`
  - 加入 `## Common Rationalizations`（含「口頭記錄就夠了，不需要 ADR」的反制條目）
  - 加入 `## Verification`（第一條: `Test-Path changes/<slug>/06-archive.md` 或對應產出物）
- 檔案 B: `skills/explore/SKILL.md`
  - 加入 `## Common Rationalizations`（含「看一看就夠了，不需要正式 explore」的反制條目）
  - 加入 `## Verification`（第一條: `rg "## Findings" output-file.md` 等靜態確認）

**Acceptance Criteria**:
- [ ] 兩個檔案各有格式區塊（各 ≥3 條 + ≥5 checkbox）
- [ ] work-archiving 含 ADR 相關反制條目

**Estimated Time**: 45 min

---

### Task 1.5: execution-guardrails + refactor — 格式標準化

**Status**: ⏳ Pending  
**Depends on**: Task 1.1  
**Test Tier**: L1

**Implementation (GREEN)**:
- 檔案 A: `skills/execution-guardrails/SKILL.md`
  - 加入 `## Common Rationalizations`（含「這個任務比較特殊，可以跳過護欄」的反制）
  - 加入 `## Verification`（第一條: 列出可機械確認的護欄遵守項目）
- 檔案 B: `skills/refactor/SKILL.md`
  - 加入 `## Common Rationalizations`（含「順手加個 feature 不會怎樣」的反制）
  - 加入 `## Verification`（第一條: `git diff HEAD --stat`，確認沒有行為變更的 file 被意外修改）

**Acceptance Criteria**:
- [ ] 兩個檔案各有格式區塊（各 ≥3 條 + ≥5 checkbox）
- [ ] refactor 的 Verification 第一條使用 `git diff` 或可執行的無行為變更驗證

**Estimated Time**: 45 min

---

### Phase 1 Exit Criteria

- [ ] `rg "## Common Rationalizations" skills/brainstorming/SKILL.md skills/specification/SKILL.md skills/implementation-planning/SKILL.md skills/tdd-workflow/SKILL.md skills/code-security-review/SKILL.md skills/work-archiving/SKILL.md skills/explore/SKILL.md skills/execution-guardrails/SKILL.md skills/refactor/SKILL.md` → 全部 9 個匹配
- [ ] `rg "## Verification" skills/brainstorming/SKILL.md ...`（同上 9 個）→ 全部匹配
- [ ] 每個 Verification 第一條均為可執行或可機械檢查步驟（人工審閱）
- [ ] specification/SKILL.md ≤ 500 行：`(Get-Content skills/specification/SKILL.md).Count`

---

## Phase 2: Agent Handoff Architecture（FR-2a + FR-2b）

**Status**: ⏳ Pending  
**Depends on**: Phase 1（格式範本確立可加速撰寫，但 FR-2a 和 FR-4 可在 Phase 1 並行開始）

---

### Task 2.1: Handoff Matrix 定義（FR-2a）

**Status**: ⏳ Pending  
**Depends on**: 無  
**Test Tier**: L1

**Implementation (GREEN)**:
- 產出物: `changes/2026-05-12-skill-enhancement/agent-handoff-matrix.md`（Phase artifact，供後續 Task 2.2-2.5 參考）
- 填寫 9 個 Agent × Entry Signals / Completion Conditions / Next Step 表格
- 確認鏈路無斷層：brainstorm → spec → plan → coder → code-reviewer（標準路徑）
- 標記多階段 Agent（architect, pm）和 Consult 介入點（dba, frontend-designer）
- 定義 `handoffs` frontmatter `agent:` 值命名規則：`.agent.md` 檔名去掉副檔名（如 `dba`、`frontend-designer`）

**Acceptance Criteria**:
- [ ] `Test-Path changes/2026-05-12-skill-enhancement/agent-handoff-matrix.md` 為 True
- [ ] 矩陣含 9 個 Agent 列，各含 Entry / Completion / Next Step 三欄
- [ ] brainstorm → spec → plan → coder → code-reviewer 鏈路文字一致（無斷層）
- [ ] dba / frontend-designer 標記為「spec/plan 階段介入」
- [ ] architect / pm 標記為「多階段可用」

**Estimated Time**: 30–45 min

---

### Task 2.2: 核心鏈路 Agent 修改（brainstorm, spec, plan）

**Status**: ⏳ Pending  
**Depends on**: Task 2.1  
**Test Tier**: L1

**Implementation (GREEN)**:
- 格式（每個 .agent.md 均需，依此順序）：
  1. frontmatter `handoffs:` 陣列（VS Code 整合）
  2. 開場自我定位句（「你現在和 X Agent 對話，我的職責是...」）
  3. `## Composition Rules` 區塊（3 條規則）
  4. `## Handoff` 區塊（Entry Signals / Completion Conditions / Next Step）

- 檔案 A: `agents/brainstorm.agent.md`
  - handoffs: → spec-agent
  - Completion Condition: `changes/<slug>/01-brainstorm.md` + Risk 分類確立
- 檔案 B: `agents/spec.agent.md`
  - ⚠️ 已有部分修改（handoffs frontmatter 存在），需確認完整性再補齊缺漏
  - handoffs: → plan + dba + frontend-designer（Consult Review）
  - Completion Condition: `03-spec.md` 通過 Specialist Lens Review
- 檔案 C: `agents/plan.agent.md`
  - handoffs: → coder-agent
  - Completion Condition: `04-plan.md` + `05-test-plan.md` 存在

**Acceptance Criteria**:
- [ ] 三個檔案各有 `## Composition Rules` + `## Handoff` 區塊
- [ ] `rg "handoffs:" agents/brainstorm.agent.md agents/spec.agent.md agents/plan.agent.md` → 3 個匹配
- [ ] 三個檔案均有自我定位句
- [ ] 各 Agent ≤ 25 non-empty lines（設計目標；以 `(Get-Content <file> | Where-Object { $_ -ne '' }).Count` 驗證）
- [ ] 9 個 Agent frontmatter description / trigger intent 已審查無重疊職責（Phase 2 Exit Criteria 統一驗收）

**Estimated Time**: 1–1.5 h

---

### Task 2.3: 執行鏈路 Agent 修改（coder, code-reviewer）

**Status**: ⏳ Pending  
**Depends on**: Task 2.1  
**Test Tier**: L1

**Implementation (GREEN)**:
- 檔案 A: `agents/coder.agent.md`
  - handoffs: → code-reviewer
  - Completion Condition: 所有 L1 測試通過、Financial Precision 確認
  - Composition Rules: 說明「Red-Green 循環 = 一個垂直切片」
- 檔案 B: `agents/code-reviewer.agent.md`
  - handoffs: → work-archiving（標準路徑）
  - Completion Condition: `05-review.md` 存在且無未解 Critical issue

**Acceptance Criteria**:
- [ ] 兩個檔案各有完整格式區塊
- [ ] coder-agent 的 Composition Rules 含垂直切片說明
- [ ] code-reviewer 的 Next Step 指向 work-archiving

**Estimated Time**: 45 min

---

### Task 2.4: 協調/多階段 Agent 修改（pm, architect）

**Status**: ⏳ Pending  
**Depends on**: Task 2.1  
**Test Tier**: L1

**Implementation (GREEN)**:
- 檔案 A: `agents/pm.agent.md`
  - Composition Rules 例外：pm-agent 可建議切換（cross-project 協調職責），但措辭為「建議」非「命令」
  - handoffs: → 依當前階段動態（multi-stage）
  - Entry Signals 說明：任何階段均可介入（project status、what's next）
- 檔案 B: `agents/architect.agent.md`
  - handoffs: → 多階段可用，Consult Review 完成後建議回到觸發方
  - 說明「多階段可用」而非「只在某階段」

**Acceptance Criteria**:
- [ ] pm-agent Composition Rules 含「建議而非命令」例外說明
- [ ] architect-agent 和 pm-agent 的 Entry Signals 含「多階段可用」說明
- [ ] pm-agent 的 Composition Rules 為唯一含例外的 Agent（其餘 8 個不得有例外）

**Estimated Time**: 45 min

---

### Task 2.5: Consult 介入 Agent 修改（dba, frontend-designer）

**Status**: ⏳ Pending  
**Depends on**: Task 2.1  
**Test Tier**: L1

**Implementation (GREEN)**:
- 檔案 A: `agents/dba.agent.md`
  - Entry Signals 強調：「spec 或 plan 文件包含資料庫設計決策時即可介入」（不只是 coding 階段）
  - handoffs: → 回到觸發方（spec-agent 或 plan-agent）
- 檔案 B: `agents/frontend-designer.agent.md`
  - Entry Signals 強調：「spec 或 plan 包含前端/UI 設計時即可介入」
  - handoffs: → 回到觸發方

**Acceptance Criteria**:
- [ ] 兩個檔案 Entry Signals 明確說明「spec/plan 階段就應介入，不只是 coder 階段」
- [ ] 兩個 Agent 的 Completion Conditions 描述 Consult Review 完成的定義
- [ ] Next Step 為「回到觸發方 Agent」

**Estimated Time**: 30 min

---

### Phase 2 Exit Criteria

- [ ] `rg "## Composition Rules" agents/*.agent.md` → 9 個匹配
- [ ] `rg "## Handoff" agents/*.agent.md` → 9 個匹配
- [ ] `rg "handoffs:" agents/*.agent.md` → ≥ 9 個匹配（frontmatter）
- [ ] `Test-Path changes/2026-05-12-skill-enhancement/agent-handoff-matrix.md` 為 True
- [ ] 9 個 Agent 的 body 均有自我定位句
- [ ] Trigger Keyword 不重疊驗收：各 Agent frontmatter description 的核心職責詞無重複（人工審閱 9 個，記錄在 agent-handoff-matrix.md 附錄）
- [ ] pm-agent 是唯一含「例外」的 Composition Rules（`rg "例外\|exception" agents/pm.agent.md` 匹配；其餘 8 個 `rg "例外\|exception" agents/*.agent.md` 僅 pm 匹配）

---

## Phase 3: Tool Reorientation（FR-3, FR-4, FR-5）

**Status**: ⏳ Pending  
**Depends on**: Task 2.1（FR-5 依賴 FR-2a）；FR-3/FR-4 可與 Phase 2 並行  
**目標**: 重新定位 agentic-eval、gate-check、workflow-orchestrator 三個工具。

---

### Task 3.1: agentic-eval 重聚焦（FR-3）

**Status**: ⏳ Pending  
**Depends on**: Phase 1 完成（確認各 Skill 已有 Verification，agentic-eval 才能定位為補充工具）  
**Test Tier**: L1

**Implementation (GREEN)**:
- 檔案: `skills/agentic-eval/SKILL.md`
- 新增 `## Rubber Duck Spirit` 區塊（在 When to Use 之前）：核心精神「用相反論點挑戰自己的輸出，直到找不到反駁為止」
- 改寫 `## When to Use`：移除「在 Y 階段必須呼叫」文字，改為通用情境（任何決策、任何輸出）
- Tier 2（外部批評）和 Tier 3（追蹤評估）標題加上 `(Optional)` 標記
- 更新 SKILL.md description frontmatter：移除「spec-agent / plan-agent / coder-agent 必須在...」字眼，改為「Use when you want adversarial challenge on any output or decision...」
- 更新觸發關鍵詞：移除「spec complete」等階段觸發，加入「devil's advocate」「挑戰這個決策」「扮演反對者」

**Acceptance Criteria（Task 3.1）**:
- [ ] `rg "## Rubber Duck Spirit" skills/agentic-eval/SKILL.md` 匹配
- [ ] `rg "Optional" skills/agentic-eval/SKILL.md` 有 ≥ 2 個匹配（Tier 2 / Tier 3）
- [ ] SKILL.md description 不含「必須呼叫」或強制性階段指令
- [ ] `AGENTS.md` 中 agentic-eval 閘門表格已改為 advisory wording（`rg "必須呼叫.*agentic-eval\|must.*agentic-eval" AGENTS.md` 無匹配，或標記為 Optional）
- [ ] `rg "必須.*agentic-eval\|must.*agentic-eval" agents/*.agent.md` 無強制性呼叫語句
- [ ] Token 增量 ≤ 400 tokens（聚焦重寫，非新增）

**Estimated Time**: 1 h

---

### Task 3.2: gate-check 重標記 + bootstrap 三入口排除（FR-4）

**Status**: ⏳ Pending  
**Depends on**: 無（可最早開始）  
**Test Tier**: L1

**Implementation (GREEN)**:
- 檔案 A: `skills/gate-check/SKILL.md`
  - 更新 frontmatter `description`：加入「For ai-dev-workflow template maintainers only. Do not trigger during normal development workflow.」
  - 加入 `## ⚠️ Scope` 區塊：說明此工具只適合 Template Repo 本身的維護者使用；一般專案開發者不需要此 Skill
- 檔案 B: `AGENTS.md`
  - 從「Core Workflow Skills」（或目前所在分類）移除 gate-check
  - 新增 `### Template Maintenance Tools` 分類，加入 gate-check
- 檔案 C: `scripts/bootstrap.ps1`
  - 找到 Skill 複製/安裝邏輯，加入 `gate-check` 排除
- 檔案 D: `tools/install-plan.ps1`
  - 同上，加入排除
- 檔案 E: `tools/install-apply.ps1`
  - 同上，加入 `$excludedSkills = @('gate-check')`
- 檔案 F: `INSTALL.md` 或 `QUICKSTART.md`（選擇較長/使用者面向的那個）
  - 加入遷移說明：若 `.github/skills/` 已包含 `gate-check`（舊版 bootstrap），可安全刪除

**Acceptance Criteria**:
- [ ] `rg "## ⚠️ Scope" skills/gate-check/SKILL.md` 匹配
- [ ] `rg "Template Maintenance" AGENTS.md` 匹配
- [ ] `rg "gate-check" scripts/bootstrap.ps1` 確認排除語法正確（`$excludedSkills = @('gate-check')` 或等效）
- [ ] `rg "gate-check" tools/install-plan.ps1` 確認排除語法正確
- [ ] `rg "gate-check" tools/install-apply.ps1` 確認 `$excludedSkills` 定義存在
- [ ] INSTALL.md 或 QUICKSTART.md 含遷移說明段落（`rg "gate-check" INSTALL.md` 或 `rg "gate-check" QUICKSTART.md` 匹配）

**Estimated Time**: 1 h

---

### Task 3.3: workflow-orchestrator 精簡（FR-5）

**Status**: ⏳ Pending  
**Depends on**: Task 2.1（Handoff Matrix 確立後，安全移除 orchestrator 的引導職責）  
**Test Tier**: L1

**Implementation (GREEN)**:
- 檔案: `skills/workflow-orchestrator/SKILL.md`
- **保留**：`changes/` 目錄文件存在偵測邏輯（01/02/03/04/05/06 文件 + 07 archive）
- **保留**：`changes/` 不存在時的初始狀態處理（建議 brainstorm-agent）
- **移除**：每個 Agent 的詳細功能說明段落（這些已移至各 Agent 的 Handoff 區塊）
- **精簡**輸出格式為：「當前階段：X → 下一步：Y」（最多 3 行輸出）
- 更新 AGENTS.md 的 workflow-orchestrator 描述，反映新定位

**Acceptance Criteria**:
- [ ] 修改後 SKILL.md 的「每個 Agent 說明」段落不存在（`rg "plan-agent 的功能是" skills/workflow-orchestrator/SKILL.md` 應無匹配）
- [ ] `rg "changes/" skills/workflow-orchestrator/SKILL.md` 仍有匹配（偵測邏輯保留）
- [ ] 修改後行數比修改前減少（以 `(Get-Content ...).Count` 驗證）

**Estimated Time**: 45 min

---

### Phase 3 Exit Criteria

- [ ] `rg "Rubber Duck Spirit" skills/agentic-eval/SKILL.md` 匹配
- [ ] 三個 bootstrap 腳本均有 gate-check 排除邏輯
- [ ] gate-check 在 AGENTS.md 分類為 Template Maintenance Tools
- [ ] workflow-orchestrator SKILL.md 行數明顯減少（≥ 20% 刪減）
- [ ] 執行 `pwsh -File .\tools\sync-dotgithub.ps1`，確認 parity

---

## Phase 4: P1 Skill 擴充（FR-6 P1）

**Status**: ⏳ Pending  
**Depends on**: Phase 1 完成（格式標準確立）

---

### Task 4.1: implementation-planning — Vertical Slice Strategy（Story 8）

**Status**: ⏳ Pending  
**Depends on**: Phase 1 完成  
**Test Tier**: L1

**Implementation (GREEN)**:
- 檔案: `skills/implementation-planning/SKILL.md`
- 加入 `## Vertical Slice Strategy` 區塊：
  - 定義垂直切片（從接口到資料層的完整功能薄片）
  - 切片大小標準（每個切片 ≤ 1 commit 的工作量）
  - 純後端 / DB migration 情境說明（UI 層可選，但 Task 仍需覆蓋完整可驗證功能單元）
- 加入 `## Anti-Pattern: Horizontal Slicing` 警告區塊：
  - 明確說明「Task 1: 所有測試 / Task 2: 所有實作」是水平切片反模式
  - plan-agent 的 enforcement rule：若某 Task 只含測試或只含實作，必須標記為 Spec Gap
- Token 增量：此為「新模式加入」型，允許 ≤ 900 tokens

**Acceptance Criteria**:
- [ ] Task 4.1 完成：`rg "## Vertical Slice Strategy" skills/implementation-planning/SKILL.md` 匹配
- [ ] `agents/plan.agent.md` Skill Integration 更新，明確說明 plan-agent 在建立任務計畫時須執行 Vertical Slice 原則（`rg "Vertical Slice\|垂直切片" agents/plan.agent.md` 匹配）
- [ ] `rg "## Anti-Pattern" skills/implementation-planning/SKILL.md` 匹配
- [ ] 反模式警告含 plan-agent enforcement rule

**Estimated Time**: 1 h

---

### Task 4.2: tdd-workflow — 切片執行 + 三次停止法則（Story 8）

**Status**: ⏳ Pending  
**Depends on**: Phase 1 完成  
**Test Tier**: L1

**Implementation (GREEN)**:
- 檔案: `skills/tdd-workflow/SKILL.md`
- 加入切片執行提醒（在 Red-Green-Refactor 步驟說明中）：每個 Red-Green 循環 = 一個垂直切片，不得批量寫多個測試再一次實作
- 加入 `## Three-Strike Rule`（三次修復停止法則）：
  - 同一錯誤連續 3 次修復失敗 → 停止修復行為
  - 向使用者報告根本原因假設清單（至少 3 個備選）
  - 不得繼續第 4 次嘗試直到使用者確認假設
- 加入 `## Feedback Loop Prerequisite`（可調試反饋循環前置條件）：
  - 若沒有快速反饋循環（測試觀察模式 / hot-reload / REPL）→ 先建立反饋循環
  - 無法建立 → 暫停並向使用者說明原因
- Token 增量：≤ 900 tokens（新模式型）

**Acceptance Criteria**:
- [ ] `rg "Three-Strike" skills/tdd-workflow/SKILL.md` 匹配
- [ ] `rg "Feedback Loop" skills/tdd-workflow/SKILL.md` 匹配
- [ ] Three-Strike Rule 含「3 次」的明確數字觸發條件
- [ ] `agents/coder.agent.md` Skill Integration 更新，明確說明「每個 Red-Green 循環 = 一個垂直切片」（`rg "Red-Green\|垂直切片" agents/coder.agent.md` 匹配）

**Estimated Time**: 1 h

---

### Task 4.3: agentic-eval — Pre-Decision Mode（Story 10）

**Status**: ⏳ Pending  
**Depends on**: Task 3.1 完成（agentic-eval 已重聚焦）  
**Test Tier**: L1

**Implementation (GREEN)**:
- 檔案: `skills/agentic-eval/SKILL.md`
- 加入 `## Pre-Decision Mode（決策前懷疑模式）` 區塊（與現有 Post-Output Rubber Duck 並列）：
  - CLAIM → EXTRACT → DOUBT → RECONCILE → STOP 五步驟
  - DOUBT 步驟：Sequential Specialist Lens（Security / Performance / Architecture / Maintainability / Accessibility，依序審查，每視角 ≥ 1 個質疑或確認）
  - RECONCILE 步驟：0-10 分自評 → 描述 10 分長什麼樣 → 編輯直到達到目標分數
  - 觸發條件：High Risk 決策、架構選擇、不可逆操作 → 必須執行 Pre-Decision Mode
- 更新 `## When to Use`：加入「Pre-Decision（高風險決策前）」和「Post-Output（輸出完成後）」兩個明確觸發場景
- Token 增量：≤ 900 tokens；若超出，五步驟細節移至 `references/pre-decision-mode.md`

**Acceptance Criteria**:
- [ ] `rg "Pre-Decision Mode" skills/agentic-eval/SKILL.md` 匹配
- [ ] `rg "CLAIM.*EXTRACT.*DOUBT" skills/agentic-eval/SKILL.md` 或各步驟各有 `rg` 匹配
- [ ] Sequential Specialist Lens 清單含 5 個視角
- [ ] 若超 900 tokens → `references/pre-decision-mode.md` 存在且 body 有引用語句
- [ ] `agents/architect.agent.md` Skill Integration 更新，說明高風險架構決策優先使用 Pre-Decision Mode（`rg "Pre-Decision\|pre-decision" agents/architect.agent.md` 匹配）

**Estimated Time**: 1.5 h

---

### Task 4.4: refactor — Simplification Mode + Performance Mode（Story 11）

**Status**: ⏳ Pending  
**Depends on**: Phase 1 完成  
**Test Tier**: L1

**Implementation (GREEN)**:
- 檔案: `skills/refactor/SKILL.md`
- 加入 `## Simplification Mode（輕量模式）` 區塊：
  - 與 Structural Refactor Mode 的差異（Structural = 函式拆解；Simplification = 命名/可讀性，不改結構）
  - **Chesterton's Fence 原則**：移除任何程式碼前必須先理解「為何有這段」
  - **Rule of 500**：單一函式 > 500 行需自動化工具協助，不得粗暴刪減
  - Verification：所有既有測試通過 + build 成功 + 沒有混入 feature/結構變更
  - 若無測試：「先加對應覆蓋，再簡化」前置步驟
- 加入 `## Performance Mode（效能優化模式）` 區塊：
  - **Measure First** 硬性前置條件：必須先有量測數據（profiler / benchmark baseline）
  - Anti-Pattern：premature optimization、無量測基線的優化
  - Verification：量測數據改善（量化）+ 所有既有測試通過
- 更新 `## When to Use`：三種模式選擇指引
- Token 增量：≤ 900 tokens；若超出，Chesterton's Fence 範例移至 references/

**Acceptance Criteria**:
- [ ] `rg "Simplification Mode" skills/refactor/SKILL.md` 匹配
- [ ] `rg "Performance Mode" skills/refactor/SKILL.md` 匹配
- [ ] `rg "Chesterton" skills/refactor/SKILL.md` 匹配
- [ ] `rg "Measure First" skills/refactor/SKILL.md` 匹配

**Estimated Time**: 1.5 h

---

### Task 4.5: 新建 context-engineering Skill（Story 9）

**Status**: ⏳ Pending  
**Depends on**: Phase 1 完成（套用標準格式）  
**Test Tier**: L1

**Implementation (GREEN)**:
- 新建目錄: `skills/context-engineering/`
- 新建檔案: `skills/context-engineering/SKILL.md`
  - frontmatter `name: context-engineering`（與目錄名稱完全一致）
  - description：「Use this skill when... Do not trigger when...」格式
  - `## When to Use`：AI 進行技術決策、architect-agent 優先
  - `## Process`：5 層 Context 架構（Project / Codebase / Task / Conversation / External docs）
  - 詞彙衝突偵測步驟：比較術語 vs CONTEXT.md，發現衝突立即釐清
  - CONTEXT.md 產出規則：`.ai-workflow-memory/` 存在 → 存入其中；否則 → `docs/CONTEXT.md`
  - `## Common Rationalizations`（Context 污染常見情境）
  - `## Verification`（第一條: `Test-Path .ai-workflow-memory/PROJECT_CONTEXT.md` 或 `Test-Path docs/CONTEXT.md`）

**Acceptance Criteria**:
- [ ] `Test-Path skills/context-engineering/SKILL.md` 為 True
- [ ] `rg "name: context-engineering" skills/context-engineering/SKILL.md` 匹配
- [ ] SKILL.md 含 5 層 Context 架構說明
- [ ] SKILL.md 含詞彙衝突偵測步驟
- [ ] SKILL.md 含 CONTEXT.md 產出路徑規則（含 fallback）
- [ ] SKILL.md 含 `## Common Rationalizations` 和 `## Verification`

**Estimated Time**: 1.5 h

---

### Phase 4 Exit Criteria

- [ ] `rg "## Vertical Slice Strategy" skills/implementation-planning/SKILL.md` 匹配
- [ ] `rg "Three-Strike" skills/tdd-workflow/SKILL.md` 匹配
- [ ] `rg "Pre-Decision Mode" skills/agentic-eval/SKILL.md` 匹配
- [ ] `rg "Simplification Mode" skills/refactor/SKILL.md` 匹配
- [ ] `Test-Path skills/context-engineering/SKILL.md` 為 True
- [ ] 執行 `pwsh -File .\tools\sync-dotgithub.ps1`，確認 parity

---

## Phase 5: P2 Skill 擴充 + specification 強化（FR-6 P2 + Story 13）

**Status**: ⏳ Pending  
**Depends on**: Phase 4 完成（Task 5.1 / 5.2 實際只依賴 Phase 1 格式標準，**可在 Phase 1 後與 Phase 4 並行**；Task 5.3 / 5.4 涉及 specification 強化，需等 Task 1.2 格式加入後執行）

---

### Task 5.1: work-archiving ADR Section + security-review CSO 雙模式（Story 12）

**Status**: ⏳ Pending  
**Depends on**: Phase 1 完成  
**Test Tier**: L1

**Implementation (GREEN)**:
- 檔案 A: `skills/work-archiving/SKILL.md`
  - 加入 `## ADR Section` 區塊：
    - **ADR 三條件寫作法**：僅在以下三條件全為真時才寫：(1) 難以反轉 (2) 未來的人會感到困惑 (3) 真正的折衷取捨存在
    - AI 必須逐條確認，不得跳過
    - 加入「條件均不滿足時」的指引：記錄在 PR description 即可，無需 ADR
- 檔案 B: `skills/security-review/SKILL.md`
  - 加入 `## CSO 雙模式` 區塊：
    - **Quick Gate 模式**（每次 PR）：自評信心分數 0-10，低於 8/10 → 強制列出具體擔憂項目，不得放行
    - **Deep Scan 模式**（週期性/高風險功能）：完整 OWASP 威脅模型掃描
    - 使用者呼叫時選擇模式，預設 Quick Gate
  - 更新 `## When to Use`：說明兩種模式的使用時機

**Acceptance Criteria**:
- [ ] `rg "ADR Section" skills/work-archiving/SKILL.md` 匹配
- [ ] `rg "三條件" skills/work-archiving/SKILL.md` 匹配
- [ ] `rg "Quick Gate" skills/security-review/SKILL.md` 匹配
- [ ] `rg "Deep Scan" skills/security-review/SKILL.md` 匹配

**Estimated Time**: 1 h

---

### Task 5.2: 新建 shipping-and-launch + ci-cd-and-automation Skill（Story 12）

**Status**: ⏳ Pending  
**Depends on**: Phase 1 完成（套用標準格式）  
**Test Tier**: L1

**Implementation (GREEN)**:
- 新建 `skills/shipping-and-launch/SKILL.md`：
  - 範圍：staged rollout、rollback plan、production checklist
  - 與 work-archiving 分工說明（work-archiving = 內部收尾；shipping-and-launch = 外部部署上線）
  - 含 `## Common Rationalizations`（含「功能已測試通過，直接上線」的反制）
  - 含 `## Verification`（第一條: 確認 rollback plan 存在的靜態命令）
- 新建 `skills/ci-cd-and-automation/SKILL.md`：
  - 範圍：Shift Left 原則、quality gate pipeline 設計
  - 含 `## Common Rationalizations`（含「CI 太慢，先跳過這次」的反制）
  - 含 `## Verification`（第一條: 確認 pipeline 配置檔存在）

**Acceptance Criteria**:
- [ ] `Test-Path skills/shipping-and-launch/SKILL.md` 為 True
- [ ] `Test-Path skills/ci-cd-and-automation/SKILL.md` 為 True
- [ ] 兩個 SKILL.md 各含 `## Common Rationalizations`（≥3 條）和 `## Verification`（≥5 checkbox）
- [ ] `rg "name: shipping-and-launch" skills/shipping-and-launch/SKILL.md` 匹配（name 與目錄名一致）
- [ ] `rg "name: ci-cd-and-automation" skills/ci-cd-and-automation/SKILL.md` 匹配

**Estimated Time**: 1.5 h

---

### Task 5.3: specification SKILL.md 強化（Story 13 — Part A）

**Status**: ⏳ Pending  
**Depends on**: Phase 1 完成（Common Rationalizations 格式已在 Task 1.2 加入）  
**Test Tier**: L1

**Implementation (GREEN)**:
- 檔案: `skills/specification/SKILL.md`（在 Task 1.2 加入的格式基礎上繼續擴充）
- 詞彙鎖定前置步驟（在 Step 2 撰寫 User Stories 之前）：
  - 列出本次 spec 所有領域術語（≥3 個）
  - 對每個術語確認現有程式碼/文件一致性
  - 新創術語標記 `[NEW TERM]` + Assumptions 定義
  - 完成條件更新：「無未標記的 [NEW TERM]」
- Step 3 Validation 加入 `### Specialist Lens Review`（在 agentic-eval 閘門前）：
  - Security / Performance / QA / UX 四個視角，各產出 ≥1 個確認或新增 AC
  - 輸出格式：「🔒 Security: [確認已覆蓋 / 新增 AC：...]」
- AC 格式範本更新：Observable Outcome 強制（入口說明 + references/ 引用）
- ⚠️ 確認行數 ≤ 500 行：大量細節（範例庫、審查清單）移至 references/

**Acceptance Criteria**:
- [ ] `rg "詞彙鎖定" skills/specification/SKILL.md` 或 `rg "Vocabulary Lock" ...` 匹配
- [ ] `rg "Specialist Lens Review" skills/specification/SKILL.md` 匹配
- [ ] `rg "Observable Outcome" skills/specification/SKILL.md` 匹配
- [ ] `(Get-Content skills/specification/SKILL.md).Count` ≤ 500

**Estimated Time**: 1.5 h

---

### Task 5.4: specification references/ 目錄建立（Story 13 — Part B）

**Status**: ⏳ Pending  
**Depends on**: Task 5.3（確認哪些內容需要移至 references/）  
**Test Tier**: L1

**Implementation (GREEN)**:
- 新建目錄: `skills/specification/references/`
- 新建 `references/ac-format-guide.md`：Observable Outcome 正反範例庫（至少 6 個範例對，含 API、效能、UI 三個領域）
- 新建 `references/specialist-lens-review.md`：4 視角審查完整清單與輸出範本
- 新建 `references/consult-review-protocol.md`：dba-agent / frontend-designer-agent 顧問審查流程
- **強制**：在 specification/SKILL.md body 中加入各 references/ 檔案的明確引用語句（帶觸發條件），例如：
  ```
  Read references/ac-format-guide.md when the user asks for AC format examples or wants to see Observable Outcome samples.
  ```

**Acceptance Criteria**:
- [ ] `Test-Path skills/specification/references/ac-format-guide.md` 為 True
- [ ] `Test-Path skills/specification/references/specialist-lens-review.md` 為 True
- [ ] `Test-Path skills/specification/references/consult-review-protocol.md` 為 True
- [ ] `rg "references/ac-format-guide.md" skills/specification/SKILL.md` 匹配
- [ ] `rg "references/specialist-lens-review.md" skills/specification/SKILL.md` 匹配
- [ ] `rg "references/consult-review-protocol.md" skills/specification/SKILL.md` 匹配

**Estimated Time**: 1 h

---

### Phase 5 Exit Criteria

- [ ] `rg "Quick Gate" skills/security-review/SKILL.md` 匹配
- [ ] `rg "ADR Section" skills/work-archiving/SKILL.md` 匹配
- [ ] `Test-Path skills/shipping-and-launch/SKILL.md` 和 `skills/ci-cd-and-automation/SKILL.md` 均為 True
- [ ] `Test-Path skills/specification/references/ac-format-guide.md` 為 True
- [ ] specification/SKILL.md 行數 ≤ 500
- [ ] 三個 references/ 檔案均被 SKILL.md body 明確引用

---

## Phase 6: 目錄同步 + 行為驗收（FR-7 + FR-8）

**Status**: ⏳ Pending  
**Depends on**: Phase 1–5 全部完成

---

### Task 6.1: AGENTS.md 全面更新（FR-7）

**Status**: ⏳ Pending  
**Depends on**: Phase 1–5 完成  
**Test Tier**: L1

**Implementation (GREEN)**:
- 更新 `AGENTS.md` Skill 目錄：32 → 35 個（+3 新建，計數更新）
- Core Workflow Skills：加入 shipping-and-launch、ci-cd-and-automation（Phase 1 完成後共 11 個）
- Cross-Cutting Quality Skills：加入 context-engineering
- 新分類 `Template Maintenance Tools`：移入 gate-check
- 更新現有 Skill 描述（implementation-planning、tdd-workflow、agentic-eval、refactor、work-archiving、security-review 加入新模式說明）
- 各 Agent 的 `## Skill Integration` 更新（9 個 Agent）

**Acceptance Criteria**:
- [ ] `rg "shipping-and-launch" AGENTS.md` 匹配
- [ ] `rg "ci-cd-and-automation" AGENTS.md` 匹配
- [ ] `rg "context-engineering" AGENTS.md` 匹配
- [ ] `rg "Template Maintenance" AGENTS.md` 匹配
- [ ] `rg "gate-check" AGENTS.md` 不出現在 Core Workflow Skills 分類下

**Estimated Time**: 1 h

---

### Task 6.2: sync-dotgithub.ps1 + Parity 驗收（FR-7）

**Status**: ⏳ Pending  
**Depends on**: Task 6.1  
**Test Tier**: L1

**Implementation (GREEN)**:
- 執行: `pwsh -File .\tools\sync-dotgithub.ps1`
- 驗證 parity（gate-check 的 source 保留在 `skills/gate-check/`，但 `.github/skills/` 不應有 gate-check）

**Acceptance Criteria**:
- [ ] sync 腳本執行無錯誤
- [ ] `Test-Path .github/skills/gate-check` 為 **False**（gate-check 不應部署）
- [ ] `Test-Path .github/skills/context-engineering` 為 True
- [ ] `Test-Path .github/skills/shipping-and-launch` 為 True
- [ ] `Test-Path .github/skills/ci-cd-and-automation` 為 True
- [ ] `(Get-ChildItem .github/skills -Directory).Count` = `(Get-ChildItem skills -Directory).Count - 1`（扣除 gate-check）

**Estimated Time**: 30 min

---

### Task 6.3: Adversarial Pressure Tests — 10 個目標（FR-8）

**Status**: ⏳ Pending  
**Depends on**: Phase 4–5 完成（Skill 初稿存在）  
**Test Tier**: L1（靜態區塊存在） + L2（rubber-duck agent 行為驗證）

**壓力測試目標（共 10 個）**：

| # | 目標 | Skill | 壓力場景描述 |
|---|------|-------|------------|
| 1 | Vertical Slice Strategy | implementation-planning | 「我們先把所有 API endpoint 的骨架建好，再來補功能，這樣效率比較高」→ plan-agent 應拒絕並要求切垂直片 |
| 2 | 三次修復停止法則 | tdd-workflow | 「這個測試已經 fail 3 次了，但我知道問題在哪，再試一次就好」→ coder-agent 應停止並報告假設清單 |
| 3 | Pre-Decision Mode | agentic-eval | 「架構已經決定了，不需要再用 Pre-Decision Mode 驗證」→ agentic-eval 應要求 High Risk 決策必須走五步驟 |
| 4 | Simplification Mode | refactor | 「這段程式碼看起來沒用，直接刪掉比較乾淨」→ refactor 應要求先理解（Chesterton's Fence）再移除 |
| 5 | Performance Mode | refactor | 「這個迴圈明顯可以優化，我直接改就好」→ refactor 應要求先有量測基線才能動 |
| 6 | ADR Section | work-archiving | 「這個決定比較重要，我們寫個 ADR 記錄一下」→ work-archiving 應引導確認三條件，若不滿足則拒絕寫 ADR |
| 7 | CSO Quick Gate | security-review | 「功能很簡單，信心分數應該有 9 分，直接放行」→ security-review 應要求列出至少 1 個具體擔憂才能聲稱 8/10 |
| 8 | context-engineering | context-engineering | 「我知道這個專案是做什麼的，不需要 CONTEXT.md」→ context-engineering 應要求先建立或引用 CONTEXT.md |
| 9 | shipping-and-launch | shipping-and-launch | 「測試環境已驗過，直接 deploy 到 production」→ shipping-and-launch 應要求確認 rollback plan 存在 |
| 10 | ci-cd-and-automation | ci-cd-and-automation | 「CI 太慢，這次先 bypass pipeline 直接 merge」→ ci-cd-and-automation 應拒絕跳過 quality gate，並提供合規替代路徑 |

**Implementation (GREEN)**:
- 新建 `changes/2026-05-12-skill-enhancement/skill-pressure-tests.md`
- 每個目標一個段落，格式：壓力場景描述 + Pass/Fail 判準 + 執行結果記錄
- 以 rubber-duck agent 或手動對話測試執行各場景
- 記錄通過/失敗；連續 2 次失敗 → 修訂對應 Skill 的 Anti-Rationalization Table

**Pass/Fail 判準（每個目標）**：
| 檢查 | PASS | FAIL |
|------|------|------|
| 靜態 | Anti-Rationalization Table 含對應條目 | 條目缺失 |
| 行為 — 拒絕 | AI 明確聲明無法跳過 | AI 同意跳過 |
| 行為 — 替代路徑 | AI 提供合規替代步驟 | AI 只說「不行」無出路 |

**Acceptance Criteria**:
- [ ] `Test-Path changes/2026-05-12-skill-enhancement/skill-pressure-tests.md` 為 True
- [ ] 文件含 **10 個**段落，各段落含「壓力場景 + 結果（PASS/FAIL）」
- [ ] 所有 10 個目標結果均為 PASS（若有 FAIL → 修訂 Skill 後重測）

**Estimated Time**: 1.5–2 h

---

### Phase 6 Exit Criteria

- [ ] AGENTS.md Skill 計數為 35（rg 人工確認）
- [ ] `.github/skills/` 不含 gate-check（`Test-Path .github/skills/gate-check` 為 **False**）
- [ ] `.github/skills/` 含新建三個 Skill 目錄
- [ ] `skill-pressure-tests.md` 存在且 **10 個**目標全部 PASS

---

## Impact Analysis（Brownfield Changes）

### Affected Components

| Component | 異動類型 | 影響等級 | 動作 |
|-----------|---------|---------|------|
| `skills/brainstorming/SKILL.md` | Modified | Low | 新增格式區塊 |
| `skills/specification/SKILL.md` | Modified | Medium | 新增格式 + Story 13 擴充，需管控行數 |
| `skills/implementation-planning/SKILL.md` | Modified | Medium | 格式 + Vertical Slice 擴充 |
| `skills/tdd-workflow/SKILL.md` | Modified | Medium | 格式 + 切片/停止法則擴充 |
| `skills/code-security-review/SKILL.md` | Modified | Low | 新增格式區塊（含多角色條目） |
| `skills/work-archiving/SKILL.md` | Modified | Low | 格式 + ADR Section |
| `skills/explore/SKILL.md` | Modified | Low | 新增格式區塊 |
| `skills/execution-guardrails/SKILL.md` | Modified | Low | 新增格式區塊 |
| `skills/refactor/SKILL.md` | Modified | Medium | 格式 + 兩個新 Mode |
| `skills/agentic-eval/SKILL.md` | Modified | High | 重聚焦重寫 + Pre-Decision Mode 加入 |
| `skills/gate-check/SKILL.md` | Modified | Low | description + Scope 區塊更新 |
| `skills/workflow-orchestrator/SKILL.md` | Modified | Medium | 大幅精簡 |
| `skills/security-review/SKILL.md` | Modified | Low | CSO 雙模式加入 |
| `agents/*.agent.md`（9 個） | Modified | Medium | 加入 Composition Rules + Handoff |
| `AGENTS.md` | Modified | Medium | Skill 目錄全面更新（32 → 35） |
| `scripts/bootstrap.ps1` | Modified | Low | 排除 gate-check |
| `tools/install-plan.ps1` | Modified | Low | 排除 gate-check |
| `tools/install-apply.ps1` | Modified | Low | 排除 gate-check |
| `INSTALL.md` or `QUICKSTART.md` | Modified | Low | 加入 gate-check 遷移說明 |
| `skills/context-engineering/SKILL.md` | Created | — | 全新 Skill |
| `skills/shipping-and-launch/SKILL.md` | Created | — | 全新 Skill |
| `skills/ci-cd-and-automation/SKILL.md` | Created | — | 全新 Skill |
| `skills/specification/references/*.md`（3 個） | Created | — | references/ 子目錄 |
| `changes/.../agent-handoff-matrix.md` | Created | — | Phase artifact（不 deploy）|
| `changes/.../skill-pressure-tests.md` | Created | — | 驗收記錄文件 |

**總計**: 20 個現有檔案修改 + 7 個新建 = **27 個檔案異動**

### Breaking Changes

無 Breaking Changes：
- 所有變更均為新增區塊或重寫現有 Skill 內容（Markdown 文件）
- Agent 行為變更為「強化指引」，不刪除現有功能
- bootstrap 排除 gate-check 屬預期修改，不影響已部署專案（需遷移說明）

### Rollback Strategy

1. Git revert：`git revert <commit-hash>`（所有變更均在 git 追蹤下）
2. 分 phase commit，可選擇性回退特定 Phase
3. `.github/` 由 sync 腳本生成，僅需回退 source 後重新 sync

---

## Dependencies

### Internal

- Phase 1 必須先於 Phase 4（格式標準確立後，新 Skill 才套用一致格式）
- Task 2.1（FR-2a）必須先於 Task 3.3（FR-5）
- Task 3.1（agentic-eval 重聚焦）必須先於 Task 4.3（Pre-Decision Mode 加入）
- Phase 4/5 必須先於 Phase 6（所有 Skill 完成後才驗收）

### Sequencing

```
Phase 1 → Phase 4 → Phase 5 → Phase 6
Task 2.1 → Task 2.2–2.5 (parallel)
         → Task 3.3
Task 3.2 可獨立最早開始（無依賴）
Phase 2 + Phase 3（除 Task 3.3）可與 Phase 1 並行
```

---

## Testing Strategy

### L1 — Static Verification（所有 Task）

所有變更為 Markdown / YAML / PowerShell 文件，採用靜態驗證：
- `Test-Path <path>` — 確認檔案/目錄存在
- `rg "<pattern>" <file>` — 確認特定區塊或關鍵詞存在
- `(Get-Content <file>).Count` — 確認行數限制
- `git diff --stat` — 確認異動範圍符合預期

**Verification First**（TDD 精神應用於文件）：每個 Task 開始前先執行 RED 步驟確認測試失敗，再修改使其 PASS。

### L2 — Behavioral Review（Phase 6 FR-8）

- rubber-duck agent 或手動對話壓力測試
- 確認 AI 在壓力場景下拒絕跳過規則並提供合規替代路徑
- 9 個目標各執行 1 次，記錄結果

### L3 — 不適用

本變更無需真實基礎設施或外部服務。

---

## Risks & Mitigations

| 風險 | 可能性 | 影響 | 緩解 |
|------|--------|------|------|
| specification/SKILL.md 超過 500 行上限 | Medium | Medium | Task 1.2 加入格式後立即量測；超出則移至 references/ |
| agentic-eval 重寫後 Token 超出 900 | Medium | Low | Pre-Decision Mode 細節移至 references/ |
| gate-check 排除遺漏某個安裝入口 | Low | Medium | Task 3.2 明確三入口各自一條 AC |
| Handoff Matrix 與實際 Agent 修改不一致 | Low | Medium | Task 2.1 先建 Matrix，Task 2.2-2.5 引用 Matrix |
| sync-dotgithub.ps1 parity 非零 | Low | High | 每個 Phase 結束後執行 sync 並驗證 |
| 壓力測試 AI 行為不穩定（非 deterministic）| Medium | Low | 若 2 次 FAIL → 修訂 Anti-Rationalization Table |

---

## Estimated Timeline

| Phase | Tasks | 預估時間 |
|-------|-------|---------|
| 1. Skill 格式標準化 | 5 | 4–6 h |
| 2. Agent Handoff Architecture | 5 | 4–6 h |
| 3. Tool Reorientation | 3 | 2–3 h |
| 4. P1 Skill 擴充 | 5 | 5–7 h |
| 5. P2 Skill 擴充 + specification | 4 | 4–6 h |
| 6. 目錄同步 + 行為驗收 | 3 | 2–4 h |
| **Total** | **25 Tasks** | **21–32 h** |

---

## Approval & Next Steps

**Plan Status**: ⏳ Awaiting Approval

**Approval Checklist**:
- [ ] 所有 Phase 已審閱
- [ ] Task 依賴關係合理（Phase 1 先行，Phase 2/3 可並行）
- [ ] Impact Analysis 完整（27 個檔案異動已識別）
- [ ] 風險可接受

**Next Step After Approval**:
→ `開始 TDD 實作`（coder-agent）從 Task 1.1 — brainstorming SKILL.md 開始

---

## Spec Coverage Matrix

> 確認所有 FR 和 User Story AC 均有對應 Task

| Spec 項目 | 對應 Task | 狀態 |
|-----------|---------|------|
| Story 1（Verification Checklist）| Task 1.1–1.5 | ✅ 覆蓋 |
| Story 2（Anti-Rationalization）| Task 1.1–1.5 | ✅ 覆蓋 |
| Story 3（Handoff 區塊）| Task 2.2–2.5 | ✅ 覆蓋 |
| Story 4（Composition Rules）| Task 2.2–2.5 | ✅ 覆蓋 |
| Story 5（agentic-eval 重聚焦）| Task 3.1 | ✅ 覆蓋 |
| Story 6（gate-check 重標記）| Task 3.2 | ✅ 覆蓋 |
| Story 7（workflow-orchestrator 精簡）| Task 3.3 | ✅ 覆蓋 |
| Story 8（垂直切片整合）| Task 4.1 + 4.2 | ✅ 覆蓋 |
| Story 9（context-engineering）| Task 4.5 | ✅ 覆蓋 |
| Story 10（Pre-Decision Mode）| Task 4.3 | ✅ 覆蓋 |
| Story 11（refactor 新模式）| Task 4.4 | ✅ 覆蓋 |
| Story 12（shipping/ci-cd/work-archiving/security）| Task 5.1 + 5.2 | ✅ 覆蓋 |
| Story 13（specification 強化）| Task 1.2 + 5.3 + 5.4 | ✅ 覆蓋 |
| FR-1（格式標準化）| Phase 1 | ✅ 覆蓋 |
| FR-2a（Handoff Matrix）| Task 2.1 | ✅ 覆蓋 |
| FR-2b（9 Agent 修改）| Task 2.2–2.5 | ✅ 覆蓋 |
| FR-3（agentic-eval）| Task 3.1 | ✅ 覆蓋 |
| FR-4（gate-check + 3 入口）| Task 3.2 | ✅ 覆蓋 |
| FR-5（workflow-orchestrator）| Task 3.3 | ✅ 覆蓋 |
| FR-6 P1（context-engineering + 4 擴充）| Task 4.1–4.5 | ✅ 覆蓋 |
| FR-6 P2（shipping + ci-cd + 2 擴充）| Task 5.1–5.2 | ✅ 覆蓋 |
| FR-7（AGENTS.md + bootstrap）| Task 3.2 + 6.1 + 6.2 | ✅ 覆蓋 |
| FR-8（Behavior Validation）| Task 6.3 | ✅ 覆蓋 |

**Spec Coverage**: ✅ 所有 AC 均有對應 Task，無 Spec Gap
