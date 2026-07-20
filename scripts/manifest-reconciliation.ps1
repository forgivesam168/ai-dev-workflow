# Thin PowerShell dispatch for the deterministic Python report-only planner.
param(
    [Parameter(Mandatory = $true)][ValidateSet('conversion-plan', 'reconcile')][string]$Operation,
    [Parameter(Mandatory = $true)][string]$SourceRoot,
    [Parameter(Mandatory = $true)][string]$TargetPath
)

$python = Get-Command python -ErrorAction SilentlyContinue
if (-not $python) { $python = Get-Command python3 -ErrorAction SilentlyContinue }
if (-not $python) { throw 'Python is required for report-only planning.' }
$helper = Join-Path $PSScriptRoot 'manifest_reconciliation.py'
& $python.Source $helper --operation $Operation --source-root $SourceRoot --target-root $TargetPath
exit $LASTEXITCODE
