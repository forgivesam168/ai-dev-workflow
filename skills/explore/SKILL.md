---
name: explore
description: >
  Explore mode for codebase investigation and requirements clarification before committing to a change package.
  Use when requirements are unclear, a codebase investigation is needed before planning, options are being compared,
  or a risk scan is needed before a commit. Triggers on: "explore", "investigate", "look around", "understand the codebase",
  "scan for risks", "what's in here", "before I commit to anything".
  Stays in read-only observe mode — no files created — until an explicit artifact commit signal is received.
---

# Explore Mode

Read-only investigation mode. Observe and analyze without creating artifacts until explicitly signaled to proceed.

## When to Enter Explore Mode

Enter explore mode when any of the following apply:

- Requirements are not yet clear; need to ask clarifying questions or read the codebase first
- A codebase investigation is needed before a plan can be written
- Option comparison is in progress (weighing approaches before deciding)
- Risk scan needed before committing to a change package scope

## While in Explore Mode

**No files are created or modified** until an explicit artifact commit signal is received.

Permitted actions in explore mode:
- Read files (`read` / `view` tools)
- Search codebase (`search` / `grep` tools)
- Ask the user clarifying questions
- Build an internal understanding of the system

Prohibited actions until signaled:
- Creating or modifying `changes/` files
- Creating or modifying any source or documentation file
- Running `sync-dotgithub.ps1`

## Explicit Artifact Commit Triggers

Explore mode ends and artifact creation begins **only** when one of the following explicit signals is received from the user:

1. `/proceed`
2. `"create change package"`
3. `"start brainstorm"`
4. `"I want to formalize this"`

Any other phrasing that sounds like "let's start writing" should be confirmed with the user before exiting explore mode: "Do you want me to create a change package now?"

## Explore Mode Summary Output

Before transitioning out of explore mode, produce a brief summary:

```
## Explore Summary
- **Scope**: [what was investigated]
- **Key Findings**: [2–5 bullet points]
- **Recommended Next Step**: [brainstorm / fast-path plan / other]
- **Risk Signal**: [Low / Med / High — brief rationale]
```

This summary becomes input to the brainstorm or plan step.
