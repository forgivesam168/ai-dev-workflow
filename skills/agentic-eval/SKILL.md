---
name: agentic-eval
description: >
  Patterns and techniques for evaluating and improving AI agent outputs through
  iterative critique and refinement. Use this skill when:
  implementing self-critique loops, evaluator-optimizer pipelines,
  rubric-based scoring, LLM-as-judge evaluation, adversarial evaluation,
  judge-and-refine cycles, or structured output quality improvement.
  Do NOT use for standard code review (use code-review skill),
  general refactoring (use refactor skill), or security audits.
allowed-tools: task sql
compatibility: >
  Tier 1 (self-critique/rubric) works in any environment.
  Tier 2 (external critic via task subagent) requires the task tool.
  Tier 3 (tracked iterations via sql) uses per-session DB only.
  Rubber-duck adversarial evaluation requires RUBBER_DUCK_AGENT experimental
  flag: run /experimental on, or set enabledFeatureFlags.RUBBER_DUCK_AGENT: true
  in ~/.copilot/config.json.
---

# Agentic Evaluation Patterns

Iterative critique-and-refine loops for quality-critical agent outputs.

```
Generate → Evaluate → Critique → Refine → Output
    ↑                              │
    └──────────────────────────────┘
```

## When to Use

- Output is **high-stakes or externally visible** (code shipped to prod, published reports)
- An **objective rubric or measurable criteria** can be defined upfront
- **Revision cost is acceptable** — iteration takes time
- A **second perspective** is needed beyond linting or syntax checks

## When NOT to Use

- Trivial or low-risk exploratory drafts
- Standard code quality/security review → use `code-review` or `code-security-review`
- Refactoring existing code → use `refactor`
- Simple formatting or lint issues

---

## 3-Tier Evaluation Framework

Choose the tier that matches your environment and quality target:

| Tier | Requires | Best For |
|------|----------|----------|
| **1 — Self-Critique** | Nothing (always available) | Quick quality check with rubric |
| **2 — External Critic** | `task` tool + critic agent | Adversarial second-opinion |
| **3 — Tracked Evaluation** | `task` + `sql` tools | Multi-iteration with history |

---

## Tier 1: Self-Critique / Rubric (Always Available)

Define a rubric, score the output, refine on FAIL dimensions. Max 3–5 iterations.

**Steps:**
1. Define criteria and score threshold (e.g., 0.8 / 5-point scale)
2. Score output against each dimension using structured JSON
3. If any dimension FAIL → refine with targeted feedback
4. Stop when all PASS or max iterations reached

See [Python implementation patterns](./references/python-patterns.md) for code examples.

---

## Tier 2: External Critic via Subagent (Requires `task` tool)

Delegate evaluation to a separate subagent using a **different model perspective** for adversarial critique.

**Steps:**
1. Generate output (code, report, design)
2. Extract a focused excerpt or summary — do NOT pass entire blobs; pass key sections, diff, or rubric context
3. Call critic subagent via `task` tool:
   - If `RUBBER_DUCK_AGENT` flag is enabled: use `agent_type: "rubber-duck"`
   - Otherwise: use `agent_type: "general-purpose"` with an adversarial system prompt
4. Parse critique → identify weak points
5. Refine output targeting identified weaknesses
6. Repeat up to 3 iterations

> ⚠️ **rubber-duck availability**: This built-in agent requires the `RUBBER_DUCK_AGENT` experimental
> flag. If unavailable, `general-purpose` with an adversarial prompt is a valid fallback.

**Context efficiency rules:**
- For code: pass file path + diff excerpt, not full file content
- For reports: pass the relevant paragraph + evaluation rubric
- For designs: pass key decisions + constraints, not full spec

See [CLI evaluation workflow](./references/cli-evaluation-workflow.md) for step-by-step guide.

---

## Tier 3: Tracked Evaluation (Requires `task` + `sql` tools)

Persist iteration scores to the **per-session database** for convergence analysis and audit trail.
Use only when tracking history across 3+ iterations is meaningful.

> ⚠️ Use `sql` with `database: "session"` (the per-session DB). Do NOT use `database: "session_store"` — it is read-only.

**Minimal schema:**
```sql
CREATE TABLE IF NOT EXISTS eval_iterations (
    id        INTEGER PRIMARY KEY AUTOINCREMENT,
    iteration INTEGER NOT NULL,
    dimension TEXT    NOT NULL,
    score     REAL    NOT NULL,
    critique  TEXT,
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP
);
```

Store only: iteration number, dimension, score, brief critique summary. Never store full output blobs.

See [CLI evaluation workflow](./references/cli-evaluation-workflow.md#tier-3-tracked-evaluation) for full query patterns.

---

## Evaluation Strategies

| Strategy | When to Use |
|----------|-------------|
| **Rubric-Based** | Clear weighted dimensions exist (accuracy, clarity, completeness) |
| **Outcome-Based** | Evaluate against expected end result |
| **LLM-as-Judge** | Compare two candidate outputs head-to-head |
| **Adversarial** | Find edge cases, failure modes, security/logic flaws |
| **Test-Driven** | Code: write tests first, iterate until all pass |

---

## Quick Start Checklist

```markdown
## Evaluation Setup
- [ ] Choose tier (1 / 2 / 3) based on environment and stakes
- [ ] Define rubric dimensions and score threshold
- [ ] Set max iterations (default: 3, max: 5)

## Execution
- [ ] Generate initial output
- [ ] Score against rubric (Tier 1) or delegate to critic (Tier 2+)
- [ ] Refine targeting failed dimensions only
- [ ] Check convergence: stop if score not improving

## Safety
- [ ] Enforce iteration limit to prevent infinite loops
- [ ] Pass summaries/excerpts to critics — not full blobs
- [ ] Handle parse failures gracefully (fallback to full re-score)
- [ ] Log final score and iteration count
```

---

## References

- [Python Application Patterns](./references/python-patterns.md) — Tier 1 code examples (self-critique, evaluator-optimizer, code reflection)
- [CLI Evaluation Workflow](./references/cli-evaluation-workflow.md) — Tier 2 & 3 step-by-step guide (task subagent, rubber-duck, SQL tracking)
