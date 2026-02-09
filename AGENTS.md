# AGENTS.md — Team AI Workflow Rules (Template Repo)

This repo is a **finance‑grade AI development workflow template**.
It contains:
- Constitution / global behavior rules for AI assistants (`copilot-instructions.md`)
- Agent personas (`agents/*.agent.md`) — 5 agents
- Instruction files (`instructions/*.instructions.md`)
- Prompt library (`prompts/*.prompt.md`) — 9 prompts
- Skills library (`skills/**/SKILL.md`) — 24 skills
- Bootstrap script (`Init-Project.ps1`) to deploy these assets into another project.

## Agents

| Agent | Description |
|-------|-------------|
| `architect.agent.md` | System Architect for design and ADRs |
| `plan.agent.md` | Strategic planning and task breakdown |
| `coder.agent.md` | TDD implementation specialist |
| `code-reviewer.agent.md` | Code quality and security review |
| `spec.agent.md` | Specification and PRD creation |

## Prompts (Slash Commands)

| Command | Stage | Description |
|---------|-------|-------------|
| `/brainstorm` | 1 | Triage risk, clarify requirements |
| `/spec` | 2 | Generate specification document |
| `/plan` | 3 | Create implementation plan |
| `/tdd` | 4 | TDD implementation |
| `/review` | 5 | Code + Security review |
| `/archive` | 6 | Finalize and document |
| `/commit` | Tool | Generate commit message |
| `/readme` | Tool | Create README |
| `/learn` | Tool | Learn and improve AI behavior |

## How this repo is structured

### Source-of-truth vs runtime locations
- **Source-of-truth (editable):** top‑level folders: `agents/`, `instructions/`, `prompts/`, `skills/`, and `copilot-instructions.md`.
- **Runtime locations (for GitHub Copilot / VS Code):** `.github/agents/`, `.github/instructions/`, `.github/prompts/`, `.github/skills/`, and `.github/copilot-instructions.md`.

The `.github/**` copies are generated for tools that only read instruction files under `.github/`.

## When you change instructions
After editing any file under `agents/`, `instructions/`, `prompts/`, `skills/`, or `copilot-instructions.md`,
run the sync script to update `.github/**`:

```powershell
pwsh -File .\tools\sync-dotgithub.ps1
```

## Usage in other repositories
To deploy this template into another repo, run:

```powershell
pwsh -File .\Init-Project.ps1
```

## Safety defaults (recommended)
- Never commit secrets or credentials.
- Any change to `.github/workflows/**` should require CODEOWNERS review.
- Prefer `mode=finsec` (governance & security) for PR reviews in regulated environments.

## Workflow (recommended)
- For medium/high-risk changes: `/brainstorm` → `/spec` → `/plan` → `/tdd` → `/review` → `/archive`
- See `WORKFLOW.md` for the full flow and skip rules.
