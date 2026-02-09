---
description: 'Change Package conventions (auditable requirements → spec → plan → test) for this repository'
applyTo: 'changes/**'
---

# Change Package Conventions

## Required (Standard Path)
Each change folder should contain:
- `00-intake.md`
- `01-brainstorm.md`
- `02-decision-log.md` (append-only)
- `03-spec.md`
- `04-plan.md`
- `05-test-plan.md`
- `06-impact-analysis.md` (brownfield/high-risk)
- `99-archive.md` (post-merge)

## Rules
- Do NOT include secrets, tokens, credentials, or customer/transaction data.
- Keep decision log append-only; add a new entry when the decision changes.
- Keep spec and plan aligned: when scope changes, update `03-spec.md` and `04-plan.md`.
- Every plan step must include a verification method (test or manual).
