# AI Development Workflow Template

This repository provides a reusable, finance-grade AI development workflow for teams.

## What You Get

- Team constitution and instruction mapping for consistent AI behavior
- Agent personas for planning, architecture, coding, review, and PRD work
- Prompt library for repeatable workflows
- Skills library for specialized tasks
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
- `agents/` - Persona definitions
- `instructions/` - Language and domain rules
- `prompts/` - Prompt commands
- `skills/` - Skills library
- `Init-Project.ps1` - Deployment script

## Notes

- Keep instructions in Traditional Chinese for explanations as defined in the constitution.
- Update the skill set per your tech stack and product needs.
