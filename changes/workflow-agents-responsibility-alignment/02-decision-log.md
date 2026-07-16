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

### Amendment A-05 — Phase 2 Structural Contract Approved

- **Approval**: Phase 2 — Agent / Skill / Prompt / Instruction Alignment is explicitly approved for product implementation in one Phase and one PR, including D-04, D-09 representation consistency, responsibility alignment, deterministic structural checking, soft line-count reporting, canonical/derived parity, and required focused/regression tests.
- **Ownership contract**: Custom Agents own only persona/role identity, specialist lens, scope boundary, delegation/handoff intent, paired Skill references, genuinely necessary tool/model restrictions, and brief entry/completion/handoff signals. Skills canonically own reusable methodology, procedures, checklists, templates, stage/domain tactics, detailed evaluation rubrics, and reusable verification guidance. Prompts own entry-point UX, necessary parameter/context collection, routing to the canonical Workflow/Skill, and concise output/handoff requirements. Instructions own only path-, file-type-, language-, framework-, or domain-scoped deltas and scope-specific verification additions.
- **Required Agent structure**: Every applicable canonical Agent must expose persona/purpose, specialist lens or an auditable N/A reason, scope boundary, delegation/handoff intent, at least one correct paired Skill pointer or an auditable no-Skill reason, and only genuinely necessary tool/model restrictions.
- **Prohibited responsibilities**: Agent methodology/procedure/checklist bodies, detailed rubrics, complete Workflow or execution-mode definitions, Global governance, Git/remote authorization policy, Prompt/Instruction generic lifecycle or policy ownership, competing canonical methodology owners, and missing or non-owning Skill pointers are structural hard failures.
- **Line-count semantics**: `≤25 non-empty lines` is a soft target. Exceeding it produces a warning only and cannot independently cause a nonzero result; structural correctness takes precedence over line count.
- **Checker semantics**: The deterministic checker scans the explicit canonical Agent set, emits per-file hard failures and soft warnings with non-empty line counts and locatable finding types, validates required structure and resolvable paired Skill pointers, detects approved prohibited responsibility categories without relying on one brittle keyword, returns nonzero for hard failures, returns success for warning-only results, and runs non-interactively in repository gates and CI. It performs no LLM/network call, aggregate scoring, automatic rewrite, content move, or deletion.
- **Representation boundary**: Methodology has one canonical Skill owner; Agents and Prompts point to it instead of duplicating it; Instructions retain scoped deltas only; generator-owned `.github/**` representations come only from the repository sync flow and preserve required Agent semantics.
- **Preserved Phase 1 contract**: Phase 2 must not change Simple/Standard/High-Risk semantics, named High-Risk gates, Change Package triggers, protected-action authorization, deterministic blockers, independent-review requirements, or the canonical Workflow lifecycle contract.
- **Still unapproved**: Phase 3 adopter-facing lifecycle-source design, Phase 4 Manifest schema, D-10 adapter implementation, unobserved adapter capability claims, migration, prune, and real adopter execution.
- **Architecture direction changed**: No.

### Gate-Check Note — 2026-07-16

- **Check**: Phase 2 canonical Agent structural contract and `≤25 non-empty lines` soft target.
- **Finding**: `agents/pm.agent.md` and `agents/spec.agent.md` each contain 29 non-empty lines. The checker reported 0 hard failures, emitted `LINE_COUNT` warnings for those two files, and returned success.
- **Decision**: Proceed. Amendment A-05 explicitly defines line count as warning-only, while the required persona, specialist lens, scope, handoff, Skill ownership pointers, and necessary restrictions remain intact.
- **Additional note**: Python regression emitted the pre-existing `pytest-asyncio` future-default deprecation warning; 89 tests passed and no deterministic failure occurred.
- **Architecture direction changed**: No.

### Amendment A-06 — Phase 3 Lifecycle Artifact and Distribution Contract Approved

- **Approval**: Phase 3 — Change Package / Review / Archive Semantics is explicitly approved for product implementation in one Phase and one PR, including D-07, D-08, the C-03 lifecycle-distribution portion, the C-06 full semantic alignment, deterministic verification, Python/PowerShell parity, generated parity, and required documentation/tests.
- **Adopter lifecycle source**: Root maintainer `WORKFLOW.md` remains the canonical maintainer lifecycle SSOT. `docs/WORKFLOW.template.md` is its adopter-facing distribution projection, not an independent policy SSOT, and bootstrap installs it at adopter root `WORKFLOW.md` with `template-managed` ownership. Root maintainer `WORKFLOW.md` is never copied directly to an adopter.
- **Projection contract**: The adopter projection preserves portable Simple/Standard/High-Risk modes, entry/escalation/verification rules, compact/full package triggers, lifecycle stage entry/exit semantics, named High-Risk gates, deterministic blockers, independent review, Review and Archive/Closeout semantics, protected-action authorization, honest completion, and one task/status SSOT. It excludes template-maintainer catalog/sync/CI/generator duties, repository maintenance commands, template release/bootstrap maintenance, unsupported surface claims, D-10 adapter claims, and Phase 4 schema/migration behavior.
- **Preservation contract**: Lifecycle assets use only the current manifest fields for exact managed-baseline, observed/source hash, ownership, source, kind, and status. New missing targets are installed; a valid `template-managed` component with the expected source and exact current-baseline equality is update-eligible; customized, project-owned, legacy/unknown, missing-baseline, or unclear-source content is preserved and reported for manual decision. Missing-manifest update remains report-only; corrupt/unsupported update remains a hard stop before writes. No real adopter migration is authorized.
- **Package contract**: Simple requires no package, Review, or Archive. Standard without a package trigger requires one declared plan/lifecycle SSOT but no repository package or Archive. Triggered Standard uses a compact package with Intake, decision evidence, plan/lifecycle evidence, exactly one task/status SSOT declaration, Review only when independent review is required, and pre-merge Closeout; Brainstorm, Spec, separate Test Plan, and Impact Analysis are selected-stage/risk artifacts, never empty file-count padding. High-Risk uses the full `00` through `06` evidence set plus Review and Archive/Closeout semantic roles.
- **Single task/status SSOT**: Every new package declares its task/status SSOT, external tracker if any, execution mode, package trigger/reason, and Compact/Full contract in `00-intake.md`. Only one dynamic progress owner is permitted; an external-tracker package may retain static plan/evidence but no competing progress status. Missing, conflicting, or unidentifiable ownership is blocking, and completion is never inferred from filename existence.
- **Review role**: New packages use canonical `07-review.md`; legacy `05-review.md` remains recognized without bulk rename. Review requires observable Summary, Findings, Verification Evidence, and a Decision of `PASS`, `PASS_WITH_NOTES`, or `BLOCKED`. Unresolved Critical/High findings or required deterministic failures require `BLOCKED`. Two independent Review bodies are competing evidence and blocking; one alias may be a pointer only.
- **Archive / Closeout role**: New packages use canonical `99-archive.md`; `99-closeout.md` is a recognized compatibility alias. Closeout requires Outcome, Approved Scope, Verification Evidence, Review Status, Delivery Status, Remaining/Deferred Work, Authorization Boundary, and applicable rollback/recovery evidence. Two independent closeout bodies are competing evidence and blocking; one alias may be a pointer only.
- **Hybrid closeout**: Simple and Standard without a package require no repository Archive. Triggered Standard and High-Risk complete `99-archive.md` pre-merge in the original implementation PR; a blocked Review or deterministic gate makes closeout `BLOCKED`. PR/Issue/Release remote evidence is authoritative for actual merge state, SHA, and `mergedAt`; pre-merge repository closeout must not invent merge evidence, and no post-merge commit or push is created merely to add merge evidence.
- **Authorization boundary**: Archive authorizes only the requested local documentation. It never grants or implies commit, push, tag, merge, branch deletion, remote Issue/PR closure, release, deployment, production, or any other remote mutation. Operational execution always requires separate explicit current-task action-specific approval.
- **Bootstrap mapping**: `docs/WORKFLOW.template.md` maps to adopter `WORKFLOW.md`; `changes/_template/**` maps to adopter `changes/_template/**`; both are `template-managed`. Bootstrap does not create work-item packages, overwrite unproven/customized content, or rename historical Review/Archive artifacts.
- **Schema boundary**: Only the current manifest schema is used. Phase 4 schema/version/migration encoding remains unapproved; no schema change, prune, retirement, or real-adopter execution is included.
- **Verification note**: The repository gate retained the approved Phase 2 soft line-count warnings for `agents/pm.agent.md` and `agents/spec.agent.md`; they remained warning-only and did not mask a structural or lifecycle hard finding. Historical `changes/2026-02-09-bootstrap-installer/05-review.md` likewise remained a nonblocking legacy-compatibility warning.
- **Environment note**: Python verification retained the pre-existing `pytest-asyncio` future-default loop-scope deprecation warning; all required Python tests passed, so no deterministic blocker was present.
- **Architecture direction changed**: No.

### Proposal Pointer — Phase 4 Manifest Schema

- **Status**: `PROPOSED — awaiting explicit user approval`.
- **Artifacts**: The proposal is recorded in `phase-4-manifest-schema-proposal.md`, `phase-4-manifest-v3.schema.proposed.json`, and `phase-4-schema-examples/` within this Change Package.
- **Authorization boundary**: Proposal only; not approved and not implemented. Production readers and writers remain limited to schema versions 1 and 2, current writers continue to emit version 2, and the Proposal PR must remain open until the user separately approves the schema and merge. This pointer is not Amendment A-07.
- **Gate-check note — 2026-07-16**: The full repository gate passed with notes. `agents/pm.agent.md` and `agents/spec.agent.md` each remain at 29 non-empty lines, producing the already-approved `LINE_COUNT` soft warnings only; the structural checker reported no hard finding. Proceeding with proposal delivery does not promote the warnings, approve the schema, or authorize implementation.
- **Architecture direction changed**: No.
