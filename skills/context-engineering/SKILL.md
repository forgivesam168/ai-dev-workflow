---
name: context-engineering
description: >
  Context structuring and conflict detection for AI-assisted development.
  Use this skill when: making technical decisions that require understanding
  full project context, detecting vocabulary or terminology conflicts before
  implementing, generating or updating CONTEXT.md for persistent project memory,
  or when architect-agent needs to ground decisions in project-wide context.
  Triggers on: "context engineering", "context conflict", "vocabulary mismatch",
  "update context", "project context", "CONTEXT.md", "context bootstrap".
  Do NOT trigger when doing routine code implementation (use tdd-workflow),
  simple Q&A, or single-file edits with no cross-cutting concerns.
---

# Context Engineering

Structured context management to reduce hallucination, vocabulary drift, and stale assumptions in AI-assisted development.

## When to Use

- AI is making a **technical decision** that affects architecture, APIs, or shared vocabulary
- **architect-agent** is reasoning about design trade-offs (architect-agent should load this skill first)
- Vocabulary or terminology inconsistency is detected between conversation and project documentation
- A new `CONTEXT.md` needs to be created or updated for project memory
- Starting a new AI session on an existing project (**context bootstrap**)

## The 5-Layer Context Architecture

Context flows from broad to narrow. Each layer informs the layers below it.

| Layer | Source | Purpose |
|-------|--------|---------|
| **1. Project** | `CONTEXT.md` / `.ai-workflow-memory/PROJECT_CONTEXT.md` | Domain model, tech stack, team conventions, glossary |
| **2. Codebase** | File structure, module map, key interfaces | Current state of the code — what exists and how it's structured |
| **3. Task** | `03-spec.md`, `04-plan.md`, current AC list | What is being built right now and why |
| **4. Conversation** | Current session history, stated assumptions | What has been decided in this session |
| **5. External Docs** | OpenAPI specs, third-party API docs, library references | External contracts and constraints |

**Loading order**: Always load Layer 1 (Project) before Layer 3 (Task). Never reason from Layer 4 (Conversation) alone when Layer 1 is available.

---

## Process

### Step 1: Load Project Context (Layer 1)

Before any technical decision, load Layer 1:

```
If .ai-workflow-memory/PROJECT_CONTEXT.md exists → read it
Else if docs/CONTEXT.md exists → read it
Else → flag: "No project context found. Generating a minimal version is recommended."
```

### Step 2: Load Codebase Snapshot (Layer 2)

- View directory structure; identify key modules, interfaces, and boundaries
- Note: structural overview only — do NOT read all files

### Step 3: Vocabulary Conflict Detection

Before any technical decision, compare terms used in:
- Current conversation (Layer 4)
- Task spec / plan (Layer 3)
- Project CONTEXT.md glossary (Layer 1)

**Conflict found → stop immediately and report:**

```
⚠️ Vocabulary Conflict Detected
Term: "[term]"
Conversation usage: "[how it's used now]"
Project glossary definition: "[CONTEXT.md definition]"
Action required: Confirm which definition applies before proceeding.
```

Do NOT proceed with implementation until the conflict is resolved.

### Step 4: Generate or Update CONTEXT.md

**Output path rules**:
- `.ai-workflow-memory/` exists → write to `.ai-workflow-memory/PROJECT_CONTEXT.md`
- `.ai-workflow-memory/` does not exist → write to `docs/CONTEXT.md`
- Never overwrite without diffing first: confirm `git diff` shows no unintended loss

**Minimum CONTEXT.md structure**:

```markdown
# Project Context

## Tech Stack
[language, framework, runtime versions]

## Domain Glossary
| Term | Definition |
|------|------------|
| [term] | [definition] |

## Architecture Boundaries
[key module boundaries and ownership]

## Active Conventions
[naming conventions, code style, test strategy]
```

---

## Common Rationalizations

在執行 context engineering 時，AI 可能以下列藉口跳過關鍵步驟：

| 常見藉口 | 反制說明 |
|---------|---------|
| "我已經知道這個專案的架構，不用再看 CONTEXT.md" | ⛔ 跨 session 記憶不可靠——每個 session 開始前必須重新載入 Layer 1，不得依賴對話歷史中的假設 |
| "這個術語顯然是指 X，不需要確認" | 詞彙衝突是 AI 幻覺的主要來源——任何「顯然」的假設必須與 CONTEXT.md 對比；不一致 → 立即釐清 |
| "CONTEXT.md 不存在，所以我直接推斷專案結構" | 無 CONTEXT.md → 先建立最小版本，再繼續——推斷式理解無法被驗證，會累積誤差 |
| "context 更新可以之後再做" | 過時的 context 比沒有 context 更危險——它會讓 AI 誤以為持有正確資訊，讓錯誤持續累積 |

---

## Verification

在任何 context-engineering 操作完成後，逐項確認：

- [ ] `Test-Path .ai-workflow-memory/PROJECT_CONTEXT.md` 或 `Test-Path docs/CONTEXT.md` 其中一項為 True
- [ ] CONTEXT.md 包含 Tech Stack、Domain Glossary、Architecture Boundaries 三個必要章節
- [ ] 所有詞彙衝突已記錄並解決（無未確認衝突）
- [ ] Layer 1（Project Context）已在技術決策**前**載入（非決策後補讀）
- [ ] CONTEXT.md 更新未覆蓋任何既有條目（`git diff` 確認無非預期刪除）
