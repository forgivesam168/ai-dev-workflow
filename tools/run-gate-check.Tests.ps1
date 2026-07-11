Describe 'run-gate-check prerequisites' {
    It 'fails explicitly when pinned Pester is unavailable' {
        $gatePath = Join-Path $PSScriptRoot '..\skills\gate-check\scripts\run-gate-check.ps1'
        $emptyModulePath = Join-Path $TestDrive 'empty-modules'
        New-Item -ItemType Directory -Path $emptyModulePath | Out-Null
        $originalModulePath = $env:PSModulePath

        try {
            $env:PSModulePath = $emptyModulePath
            $output = & pwsh -NoProfile -File $gatePath 2>&1
            $exitCode = $LASTEXITCODE
        }
        finally {
            $env:PSModulePath = $originalModulePath
        }

        $exitCode | Should -Be 1
        ($output -join "`n") | Should -Match 'ENVIRONMENT_PREREQUISITE_MISSING.*Pester 5\.6\.1'
    }
}
