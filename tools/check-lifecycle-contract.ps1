#Requires -Version 7
[CmdletBinding()]
param(
    [string]$RepositoryRoot = (Split-Path $PSScriptRoot -Parent),
    [switch]$SkipBootstrapMapping
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$requiredMarkers = @(
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

$semanticSignals = @{
    LIFECYCLE_SSOT = @(
        @{ Name = 'single-owner'; Pattern = '(?is)(?:canonical lifecycle|lifecycle).{0,160}SSOT' }
    )
    MODE_SIMPLE = @(
        @{ Name = 'localized-reversible'; Pattern = '(?is)localized.{0,120}reversible' },
        @{ Name = 'targeted-verification'; Pattern = '(?i)targeted verification' },
        @{ Name = 'no-package'; Pattern = '(?is)(?:does not require|no).{0,120}(?:Change Package|repository package)' }
    )
    MODE_STANDARD = @(
        @{ Name = 'one-ssot'; Pattern = '(?is)(?:exactly )?one.{0,100}(?:plan/lifecycle|task/status) SSOT' },
        @{ Name = 'package-triggers'; Pattern = '(?is)cross-session.{0,100}cross-component.{0,120}contract.{0,160}independent.review.{0,160}migration/audit.{0,160}escalation-prone' }
    )
    MODE_HIGH_RISK = @(
        @{ Name = 'risk-boundaries'; Pattern = '(?is)security.{0,80}auth.{0,100}permission.{0,120}financial.{0,120}migration.{0,160}(?:public breaking|breaking).{0,160}irreversible.{0,160}deployment.{0,100}production.{0,160}architecture' },
        @{ Name = 'full-evidence'; Pattern = '(?is)full Workflow.{0,120}(?:complete )?Change Package.{0,160}explicit approvals.{0,160}independent review.{0,180}rollback.{0,180}operational evidence' }
    )
    MODE_ESCALATION = @(
        @{ Name = 'stop-reclassify'; Pattern = '(?is)stop.{0,100}(?:reclassify|escalate).{0,160}before.{0,160}(?:implementation|continuing|further)' }
    )
    STAGE_ENTRY_EXIT = @(
        @{ Name = 'stage-roles'; Pattern = '(?is)Brainstorm.{0,200}Spec.{0,200}Plan.{0,200}Implement.{0,200}Review.{0,200}(?:Closeout|Archive)' },
        @{ Name = 'entry-exit'; Pattern = '(?is)Entry.{0,200}Exit' }
    )
    PACKAGE_COMPACT = @(
        @{ Name = 'compact-roles'; Pattern = '(?is)Intake.{0,160}decision.{0,160}plan.{0,220}Review only when independent review is required.{0,220}pre-merge Closeout' },
        @{ Name = 'no-padding'; Pattern = '(?is)(?:selected-stage|selected stage).{0,160}(?:never|not).{0,120}(?:padding|empty)' }
    )
    PACKAGE_FULL = @(
        @{ Name = 'full-roles'; Pattern = '(?is)00.{0,80}01.{0,80}02.{0,80}03.{0,80}04.{0,80}05.{0,80}06.{0,160}Review.{0,120}(?:Closeout|Archive)' }
    )
    TASK_STATUS_SSOT = @(
        @{ Name = 'declaration'; Pattern = '(?is)declaration.{0,100}exactly once.{0,180}task/status SSOT' },
        @{ Name = 'single-owner'; Pattern = '(?is)(?:one task/status SSOT|competing owner)' },
        @{ Name = 'external-tracker'; Pattern = '(?is)external tracker.{0,240}(?:pointer|identify|same URL)' }
    )
    GATE_ARCHITECTURE_DECISION_EXIT = @(
        @{ Name = 'gate-name'; Pattern = '(?i)Architecture Decision Exit' },
        @{ Name = 'gate-semantics'; Pattern = '(?is)Blocking conditions.{0,1600}Warning-only' }
    )
    GATE_PRE_IMPLEMENTATION_READINESS = @(
        @{ Name = 'gate-name'; Pattern = '(?i)Pre-Implementation Readiness' },
        @{ Name = 'gate-semantics'; Pattern = '(?is)Blocking conditions.{0,1600}Warning-only' }
    )
    GATE_PRE_DELIVERY_VERIFICATION = @(
        @{ Name = 'gate-name'; Pattern = '(?i)Pre-Delivery Verification' },
        @{ Name = 'gate-semantics'; Pattern = '(?is)Blocking conditions.{0,1600}Warning-only' }
    )
    GATE_MIGRATION_DEPLOYMENT_READINESS = @(
        @{ Name = 'gate-name'; Pattern = '(?i)Migration / Deployment Readiness' },
        @{ Name = 'gate-semantics'; Pattern = '(?is)Blocking conditions.{0,1600}Warning-only.{0,1200}N/A' }
    )
    CROSS_GATE_SEMANTICS = @(
        @{ Name = 'deterministic-blocker'; Pattern = '(?is)Deterministic failure.{0,100}blocking' },
        @{ Name = 'independent-review'; Pattern = '(?is)independent review' },
        @{ Name = 'no-score'; Pattern = '(?is)no aggregate score.{0,100}numeric threshold' }
    )
    REVIEW_ROLE = @(
        @{ Name = 'review-files'; Pattern = '(?is)07-review\.md.{0,160}05-review\.md' },
        @{ Name = 'review-content'; Pattern = '(?is)reviewed scope.{0,120}reviewer.{0,160}Critical.{0,80}High.{0,160}(?:required-gate|required gate).{0,180}Decision.{0,120}PASS.{0,80}PASS_WITH_NOTES.{0,80}BLOCKED' },
        @{ Name = 'review-competition'; Pattern = '(?is)two independent Review bodies.{0,120}blocking' }
    )
    CLOSEOUT_ROLE = @(
        @{ Name = 'closeout-files'; Pattern = '(?is)99-archive\.md.{0,160}99-closeout\.md' },
        @{ Name = 'closeout-content'; Pattern = '(?is)Outcome.{0,160}approved scope.{0,180}deterministic.{0,120}Review status.{0,180}(?:pre-merge|unmerged).{0,180}remote-delivery evidence.{0,180}(?:remaining|deferred).{0,180}authorization boundary' },
        @{ Name = 'closeout-competition'; Pattern = '(?is)two independent closeout bodies.{0,120}blocking' }
    )
    HYBRID_CLOSEOUT = @(
        @{ Name = 'mode-aware'; Pattern = '(?is)Simple.{0,160}(?:no|does not require).{0,120}(?:Archive|Closeout).{0,240}Standard without a package.{0,160}(?:no|does not require).{0,120}(?:Archive|Closeout).{0,240}(?:triggered Standard|Standard with a package).{0,160}pre-merge.{0,240}High-Risk.{0,160}pre-merge' },
        @{ Name = 'blocked-closeout'; Pattern = '(?is)(?:blocked Review|deterministic gate).{0,160}BLOCKED' },
        @{ Name = 'merge-evidence'; Pattern = '(?is)authoritative (?:remote delivery|merge-result) evidence.{0,160}external.{0,200}pre-merge.{0,200}(?:must not|does not).{0,120}claim.{0,120}(?:actual )?merged state' }
    )
    PROTECTED_ACTIONS = @(
        @{ Name = 'local-docs-only'; Pattern = '(?is)only.{0,100}(?:requested )?local documentation' },
        @{ Name = 'protected-actions'; Pattern = '(?is)commit.{0,80}push.{0,80}tag.{0,80}merge.{0,120}branch deletion.{0,160}(?:Issue|PR) closure.{0,120}release.{0,120}deployment.{0,120}production' },
        @{ Name = 'action-approval'; Pattern = '(?is)explicit.{0,80}current-task.{0,80}action-specific approval' }
    )
    HONEST_COMPLETION = @(
        @{ Name = 'evidence-state'; Pattern = '(?is)approved scope.{0,160}verification evidence.{0,160}delivery state' },
        @{ Name = 'not-complete'; Pattern = '(?is)unverified.{0,100}unmerged.{0,100}partial.{0,100}(?:Deferred|deferred).{0,100}blocked.{0,100}N/A' }
    )
}

function Get-LineNumber {
    param([string]$Text, [int]$Index)
    if ($Index -lt 0) { return 1 }
    return ([regex]::Matches($Text.Substring(0, $Index), "`n").Count + 1)
}

function Add-Finding {
    param(
        [Parameter(Mandatory)][AllowEmptyCollection()][System.Collections.Generic.List[object]]$List,
        [Parameter(Mandatory)][string]$Path,
        [Parameter(Mandatory)][string]$Type,
        [int]$Line = 1,
        [string]$Detail = ''
    )
    $List.Add([pscustomobject]@{ Path = $Path; Type = $Type; Line = $Line; Detail = $Detail }) | Out-Null
}

$root = [IO.Path]::GetFullPath($RepositoryRoot)
$findings = [System.Collections.Generic.List[object]]::new()
$documents = @(
    @{ Path = 'WORKFLOW.md'; FullPath = (Join-Path $root 'WORKFLOW.md') },
    @{ Path = 'docs/WORKFLOW.template.md'; FullPath = (Join-Path $root 'docs\WORKFLOW.template.md') }
)

foreach ($document in $documents) {
    if (-not (Test-Path -LiteralPath $document.FullPath -PathType Leaf)) {
        Write-Output "[FILE] $($document.Path) markers=0"
        Add-Finding -List $findings -Path $document.Path -Type 'FILE_MISSING'
        $document.Text = ''
        $document.Markers = @()
        continue
    }

    $text = Get-Content -LiteralPath $document.FullPath -Raw
    $markerMatches = @([regex]::Matches($text, '<!--\s*lifecycle-contract:(?<id>[A-Z0-9_]+)\s*-->'))
    $document.Text = $text
    $document.Markers = @($markerMatches | ForEach-Object { $_.Groups['id'].Value })
    Write-Output "[FILE] $($document.Path) markers=$($document.Markers.Count)"

    foreach ($requiredMarker in $requiredMarkers) {
        $markerOccurrences = @($markerMatches | Where-Object { $_.Groups['id'].Value -eq $requiredMarker })
        if ($markerOccurrences.Count -eq 0) {
            Add-Finding -List $findings -Path $document.Path -Type 'MARKER_MISSING' -Detail "id=$requiredMarker"
            continue
        }
        if ($markerOccurrences.Count -gt 1) {
            Add-Finding -List $findings -Path $document.Path -Type 'MARKER_DUPLICATE' -Line (Get-LineNumber -Text $text -Index $markerOccurrences[1].Index) -Detail "id=$requiredMarker"
            continue
        }

        $blockPattern = "(?s)<!--\s*lifecycle-contract:$([regex]::Escape($requiredMarker))\s*-->(?<body>.*?)(?=<!--\s*lifecycle-contract:|\z)"
        $blockMatch = [regex]::Match($text, $blockPattern)
        $block = $blockMatch.Groups['body'].Value
        foreach ($signal in $semanticSignals[$requiredMarker]) {
            if ($block -notmatch $signal.Pattern) {
                Add-Finding -List $findings -Path $document.Path -Type 'PORTABLE_SEMANTIC_MISSING' -Line (Get-LineNumber -Text $text -Index $markerOccurrences[0].Index) -Detail "id=$requiredMarker signal=$($signal.Name)"
            }
        }
    }

    foreach ($unexpected in @($document.Markers | Where-Object { $_ -notin $requiredMarkers } | Sort-Object -Unique)) {
        $match = $markerMatches | Where-Object { $_.Groups['id'].Value -eq $unexpected } | Select-Object -First 1
        Add-Finding -List $findings -Path $document.Path -Type 'MARKER_UNAPPROVED' -Line (Get-LineNumber -Text $text -Index $match.Index) -Detail "id=$unexpected"
    }
}

$projection = $documents[1]
if ($projection.Text) {
    $forbiddenProjectionMarkers = @(
        @{ Name = 'sync-dotgithub'; Pattern = '(?i)sync-dotgithub' },
        @{ Name = 'audit-catalog'; Pattern = '(?i)audit-catalog' },
        @{ Name = 'gate-check'; Pattern = '(?i)gate-check' },
        @{ Name = 'maintainer-ci'; Pattern = '(?i)\.github/workflows' },
        @{ Name = 'bootstrap-maintenance'; Pattern = '(?i)bootstrap\.(?:py|ps1)' },
        @{ Name = 'copilot-memory'; Pattern = '(?i)Copilot Memory' },
        @{ Name = 'mcp-server'; Pattern = '(?i)MCP Server' },
        @{ Name = 'auth-command'; Pattern = '(?i)gh auth status' }
    )
    foreach ($forbidden in $forbiddenProjectionMarkers) {
        $match = [regex]::Match($projection.Text, $forbidden.Pattern)
        if ($match.Success) {
            Add-Finding -List $findings -Path $projection.Path -Type 'MAINTAINER_CONTENT' -Line (Get-LineNumber -Text $projection.Text -Index $match.Index) -Detail "marker=$($forbidden.Name)"
        }
    }
}

$templateRoot = Join-Path $root 'changes\_template'
$expectedTemplates = @('00-intake.md', '01-brainstorm.md', '02-decision-log.md', '03-spec.md', '04-plan.md', '05-test-plan.md', '06-impact-analysis.md', '07-review.md', '99-archive.md')
$actualTemplates = if (Test-Path -LiteralPath $templateRoot -PathType Container) {
    @(Get-ChildItem -LiteralPath $templateRoot -File | Select-Object -ExpandProperty Name)
} else { @() }
Write-Output "[DIR] changes/_template files=$($actualTemplates.Count)"
foreach ($missing in @($expectedTemplates | Where-Object { $_ -notin $actualTemplates })) {
    Add-Finding -List $findings -Path 'changes/_template' -Type 'TEMPLATE_MISSING' -Detail "file=$missing"
}
foreach ($unexpected in @($actualTemplates | Where-Object { $_ -notin $expectedTemplates })) {
    Add-Finding -List $findings -Path 'changes/_template' -Type 'TEMPLATE_UNAPPROVED' -Detail "file=$unexpected"
}

if (-not $SkipBootstrapMapping) {
    $mappingChecks = @(
        @{ Path = 'scripts/bootstrap.py'; Source = 'docs/WORKFLOW.template.md'; Target = 'WORKFLOW.md' },
        @{ Path = 'scripts/bootstrap.ps1'; Source = 'docs/WORKFLOW.template.md'; Target = 'WORKFLOW.md' }
    )
    foreach ($mapping in $mappingChecks) {
        $fullPath = Join-Path $root ($mapping.Path.Replace('/', '\'))
        if (-not (Test-Path -LiteralPath $fullPath -PathType Leaf)) {
            Add-Finding -List $findings -Path $mapping.Path -Type 'BOOTSTRAP_FILE_MISSING'
            continue
        }
        $text = Get-Content -LiteralPath $fullPath -Raw
        if ($text -notmatch [regex]::Escape($mapping.Source) -or $text -notmatch [regex]::Escape($mapping.Target)) {
            Add-Finding -List $findings -Path $mapping.Path -Type 'BOOTSTRAP_MAPPING_MISSING' -Detail 'source=docs/WORKFLOW.template.md target=WORKFLOW.md'
        }
    }
}

foreach ($finding in $findings) {
    $detail = if ($finding.Detail) { " $($finding.Detail)" } else { '' }
    Write-Output "[HARD] $($finding.Path) $($finding.Type) line=$($finding.Line)$detail"
}

if ($findings.Count -gt 0) {
    Write-Output "LIFECYCLE CONTRACT FAILED hard=$($findings.Count)"
    exit 1
}

Write-Output 'LIFECYCLE CONTRACT PASSED'
exit 0
