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
| NFR-05 | At **stage-transition quality checkpoints** — defined as any agentic-eval evaluation that gates progression to the next workflow stage (spec handoff, plan handoff before coding, code handoff before review, and review completeness check) — agentic-eval self-review loops must be bounded to maximum **2 iterations** before terminating and escalating to human review. General-purpose agentic-eval quality loops outside stage gates (e.g., iterative draft improvement) follow the default 3–5 iteration ceiling defined in the agentic-eval skill. |

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
- The repository defines expected responsibilities and boundaries for `install-plan`, `install-apply`, and `doctor`, captured in a new **`docs/install-surface-design.md`**.
- Required content in that design document:
  - `install-plan` output format: human-readable text table; optional `--json` flag for machine-readable output
  - `install-apply` conflict behavior: default **skip-if-exists**; overwrite only with explicit `--force` flag
  - `doctor` output format: **aligned with gate-check verdict semantics** (`DOCTOR PASSED / DOCTOR PASSED WITH NOTES / DOCTOR FAILED`)
  - JSON manifest minimum schema:
    ```json
    { "schema_version": 1, "installed_at": "<ISO-8601-UTC>", "source_ref": "<commit-sha-or-tag>", "components": [] }
    ```
- Compatibility with `Init-Project.ps1` documented: new install surface is **additive**; existing entrypoint preserved as a compatible wrapper.
- Verification:
  - `docs/install-surface-design.md` exists and contains all four design sections above
  - JSON schema sample includes `schema_version: 1` as the first field
  - Compatibility notes reference current `Init-Project.ps1` explicitly

### AC-4 Explore Mode Spec ← FR-09
- A no-artifact exploration mode is specified in a new **`skills/explore/SKILL.md`** (or as a dedicated section in `skills/workflow-orchestrator/SKILL.md` if scoped narrowly), including:
  - When to enter explore mode: requirements not yet clear; codebase investigation needed; option comparison in progress; risk scan before commit
  - While in explore mode: **no files are created** until an explicit artifact commit signal is given
  - Explicit artifact commit triggers (enumerated — not open-ended): user says `/proceed`, `"create change package"`, `"start brainstorm"`, or `"I want to formalize this"`
- Verification:
  - Skill document exists and specifies all three sections above
  - Trigger phrase list is **explicitly enumerated**; phrase "or equivalent" must not appear without an accompanying list

### AC-5 Deterministic Gate-Check Spec ← FR-10, FR-11
- A deterministic verification surface is specified in a new **`skills/gate-check/SKILL.md`** with a reference **`skills/gate-check/scripts/run-gate-check.ps1`** stub, defining clear verdict semantics:
  - `GATE PASSED`: all deterministic checks pass; proceed to next verification layer
  - `GATE PASSED WITH NOTES`: checks pass but with non-blocking warnings; proceed, but notes **must** be logged to the change package (e.g., appended to `02-decision-log.md`)
  - `GATE FAILED`: hard stop; **do not proceed** to agentic-eval or code-reviewer; a human or designated agent must resolve before gate-check is rerun
- The skill specifies the **minimum check set** (each marked as required or conditional on toolchain):
  - TypeScript / PowerShell typecheck (conditional: if configured)
  - Lint (conditional: if linter configured)
  - Tests (conditional: if test suite configured)
  - Build (conditional: if build step configured)
  - Source vs `.github/**` drift check (`sync-dotgithub.ps1` or equivalent)
  - Catalog count parity (FR-03 audit script result)
- The semantic boundary between `gate-check` and `agentic-eval` is explicitly defined:
  - `gate-check`: deterministic evidence (typecheck, lint, tests, build, drift check) — hard stop on FAIL
  - `agentic-eval`: model-based rubric loop (AC testability, traceability, financial precision) — quality guidance
  - The two are complementary and must not be conflated or replaced by each other.
- The **execution ordering** of the three verification layers **at the code→review handoff** is explicitly defined:
  1. `gate-check` runs first — deterministic hard stop; if `GATE FAILED`, stop; do not proceed
  2. `agentic-eval` runs second — model-based rubric; bounded to max 2 iterations (NFR-05); if unresolved after 2 iterations, **escalate to human** before proceeding to code-reviewer
  3. `code-reviewer-agent` runs third — delegated review; two-stage internal ordering (spec compliance before code quality) is a **Wave 5 specification goal** and is **not** required to be implemented in this wave
- **Scope note**: This three-layer ordering applies at the **code→review handoff**. At earlier stage transitions (e.g., spec→plan), agentic-eval is the primary quality gate; gate-check is not required at those earlier transitions unless the repo has a configured check suite.
- Verification:
  - `skills/gate-check/SKILL.md` exists with all verdict definitions, minimum check set, boundary definition, and three-layer ordering
  - `skills/gate-check/scripts/run-gate-check.ps1` stub exists and documents expected check invocations
  - Example verdicts provided for all three categories (at least one concrete example per verdict)
  - Clear table or section showing three-layer ordering, hard-stop conditions, and escalation paths

### AC-6 Repo Memory Spec ← FR-13, FR-14
- A minimal repo memory structure and lifecycle rules are specified in a new **`docs/repo-memory-design.md`**, including:
  - Directory structure:
    ```
    .ai-workflow-memory/
    ├── PROJECT_CONTEXT.md    # stable project overview; updated when context changes significantly
    ├── CURRENT_STATE.md      # current work status; updated at end of each major session
    └── session-journal/      # append-only session records; one file per session (YYYY-MM-DD-<slug>.md)
    ```
  - Update rules: which agent updates which file, at what trigger, and with what minimum content
  - Opt-in mechanism: the `.ai-workflow-memory/` directory is **not created by default**; activation requires one of: explicit `--enable-memory` flag on `install-apply`, or manual directory creation
  - The feature must **not** add any files to `.github/**` mirror — memory remains local to the deploying repo only
- Verification:
  - `docs/repo-memory-design.md` exists with directory structure, update rules, and opt-in mechanism
  - Default behavior (no memory dir created) is explicitly documented
  - `install-surface-design.md` (AC-3) references the `--enable-memory` opt-in flag

### AC-7 Subagent Status Protocol ← FR-12
- A standard subagent status reporting protocol is defined with four states:
  - `DONE`: task completed fully, no concerns
  - `DONE_WITH_CONCERNS`: task completed but issues noted for caller attention
  - `NEEDS_CONTEXT`: blocked waiting for clarifying information from caller
  - `BLOCKED`: cannot proceed; hard blocker that requires human or orchestrator intervention
- Protocol is specified in **all three target agent files**: `agents/coder-agent.md`, `agents/plan-agent.md`, and `agents/architect-agent.md`.
- Verification:
  - All three of `agents/coder-agent.md`, `agents/plan-agent.md`, `agents/architect-agent.md` contain a **"Subagent Status Protocol" section** with all four states and at least one example scenario per state
  - After sync: corresponding `.github/agents/` files also reflect the update (sync-dotgithub.ps1 passes)

### AC-8 Debug Skill Spec ← FR-15
- A systematic debug skill is specified in a new **`skills/debug/SKILL.md`** with:
  - Invocation criteria (when to use: build failures, test failures, unexpected agent behavior, drift errors)
  - Investigation step sequence (ordered steps an agent follows before concluding)
  - Output format (findings report vs. escalation trigger)
- Explicit escalation threshold: after **2 consecutive failed debug cycles** (defined as: attempted a corrective action, reran the failing check, still failed), the debug skill must **terminate the loop** and surface findings to human review. The agent must NOT autonomously initiate a third cycle.
- Verification:
  - `skills/debug/SKILL.md` exists with all four sections above
  - Escalation threshold is stated as a specific number (2 cycles), not a variable placeholder

### AC-9 Bounded Self-Review ← NFR-05
- The `skills/agentic-eval/SKILL.md` is updated to **explicitly distinguish** two iteration ceilings:
  - **Stage-transition gating loops** (any agentic-eval evaluation that gates progression to the next workflow stage — including spec handoff, plan handoff before coding, code handoff before review, and review completeness check): maximum **2 iterations**, then terminate and escalate to human
  - **General-purpose agentic-eval loops** (draft improvement, iterative refinement outside stage gates): maximum **3–5 iterations** (existing ceiling unchanged)
- After 2 iterations at a stage gate without resolution, the loop **must terminate** and surface all unresolved FAIL dimensions to human review. The agent must not continue iterating.
- This constraint is documented in `skills/agentic-eval/SKILL.md` **and** referenced in `agents/coder-agent.md` and `agents/architect-agent.md`.
- Verification:
  - `skills/agentic-eval/SKILL.md` contains a section distinguishing stage-transition (2-iter) from general-purpose (3–5-iter) ceilings
  - `agents/coder-agent.md` references the 2-iteration stage-transition limit explicitly
  - `agents/architect-agent.md` references the 2-iteration stage-transition limit explicitly
  - After sync: all `.github/skills/agentic-eval/` and `.github/agents/` files reflect the update

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
