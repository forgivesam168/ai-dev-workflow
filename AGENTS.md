# AGENTS.md — Team AI Workflow Rules (Template Repo)

This repo is a **production‑grade AI development workflow template**.
It contains:
- Constitution / global behavior rules for AI assistants (`copilot-instructions.md`)
- Agent personas (`agents/*.agent.md`) — 9 agents
- Instruction files (`instructions/*.instructions.md`)
- Prompt library (`prompts/*.prompt.md`) — 10 prompts
- Skills library (`skills/**/SKILL.md`) — 35 total skills: 34 adopter skills + 1 maintainer-only `gate-check`
- Bootstrap installer (`bootstrap.ps1`) to deploy these assets into any project.

## Cross-CLI Constitutional Baseline

Not every CLI treats `copilot-instructions.md` as its always-on constitution. Treat this section as the **portable constitutional mirror** for Codex, Claude Code, Antigravity, and any other surface that reads `AGENTS.md` first.

**Boundary rule:**
- `copilot-instructions.md` keeps the maintainer-specific compact constitution and sync obligations.
- `AGENTS.md` carries the portable constitutional baseline plus repo workflow rules.
- `docs/AGENTS.template.md` must mirror this baseline and a thin operating model so adopter projects receive the same default behavior.

### Cross-CLI Consistency Principle

- Different CLI surfaces may expose different UX, but they should not materially diverge in constitutional behavior, persona intent, workflow entry points, or handoff quality thresholds.
- The stable cross-CLI floor belongs in `AGENTS.md`.
- Detailed persona bodies belong in `agents/`.
- Detailed methodology, checklists, and quality rubrics belong in `skills/`.
- If a surface cannot load repo-local agents, fall back to `AGENTS.md` + the relevant skill while preserving the same standards.

**Tradeoff:** These rules bias toward caution over speed for non-trivial work. For trivial tasks, use judgment without dropping the safety floor.

### 1. Think Before Coding

- State assumptions explicitly. Separate facts, assumptions, and unknowns instead of guessing silently.
- If multiple interpretations exist, surface them. Do not pick one without saying so.
- If a simpler approach exists, say so. Push back on unnecessary complexity when warranted.
- If ambiguity materially changes the implementation path, stop and clarify before proceeding.

### 2. Simplicity First

- Implement the smallest solution that satisfies the current requirement.
- Do not add speculative abstractions, flexibility, configuration, or future-proofing.
- Do not add features beyond what was asked.
- Prefer the version a senior engineer would call obviously simpler.

### 3. Surgical Changes

- Every changed line must trace directly to the user's request or to dead code created by that change.
- Do not perform drive-by refactors, formatting churn, or adjacent comment rewrites.
- Match existing style and boundaries unless the request explicitly changes them.
- Remove only the imports, variables, or functions that your own change makes unused. Mention pre-existing dead code instead of deleting it unasked.

### 4. Goal-Driven Verification

- Convert requests into verifiable outcomes: tests, assertions, reproducible checks, or explicit manual validation.
- For bug fixes, prefer reproducing the issue first, then fixing it, then proving the fix.
- For multi-step work, state a short plan where each step has a verification method.
- Avoid weak completion language such as "make it work" without a measurable check.

### 5. Context Loading Order

- If `.ai-workflow-memory/PROJECT_CONTEXT.md` exists, load it before making technical decisions.
- Else if `docs/CONTEXT.md` exists, load it before reasoning from session memory alone.
- Detect vocabulary conflicts between conversation, spec/plan, and project glossary before implementation.
- Do not let Layer 4 conversation context override Layer 1 project context silently.

### 6. Safety Floor

- Never commit secrets or credentials.
- Validate external input and verify input boundaries on every change.
- For money, never use `float` or `double`; use decimal types, integer minor units, or strings at API boundaries.
- When transactions can be retried, require idempotency support such as `Idempotency-Key`.
- Adapt the checklist to the project domain, but precision and security are never optional.

### 7. Communication Contract

- Use Traditional Chinese for explanations, analysis, reasoning, planning, and commit messages.
- Use English for source code, code comments, and technical identifiers unless the file itself already uses another convention.
- Be direct and explicit about uncertainty.
- When enforcing a repo-specific rule, cite the governing file so downstream agents can trace the source.

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

## Design Philosophy: Persona vs Behavior

> **Agent = Persona** (who does the work): tool restrictions, model preferences, handoff routes, role identity. Loaded only when that agent is selected.
> **Skill = Behavior** (how to do it): methodology, templates, scripts — portable across VS Code / CLI / Claude Code. Loaded progressively (L1→L3) when relevant.
>
> **Rule**: Keep agent bodies thin (≤25 non-empty lines). Move methodology detail into the paired skill. The agent holds identity; the skill holds knowledge.

## Agents

| Agent | Paired Skill | Description |
|-------|-------------|-------------|
| `brainstorm.agent.md` | `brainstorming` | Requirements explorer, risk classifier |
| `architect.agent.md` | `brainstorming` | Cross-stage System Architect for design and ADRs |
| `spec.agent.md` | `specification` | Specification and PRD creation |
| `plan.agent.md` | `implementation-planning` | Strategic planning and task breakdown |
| `coder.agent.md` | `tdd-workflow` | TDD implementation specialist |
| `code-reviewer.agent.md` | `code-security-review` | Code quality and security review |
| `pm.agent.md` | `workflow-orchestrator` | Project Manager: cross-session state tracking, workflow routing, PRD drafting |
| `frontend-designer.agent.md` | `frontend-patterns` | Frontend UI/UX Designer: component spec, accessibility, design system alignment |
| `dba.agent.md` | `sql.instructions.md` | Database Architect: schema design, migration safety, query optimization |

### Agent ↔ Skill Integration Pattern

Each agent includes a `## Skill Integration` section that uses a three-layer binding strategy:

1. **Keyword Magnetism** (YAML `description`): Agent descriptions include the same trigger keywords as their paired skill, increasing auto-load probability during L1 Discovery.
2. **Explicit Directive** (body text): Agent body instructs the model to follow the paired skill's methodology when loaded.
3. **User Fallback** (tool-specific explicit trigger): Each agent suggests the paired skill's manual trigger when auto-load doesn't activate.

> **Note**: Skill auto-load is probabilistic (model-driven). If the paired skill doesn't load automatically, use the tool-native explicit invocation per CLI. Agent invocation also differs per CLI — **Codex CLI has no `/agent-name` slash command**; use natural language or description-based auto-delegation instead.
>
> | CLI | Invoke a Skill | Invoke a Custom Agent |
> |-----|---------------|----------------------|
> | **GitHub Copilot CLI** | `/skill-name` | `/agent` → select from list, or natural language |
> | **Codex CLI** | `$skill-name` or `/skills` to browse | No slash command — ask naturally: "use the X agent"; Codex auto-delegates based on `description` |
> | **Claude Code** | `/skill-name` | `/agents` UI, `claude --agent <name>`, or natural language |
> | **Antigravity CLI** | Auto-activated based on description, or natural language | No dedicated agent mechanism; agent behavior is triggered via skills and natural language prompts |

### Shared Guardrails Layer

Not every skill in this repo is a stage-level **primary skill**. `execution-guardrails` is a **cross-cutting quality layer** that complements the existing Agent → Primary Skill pairing rather than replacing it.

Use this layering model:

1. **Agent** — who does the work
2. **Primary Skill** — the main methodology for that stage
3. **Guardrails** — shared execution constraints (assumptions explicit, simplicity first, surgical changes, verifiable success criteria)
4. **Quality Gate** — `agentic-eval` / `gate-check` before handoff

Operational rule:
- **Always-on essence** lives in `copilot-instructions.md` + core agent body text
- **Manual fallback** lives in `/execution-guardrails`
- **Quality scoring** lives in `agentic-eval` rubrics

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

## Skills (35 total: 34 adopter + 1 maintainer-only)

Skills provide methodology and toolkits that are automatically loaded into the current agent's context.

### Core Workflow Skills (10)

| Skill | Description | Triggers On | Recommended Agent |
|-------|-------------|-------------|-------------------|
| workflow-orchestrator | Flow coordinator: detects current stage and recommends next steps | workflow, what's next | — |
| brainstorming | Structured requirements exploration and risk classification | brainstorm, explore options | brainstorm-agent |
| specification | Generate PRD/Spec documents (with Vocabulary Lock, Specialist Lens Review, Observable Outcome AC format) | spec, PRD, requirements | spec-agent |
| implementation-planning | Break down implementation plan with TDD integration; Vertical Slice enforcement; plan-from-spec | plan, task breakdown, spec to plan, vertical slice | plan-agent |
| tdd-workflow | TDD methodology (Red-Green-Refactor); Three-Strike Rule; Feedback Loop Prerequisite | TDD, test-driven, three-strike | coder-agent |
| code-security-review | Code quality and security audit for financial systems | review, audit | code-reviewer-agent |
| work-archiving | Finalize and archive completed work; ADR Section with three-condition guard | archive, finalize, ADR | — |
| explore | Read-only codebase investigation before committing to a change package | explore, investigate, scan risks | — |
| shipping-and-launch | External deployment and launch readiness: Rollback Plan, Staged Rollout, Go/No-Go checklist | deploy, launch, rollout, go live, rollback | — |
| ci-cd-and-automation | CI/CD pipeline design and automation: Shift Left, 4-stage pipeline, Quality Gate rules, Anti-Pattern guard | CI/CD, pipeline, automation, quality gate | — |

### Tool Skills (3)

| Skill | Description | Triggers On |
|-------|-------------|-------------|
| git-commit | Conventional Commits message generation with intelligent staging | commit |
| prd | Generate Product Requirements Documents | PRD, product requirements |
| make-skill-template | Scaffold new Agent Skills for GitHub Copilot | create a skill, scaffold skill |

### Cross-Cutting Quality Skills (2)

| Skill | Description | Triggers On |
|-------|-------------|-------------|
| execution-guardrails | Shared quality guardrails that reduce hidden assumptions, overengineering, unrelated edits, and weak success criteria; use as manual fallback with `/execution-guardrails` | hidden assumptions, overengineering, unrelated edits, success criteria |
| context-engineering | 5-layer context architecture (Project/Codebase/Task/Conversation/External Docs); vocabulary conflict detection; CONTEXT.md path rules; combats AI hallucination from context pollution | context engineering, CONTEXT.md, context pollution, vocabulary conflict |

### Development Pattern Skills (5)

| Skill | Description | Triggers On |
|-------|-------------|-------------|
| coding-standards | Universal standards for TypeScript, JavaScript, React, Node.js | coding standards, best practices |
| backend-patterns | Backend architecture, API design, DB optimization (Node/Express/Next) | backend, API design |
| frontend-patterns | React, Next.js, state management, performance, UI patterns | frontend, React patterns |
| python-patterns | PEP 8, type hints, pytest, TDD for Python | Python, pytest |
| refactor | Surgical code refactoring without behavior changes; Simplification Mode (Chesterton's Fence); Performance Mode (Measure First) | refactor, code smells, simplification, performance optimization |

### Microsoft & GitHub Skills (5)

| Skill | Description | Triggers On |
|-------|-------------|-------------|
| microsoft-docs | Query official Microsoft documentation | Azure, .NET, Microsoft |
| microsoft-code-reference | Look up Microsoft API references and verify SDK code | Azure SDK, .NET API |
| copilot-sdk | Build agentic apps with GitHub Copilot SDK | Copilot SDK, custom agent |
| gh-cli | GitHub CLI comprehensive reference | gh CLI, GitHub operations |
| github-issues | Create, update, and manage GitHub issues via MCP | create issue, file bug |

### Testing & QA Skills (4)

| Skill | Description | Triggers On |
|-------|-------------|-------------|
| webapp-testing | Test local web apps using Playwright | test webapp, Playwright |
| scoutqa-test | Exploratory QA testing (smoke, accessibility, e-commerce flows) | test website, accessibility |
| agentic-eval | Evaluate and improve AI agent outputs (self-critique, rubrics); Pre-Decision Mode (5-step: CLAIM→EXTRACT→DOUBT→RECONCILE→STOP) | evaluate agent, quality loop, pre-decision |
| debug | Systematic debugging for build/test failures, unexpected behavior, drift errors; escalates after 2 failed cycles | debug, fix build, tests failing, investigate failure |

### Security & Review Skills (1)

| Skill | Description | Triggers On |
|-------|-------------|-------------|
| security-review | Security checklist for auth, input handling, secrets, payments; CSO 雙模式 (Quick Gate 0-10 self-score + Deep Scan OWASP Top 10) | security review, auth check, CSO, OWASP |

### Content & Visualization Skills (4)

| Skill | Description | Triggers On |
|-------|-------------|-------------|
| excalidraw-diagram-generator | Generate Excalidraw diagrams from natural language | create diagram, flowchart |
| markdown-to-html | Convert Markdown to HTML (GFM, CommonMark) | convert markdown, render md |
| web-design-reviewer | Visual inspection of websites to find and fix design issues | review design, check UI |
| chrome-devtools | Browser automation, debugging, performance via Chrome DevTools MCP | DevTools, browser debug |

### Skills Usage

**GitHub Copilot CLI**:
```
/skill-name              # Direct invocation
/skills list             # List all available skills
> I want to generate spec   # Auto-loads matching skill
```

**Codex CLI**:
```
$skill-name              # Direct invocation (dollar prefix)
/skills                  # Browse and activate skills
> I want to generate spec   # Auto-loads matching skill
```
> ⚠️ Codex CLI uses `$skill-name` (dollar), not `/skill-name` (slash).

**Claude Code**:
```
/skill-name              # Direct invocation
/agents                  # Manage and select custom sub-agents
claude --agent <name>    # Launch with specific agent from CLI
> I want to generate spec   # Auto-loads matching skill
```

**Antigravity CLI**:
```
> I want to generate spec   # Auto-activates matching skill via description
```
Skills in `.agents/skills/` are discovered automatically; the model activates them based on description.

---

### Template Maintenance Tools (1)

> ⚠️ **Not deployed to adopter projects.** The following skills are for maintainers of this template repository only. They verify sync parity between source folders and `.github/**` — checks that are meaningless outside the template repo itself.

| Skill | Description | Triggers On |
|-------|-------------|-------------|
| gate-check | Deterministic pre-review gate: source vs `.github/**` sync drift + catalog parity + build/lint/test | gate check, check sync drift, check catalog parity |

---

### Source-of-truth vs runtime locations
- **Source-of-truth (editable):** top‑level folders: `agents/`, `instructions/`, `prompts/`, `skills/`, and `copilot-instructions.md`.
- **Portable runtime (multi-CLI):** shared `skills/`, shared `agents/`, `.agents/skills/`, `.claude/skills/`, `.agent/skills/` (legacy Antigravity compat), generated `.codex/agents/`, generated `.claude/agents/`, plus `AGENTS.md` / `CLAUDE.md` / `GEMINI.md` (Antigravity CLI project context).
- **Legacy runtime (GitHub Copilot / VS Code compatibility):** `.github/agents/`, `.github/instructions/`, `.github/prompts/`, `.github/skills/`, and `.github/copilot-instructions.md`.

The `.github/**` copies are generated for tools that only read instruction files under `.github/`. Bootstrap installs both layers.

### Ownership classes in adopter repos
- **Template-managed:** top-level `skills/`, top-level `agents/`, `.github/instructions/`, `.github/prompts/`, `.github/copilot-instructions.md`, `.gitattributes`, `.editorconfig`.
- **Project-owned:** `AGENTS.md`, `CLAUDE.md`, `GEMINI.md` (Antigravity CLI project context).
- **Derived runtime:** `.github/skills/`, `.github/agents/`, `.agents/skills/`, `.claude/skills/`, `.agent/skills/`, `.codex/agents/`, `.claude/agents/`.

Operational rule:
- Edit shared workflow customizations in `skills/` or `agents/`.
- Do not hand-edit derived runtime files; bootstrap regenerates them.
- Commit `.ai-workflow-install.json` so `bootstrap --update` can tell whether a template-managed file is still safe to refresh or has already been forked by the project.

### Deployed constitution vs maintainer constitution
- **`copilot-instructions.md`** — Maintainer version. Contains SSOT sync rules and template-repo-specific instructions. Used by `sync-dotgithub.ps1` to update this repo's own `.github/copilot-instructions.md`.
- **`docs/copilot-instructions.template.md`** — Adopter version. Strips the sync rules (irrelevant in adopter repos). This is what `bootstrap` deploys to adopter projects' `.github/copilot-instructions.md`.

## When you change instructions
After editing any file under `agents/`, `instructions/`, `prompts/`, `skills/`, or `copilot-instructions.md`,
run the sync script to update `.github/**`:

```powershell
pwsh -File .\tools\sync-dotgithub.ps1
pwsh -File .\tools\check-sync.ps1
```

## Usage in other repositories
To deploy this template into another repo, run bootstrap from the target project directory:

```powershell
# Download and run (auto-fetches from GitHub)
Invoke-WebRequest -Uri "https://raw.githubusercontent.com/forgivesam168/ai-dev-workflow/main/scripts/bootstrap.ps1" -OutFile "bootstrap.ps1"
pwsh -ExecutionPolicy Bypass -File .\bootstrap.ps1
Remove-Item bootstrap.ps1

# To update an existing project
Invoke-WebRequest -Uri "https://raw.githubusercontent.com/forgivesam168/ai-dev-workflow/main/scripts/bootstrap.ps1" -OutFile "bootstrap.ps1"
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
