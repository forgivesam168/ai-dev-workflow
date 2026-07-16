---
description: 'Route an approved local archive-documentation request to the canonical work-archiving method.'
---

# Archive Command

## Entry

Use `/archive` only for requested local archive documentation after the PR is merged and the applicable delivery evidence already exists. Preserve the existing archive filename and lifecycle timing defined by the canonical method.

## Route

Follow [work-archiving](../skills/work-archiving/SKILL.md) for the archive method, evidence rules, output structure, and protected-action boundary. Use the canonical Workflow contract declared by Project AGENTS only to confirm that the selected lifecycle has reached its archive handoff; this Prompt does not select an adopter-facing lifecycle source.

## Authorization

This Prompt authorizes only the explicitly requested local archive-documentation writes. It does not authorize Git or remote mutation; every protected action still requires explicit, current-task, action-specific approval under the canonical Skill.

## Output

Return the local documentation changed, the existing evidence recorded, and any unverified or deferred item. Do not invent completion or merge evidence.

## Handoff

If required evidence or action-specific approval is absent, finish only the safe authorized local scope, identify the exact missing evidence or approval, and stop or return control to the caller.
