#Requires -Version 7
[CmdletBinding()]
param(
    [string]$RepositoryRoot = (Split-Path $PSScriptRoot -Parent),
    [string[]]$PackagePath,
    [string]$BaseRef
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

function Add-Result {
    param(
        [Parameter(Mandatory)][AllowEmptyCollection()][System.Collections.Generic.List[object]]$List,
        [Parameter(Mandatory)][string]$Package,
        [Parameter(Mandatory)][string]$Code,
        [string]$Detail = ''
    )

    $List.Add([pscustomobject]@{ Package = $Package; Code = $Code; Detail = $Detail }) | Out-Null
}

function Get-FieldMatches {
    param(
        [Parameter(Mandatory)][string]$Text,
        [Parameter(Mandatory)][string]$Field
    )

    $matches = @([regex]::Matches($Text, "(?im)^[ \t]*-[ \t]*$([regex]::Escape($Field)):[ \t]*(?<value>.*?)[ \t]*$"))
    return ,$matches
}

function Get-SectionText {
    param(
        [Parameter(Mandatory)][string]$Text,
        [Parameter(Mandatory)][string]$Heading
    )

    $match = [regex]::Match($Text, "(?ims)^##[ \t]+$([regex]::Escape($Heading))[ \t]*$\r?\n(?<body>.*?)(?=^##[ \t]+|\z)")
    if (-not $match.Success) { return $null }
    return $match.Groups['body'].Value
}

function Get-StructuredField {
    param(
        [Parameter(Mandatory)][string]$Text,
        [Parameter(Mandatory)][string]$Section,
        [Parameter(Mandatory)][string]$Field
    )

    $sectionText = Get-SectionText -Text $Text -Heading $Section
    if ($null -eq $sectionText) {
        return [pscustomobject]@{ Count = 0; Value = $null }
    }
    $matches = Get-FieldMatches -Text $sectionText -Field $Field
    $value = if ($matches.Count -eq 1) { $matches[0].Groups['value'].Value.Trim().Trim('`').Trim() } else { $null }
    return [pscustomobject]@{ Count = $matches.Count; Value = $value }
}

function Test-PlaceholderValue {
    param([AllowNull()][string]$Value)

    if ([string]::IsNullOrWhiteSpace($Value)) { return $true }
    $trimmed = $Value.Trim()
    if ($trimmed -match '^(?:-|—|TBD|TODO|UNKNOWN|\{[^}]*\}|<[^>]*>|\[[^]]*\]|Y{4}-M{2}-D{2})$') { return $true }
    if ($trimmed -match '\s(?:\||/)\s') { return $true }
    return $false
}

function Get-StatusToken {
    param(
        [AllowNull()][string]$Value,
        [Parameter(Mandatory)][string[]]$Allowed
    )

    if (Test-PlaceholderValue -Value $Value) { return $null }
    foreach ($token in $Allowed) {
        if ($Value -match "(?i)^$([regex]::Escape($token))(?:\s|—|$)") { return $token.ToUpperInvariant() }
    }
    return $null
}

function Test-NoneValue {
    param([AllowNull()][string]$Value)

    return -not [string]::IsNullOrWhiteSpace($Value) -and $Value.Trim() -match '^(?i:None|0|N/A(?:\s+—\s+.+)?)$'
}

function Test-SubstantiveEvidence {
    param([Parameter(Mandatory)][string]$Text)

    foreach ($line in ($Text -split "\r?\n")) {
        $candidate = $line.Trim()
        if (-not $candidate -or $candidate -match '^(?:#|<!--|-->|\|?\s*:?-{3,})') { continue }
        $candidate = $candidate -replace '^[-*+]\s*', '' -replace '^\[[ xX]\]\s*', ''
        if ($candidate -match '^[^:]+:\s*(?<value>.*)$') { $candidate = $Matches['value'].Trim() }
        if (-not (Test-PlaceholderValue -Value $candidate) -and $candidate -match '[\p{L}\p{N}]{3}') { return $true }
    }
    return $false
}

function Normalize-Content {
    param([Parameter(Mandatory)][string]$Text)
    return ($Text -replace "`r`n", "`n").Trim()
}

function Test-ExternalTrackerPointer {
    param([Parameter(Mandatory)][string]$Value)

    return $Value -match '^(?i:https?://\S+|[A-Za-z0-9_.-]+/[A-Za-z0-9_.-]+#\d+|(?:GitHub\s+)?(?:Issue|PR)\s+#\d+)$'
}

function Test-AccessibleSsotPointer {
    param(
        [Parameter(Mandatory)][string]$Value,
        [Parameter(Mandatory)][string]$PackageRoot,
        [Parameter(Mandatory)][string]$RepositoryRoot
    )

    $pointer = $Value.Trim().Trim('`').Trim()
    $markdownLink = [regex]::Match($pointer, '^\[[^]]+\]\((?<path>[^)]+)\)$')
    if ($markdownLink.Success) { $pointer = $markdownLink.Groups['path'].Value.Trim() }
    $pointer = $pointer -replace '^(?i:file):\s*', ''
    if (-not $pointer -or [IO.Path]::IsPathRooted($pointer) -or $pointer -match '^[a-zA-Z][a-zA-Z0-9+.-]*:') { return $false }

    foreach ($base in @($PackageRoot, $RepositoryRoot)) {
        try {
            $candidate = [IO.Path]::GetFullPath((Join-Path $base ($pointer.Replace('/', '\'))))
        } catch {
            continue
        }
        $rootPrefix = $RepositoryRoot.TrimEnd('\', '/') + [IO.Path]::DirectorySeparatorChar
        if (-not $candidate.StartsWith($rootPrefix, [StringComparison]::OrdinalIgnoreCase)) { continue }
        if (Test-Path -LiteralPath $candidate -PathType Leaf) { return $true }
    }
    return $false
}

function Test-PointerAlias {
    param(
        [Parameter(Mandatory)][string]$Text,
        [Parameter(Mandatory)][ValidateSet('Review', 'Closeout')][string]$Role,
        [Parameter(Mandatory)][string]$CanonicalFile
    )

    $normalized = ($Text -replace "`r`n", "`n").Trim()
    $pattern = "(?s)^# Compatibility Alias\s*\n- Semantic role: $([regex]::Escape($Role))\s*\n- Canonical file: ``$([regex]::Escape($CanonicalFile))``\s*\n- Alias mode: pointer-only$"
    return $normalized -match $pattern
}

function Test-RequiredHeadings {
    param(
        [Parameter(Mandatory)][string]$Text,
        [Parameter(Mandatory)][string[]]$Headings
    )

    foreach ($heading in $Headings) {
        if ($Text -notmatch "(?im)^## $([regex]::Escape($heading))\s*$") { return $false }
    }
    return $true
}

$root = [IO.Path]::GetFullPath($RepositoryRoot)
$changesRoot = Join-Path $root 'changes'
$hard = [System.Collections.Generic.List[object]]::new()
$warnings = [System.Collections.Generic.List[object]]::new()

if ($BaseRef) {
    & git -C $root rev-parse --verify --quiet "$BaseRef^{commit}" *> $null
    if ($LASTEXITCODE -ne 0) {
        Write-Output "CHANGE PACKAGE CHECK ERROR base-ref=$BaseRef"
        exit 2
    }
}

$packages = [System.Collections.Generic.List[object]]::new()
if ($PackagePath) {
    foreach ($requestedPath in $PackagePath) {
        $relative = $requestedPath.Replace('\', '/').Trim('/')
        if ($relative -notmatch '^changes/[^/]+$' -or $relative -eq 'changes/_template') {
            Write-Output "CHANGE PACKAGE CHECK ERROR invalid-package-path=$requestedPath"
            exit 2
        }
        $fullPath = Join-Path $root ($relative.Replace('/', '\'))
        if (-not (Test-Path -LiteralPath $fullPath -PathType Container)) {
            Write-Output "CHANGE PACKAGE CHECK ERROR missing-package-path=$relative"
            exit 2
        }
        $packages.Add([pscustomobject]@{ Relative = $relative; FullPath = $fullPath }) | Out-Null
    }
} elseif (Test-Path -LiteralPath $changesRoot -PathType Container) {
    foreach ($directory in @(Get-ChildItem -LiteralPath $changesRoot -Directory | Where-Object Name -ne '_template' | Sort-Object Name)) {
        $packages.Add([pscustomobject]@{ Relative = "changes/$($directory.Name)"; FullPath = $directory.FullName }) | Out-Null
    }
}

foreach ($package in $packages) {
    $intakePath = Join-Path $package.FullPath '00-intake.md'
    $intake = if (Test-Path -LiteralPath $intakePath -PathType Leaf) { Get-Content -LiteralPath $intakePath -Raw } else { '' }
    $isNew = $intake -match '(?im)^## Lifecycle Declaration\s*$|^\s*-\s*(?:Task/status SSOT|External tracker|Execution mode|Package trigger/reason|Package contract):'
    if ($BaseRef) {
        & git -C $root cat-file -e "$BaseRef`:$($package.Relative)" 2>$null
        $isNew = $LASTEXITCODE -ne 0
    }

    if (-not $isNew) {
        Write-Output "[PACKAGE] $($package.Relative) class=HISTORICAL mode=UNKNOWN contract=LEGACY"

        $legacyReviewPath = Join-Path $package.FullPath '05-review.md'
        $canonicalReviewPath = Join-Path $package.FullPath '07-review.md'
        $reviewPaths = @($canonicalReviewPath, $legacyReviewPath | Where-Object { Test-Path -LiteralPath $_ -PathType Leaf })
        if ($reviewPaths.Count -eq 2) {
            $aliasText = Get-Content -LiteralPath $legacyReviewPath -Raw
            if (Test-PointerAlias -Text $aliasText -Role Review -CanonicalFile '07-review.md') {
                Add-Result -List $warnings -Package $package.Relative -Code 'POINTER_ALIAS' -Detail 'role=Review source=05-review.md canonical=07-review.md'
            } else {
                Add-Result -List $hard -Package $package.Relative -Code 'COMPETING_ROLE' -Detail 'role=Review files=07-review.md,05-review.md'
            }
        } elseif (Test-Path -LiteralPath $legacyReviewPath -PathType Leaf) {
            $legacyText = Get-Content -LiteralPath $legacyReviewPath -Raw
            if ([string]::IsNullOrWhiteSpace($legacyText)) {
                Add-Result -List $warnings -Package $package.Relative -Code 'ROLE_INCOMPLETE' -Detail 'role=Review source=05-review.md'
            } else {
                Add-Result -List $warnings -Package $package.Relative -Code 'LEGACY_REVIEW' -Detail 'source=05-review.md'
            }
        } elseif (Test-Path -LiteralPath $canonicalReviewPath -PathType Leaf) {
            $canonicalText = Get-Content -LiteralPath $canonicalReviewPath -Raw
            if ([string]::IsNullOrWhiteSpace($canonicalText)) {
                Add-Result -List $warnings -Package $package.Relative -Code 'ROLE_INCOMPLETE' -Detail 'role=Review source=07-review.md'
            }
        }

        $canonicalCloseoutPath = Join-Path $package.FullPath '99-archive.md'
        $aliasCloseoutPath = Join-Path $package.FullPath '99-closeout.md'
        if ((Test-Path -LiteralPath $canonicalCloseoutPath -PathType Leaf) -and (Test-Path -LiteralPath $aliasCloseoutPath -PathType Leaf)) {
            $aliasText = Get-Content -LiteralPath $aliasCloseoutPath -Raw
            if (Test-PointerAlias -Text $aliasText -Role Closeout -CanonicalFile '99-archive.md') {
                Add-Result -List $warnings -Package $package.Relative -Code 'POINTER_ALIAS' -Detail 'role=Closeout source=99-closeout.md canonical=99-archive.md'
            } else {
                Add-Result -List $hard -Package $package.Relative -Code 'COMPETING_ROLE' -Detail 'role=Closeout files=99-archive.md,99-closeout.md'
            }
        } elseif (Test-Path -LiteralPath $aliasCloseoutPath -PathType Leaf) {
            Add-Result -List $warnings -Package $package.Relative -Code 'LEGACY_CLOSEOUT' -Detail 'source=99-closeout.md'
        }
        continue
    }

    $modeMatches = Get-FieldMatches -Text $intake -Field 'Execution mode'
    $contractMatches = Get-FieldMatches -Text $intake -Field 'Package contract'
    $mode = if ($modeMatches.Count -eq 1) { $modeMatches[0].Groups['value'].Value.Trim().Trim('`').Trim() } else { $null }
    $contract = if ($contractMatches.Count -eq 1) { $contractMatches[0].Groups['value'].Value.Trim().Trim('`').Trim() } else { $null }
    $displayMode = if ($mode) { $mode } else { 'UNKNOWN' }
    $displayContract = if ($contract) { $contract } else { 'UNKNOWN' }
    Write-Output "[PACKAGE] $($package.Relative) class=NEW mode=$displayMode contract=$displayContract"

    if (-not (Test-Path -LiteralPath $intakePath -PathType Leaf)) {
        Add-Result -List $hard -Package $package.Relative -Code 'REQUIRED_ROLE_MISSING' -Detail 'file=00-intake.md contract=Undeclared'
        continue
    }

    $declarations = @{}
    foreach ($field in @('Task/status SSOT', 'External tracker', 'Execution mode', 'Package trigger/reason', 'Package contract')) {
        $matches = Get-FieldMatches -Text $intake -Field $field
        $value = if ($matches.Count -eq 1) { $matches[0].Groups['value'].Value.Trim().Trim('`').Trim() } else { $null }
        $declarations[$field] = $value
        if ($matches.Count -eq 0) {
            Add-Result -List $hard -Package $package.Relative -Code 'DECLARATION_MISSING' -Detail "file=00-intake.md field=$field"
        } elseif ($matches.Count -gt 1) {
            Add-Result -List $hard -Package $package.Relative -Code 'DECLARATION_DUPLICATE' -Detail "file=00-intake.md field=$field count=$($matches.Count)"
        } elseif ([string]::IsNullOrWhiteSpace($value)) {
            Add-Result -List $hard -Package $package.Relative -Code 'DECLARATION_MISSING' -Detail "file=00-intake.md field=$field"
        }
    }

    if ($mode -notin @('Simple', 'Standard', 'High-Risk')) {
        Add-Result -List $hard -Package $package.Relative -Code 'DECLARATION_INVALID' -Detail 'file=00-intake.md field=Execution mode'
    }
    if ($contract -notin @('Compact', 'Full')) {
        Add-Result -List $hard -Package $package.Relative -Code 'DECLARATION_INVALID' -Detail 'file=00-intake.md field=Package contract'
    } elseif ($mode -eq 'Standard' -and $contract -ne 'Compact') {
        Add-Result -List $hard -Package $package.Relative -Code 'MODE_CONTRACT_CONFLICT' -Detail 'mode=Standard expected=Compact'
    } elseif ($mode -eq 'High-Risk' -and $contract -ne 'Full') {
        Add-Result -List $hard -Package $package.Relative -Code 'MODE_CONTRACT_CONFLICT' -Detail 'mode=High-Risk expected=Full'
    }

    $externalTracker = $declarations['External tracker']
    $ssot = $declarations['Task/status SSOT']
    $hasExternalTracker = $externalTracker -and $externalTracker -notmatch '^(?i:N/?A|None|No|Not applicable)$'
    if ($hasExternalTracker) {
        if (-not (Test-ExternalTrackerPointer -Value $externalTracker)) {
            Add-Result -List $hard -Package $package.Relative -Code 'EXTERNAL_TRACKER_UNIDENTIFIABLE' -Detail "file=00-intake.md value=$externalTracker"
        }
        if ($ssot) {
            $normalizedSsot = ($ssot -replace '^(?i:External tracker):\s*', '').Trim()
            if ($normalizedSsot -ne $externalTracker) {
                Add-Result -List $hard -Package $package.Relative -Code 'SSOT_CONFLICT' -Detail 'file=00-intake.md external-tracker-declared'
            }
        }
    } elseif ($ssot -and -not (Test-AccessibleSsotPointer -Value $ssot -PackageRoot $package.FullPath -RepositoryRoot $root)) {
        Add-Result -List $hard -Package $package.Relative -Code 'SSOT_UNIDENTIFIABLE' -Detail "file=00-intake.md value=$ssot"
    }

    $ssotDeclarations = [System.Collections.Generic.List[object]]::new()
    foreach ($markdownFile in @(Get-ChildItem -LiteralPath $package.FullPath -File -Filter '*.md' | Sort-Object Name)) {
        $text = Get-Content -LiteralPath $markdownFile.FullName -Raw
        foreach ($match in (Get-FieldMatches -Text $text -Field 'Task/status SSOT')) {
            $ssotDeclarations.Add([pscustomobject]@{
                File = $markdownFile.Name
                Value = $match.Groups['value'].Value.Trim().Trim('`').Trim()
            }) | Out-Null
        }
    }
    if ($ssotDeclarations.Count -gt 1) {
        $declarationDetail = ($ssotDeclarations | ForEach-Object { "$($_.File):$($_.Value)" }) -join ','
        if (@($ssotDeclarations.Value | Sort-Object -Unique).Count -gt 1) {
            Add-Result -List $hard -Package $package.Relative -Code 'SSOT_CONFLICT' -Detail "declarations=$declarationDetail"
        } else {
            Add-Result -List $hard -Package $package.Relative -Code 'SSOT_DECLARATION_DUPLICATE' -Detail "declarations=$declarationDetail"
        }
    }

    $requiredFiles = if ($contract -eq 'Full') {
        @('00-intake.md', '01-brainstorm.md', '02-decision-log.md', '03-spec.md', '04-plan.md', '05-test-plan.md', '06-impact-analysis.md', '07-review.md', '99-archive.md')
    } else {
        @('00-intake.md', '02-decision-log.md', '04-plan.md', '99-archive.md')
    }
    foreach ($requiredFile in $requiredFiles) {
        $requiredPath = Join-Path $package.FullPath $requiredFile
        if (-not (Test-Path -LiteralPath $requiredPath -PathType Leaf)) {
            Add-Result -List $hard -Package $package.Relative -Code 'REQUIRED_ROLE_MISSING' -Detail "file=$requiredFile contract=$displayContract"
        } else {
            $requiredText = Get-Content -LiteralPath $requiredPath -Raw
            if ([string]::IsNullOrWhiteSpace($requiredText)) {
                Add-Result -List $hard -Package $package.Relative -Code 'REQUIRED_ROLE_EMPTY' -Detail "file=$requiredFile contract=$displayContract"
                continue
            }
            $templatePath = Join-Path $changesRoot "_template\$requiredFile"
            if ((Test-Path -LiteralPath $templatePath -PathType Leaf) -and
                (Normalize-Content -Text $requiredText) -ceq (Normalize-Content -Text (Get-Content -LiteralPath $templatePath -Raw))) {
                Add-Result -List $hard -Package $package.Relative -Code 'ROLE_TEMPLATE_UNCHANGED' -Detail "file=$requiredFile contract=$displayContract"
            } elseif ($requiredFile -notin @('00-intake.md', '07-review.md', '99-archive.md') -and -not (Test-SubstantiveEvidence -Text $requiredText)) {
                Add-Result -List $hard -Package $package.Relative -Code 'ROLE_INCOMPLETE' -Detail "file=$requiredFile contract=$displayContract"
            }
        }
    }

    $canonicalReviewPath = Join-Path $package.FullPath '07-review.md'
    $legacyReviewPath = Join-Path $package.FullPath '05-review.md'
    $hasCanonicalReview = Test-Path -LiteralPath $canonicalReviewPath -PathType Leaf
    $hasLegacyReview = Test-Path -LiteralPath $legacyReviewPath -PathType Leaf
    $reviewDecision = $null
    if ($hasCanonicalReview -and $hasLegacyReview) {
        $legacyText = Get-Content -LiteralPath $legacyReviewPath -Raw
        if (Test-PointerAlias -Text $legacyText -Role Review -CanonicalFile '07-review.md') {
            Add-Result -List $warnings -Package $package.Relative -Code 'POINTER_ALIAS' -Detail 'role=Review source=05-review.md canonical=07-review.md'
        } else {
            Add-Result -List $hard -Package $package.Relative -Code 'COMPETING_ROLE' -Detail 'role=Review files=07-review.md,05-review.md'
        }
    } elseif ($hasLegacyReview) {
        Add-Result -List $hard -Package $package.Relative -Code 'NEW_PACKAGE_LEGACY_ROLE' -Detail 'role=Review source=05-review.md canonical=07-review.md'
    }
    if ($hasCanonicalReview) {
        $reviewText = Get-Content -LiteralPath $canonicalReviewPath -Raw
        $reviewComplete = Test-RequiredHeadings -Text $reviewText -Headings @('Summary', 'Findings', 'Verification Evidence', 'Decision')
        $reviewFields = @{}
        foreach ($fieldSpec in @(
            @('Summary', 'Reviewed scope'),
            @('Summary', 'Independent reviewer'),
            @('Findings', 'Critical'),
            @('Findings', 'High'),
            @('Findings', 'Medium'),
            @('Findings', 'Low'),
            @('Verification Evidence', 'Targeted tests'),
            @('Verification Evidence', 'Required full/static/project gates'),
            @('Verification Evidence', 'Unavailable or unverified checks'),
            @('Decision', 'Decision'),
            @('Decision', 'Rationale')
        )) {
            $fieldState = Get-StructuredField -Text $reviewText -Section $fieldSpec[0] -Field $fieldSpec[1]
            $reviewFields[$fieldSpec[1]] = $fieldState.Value
            if ($fieldState.Count -ne 1 -or (Test-PlaceholderValue -Value $fieldState.Value)) { $reviewComplete = $false }
        }

        $reviewDecision = Get-StatusToken -Value $reviewFields['Decision'] -Allowed @('PASS_WITH_NOTES', 'PASS', 'BLOCKED')
        $targetedStatus = Get-StatusToken -Value $reviewFields['Targeted tests'] -Allowed @('PASS', 'BLOCKED', 'N/A')
        $requiredGateStatus = Get-StatusToken -Value $reviewFields['Required full/static/project gates'] -Allowed @('PASS', 'BLOCKED', 'N/A')
        if (-not $reviewDecision -or -not $targetedStatus -or -not $requiredGateStatus) { $reviewComplete = $false }
        if (($targetedStatus -eq 'N/A' -and $reviewFields['Targeted tests'] -notmatch '(?i)^N/A\s+—\s+.+') -or
            ($requiredGateStatus -eq 'N/A' -and $reviewFields['Required full/static/project gates'] -notmatch '(?i)^N/A\s+—\s+.+')) {
            $reviewComplete = $false
        }

        $criticalHighBlocked = $false
        foreach ($severity in @('Critical', 'High')) {
            $findingValue = $reviewFields[$severity]
            $isResolved = $findingValue -match '^(?i:Resolved)(?:\s+—|:)\s*\S.+'
            if (-not (Test-NoneValue -Value $findingValue) -and -not $isResolved) { $criticalHighBlocked = $true }
        }
        $reviewGapStatus = if (Test-NoneValue -Value $reviewFields['Unavailable or unverified checks']) {
            'NONE'
        } else {
            Get-StatusToken -Value $reviewFields['Unavailable or unverified checks'] -Allowed @('WARNING', 'BLOCKED')
        }
        if (-not $reviewGapStatus) { $reviewComplete = $false }
        if ($reviewGapStatus -in @('WARNING', 'BLOCKED') -and
            $reviewFields['Unavailable or unverified checks'] -notmatch "(?i)^$reviewGapStatus\s+—\s+\S.+") {
            $reviewComplete = $false
        }
        $deterministicBlocked = $targetedStatus -eq 'BLOCKED' -or $requiredGateStatus -eq 'BLOCKED' -or $reviewGapStatus -eq 'BLOCKED'

        if (-not $reviewComplete) {
            Add-Result -List $hard -Package $package.Relative -Code 'ROLE_INCOMPLETE' -Detail 'role=Review source=07-review.md'
        } else {
            Write-Output "[ROLE] $($package.Relative) Review source=07-review.md status=$reviewDecision"
            if ($reviewGapStatus -eq 'WARNING') {
                Add-Result -List $warnings -Package $package.Relative -Code 'REVIEW_EVIDENCE_WARNING' -Detail 'source=07-review.md'
            }
            if ($reviewDecision -eq 'BLOCKED') {
                Add-Result -List $hard -Package $package.Relative -Code 'REVIEW_BLOCKED' -Detail 'source=07-review.md'
            } elseif ($criticalHighBlocked) {
                Add-Result -List $hard -Package $package.Relative -Code 'REVIEW_DECISION_CONFLICT' -Detail "source=07-review.md decision=$reviewDecision reason=unresolved-critical-high"
            } elseif ($deterministicBlocked) {
                Add-Result -List $hard -Package $package.Relative -Code 'REVIEW_DECISION_CONFLICT' -Detail "source=07-review.md decision=$reviewDecision reason=deterministic-blocked"
            }
        }
    }

    $canonicalCloseoutPath = Join-Path $package.FullPath '99-archive.md'
    $aliasCloseoutPath = Join-Path $package.FullPath '99-closeout.md'
    $hasCanonicalCloseout = Test-Path -LiteralPath $canonicalCloseoutPath -PathType Leaf
    $hasAliasCloseout = Test-Path -LiteralPath $aliasCloseoutPath -PathType Leaf
    if ($hasCanonicalCloseout -and $hasAliasCloseout) {
        $aliasText = Get-Content -LiteralPath $aliasCloseoutPath -Raw
        if (Test-PointerAlias -Text $aliasText -Role Closeout -CanonicalFile '99-archive.md') {
            Add-Result -List $warnings -Package $package.Relative -Code 'POINTER_ALIAS' -Detail 'role=Closeout source=99-closeout.md canonical=99-archive.md'
        } else {
            Add-Result -List $hard -Package $package.Relative -Code 'COMPETING_ROLE' -Detail 'role=Closeout files=99-archive.md,99-closeout.md'
        }
    } elseif ($hasAliasCloseout) {
        Add-Result -List $hard -Package $package.Relative -Code 'NEW_PACKAGE_LEGACY_ROLE' -Detail 'role=Closeout source=99-closeout.md canonical=99-archive.md'
    }
    if ($hasCanonicalCloseout) {
        $closeoutText = Get-Content -LiteralPath $canonicalCloseoutPath -Raw
        $closeoutComplete = Test-RequiredHeadings -Text $closeoutText -Headings @('Outcome', 'Approved Scope', 'Verification Evidence', 'Review Status', 'Delivery Status', 'Remaining or Deferred Work', 'Authorization Boundary', 'Rollback or Recovery')
        $closeoutFields = @{}
        foreach ($fieldSpec in @(
            @('Outcome', 'Status'),
            @('Outcome', 'Summary'),
            @('Approved Scope', 'Completed'),
            @('Approved Scope', 'Excluded'),
            @('Verification Evidence', 'Tests/checks/gates'),
            @('Verification Evidence', 'Evidence gaps'),
            @('Review Status', 'Review file'),
            @('Review Status', 'Decision'),
            @('Delivery Status', 'State'),
            @('Delivery Status', 'Remote delivery evidence'),
            @('Remaining or Deferred Work', 'Remaining'),
            @('Remaining or Deferred Work', 'Deferred'),
            @('Rollback or Recovery', 'Evidence or N/A')
        )) {
            $fieldState = Get-StructuredField -Text $closeoutText -Section $fieldSpec[0] -Field $fieldSpec[1]
            $closeoutFields[$fieldSpec[1]] = $fieldState.Value
            if ($fieldState.Count -ne 1 -or (Test-PlaceholderValue -Value $fieldState.Value)) { $closeoutComplete = $false }
        }
        foreach ($section in @('Authorization Boundary')) {
            $sectionText = Get-SectionText -Text $closeoutText -Heading $section
            if ($null -eq $sectionText -or -not (Test-SubstantiveEvidence -Text $sectionText)) { $closeoutComplete = $false }
        }

        $outcomeStatus = Get-StatusToken -Value $closeoutFields['Status'] -Allowed @('COMPLETE_WITH_NOTES', 'COMPLETE', 'BLOCKED')
        $closeoutReviewDecision = Get-StatusToken -Value $closeoutFields['Decision'] -Allowed @('PASS_WITH_NOTES', 'PASS', 'BLOCKED', 'N/A')
        $closeoutGateStatus = Get-StatusToken -Value $closeoutFields['Tests/checks/gates'] -Allowed @('PASS', 'BLOCKED', 'N/A')
        if (-not $outcomeStatus -or -not $closeoutReviewDecision -or -not $closeoutGateStatus) { $closeoutComplete = $false }
        if (($closeoutReviewDecision -eq 'N/A' -and $closeoutFields['Decision'] -notmatch '(?i)^N/A\s+—\s+.+') -or
            ($closeoutGateStatus -eq 'N/A' -and $closeoutFields['Tests/checks/gates'] -notmatch '(?i)^N/A\s+—\s+.+')) {
            $closeoutComplete = $false
        }
        $rollbackValue = [string]$closeoutFields['Evidence or N/A']
        if ([string]::IsNullOrWhiteSpace($rollbackValue) -or -not (Test-SubstantiveEvidence -Text $rollbackValue) -or
            ($rollbackValue -match '^(?i)N/A(?:\s|$)' -and $rollbackValue -notmatch '(?i)^N/A\s+—\s+\S.+')) {
            $closeoutComplete = $false
        }
        if ($closeoutFields['State'] -notin @('pre-merge', 'unmerged')) { $closeoutComplete = $false }

        $actualMergeClaim = $false
        $userAuthoredContent = $closeoutText -replace '(?s)<!--\s*verifier-instruction:premerge-merge-claims\b.*?-->', ''
        foreach ($line in ($userAuthoredContent -split "\r?\n")) {
            if ($line -match '(?i)\bmerge(?:d)?\s+SHA\b\s*[:=]?\s*[0-9a-f]{7,40}\b' -or
                $line -match '(?i)\bmergedAt\b\s*[:=]\s*(?!not available|unavailable|unknown|pending)\S+' -or
                $line -match '(?i)^\s*(?:[-*]\s*)?(?:Delivery\s+)?State:\s*merged\b') {
                $actualMergeClaim = $true
                break
            }
            if ($line -match '(?i)\b(?:not available|unavailable|unknown|pending|must not|cannot|do not|avoid|prohibit|forbid)\b') { continue }
            if ($line -match '(?i)\b(?:PR|pull request|change)\s+(?:is|was|has been)\s+merged\b' -or
                $line -match '(?i)\b(?:actual\s+)?merged state\b\s*(?:is|:|=)\s*\S+' -or
                $line -match '(?i)\bactual merge (?:state|result|evidence)\b\s*(?:is|:|=)\s*\S+' -or
                $line -match '(?i)\bmerged into\b' -or
                $line -match '(?i)\bmerge (?:completed|succeeded)\b') {
                $actualMergeClaim = $true
                break
            }
        }
        if ($actualMergeClaim) {
            Add-Result -List $hard -Package $package.Relative -Code 'PREMERGE_MERGE_CLAIM' -Detail 'file=99-archive.md'
        }

        if ($reviewDecision) {
            $closeoutReviewFile = [string]$closeoutFields['Review file']
            if ($closeoutReviewFile.Trim('`').Trim() -ne '07-review.md') {
                Add-Result -List $hard -Package $package.Relative -Code 'CLOSEOUT_STATUS_CONFLICT' -Detail 'review-file-mismatch expected=07-review.md'
            }
            if ($closeoutReviewDecision -and $closeoutReviewDecision -ne $reviewDecision) {
                Add-Result -List $hard -Package $package.Relative -Code 'CLOSEOUT_STATUS_CONFLICT' -Detail "review=$reviewDecision closeout-review=$closeoutReviewDecision"
            }
        } elseif ($closeoutReviewDecision -and $closeoutReviewDecision -ne 'N/A') {
            Add-Result -List $hard -Package $package.Relative -Code 'CLOSEOUT_STATUS_CONFLICT' -Detail "review=ABSENT closeout-review=$closeoutReviewDecision"
        } elseif ($closeoutFields['Review file'] -notmatch '(?i)^N/A\s+—\s+.+') {
            Add-Result -List $hard -Package $package.Relative -Code 'CLOSEOUT_STATUS_CONFLICT' -Detail 'review=ABSENT review-file-not-N/A'
        }

        $closeoutGapStatus = if (Test-NoneValue -Value $closeoutFields['Evidence gaps']) {
            'NONE'
        } else {
            Get-StatusToken -Value $closeoutFields['Evidence gaps'] -Allowed @('WARNING', 'BLOCKED')
        }
        if (-not $closeoutGapStatus) { $closeoutComplete = $false }
        if ($closeoutGapStatus -in @('WARNING', 'BLOCKED') -and
            $closeoutFields['Evidence gaps'] -notmatch "(?i)^$closeoutGapStatus\s+—\s+\S.+") {
            $closeoutComplete = $false
        }
        $closeoutDeterministicBlocked = $closeoutGateStatus -eq 'BLOCKED' -or $closeoutGapStatus -eq 'BLOCKED'
        if ($reviewDecision -eq 'BLOCKED' -and $outcomeStatus -ne 'BLOCKED') {
            Add-Result -List $hard -Package $package.Relative -Code 'CLOSEOUT_STATUS_CONFLICT' -Detail "outcome=$outcomeStatus reason=review-blocked"
        }
        if ($closeoutDeterministicBlocked -and $outcomeStatus -ne 'BLOCKED') {
            Add-Result -List $hard -Package $package.Relative -Code 'CLOSEOUT_STATUS_CONFLICT' -Detail "outcome=$outcomeStatus reason=deterministic-blocked"
        }

        if (-not $closeoutComplete) {
            Add-Result -List $hard -Package $package.Relative -Code 'ROLE_INCOMPLETE' -Detail 'role=Closeout source=99-archive.md'
        } else {
            Write-Output "[ROLE] $($package.Relative) Closeout source=99-archive.md status=$outcomeStatus"
            if ($closeoutGapStatus -eq 'WARNING') {
                Add-Result -List $warnings -Package $package.Relative -Code 'CLOSEOUT_EVIDENCE_WARNING' -Detail 'source=99-archive.md'
            }
            if ($outcomeStatus -eq 'BLOCKED') {
                Add-Result -List $hard -Package $package.Relative -Code 'CLOSEOUT_BLOCKED' -Detail 'source=99-archive.md'
            }
        }
    }
}

foreach ($finding in $warnings) {
    $detail = if ($finding.Detail) { " $($finding.Detail)" } else { '' }
    Write-Output "[WARN] $($finding.Package) $($finding.Code)$detail"
}
foreach ($finding in $hard) {
    $detail = if ($finding.Detail) { " $($finding.Detail)" } else { '' }
    Write-Output "[HARD] $($finding.Package) $($finding.Code)$detail"
}

if ($hard.Count -gt 0) {
    Write-Output "CHANGE PACKAGE CHECK FAILED packages=$($packages.Count) hard=$($hard.Count) warnings=$($warnings.Count)"
    exit 1
}

Write-Output "CHANGE PACKAGE CHECK PASSED packages=$($packages.Count) warnings=$($warnings.Count)"
exit 0
