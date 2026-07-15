---
description: 'Start a work item: triage risk, select the canonical execution mode, run structured brainstorming, and create only the lifecycle artifacts required by WORKFLOW.md.'
---

# Brainstorm Command

> **💡 Recommended Agent**: This command works best with `brainstorm-agent` for requirements discovery. Use `/agent` in CLI or select from agent dropdown in VS Code.
> If the skill does not auto-load, run `/brainstorming` manually.

Use `/brainstorm` at the start of any new work item to:
1. Triage and classify risk (Low/Med/High)
2. Select exactly one execution mode from `WORKFLOW.md` (Simple, Standard, or High-Risk)
3. Clarify requirements and compare options
4. Produce only the lifecycle artifacts required by the selected mode

## When to Use
- Requirements are unclear, high-risk, or multiple approaches exist
- Starting a new feature or significant change
- Before `/plan` or `/tdd`

## Process

### Step 1: Intake & Risk Classification
- Clarify goals and non-goals
- Classify risk: **Low** / **Med** / **High**
- Determine if this is brownfield (existing system)
- Apply the mode entry and escalation rules from `WORKFLOW.md`; do not create another path label.

### Step 2: Structured Brainstorming
1) **Clarifying Questions** — ask at least 5 targeted questions in each new brainstorming round before options or recommendations, unless the user explicitly allows assumptions
2) **Assumptions & Constraints** — separate confirmed facts from assumptions
3) **Options (2–3)** with pros/cons and risk notes
4) **Recommendation** (chosen approach)
5) **Decision Log** (copy/paste-ready)

## Output: Required Lifecycle Artifacts

Simple does not require a Change Package; keep the confirmed summary inline or in an existing project plan when useful.

When `WORKFLOW.md` requires a compact or full Change Package, create `changes/<YYYY-MM-DD>-<slug>/` with:
- `01-brainstorm.md` — requirements clarification + options analysis
- `02-decision-log.md` — key decisions (append-only)
- `03-spec.md` — draft specification + acceptance criteria

## Rules
- In each new brainstorming round, ask at least 5 targeted questions before presenting options or recommendations, unless the user explicitly allows assumptions
- Keep acceptance criteria explicit and testable
- Do not include secrets or sensitive customer/transaction data
- For brownfield: note affected modules and regression points

## Next Step
After brainstorm completion:
- **High-Risk or selected Standard stages**: Run `/spec` when the selected lifecycle requires a formal specification
- **Simple or selected Standard stages**: Continue to `/plan` only when a plan is useful or required
- Or use `/workflow` for guided progression
