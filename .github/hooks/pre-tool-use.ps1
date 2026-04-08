# pre-tool-use.ps1 - Copilot CLI preToolUse hook (Windows)
# Blocks dangerous commands and scans for secrets
# fail-open: errors output allow to not block development

$ErrorActionPreference = 'Stop'

try {
    # Read tool input from stdin
    $rawInput = $input | Out-String
    $data = $rawInput | ConvertFrom-Json -ErrorAction SilentlyContinue

    $toolName = if ($data.tool_name) { $data.tool_name } else { '' }
    $command = ''
    if ($data.tool_input -and $data.tool_input.command) {
        $command = $data.tool_input.command
    }

    # === DANGEROUS COMMAND PATTERNS ===
    $dangerousPatterns = @(
        'rm -rf /',
        'rm -rf ~',
        'DROP TABLE',
        'DROP DATABASE',
        'TRUNCATE TABLE',
        'git push --force',
        'git push -f ',
        'chmod 777',
        'chmod -R 777',
        'curl.*\|.*sh',
        'wget.*\|.*bash',
        'format c:',
        'mkfs\.',
        '> /dev/sda',
        'Remove-Item.*-Recurse.*-Force.*C:\\',
        'Remove-Item.*-Recurse.*-Force.*\$env:',
        'Format-Volume'
    )

    foreach ($pattern in $dangerousPatterns) {
        if ($command -match [regex]::Escape($pattern) -or $command -imatch $pattern) {
            Write-Output ('{"decision":"block","reason":"Dangerous command pattern detected: ' + $pattern + '"}')
            exit 0
        }
    }

    # === SECRET SCANNING ===
    $secretPatterns = @(
        '[A-Za-z0-9+/]{40}',
        'sk-[a-zA-Z0-9]{20,}',
        'ghp_[A-Za-z0-9]{36}',
        'AKIA[0-9A-Z]{16}',
        '-----BEGIN.*PRIVATE KEY-----',
        'password\s*=\s*[''"][^''"]{8,}',
        'api_key\s*=\s*[''"][^''"]{8,}'
    )

    foreach ($pattern in $secretPatterns) {
        if ($command -match $pattern) {
            Write-Output '{"decision":"warn","reason":"Possible secret detected in command. Review before proceeding."}'
            exit 0
        }
    }

    # Allow by default
    Write-Output '{"decision":"allow"}'
    exit 0
}
catch {
    # fail-open: on error, allow the operation
    Write-Output '{"decision":"allow"}'
    exit 0
}
