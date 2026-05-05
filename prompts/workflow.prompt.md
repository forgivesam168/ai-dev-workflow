---
description: 'Workflow Orchestrator: detect current stage, suggest next step, and guide through the 6-stage development workflow.'
---

# Workflow Command

Use `/workflow` to check current progress and get guided through the 6-stage development workflow.

## What This Command Does

1. **Detect Current State** - Analyze existing change packages and current stage
2. **Suggest Next Step** - Recommend which command to run next
3. **Provide Context** - Show what's been completed and what's remaining
4. **Interactive Guidance** - Ask user if they want to proceed

## When to Use

- Starting a new feature (no change package exists)
- Resuming work on an existing feature
- Unsure which stage you're at
- Want guided workflow instead of manual commands

## How It Works

### Step 1: Detect Current State

Check for existing change packages in `changes/`:
```
changes/
├── 2026-02-09-feature-a/
│   ├── 01-brainstorm.md ✅
│   ├── 02-decision-log.md ✅
│   ├── 03-spec.md ✅
│   ├── 04-plan.md ✅
│   └── ... (missing files)
```

### Step 2: Determine Stage

Based on files present:

| Files Present | Current Stage | Next Command |
|---------------|---------------|--------------|
| (none) | 🆕 New work | `/brainstorm` |
| 01-brainstorm.md | Brainstorm done | `/spec` |
| 03-spec.md | Spec done | `/create-plan` |
| 04-plan.md | Plan done | `/tdd` |
| (implementation done) | Code complete | `/code-review` |
| 05-review.md | Review done | `/archive` |
| 99-archive.md | ✅ Complete | (start new work) |

### Step 3: Provide Guidance

Show user:
```
📍 Current Status: Spec stage completed
✅ Completed: Brainstorm → Spec
⏭️  Next Step: Generate implementation plan

Would you like to run `/create-plan` now? (yes/no)
```

### Step 4: Interactive Execution

If user confirms:
- Run the suggested command automatically
- After completion, show next step hint
- Allow user to continue or pause

## Workflow Stages Reference

```
1. Brainstorm (/brainstorm)
   ├─ Risk classification
   ├─ Requirements clarification (ask at least 5 discovery questions unless the user allows assumptions)
   └─ Create change package skeleton

2. Spec (/spec)
   ├─ Generate formal specification
   ├─ Define acceptance criteria
   └─ Security/compliance requirements

3. Plan (/create-plan)
   ├─ Break down into tasks
   ├─ Create test strategy
   └─ Impact analysis (brownfield)

4. Implement (/tdd)
   ├─ Red: Write failing tests
   ├─ Green: Minimal implementation
   └─ Refactor: Improve code

5. Review (/code-review)
   ├─ Code review (quality)
   └─ Security review (parallel)

6. Archive (/archive)
   ├─ Generate work log
   └─ Finalize change package
```

## Detection Rules

### Identifying Active Change Package

Priority order:
1. User-specified path: `changes/<slug>/`
2. Most recent folder (by date prefix)
3. Ask user if multiple candidates exist

### Determining Completion Status

File exists + non-empty + valid structure = ✅ Complete

Check markers:
- `01-brainstorm.md` → Has "## Decision Log" section
- `03-spec.md` → Has "## Acceptance Criteria" section
- `04-plan.md` → Has "## Implementation Steps" section
- `05-review.md` → Has "## Summary" section
- `99-archive.md` → Has "## Outcome" section

## Fast Path vs Standard Path

If risk is **Low** in `01-brainstorm.md`:
```
Fast Path: Brainstorm → Plan → Implement → Review → Archive
          (skip Spec stage)
```

If risk is **Med/High**:
```
Standard Path: Brainstorm → Spec → Plan → Implement → Review → Archive
              (full workflow)
```

## Example Usage

### Scenario 1: Starting Fresh
```
User: /workflow

Agent:
📍 Current Status: No active change packages found
🆕 Starting new work

Would you like to start with `/brainstorm`? It will begin with discovery questions unless you explicitly allow assumptions. (yes/no)
Options:
- "yes" → Run /brainstorm
- "fast" → Skip to /create-plan (low-risk only)
```

### Scenario 2: Mid-Workflow
```
User: /workflow

Agent:
📍 Current Status: Plan stage completed
📂 Active: changes/2026-02-09-add-notifications/

✅ Completed:
  1. ✅ Brainstorm
  2. ✅ Spec  
  3. ✅ Plan

⏭️  Next: Implementation (TDD)

📋 Plan Summary:
- Add notification system
- 4 phases identified
- Estimated: Medium complexity

Would you like to run `/tdd` now? (yes/no/show-plan)
```

### Scenario 3: Review Stage
```
User: /workflow

Agent:
📍 Current Status: Implementation completed (detected uncommitted changes)
📂 Active: changes/2026-02-09-add-notifications/

✅ Completed:
  1. ✅ Brainstorm
  2. ✅ Spec
  3. ✅ Plan
  4. ✅ Implement

⏭️  Next: Code + Security Review

🔍 Changes Detected:
- src/notifications/service.ts (new)
- src/notifications/types.ts (new)
- src/notifications/service.test.ts (new)

Would you like to run `/code-review` now? (yes/no/show-diff)
```

## Advanced Options

User can specify:
- `/workflow <slug>` → Check specific change package
- `/workflow --all` → List all active change packages
- `/workflow --status` → Show current stage only (no prompts)
- `/workflow --skip-to=<stage>` → Jump to specific stage (with confirmation)

## Rules

- Always show current status before suggesting action
- Never auto-execute without user confirmation
- Provide context (what's done, what's next, why)
- Respect fast path if marked low-risk
- Warn if skipping stages in standard path

## Integration with Other Commands

After any workflow command completes:
```
✅ {Command} completed

Next Step: {Next command}
Run `/workflow` to continue, or manually use `/{next-command}`
```

## Next Step
After state detection, this command will suggest the next action. User can confirm or modify.
