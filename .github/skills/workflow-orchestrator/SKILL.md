---
name: workflow-orchestrator
description: 'Orchestrate the six-stage development workflow. Use when user asks "what stage am I at?", "what''s next?", "workflow status", "where should I start?", "工作流程", "下一步是什麼", "我在哪個階段", or wants guidance on the development process. Detects current state by checking changes/ folder and guides users through brainstorm → spec → plan → tdd → review → archive stages.'
license: See LICENSE.txt in repository root
---

# Workflow Orchestrator

> 🎯 **Purpose**: Detect current workflow stage and guide users through the six-stage development process with clear Agent recommendations.

## When to Use This Skill

Use this skill when:
- Starting a new feature and unsure where to begin
- Wondering "what's next?" after completing a stage
- Need to check current workflow status
- Want to understand the overall development flow
- 想知道目前在哪個階段
- 不確定下一步該做什麼

## Six-Stage Workflow Overview

```
1. Brainstorm → 2. Spec → 3. Plan → 4. TDD → 5. Review → 6. Archive
```

**Standard Path** (Med/High risk):
```
Brainstorm → Spec → Plan → TDD → Review → Archive
```

**Fast Path** (Low risk only):
```
Brainstorm → Plan → TDD → Review → Archive
          (skip Spec)
```

## Current State Detection

### Step 1: Check Changes Folder

Look for `changes/<YYYY-MM-DD>-<slug>/` directory and check which files exist:

| File Present | Stage Completed | Next Stage | Recommended Action |
|-------------|----------------|-----------|-------------------|
| None | Not started | Brainstorm | Start with brainstorming |
| `01-brainstorm.md` | Brainstorm ✅ | Spec | Generate specification |
| `03-spec.md` | Spec ✅ | Plan | Create implementation plan |
| `04-plan.md` | Plan ✅ | TDD | Start TDD implementation |
| Code changes (git diff) | TDD in progress/done | Review | Run code review |
| `05-review.md` | Review ✅ | Archive | Finalize and archive |
| `99-archive.md` | Complete 🎉 | - | Start new feature |

### Step 2: Provide Guidance

Based on detected stage, provide:
1. ✅ **Current Status**: Which stage is completed
2. 🎯 **Next Step**: What to do next
3. 🤖 **Agent Recommendation**: Which agent to use
4. 📝 **Action Instructions**: Clear CLI/VS Code commands
5. 🔗 **Reference**: Link to detailed documentation

## Stage-by-Stage Guidance

### Stage 0: Not Started → Brainstorm

**Status**: No change package detected

**Next Step**: Start brainstorming session

**Recommended Agent**: `brainstorm-agent`

**Action Instructions**:

**CLI**:
```
Input: "我要開始一個新功能的 brainstorming"
[System loads brainstorming skill]
→ /agent → Select brainstorm-agent
→ Ask at least 5 discovery questions unless the user explicitly allows assumptions
→ Continue conversation to generate 01-brainstorm.md
```

**VS Code**:
```
Input: /brainstorm
Or: "brainstorm a new feature"
→ Select @workspace #brainstorm-agent
```

**Triggers brainstorming skill**: Risk classification, discovery questions, option exploration, decision log

---

### Stage 1: Brainstorm ✅ → Spec

**Status**: `01-brainstorm.md` exists, clarified requirements

**Next Step**: Generate specification document (PRD)

**Recommended Agent**: `spec-agent`

**Action Instructions**:

**CLI**:
```
Input: "產生 spec 文件"
[System loads specification skill]
→ /agent → Select spec-agent
→ Continue conversation to generate 03-spec.md
```

**VS Code**:
```
Input: /spec
Or: "generate spec document"
→ Select @workspace #spec-agent
```

**Triggers specification skill**: User stories, acceptance criteria, technical requirements

**Note**: Low-risk changes can skip to Plan (Fast Path)

---

### Stage 2: Spec ✅ → Plan

**Status**: `03-spec.md` exists, requirements documented

**Next Step**: Break down into executable implementation plan

**Recommended Agent**: `plan-agent`

**Action Instructions**:

**CLI**:
```
Input: "幫我規劃實作計畫"
[System loads implementation-planning skill]
→ /agent → Select plan-agent
→ Continue conversation to generate 04-plan.md
```

**VS Code**:
```
Input: /create-plan
Or: "create implementation plan"
→ Select @workspace #plan-agent
```

**Triggers implementation-planning skill**: Task breakdown, TDD integration, impact analysis

---

### Stage 3: Plan ✅ → TDD

**Status**: `04-plan.md` exists, tasks defined

**Next Step**: Start test-driven development implementation

**Recommended Agent**: `coder-agent`

**Action Instructions**:

**CLI**:
```
Input: "開始 TDD 實作"
[System loads tdd-workflow skill]
→ /agent → Select coder-agent
→ Follow Red-Green-Refactor cycle
```

**VS Code**:
```
Input: /tdd
Or: "start TDD implementation"
→ Select @workspace #coder-agent
```

**Triggers tdd-workflow skill**: Red-Green-Refactor, test scaffolding, coverage verification

---

### Stage 4: TDD Done → Review

**Status**: Code changes detected (git status/diff shows modifications)

**Next Step**: Run code and security review

**Recommended Agent**: `code-reviewer-agent`

**Action Instructions**:

**CLI**:
```
Input: "review 我的 code"
[System loads code-security-review skill]
→ /agent → Select code-reviewer-agent
→ Review checklist: DDD, security, financial precision
```

**VS Code**:
```
Input: /code-review
Or: "review my code"
→ Select @workspace #code-reviewer-agent
```

**Triggers code-security-review skill**: Code quality, security audit, financial correctness

---

### Stage 5: Review ✅ → Archive

**Status**: `05-review.md` exists, code reviewed and approved

**Next Step**: Finalize change package and create work log

**Recommended Agent**: Default agent (no specific agent required)

**Action Instructions**:

**CLI**:
```
Input: "archive 這個 change package"
[System loads work-archiving skill]
→ Generate 99-archive.md and update WORK_LOG.md
```

**VS Code**:
```
Input: /archive
Or: "finalize and archive"
```

**Triggers work-archiving skill**: Work log entry, lessons learned, follow-up items

---

### Stage 6: Complete 🎉

**Status**: `99-archive.md` exists, change package archived

**Next Step**: Start new feature or celebrate! 🎉

**Action**: Ready for next work item
- Run `/workflow` for new feature
- Or: "我要開始新的 brainstorming"

## Output Template

When user asks about workflow status, respond with:

```markdown
## 📍 Current Workflow Status

### Detected State
- **Change Package**: `changes/<date>-<slug>/`
- **Completed Stages**: [List completed stages with ✅]
- **Current Stage**: [Current stage name]

### 🎯 Next Step: [Next stage name]

**What to do**: [Brief description]

**Recommended Agent**: `[agent-name]`

**Action Instructions**:

**CLI**:
[Provide exact CLI commands and natural language inputs]

**VS Code**:
[Provide slash command or natural language inputs]

### 📊 Progress Overview
- [x] Brainstorm
- [x] Spec
- [ ] Plan ← **You are here**
- [ ] TDD
- [ ] Review
- [ ] Archive

### 📖 Detailed Workflow
For complete workflow documentation, see [WORKFLOW.md](../../WORKFLOW.md)
```

## Fast Path Decision Helper

If user asks "should I skip spec?", apply these rules:

| Risk Level | Criteria | Workflow Path |
|-----------|----------|---------------|
| **Low** | Bug fix, minor refactor, config change | Fast Path (skip Spec) |
| **Medium** | New feature, API change, schema change | Standard Path (include Spec) |
| **High** | Security, auth, money handling, breaking change | Standard Path (mandatory) |

**When in doubt**: Use Standard Path (better safe than sorry)

## Troubleshooting

### "I don't see any changes/ folder"
**Solution**: You haven't started a change package yet. Begin with brainstorming:
- CLI: "開始 brainstorming"
- VS Code: `/brainstorm`

### "Multiple change folders exist"
**Solution**: Work on the most recent one (highest date). Archive old ones if completed.

### "I want to skip a stage"
**Solution**: 
- Low-risk only: Can skip Spec (brainstorm → plan)
- Never skip: Brainstorm, Plan, TDD, Review (core safety net)

### "Which agent should I use?"
**Solution**: Follow the "Recommended Agent" for each stage. If unsure, use the default agent—it will still work but may be less specialized.

## Integration with Other Skills

This orchestrator skill works with:
- **brainstorming**: Stage 1
- **specification**: Stage 2
- **implementation-planning**: Stage 3
- **tdd-workflow**: Stage 4
- **code-security-review**: Stage 5
- **work-archiving**: Stage 6

## Related Documentation

- [WORKFLOW.md](../../WORKFLOW.md) - Detailed six-stage process
- [AGENTS.md](../../AGENTS.md) - Agent roles and responsibilities
- [README.zh-TW.md](../../README.zh-TW.md) - CLI vs VS Code usage guide

---

💡 **Pro Tip**: Run workflow detection regularly by asking "what's next?" to stay on track and maintain momentum.
