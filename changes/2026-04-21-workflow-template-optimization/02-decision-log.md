# Decision Log

## 2026-04-21 — Adopt Foundation-First optimization path for the workflow template
- Decision:
  - Use a staged optimization strategy centered on governance and platform foundations before larger workflow productization.
  - Prioritize: document/catalog alignment, catalog audit, install surface planning, repo-persisted memory skeleton, and deterministic gate-check.
- Rationale:
  - The current repository already shows contract drift between README, AGENTS, WORKFLOW, and change-package rules.
  - Research indicates the highest-leverage upgrades are not more agents, but better install/update surfaces, memory handoff, and deterministic verification.
  - Brownfield-safe evolution favors tightening source-of-truth first, then extending the platform.
- Trade-offs:
  - Slower visible feature expansion in the short term.
  - Requires touching both user-facing docs and maintainer-facing tooling before adding larger new capabilities.
- Risks:
  - Cross-file alignment work may reveal more undocumented drift than expected.
  - Adding audit and doctor surfaces may force clarification of ambiguous current behavior.
  - If scope expands to profiles/dist too early, this workstream may become too broad for one change package.

## 2026-04-21 — Resolve open architectural questions and unblock spec handoff
- Context:
  - `02-decision-log.md` previously recorded `SPEC HANDOFF BLOCKED` due to missing FR/NFR traceability IDs and unresolved open questions.
  - `03-spec.md` has been updated to add explicit `FR-01` through `FR-14` and `NFR-01` through `NFR-04` requirement IDs, each mapped to its acceptance criterion.
- Open question resolutions:
  - **Install state format**: Adopt **JSON manifest** first. SQLite upgrade deferred to a future wave if query/analytics become needed. Rationale: lower adoption friction; forwards-compatible schema is sufficient for this iteration.
    - **Forward-compatibility requirement**: JSON schema must include a `schema_version` field from the first version to ensure future upgrade paths remain viable.
  - **Gate-check mode**: First version will produce **deterministic report + explicit verdict** (`GATE PASSED / GATE PASSED WITH NOTES / GATE FAILED`). Hard-stop enforcement (blocking handoff/merge) deferred to a follow-up iteration once the report surface is validated.
    - **Graduation criteria for hard-stop**: enforcement upgrades when (a) the check has produced clean results across at least 2 delivery waves without false positives, OR (b) a maintainer explicitly sets `gate-check.strict = true` in repo config. This criteria must be documented at implementation time to prevent report-only mode becoming a permanent state.
  - **Subagent status protocol**: Added as `FR-12` / `AC-7` in `03-spec.md`. First target agents: coder-agent, plan-agent, architect-agent.
  - **Two-stage review ordering** (Superpowers): Captured as Wave 5 in `01-brainstorm.md`. Deferred after gate-check is available. Decision: do not apply this ordering yet; gate-check establishes the spec-compliance evidence that review ordering relies on.
  - **Git worktree isolation** (Superpowers): Deferred to Wave 5 evaluation. Not in scope for this change package.
  - **Profile/preset/dist layer**: Explicitly not in this iteration's scope. Future wave noted in `01-brainstorm.md`. The core six-stage flow and source/runtime model must be stable before introducing a distribution layer.
- Traceability gate status:
  - **SPEC HANDOFF UNBLOCKED** — `03-spec.md` now contains explicit FR/NFR IDs and each AC maps to one or more requirement IDs.
- Trade-offs:
  - JSON state is less queryable than SQLite but substantially simpler to ship and adopt.
  - Report-only gate-check is less powerful as a hard stop but reduces adoption risk in the first wave.
  - Deferring worktree and profile layer keeps this change package convergent.

## 2026-04-21 — Add three missing research-report insights to spec
- Trigger: cross-reference of research report vs spec revealed three genuine gaps not yet addressed.
- Gap 1 — Systematic debug skill (FR-15 / AC-8):
  - Research report (Superpowers §2) explicitly stated "系統化 debug skill（你現在明顯還缺這一塊）".
  - Decision: add as Scope E with a spec-only deliverable for this wave; full skill implementation deferred.
  - Rationale: spec the capability now so the plan-agent can size it; don't implement until foundation waves are stable.
- Gap 2 — Bounded self-review loop (NFR-05 / AC-9):
  - Research report (dev-process-toolkit §3) specified: self-review loop must be bounded, maximum 2 iterations before escalating to human.
  - Decision: encode as NFR-05 immediately; apply to agentic-eval skill documentation and relevant agent files.
  - Rationale: unbounded model judgment cycles are a governance risk; this is a low-cost rule with high safety value.
- Gap 3 — Three-layer verification ordering (AC-5 strengthened):
  - Research report defined: gate-check → spec compliance review → code quality review (not the reverse).
  - Decision: embed the ordering (gate-check → agentic-eval ≤2 iterations → code-reviewer-agent) into AC-5 rather than deferring to Wave 5.
  - Rationale: the ordering is a property of the spec, not just an implementation detail; defining it now prevents misuse of the gate and review surfaces.
- Delta spec pattern (OpenSpec): noted as future design consideration; not added as a requirement this wave.
  - Reason: delta specs require a `specs/` vs `changes/` architecture refactor — too broad for this change package.

## 2026-04-21 — Architect evaluation of brainstorm/spec planning maturity
- Context:
  - Evaluated `01-brainstorm.md` and `03-spec.md` against the `agentic-eval` stage rubrics for `#brainstorm` and `#spec`.
  - Objective: determine whether this change package is ready to hand off into implementation planning.
- Brainstorm rubric result:
  - Risk Classification: PASS — high risk and standard path are explicit, with brownfield rationale and impact surface stated.
  - Requirements Coverage: PASS — the brainstorm captures governance, install surface, memory, gate-check, constraints, and non-goals.
  - Option Diversity: PASS — Options A/B/C are meaningfully different in scope and sequencing, not simple rewordings.
  - Decision Log: PASS — the chosen foundation-first path and trade-offs are recorded in this file.
- Spec rubric result:
  - AC Testability: PASS — `03-spec.md` defines AC-1 through AC-6 with verification directions that are sufficient to derive planning steps.
  - Scope Boundary: PASS — goals, non-goals, minimum scope, and constraints are explicitly separated.
  - Traceability: FAIL — requirements are not yet normalized into unique `FR-XXX` / `NFR-XXX` identifiers, so downstream plan-to-spec mapping would be weaker than the repo's desired audit standard.
  - Financial Precision: PASS — this change is workflow/platform governance work and does not define money fields or float-based financial contracts.
- Synthesis:
  - Planning maturity is **substantial but not yet plan-ready for formal handoff**.
  - The change package is directionally strong and architecturally coherent, but the current spec still fails the traceability gate for a high-risk item.
- Required next refinement before plan handoff:
  - Add explicit `FR-XXX` / `NFR-XXX` requirement IDs to `03-spec.md`.
  - Map each acceptance criterion to those requirement IDs.
  - Convert the main open architectural choices from `01-brainstorm.md` into either decided constraints or explicitly bounded plan-time decisions.
- Handoff status:
  - `SPEC HANDOFF BLOCKED` until traceability is added and the remaining architectural decision points are normalized.
