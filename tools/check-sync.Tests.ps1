BeforeAll {
    $script:CheckerPath = Join-Path $PSScriptRoot 'check-sync.ps1'
    $script:SyncPath = Join-Path $PSScriptRoot 'sync-dotgithub.ps1'

    function New-SyncFixture {
        param([string]$Root)

        New-Item -ItemType Directory -Path $Root | Out-Null
        Set-Content -Path (Join-Path $Root 'copilot-instructions.md') -Value 'constitution'
        foreach ($directory in @('agents', 'instructions', 'prompts', 'skills/demo-skill')) {
            New-Item -ItemType Directory -Path (Join-Path $Root $directory) -Force | Out-Null
        }
        Set-Content -Path (Join-Path $Root 'agents/demo.agent.md') -Value 'agent'
        Set-Content -Path (Join-Path $Root 'instructions/demo.instructions.md') -Value 'instruction'
        Set-Content -Path (Join-Path $Root 'prompts/demo.prompt.md') -Value 'prompt'
        Set-Content -Path (Join-Path $Root 'skills/demo-skill/SKILL.md') -Value 'skill'

        & pwsh -NoProfile -File $script:SyncPath -RepoRoot $Root *> $null
        $LASTEXITCODE | Should -Be 0
    }

    function Invoke-SyncChecker {
        param([string]$Root)

        $output = & pwsh -NoProfile -File $script:CheckerPath -RepoRoot $Root -SyncScriptPath $script:SyncPath 2>&1
        return [PSCustomObject]@{ ExitCode = $LASTEXITCODE; Output = ($output -join "`n") }
    }

    function Get-FixtureFingerprint {
        param([string]$Root)

        return @(Get-ChildItem $Root -Recurse | ForEach-Object {
            $relative = $_.FullName.Substring($Root.Length).Replace('\', '/')
            if ($_.PSIsContainer) { "D:$relative" } else { "F:${relative}:$((Get-FileHash $_.FullName).Hash)" }
        } | Sort-Object)
    }
}

Describe 'check-sync read-only managed-destination contract' {
    BeforeEach {
        $fixture = Join-Path $TestDrive ([guid]::NewGuid().ToString('N'))
        New-SyncFixture -Root $fixture
    }

    It 'passes a clean generated mirror without changing the fixture' {
        $before = Get-FixtureFingerprint -Root $fixture
        $result = Invoke-SyncChecker -Root $fixture
        $after = Get-FixtureFingerprint -Root $fixture

        $result.ExitCode | Should -Be 0
        @(Compare-Object $before $after).Count | Should -Be 0
    }

    It 'fails for content mismatch in a managed destination' {
        Set-Content -Path (Join-Path $fixture '.github/agents/demo.agent.md') -Value 'drift'
        $before = Get-FixtureFingerprint -Root $fixture
        $result = Invoke-SyncChecker -Root $fixture
        $after = Get-FixtureFingerprint -Root $fixture

        $result.ExitCode | Should -Be 1
        $result.Output | Should -Match 'CONTENT_MISMATCH'
        $result.Output | Should -Match '\.github/agents/demo\.agent\.md'
        @(Compare-Object $before $after).Count | Should -Be 0
    }

    It 'fails for missing and extra files in a managed directory' {
        Remove-Item -LiteralPath (Join-Path $fixture '.github/prompts/demo.prompt.md')
        Set-Content -Path (Join-Path $fixture '.github/prompts/extra.prompt.md') -Value 'extra'
        $before = Get-FixtureFingerprint -Root $fixture
        $result = Invoke-SyncChecker -Root $fixture
        $after = Get-FixtureFingerprint -Root $fixture

        $result.ExitCode | Should -Be 1
        $result.Output | Should -Match 'MISSING'
        $result.Output | Should -Match 'EXTRA'
        @(Compare-Object $before $after).Count | Should -Be 0
    }

    It 'ignores unmanaged .github paths' {
        New-Item -ItemType Directory -Path (Join-Path $fixture '.github/workflows') -Force | Out-Null
        Set-Content -Path (Join-Path $fixture '.github/workflows/ci.yml') -Value 'workflow'
        Set-Content -Path (Join-Path $fixture '.github/CODEOWNERS') -Value '* @owner'
        Set-Content -Path (Join-Path $fixture '.github/dependabot.yml') -Value 'version: 2'
        Set-Content -Path (Join-Path $fixture '.github/unmanaged.txt') -Value 'unmanaged'
        $before = Get-FixtureFingerprint -Root $fixture
        $result = Invoke-SyncChecker -Root $fixture
        $after = Get-FixtureFingerprint -Root $fixture

        $result.ExitCode | Should -Be 0
        @(Compare-Object $before $after).Count | Should -Be 0
    }

    It 'returns checker error without changing a fixture with missing generator source' {
        Remove-Item -LiteralPath (Join-Path $fixture 'agents') -Recurse
        $before = Get-FixtureFingerprint -Root $fixture
        $result = Invoke-SyncChecker -Root $fixture
        $after = Get-FixtureFingerprint -Root $fixture

        $result.ExitCode | Should -Be 2
        $result.Output | Should -Match 'SYNC CHECK ERROR'
        @(Compare-Object $before $after).Count | Should -Be 0
    }
}
