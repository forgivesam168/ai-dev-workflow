param(
  [string]$RepoRoot = (Resolve-Path "$PSScriptRoot/..").Path
)

# Skills that exist in source but must NOT be deployed to .github/skills/
# (template-repo-only skills; meaningless outside the template repo itself)
$excludeSkills = @('gate-check')

function Copy-Folder($src, $dst) {
  if (Test-Path $dst) { Remove-Item -Recurse -Force $dst }
  Copy-Item -Recurse -Force $src $dst
}

Write-Host "RepoRoot: $RepoRoot" -ForegroundColor Cyan

$map = @(
  @{ Src = "copilot-instructions.md"; Dst = ".github/copilot-instructions.md"; Type="file" },
  @{ Src = "agents"; Dst = ".github/agents"; Type="dir" },
  @{ Src = "instructions"; Dst = ".github/instructions"; Type="dir" },
  @{ Src = "prompts"; Dst = ".github/prompts"; Type="dir" },
  @{ Src = "skills"; Dst = ".github/skills"; Type="dir" }
)

Push-Location $RepoRoot
try {
  foreach ($m in $map) {
    $srcPath = Join-Path $RepoRoot $m.Src
    $dstPath = Join-Path $RepoRoot $m.Dst

    if ($m.Type -eq "file") {
      if (!(Test-Path $srcPath)) { throw "Missing source file: $srcPath" }
      $dstDir = Split-Path $dstPath -Parent
      if (!(Test-Path $dstDir)) { New-Item -ItemType Directory -Force -Path $dstDir | Out-Null }
      Copy-Item -Force $srcPath $dstPath
      Write-Host "✅ Synced file: $($m.Src) -> $($m.Dst)" -ForegroundColor Green
    } else {
      if (!(Test-Path $srcPath)) { throw "Missing source dir: $srcPath" }
      $dstDir = Split-Path $dstPath -Parent
      if (!(Test-Path $dstDir)) { New-Item -ItemType Directory -Force -Path $dstDir | Out-Null }
      Copy-Folder $srcPath $dstPath
      Write-Host "✅ Synced dir:  $($m.Src) -> $($m.Dst)" -ForegroundColor Green

      # Remove excluded skills from .github/skills/ after sync
      if ($m.Src -eq "skills") {
        foreach ($excluded in $excludeSkills) {
          $excludedDst = Join-Path $dstPath $excluded
          if (Test-Path $excludedDst) {
            Remove-Item -Recurse -Force $excludedDst
            Write-Host "🚫 Excluded from deploy: $excluded" -ForegroundColor Yellow
          }
        }
      }
    }
  }
}
finally {
  Pop-Location
}

Write-Host "Done. (.github/** updated)" -ForegroundColor Cyan

# Skills count verification (source total minus excluded = deployed)
$sourceCount = (Get-ChildItem (Join-Path $RepoRoot "skills") -Recurse -Filter "SKILL.md").Count
$mirrorCount = (Get-ChildItem (Join-Path $RepoRoot ".github/skills") -Recurse -Filter "SKILL.md").Count
$expectedMirror = $sourceCount - $excludeSkills.Count
if ($mirrorCount -eq $expectedMirror) {
    Write-Host "✅ Skills in sync: $mirrorCount deployed ($($excludeSkills.Count) excluded: $($excludeSkills -join ', '))" -ForegroundColor Green
} else {
    Write-Warning "⚠️ Skills count mismatch: source=$sourceCount, deployed=$mirrorCount, expected=$expectedMirror"
}
