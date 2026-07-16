#Requires -Version 7
[CmdletBinding()]
param(
    [string]$RepositoryRoot = (Split-Path $PSScriptRoot -Parent),
    [string[]]$AgentPath = @(
        'agents/architect.agent.md',
        'agents/brainstorm.agent.md',
        'agents/code-reviewer.agent.md',
        'agents/coder.agent.md',
        'agents/dba.agent.md',
        'agents/frontend-designer.agent.md',
        'agents/plan.agent.md',
        'agents/pm.agent.md',
        'agents/spec.agent.md'
    )
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

function Get-FirstLineNumber {
    param(
        [Parameter(Mandatory)][AllowEmptyString()][string[]]$Lines,
        [Parameter(Mandatory)][string]$Pattern
    )

    for ($index = 0; $index -lt $Lines.Count; $index++) {
        if ($Lines[$index] -match $Pattern) {
            return $index + 1
        }
    }

    return 0
}

function Get-LevelTwoSection {
    param(
        [Parameter(Mandatory)][AllowEmptyString()][string[]]$Lines,
        [Parameter(Mandatory)][string]$Name
    )

    $startLine = Get-FirstLineNumber -Lines $Lines -Pattern "(?i)^##\s+$([regex]::Escape($Name))\s*$"
    if ($startLine -eq 0) {
        return [pscustomobject]@{ StartLine = 0; Text = '' }
    }

    $body = [System.Collections.Generic.List[string]]::new()
    for ($index = $startLine; $index -lt $Lines.Count; $index++) {
        if ($Lines[$index] -match '^##\s+') {
            break
        }
        $body.Add($Lines[$index])
    }

    return [pscustomobject]@{
        StartLine = $startLine
        Text = ($body -join "`n").Trim()
    }
}

$root = [IO.Path]::GetFullPath($RepositoryRoot)
if (-not (Test-Path -LiteralPath $root -PathType Container)) {
    Write-Output "[HARD] <checker> INVALID_REPOSITORY_ROOT line=1 path=$RepositoryRoot"
    Write-Output 'CHECK FAILED hard=1 warning=0'
    exit 1
}

$expectedSkillOwners = @{
    'agents/architect.agent.md' = @('brainstorming', 'agentic-eval')
    'agents/brainstorm.agent.md' = @('brainstorming')
    'agents/code-reviewer.agent.md' = @('code-security-review')
    'agents/coder.agent.md' = @('tdd-workflow')
    'agents/dba.agent.md' = @('backend-patterns', 'specification', 'implementation-planning')
    'agents/frontend-designer.agent.md' = @('frontend-patterns', 'specification')
    'agents/plan.agent.md' = @('implementation-planning')
    'agents/pm.agent.md' = @('workflow-orchestrator', 'prd')
    'agents/spec.agent.md' = @('specification')
}

$hardFindings = [System.Collections.Generic.List[object]]::new()
$warningFindings = [System.Collections.Generic.List[object]]::new()
$expandedAgentPaths = @($AgentPath | ForEach-Object { $_ -split ',' } | Where-Object { -not [string]::IsNullOrWhiteSpace($_) })

foreach ($requestedPath in $expandedAgentPaths) {
    $relativePath = $requestedPath.Replace('\', '/').TrimStart([char[]]'./')
    $fullPath = Join-Path $root ($relativePath.Replace('/', [IO.Path]::DirectorySeparatorChar))

    if (-not (Test-Path -LiteralPath $fullPath -PathType Leaf)) {
        Write-Output "[FILE] $relativePath non-empty=0"
        $hardFindings.Add([pscustomobject]@{ Path = $relativePath; Type = 'AGENT_FILE_MISSING'; Line = 1; Detail = '' }) | Out-Null
        continue
    }

    $lines = @(Get-Content -LiteralPath $fullPath)
    $content = $lines -join "`n"
    $nonEmptyCount = @($lines | Where-Object { -not [string]::IsNullOrWhiteSpace($_) }).Count
    Write-Output "[FILE] $relativePath non-empty=$nonEmptyCount"

    if ($nonEmptyCount -gt 25) {
        $warningFindings.Add([pscustomobject]@{
            Path = $relativePath
            Type = 'LINE_COUNT'
            Line = 1
            Detail = "non-empty=$nonEmptyCount target=25"
        }) | Out-Null
    }

    foreach ($requiredSection in @(
        @{ Name = 'Persona'; Finding = 'MISSING_PERSONA' },
        @{ Name = 'Lens'; Finding = 'MISSING_LENS' },
        @{ Name = 'Scope'; Finding = 'MISSING_SCOPE' },
        @{ Name = 'Handoff'; Finding = 'MISSING_HANDOFF' }
    )) {
        $section = Get-LevelTwoSection -Lines $lines -Name $requiredSection.Name
        if ($section.StartLine -eq 0 -or [string]::IsNullOrWhiteSpace($section.Text)) {
            $hardFindings.Add([pscustomobject]@{ Path = $relativePath; Type = $requiredSection.Finding; Line = 1; Detail = '' }) | Out-Null
        }
    }

    $skillSection = Get-LevelTwoSection -Lines $lines -Name 'Skill Integration'
    $pointerMatches = @(
        if ($skillSection.StartLine -gt 0) {
            [regex]::Matches(
                $skillSection.Text,
                '(?i)\[[^\]]+\]\((?<path>[^)\r\n]*skills[/\\](?<skill>[^/\\)]+)[/\\]SKILL\.md)\)'
            )
        }
    )

    if ($pointerMatches.Count -eq 0) {
        $hardFindings.Add([pscustomobject]@{ Path = $relativePath; Type = 'MISSING_SKILL_POINTER'; Line = 1; Detail = '' }) | Out-Null
    } else {
        $expectedOwners = $expectedSkillOwners[$relativePath]
        if (-not $expectedOwners) {
            $hardFindings.Add([pscustomobject]@{ Path = $relativePath; Type = 'UNKNOWN_AGENT_MAPPING'; Line = 1; Detail = '' }) | Out-Null
        }

        foreach ($pointerMatch in $pointerMatches) {
            $pointerPath = $pointerMatch.Groups['path'].Value
            $skillName = $pointerMatch.Groups['skill'].Value
            $pointerLine = Get-FirstLineNumber -Lines $lines -Pattern ([regex]::Escape($pointerPath))
            $candidate = [IO.Path]::GetFullPath((Join-Path (Split-Path $fullPath -Parent) $pointerPath))
            $rootPrefix = $root.TrimEnd([IO.Path]::DirectorySeparatorChar) + [IO.Path]::DirectorySeparatorChar

            if (-not $candidate.StartsWith($rootPrefix, [StringComparison]::OrdinalIgnoreCase) -or -not (Test-Path -LiteralPath $candidate -PathType Leaf)) {
                $hardFindings.Add([pscustomobject]@{
                    Path = $relativePath
                    Type = 'UNRESOLVED_SKILL_POINTER'
                    Line = [Math]::Max($pointerLine, 1)
                    Detail = "pointer=$pointerPath"
                }) | Out-Null
            }

            if ($expectedOwners -and $skillName -notin $expectedOwners) {
                $hardFindings.Add([pscustomobject]@{
                    Path = $relativePath
                    Type = 'NON_OWNING_SKILL_POINTER'
                    Line = [Math]::Max($pointerLine, 1)
                    Detail = "skill=$skillName expected=$($expectedOwners -join ',')"
                }) | Out-Null
            }
        }

        if ($expectedOwners) {
            $presentSkillNames = @($pointerMatches | ForEach-Object { $_.Groups['skill'].Value } | Sort-Object -Unique)
            foreach ($expectedOwner in $expectedOwners) {
                if ($expectedOwner -notin $presentSkillNames) {
                    $hardFindings.Add([pscustomobject]@{
                        Path = $relativePath
                        Type = 'MISSING_EXPECTED_SKILL_POINTER'
                        Line = [Math]::Max($skillSection.StartLine, 1)
                        Detail = "skill=$expectedOwner"
                    }) | Out-Null
                }
            }
        }
    }

    $numberedStepCount = @($lines | Where-Object { $_ -match '^\s*\d+\.\s+\S' }).Count
    $checkboxCount = @($lines | Where-Object { $_ -match '^\s*-\s+\[[ xX]\]\s+\S' }).Count
    $methodLine = Get-FirstLineNumber -Lines $lines -Pattern '(?i)^##+\s+.*(?:Methodology|Procedure|Checklist|Step-by-Step|Workflow Steps|Core Principles|Composition Rules)\b'
    if ($methodLine -gt 0 -and ($numberedStepCount -ge 3 -or $checkboxCount -ge 3)) {
        $hardFindings.Add([pscustomobject]@{ Path = $relativePath; Type = 'PROHIBITED_METHODOLOGY'; Line = $methodLine; Detail = '' }) | Out-Null
    }

    $rubricLine = Get-FirstLineNumber -Lines $lines -Pattern '(?i)^##+\s+.*Rubric\b'
    $rubricTableLine = Get-FirstLineNumber -Lines $lines -Pattern '(?i)^\|\s*Dimension\s*\|.*(?:Weight|PASS|Threshold)'
    if ($rubricLine -gt 0 -and $rubricTableLine -gt 0) {
        $hardFindings.Add([pscustomobject]@{ Path = $relativePath; Type = 'PROHIBITED_RUBRIC'; Line = $rubricLine; Detail = '' }) | Out-Null
    }

    $modeOwnerLine = Get-FirstLineNumber -Lines $lines -Pattern '(?i)^##+\s+.*Execution Modes\b'
    $hasAllModeHeadings = (
        (Get-FirstLineNumber -Lines $lines -Pattern '(?i)^###+\s+Simple\s*$') -gt 0 -and
        (Get-FirstLineNumber -Lines $lines -Pattern '(?i)^###+\s+Standard\s*$') -gt 0 -and
        (Get-FirstLineNumber -Lines $lines -Pattern '(?i)^###+\s+High-Risk\s*$') -gt 0
    )
    $stageTableLine = Get-FirstLineNumber -Lines $lines -Pattern '(?i)^\|\s*(?:Highest File Present|Stage)\s*\|'
    $artifactSignals = [regex]::Matches($content, '(?i)\b(?:01-brainstorm|03-spec|04-plan|05-test-plan|99-archive)\.md\b').Count
    if (($modeOwnerLine -gt 0 -and $hasAllModeHeadings) -or ($stageTableLine -gt 0 -and $artifactSignals -ge 3)) {
        $workflowLine = if ($modeOwnerLine -gt 0) { $modeOwnerLine } else { $stageTableLine }
        $hardFindings.Add([pscustomobject]@{ Path = $relativePath; Type = 'PROHIBITED_WORKFLOW'; Line = $workflowLine; Detail = '' }) | Out-Null
    }

    $globalLine = Get-FirstLineNumber -Lines $lines -Pattern '(?i)^##+\s+.*(?:Global Governance|Global Policy|Constitution)\b'
    if ($globalLine -gt 0 -and $content -match '(?i)\b(?:every repository|all repositories|all agents|always-on)\b') {
        $hardFindings.Add([pscustomobject]@{ Path = $relativePath; Type = 'PROHIBITED_GLOBAL_GOVERNANCE'; Line = $globalLine; Detail = '' }) | Out-Null
    }

    $remoteActionKinds = @([regex]::Matches($content, '(?i)\b(?:commit|push|merge|tag|release|branch deletion|remote mutation)\b') | ForEach-Object Value | Sort-Object -Unique).Count
    $authorizationLine = Get-FirstLineNumber -Lines $lines -Pattern '(?i)\b(?:explicit approval|explicit authorization|require(?:s|d)? approval|authorization policy)\b'
    if ($remoteActionKinds -ge 3 -and $authorizationLine -gt 0) {
        $hardFindings.Add([pscustomobject]@{ Path = $relativePath; Type = 'PROHIBITED_REMOTE_AUTHORIZATION'; Line = $authorizationLine; Detail = '' }) | Out-Null
    }
}

foreach ($finding in $hardFindings) {
    $detail = if ($finding.Detail) { " $($finding.Detail)" } else { '' }
    Write-Output "[HARD] $($finding.Path) $($finding.Type) line=$($finding.Line)$detail"
}

foreach ($finding in $warningFindings) {
    Write-Output "[WARNING] $($finding.Path) $($finding.Type) line=$($finding.Line) $($finding.Detail)"
}

if ($hardFindings.Count -gt 0) {
    Write-Output "CHECK FAILED hard=$($hardFindings.Count) warning=$($warningFindings.Count)"
    exit 1
}

if ($warningFindings.Count -gt 0) {
    Write-Output 'CHECK PASSED WITH WARNINGS'
    exit 0
}

Write-Output 'CHECK PASSED'
exit 0
