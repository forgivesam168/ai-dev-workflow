# Agent Handoff Matrix

**Purpose**: Phase artifact for Task 2.2–2.5 reference.  
**Last Updated**: 2026-05-13  
**Spec Reference**: `changes/2026-05-12-skill-enhancement/03-spec.md` — FR-2a

---

## Naming Convention

`handoffs` frontmatter `agent:` 值 = `.agent.md` 檔名去掉 `.agent.md` 副檔名：

| 檔名 | `agent:` 值 |
|------|------------|
| `brainstorm.agent.md` | `brainstorm` |
| `spec.agent.md` | `spec` |
| `plan.agent.md` | `plan` |
| `coder.agent.md` | `coder` |
| `code-reviewer.agent.md` | `code-reviewer` |
| `pm.agent.md` | `pm` |
| `architect.agent.md` | `architect` |
| `dba.agent.md` | `dba` |
| `frontend-designer.agent.md` | `frontend-designer` |

---

## Standard Chain（標準路徑）

```
brainstorm-agent → spec-agent → plan-agent → coder-agent → code-reviewer → work-archiving
                       ↑↓ Consult: dba-agent
                       ↑↓ Consult: frontend-designer-agent
                   ←← pm-agent (任何階段均可介入)
                   ←← architect-agent (任何階段均可介入)
```

---

## Agent Handoff Matrix（9 個 Agent）

### 📌 標準鏈路 Agent

| Agent | Entry Signals | Completion Conditions | Next Step |
|-------|-------------|----------------------|-----------|
| **brainstorm-agent** | 新功能/需求啟動、需求模糊或不完整、"brainstorm"、"探索選項"、"釐清需求"、任何新工作項目開始 | `01-brainstorm.md` 已建立 + Risk Classification（Low/Med/High）已確立 + 至少 5 個 Must-Ask 問題已覆蓋或使用者明確允許 assumption-driven 模式 | **Standard Path** → spec-agent<br>**Fast Path**（Low-risk only）→ plan-agent |
| **spec-agent** | brainstorm 完成後、需要規格/PRD 文件、"write spec"、"create PRD"、"document requirements" | `03-spec.md` 已建立 + 所有 `[ASSUMED]` 條目已解決或 user-approved + AC Testability 通過（所有 AC 可表達為失敗測試）+ 無未解 Open Questions | **Main** → plan-agent<br>**Consult** → dba（DB 設計審查）<br>**Consult** → frontend-designer（UI 設計審查）|
| **plan-agent** | spec 完成後、需要實作計畫、"create plan"、"task breakdown"、"spec to plan" | `04-plan.md` 已建立 + First TDD Slice 已標記 + 所有 Task 均有具體可執行步驟 + Spec Coverage Matrix 完成 | coder-agent |
| **coder-agent** | plan 完成後、TDD 實作、"implement"、"code"、"開始 TDD"、"TDD 實作" | 所有 L1 測試通過（Green Build）+ Financial Precision 確認 + Pre-Review Self-Eval 通過 + 無 float/double 用於金錢 | code-reviewer |
| **code-reviewer** | 實作完成後、準備 PR、"review"、"audit"、"code review"、"審核程式碼" | `05-review.md` 已建立 + 無未解 🔴 Critical issue + Approval Status（🔴/🟡/🟢）已填寫 | work-archiving（標準路徑）<br>coder-agent（若有 Critical issue 需修復）|

---

### 🔄 多階段 Agent（Multi-Stage）

| Agent | Entry Signals | Completion Conditions | Next Step |
|-------|-------------|----------------------|-----------|
| **pm-agent** | 任何階段均可介入 — "project status"、"what's next"、"current stage"、"workflow status"、"我們現在在哪" | 當前階段已確認（依 `changes/` 目錄文件判斷）+ 下一步建議已提供 | **建議**（非命令）依當前階段動態路由：brainstorm → spec → plan → coder → code-reviewer → archive<br>⚠️ pm-agent 只建議，不強制切換 |
| **architect-agent** | 任何階段均可介入 — "design"、"architect"、"ADR"、"system design"、"architectural trade-offs"、架構選擇、高風險技術決策 | Consult Review 完成 + 架構建議已記錄（ADR 或 spec notes）+ 任何架構風險已明確告知觸發方 | 完成後建議**回到觸發方** Agent（非強制切換至新 Agent）|

---

### 🔍 Consult 介入 Agent（Specialist Review）

| Agent | Entry Signals（重要：spec/plan 階段就應介入） | Completion Conditions | Next Step |
|-------|-------------|----------------------|-----------|
| **dba-agent** | spec 或 plan 文件包含資料庫設計決策時即可介入（不只是 coding 階段）— "design schema"、"ERD"、"migration"、"資料庫設計"、spec 中有 Data Model 章節 | Schema 設計完成（ERD + 欄位定義）+ Migration scripts（up + down）存在 + 審查清單完成 + 破壞性變更已標記 | **回到觸發方**（spec-agent 或 plan-agent）將 DB 審查結果整合回規格/計畫 |
| **frontend-designer-agent** | spec 或 plan 文件包含前端/UI 設計需求時即可介入（spec/plan 階段優先）— "design UI"、"wireframe"、"component spec"、spec 中有前端相關 User Stories | Component spec 完成（props/states/variants）+ 無障礙清單（WCAG 2.1 AA）+ Handoff notes 給 coder-agent | **回到觸發方**（spec-agent 或 plan-agent）將 UI 設計結果整合回規格/計畫 |

---

## Chain Link Verification（鏈路無斷層確認）

| 鏈路步驟 | 交付物 | 接收方驗收條件 |
|---------|-------|--------------|
| brainstorm-agent → spec-agent | `01-brainstorm.md` + Risk Level | spec-agent 確認 Risk Level 存在，依 Risk Level 決定規格深度 |
| spec-agent → plan-agent | `03-spec.md` + AC List | plan-agent 執行 Spec Cross-Validation（每個 AC 均可寫出具體步驟）|
| plan-agent → coder-agent | `04-plan.md` + First TDD Slice | coder-agent 從 First TDD Slice 開始 RED 驗證 |
| coder-agent → code-reviewer | Green Build + `DONE` status | code-reviewer 執行 Step 1: `git diff` 取得變更範圍 |
| code-reviewer → work-archiving | `05-review.md` + 🟢 Approved | work-archiving 確認 review.md Approval Status 為 🟢 |

---

## Trigger Keyword 不重疊審查

> **目的**: 確認 9 個 Agent 的核心觸發詞無重疊，防止錯誤 Agent 被自動啟動。

| Agent | 核心觸發詞 | 潛在重疊風險 | 評估 |
|-------|----------|------------|------|
| brainstorm | brainstorm, explore options, triage risk, clarify requirements, 釐清需求, 腦力激盪 | 無顯著重疊 | ✅ |
| spec | write spec, create PRD, document requirements, user stories, acceptance criteria | 無顯著重疊 | ✅ |
| plan | implementation plan, task breakdown, spec to plan, 規劃實作, 拆解任務 | 無顯著重疊 | ✅ |
| coder | implement, code, write code, TDD, test-driven, 開始 TDD, 測試先行 | 無顯著重疊 | ✅ |
| code-reviewer | review, audit, check code quality, security review, 審核程式碼 | 無顯著重疊 | ✅ |
| pm | project status, what's next, current stage, workflow status, 所有專案狀態 | 無顯著重疊 | ✅ |
| architect | design, architect, ADR, system design, architectural trade-offs | "design" 可能與 frontend-designer 的 "design UI" 重疊 | ⚠️ 低風險：architect 觸發詞無 "UI"，frontend-designer 有 "UI/UX" 限定 |
| dba | design schema, ERD, migration, optimize query, 資料庫設計, SQL review | 無顯著重疊 | ✅ |
| frontend-designer | design UI, wireframe, component spec, design system, 前端設計, UI 規格 | 同上 architect "design" | ⚠️ 低風險：frontend-designer 觸發詞均含 UI/UX/component 限定詞 |

**結論**: 9 個 Agent 觸發詞整體無嚴重重疊。"design" 一詞在 architect 和 frontend-designer 間存在低風險重疊，但各自有限定詞（architect 無 UI 限定；frontend-designer 有 UI/UX/component 限定），在實際使用中應可區分。

---

## Appendix: Composition Rules 共同約束

所有 9 個 Agent 的 Composition Rules 均需遵守以下共同約束：

1. **不得主動切換 Agent**：每個 Agent 完成職責後，輸出 Next Step 建議，但不主動呼叫或切換至其他 Agent（使用者或 pm-agent 決定）。
2. **不得處理非職責範圍的工作**：若使用者提出超出當前 Agent 職責的請求，提示切換至對應 Agent。
3. **不得靜默假設**：所有假設必須明確標記並告知使用者，不得以「理解了」替代確認。

**例外**：pm-agent 的 Composition Rules 允許跨階段建議切換（其職責即為跨階段協調），但措辭為「建議」非「命令」。pm-agent 是唯一含此例外的 Agent。
