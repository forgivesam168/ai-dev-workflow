#Requires -Version 7
param(
    [string]$RepoRoot = (Resolve-Path "$PSScriptRoot/..").Path,
    [string]$SyncScriptPath = (Join-Path $PSScriptRoot 'sync-dotgithub.ps1')
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$managedDestinations = @(
    @{ Path = '.github/copilot-instructions.md'; Type = 'File' },
    @{ Path = '.github/agents'; Type = 'Directory' },
    @{ Path = '.github/instructions'; Type = 'Directory' },
    @{ Path = '.github/prompts'; Type = 'Directory' },
    @{ Path = '.github/skills'; Type = 'Directory' }
)

function Get-ManagedFiles {
    param(
        [string]$Root,
        [hashtable]$Destination
    )

    $fullPath = Join-Path $Root $Destination.Path
    if ($Destination.Type -eq 'File') {
        if (Test-Path $fullPath -PathType Leaf) {
            return ,([PSCustomObject]@{ RelativePath = $Destination.Path; FullPath = $fullPath })
        }
        return @()
    }

    if (-not (Test-Path $fullPath -PathType Container)) {
        return @()
    }

    $resolvedRoot = (Resolve-Path $Root).Path
    return @(Get-ChildItem $fullPath -Recurse -File | ForEach-Object {
        [PSCustomObject]@{
            RelativePath = $_.FullName.Substring($resolvedRoot.Length + 1).Replace('\', '/')
            FullPath = $_.FullName
        }
    })
}

$repoRootResolved = (Resolve-Path $RepoRoot).Path
$syncScriptResolved = (Resolve-Path $SyncScriptPath).Path
$tempRoot = Join-Path ([IO.Path]::GetTempPath()) ("ai-dev-workflow-sync-check-" + [guid]::NewGuid().ToString('N'))
$drift = [System.Collections.Generic.List[PSCustomObject]]::new()

try {
    New-Item -ItemType Directory -Path $tempRoot | Out-Null

    foreach ($source in @('copilot-instructions.md', 'agents', 'instructions', 'prompts', 'skills')) {
        $sourcePath = Join-Path $repoRootResolved $source
        if (-not (Test-Path $sourcePath)) {
            throw "Missing generator source: $source"
        }
        Copy-Item $sourcePath -Destination (Join-Path $tempRoot $source) -Recurse -Force
    }

    & pwsh -NoProfile -File $syncScriptResolved -RepoRoot $tempRoot *> $null
    if ($LASTEXITCODE -ne 0) {
        throw "Sync generator failed in temporary workspace with exit code $LASTEXITCODE"
    }

    foreach ($destination in $managedDestinations) {
        $expected = @{}
        foreach ($file in @(Get-ManagedFiles -Root $tempRoot -Destination $destination)) {
            $expected[$file.RelativePath] = $file.FullPath
        }

        $actual = @{}
        foreach ($file in @(Get-ManagedFiles -Root $repoRootResolved -Destination $destination)) {
            $actual[$file.RelativePath] = $file.FullPath
        }

        foreach ($relativePath in @($expected.Keys + $actual.Keys | Sort-Object -Unique)) {
            if (-not $actual.ContainsKey($relativePath)) {
                $drift.Add([PSCustomObject]@{ Kind = 'MISSING'; Path = $relativePath })
                continue
            }
            if (-not $expected.ContainsKey($relativePath)) {
                $drift.Add([PSCustomObject]@{ Kind = 'EXTRA'; Path = $relativePath })
                continue
            }

            $expectedHash = (Get-FileHash $expected[$relativePath] -Algorithm SHA256).Hash
            $actualHash = (Get-FileHash $actual[$relativePath] -Algorithm SHA256).Hash
            if ($expectedHash -ne $actualHash) {
                $drift.Add([PSCustomObject]@{ Kind = 'CONTENT_MISMATCH'; Path = $relativePath })
            }
        }
    }

    if ($drift.Count -gt 0) {
        Write-Host 'SYNC DRIFT DETECTED' -ForegroundColor Red
        $drift | Sort-Object Kind, Path | Format-Table -AutoSize Kind, Path
        exit 1
    }

    Write-Host 'SYNC CHECK PASSED: managed .github destinations match generated output.' -ForegroundColor Green
    exit 0
}
catch {
    [Console]::Error.WriteLine("SYNC CHECK ERROR: $($_.Exception.Message)")
    exit 2
}
finally {
    if (Test-Path $tempRoot) {
        Remove-Item -LiteralPath $tempRoot -Recurse -Force
    }
}
