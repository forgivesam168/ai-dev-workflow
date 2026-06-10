# Project AI Workflow Guide

> 這份 `AGENTS.md` 是專案共用規則的唯一來源；`CLAUDE.md` / `GEMINI.md` 只做薄包裝並指回這裡。

## Constitutional Baseline

> 某些 CLI 不會把 `copilot-instructions.md` 視為 always-on 憲法，因此這一節是專案在 Codex / Claude Code / Antigravity / Copilot 間共用的可攜憲法層。

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
- Do not let session context override project context silently.

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
- When enforcing a repo-specific rule, cite the governing file so other agents can trace the source.

## Operating Model

> 目標：即使換了 CLI surface，AI agent 的核心體感也不應該明顯漂移。工具介面可以不同，但憲法、角色意圖、方法論入口、交接品質門檻應保持一致。

### Layering

1. `AGENTS.md` — project-wide constitution, workflow contract, and stable cross-CLI operating rules
2. `agents/*.agent.md` — persona identity, role boundaries, and handoff intent
3. `skills/*/SKILL.md` — execution methodology, checklists, templates, and reusable tactics

### Persona vs Behavior

- **Agent = Persona**: define who is doing the work, what role they play, and when to hand off.
- **Skill = Behavior**: define how the work is performed.
- When customizing the workflow, keep persona descriptions thin and move detailed methodology into skills.
- If a CLI cannot load repo-local custom agents, fall back to `AGENTS.md` + the relevant skill without changing the workflow standard.

## Suggested Personas

> 這份清單的目的是讓不同 CLI 對角色分工有相同預期。詳細 persona 內容以 `agents/` 目錄中的實際檔案為準。

| Persona | Primary Role | Typical Skill |
|---------|--------------|---------------|
| `brainstorm` | Clarify requirements, explore options, classify risk | `brainstorming` |
| `architect` | Cross-stage design, tradeoff analysis, ADR framing | `brainstorming` + `context-engineering` |
| `spec` | Turn requirements into spec / PRD / acceptance criteria | `specification` |
| `plan` | Break the spec into executable implementation slices | `implementation-planning` |
| `coder` | Implement changes with TDD discipline | `tdd-workflow` |
| `code-reviewer` | Review correctness, regressions, and security risks | `code-security-review` |
| `pm` | Track stage, route workflow, maintain cross-session continuity | `workflow-orchestrator` |
| `frontend-designer` | UI/UX quality, design-system alignment, accessibility | `frontend-patterns` |
| `dba` | Schema design, query safety, migration review | `sql.instructions.md` |

## Quality Gates

> 這一節只放 adopter 專案需要的輕量政策；完整 rubric 與 maintainer 細節留在 skills 內。

- Use `execution-guardrails` whenever work starts drifting in assumptions, complexity, diff scope, or verification clarity.
- For medium/high-risk spec, plan, implementation, or handoff artifacts, run `agentic-eval` before passing work downstream.
- The review stage should use `code-reviewer` / `code-security-review` as the independent gate before archive or merge.
- Unresolved vocabulary conflicts, hidden assumptions that materially change implementation, or failed verification should block handoff.
- For financial or ledger-like domains, any money-precision violation blocks handoff immediately.

## Project

| Field | Value |
|-------|-------|
| **Name** | <!-- Project name --> |
| **Domain** | <!-- HR / Financial / Legal / etc. --> |
| **Tech Stack** | <!-- Languages, frameworks, DB --> |
| **Test** | <!-- e.g., dotnet test / npm test --> |
| **Build** | <!-- e.g., dotnet build / npm run build --> |

## Shared Runtime Layout

| Surface | Purpose |
|---------|---------|
| `skills/` | Shared skill source for all supported CLIs |
| `.agents/skills/` | Codex / Antigravity skill mount |
| `.claude/skills/` | Claude Code skill mount |
| `.agent/skills/` | Legacy Antigravity compatibility mount |
| `agents/` | Canonical persona source files |
| `.codex/agents/` | Generated Codex custom agents (`.toml`) |
| `.claude/agents/` | Generated Claude custom agents (`.md`) |

## Ownership Rules

- `skills/` and `agents/` are the editable shared workflow baseline for this project.
- `.github/skills/`, `.github/agents/`, `.codex/agents/`, `.claude/agents/`, and the skill mounts are derived runtime. Do not treat them as hand-edited source.
- `AGENTS.md`, `CLAUDE.md`, and `GEMINI.md` are project-owned guidance files.
- Commit `.ai-workflow-install.json` so future `bootstrap --update` runs can preserve project forks while still refreshing template-managed files that remain untouched.

## 6-Stage Workflow

| Stage | Primary Skill | Suggested Persona |
|-------|---------------|-------------------|
| Brainstorm | `/brainstorming` | `brainstorm` |
| Spec | `/specification` | `spec` |
| Plan | `/implementation-planning` | `plan` |
| Implement | `/tdd-workflow` | `coder` |
| Review | `/code-security-review` | `code-reviewer` |
| Archive | `/work-archiving` | — |

## Custom Agent Strategy

- **Portable baseline**: skills + this `AGENTS.md` must be enough to run the workflow even if a CLI does not support repo-local custom agents.
- **Codex**: use generated files under `.codex/agents/`.
- **Claude Code**: use generated files under `.claude/agents/`.
- **Antigravity**: rely on `skills/` + `AGENTS.md` as the default portable path. If you later need native Antigravity agents, package them as a plugin instead of treating `.github/agents` as runtime source.

Use `/workflow` to auto-detect stage. Change packages → `changes/<slug>/`.
