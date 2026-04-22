# AGENTS.md — Team AI Workflow Rules (Template Repo)

This repo is a **production‑grade AI development workflow template**.
It contains:
- Constitution / global behavior rules for AI assistants (`copilot-instructions.md`)
- Agent personas (`agents/*.agent.md`) — 6 agents
- Instruction files (`instructions/*.instructions.md`)
- Prompt library (`prompts/*.prompt.md`) — 10 prompts
- Skills library (`skills/**/SKILL.md`) — 30 skills
- Bootstrap installer (`bootstrap.ps1`) to deploy these assets into any project.

## Pointer-Style Guidance Architecture

Context is loaded progressively — heavier files load only when needed:

| Layer | Path | Size Target | Loaded When |
|-------|------|-------------|-------------|
| ① Constitution | `copilot-instructions.md` | ≤40 lines (~390 tokens) | Every interaction |
| ② Repo rules | `AGENTS.md` | — | Every interaction |
| ③ Agent persona | `agents/*.agent.md` | ≤25 non-empty lines each | Agent selected |
| ④ Language/domain | `instructions/*.instructions.md` | Varies | File-type matches `applyTo` glob |
| ⑤ Skills | `skills/*/SKILL.md` | Progressive (L1→L2→L3) | Only when relevant to prompt |

**Skill progressive loading:**
- **L1 Discovery** — `name` + `description` only (always scanned)
- **L2 Instructions** — full SKILL.md body (when prompt matches)
- **L3 Resources** — `scripts/`, `references/`, `templates/` (when explicitly referenced)

## Agents

| Agent | Paired Skill | Description |
|-------|-------------|-------------|
| `brainstorm.agent.md` | `brainstorming` | Requirements explorer, risk classifier |
| `architect.agent.md` | `brainstorming` | Cross-stage System Architect for design and ADRs |
| `spec.agent.md` | `specification` | Specification and PRD creation |
| `plan.agent.md` | `implementation-planning` | Strategic planning and task breakdown |
| `coder.agent.md` | `tdd-workflow` | TDD implementation specialist |
| `code-reviewer.agent.md` | `code-security-review` | Code quality and security review |

### Agent ↔ Skill Integration Pattern

Each agent includes a `## Skill Integration` section that uses a three-layer binding strategy:

1. **Keyword Magnetism** (YAML `description`): Agent descriptions include the same trigger keywords as their paired skill, increasing auto-load probability during L1 Discovery.
2. **Explicit Directive** (body text): Agent body instructs the model to follow the paired skill's methodology when loaded.
3. **User Fallback** (slash command tip): Each agent suggests `/skill-name` as a manual trigger if auto-load doesn't activate.

> **Note**: Skill auto-load is probabilistic (model-driven). If the paired skill doesn't load automatically, use the `/skill-name` command shown in the agent's Skill Integration section.

### agentic-eval 品質閘門（次要整合層）

在各 agent 完成**主要 skill** 之後，`agentic-eval` skill 作為次要整合層介入，在階段交接點提供品質驗證，確保產出物符合下游 agent 的期望品質。

| Agent | 主要 Skill 完成後 → agentic-eval | 目的與效益 | Tier | 風險閾值 |
|-------|----------------------------------|-----------|------|---------|
| `spec-agent` | `specification` → 03-spec.md | AC 可測性 + 邊界覆蓋自評；**Testability / Traceability FAIL 則阻擋 handoff**，防止不完整規格流入計畫階段 | 1 | 所有風險 |
| `plan-agent` | `implementation-planning` → 04-plan.md | 從規劃者視角交叉驗證 spec 可行性，找出「無法寫出具體步驟」的需求並標記 gap | 1 | Med / High |
| `coder-agent` | `tdd-workflow` → 實作完成 | 交 code-reviewer 前確認 Financial Precision + Green Build；**Financial Precision FAIL = 強制停止**，不得進入 Review | 1 | 所有風險 |
| `architect-agent` | `brainstorming` → Spec/Plan/Review | 跨階段品質仲裁：從架構視角評估規格完整性、計畫邊界合規、Review 完整性；≥2 維度 FAIL 則委派 Tier 2 子代理對抗性批評 | 1 / 2 | Med / High |

**不適用情境：**
- `brainstorm-agent`：發散思維階段刻意不評估，保護創意探索空間
- `code-reviewer`：本身即獨立 Tier 2 閘門，不需再套用 agentic-eval

> 詳細 rubric 維度與 adversarial prompt template 見 [`skills/agentic-eval/references/stage-rubrics.md`](./skills/agentic-eval/references/stage-rubrics.md)。

## Prompts (Slash Commands)

| Command | Stage | Description |
|---------|-------|-------------|
| `/workflow` | 0 | **Orchestrator**: Detect stage, guide next step |
| `/brainstorm` | 1 | Triage risk, clarify requirements |
| `/spec` | 2 | Generate specification document |
| `/create-plan` | 3 | Create implementation plan |
| `/tdd` | 4 | TDD implementation |
| `/code-review` | 5 | Code + Security review |
| `/archive` | 6 | Finalize and document |
| `/commit` | Tool | Generate commit message |
| `/readme` | Tool | Create README |
| `/learn` | Tool | Learn and improve AI behavior |

## Skills (31)

Skills provide methodology and toolkits that are automatically loaded into the current agent's context.

### Core Workflow Skills (9)

| Skill | Description | Triggers On | Recommended Agent |
|-------|-------------|-------------|-------------------|
| workflow-orchestrator | Flow coordinator: detects current stage and recommends next steps | workflow, what's next | — |
| brainstorming | Structured requirements exploration and risk classification | brainstorm, explore options | architect / spec |
| specification | Generate PRD/Spec documents | spec, PRD, requirements | spec-agent |
| implementation-planning | Break down implementation plan with TDD integration (includes plan-from-spec) | plan, task breakdown, spec to plan | plan-agent |
| tdd-workflow | TDD methodology (Red-Green-Refactor) | TDD, test-driven | coder-agent |
| code-security-review | Code quality and security audit for financial systems | review, audit | code-reviewer-agent |
| work-archiving | Finalize and archive completed work | archive, finalize | — |
| explore | Read-only codebase investigation before committing to a change package | explore, investigate, scan risks | — |
| gate-check | Deterministic pre-review gate: sync drift + catalog parity + build/lint/test | gate check, pre-review check | coder-agent |

### Tool Skills (3)

| Skill | Description | Triggers On |
|-------|-------------|-------------|
| git-commit | Conventional Commits message generation with intelligent staging | commit |
| prd | Generate Product Requirements Documents | PRD, product requirements |
| make-skill-template | Scaffold new Agent Skills for GitHub Copilot | create a skill, scaffold skill |

### Development Pattern Skills (5)

| Skill | Description | Triggers On |
|-------|-------------|-------------|
| coding-standards | Universal standards for TypeScript, JavaScript, React, Node.js | coding standards, best practices |
| backend-patterns | Backend architecture, API design, DB optimization (Node/Express/Next) | backend, API design |
| frontend-patterns | React, Next.js, state management, performance, UI patterns | frontend, React patterns |
| python-patterns | PEP 8, type hints, pytest, TDD for Python | Python, pytest |
| refactor | Surgical code refactoring without behavior changes | refactor, code smells |

### Microsoft & GitHub Skills (5)

| Skill | Description | Triggers On |
|-------|-------------|-------------|
| microsoft-docs | Query official Microsoft documentation | Azure, .NET, Microsoft |
| microsoft-code-reference | Look up Microsoft API references and verify SDK code | Azure SDK, .NET API |
| copilot-sdk | Build agentic apps with GitHub Copilot SDK | Copilot SDK, custom agent |
| gh-cli | GitHub CLI comprehensive reference | gh CLI, GitHub operations |
| github-issues | Create, update, and manage GitHub issues via MCP | create issue, file bug |

### Testing & QA Skills (3)

| Skill | Description | Triggers On |
|-------|-------------|-------------|
| webapp-testing | Test local web apps using Playwright | test webapp, Playwright |
| scoutqa-test | Exploratory QA testing (smoke, accessibility, e-commerce flows) | test website, accessibility |
| agentic-eval | Evaluate and improve AI agent outputs (self-critique, rubrics) | evaluate agent, quality loop |
| debug | Systematic debugging for build/test failures, unexpected behavior, drift errors; escalates after 2 failed cycles | debug, fix build, tests failing, investigate failure |

### Security & Review Skills (1)

| Skill | Description | Triggers On |
|-------|-------------|-------------|
| security-review | Security checklist for auth, input handling, secrets, payments | security review, auth check |

### Content & Visualization Skills (4)

| Skill | Description | Triggers On |
|-------|-------------|-------------|
| excalidraw-diagram-generator | Generate Excalidraw diagrams from natural language | create diagram, flowchart |
| markdown-to-html | Convert Markdown to HTML (GFM, CommonMark) | convert markdown, render md |
| web-design-reviewer | Visual inspection of websites to find and fix design issues | review design, check UI |
| chrome-devtools | Browser automation, debugging, performance via Chrome DevTools MCP | DevTools, browser debug |

### Skills Usage

**CLI**:
```bash
# View installed skills
/skills list

# Trigger by natural language (auto-loads)
> I want to generate spec
[System auto-loads specification skill]
```

**VS Code**:
- Input keywords (auto-loads skill)
- Or use corresponding slash command (shortcut)

---

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
To deploy this template into another repo, run bootstrap from the target project directory:

```powershell
# Download and run (auto-fetches from GitHub)
Invoke-WebRequest -Uri "https://raw.githubusercontent.com/forgivesam168/ai-dev-workflow/main/bootstrap.ps1" -OutFile "bootstrap.ps1"
pwsh -ExecutionPolicy Bypass -File .\bootstrap.ps1
Remove-Item bootstrap.ps1

# To update an existing project
Invoke-WebRequest -Uri "https://raw.githubusercontent.com/forgivesam168/ai-dev-workflow/main/bootstrap.ps1" -OutFile "bootstrap.ps1"
pwsh -ExecutionPolicy Bypass -File .\bootstrap.ps1 -Update
Remove-Item bootstrap.ps1
```

Maintainers of this template repo update via `git pull` — no scripts needed.

## Safety defaults (recommended)
- Never commit secrets or credentials.
- Any change to `.github/workflows/**` should require CODEOWNERS review.
- Prefer `mode=finsec` (governance & security) for PR reviews in regulated environments.

## Workflow (recommended)
- For guided workflow: `/workflow` (automatic stage detection)
- For medium/high-risk changes: `/brainstorm` → `/spec` → `/create-plan` → `/tdd` → `/code-review` → `/archive`
- For low-risk changes: `/brainstorm` → `/create-plan` → `/tdd` → `/code-review` → `/archive` (fast path)
- See `WORKFLOW.md` for the full flow and skip rules.
