BeforeAll {
    $script:AuditPath = Join-Path $PSScriptRoot 'audit-catalog.ps1'
    $script:RequiredChangeFiles = @(
        '00-intake.md', '01-brainstorm.md', '02-decision-log.md', '03-spec.md',
        '04-plan.md', '05-test-plan.md', '06-impact-analysis.md', '99-archive.md'
    )

    function New-CatalogFixture {
        param([string]$Root)

        foreach ($directory in @('agents', 'prompts', 'skills', '.github/skills', 'instructions')) {
            New-Item -ItemType Directory -Path (Join-Path $Root $directory) -Force | Out-Null
        }
        1..9 | ForEach-Object { Set-Content (Join-Path $Root "agents/agent-$_.agent.md") 'agent' }
        1..10 | ForEach-Object { Set-Content (Join-Path $Root "prompts/prompt-$_.prompt.md") 'prompt' }
        1..34 | ForEach-Object {
            $name = "skill-$_"
            New-Item -ItemType Directory -Path (Join-Path $Root "skills/$name") | Out-Null
            New-Item -ItemType Directory -Path (Join-Path $Root ".github/skills/$name") | Out-Null
            Set-Content (Join-Path $Root "skills/$name/SKILL.md") 'skill'
            Set-Content (Join-Path $Root ".github/skills/$name/SKILL.md") 'skill'
        }
        New-Item -ItemType Directory -Path (Join-Path $Root 'skills/gate-check') | Out-Null
        Set-Content (Join-Path $Root 'skills/gate-check/SKILL.md') 'maintainer'
        $contract = $script:RequiredChangeFiles -join "`n"
        Set-Content (Join-Path $Root 'WORKFLOW.md') $contract
        Set-Content (Join-Path $Root 'instructions/changes.instructions.md') $contract
    }

    function Invoke-CatalogAudit {
        param([string]$Root)

        $output = & pwsh -NoProfile -File $script:AuditPath -RepoRoot $Root 2>&1
        return [PSCustomObject]@{ ExitCode = $LASTEXITCODE; Output = ($output -join "`n") }
    }
}

Describe 'catalog 35 total / 34 adopter / 1 maintainer-only contract' {
    BeforeEach {
        $fixture = Join-Path $TestDrive ([guid]::NewGuid().ToString('N'))
        New-CatalogFixture -Root $fixture
    }

    It 'passes the reviewed catalog and deployment contract' {
        $result = Invoke-CatalogAudit -Root $fixture

        $result.ExitCode | Should -Be 0
        $result.Output | Should -Match 'Skills total'
        $result.Output | Should -Match 'Skills adopter'
        $result.Output | Should -Match 'Skills maintainer-only'
        $result.Output | Should -Match 'Skills summary: total=35 adopter=34 maintainer-only=1 \[gate-check\]'
    }

    It 'fails clearly when an unreviewed skill is added' {
        New-Item -ItemType Directory -Path (Join-Path $fixture 'skills/unreviewed') | Out-Null
        Set-Content (Join-Path $fixture 'skills/unreviewed/SKILL.md') 'skill'
        $result = Invoke-CatalogAudit -Root $fixture

        $result.ExitCode | Should -Be 1
        $result.Output | Should -Match 'Catalog contract changed'
    }

    It 'fails clearly when a reviewed skill is removed' {
        Remove-Item -LiteralPath (Join-Path $fixture 'skills/skill-34') -Recurse
        $result = Invoke-CatalogAudit -Root $fixture

        $result.ExitCode | Should -Be 1
        $result.Output | Should -Match 'Catalog contract changed'
    }

    It 'fails when the maintainer-only skill is deployed' {
        New-Item -ItemType Directory -Path (Join-Path $fixture '.github/skills/gate-check') | Out-Null
        Set-Content (Join-Path $fixture '.github/skills/gate-check/SKILL.md') 'maintainer'
        $result = Invoke-CatalogAudit -Root $fixture

        $result.ExitCode | Should -Be 1
        $result.Output | Should -Match 'Maintainer-only deployed'
    }
}
