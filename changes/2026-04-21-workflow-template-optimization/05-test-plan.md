# Test Plan: Workflow Template Optimization

**Spec Reference**: `03-spec.md`
**Plan Reference**: `04-plan.md`

---

## Overview

This change package is primarily documentation, specification, and tooling work — not runtime software. Testing strategy is **verification-driven**: each AC defines a precise verification method, and this test plan maps those methods to explicit steps with commands or manual review procedures.

**No unit test framework required.** Verification uses:
- File existence checks (PowerShell `Test-Path`)
- Content checks (PowerShell `Select-String` / manual review)
- Script execution (PowerShell 7+)
- Sync integrity check (`tools/check-sync.ps1` or `sync-dotgithub.ps1` exit code)

---

## Phase-by-Phase Verification

### Phase 1: Wave 1 — Drift & Truth

#### V-1.1 Catalog Count Consistency

**What is being verified**: README.md, README.zh-TW.md, AGENTS.md, WORKFLOW.md all agree on agent / prompt / skill counts.

**Steps**:
```powershell
# Ground-truth counts (as of this change package)
# Expected: 6 agents, 10 prompts, 28 skills
(Get-ChildItem agents -Directory).Count           # Expect: 6 (note: *.agent.md files, not dirs)
(Get-ChildItem agents -Filter "*.agent.md").Count # Expect: 6
(Get-ChildItem prompts -Filter "*.prompt.md").Count  # Expect: 10
(Get-ChildItem skills -Directory).Count           # Expect: 28

# Check claims in docs
Select-String -Path "README.md","AGENTS.md","WORKFLOW.md" -Pattern "\d+ (skills|agents|prompts)"
```

**Pass Criteria**:
- [ ] All count statements in all four docs match ground truth
- [ ] No conflicting numeric claims found

---

#### V-1.2 Change-Package Contract Alignment

**What is being verified**: `WORKFLOW.md` and `instructions/changes.instructions.md` agree on required file list and rules.

**Steps**:
```powershell
# View both files' file-list sections
Select-String -Path "WORKFLOW.md" -Pattern "00-|01-|02-|03-|04-|05-|06-|99-"
Select-String -Path "instructions\changes.instructions.md" -Pattern "00-|01-|02-|03-|04-|05-|06-|99-"
```

**Pass Criteria**:
- [ ] Required file lists match between both documents
- [ ] No rule contradictions (e.g., append-only vs. overwrite-ok)

---

#### V-1.3 Audit Script Execution

**What is being verified**: `tools/audit-catalog.ps1` runs, produces a result table, and exits 0 on a clean repo.

**Steps**:
```powershell
# Clean run
pwsh -File .\tools\audit-catalog.ps1
$LASTEXITCODE  # Expect: 0

# Failure-path test (rename one agent file temporarily)
Rename-Item "agents\coder.agent.md" "agents\coder.agent.md.bak"
pwsh -File .\tools\audit-catalog.ps1
$LASTEXITCODE  # Expect: 1 (FAIL)
Rename-Item "agents\coder.agent.md.bak" "agents\coder.agent.md"

# Re-run to confirm PASS restored
pwsh -File .\tools\audit-catalog.ps1
$LASTEXITCODE  # Expect: 0
```

**Pass Criteria**:
- [ ] Script exits 0 on clean repo
- [ ] Script exits 1 when an agent is missing
- [ ] Script outputs human-readable table

---

### Phase 2: Wave 2 — Install Surface Design

#### V-2.1 Install Surface Design Document

**What is being verified**: `docs/install-surface-design.md` exists and contains all required AC-3 content.

**Steps**:
```powershell
# File existence
Test-Path "docs\install-surface-design.md"   # True

# Check all four required sections
Select-String -Path "docs\install-surface-design.md" -Pattern "install-plan"
Select-String -Path "docs\install-surface-design.md" -Pattern "install-apply"
Select-String -Path "docs\install-surface-design.md" -Pattern "doctor"
Select-String -Path "docs\install-surface-design.md" -Pattern "schema_version"
Select-String -Path "docs\install-surface-design.md" -Pattern "Init-Project"
Select-String -Path "docs\install-surface-design.md" -Pattern "enable-memory"
```

**Pass Criteria**:
- [ ] File exists
- [ ] `install-plan` section present with output format described
- [ ] `install-apply` section present with conflict behavior (skip-if-exists, --force) described
- [ ] `doctor` section present with verdict format aligned to gate-check
- [ ] JSON schema sample present with `schema_version` as first field
- [ ] Compatibility with `Init-Project.ps1` mentioned
- [ ] `--enable-memory` flag mentioned with reference to `docs/repo-memory-design.md`

---

### Phase 3: Wave 3 — Workflow Enhancements

#### V-3.1 Explore Mode Skill

**What is being verified**: `skills/explore/SKILL.md` exists with three required sections and enumerated trigger list.

**Steps**:
```powershell
Test-Path "skills\explore\SKILL.md"   # True

# Verify three sections
Select-String -Path "skills\explore\SKILL.md" -Pattern "When to enter|enter explore"
Select-String -Path "skills\explore\SKILL.md" -Pattern "no files|artifact"
Select-String -Path "skills\explore\SKILL.md" -Pattern "/proceed|create change package|start brainstorm|I want to formalize"

# Verify "or equivalent" does not appear unaccompanied
$content = Get-Content "skills\explore\SKILL.md" -Raw
if ($content -match "or equivalent" -and $content -notmatch "or equivalent.*\n.*-") {
    Write-Warning "FAIL: 'or equivalent' found without accompanying list"
}
```

**Pass Criteria**:
- [ ] File exists
- [ ] All three required sections present
- [ ] All four trigger phrases explicitly listed
- [ ] "or equivalent" either absent or accompanied by a list

---

#### V-3.2 Gate-Check Skill and Script Stub

**What is being verified**: `skills/gate-check/SKILL.md` and `skills/gate-check/scripts/run-gate-check.ps1` exist with required content.

**Steps**:
```powershell
# File existence
Test-Path "skills\gate-check\SKILL.md"                          # True
Test-Path "skills\gate-check\scripts\run-gate-check.ps1"        # True

# Verdict semantics
Select-String -Path "skills\gate-check\SKILL.md" -Pattern "GATE PASSED"
Select-String -Path "skills\gate-check\SKILL.md" -Pattern "GATE PASSED WITH NOTES"
Select-String -Path "skills\gate-check\SKILL.md" -Pattern "GATE FAILED"

# Required checks (both must be marked Required)
Select-String -Path "skills\gate-check\SKILL.md" -Pattern "sync-dotgithub|drift"
Select-String -Path "skills\gate-check\SKILL.md" -Pattern "audit-catalog|catalog.*parity"

# Boundary definition
Select-String -Path "skills\gate-check\SKILL.md" -Pattern "agentic-eval"
Select-String -Path "skills\gate-check\SKILL.md" -Pattern "deterministic"

# Three-layer ordering
Select-String -Path "skills\gate-check\SKILL.md" -Pattern "code-reviewer|three.layer|ordering"

# Script documents check invocations
Select-String -Path "skills\gate-check\scripts\run-gate-check.ps1" -Pattern "#|GATE"
```

**Pass Criteria**:
- [ ] Both files exist
- [ ] All three verdict strings present in SKILL.md
- [ ] Source drift check and catalog parity check present (and marked Required)
- [ ] Boundary between gate-check and agentic-eval defined
- [ ] Three-layer ordering documented (gate-check → agentic-eval → code-reviewer)
- [ ] At least one concrete example per verdict present
- [ ] `GATE PASSED WITH NOTES` escalation path specified (log to change package)
- [ ] Script stub documents expected check invocations

---

#### V-3.3 Subagent Status Protocol in Agent Files

**What is being verified**: All three target agent files contain a Subagent Status Protocol section with all four states.

**Steps**:
```powershell
# Check all three files
Select-String -Path "agents\coder-agent.md","agents\plan-agent.md","agents\architect-agent.md" `
    -Pattern "Subagent Status Protocol"
# Expect: 3 matches

# Check all four states in each file
foreach ($f in @("agents\coder-agent.md","agents\plan-agent.md","agents\architect-agent.md")) {
    $c = Get-Content $f -Raw
    @("DONE","DONE_WITH_CONCERNS","NEEDS_CONTEXT","BLOCKED") | ForEach-Object {
        if ($c -notmatch $_) { Write-Warning "FAIL: $_ missing in $f" }
    }
}

# Sync verification
pwsh -File .\tools\sync-dotgithub.ps1
# Verify .github/agents/ files are updated
Select-String -Path ".github\agents\coder-agent.md",".github\agents\plan-agent.md",".github\agents\architect-agent.md" `
    -Pattern "Subagent Status Protocol"
# Expect: 3 matches
```

**Pass Criteria**:
- [ ] All three source agent files contain "Subagent Status Protocol" heading
- [ ] All four states (DONE, DONE_WITH_CONCERNS, NEEDS_CONTEXT, BLOCKED) present in each file
- [ ] Sync passes; `.github/agents/` files match

---

### Phase 4: Wave 4 — Repo Memory

#### V-4.1 Repo Memory Design Document

**What is being verified**: `docs/repo-memory-design.md` exists with all required AC-6 content.

**Steps**:
```powershell
Test-Path "docs\repo-memory-design.md"   # True

# Required content checks
Select-String -Path "docs\repo-memory-design.md" -Pattern "PROJECT_CONTEXT"
Select-String -Path "docs\repo-memory-design.md" -Pattern "CURRENT_STATE"
Select-String -Path "docs\repo-memory-design.md" -Pattern "session-journal"
Select-String -Path "docs\repo-memory-design.md" -Pattern "enable-memory|opt.in"
Select-String -Path "docs\repo-memory-design.md" -Pattern "\.github|mirror|not.*added"
Select-String -Path "docs\repo-memory-design.md" -Pattern "not created by default|default.*no"
```

**Pass Criteria**:
- [ ] File exists
- [ ] Directory structure with all three entries documented
- [ ] Update rules section present
- [ ] Opt-in mechanism (--enable-memory) documented
- [ ] Mirror exclusion (.github/**) documented
- [ ] Default behavior (no dir created) explicitly stated

---

#### V-4.2 Install Surface Cross-Reference

**Steps**:
```powershell
Select-String -Path "docs\install-surface-design.md" -Pattern "enable-memory"
Select-String -Path "docs\install-surface-design.md" -Pattern "repo-memory-design"
```

**Pass Criteria**:
- [ ] `--enable-memory` referenced in install-surface-design.md
- [ ] `docs/repo-memory-design.md` referenced by name

---

### Phase 5: Wave 5 — Debug Skill + Bounded Self-Review

#### V-5.1 Debug Skill

**What is being verified**: `skills/debug/SKILL.md` exists with all four sections and fixed threshold.

**Steps**:
```powershell
Test-Path "skills\debug\SKILL.md"   # True

Select-String -Path "skills\debug\SKILL.md" -Pattern "build failure|test failure|unexpected|drift"
Select-String -Path "skills\debug\SKILL.md" -Pattern "reproduce|isolate|hypothes"
Select-String -Path "skills\debug\SKILL.md" -Pattern "findings|escalat"
Select-String -Path "skills\debug\SKILL.md" -Pattern "2 consecutive|2 failed"
```

**Pass Criteria**:
- [ ] File exists
- [ ] All four invocation criteria present
- [ ] Investigation step sequence present (ordered steps)
- [ ] Output format / escalation trigger defined
- [ ] Escalation threshold appears as specific number "2" (not a variable)

---

#### V-5.2 Agentic-Eval Iteration Ceiling

**What is being verified**: `skills/agentic-eval/SKILL.md` distinguishes stage-transition (2-iter) from general-purpose (3–5-iter) ceilings; `.github/skills/agentic-eval/` reflects update.

**Steps**:
```powershell
Select-String -Path "skills\agentic-eval\SKILL.md" -Pattern "stage.transition|stage gate"
Select-String -Path "skills\agentic-eval\SKILL.md" -Pattern "2 iter|max.*2|maximum.*2"
Select-String -Path "skills\agentic-eval\SKILL.md" -Pattern "3.5|general.purpose"

# After sync
pwsh -File .\tools\sync-dotgithub.ps1
Select-String -Path ".github\skills\agentic-eval\SKILL.md" -Pattern "stage.transition|2 iter"
```

**Pass Criteria**:
- [ ] Stage-transition ceiling (2 iterations) and general-purpose ceiling (3–5) both explicitly defined
- [ ] Termination + escalation rule for stage-gate loops documented
- [ ] `.github/skills/agentic-eval/SKILL.md` reflects the update after sync

---

#### V-5.3 Agent File References to 2-Iteration Limit

**Steps**:
```powershell
Select-String -Path "agents\coder-agent.md" -Pattern "2 iter|NFR-05"
Select-String -Path "agents\architect-agent.md" -Pattern "2 iter|NFR-05"

# After sync
pwsh -File .\tools\sync-dotgithub.ps1
Select-String -Path ".github\agents\coder-agent.md",".github\agents\architect-agent.md" -Pattern "2 iter|NFR-05"
```

**Pass Criteria**:
- [ ] `coder-agent.md` references 2-iteration stage-transition limit
- [ ] `architect-agent.md` references 2-iteration stage-transition limit
- [ ] `.github/agents/` files reflect update after sync

---

## Cross-Cutting Checks

### CC-1 Sync Integrity (Run After Each Phase Touching agents/skills/instructions)

```powershell
# Check sync is clean (no unsynced changes)
pwsh -File .\tools\check-sync.ps1
# Expect: clean / no drift reported
```

### CC-2 Audit Script Clean Run (Run After Phase 1 and at End of Change)

```powershell
pwsh -File .\tools\audit-catalog.ps1
# Expect: all PASS
```

### CC-3 Regression: Existing Workflows Unaffected

**What is being verified**: Existing skills, agents, prompts, instructions are not modified except as required by this change package.

**Steps**:
```powershell
# Review git diff after each phase — confirm only expected files changed
git --no-pager diff --name-only HEAD
```

**Pass Criteria**:
- [ ] No unexpected file modifications outside the change package scope
- [ ] `tools/sync-dotgithub.ps1` continues to run without errors
- [ ] Existing agent and skill files (not in scope) are unchanged

---

## Full AC Verification Matrix

| AC | Verification Method | Automated? | Phase |
|----|--------------------|-----------:|-------|
| AC-1 Catalog Truth | Count grep + audit script | Partial | 1 |
| AC-2 Change-Package Contract | File comparison + sync check | Manual | 1 |
| AC-3 Install Surface Spec | File exists + section grep | Manual | 2 |
| AC-4 Explore Mode Spec | File exists + section grep + trigger-list grep | Partial | 3 |
| AC-5 Gate-Check Spec | File exists + verdict grep + script exists | Partial | 3 |
| AC-6 Repo Memory Spec | File exists + section grep | Manual | 4 |
| AC-7 Subagent Status Protocol | Select-String 3 files + sync | Partial | 3 |
| AC-8 Debug Skill Spec | File exists + section grep + threshold grep | Partial | 5 |
| AC-9 Bounded Self-Review | SKILL.md + 2 agent files + sync | Partial | 5 |

---

## Definition of Done

All of the following must be true before the change package advances to code-review:

1. ✅ All 9 ACs pass their verification steps
2. ✅ `tools/audit-catalog.ps1` exits 0 on clean repo
3. ✅ `tools/sync-dotgithub.ps1` passes with no drift
4. ✅ `tools/check-sync.ps1` reports no unsynced source changes
5. ✅ Git diff confirms only expected files were modified
6. ✅ No floating-point or financial precision concerns (N/A for this change — governance only)
7. ✅ No secrets or credentials introduced in any file
