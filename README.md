# AI Development Workflow Template

This repository provides a reusable, finance-grade AI development workflow for GitHub Copilot CLI and VS Code.

## What You Get

- Team constitution and instruction mapping for consistent AI behavior
- Agent personas: Architect, Plan, Coder, Reviewer, Spec
- Prompt library (9 commands) for repeatable workflows
- Skills library (24 specialized capabilities)
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
- `agents/` - Persona definitions (5 agents)
- `instructions/` - Language and domain rules
- `prompts/` - Slash commands (9 prompts)
- `skills/` - Skills library (24 skills)
- `Init-Project.ps1` - Deployment script
- `tools/` - Sync scripts

## 6-Stage Workflow

```
1. Brainstorm → 2. Spec → 3. Plan → 4. Implement → 5. Review → 6. Archive
   (釐清需求)    (規格)    (計畫)     (TDD)       (Code+Security) (歸檔)
```

### Commands

| Stage | Command | Description |
|-------|---------|-------------|
| 1 | `/brainstorm` | Triage risk, clarify requirements, create change package |
| 2 | `/spec` | Generate specification document |
| 3 | `/plan` | Create executable implementation plan |
| 4 | `/tdd` | Implement with Red-Green-Refactor |
| 5 | `/review` | Code Review + Security Review (parallel) |
| 6 | `/archive` | Finalize and document |

### Workflow Paths

- **Standard path**: Brainstorm → Spec → Plan → Implement (TDD) → Review → Archive
- **Fast path**: Plan → Implement → Review (low-risk only)

Each work item produces a **Change Package** under `changes/<YYYY-MM-DD>-<slug>/`.

## Notes

- Keep instructions in Traditional Chinese for explanations as defined in the constitution.
- Update the skill set per your tech stack and product needs.
- Run `pwsh -File .\tools\sync-dotgithub.ps1` after editing instructions.

See `WORKFLOW.md` for detailed workflow documentation.
