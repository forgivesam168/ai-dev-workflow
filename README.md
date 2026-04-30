# AI Development Workflow Template

This repository provides a reusable AI development workflow for GitHub Copilot CLI and VS Code, suitable for any software domain (financial, HR, legal, compliance, audit, small tools, etc.).

## What You Get

- Team constitution and instruction mapping for consistent AI behavior
- Agent personas: Architect, Plan, Coder, Reviewer, Spec
- Prompt library (10 commands) for repeatable workflows
- Skills library (28 specialized capabilities)
- Bootstrap installer for deploying to any project
- **Repo Memory** for persistent project context across sessions (opt-in)

## Getting Started

Navigate to your target project directory and run:

```powershell
# Download and run (auto-fetches template from GitHub)
Invoke-WebRequest -Uri "https://raw.githubusercontent.com/forgivesam168/ai-dev-workflow/main/bootstrap.ps1" -OutFile "bootstrap.ps1"
pwsh -ExecutionPolicy Bypass -File .\bootstrap.ps1
Remove-Item bootstrap.ps1
```

To update an existing project to the latest template:

```powershell
Invoke-WebRequest -Uri "https://raw.githubusercontent.com/forgivesam168/ai-dev-workflow/main/bootstrap.ps1" -OutFile "bootstrap.ps1"
pwsh -ExecutionPolicy Bypass -File .\bootstrap.ps1 -Update
Remove-Item bootstrap.ps1
```

See [BOOTSTRAP-GUIDE.md](./BOOTSTRAP-GUIDE.md) for all parameters and advanced options.

## Structure

- `copilot-instructions.md` - Team constitution
- `agents/` - Persona definitions (6 agents)
- `instructions/` - Language and domain rules
- `prompts/` - Slash commands (10 prompts)
- `skills/` - Skills library (28 skills)
- `bootstrap.ps1` - Deployment & update installer
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

- **Standard path**: Brainstorm → Spec → Plan → Implement (TDD) → Review → Archive
- **Fast path**: Brainstorm → Plan → Implement → Review (low-risk only, skip Spec)

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

## Repo Memory (Opt-In)

Repo Memory lets the AI retain project context across sessions — no re-explaining your tech stack or current stage every time.

**Enable it** (add `-EnableMemory` flag):
```powershell
Invoke-WebRequest -Uri "https://raw.githubusercontent.com/forgivesam168/ai-dev-workflow/main/bootstrap.ps1" -OutFile "bootstrap.ps1"
pwsh -ExecutionPolicy Bypass -File .\bootstrap.ps1 -EnableMemory
Remove-Item bootstrap.ps1
```

**What gets created:**
```
.ai-workflow-memory/
├── PROJECT_CONTEXT.md   # Tech stack, key architectural decisions (committed)
├── CURRENT_STATE.md     # Active work status, updated each session (committed)
└── session-journal/     # Append-only per-session logs (gitignored)
```

**How it works:** The AI reads `PROJECT_CONTEXT.md` and `CURRENT_STATE.md` before starting any analysis or implementation. At session end, it updates `CURRENT_STATE.md` with stage and next steps.

> See `docs/repo-memory-design.md` for full design specification.

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
