---
name: agentic-eval
description: >
  Patterns and techniques for evaluating and improving AI agent outputs through
  iterative critique and refinement. Use this skill when:
  implementing self-critique loops, evaluator-optimizer pipelines,
  rubric-based scoring, LLM-as-judge evaluation, adversarial evaluation,
  judge-and-refine cycles, structured output quality improvement,
  cross-agent evaluation, plan quality review, spec validation before planning,
  document consistency checking, stage transition quality gate,
  architect review of plan or spec, verifying a downstream agent can consume
  an upstream artifact, or inter-stage artifact consistency checks.
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

## Integration with 6-Stage AI Development Workflow

This skill integrates at specific **quality inflection points** where context isolation provides value.
Evaluation strictness is **risk-adaptive** — tied to the brainstorm-agent's Low/Med/High classification.
It complements the repo's shared `execution-guardrails` layer: guardrails shape behavior **before and during** work, while `agentic-eval` scores whether an artifact is safe to hand off.

| Stage Transition | Trigger Agent | Tier | Risk Level |
|-----------------|---------------|------|------------|
| Before Spec → handoff | spec-agent (self) | 1 | All |
| Spec → Plan | plan-agent (cross-eval) | 1 | Med / High |
| After Plan complete | architect-agent (external) | 2 | Med / High |
| Before code-reviewer | coder-agent (self) | 1 | All |
| Review completeness check | architect-agent (meta-review) | 1 | High only |

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

## Tier 2: External Critic via Subagent (Requires `agent` tool)

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
