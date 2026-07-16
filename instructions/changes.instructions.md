---
description: 'Scoped Change Package semantic roles, evidence, compatibility aliases, and verification rules'
applyTo: 'changes/**'
---

# Change Package Conventions

Simple and Standard work without a package trigger do not require a repository Change Package. When a package is voluntarily created, validate its declared Compact or Full contract; never create blank artifacts to satisfy a filename list.

## Intake Declaration

Every new package declares exactly once in `00-intake.md`: Task/status SSOT, External tracker, Execution mode, Package trigger/reason, and Package contract (`Compact` or `Full`). Without an external tracker, the SSOT is an accessible package-relative or repository-relative file. With one, both fields identify the same URL, `owner/repo#number`, or current-repository Issue/PR pointer. A second declaration, conflicting value, inaccessible file, or unidentifiable tracker is blocking. Filename existence does not prove completion.

## Compact Package

Triggered Standard uses:

- `00-intake.md` with the lifecycle declaration;
- append-only decision evidence in `02-decision-log.md` or an identified equivalent;
- plan/lifecycle evidence in `04-plan.md` or the declared external tracker;
- `07-review.md` Review only when independent review is required;
- pre-merge `99-archive.md` Closeout.

Brainstorm, Spec, a separate Test Plan, and Impact Analysis are selected-stage/risk artifacts, not empty file-count padding.

## Full Package

High-Risk uses substantive evidence in `00-intake.md`, `01-brainstorm.md`, `02-decision-log.md`, `03-spec.md`, `04-plan.md`, `05-test-plan.md`, and `06-impact-analysis.md`, plus canonical `07-review.md` and pre-merge `99-archive.md`.

## Review and Closeout Roles

Review requires substantive Summary (`Reviewed scope`, `Independent reviewer`), explicit Critical/High/Medium/Low status, readable targeted and required-gate status, unavailable-check evidence, and `Decision: PASS | PASS_WITH_NOTES | BLOCKED` plus rationale. `None` is the explicit zero-finding value. `WARNING — evidence` is recorded but nonblocking; `BLOCKED — required deterministic evidence` forces `BLOCKED`.

Closeout requires a selected Outcome status, completed/excluded scope, readable deterministic status and evidence gaps, Review file/decision, pre-merge or unmerged delivery state, unavailable remote-delivery evidence, remaining/deferred work, authorization boundary, and exactly one rollback/recovery value: substantive evidence or `N/A — reason`. `WARNING` is recorded but nonblocking; `BLOCKED` forces Outcome `BLOCKED`. Unchanged templates, option lists, and empty placeholders are incomplete.

A pre-merge Closeout must not claim an actual merged state, merge SHA, or `mergedAt` anywhere in user-authored content. Expected head SHA, final head, and commit SHA evidence are allowed. Template-only guidance belongs in an HTML comment so it is not mistaken for authored evidence.

Unresolved Critical/High findings and required deterministic failures force Review and Closeout to `BLOCKED`. Two independent Review bodies or two independent Closeout bodies are competing evidence and blocking.

## Compatibility Alias

Historical `05-review.md` is recognized as the Review role. `99-closeout.md` is recognized as a Closeout alias. A canonical file and alias may coexist only when one file contains exactly the narrow pointer-only form below (with the applicable role and canonical file):

```markdown
# Compatibility Alias
- Semantic role: Review
- Canonical file: `07-review.md`
- Alias mode: pointer-only
```

or:

```markdown
# Compatibility Alias
- Semantic role: Closeout
- Canonical file: `99-archive.md`
- Alias mode: pointer-only
```

The pointer file owns no independent findings, decision, outcome, status, or evidence.

## Rules

- Do not include secrets, tokens, credentials, PII, or customer/transaction data.
- Keep decision history append-only.
- Keep scope, spec, plan, tests, Review, and Closeout evidence aligned.
- Archive authorizes requested local documentation only; protected or remote actions need separate explicit current-task action-specific approval.
