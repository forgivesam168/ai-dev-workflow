#Requires -Version 7
param(
    [string]$RepoRoot = (Resolve-Path "$PSScriptRoot/..").Path
)
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
$ExpectedAgentCount       = 9
$ExpectedPromptCount      = 10
$ExpectedTotalSkillCount  = 35
$MaintainerOnlySkills     = @('gate-check')
$ExpectedAdopterSkillCount = $ExpectedTotalSkillCount - $MaintainerOnlySkills.Count

# ─── Required change-package files (canonical source: changes.instructions.md)
$RequiredChangeFiles = @(
    '00-intake.md',
    '01-brainstorm.md',
    '02-decision-log.md',
    '03-spec.md',
    '04-plan.md',
    '05-test-plan.md',
    '06-impact-analysis.md',
    '07-review.md',
    '99-archive.md'
)

# ─── Helpers ───────────────────────────────────────────────────────────────
$results = [System.Collections.Generic.List[PSCustomObject]]::new()
$rootDir = (Resolve-Path $RepoRoot).Path

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
$skillNames = @(Get-ChildItem (Join-Path $rootDir 'skills') -Directory |
    Where-Object { Test-Path (Join-Path $_.FullName 'SKILL.md') } |
    Select-Object -ExpandProperty Name)
$totalSkillActual = $skillNames.Count
$maintainerSkillActual = @($skillNames | Where-Object { $_ -in $MaintainerOnlySkills }).Count
$adopterSkillNames = @($skillNames | Where-Object { $_ -notin $MaintainerOnlySkills })
$adopterSkillActual = $adopterSkillNames.Count

$mirrorSkillsPath = Join-Path $rootDir '.github\skills'
$mirrorSkillNames = if (Test-Path $mirrorSkillsPath) {
    @(Get-ChildItem $mirrorSkillsPath -Directory |
        Where-Object { Test-Path (Join-Path $_.FullName 'SKILL.md') } |
        Select-Object -ExpandProperty Name)
} else {
    @()
}
$unexpectedMaintainerDeployments = @($mirrorSkillNames | Where-Object { $_ -in $MaintainerOnlySkills })
$missingAdopterSkills = @($adopterSkillNames | Where-Object { $_ -notin $mirrorSkillNames })
$extraMirrorSkills = @($mirrorSkillNames | Where-Object { $_ -notin $adopterSkillNames })

Add-Result 'Agent files'   $ExpectedAgentCount  $agentActual  $(if ($agentActual  -eq $ExpectedAgentCount)  { 'PASS' } else { 'FAIL' })
Add-Result 'Prompt files'  $ExpectedPromptCount $promptActual $(if ($promptActual -eq $ExpectedPromptCount) { 'PASS' } else { 'FAIL' })
Add-Result 'Skills total' $ExpectedTotalSkillCount $totalSkillActual $(if ($totalSkillActual -eq $ExpectedTotalSkillCount) { 'PASS' } else { 'FAIL' }) `
    $(if ($totalSkillActual -ne $ExpectedTotalSkillCount) { 'Catalog contract changed; update the reviewed 35 total / 34 adopter / 1 maintainer-only contract.' } else { '' })
Add-Result 'Skills adopter' $ExpectedAdopterSkillCount $adopterSkillActual $(if ($adopterSkillActual -eq $ExpectedAdopterSkillCount) { 'PASS' } else { 'FAIL' })
Add-Result 'Skills maintainer-only' $MaintainerOnlySkills.Count $maintainerSkillActual $(if ($maintainerSkillActual -eq $MaintainerOnlySkills.Count) { 'PASS' } else { 'FAIL' }) `
    "Expected: $($MaintainerOnlySkills -join ', ')"

$deploymentStatus = if (
    $unexpectedMaintainerDeployments.Count -eq 0 -and
    $missingAdopterSkills.Count -eq 0 -and
    $extraMirrorSkills.Count -eq 0
) { 'PASS' } else { 'FAIL' }
$deploymentNote = @(
    if ($unexpectedMaintainerDeployments.Count) { "Maintainer-only deployed: $($unexpectedMaintainerDeployments -join ', ')" }
    if ($missingAdopterSkills.Count) { "Missing adopter skills: $($missingAdopterSkills -join ', ')" }
    if ($extraMirrorSkills.Count) { "Extra mirror skills: $($extraMirrorSkills -join ', ')" }
) -join '. '
Add-Result 'Skill deployment contract' '34 adopter; gate-check excluded' $mirrorSkillNames.Count $deploymentStatus $deploymentNote

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

$templateRoot = Join-Path $rootDir 'changes\_template'
$actualTemplates = if (Test-Path -LiteralPath $templateRoot -PathType Container) {
    @(Get-ChildItem -LiteralPath $templateRoot -File | Select-Object -ExpandProperty Name)
} else { @() }
$missingTemplates = @($RequiredChangeFiles | Where-Object { $_ -notin $actualTemplates })
$unexpectedTemplates = @($actualTemplates | Where-Object { $_ -notin $RequiredChangeFiles })
$templateNotes = @(
    if ($missingTemplates.Count) { "Missing canonical templates: $($missingTemplates -join ', ')" }
    if ($unexpectedTemplates.Count) { "Unexpected templates: $($unexpectedTemplates -join ', ')" }
) -join '. '
$templateStatus = if ($missingTemplates.Count -eq 0 -and $unexpectedTemplates.Count -eq 0) { 'PASS' } else { 'FAIL' }
Add-Result 'Change-pkg template set' ($RequiredChangeFiles.Count) $actualTemplates.Count $templateStatus $templateNotes

$semanticSignals = @('Compact', 'Full', '05-review.md', '99-closeout.md', 'pointer-only')
$semanticMissing = @()
foreach ($signal in $semanticSignals) {
    if ($workflowContent -notmatch [regex]::Escape($signal) -or $instructionsContent -notmatch [regex]::Escape($signal)) {
        $semanticMissing += $signal
    }
}
$semanticStatus = if ($semanticMissing.Count -eq 0) { 'PASS' } else { 'FAIL' }
$semanticNote = if ($semanticMissing.Count) { "Missing semantic contract signals: $($semanticMissing -join ', ')" } else { '' }
Add-Result 'Change-pkg semantic roles' 'Compact/Full + aliases' '(checked)' $semanticStatus $semanticNote

# ─── Output table ──────────────────────────────────────────────────────────
Write-Host ''
Write-Host '╔══════════════════════════════════════════════════════════════╗'
Write-Host '║              AI Workflow Template — Catalog Audit            ║'
Write-Host '╚══════════════════════════════════════════════════════════════╝'
Write-Host ''
Write-Host "Skills summary: total=$totalSkillActual adopter=$adopterSkillActual maintainer-only=$maintainerSkillActual [$($MaintainerOnlySkills -join ',')]"
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

$failedResults = @($results | Where-Object { $_.Status -eq 'FAIL' })
if ($failedResults.Count -gt 0) {
    Write-Host ''
    Write-Host 'Failure diagnostics:'
    foreach ($result in $failedResults) {
        $note = if ([string]::IsNullOrWhiteSpace([string]$result.Note)) {
            'No additional note.'
        } else {
            [string]$result.Note
        }
        Write-Host "FAIL DIAGNOSTIC: $($result.Category): $note"
    }
}

$failCount = @($results | Where-Object { $_.Status -eq 'FAIL' }).Count
if ($failCount -gt 0) {
    Write-Host "Audit FAILED: $failCount check(s) failed." -ForegroundColor Red
    exit 1
} else {
    Write-Host 'Audit PASSED: all checks clean.' -ForegroundColor Green
    exit 0
}
