# Spec Draft — Workflow Template Optimization

## Problem Statement

The template must become easier to maintain, safer to evolve, and more reliable to deploy into other repositories without increasing hidden drift between source files, runtime mirrors, documentation, and bootstrap surfaces.

## Goals

1. Establish a canonical truth-checking mechanism for repo catalog and change-package contracts.
2. Define a more productized installation/update surface beyond the current interactive bootstrap script.
3. Add a lightweight, repo-persisted handoff memory surface for long-running work.
4. Add deterministic verification capabilities that complement existing agentic-eval quality gates.
5. Preserve the current six-stage workflow and source-of-truth architecture.

## Functional Requirements

| ID | Description | Scope |
|----|-------------|-------|
| FR-01 | Define a canonical source for agent / prompt / skill counts, reconciled across README, AGENTS, and WORKFLOW | A |
| FR-02 | Align change-package contract (file list and rules) between WORKFLOW.md and instructions/changes.instructions.md | A |
| FR-03 | Implement an automated catalog audit script that reports count and contract parity | A |
| FR-04 | Specify target behavior and boundaries for `install-plan` (dry-run list of changes) | B |
| FR-05 | Specify target behavior and boundaries for `install-apply` (execute install-plan) | B |
| FR-06 | Specify minimum install-state representation (JSON manifest, first version) | B |
| FR-07 | Document compatibility contract between new install surface and existing `Init-Project.ps1` | B |
| FR-08 | Specify a `doctor` behavior that checks source vs `.github/**` vs deployed-target parity | B |
| FR-09 | Specify an artifact-free `explore` mode with explicit file-creation trigger conditions | C |
| FR-10 | Specify a deterministic `gate-check` surface with clear `GATE PASSED / GATE PASSED WITH NOTES / GATE FAILED` verdict semantics | C |
| FR-11 | Define the explicit semantic boundary between `gate-check` (deterministic evidence) and `agentic-eval` (model-based rubric) | C |
| FR-12 | Define a standard subagent status reporting protocol: `DONE / DONE_WITH_CONCERNS / NEEDS_CONTEXT / BLOCKED` for use in coder-agent, plan-agent, and architect-agent | C |
| FR-13 | Define a minimal in-repo memory directory structure (`.ai-workflow-memory/`) and update lifecycle rules | D |
| FR-14 | Ensure repo memory feature is explicitly opt-in and non-breaking for existing adopters | D |
| FR-15 | Specify the scope and structure of a systematic debug skill: when to invoke it, what investigation steps to follow, and how to report findings vs. escalate | E |

## Non-Functional Requirements

| ID | Description |
|----|-------------|
| NFR-01 | All changes must preserve the source-of-truth vs `.github/**` runtime mirror model |
| NFR-02 | Template must remain understandable to Copilot-first users without added toolchain complexity |
| NFR-03 | All new surfaces must be brownfield-safe and additive (no rewrites of existing core flows) |
| NFR-04 | Install-state JSON schema must be forwards-compatible (new fields can be added without breaking existing state files) |
| NFR-05 | At **stage-transition quality checkpoints** (spec→plan handoff, code→review handoff), agentic-eval self-review loops must be bounded to maximum **2 iterations** before terminating and escalating to human review. General-purpose agentic-eval quality loops outside stage gates follow the default 3–5 iteration ceiling defined in the agentic-eval skill. |

## Non-Goals

1. Rebuild the whole workflow around native OpenSpec.
2. Expand the agent roster significantly in this change.
3. Fully implement multi-harness distribution in the same iteration.
4. Introduce an external memory service dependency.

## Minimum Scope

### Scope A — Catalog / Contract Alignment
- Align public-facing and maintainer-facing documentation where counts or workflow contracts differ.
- Define the canonical source for agent / prompt / skill counts.
- Define the canonical change-package contract for this repo.

### Scope B — Install Surface Design
- Specify target behavior for `install-plan`, `install-apply`, and `doctor`.
- Define compatibility expectations with `Init-Project.ps1`.
- Define the minimum install-state representation.

### Scope C — Workflow Enhancements
- Specify an artifact-free `explore` mode for investigation before file creation.
- Specify a deterministic `gate-check` surface with explicit verdicts.
- Define a standard subagent status protocol for future agent updates.

### Scope D — Repo Memory Skeleton
- Define a minimal in-repo memory structure and update rules.
- Keep the feature opt-in for adopters.

### Scope E — Debug Skill (Scoped)
- Specify a systematic debug skill: when to invoke it (build failures, unexpected agent output, test failures, drift-related errors), what investigation steps to follow, and how to report findings vs. escalate to human.
- This directly addresses the gap identified in the research report (Superpowers §2): "系統化 debug skill（你現在明顯還缺這一塊）".
- Minimum viable scope: skill spec only; implementation in a later wave if needed.

## Acceptance Criteria

### AC-1 Catalog Truth ← FR-01, FR-03
- A canonical source for counts and workflow contract is documented.
- README, AGENTS, and WORKFLOW no longer contradict each other on core catalog or flow claims.
- Verification:
  - Manual diff review of affected docs
  - Automated audit script result is clean (FR-03)

### AC-2 Change Package Contract ← FR-02, FR-03
- The expected change-package structure is defined consistently across workflow docs and instructions.
- Verification:
  - Compare `WORKFLOW.md` and `instructions/changes.instructions.md`
  - Audit script reports no contract mismatch

### AC-3 Install Surface Spec ← FR-04, FR-05, FR-06, FR-07, FR-08
- The repository defines expected responsibilities and boundaries for `install-plan`, `install-apply`, and `doctor`.
- Minimum install-state representation (JSON manifest) is specified with forwards-compatible schema.
- Compatibility with current bootstrap entrypoint is documented.
- Verification:
  - Design/spec review against current `Init-Project.ps1`
  - JSON schema sample reviewed for forwards-compatibility

### AC-4 Explore Mode Spec ← FR-09
- A no-artifact exploration mode is specified, including when it should and should not create files.
- Explicit trigger condition defined: only `/proceed` or equivalent confirms artifact creation.
- Verification:
  - Skill/spec review

### AC-5 Deterministic Gate-Check Spec ← FR-10, FR-11
- A deterministic verification surface is specified with clear verdict semantics (`GATE PASSED / GATE PASSED WITH NOTES / GATE FAILED`).
- The semantic boundary between `gate-check` and `agentic-eval` is explicitly defined:
  - `gate-check`: deterministic evidence (typecheck, lint, tests, build, drift check) — hard stop on failure
  - `agentic-eval`: model-based rubric loop (AC testability, traceability, financial precision) — quality guidance
  - The two are complementary and must not be conflated or replaced by each other.
- The **execution ordering** of the three verification layers is explicitly defined:
  1. `gate-check` runs first — deterministic hard stop; if GATE FAILED, do not proceed
  2. `agentic-eval` runs second — model-based rubric; bounded to max 2 iterations (NFR-05); escalate to human if not resolved
  3. `code-reviewer-agent` runs third — delegated human or senior-agent review for spec compliance, then code quality (two-stage ordering)
- Verification:
  - Spec review with example verdicts for each verdict category
  - Clear diagram or table showing the three-layer ordering and escalation paths

### AC-6 Repo Memory Spec ← FR-13, FR-14
- A minimal repo memory directory structure and update rules are specified.
- The feature is explicitly opt-in.
- Verification:
  - Spec review of structure and lifecycle rules

### AC-7 Subagent Status Protocol ← FR-12
- A standard subagent status reporting protocol is defined with four states:
  - `DONE`: task completed fully, no concerns
  - `DONE_WITH_CONCERNS`: task completed but issues noted for caller attention
  - `NEEDS_CONTEXT`: blocked waiting for clarifying information from caller
  - `BLOCKED`: cannot proceed; hard blocker that requires human or orchestrator intervention
- Protocol is specified in `coder-agent`, `plan-agent`, and `architect-agent` execution rules.
- Verification:
  - Agent spec review confirms all four states are described with example scenarios
  - At least one agent file is updated with the protocol language

### AC-8 Debug Skill Spec ← FR-15
- A systematic debug skill is specified with:
  - Invocation criteria (when to use: build failures, test failures, unexpected agent behavior, drift errors)
  - Investigation step sequence
  - Output format (findings report vs. escalation trigger)
- Verification:
  - Skill spec review
  - Explicit escalation threshold defined (e.g., after N failed debug cycles, surface to human)

### AC-9 Bounded Self-Review ← NFR-05
- The agentic-eval self-review loop is explicitly documented as bounded to a maximum of 2 iterations.
- After 2 iterations without resolution, the loop must terminate and surface findings to human review rather than continuing to iterate.
- This constraint is documented in the agentic-eval skill and in relevant agent execution rules.
- Verification:
  - agentic-eval skill documentation review confirms the 2-iteration limit
  - At least one agent file references the bounded loop rule

## Constraints

- Preserve current source-of-truth vs `.github/**` runtime mirror model.
- Keep the template understandable to current Copilot-first users.
- Prefer additive, brownfield-safe changes over large rewrites.

## Risks

1. Existing inconsistencies may be broader than the currently observed set.
2. Installer redesign may spill into bundle/profile scope if not tightly bounded.
3. Memory features can overreach quickly if not kept minimal and repo-local.

## Verification Strategy

- Documentation consistency review
- Script-level audit design
- Explicit acceptance-criteria traceability in follow-up plan
- Brownfield-safe implementation in waves, starting with truth alignment
