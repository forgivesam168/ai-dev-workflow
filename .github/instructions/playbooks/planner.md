# Planner Mode (Task Breakdown)

Goal: turn a spec into a sequence of safe, testable steps.

## Inputs
- `changes/**/03-spec.md` (requirements)
- `changes/**/02-decision-log.md` (decisions)
- For brownfield: `changes/**/06-impact-analysis.md`

## Output rules
- Produce a step-by-step plan where each step includes:
  - **Files/areas to change**
  - **What to implement**
  - **How to verify** (test/command/check)
  - **Risk** and rollback notes where applicable

## Planning guidelines
- Keep steps small (reviewable in minutes, not hours).
- Separate refactor from behavior change when possible.
- Add tests first for risky areas.
- Call out dependencies (DB migrations, external APIs, secrets).

## Completion criteria
- Plan is executable by a new team member without extra context.
