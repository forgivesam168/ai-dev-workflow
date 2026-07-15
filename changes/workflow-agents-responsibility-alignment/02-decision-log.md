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

### Amendment A-04 — Phase 1 Fallback Rules and High-Risk Gates Approved

- **Approval**: Phase 1 — AGENTS / WORKFLOW / Risk-Mode Contract is explicitly approved for implementation, including D-01, D-03, the D-09 policy layer, the C-03 contract portion, the Project AGENTS standalone fallback contract, the Simple/Standard/High-Risk execution modes, the named High-Risk gate semantics, canonical Workflow lifecycle ownership, the `agentic-eval` self-evaluation boundary, and required canonical/derived consistency and tests.
- **Approved Project AGENTS fallback rules**:
  1. **Evidence and uncertainty**: Base material conclusions on repository evidence, tool output, or other verifiable evidence; distinguish facts, assumptions, inferences, and unknowns; never fabricate status, test results, sources, or completion evidence.
  2. **Material assumptions**: Before modification, disclose assumptions that affect scope, contracts, security, data, migration, or verification. Stop for clarification when different answers would materially change the implementation path.
  3. **Project context and SSOT**: Load the Project AGENTS-designated context, architecture, and task/status SSOT first. Resolve conversation, plan, spec, code, or project-vocabulary conflicts through project precedence; stop when they cannot be resolved.
  4. **Surgical scope control**: Change only the smallest content required by the approved scope. No drive-by refactor, unrelated formatting, speculative abstraction, unrequested feature, or cross-phase implementation.
  5. **Secrets and sensitive data**: Do not access, display, commit, or write unnecessary secrets, credentials, tokens, PII, or sensitive data. Stop the exposure path, redact reporting, and exclude sensitive content from artifacts, logs, commits, and remote content.
  6. **Protected-action authorization**: Commit, push, merge, tag, release, branch deletion, remote Issue/PR closure, deployment, production operation, destructive action, and other remote mutation require explicit, current-task, action-specific authorization. Approval for one action does not authorize another; tool availability or Agent identity is not authorization.
  7. **Verification and deterministic blockers**: Define verifiable success before implementation and run applicable targeted tests, required full checks, static checks, and project gates before completion. Known test, build, lint, security, data-integrity, or deterministic gate failure is blocking and cannot be overridden by prose review, self-evaluation, or inference.
  8. **Risk escalation and rollback**: Stop and escalate the execution mode when work crosses auth, security, financial, migration, public-contract, destructive, deployment, production, irreversible, or difficult-to-verify boundaries. Non-simple reversible work requires risk-proportionate rollback, restore, compensation, or safe-stop guidance.
  9. **Honest completion**: Claim completion only when the approved scope is complete, required verification has evidence, and delivery state is accurate. Distinguish unverified, unmerged, partial, Deferred, blocked, N/A, and user-decision-dependent work from Complete.
- **Approved named High-Risk gates**:
  1. **Architecture Decision Exit** applies before irreversible or high-cost architecture, security, permission, data, or public-contract decisions enter downstream commitment. Blocking conditions are an unresolved safety/authorization boundary; fabricated, unverified, or materially unsupported source/assumption; an irreversible decision without viable rollback, migration, or compensation; or an unresolved material contract conflict. Warning-only findings are maintainability preferences and optional documentation or naming improvements that do not affect correctness, security, reversibility, or contract behavior.
  2. **Pre-Implementation Readiness** applies before every High-Risk implementation. Blocking conditions are unresolved required AC/scope/decision/prerequisite; missing protected-action approval; a missing or non-executable applicable migration/rollback/recovery plan; no reliable RED/GREEN or other verifiable path; or unclear ownership/affected-system boundaries. Warning-only findings are optional documentation, presentation, or wording improvements that do not affect safe or verifiable implementation.
  3. **Pre-Delivery Verification** applies before every High-Risk commit, push, PR, or merge. Blocking conditions are a known red test/build/lint/static check/required gate; a material requirement or AC without evidence; a security, authorization, financial, data-integrity, or migration invariant failure; scope leakage, unreviewed generated drift, or an invalid worktree state; or missing required independent review or unresolved Critical/High findings. Warning-only findings are style, presentation, or low-impact clarity issues that do not affect correctness or auditability.
  4. **Migration / Deployment Readiness** applies only when separately authorized migration, deployment, production, or irreversible data execution is in scope. Blocking conditions are missing explicit current-task action-specific execution approval; an unbounded scope/target/batch/affected population; missing rollback/restore/compensation/safe-stop; missing rehearsal/recovery validation/required operational signal; or unclear ownership, backup, reversibility, or failure handling. Warning-only findings are non-critical presentation, report-formatting, or optional-observability improvements. Otherwise record: `N/A — no migration or deployment execution is authorized in this Phase.`
- **Cross-gate semantics**: Deterministic failure is always blocking. `agentic-eval` is self-evaluation, never independent review, and cannot override test/build/gate failure. Warning-only findings must be recorded but cannot be silently promoted to blocking without new evidence that matches an approved blocking condition. Blocking findings must be resolved before the next gate. N/A requires an auditable reason. High-Risk work still requires independent review. Phase 1 introduces no aggregate score or numeric threshold; any future gate, blocking dimension, or aggregate threshold requires separate approval.
- **Still unapproved**: Phase 3 adopter-facing lifecycle source selection and Phase 4 Manifest schema.
- **Architecture direction changed**: No.
