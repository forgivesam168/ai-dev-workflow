# Stage-Specific Evaluation Rubrics

Per-stage rubric dimensions, scoring criteria, and adversarial prompt templates for the
6-Stage AI Development Workflow. Use alongside `agentic-eval` skill to apply targeted critique
at each quality inflection point.

---

## #brainstorm

**Evaluation model**: Tier 1 self-check only (no external critic — preserve divergent thinking).
**Who evaluates**: brainstorm-agent itself, at end of session.

| Dimension | Weight | PASS Criteria |
|-----------|--------|---------------|
| Risk Classification | 30% | Low/Med/High explicitly stated with rationale |
| Requirements Coverage | 30% | Functional + non-functional requirements captured |
| Option Diversity | 20% | ≥2 meaningfully different solution options documented |
| Decision Log | 20% | At least one ADR entry with trade-off rationale |

**Adversarial prompt template (self-eval only):**
> "Review the brainstorm output. Identify any requirements that seem implied but are NOT explicitly stated.
> Flag any options that are essentially the same approach reworded. Confirm the risk classification
> is defensible. Reply with PASS or FAIL per dimension with a one-sentence rationale."

---

## #spec

**Evaluation model**: Tier 1 self-check (spec-agent) + Tier 1 cross-check (plan-agent reads spec).
**Who evaluates**:
- spec-agent: Output Quality Self-Check before handoff
- plan-agent: Spec Evaluation Before Planning (verifies implementability)

| Dimension | Weight | PASS Criteria |
|-----------|--------|---------------|
| AC Testability | 30% | Every AC has a concrete, verifiable success condition |
| Scope Boundary | 25% | In-scope / out-of-scope explicitly listed |
| Traceability | 25% | Each requirement has a unique ID (FR-XXX / NFR-XXX) |
| Financial Precision | 20% | No float types mentioned for money fields; minor-unit or string specified |

**FAIL → handoff blocked** if: AC Testability FAIL OR Traceability FAIL OR Financial Precision FAIL.

**Adversarial prompt (plan-agent cross-eval):**
> "Read only the AC list and constraints below. For each AC, answer: can I write a concrete
> implementation plan step that satisfies this AC without ambiguity? Flag any AC that is
> too vague to plan against. Reply with per-AC PASS/FAIL and a gap description for FAILs."
>
> [Insert: AC list, constraint summary — NOT full spec document]

---

## #plan

**Evaluation model**: Tier 1 cross-check (plan-agent self + spec consistency) → Tier 2 architect external (Med/High risk).
**Who evaluates**:
- plan-agent: Spec Evaluation Before Planning (at start), then self-check after plan
- architect-agent: External Tier 2 evaluation for Med/High risk plans

| Dimension | Weight | PASS Criteria |
|-----------|--------|---------------|
| Spec AC Coverage | 35% | Every FR-ID in spec appears in at least one plan step |
| Step Verifiability | 25% | Every step has a stated verification method (test, assertion, or manual check) |
| Dependency Order | 20% | No circular dependencies; dependencies are explicit |
| Risk Identification | 20% | Each High-complexity step has a noted risk or mitigation |

**Adversarial prompt (architect Tier 2 eval):**
> "You are an adversarial reviewer. Review this plan excerpt and AC list.
> Identify: (1) Any spec requirement NOT covered by a plan step.
> (2) Any plan step with no verifiable outcome. (3) Any implicit assumption that,
> if wrong, would invalidate multiple steps. Respond PASS/FAIL per dimension.
> Do NOT suggest rewrites — only identify gaps."
>
> [Insert: plan steps summary + AC list — max 800 words total]

---

## #code

**Evaluation model**: Tier 1 self-check only (coder-agent). Code-reviewer is the independent Tier 2.
**Who evaluates**: coder-agent Pre-Review Self-Evaluation before handoff to code-reviewer.

| Dimension | Weight | PASS Criteria |
|-----------|--------|---------------|
| Green Build | 30% | All tests pass; no skipped/pending tests |
| Financial Precision | 25% | `grep -rn "float\|double" src/` returns no money-related hits |
| Spec AC Coverage | 25% | Every FR-ID has a corresponding test (not just code path) |
| Dead Code Absence | 10% | No unused imports/variables in the diff |
| Environment Compatibility | 10% | No Linux-only commands; no hardcoded paths or credentials |

> 🔴 **Financial Precision FAIL → STOP and fix before any other action.**
> All other FAILs: fix targeting the failed dimension only, then re-score.

**Self-eval prompt template:**
> "Review the following diff and test output. Score each dimension PASS or FAIL with evidence.
> Evidence must be a specific line number or grep result — not a general statement."
>
> [Insert: git diff + pytest/test output tail — NOT full file content]

---

## #review

**Evaluation model**: Tier 1 meta-check (architect-agent, High-risk only) after code-reviewer completes.
**Who evaluates**: architect-agent checks whether the review itself is sufficiently thorough.

| Dimension | Weight | PASS Criteria |
|-----------|--------|---------------|
| Severity Coverage | 35% | At least one finding per severity level if applicable (🔴/🟡/🟢) |
| Financial Rule Enforcement | 30% | Float/money issues explicitly called out or confirmed absent |
| Spec Alignment | 20% | Review references spec AC IDs where relevant |
| Actionability | 15% | Every issue has a suggested fix, not just a description |

**Adversarial meta-prompt (architect Tier 1):**
> "Review this code-reviewer report. Identify: (1) Any severity category with zero findings
> when the diff suggests otherwise. (2) Any money-related code change NOT addressed by
> financial precision checks. (3) Any finding without a concrete actionable suggestion.
> Reply PASS/FAIL per dimension. If all PASS, output 'REVIEW ACCEPTED'."
>
> [Insert: review report summary + diff stat — NOT full code files]

---

## Context Isolation Reference

| What to pass to critic | What to NEVER pass |
|------------------------|--------------------|
| AC list + constraint summary (≤800 words) | Full spec document |
| git diff + test output tail | Full source file content |
| Plan step list + risk flags | Brainstorm conversation history |
| Review findings summary | Full file tree or directory listing |
| Specific rubric dimensions to evaluate | Unrelated context from other stages |
