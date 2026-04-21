#Requires -Version 7
<#
.SYNOPSIS
    Audits the AI workflow template catalog for count and contract parity.

.DESCRIPTION
    Checks:
    1. Agent / prompt / skill directory counts against expected constants.
    2. Change-package required file list parity between WORKFLOW.md and
       instructions/changes.instructions.md.

    Exit 0 = all PASS.  Exit 1 = one or more FAIL.

.EXAMPLE
    pwsh -File .\tools\audit-catalog.ps1
#>

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

# ─── Expected count constants ──────────────────────────────────────────────
# Update these constants in the same commit that adds/removes files.
# Phase 3 update: 28 → 30  (explore + gate-check added)
# Phase 5 update: 30 → 31  (debug added)
$ExpectedAgentCount  = 6
$ExpectedPromptCount = 10
$ExpectedSkillCount  = 28   # <-- update here when adding new skills

# ─── Required change-package files (canonical source: changes.instructions.md)
$RequiredChangeFiles = @(
    '00-intake.md',
    '01-brainstorm.md',
    '02-decision-log.md',
    '03-spec.md',
    '04-plan.md',
    '05-test-plan.md',
    '06-impact-analysis.md',
    '99-archive.md'
)

# ─── Helpers ───────────────────────────────────────────────────────────────
$results = [System.Collections.Generic.List[PSCustomObject]]::new()
$rootDir = Split-Path $PSScriptRoot -Parent

function Add-Result {
    param([string]$Category, [object]$Expected, [object]$Actual, [string]$Status, [string]$Note = '')
    $results.Add([PSCustomObject]@{
        Category = $Category
        Expected = $Expected
        Actual   = $Actual
        Status   = $Status
        Note     = $Note
    })
}

# ─── Check 1: Count parity ─────────────────────────────────────────────────
$agentActual  = (Get-ChildItem (Join-Path $rootDir 'agents')  -Filter '*.agent.md').Count
$promptActual = (Get-ChildItem (Join-Path $rootDir 'prompts') -Filter '*.prompt.md').Count
$skillActual  = (Get-ChildItem (Join-Path $rootDir 'skills')  -Directory).Count

Add-Result 'Agent files'   $ExpectedAgentCount  $agentActual  $(if ($agentActual  -eq $ExpectedAgentCount)  { 'PASS' } else { 'FAIL' })
Add-Result 'Prompt files'  $ExpectedPromptCount $promptActual $(if ($promptActual -eq $ExpectedPromptCount) { 'PASS' } else { 'FAIL' })
Add-Result 'Skill dirs'    $ExpectedSkillCount  $skillActual  $(if ($skillActual  -eq $ExpectedSkillCount)  { 'PASS' } else { 'FAIL' })

# ─── Check 2: Change-package contract parity ──────────────────────────────
$workflowPath     = Join-Path $rootDir 'WORKFLOW.md'
$instructionsPath = Join-Path $rootDir 'instructions\changes.instructions.md'

$workflowContent     = Get-Content $workflowPath     -Raw
$instructionsContent = Get-Content $instructionsPath -Raw

$missingInWorkflow     = @()
$missingInInstructions = @()

foreach ($file in $RequiredChangeFiles) {
    if ($workflowContent     -notmatch [regex]::Escape($file)) { $missingInWorkflow     += $file }
    if ($instructionsContent -notmatch [regex]::Escape($file)) { $missingInInstructions += $file }
}

$contractNote = ''
if ($missingInWorkflow.Count -gt 0) {
    $contractNote += "Missing in WORKFLOW.md: $($missingInWorkflow -join ', '). "
}
if ($missingInInstructions.Count -gt 0) {
    $contractNote += "Missing in changes.instructions.md: $($missingInInstructions -join ', ')."
}

$contractStatus = if ($missingInWorkflow.Count -eq 0 -and $missingInInstructions.Count -eq 0) { 'PASS' } else { 'FAIL' }
Add-Result 'Change-pkg contract' '(all files)' '(checked)' $contractStatus $contractNote

# ─── Output table ──────────────────────────────────────────────────────────
Write-Host ''
Write-Host '╔══════════════════════════════════════════════════════════════╗'
Write-Host '║              AI Workflow Template — Catalog Audit            ║'
Write-Host '╚══════════════════════════════════════════════════════════════╝'
Write-Host ''

$results | Format-Table -AutoSize @(
    @{L='Category'; E='Category'; Width=30},
    @{L='Expected'; E='Expected'; Width=10},
    @{L='Actual';   E='Actual';   Width=10},
    @{L='Status';   E={
        if ($_.Status -eq 'PASS') { "$([char]0x2705) PASS" }
        else                       { "$([char]0x274C) FAIL" }
    }; Width=10},
    @{L='Note';     E='Note'; Width=60}
)

$failCount = @($results | Where-Object { $_.Status -eq 'FAIL' }).Count
if ($failCount -gt 0) {
    Write-Host "Audit FAILED: $failCount check(s) failed." -ForegroundColor Red
    exit 1
} else {
    Write-Host 'Audit PASSED: all checks clean.' -ForegroundColor Green
    exit 0
}
