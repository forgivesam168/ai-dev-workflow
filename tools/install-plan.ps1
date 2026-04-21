#Requires -Version 7
<#
.SYNOPSIS
    Dry-run: shows what install-apply would deploy to .github/**.
.DESCRIPTION
    Lists every component and its status. No files are written.
    Status: NEW | EXISTS (skip) | EXISTS (overwrite with --force) | MISSING SOURCE
.PARAMETER Json
    Emit machine-readable JSON (schema_version is first field per AC-3).
.EXAMPLE
    pwsh -File .\tools\install-plan.ps1
    pwsh -File .\tools\install-plan.ps1 -Json
#>
param(
    [switch]$Json,
    [string]$RepoRoot = (Resolve-Path "$PSScriptRoot/..").Path
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

# ─── Status helpers ────────────────────────────────────────────────────────
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
    $src    = Join-Path $RepoRoot $relSrc
    $dst    = Join-Path $RepoRoot $relDst
    $status = if ($type -eq 'dir') { Get-DirStatus $src $dst } else { Get-FileStatus $src $dst }
    $components.Add([PSCustomObject]@{
        name   = $name
        source = ("./$relSrc" -replace '\\', '/')
        target = ("./$relDst" -replace '\\', '/')
        status = $status
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

# ─── Output ────────────────────────────────────────────────────────────────
if ($Json) {
    [ordered]@{
        schema_version = 1
        components     = @($components | ForEach-Object {
            [ordered]@{ name = $_.name; source = $_.source; target = $_.target; status = $_.status }
        })
    } | ConvertTo-Json -Depth 4
    exit 0
}

Write-Host ''
Write-Host '╔══════════════════════════════════════════════════════════════╗'
Write-Host '║            AI Workflow Template — Install Plan               ║'
Write-Host '╚══════════════════════════════════════════════════════════════╝'
Write-Host ''

$components | Format-Table -AutoSize @(
    @{L='Component'; E='name';   Width=42},
    @{L='Source';    E='source'; Width=38},
    @{L='Target';    E='target'; Width=38},
    @{L='Status';    E={
        switch -Wildcard ($_.status) {
            'NEW'             { '🆕 NEW' }
            'EXISTS (skip)'   { '✅ EXISTS (skip)' }
            'EXISTS (overwr*' { '⚠️  EXISTS (overwrite with --force)' }
            'MISSING SOURCE'  { '❌ MISSING SOURCE' }
            default           { $_.status }
        }
    }; Width=40}
)

$counts = $components | Group-Object status | ForEach-Object { "$($_.Count) $($_.Name)" }
Write-Host ("Summary: " + ($counts -join '  |  ')) -ForegroundColor Cyan

$missCount = @($components | Where-Object { $_.status -eq 'MISSING SOURCE' }).Count
if ($missCount -gt 0) {
    Write-Host "❌ $missCount missing source(s) — check repo integrity." -ForegroundColor Red
    exit 1
}
exit 0
