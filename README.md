# AI Development Workflow Template

This repository provides a reusable, finance-grade AI development workflow for GitHub Copilot CLI and VS Code.

## What You Get

- Team constitution and instruction mapping for consistent AI behavior
- Agent personas: Architect, Plan, Coder, Reviewer, Spec, PM, Frontend Designer, DBA (9 agents)
- Prompt library (10 commands) for repeatable workflows
- Skills library (31 specialized capabilities)
- Initialization script for quick rollout

## Getting Started

1. Copy this template into your repository.
2. Run the initialization script:

```powershell
pwsh -File .\Init-Project.ps1
```

Optional parameters:

```powershell
pwsh -File .\Init-Project.ps1 -Include copilot,agents,instructions,prompts,skills,project-files
pwsh -File .\Init-Project.ps1 -Exclude skills
```

## Structure

- `copilot-instructions.md` - Team constitution
- `agents/` - Persona definitions (9 agents)
- `instructions/` - Language and domain rules
- `prompts/` - Slash commands (10 prompts)
- `skills/` - Skills library (31 skills)
- `Init-Project.ps1` - Deployment script
- `tools/` - Sync scripts

## 6-Stage Workflow

```
1. Brainstorm → 2. Spec → 3. Plan → 4. Implement → 5. Review → 6. Archive
   (釐清需求)    (規格)    (計畫)     (TDD)       (Code+Security) (歸檔)
```

### Commands (VS Code Slash Commands)

| Stage | VS Code | Description |
|-------|---------|-------------|
| 0 | `/workflow` | **Orchestrator**: Detect current stage, guide next step |
| 1 | `/brainstorm` | Triage risk, clarify requirements, create change package |
| 2 | `/spec` | Generate specification document |
| 3 | `/create-plan` | Create executable implementation plan |
| 4 | `/tdd` | Implement with Red-Green-Refactor |
| 5 | `/code-review` | Code Review + Security Review (parallel) |
| 6 | `/archive` | Finalize and document |

> **Copilot CLI users**: The above are VS Code prompt shortcuts (`.github/prompts/`).
> In CLI, use natural language instead — e.g., "review my code", "create an implementation plan".
> Note: CLI has its own built-in `/plan` (Plan Mode) and `/review` (code review agent), which are
> different from these workflow prompts.

### Workflow Orchestrator

Use `/workflow` for guided progression:
- Automatically detects current stage
- Suggests next command
- Shows progress and what's remaining
- Interactive execution with confirmation

### Workflow Paths

- 🔴 **Strategic path**: Brainstorm → PRD → Spec → Plan → Implement (TDD) → Review → Archive *(multi-stakeholder / cross-department projects)*
- 🟡 **Standard path**: Brainstorm → Spec → Plan → Implement (TDD) → Review → Archive
- 🟢 **Fast path**: Plan → Implement → Review *(low-risk only; skip Brainstorm + Spec)*

Each work item produces a **Change Package** under `changes/<YYYY-MM-DD>-<slug>/`.

### Quality Gates (Automatic)

Between stages, agents automatically validate output quality before handing off using `agentic-eval`. **No manual triggers needed** — agents run these checks internally and report results.

| Trigger | Runs In | What It Checks | If FAIL |
|---------|---------|----------------|---------|
| After Spec → before Plan handoff | spec-agent self-eval | AC testability, requirement traceability | Auto-correct or block handoff |
| Before Plan writes tasks | plan-agent cross-validate | Can spec be broken into executable steps? | Gap markers at top of 04-plan.md |
| After Code → before Review | coder-agent self-eval | Green build, Financial Precision, AC coverage | **Financial Precision = hard stop** |
| After Plan/Spec (Med/High risk) | architect-agent arbitration | Architectural compliance, spec coverage | Requires manual request; triggers subagent critique |

> ⚠️ **The only hard-stop rule**: float/double used for money — coder-agent refuses to proceed to Review. Fix the precision issue first.
>
> 💡 **Architect arbitration** is the only gate that requires user action. After plan completes on Med/High risk work, switch to architect-agent and say: "请对这份 plan 做架构仲裁" or "arbitrate this plan".

## Notes

- Keep instructions in Traditional Chinese for explanations as defined in the constitution.
- Update the skill set per your tech stack and product needs.
- Run `pwsh -File .\tools\sync-dotgithub.ps1` after editing instructions.

See `WORKFLOW.md` for detailed workflow documentation.

## 📚 Documentation & Reading Path

### 🆕 First time? Read in this order:

| Step | Document | Purpose |
|------|----------|---------|
| 1 | [ONBOARDING.md](./ONBOARDING.md) | Environment checklist — Copilot subscription, CLI install, execution policy |
| 2 | [INSTALL.md](./INSTALL.md) | Detailed installation & troubleshooting guide |
| 3 | [QUICKSTART.md](./QUICKSTART.md) | **5-minute quick start** — 6-stage workflow + CLI flow demo + skills overview |
| 4 | [WORKFLOW.md](./WORKFLOW.md) | **Full workflow reference** — paths, skills mapping, decision rules, memory tips |

### 📖 Reference (as needed):

| Document | Purpose |
|----------|---------|
| [BOOTSTRAP-GUIDE.md](./BOOTSTRAP-GUIDE.md) | Advanced bootstrap parameters and deployment modes |
| [REMOTE-INSTALL.md](./REMOTE-INSTALL.md) | One-click remote installation |
| [SECURITY.md](./SECURITY.md) | Security guidelines for financial systems |
| [INSTALL.zh-TW.md](./INSTALL.zh-TW.md) | 繁體中文安裝指南 |
| [README.zh-TW.md](./README.zh-TW.md) | 完整繁體中文說明（含六階段逐步指引）|
