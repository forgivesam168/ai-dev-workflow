# 03 Specification — Target Responsibility Architecture

## Status and Vocabulary

- **Architecture status**: Approved direction; not implemented
- **Risk**: High-Risk architecture/distribution change
- **Canonical**: Human-editable source from which representations are generated.
- **Derived runtime**: Generated or mounted CLI-compatible representation; not an independent policy source.
- **Adopter**: A project receiving assets through bootstrap.
- **Untouched adopter**: Current content is proven identical to its recorded managed baseline.
- **Customized adopter**: Current content differs from its recorded managed baseline.
- **Legacy adopter**: Proven lineage is unavailable, including projects without a trustworthy manifest.
- **Semantic role**: Lifecycle meaning independent of a specific historical filename.

## Goals

1. Establish one owner for every governance, lifecycle, methodology, distribution, and runtime responsibility.
2. Correct critical distribution and authorization defects without overwriting adopter customization.
3. Make execution risk-adaptive and portable across supported CLI capabilities.
4. Make migration, generation, and retirement decisions evidence-based and reversible.

## Non-Goals

- Define the complete future manifest JSON schema.
- Implement a CLI adapter whose official capability is not observed.
- Select a new Review or Archive filename in this stage.
- Automatically migrate or prune any adopter project.
- Replace project planning tools with the Change Package.

## Target Architecture Contract

### 1. User-level Global AGENTS

Global AGENTS owns cross-repository factuality, assumption discipline, planning and scope control, verification, external/destructive/Git authorization, completion honesty, independent review principles, and Checkpoints A–D.

It is user-owned and local-only. This repository and bootstrap must not install, update, require, or infer its presence.

### 2. Template Maintainer AGENTS

Root `AGENTS.md` owns the template product contract:

- canonical and derived source relationships;
- catalog and maintainer-only assets;
- bootstrap compatibility and distribution safety;
- sync/generator obligations;
- adopter impact, release, and migration review;
- maintainer CI and gates.

It must not be used as the adopter Project AGENTS template.

### 3. Adopter Project AGENTS

Adopter `AGENTS.md` owns:

- project purpose, domain, stack, structure, and SSOT;
- build, test, lint, and validation commands;
- project-specific risk and safety constraints;
- context loading and project completion requirements;
- Workflow entry guidance;
- approximately 6–10 standalone fallback rules.

Fallback rules must cover evidence, material assumptions, scoped changes, secrets, protected-action approval, verification, and honest completion. They must not reproduce the complete Global document.

### 4. WORKFLOW Lifecycle SSOT

The canonical Workflow contract is the lifecycle SSOT and owns:

- Simple, Standard, and High-Risk modes;
- lifecycle stage purpose and entry/exit criteria;
- risk escalation;
- selected artifact requirements;
- handoff and return-to-understand behavior;
- Review and closeout semantics.

Agents, Skills, and Prompts may reference this contract but must not redefine it.

The current root `WORKFLOW.md` is a maintainer-repository source. Phase 3 must decide and obtain approval for the adopter-facing lifecycle source before bootstrap distribution. Permitted design candidates are an adopter-specific lifecycle template, a shared canonical lifecycle core with maintainer/adopter projections, or a shared document proven fully generic by explicit maintainer/adopter difference review. This Spec does not select a model, filename, or path, and bootstrap must not treat root maintainer `WORKFLOW.md` as the adopter-installed contract by default.

### 5. Risk-Adaptive Execution Modes

#### Simple

Entry requires localized, reversible scope; no auth/security/financial/migration/deployment/destructive/public-breaking boundary; and one reliable targeted verification path.

Required artifacts: none beyond an inline or existing project plan when useful. Required gates: lightweight Understand, Implement, Prove, Deliver and targeted verification.

Escalate when scope crosses components/contracts, becomes difficult to reverse, loses reliable verification, or reaches a High-Risk boundary.

#### Standard

Entry includes normal feature work, multiple files/components, meaningful design choices, bounded contract/config changes, or moderate regression risk.

Required artifacts: exactly one plan/lifecycle SSOT. A compact Change Package is required for cross-session, cross-component, contract-change, independent-review, migration/audit-trace, or escalation-prone work.

Required gates: explicit risk classification, selected stage exit criteria, verification evidence, and independent review when the risk requires it.

#### High-Risk

Entry includes security, auth, permissions, financial/ledger behavior, migrations, public breaking changes, irreversible data work, production/deployment, or major architecture change.

Required artifacts: complete Workflow and Change Package, explicit approvals, independent review, rollback/migration evidence, and operational validation appropriate to the change.

### 6. Change Package Responsibility

A Change Package is a lifecycle evidence container, decision trace, and implementation/verification record. It is not a complete project management system.

Each work item declares one task/status SSOT:

- with external tracker: package stores the pointer, decisions, and evidence;
- without external tracker: `04-plan.md` may explicitly be the task/status SSOT.

This Change Package uses `04-plan.md` as its SSOT.

Review is represented by a semantic lifecycle role. Legacy `05-review.md` remains a recognized alias until a separately approved migration selects a canonical filename.

### 7. Agent, Skill, Prompt, and Instruction Boundaries

#### Custom Agent

Owns persona, specialist lens, scope boundary, delegation/handoff intent, paired Skill references, and necessary tool/model restrictions.

Must not own full methodology, detailed rubrics, complete Workflow, Global governance, or Git/remote authorization. `≤25 non-empty lines` is a soft target; structural violations are a hard gate.

#### Skill

Owns reusable methodology, procedures, checklists, templates, and stage/domain tactics. It must not grant user-level authorization or redefine the always-on constitution.

#### Prompt

Owns explicit entry-point UX, parameter collection, and routing to canonical Workflow/Skill behavior. It must not become a policy SSOT.

#### Instruction

Owns path-, file-type-, language-, or domain-scoped behavior. It must not duplicate generic Workflow or Global policy.

### 8. Bootstrap Distribution Responsibility

Bootstrap owns packaging, installation, ownership classification, preservation, migration reporting, canonical-to-derived generation, compatibility reporting, and manifest maintenance.

It must:

- use the adopter-specific constitution source;
- keep project-owned guidance intact unless a separately approved migration is proven safe;
- exclude maintainer-only assets;
- install promised lifecycle assets under explicit ownership;
- distinguish new, untouched, customized, and legacy adopters;
- avoid using policy content as hidden installer control flow.

### 9. Manifest Safety Invariants

Future manifest evolution must be able to represent:

- previous managed baseline;
- current observed hash;
- new source hash;
- ownership;
- `generated_from` relationship;
- source release/version;
- fork/customization status;
- retired/tombstone status;
- parse state.

The complete schema remains unapproved.

Update behavior:

- corrupt or unsupported existing manifest: hard stop;
- legacy project without manifest: warning and report-only;
- silent reset: prohibited.

### 10. Canonical / Derived Invariants

Every derived output must identify a canonical source through generation logic and manifest provenance.

Manual derived edits must be detected and reported. They must not silently become canonical and must not be overwritten or removed unless the applicable ownership/migration rule explicitly permits it.

Canonical rename/delete produces stale-output findings. Prune is allowed only when all D-05 proof conditions hold and the user explicitly approves that prune operation.

### 11. Archive Authorization Boundary

Archive/closeout records lifecycle evidence. It never grants or implies authority for commit, push, tag, merge, branch deletion, or remote issue/PR closure.

Hybrid behavior:

- Simple: no Archive requirement;
- Standard with Change Package: pre-merge lifecycle closeout in the original PR;
- High-Risk: pre-merge closeout mandatory;
- PR/release/issue: authoritative merge evidence;
- deployment/migration: separately authorized post-merge operational validation record.

Artifact naming remains open for Phase 3.

### 12. agentic-eval and Independent Review

`agentic-eval` is self-evaluation, not independent review.

- Simple: not required.
- Standard: risk-triggered.
- High-Risk: mandatory at explicitly named gates.
- Independent code/security review remains a separate requirement where applicable.

#### Proposed Named High-Risk Gates

These are Spec-level proposals, not implemented gates:

| Gate | Purpose | Proposed blocking failures | Warning-only examples |
|---|---|---|---|
| Architecture decision exit | Challenge irreversible architecture/security/contract decisions before downstream commitment. | Unresolved safety boundary, fabricated source, missing viable rollback for an irreversible decision. | Non-blocking maintainability preference. |
| Pre-implementation readiness | Confirm requirements, approvals, plan, migration, and testability are executable. | Unresolved required AC, missing protected-action approval, no safe migration/rollback for applicable work. | Optional documentation refinement. |
| Pre-delivery verification | Self-check evidence completeness before independent review/delivery. | Known red build/test, material requirement unproven, security/financial/data-integrity invariant failure. | Style or low-impact clarity issue. |
| Migration/deployment readiness | Validate rehearsal, rollback, scope, and operational signals before authorized execution. | Missing explicit approval, unbounded scope, no rollback/compensation, missing recovery validation. | Non-critical presentation issue. |

Final dimensions and thresholds require implementation-phase review. No `agentic-eval` result may override a deterministic failure or replace independent review.

### 13. Cross-CLI Fallback Invariant

The portable minimum is Project AGENTS plus relevant Skills. Custom Agents and native adapters are enhancement layers.

If a capability is unsupported or not observed, the surface must fall back to the canonical capability contract without changing lifecycle, risk, approval, or quality semantics.

Codex and Antigravity current adapter capabilities remain **Not observed** and **Deferred** under D-10.

### 14. Installer Support Contract

- PowerShell and Python are supported installer implementations.
- Python is the supported Linux/macOS path.
- Bash is deprecated and must reject update of existing adopters.
- Bash must not claim parity.
- Any retained Bash initial-install behavior must be a warning-emitting thin wrapper, not a third full implementation.

### 15. Backward Compatibility

- Existing project-owned AGENTS/wrappers are preserved.
- An existing constitution is automatically migratable only when a trusted existing manifest records a verifiable previous managed baseline for that exact component and current content equals it; all other states are preserved and reported for manual decision.
- Existing customized Agent/Skill content is preserved and reported.
- Legacy Review and Archive artifacts remain readable until an explicit migration is approved.
- Manifest v1/v2 remain readable during an approved schema transition.
- No stale output is automatically removed.
- No adapter or lifecycle rename may silently invalidate historical Change Packages.

### 16. Adopter Classes

| Class | Required behavior |
|---|---|
| New | Install current adopter defaults and record full provenance. |
| Untouched | Automatically migrate only when a trusted existing manifest records a verifiable previous managed baseline for the exact component and current content equals it. |
| Customized | Preserve; report template delta and require manual adoption decision. |
| Legacy | Do not infer ownership; warning + report-only until provenance is established. |

## Acceptance Criteria

### AC-01 — Constitution source

Given a new adopter install, the installed adopter constitution content equals the designated adopter source and contains no maintainer-only sync/catalog instruction.

### AC-02 — Existing constitution preservation

Given an existing `.github/copilot-instructions.md`, automatic migration is eligible only when a trusted existing manifest records a verifiable previous managed baseline for that exact constitution component and current content equals it. Given an absent component baseline, missing/corrupt/unsupported manifest, unclear source identity, similarity-only evidence, reconstructed/guessed baseline, customization, or unknown legacy ownership, update preserves the file, reports the state, and requires manual decision without inventing D-06 lineage.

### AC-03 — Missing Global fallback

Given no user-level Global AGENTS and a Simple task, Project AGENTS plus one relevant Skill provides explicit evidence, assumption, scope, authorization, verification, secrets, and completion rules.

### AC-04 — Risk modes

Given representative Simple, Standard, and High-Risk scenarios, exactly one mode is selected and no Fast Path label or fourth execution mode is emitted.

### AC-05 — Simple artifact behavior

Given a qualifying Simple task, Workflow does not require a six-stage lifecycle or Change Package and still requires targeted verification.

### AC-06 — Standard package trigger

Given Standard work that is cross-session, cross-component, contract-changing, independently reviewed, migration/audit-sensitive, or escalation-prone, Workflow requires a compact Change Package; otherwise one declared plan/lifecycle SSOT is sufficient.

### AC-07 — High-Risk requirements

Given security, auth, financial, migration, breaking API, irreversible data, deployment, production, or major architecture work, the full Workflow, Change Package, explicit approvals, independent review, rollback/migration, and operational evidence are required.

### AC-08 — Thin Agent structure

Given every canonical Agent, a structural check finds persona/lens/scope/handoff/Skill pointers only and rejects embedded full Workflow, detailed rubric, Global governance, or Git/remote authorization policy. Line count alone does not fail the gate.

### AC-09 — Single lifecycle owner

Given Workflow, Prompt, Skill, and PM Agent content, stage names, modes, entry/exit rules, and artifact semantics originate from the Workflow contract; other surfaces contain only references or routing behavior.

### AC-09A — Adopter-facing lifecycle source approval

Given Phase 3 lifecycle distribution, implementation cannot begin until a maintainer/adopter difference review and user-approved source design identifies the adopter-facing lifecycle contract. No test or installer mapping may presume root maintainer `WORKFLOW.md` is directly installable merely because it currently owns the maintainer lifecycle contract.

### AC-10 — Task/status SSOT

Given a Change Package with an external tracker, progress exists only in the tracker and the package stores a pointer/evidence; without an external tracker, `04-plan.md` explicitly declares whether it is the SSOT.

### AC-11 — Review compatibility

Given a legacy package with `05-review.md`, stage detection recognizes its Review semantic role without requiring a renamed artifact.

### AC-12 — Archive authorization

Given an Archive or closeout request without explicit Git/remote authorization, no commit, push, tag, merge, branch deletion, or remote issue/PR closure is executed or recommended as already authorized.

### AC-13 — agentic-eval separation

Given any self-evaluation result, independent review requirements remain unchanged and deterministic failures cannot be overridden by the self-evaluation.

### AC-14 — Manifest parse safety

Given an update with a corrupt or unsupported manifest, both supported installers stop with actionable diagnostics and make no managed-file changes.

### AC-15 — Legacy missing manifest

Given a legacy project without a manifest, update produces warning/report-only output and performs no inferred ownership migration.

### AC-16 — Stale derived detection

Given a canonical rename/delete, dry-run reports every attributable stale output and does not delete any output.

### AC-17 — Safe prune

Given stale output, prune proceeds only when managed/generated provenance, unchanged current content, source retirement evidence, dry-run report, and explicit user approval are all present.

### AC-18 — Installer support

Given `bootstrap.sh --update` against an existing adopter, the command refuses before modifying files and directs the user to the Python installer.

### AC-19 — Cross-CLI uncertainty

Given an unverified Codex or Antigravity capability, documentation labels it Not observed/Deferred and uses Project AGENTS plus relevant Skill as fallback.

### AC-20 — Historical compatibility

Given historical Change Packages and customized canonical assets, an alignment update neither renames nor removes them without an explicit, tested migration decision.
