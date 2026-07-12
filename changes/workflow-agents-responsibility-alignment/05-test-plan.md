# 05 Test Plan — Workflow–AGENTS Responsibility Alignment

## Status

This is the approved architecture test strategy. Tests are planned, not executed by this documentation stage.

## Test Principles

- Test observable ownership, preservation, lifecycle, and generated-output behavior.
- Prove negative behavior: no overwrite, no policy leakage, no implicit authorization, no silent reset, and no automatic prune.
- Run targeted tests per phase before the complete maintainer gate.
- Compare Python and PowerShell behavior with equivalent fixtures.
- Run cross-platform behavior on Windows and Ubuntu where path, link, shell, or generated output differs.
- Never update expected files merely to make a failing test pass; inspect the semantic change first.

## Phase 0 Containment Tests

### Constitution Distribution

| Scenario | Expected evidence |
|---|---|
| New adopter | Installed constitution equals adopter source and excludes maintainer sync/catalog policy. |
| Existing untouched | Migration occurs only when a trusted existing manifest records a verifiable previous managed baseline for the exact constitution component and current content equals it. |
| Existing customized | File remains byte-for-byte unchanged; report identifies customization. |
| Legacy/unknown | File remains unchanged; report requires manual decision. |
| Source selection | Diagnostic/manifest evidence identifies adopter source, not maintainer `.github` mirror. |
| Insufficient untouched proof | Absent component baseline, missing/corrupt/unsupported manifest, unclear source identity, similarity-only evidence, reconstructed/guessed baseline, customization, or unknown ownership produces preserve → report → manual decision. |

### Bash Safety

| Scenario | Expected evidence |
|---|---|
| Existing adopter + `bootstrap.sh --update` | Nonzero refusal before any target write. |
| Deprecated initial install retained | Warning shown and supported Python command provided. |
| Linux/macOS guidance | Documentation and output point to Python installer. |
| Worktree/fixture invariant | Before/after file inventory and hashes are identical on refused update. |

### Manifest Parse Safety Containment — Phase 0C

| Scenario | Expected evidence |
|---|---|
| Corrupt existing manifest + update | Hard stop before managed-file write. |
| Unsupported manifest + update | Hard stop with actionable compatibility message. |
| Missing legacy manifest | Warning + report-only; distinct from parse failure. |

For every Phase 0C failure fixture, Python and PowerShell must prove no managed-file write occurs after failure detection. These tests do not emit a new schema or exercise Archive behavior.

### Archive Authorization Containment — Phase 0D

| Scenario | Expected evidence |
|---|---|
| Archive without write approval | No Git mutation or remote action attempted. |
| Protected Archive action | Commit, push, tag, merge, branch deletion, and remote issue/PR closure each require separate task-scoped authorization. |

Phase 0D tests preserve current Archive filenames and lifecycle timing and do not exercise manifest handling or Hybrid lifecycle behavior.

## Risk-Mode Contract Tests

| Mode | Scenario | Expected behavior |
|---|---|---|
| Simple | Localized documentation or isolated reversible fix | Lightweight A/B/C/D; targeted verification; no mandatory Change Package or six-stage flow. |
| Standard | Multi-file feature with one plan SSOT | Selected stages and explicit verification; compact package only when a trigger applies. |
| Standard + package trigger | Cross-session/component, contract, independent review, migration/audit, or escalation-prone work | Compact Change Package required. |
| High-Risk | Auth/security/financial/migration/breaking/deployment/production/major architecture | Full Workflow and package, explicit approvals, independent review, rollback/migration/operational evidence. |
| Escalation | Simple/Standard crosses a higher-risk boundary | Current mode stops and reclassifies before further implementation. |

Assertions:

- No canonical lifecycle owner emits `Fast Path` as an execution mode.
- Every representative scenario selects exactly one mode.
- Missing reliable verification prevents Simple classification.

## Agent / Skill / Prompt / Instruction Tests

### Thin-Agent Structural Contract

The checker must report:

- persona present;
- specialist lens present where applicable;
- scope boundary present;
- handoff/delegation intent present;
- paired Skill reference present;
- prohibited full methodology absent;
- detailed rubric absent;
- full Workflow absent;
- Global governance absent;
- Git/remote authorization policy absent.

`≤25 non-empty lines` produces a soft warning only. A prohibited responsibility produces a hard failure.

### Methodology Ownership

- Each stage methodology has one canonical Skill owner.
- Agents and Prompts reference rather than duplicate the methodology.
- Instructions contain only path/language/domain-scoped deltas.
- Workflow stages and mode semantics originate only from the canonical Workflow contract; the adopter-facing projection is selected in Phase 3.

### Lifecycle Distribution Contract

- Phase 3 tests are blocked until the adopter-facing lifecycle source design is approved after maintainer/adopter difference review.
- Fixtures must prove the installed lifecycle contract comes from the approved adopter-facing source/projection, not from an unreviewed assumption that root maintainer `WORKFLOW.md` is directly distributable.
- Fixtures must prove maintainer-only lifecycle content is absent and that lifecycle/mode/quality semantics remain equivalent to the canonical contract.
- No test predetermines a filename or path for the adopter-facing source.

### Generated Runtime Parity

- Generated Agent representations preserve name, persona, lens, scope, handoff intent, and paired Skill pointers.
- Generated mirrors contain no content absent from canonical source except format adapters.
- Catalog counts and maintainer-only exclusions remain correct.
- D-10 unverified adapter behavior is not asserted as supported.

## Change Package Tests

| Scenario | Expected behavior |
|---|---|
| External tracker declared | Package stores tracker pointer, decisions, and evidence; no duplicate progress status. |
| No external tracker | `04-plan.md` explicitly declares whether it is task/status SSOT. |
| Legacy `05-review.md` | Recognized as Review semantic role. |
| Future alias | Semantic role resolver can support an approved alias without invalidating history. |
| File exists but invalid/empty | Stage is not complete solely because filename exists. |
| Simple task | No package required. |
| High-Risk task | Full required artifact/evidence contract enforced. |

Current verifier behavior is baseline evidence only. The implementation must not distort the approved contract merely to satisfy the old verifier.

## Archive / Closeout Tests

| Scenario | Expected behavior |
|---|---|
| Simple | No Archive required. |
| Standard with package | Pre-merge lifecycle closeout can be included in original PR. |
| High-Risk | Pre-merge closeout required. |
| Merge evidence | PR/release/issue is treated as authoritative actual merge evidence. |
| Deployment/migration | Separately authorized post-merge operational validation record required. |
| Archive request only | No commit, push, tag, merge, branch deletion, or remote closure. |
| Historical artifact | Existing Archive filename remains readable. |

## agentic-eval Tests

- Simple mode does not require `agentic-eval`.
- Standard triggers only when the approved risk condition applies.
- High-Risk invokes only explicitly named gates.
- Blocking failures cite an approved blocking dimension.
- Warning-only dimensions do not silently become hard gates.
- Self-evaluation cannot override deterministic failure.
- Independent code/security review remains required after self-evaluation where the mode requires it.

Proposed named-gate coverage:

- architecture decision exit;
- pre-implementation readiness;
- pre-delivery verification;
- migration/deployment readiness.

## Manifest and Migration Fixtures

Required fixtures:

1. Valid schema v1.
2. Valid schema v2.
3. Missing manifest.
4. Corrupt JSON.
5. Unsupported schema version.
6. Untouched managed component.
7. Customized project fork.
8. Project-owned guidance.
9. Derived Agent/Skill runtime.
10. Canonical rename.
11. Canonical delete.
12. Modified stale derived output.
13. Unmodified stale derived output.
14. Explicitly approved safe prune.

Required assertions:

- v1/v2 remain readable during migration.
- corrupt/unsupported update stops before writes.
- missing legacy manifest is report-only.
- previous baseline, observed hash, new source hash, source version, ownership, fork status, `generated_from`, and retirement state survive round-trip once schema is approved.
- rename/delete produces a dry-run stale report.
- safe prune is impossible without every D-05 condition and task-scoped approval.
- unknown/customized/legacy content is never automatically deleted.

## Installer Tests

### Python / PowerShell Parity

- Same ownership classifications.
- Same new/untouched/customized/legacy outcomes.
- Same constitution source.
- Same manifest failure policy.
- Same derived generation inputs and output semantics.
- Same stale detection and safe-prune eligibility.
- Same maintainer-only exclusions.

### Bash Contract

- `--update` refusal.
- Deprecation warning.
- Python migration command.
- No independent manifest/update logic after deprecation completion.

## Cross-CLI Evidence Backlog

D-10 tests are deferred until current official evidence is collected:

- repository/global AGENTS or rule loading;
- Skill locations and invocation;
- custom-agent support and format;
- wrapper/import behavior;
- unsupported-capability fallback;
- canonical lifecycle/quality semantic preservation.

Codex and Antigravity capability assertions remain **Not observed**. Evidence collection must precede implementation tests.

## Windows / Ubuntu Matrix

| Area | Windows | Ubuntu |
|---|---:|---:|
| Python installer tests | Required | Required |
| PowerShell installer/tests | Required | Required where current CI supports pwsh |
| Path identity | Required | Required |
| Symlink/copy fallback | Required | Required |
| Bash refusal/deprecation | Optional syntax check | Required |
| Generated text normalization | Required | Required |
| Manifest migration fixtures | Required | Required |
| Full maintainer gate | Required | Required |

## Phase Exit Verification

Every implementation phase must run:

1. Targeted tests for the changed contract.
2. Python installer suite when bootstrap Python is affected.
3. PowerShell installer/tool suite when PowerShell or generation is affected.
4. Catalog and sync checks when canonical workflow assets change.
5. `git diff --check`.
6. Worktree invariance check around read-only gates.
7. Independent review appropriate to phase risk.

Unavailable checks must be reported with reason and exact follow-up command; they must not be silently skipped.
