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
| Risk Classification | 25% | Low/Med/High explicitly stated with rationale |
| Requirements Coverage | 25% | Functional + non-functional requirements captured |
| Option Diversity | 15% | ≥2 meaningfully different solution options documented |
| Assumption Management | 20% | Facts, assumptions, and unknowns are separated; no major hidden assumption drives the recommendation |
| Decision Log | 15% | At least one ADR entry with trade-off rationale |

**Adversarial prompt template (self-eval only):**
> "Review the brainstorm output. Identify any requirements that seem implied but are NOT explicitly stated.
> Flag any options that are essentially the same approach reworded. Confirm the risk classification
> is defensible. Call out any hidden assumption that materially changes the recommendation. Reply with PASS or FAIL per dimension with a one-sentence rationale."

---

## #spec

**Evaluation model**: Tier 1 self-check (spec-agent) + Tier 1 cross-check (plan-agent reads spec).
**Who evaluates**:
- spec-agent: Output Quality Self-Check before handoff
- plan-agent: Spec Evaluation Before Planning (verifies implementability)

| Dimension | Weight | PASS Criteria |
|-----------|--------|---------------|
| AC Testability | 20% | Every AC has a concrete, verifiable success condition |
| Scope Boundary | 15% | In-scope / out-of-scope explicitly listed |
| Traceability | 15% | Each requirement has a unique ID (FR-XXX / NFR-XXX) |
| Assumption Exposure | 15% | Assumptions, unresolved questions, and non-goals are explicitly separated from requirements |
| Requirement Provenance | 15% | Every FR-XXX references its originating source: a user statement, brainstorm ADR, or explicit user approval. Requirements with no traceable source are flagged as Source Fabrication risk |
| Financial Precision | 20% | No float types mentioned for money fields; minor-unit or string specified *(skip if domain is non-financial per PROJECT_CONTEXT.md or 00-intake.md)* |

**FAIL → handoff blocked** if: AC Testability FAIL OR Traceability FAIL OR Requirement Provenance FAIL OR Financial Precision FAIL *(financial domain only)*.

**Adversarial prompt (plan-agent cross-eval):**
> "Read only the AC list and constraints below. For each AC, answer: can I write a concrete
> implementation plan step that satisfies this AC without ambiguity? Flag any AC that is
> too vague to plan against. Identify any hidden assumption masquerading as a requirement.
> Flag any requirement that appears to have no traceable source in user input or brainstorm output.
> Reply with per-AC PASS/FAIL and a gap description for FAILs."
>
> [Insert: AC list, constraint summary, confirmed requirements summary ≤200 words — NOT full spec document]

**User-intent validation (Goodhart's Law mitigation — use alongside rubric):**
> "Ignore the rubric for a moment. In one paragraph, describe what problem this spec appears to be solving.
> Then answer: does this match what the user originally requested? List any content that seems to go beyond or diverge from the original request."

---

## #plan

**Evaluation model**: Tier 1 cross-check (plan-agent self + spec consistency) → Tier 2 architect external (Med/High risk).
**Who evaluates**:
- plan-agent: Spec Evaluation Before Planning (at start), then self-check after plan
- architect-agent: External Tier 2 evaluation for Med/High risk plans

| Dimension | Weight | PASS Criteria |
|-----------|--------|---------------|
| Spec AC Coverage | 30% | Every FR-ID in spec appears in at least one plan step |
| Step Verifiability | 25% | Every step has a stated verification method. Steps referencing a specific library function, API endpoint, or external service mark it `[VERIFIED]` (existence confirmed) or `[UNVERIFIED]` (unconfirmed). `[UNVERIFIED]` items are captured in a `## Unverified References` section |
| Dependency Order | 15% | No circular dependencies; dependencies are explicit |
| Assumption Management | 15% | Plan-specific assumptions are explicit and localized. All state prerequisites plan steps depend on (e.g., "Phase 0 schema is ready") are marked `[VERIFIED: <evidence>]` or `[ASSUMED: <unverified>]`. No hidden state dependency invalidates multiple steps |
| Simplicity / Scope Discipline | 15% | Plan stays within current spec scope; no speculative architecture or future-proofing work is introduced without justification |

**Adversarial prompt (architect Tier 2 eval):**
> "You are an adversarial reviewer. Review this plan excerpt and AC list.
> Identify: (1) Any spec requirement NOT covered by a plan step.
> (2) Any plan step with no verifiable outcome. (3) Any implicit assumption that,
> if wrong, would invalidate multiple steps. (4) Any step that adds speculative scope or architecture
> not demanded by the current spec. (5) List all specific library functions, API endpoints, or service
> integrations referenced in plan steps; state your confidence each exists: HIGH / MEDIUM / UNVERIFIED.
> Respond PASS/FAIL per dimension. Do NOT suggest rewrites — only identify gaps."
>
> [Insert: plan steps summary + AC list — max 800 words total]

---

## #code

**Evaluation model**: Tier 1 self-check only (coder-agent). Code-reviewer is the independent Tier 2.
**Who evaluates**: coder-agent Pre-Review Self-Evaluation before handoff to code-reviewer.

| Dimension | Weight | PASS Criteria |
|-----------|--------|---------------|
| Green Build | 25% | All tests pass; no skipped/pending tests |
| Financial Precision | 20% | `grep -rn "float\|double" src/` returns no money-related hits *(skip if domain is non-financial per PROJECT_CONTEXT.md or 00-intake.md)* |
| Spec AC Coverage | 20% | Every FR-ID has a corresponding test (not just code path) |
| Diff Scope Hygiene | 15% | The diff contains no unrelated edits; any unused imports/variables were created by this change and are cleaned up |
| Simplicity / Overengineering Risk | 10% | The implementation uses the smallest viable design; no speculative abstraction appears without current need |
| Environment Compatibility | 10% | No Linux-only commands; no hardcoded paths or credentials |

> 🔴 **Financial Precision FAIL (financial domain only) → STOP and fix before any other action.**
> All other FAILs: fix targeting the failed dimension only, then re-score.

**Self-eval prompt template:**
> "Review the following diff and test output. Score each dimension PASS or FAIL with evidence.
> Evidence must be a specific line number, diff hunk, or grep result — not a general statement.
> Explicitly flag any unrelated edit or speculative abstraction."
>
> [Insert: git diff + pytest/test output tail — NOT full file content]

---

## #review

**Evaluation model**: Tier 1 meta-check (architect-agent, High-risk only) after code-reviewer completes.
**Who evaluates**: architect-agent checks whether the review itself is sufficiently thorough.

| Dimension | Weight | PASS Criteria |
|-----------|--------|---------------|
| Severity Coverage | 30% | At least one finding per severity level if applicable (🔴/🟡/🟢) |
| Financial Rule Enforcement | 25% | Float/money issues explicitly called out or confirmed absent |
| Spec Alignment | 15% | Review references spec AC IDs where relevant |
| Scope Discipline | 15% | Review calls out hidden assumptions, unrelated edits, or overengineering when present |
| Actionability | 15% | Every issue has a suggested fix, not just a description |

**Adversarial meta-prompt (architect Tier 1):**
> "Review this code-reviewer report. Identify: (1) Any severity category with zero findings
> when the diff suggests otherwise. (2) Any money-related code change NOT addressed by
> financial precision checks. (3) Any hidden-assumption / overengineering / unrelated-edit issue
> in the diff that the review ignored. (4) Any finding without a concrete actionable suggestion.
> Reply PASS/FAIL per dimension. If all PASS, output 'REVIEW ACCEPTED'."
>
> [Insert: review report summary + diff stat — NOT full code files]

---

## Context Isolation Reference

| What to pass to critic | What to NEVER pass |
|------------------------|--------------------|
| AC list + constraint summary (≤800 words) | Full spec document |
| git diff + test output tail | Full source file content |
| Plan step list + risk flags | Full brainstorm conversation history |
| Review findings summary | Full file tree or directory listing |
| Specific rubric dimensions to evaluate | Unrelated context from other stages |
| Confirmed requirements summary ≤200 words *(exception for Requirement Provenance checking)* | |

**Exception for Requirement Provenance (BLK-1):** A confirmed requirements summary (≤200 words), generated by brainstorm-agent at session end and stored in `01-brainstorm.md`, MAY be passed to spec-agent and its cross-evaluator to verify that spec requirements trace back to actual user input. This is the ONLY brainstorm artifact that may be passed to a downstream critic.
