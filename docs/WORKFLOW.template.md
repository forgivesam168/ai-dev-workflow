# Portable AI Development Workflow

<!-- lifecycle-contract:LIFECYCLE_SSOT -->
## Lifecycle SSOT

This file is the adopter distribution projection of the template's canonical lifecycle contract, not a second or independent policy owner. Once installed at project root as `WORKFLOW.md`, Project AGENTS declares it as the project's lifecycle SSOT. Agents, Skills, Prompts, and Instructions route to it without redefining modes, stage exits, artifacts, or authorization.

This portable projection makes no D-10 adapter capability claim; unobserved surface behavior remains Deferred. Phase 4 schema, migration, prune, and real-adopter migration behavior is not authorized here.

Every task selects exactly one mode: Simple, Standard, or High-Risk.

<!-- lifecycle-contract:MODE_SIMPLE -->
## Simple

Use Simple only for localized, reversible work with one reliable targeted verification path and no auth, security, financial, migration, deployment, destructive, or public-breaking boundary. Simple uses lightweight Understand, Implement, Prove, and Deliver checkpoints and does not require a Change Package, Review artifact, or Archive / Closeout artifact.

<!-- lifecycle-contract:MODE_STANDARD -->
## Standard

Use Standard for normal feature work, multiple files or components, meaningful design choices, bounded contract/config changes, or moderate regression risk. Declare exactly one plan/lifecycle SSOT and select only the stages needed for their exit evidence.

A compact Change Package is required when Standard work is cross-session, cross-component, contract-change, independent-review, migration/audit-sensitive, or escalation-prone. Otherwise one declared plan/lifecycle SSOT is sufficient.

<!-- lifecycle-contract:MODE_HIGH_RISK -->
## High-Risk

Use High-Risk for security, auth, permission, financial, migration, public breaking changes, irreversible data work, deployment, production, or major architecture work. It requires the full Workflow, complete Change Package, explicit approvals, independent review, rollback or migration evidence, and operational evidence appropriate to the change.

<!-- lifecycle-contract:MODE_ESCALATION -->
## Escalation

When Simple or Standard loses reliable verification, crosses components or contracts, becomes difficult to reverse, or reaches a High-Risk boundary, stop and reclassify or escalate before continuing implementation.

<!-- lifecycle-contract:STAGE_ENTRY_EXIT -->
## Stage entry and exit

Filename existence never proves a stage complete. Selected stages use these portable Entry and Exit semantics:

| Stage | Entry | Exit |
|---|---|---|
| Brainstorm | Goal or material ambiguity needs exploration. | Requirements, options, risk, and unresolved choices are explicit. |
| Spec | Approved requirements need a behavioral contract. | Scope, observable acceptance criteria, exclusions, and dependencies are testable. |
| Plan | The approved contract needs executable sequencing. | Bounded steps, verification, dependencies, and rollback or safe-stop are executable. |
| Implement | Scope, authorization, and a reliable RED/GREEN path are ready. | Approved implementation and applicable verification evidence are recorded. |
| Review | Implementation and evidence are ready for independent review. | Review records findings, evidence, and a justified decision. |
| Closeout / Archive | Required Review and deterministic gates have completed. | Mode-required pre-merge closeout accurately records scope, evidence, review, delivery state, and remaining work. |

<!-- lifecycle-contract:PACKAGE_COMPACT -->
## Compact package

Triggered Standard uses Intake, decision evidence, plan/lifecycle evidence, exactly one task/status SSOT declaration, Review only when independent review is required, and pre-merge Closeout. A voluntarily created package follows its declared Compact or Full contract. Brainstorm, Spec, a separate Test Plan, and Impact Analysis are selected-stage or risk artifacts; they are never empty file-count padding.

<!-- lifecycle-contract:PACKAGE_FULL -->
## Full package

High-Risk uses the full `00`, `01`, `02`, `03`, `04`, `05`, and `06` evidence set plus Review and Closeout / Archive. Each required role must contain substantive evidence; empty files never satisfy the contract.

<!-- lifecycle-contract:TASK_STATUS_SSOT -->
## One task/status SSOT

Every lifecycle declaration appears exactly once in `00-intake.md`, including one task/status SSOT, external tracker, execution mode, package trigger/reason, and Compact or Full contract. Without an external tracker, the SSOT is an accessible package-relative or repository-relative file such as `04-plan.md`. With one, both pointer fields identify the same URL, `owner/repo#number`, or current-repository Issue/PR. Duplicate declarations, inaccessible pointers, unidentifiable trackers, and competing owners are blocking.

<!-- lifecycle-contract:GATE_ARCHITECTURE_DECISION_EXIT -->
## Architecture Decision Exit

Apply before an irreversible or high-cost architecture, security, permission, data, or public-contract decision enters downstream commitment.

Blocking conditions include an unresolved safety or authorization boundary, unsupported material source or assumption, an irreversible decision without viable rollback/migration/compensation, or unresolved material contract conflict.

Warning-only findings are maintainability, naming, or optional documentation preferences that do not affect correctness, security, reversibility, or contract behavior.

<!-- lifecycle-contract:GATE_PRE_IMPLEMENTATION_READINESS -->
## Pre-Implementation Readiness

Apply before every High-Risk implementation.

Blocking conditions include unresolved required AC/scope/decision/prerequisite, missing protected-action approval, missing executable migration/rollback/recovery when applicable, no reliable RED/GREEN or other verifiable path, or unclear ownership/affected-system boundary.

Warning-only findings are optional documentation, presentation, or wording improvements that do not affect safe or verifiable implementation.

<!-- lifecycle-contract:GATE_PRE_DELIVERY_VERIFICATION -->
## Pre-Delivery Verification

Apply before every High-Risk commit, push, PR, or merge.

Blocking conditions include a known red test/build/lint/static check/required gate, unproven material requirement or AC, invariant failure, scope leakage, generated drift, invalid worktree state, missing independent review, or unresolved Critical/High finding.

Warning-only findings are style, presentation, or low-impact clarity issues that do not affect correctness or auditability.

<!-- lifecycle-contract:GATE_MIGRATION_DEPLOYMENT_READINESS -->
## Migration / Deployment Readiness

Apply only when migration, deployment, production, or irreversible data execution is in scope and separately authorized.

Blocking conditions include missing explicit current-task action-specific execution approval, unbounded target/batch/population, missing rollback/restore/compensation/safe-stop, missing rehearsal/recovery validation/operational signal, or unclear ownership/backup/reversibility/failure handling.

Warning-only findings are non-critical presentation, report-formatting, or optional-observability improvements. Otherwise record `N/A — no migration or deployment execution is authorized in this Phase.`

<!-- lifecycle-contract:CROSS_GATE_SEMANTICS -->
## Cross-gate semantics

Deterministic failure is always blocking. Warning-only findings stay warnings unless new evidence matches an approved blocking condition. Resolve blocking findings before the next gate. N/A requires an auditable reason. `agentic-eval` is self-evaluation and never replaces independent review or overrides deterministic checks. The named gates use rule-based conditions with no aggregate score or numeric threshold.

<!-- lifecycle-contract:REVIEW_ROLE -->
## Review role

New packages use canonical `07-review.md`; legacy `05-review.md` remains recognized. Review records substantive reviewed scope/reviewer evidence, explicit Critical/High/Medium/Low status, readable targeted and required-gate status, unavailable-check evidence, and `Decision: PASS | PASS_WITH_NOTES | BLOCKED` with rationale. `None` is the explicit zero-finding value; `WARNING` is recorded but nonblocking; `BLOCKED` is a deterministic blocker. Unresolved Critical/High findings or a required deterministic failure require `BLOCKED`. Two independent Review bodies are competing evidence and blocking; an alias may coexist only as a pointer-only file.

<!-- lifecycle-contract:CLOSEOUT_ROLE -->
## Closeout / Archive role

New packages use canonical `99-archive.md`; `99-closeout.md` remains a compatibility alias. Closeout records a selected Outcome, approved scope, readable deterministic and Review status, `pre-merge` or `unmerged` delivery state, unavailable remote-delivery evidence, remaining/deferred work, authorization boundary, and exactly one rollback/recovery value containing substantive evidence or `N/A — reason`. `WARNING` is recorded but nonblocking; `BLOCKED` requires Outcome `BLOCKED`. Unchanged templates and option lists are incomplete. Two independent closeout bodies are competing evidence and blocking; an alias may coexist only as a pointer-only file.

<!-- lifecycle-contract:HYBRID_CLOSEOUT -->
## Hybrid closeout

Simple does not require Archive or Closeout. Standard without a package does not require Archive or Closeout. A voluntarily created package follows its declared contract. Triggered Standard completes pre-merge Closeout in the original implementation PR, and High-Risk also requires pre-merge Closeout. A blocked Review or required deterministic gate makes closeout `BLOCKED`.

Authoritative merge-result evidence remains external before merge. A pre-merge closeout must not claim an actual merged state, merge SHA, or `mergedAt` anywhere in the artifact. Expected head SHA, final head, and commit SHA evidence are allowed; no post-merge commit or push is created merely to add merge-result evidence.

<!-- lifecycle-contract:PROTECTED_ACTIONS -->
## Authorization boundary

Archive authorizes only requested local documentation. It never authorizes commit, push, tag, merge, branch deletion, remote Issue or PR closure, release, deployment, production, or other remote mutation. Each operational action needs separate explicit, current-task, action-specific approval.

<!-- lifecycle-contract:HONEST_COMPLETION -->
## Honest completion

Complete means the approved scope is complete, applicable verification evidence exists, and delivery state is accurate. Unverified, unmerged, partial, Deferred, blocked, N/A, and user-decision-dependent work remain distinct and must not be reported as Complete.
