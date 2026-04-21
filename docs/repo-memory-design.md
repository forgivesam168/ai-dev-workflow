# Repo Memory Design

**Status**: Design Specification (pre-implementation)
**Spec Reference**: `changes/2026-04-21-workflow-template-optimization/03-spec.md` — AC-6

---

## Overview

This document defines the opt-in repo memory structure, lifecycle rules, and update protocol for the AI development workflow template. Repo memory provides persistent project context across AI sessions without requiring re-explanation each time.

**Default behavior**: The `.ai-workflow-memory/` directory is **NOT created by default**. Memory must be explicitly opt-in.

---

## Directory Structure

```
.ai-workflow-memory/
├── PROJECT_CONTEXT.md    # stable project overview; updated when context changes significantly
├── CURRENT_STATE.md      # current work status; updated at end of each major session
└── session-journal/      # append-only; one file per session (YYYY-MM-DD-<slug>.md)
```

### File Descriptions

| File | Purpose | Volatility |
|------|---------|-----------|
| `PROJECT_CONTEXT.md` | Stable facts: tech stack, team norms, key architectural decisions, domain glossary | Low — updated only when fundamentally changes |
| `CURRENT_STATE.md` | Active work: current change package, blockers, recent decisions, next steps | Medium — updated at end of each work session |
| `session-journal/YYYY-MM-DD-<slug>.md` | Per-session log: what was explored, decisions made, outputs produced | Append-only; never modified after session ends |

---

## Update Rules

### `PROJECT_CONTEXT.md`

**Who updates**: Any agent, or the user directly.
**When**: When a significant architectural decision is made, the tech stack changes, or a key constraint is added/removed.
**Minimum content**:
- Project name and purpose (1–3 sentences)
- Tech stack (language, framework, key dependencies)
- Key architectural decisions or constraints
- Domain glossary (if domain-specific terms are used)

**Do NOT update**: For every small change. This file should remain stable.

### `CURRENT_STATE.md`

**Who updates**: `coder-agent` or `plan-agent` at end of each major work session.
**When**: At the end of a session where meaningful progress was made.
**Minimum content**:
- Active change package path (e.g., `changes/2026-04-21-<slug>/`)
- Current stage (Brainstorm / Spec / Plan / Implement / Review / Archive)
- Last action taken
- Next step or known blocker

**Format**:
```markdown
## Status as of YYYY-MM-DD

- **Active change**: changes/YYYY-MM-DD-<slug>/
- **Stage**: Plan (04-plan.md complete)
- **Last action**: Completed Phase 3 implementation
- **Next step**: Begin Phase 4 — Repo Memory skeleton
- **Blockers**: None
```

### `session-journal/YYYY-MM-DD-<slug>.md`

**Who updates**: Any agent, at the end of a session.
**When**: Once per session, as a final append-only record.
**Minimum content**:
- Session goal
- What was explored or produced
- Key decisions made
- Unresolved questions or deferred items

**Naming convention**: `YYYY-MM-DD-<brief-slug>.md` (e.g., `2026-04-21-phase3-workflow-skills.md`)

**Append-only rule**: Session journal files are never modified after creation. A new file is created for each session.

---

## Opt-In Mechanism

The `.ai-workflow-memory/` directory is **NOT created by default** when the template is installed. This is intentional:

- Prevents unwanted directory creation in repos that don't need memory
- Keeps the install surface non-opinionated for adopters
- Avoids unexpected file creation in CI/CD environments

### Activation Methods

1. **Via install-apply flag** (future implementation):
   ```powershell
   pwsh -File .\Init-Project.ps1 --enable-memory
   ```
   Creates the `.ai-workflow-memory/` skeleton with placeholder files.

2. **Manual creation**:
   ```powershell
   New-Item -ItemType Directory ".ai-workflow-memory\session-journal" -Force
   New-Item ".ai-workflow-memory\PROJECT_CONTEXT.md" -Value "# Project Context`n`n<!-- Add project overview here -->`n"
   New-Item ".ai-workflow-memory\CURRENT_STATE.md"   -Value "# Current State`n`n<!-- Updated at end of each session -->`n"
   ```

---

## Mirror Exclusion

`.ai-workflow-memory/` is **NOT** added to the `.github/**` mirror.

**Rationale**:
- Memory is local to the deploying repository; it contains project-specific content that is not part of the template
- The sync script (`tools/sync-dotgithub.ps1`) mirrors only template governance files (agents, skills, instructions, prompts, copilot-instructions.md)
- Memory files should not be synced to GitHub Copilot's runtime path (`.github/`) as they are repo-specific, not template-level

---

## Gitignore Guidance

If session journals are not intended to be committed (e.g., in private or ephemeral work sessions), add to `.gitignore`:

```gitignore
# AI workflow session journals (optional — omit if you want to commit session history)
.ai-workflow-memory/session-journal/
```

`PROJECT_CONTEXT.md` and `CURRENT_STATE.md` are generally worth committing as they provide team-wide context.

---

## Lifecycle Summary

```
install-apply --enable-memory
    → Creates .ai-workflow-memory/ skeleton (PROJECT_CONTEXT.md, CURRENT_STATE.md, session-journal/)

Session begins
    → Agent reads PROJECT_CONTEXT.md + CURRENT_STATE.md for context

Session ends
    → coder-agent / plan-agent updates CURRENT_STATE.md
    → Agent appends new session-journal/YYYY-MM-DD-<slug>.md

Context changes significantly
    → Any agent or user updates PROJECT_CONTEXT.md
```
