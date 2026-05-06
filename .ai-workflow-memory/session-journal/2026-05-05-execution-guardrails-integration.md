# Session Journal — Execution Guardrails Integration

## Summary

Integrated a shared guardrails layer into the workflow template without changing the existing Agent → Primary Skill mental model.

## Work Completed

- Added `skills/execution-guardrails/` with manual fallback slash usage
- Documented the shared guardrails layer in `AGENTS.md`
- Added always-on execution guardrails to `copilot-instructions.md`
- Updated core agents to reference `/execution-guardrails` as a fallback
- Extended `agentic-eval` rubric dimensions for assumptions, simplicity, diff hygiene, and verification strength
- Updated user-facing docs to explain that guardrails are a shared quality floor, not a new workflow stage
- Synced source-of-truth to `.github/**` and passed catalog audit

## Key Decisions

- Keep the existing stage-level primary skills unchanged
- Make guardrails always-on via constitution + agents
- Keep the skill visible as a manual fallback (`/execution-guardrails`)
- Defer Lite / Guardrail-only install mode to a future change

## Next Consideration

Watch for whether users actually invoke `/execution-guardrails`, or whether the always-on integration already covers most real-world cases.
