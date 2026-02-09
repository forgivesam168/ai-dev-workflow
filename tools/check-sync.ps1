param(
  [string]$RepoRoot = (Resolve-Path "$PSScriptRoot/..").Path
)

function Get-FileHashHex($path) {
  return (Get-FileHash -Algorithm SHA256 -Path $path).Hash.ToLowerInvariant()
}

function Compare-File($src, $dst) {
  if (!(Test-Path $src)) { throw "Missing: $src" }
  if (!(Test-Path $dst)) { throw "Missing: $dst" }
  $a = Get-FileHashHex $src
  $b = Get-FileHashHex $dst
  if ($a -ne $b) {
    Write-Host "❌ Drift: $src != $dst" -ForegroundColor Red
    return $false
  }
  Write-Host "✅ OK: $src == $dst" -ForegroundColor Green
  return $true
}

function Compare-Dir($srcDir, $dstDir) {
  if (!(Test-Path $srcDir)) { throw "Missing: $srcDir" }
  if (!(Test-Path $dstDir)) { throw "Missing: $dstDir" }

  $ok = $true
  $srcFiles = Get-ChildItem -Recurse -File $srcDir | ForEach-Object {
    $_.FullName.Substring($srcDir.Length).TrimStart('\','/')
  }

  foreach ($rel in $srcFiles) {
    $src = Join-Path $srcDir $rel
    $dst = Join-Path $dstDir $rel
    if (!(Test-Path $dst)) {
      Write-Host "❌ Missing in dst: $dst" -ForegroundColor Red
      $ok = $false
      continue
    }
    if (-not (Compare-File $src $dst)) { $ok = $false }
  }
  return $ok
}

Push-Location $RepoRoot
try {
  $allOk = $true
  $allOk = (Compare-File "copilot-instructions.md" ".github/copilot-instructions.md") -and $allOk
  $allOk = (Compare-Dir  "agents" ".github/agents") -and $allOk
  $allOk = (Compare-Dir  "instructions" ".github/instructions") -and $allOk
  $allOk = (Compare-Dir  "prompts" ".github/prompts") -and $allOk
  $allOk = (Compare-Dir  "skills" ".github/skills") -and $allOk

  if (-not $allOk) {
    Write-Host "Sync check failed. Run: pwsh -File .\tools\sync-dotgithub.ps1" -ForegroundColor Yellow
    exit 1
  }
  Write-Host "All sync checks passed." -ForegroundColor Cyan
}
finally {
  Pop-Location
}
