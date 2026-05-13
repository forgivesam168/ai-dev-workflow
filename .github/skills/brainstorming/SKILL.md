---
name: brainstorming
description: 'Start a work item: triage risk, run structured brainstorming to clarify requirements, compare solution options, and produce a decision log + change package skeleton.'
license: MIT
---

# Brainstorming

> 💡 **Recommended Agent**: `brainstorm-agent` (Requirements Explorer)
> - **CLI**: Input `/agent` and select `brainstorm-agent`
> - **VS Code**: Use `@workspace #brainstorm-agent` in Chat

## When to Use
Use this skill at the **start of any request/change** when:
- Requirements are ambiguous or incomplete
- The change touches security, auth/authz, data flow, CI/CD, or supply chain
- There are multiple plausible implementation approaches
- You need a rationale trail (auditability)

> 💡 **方向完全不明確？** 先用 `/research` 探索技術地圖，再回來 brainstorm。

## Workflow

### Pre-Phase — Domain Research（條件觸發）

**觸發條件**（滿足任一即觸發）：
- 使用者未指定技術棧
- 無現有 codebase（greenfield 專案）
- 想法屬於領域/概念層級（如「我想做 AI 客服平台」「我想做財務分析工具」）

派遣 `research` subagent，指令範本：
> *"Search GitHub for [domain] popular libraries, architectures, and community trends (2024–2025). Report top 3 approaches with complexity, maturity, and trade-offs, with citations."*

將研究結果整理為**解法地圖**（2-3 條路線 + 社群成熟度），作為 Phase 1 提問與 Phase 2 選項比較的依據。

### Phase 0 — Intake & Risk Classification
- Clarify goals/non-goals and acceptance criteria
- Classify risk: **Low** / **Med** / **High**
- Determine if this is brownfield (existing system)
- Decide workflow path:
  - **Standard**: brainstorm → plan → tdd → review
  - **Fast** (low-risk only): plan → tdd → review

### Phase 1 — Clarify
- In each new brainstorming round, ask at least 5 targeted questions before options/recommendation unless the user explicitly says assumptions are acceptable
- If the user cannot answer immediately, list assumptions separately and label what remains unknown

### Phase 2 — Explore Options
- Produce 2–3 options
- For each: complexity (L/M/H), risks, dependencies, rollback strategy

### Phase 3 — Decide & Record
- Recommend one option and justify
- Produce a **Decision Log** entry (append-only)

### Phase 4 — Change Package Skeleton
- Use shell to create `changes/<YYYY-MM-DD>-<slug>/` directory first
- Then write stub files (do NOT use `edit` on non-existent files):
  - `01-brainstorm.md`
  - `02-decision-log.md`
  - `03-spec.md` (draft)
- If shell is unavailable, output file contents in response for manual creation

## Must-Ask Questions

Apply to **every project** regardless of domain:

In a normal kickoff, cover at least five of these categories before recommending a path or solution. If the user explicitly allows assumptions, say that you are switching to assumption-driven brainstorming.

| Category | Question | Purpose |
|----------|----------|---------|
| **Problem** | What problem are we solving? How is it handled today? | Avoid solving the wrong problem |
| **Users** | Who will use this? What are the different roles? | Define personas |
| **Non-goals** | What are we explicitly NOT doing in this iteration? | Prevent scope creep |
| **Failure scenario** | If this feature breaks, what's the worst case? | Risk awareness |
| **Existing system** | What existing components will this touch or depend on? | Greenfield vs brownfield |
| **Acceptance** | How will we know it's done? How will we verify it works? | Seed acceptance criteria |
| **Rollback** | If we ship this and it causes problems, can we revert? | Safety net |

## Conditional Follow-up Questions

Trigger these based on the user's answers:

| Trigger | Follow-up Questions |
|---------|---------------------|
| Involves money / pricing | Precision rules? Which currencies? Rounding strategy? Idempotency? |
| Involves personal data | Privacy requirements? Who can access? Retention policy? |
| Involves permissions / roles | Who can read, write, approve? Audit trail needed? |
| Brownfield system | Which modules are affected? Dependent systems? Migration needed? |
| Multi-system integration | API contracts? Failure/retry behavior? Eventual consistency acceptable? |
| Scheduled / batch processing | What if it runs twice? Timeout handling? Partial failure recovery? |
| Reporting / audit | Who reads the reports? How far back must data be queryable? |
| Workflow / approvals | What are the state transitions? Who can approve or reject? |

## Risk Classification

| Level | Criteria | Recommended Path |
|-------|----------|--------------------|
| **Low** | Single file or isolated component, no existing users, no data flow changes, easily reverted | Fast Path: Plan → TDD → Review |
| **Med** | Multiple files, touches existing features, some external dependencies | Standard Path: Spec → Plan → TDD → Review → Archive |
| **High** | Cross-module, security/permissions, data migration, regulatory, or production-critical | Standard Path (mandatory): all 6 stages, CODEOWNERS review |

## Output Template

- Risk Classification (Low/Med/High)
- Workflow Path Recommendation (Standard/Fast)
- Questions Asked (at least 5 unless the user explicitly allowed assumptions)
- Assumptions & Constraints
- Options (2–3)
- Recommendation
- Decision Log
- Change Package Skeleton (file stubs)

### Brainstorm Summary Format

Use this structure in `01-brainstorm.md`:

```markdown
## Brainstorm Summary

**Problem**: [one sentence]
**Risk Level**: Low / Med / High
**Workflow Path**: Fast / Standard
**Chosen Approach**: [option name and one-line reason]
**Discovery Questions Covered**: [at least five categories, or note that the user explicitly allowed assumptions]
**Open Questions**: [anything still unresolved]
**Assumptions**: [what we're assuming to be true]
**Non-goals**: [explicitly out of scope]
```

## Output Mapping (Change Package)
Write results into:
- `changes/<YYYY-MM-DD>-<slug>/01-brainstorm.md`
- `changes/<YYYY-MM-DD>-<slug>/02-decision-log.md`
- Draft/Update `changes/<...>/03-spec.md` (minimum scope + verification)

**Directory creation**: Always create the target directory with shell (`mkdir -p` / `New-Item -ItemType Directory -Force`) before writing files. The `edit` tool CANNOT create new files — use shell or `create` tool instead.
If shell is unavailable, output file contents in response for manual creation.

## Common Rationalizations

在腦力激盪過程中，AI 可能以下列藉口跳過關鍵步驟。以下為常見合理化說詞與反制說明：

| 常見藉口 | 反制說明 |
|---------|---------|
| "我只是先試試，不是真的要實作" | ⛔ 在設計批准前，任何實作程式碼均為違規——無論使用者要求多迫切 |
| "需求很清楚了，不需要再問問題" | 腦力激盪的目的是發現「你不知道你不知道的」——即使需求看起來清楚，仍需走完 Must-Ask Questions |
| "風險很低，可以跳過 brainstorm 直接 plan" | Fast Path 仍需 Risk Classification 和 Change Package Skeleton；跳過分類等於盲目行動 |
| "使用者已經給了選項，我選一個就好" | 未產出 2–3 個選項比較 = 放棄最重要的決策品質保證；必須列出選項與折衷取捨，即使使用者傾向某選項 |

## Verification

在輸出 brainstorm 產出物前，逐項確認（Gate = 交付前閘門；Verification = 自我完成確認）：

- [ ] `Test-Path changes/<slug>/01-brainstorm.md` 回傳 True（Change Package 目錄與 brainstorm 文件已實際建立）
- [ ] Risk Classification 已完成，等級為 Low / Med / High 三者之一，且依 Risk Level 對齊 Workflow Path
- [ ] 至少 5 個 Must-Ask 問題類別已覆蓋，或使用者已明確允許 assumption-driven 模式（不得靜默跳過）
- [ ] 至少 2 個選項已比較（complexity / risks / rollback strategy），並有明確推薦理由
- [ ] Decision Log 條目已寫入 `02-decision-log.md`
- [ ] Open Questions 欄位已填寫（若有未解問題），不得略去
- [ ] 所有 Assumptions 均已明確標記（不得以隱性假設替代明確說明）
