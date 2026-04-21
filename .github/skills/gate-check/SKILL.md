---
name: gate-check
description: >
  Deterministic pre-review gate that runs automated checks before handing off to agentic-eval or code-reviewer.
  Use before any stage transition (code→review, plan→code, spec→plan) to catch hard failures early.
  Triggers on: "gate check", "run gate", "pre-review check", "verify before review", "check build",
  "check sync drift", "check catalog parity". Reports GATE PASSED / GATE PASSED WITH NOTES / GATE FAILED.
---

# Gate-Check Skill

Deterministic automated quality gate. Runs before `agentic-eval` and `code-reviewer`. Hard failures stop the pipeline.

## Verdict Semantics

| Verdict | Meaning | Action |
|---------|---------|--------|
| `GATE PASSED` | All required checks pass; no blocking issues | Proceed to `agentic-eval` → `code-reviewer` |
| `GATE PASSED WITH NOTES` | Required checks pass; non-blocking warnings present | Log warning to `02-decision-log.md`, then proceed |
| `GATE FAILED` | One or more required checks failed | **STOP. Do not proceed to agentic-eval or code-reviewer. Resolve failures first.** |

### Concrete Examples

**GATE PASSED**
> Source vs `.github/**` drift check: no drift. Catalog parity: 6/10/28 match. → `GATE PASSED`

**GATE PASSED WITH NOTES**
> Catalog check: 30 skills found, expected 28. New skills were added intentionally (Phase 3 delivery). Constant not yet updated.
> → `GATE PASSED WITH NOTES` — update `$ExpectedSkillCount` in `audit-catalog.ps1`; log to `02-decision-log.md`.

**GATE FAILED**
> `sync-dotgithub.ps1` reports drift: `.github/agents/coder.agent.md` is out of date with source.
> → `GATE FAILED` — run `pwsh -File .\tools\sync-dotgithub.ps1` and re-run gate-check.

## Minimum Check Set

| Check | Required? | Command / Method |
|-------|-----------|-----------------|
| Source vs `.github/**` drift | **Required** | `pwsh -File .\tools\sync-dotgithub.ps1` (exit code 0 = clean) |
| Catalog count parity | **Required** | `pwsh -File .\tools\audit-catalog.ps1` (exit code 0 = clean) |
| TypeScript / PowerShell type-check | Conditional | Run if type-checker is configured in the repo |
| Lint | Conditional | Run if linter is configured |
| Tests | Conditional | Run if test suite is configured |
| Build | Conditional | Run if build step is configured |

Required checks must pass for `GATE PASSED`. Conditional checks are skipped if not configured.

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

Current mode: **Advisory** — gate-check reports `GATE FAILED` and stops the agent's forward progress.
Future graduation criteria for Strict Mode (documented here, not yet enforced):
- All required checks automated in `run-gate-check.ps1`
- CI integration available to block PR merges on gate failure
