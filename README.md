# AI Development Workflow Template

This repository provides a reusable AI development workflow template that can be consumed from GitHub Copilot, OpenAI Codex, Anthropic Claude Code, and Google Antigravity, suitable for any software domain (financial, HR, legal, compliance, audit, small tools, etc.).

## What You Get

- Team constitution and instruction mapping for consistent AI behavior
- 9 agent personas: Brainstorm, Architect, Spec, Plan, Coder, Code Reviewer, PM, Frontend Designer, DBA
- Prompt library (10 commands) for repeatable workflows
- Skills library (35 specialized capabilities)
- Bootstrap installer for deploying to any project
- **Repo Memory** for persistent project context across sessions (opt-in)

## Multi-CLI Runtime

Bootstrap now installs a portable runtime in addition to the legacy `.github/**` compatibility layer:

- `skills/` becomes the shared skill source of truth
- `.agents/skills/`, `.claude/skills/`, and `.agent/skills/` point to that shared skill library
- `agents/` remains the canonical persona source
- `.codex/agents/` and `.claude/agents/` are generated from `agents/*.agent.md`
- `AGENTS.md` is the shared repo guidance source; `CLAUDE.md` and `GEMINI.md` are thin wrappers

Deprecated `scripts/bootstrap.sh` does not install that full portable runtime. It is a compatibility-only Bash path that seeds the legacy `.github/**` layer, copies root `.gitattributes` / `.editorconfig` when present, and initializes Git if the target repo does not already have `.git`.

For existing projects, run the updater once and commit the newly added managed paths:
`skills/`, `agents/`, `.agents/`, `.agent/`, `.claude/`, `.codex/`, `CLAUDE.md`, `GEMINI.md`, and `.ai-workflow-install.json`.
Existing project `AGENTS.md` files are preserved and may need a manual merge if you want the new template wording.

Ownership model in adopter repos:

- `skills/` and `agents/` are the template-managed baseline. Customize them here and commit the changes.
- `.github/skills/`, `.github/agents/`, `.codex/agents/`, `.claude/agents/`, and the skill mounts are derived runtime. Bootstrap regenerates them from the top-level sources.
- `AGENTS.md`, `CLAUDE.md`, and `GEMINI.md` are project-owned. Bootstrap creates them once and then preserves local edits.
- Supported update paths are `.\scripts\bootstrap.ps1 -Update` on Windows and `python3 scripts/bootstrap.py --update` on Linux/macOS. Bash is deprecated and does not provide update, force, or backup modes.

## Getting Started

Navigate to your target project directory and run:

```powershell
# Download and run (auto-fetches template from GitHub)
Invoke-WebRequest -Uri "https://raw.githubusercontent.com/forgivesam168/ai-dev-workflow/main/scripts/bootstrap.ps1" -OutFile "bootstrap.ps1"
pwsh -ExecutionPolicy Bypass -File .\bootstrap.ps1
Remove-Item bootstrap.ps1
```

To update an existing project to the latest template:

```powershell
Invoke-WebRequest -Uri "https://raw.githubusercontent.com/forgivesam168/ai-dev-workflow/main/scripts/bootstrap.ps1" -OutFile "bootstrap.ps1"
pwsh -ExecutionPolicy Bypass -File .\bootstrap.ps1 -Update
Remove-Item bootstrap.ps1
```

After updating, start a new Codex / Claude session so newly generated skills and custom agents are reloaded.
In Codex CLI, use `/skills` to inspect installed skills and `$skill-name` for explicit invocation.

See [BOOTSTRAP-GUIDE.md](./BOOTSTRAP-GUIDE.md) for all parameters and advanced options.

## Structure

- `copilot-instructions.md` - Team constitution
- `agents/` - Persona definitions (9 agents)
- `instructions/` - Language and domain rules
- `prompts/` - Slash commands (10 prompts)
- `skills/` - Skills library (35 total: 34 deployed to adopter projects + maintainer-only `gate-check`)
- `.codex/agents/` - Generated Codex custom agents in adopter repos
- `.claude/agents/` - Generated Claude custom agents in adopter repos
- `scripts/bootstrap.ps1` - Single supported public install/update entry point
- `tools/` - Maintainer-only repo utilities (`sync-dotgithub`, read-only `check-sync`, `audit-catalog`)

## Agents

Nine specialized agents cover the full development lifecycle. Each agent has a defined role, primary skill, and handoff protocol.

| Agent | Role | Primary Skill(s) | Trigger Keywords |
|-------|------|-----------------|-----------------|
| **brainstorm-agent** | Requirements Explorer & Risk Classifier | `brainstorming` | brainstorm, 釐清需求, 我有個想法, explore options |
| **architect-agent** | Cross-Stage System Architect & Quality Arbitrator | `brainstorming` (ADR) + `agentic-eval` | design, architect, ADR, system design, architectural trade-offs |
| **spec-agent** | Specification Specialist | `specification` | write spec, create PRD, requirements, 規格文件 |
| **plan-agent** | Strategic Implementation Planner | `implementation-planning` | create plan, task breakdown, 規劃實作, spec to plan |
| **coder-agent** | TDD & Build-Aware Implementation | `tdd-workflow` | TDD, implement, 開始 TDD, test-driven |
| **code-reviewer** | Code Quality & Security Auditor | `code-security-review` | review, audit, 審核程式碼, code review |
| **pm-agent** | Cross-Session Workflow Guardian | `workflow-orchestrator` + `prd` | project status, what's next, 我們在哪, workflow status |
| **frontend-designer-agent** | UI/UX Designer & Component Spec | `frontend-patterns` + `excalidraw-diagram-generator` | design UI, wireframe, component spec, 前端設計 |
| **dba-agent** | Database Architect & Migration Safety | `sql.instructions.md` | design schema, ERD, migration, 資料庫設計 |

### Agent Roles at a Glance

- **PM**: *"Where are we?"* — Scans `changes/` to detect stage and recommend next step
- **Brainstorm**: *"What are we building?"* — Clarifies requirements before code is written
- **Architect**: *"Is the design sound?"* — Cross-stage quality arbitration; available at any stage
- **Spec**: *"What exactly must be done?"* — Turns requirements into testable acceptance criteria
- **Plan**: *"How do we do it step-by-step?"* — Produces `04-plan.md` with TDD-integrated tasks
- **Coder**: *"Write the code."* — Red-Green-Refactor; Financial Precision is a hard stop
- **DBA** *(Consult)*: *"Is the schema right?"* — Engages at Spec/Plan stage, not coding stage
- **Frontend Designer** *(Consult)*: *"Is the UI/UX right?"* — Engages at Spec/Plan stage
- **Code Reviewer**: *"Is the code shippable?"* — Multi-lens audit; routes to work-archiving on pass

## 6-Stage Workflow

```
1. Brainstorm → 2. Spec → 3. Plan → 4. Implement → 5. Review → 6. Archive
   (釐清需求)    (規格)    (計畫)     (TDD)       (Code+Security) (歸檔)
```

### Commands (VS Code Slash Commands)

| Stage | VS Code | Description |
|-------|---------|-------------|
| 0 | `/workflow` | **Orchestrator**: Detect current stage, guide next step |
| 1 | `/brainstorm` | Triage risk, ask at least five discovery questions, create change package |
| 2 | `/spec` | Generate specification document |
| 3 | `/create-plan` | Create executable implementation plan |
| 4 | `/tdd` | Implement with Red-Green-Refactor |
| 5 | `/code-review` | Code Review + Security Review (parallel) |
| 6 | `/archive` | Finalize and document |

> **Codex / Claude / Antigravity CLI users**: The above are VS Code prompt shortcuts (`.github/prompts/`).
> In CLI, use natural language instead — e.g., "review my code", "create an implementation plan".
> Note: CLI has its own built-in `/plan` (Plan Mode) and `/review` (code review agent), which are
> different from these workflow prompts.
> Brainstorm starts with discovery questions by default; if the skill does not auto-load, use the tool-native explicit invocation (`$brainstorming` in Codex CLI, `/brainstorming` in Copilot / VS Code).

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

### Shared Guardrails (Always-On + Manual Fallback)

The workflow keeps the existing **Agent → Primary Skill** pairing intact. `execution-guardrails` is a shared quality layer that reinforces:

- assumptions must be explicit
- solutions should stay as simple as the current request allows
- diffs should remain surgical
- success criteria should be verifiable

Most of this behavior is now always-on through the constitution and core agents. When you want an explicit reset, use `/execution-guardrails` as a manual fallback.

## Notes

- Keep instructions in Traditional Chinese for explanations as defined in the constitution.
- Update the skill set per your tech stack and product needs.
- Template maintainers only: run `pwsh -File .\tools\sync-dotgithub.ps1` after editing top-level source files that must stay mirrored under this repo's `.github/**`.

See `WORKFLOW.md` for detailed workflow documentation.

## Skills (35 total; 34 adopter + 1 maintainer-only) — What's New

Skills are the methodology layer loaded automatically by agents. Recent additions expand the toolkit significantly:

| Category | Skills | Highlights |
|----------|--------|-----------|
| **Core Workflow** (10) | `workflow-orchestrator`, `brainstorming`, `specification`, `implementation-planning`, `tdd-workflow`, `code-security-review`, `work-archiving`, `explore`, **`shipping-and-launch`** ✨, **`ci-cd-and-automation`** ✨ | New: production deployment + CI/CD pipeline design |
| **Quality & Context** (2) | `execution-guardrails`, **`context-engineering`** ✨ | New: 5-layer context architecture, vocabulary conflict detection, anti-hallucination |
| **Development Patterns** (5) | `coding-standards`, `backend-patterns`, `frontend-patterns`, `python-patterns`, `refactor` | `refactor` upgraded: Chesterton's Fence + Measure-First modes |
| **Testing & QA** (4) | `agentic-eval`, **`debug`** ✨, `webapp-testing`, `scoutqa-test` | New: systematic debug skill with 2-cycle escalation ceiling |
| **Tool Skills** (3) | `git-commit`, `prd`, `make-skill-template` | — |
| **Security** (1) | `security-review` | CSO dual-mode: Quick Gate + Deep Scan (OWASP Top 10) |
| **Microsoft & GitHub** (5) | `microsoft-docs`, `microsoft-code-reference`, `copilot-sdk`, `gh-cli`, `github-issues` | — |
| **Content & Viz** (4) | `excalidraw-diagram-generator`, `markdown-to-html`, `web-design-reviewer`, `chrome-devtools` | — |

✨ = newly added in this release. Full descriptions in `AGENTS.md` → Skills (35 total: 34 adopter + 1 maintainer-only).

## Repo Memory (Opt-In)

Repo Memory lets the AI retain project context across sessions — no re-explaining your tech stack or current stage every time.

**Enable it** (add `-EnableMemory` flag):
```powershell
Invoke-WebRequest -Uri "https://raw.githubusercontent.com/forgivesam168/ai-dev-workflow/main/scripts/bootstrap.ps1" -OutFile "bootstrap.ps1"
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
| 1 | [ONBOARDING.md](./ONBOARDING.md) | Environment checklist — Codex / Claude / Copilot tooling, CLI install, execution policy |
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
