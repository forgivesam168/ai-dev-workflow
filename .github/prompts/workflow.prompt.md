---
description: 'Inspect current project state and route the next action through the canonical Workflow contract.'
---

# Workflow Command

## Entry

Use `/workflow` with the current project context, task/status SSOT, approved decisions, and any active lifecycle artifact path. Treat missing optional artifacts as absence, not automatically as a process gap.

## Route

Use the canonical Workflow contract declared by Project AGENTS as the sole lifecycle, execution-mode, artifact, stage-exit, and named-gate owner. Follow [workflow-orchestrator](../skills/workflow-orchestrator/SKILL.md) for state inspection and routing methodology; this Prompt does not select an adopter-facing lifecycle source or redefine either owner.

## Output

Return the evidence-backed current state, exactly one applicable route, the next action and reason, and any prerequisite or authorization blocker. Distinguish facts, assumptions, inferences, and unknowns.

## Handoff

Do not auto-execute the proposed next action. Return control for confirmation or route to the applicable Agent and Skill only after the required authorization and prerequisites are present.
