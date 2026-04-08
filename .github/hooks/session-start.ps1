# session-start.ps1 - Copilot CLI sessionStart hook (Windows)
# Logs session start for audit trail
# fail-open: errors output allow to not block development

$ErrorActionPreference = 'Stop'

try {
    $logDir = '.copilot/logs'
    if (-not (Test-Path $logDir)) {
        New-Item -ItemType Directory -Path $logDir -Force | Out-Null
    }
    $logFile = Join-Path $logDir 'audit.log'

    $timestamp = (Get-Date).ToUniversalTime().ToString('yyyy-MM-ddTHH:mm:ssZ')
    $user = git config user.name 2>$null
    if (-not $user) { $user = 'unknown' }
    $email = git config user.email 2>$null
    if (-not $email) { $email = 'unknown' }
    $dir = Get-Location

    Add-Content -Path $logFile -Value "[$timestamp] SESSION_START user=$user email=$email dir=$dir"

    Write-Output '{"decision":"allow"}'
    exit 0
}
catch {
    # fail-open: on error, allow the operation
    Write-Output '{"decision":"allow"}'
    exit 0
}
