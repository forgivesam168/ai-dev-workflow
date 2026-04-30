#Requires -Version 7
<#
.SYNOPSIS
    Deploys template components from source to .github/**.
.DESCRIPTION
    Default: skip existing files (preserves local customizations in adopter repos).
    Use -Force to overwrite files that differ from source.
    Use -EnableMemory to create .ai-workflow-memory/ skeleton.
    Idempotent: re-running is safe.
.PARAMETER Force
    Overwrite target files that differ from source.
.PARAMETER EnableMemory
    Initialize .ai-workflow-memory/ skeleton (opt-in per AC-3).
.PARAMETER DryRun
    Delegates to install-plan.ps1 without making any changes.
.EXAMPLE
    pwsh -File .\tools\install-apply.ps1
    pwsh -File .\tools\install-apply.ps1 -Force
    pwsh -File .\tools\install-apply.ps1 -EnableMemory
#>
param(
    [switch]$Force,
    [switch]$EnableMemory,
    [switch]$DryRun,
    [string]$RepoRoot = (Resolve-Path "$PSScriptRoot/..").Path,
    # Deploy mode: copy to a different repo's .github/
    [string]$Target   = ""
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

# Self mode: deploy to this template repo's .github/**
# Deploy mode (-Target <path>): deploy to another repo's .github/**
$DeployRoot = if ($Target) { (Resolve-Path $Target -ErrorAction Stop).Path } else { $RepoRoot }

if ($DryRun) {
    Write-Host 'DryRun 模式 — 委派 install-plan 預覽。' -ForegroundColor Cyan
    $planArgs = @{ RepoRoot = $RepoRoot }
    if ($Target) { $planArgs['Target'] = $Target }
    & (Join-Path $PSScriptRoot 'install-plan.ps1') @planArgs
    exit $LASTEXITCODE
}

# ─── Status helpers (same logic as install-plan) ──────────────────────────
function Get-FileStatus([string]$src, [string]$dst) {
    if (-not (Test-Path $src)) { return 'MISSING SOURCE' }
    if (-not (Test-Path $dst)) { return 'NEW' }
    $h1 = (Get-FileHash $src -Algorithm SHA256).Hash
    $h2 = (Get-FileHash $dst -Algorithm SHA256).Hash
    if ($h1 -eq $h2) { 'EXISTS (skip)' } else { 'EXISTS (overwrite with --force)' }
}

function Get-DirStatus([string]$src, [string]$dst) {
    if (-not (Test-Path $src)) { return 'MISSING SOURCE' }
    if (-not (Test-Path $dst)) { return 'NEW' }
    $hasDrift = $false
    Get-ChildItem $src -Recurse -File | ForEach-Object {
        if ($hasDrift) { return }
        $rel     = $_.FullName.Substring($src.Length).TrimStart([IO.Path]::DirectorySeparatorChar)
        $dstFile = Join-Path $dst $rel
        if (-not (Test-Path $dstFile)) { $hasDrift = $true; return }
        $h1 = (Get-FileHash $_.FullName -Algorithm SHA256).Hash
        $h2 = (Get-FileHash $dstFile    -Algorithm SHA256).Hash
        if ($h1 -ne $h2) { $hasDrift = $true }
    }
    if ($hasDrift) { 'EXISTS (overwrite with --force)' } else { 'EXISTS (skip)' }
}

# ─── Component enumeration ─────────────────────────────────────────────────
$components = [System.Collections.Generic.List[PSCustomObject]]::new()

function Add-Component([string]$name, [string]$relSrc, [string]$relDst, [string]$type) {
    $src    = Join-Path $RepoRoot  $relSrc
    $dst    = Join-Path $DeployRoot $relDst
    $status = if ($type -eq 'dir') { Get-DirStatus $src $dst } else { Get-FileStatus $src $dst }
    $components.Add([PSCustomObject]@{
        name    = $name
        srcPath = $src
        dstPath = $dst
        type    = $type
        status  = $status
    })
}

Add-Component 'copilot-instructions.md' `
    'copilot-instructions.md' '.github/copilot-instructions.md' 'file'

Get-ChildItem (Join-Path $RepoRoot 'agents')       -Filter '*.agent.md'        -ErrorAction SilentlyContinue |
    ForEach-Object { Add-Component "agents/$($_.Name)"       "agents/$($_.Name)"       ".github/agents/$($_.Name)"       'file' }

Get-ChildItem (Join-Path $RepoRoot 'instructions') -Filter '*.instructions.md' -ErrorAction SilentlyContinue |
    ForEach-Object { Add-Component "instructions/$($_.Name)" "instructions/$($_.Name)" ".github/instructions/$($_.Name)" 'file' }

Get-ChildItem (Join-Path $RepoRoot 'prompts')      -Filter '*.prompt.md'       -ErrorAction SilentlyContinue |
    ForEach-Object { Add-Component "prompts/$($_.Name)"      "prompts/$($_.Name)"      ".github/prompts/$($_.Name)"      'file' }

Get-ChildItem (Join-Path $RepoRoot 'skills')       -Directory                  -ErrorAction SilentlyContinue |
    ForEach-Object { Add-Component "skills/$($_.Name)/" "skills/$($_.Name)" ".github/skills/$($_.Name)" 'dir' }

# ─── Abort on missing sources ──────────────────────────────────────────────
$missing = @($components | Where-Object { $_.status -eq 'MISSING SOURCE' })
if ($missing.Count -gt 0) {
    foreach ($m in $missing) { Write-Host "❌ Missing source: $($m.name)" -ForegroundColor Red }
    throw "Aborting: $($missing.Count) missing source(s). Check repo integrity."
}

# ─── Apply ────────────────────────────────────────────────────────────────
$applied  = [System.Collections.Generic.List[PSCustomObject]]::new()
$appliedCount = 0
$skippedCount = 0

$modeLabel = if ($Target) { "部署模式 → $DeployRoot" } else { "自身模式 → .github/**" }
Write-Host ''
Write-Host '╔══════════════════════════════════════════════════════════════╗'
Write-Host '║          AI Workflow Template — 安裝執行 (Install Apply)     ║'
Write-Host "║  模式：$($modeLabel.PadRight(49))║"
Write-Host '╚══════════════════════════════════════════════════════════════╝'
Write-Host ''

foreach ($c in $components) {
    $shouldApply = $c.status -eq 'NEW' -or ($Force -and $c.status -like 'EXISTS (overwrite*')

    if (-not $shouldApply) {
        Write-Host "  ⏭  SKIP  $($c.name)" -ForegroundColor DarkGray
        $skippedCount++
        continue
    }

    $dstDir = Split-Path $c.dstPath -Parent
    if (-not (Test-Path $dstDir)) { New-Item -ItemType Directory -Force -Path $dstDir | Out-Null }

    if ($c.type -eq 'file') {
        Copy-Item -Force $c.srcPath $c.dstPath
        $hash = (Get-FileHash $c.dstPath -Algorithm SHA256).Hash
        $applied.Add([PSCustomObject]@{
            name         = $c.name
            installed_at = (Get-Date -Format 'o')
            source_hash  = "sha256:$hash"
        })
    } else {
        if (Test-Path $c.dstPath) { Remove-Item -Recurse -Force $c.dstPath }
        Copy-Item -Recurse -Force $c.srcPath $c.dstPath
        $applied.Add([PSCustomObject]@{
            name         = $c.name
            installed_at = (Get-Date -Format 'o')
            source_hash  = $null
        })
    }

    Write-Host "  ✅ APPLY $($c.name)" -ForegroundColor Green
    $appliedCount++
}

# ─── Write sync manifest (always — records current deployed state) ────────
$gitRef = & git -C $RepoRoot rev-parse --short HEAD 2>$null

# Enumerate everything currently in .github/** to record full deployed state
$deployedComponents = [System.Collections.Generic.List[PSCustomObject]]::new()
foreach ($c in $components) {
    if (Test-Path $c.dstPath) {
        $hash = if ($c.type -eq 'file') {
            "sha256:$((Get-FileHash $c.dstPath -Algorithm SHA256).Hash)"
        } else { $null }
        $deployedComponents.Add([PSCustomObject]@{
            name         = $c.name
            installed_at = (Get-Date -Format 'o')
            source_hash  = $hash
        })
    }
}

$manifestPath = Join-Path $DeployRoot '.ai-workflow-install.json'
[ordered]@{
    schema_version = 1
    installed_at   = (Get-Date -Format 'o')
    source_ref     = if ($gitRef) { $gitRef } else { 'unknown' }
    components     = @($deployedComponents)
} | ConvertTo-Json -Depth 4 | Set-Content -Path $manifestPath -Encoding UTF8
Write-Host ''
Write-Host "📄 Manifest written: .ai-workflow-install.json ($($deployedComponents.Count) components)" -ForegroundColor Cyan

# ─── Optional: enable memory skeleton ────────────────────────────────────
if ($EnableMemory) {
    $memDir     = Join-Path $DeployRoot '.ai-workflow-memory'
    $journalDir = Join-Path $memDir 'session-journal'

    foreach ($d in @($memDir, $journalDir)) {
        if (-not (Test-Path $d)) { New-Item -ItemType Directory -Force -Path $d | Out-Null }
    }

    $contextFile = Join-Path $memDir 'PROJECT_CONTEXT.md'
    if (-not (Test-Path $contextFile)) {
        @'
# Project Context

> This file is maintained by AI agents. Update when project fundamentals change.

## Project Overview
<!-- Describe the project purpose and scope -->

## Tech Stack
<!-- List key technologies, frameworks, languages -->

## Key Decisions
<!-- Log major architectural or design decisions -->

## Important Files
<!-- Reference key files and their purpose -->
'@ | Set-Content -Path $contextFile -Encoding UTF8
    }

    $stateFile = Join-Path $memDir 'CURRENT_STATE.md'
    if (-not (Test-Path $stateFile)) {
        @"
# Current State

> Updated at the end of each AI session.

**Last Updated**: $(Get-Date -Format 'yyyy-MM-dd')
**Current Stage**: Initial setup

## What's Done
- Memory skeleton initialized via: install-apply -EnableMemory

## What's Next
<!-- Describe the next planned action -->

## Open Questions
<!-- List any unresolved questions or decisions -->
"@ | Set-Content -Path $stateFile -Encoding UTF8
    }

    $gitkeep = Join-Path $journalDir '.gitkeep'
    if (-not (Test-Path $gitkeep)) { '' | Set-Content -Path $gitkeep -Encoding UTF8 }

    Write-Host "🧠 Memory skeleton initialized: .ai-workflow-memory/" -ForegroundColor Magenta
}

# ─── Summary ──────────────────────────────────────────────────────────────
Write-Host ''
$driftCount = @($components | Where-Object { $_.status -like 'EXISTS (overwrite*' }).Count
Write-Host "Summary: $appliedCount applied  |  $skippedCount skipped" -ForegroundColor Cyan
if (-not $Force -and $driftCount -gt 0) {
    Write-Host "ℹ️  $driftCount component(s) differ from source (use -Force to overwrite)." -ForegroundColor Yellow
}
exit 0
