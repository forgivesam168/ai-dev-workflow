---
name: gate-check
description: >
  For ai-dev-workflow template maintainers only. Do not trigger during normal development workflow.
  Deterministic pre-review gate that verifies source vs .github/** sync parity and catalog counts
  before committing changes to the template repo itself.
  Triggers on: "gate check", "run gate", "pre-review check", "verify before review",
  "check sync drift", "check catalog parity". Reports GATE PASSED / GATE PASSED WITH NOTES / GATE FAILED.
---

# Gate-Check Skill

Deterministic automated quality gate. Runs before `agentic-eval` and `code-reviewer`. Hard failures stop the pipeline.

## ⚠️ Scope

**This skill is for ai-dev-workflow template maintainers only.**

It verifies sync parity between the `skills/`, `agents/`, `instructions/`, `prompts/` source folders
and the generated `.github/**` copies — checks that are only meaningful inside the template repository itself.

If you are using this template in your own project (via `bootstrap.ps1` or `install-apply.ps1`),
`gate-check` is **not deployed** to your project. You do not need it and should not trigger it.

## Verdict Semantics

| Verdict | Meaning | Action |
|---------|---------|--------|
| `GATE PASSED` | All required checks pass; no blocking issues | Proceed to `agentic-eval` → `code-reviewer` |
| `GATE PASSED WITH NOTES` | Required checks pass; non-blocking warnings present | Log warning to `02-decision-log.md`, then proceed |
| `GATE FAILED` | One or more required checks failed | **STOP. Do not proceed to agentic-eval or code-reviewer. Resolve failures first.** |

### Concrete Examples

**GATE PASSED**
> Managed `.github` destinations: no drift. Catalog parity: 9 agents / 10 prompts / 35 total skills / 34 adopter skills / 1 maintainer-only skill. → `GATE PASSED`

**GATE PASSED WITH NOTES**
> Catalog check: 36 total skills found, expected 35. A new skill was added without updating the reviewed contract.
> → `GATE PASSED WITH NOTES` — update the 35/34/1 catalog contract in the same reviewed change; log to `02-decision-log.md`.

**GATE FAILED**
> `check-sync.ps1` reports drift: `.github/agents/coder.agent.md` is out of date with source.
> → `GATE FAILED` — run `pwsh -File .\tools\sync-dotgithub.ps1` and re-run gate-check.

## Minimum Check Set

| Check | Required? | Command / Method |
|-------|-----------|-----------------|
| Managed source vs `.github` destinations | **Required** | `pwsh -File .\tools\check-sync.ps1` (read-only; exit code 0 = clean) |
| Catalog count parity | **Required** | `pwsh -File .\tools\audit-catalog.ps1` (exit code 0 = clean) |
| Python bootstrap tests | **Required** | pytest 8.3.5 |
| PowerShell bootstrap/tool tests | **Required** | Pester 5.6.1 |
| Diff hygiene | **Required** | `git diff --check` |
| Worktree invariant | **Required** | `git status --porcelain=v1` unchanged before/after |

The gate never installs dependencies or repairs drift. Missing pytest or Pester is reported as `ENVIRONMENT_PREREQUISITE_MISSING` and stops with a nonzero exit code. CI is responsible for preparing the pinned test environment.

Every required check above must pass for `GATE PASSED`. The gate does not install missing prerequisites or repair drift.

## Boundary: gate-check vs agentic-eval

| Dimension | gate-check | agentic-eval |
|-----------|-----------|-------------|
| Nature | **Deterministic** (script exit codes, file diff) | **Model-based** (rubric scoring, judgment) |
| Failure type | Hard binary FAIL (exit ≠ 0) | Dimensional FAIL (rubric score below threshold) |
| When it runs | Before agentic-eval | After gate-check passes |
| Iteration | No iteration (fix and re-run) | Max 2 iterations at stage gates |
| Who resolves | Implementer (fix the code/sync) | Agent (self-correct) or human (escalation) |

`gate-check` catches objective failures. `agentic-eval` catches subjective quality gaps. They are complementary, not redundant.

## Three-Layer Ordering at Code→Review Handoff

```
1. gate-check          (deterministic; GATE FAILED = STOP)
       ↓
2. agentic-eval        (model-based; max 2 iterations at stage gate; unresolved → escalate to human)
       ↓
3. code-reviewer-agent (delegated review; independent Tier 2 gate)
```

Skipping `gate-check` or proceeding past `GATE FAILED` is a protocol violation.

## `GATE PASSED WITH NOTES` Escalation Path

When the verdict is `GATE PASSED WITH NOTES`:

1. Record the note in `changes/<slug>/02-decision-log.md` (append-only):
   ```
   ## Gate-Check Note — <date>
   - Check: <check name>
   - Finding: <brief description>
   - Decision: <proceed / defer / fix>
   ```
2. Proceed to `agentic-eval` after logging.
3. Do NOT suppress or silently ignore the note.

## Hard-Stop Enforcement

Execution mode: **hard-fail** — `run-gate-check.ps1` exits nonzero on any required-check failure, and maintainer CI runs the same gate. Whether a failing workflow blocks merging remains a repository branch-protection setting outside this script.
