---
name: agentic-eval
description: >
  Adversarial evaluation patterns for any output or decision where you want
  a devil's advocate challenge before committing. Use when:
  you want to challenge a decision, get an adversarial second opinion,
  implement self-critique loops, apply rubric-based scoring,
  run evaluator-optimizer pipelines, judge-and-refine cycles,
  verify a downstream agent can consume an upstream artifact,
  or check inter-stage artifact consistency.
  Triggers on "devil's advocate", "challenge this decision", "挑戰這個決策",
  "扮演反對者", "adversarial review", "self-critique", "質疑這個方案".
  Do NOT use for standard code review (use code-security-review skill),
  general refactoring (use refactor skill), or security audits.
allowed-tools: agent sql
compatibility: >
  Tier 1 (self-critique/rubric) works in all environments (VS Code, CLI, cloud).
  Tier 2 (external critic via subagent) requires the agent tool: in CLI use task tool
  with agent_type; in VS Code use runSubagent / agent tool with explicit model selection
  for multi-model diversity. Rubber-duck (CLI) requires RUBBER_DUCK_AGENT experimental flag.
  Tier 3 (tracked iterations via sql) is CLI-only; uses per-session DB.
---

# Agentic Evaluation Patterns

Iterative critique-and-refine loops for quality-critical agent outputs.

```
Generate → Evaluate → Critique → Refine → Output
    ↑                              │
    └──────────────────────────────┘
```

## Rubber Duck Spirit

用相反論點挑戰自己的輸出，直到找不到反駁為止。

> *"If you can't find a counter-argument, the output is ready. If you can, fix the weakness first."*

核心行為模式：
1. 生成輸出後，立即問：「什麼論點可以反駁這個決定？」
2. 若找到反論 → 修正輸出，再問一次
3. 若找不到有力反論 → 輸出已足夠穩健，繼續前進
4. 不因「感覺對了」或「已經改很多次」就停止挑戰

agentic-eval 是將此精神**結構化**的工具集。任何決策、任何輸出均可使用，無須等特定階段。

---

## General-Purpose Pre-Decision Mode（決策前懷疑模式）

Use this optional scoring pattern to challenge a decision outside the named High-Risk lifecycle gates. For High-Risk architecture, security, permission, data, or public-contract commitment, use the rule-based **Architecture Decision Exit** gate instead.

> Numeric self-scoring in this section is a general-purpose refinement aid. It is not approval evidence and does not apply to any named High-Risk gate.

### Five-Step Protocol

| Step | Action |
|------|--------|
| **CLAIM** | State the decision in one sentence: *"I will [X] because [Y]"* |
| **EXTRACT** | List all assumptions the decision depends on (≥ 3) |
| **DOUBT** | Apply **Sequential Specialist Lens** — each perspective states ≥ 1 challenge or confirmation |
| **RECONCILE** | Self-score 0–10; describe what "10" looks like; edit until target score reached |
| **STOP** | Score ≥ 8 → proceed; Score < 8 after 1 re-score → escalate to user with DOUBT findings |

### Sequential Specialist Lens（DOUBT 步驟）

依序審查，每視角至少提出 **1 個質疑或確認**：

1. **Security** — 這個決策是否開了攻擊面？認證 / 授權 / 注入風險？
2. **Performance** — 是否引入 N+1 查詢、無界資料集、阻塞呼叫？
3. **Architecture** — 是否違反分層邊界、DDD 聚合規則、循環依賴？
4. **Maintainability** — 新成員 6 個月後能看懂嗎？測試可維護嗎？
5. **Operability** — 錯誤訊息有意義嗎？日誌可觀察嗎？部署可回滾嗎？

### RECONCILE 自評格式

```
Score: X/10
What 10 looks like: [one sentence]
Gap to close: [specific action needed]
```

---

## When to Use

**General Pre-Decision（一般決策前）**:
- General decision challenges that are not governed by a named High-Risk gate
- Early option exploration before a decision reaches downstream commitment
- Draft reasoning where a numeric self-score is useful only as advisory refinement

**Post-Output（輸出完成後）**:
- Output is **high-stakes or externally visible** (code shipped to prod, published reports)
- An **objective rubric or measurable criteria** can be defined upfront
- A **second perspective** is needed beyond linting or syntax checks
- You want to verify that a downstream agent can consume an upstream artifact

## When NOT to Use

- Trivial or low-risk exploratory drafts
- Standard code quality/security review → use `code-review` or `code-security-review`
- Refactoring existing code → use `refactor`
- Simple formatting or lint issues
- A named High-Risk gate decision that requires the rule-based `WORKFLOW.md` conditions rather than scoring

---

## Named High-Risk Gates

`agentic-eval` is risk-adaptive self-evaluation, not independent review. It cannot override test, build, or deterministic failure and never replaces required independent code/security review.
The named High-Risk gates do not use scores or numeric thresholds; they evaluate only the approved rule-based conditions.

- Simple: not required.
- Standard: risk-triggered when an approved condition calls for self-evaluation.
- High-Risk: run only the explicitly named gates below at their canonical lifecycle points, then retain independent review.

| Gate | Canonical purpose |
|---|---|
| Architecture Decision Exit | Challenge irreversible or high-cost architecture, security, permission, data, or public-contract commitment. |
| Pre-Implementation Readiness | Verify approved AC, scope, prerequisites, authorization, recovery, testability, and ownership before High-Risk implementation. |
| Pre-Delivery Verification | Verify deterministic checks, AC evidence, invariants, scope, generated parity, worktree state, and independent-review status before protected delivery. |
| Migration / Deployment Readiness | Verify separately authorized operational scope, rollback/restore/compensation, rehearsal, signals, ownership, and reversibility. |

The full blocking and warning-only conditions are canonical in `WORKFLOW.md`. For these named High-Risk gates:

- deterministic failure is always blocking;
- warning-only findings must be recorded but cannot be promoted to blocking without new evidence matching an approved blocking condition;
- blocking findings must be resolved before the next gate;
- N/A requires an auditable reason; when no operational execution is in scope, record `N/A — no migration or deployment execution is authorized in this Phase.`;
- no aggregate score or numeric threshold applies;
- general-purpose scoring, weighted rubrics, iteration scores, and score thresholds do not apply to the named High-Risk gates.

Any future gate, blocking dimension, or aggregate threshold requires separate approval.

---

## Integration with 6-Stage AI Development Workflow

This skill can be used at any stage where adversarial challenge adds value, subject to the selected execution mode.
Evaluation strictness is **risk-adaptive** and follows the canonical Simple / Standard / High-Risk contract in `WORKFLOW.md`.
It complements the repo's shared `execution-guardrails` layer: guardrails shape behavior **before and during** work, while `agentic-eval` provides on-demand adversarial challenge.

The table below shows **general-purpose usage patterns** for Standard work (advisory, not mandatory). It does not define or replace a named High-Risk gate:

| Stage Transition | Common Use | Tier | Risk Level |
|-----------------|------------|------|------------|
| Before Spec → handoff | spec-agent self-challenge | 1 | Standard when risk-triggered |
| Spec → Plan | plan-agent cross-validation | 1 | Standard when risk-triggered |
| After Plan complete | architect-agent external critique | 2 (Optional) | Standard when risk-triggered |
| Before code-reviewer | coder-agent self-eval | 1 | Standard when risk-triggered |
| Review completeness check | architect-agent meta-review | 1 (Optional) | Standard when risk-triggered |

### General-Purpose Architect-Agent Trigger Conditions

When invoked by `architect-agent` for Standard cross-stage quality arbitration outside the named High-Risk gates:

| Invocation Point | Rubric | Tier | Risk Threshold |
|-----------------|--------|------|----------------|
| After `spec-agent` | `#spec` | 1 | Standard when risk-triggered |
| After `plan-agent` | `#plan` | 1; Tier 2 if ≥2 FAIL | Standard when risk-triggered |
| After `code-reviewer` | `#review` meta-rubric | 1 | Standard when risk-triggered |

**FAIL path**: All PASS → `REVIEW ACCEPTED`. 1 FAIL → targeted re-review. ≥2 FAIL or Financial Precision FAIL → route to coder then full re-review. Max 2 iterations; unresolved → escalate to human.

Even when Tier 2 invokes an external critic, that critic supplies supporting evidence inside the `agentic-eval` self-evaluation workflow. It does not satisfy or replace the independent review required by a named High-Risk gate.

### Subagent Status Protocol

| Status | Meaning |
|--------|---------|
| `DONE` | Completed; no blocking concerns |
| `DONE_WITH_CONCERNS` | Completed; 1+ concerns flagged in output |
| `NEEDS_CONTEXT` | Blocked; awaiting input artifact |
| `BLOCKED` | Hard blocker; requires human decision |

**Guardrail-aware scoring**:
- Use rubric dimensions such as **Assumption Management**, **Simplicity / Overengineering Risk**, **Diff Scope Hygiene**, and **Verification Strength** where they materially affect handoff quality.
- Prefer stage-specific wording rather than a generic global checklist; the same guardrail should look different in brainstorm, plan, code, and review.

**Context isolation rules (apply everywhere):**
- Pass summaries and key excerpts — NEVER full document blobs
- For specs/plans: AC list + constraints, not full text (≤800 words to any critic)
- For code: diff + test result summary, not full file content
- Never include brainstorm conversation history in critic context

See [stage-rubrics.md](./references/stage-rubrics.md) for per-stage rubric dimensions and adversarial prompt templates.

---

## 3-Tier Evaluation Framework

Choose the tier that matches your environment and quality target:

| Tier | Requires | CLI | VS Code | Best For |
|------|----------|-----|---------|----------|
| **1 — Self-Critique** | Nothing | ✅ | ✅ | Quick rubric check |
| **2 — External Critic** | `agent` tool | ✅ rubber-duck or general-purpose | ✅ `runSubagent` + model selection | Adversarial second opinion |
| **3 — Tracked Evaluation** | `agent` + `sql` | ✅ | ❌ (no sql tool) | Multi-iteration history |

---

## Iteration Ceilings (NFR-05)

Two distinct ceilings apply depending on context:

### Stage-Transition Gating Loops (max 2 iterations)

Applies when agentic-eval is used as a **stage gate** — i.e., at any of:
- Spec → Plan handoff (spec-agent self-eval)
- Plan → Code handoff (plan-agent cross-eval)
- Code → Review handoff (coder-agent self-eval)
- Review completeness check (architect-agent meta-review)

**Ceiling**: **max 2 iterations**. After 2 iterations at a stage gate without all dimensions resolving to PASS:
1. Terminate the loop immediately
2. Surface all unresolved FAIL dimensions to the human using this structured format
3. Do NOT initiate a third iteration autonomously

**Structured escalation message (required format):**
```
## ⛔ Stage Gate Blocked — Human Decision Required
Unresolved dimensions after 2 iterations:
- [DIMENSION]: [one-sentence FAIL reason] → [specific line/excerpt as evidence]

Root cause type (pick one per dimension):
  UPSTREAM_GAP   — problem is in the input artifact (spec/brainstorm), not this artifact
  CONTENT_GAP    — this artifact is missing required content
  AMBIGUITY      — rubric cannot resolve without more context from user

Recommended actions:
  A. Fix upstream artifact (UPSTREAM_GAP) → re-run this agent after fix
  B. Add missing content to this artifact (CONTENT_GAP) → targeted edit
  C. Override this FAIL with explicit user approval and stated rationale (last resort)
  D. Stop this work package — revisit requirements
```

**Rationale**: Stage gates must not become infinite loops. 2 iterations provide one self-correction opportunity. If unresolved after 2, human judgment is required — but the human needs structured information to decide, not a raw list of failures.

### General-Purpose Refinement Loops (max 3–5 iterations)

Applies when agentic-eval is used for **non-gate iterative improvement** — e.g.:
- Draft document improvement
- Report quality refinement
- Iterative clarification outside stage transitions

**Ceiling**: **max 3–5 iterations** (Tier 1 self-critique default; adjust based on quality target).

### Summary Table

| Loop Type | Context | Max Iterations | Unresolved Action |
|-----------|---------|---------------|-------------------|
| Stage-transition gate | spec/plan/code/review handoff | **2** | Terminate; surface to human |
| General-purpose refinement | draft improvement, non-gate loops | 3–5 | Stop; output best available |

---

## Tier 1: Self-Critique / Rubric (Always Available)

Define a rubric, score the output, refine on FAIL dimensions. Max 3–5 iterations (general-purpose) or max 2 iterations (stage gate — see NFR-05 above).

**Steps:**
1. Define criteria and score threshold (e.g., 0.8 / 5-point scale)
2. **Adopt adversarial persona before scoring** (required for stage gates):  
   *"You are a skeptical external auditor. Your job is to find problems, not confirm quality. For every dimension you score PASS, state the strongest counter-argument you can. If no counter-argument exists, write 'no counter-argument found'."*  
   This combats Anchoring and RLHF sycophancy bias — LLMs systematically self-score high (7–8/10). The persona switch must precede scoring.
3. Score output against each dimension using structured JSON
4. If any dimension FAIL → refine with targeted feedback; evidence must cite a specific line, hunk, or excerpt — not a general statement
5. Stop when all PASS or max iterations reached

See [Python implementation patterns](./references/python-patterns.md) for code examples.

---

## Tier 2: External Critic via Subagent (Optional — Requires `agent` tool)

Delegate evaluation to a separate subagent using a **different model perspective** for adversarial critique.

**Steps:**
1. Generate output (code, report, design)
2. Extract a focused excerpt or summary — do NOT pass entire blobs; pass key sections, diff, or rubric context
3. Call critic subagent:
   - **CLI — rubber-duck available** (`RUBBER_DUCK_AGENT` flag on): use `task(agent_type: "rubber-duck")`
   - **CLI — no rubber-duck**: use `task(agent_type: "general-purpose")` with adversarial system prompt
   - **VS Code**: use `agent` tool (`runSubagent`); explicitly request a different model in the prompt:
     `"Use [GPT-4o / Claude Haiku] to critique this..."` — model diversity is the key mechanism
4. Parse critique → identify weak points
5. **Goodhart's Law mitigation**: Supplement rubric scoring with at least one user-intent question:  
   > "Ignore the rubric. In one paragraph: what problem does this artifact appear to be solving? Does this match what the user originally requested?"  
   This surfaces drift that structured rubric dimensions cannot catch (model optimizes rubric format at generation time).
6. Refine output targeting identified weaknesses
7. Repeat up to 3 iterations

> ⚠️ **rubber-duck availability (CLI only)**: Requires `RUBBER_DUCK_AGENT` experimental flag.
> Enable via `/experimental on` or `enabledFeatureFlags.RUBBER_DUCK_AGENT: true` in `~/.copilot/config.json`.
> In VS Code or without the flag, use `general-purpose` subagent with adversarial prompt — model diversity
> can be achieved by requesting a specific model different from the main conversation model.

**Context efficiency rules (apply in all environments):**
- For code: pass file path + diff excerpt, not full file content
- For reports: pass the relevant paragraph + evaluation rubric
- For designs/plans: pass key decisions + constraints, not full spec

> ⚠️ **Critic reliability**: A Tier 2 critic is also an LLM and can hallucinate. Treat critic *positive validations* ("X is correct", "function Y exists") as **non-authoritative**. Only critic-identified *gaps and failures* require action. Correctness is confirmed by running code, querying APIs, or consulting authoritative sources — not by asking a critic.

See [Evaluation Workflow](./references/cli-evaluation-workflow.md) for step-by-step guide (CLI + VS Code).

---

## Tier 3: Tracked Evaluation (Optional — Requires `task` + `sql` tools)

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
