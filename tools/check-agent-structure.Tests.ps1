BeforeAll {
    $script:RepoRoot = Split-Path $PSScriptRoot -Parent
    $script:CheckerPath = Join-Path $PSScriptRoot 'check-agent-structure.ps1'

    function New-CheckerFixture {
        $root = Join-Path $TestDrive ([guid]::NewGuid().ToString('N'))
        New-Item -ItemType Directory -Path (Join-Path $root 'agents') -Force | Out-Null
        New-Item -ItemType Directory -Path (Join-Path $root 'skills\tdd-workflow') -Force | Out-Null
        New-Item -ItemType Directory -Path (Join-Path $root 'skills\specification') -Force | Out-Null
        New-Item -ItemType Directory -Path (Join-Path $root 'skills\brainstorming') -Force | Out-Null
        New-Item -ItemType Directory -Path (Join-Path $root 'skills\agentic-eval') -Force | Out-Null
        Set-Content -LiteralPath (Join-Path $root 'skills\tdd-workflow\SKILL.md') -Value "---`nname: tdd-workflow`n---`n"
        Set-Content -LiteralPath (Join-Path $root 'skills\specification\SKILL.md') -Value "---`nname: specification`n---`n"
        Set-Content -LiteralPath (Join-Path $root 'skills\brainstorming\SKILL.md') -Value "---`nname: brainstorming`n---`n"
        Set-Content -LiteralPath (Join-Path $root 'skills\agentic-eval\SKILL.md') -Value "---`nname: agentic-eval`n---`n"
        return $root
    }

    function Set-FixtureAgent {
        param(
            [Parameter(Mandatory)][string]$Root,
            [Parameter(Mandatory)][string]$Name,
            [Parameter(Mandatory)][string]$Content
        )

        Set-Content -LiteralPath (Join-Path $Root "agents\$Name") -Value $Content
    }

    function Invoke-StructureChecker {
        param(
            [Parameter(Mandatory)][string]$Root,
            [Parameter(Mandatory)][string[]]$AgentPath
        )

        $agentArgument = $AgentPath -join ','
        $output = & pwsh -NoProfile -File $script:CheckerPath -RepositoryRoot $Root -AgentPath $agentArgument 2>&1
        return [pscustomobject]@{
            ExitCode = $LASTEXITCODE
            Output = ($output -join "`n")
        }
    }

    $script:ThinCoder = @'
---
name: coder-agent
description: Approved-scope TDD implementer.
tools: ["read", "edit", "execute"]
---

# Coder Agent

## Persona
Implement only the approved product scope and return evidence to the caller.

## Lens
Apply a TDD and financial-precision lens to implementation choices.

## Scope
Write product files only within the caller-provided allowlist; methodology stays in the paired Skill.

## Skill Integration
Follow [tdd-workflow](../skills/tdd-workflow/SKILL.md) for the canonical implementation method.

## Handoff
Return changed files and RED/GREEN evidence for independent review.
'@

    $script:ThinSpec = @'
---
name: spec-agent
description: Testable specification specialist.
tools: ["read", "edit"]
---

# Spec Agent

## Persona
Turn approved requirements into a testable specification.

## Lens
Use testability and traceability as the specialist lens.

## Scope
Own specification output only; reusable procedure stays in the paired Skill.

## Skill Integration
Follow [specification](../skills/specification/SKILL.md) for the canonical method.

## Handoff
Return the specification and unresolved gaps to the planner.
'@
}

Describe 'check-agent-structure required contract' {
    It 'accepts a structurally complete Agent and emits locatable per-file output' {
        $root = New-CheckerFixture
        Set-FixtureAgent -Root $root -Name 'coder.agent.md' -Content $script:ThinCoder

        $result = Invoke-StructureChecker -Root $root -AgentPath 'agents/coder.agent.md'

        $result.ExitCode | Should -Be 0
        $result.Output | Should -Match '(?m)^\[FILE\] agents/coder\.agent\.md non-empty=\d+$'
        $result.Output | Should -Match '(?m)^CHECK PASSED$'
    }

    It 'reports every missing required element as a per-file hard finding and exits nonzero' {
        $root = New-CheckerFixture
        Set-FixtureAgent -Root $root -Name 'coder.agent.md' -Content "---`nname: coder-agent`n---`n# Coder Agent`n"

        $result = Invoke-StructureChecker -Root $root -AgentPath 'agents/coder.agent.md'

        $result.ExitCode | Should -Be 1
        foreach ($finding in @('MISSING_PERSONA', 'MISSING_LENS', 'MISSING_SCOPE', 'MISSING_HANDOFF', 'MISSING_SKILL_POINTER')) {
            $result.Output | Should -Match "(?m)^\[HARD\] agents/coder\.agent\.md $finding line=\d+"
        }
    }

    It 'rejects unresolved and non-owning Skill pointers' {
        $root = New-CheckerFixture
        $unresolved = $script:ThinCoder.Replace('../skills/tdd-workflow/SKILL.md', '../skills/missing/SKILL.md')
        Set-FixtureAgent -Root $root -Name 'coder.agent.md' -Content $unresolved

        $missingResult = Invoke-StructureChecker -Root $root -AgentPath 'agents/coder.agent.md'
        $missingResult.ExitCode | Should -Be 1
        $missingResult.Output | Should -Match '(?m)^\[HARD\] agents/coder\.agent\.md UNRESOLVED_SKILL_POINTER line=\d+'

        $wrongOwner = $script:ThinCoder.Replace('tdd-workflow](../skills/tdd-workflow', 'brainstorming](../skills/brainstorming')
        Set-FixtureAgent -Root $root -Name 'coder.agent.md' -Content $wrongOwner
        $ownerResult = Invoke-StructureChecker -Root $root -AgentPath 'agents/coder.agent.md'
        $ownerResult.ExitCode | Should -Be 1
        $ownerResult.Output | Should -Match '(?m)^\[HARD\] agents/coder\.agent\.md NON_OWNING_SKILL_POINTER line=\d+'
    }

    It 'rejects a multi-Skill Agent that omits an expected canonical owner' {
        $root = New-CheckerFixture
        $architect = $script:ThinCoder.Replace('name: coder-agent', 'name: architect-agent').Replace(
            '[tdd-workflow](../skills/tdd-workflow/SKILL.md)',
            '[brainstorming](../skills/brainstorming/SKILL.md)'
        )
        Set-FixtureAgent -Root $root -Name 'architect.agent.md' -Content $architect

        $result = Invoke-StructureChecker -Root $root -AgentPath 'agents/architect.agent.md'

        $result.ExitCode | Should -Be 1
        $result.Output | Should -Match '(?m)^\[HARD\] agents/architect\.agent\.md MISSING_EXPECTED_SKILL_POINTER line=\d+ skill=agentic-eval$'
    }

    It 'reports each requested Agent independently' {
        $root = New-CheckerFixture
        Set-FixtureAgent -Root $root -Name 'coder.agent.md' -Content $script:ThinCoder
        Set-FixtureAgent -Root $root -Name 'spec.agent.md' -Content $script:ThinSpec

        $result = Invoke-StructureChecker -Root $root -AgentPath @('agents/coder.agent.md', 'agents/spec.agent.md')

        $result.ExitCode | Should -Be 0 -Because $result.Output
        ([regex]::Matches($result.Output, '(?m)^\[FILE\] agents/(?:coder|spec)\.agent\.md non-empty=\d+$')).Count | Should -Be 2
    }
}

Describe 'check-agent-structure prohibited responsibility contract' {
    It 'hard-fails multi-signal methodology rubrics Workflow governance and authorization ownership' {
        $root = New-CheckerFixture
        $agent = $script:ThinCoder + @'

## Step-by-Step Procedure
1. Gather every input.
2. Execute every implementation step.
3. Verify every output.

## Detailed Rubric
| Dimension | Weight | PASS Criteria |
|---|---:|---|
| Quality | 100% | Every item passes |

## Execution Modes
### Simple
Use a short path.
### Standard
Use a package.
### High-Risk
Use every gate.

## Global Governance
These rules apply to every repository and user.

## Remote Authorization
Commit, push, and merge require explicit approval.
'@
        Set-FixtureAgent -Root $root -Name 'coder.agent.md' -Content $agent

        $result = Invoke-StructureChecker -Root $root -AgentPath 'agents/coder.agent.md'

        $result.ExitCode | Should -Be 1
        foreach ($finding in @('PROHIBITED_METHODOLOGY', 'PROHIBITED_RUBRIC', 'PROHIBITED_WORKFLOW', 'PROHIBITED_GLOBAL_GOVERNANCE', 'PROHIBITED_REMOTE_AUTHORIZATION')) {
            $result.Output | Should -Match "(?m)^\[HARD\] agents/coder\.agent\.md $finding line=\d+"
        }
    }

    It 'does not fail on isolated ownership words without corroborating structural signals' {
        $root = New-CheckerFixture
        $agent = $script:ThinCoder.Replace(
            'methodology stays in the paired Skill.',
            'the paired Skill owns the methodology, checklist, Workflow, rubric, and authorization details.'
        )
        Set-FixtureAgent -Root $root -Name 'coder.agent.md' -Content $agent

        $result = Invoke-StructureChecker -Root $root -AgentPath 'agents/coder.agent.md'

        $result.ExitCode | Should -Be 0
        $result.Output | Should -Not -Match '(?m)^\[HARD\]'
    }
}

Describe 'check-agent-structure warning and gate integration contract' {
    It 'reports non-empty line count as a warning but succeeds when structure is valid' {
        $root = New-CheckerFixture
        $filler = (1..12 | ForEach-Object { "Additional bounded scope note $_." }) -join "`n"
        $agent = $script:ThinCoder.Replace(
            'Write product files only within the caller-provided allowlist; methodology stays in the paired Skill.',
            "Write product files only within the caller-provided allowlist; methodology stays in the paired Skill.`n$filler"
        )
        Set-FixtureAgent -Root $root -Name 'coder.agent.md' -Content $agent

        $result = Invoke-StructureChecker -Root $root -AgentPath 'agents/coder.agent.md'

        $result.ExitCode | Should -Be 0
        $result.Output | Should -Match '(?m)^\[WARNING\] agents/coder\.agent\.md LINE_COUNT line=1 non-empty=\d+ target=25$'
        $result.Output | Should -Match '(?m)^CHECK PASSED WITH WARNINGS$'
    }

    It 'is a required noninteractive check in the maintainer gate' {
        $gateScript = Get-Content -LiteralPath (Join-Path $script:RepoRoot 'skills\gate-check\scripts\run-gate-check.ps1') -Raw

        $gateScript | Should -Match '(?is)REQUIRED.{0,160}Agent structure.{0,500}tools[\\/]check-agent-structure\.ps1'
        $gateScript | Should -Match '(?is)check-agent-structure\.ps1.{0,500}LASTEXITCODE.{0,300}failed'
    }
}

Describe 'check-agent-structure canonical Agent mapping' {
    It 'passes the explicit nine-Agent canonical set with one report per file' {
        $output = & pwsh -NoProfile -File $script:CheckerPath -RepositoryRoot $script:RepoRoot 2>&1
        $exitCode = $LASTEXITCODE
        $text = $output -join "`n"

        $exitCode | Should -Be 0 -Because $text
        ([regex]::Matches($text, '(?m)^\[FILE\] agents/[^\r\n]+\.agent\.md non-empty=\d+$')).Count | Should -Be 9
        $text | Should -Not -Match '(?m)^\[HARD\]'
    }
}

Describe 'Phase 2 canonical Skill ownership mapping' {
    It 'keeps reusable database consultation tactics in backend-patterns' {
        $backend = Get-Content -LiteralPath (Join-Path $script:RepoRoot 'skills\backend-patterns\SKILL.md') -Raw

        $backend | Should -Match '(?is)## Database Design and Review Tactics.{0,1800}schema contract.{0,300}migration.{0,300}rollback.{0,300}(?:money|financial precision).{0,300}index.{0,300}(?:EXPLAIN|query).{0,500}handoff'
    }

    It 'keeps reusable UI consultation tactics in frontend-patterns' {
        $frontend = Get-Content -LiteralPath (Join-Path $script:RepoRoot 'skills\frontend-patterns\SKILL.md') -Raw

        $frontend | Should -Match '(?is)## UI/UX Design Consultation Tactics.{0,1800}component spec.{0,300}(?:states|variants).{0,300}accessibility.{0,300}design system.{0,300}responsive.{0,500}handoff'
    }

    It 'does not make the legacy security-reviewer playbook a code-review methodology owner' {
        $reviewSkill = Get-Content -LiteralPath (Join-Path $script:RepoRoot 'skills\code-security-review\SKILL.md') -Raw

        $reviewSkill | Should -Not -Match '(?i)instructions/playbooks/security-reviewer\.md'
    }

    It 'does not make the legacy TDD playbook a planning methodology owner' {
        $planningSkill = Get-Content -LiteralPath (Join-Path $script:RepoRoot 'skills\implementation-planning\SKILL.md') -Raw

        $planningSkill | Should -Not -Match '(?i)instructions/playbooks/tdd-guide\.md'
    }
}

Describe 'Phase 2 Prompt router ownership mapping' {
    It 'routes each affected Prompt to its canonical Skill without embedding stage methodology' {
        $promptMappings = @(
            @{ Path = 'prompts/archive.prompt.md'; Skill = 'work-archiving' }
            @{ Path = 'prompts/brainstorm.prompt.md'; Skill = 'brainstorming' }
            @{ Path = 'prompts/code-review.prompt.md'; Skill = 'code-security-review' }
            @{ Path = 'prompts/commit-gen.prompt.md'; Skill = 'git-commit' }
            @{ Path = 'prompts/create-plan.prompt.md'; Skill = 'implementation-planning' }
            @{ Path = 'prompts/spec.prompt.md'; Skill = 'specification' }
            @{ Path = 'prompts/tdd.prompt.md'; Skill = 'tdd-workflow' }
            @{ Path = 'prompts/workflow.prompt.md'; Skill = 'workflow-orchestrator' }
        )

        foreach ($mapping in $promptMappings) {
            $prompt = Get-Content -LiteralPath (Join-Path $script:RepoRoot $mapping.Path) -Raw
            $escapedSkill = [regex]::Escape($mapping.Skill)

            $prompt | Should -Match '(?m)^## Route\s*$' -Because $mapping.Path
            $prompt | Should -Match "(?i)\]\(\.\./skills/$escapedSkill/SKILL\.md\)" -Because $mapping.Path
            $prompt | Should -Not -Match '(?im)^## (?:What This Command Does|How It Works|Process|Review Priorities|Review Checklist|TDD Cycle|TDD Best Practices|Coverage Requirements|Workflow Stages Reference|Detection Rules|Complete Change Package|Detailed Rubric)\s*$' -Because $mapping.Path
        }
    }

    It 'keeps lifecycle selection in WORKFLOW while affected lifecycle Prompts only route to it' {
        foreach ($path in @('prompts/brainstorm.prompt.md', 'prompts/create-plan.prompt.md', 'prompts/workflow.prompt.md')) {
            $prompt = Get-Content -LiteralPath (Join-Path $script:RepoRoot $path) -Raw

            $prompt | Should -Match '(?is)canonical Workflow contract.{0,160}(?:declared by Project AGENTS|sole lifecycle)' -Because $path
            $prompt | Should -Not -Match '(?i)\]\(\.\./WORKFLOW(?:\.md)?\)' -Because "$path must not preselect the unapproved adopter-facing lifecycle source"
            $prompt | Should -Not -Match '(?im)^### (?:Simple|Standard|High-Risk)\s*$' -Because $path
            $prompt | Should -Not -Match '(?is)\|\s*Files Present\s*\|\s*Current Stage\s*\|\s*Next Command\s*\|' -Because $path
        }
    }

    It 'keeps commit-gen as message UX and grants no Git mutation authority' {
        $prompt = Get-Content -LiteralPath (Join-Path $script:RepoRoot 'prompts\commit-gen.prompt.md') -Raw

        $prompt | Should -Match '(?is)does not authorize.{0,120}staging.{0,120}commit'
        $prompt | Should -Not -Match '(?im)^\s*(?:git add|git commit|git push)\b'
    }
}

Describe 'Phase 2 scoped Instruction ownership mapping' {
    It 'keeps code review as a source-file delta pointing to code-security-review' {
        $instruction = Get-Content -LiteralPath (Join-Path $script:RepoRoot 'instructions\code-review.instructions.md') -Raw

        $instruction | Should -Match '(?m)^applyTo:\s*["'']?\*\*/\*\.'
        $instruction | Should -Not -Match '(?m)^applyTo:\s*["'']?\*\*["'']?\s*$'
        $instruction | Should -Match '(?i)\]\(\.\./skills/code-security-review/SKILL\.md\)'
        foreach ($heading in @('Scope', 'Canonical Method', 'Scoped Delta', 'Scoped Verification')) {
            $instruction | Should -Match "(?m)^## $([regex]::Escape($heading))\s*$"
        }
        $instruction | Should -Not -Match '(?im)^## (?:Review Priorities|General Review Principles|Review Checklist|Prompt Engineering Tips|Project Context)\s*$'
    }

    It 'keeps Python as a language-scoped delta pointing to python-patterns' {
        $instruction = Get-Content -LiteralPath (Join-Path $script:RepoRoot 'instructions\python.instructions.md') -Raw

        $instruction | Should -Match '(?m)^applyTo:\s*["'']?\*\*/\*\.py["'']?\s*$'
        $instruction | Should -Match '(?i)\]\(\.\./skills/python-patterns/SKILL\.md\)'
        foreach ($heading in @('Scope', 'Canonical Method', 'Scoped Delta', 'Scoped Verification')) {
            $instruction | Should -Match "(?m)^## $([regex]::Escape($heading))\s*$"
        }
        $instruction | Should -Not -Match '(?im)^## (?:Available Tools Configuration|Research Workflow|Research Templates|Final Execution Protocol|Version Control)\b'
    }
}

Describe 'Phase 2 legacy playbook compatibility mapping' {
    It 'keeps each legacy playbook as a compatibility pointer to canonical Skill owners' {
        $playbookMappings = @(
            @{ Path = 'instructions/playbooks/architect.md'; Skills = @('brainstorming', 'agentic-eval') }
            @{ Path = 'instructions/playbooks/database-reviewer.md'; Skills = @('backend-patterns', 'specification', 'implementation-planning') }
            @{ Path = 'instructions/playbooks/planner.md'; Skills = @('implementation-planning') }
            @{ Path = 'instructions/playbooks/security-reviewer.md'; Skills = @('code-security-review') }
            @{ Path = 'instructions/playbooks/tdd-guide.md'; Skills = @('tdd-workflow') }
        )

        foreach ($mapping in $playbookMappings) {
            $playbook = Get-Content -LiteralPath (Join-Path $script:RepoRoot $mapping.Path) -Raw

            $playbook | Should -Match '(?m)^# Compatibility Pointer\s*$' -Because $mapping.Path
            foreach ($skill in $mapping.Skills) {
                $escapedSkill = [regex]::Escape($skill)
                $playbook | Should -Match "(?i)\]\(\.\./\.\./skills/$escapedSkill/SKILL\.md\)" -Because $mapping.Path
            }
            $playbook | Should -Match '(?i)legacy.{0,120}compatibility'
            $playbook | Should -Not -Match '(?m)^\s*- \[ \]'
            $playbook | Should -Not -Match '(?im)^## (?:Checklist|Core Loop|Design Checklist|Planning Guidelines|Output Rules|Deliverables Before Coding)\s*$'
        }
    }
}
