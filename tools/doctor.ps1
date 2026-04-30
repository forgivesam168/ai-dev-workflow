#Requires -Version 7
<#
.SYNOPSIS
    Audits the deployed state of the AI workflow template.
.DESCRIPTION
    Runs three checks:
    1. Source vs .github/** parity (content comparison per file)
    2. Manifest parity (.ai-workflow-install.json, if present)
    3. Catalog integrity (delegates to tools/audit-catalog.ps1)

    Verdicts:
      DOCTOR PASSED           — all checks pass
      DOCTOR PASSED WITH NOTES — minor issues; non-blocking
      DOCTOR FAILED           — drift or missing files detected
.EXAMPLE
    pwsh -File .\tools\doctor.ps1
#>
param(
    [string]$RepoRoot = (Resolve-Path "$PSScriptRoot/..").Path,
    # Target mode: audit deployed state at another repo (reads its manifest)
    [string]$Target   = ""
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$IsTargetMode = $Target -ne ""
$CheckRoot    = if ($IsTargetMode) { (Resolve-Path $Target -ErrorAction Stop).Path } else { $RepoRoot }

$issues  = [System.Collections.Generic.List[string]]::new()
$notes   = [System.Collections.Generic.List[string]]::new()
$passing = [System.Collections.Generic.List[string]]::new()

# ─── Check 1: Source vs .github/** parity (self mode only) ───────────────
if (-not $IsTargetMode) {
Write-Host 'Check 1: Source vs .github/** parity...' -ForegroundColor Cyan

$syncMap = @(
    @{ Src = 'copilot-instructions.md'; Dst = '.github/copilot-instructions.md'; Type = 'file' }
    @{ Src = 'agents';       Dst = '.github/agents';       Type = 'dir' }
    @{ Src = 'instructions'; Dst = '.github/instructions'; Type = 'dir' }
    @{ Src = 'prompts';      Dst = '.github/prompts';      Type = 'dir' }
    @{ Src = 'skills';       Dst = '.github/skills';       Type = 'dir' }
)

$driftItems = @()
foreach ($m in $syncMap) {
    $src = Join-Path $RepoRoot $m.Src
    $dst = Join-Path $RepoRoot $m.Dst

    if (-not (Test-Path $src)) { $issues.Add("Missing source: $($m.Src)"); continue }
    if (-not (Test-Path $dst)) { $issues.Add("Missing mirror: $($m.Dst) (run sync-dotgithub.ps1)"); continue }

    if ($m.Type -eq 'file') {
        $h1 = (Get-FileHash $src -Algorithm SHA256).Hash
        $h2 = (Get-FileHash $dst -Algorithm SHA256).Hash
        if ($h1 -ne $h2) { $driftItems += "$($m.Src) → $($m.Dst): MODIFIED" }
    } else {
        Get-ChildItem $src -Recurse -File | ForEach-Object {
            $rel     = $_.FullName.Substring($src.Length).TrimStart([IO.Path]::DirectorySeparatorChar)
            $dstFile = Join-Path $dst $rel
            if (-not (Test-Path $dstFile)) {
                $driftItems += "$($m.Src)/$rel → missing in $($m.Dst)"
            } else {
                $h1 = (Get-FileHash $_.FullName -Algorithm SHA256).Hash
                $h2 = (Get-FileHash $dstFile    -Algorithm SHA256).Hash
                if ($h1 -ne $h2) { $driftItems += "$($m.Src)/$rel → $($m.Dst)/${rel} MODIFIED" }
            }
        }
    }
}

if ($driftItems.Count -gt 0) {
    foreach ($d in $driftItems) { $issues.Add("Source vs .github drift: $d") }
} else {
    $agentCount  = (Get-ChildItem (Join-Path $RepoRoot 'agents')  -Filter '*.agent.md').Count
    $promptCount = (Get-ChildItem (Join-Path $RepoRoot 'prompts') -Filter '*.prompt.md').Count
    $skillCount  = (Get-ChildItem (Join-Path $RepoRoot 'skills')  -Directory).Count
    $passing.Add("Source vs .github/** parity: $agentCount agents, $promptCount prompts, $skillCount skills — all in sync")
}
} # end if (-not $IsTargetMode) — Check 1

# ─── Check 2: Manifest parity ─────────────────────────────────────────────
Write-Host 'Check 2: Manifest parity...' -ForegroundColor Cyan

$manifestPath = Join-Path $CheckRoot '.ai-workflow-install.json'
if (-not (Test-Path $manifestPath)) {
    $notes.Add('No .ai-workflow-install.json found — manifest check skipped (run install-apply to create one)')
} else {
    $manifest    = Get-Content $manifestPath -Raw | ConvertFrom-Json
    $staleItems  = @()
    foreach ($comp in $manifest.components) {
        if (-not $comp.name) { continue }
        $name       = $comp.name.TrimEnd('/')
        $deployedAt = Join-Path $CheckRoot ".github/$name"
        if (-not (Test-Path $deployedAt)) {
            $staleItems += "$name : recorded in manifest but not found in .github/"
        }
    }
    if ($staleItems.Count -gt 0) {
        foreach ($s in $staleItems) { $issues.Add("Manifest drift: $s") }
    } else {
        $sourceInfo = if ($manifest.source_ref) { " (source_ref: $($manifest.source_ref))" } else { "" }
        $passing.Add("Manifest parity: $($manifest.components.Count) component(s) all present$sourceInfo")
    }
}

# ─── Check 3: Catalog integrity (self mode only) ─────────────────────────
if (-not $IsTargetMode) {
Write-Host 'Check 3: Catalog integrity...' -ForegroundColor Cyan

$auditScript = Join-Path $PSScriptRoot 'audit-catalog.ps1'
if (-not (Test-Path $auditScript)) {
    $notes.Add('tools/audit-catalog.ps1 not found — catalog check skipped')
} else {
    $null = & pwsh -File $auditScript 2>&1
    if ($LASTEXITCODE -eq 0) {
        $passing.Add('Catalog integrity: counts match expected')
    } else {
        $issues.Add('Catalog integrity FAIL (run tools/audit-catalog.ps1 for details)')
    }
}
} # end if (-not $IsTargetMode) — Check 3

# ─── Verdict ──────────────────────────────────────────────────────────────
$modeLabel = if ($IsTargetMode) { "部署稽核模式 → $CheckRoot" } else { "自身模式" }
Write-Host ''
Write-Host '╔══════════════════════════════════════════════════════════════╗'
Write-Host '║            AI Workflow Template — 健康檢查 (Doctor)          ║'
Write-Host "║  模式：$($modeLabel.PadRight(49))║"
Write-Host '╚══════════════════════════════════════════════════════════════╝'
Write-Host ''

foreach ($p in $passing) { Write-Host "  ✅ $p" -ForegroundColor Green  }
foreach ($n in $notes)   { Write-Host "  ⚠️  $n" -ForegroundColor Yellow }
foreach ($i in $issues)  { Write-Host "  ❌ $i" -ForegroundColor Red    }

Write-Host ''
if ($issues.Count -gt 0) {
    Write-Host 'DOCTOR FAILED' -ForegroundColor Red
    Write-Host 'Remediation: run sync-dotgithub.ps1 or install-apply to fix drift.' -ForegroundColor Yellow
    exit 1
} elseif ($notes.Count -gt 0) {
    Write-Host 'DOCTOR PASSED WITH NOTES' -ForegroundColor Yellow
    exit 0
} else {
    Write-Host 'DOCTOR PASSED' -ForegroundColor Green
    exit 0
}
