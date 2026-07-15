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

### Standalone Fallback Rules

Use these rules whenever no user-level Global AGENTS is available. They are the minimum portable safety contract; project-specific rules may add stricter requirements without weakening this baseline.

1. **Evidence and uncertainty**: Base material conclusions on repository evidence, tool output, or other verifiable evidence. Distinguish facts, assumptions, inferences, and unknowns. Never fabricate status, test results, sources, or completion evidence.
2. **Material assumptions**: Before modification, disclose assumptions that affect scope or contract, security, data, migration, or verification. Stop and request clarification when different answers would materially change the implementation path.
3. **Project context and SSOT**: First read the context, architecture, and task/status SSOT named by Project AGENTS. Resolve conflicts among conversation or plan, spec, code, and project vocabulary using the project's precedence rules; stop when the conflict cannot be resolved.
4. **Surgical scope control**: Change only the minimum content required within the currently approved scope. Do not perform drive-by refactors, unrelated formatting, speculative abstractions, unrequested features, or cross-phase implementation.
5. **Secrets and sensitive data**: Do not unnecessarily read, display, commit, or write secrets, credentials, tokens, PII, or sensitive data. If sensitive content is found, stop the exposure path, redact the report, and keep it out of artifacts, logs, commits, and remote content.
6. **Protected-action authorization**: Commit, push, merge, tag, release, branch deletion, remote Issue or PR closure, deployment, production operations, destructive actions, and other remote mutations require explicit, current-task, action-specific authorization. One approval cannot imply another action's approval; tool availability or Agent identity is not authorization.
7. **Verification and deterministic blockers**: Define verifiable success before implementation. Before completion, run applicable targeted tests, required full checks, static checks, and project gates. A known test or build, lint, security, data-integrity, or deterministic gate failure is blocking and cannot be overridden by prose review, self-evaluation, or inference.
8. **Risk escalation and rollback**: Stop and escalate the execution mode when work crosses auth, security, financial, migration, public-contract, destructive, deployment, production, irreversible, or difficult-to-verify boundaries. Non-simple reversible work requires risk-proportionate rollback or restore, compensation, or safe-stop guidance.
9. **Honest completion**: Claim completion only when the approved scope is complete, required verification has evidence, and delivery state is accurate. Distinguish unverified, unmerged, partial, Deferred, blocked, N/A, and user-decision-dependent work from Complete.

## Project-Specific Operating Defaults

These concrete defaults extend the fallback contract for this template repository; they are not a second fallback rule set.

- **Context loading**: If `.ai-workflow-memory/PROJECT_CONTEXT.md` exists, load it before technical decisions; otherwise load `docs/CONTEXT.md` when present. Do not let conversation context silently override project context.
- **Implementation discipline**: Prefer the smallest clear solution, match existing style and boundaries, and remove only artifacts made obsolete by the current change. For bug fixes, reproduce first when practical; for multi-step work, state a short plan with verification.
- **Input and domain safety**: Validate external input at system boundaries. For money, never use `float` or `double`; use decimal types, integer minor units, or strings at API boundaries. Retriable transactions require idempotency support such as `Idempotency-Key`.
- **Communication**: Use Traditional Chinese for explanations, analysis, reasoning, planning, and commit messages. Use English for source code, code comments, and technical identifiers unless the file already uses another convention. Cite the governing file when enforcing a repository-specific rule.

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
4. **Quality Gate** — risk-adaptive `agentic-eval`, deterministic project gates, and independent review as required by `WORKFLOW.md`

Operational rule:
- **Always-on essence** lives in `copilot-instructions.md` + core agent body text
- **Manual fallback** lives in `/execution-guardrails`
- **Self-evaluation patterns** live in `agentic-eval`; named High-Risk gate semantics live in `WORKFLOW.md`

### agentic-eval and named High-Risk gates

`agentic-eval` is risk-adaptive self-evaluation, not independent review. It cannot override test, build, or deterministic gate failure and never replaces required independent code/security review.

- Simple: `agentic-eval` is not required.
- Standard: use it only when a risk condition triggers it.
- High-Risk: use the four rule-based gates below in the order and with the full blocking conditions defined by `WORKFLOW.md`.

| Named gate | Applies before | Blocking summary |
|---|---|---|
| Architecture Decision Exit | irreversible or high-cost architecture, security, permission, data, or public-contract commitment | unresolved safety/authorization or contract boundary, unsupported source/assumption, or irreversible decision without rollback/migration/compensation |
| Pre-Implementation Readiness | every High-Risk implementation | unresolved AC/scope/decision/prerequisite, missing approval or executable recovery path, no verifiable RED/GREEN path, or unclear ownership |
| Pre-Delivery Verification | every High-Risk commit, push, PR, or merge | deterministic failure, missing AC evidence, invariant failure, scope/generated/worktree drift, or missing independent review/unresolved Critical or High |
| Migration / Deployment Readiness | separately authorized migration, deployment, production, or irreversible-data execution | missing action-specific approval, bounded target, recovery path, rehearsal/operational signal, or ownership/reversibility evidence |

Deterministic failure is always blocking. Warning-only findings must be recorded but cannot be promoted to blocking without new evidence matching an approved blocking condition. Resolve blocking findings before the next gate. N/A requires an auditable reason; for out-of-scope operational execution record `N/A — no migration or deployment execution is authorized in this Phase.` The named gates use no aggregate score or numeric threshold; future gates, blocking dimensions, or aggregate thresholds require separate approval.

> Detailed conditions are canonical in [`WORKFLOW.md`](./WORKFLOW.md); supporting self-evaluation patterns are in [`skills/agentic-eval/SKILL.md`](./skills/agentic-eval/SKILL.md).

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
| agentic-eval | Evaluate and improve AI agent outputs (self-critique, rubrics); General-Purpose Pre-Decision Mode (5-step: CLAIM→EXTRACT→DOUBT→RECONCILE→STOP) | evaluate agent, quality loop, pre-decision |
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
- For Simple changes: use only the stages needed for lightweight Understand / Implement / Prove / Deliver and targeted verification; no six-stage flow or Change Package is mandatory
- For Standard changes: use selected stage exits and exactly one plan/lifecycle SSOT; require a compact Change Package only when a canonical trigger applies
- For High-Risk changes: use the full Workflow and Change Package, named gates, explicit approvals, independent review, and rollback/migration/operational evidence
- See `WORKFLOW.md` for the full flow and skip rules.
