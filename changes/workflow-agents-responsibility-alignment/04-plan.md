# 04 Plan — Workflow–AGENTS Responsibility Alignment

## Plan Status

- **Status**: Phase 4A local implementation verified; PR pending; Phase 4 overall partially implemented; writer enablement, migration, prune, and real-adopter execution not authorized
- **Task/status SSOT**: This file
- **External tracker**: None
- **Execution rule**: One phase requires separate user approval, implementation, verification, review, and PR boundary before the next phase begins.
- **Current active phase**: Phase 4A — Manifest v3 Reader-First Foundation

## Phase Status Summary

| Phase | Status | Separate approval | Separate PR |
|---|---|---|---|
| 0A — Adopter constitution containment | Merged | Required | Required |
| 0B — Bash update safety | Merged | Required | Required |
| 0C — Manifest parse safety containment | Merged | Required | Required |
| 0D — Archive authorization containment | Merged | Required | Required |
| 1 — AGENTS / WORKFLOW / risk contract | Merged | Required | Required |
| 2 — Agent / Skill / Prompt / Instruction alignment | Merged | Required | Required |
| 3 — Change Package / Review / Archive semantics | Merged | Required | Required |
| 4 — Manifest / provenance / stale-derived migration | In progress / partially implemented: Schema approved and Proposal PR #11 merged; Phase 4A local implementation verified and PR pending; Phase 4B, writer enablement, migration, and prune not authorized | Required | Required |
| 5 — Cross-CLI evidence and adapter proposal | Pending | Required | Evidence PR before implementation PR |
| 6 — Bash deprecation completion | Pending | Required | Required |

## Global Sequencing Rules

1. Do not combine C-01 through C-06 into one implementation PR.
2. Phase 0 containment must not pre-empt Phase 4 schema design.
3. Canonical files change before synchronized/generated output.
4. Generated output is produced only by the repository generator after canonical review.
5. Existing adopter migration must be validated by class: new, untouched, customized, legacy.
6. D-10 evidence must be approved before adapter implementation.
7. Every phase records rollback, compatibility, observed test evidence, and unresolved uncertainty.
8. Phase 0C and Phase 0D require separate approval, implementation, verification, review, and PR; neither phase may absorb the other's defect or files.
9. Phase 3 lifecycle distribution cannot begin until the adopter-facing lifecycle source design is reviewed and approved.

## Phase 0A — Adopter Constitution Distribution Containment

### Objective

Stop maintainer constitution leakage and make the adopter constitution source explicit without redesigning manifest lineage.

### Decisions and Defects

- D-02
- C-01

### Prerequisites

- Explicit user approval for Phase 0A.
- Confirm branch and clean worktree.
- Reconfirm actual bootstrap source mapping and existing preservation behavior.

### Exact Scope

- Wire new adopter installation to `docs/copilot-instructions.template.md` or an explicitly reviewed adopter source.
- Preserve existing adopter `.github/copilot-instructions.md` by default.
- Permit an existing untouched migration only when a trusted existing manifest records a verifiable previous managed baseline for that exact constitution component and current content equals it.
- Treat absent component baseline, missing/corrupt/unsupported manifest, unclear source identity, similarity-only evidence, reconstructed/guessed baseline, customization, and unknown legacy ownership as ineligible for automatic update: preserve → report → manual decision.
- Report customized/legacy state and require manual decision.
- Add diagnostics that identify the selected constitution source and preservation outcome.

### Expected Canonical Files

- `docs/copilot-instructions.template.md`
- `scripts/bootstrap.py`
- `scripts/bootstrap.ps1`
- Installer tests
- Distribution documentation directly required by the change

### Expected Generated Files

- None unless canonical maintainer source under the normal sync map changes.
- Adopter fixture outputs in test temporary directories only.

### Bootstrap / Manifest Impact

- Bootstrap source mapping changes.
- No manifest schema redesign.
- Existing ownership/status fields may only be used as currently proven.

### Migration Classes

- New: install corrected adopter constitution.
- Untouched: update only with exact-component baseline proof from an existing trusted manifest and current-baseline equality.
- Customized: preserve/report.
- Legacy: preserve/report; no inferred migration.

### Required Tests

- New adopter content equals adopter source.
- Maintainer-only sync/catalog text absent.
- Existing identical baseline handling.
- Customized and unknown files preserved.
- Python/PowerShell behavior parity.

### Rollback

Revert only the Phase 0A source-mapping commit/PR. Existing adopter files must remain unchanged by rollback because no unsafe migration is permitted.

### Hard Exclusions

- No manifest schema change.
- No Agent/Skill/Workflow rewrite.
- No automatic customized/legacy migration.
- No Bash work.

### Approval and PR Boundary

Separate user approval and separate PR required. Stop after verification and review.

### Observed Evidence

- PR #4
- Squash merge SHA: `a0628198c3ac338c19b428b09f0b502d9fbd57da`
- Python: 63 passed
- Pester: 43 passed
- Remote CI: success

## Phase 0B — Bash Update Safety and Deprecation

### Objective

Prevent `bootstrap.sh --update` from modifying existing adopters and establish Python as the supported Linux/macOS path.

### Decisions and Defects

- D-11
- C-02

### Prerequisites

- Explicit user approval for Phase 0B.
- Confirm supported Python command and documentation surface.

### Exact Scope

- Reject Bash `--update` before sync or file writes.
- Display actionable deprecation warning.
- Direct Linux/macOS users to the Python installer.
- Stop parity claims.
- Define current support matrix.
- Preserve only a narrowly documented initial-install path if explicitly retained.

### Expected Canonical Files

- `scripts/bootstrap.sh`
- Installer/support documentation
- Bash behavior tests or deterministic shell checks

### Expected Generated Files

- None.

### Bootstrap / Manifest Impact

- Bash stops acting as an updater.
- No manifest change.
- Python/PowerShell implementation unchanged.

### Migration Classes

- Existing Bash adopter: migration guidance to Python.
- New Linux/macOS adopter: Python is primary.
- Unknown/legacy: no Bash update attempt.

### Required Tests

- `bootstrap.sh --update` exits nonzero before writes.
- Deprecation and Python guidance are emitted.
- Initial-install behavior, if retained, emits warning.
- Worktree/fixture invariance on refused update.

### Rollback

Restore the previous Bash entry point only if the deprecation blocks a documented supported path; do not restore unsafe update without a new explicit decision.

### Hard Exclusions

- No full Bash parity rewrite.
- No Python/PowerShell redesign.
- No adopter migration execution.

### Approval and PR Boundary

Separate user approval and separate PR required.

### Observed Evidence

- PR #5
- Final head: `29fa8ca7fcf8762ec5f16e9290ca5d9b9fe026b6`
- Squash merge SHA: `66c88ac895eff12d223c1895a44ab949bba949d2`
- Targeted Bash contract tests: `python -m pytest scripts/tests/test_bootstrap.py -q -k phase0b` → 13 passed
- Full Python bootstrap tests: `python -m pytest scripts/tests/test_bootstrap.py -q` → 76 passed
- Pester: 43 passed
- Bash syntax: `bash -n scripts/bootstrap.sh` → pass
- Full gate: `pwsh -NoProfile -File .\skills\gate-check\scripts\run-gate-check.ps1` → pass
- Remote Verify Change Package: success
- Remote verify-sync Windows: success
- Remote verify-sync Ubuntu: success

## Phase 0C — Manifest Parse Safety Containment

### Objective

Contain C-04 by making update failure safe before broader manifest schema redesign.

### Decisions and Defects

- D-06 failure policy only
- C-04

### Prerequisites

- Phase 0C approval.
- Confirm exact Python and PowerShell update-mode entry points.

### Exact Scope

- Hard stop update when an existing manifest is corrupt or unsupported.
- Preserve warning/report-only behavior for a genuinely missing legacy manifest.
- Maintain Python/PowerShell parity.
- Ensure no managed-file write occurs after manifest failure is detected.

### Expected Canonical Files

- `scripts/bootstrap.py`
- `scripts/bootstrap.ps1`
- Focused tests

### Expected Generated Files

- None.

### Bootstrap / Manifest Impact

- Loader returns an explicit parse state/error instead of empty provenance during update.
- No new schema fields emitted.

### Migration Classes

- Valid v1/v2: unchanged.
- Missing legacy manifest: report-only.
- Corrupt/unsupported: hard stop.

### Required Tests

- Corrupt JSON and unsupported schema stop before writes in both installers.
- Missing manifest is distinct from parse failure.
- Focused before/after assertions prove no managed-file write occurs after failure.

### Rollback

Revert containment changes without changing manifests or adopter content.

### Hard Exclusions

- No schema redesign.
- No new manifest fields.
- No migration execution.
- No stale-output reconciliation.
- No Archive work.

### Approval and PR Boundary

Separate user approval, implementation, verification, review, and PR required.

### Observed Evidence

- RED targeted Pester: 11 total, 1 passed, 10 failed, 0 skipped, 0 not run; failed tests covered local scope, approval boundary, protected-action list, safe stop/handoff, executable command scan, legacy imperatives, Prompt privilege signal, WORKFLOW mapping, preserved semantics, and local documentation scope.
- GREEN targeted Pester 5.6.1: 11 total, 11 passed, 0 failed, 0 skipped, 0 not run.
- Full Pester 5.6.1 (`scripts` + `tools`): 67 total, 67 passed, 0 failed, 0 skipped, 0 not run.
- Python regression (`python -m pytest scripts/tests/test_bootstrap.py -q -p no:cacheprovider`): 89 passed, 0 failures, 0 errors.
- Protected-command scan: pass; no executable protected command examples in canonical Skill or Prompt.
- Canonical/derived parity: pass; Archive Skill and Prompt mirrors are byte-for-byte equal.
- `check-sync.ps1`: pass.
- `audit-catalog.ps1`: pass; catalog total=35, adopter=34, maintainer-only=1.
- Full repository gate: pass, overall exit code 0; Python PASS, Pester PASS, sync PASS, catalog PASS, `git diff --check` PASS, worktree invariance PASS. Initial environment-only Pester discovery failure was resolved by exposing the existing cached Pester module through process-local `PSModulePath`; no repository file changed.
- Independent read-only review: 0 Critical, 0 High, 0 Medium, 0 Low; reviewer allowed local commit and made no changes.
- Scope audit: 6 allowed tracked files modified plus `tools/archive-authorization.Tests.ps1` as the only untracked file; no Archive artifact, `CHANGELOG.md`, `docs/WORK_LOG.md`, Manifest/bootstrap, Agent/Instruction, GitHub Actions, or unrelated derived output changed.

### Observed Evidence

- PR #6
- Final head: `2b40fed37d5c0ed755f76720471eeedf7808627f`
- Squash merge SHA: `d7dc6058573c08b04fffafb685cac79e22db9d83`
- Remote Verify Change Package: success
- Remote verify-sync Ubuntu: success
- Remote verify-sync Windows: success

### Historical Phase 0C Verification Evidence

- Python targeted: `python -m pytest scripts/tests/test_bootstrap.py -q -k phase0c` → 13 passed
- Python full: `python -m pytest scripts/tests/test_bootstrap.py -q` → 89 passed
- Pester targeted (`Phase 0C manifest parse safety`): 13 passed
- Pester full (`scripts/bootstrap.Tests.ps1`): 46 passed
- Phase 0B regression: `python -m pytest scripts/tests/test_bootstrap.py -q -k phase0b` → 13 passed
- Python compile: `python -m py_compile scripts/bootstrap.py` → pass
- PowerShell parser syntax: `scripts/bootstrap.ps1` → pass
- Full gate: `pwsh -NoProfile -File .\skills\gate-check\scripts\run-gate-check.ps1` → pass
- check-sync: pass
- audit-catalog: pass
- Worktree invariance: pass
- Independent read-only review: 0 Critical, 0 High, 0 Medium; one diagnostic-ordering Low resolved and two test-coverage Low findings remain non-blocking.

## Phase 0D — Archive Authorization Containment

### Objective

Contain C-06 by removing any implication that Archive grants Git or remote authority, without changing lifecycle semantics.

### Decisions and Defects

- D-08 authorization boundary only
- C-06

### Prerequisites

- Phase 0D approval.
- Confirm Archive Skill and Prompt invocation surfaces.

### Exact Scope

- Remove all implication that Archive itself authorizes Git or remote writes.
- Require separate task-scoped authorization for commit, push, tag, merge, branch deletion, or remote issue/PR closure.
- Preserve current Archive filenames and lifecycle timing until Phase 3.

### Expected Canonical Files

- `skills/work-archiving/SKILL.md`
- Archive Prompt
- Focused tests

### Expected Generated Files

- Normal `.github` synchronized copies for changed Skill/Prompt only.

### Bootstrap Impact

- None.

### Migration Classes

- Existing Archive users: behavior becomes explicit safe refusal/hand-off when authorization is absent.
- Historical Archive artifacts: unchanged.

### Required Tests

- Archive without explicit task-scoped authorization attempts no Git mutation or remote action.
- Each protected action requires separate current-task approval.
- Focused no-side-effect assertions cover Skill and Prompt entry paths.

### Rollback

Revert only the authorization wording/routing changes; do not change Archive artifacts or lifecycle timing.

### Hard Exclusions

- No Hybrid lifecycle implementation.
- No Archive filename rename.
- No post-merge record implementation.
- No Git or remote action.
- No manifest work.

### Approval and PR Boundary

Separate user approval, implementation, verification, review, and PR required.

### Observed Evidence

- PR #7
- Final head: `79e093323515e869107a7ff7d9785d128934c8bc`
- Squash merge SHA: `18b3ed5a876f4bf72a9564abe2fe7139a7cbd498`
- Remote Verify Change Package: success
- Remote verify-sync Ubuntu: success
- Remote verify-sync Windows: success
- Reviews: none
- Review threads: none

## Phase 1 — AGENTS / WORKFLOW / Risk-Mode Contract

### Objective

Establish D-01, D-03, and D-09 as one coherent responsibility contract.

### Decisions and Defects

- D-01
- D-03
- D-09 policy layer
- C-03 contract portion

### Prerequisites

- Phase 0 containment complete or consciously sequenced without conflict.
- User approval for the exact fallback rule set and named High-Risk gate proposal.

### Prerequisite Evidence

- Phase 0A through Phase 0D are merged. Phase 0D remote evidence is recorded above.
- Phase 1, the exact nine-rule Project AGENTS fallback contract, and the four rule-based named High-Risk gates were explicitly approved in the current task instruction and recorded as Amendment A-04 in `02-decision-log.md`.
- Phase 3 adopter-facing lifecycle source selection and Phase 4 Manifest schema remain unapproved and outside this Phase.
- Migration / Deployment Readiness: `N/A — no migration or deployment execution is authorized in this Phase.`

### Confirmed Responsibility Mapping

The following mapping is the single reviewed Phase 2 inventory. Agent edits must preserve the retained identity/lens/scope/handoff and replace embedded methodology with resolvable canonical Skill pointers; this is not authorization for a blanket Agent rewrite.

| Agent | Retain in Agent | Methodology/rubric removed from Agent | Canonical Skill owner(s) | Direct Prompt / Instruction impact |
|---|---|---|---|---|
| `architect.agent.md` | Cross-stage architect identity; architecture/security lens; consult scope; return-to-caller handoff; necessary tools | Composition procedure, design checklist, evaluation trigger details | `brainstorming`; `agentic-eval` | `instructions/playbooks/architect.md` becomes a compatibility pointer only |
| `brainstorm.agent.md` | Requirements-explorer identity; ambiguity/risk lens; pre-code scope; mode-aware handoff | Question-count procedure, option/premortem checklist, risk/output methodology | `brainstorming` | `brainstorm.prompt.md` becomes an entry/router Prompt |
| `code-reviewer.agent.md` | Independent reviewer identity; correctness/security/financial/TDD lens; review-only scope; correction handoff | Review priorities, severity rubric, detailed checklist | `code-security-review` | `code-review.prompt.md`, `code-review.instructions.md`, and `playbooks/security-reviewer.md` route to the Skill instead of owning the method |
| `coder.agent.md` | Implementer identity; TDD/financial-precision lens; approved-scope writer boundary; review handoff; necessary tools | Vertical-slice procedure, phase sequence, self-eval/document-update procedure | `tdd-workflow` | `tdd.prompt.md` and `playbooks/tdd-guide.md` become routers/pointers |
| `dba.agent.md` | Database architect identity; schema/migration/performance lens; DB-only consult scope; return-to-caller handoff | Schema/migration mandates, deliverable checklist, verification procedure | `backend-patterns` for database design/review tactics; `specification` for schema contracts; `implementation-planning` for migration/rollback planning | `sql.instructions.md` remains the unchanged `**/*.sql` scoped delta; `playbooks/database-reviewer.md` becomes a compatibility pointer |
| `frontend-designer.agent.md` | UI/UX identity; accessibility/component lens; design-only scope; return-to-caller handoff | Design procedure, breakpoint/checklist and deliverable method | `frontend-patterns`; `specification` for consult integration | No stage Prompt; no generic Instruction added |
| `plan.agent.md` | Planner identity; dependency/spec-gap lens; plan-only scope; coder handoff | Mode/artifact rules, vertical-slice procedure, output/self-eval gates | `implementation-planning` | `create-plan.prompt.md` and `playbooks/planner.md` become router/pointer surfaces |
| `pm.agent.md` | Project-router identity; state/SSOT lens; read/route-only scope; advisory dynamic handoff | Stage table, detection procedure, artifact/mode descriptions | `workflow-orchestrator`; `prd` | `workflow.prompt.md` becomes an entry/router Prompt |
| `spec.agent.md` | Specification identity; testability/traceability lens; spec-only consult scope; planner handoff | Clarification/spec procedure, quality rubric, input/output gate | `specification` | `spec.prompt.md` becomes an entry/router Prompt |

Cross-cutting reviewed mapping:

- `archive.prompt.md` routes to `work-archiving`; the Skill remains the method and protected-action boundary owner. Phase 0D behavior remains unchanged.
- `commit-gen.prompt.md` routes to `git-commit` and explicitly grants no staging or commit authority.
- `python.instructions.md` becomes a `**/*.py` language-scoped delta pointing to `python-patterns`; persona, tool-selection, research workflow, templates, Git policy, and generic execution procedure are removed.
- `code-review.instructions.md` becomes a source-file-scoped delta pointing to `code-security-review`; its generic review procedure, rubric, checklist, and global policy are removed.
- The five files under `instructions/playbooks/` become compatibility pointers only; they do not remain competing methodology owners. Direct Skill references to those legacy playbooks are removed where they would create circular ownership.
- `create-readme.prompt.md`, `learn.prompt.md`, and all other reviewed Instructions remain unchanged because they contain only task-specific entry/output UX or an already explicit file/language/framework/domain scope and do not own the mapped stage methodology.
- All changed `.github/**` files are generator-owned mirrors produced by `tools/sync-dotgithub.ps1`, never independent policy edits.

### Exact Luna Product Allowlist

Canonical Agents:

- `agents/architect.agent.md`
- `agents/brainstorm.agent.md`
- `agents/code-reviewer.agent.md`
- `agents/coder.agent.md`
- `agents/dba.agent.md`
- `agents/frontend-designer.agent.md`
- `agents/plan.agent.md`
- `agents/pm.agent.md`
- `agents/spec.agent.md`

Canonical Skills and gate integration:

- `skills/backend-patterns/SKILL.md`
- `skills/frontend-patterns/SKILL.md`
- `skills/code-security-review/SKILL.md`
- `skills/implementation-planning/SKILL.md`
- `skills/gate-check/SKILL.md`
- `skills/gate-check/scripts/run-gate-check.ps1`

Canonical Prompts:

- `prompts/archive.prompt.md`
- `prompts/brainstorm.prompt.md`
- `prompts/code-review.prompt.md`
- `prompts/commit-gen.prompt.md`
- `prompts/create-plan.prompt.md`
- `prompts/spec.prompt.md`
- `prompts/tdd.prompt.md`
- `prompts/workflow.prompt.md`

Canonical Instructions:

- `instructions/code-review.instructions.md`
- `instructions/python.instructions.md`
- `instructions/playbooks/architect.md`
- `instructions/playbooks/database-reviewer.md`
- `instructions/playbooks/planner.md`
- `instructions/playbooks/security-reviewer.md`
- `instructions/playbooks/tdd-guide.md`

Checker and regression tests:

- `tools/check-agent-structure.ps1`
- `tools/check-agent-structure.Tests.ps1`
- `tools/workflow-risk-mode.Tests.ps1`
- `tools/archive-authorization.Tests.ps1`

Generator-owned mirrors, writable only through the normal sync flow:

- `.github/agents/architect.agent.md`
- `.github/agents/brainstorm.agent.md`
- `.github/agents/code-reviewer.agent.md`
- `.github/agents/coder.agent.md`
- `.github/agents/dba.agent.md`
- `.github/agents/frontend-designer.agent.md`
- `.github/agents/plan.agent.md`
- `.github/agents/pm.agent.md`
- `.github/agents/spec.agent.md`
- `.github/skills/backend-patterns/SKILL.md`
- `.github/skills/frontend-patterns/SKILL.md`
- `.github/skills/code-security-review/SKILL.md`
- `.github/skills/implementation-planning/SKILL.md`
- `.github/prompts/archive.prompt.md`
- `.github/prompts/brainstorm.prompt.md`
- `.github/prompts/code-review.prompt.md`
- `.github/prompts/commit-gen.prompt.md`
- `.github/prompts/create-plan.prompt.md`
- `.github/prompts/spec.prompt.md`
- `.github/prompts/tdd.prompt.md`
- `.github/prompts/workflow.prompt.md`
- `.github/instructions/code-review.instructions.md`
- `.github/instructions/python.instructions.md`
- `.github/instructions/playbooks/architect.md`
- `.github/instructions/playbooks/database-reviewer.md`
- `.github/instructions/playbooks/planner.md`
- `.github/instructions/playbooks/security-reviewer.md`
- `.github/instructions/playbooks/tdd-guide.md`

If this exact allowlist is insufficient, Luna must stop and report the missing path and contract reason. No scope expansion is implicit.

### Exact Scope

- Separate maintainer and adopter AGENTS responsibilities.
- Add the short standalone Project fallback.
- Make the canonical Workflow contract the lifecycle SSOT for maintainers and adopter-facing projections.
- Replace all Fast Path terminology with Simple/Standard/High-Risk.
- Map Global A/B/C/D checkpoints to lifecycle use without copying Global policy.
- Define `agentic-eval` as self-evaluation with risk-based triggers.
- Define which lifecycle assets bootstrap promises; implementation may be deferred to Phase 3 where needed.
- Record the adopter-facing lifecycle source as a Phase 3 open design question; do not presume root maintainer `WORKFLOW.md` is the installed adopter contract.

### Expected Canonical Files

- `AGENTS.md`
- `docs/AGENTS.template.md`
- `WORKFLOW.md`
- `skills/workflow-orchestrator/SKILL.md`
- `skills/agentic-eval/SKILL.md`
- Directly affected workflow Prompt/PM references

### Expected Generated Files

- Corresponding `.github/**` synchronized mirrors.

### Bootstrap / Manifest Impact

- No schema change.
- Distribution promise changes must be recorded for Phase 3 implementation.

### Migration Classes

- New adopter: new Project AGENTS default.
- Existing Project AGENTS: manual alignment only.
- Existing template-managed lifecycle assets: normal hash-preserving update rules.

### Required Tests

- One and only one execution mode selected for representative scenarios.
- No Fast Path references remain in canonical lifecycle owners.
- Simple does not require Change Package.
- High-Risk requires full lifecycle and independent review.
- Project fallback covers required safety categories.
- Named gate semantics are consistent across owners.

### Rollback

Revert the Phase 1 canonical/mirror changes as a unit; do not roll back only one policy surface.

### Hard Exclusions

- No wholesale Agent methodology relocation.
- No manifest redesign.
- No adapter implementation.

### Approval and PR Boundary

Separate user approval and separate PR required.

### Observed Evidence

- Luna agent: built-in `worker`; requested GPT-5.6 with reasoning `medium`; observed model/effort: unknown because the runtime did not expose metadata.
- TDD RED → GREEN slices: fallback `0/9 → 9/9`; execution modes `9/16 → 16/16`; named gates `16/24 → 24/24`; canonical/derived parity `24/25 → 25/25`; conditional package semantics `25/28 → 28/28`; Simple artifact consistency `28/29 → 29/29`.
- Correction round 1: `28/32 → 32/32`; removed the remaining `fast-path` label and made PM routing reference canonical `WORKFLOW.md` while allowing Simple without a Change Package.
- Correction round 2: `23/34 → 34/34`; consolidated both Project AGENTS files to one nine-rule fallback block and preserved concrete project-specific defaults outside that block.
- Final targeted Pester 5.6.1: 34 passed, 0 failed, 0 skipped, 0 not run, 0 failed containers.
- Final full Pester 5.6.1 (`scripts` + `tools`): 101 passed, 0 failed, 0 skipped, 0 not run, 0 inconclusive, 0 failed containers.
- Python bootstrap regression: 89 passed. One pre-existing `pytest-asyncio` future-default deprecation warning remained warning-only and did not affect results.
- `check-sync.ps1`: pass; all managed `.github/**` mirrors match generated output.
- `audit-catalog.ps1`: pass; 9 agents, 10 prompts, 35 total skills, 34 adopter skills, 1 maintainer-only `gate-check`.
- `git diff --check`: pass.
- Full repository gate: `GATE PASSED`; pytest 8.3.5 and Pester 5.6.1 prerequisites passed; Python/Pester/sync/catalog/diff checks passed; worktree status was unchanged by the gate.
- Final scope audit: 31 changed/untracked paths, all limited to Sol-owned approval/status evidence, Phase 1 canonical product/test files, or generator-owned `.github/**` mirrors; no Phase 2 structural rewrite, Phase 3 lifecycle-source selection, Phase 4 Manifest schema, D-10 adapter, migration, prune, adopter execution, deployment, or production change.
- Sol independent audit after Luna handoff: 0 Critical, 0 High, 0 unresolved Medium, 0 Low product findings. Three blocking Medium contract gaps were found across two correction rounds and resolved by the same Luna.
- Rule-based High-Risk gates: Architecture Decision Exit — pass; Pre-Implementation Readiness — pass; Pre-Delivery Verification — pass; Migration / Deployment Readiness — `N/A — no migration or deployment execution is authorized in this Phase.`
- Coverage: N/A — Phase 1 changes policy/document contracts and uses deterministic Pester content/parity tests rather than executable production branches with a meaningful line-coverage metric.
- PR #8
- Final head: `9efa4511f081dcfb1c959fd18fbc92956e184646`
- Squash merge SHA: `8fe0abc71745b713985846fe9c42b67f78d3405f`
- Remote Verify Change Package: completed / success
- Remote verify-sync Ubuntu: completed / success
- Remote verify-sync Windows: completed / success
- Reviews: none
- Review threads: none

## Phase 2 — Agent / Skill / Prompt / Instruction Alignment

### Objective

Enforce the persona/behavior/router/scoped-instruction boundary without changing approved lifecycle semantics.

### Decisions and Defects

- D-04
- D-09 representation consistency

### Prerequisites

- Phase 1 Workflow and gate contract accepted.
- Structural Agent contract approved.

### Prerequisite Evidence

- Phase 1 is merged through PR #8 at squash merge SHA `8fe0abc71745b713985846fe9c42b67f78d3405f`; its final head and successful remote checks are recorded above.
- The current task explicitly approves Phase 2 product implementation, the D-04 Agent/Skill/Prompt/Instruction ownership contract, deterministic structural-checker semantics, soft line-count reporting, and a single Phase/single PR boundary; Amendment A-05 records that approval.
- Phase 1 lifecycle/mode/gate/authorization semantics remain immutable in this Phase.
- Phase 3 adopter-facing lifecycle source, Phase 4 Manifest schema, D-10 adapters, migration, prune, adopter execution, deployment, and production operation remain unapproved and outside scope.
- Migration / Deployment Readiness: `N/A — no migration or deployment execution is authorized in this Phase.`

### Exact Scope

- Reduce Agents to the approved thin responsibility set.
- Move methodology and detailed rubrics to paired Skills.
- Make workflow Prompts routers rather than policy owners.
- Remove generic lifecycle/global rules from path/domain Instructions.
- Keep specialized lens, handoff, and required tool restrictions.

### Expected Canonical Files

- `agents/*.agent.md` as required by the reviewed mapping
- Paired `skills/*/SKILL.md`
- Workflow Prompts
- Directly overlapping Instructions
- Structural/catalog checks

### Expected Generated Files

- `.github/agents/**`
- `.github/skills/**`
- `.github/prompts/**`
- `.github/instructions/**`
- Generated `.codex/agents/**` and `.claude/agents/**` only in adopter fixtures, pending D-10 constraints

### Bootstrap / Manifest Impact

- No schema change.
- Existing customized Agent/Skill content remains preserved.

### Migration Classes

- Untouched template-managed: normal update eligibility.
- Customized: preserve/report/manual merge.
- Derived customization: report as non-canonical; do not silently adopt.

### Required Tests

- Structural hard-gate checks.
- Soft line-count reporting.
- Methodology has one canonical owner.
- Generated content preserves persona/lens/handoff semantics.
- Catalog and sync parity.

### Rollback

Revert each paired Agent/Skill move together; never leave a pointer without its methodology owner.

### Hard Exclusions

- No new lifecycle semantics.
- No adapter capability claim beyond observed evidence.
- No unrelated Skill modernization.

### Approval and PR Boundary

Phase 2 has separate user approval and must be delivered as one Phase and one PR. If the reviewed mapping cannot be completed safely within that boundary, stop and report a proposed split without starting partial remote delivery.

### Observed Evidence

- Luna agent: built-in `worker`; requested GPT-5.6 with reasoning `medium`; observed model/effort: unknown because the runtime did not expose metadata.
- TDD RED → GREEN: structural checker `0/8 → 8/8`; current canonical Agents initially produced 45 hard failures and 8 warnings, then reached 0 hard failures; Agent/Skill mapping `8/9 → 13/13`; Prompt/Instruction/playbook ownership `13/19 → 19/19`; expected multi-Skill owner regression `19/20 → 20/20`; final combined Phase 0D/1/2 focused suite `66/66`.
- Luna implementation retained per-Agent persona/lens/scope/handoff, moved reusable database and UI consultation tactics to `backend-patterns` and `frontend-patterns`, converted affected Prompts/Instructions/playbooks to routers or scoped compatibility pointers, added the structural checker and tests, and regenerated `.github/**` mirrors through the repository sync flow.
- Sol independent audit: 0 Critical, 0 High, 0 Medium. Warning-only/Low evidence: `pm.agent.md` and `spec.agent.md` each contain 29 non-empty lines against the soft target of 25; Python regression emitted one pre-existing `pytest-asyncio` future-default deprecation warning. Neither warning matches an approved blocking condition.
- Correction rounds requested by Sol: 0 of 2. Luna made two bounded self-corrections before handoff: explicit expected-owner validation for multi-Skill Agents and removal of Prompt-side adopter lifecycle-source preselection.
- Direct structural checker: 0 hard failures; 2 `LINE_COUNT` warnings; exit 0.
- Final targeted Pester 5.6.1: 66 passed, 0 failed.
- Final full Pester 5.6.1 (`scripts` + `tools`): 122 passed, 0 failed, 0 skipped, 0 not run, 0 inconclusive, 0 failed containers.
- Python bootstrap regression: 89 passed, 0 failed. The pre-existing `pytest-asyncio` warning is recorded above.
- `check-sync.ps1`: pass; all managed `.github/**` mirrors match generated output.
- `audit-catalog.ps1`: pass; 9 agents, 10 prompts, 35 total skills, 34 adopter skills, 1 maintainer-only `gate-check`.
- Static pointer scan: 31 changed canonical Markdown files, 38 relative links, 0 broken links. No affected Prompt selects an adopter-facing lifecycle source.
- Full repository gate: `GATE PASSED WITH NOTES`, exit 0; environment, sync, catalog, structural checker, Python, Pester, `git diff --check`, and worktree invariance passed. Notes are the two approved soft line-count warnings.
- Final scope audit: exactly 64 changed/untracked paths, all in the reviewed allowlist; 0 unexpected and 0 missing. No lifecycle-semantic, Phase 3 source-selection, Phase 4 schema, D-10 adapter, migration, prune, real-adopter, deployment, or production change.
- Rule-based High-Risk gates: Architecture Decision Exit — pass; Pre-Implementation Readiness — pass; Pre-Delivery Verification — pass; Migration / Deployment Readiness — `N/A — no migration or deployment execution is authorized in this Phase.`
- Coverage: N/A — Phase 2 changes Markdown responsibility contracts and deterministic PowerShell checkers; focused structural/parity/regression evidence is the meaningful verification boundary rather than a line-coverage metric.
- PR #9
- Final head: `38caaa764bb5db956a4f75931767ab25954d230c`
- Squash merge SHA: `117e3192ff002040ce4e05fe5d3bf975696c9d4a`
- Commits: 1
- Changed files: 64
- Remote Verify Change Package: completed / success
- Remote verify-sync Ubuntu: completed / success
- Remote verify-sync Windows: completed / success
- Reviews: none
- Review threads: none

## Phase 3 — Change Package / Review / Archive Semantics

### Objective

Implement D-07 and D-08, resolve lifecycle artifact contracts, and distribute promised lifecycle assets safely.

### Decisions and Defects

- D-07
- D-08
- C-03 distribution portion
- C-06 full semantic fix

### Prerequisites

- Phase 1 mode contract accepted.
- Adopter-facing lifecycle source design approved after maintainer/adopter difference review.
- Separate decision on Archive artifact naming.
- Review semantic role compatibility design approved.

### Prerequisite Evidence

- Phase 2 is merged through PR #9 at squash merge SHA `117e3192ff002040ce4e05fe5d3bf975696c9d4a`; its final head, one-commit/64-file shape, successful remote checks, and review/thread evidence are recorded above.
- The current task explicitly approves Phase 3 product implementation and resolves the adopter source, compact/full package, single task/status SSOT, Review filename/alias, Archive/Closeout filename/alias, Hybrid closeout, bootstrap mapping, and current-schema preservation prerequisites. Amendment A-06 records that approval append-only.
- Root `WORKFLOW.md` remains the maintainer lifecycle SSOT; `docs/WORKFLOW.template.md` is the approved adopter projection and installs to adopter root `WORKFLOW.md` as `template-managed`.
- The current schema safely represents these assets through existing `name`, `source_hash`, `managed_hash`, `observed_hash`, `ownership`, `kind`, `source`, and `status` fields. No new schema version, field, or migration encoding is required or authorized.
- Migration / Deployment Readiness: `N/A — no migration or deployment execution is authorized in this Phase.`

### Maintainer / Adopter Difference Review

This is the single Phase 3 difference review. The projection is a distribution view of the root contract, not a second policy owner.

| Contract area | Root maintainer source | Adopter projection | Parity / exclusion rule |
|---|---|---|---|
| Lifecycle ownership and modes | `WORKFLOW.md` | `docs/WORKFLOW.template.md` | Preserve the canonical lifecycle pointer and exactly Simple/Standard/High-Risk with equivalent entry and escalation behavior. |
| Stages and verification | Full maintainer narrative, command tables, and stage exits | Portable stage purpose, entry/exit, verification, and handoff semantics | Preserve behavior; omit template-repository maintenance UX and surface-specific command claims. |
| High-Risk gates | Four named rule-based gates and cross-gate semantics | Same four gates and blocking/warning/N/A/independent-review boundary | Required deterministic semantic parity; no aggregate score. |
| Change Package and SSOT | Maintainer contract plus repository paths | Portable compact/full, trigger, semantic-role, and single-owner contract | Preserve required roles and blocking semantics; adopter paths are project-relative. |
| Review / Closeout | Canonical semantic definitions and compatibility aliases | Same role, filename, alias, content/status, and Hybrid closeout behavior | Preserve `07-review.md`, legacy `05-review.md`, `99-archive.md`, alias `99-closeout.md`, and competing-evidence blocking. |
| Authorization / completion | Protected-action and honest-completion boundaries | Same portable boundaries | Archive grants local documentation only; actual merge evidence remains remote-authoritative. |
| Maintainer-only material | Catalog, sync/generator, maintainer CI, repository maintenance, template release/bootstrap maintenance, repo-specific memory and MCP/CLI operational sections | Excluded | Difference is intentional and must be detected by forbidden-marker tests; exclusion cannot remove portable lifecycle semantics. |
| Deferred capabilities | D-10 unobserved adapters and Phase 4 schema/migration | Excluded except explicit deferral/safe boundary | No unsupported CLI claim, schema design, migration, prune, or real-adopter behavior. |

### Confirmed Responsibility Mapping

| Responsibility | Canonical owner / implementation | Required alignment |
|---|---|---|
| Maintainer lifecycle | `WORKFLOW.md` | Replace the open Phase 3 source note; define approved package, Review, Closeout, Hybrid, merge-evidence, and single-SSOT semantics without changing Phase 1 modes/gates. |
| Adopter lifecycle | `docs/WORKFLOW.template.md` | New projection with portable semantic markers and explicit maintainer-only exclusions; never a direct root copy. |
| Package templates | `changes/_template/**`; `changes/README.md`; `instructions/changes.instructions.md` | Add declaration fields, canonical `07-review.md`, pre-merge `99-archive.md`, compact/full guidance, content/status markers, and alias compatibility; never create actual packages. |
| Review method | `skills/code-security-review/SKILL.md` | Generate canonical `07-review.md`, retain `05-review.md` as historical alias, require Summary/Findings/Verification/Decision, and block deterministic/Critical/High failures. |
| Closeout method | `skills/work-archiving/SKILL.md`; `prompts/archive.prompt.md` | Make closeout mode-aware and pre-merge for package flows while retaining Phase 0D protected-action boundaries and remote-authoritative merge evidence. |
| Stage routing | `skills/workflow-orchestrator/SKILL.md` | Use execution mode, package trigger, semantic resolver, and content/status evidence rather than filename existence. |
| Package verification | `tools/verify-change-package.ps1` and tests | Deterministic new/historical resolver; canonical/alias competition, SSOT, role content/status, Simple/no-package, compact/full, and non-mutating output. |
| Lifecycle projection verification | `tools/check-lifecycle-contract.ps1` and tests | Deterministic root/projection portable parity, maintainer-only exclusion, canonical template set, and bootstrap source/target mapping. |
| Audit / repository gate / CI | `tools/audit-catalog.ps1`, gate-check, and `verify-change-package.yml` | Align audit with semantic roles; make lifecycle contract a required gate and package verification a noninteractive CI check on Ubuntu while full gate remains Windows/Ubuntu. |
| Bootstrap distribution | `scripts/bootstrap.py`; `scripts/bootstrap.ps1`; equivalent tests | Install projection/templates with existing-schema `template-managed` records; update only exact expected managed baseline; preserve customized/project-owned/legacy/unknown; retain Phase 0C missing/corrupt/unsupported behavior. |
| User documentation | `README.md`; `README.zh-TW.md`; `QUICKSTART.md` | Remove Fast Path/every-task-package/post-merge Archive drift and document Simple/Standard/High-Risk, compact/full, canonical Review, and pre-merge Closeout. |
| Generated mirrors | Repository sync flow only | Regenerate only directly changed Skill/Prompt/Instruction mirrors; no hand-owned mirror policy. |

### Exact Luna Product Allowlist

Lifecycle sources and user documentation:

- `WORKFLOW.md`
- `docs/WORKFLOW.template.md`
- `README.md`
- `README.zh-TW.md`
- `QUICKSTART.md`
- `changes/README.md`

Change Package templates and scoped instruction:

- `changes/_template/00-intake.md`
- `changes/_template/01-brainstorm.md`
- `changes/_template/02-decision-log.md`
- `changes/_template/03-spec.md`
- `changes/_template/04-plan.md`
- `changes/_template/05-test-plan.md`
- `changes/_template/06-impact-analysis.md`
- `changes/_template/07-review.md`
- `changes/_template/99-archive.md`
- `instructions/changes.instructions.md`

Canonical Skills and Prompt:

- `skills/workflow-orchestrator/SKILL.md`
- `skills/code-security-review/SKILL.md`
- `skills/work-archiving/SKILL.md`
- `prompts/archive.prompt.md`

Bootstrap implementations and tests:

- `scripts/bootstrap.py`
- `scripts/bootstrap.ps1`
- `scripts/tests/test_bootstrap.py`
- `scripts/bootstrap.Tests.ps1`

Deterministic verifier, projection, audit, regression, gate, and CI:

- `tools/verify-change-package.ps1`
- `tools/verify-change-package.Tests.ps1`
- `tools/check-lifecycle-contract.ps1`
- `tools/check-lifecycle-contract.Tests.ps1`
- `tools/audit-catalog.ps1`
- `tools/audit-catalog.Tests.ps1`
- `tools/workflow-risk-mode.Tests.ps1`
- `tools/archive-authorization.Tests.ps1`
- `skills/gate-check/SKILL.md`
- `skills/gate-check/scripts/run-gate-check.ps1`
- `.github/workflows/verify-change-package.yml`

Generator-owned mirrors, writable only through `tools/sync-dotgithub.ps1`:

- `.github/instructions/changes.instructions.md`
- `.github/skills/workflow-orchestrator/SKILL.md`
- `.github/skills/code-security-review/SKILL.md`
- `.github/skills/work-archiving/SKILL.md`
- `.github/prompts/archive.prompt.md`

If this exact allowlist is insufficient, Luna must stop and report the missing path and contract reason. No scope expansion is implicit. Sol alone may update `02-decision-log.md` and `04-plan.md` as governance evidence.

### Exact Scope

- Define compact versus full package requirements.
- Require one declared task/status SSOT.
- Implement Review semantic role and legacy aliases.
- Decide Archive/Closeout filename and compatibility behavior.
- Implement Hybrid closeout semantics.
- Select the adopter-facing lifecycle source from an approved design, then package that source and Change Package templates under explicit ownership.
- Do not directly distribute root maintainer `WORKFLOW.md` unless the approved difference review proves it fully generic.
- Align verifier, audit, stage detection, templates, and documentation.

### Expected Canonical Files

- Root `WORKFLOW.md` and whichever adopter-facing lifecycle source/projection is selected by the prerequisite decision; no path is preselected in this plan
- `changes/_template/**`
- `instructions/changes.instructions.md`
- Review/Archive Skills, Agents, and Prompts as directly required
- `tools/audit-catalog.ps1`
- Change Package verifier and tests
- Bootstrap lifecycle asset mapping

### Expected Generated Files

- Corresponding `.github/**` mirrors.
- Adopter lifecycle fixture outputs.

### Bootstrap / Manifest Impact

- New explicit ownership for lifecycle assets.
- No full manifest schema redesign; record only what current schema safely supports until Phase 4.

### Migration Classes

- Historical package: remain readable.
- Legacy `05-review.md`: recognized.
- Existing Archive filename: compatibility preserved.
- Customized lifecycle template: preserve/report.

### Required Tests

- Mode-based artifact requirements.
- Semantic Review detection with legacy alias.
- Stage completion validates content/status, not mere file existence.
- Hybrid closeout behavior.
- No implicit Git/remote action.
- Bootstrap distribution and customization preservation.
- Lifecycle distribution fixture proves the installed source matches the approved adopter-facing design and excludes maintainer-only content.

### Rollback

Revert lifecycle distribution and semantic contract together; continue recognizing historical aliases.

### Hard Exclusions

- No history rewrite or bulk rename.
- No post-merge Git action.
- No automatic adopter package creation.
- No lifecycle distribution implementation before the adopter-facing source decision is approved.

### Approval and PR Boundary

Separate approval and separate PR required; naming decision must be recorded before implementation.

### Observed Evidence

- Luna agent: built-in `worker`; requested GPT-5.6 with reasoning `medium`; observed model/effort: unknown because the runtime did not expose metadata. Sol requested GPT-5.6 with reasoning `xhigh`; observed model/effort: unknown because the runtime did not expose metadata.
- Initial bounded TDD slices: lifecycle projection `0/12 -> 12/12`; semantic package verifier `0/13 -> 14/14`; Python/PowerShell lifecycle distribution `0/3 -> 3/3` per runtime; audit/gate/CI integration `16/20 -> 20/20`.
- Correction round 1: `10/25 -> 29/29`; resolved canonical template/parser mismatch, substantive content/status validation, single task/status SSOT conflicts, Simple voluntary-package handling, and pre-merge structured status consistency.
- Correction round 2: `26/37 -> 38/38`; preserved warning-only semantics, distinguished actual merge claims from allowed head/commit SHA evidence, and made rollback/recovery evidence versus `N/A — reason` mutually exclusive.
- Luna final combined Phase 3 regressions: 100 passed, 0 failed, 0 skipped. Luna did not run the full repository gate and performed no protected Git or remote action.
- Sol targeted Pester 5.6.1: 100 passed, 0 failed, 0 skipped, 0 not run, 0 failed containers.
- Sol full Pester 5.6.1 (`scripts` + `tools`): 181 passed, 0 failed, 0 skipped, 0 not run, 0 failed containers.
- Sol Python bootstrap regression: 92 passed. The pre-existing `pytest-asyncio` future-default loop-scope deprecation warning remained warning-only.
- Direct lifecycle checker: pass with 19 root markers, 19 adopter-projection markers, and exactly 9 canonical templates.
- Direct package verifier with and without BaseRef: pass for 8 historical packages; one nonblocking legacy `05-review.md` warning remained.
- `check-sync.ps1`: pass; all changed canonical Instruction/Prompt/Skill sources match generated `.github/**` mirrors.
- `audit-catalog.ps1`: pass; 9 agents, 10 prompts, 35 total skills, 34 adopter skills, 1 maintainer-only `gate-check`, 9 canonical Change Package templates, and semantic-role parity.
- Agent structure checker: pass with warning-only line-count findings for `agents/pm.agent.md` and `agents/spec.agent.md`; no structural hard finding.
- `.github/workflows/verify-change-package.yml`: YAML safe-parse pass; job `verify` invokes the semantic verifier with BaseRef and enforces worktree invariance.
- `git diff --check`: pass.
- Full repository gate: `GATE PASSED WITH NOTES`; all required Python/Pester/sync/catalog/lifecycle/package/agent-structure/diff checks passed. Notes were limited to the approved Phase 2 soft line-count warnings.
- Worktree invariance: targeted/full/direct checks and the full gate left status unchanged; the final gate preserved the path, byte length, and SHA-256 of all 36 changed/untracked files.
- Final scope audit: 36 changed/untracked paths, all inside the exact product allowlist or Sol-owned `02-decision-log.md` / `04-plan.md`; 0 unexpected paths. No Phase 4 schema/version/migration, real adopter execution, prune, D-10 adapter, unobserved capability claim, deployment, production, branch deletion, tag, release, force push, rebase, push-main, auto-merge, or admin-bypass change.
- Sol independent audit: 0 Critical, 0 High, 0 unresolved Medium, 0 Low product findings after two bounded correction rounds. The first round resolved 3 High and 2 Medium findings; the second and final round resolved 2 High and 1 Medium findings.
- Rule-based High-Risk gates: Architecture Decision Exit — pass; Pre-Implementation Readiness — pass; Pre-Delivery Verification — pass; Migration / Deployment Readiness — `N/A — no migration or deployment execution is authorized in this Phase.`
- Coverage: N/A — Phase 3 behavior is covered through deterministic PowerShell semantic/contract fixtures plus Python and PowerShell bootstrap parity; a line-coverage percentage is not the meaningful acceptance boundary for these repository tools and Markdown contracts.
- Remote delivery: PR #10 (`https://github.com/forgivesam168/ai-dev-workflow/pull/10`) merged to `main`; final feature head `08e4fe7febc5743141ed2b237fae025a05adbd2c`; squash merge SHA `f8a0116ce4af0b463c838150350a9ccfa7c2cac6`.
- Remote shape: 1 commit, 36 changed files, no submitted reviews, and no review threads.
- Remote CI: `Verify Change Package / verify`, `verify-sync / baseline (ubuntu-latest)`, and `verify-sync / baseline (windows-latest)` all completed successfully.

## Phase 4 — Manifest / Provenance / Stale-Derived Migration

### Schema Proposal Status

- **Status**: Schema Design approved; Proposal PR #11 merged; Phase 4A Reader-First Foundation in progress; Phase 4 overall remains incomplete.
- **Authorization boundary**: Phase 4A may create the approved Production Schema and Component Catalog, add read-only v3 validation to both runtimes, preserve v1/v2 reading, and block every v3 mutation path before writes. Candidate schema/examples must remain byte-identical to approved head `16aa063139431cbd07cba147d81be1d2cb3da609`; writer enablement, conversion planning, migration, tombstone mutation, prune, and real-adopter behavior remain unauthorized.
- **Proposal branch**: `design/phase-4-manifest-schema-proposal` from merged Phase 3 `main` at `f8a0116ce4af0b463c838150350a9ccfa7c2cac6`.
- **Approval evidence**: Amendment A-07 records explicit current-task approval of OD-01 through OD-17 and the complete Manifest v3 Schema Design at exact head `16aa063139431cbd07cba147d81be1d2cb3da609`.
- **Remote evidence**: PR #11 was merged from final status head `fa0471d8139e288fcf856af7a160f0e2d1335627` as squash merge `5300d56c9ef9594f9bb3007b22824a644e06ee62`; three commits and 13 files; latest Verify Change Package, verify-sync Ubuntu, and verify-sync Windows completed successfully; no reviews or unresolved review threads.
- **Delivery boundary**: Phase 4A uses its own branch and PR. Phase 4B, writer enablement, migration, tombstone mutation, prune, and real-adopter execution remain separate future decisions.

### Phase 4A — Reader-First Foundation

- **Status**: Local implementation verified; PR pending under Amendment A-08. Phase 4 overall remains in progress / partially implemented.
- **Starting main**: local `main` = `origin/main` = `5300d56c9ef9594f9bb3007b22824a644e06ee62`; working tree clean before branch creation.
- **Branch**: `feat/phase-4a-manifest-reader-foundation`.
- **Approved product boundary**: Production Manifest v3 Schema; Stable Component ID Catalog v1; strict read-only v3 parsing and semantic validation in Python and PowerShell; preserved v1/v2 reading; valid-v3 zero-write mutation blocking; shared vectors and parity/regression evidence. Production writers remain v2.
- **Hard exclusions**: no conversion or stale planner, v3 writer, migration, tombstone write, prune/delete, real-adopter operation, deployment/production, Phase 4B/4C/4D, or Phase 5.
- **Worker**: existing built-in `worker` Luna is the sole product writer; requested GPT-5.6 / medium; observed model and effort are unknown because the runtime exposes no auditable value; no configuration change is permitted.

#### One-Time Current Distribution Inventory and Stable-ID Mapping

Sol inspected the actual Python and PowerShell distribution paths before delegation. The corrected exact active Catalog inventory is 253 components: 101 canonical, 110 generated, 3 project-owned, and 39 compatibility; 249 files, one directory, and 3 mounts. The reviewed mapping has zero duplicate IDs, zero ASCII-lower path-key collisions, and a maximum ID length of 96. Its read-only canonical inventory fingerprint is `sha256:4e68c7431da961b126748b2a3fb110e9dc52094cf1a958b64528337422800c66`; this is audit evidence for the reviewed mapping, not authenticity, authorization, or a runtime ID generator.

The initial 252-entry allocation incorrectly listed all 80 Skill files as direct parents of each Skill mount, conflicting with the approved Schema limit of 64 `generated_from` entries. Correction round 1 uses the already-approved `directory` kind and parent-component semantics: `cmp:canonical-skills-root` represents canonical `skills`, and every Skill mount has that one directory parent. The 80 file identities remain independently allocated. No Schema field, limit, enum, lifecycle rule, or approved technical decision changes.

| Component class | Count | Exact mapping and lineage |
|---|---:|---|
| Canonical Skill root and files | 81 | `skills` → `cmp:canonical-skills-root` with kind `directory`; plus every tracked adopter Skill file except `skills/gate-check/**` using `cmp:canonical-skill-<skill>` for `SKILL.md` and `cmp:canonical-skill-<skill>-<artifact-kind>-<logical-name>` for reviewed references/scripts/templates/assets. |
| Canonical Agent files | 9 | `agents/<name>.agent.md` → `cmp:canonical-<name>-agent`. |
| Canonical adopter lifecycle / constitution | 11 | `.github/copilot-instructions.md` → `cmp:canonical-adopter-copilot-instructions`; `WORKFLOW.md` → `cmp:canonical-adopter-workflow`; nine `changes/_template/*.md` files → `cmp:canonical-change-template-<filename-stem>`. |
| Project-owned guides | 3 | `AGENTS.md`, `CLAUDE.md`, and `GEMINI.md` → `cmp:project-<surface>-guide`. |
| Compatibility files | 39 | The 37 installer-distributed `.github/**` files outside workflows, Agents, Skills, CODEOWNERS, dependabot, and adopter constitution, plus `.gitattributes` and `.editorconfig`; each has an explicit `cmp:compat-*` logical ID and no generated parent. |
| Generated Skill mirrors | 80 | `.github/skills/<relative>` → `cmp:generated-github-<canonical-skill-ID-suffix>`, with the exact corresponding canonical Skill file as its only parent. |
| Generated Agent representations | 27 | For every canonical Agent: `.github/agents/<name>.agent.md`, `.claude/agents/<name>.md`, and `.codex/agents/<name>.toml` → `cmp:generated-<surface>-<name>-agent`, each with that canonical Agent as its only parent. |
| Generated Skill mounts | 3 | `.agent/skills`, `.agents/skills`, and `.claude/skills` → fixed IDs `cmp:generated-agent-skills-mount`, `cmp:generated-agents-skills-mount`, and `cmp:generated-claude-skills-mount`; each records only `cmp:canonical-skills-root` as its direct parent. |

Every entry uses its adopter-relative logical target as `canonical_source_path`, is active in initial release `ai-dev-workflow:component-catalog:1`, has empty `previous_paths`, null successor/reintroduction/retired release, and is sorted by stable ID. IDs are explicitly allocated in the version-controlled Catalog and are never recomputed from path, hash, time, adopter content, randomness, or runtime state. Rename must preserve the existing ID; retirement/tombstone permanently reserves it.

#### Exact Stable-ID Allocation

The following table is the complete one-time Sol allocation. It is normative for Phase 4A: Luna must transcribe it into the Catalog and must not choose, shorten, regenerate, or infer another ID. The fingerprint above is SHA-256 over UTF-8 bytes of a compact JSON array sorted by `id`, with each object in property order `id`, `canonical_source_path`, `role`, `kind`, `generated_from`; every `generated_from` array is sorted. This serialization definition is audit-only and must not become runtime allocation logic.

| Stable ID | Canonical source path | Role | Kind | Generated from |
|---|---|---|---|---|
| `cmp:canonical-adopter-copilot-instructions` | `.github/copilot-instructions.md` | canonical | file | — |
| `cmp:canonical-adopter-workflow` | `WORKFLOW.md` | canonical | file | — |
| `cmp:canonical-architect-agent` | `agents/architect.agent.md` | canonical | file | — |
| `cmp:canonical-brainstorm-agent` | `agents/brainstorm.agent.md` | canonical | file | — |
| `cmp:canonical-change-template-00-intake` | `changes/_template/00-intake.md` | canonical | file | — |
| `cmp:canonical-change-template-01-brainstorm` | `changes/_template/01-brainstorm.md` | canonical | file | — |
| `cmp:canonical-change-template-02-decision-log` | `changes/_template/02-decision-log.md` | canonical | file | — |
| `cmp:canonical-change-template-03-spec` | `changes/_template/03-spec.md` | canonical | file | — |
| `cmp:canonical-change-template-04-plan` | `changes/_template/04-plan.md` | canonical | file | — |
| `cmp:canonical-change-template-05-test-plan` | `changes/_template/05-test-plan.md` | canonical | file | — |
| `cmp:canonical-change-template-06-impact-analysis` | `changes/_template/06-impact-analysis.md` | canonical | file | — |
| `cmp:canonical-change-template-07-review` | `changes/_template/07-review.md` | canonical | file | — |
| `cmp:canonical-change-template-99-archive` | `changes/_template/99-archive.md` | canonical | file | — |
| `cmp:canonical-code-reviewer-agent` | `agents/code-reviewer.agent.md` | canonical | file | — |
| `cmp:canonical-coder-agent` | `agents/coder.agent.md` | canonical | file | — |
| `cmp:canonical-dba-agent` | `agents/dba.agent.md` | canonical | file | — |
| `cmp:canonical-frontend-designer-agent` | `agents/frontend-designer.agent.md` | canonical | file | — |
| `cmp:canonical-plan-agent` | `agents/plan.agent.md` | canonical | file | — |
| `cmp:canonical-pm-agent` | `agents/pm.agent.md` | canonical | file | — |
| `cmp:canonical-skill-agentic-eval` | `skills/agentic-eval/SKILL.md` | canonical | file | — |
| `cmp:canonical-skill-agentic-eval-reference-cli-evaluation-workflow` | `skills/agentic-eval/references/cli-evaluation-workflow.md` | canonical | file | — |
| `cmp:canonical-skill-agentic-eval-reference-python-patterns` | `skills/agentic-eval/references/python-patterns.md` | canonical | file | — |
| `cmp:canonical-skill-agentic-eval-reference-stage-rubrics` | `skills/agentic-eval/references/stage-rubrics.md` | canonical | file | — |
| `cmp:canonical-skill-backend-patterns` | `skills/backend-patterns/SKILL.md` | canonical | file | — |
| `cmp:canonical-skill-brainstorming` | `skills/brainstorming/SKILL.md` | canonical | file | — |
| `cmp:canonical-skill-brainstorming-template-decision-log` | `skills/brainstorming/templates/decision-log.md` | canonical | file | — |
| `cmp:canonical-skill-brainstorming-template-proposal` | `skills/brainstorming/templates/proposal.md` | canonical | file | — |
| `cmp:canonical-skill-brainstorming-template-tasks` | `skills/brainstorming/templates/tasks.md` | canonical | file | — |
| `cmp:canonical-skill-chrome-devtools` | `skills/chrome-devtools/SKILL.md` | canonical | file | — |
| `cmp:canonical-skill-ci-cd-and-automation` | `skills/ci-cd-and-automation/SKILL.md` | canonical | file | — |
| `cmp:canonical-skill-code-security-review` | `skills/code-security-review/SKILL.md` | canonical | file | — |
| `cmp:canonical-skill-coding-standards` | `skills/coding-standards/SKILL.md` | canonical | file | — |
| `cmp:canonical-skill-context-engineering` | `skills/context-engineering/SKILL.md` | canonical | file | — |
| `cmp:canonical-skill-copilot-sdk` | `skills/copilot-sdk/SKILL.md` | canonical | file | — |
| `cmp:canonical-skill-debug` | `skills/debug/SKILL.md` | canonical | file | — |
| `cmp:canonical-skill-excalidraw-diagram-generator` | `skills/excalidraw-diagram-generator/SKILL.md` | canonical | file | — |
| `cmp:canonical-skill-excalidraw-diagram-generator-reference-element-types` | `skills/excalidraw-diagram-generator/references/element-types.md` | canonical | file | — |
| `cmp:canonical-skill-excalidraw-diagram-generator-reference-excalidraw-schema` | `skills/excalidraw-diagram-generator/references/excalidraw-schema.md` | canonical | file | — |
| `cmp:canonical-skill-excalidraw-diagram-generator-script-` | `skills/excalidraw-diagram-generator/scripts/.gitignore` | canonical | file | — |
| `cmp:canonical-skill-excalidraw-diagram-generator-script-add-arrow` | `skills/excalidraw-diagram-generator/scripts/add-arrow.py` | canonical | file | — |
| `cmp:canonical-skill-excalidraw-diagram-generator-script-add-icon-to-diagram` | `skills/excalidraw-diagram-generator/scripts/add-icon-to-diagram.py` | canonical | file | — |
| `cmp:canonical-skill-excalidraw-diagram-generator-script-readme` | `skills/excalidraw-diagram-generator/scripts/README.md` | canonical | file | — |
| `cmp:canonical-skill-excalidraw-diagram-generator-script-split-excalidraw-library` | `skills/excalidraw-diagram-generator/scripts/split-excalidraw-library.py` | canonical | file | — |
| `cmp:canonical-skill-excalidraw-diagram-generator-template-business-flow-swimlane-template` | `skills/excalidraw-diagram-generator/templates/business-flow-swimlane-template.excalidraw` | canonical | file | — |
| `cmp:canonical-skill-excalidraw-diagram-generator-template-class-diagram-template` | `skills/excalidraw-diagram-generator/templates/class-diagram-template.excalidraw` | canonical | file | — |
| `cmp:canonical-skill-excalidraw-diagram-generator-template-data-flow-diagram-template` | `skills/excalidraw-diagram-generator/templates/data-flow-diagram-template.excalidraw` | canonical | file | — |
| `cmp:canonical-skill-excalidraw-diagram-generator-template-er-diagram-template` | `skills/excalidraw-diagram-generator/templates/er-diagram-template.excalidraw` | canonical | file | — |
| `cmp:canonical-skill-excalidraw-diagram-generator-template-flowchart-template` | `skills/excalidraw-diagram-generator/templates/flowchart-template.excalidraw` | canonical | file | — |
| `cmp:canonical-skill-excalidraw-diagram-generator-template-mindmap-template` | `skills/excalidraw-diagram-generator/templates/mindmap-template.excalidraw` | canonical | file | — |
| `cmp:canonical-skill-excalidraw-diagram-generator-template-relationship-template` | `skills/excalidraw-diagram-generator/templates/relationship-template.excalidraw` | canonical | file | — |
| `cmp:canonical-skill-excalidraw-diagram-generator-template-sequence-diagram-template` | `skills/excalidraw-diagram-generator/templates/sequence-diagram-template.excalidraw` | canonical | file | — |
| `cmp:canonical-skill-execution-guardrails` | `skills/execution-guardrails/SKILL.md` | canonical | file | — |
| `cmp:canonical-skill-execution-guardrails-reference-anti-patterns` | `skills/execution-guardrails/references/anti-patterns.md` | canonical | file | — |
| `cmp:canonical-skill-execution-guardrails-reference-stage-usage` | `skills/execution-guardrails/references/stage-usage.md` | canonical | file | — |
| `cmp:canonical-skill-explore` | `skills/explore/SKILL.md` | canonical | file | — |
| `cmp:canonical-skill-frontend-patterns` | `skills/frontend-patterns/SKILL.md` | canonical | file | — |
| `cmp:canonical-skill-gh-cli` | `skills/gh-cli/SKILL.md` | canonical | file | — |
| `cmp:canonical-skill-git-commit` | `skills/git-commit/SKILL.md` | canonical | file | — |
| `cmp:canonical-skill-github-issues` | `skills/github-issues/SKILL.md` | canonical | file | — |
| `cmp:canonical-skill-github-issues-reference-templates` | `skills/github-issues/references/templates.md` | canonical | file | — |
| `cmp:canonical-skill-implementation-planning` | `skills/implementation-planning/SKILL.md` | canonical | file | — |
| `cmp:canonical-skill-make-skill-template` | `skills/make-skill-template/SKILL.md` | canonical | file | — |
| `cmp:canonical-skill-markdown-to-html` | `skills/markdown-to-html/SKILL.md` | canonical | file | — |
| `cmp:canonical-skill-markdown-to-html-reference-basic-markdown` | `skills/markdown-to-html/references/basic-markdown.md` | canonical | file | — |
| `cmp:canonical-skill-markdown-to-html-reference-basic-markdown-to-html` | `skills/markdown-to-html/references/basic-markdown-to-html.md` | canonical | file | — |
| `cmp:canonical-skill-markdown-to-html-reference-code-blocks` | `skills/markdown-to-html/references/code-blocks.md` | canonical | file | — |
| `cmp:canonical-skill-markdown-to-html-reference-code-blocks-to-html` | `skills/markdown-to-html/references/code-blocks-to-html.md` | canonical | file | — |
| `cmp:canonical-skill-markdown-to-html-reference-collapsed-sections` | `skills/markdown-to-html/references/collapsed-sections.md` | canonical | file | — |
| `cmp:canonical-skill-markdown-to-html-reference-collapsed-sections-to-html` | `skills/markdown-to-html/references/collapsed-sections-to-html.md` | canonical | file | — |
| `cmp:canonical-skill-markdown-to-html-reference-gomarkdown` | `skills/markdown-to-html/references/gomarkdown.md` | canonical | file | — |
| `cmp:canonical-skill-markdown-to-html-reference-hugo` | `skills/markdown-to-html/references/hugo.md` | canonical | file | — |
| `cmp:canonical-skill-markdown-to-html-reference-jekyll` | `skills/markdown-to-html/references/jekyll.md` | canonical | file | — |
| `cmp:canonical-skill-markdown-to-html-reference-marked` | `skills/markdown-to-html/references/marked.md` | canonical | file | — |
| `cmp:canonical-skill-markdown-to-html-reference-pandoc` | `skills/markdown-to-html/references/pandoc.md` | canonical | file | — |
| `cmp:canonical-skill-markdown-to-html-reference-tables` | `skills/markdown-to-html/references/tables.md` | canonical | file | — |
| `cmp:canonical-skill-markdown-to-html-reference-tables-to-html` | `skills/markdown-to-html/references/tables-to-html.md` | canonical | file | — |
| `cmp:canonical-skill-markdown-to-html-reference-writing-mathematical-expressions` | `skills/markdown-to-html/references/writing-mathematical-expressions.md` | canonical | file | — |
| `cmp:canonical-skill-markdown-to-html-reference-writing-mathematical-expressions-to-html` | `skills/markdown-to-html/references/writing-mathematical-expressions-to-html.md` | canonical | file | — |
| `cmp:canonical-skill-microsoft-code-reference` | `skills/microsoft-code-reference/SKILL.md` | canonical | file | — |
| `cmp:canonical-skill-microsoft-docs` | `skills/microsoft-docs/SKILL.md` | canonical | file | — |
| `cmp:canonical-skill-prd` | `skills/prd/SKILL.md` | canonical | file | — |
| `cmp:canonical-skill-python-patterns` | `skills/python-patterns/SKILL.md` | canonical | file | — |
| `cmp:canonical-skill-refactor` | `skills/refactor/SKILL.md` | canonical | file | — |
| `cmp:canonical-skill-scoutqa-test` | `skills/scoutqa-test/SKILL.md` | canonical | file | — |
| `cmp:canonical-skill-security-review` | `skills/security-review/SKILL.md` | canonical | file | — |
| `cmp:canonical-skill-security-review-asset-cloud-infrastructure-security` | `skills/security-review/cloud-infrastructure-security.md` | canonical | file | — |
| `cmp:canonical-skill-shipping-and-launch` | `skills/shipping-and-launch/SKILL.md` | canonical | file | — |
| `cmp:canonical-skill-specification` | `skills/specification/SKILL.md` | canonical | file | — |
| `cmp:canonical-skill-specification-reference-ac-format-guide` | `skills/specification/references/ac-format-guide.md` | canonical | file | — |
| `cmp:canonical-skill-specification-reference-consult-review-protocol` | `skills/specification/references/consult-review-protocol.md` | canonical | file | — |
| `cmp:canonical-skill-specification-reference-specialist-lens-review` | `skills/specification/references/specialist-lens-review.md` | canonical | file | — |
| `cmp:canonical-skill-tdd-workflow` | `skills/tdd-workflow/SKILL.md` | canonical | file | — |
| `cmp:canonical-skill-web-design-reviewer` | `skills/web-design-reviewer/SKILL.md` | canonical | file | — |
| `cmp:canonical-skill-web-design-reviewer-reference-framework-fixes` | `skills/web-design-reviewer/references/framework-fixes.md` | canonical | file | — |
| `cmp:canonical-skill-web-design-reviewer-reference-visual-checklist` | `skills/web-design-reviewer/references/visual-checklist.md` | canonical | file | — |
| `cmp:canonical-skill-webapp-testing` | `skills/webapp-testing/SKILL.md` | canonical | file | — |
| `cmp:canonical-skill-webapp-testing-asset-test-helper` | `skills/webapp-testing/test-helper.js` | canonical | file | — |
| `cmp:canonical-skill-work-archiving` | `skills/work-archiving/SKILL.md` | canonical | file | — |
| `cmp:canonical-skill-workflow-orchestrator` | `skills/workflow-orchestrator/SKILL.md` | canonical | file | — |
| `cmp:canonical-skills-root` | `skills` | canonical | directory | — |
| `cmp:canonical-spec-agent` | `agents/spec.agent.md` | canonical | file | — |
| `cmp:compat-editorconfig` | `.editorconfig` | compatibility | file | — |
| `cmp:compat-gitattributes` | `.gitattributes` | compatibility | file | — |
| `cmp:compat-hook-post-tool-use-powershell` | `.github/hooks/post-tool-use.ps1` | compatibility | file | — |
| `cmp:compat-hook-post-tool-use-shell` | `.github/hooks/post-tool-use.sh` | compatibility | file | — |
| `cmp:compat-hook-pre-tool-use-powershell` | `.github/hooks/pre-tool-use.ps1` | compatibility | file | — |
| `cmp:compat-hook-pre-tool-use-shell` | `.github/hooks/pre-tool-use.sh` | compatibility | file | — |
| `cmp:compat-hook-session-start-powershell` | `.github/hooks/session-start.ps1` | compatibility | file | — |
| `cmp:compat-hook-session-start-shell` | `.github/hooks/session-start.sh` | compatibility | file | — |
| `cmp:compat-hooks-copilot-hooks` | `.github/hooks/copilot-hooks.json` | compatibility | file | — |
| `cmp:compat-instruction-agent-skills` | `.github/instructions/agent-skills.instructions.md` | compatibility | file | — |
| `cmp:compat-instruction-api-design` | `.github/instructions/api-design.instructions.md` | compatibility | file | — |
| `cmp:compat-instruction-architect` | `.github/instructions/playbooks/architect.md` | compatibility | file | — |
| `cmp:compat-instruction-aspnet-rest-apis` | `.github/instructions/aspnet-rest-apis.instructions.md` | compatibility | file | — |
| `cmp:compat-instruction-changes` | `.github/instructions/changes.instructions.md` | compatibility | file | — |
| `cmp:compat-instruction-code-review` | `.github/instructions/code-review.instructions.md` | compatibility | file | — |
| `cmp:compat-instruction-csharp` | `.github/instructions/csharp.instructions.md` | compatibility | file | — |
| `cmp:compat-instruction-database-reviewer` | `.github/instructions/playbooks/database-reviewer.md` | compatibility | file | — |
| `cmp:compat-instruction-dotnet-architecture-good-practices` | `.github/instructions/dotnet-architecture-good-practices.instructions.md` | compatibility | file | — |
| `cmp:compat-instruction-openspec` | `.github/instructions/openspec.instructions.md` | compatibility | file | — |
| `cmp:compat-instruction-planner` | `.github/instructions/playbooks/planner.md` | compatibility | file | — |
| `cmp:compat-instruction-python` | `.github/instructions/python.instructions.md` | compatibility | file | — |
| `cmp:compat-instruction-security-reviewer` | `.github/instructions/playbooks/security-reviewer.md` | compatibility | file | — |
| `cmp:compat-instruction-sql` | `.github/instructions/sql.instructions.md` | compatibility | file | — |
| `cmp:compat-instruction-tdd-guide` | `.github/instructions/playbooks/tdd-guide.md` | compatibility | file | — |
| `cmp:compat-issue-template-bug-report` | `.github/ISSUE_TEMPLATE/bug_report.md` | compatibility | file | — |
| `cmp:compat-issue-template-feature-request` | `.github/ISSUE_TEMPLATE/feature_request.md` | compatibility | file | — |
| `cmp:compat-issue-template-task` | `.github/ISSUE_TEMPLATE/task.md` | compatibility | file | — |
| `cmp:compat-mcp` | `.github/mcp.json` | compatibility | file | — |
| `cmp:compat-prompt-archive` | `.github/prompts/archive.prompt.md` | compatibility | file | — |
| `cmp:compat-prompt-brainstorm` | `.github/prompts/brainstorm.prompt.md` | compatibility | file | — |
| `cmp:compat-prompt-code-review` | `.github/prompts/code-review.prompt.md` | compatibility | file | — |
| `cmp:compat-prompt-commit-gen` | `.github/prompts/commit-gen.prompt.md` | compatibility | file | — |
| `cmp:compat-prompt-create-plan` | `.github/prompts/create-plan.prompt.md` | compatibility | file | — |
| `cmp:compat-prompt-create-readme` | `.github/prompts/create-readme.prompt.md` | compatibility | file | — |
| `cmp:compat-prompt-learn` | `.github/prompts/learn.prompt.md` | compatibility | file | — |
| `cmp:compat-prompt-spec` | `.github/prompts/spec.prompt.md` | compatibility | file | — |
| `cmp:compat-prompt-tdd` | `.github/prompts/tdd.prompt.md` | compatibility | file | — |
| `cmp:compat-prompt-workflow` | `.github/prompts/workflow.prompt.md` | compatibility | file | — |
| `cmp:compat-pull-request-template` | `.github/PULL_REQUEST_TEMPLATE.md` | compatibility | file | — |
| `cmp:generated-agent-skills-mount` | `.agent/skills` | generated | mount | `cmp:canonical-skills-root` |
| `cmp:generated-agents-skills-mount` | `.agents/skills` | generated | mount | `cmp:canonical-skills-root` |
| `cmp:generated-claude-architect-agent` | `.claude/agents/architect.md` | generated | file | `cmp:canonical-architect-agent` |
| `cmp:generated-claude-brainstorm-agent` | `.claude/agents/brainstorm.md` | generated | file | `cmp:canonical-brainstorm-agent` |
| `cmp:generated-claude-code-reviewer-agent` | `.claude/agents/code-reviewer.md` | generated | file | `cmp:canonical-code-reviewer-agent` |
| `cmp:generated-claude-coder-agent` | `.claude/agents/coder.md` | generated | file | `cmp:canonical-coder-agent` |
| `cmp:generated-claude-dba-agent` | `.claude/agents/dba.md` | generated | file | `cmp:canonical-dba-agent` |
| `cmp:generated-claude-frontend-designer-agent` | `.claude/agents/frontend-designer.md` | generated | file | `cmp:canonical-frontend-designer-agent` |
| `cmp:generated-claude-plan-agent` | `.claude/agents/plan.md` | generated | file | `cmp:canonical-plan-agent` |
| `cmp:generated-claude-pm-agent` | `.claude/agents/pm.md` | generated | file | `cmp:canonical-pm-agent` |
| `cmp:generated-claude-skills-mount` | `.claude/skills` | generated | mount | `cmp:canonical-skills-root` |
| `cmp:generated-claude-spec-agent` | `.claude/agents/spec.md` | generated | file | `cmp:canonical-spec-agent` |
| `cmp:generated-codex-architect-agent` | `.codex/agents/architect.toml` | generated | file | `cmp:canonical-architect-agent` |
| `cmp:generated-codex-brainstorm-agent` | `.codex/agents/brainstorm.toml` | generated | file | `cmp:canonical-brainstorm-agent` |
| `cmp:generated-codex-code-reviewer-agent` | `.codex/agents/code-reviewer.toml` | generated | file | `cmp:canonical-code-reviewer-agent` |
| `cmp:generated-codex-coder-agent` | `.codex/agents/coder.toml` | generated | file | `cmp:canonical-coder-agent` |
| `cmp:generated-codex-dba-agent` | `.codex/agents/dba.toml` | generated | file | `cmp:canonical-dba-agent` |
| `cmp:generated-codex-frontend-designer-agent` | `.codex/agents/frontend-designer.toml` | generated | file | `cmp:canonical-frontend-designer-agent` |
| `cmp:generated-codex-plan-agent` | `.codex/agents/plan.toml` | generated | file | `cmp:canonical-plan-agent` |
| `cmp:generated-codex-pm-agent` | `.codex/agents/pm.toml` | generated | file | `cmp:canonical-pm-agent` |
| `cmp:generated-codex-spec-agent` | `.codex/agents/spec.toml` | generated | file | `cmp:canonical-spec-agent` |
| `cmp:generated-github-architect-agent` | `.github/agents/architect.agent.md` | generated | file | `cmp:canonical-architect-agent` |
| `cmp:generated-github-brainstorm-agent` | `.github/agents/brainstorm.agent.md` | generated | file | `cmp:canonical-brainstorm-agent` |
| `cmp:generated-github-code-reviewer-agent` | `.github/agents/code-reviewer.agent.md` | generated | file | `cmp:canonical-code-reviewer-agent` |
| `cmp:generated-github-coder-agent` | `.github/agents/coder.agent.md` | generated | file | `cmp:canonical-coder-agent` |
| `cmp:generated-github-dba-agent` | `.github/agents/dba.agent.md` | generated | file | `cmp:canonical-dba-agent` |
| `cmp:generated-github-frontend-designer-agent` | `.github/agents/frontend-designer.agent.md` | generated | file | `cmp:canonical-frontend-designer-agent` |
| `cmp:generated-github-plan-agent` | `.github/agents/plan.agent.md` | generated | file | `cmp:canonical-plan-agent` |
| `cmp:generated-github-pm-agent` | `.github/agents/pm.agent.md` | generated | file | `cmp:canonical-pm-agent` |
| `cmp:generated-github-skill-agentic-eval` | `.github/skills/agentic-eval/SKILL.md` | generated | file | `cmp:canonical-skill-agentic-eval` |
| `cmp:generated-github-skill-agentic-eval-reference-cli-evaluation-workflow` | `.github/skills/agentic-eval/references/cli-evaluation-workflow.md` | generated | file | `cmp:canonical-skill-agentic-eval-reference-cli-evaluation-workflow` |
| `cmp:generated-github-skill-agentic-eval-reference-python-patterns` | `.github/skills/agentic-eval/references/python-patterns.md` | generated | file | `cmp:canonical-skill-agentic-eval-reference-python-patterns` |
| `cmp:generated-github-skill-agentic-eval-reference-stage-rubrics` | `.github/skills/agentic-eval/references/stage-rubrics.md` | generated | file | `cmp:canonical-skill-agentic-eval-reference-stage-rubrics` |
| `cmp:generated-github-skill-backend-patterns` | `.github/skills/backend-patterns/SKILL.md` | generated | file | `cmp:canonical-skill-backend-patterns` |
| `cmp:generated-github-skill-brainstorming` | `.github/skills/brainstorming/SKILL.md` | generated | file | `cmp:canonical-skill-brainstorming` |
| `cmp:generated-github-skill-brainstorming-template-decision-log` | `.github/skills/brainstorming/templates/decision-log.md` | generated | file | `cmp:canonical-skill-brainstorming-template-decision-log` |
| `cmp:generated-github-skill-brainstorming-template-proposal` | `.github/skills/brainstorming/templates/proposal.md` | generated | file | `cmp:canonical-skill-brainstorming-template-proposal` |
| `cmp:generated-github-skill-brainstorming-template-tasks` | `.github/skills/brainstorming/templates/tasks.md` | generated | file | `cmp:canonical-skill-brainstorming-template-tasks` |
| `cmp:generated-github-skill-chrome-devtools` | `.github/skills/chrome-devtools/SKILL.md` | generated | file | `cmp:canonical-skill-chrome-devtools` |
| `cmp:generated-github-skill-ci-cd-and-automation` | `.github/skills/ci-cd-and-automation/SKILL.md` | generated | file | `cmp:canonical-skill-ci-cd-and-automation` |
| `cmp:generated-github-skill-code-security-review` | `.github/skills/code-security-review/SKILL.md` | generated | file | `cmp:canonical-skill-code-security-review` |
| `cmp:generated-github-skill-coding-standards` | `.github/skills/coding-standards/SKILL.md` | generated | file | `cmp:canonical-skill-coding-standards` |
| `cmp:generated-github-skill-context-engineering` | `.github/skills/context-engineering/SKILL.md` | generated | file | `cmp:canonical-skill-context-engineering` |
| `cmp:generated-github-skill-copilot-sdk` | `.github/skills/copilot-sdk/SKILL.md` | generated | file | `cmp:canonical-skill-copilot-sdk` |
| `cmp:generated-github-skill-debug` | `.github/skills/debug/SKILL.md` | generated | file | `cmp:canonical-skill-debug` |
| `cmp:generated-github-skill-excalidraw-diagram-generator` | `.github/skills/excalidraw-diagram-generator/SKILL.md` | generated | file | `cmp:canonical-skill-excalidraw-diagram-generator` |
| `cmp:generated-github-skill-excalidraw-diagram-generator-reference-element-types` | `.github/skills/excalidraw-diagram-generator/references/element-types.md` | generated | file | `cmp:canonical-skill-excalidraw-diagram-generator-reference-element-types` |
| `cmp:generated-github-skill-excalidraw-diagram-generator-reference-excalidraw-schema` | `.github/skills/excalidraw-diagram-generator/references/excalidraw-schema.md` | generated | file | `cmp:canonical-skill-excalidraw-diagram-generator-reference-excalidraw-schema` |
| `cmp:generated-github-skill-excalidraw-diagram-generator-script-` | `.github/skills/excalidraw-diagram-generator/scripts/.gitignore` | generated | file | `cmp:canonical-skill-excalidraw-diagram-generator-script-` |
| `cmp:generated-github-skill-excalidraw-diagram-generator-script-add-arrow` | `.github/skills/excalidraw-diagram-generator/scripts/add-arrow.py` | generated | file | `cmp:canonical-skill-excalidraw-diagram-generator-script-add-arrow` |
| `cmp:generated-github-skill-excalidraw-diagram-generator-script-add-icon-to-diagram` | `.github/skills/excalidraw-diagram-generator/scripts/add-icon-to-diagram.py` | generated | file | `cmp:canonical-skill-excalidraw-diagram-generator-script-add-icon-to-diagram` |
| `cmp:generated-github-skill-excalidraw-diagram-generator-script-readme` | `.github/skills/excalidraw-diagram-generator/scripts/README.md` | generated | file | `cmp:canonical-skill-excalidraw-diagram-generator-script-readme` |
| `cmp:generated-github-skill-excalidraw-diagram-generator-script-split-excalidraw-library` | `.github/skills/excalidraw-diagram-generator/scripts/split-excalidraw-library.py` | generated | file | `cmp:canonical-skill-excalidraw-diagram-generator-script-split-excalidraw-library` |
| `cmp:generated-github-skill-excalidraw-diagram-generator-template-business-flow-swimlane-template` | `.github/skills/excalidraw-diagram-generator/templates/business-flow-swimlane-template.excalidraw` | generated | file | `cmp:canonical-skill-excalidraw-diagram-generator-template-business-flow-swimlane-template` |
| `cmp:generated-github-skill-excalidraw-diagram-generator-template-class-diagram-template` | `.github/skills/excalidraw-diagram-generator/templates/class-diagram-template.excalidraw` | generated | file | `cmp:canonical-skill-excalidraw-diagram-generator-template-class-diagram-template` |
| `cmp:generated-github-skill-excalidraw-diagram-generator-template-data-flow-diagram-template` | `.github/skills/excalidraw-diagram-generator/templates/data-flow-diagram-template.excalidraw` | generated | file | `cmp:canonical-skill-excalidraw-diagram-generator-template-data-flow-diagram-template` |
| `cmp:generated-github-skill-excalidraw-diagram-generator-template-er-diagram-template` | `.github/skills/excalidraw-diagram-generator/templates/er-diagram-template.excalidraw` | generated | file | `cmp:canonical-skill-excalidraw-diagram-generator-template-er-diagram-template` |
| `cmp:generated-github-skill-excalidraw-diagram-generator-template-flowchart-template` | `.github/skills/excalidraw-diagram-generator/templates/flowchart-template.excalidraw` | generated | file | `cmp:canonical-skill-excalidraw-diagram-generator-template-flowchart-template` |
| `cmp:generated-github-skill-excalidraw-diagram-generator-template-mindmap-template` | `.github/skills/excalidraw-diagram-generator/templates/mindmap-template.excalidraw` | generated | file | `cmp:canonical-skill-excalidraw-diagram-generator-template-mindmap-template` |
| `cmp:generated-github-skill-excalidraw-diagram-generator-template-relationship-template` | `.github/skills/excalidraw-diagram-generator/templates/relationship-template.excalidraw` | generated | file | `cmp:canonical-skill-excalidraw-diagram-generator-template-relationship-template` |
| `cmp:generated-github-skill-excalidraw-diagram-generator-template-sequence-diagram-template` | `.github/skills/excalidraw-diagram-generator/templates/sequence-diagram-template.excalidraw` | generated | file | `cmp:canonical-skill-excalidraw-diagram-generator-template-sequence-diagram-template` |
| `cmp:generated-github-skill-execution-guardrails` | `.github/skills/execution-guardrails/SKILL.md` | generated | file | `cmp:canonical-skill-execution-guardrails` |
| `cmp:generated-github-skill-execution-guardrails-reference-anti-patterns` | `.github/skills/execution-guardrails/references/anti-patterns.md` | generated | file | `cmp:canonical-skill-execution-guardrails-reference-anti-patterns` |
| `cmp:generated-github-skill-execution-guardrails-reference-stage-usage` | `.github/skills/execution-guardrails/references/stage-usage.md` | generated | file | `cmp:canonical-skill-execution-guardrails-reference-stage-usage` |
| `cmp:generated-github-skill-explore` | `.github/skills/explore/SKILL.md` | generated | file | `cmp:canonical-skill-explore` |
| `cmp:generated-github-skill-frontend-patterns` | `.github/skills/frontend-patterns/SKILL.md` | generated | file | `cmp:canonical-skill-frontend-patterns` |
| `cmp:generated-github-skill-gh-cli` | `.github/skills/gh-cli/SKILL.md` | generated | file | `cmp:canonical-skill-gh-cli` |
| `cmp:generated-github-skill-git-commit` | `.github/skills/git-commit/SKILL.md` | generated | file | `cmp:canonical-skill-git-commit` |
| `cmp:generated-github-skill-github-issues` | `.github/skills/github-issues/SKILL.md` | generated | file | `cmp:canonical-skill-github-issues` |
| `cmp:generated-github-skill-github-issues-reference-templates` | `.github/skills/github-issues/references/templates.md` | generated | file | `cmp:canonical-skill-github-issues-reference-templates` |
| `cmp:generated-github-skill-implementation-planning` | `.github/skills/implementation-planning/SKILL.md` | generated | file | `cmp:canonical-skill-implementation-planning` |
| `cmp:generated-github-skill-make-skill-template` | `.github/skills/make-skill-template/SKILL.md` | generated | file | `cmp:canonical-skill-make-skill-template` |
| `cmp:generated-github-skill-markdown-to-html` | `.github/skills/markdown-to-html/SKILL.md` | generated | file | `cmp:canonical-skill-markdown-to-html` |
| `cmp:generated-github-skill-markdown-to-html-reference-basic-markdown` | `.github/skills/markdown-to-html/references/basic-markdown.md` | generated | file | `cmp:canonical-skill-markdown-to-html-reference-basic-markdown` |
| `cmp:generated-github-skill-markdown-to-html-reference-basic-markdown-to-html` | `.github/skills/markdown-to-html/references/basic-markdown-to-html.md` | generated | file | `cmp:canonical-skill-markdown-to-html-reference-basic-markdown-to-html` |
| `cmp:generated-github-skill-markdown-to-html-reference-code-blocks` | `.github/skills/markdown-to-html/references/code-blocks.md` | generated | file | `cmp:canonical-skill-markdown-to-html-reference-code-blocks` |
| `cmp:generated-github-skill-markdown-to-html-reference-code-blocks-to-html` | `.github/skills/markdown-to-html/references/code-blocks-to-html.md` | generated | file | `cmp:canonical-skill-markdown-to-html-reference-code-blocks-to-html` |
| `cmp:generated-github-skill-markdown-to-html-reference-collapsed-sections` | `.github/skills/markdown-to-html/references/collapsed-sections.md` | generated | file | `cmp:canonical-skill-markdown-to-html-reference-collapsed-sections` |
| `cmp:generated-github-skill-markdown-to-html-reference-collapsed-sections-to-html` | `.github/skills/markdown-to-html/references/collapsed-sections-to-html.md` | generated | file | `cmp:canonical-skill-markdown-to-html-reference-collapsed-sections-to-html` |
| `cmp:generated-github-skill-markdown-to-html-reference-gomarkdown` | `.github/skills/markdown-to-html/references/gomarkdown.md` | generated | file | `cmp:canonical-skill-markdown-to-html-reference-gomarkdown` |
| `cmp:generated-github-skill-markdown-to-html-reference-hugo` | `.github/skills/markdown-to-html/references/hugo.md` | generated | file | `cmp:canonical-skill-markdown-to-html-reference-hugo` |
| `cmp:generated-github-skill-markdown-to-html-reference-jekyll` | `.github/skills/markdown-to-html/references/jekyll.md` | generated | file | `cmp:canonical-skill-markdown-to-html-reference-jekyll` |
| `cmp:generated-github-skill-markdown-to-html-reference-marked` | `.github/skills/markdown-to-html/references/marked.md` | generated | file | `cmp:canonical-skill-markdown-to-html-reference-marked` |
| `cmp:generated-github-skill-markdown-to-html-reference-pandoc` | `.github/skills/markdown-to-html/references/pandoc.md` | generated | file | `cmp:canonical-skill-markdown-to-html-reference-pandoc` |
| `cmp:generated-github-skill-markdown-to-html-reference-tables` | `.github/skills/markdown-to-html/references/tables.md` | generated | file | `cmp:canonical-skill-markdown-to-html-reference-tables` |
| `cmp:generated-github-skill-markdown-to-html-reference-tables-to-html` | `.github/skills/markdown-to-html/references/tables-to-html.md` | generated | file | `cmp:canonical-skill-markdown-to-html-reference-tables-to-html` |
| `cmp:generated-github-skill-markdown-to-html-reference-writing-mathematical-expressions` | `.github/skills/markdown-to-html/references/writing-mathematical-expressions.md` | generated | file | `cmp:canonical-skill-markdown-to-html-reference-writing-mathematical-expressions` |
| `cmp:generated-github-skill-markdown-to-html-reference-writing-mathematical-expressions-to-html` | `.github/skills/markdown-to-html/references/writing-mathematical-expressions-to-html.md` | generated | file | `cmp:canonical-skill-markdown-to-html-reference-writing-mathematical-expressions-to-html` |
| `cmp:generated-github-skill-microsoft-code-reference` | `.github/skills/microsoft-code-reference/SKILL.md` | generated | file | `cmp:canonical-skill-microsoft-code-reference` |
| `cmp:generated-github-skill-microsoft-docs` | `.github/skills/microsoft-docs/SKILL.md` | generated | file | `cmp:canonical-skill-microsoft-docs` |
| `cmp:generated-github-skill-prd` | `.github/skills/prd/SKILL.md` | generated | file | `cmp:canonical-skill-prd` |
| `cmp:generated-github-skill-python-patterns` | `.github/skills/python-patterns/SKILL.md` | generated | file | `cmp:canonical-skill-python-patterns` |
| `cmp:generated-github-skill-refactor` | `.github/skills/refactor/SKILL.md` | generated | file | `cmp:canonical-skill-refactor` |
| `cmp:generated-github-skill-scoutqa-test` | `.github/skills/scoutqa-test/SKILL.md` | generated | file | `cmp:canonical-skill-scoutqa-test` |
| `cmp:generated-github-skill-security-review` | `.github/skills/security-review/SKILL.md` | generated | file | `cmp:canonical-skill-security-review` |
| `cmp:generated-github-skill-security-review-asset-cloud-infrastructure-security` | `.github/skills/security-review/cloud-infrastructure-security.md` | generated | file | `cmp:canonical-skill-security-review-asset-cloud-infrastructure-security` |
| `cmp:generated-github-skill-shipping-and-launch` | `.github/skills/shipping-and-launch/SKILL.md` | generated | file | `cmp:canonical-skill-shipping-and-launch` |
| `cmp:generated-github-skill-specification` | `.github/skills/specification/SKILL.md` | generated | file | `cmp:canonical-skill-specification` |
| `cmp:generated-github-skill-specification-reference-ac-format-guide` | `.github/skills/specification/references/ac-format-guide.md` | generated | file | `cmp:canonical-skill-specification-reference-ac-format-guide` |
| `cmp:generated-github-skill-specification-reference-consult-review-protocol` | `.github/skills/specification/references/consult-review-protocol.md` | generated | file | `cmp:canonical-skill-specification-reference-consult-review-protocol` |
| `cmp:generated-github-skill-specification-reference-specialist-lens-review` | `.github/skills/specification/references/specialist-lens-review.md` | generated | file | `cmp:canonical-skill-specification-reference-specialist-lens-review` |
| `cmp:generated-github-skill-tdd-workflow` | `.github/skills/tdd-workflow/SKILL.md` | generated | file | `cmp:canonical-skill-tdd-workflow` |
| `cmp:generated-github-skill-web-design-reviewer` | `.github/skills/web-design-reviewer/SKILL.md` | generated | file | `cmp:canonical-skill-web-design-reviewer` |
| `cmp:generated-github-skill-web-design-reviewer-reference-framework-fixes` | `.github/skills/web-design-reviewer/references/framework-fixes.md` | generated | file | `cmp:canonical-skill-web-design-reviewer-reference-framework-fixes` |
| `cmp:generated-github-skill-web-design-reviewer-reference-visual-checklist` | `.github/skills/web-design-reviewer/references/visual-checklist.md` | generated | file | `cmp:canonical-skill-web-design-reviewer-reference-visual-checklist` |
| `cmp:generated-github-skill-webapp-testing` | `.github/skills/webapp-testing/SKILL.md` | generated | file | `cmp:canonical-skill-webapp-testing` |
| `cmp:generated-github-skill-webapp-testing-asset-test-helper` | `.github/skills/webapp-testing/test-helper.js` | generated | file | `cmp:canonical-skill-webapp-testing-asset-test-helper` |
| `cmp:generated-github-skill-work-archiving` | `.github/skills/work-archiving/SKILL.md` | generated | file | `cmp:canonical-skill-work-archiving` |
| `cmp:generated-github-skill-workflow-orchestrator` | `.github/skills/workflow-orchestrator/SKILL.md` | generated | file | `cmp:canonical-skill-workflow-orchestrator` |
| `cmp:generated-github-spec-agent` | `.github/agents/spec.agent.md` | generated | file | `cmp:canonical-spec-agent` |
| `cmp:project-agents-guide` | `AGENTS.md` | project-owned | file | — |
| `cmp:project-claude-guide` | `CLAUDE.md` | project-owned | file | — |
| `cmp:project-gemini-guide` | `GEMINI.md` | project-owned | file | — |


#### Exact Phase 4A Allowlist

Sol may modify only governance/status evidence:

- `changes/workflow-agents-responsibility-alignment/02-decision-log.md`
- `changes/workflow-agents-responsibility-alignment/04-plan.md`
- `changes/workflow-agents-responsibility-alignment/phase-4-manifest-schema-proposal.md` (implementation status only)

Luna may create or modify only these exact product paths:

- `schemas/ai-workflow-install-manifest-v3.schema.json`
- `manifest/component-catalog.json`
- `scripts/bootstrap.py`
- `scripts/bootstrap.ps1`
- `scripts/tests/test_bootstrap.py`
- `scripts/bootstrap.Tests.ps1`
- `scripts/tests/manifest-v3-vectors.json`

No helper file is allowed or needed: both bootstrap entry points are currently standalone distribution surfaces, so an external runtime helper would add an unapproved availability/deployment dependency. `scripts/tests/manifest-v3-vectors.json` is the one shared non-production vector file in the existing `scripts/tests` directory. Candidate Schema, candidate examples, CI workflows, gates, lifecycle assets, Agents, Skills, Prompts, Instructions, `bootstrap.sh`, and unrelated files are immutable in Phase 4A.

#### Phase 4A Local Verification Evidence

- **Luna / TDD**: The sole built-in `worker` was requested as GPT-5.6 / medium; observed model and effort are unknown. Initial RED was Python `2 failed / 1 passed / 92 deselected` and Pester `3 failed / 1 passed / 49 not run`. The final correction RED was Python `15 failed / 62 passed / 92 deselected` and Pester `16 failed / 61 passed / 49 not run`. Luna changed only the seven exact product paths and performed no Git, governance, or remote action.
- **Correction round 1**: Replaced the invalid 80-parent Skill-mount mapping with the approved `cmp:canonical-skills-root` directory identity. The Catalog became 253 reviewed identities without changing any approved Schema rule.
- **Correction round 2**: Required complete Production Schema plus exact Catalog validation before `valid-v3`; added the non-valid `v3-validation-blocked` / `catalog-unavailable` outcome, authoritative shared vectors, corrupt/unsupported all-route blocking, Catalog/Manifest parity fixes, and PowerShell remote source-artifact acquisition/revalidation/cleanup before adopter mutation.
- **Production Schema**: `schemas/ai-workflow-install-manifest-v3.schema.json` is Draft 2020-12 with `$id` `urn:ai-dev-workflow:manifest-schema:v3`. Its parsed object is deep-equal to the approved Candidate after only the four allowlisted transformations. Runtime code does not reference the Candidate path.
- **Stable Catalog**: `manifest/component-catalog.json` has 253 components: 101 canonical, 110 generated, 3 project-owned, and 39 compatibility; 249 files, one directory, and three mounts. It exactly matches the normative table and retains allocation fingerprint `sha256:4e68c7431da961b126748b2a3fb110e9dc52094cf1a958b64528337422800c66`.
- **Candidate invariance**: Candidate Schema SHA-256 remains `sha256:c4623a55745d816494c1623eb242961b5ea0a458bd8f7cdabd9fcda73f6de886`; all nine approved examples are byte-identical to starting `main`. All seven v3 examples pass the Python semantic validator without source binding and the Production Schema structural validator after removing only proposal-only metadata.
- **Reader / writer boundary**: Fully Schema/Catalog-bound v3 returns `valid-v3`; source-unavailable v3 returns `v3-validation-blocked`, never `valid-v3`. Install, update, force, and update-force paths block valid-v3, corrupt, and unsupported inputs before adopter writes. v1/v2 remain read-only compatible. Both production writers still emit schema version 2.
- **Zero-write evidence**: Python and PowerShell isolated route tests preserve exact Manifest/sentinel bytes, file and directory inventory, and absence of backup or `.git` creation across all four routes. PowerShell remote revalidation uses local fixtures/static sparse-set evidence; no live network or real adopter operation was executed.
- **Sol independent findings**: Critical findings (premature `valid-v3`; optional Schema/Catalog validation; incomplete remote source acquisition) and High findings (corrupt/unsupported non-update mutation risk; non-authoritative vectors; cross-runtime bounds/timestamp/role-kind/type parity) were resolved in correction round 2. Medium: none. Low/warning-only: historical `05-review.md` alias, `pm/spec` soft line-count warnings, and the environment `pytest-asyncio` deprecation warning. No unresolved Critical or High finding, scope leakage, Schema drift, Catalog identity conflict, downgrade path, or unauthorized behavior remains.
- **Sol verification**: focused Python `91 passed`; focused Pester `91 passed / 0 failed / 0 skipped`; full Python `170 passed`; full Pester `259 passed / 0 failed / 0 skipped / 0 not run / 0 inconclusive / 0 failed containers`; sync, catalog, lifecycle, Change Package, Agent structure, JSON parse, Python compile, and `git diff --check` all passed. The first complete gate returned `GATE PASSED WITH NOTES`; its 10-path outer SHA-256 snapshot was identical before and after (`008b06c97a5e2707c39ba4a5a3b2b7b6c343d3c018ada7c47865ad7cb47f702a`). The required post-note full-gate rerun is a commit precondition.
- **High-Risk gates**: Architecture Decision Exit — PASS; A-07 remains the exact approved architecture. Pre-Implementation Readiness — PASS; A-08, prerequisites, mapping, allowlist, RED/GREEN path, ownership, and rollback boundary were explicit. Pre-Delivery Verification — PASS for product, scope, independent review, and deterministic evidence, with the logged warning-only note and post-note full-gate rerun required before commit. Migration / Deployment Readiness — `N/A — no migration, deployment, writer enablement, prune, or real-adopter execution is authorized in Phase 4A.`
- **Delivery boundary**: One main local commit and one non-Draft PR remain pending. Phase 4A is not merged yet and must not be called complete. Phase 4 overall remains incomplete; Phase 4B, writer enablement, migration, tombstone mutation, prune, real-adopter operation, and Phase 5 remain unauthorized.

### Validated Current-State Inventory for the Proposal

Facts verified once from the current Python/PowerShell implementations, tests, and tracked v1 artifact:

- Both readers support exactly schema versions 1 and 2. Both writers currently emit schema version 2.
- The tracked v1 artifact has top-level `schema_version`, `installed_at`, `source_ref`, and `components`; all 58 observed components have `name`, `installed_at`, and `source_hash`. Twenty-seven hashes are present and 31 are null.
- The current v2 writer emits the same four top-level fields. A writer-produced component contains `name`, `installed_at`, `updated_at`, `source_hash`, `managed_hash`, `observed_hash`, `ownership`, `kind`, `source`, and `status`.
- Both readers validate the top-level object, integer/supported schema version, component array, component object, non-empty string `name`, and exact case-sensitive duplicate `name`. They do not enforce version-specific component shapes, normalize reader identities, reject traversal/case-colliding identities, validate hash syntax, or reject unknown fields.
- Current writers normalize separators and leading `./` only when recording a path; the normalization functions explicitly do not sanitize parent traversal. Reader keys retain the persisted spelling.
- Current hash production is SHA-256 over exact bytes with a lowercase `sha256:` prefix. The tracked v1 artifact contains uppercase digest text, which both readers accept because neither validates hash encoding. No text normalization occurs inside the hash functions; selected text sources are normalized before bytes are passed to them.
- On new, in-sync, or approved current update writes, `source_hash` and `managed_hash` are both set to the desired managed hash and `observed_hash` is set to the resulting target hash. On preserved customization or conflict, the managed/source hash retains the previous baseline while `observed_hash` records current target content. A successful update replaces the old baseline, so the present schema cannot preserve baseline, pre-operation observation, proposed source, and result as distinct time points.
- Observed ownership values are `template-managed`, `project-owned`, `derived-runtime`, and `legacy-compat`; observed kinds are `file` and `mount`; observed statuses are `managed`, `in-sync`, `preserved-existing`, `preserved-customization`, `conflicted`, `project-owned`, and `derived-runtime`. These are writer conventions, not reader-enforced enums.
- Derived Agent/Skill files record `derived-runtime` plus a `project:` source label. Skill mounts record kind `mount` with null hashes. Directories are not independently recorded as current v2 components.
- Loader outcomes are runtime-only `valid`, `missing`, `corrupt`, or `unsupported`. Missing update is warning/report-only; corrupt and unsupported update hard-stop before managed writes. Any invalid component makes the whole manifest corrupt with empty entries; neither loader rewrites the manifest to record failure.
- Valid v1 and v2 are normalized only into an in-memory exact-name entry map. A later successful update may write v2; read-only loading does not migrate or rewrite.
- Canonical rename/delete currently has no reconciliation pass. Old manifest entries and attributable derived files can remain; there is no `generated_from`, fork classification, source-release provenance beyond top-level `source_ref`, retirement/tombstone, stale report, or safe-prune proof model.
- Python and PowerShell agree on the supported versions, required loader checks, state classes, writer version, top/component field names, hash algorithm, main ownership/kind/status conventions, and update containment. Their JSON formatting, timestamp rendering, and file-writing mechanisms differ; neither writer is atomic or fsync-backed.
- Fixture sufficiency: the tracked repository manifest is direct v1 evidence; equivalent Python/Pester tests prove minimal v1/v2 readability and failure states; the complete v2 shape is directly reconstructable from both current production writers. The proposed v2 example must be labeled writer-derived non-runtime evidence, not a captured real-adopter artifact.

### Exact Proposal Allowlist

Sol alone may update:

- `changes/workflow-agents-responsibility-alignment/02-decision-log.md` (proposal pointer and required gate note only; no approved Amendment)
- `changes/workflow-agents-responsibility-alignment/04-plan.md`

Luna may create or modify only:

- `changes/workflow-agents-responsibility-alignment/phase-4-manifest-schema-proposal.md`
- `changes/workflow-agents-responsibility-alignment/phase-4-manifest-v3.schema.proposed.json`
- `changes/workflow-agents-responsibility-alignment/phase-4-schema-examples/valid-v1-observed.json`
- `changes/workflow-agents-responsibility-alignment/phase-4-schema-examples/valid-v2-observed.json`
- `changes/workflow-agents-responsibility-alignment/phase-4-schema-examples/valid-v3-proposed.json`
- `changes/workflow-agents-responsibility-alignment/phase-4-schema-examples/v3-customized-component.json`
- `changes/workflow-agents-responsibility-alignment/phase-4-schema-examples/v3-derived-component.json`
- `changes/workflow-agents-responsibility-alignment/phase-4-schema-examples/v3-retired-component.json`
- `changes/workflow-agents-responsibility-alignment/phase-4-schema-examples/v3-stale-but-modified.json`
- `changes/workflow-agents-responsibility-alignment/phase-4-schema-examples/v3-prune-eligible-proposed.json`
- `changes/workflow-agents-responsibility-alignment/phase-4-schema-examples/v3-reintroduced-component.json`

If this exact allowlist cannot express a complete, internally consistent proposal, Luna must stop and report the missing path and contract reason. No production path, test, gate, installer, generated mirror, decision-log amendment, or additional artifact is implicitly allowed.

### Approval-Blocking Correction Scope

- **Baseline**: PR #11 remains open and non-Draft at expected head `5bf032b4747839541d201dc86b96d2ddd18a805b`; local/remote proposal branch match; local/origin `main` remain `f8a0116ce4af0b463c838150350a9ccfa7c2cac6`; existing CI is successful; reviews and review threads are empty.
- **Tombstone identity**: Tombstoned component IDs are terminal and permanently reserved. A separately authorized future reintroduction receives a new ID and uses a non-authorizing relationship to the unchanged tombstoned component.
- **Stable-ID catalog**: The proposal must define `manifest/component-catalog.json` as the single version-controlled source-side allocation SSOT; neither runtime may independently derive IDs, and legacy ambiguity remains report-only.
- **Production schema boundary**: The proposal must define `schemas/ai-workflow-install-manifest-v3.schema.json` with stable `$id` `urn:ai-dev-workflow:manifest-schema:v3` as the future production artifact while retaining the Change Package candidate, proposal marker, and `example.invalid` identity in this PR.
- **Delivery boundary**: Luna is the only Proposal product writer. Sol owns governance, audit, one non-amended follow-up commit, normal push, PR/CI verification, and the mandatory stop with PR #11 still open. No production reader/writer/test/gate, schema emission, migration, prune, real-adopter operation, merge, or Phase 5 work is authorized.

### Approval-Blocking Correction Evidence

- Luna used the existing built-in `worker` as the only Proposal product writer; requested model GPT-5.6 and reasoning effort medium; observed model/effort unknown; no configuration change. Luna changed exactly the Proposal, candidate schema, six existing candidate-v3 examples, and new `v3-reintroduced-component.json`; v1/v2 examples and all production/test/gate paths remained unchanged.
- Luna recorded RED evidence for the absent terminal-tombstone/new-ID relationship, absent fixed component-catalog SSOT/binding, and absent production schema identity/transformation contract. GREEN added `lifecycle.reintroduces_component_id`, catalog binding on all seven candidate-v3 examples, the reintroduction example, exact catalog allocation rules, future production path/URN, and updated OD-02/OD-03/OD-07 while retaining `PROPOSED — NOT APPROVED — NOT IMPLEMENTED`.
- Sol independently reviewed the actual Proposal/schema/example diffs. Two Medium ambiguities were returned to the same Luna and resolved: component `last_operation` may predate top-level `last_transaction`, and marker-free production vectors remove only top-level `proposal_status` before applying the same scenario/negative mutations. Current audit: 0 Critical, 0 High, 0 unresolved Medium.
- Sol JSON/schema validation parsed the candidate plus seven candidate-v3 examples and accepted all 7/7 examples. Focused validation rejected 5/5 structural schema negatives, 8/8 Manifest semantic negatives, and 4/4 catalog semantic negatives; two positive semantic models and the candidate/production boundary passed.
- The final intended correction scope is exactly nine Luna product paths plus Sol-owned `02-decision-log.md` and `04-plan.md`. Candidate Draft 2020-12 remains under `example.invalid` with its proposal marker; no `manifest/component-catalog.json` or `schemas/ai-workflow-install-manifest-v3.schema.json` production artifact is created in this PR.
- Existing Python regression passed 92 tests; full Pester 5.6.1 passed 181 tests with 0 failed/skipped/not-run; direct sync, catalog, lifecycle, Change Package, and Agent checks passed; `git diff --check` passed. The stable-diff full repository gate returned `GATE PASSED WITH NOTES`, limited to the recorded Agent line-count warnings, and preserved branch, HEAD, status, path, byte length, and SHA-256 invariance for all 11 changed paths.
- Rule-based gates: Architecture Decision Exit — pass for proposal correction review; Pre-Implementation Readiness — `N/A — this task contains proposal correction only; Phase 4 implementation is not authorized`; Pre-Delivery Verification — pass; Migration / Deployment Readiness — `N/A — no migration or deployment execution is authorized in this task.` Deterministic failure remains blocking and cannot be overridden by this review evidence or `agentic-eval`.

### Local Proposal Verification Evidence

- Luna used the built-in `worker` as the sole proposal writer, with requested model GPT-5.6 and reasoning effort medium; observed model and effort are unknown because the runtime exposes no auditable value. No configuration was changed.
- Luna created exactly the ten proposal/schema/example paths in the allowlist. One bounded correction round resolved three High, five Medium, and one Low proposal findings; Luna performed no Git, remote, governance, production-code, test, installer, or gate change.
- Sol independently inspected the current Python and PowerShell implementations, v1 artifact, v2 writer contract, complete proposal, machine-readable candidate, and all eight examples. Current unresolved findings are 0 Critical, 0 High, and 0 Medium; residual Low notes are limited to future semantic checks that JSON Schema alone cannot express and use of existing standard parsers because no new validation dependency is authorized.
- Proposal validation parsed the candidate schema and all eight examples as JSON; accepted all six candidate-v3 examples; rejected five representative invalid vectors; confirmed eight exact fork-classification evidence mappings, 18 required proposal sections, eight proposal markers, normalized/sorted unique component identities, valid references, and required transaction relationships.
- Python regression: 92 passed. Full Pester 5.6.1 regression: 181 passed, 0 failed, 0 skipped, 0 not run. The existing `pytest-asyncio` future-default warning remained nonblocking.
- Direct repository checks passed: sync; catalog (9 Agents, 10 Prompts, 35 Skills, 34 adopter Skills, one maintainer-only gate Skill, and 9 templates); lifecycle (19 root markers, 19 projection markers, 9 templates); Change Package verification for 8 packages; and Agent structure with no hard finding. The historical legacy `05-review.md` and two soft Agent line-count findings remained warning-only.
- `git diff --check` passed. The full repository gate returned `GATE PASSED WITH NOTES`; every required Python, Pester, sync, catalog, lifecycle, package, Agent-structure, and diff check passed. The gate note is recorded in `02-decision-log.md`; this governance record does not replace the required final stable-diff rerun before commit.
- Pre-gate and post-gate worktree inventories were identical by branch, HEAD, status, path, byte length, and SHA-256 for all then-changed paths. Final scope is restricted to the ten proposal artifacts plus Sol-owned `02-decision-log.md` and `04-plan.md`; production code, tests, runtime schema acceptance/emission, migration, prune, real-adopter operations, and Phase 5 remain unchanged.
- Rule-based gates: Architecture Decision Exit — pass for proposal delivery; Pre-Implementation Readiness — `N/A — this Phase contains a schema proposal only; product implementation is not authorized`; Pre-Delivery Verification — pass subject to the final stable-diff rerun; Migration / Deployment Readiness — `N/A — no migration or deployment execution is authorized in this Phase.`
- `agentic-eval` is a Tier 1 self-evaluation scheduled only after deterministic checks; it cannot serve as independent review or override any failure. Sol's direct audit of Luna's artifacts is the independent proposal review.

### Objective

Design and implement D-05/D-06 with versioned migration, provenance, dry-run retirement, and safe prune controls.

### Decisions and Defects

- D-05
- D-06
- C-04 full fix
- C-05

### Prerequisites

- Separate schema proposal and user approval.
- Validated inventory of v1/v2 and legacy states.
- Explicit safe-prune UX decision.

### Exact Scope

- Define versioned schema and migration semantics.
- Preserve previous baseline, observed/new hashes, source version, ownership, fork status, generation relation, retirement, and parse state.
- Detect canonical rename/delete and report stale outputs.
- Implement dry-run/tombstone behavior.
- Implement prune only behind explicit user authorization and all D-05 proofs.

### Expected Canonical Files

- `scripts/bootstrap.py`
- `scripts/bootstrap.ps1`
- Manifest schema/migration documentation or code-owned schema representation
- Installer tests and fixtures

### Expected Generated Files

- Test fixtures only until an adopter migration is separately authorized.

### Bootstrap / Manifest Impact

- New schema version and compatibility reader.
- Provenance and retirement reporting.

### Migration Classes

- Valid v1.
- Valid v2.
- Missing legacy.
- Corrupt/unsupported.
- Untouched/customized fork.
- Retired canonical/derived output.

### Required Tests

- v1/v2 migration and round-trip.
- Corrupt/unsupported hard stop before writes.
- Missing legacy report-only.
- Fork classification.
- Rename/delete stale report.
- Modified derived output not pruned.
- Approved safe prune path.
- Python/PowerShell parity on Windows and Ubuntu.

### Rollback

Keep readers backward-compatible; rollback writer emission without discarding previously recorded lineage. Never downgrade by silently removing new provenance.

### Hard Exclusions

- No automatic migration execution against real adopters.
- No prune without task-scoped approval.
- No adapter redesign.

### Approval and PR Boundary

Schema approval, implementation approval, and any real prune approval are separate decisions. Separate PR required.

## Phase 5 — Cross-CLI Evidence and Adapter Proposal

### Objective

Resolve D-10 through current official evidence before proposing runtime changes.

### Decisions and Defects

- D-10

### Prerequisites

- Explicit authorization for external official-document research.
- Approved canonical capability contract from earlier phases.

### Exact Scope

- Verify AGENTS/rules loading, Skill discovery/invocation, custom-agent support, generated format, and fallback behavior for each surface.
- Produce a capability/evidence matrix.
- Identify unsupported or uncertain capabilities.
- Propose adapters without implementing them.

### Expected Canonical Files

- Evidence/architecture documentation selected in the separately approved phase.

### Expected Generated Files

- None during evidence collection.

### Bootstrap / Manifest Impact

- None until an adapter proposal is separately approved.

### Migration Classes

- New and existing adopters evaluated only after adapter design approval.

### Required Tests

- Evidence traceability to current official sources.
- Fallback contract for each unsupported capability.
- No lifecycle/quality semantic downgrade.

### Rollback

N/A for evidence-only work; discard unapproved adapter proposals.

### Hard Exclusions

- No runtime implementation.
- No derived regeneration.
- No unverified capability claim.

### Approval and PR Boundary

Evidence collection and adapter implementation require separate approvals and separate PRs.

## Phase 6 — Bash Deprecation Completion

### Objective

Complete D-11 after migration evidence establishes that supported users can move safely to Python.

### Decisions and Defects

- D-11 completion

### Prerequisites

- Phase 0B completed.
- Linux/macOS Python path validated.
- Usage/removal impact reviewed.

### Exact Scope

- Decide final wrapper retention or removal timing.
- Finalize Linux/macOS migration guidance and support matrix.
- Remove stale parity claims.
- If retained, make Bash a thin Python delegator with no independent update logic.

### Expected Canonical Files

- `scripts/bootstrap.sh`
- Support/migration documentation
- Focused shell/Python integration tests

### Expected Generated Files

- None.

### Bootstrap / Manifest Impact

- Python remains the ownership/manifest implementation for Linux/macOS.

### Migration Classes

- Existing Bash users receive explicit migration path.
- Automated callers receive documented exit/change behavior.

### Required Tests

- Linux/Ubuntu invocation.
- Delegation or removal behavior.
- No independent force/update path.
- Documentation/support matrix consistency.

### Rollback

Retain the deprecated refusal wrapper if immediate removal breaks supported discovery; never restore unsafe independent update logic.

### Hard Exclusions

- No full Bash parity rewrite.
- No separate Bash manifest implementation.

### Approval and PR Boundary

Separate user approval and separate PR required.

## Implementation Start Gate

No phase may start until the user explicitly names and approves that phase. Approval of this Change Package is not implementation authorization.
