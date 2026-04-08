# post-tool-use.ps1 - Copilot CLI postToolUse hook (Windows)
# Logs tool execution results for audit
# fail-open: errors output allow to not block development

$ErrorActionPreference = 'Stop'

try {
    # Read tool input from stdin
    $rawInput = $input | Out-String
    $data = $rawInput | ConvertFrom-Json -ErrorAction SilentlyContinue

    $logDir = '.copilot/logs'
    if (-not (Test-Path $logDir)) {
        New-Item -ItemType Directory -Path $logDir -Force | Out-Null
    }
    $logFile = Join-Path $logDir 'audit.log'

    $timestamp = (Get-Date).ToUniversalTime().ToString('yyyy-MM-ddTHH:mm:ssZ')
    $tool = if ($data.tool_name) { $data.tool_name } else { 'unknown' }
    $exitCode = if ($null -ne $data.exit_code) { $data.exit_code } else { '?' }

    Add-Content -Path $logFile -Value "[$timestamp] TOOL_USED tool=$tool exit_code=$exitCode"

    Write-Output '{"decision":"allow"}'
    exit 0
}
catch {
    # fail-open: on error, allow the operation
    Write-Output '{"decision":"allow"}'
    exit 0
}
