#Requires -Version 7
<#
.SYNOPSIS
    Gate-check script stub — runs deterministic pre-review checks.

.DESCRIPTION
    This is a stub that documents the expected check invocations.
    Each section below represents one gate-check dimension.

    Overall verdict:
      Exit 0  = GATE PASSED
      Exit 1  = GATE FAILED

    Run before handing off to agentic-eval or code-reviewer.

.EXAMPLE
    pwsh -File .\skills\gate-check\scripts\run-gate-check.ps1
#>

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$rootDir = (Resolve-Path "$PSScriptRoot/../../..").Path
$failed  = $false
$notes   = [System.Collections.Generic.List[string]]::new()
$initialStatus = @()

Write-Host ''
Write-Host '╔══════════════════════════════════════════════════════╗'
Write-Host '║               AI Workflow Gate-Check                 ║'
Write-Host '╚══════════════════════════════════════════════════════╝'
Write-Host ''

# ─── REQUIRED: Environment prerequisites ───────────────────────────────────
Write-Host '--- [REQUIRED] Environment prerequisites ---'
$pythonCommand = Get-Command python -ErrorAction SilentlyContinue
$gitCommand = Get-Command git -ErrorAction SilentlyContinue
$pesterModule = Get-Module Pester -ListAvailable |
    Where-Object Version -eq ([version]'5.6.1') |
    Select-Object -First 1

if (-not $gitCommand) {
    Write-Host '  ❌ ENVIRONMENT_PREREQUISITE_MISSING — git' -ForegroundColor Red
    $failed = $true
} else {
    $insideWorktree = & git -C $rootDir rev-parse --is-inside-work-tree 2>$null
    if ($LASTEXITCODE -ne 0 -or $insideWorktree -ne 'true') {
        Write-Host '  ❌ ENVIRONMENT_PREREQUISITE_MISSING — valid git worktree' -ForegroundColor Red
        $failed = $true
    }
}

if (-not $pythonCommand) {
    Write-Host '  ❌ ENVIRONMENT_PREREQUISITE_MISSING — python' -ForegroundColor Red
    $failed = $true
} else {
    $pytestVersion = & python -m pytest --version 2>$null
    if ($LASTEXITCODE -ne 0 -or $pytestVersion -notmatch '(?m)^pytest 8\.3\.5(?:\s|$)') {
        Write-Host '  ❌ ENVIRONMENT_PREREQUISITE_MISSING — pytest 8.3.5' -ForegroundColor Red
        $failed = $true
    }
}

if (-not $pesterModule) {
    Write-Host '  ❌ ENVIRONMENT_PREREQUISITE_MISSING — Pester 5.6.1' -ForegroundColor Red
    $failed = $true
} else {
    Import-Module $pesterModule.Path -Force
}

if ($failed) {
    Write-Host 'GATE FAILED — required test environment is unavailable.' -ForegroundColor Red
    exit 1
}

Write-Host '  ✅ PASS — pytest 8.3.5 and Pester 5.6.1 available' -ForegroundColor Green
$initialStatus = @(git -C $rootDir status --porcelain=v1)

# ─── REQUIRED: Source vs .github/** drift check ────────────────────────────
Write-Host '--- [REQUIRED] Source vs .github/** drift check ---'
try {
    $syncResult = & pwsh -NoProfile -File (Join-Path $rootDir 'tools\check-sync.ps1') 2>&1
    $syncExit = $LASTEXITCODE
    if ($syncExit -ne 0) {
        $failureKind = if ($syncExit -eq 1) { 'DRIFT' } else { 'CHECKER_ERROR' }
        Write-Host "  ❌ FAIL — read-only sync checker: $failureKind (exit $syncExit)" -ForegroundColor Red
        $syncResult | ForEach-Object { Write-Host "    $_" }
        $failed = $true
    } else {
        Write-Host "  ✅ PASS — no drift detected" -ForegroundColor Green
    }
} catch {
    Write-Host "  ❌ FAIL — check-sync.ps1 error: $_" -ForegroundColor Red
    $failed = $true
}

# ─── REQUIRED: Catalog count parity ───────────────────────────────────────
Write-Host ''
Write-Host '--- [REQUIRED] Catalog count parity ---'
try {
    $auditResult = & pwsh -File (Join-Path $rootDir 'tools\audit-catalog.ps1') 2>&1
    if ($LASTEXITCODE -ne 0) {
        Write-Host "  ❌ FAIL — audit-catalog.ps1 reported count mismatch" -ForegroundColor Red
        $auditResult | ForEach-Object { Write-Host "    $_" }
        $failed = $true
    } else {
        Write-Host "  ✅ PASS — catalog counts match expected" -ForegroundColor Green
    }
} catch {
    Write-Host "  ❌ FAIL — audit-catalog.ps1 error: $_" -ForegroundColor Red
    $failed = $true
}

# ─── CONDITIONAL: TypeScript / PowerShell type-check ──────────────────────
# Uncomment and adapt if type-checker is configured in this repo.
# Write-Host ''
# Write-Host '--- [CONDITIONAL] Type-check ---'
# & npx tsc --noEmit   # TypeScript example
# if ($LASTEXITCODE -ne 0) { $failed = $true }

# ─── CONDITIONAL: Lint ────────────────────────────────────────────────────
# Uncomment and adapt if linter is configured in this repo.
# Write-Host ''
# Write-Host '--- [CONDITIONAL] Lint ---'
# & npx eslint src/    # ESLint example
# if ($LASTEXITCODE -ne 0) { $failed = $true }

# ─── REQUIRED: Python tests ─────────────────────────────────────────────────
Write-Host ''
Write-Host '--- [REQUIRED] Python bootstrap tests ---'
& python -m pytest (Join-Path $rootDir 'scripts\tests\test_bootstrap.py') -q -p no:cacheprovider
if ($LASTEXITCODE -ne 0) { $failed = $true }

# ─── REQUIRED: PowerShell tests ─────────────────────────────────────────────
Write-Host ''
Write-Host '--- [REQUIRED] PowerShell bootstrap/tool tests ---'
$pesterCommand = {
    param($ModulePath, $RepositoryRoot)

    Import-Module $ModulePath -Force -ErrorAction Stop
    $result = Invoke-Pester -Path @(
        (Join-Path $RepositoryRoot 'scripts'),
        (Join-Path $RepositoryRoot 'tools')
    ) -PassThru -Output Detailed
    Write-Host "PESTER SUMMARY: Result=$($result.Result) Total=$($result.TotalCount) Passed=$($result.PassedCount) Failed=$($result.FailedCount) Skipped=$($result.SkippedCount) NotRun=$($result.NotRunCount) Inconclusive=$($result.InconclusiveCount) FailedContainers=$($result.FailedContainersCount)"
    if (
        $result.Result -ne 'Passed' -or
        $result.TotalCount -eq 0 -or
        $result.FailedCount -ne 0 -or
        $result.SkippedCount -ne 0 -or
        $result.NotRunCount -ne 0 -or
        $result.InconclusiveCount -ne 0 -or
        $result.FailedContainersCount -ne 0
    ) { exit 1 }
}
& pwsh -NoProfile -Command $pesterCommand -args $pesterModule.Path, $rootDir
if ($LASTEXITCODE -ne 0) { $failed = $true }

# ─── REQUIRED: Diff hygiene ─────────────────────────────────────────────────
Write-Host ''
Write-Host '--- [REQUIRED] git diff --check ---'
git -C $rootDir diff --check
if ($LASTEXITCODE -ne 0) { $failed = $true }

# ─── REQUIRED: Worktree invariant ───────────────────────────────────────────
$finalStatus = @(git -C $rootDir status --porcelain=v1)
if (-not [System.Linq.Enumerable]::SequenceEqual([string[]]$initialStatus, [string[]]$finalStatus)) {
    Write-Host '  ❌ FAIL — gate changed git status' -ForegroundColor Red
    $failed = $true
} else {
    Write-Host '  ✅ PASS — git status unchanged by gate' -ForegroundColor Green
}

# ─── CONDITIONAL: Build ───────────────────────────────────────────────────
# Uncomment and adapt if build step is configured in this repo.
# Write-Host ''
# Write-Host '--- [CONDITIONAL] Build ---'
# & npm run build
# if ($LASTEXITCODE -ne 0) { $failed = $true }

# ─── Verdict ──────────────────────────────────────────────────────────────
Write-Host ''
Write-Host '─────────────────────────────────────────────────────'
if ($failed) {
    Write-Host 'GATE FAILED — resolve issues above before proceeding.' -ForegroundColor Red
    Write-Host 'Do NOT hand off to agentic-eval or code-reviewer until gate passes.'
    exit 1
} elseif ($notes.Count -gt 0) {
    Write-Host 'GATE PASSED WITH NOTES' -ForegroundColor Yellow
    $notes | ForEach-Object { Write-Host "  ⚠️  $_" -ForegroundColor Yellow }
    Write-Host 'Log notes to 02-decision-log.md, then proceed.'
    exit 0
} else {
    Write-Host 'GATE PASSED — proceed to agentic-eval → code-reviewer.' -ForegroundColor Green
    exit 0
}
