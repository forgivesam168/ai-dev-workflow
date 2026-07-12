# 02 Decision Log — Workflow–AGENTS Responsibility Alignment

> Append-only. Amendments must be added as new entries; do not rewrite approved history.

## Approval Record

- **Source**: Current Alignment approval instruction
- **Scope**: Architecture directions D-01 through D-11 and authorization to create this Change Package only
- **Not authorized**: Implementation, commit, push, PR, migration, derived regeneration, or remote actions

## D-01 — Global / Project AGENTS Boundary

- **Status**: APPROVED
- **Direction**: Global AGENTS retains complete cross-repository governance, authorization, A–D checkpoints, and completion honesty. Adopter Project AGENTS contains project-specific rules plus approximately 6–10 minimum fallback rules.
- **Rationale**: Project behavior must remain safe without Global AGENTS while avoiding a complete duplicated governance document.
- **Constraints**: Bootstrap never installs or updates user-level Global AGENTS.
- **Migration implication**: Existing Project AGENTS is project-owned; provide a manual alignment proposal, never unconditional replacement.
- **Deferred**: Exact wording of fallback rules.

## D-02 — Maintainer / Adopter Constitution Distribution

- **Status**: APPROVED — CRITICAL
- **Direction**: Bootstrap must use an adopter-specific constitution source and must not distribute maintainer sync/catalog policy.
- **Rationale**: Current bootstrap sources `.github`, whose constitution mirrors maintainer `copilot-instructions.md`, while `AGENTS.md` declares the adopter template as intended source.
- **Constraints**: New adopters receive the corrected default. Untouched existing adopters migrate only with proven hash lineage. Customized and legacy adopters receive report/manual decision behavior.
- **Migration implication**: No inferred automatic migration before D-06 lineage support.
- **Deferred**: Exact temporary migration mechanism before the manifest redesign.

## D-03 — Risk-Adaptive Workflow

- **Status**: APPROVED
- **Direction**: Only Simple, Standard, and High-Risk modes remain. The Fast Path name is retired.
- **Rationale**: Existing Fast Path definitions conflict and impose lifecycle overhead on small tasks.
- **Constraints**: Every mode retains verifiable completion; High-Risk always uses the full Workflow and Change Package.
- **Migration implication**: All lifecycle owners and routers must move to the same mode contract in one reviewed phase.
- **Deferred**: None at architecture level.

## D-04 — Custom Agent / Skill Boundary

- **Status**: APPROVED WITH REVISION
- **Direction**: Agent owns persona, specialist lens, scope, delegation/handoff, paired Skill references, and necessary tool/model restrictions. Methodology and rubrics belong in Skills.
- **Rationale**: Eight of nine current Agents exceed the declared thin target and several duplicate stage policy or methodology.
- **Constraints**: `≤25 non-empty lines` is a soft target. Structural responsibility violations are a hard gate.
- **Migration implication**: Preserve customized Agents and regenerate runtime only from accepted canonical changes.
- **Deferred**: Exact structural checker implementation.

## D-05 — Canonical / Derived Retirement

- **Status**: APPROVED
- **Direction**: Detect → dry-run → report. Prune requires managed/generated proof, unchanged current content, source retirement/rename evidence, a dry-run report, and task-scoped user approval.
- **Rationale**: Current generation loops do not retire stale outputs, while automatic deletion would endanger legacy/custom content.
- **Constraints**: Never prune customized, unknown, or legacy content automatically.
- **Migration implication**: Add provenance and tombstone behavior only with compatibility fixtures.
- **Deferred**: CLI and syntax of any future explicit prune command.

## D-06 — Manifest Evolution

- **Status**: DIRECTION APPROVED; SCHEMA NOT APPROVED
- **Direction**: Future manifest must represent previous baseline, observed/new hash, ownership, `generated_from`, source release/version, fork/customization, retired/tombstone, and parse state.
- **Rationale**: Current schema and loader behavior cannot safely distinguish all adopter classes or preserve provenance after parse failure.
- **Constraints**: Corrupt/unsupported manifest plus update is a hard stop. Missing legacy manifest is warning plus report-only. Silent reset is prohibited.
- **Migration implication**: v1/v2 compatibility must be designed before a new schema is emitted.
- **Deferred**: Complete JSON schema, schema version, migration encoding, and recovery UX.

## D-07 — Change Package and Task SSOT

- **Status**: APPROVED WITH REVISION
- **Direction**: Change Package is lifecycle evidence, decision trace, and implementation/verification record. Each work item has one task/status SSOT. This package declares `04-plan.md` as its SSOT.
- **Rationale**: Change Package, plan, external trackers, and memory must not maintain competing progress states.
- **Constraints**: With an external tracker, package stores only pointer, decisions, and evidence. Review is a semantic role with legacy filename aliases.
- **Migration implication**: Existing `05-review.md` remains recognized.
- **Deferred**: Canonical Review filename and any `07-review.md` adoption.

## D-08 — Archive / Closeout

- **Status**: HYBRID DIRECTION APPROVED; ARTIFACT NAME OPEN
- **Direction**: Simple has no Archive requirement. Standard packages preserve pre-merge lifecycle closeout in the original PR. PR/release/issue is authoritative merge evidence. High-Risk requires pre-merge closeout. Deployment/migration also records post-merge operational validation.
- **Rationale**: Pure post-merge repository Archive requires another write and conflicts with authorization boundaries.
- **Constraints**: Archive never implies commit, push, tag, merge, branch deletion, or remote issue/PR closure.
- **Migration implication**: Legacy archive artifacts remain readable.
- **Deferred**: `99-archive.md`, `99-closeout.md`, or compatibility alias decision.

## D-09 — agentic-eval Policy

- **Status**: DIRECTION APPROVED
- **Direction**: `agentic-eval` is self-evaluation. Simple does not require it; Standard is risk-triggered; High-Risk uses it at explicitly named gates. It never replaces independent code/security review.
- **Rationale**: Current policy describes it as automatic, mandatory, advisory, and on-demand.
- **Constraints**: Blocking outcomes must be explicitly named. Non-critical quality concerns are warnings.
- **Migration implication**: Workflow, Agents, Skills, and rubrics must change together.
- **Deferred**: Final thresholds and exact rubric implementation.

## D-10 — Cross-CLI Adapter

- **Status**: DEFERRED — GATHER EVIDENCE
- **Direction**: Define one canonical capability contract and fallback; adapters may change representation, not lifecycle or quality semantics.
- **Rationale**: Current official Codex and Antigravity capability evidence is not observed.
- **Constraints**: No runtime adapter implementation before separate evidence review and approval.
- **Migration implication**: Unknown capability must fall back to Project AGENTS plus relevant Skill.
- **Deferred**: Codex and Antigravity capability matrix and adapter proposal.

## D-11 — bootstrap.sh Support Contract

- **Status**: APPROVED — DEPRECATED
- **Direction**: Python is the supported Linux/macOS installer. Bash must reject update of existing adopters, stop claiming parity, and show a deprecation warning. It may temporarily be an initial-install thin wrapper.
- **Rationale**: Current Bash update implies force and does not implement ownership/manifest/runtime semantics.
- **Constraints**: Do not rewrite a third complete installer.
- **Migration implication**: Existing Bash users need explicit Python migration guidance.
- **Deferred**: Removal timing and duration of wrapper compatibility.

## Amendments

These amendments preserve the approved architecture directions above. They correct implementation boundaries and safety conditions only. Approval source: current Change Package Consistency Correction instruction.

### Amendment A-01 — Split Phase 0C / Phase 0D

- **Amends implementation boundary for**: D-06, D-08, C-04, and C-06.
- **Correction**: Phase 0C is limited to Manifest Parse Safety Containment for C-04. Phase 0D is a separate Archive Authorization Containment phase for C-06.
- **Boundary**: Each phase requires separate approval, implementation, verification, review, and PR. Manifest work and Archive work must not share either containment phase.
- **Architecture direction changed**: No.

### Amendment A-02 — Adopter-Facing Workflow Source Remains Open

- **Amends implementation boundary for**: D-03 and D-07, Phase 3.
- **Correction**: Phase 3 must obtain approval for the adopter-facing lifecycle source before distribution implementation. Root maintainer `WORKFLOW.md` must not be installed directly unless a maintainer/adopter difference review proves it fully generic.
- **Open candidates**: Adopter-specific lifecycle template; shared canonical lifecycle core with maintainer/adopter projections; or a reviewed fully generic shared document.
- **Deferred**: Final model, filename, and path. No new Decision ID is introduced.
- **Architecture direction changed**: No.

### Amendment A-03 — Exact Recorded Baseline Required for Untouched Constitution Migration

- **Amends safety condition for**: D-02, Phase 0A.
- **Correction**: An existing constitution is an untouched migration candidate only when a trusted existing manifest records a verifiable previous managed baseline for that exact component and current content equals that baseline.
- **Not sufficient**: Missing component baseline; missing, corrupt, or unsupported manifest; unclear source identity; content similarity; reconstructed or guessed baseline; customization; or unknown legacy ownership.
- **Required fallback**: Preserve → report → manual decision.
- **Boundary**: Phase 0A must not invent D-06 lineage.
- **Architecture direction changed**: No.
