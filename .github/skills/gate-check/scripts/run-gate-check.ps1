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

$rootDir = Split-Path (Split-Path $PSScriptRoot -Parent) -Parent
$failed  = $false
$notes   = [System.Collections.Generic.List[string]]::new()

Write-Host ''
Write-Host '╔══════════════════════════════════════════════════════╗'
Write-Host '║               AI Workflow Gate-Check                 ║'
Write-Host '╚══════════════════════════════════════════════════════╝'
Write-Host ''

# ─── REQUIRED: Source vs .github/** drift check ────────────────────────────
Write-Host '--- [REQUIRED] Source vs .github/** drift check ---'
try {
    $syncResult = & pwsh -File (Join-Path $rootDir 'tools\sync-dotgithub.ps1') 2>&1
    if ($LASTEXITCODE -ne 0) {
        Write-Host "  ❌ FAIL — sync-dotgithub.ps1 reported drift" -ForegroundColor Red
        $failed = $true
    } else {
        Write-Host "  ✅ PASS — no drift detected" -ForegroundColor Green
    }
} catch {
    Write-Host "  ❌ FAIL — sync-dotgithub.ps1 error: $_" -ForegroundColor Red
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

# ─── CONDITIONAL: Tests ───────────────────────────────────────────────────
# Uncomment and adapt if test suite is configured in this repo.
# Write-Host ''
# Write-Host '--- [CONDITIONAL] Tests ---'
# & npx jest --passWithNoTests
# if ($LASTEXITCODE -ne 0) { $failed = $true }

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
