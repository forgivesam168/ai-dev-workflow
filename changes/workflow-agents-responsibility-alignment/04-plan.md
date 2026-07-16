# 04 Plan — Workflow–AGENTS Responsibility Alignment

## Plan Status

- **Status**: Phase 3 local implementation verified; PR pending
- **Task/status SSOT**: This file
- **External tracker**: None
- **Execution rule**: One phase requires separate user approval, implementation, verification, review, and PR boundary before the next phase begins.
- **Current active phase**: Phase 3 — Change Package / Review / Archive Semantics

## Phase Status Summary

| Phase | Status | Separate approval | Separate PR |
|---|---|---|---|
| 0A — Adopter constitution containment | Merged | Required | Required |
| 0B — Bash update safety | Merged | Required | Required |
| 0C — Manifest parse safety containment | Merged | Required | Required |
| 0D — Archive authorization containment | Merged | Required | Required |
| 1 — AGENTS / WORKFLOW / risk contract | Merged | Required | Required |
| 2 — Agent / Skill / Prompt / Instruction alignment | Merged | Required | Required |
| 3 — Change Package / Review / Archive semantics | Local implementation verified; PR pending | Required | Required |
| 4 — Manifest / provenance / stale-derived migration | Pending | Required | Required |
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

## Phase 4 — Manifest / Provenance / Stale-Derived Migration

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
