# Implementation Plan: Workflow Template Optimization

**Spec Reference**: `03-spec.md`
**Risk Level**: High
**Workflow Path**: Standard
**Brownfield**: Yes → see `06-impact-analysis.md`

---

## Spec Cross-Eval (Planner Perspective)

| AC | Executable? | Notes |
|----|-------------|-------|
| AC-1 Catalog Truth | ✅ PASS | Clear deliverables: doc diffs + audit script |
| AC-2 Change Package Contract | ✅ PASS | Two known files to compare and align |
| AC-3 Install Surface Spec | ✅ PASS | Four required sections explicitly specified |
| AC-4 Explore Mode Spec | ✅ PASS | Three required sections; trigger list enumerated |
| AC-5 Gate-Check Spec | ✅ PASS | Deliverables, verdict set, min check set all defined |
| AC-6 Repo Memory Spec | ✅ PASS | Directory structure and opt-in rule explicit |
| AC-7 Subagent Status Protocol | ✅ PASS | ⚠️ All 3 target agent files already exceed ≤25 non-empty lines target. AC-7 requires adding ~10+ lines each. Plan mandates compact format (table) to minimize further growth. |
| AC-8 Debug Skill Spec | ✅ PASS | Four required sections explicit; threshold is a fixed number |
| AC-9 Bounded Self-Review | ✅ PASS | Three specific files to update; distinction is clearly scoped |

**Conclusion**: All ACs pass executability. No spec gaps. One implementation constraint flagged on AC-7.

---

## Overview

A staged, brownfield-safe optimization of the AI development workflow template. The approach is **Foundation First**: align governance and platform basics before adding new capabilities. Changes are organized into 5 delivery waves, each independently committable and verifiable.

## Implementation Strategy

**Approach**: Additive and alignment-first. No rewrites of existing core flows.
**Phases**: 5 waves, sequenced with internal dependencies.
**Sync rule**: Run `pwsh -File .\tools\sync-dotgithub.ps1` after every phase that modifies `agents/`, `skills/`, or `instructions/`. Commit source and `.github/**` together.

**NFR compliance notes (apply to all phases)**:
- NFR-02 (no added toolchain complexity): All new surfaces are optional skills and design docs. No new required tools beyond existing `pwsh`. Verification: no new mandatory install steps introduced.
- NFR-03 (additive, brownfield-safe): No existing files deleted; all changes are additions or targeted text appends. Verification: `git diff --stat` for each phase must show only additions or known targeted edits.

---

## Phase 1: Wave 1 — Drift & Truth (Scope A)

**Objective**: Eliminate observable catalog count drift and change-package contract inconsistencies across user-facing and maintainer-facing documentation. Deliver an automated audit tool.

**Covers**: AC-1, AC-2, FR-01, FR-02, FR-03

---

### Task 1.1 — Catalog Count Alignment

**Verification Target (RED)**:
- Define expected counts: **6 agents**, **10 prompts**, **28 skills** (current ground truth from directory listing)
- Identify all locations in `README.md`, `README.zh-TW.md`, `AGENTS.md`, `WORKFLOW.md`, `copilot-instructions.md` that state or imply counts
- Expected finding: at least one count mismatch or stale reference

**Implementation (GREEN)**:
- Files: `README.md`, `README.zh-TW.md`, `AGENTS.md`, `WORKFLOW.md`
- Action: update all count statements to reflect ground truth
- Identify and designate **canonical count source** (AGENTS.md Skills section as SSOT)
- Document the canonical source in AGENTS.md under a new note

**Refactor**:
- Consolidate count statements to a single location per document; remove duplicates
- Where possible, cross-reference AGENTS.md rather than restating the count

**Acceptance Criteria**:
- [ ] `AGENTS.md` states correct counts and is designated canonical source
- [ ] `README.md` and `README.zh-TW.md` counts match AGENTS.md
- [ ] `WORKFLOW.md` does not contradict AGENTS.md on catalog facts

**Verification**: Manual diff; grep for numeric claims (e.g., `28 skills`, `6 agents`, `10 prompts`)

---

### Task 1.2 — Change-Package Contract Alignment

**Verification Target (RED)**:
- List required change-package files per `WORKFLOW.md`
- List required change-package files per `instructions/changes.instructions.md` (source) and `.github/instructions/changes.instructions.md` (mirror)
- Expected finding: file list, naming, or rule descriptions diverge

**Implementation (GREEN)**:
- Files: `WORKFLOW.md`, `instructions/changes.instructions.md`
- Action: reconcile file lists and rules; designate `instructions/changes.instructions.md` as canonical contract
- `WORKFLOW.md` should reference (not duplicate) the canonical contract
- Sync: run `pwsh -File .\tools\sync-dotgithub.ps1`

**Refactor**:
- Remove any inline contract duplication in WORKFLOW.md; replace with a reference

**Acceptance Criteria**:
- [ ] `instructions/changes.instructions.md` and `WORKFLOW.md` agree on required file list and rules
- [ ] Sync passes cleanly after change

**Verification**: Side-by-side diff; `tools/check-sync.ps1` passes

---

### Task 1.3 — Catalog Audit Script

**Verification Target (RED)**:
- No automated way to detect drift currently exists
- Define what "clean audit" means: expected count matches actual directory count; change-package required files are all present in a sample change package

**Implementation (GREEN)**:
- File: `tools/audit-catalog.ps1`
- Responsibilities:
  - Count directories under `agents/`, `skills/`, `prompts/` and compare against expected values stored as script constants
  - Check that `instructions/changes.instructions.md` lists match `WORKFLOW.md` lists (string comparison)
  - Output: table of `[Category] [Expected] [Actual] [Status: PASS/FAIL]`
  - Exit code 0 if all PASS, 1 if any FAIL

**Refactor**:
- Extract expected counts as named constants at the top of the script for easy future updates

**Risk**:
- **Constants drift**: If Phase 3 or Phase 5 adds new skills without updating the script constants, the audit script will report false FAILs. Mitigation: update `$ExpectedSkillCount` constant in the same commit that adds each new skill (Phase 3: 28→30; Phase 5: 30→31). This is enforced as an explicit exit criterion in Phase 3 and Phase 5.

**Acceptance Criteria**:
- [ ] `tools/audit-catalog.ps1` exists and runs without error on PowerShell 7+
- [ ] Script reports PASS for all categories on the current repo state (post-alignment)
- [ ] Script reports FAIL if an agent or skill directory is removed

**Verification**:
```powershell
pwsh -File .\tools\audit-catalog.ps1
# Expect: all PASS
# Test failure path: rename one agent dir temporarily; re-run; expect FAIL
```

---

### Phase 1 Exit Criteria
- [ ] All catalog counts consistent across user-facing docs
- [ ] Change-package contract consistent across WORKFLOW.md and instructions file
- [ ] `tools/audit-catalog.ps1` reports clean on current repo
- [ ] `tools/sync-dotgithub.ps1` passes; changes committed together

---

## Phase 2: Wave 2 — Install Surface Design (Scope B)

**Objective**: Produce a formal design document that defines responsibilities, behaviors, and compatibility constraints for the next-generation install surface. No implementation yet — this is a specification-level deliverable.

**Covers**: AC-3, FR-04, FR-05, FR-06, FR-07, FR-08

---

### Task 2.1 — Install Surface Design Document

**Verification Target (RED)**:
- No `docs/install-surface-design.md` exists
- AC-3 requires four specific sections plus JSON schema sample

**Implementation (GREEN)**:
- File: `docs/install-surface-design.md`
- Required sections:
  1. **`install-plan` behavior**: output format (human-readable table; `--json` flag for machine-readable); what it lists (components, source vs. target diffs); what it does NOT do (no side effects)
  2. **`install-apply` behavior**: conflict resolution (`skip-if-exists` default; `--force` to overwrite); rollback guidance; compatibility with `Init-Project.ps1` as wrapper
  3. **`doctor` behavior**: checks source vs `.github/**` vs deployed-target parity; output aligned with gate-check verdict format (`DOCTOR PASSED / DOCTOR PASSED WITH NOTES / DOCTOR FAILED`)
  4. **JSON manifest minimum schema**:
     ```json
     { "schema_version": 1, "installed_at": "<ISO-8601-UTC>", "source_ref": "<commit-sha-or-tag>", "components": [] }
     ```
     - `schema_version` must be the first field
     - Schema is forwards-compatible: new fields may be added without breaking existing state files (NFR-04)
  5. **Compatibility with `Init-Project.ps1`**: new install surface is additive; `Init-Project.ps1` preserved as compatible entrypoint / wrapper

**Refactor**:
- Add a "Future Scope" section noting what is deferred (multi-harness dist, profile presets)

**Acceptance Criteria**:
- [ ] `docs/install-surface-design.md` exists with all five sections
- [ ] JSON schema sample starts with `"schema_version": 1`
- [ ] Compatibility section references `Init-Project.ps1` by name
- [ ] `--enable-memory` flag opt-in is mentioned (reference to AC-6; detail in `docs/repo-memory-design.md`)

**Verification**: File existence check; manually verify all four AC-3 content requirements are present

---

### Phase 2 Exit Criteria
- [ ] `docs/install-surface-design.md` exists and passes AC-3 verification
- [ ] No sync needed (docs/ is not mirrored to `.github/**`)

---

## Phase 3: Wave 3 — Workflow Enhancements (Scope C)

**Objective**: Add explore mode, deterministic gate-check, and subagent status protocol specifications.

**Covers**: AC-4, AC-5, AC-7, FR-09, FR-10, FR-11, FR-12

---

### Task 3.1 — Explore Mode Skill

**Verification Target (RED)**:
- No `skills/explore/` directory or `SKILL.md` exists
- AC-4 requires three specific sections with enumerated trigger list

**Implementation (GREEN)**:
- File: `skills/explore/SKILL.md`
- Required sections:
  1. **When to enter explore mode**: requirements not yet clear; codebase investigation needed; option comparison in progress; risk scan before commit
  2. **While in explore mode**: no files created until explicit artifact commit signal
  3. **Explicit artifact commit triggers** (enumerated list — no "or equivalent" without list):
     - `/proceed`
     - `"create change package"`
     - `"start brainstorm"`
     - `"I want to formalize this"`
- YAML frontmatter: `name: explore`, `description` with trigger keywords

**Acceptance Criteria**:
- [ ] `skills/explore/SKILL.md` exists with all three sections
- [ ] Trigger list is explicitly enumerated; phrase "or equivalent" does not appear without an accompanying list

**Verification**: File exists; grep `"or equivalent"` in skill file returns no unaccompanied occurrences

---

### Task 3.2 — Gate-Check Skill + Script Stub

**Verification Target (RED)**:
- No `skills/gate-check/` directory exists
- AC-5 requires: SKILL.md with verdict definitions, min check set, boundary definition, three-layer ordering; plus `scripts/run-gate-check.ps1` stub

**Implementation (GREEN)**:
- File 1: `skills/gate-check/SKILL.md`
  - Verdict semantics:
    - `GATE PASSED`: all checks pass → proceed
    - `GATE PASSED WITH NOTES`: non-blocking warnings → log to `02-decision-log.md`, proceed
    - `GATE FAILED`: hard stop → do not proceed to agentic-eval or code-reviewer; resolve first
  - Minimum check set (required/conditional):
    | Check | Required? |
    |-------|-----------|
    | TypeScript/PowerShell typecheck | Conditional (if configured) |
    | Lint | Conditional (if linter configured) |
    | Tests | Conditional (if test suite configured) |
    | Build | Conditional (if build step configured) |
    | Source vs `.github/**` drift (`sync-dotgithub.ps1`) | Required |
    | Catalog count parity (`audit-catalog.ps1`) | Required |
  - Semantic boundary between `gate-check` and `agentic-eval` (table format)
  - Three-layer ordering at **code→review handoff**:
    1. `gate-check` (deterministic; GATE FAILED = stop)
    2. `agentic-eval` (model-based; max 2 iterations; unresolved → escalate to human)
    3. `code-reviewer-agent` (delegated review)
  - One concrete example per verdict
  - `GATE PASSED WITH NOTES` escalation path: append to `02-decision-log.md`, then proceed
  - Hard-stop enforcement (strict mode) deferred; graduation criteria documented here
- File 2: `skills/gate-check/scripts/run-gate-check.ps1`
  - Stub that documents each expected check invocation as a commented section
  - Reports overall verdict to stdout
  - Exit code 0 = GATE PASSED, 1 = GATE FAILED

**Acceptance Criteria**:
- [ ] `skills/gate-check/SKILL.md` exists with all verdict definitions, min check set table, boundary definition, three-layer ordering, and at least one example per verdict
- [ ] `skills/gate-check/scripts/run-gate-check.ps1` exists and documents expected check invocations
- [ ] Source vs `.github/**` drift check and catalog parity check are marked as Required (not conditional)

**Risk**:
- **Partial AC-5 satisfaction**: The gate-check SKILL.md has many required elements (3 verdicts, min check set table, boundary section, three-layer ordering, 1 example per verdict). Any omission fails AC-5. Mitigation: run each `Select-String` verification step sequentially and confirm a match before proceeding to the next; do not mark the task complete until all checks pass.

**Verification**:
```powershell
Test-Path "skills\gate-check\SKILL.md"           # True
Test-Path "skills\gate-check\scripts\run-gate-check.ps1"  # True
```

---

### Task 3.3 — Subagent Status Protocol in Agent Files

**Verification Target (RED)**:
- None of the three agent files contain a "Subagent Status Protocol" section
- AC-7 requires all four states + at least one example per state in all three files

**⚠️ Implementation Constraint**:
- All three target agent files already exceed the ≤25 non-empty lines target (coder≈28, plan≈30, architect≈38 non-empty lines)
- Adding a full protocol section would further increase this
- **Mitigation**: Use a compact table format (4-row table for states + one inline example column) rather than verbose prose; this adds ≈8–10 non-empty lines instead of 20+. This is the minimum compliant implementation.

**Implementation (GREEN)**:
- Files: `agents/coder-agent.md`, `agents/plan-agent.md`, `agents/architect-agent.md`
- Section to add to each file (compact table format):

```markdown
## Subagent Status Protocol

| Status | Meaning | Example |
|--------|---------|---------|
| `DONE` | Task completed; no concerns | All tests pass, deliverable committed |
| `DONE_WITH_CONCERNS` | Completed but issues noted for caller | Tests pass but coverage dropped below 80% |
| `NEEDS_CONTEXT` | Blocked; awaiting clarifying info | Spec AC-3 is ambiguous about conflict resolution |
| `BLOCKED` | Cannot proceed; hard blocker requires human | Build fails after 2 fix attempts; escalating |
```

- After edits: run `pwsh -File .\tools\sync-dotgithub.ps1`

**Acceptance Criteria**:
- [ ] All three of `agents/coder-agent.md`, `agents/plan-agent.md`, `agents/architect-agent.md` contain "Subagent Status Protocol" section with all four states and one example each
- [ ] `tools/sync-dotgithub.ps1` passes; `.github/agents/` files reflect update

**Verification**:
```powershell
Select-String -Path "agents\*.md" -Pattern "Subagent Status Protocol"
# Expect: 3 matches (one per file)
pwsh -File .\tools\sync-dotgithub.ps1
# Expect: no errors
```

---

### Phase 3 Exit Criteria
- [ ] `skills/explore/SKILL.md` exists with all required sections
- [ ] `skills/gate-check/SKILL.md` + `scripts/run-gate-check.ps1` exist and pass AC-5 checks
- [ ] All three agent files contain Subagent Status Protocol section
- [ ] `AGENTS.md` skill count updated from 28 → 30; `tools/audit-catalog.ps1` `$ExpectedSkillCount` constant updated to 30
- [ ] `pwsh -File .\tools\audit-catalog.ps1` exits 0 after count update
- [ ] Sync passes; `.github/` updated; all changes (source + .github/**) committed together

---

## Phase 4: Wave 4 — Repo Memory Skeleton (Scope D)

**Objective**: Document the opt-in repo memory structure and lifecycle rules. Update install surface design to reference the opt-in flag.

**Covers**: AC-6, FR-13, FR-14

---

### Task 4.1 — Repo Memory Design Document

**Verification Target (RED)**:
- No `docs/repo-memory-design.md` exists

**Implementation (GREEN)**:
- File: `docs/repo-memory-design.md`
- Required content:
  1. **Directory structure** (verbatim per spec):
     ```
     .ai-workflow-memory/
     ├── PROJECT_CONTEXT.md    # stable project overview; updated when context changes significantly
     ├── CURRENT_STATE.md      # current work status; updated at end of each major session
     └── session-journal/      # append-only; one file per session (YYYY-MM-DD-<slug>.md)
     ```
  2. **Update rules**: which agent updates which file, at what trigger, with minimum content requirements
  3. **Opt-in mechanism**: directory NOT created by default; activation via `--enable-memory` flag on `install-apply`, or manual directory creation
  4. **Mirror exclusion**: `.ai-workflow-memory/` is NOT added to `.github/**` mirror; memory is local to deploying repo only
  5. **Gitignore guidance**: recommend adding `.ai-workflow-memory/session-journal/` to `.gitignore` if session journals are not intended for commit

**Acceptance Criteria**:
- [ ] `docs/repo-memory-design.md` exists with directory structure, update rules, opt-in mechanism, mirror exclusion rule
- [ ] Default behavior (no memory dir created) explicitly documented

**Verification**: File existence + manual review of all four required sections

---

### Task 4.2 — Cross-Reference in Install Surface Design

**Verification Target (RED)**:
- `docs/install-surface-design.md` (created in Phase 2) does not yet reference `--enable-memory` opt-in flag

**Implementation (GREEN)**:
- File: `docs/install-surface-design.md`
- Add to `install-apply` section: note that `--enable-memory` flag creates `.ai-workflow-memory/` skeleton; reference `docs/repo-memory-design.md` for full spec

**Acceptance Criteria**:
- [ ] `install-surface-design.md` `install-apply` section references `--enable-memory` and `docs/repo-memory-design.md`

**Verification**: `Select-String -Path "docs\install-surface-design.md" -Pattern "\-\-enable-memory"`

---

### Phase 4 Exit Criteria
- [ ] `docs/repo-memory-design.md` exists and passes AC-6 verification
- [ ] `docs/install-surface-design.md` cross-references memory opt-in
- [ ] No sync needed (docs/ not mirrored)

---

## Phase 5: Wave 5 — Debug Skill + Bounded Self-Review (Scope E + NFR-05)

**Objective**: Specify the systematic debug skill and enforce iteration ceiling distinction in agentic-eval.

**Covers**: AC-8, AC-9, FR-15, NFR-05

---

### Task 5.1 — Debug Skill Specification

**Verification Target (RED)**:
- No `skills/debug/` directory exists
- AC-8 requires four specific sections and a fixed numeric escalation threshold

**Implementation (GREEN)**:
- File: `skills/debug/SKILL.md`
- Required sections:
  1. **Invocation criteria**: build failures; test failures; unexpected agent behavior; drift-related errors
  2. **Investigation step sequence** (ordered): reproduce → isolate → hypothesize → test hypothesis → record finding
  3. **Output format**: structured findings report (what was tested, what was observed, hypothesis confirmed/rejected); escalation trigger if unresolved
  4. **Escalation threshold**: after **2 consecutive failed debug cycles** (attempted corrective action → reran check → still failed = 1 cycle), terminate loop; surface findings to human. Must NOT autonomously initiate third cycle.
- Threshold must appear as the literal number "2", not a placeholder or variable

**Acceptance Criteria**:
- [ ] `skills/debug/SKILL.md` exists with all four sections
- [ ] Escalation threshold is stated as "2 cycles" (specific number)

**Verification**:
```powershell
Test-Path "skills\debug\SKILL.md"   # True
Select-String -Path "skills\debug\SKILL.md" -Pattern "2 consecutive"  # 1 match
```

---

### Task 5.2 — Agentic-Eval Iteration Ceiling Update

**Verification Target (RED)**:
- `skills/agentic-eval/SKILL.md` does not currently distinguish stage-transition (2-iter) from general-purpose (3–5-iter) ceilings

**Implementation (GREEN)**:
- File: `skills/agentic-eval/SKILL.md`
- Add explicit section (or update existing iteration section) with:
  - **Stage-transition gating loops** (spec→plan handoff, plan→code handoff, code→review handoff, review completeness check): max **2 iterations** then terminate + escalate to human
  - **General-purpose loops** (draft improvement, iterative refinement outside stage gates): max **3–5 iterations** (existing ceiling preserved)
  - After 2 iterations at a stage gate without resolution: loop terminates; all unresolved FAIL dimensions surfaced to human
- Sync: run `pwsh -File .\tools\sync-dotgithub.ps1`

**Acceptance Criteria**:
- [ ] `skills/agentic-eval/SKILL.md` has a section distinguishing stage-transition (2-iter) vs general-purpose (3–5-iter) ceilings
- [ ] Sync passes; `.github/skills/agentic-eval/` reflects update

**Risk**:
- **Inadvertent ceiling change**: Modifying `skills/agentic-eval/SKILL.md` could accidentally alter the existing general-purpose ceiling (3–5 iter) wording if the edit is not surgical. Mitigation: the edit must only ADD a new section or subsection; existing "3–5 iterations" language elsewhere in the file must remain unchanged. Verification: `git diff skills/agentic-eval/SKILL.md` must show only additions (lines starting with `+`), no deletions of existing ceiling text.

**Verification**:
```powershell
Select-String -Path "skills\agentic-eval\SKILL.md" -Pattern "stage.transition|stage gate"
Select-String -Path "skills\agentic-eval\SKILL.md" -Pattern "2 iter|max.*2|maximum.*2"
# Verify existing general-purpose ceiling NOT removed
Select-String -Path "skills\agentic-eval\SKILL.md" -Pattern "3.5|3–5|general.purpose"
git --no-pager diff --stat skills\agentic-eval\SKILL.md
# Expect: only additions, no net deletions
```

### Task 5.3 — Agent File References to 2-Iteration Limit

**Verification Target (RED)**:
- `agents/coder-agent.md` and `agents/architect-agent.md` do not reference the 2-iteration stage-transition limit

**Implementation (GREEN)**:
- File: `agents/coder-agent.md`
  - Update "Pre-Review Self-Evaluation" section to note: "Stage-transition agentic-eval loops are bounded to **max 2 iterations**; if unresolved, terminate and escalate to human (NFR-05)"
- File: `agents/architect-agent.md`
  - Update "Cross-Stage Quality Arbitration" section to note: "Stage-gate agentic-eval calls (spec/plan/review handoffs) are bounded to **max 2 iterations**; escalate to human if unresolved (NFR-05)"
- Sync: run `pwsh -File .\tools\sync-dotgithub.ps1`

**⚠️ Constraint**: Same agent file size concern as Task 3.3. Keep additions to ≤2 non-empty lines per file. Reference NFR-05 inline; do not elaborate.

**Acceptance Criteria**:
- [ ] `agents/coder-agent.md` references the 2-iteration stage-transition limit
- [ ] `agents/architect-agent.md` references the 2-iteration stage-transition limit
- [ ] Sync passes; `.github/agents/` files reflect update

**Verification**:
```powershell
Select-String -Path "agents\coder-agent.md","agents\architect-agent.md" -Pattern "2 iter|NFR-05"
pwsh -File .\tools\sync-dotgithub.ps1
```

---

### Phase 5 Exit Criteria
- [ ] `skills/debug/SKILL.md` exists with all four required sections and fixed threshold
- [ ] `skills/agentic-eval/SKILL.md` distinguishes the two iteration ceilings; existing 3–5 ceiling unchanged
- [ ] Both `coder-agent.md` and `architect-agent.md` reference the 2-iteration limit
- [ ] `AGENTS.md` skill count updated from 30 → 31; `tools/audit-catalog.ps1` `$ExpectedSkillCount` constant updated to 31
- [ ] `pwsh -File .\tools\audit-catalog.ps1` exits 0 after count update
- [ ] Sync passes; `.github/` updated; all changes committed together

---

## Dependencies

### External
- PowerShell 7+ (pwsh) available for `audit-catalog.ps1` and `run-gate-check.ps1`

### Internal
- Phase 1 must complete before Phase 2 (catalog alignment validates the count baselines the audit script uses)
- Phase 2 must complete before Phase 4 (memory opt-in cross-reference requires `install-surface-design.md`)
- Phase 3 can begin in parallel with Phase 2 (no shared file edits between the two)
- Phase 5 can begin after Phase 3 (AC-9 references agentic-eval, which is used in gate-check context)
- **Audit script constant update** must occur in the same commit as the new skills it tracks:
  - Phase 3 commit: `skills/explore/` + `skills/gate-check/` created → update `$ExpectedSkillCount` to 30
  - Phase 5 commit: `skills/debug/` created → update `$ExpectedSkillCount` to 31

### Sequencing
```
Phase 1 (Drift & Truth)
    ↓
Phase 2 (Install Surface) ←→ Phase 3 (Workflow Enhancements) [parallel OK]
    ↓
Phase 4 (Repo Memory)
    ↓
Phase 5 (Debug + Bounded Self-Review)
```

---

## Sync Protocol (Mandatory)

Run after each phase that touches `agents/`, `skills/`, `instructions/`, `prompts/`, or `copilot-instructions.md`:

```powershell
pwsh -File .\tools\sync-dotgithub.ps1

# Verify sync correctness — confirm no drift remains
pwsh -File .\tools\check-sync.ps1
# Expect: exit 0 / no drift reported
```

Commit source and `.github/**` together in the same commit. Never commit one without the other.

**AGENTS.md skill count update protocol** (required when new skills are added):
```powershell
# Verify new skill count before updating AGENTS.md
(Get-ChildItem skills -Directory).Count   # Confirm actual count matches expected

# After updating AGENTS.md count and audit-catalog.ps1 constant:
pwsh -File .\tools\audit-catalog.ps1     # Expect: exit 0
```

---

## Estimated Timeline

| Phase | Tasks | Deliverables | Estimated Effort |
|-------|-------|-------------|------------------|
| Phase 1 — Drift & Truth | 3 tasks | 3 doc updates + audit script | 3–5 hours |
| Phase 2 — Install Surface | 1 task | 1 design doc | 2–3 hours |
| Phase 3 — Workflow Enhancements | 3 tasks | 2 new skills + 3 agent updates | 4–6 hours |
| Phase 4 — Repo Memory | 2 tasks | 1 design doc + cross-ref | 2–3 hours |
| Phase 5 — Debug + Self-Review | 3 tasks | 1 new skill + 2 skill/agent updates | 3–5 hours |
| **Total** | **12 tasks** | **9 new files, 7 modified files** | **14–22 hours** |

---

## Approval & Next Steps

**Plan Status**: ⏳ Awaiting Approval

**Approval Checklist**:
- [ ] All phases reviewed; wave sequencing acceptable
- [ ] AC-7 agent file size constraint acknowledged (compact table format)
- [ ] Phase 3 and Phase 2 parallel execution approved (or sequentialized if preferred)
- [ ] Impact analysis (`06-impact-analysis.md`) reviewed and rollback strategy accepted

**Next Step After Approval**:
→ Begin Phase 1: `"開始 TDD 實作"` or switch to coder-agent
→ Or: `"what's next?"` to use workflow orchestrator
