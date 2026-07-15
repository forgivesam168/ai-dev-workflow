# Project AI Workflow Guide

> 這份 `AGENTS.md` 是專案共用規則的唯一來源；`CLAUDE.md` / `GEMINI.md` 只做薄包裝並指回這裡。

## Constitutional Baseline

> 某些 CLI 不會把 `copilot-instructions.md` 視為 always-on 憲法，因此這一節是專案在 Codex / Claude Code / Antigravity / Copilot 間共用的可攜憲法層。

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

These concrete defaults extend the fallback contract for adopter projects; they are not a second fallback rule set.

- **Context loading**: If `.ai-workflow-memory/PROJECT_CONTEXT.md` exists, load it before technical decisions; otherwise load `docs/CONTEXT.md` when present. Do not let conversation context silently override project context.
- **Implementation discipline**: Prefer the smallest clear solution, match existing style and boundaries, and remove only artifacts made obsolete by the current change. For bug fixes, reproduce first when practical; for multi-step work, state a short plan with verification.
- **Input and domain safety**: Validate external input at system boundaries. For money, never use `float` or `double`; use decimal types, integer minor units, or strings at API boundaries. Retriable transactions require idempotency support such as `Idempotency-Key`.
- **Communication**: Use Traditional Chinese for explanations, analysis, reasoning, planning, and commit messages. Use English for source code, code comments, and technical identifiers unless the file already uses another convention. Cite the governing file when enforcing a project-specific rule.

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
- `agentic-eval` is risk-adaptive self-evaluation, not independent review. It cannot override test, build, or deterministic gate failure and never replaces required independent code/security review.
- Simple does not require `agentic-eval`; Standard uses it only when risk-triggered; High-Risk uses the four rule-based gates below.

| Named High-Risk gate | Applies before | Blocking summary |
|---|---|---|
| Architecture Decision Exit | irreversible or high-cost architecture, security, permission, data, or public-contract commitment | unresolved safety/authorization or contract boundary, unsupported source/assumption, or no viable rollback/migration/compensation |
| Pre-Implementation Readiness | every High-Risk implementation | unresolved AC/scope/decision/prerequisite, missing protected-action approval or recovery plan, no verifiable RED/GREEN path, or unclear ownership |
| Pre-Delivery Verification | every High-Risk commit, push, PR, or merge | deterministic failure, missing AC evidence, invariant failure, scope/generated/worktree drift, or missing independent review/unresolved Critical or High |
| Migration / Deployment Readiness | separately authorized migration, deployment, production, or irreversible-data execution | missing action-specific approval, bounded target, recovery path, rehearsal/operational signal, or ownership/reversibility evidence |

Deterministic failure is always blocking. Warning-only findings must be recorded but cannot be promoted to blocking without new evidence matching an approved blocking condition. Resolve blocking findings before the next gate. N/A requires an auditable reason; when operational execution is outside scope record `N/A — no migration or deployment execution is authorized in this Phase.` Named High-Risk gates use no aggregate score or numeric threshold; future gates, blocking dimensions, or aggregate thresholds require separate approval.

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

## Lifecycle Stage Reference

High-Risk work follows the full six-stage lifecycle. Standard work uses the stages selected by its declared lifecycle contract; Simple work uses a lightweight plan and verification path without a mandatory six-stage flow or Change Package.

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
