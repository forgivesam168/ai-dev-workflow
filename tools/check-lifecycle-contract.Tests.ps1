BeforeAll {
    $script:RepoRoot = Split-Path $PSScriptRoot -Parent
    $script:CheckerPath = Join-Path $PSScriptRoot 'check-lifecycle-contract.ps1'
    $script:RequiredMarkers = @(
        'LIFECYCLE_SSOT',
        'MODE_SIMPLE',
        'MODE_STANDARD',
        'MODE_HIGH_RISK',
        'MODE_ESCALATION',
        'STAGE_ENTRY_EXIT',
        'PACKAGE_COMPACT',
        'PACKAGE_FULL',
        'TASK_STATUS_SSOT',
        'GATE_ARCHITECTURE_DECISION_EXIT',
        'GATE_PRE_IMPLEMENTATION_READINESS',
        'GATE_PRE_DELIVERY_VERIFICATION',
        'GATE_MIGRATION_DEPLOYMENT_READINESS',
        'CROSS_GATE_SEMANTICS',
        'REVIEW_ROLE',
        'CLOSEOUT_ROLE',
        'HYBRID_CLOSEOUT',
        'PROTECTED_ACTIONS',
        'HONEST_COMPLETION'
    )

    function Read-RepoFile {
        param([Parameter(Mandatory)][string]$RelativePath)
        Get-Content -LiteralPath (Join-Path $script:RepoRoot $RelativePath) -Raw
    }

    function Invoke-LifecycleChecker {
        param([Parameter(Mandatory)][string]$Root)
        $output = & pwsh -NoProfile -File $script:CheckerPath -RepositoryRoot $Root -SkipBootstrapMapping 2>&1
        [pscustomobject]@{ ExitCode = $LASTEXITCODE; Output = ($output -join "`n") }
    }

    function New-ContractFixture {
        $root = Join-Path $TestDrive ([guid]::NewGuid().ToString('N'))
        New-Item -ItemType Directory -Path (Join-Path $root 'docs') -Force | Out-Null
        New-Item -ItemType Directory -Path (Join-Path $root 'changes\_template') -Force | Out-Null
        Copy-Item -LiteralPath (Join-Path $script:RepoRoot 'WORKFLOW.md') -Destination (Join-Path $root 'WORKFLOW.md')
        Copy-Item -LiteralPath (Join-Path $script:RepoRoot 'docs\WORKFLOW.template.md') -Destination (Join-Path $root 'docs\WORKFLOW.template.md')
        Get-ChildItem -LiteralPath (Join-Path $script:RepoRoot 'changes\_template') -File |
            Copy-Item -Destination (Join-Path $root 'changes\_template')
        return $root
    }
}

Describe 'Phase 3 lifecycle projection contract' {
    It 'passes the deterministic portable semantic checker without bootstrap mapping during Slice A' {
        $result = Invoke-LifecycleChecker -Root $script:RepoRoot

        $result.ExitCode | Should -Be 0 -Because $result.Output
        $result.Output | Should -Match '(?m)^\[FILE\] WORKFLOW\.md markers=19$'
        $result.Output | Should -Match '(?m)^\[FILE\] docs/WORKFLOW\.template\.md markers=19$'
        $result.Output | Should -Match '(?m)^LIFECYCLE CONTRACT PASSED$'
    }

    It 'uses exactly one copy of every approved portable semantic marker in root and projection' {
        foreach ($path in @('WORKFLOW.md', 'docs/WORKFLOW.template.md')) {
            $text = Read-RepoFile $path
            $markers = @([regex]::Matches($text, '<!--\s*lifecycle-contract:(?<id>[A-Z0-9_]+)\s*-->') | ForEach-Object { $_.Groups['id'].Value })

            $markers.Count | Should -Be $script:RequiredMarkers.Count -Because $path
            foreach ($marker in $script:RequiredMarkers) {
                @($markers | Where-Object { $_ -eq $marker }).Count | Should -Be 1 -Because "$path marker $marker"
            }
        }
    }

    It 'keeps the adopter projection distinct and free of maintainer-only implementation material' {
        $root = Read-RepoFile 'WORKFLOW.md'
        $projection = Read-RepoFile 'docs/WORKFLOW.template.md'

        $projection | Should -Not -BeExactly $root
        $projection | Should -Not -Match '(?i)sync-dotgithub|audit-catalog|gate-check|\.github/workflows|template release|bootstrap\.(?:py|ps1)|Copilot Memory|MCP Server|gh auth status'
        $projection | Should -Match '(?i)distribution projection.{0,200}not.{0,80}(?:second|independent) policy owner'
        $projection | Should -Match '(?i)D-10.{0,100}(?:not claimed|Deferred)'
        $projection | Should -Match '(?i)Phase 4.{0,120}(?:not authorized|Deferred)'
    }

    It 'aligns user documentation to the three modes canonical Review and pre-merge Closeout' {
        foreach ($path in @('README.md', 'README.zh-TW.md', 'QUICKSTART.md', 'changes/README.md')) {
            $text = Read-RepoFile $path
            $text | Should -Match '(?is)Simple.{0,600}Standard.{0,600}High-Risk' -Because $path
            $text | Should -Match '07-review\.md' -Because $path
            $text | Should -Match '99-archive\.md' -Because $path
            $text | Should -Match '(?i)pre-merge' -Because $path
            $text | Should -Not -Match '(?i)\bfast(?:[ -]+)path\b|快速路' -Because $path
            $text | Should -Not -Match '(?i)(?:each|every|每次).{0,80}(?:work item|需求|變更).{0,80}(?:Change Package|變更包)' -Because $path
        }
    }
}

Describe 'Phase 3 canonical package template contract' {
    It 'contains exactly the approved canonical template filenames' {
        $actual = @(Get-ChildItem -LiteralPath (Join-Path $script:RepoRoot 'changes\_template') -File | Select-Object -ExpandProperty Name | Sort-Object)
        $expected = @('00-intake.md', '01-brainstorm.md', '02-decision-log.md', '03-spec.md', '04-plan.md', '05-test-plan.md', '06-impact-analysis.md', '07-review.md', '99-archive.md') | Sort-Object

        $actual | Should -Be $expected
    }

    It 'requires the new-package declaration fields in Intake' {
        $intake = Read-RepoFile 'changes/_template/00-intake.md'

        foreach ($field in @('Task/status SSOT', 'External tracker', 'Execution mode', 'Package trigger/reason', 'Package contract')) {
            $intake | Should -Match "(?im)^- $([regex]::Escape($field)):\s*$"
        }
        $intake | Should -Match '(?i)Package contract.{0,80}Compact / Full'
        $intake | Should -Match '(?is)declaration.{0,80}exactly once'
        $intake | Should -Match '(?is)Task/status SSOT.{0,180}(?:accessible|package-relative).{0,180}file path'
        $intake | Should -Match '(?is)no second task/status owner'
        $intake | Should -Match '(?i)filename existence.{0,100}does not.{0,80}complete'
    }

    It 'defines the canonical Review role content and blocking decision contract' {
        $review = Read-RepoFile 'changes/_template/07-review.md'

        foreach ($heading in @('Summary', 'Findings', 'Verification Evidence', 'Decision')) {
            $review | Should -Match "(?m)^## $([regex]::Escape($heading))\s*$"
        }
        $review | Should -Match '(?i)PASS\s*\|\s*PASS_WITH_NOTES\s*\|\s*BLOCKED'
        $review | Should -Match '(?is)unresolved Critical or High.{0,160}BLOCKED'
        $review | Should -Match '(?is)required deterministic failure.{0,160}BLOCKED'
        $review | Should -Match '(?im)^- Unavailable or unverified checks: None \| WARNING — .+ \| BLOCKED — .+$'
        $review | Should -Match '(?is)WARNING.{0,120}does not block.{0,120}BLOCKED.{0,120}deterministic blocker'
    }

    It 'defines the canonical pre-merge Closeout role without invented merge evidence' {
        $closeout = Read-RepoFile 'changes/_template/99-archive.md'

        foreach ($heading in @('Outcome', 'Approved Scope', 'Verification Evidence', 'Review Status', 'Delivery Status', 'Remaining or Deferred Work', 'Authorization Boundary', 'Rollback or Recovery')) {
            $closeout | Should -Match "(?m)^## $([regex]::Escape($heading))\s*$"
        }
        $closeout | Should -Match '(?i)pre-merge'
        $closeout | Should -Match '(?im)^- State: pre-merge \| unmerged$'
        $closeout | Should -Match '(?im)^- Remote delivery evidence: Not available pre-merge\.$'
        $closeout | Should -Not -Match '(?im)^- State:.*merged-with'
        $closeout | Should -Match '(?is)blocked Review.{0,160}BLOCKED'
        $closeout | Should -Match '(?im)^- Evidence gaps: None \| WARNING — .+ \| BLOCKED — .+$'
        $closeout | Should -Match '(?im)^- Evidence or N/A: .+ \| N/A — reason$'
        $closeout | Should -Not -Match '(?im)^- (?:Applicable rollback|N/A reason when)'
        $closeout | Should -Match '(?is)<!--\s*verifier-instruction:premerge-merge-claims.{0,160}actual merged state.{0,120}merge SHA.{0,120}mergedAt.{0,180}Expected head SHA.{0,120}commit SHA.{0,160}-->'
    }

    It 'documents compact full semantic roles and the narrow pointer-only alias convention in the scoped Instruction' {
        $instruction = Read-RepoFile 'instructions/changes.instructions.md'

        $instruction | Should -Match '(?is)## Compact Package.{0,900}00-intake\.md.{0,200}decision.{0,200}plan.{0,300}Review only when independent review is required.{0,300}99-archive\.md'
        $instruction | Should -Match '(?is)## Full Package.{0,900}00-intake\.md.{0,100}01-brainstorm\.md.{0,100}02-decision-log\.md.{0,100}03-spec\.md.{0,100}04-plan\.md.{0,100}05-test-plan\.md.{0,100}06-impact-analysis\.md.{0,200}07-review\.md.{0,100}99-archive\.md'
        $instruction | Should -Match '(?is)# Compatibility Alias.{0,200}Semantic role: (?:Review|Closeout).{0,160}Canonical file: `(?:07-review|99-archive)\.md`.{0,160}Alias mode: pointer-only'
        $instruction | Should -Match '(?i)two independent.{0,80}(?:Review|Closeout).{0,100}blocking'
    }
}

Describe 'Phase 3 lifecycle checker negative behavior' {
    It 'hard-fails a missing portable marker with a locatable finding' {
        $root = New-ContractFixture
        $projectionPath = Join-Path $root 'docs\WORKFLOW.template.md'
        $content = Get-Content -LiteralPath $projectionPath -Raw
        Set-Content -LiteralPath $projectionPath -Value ($content -replace '<!-- lifecycle-contract:REVIEW_ROLE -->', '') -NoNewline

        $result = Invoke-LifecycleChecker -Root $root

        $result.ExitCode | Should -Be 1
        $result.Output | Should -Match '(?m)^\[HARD\] docs/WORKFLOW\.template\.md MARKER_MISSING line=1 id=REVIEW_ROLE$'
    }

    It 'hard-fails maintainer-only material in the adopter projection' {
        $root = New-ContractFixture
        Add-Content -LiteralPath (Join-Path $root 'docs\WORKFLOW.template.md') -Value "`nRun tools/sync-dotgithub.ps1."

        $result = Invoke-LifecycleChecker -Root $root

        $result.ExitCode | Should -Be 1
        $result.Output | Should -Match '(?m)^\[HARD\] docs/WORKFLOW\.template\.md MAINTAINER_CONTENT line=\d+ marker=sync-dotgithub$'
    }

    It 'hard-fails a marker whose portable semantic evidence was removed' {
        $root = New-ContractFixture
        $projectionPath = Join-Path $root 'docs\WORKFLOW.template.md'
        $content = Get-Content -LiteralPath $projectionPath -Raw
        Set-Content -LiteralPath $projectionPath -Value ($content -replace 'targeted verification', 'focused evidence') -NoNewline

        $result = Invoke-LifecycleChecker -Root $root

        $result.ExitCode | Should -Be 1
        $result.Output | Should -Match '(?m)^\[HARD\] docs/WORKFLOW\.template\.md PORTABLE_SEMANTIC_MISSING line=\d+ id=MODE_SIMPLE signal=targeted-verification$'
    }
}

Describe 'Phase 3 maintainer gate and CI integration' {
    It 'runs lifecycle and semantic package checks as required deterministic gate steps' {
        $gateScript = Read-RepoFile 'skills/gate-check/scripts/run-gate-check.ps1'
        $gateSkill = Read-RepoFile 'skills/gate-check/SKILL.md'

        $lifecycleIndex = $gateScript.IndexOf("tools\check-lifecycle-contract.ps1")
        $packageIndex = $gateScript.IndexOf("tools\verify-change-package.ps1")
        $pythonIndex = $gateScript.IndexOf('Python bootstrap tests')
        $lifecycleIndex | Should -BeGreaterOrEqual 0
        $packageIndex | Should -BeGreaterOrEqual 0
        $lifecycleIndex | Should -BeLessThan $pythonIndex
        $packageIndex | Should -BeLessThan $pythonIndex
        $gateSkill | Should -Match 'check-lifecycle-contract\.ps1'
        $gateSkill | Should -Match 'verify-change-package\.ps1'
    }

    It 'uses the semantic verifier noninteractively on Ubuntu without requiring a package for every PR' {
        $workflow = Read-RepoFile '.github/workflows/verify-change-package.yml'

        $workflow | Should -Match '(?i)runs-on:\s*ubuntu-latest'
        $workflow | Should -Match '(?is)verify-change-package\.ps1.{0,240}-BaseRef'
        $workflow | Should -Match '(?is)git status --porcelain=v1.{0,1000}git status --porcelain=v1'
        $workflow | Should -Not -Match '(?i)FAIL_MODE|NEEDS_PACKAGE|code-like changes|missing required file'
        $workflow | Should -Not -Match '(?im)^\s*(?:git|gh)\s+(?:add|commit|push|merge|tag|pr\s+|issue\s+)'
    }
}
