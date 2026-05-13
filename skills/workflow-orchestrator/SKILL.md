---
name: workflow-orchestrator
description: 'Orchestrate the six-stage development workflow. Use when user asks "what stage am I at?", "what''s next?", "workflow status", "where should I start?", "工作流程", "下一步是什麼", "我在哪個階段", or wants guidance on the development process. Detects current state by checking changes/ folder and guides users through brainstorm → spec → plan → tdd → review → archive stages.'
license: See LICENSE.txt in repository root
---

# Workflow Orchestrator

> 🎯 **Purpose**: Detect current workflow stage and recommend the next step in ≤ 3 lines.

## When to Use This Skill

- Starting a new feature and unsure where to begin
- Wondering "what's next?" after completing a stage
- 想知道目前在哪個階段 / 不確定下一步該做什麼

## Stage Detection

Check `changes/<YYYY-MM-DD>-<slug>/` for these files:

| File Present | Stage | Next Step | Agent |
|-------------|-------|-----------|-------|
| None | Not started | Brainstorm | `brainstorm-agent` |
| `01-brainstorm.md` | Brainstorm ✅ | Spec | `spec-agent` |
| `03-spec.md` | Spec ✅ | Plan | `plan-agent` |
| `04-plan.md` | Plan ✅ | TDD | `coder-agent` |
| Code changes (git diff) | TDD ✅ | Review | `code-reviewer-agent` |
| `05-review.md` | Review ✅ | Archive | (default agent) |
| `99-archive.md` | Complete 🎉 | New feature | `brainstorm-agent` |

No `changes/` folder → stage = Not Started → start with `brainstorm-agent`.

## Output Format

Respond concisely (max 3 lines):

```
當前階段：[Stage] ✅
下一步：[Next Stage] → 使用 [agent-name]
指令：/[slash-command] 或輸入「[trigger phrase]」
```

## Workflow Paths

**Standard** (Med/High risk): `Brainstorm → Spec → Plan → TDD → Review → Archive`  
**Fast Path** (Low risk only): `Brainstorm → Plan → TDD → Review → Archive`

| Risk | Criteria | Path |
|------|----------|------|
| Low | Bug fix, config change, minor refactor | Fast Path (skip Spec) |
| Medium | New feature, API change, schema change | Standard |
| High | Security, auth, money, breaking change | Standard (mandatory) |

## Stage Skip Rules

- Low-risk only: Can skip Spec (Brainstorm → Plan directly)
- **Never skip**: Brainstorm, Plan, TDD, Review

## Troubleshooting

**No `changes/` folder** → Not started. Begin with `/brainstorm`.  
**Multiple `changes/` folders** → Work on most recent date. Archive completed ones.  
**Which agent for this stage?** → See each agent's `## Handoff` block for Entry Signals and Next Step.

---

💡 For complete workflow documentation, see [WORKFLOW.md](../../WORKFLOW.md).
