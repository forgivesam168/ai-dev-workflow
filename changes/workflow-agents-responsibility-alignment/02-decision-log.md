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
- **Approval-blocking correction review — 2026-07-17**: Still `PROPOSED — awaiting explicit user approval`. The proposal now makes tombstoned IDs terminal and permanently reserved, models any future separately authorized reintroduction as a new ID pointing to the unchanged tombstone, fixes `manifest/component-catalog.json` as the version-controlled source-side identity SSOT, and recommends future production schema path `schemas/ai-workflow-install-manifest-v3.schema.json` with `$id` `urn:ai-dev-workflow:manifest-schema:v3`. None of these proposal corrections authorizes schema approval, runtime import, writer enablement, migration, prune, merge, or Phase 4 implementation.
- **Gate-check note — 2026-07-17**: The correction changes no canonical Agent. The unchanged 29-line `agents/pm.agent.md` and `agents/spec.agent.md` findings remain the already-approved `LINE_COUNT` soft warnings; proceed only if the final stable-diff gate again reports no structural or other hard failure. This recorded disposition cannot override a deterministic failure.
- **Architecture direction changed**: No.

### Amendment A-07 — Manifest v3 Schema Contract Approved

- **Approval source**: Explicit current-task instruction, "Phase 4 Manifest v3 Schema Approval and Proposal Merge".
- **Approved Proposal**: PR #11 at exact head `16aa063139431cbd07cba147d81be1d2cb3da609`; OD-01 through OD-17 in that head are approved as one complete, internally consistent contract.
- **Approved architecture**: Structured Manifest schema version 3 with the approved identity, provenance, four-timepoint hash, ownership/fork classification, lifecycle, loader/report parse-state, compatibility, deterministic dry-run, atomic publication, rollback, link/mount, and cross-runtime parity contracts.
- **Production Schema identity**: Future production artifact `schemas/ai-workflow-install-manifest-v3.schema.json`, JSON Schema Draft 2020-12, stable `$id` `urn:ai-dev-workflow:manifest-schema:v3`, produced only through the approved allowlisted deterministic candidate-to-production transform.
- **Stable Component Identity**: Canonical source-side catalog `manifest/component-catalog.json`, catalog schema version 1, exact source-release digest binding, and no path-, timestamp-, adopter-content-, or runtime-generated IDs.
- **Hash semantics**: Four distinct exact-byte SHA-256 timepoints — baseline, observed-before, proposed-source, and result-after — with the approved canonical encoding and Python/PowerShell serialized-byte parity requirements.
- **Lifecycle semantics**: Tombstoned is terminal; its ID is permanently reserved. Source reappearance is report-only. Any separately authorized future reintroduction receives a new ID linked to the unchanged tombstone through `reintroduces_component_id`; the relationship is not authorization.
- **Rollout**: Reader-first v1/v2 compatibility and in-memory normalization only; no read-time rewrite. Writer enablement remains a separate future decision, and production writers continue to emit v2.
- **Safe-Prune**: Option A is approved as the design contract: exact component IDs plus exact report hash plus external explicit current-task action-specific authorization, with no prune-all behavior.
- **Candidate boundary**: Change Package schema/examples remain non-runtime decision evidence with proposal markers and `example.invalid`; approval does not make them runtime dependencies or create the production Schema artifact.
- **Execution boundary**: No writer enablement, Phase 4 product implementation, migration, prune, real-adopter execution, deployment, or production operation is authorized by this amendment.
- **Next authorization**: Phase 4 product implementation still requires a separate explicit current-task approval.
- **Architecture direction changed**: No.

### Gate-Check Note — 2026-07-17 (Schema Approval Status)

- **Check**: Final status-only Schema approval diff before Proposal PR #11 delivery and guarded merge.
- **Finding**: The complete repository gate passed every required check and returned `GATE PASSED WITH NOTES`. `agents/pm.agent.md` and `agents/spec.agent.md` remain at 29 non-empty lines and produced only the already-approved `LINE_COUNT` soft warnings; no Agent or generated file changed. The historical `05-review.md` compatibility warning and pre-existing `pytest-asyncio` deprecation warning also remained nonblocking.
- **Decision**: Proceed after rerunning the full gate on this final recorded diff. These warnings do not match an approved blocking condition and cannot override any deterministic failure.

### Amendment A-08 — Phase 4A Reader-First Foundation Authorized

- **Approval source**: Explicit current-task instruction, "Phase 4A — Manifest v3 Reader-First Foundation".
- **Approved baseline**: Amendment A-07 and Proposal PR #11 squash merge `5300d56c9ef9594f9bb3007b22824a644e06ee62`; OD-01 through OD-17 remain unchanged and approved.
- **Production Schema**: Phase 4A may create Draft 2020-12 `schemas/ai-workflow-install-manifest-v3.schema.json` with stable `$id` `urn:ai-dev-workflow:manifest-schema:v3` only through the approved deterministic candidate-to-production transform. Candidate artifacts remain byte-identical non-runtime evidence.
- **Stable Component Identity**: Phase 4A may create canonical Catalog `manifest/component-catalog.json`, catalog schema version 1, with initial logical release identity `ai-dev-workflow:component-catalog:1`, source ref `manifest/component-catalog.json`, and version `1`. Exact-byte SHA-256 is integrity evidence only, never authenticity or authorization.
- **Reader capability**: Python and PowerShell may strictly recognize and validate valid v3 as `valid-v3`, including Production Schema, exact Catalog binding, path, hash, provenance, fork, lifecycle, transaction, and cross-record semantics. Existing v1/v2 read compatibility and no-read-time-rewrite behavior must remain intact.
- **Mutation boundary**: Every current install/update/force path that observes valid v3 must stop before backup, directory, file, link, temporary production artifact, or Manifest mutation, report that writer/migration is not enabled, and must never downgrade or overwrite v3 with v2.
- **Writer boundary**: Production writers remain schema version 2. Phase 4A does not authorize conversion planning, writer enablement, migration, tombstone mutation, prune/delete, real-adopter execution, deployment, or production operation.
- **Phase boundary**: Phase 4A is one reader-first implementation tranche. Phase 4 remains incomplete; Phase 4B and later tranches plus Phase 5 remain separately unauthorized.
- **Architecture direction changed**: No.

### Gate-Check Note — 2026-07-17 (Phase 4A Reader-First Foundation)

- **Check**: Phase 4A local product diff after two bounded Luna correction rounds and Sol independent review.
- **Finding**: The complete repository gate passed every deterministic check and returned `GATE PASSED WITH NOTES`. `agents/pm.agent.md` and `agents/spec.agent.md` remain at 29 non-empty lines and produced only the approved `LINE_COUNT` soft warnings; neither Agent nor any generated representation changed in Phase 4A. The direct Change Package check also retained one nonblocking historical compatibility warning for `changes/2026-02-09-bootstrap-installer/05-review.md`. The Python environment emitted the pre-existing `pytest-asyncio` deprecation warning.
- **Decision**: Record these findings as warning-only and rerun the complete repository gate on the final governance/status diff before commit. They do not satisfy an approved blocking condition, do not override deterministic checks, and do not authorize any scope expansion.

### Amendment A-09 — Phase 4B Report-Only Planner Authorized

- **Approval source**: Explicit current-task authorization, “Phase 4B — Deterministic No-Write Conversion & Stale Planner”.
- **Approved baseline**: Phase 4A PR #12 merged as squash commit `3902639bb2ee3406fc04405f0a8ff644dfcd5e8b`; final head `774c613f327213db087a1af27168d34770c3ca03`; base `5300d56c9ef9594f9bb3007b22824a644e06ee62`; two commits, ten changed files, required CI successful, no reviews or unresolved threads.
- **Production report schema**: `schemas/ai-workflow-manifest-reconciliation-report-v1.schema.json`, Draft 2020-12, `$id` `urn:ai-dev-workflow:manifest-reconciliation-report:v1`, report contract version `1`.
- **Capability**: Read-only `conversion-plan` and `reconcile` operations for valid v1/v2/v3 input, manifest/catalog/source/target reconciliation, conservative lineage, rename/retirement/stale detection, deterministic canonical report bytes, and `sha256:<64 lowercase hex>` report digest.
- **Legacy and v3 policy**: Missing is report-only without inferred lineage; corrupt/unsupported blocks before planning; v1/v2 remain conservative and byte-preserving; valid-v3 reuses Phase 4A validation and reconciles against fresh target bytes.
- **Eligibility and authorization**: Computed prune eligibility is evidence only and always `not_authority: true`; approval is not supplied or accepted by the planner; no prune selection, approval reference, delete, tombstone, migration, restore, writer enablement, or real-adopter operation is exposed.
- **No-write boundary**: Default output is JSON on stdout only. Manifest, Catalog, source, target, directory/path inventory, timestamps, `.git`, lifecycle, transaction, backup, lock, journal, temporary artifact, and writer outputs remain unchanged; production writers continue to emit v2 and valid-v3 mutation blocking remains intact.
- **Model experiment and review**: Sol owns orchestration/governance/audit/delivery; Luna is the sole product writer; a separate built-in read-only Reviewer must inspect the stable exact diff before commit; neither worker may perform protected remote actions.
- **Phase boundary**: No migration rehearsal, v3 writer, Manifest migration/rewrite, tombstone mutation, prune, restore/reintroduction execution, or Phase 5. Phase 4 remains incomplete.
- **Architecture direction changed**: No.

### Amendment A-10 — Phase 4B Deterministic Timestamp Correction Delivered

- **Approval source**: Explicit current-task bounded model-escalation authorization for the Reviewer-confirmed High finding; no Phase 4C or mutation authorization was added.
- **High finding**: Raw `mtime_ns` entered normalized source/target snapshot hashing indirectly, so equal content bytes with different filesystem timestamps produced different canonical report identity.
- **Correction**: `scripts/manifest_reconciliation.py` now strips `mtime_ns` recursively before normalized snapshot hashing; raw pre/post timestamp comparison remains separate and emits `no-write-proof-failed` with `writes_performed: true` when it detects same-run timestamp mutation. The report schema changes only `writes_performed` from `const false` to boolean to represent that blocking proof state; it adds no raw timestamp to the report body.
- **Model evidence**: Sol requested GPT-5.6 Luna / high; observed unknown. Luna requested GPT-5.4 / medium; observed unknown; one product-correction invocation in this escalation. The independent Reviewer was requested as GPT-5.4 mini / medium; observed unknown; one read-only review invocation.
- **RED/GREEN evidence**: Luna RED was `3 failed, 185 deselected`, isolating same-bytes/different-mtime snapshot/report digest drift and same-run timestamp mutation proof weakness. Sol GREEN was focused Python contract `7 passed`, Phase 4B Python `18 passed`, pinned Pester parity `2 passed`, full Python `188 passed`, full Pester `130 passed`, and the valid full repository gate Python `188 passed` plus Pester `262 passed`.
- **Review and gate**: Independent read-only review classified Critical/High/Medium/Low as `0/0/0/0` and marked the original High finding `Resolved`; Full Gate returned `GATE PASSED WITH NOTES`, with only existing Agent line-count warnings, historical legacy-review warning, and pre-existing pytest deprecation warning. Gate pre/post branch, HEAD, status, path, bytes, and SHA-256 invariance was true.
- **Phase boundary**: Phase 4B remains report-only and deterministic. Production writers remain v2; no migration, tombstone mutation, prune, restore, real-adopter operation, Phase 4C, or Phase 5 was performed or authorized. Phase 4 overall remains incomplete.

### Amendment A-11 — Phase 4C Migration Rehearsal & Recovery Foundation Authorized

- **Approval source**: Explicit current-task authorization, “Phase 4C — Migration Rehearsal & Recovery Foundation”.
- **Approved capability**: Test-only or explicitly rehearsal-only v1/v2-to-v3 conversion rehearsal over synthetic or copied fixtures, including canonical v3 candidate validation, same-filesystem staging, lock acquisition/release, journal and backup capture, crash simulation before and after manifest replacement, exact-byte rollback, recovery-required classification, and Python/PowerShell semantic parity.
- **Rehearsal boundary**: Every entry point must identify itself as rehearsal-only, reject repository-external real targets by default, accept only test fixtures or an explicit isolated workspace, expose no bypass flag, and remain unreachable from normal install/update writers.
- **Recovery contract**: A prior complete Manifest byte sequence is retained; a candidate is validated before publication; interruption before replacement preserves prior bytes; interruption after replacement requires committed-state validation or recovery; rollback restores exact prior bytes; rollback failure returns `recovery-required`; no false committed state or v3-to-v2 downgrade is allowed.
- **Execution boundary**: No real-adopter Migration, normal v3 writer enablement, Manifest rewrite, tombstone mutation, prune/delete, restore/reintroduction, deployment, production operation, or Phase 5 work is authorized by this amendment. Production writers remain v2.
- **Required evidence**: Valid v1/v2 mappings, corrupt/unsupported hard stops, missing legacy report-only behavior, lock contention, both interruption points, rollback success/failure, no-write and no-false-commit invariants, cross-runtime parity, and zero real-adopter operation.
- **Architecture direction changed**: No.
- **Recovery scratch adjudication**: The current task explicitly classifies untracked `tasks/todo.md` (`4356` bytes; SHA-256 `7a71daedd9564dbae2bd26dbb8114c0031bf0fb772dd0eb4f548bdceffd8329a`) as aborted-session Codex checkpoint metadata, not Product, Test, Fixture, Runtime, or required Change Package evidence. Its former Phase 4C allowlist mention was non-blocking planning text. The task specifically authorizes removing that mention, deleting only this exact file, and removing `tasks/` only if empty; `git clean`, wildcard deletion, other path deletion, and committing the scratch content remain prohibited.

### Amendment A-12 — Phase 4C Atomicity State-Machine Stabilization Authorized

- **Approval source**: Explicit current-task authorization, “Phase 4C Atomicity State-Machine Stabilization and Delivery”.
- **Exact correction scope**: Resolve only restore eligibility, backup/journal lifetime, persisted false-commit ambiguity, and lock failure atomicity in the four allowlisted Phase 4C Product/Test paths. The three existing governance paths may record evidence. Production Schema, Component Catalog, OD-01 through OD-17, normal writers, installer entry points, CI, and later phases remain immutable.
- **Truth table**: Trusted pre-mutation plus exact zero-mutation proof is blocked without restore. Trusted post-mutation plus fully valid/bound journal may restore only after every proof passes; unsafe journal remains `recovery-required` without restore. Unknown/conflicting phase remains `recovery-required` without restore. Rollback in progress requires valid recovery evidence and remains `recovery-required` until terminal. Revalidated terminal commit remains committed; post-commit cleanup residual remains committed with a non-authoritative diagnostic.
- **Manifest authority boundary**: Schema-valid committed-v3 bytes remain non-authoritative in transaction-scoped staging/candidate paths while the live v1/v2 Manifest remains unchanged. Final atomic Manifest publication, exact live readback, Schema/semantic/transaction binding, and signed terminal-journal atomic persistence/readback must all succeed before the external outcome is committed. No nonterminal production Manifest enum is added.
- **Recovery evidence boundary**: Manifest/component backups, journal, operation-state, and owned lock remain through terminal authority. Pre-terminal failure is blocked only with exact zero-mutation proof; otherwise it is `recovery-required`. Post-terminal cleanup stops on first failure, preserves remaining artifacts, and cannot downgrade authority or require rollback. Backup removal is a final cleanup action.
- **Lock boundary**: Exclusive create, HMAC-bound transaction/workspace/fixture identity, ownership token, file identity, durable readback, strict absence verification, and final-publication ownership revalidation distinguish `acquired`, `contended`, `failed-clean`, and `failed-uncertain`. Existing or foreign locks are never overwritten or stolen.
- **Model and review evidence**: Sol requested GPT-5.6 Sol / high; observed unknown. Luna requested GPT-5.6 Luna / high; observed unknown. The pre-implementation read-only Reviewer requested GPT-5.4 mini / medium; observed unknown and returned `PASS`, Critical/High/Medium `0/0/0`.
- **TDD and correction evidence**: Main RED was Python `28 failed, 46 passed, 3 skipped` and Pester `1 failed, 6 passed`; main GREEN was Python `74 passed, 3 skipped` and Pester `7 passed`. Sol audit correction `1/1` RED was Python `6 failed, 74 passed, 3 skipped`; correction GREEN was Python `80 passed, 3 skipped` and Pester `7 passed`. The first final Reviewer then found one persisted-truth High: terminal committed-journal recovery did not reconcile signed operation-state. Final Reviewer correction `1/1` RED was Python `6 failed, 80 passed, 3 skipped`; GREEN was Python `86 passed, 3 skipped` and Pester `7 passed`. The exploit and missing/malformed/pre-mutation/rollback-terminal/conflicting operation-state cases now remain `recovery-required` without restore; genuine `terminal-journal-started` or `committed` state still validates committed authority.
- **Regression and Gate evidence**: Post-correction full Python was `274 passed, 3 skipped`; full pinned Pester 5.6.1 was `269 passed`. After the correction, all three Windows `WinError 1314` symlink skips again executed in isolated Linux without skips: `3 passed`. Sync, Catalog, lifecycle, Change Package, Agent structure, all 19 tracked JSON parses, Schema/parser/compile, deterministic rehearsal checks, and `git diff --check` passed. The pre-correction Gate was invalidated for delivery by the Product correction; its Python `188 passed`, Pester `269 passed`, and exact invariance remain historical evidence only. Existing Agent line-count warnings, the historical legacy Review compatibility warning, and the pre-existing `pytest-asyncio` deprecation warning remained warning-only.
- **Independent review boundary**: The first final exact seven-path Reviewer was requested as GPT-5.4 mini / medium, observed unknown, and returned `BLOCKED` at `0 Critical / 1 High / 0 Medium / 0 Low`; the other three current findings were resolved. A new read-only re-review with the same requested model/effort is required after a new final Full Gate. Any remaining blocking finding stops delivery because the Final Reviewer/CI correction budget is exhausted.
- **Delivery boundary unchanged**: Phase 4C remains rehearsal-only over tool-created synthetic/copied fixtures. Production writers still emit v2. No real-adopter Migration, Manifest rewrite, prune/tombstone, Restore/Reintroduction capability, deployment, production operation, Phase 4D, Phase 4E, Phase 5, Phase 6, or Final Closeout is authorized or performed.
- **Architecture direction changed**: No.

### Amendment A-13 — Phase 4C Journal-Type and Manifest-Link Correction Authorized

- **Approval source**: Explicit current-task authorization, “Phase 4C Final Bounded Journal-Type and Manifest-Symlink Correction”.
- **Exact correction scope**: Resolve only valid-JSON wrong-top-level journal handling and live Manifest ancestor/leaf no-follow containment before any read, hash, backup, staging, or diagnostic data flow. The Product/Test allowlist remains the four Phase 4C rehearsal paths; Production Schema, Component Catalog, OD-01 through OD-17, normal writers, installer entry points, CI, and later phases remain immutable.
- **Journal boundary**: JSON parsing now precedes an explicit top-level object check, which precedes every mapping operation and structural/semantic field validation. The validator returns invalid evidence to the caller contract: trusted zero-mutation state is `blocked`; interrupted, post-mutation, unknown, or conflicting state is `recovery-required`; neither class attempts restore or consumes journal-provided paths.
- **Manifest boundary**: Every live Manifest byte-read site uses lexical containment, ancestor/leaf `lstat` reparse rejection, regular-file proof, pre-open identity, descriptor identity before `os.read`, post-read identity, and workspace identity revalidation. Unavailable or changed proof fails closed before target bytes can enter reports, journals, backups, staging, digests, or diagnostics.
- **Model and invocation evidence**: Sol requested GPT-5.6 Sol / high; observed model/effort unknown. Luna was requested as GPT-5.6 Luna / medium; observed model/effort unknown. Luna used one main correction and both authorized additional exact-finding corrections; the additional correction budget is exhausted.
- **TDD evidence**: Main RED was `13 failed, 10 passed, 4 skipped, 89 deselected`; main GREEN reached Python `136 passed, 7 skipped` and pinned Pester `7 passed`. Additional correction 1 RED was `3 failed, 3 passed, 5 skipped, 137 deselected`, then GREEN reached Python `140 passed, 8 skipped` and Pester `7 passed`. Additional correction 2 RED was `5 failed, 148 deselected`, then GREEN and Sol reproduction reached Python `145 passed, 8 skipped` and Pester `7 passed`.
- **Regression and platform evidence**: Full Python passed `333` with `8` Windows privilege skips; full pinned Pester 5.6.1 passed `269` with no skip. Official Ubuntu 24.04 with Python 3.12.3 and pytest 8.3.5 executed eight named real symlink cases, including Manifest leaf-to-outside, leaf-to-inside, broken leaf, linked workspace ancestor, and TOCTOU swap, with `8 passed / 0 skipped`; their assertions prove no outside-target read and no target-byte backup/artifact. Direct sync, Catalog, lifecycle, Change Package, Agent structure, JSON/Schema/parser/compile, deterministic rehearsal, and `git diff --check` checks passed.
- **Gate and review boundary**: The Product-stable pre-governance Full Gate returned `GATE PASSED WITH NOTES`, Gate Python `188 passed`, Pester `269 passed`, and exact seven-path branch/HEAD/status/bytes/length/SHA-256 invariance. The notes remain the approved Agent line-count warnings, historical legacy Review compatibility warning, and pre-existing pytest deprecation warning. Governance editing requires one final invariant Gate; the new independent exact-diff Reviewer is still pending and no review result is claimed here.
- **Delivery boundary unchanged**: Phase 4C remains rehearsal-only over tool-created synthetic/copied fixtures. Production writers still emit v2. No real-adopter Migration, Manifest rewrite, prune/tombstone, Restore/Reintroduction capability, deployment, production operation, Phase 4D, Phase 4E, Phase 5, Phase 6, or Final Closeout is authorized or performed.
- **Architecture direction changed**: No.

### Amendment A-14 — Windows-First Remaining Phase 4 Execution Profile Authorized

- **Approval source**: Explicit current-task authorization, “Windows-First Workflow Manifest Completion Program”.
- **Execution-profile SSOT**: `phase-4-windows-first-execution-profile.md` is the Acceptance Boundary SSOT for the remaining Phase 4C, Phase 4D, and Phase 4E implementation. It does not replace the Production Manifest v3 Schema or Component Catalog.
- **Preserved contract**: Manifest v3 data model, Stable Component IDs, Reader-first/report-only results, ownership/provenance/hash/generated/lifecycle/parse-state fields, Customized preservation, conservative Legacy ownership, corrupt/unsupported hard stop, explicit Migration, honest completion, and separate authorization for real-adopter operations remain applicable.
- **Windows Product path**: Windows 11 and PowerShell 7.x on a local fixed disk are the supported Product environment. PowerShell is the Production installer/writer path. Python retains Reader/report/regression/reference roles but is not required to provide a Production v3 Writer or mutation parity in this Program.
- **Superseded implementation requirements**: Malicious concurrent filesystem replacement defense, hostile lock/rename/junction/inode proof, POSIX descriptor-chain operations, Windows/Linux writer parity, Python/PowerShell Production mutation parity, durable `fsync` crash consistency, corrupt-Journal automatic Restore, production automatic recovery, automatic Prune, Tombstone mutation, and Linux/macOS v3 writer work are Deferred or outside the current support contract.
- **Reviewer rule**: A missing Deferred capability is not blocking. A defect remains Applicable and blocking when ordinary supported Windows operation can write the wrong target, lose data or backup, overwrite Customized content, infer Legacy ownership, write after corrupt/unsupported input, or report false success.
- **Phase authorization**: The Program separately authorizes sequential Phase 4C, 4D, 4E, 5, 6, and Final Closeout branches/PRs and their named protected actions. No later Phase may start before the current Phase is merged and local `main` is synchronized.
- **Candidate disposition**: The prior seven-path dirty baseline remains evidence, not delivery. The three tracked governance candidates are retained and superseded by this Amendment/profile/status update. All four untracked Product/Test candidates are rewritten within their existing exact paths; conversion/validation/backup/diagnostic/ordinary Windows path-safety value is retained, while lock/journal/automatic-Restore and hostile/POSIX/Linux-mutation-only tests may be removed as superseded or Deferred.
- **Operational exclusion**: No real-adopter Migration, Restore, Cleanup, deployment, production operation, Adapter implementation, automatic Prune, Tombstone mutation, force push, push to `main`, rebase, branch deletion, tag, or release is authorized.
- **Architecture direction changed**: Yes for the remaining Phase 4 execution and support profile; no for the approved Manifest v3 Schema data model, Stable Component IDs, or Component Catalog.

### A-14 Phase 4C Windows-First Implementation Checkpoint

- **Model evidence**: Sol requested GPT-5.6 Sol / high; observed model and effort are unknown. The Phase 4C sole Product writer Luna requested GPT-5.6 Luna / medium; observed model and effort are unknown because the execution interface did not expose that model identity. No Codex configuration or model setting changed.
- **Main RED/GREEN**: The rewritten Windows-first tests first produced Python `13 failed / 2 passed` and pinned Pester 5.6.1 `12 failed / 0 passed`. The minimal native implementation then reached Python `15 passed / 0 failed / 0 skipped` and Pester `12 passed / 0 failed / 0 skipped`.
- **Sol audit finding**: The first GREEN trusted legacy `observed_hash` without hashing copied workspace component bytes, so ordinary post-Manifest customization could be mislabeled `untouched`. Raw traversal segments were normalized instead of rejected; valid-input backup followed Catalog access; and an uncertain replace exception could be mislabeled clean `blocked`. These were Applicable Windows-first data-integrity and honest-failure findings, not Deferred hostile-concurrency requirements.
- **Correction 1/3**: Luna added exact regressions and the minimum two-file PowerShell correction. RED was Pester `7 failed / 12 passed / 0 skipped`; GREEN was Pester `19 passed / 0 failed / 0 skipped`. Fresh copied bytes now control Untouched/Customized classification, missing/unsafe component bytes require manual decision, raw traversal is rejected, backup precedes Catalog/conversion/publication work, uncertain replacement is `manual-recovery-required`, and diagnostic paths are reported only after successful persistence. No automatic Restore was added.
- **Sol focused reproduction**: Python `15 passed / 0 failed / 0 skipped`; pinned Pester 5.6.1 `19 passed / 0 failed / 0 skipped`; only the pre-existing `pytest-asyncio` configuration deprecation warning remained.
- **Candidate disposition delivered locally**: The four candidate paths were rewritten from `310955` total bytes of hostile-concurrency/recovery machinery to `64371` total bytes of bounded Windows-first Product/Test files. The exact stable Product hashes and byte sizes are recorded in `04-plan.md`; removed lock/journal/automatic-Restore/POSIX/fsync/Linux-mutation/prune/tombstone code and tests are superseded or Deferred, not passed.
- **Remaining gates**: Full Python and pinned Pester regressions, direct deterministic checks, one invariant full repository Gate, an independent exact-diff read-only review, local commit, PR/CI evidence, expected-head guarded squash merge, and ff-only `main` synchronization remain pending. Phase 4C and the Program are not complete.

### A-14 Phase 4C Full Regression Checkpoint

- **Full Python regression**: `python -m pytest scripts/tests -q -p no:cacheprovider` passed `203` tests in `51.60s`; no failure or skip. The pre-existing `pytest-asyncio` configuration deprecation warning remained warning-only.
- **Full PowerShell regression**: Pinned Pester 5.6.1 discovered `281` tests across `scripts` and `tools`; `281 passed / 0 failed / 0 skipped / 0 not run / 0 inconclusive / 0 failed containers` in `124.3s`.
- **State**: Product and governance content are stable for direct deterministic checks and the single final invariant full repository Gate. Independent review and all delivery actions remain pending.

### A-14 Phase 4C Direct Deterministic Checkpoint

- **Required checks passed**: `check-sync.ps1`; `audit-catalog.ps1` with `9` Agents, `10` Prompts, `35` total Skills, `34` adopter Skills, and `1` maintainer-only Skill; lifecycle contract; Change Package contract; Agent structure; all `19` tracked JSON parses; in-memory Python compile; both Phase 4C PowerShell parsers; `git diff --check`; exact eight-path scope with `0` missing and `0` extra paths.
- **Warning-only notes**: `agents/pm.agent.md` and `agents/spec.agent.md` remain at `29` non-empty lines; the historical `changes/2026-02-09-bootstrap-installer/05-review.md` legacy Review warning remains; the existing `pytest-asyncio` configuration deprecation remains. No file that causes these notes changed in Phase 4C, and no deterministic check failed.
- **Final local gate boundary**: One invariant full repository Gate over this exact governance and Product state remains before independent review. No completion or delivery claim is made.

### Gate-Check Note — 2026-07-26 (Phase 4C Windows-First Rehearsal)

- **Check**: Full repository Gate after the Windows-first Product correction, full regressions, and direct deterministic evidence.
- **Observed pre-note run**: `GATE PASSED WITH NOTES`; Gate Python `188 passed`; pinned Pester 5.6.1 `281 passed / 0 failed / 0 skipped / 0 not run / 0 inconclusive / 0 failed containers`; exact branch `feat/phase-4c-migration-rehearsal`, HEAD `a5f7161df0f453e2cf22db780cf5fe20eea4cac5`, full status, eight paths, bytes, and SHA-256 were invariant.
- **Notes**: The two approved Agent line-count warnings, historical legacy Review warning, and pre-existing `pytest-asyncio` configuration deprecation remain warning-only. No deterministic contract failed and no warning source changed in Phase 4C.
- **Decision**: Proceed only after one immediate Gate rerun over this appended note. The rerun must again produce Gate Python `188 passed`, Pester `281 passed`, the same notes, and exact branch/HEAD/status/eight-path byte/SHA-256 invariance; otherwise this checkpoint is invalid and delivery stops.

### A-14 Phase 4C First Windows-First Review and Correction 2 Checkpoint

- **Independent review**: The first Windows-first exact eight-path Reviewer requested GPT-5.4 mini / medium, with observed model/effort unknown, returned `BLOCKED` at `0 Critical / 3 High / 0 Medium / 2 Low`. The three Applicable High findings were source/workspace path overlap that could mutate the source fixture, legacy corruption validation weaker than the Production reader, and live publication of a candidate containing `committed` before post-write proof. The Reviewer did not block on hostile concurrency, POSIX/Linux parity, durable `fsync`, automatic Journal recovery, Prune, or Tombstone.
- **Applicable Low disposition**: A narrow historical v1 vector was added to Product regression evidence. The older Phase 4B authorization text remains intact but now carries an explicit historical-snapshot notice that Amendment A-14 supersedes it. Neither improvement changes the Schema, Catalog, or Stable IDs.
- **Correction 2/3 RED**: The overlap regression reproduced an unbounded self-copy when `WorkspaceParent` equaled the source fixture; Luna safely terminated that focused run after more than 50 seconds instead of claiming an assertion count. After the minimum pre-creation overlap guard, the remaining malformed-legacy and publication-boundary regressions produced pinned Pester 5.6.1 `22 passed / 7 failed / 0 skipped`.
- **Correction 2/3 GREEN**: Pinned Pester 5.6.1 passed `29 / 29`; Python focused passed `15 / 15`. Equal, ancestor, and descendant source/workspace overlap is rejected before parent or child creation. Strict UTF-8 and Production-aligned component object/name/duplicate validation classify malformed legacy input as corrupt before backup or candidate creation. Candidate bytes are staged, reopened, Schema/Catalog/exact-byte validated, and only then moved to the live workspace Manifest. A deterministic staging validation failure leaves exact legacy live bytes and no persisted committed claim; final-publication uncertainty remains `manual-recovery-required` without speculative Restore.
- **Superseded evidence**: Every focused/full/direct/Gate result recorded before Correction 2 remains historical but is invalid for delivery because Product changed after the first review. The correction stayed within the exact two PowerShell Product/Test paths and introduced no Phase 4D behavior, normal-writer integration, real-adopter operation, Journal, hostile-lock defense, automatic recovery engine, Prune, or Tombstone.
- **Stable Product inventory after Correction 2**: `scripts/manifest_migration_rehearsal.py` = `13797` bytes / SHA-256 `eac934cf53ee0dff96d9291caef6c33aef17697ef23a097e35f53d1c55ac8402`; `scripts/manifest-migration-rehearsal.ps1` = `30791` bytes / `e62f08ec22deb0471145b402dea3e2e8eec5d86f46c844a8f6f4cb98ae41ed4d`; `scripts/tests/test_manifest_migration_rehearsal.py` = `6276` bytes / `f8a25266200f2a44a49d4d462b41be9eaf98df24fae2d677408840afff247c87`; `scripts/manifest-migration-rehearsal.Tests.ps1` = `21331` bytes / `7a2e141f4a608f6d64fd1adca087448372f494c61b8bf129071c3b39a7c5268e`.
- **Remaining gates**: Full Python and pinned Pester regressions, all direct deterministic checks, one valid invariant full repository Gate over the final governance state, and a new independent exact-diff review remain before any commit or remote delivery action.

### A-14 Phase 4C Post-Correction Full Regression Checkpoint

- **Full Python regression**: `python -m pytest scripts/tests -q -p no:cacheprovider` passed `203 / 203` in `50.47s`, with no failure or skip. The existing `pytest-asyncio` configuration deprecation warning remains warning-only.
- **Full Windows regression**: Pinned Pester 5.6.1 discovered `291` tests across `scripts` and `tools`; `291 passed / 0 failed / 0 skipped / 0 not run / 0 inconclusive / 0 failed containers` in `123.4s`.
- **State**: Correction 2 Product and current governance are stable for direct deterministic verification and one final invariant full repository Gate. A new independent exact eight-path review remains mandatory before commit.

### A-14 Phase 4C Post-Correction Direct Deterministic Checkpoint

- **Required checks passed**: generated `.github/**` sync; Catalog at `9` Agents / `10` Prompts / `35` total Skills / `34` adopter / `1` maintainer-only; lifecycle contract; Change Package contract; Agent structure; all `19` tracked JSON parses; in-memory Python compile; both Phase 4C PowerShell parsers; `git diff --check`; and exact eight-path scope with `0` missing and `0` extra.
- **Warning-only notes**: The historical legacy Review compatibility warning, `agents/pm.agent.md` and `agents/spec.agent.md` at `29` non-empty lines, and the pre-existing `pytest-asyncio` deprecation remain unchanged and warning-only. No source of those notes is in the Phase 4C allowlist.
- **Final local gate boundary**: Governance is complete before the Gate note. Run one exact invariant full repository Gate, append its observed evidence, then immediately rerun over the appended note without further file modification. Any deterministic failure or branch/HEAD/status/path/byte/hash drift blocks review and delivery.

### Gate-Check Note — 2026-07-26 (Phase 4C Correction 2 Final State)

- **Observed pre-note Gate**: `GATE PASSED WITH NOTES`; Gate Python `188 passed`; pinned Pester 5.6.1 `291 passed / 0 failed / 0 skipped / 0 not run / 0 inconclusive / 0 failed containers`.
- **Invariant proof**: Exact branch `feat/phase-4c-migration-rehearsal`, HEAD `a5f7161df0f453e2cf22db780cf5fe20eea4cac5`, complete porcelain status, exact eight paths, byte lengths, and SHA-256 digests were identical before and after the Gate.
- **Notes**: The two existing Agent line-count warnings, historical legacy Review warning, and pre-existing `pytest-asyncio` deprecation remain warning-only. No deterministic contract failed and no warning source changed.
- **Decision**: This evidence note changes governance bytes and therefore the pre-note Gate cannot authorize delivery. Immediately rerun the same invariant Gate over this appended note without any further edit. Only a matching successful rerun may support the new independent exact-diff review.

### A-14 Phase 4C Second Review and Final Correction Boundary

- **Final Gate before review**: The immediate rerun returned `GATE PASSED WITH NOTES`, Gate Python `188`, pinned Pester 5.6.1 `291 / 291`, and exact branch/HEAD/status/eight-path length/SHA-256 invariance. The subsequent independent review, not a deterministic failure, invalidated delivery readiness by finding one new Applicable High.
- **Second independent review**: The new Reviewer requested GPT-5.4 mini / medium with observed model/effort unknown and returned `BLOCKED`, Applicable Critical/High/Medium/Low = `0/1/0/0`, plus one non-blocking Python classifier improvement. A conflicting legacy locator and fabricated but well-formed `source_hash` could be assigned the Catalog path's Stable ID, have its locator silently rewritten, and be persisted as current `proposed_source` without a manual decision. This is ordinary-input Legacy ownership/source-lineage inference, not a Deferred concurrency or platform-parity requirement.
- **Resolved prior findings**: The Reviewer independently confirmed the source/workspace overlap guard, strict PowerShell legacy corruption classification, and stage-before-live committed boundary. It also confirmed exact eight-path scope, no Schema/Catalog/bootstrap diff, normal writers at v2, and no Phase 4D or real-adopter capability.
- **Correction 3/3 boundary**: The sole Luna Product writer may change only the four Phase 4C Product/Test paths to require exact Catalog-component locator binding, derive `proposed_source` only from exact current repository source bytes, reject inconsistent legacy source/baseline evidence to manual decision, and align the Python reference classifier. No Production writer, Schema/Catalog/ID change, source download, generated/project-owned ownership inference, Journal/Restore, or later-Phase capability is allowed.
- **Budget and evidence reset**: This is the final authorized Product correction. Every prior Product-dependent focused/full/Gate/review result remains historical and cannot authorize delivery. A successful correction still requires affected focused RED/GREEN, full regressions, direct checks, a new invariant Gate sequence, and another new independent exact-diff review. Any remaining Applicable Critical/High or blocking data-integrity Medium stops Phase 4C.

### A-14 Phase 4C Correction 3/3 Checkpoint

- **Final correction RED**: Python focused produced `16 passed / 10 failed`; pinned Pester produced `28 passed / 5 failed`. An additional Ordinal-only selected Pester run discovered `35` tests and produced `4 passed / 2 failed / 29 not run`, proving PowerShell's default case-insensitive comparisons could still map case-mismatched names/locators.
- **Final correction GREEN**: Sol reproduced Python focused `27 / 27` and pinned Pester 5.6.1 `35 / 35`, with zero failed, skipped, not-run, inconclusive, or failed-container results. Python AST, PowerShell parsing, `git diff --check`, and exact eight-path scope also pass.
- **Lineage result**: Only an active canonical regular file with an Ordinal-exact Catalog path, exact `template:<canonical_source_path>` legacy locator, `template-managed` ownership, matching file kind, and legacy `source_hash == managed_hash` is eligible. Generated, project-owned, compatibility, special/unproven mapping, empty/conflicting/prefix-only/case-mismatched locator, case-mismatched component name, or inconsistent source hash remains a manual decision with no v3 component.
- **Current-source proof**: `proposed_source` is computed from exact current repository source bytes after root containment, regular-file, and pre-existing ReparsePoint checks. It is no longer copied from legacy evidence. Fresh copied adopter bytes independently determine `observed_before`, `result_after`, and Untouched/Customized classification.
- **Reference parity**: The Python in-memory reference applies the same conservative mapping/current-source contract and now classifies non-object, missing/blank/unsafe-name, and exact duplicate legacy component records as corrupt. It remains non-publishing and is not a Production writer.
- **Stable Product inventory after Correction 3**: `scripts/manifest_migration_rehearsal.py` = `16015` bytes / SHA-256 `1eb90427b266ef947d2a95463f91cfdb7f8ae84287337ffed47ac87bef77747f`; `scripts/manifest-migration-rehearsal.ps1` = `32386` bytes / `80b2685744ae32c60885d2f3d1c128b97e973c0b077ebf405042961ba5592663`; `scripts/tests/test_manifest_migration_rehearsal.py` = `9210` bytes / `277de83484fb93b17c33669f3410a6910a202da7d98f4c3e3c0f3b7930221784`; `scripts/manifest-migration-rehearsal.Tests.ps1` = `23938` bytes / `5a086c1b832d8a6ef5da77ba07e991e8d8bfa9895c5b74a363ceb210518dbf61`.
- **Budget exhausted**: All three Windows-first Product corrections are used. Full regressions, direct deterministic checks, a final invariant Gate sequence, and a new independent exact-diff review remain. Any remaining Applicable Critical/High or blocking data-integrity Medium ends Phase 4C without commit.

### A-14 Phase 4C Final-Correction Full Regression Checkpoint

- **Full Python regression**: `python -m pytest scripts/tests -q -p no:cacheprovider` passed `215 / 215` in `50.22s`, with no failure or skip. The existing `pytest-asyncio` configuration deprecation warning remains warning-only.
- **Full Windows regression**: Pinned Pester 5.6.1 discovered `297` tests across `scripts` and `tools`; `297 passed / 0 failed / 0 skipped / 0 not run / 0 inconclusive / 0 failed containers` in `132.06s`.
- **State**: Final-correction Product and governance are stable for direct deterministic verification. The final invariant Gate sequence and a new independent exact eight-path review remain mandatory; the correction budget remains exhausted.

### A-14 Phase 4C Final-Correction Direct Deterministic Checkpoint

- **Required checks passed**: generated `.github/**` sync; Catalog at `9` Agents / `10` Prompts / `35` total Skills / `34` adopter / `1` maintainer-only; lifecycle; Change Package; Agent structure; all `19` tracked JSON parses; in-memory Python compile; both Phase 4C PowerShell parsers; `git diff --check`; and exact eight-path scope with `0` missing and `0` extra.
- **Warning-only notes**: The two existing Agent line-count warnings and historical legacy Review compatibility warning remain unchanged; the existing `pytest-asyncio` deprecation remains warning-only. No warning source is in the allowlist.
- **Final Gate boundary**: Run one governance-complete invariant full repository Gate, append its exact result, and immediately rerun over the note without further modification. Any deterministic failure or branch/HEAD/status/path/byte/hash drift ends Phase 4C because no correction remains.

### Gate-Check Note — 2026-07-26 (Phase 4C Final Correction)

- **Observed pre-note Gate**: `GATE PASSED WITH NOTES`; Gate Python `188 passed`; pinned Pester 5.6.1 `297 passed / 0 failed / 0 skipped / 0 not run / 0 inconclusive / 0 failed containers`.
- **Invariant proof**: Exact branch `feat/phase-4c-migration-rehearsal`, HEAD `a5f7161df0f453e2cf22db780cf5fe20eea4cac5`, complete porcelain status, exact eight paths, byte lengths, and SHA-256 digests were identical before and after the Gate.
- **Notes**: The two existing Agent line-count warnings, historical legacy Review warning, and pre-existing `pytest-asyncio` deprecation remain warning-only. No deterministic contract failed.
- **Decision**: This appended note invalidates the pre-note run for delivery. Immediately rerun the same invariant Gate without any further file modification. A mismatch or failure ends Phase 4C; a matching success permits only the final new independent exact-diff review.

### A-14 Phase 4C Final Review Stop — Correction Budget Exhausted

- **Final Gate rerun**: `GATE PASSED WITH NOTES`; Gate Python `188`, pinned Pester 5.6.1 `297 / 297`, zero failed/skipped/not-run/inconclusive/failed-container results, and exact branch/HEAD/status/eight-path length/SHA-256 invariance.
- **Final independent review**: The new read-only Reviewer requested GPT-5.4 mini / medium with observed model/effort unknown and returned `BLOCKED`: one Applicable blocking Medium, zero Applicable non-blocking findings, eight approved Deferred boundaries, and four Out-of-Phase boundaries.
- **Blocking evidence**: When the copied fixture contains an existing directory named `.ai-workflow-install.json`, `Get-ManifestClassification` treats the non-leaf as absent and the public entry returns exit `0`, `status=report-only`, `classification=missing`. Both unchanged Production readers classify the existing unreadable/non-regular Manifest path as corrupt. No source bytes changed and no candidate/backup was created, but the success classification violates the corrupt hard-stop and honest-result contract in ordinary supported Windows operation.
- **Prior finding disposition**: Exact legacy locator/Catalog/current-source proof is resolved; conflicting/fabricated/case/empty/prefix and unsupported-role records remain manual. Source/workspace overlap, strict malformed legacy classification, fresh Customized evidence, stage-before-live committed truth, backup/diagnostic tested failures, exact scope, and normal-writer v2 isolation remain resolved. Raw backslash separator representation is not a finding because the supported legacy writer normalizes it before Catalog identity and all exact locator/ownership/kind/hash proofs still apply.
- **Stop decision**: Correction 3/3 is exhausted, and this Applicable blocking Medium concerns false success. Per the approved Program stop conditions, Phase 4C stops without commit, push, PR, CI, merge, or later-Phase work. No Product correction was attempted after the review. The exact eight-path candidate remains preserved for manual/user adjudication.
- **Delivery state**: Phase 4C Windows-first = incomplete/blocked; Phase 4 overall = incomplete; Phase 4D, 4E, 5, 6, and Final Closeout = not started in this run. Production writers still emit v2. No real-adopter Migration, Restore, Cleanup, deployment, production operation, Adapter implementation, branch deletion, tag, or release occurred.

### A-14 Phase 4C Manifest Path-Type Closure and Acceptance

- **Approval source**: Explicit current-task authorization, `Phase 4C Final Windows Manifest Path-Type Closure and Delivery`. This authorization reopens only the known non-leaf Manifest-path blocker and its Phase 4C delivery actions. It does not reopen the Windows-first profile, Schema, Catalog, Stable Component IDs, Deferred hostile-concurrency requirements, or Phase 4D.
- **Writer boundary**: Sol requested GPT-5.6 Sol / high and is the sole Product/Test writer; observed model/effort are unknown. No Luna or other write-capable subagent was invoked. Product correction count for this closure is `1`, limited to `scripts/manifest-migration-rehearsal.ps1` and `scripts/manifest-migration-rehearsal.Tests.ps1`; the Python reference and tests remained byte-identical.
- **Path-Type resolution**: Only a genuine absent-path `ItemNotFoundException` produces `missing/report-only/exit 0`. Regular files enter the existing strict parser. Directory/container and other non-regular objects produce `corrupt`; ReparsePoint/Junction/SymbolicLink paths produce `unsafe-path`; all other inspection/access failures produce `corrupt`. Non-absent unsafe or unprovable paths return nonzero without backup or candidate publication, and source fixture inventories remain unchanged.
- **RED/GREEN evidence**: Focused Path-Type RED selected `6` of `38` Pester cases and produced `4 passed / 2 failed / 32 not run`. GREEN produced `6 passed / 0 failed / 0 skipped / 32 not run`. The complete Phase 4C focused Pester file passed `38 / 38`. Python was not modified and its focused suite was not redundantly rerun.
- **Single Full Gate evidence**: The one post-fix repository Gate returned `GATE PASSED WITH NOTES`, Python `188 / 188`, pinned Pester 5.6.1 `300 / 300`, and zero negative Pester counts. All required sync, Catalog, lifecycle, Change Package, Agent structure, JSON/Schema/parser/compile, and diff checks passed. Branch, HEAD, complete status, exact eight-path inventory, lengths, and SHA-256 were invariant before and after the Gate. Notes are limited to the existing Agent line-count, historical legacy Review, and `pytest-asyncio` deprecation warnings.
- **Independent review**: The sole new read-only Reviewer requested GPT-5.4 mini / medium; observed model/effort are unknown. The Reviewer returned `ACCEPTED`, with `0` Blocking and `0` Critical/High findings. One Low non-blocking coverage note records the absence of a practical Windows fixture for the explicit non-container/non-reparse/non-`FileInfo` branch; the branch is fail-closed and inspection-failure behavior has focused coverage.
- **Deferred boundary retained**: Hostile concurrent replacement, POSIX descriptor chains, Linux mutation parity, Python/PowerShell Production writer parity, durable `fsync`, automatic recovery from untrusted Journal, automatic Prune, and Tombstone mutation remain Deferred and were not treated as blockers.
- **Delivery state**: The exact eight-path candidate has completed local Product acceptance and may proceed to the separately authorized commit, normal feature-branch push, non-Draft PR, CI/review/thread verification, expected-head guarded squash merge, and ff-only `main` synchronization. Until those actions complete, Phase 4C remains pending delivery. Production writers still emit v2; no real-adopter Migration, Restore, Cleanup, deployment, production operation, or Phase 4D work occurred.
- **Architecture direction changed**: No.

### A-14 Phase 4C PR #14 Ubuntu Matrix-Test Correction

- **Remote evidence before correction**: Main commit `a53de52d4819812050b681f555f188fa59e781b5` was normally pushed to the retained Phase 4C feature branch and opened as non-Draft PR #14 to `main`. The PR base/head/files were exact, it was `MERGEABLE`, and reviews/reviewThreads were empty. The `verify` check passed.
- **CI failure classification**: Ubuntu baseline Pester discovered `300` tests and produced `299 passed / 1 failed`. The only failure was the Windows leaf-Junction Path-Type test expecting the Windows entry point to reject a junction. Linux PowerShell accepted `New-Item -ItemType Junction` without Windows ReparsePoint semantics, so this was an exact test-platform boundary inside the fixed Matrix, not a Production Matrix failure or a new Critical/High.
- **Authorized CI correction 1/1**: The sole change is a four-line `$IsWindows` guard in `scripts/manifest-migration-rehearsal.Tests.ps1`. Non-Windows records an explicit skip because Linux mutation parity is Deferred; Windows still executes the full junction/no-target-read/source-and-target-invariance/hard-stop proof. No Product code or contract changed.
- **Verification and review**: Windows focused Path-Type Pester passed `6 / 6` with zero failure or skip. The single post-correction Full Gate returned `GATE PASSED WITH NOTES`, Python `188`, pinned Pester `300 / 300`, zero negative counts, and exact branch/HEAD/status/modified-test length/SHA-256 invariance. The same sole independent read-only Reviewer returned `ACCEPTED`, with `0` Blocking, `0` Critical/High, and `0` non-blocking findings.
- **Delivery boundary**: PR #14's required CI and merge path are complete; PR #14 is authoritative merged evidence and Phase 4C = Complete / merged. The earlier correction-pending wording is superseded. Phase 4D is separately active as the current Build candidate; real-adopter operations remain out of scope.
- **Architecture direction changed**: No.

### Phase 4D Build Candidate Governance — 2026-08-14

- **Status correction**: Phase 4C authoritative status is Complete / merged, including PR #14 merge evidence. Phase 4D is In progress / Build candidate, not Complete and not Awaiting Acceptance until a PR is actually created. Phase 4 overall remains Incomplete.
- **Frozen A–G boundary**: New Install emits v3; explicit `-MigrationPreview` is deterministic/no-write; explicit `-ApplyMigration -ExpectedPreviewId` recomputes and binds to the preview; general v1/v2 Update does not auto-migrate; valid-v3 Update manages only trusted Untouched records; Customized, Legacy, Unknown, Project-owned, and stale records are preserved or reported; corrupt/unsupported/unsafe input hard-stops before writes; Manifest is published last; failure retains backup/diagnostic and never reports false success.
- **Excluded/deferred**: Python/Linux v3 writer, automatic prune/delete/tombstone, automatic restore, Lock/Journal/Recovery Engine, hostile concurrency, and real-adopter migration/restore/cleanup were not implemented or executed. `Force` and `AlwaysOverwrite` do not bypass v3 ownership. Schema, Catalog, Phase 4C, and Python writer boundaries remain unchanged.
- **Verification handoff**: Product/Test remained unchanged during governance. Carry forward the existing focused Pester 5.6.1 `23/23` evidence, run the one Repository Full Gate after these documentation edits, then stop Product changes after a passing Gate. No independent Reviewer is called in this Build; acceptance is delegated to a new Session.

### Phase 4D Repository Full Gate Stop — 2026-08-14

- **Result**: The one authorized Repository Full Gate returned `GATE FAILED`; no delivery action followed.
- **Counts**: Python required check `76 passed / 12 failed`; pinned Pester 5.6.1 `323 total / 317 passed / 6 failed / 0 skipped`; sync, Catalog, lifecycle, Change Package, Agent structure, and diff-check passed, and the Gate preserved worktree status.
- **Classification**: Python failures are Phase 0B Bash tests using `/bin/bash` against a Windows `<repo-root>/scripts/bootstrap.sh` path (environment/path). Pester failures are six deterministic contract mismatches: missing-manifest diagnostic wording, schema-v2 writer regression expectation, and four Phase 4A valid-v3 route expectations for the retired `manifest-v3-writer-disabled` behavior.
- **Stop**: No Product/Test correction, commit, push, PR, independent Reviewer, CI, merge, auto-merge, admin bypass, branch deletion, or later phase was started. Phase 4D is blocked as a Build candidate; Phase 4 overall remains Incomplete.

### Phase 4D Bounded Failure Triage and Correction — 2026-08-16

- **Attribution**: Python Phase 0B failures are BASELINE-ENVIRONMENT; exact clean-main and current targeted runs pass `13/13`. The six Pester failures are EXPECTATION-CHANGED under the approved Phase 4D A–G contract. The clean-main route line-wrap issue remains baseline-only and was not corrected.
- **Correction scope**: Only `scripts/bootstrap.Tests.ps1` changed. It updates the retired missing-manifest wording and schema-v2 expectation, and rewrites the four stale valid-v3 route assertions to prove Phase 4D explicit-update/no-update behavior, backup, valid-v3 publication, and preservation. No Product code or new capability changed.
- **Pre-Gate evidence**: Corrected cases `6 passed / 0 failed / 0 skipped / 0 inconclusive`; Phase 4D focused `23 passed / 0 failed / 0 skipped`; Python Phase 0B `13 passed`. The one Repository Full Gate is pending with Git Bash explicitly selected for the known environment boundary.

### Phase 4D Repository Full Gate Result — 2026-08-16

- **Gate**: `GATE PASSED WITH NOTES`; Python `188 passed`; pinned Pester 5.6.1 `323 passed / 0 failed / 0 skipped`; all other required gate components passed and worktree status was invariant.
- **Note and boundary**: The only note is the pre-existing Agent line-count warning. Product/Test are frozen after this Gate. Phase 4D remains In progress / Build candidate, not Complete; no commit, push, PR, CI, merge, or independent Reviewer was invoked.
### Phase 4D Final Delivery Evidence — 2026-08-16

- **Superseding status**: This entry supersedes the prior Build-candidate and Gate-stop entries for Phase 4D. Phase 4C = Complete / merged (PR #14) remains authoritative. Phase 4D = Complete / merged (PR #15). Phase 4 overall = Incomplete; Phase 4E = Not started.
- **PR #15**: Non-Draft, Open → merged. Base = main @ 13669f4929fb7ea9eeab8b2128295eaa1f4583cf. Original PR head = 5c4f65e7d3f6f48427925b07c19df3110f3071ca (commit: feat: 啟用 Windows PowerShell Manifest v3 寫入與明確遷移).
- **Independent Acceptance Session**: A new Acceptance Session verified the PR #15 Phase 4D Product, corrected known Ubuntu Pester portability issues, completed Acceptance Review, and performed guarded squash merge.
- **Test-only correction**: Commit 9f58a458576d5a683ed18574d84d3a8bf9465522 (test: 修正 Phase 4D 跨平台 hidden path 驗證) modified only scripts/bootstrap.Tests.ps1 — 6 lines adding -Force to Get-Item/Get-ChildItem calls accessing dot-prefixed hidden paths on Unix PowerShell. Product scripts/bootstrap.ps1 was not modified by the correction.
- **Final PR head**: 9f58a458576d5a683ed18574d84d3a8bf9465522.
- **Changed files**: 8 (unchanged from original PR): BOOTSTRAP-GUIDE.md, changes/workflow-agents-responsibility-alignment/{02-decision-log.md, 04-plan.md, 05-test-plan.md, 06-impact-analysis.md, phase-4-windows-first-execution-profile.md}, scripts/bootstrap.Tests.ps1, scripts/bootstrap.ps1.
- **Remote CI on final head**: Verify Change Package = success; Windows baseline = success (Python 188 passed, Pester 323 passed / 0 failed / 0 skipped); Ubuntu baseline = success (Python 188 passed, Pester 321 passed / 0 failed / 0 skipped). The 5 originally-failing Ubuntu tests now pass (not skipped).
- **Independent Acceptance Review**: PASS — no blocking findings. All 10 checklist items verified: A–G fixed state matrix, Product diff, Customized/Legacy/Project-owned preservation, v1/v2 no auto-migration, Preview deterministic/no-write, Apply requires matching Preview, Corrupt/Unsupported hard-stop, failure no false-success, no prune/tombstone/automatic restore, and Ubuntu correction no coverage reduction.
- **GitHub reviews**: none submitted. GitHub review threads: none.
- **Squash merge**: Method = squash merge with expected-head guard (expected_head_sha = 9f58a458576d5a683ed18574d84d3a8bf9465522). Squash merge SHA = 5cd848b86c5e084d6d30096daa3f1c04c661b26b. No auto-merge, admin bypass, rebase merge, normal merge, branch deletion, or tag/release.
- **Post-merge**: git pull --ff-only origin main succeeded. Local main = origin/main = 5cd848b86c5e084d6d30096daa3f1c04c661b26b. Worktree clean. Feature branch retained locally and remotely.
- **Delivery state**: Phase 4D = Complete / merged. Windows PowerShell New Install emits Manifest v3. v1/v2 General Update does not auto-migrate. Preview is deterministic/no-write. Apply requires matching Preview. valid-v3 ownership update enabled. Customized/Legacy/Project-owned preserved. Corrupt/Unsupported hard-stop. No automatic prune/tombstone. Python/Linux v3 Writer deferred. No real migration/restore/cleanup executed. Phase 4 overall = Incomplete. Phase 4E = Not started (next eligible phase).
- **Architecture direction changed**: No.

### Phase 4E / Phase 4 Post-Merge Governance Closure — 2026-08-16

- **Superseding status**: This entry supersedes the prior Phase 4E Build Candidate / Awaiting Independent Acceptance status. Phase 4C = Complete / merged (PR #14), Phase 4D = Complete / merged (PR #15), Phase 4E = Complete / merged (PR #17), and Phase 4 overall = Complete. Phase 5 = Not started / next eligible phase; no Phase 5 execution began.
- **Final correction contract**: `manual-cleanup-candidate` requires all of `valid-v3`, a Manifest record, a regular target file, exact trusted-baseline equality, typed Catalog retirement evidence, generated/derived-runtime cleanup scope, and trusted ownership/provenance. Source working-tree absence alone does not prove retirement. Active canonical/generated components are not cleanup candidates. Modified retired derived output is `manual-review; preserve`. Eligibility remains `false`; the recommendation is not deletion authority.
- **Delivery evidence**: Original PR head = `f62559e9159d3d3abd23f9290fde70e46e784055`; correction/final head = `b908e36d3135cc9b186fc978534120ba0cc972ec`; expected-head guarded squash merge SHA = `9d55ee112cc826f30c57de3a775041d462587fde`.
- **Authoritative CI**: Verify Change Package = success. Windows baseline = success with Python `188 passed` and Pester `336/336`, zero failed/skipped/not-run. Ubuntu baseline = success with Python `188 passed` and Pester `334/334`, zero failed/skipped/not-run. Both remote Gates returned `GATE PASSED WITH NOTES` and preserved worktree invariance.
- **Acceptance evidence**: Phase 4E focused verification was `13 passed / 0 failed / 0 skipped`. Independent Acceptance is evidence from the Acceptance Session; no GitHub submitted review or review thread exists. The merged PR body remains unchanged: its original Build-time evidence is superseded for the final contract by final-head `b908e36` plus the authoritative CI evidence.
- **Local Gate boundary**: Local Full Gate was `LOCAL-ENVIRONMENT-UNAVAILABLE` in the sandbox because the test-harness prerequisite behavior recursively spawned Gate processes. It was not treated as local PASS; remote Windows/Ubuntu CI is the authoritative Full Gate evidence.
- **Operational and artifact boundary**: No delete, prune, tombstone, new CLI, real cleanup, migration, restore, deployment, or adopter operation occurred. Schema and Catalog remained unchanged. This closure changes governance documentation only; Product, Test, Gate, and CI files are not changed by the closure.
- **Architecture direction changed**: No.
