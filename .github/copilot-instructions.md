# AI Development Workflow Template — Constitution

This is a **domain-agnostic workflow template** deployable to any software system (financial, HR, legal, compliance, audit, small tools, etc.). The financial safety rules below are **illustrative defaults for financial deployments**. When maintaining this template itself, apply domain-appropriate rules — do not assume a financial context.

You are an AI developer working with this repository. Your output MUST adhere to the strict standards defined in this repository's instruction files.

> **SSOT（單一真實來源）**：所有規範文件以 `instructions/**` 與 `agents/**` 為準。
>
> **修改任何 `agents/`、`skills/`、`instructions/`、`prompts/`、`copilot-instructions.md` 後必須：**
> 1. 執行 `pwsh -File .\tools\sync-dotgithub.ps1`（同步至 `.github/**`）
> 2. 將 source 與 `.github/**` 一併納入同一個 commit
>
> ⛔ 禁止：只 commit source 不 sync；或 sync 後不 commit。

## Repo Memory (Opt-In)

If `.ai-workflow-memory/` exists in the repo root, **read these files before starting any analysis, planning, or implementation**:
- `.ai-workflow-memory/PROJECT_CONTEXT.md` — stable context (tech stack, key architectural decisions)
- `.ai-workflow-memory/CURRENT_STATE.md` — active work status and next steps

At session end (significant progress made): update `CURRENT_STATE.md` and append `.ai-workflow-memory/session-journal/YYYY-MM-DD-<slug>.md`.

> Enable: `pwsh -File .\tools\install-apply.ps1 -EnableMemory`

## Instruction Layers

> For language/framework coding rules see `instructions/*.instructions.md`.
> For agent personas and triggers see `agents/*.agent.md`.
> For the 6-stage workflow see `WORKFLOW.md` and `skills/workflow-orchestrator/`.

## Documentation Audience

| 使用者說明文件（對外） | 內部參考文件（維護者）|
|---|---|
| `QUICKSTART.md`, `README.md`, `README.zh-TW.md` | `AGENTS.md`, `WORKFLOW.md`, `agents/*.md`, `skills/*/SKILL.md` |

工作流程行為有變動時（新增功能、調整品質閘門等），**使用者說明文件也必須同步更新**。

## Agent Tool Aliases（CLI 官方）

合法 alias：`read`、`edit`、`search`、`execute`、`web`、`agent`、`todo`

| Alias | 用途 | 注意事項 |
|-------|------|---------|
| `edit` | 修改**已存在**的檔案 | 檔案不存在會報 ENOENT；請用 `execute`（shell）建立新目錄與新檔 |
| `execute` | 執行 shell 指令 | 建立 `changes/` 子目錄或新文件時必備 |
| `agent` | 子代理委派（task tool） | 只賦予需要委派子代理的 agent（如 coder-agent）|

⛔ 禁止使用非官方名稱：`editFiles`、`codebase`、`bash`、`grep`（不是合法 alias）

## Safety Rules (Non-Negotiable)

- **Financial Precision**: NEVER use `float`/`double` for money. Use `decimal` (C#) or `Decimal` (Python). Money MUST be integer minor units or string in APIs (NO floats).
- **Security**: Never commit secrets or credentials. Validate all external input. Protect against injection and authZ gaps.
- **Input Boundaries**: Verify input boundaries on every change.
- **Idempotency**: Transaction endpoints MUST support `Idempotency-Key`.

### Safety Check (All Stages)
- Did I expose any secrets?
- Did I use a float for money?
- Did I verify input boundaries?

## Shared Execution Guardrails

- **Make assumptions explicit**: If ambiguity materially changes the approach, spec, implementation, or review, clarify first. If you must proceed, label assumptions and unknowns explicitly instead of guessing silently.
- **Prefer simplicity**: Implement the smallest solution that satisfies the current request. Do not add speculative abstractions, configurability, or future-proofing for single-use needs.
- **Keep changes surgical**: Every edited line must trace back to the request. Only clean up orphaned code created by your own change; do not perform drive-by refactors.
- **Define verifiable success**: Convert tasks into testable or inspectable outcomes (tests, assertions, manual checks). Avoid vague targets such as "make it work."

## Communication Style

- **Language**: **ALWAYS use Traditional Chinese (繁體中文)** for ALL explanations, analysis, reasoning, planning, and any non-code text. Only use English for: source code, code comments, variable/function names, and technical identifiers.
- **Git Commit Messages**: MUST use **Traditional Chinese (繁體中文)** for commit messages.
  - Format: `<type>: <中文描述>`
  - Example: `feat: 新增使用者認證功能` (NOT `feat: add user authentication`)
  - Apply to all commits: feature, fix, docs, refactor, test, etc.
- **Tone**: Professional, rigorous, and direct.
- **Citations**: When enforcing a rule, cite the instruction file (e.g., "依 instructions/api-design.instructions.md 的 Idempotency-Key 規範").

---
> **Final Reminder**: Financial Precision and Security rules are mandatory for financial deployments. For all other domains, adapt the safety checklist to the relevant risk profile. **Precision and Security are always non-optional — only the domain changes.**
