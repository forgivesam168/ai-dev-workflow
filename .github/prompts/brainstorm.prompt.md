---
description: 'Start a work item: triage risk, run structured brainstorming, and create the change package skeleton.'
---

# Brainstorm Command

Use `/brainstorm` at the start of any new work item to:
1. Triage and classify risk (Low/Med/High)
2. Decide workflow path (Standard vs Fast)
3. Clarify requirements and compare options
4. Create the change package skeleton

## When to Use
- Requirements are unclear, high-risk, or multiple approaches exist
- Starting a new feature or significant change
- Before `/plan` or `/tdd`

## Process

### Step 1: Intake & Risk Classification
- Clarify goals and non-goals
- Classify risk: **Low** / **Med** / **High**
- Determine if this is brownfield (existing system)
- Recommend path:
  - **Standard**: `/brainstorm` → `/plan` → `/tdd` → `/review`
  - **Fast** (low-risk only): `/plan` → `/tdd` → `/review`

### Step 2: Structured Brainstorming
1) **Clarifying Questions** (if needed)
2) **Assumptions & Constraints**
3) **Options (2–3)** with pros/cons and risk notes
4) **Recommendation** (chosen approach)
5) **Decision Log** (copy/paste-ready)

## Output: Change Package Skeleton

Create `changes/<YYYY-MM-DD>-<slug>/` with:
- `01-brainstorm.md` — requirements clarification + options analysis
- `02-decision-log.md` — key decisions (append-only)
- `03-spec.md` — draft specification + acceptance criteria

## Rules
- Keep acceptance criteria explicit and testable
- Do not include secrets or sensitive customer/transaction data
- For brownfield: note affected modules and regression points

## Next Step
After brainstorm completion:
- **Standard Path (Med/High risk)**: Run `/spec` to generate formal specification
- **Fast Path (Low risk)**: Skip to `/plan` for immediate task breakdown
- Or use `/workflow` for guided progression
