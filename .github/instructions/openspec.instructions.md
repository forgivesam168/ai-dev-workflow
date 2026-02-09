---
description: 'Specification-Driven Development (OpenSpec-like) conventions for this repository'
applyTo: 'specs/**'
---

# Specs Conventions (OpenSpec-like)

This repository adopts a lightweight, OpenSpec-inspired structure to keep decisions and plans **auditable**.

## Directory Layout
Create specs under:

- `specs/<YYYY-MM-DD>-<slug>/`

Minimum files:
- `proposal.md` — problem statement, goals/non-goals, constraints, options, chosen approach
- `tasks.md` — executable task list with acceptance criteria
- `decision-log.md` — key decisions + rationale + trade-offs

Optional:
- `design.md` — diagrams, interfaces, API contracts
- `risk.md` — security/compliance/performance risks and mitigations

## Rules
- Specs are **source of truth** for medium/high-risk changes.
- Plans must reference specs paths.
- Update specs when scope changes; do not rewrite history—append to decision log.
