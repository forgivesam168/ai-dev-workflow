# 04 Plan — Workflow–AGENTS Responsibility Alignment

## Plan Status

- **Status**: Approved architecture; implementation not started
- **Task/status SSOT**: This file
- **External tracker**: None
- **Execution rule**: One phase requires separate user approval, implementation, verification, review, and PR boundary before the next phase begins.
- **Current active phase**: None

## Phase Status Summary

| Phase | Status | Separate approval | Separate PR |
|---|---|---|---|
| 0A — Adopter constitution containment | Pending | Required | Required |
| 0B — Bash update safety | Pending | Required | Required |
| 0C — Manifest parse safety containment | Pending | Required | Required |
| 0D — Archive authorization containment | Pending | Required | Required |
| 1 — AGENTS / WORKFLOW / risk contract | Pending | Required | Required |
| 2 — Agent / Skill / Prompt / Instruction alignment | Pending | Required | Required |
| 3 — Change Package / Review / Archive semantics | Pending | Required | Required |
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

## Phase 2 — Agent / Skill / Prompt / Instruction Alignment

### Objective

Enforce the persona/behavior/router/scoped-instruction boundary without changing approved lifecycle semantics.

### Decisions and Defects

- D-04
- D-09 representation consistency

### Prerequisites

- Phase 1 Workflow and gate contract accepted.
- Structural Agent contract approved.

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

Separate user approval and separate PR required; large Agent groups may require multiple non-overlapping PRs.

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
