BeforeAll {
    $script:VerifierPath = Join-Path $PSScriptRoot 'verify-change-package.ps1'

    function Invoke-PackageVerifier {
        param(
            [Parameter(Mandatory)][string]$Root,
            [string[]]$PackagePath,
            [string]$BaseRef
        )

        $arguments = @('-NoProfile', '-File', $script:VerifierPath, '-RepositoryRoot', $Root)
        if ($PackagePath) {
            $arguments += '-PackagePath'
            $arguments += $PackagePath
        }
        if ($BaseRef) {
            $arguments += @('-BaseRef', $BaseRef)
        }
        $output = & pwsh @arguments 2>&1
        [pscustomobject]@{ ExitCode = $LASTEXITCODE; Output = ($output -join "`n") }
    }

    function New-PackageRoot {
        $root = Join-Path $TestDrive ([guid]::NewGuid().ToString('N'))
        New-Item -ItemType Directory -Path (Join-Path $root 'changes') -Force | Out-Null
        return $root
    }

    function Write-PackageFile {
        param(
            [Parameter(Mandatory)][string]$Package,
            [Parameter(Mandatory)][string]$Name,
            [Parameter(Mandatory)][AllowEmptyString()][string]$Content
        )

        Set-Content -LiteralPath (Join-Path $Package $Name) -Value $Content -NoNewline
    }

    function New-ValidPackage {
        param(
            [Parameter(Mandatory)][string]$Root,
            [string]$Name = '2026-07-16-example',
            [ValidateSet('Simple', 'Standard', 'High-Risk')][string]$Mode = 'Standard',
            [ValidateSet('Compact', 'Full')][string]$Contract = 'Compact',
            [switch]$WithReview
        )

        $package = Join-Path $Root "changes\$Name"
        New-Item -ItemType Directory -Path $package -Force | Out-Null
        Write-PackageFile -Package $package -Name '00-intake.md' -Content @"
# 00 Intake
## Lifecycle Declaration
- Task/status SSOT: 04-plan.md
- External tracker: N/A
- Execution mode: $Mode
- Package trigger/reason: cross-session work
- Package contract: $Contract
## Acceptance Criteria
- [ ] Verified behavior
"@
        Write-PackageFile -Package $package -Name '02-decision-log.md' -Content "# Decision Evidence`n- Approved bounded direction."
        Write-PackageFile -Package $package -Name '04-plan.md' -Content "# Plan / Lifecycle Evidence`n- Current status: implementation verified.`n- Targeted verification: verifier tests."

        $reviewApplies = $WithReview -or $Contract -eq 'Full'
        $reviewFile = if ($reviewApplies) { '`07-review.md`' } else { 'N/A — independent review is not required' }
        $reviewDecision = if ($reviewApplies) { 'PASS' } else { 'N/A — independent review is not required' }
        Write-PackageFile -Package $package -Name '99-archive.md' -Content @"
# Closeout
## Outcome
- Status: COMPLETE
- Summary: Scoped implementation and required verification are complete.
## Approved Scope
- Completed: Approved package contract only.
- Excluded: Protected and remote actions.
## Verification Evidence
- Tests/checks/gates: PASS — package verifier fixture passed.
- Evidence gaps: None
## Review Status
- Review file: $reviewFile
- Decision: $reviewDecision
## Delivery Status
- State: pre-merge
- Remote delivery evidence: Not available pre-merge.
## Remaining or Deferred Work
- Remaining: None
- Deferred: Remote delivery is separately authorized.
## Authorization Boundary
- Local documentation only; protected actions require separate approval.
## Rollback or Recovery
- Evidence or N/A: Revert the scoped change.
"@

        if ($Contract -eq 'Full') {
            Write-PackageFile -Package $package -Name '01-brainstorm.md' -Content "# Brainstorm`n- High-risk exploration complete."
            Write-PackageFile -Package $package -Name '03-spec.md' -Content "# Spec`n## Acceptance Criteria`n- Observable result."
            Write-PackageFile -Package $package -Name '05-test-plan.md' -Content "# Test Plan`n- RED and GREEN path."
            Write-PackageFile -Package $package -Name '06-impact-analysis.md' -Content "# Impact Analysis`n- Rollback and affected systems."
        }
        if ($reviewApplies) {
            Write-PackageFile -Package $package -Name '07-review.md' -Content @'
# Review
## Summary
- Reviewed scope: Approved package implementation and evidence.
- Independent reviewer: Fixture reviewer.
## Findings
- Critical: None
- High: None
- Medium: None
- Low: None
## Verification Evidence
- Targeted tests: PASS — focused package verifier tests.
- Required full/static/project gates: PASS — required fixture gates.
- Unavailable or unverified checks: None
## Decision
- Decision: PASS
- Rationale: No blockers remain and required evidence is present.
'@
        }
        return $package
    }

    function Install-CanonicalTemplates {
        param([Parameter(Mandatory)][string]$Root)

        $destination = Join-Path $Root 'changes\_template'
        New-Item -ItemType Directory -Path $destination -Force | Out-Null
        Copy-Item -Path (Join-Path (Split-Path $PSScriptRoot -Parent) 'changes\_template\*') -Destination $destination -Force
    }

    function PointerAlias {
        param(
            [ValidateSet('Review', 'Closeout')][string]$Role,
            [string]$CanonicalFile
        )
        return "# Compatibility Alias`n- Semantic role: $Role`n- Canonical file: ``$CanonicalFile```n- Alias mode: pointer-only"
    }
}

Describe 'Phase 3 mode-aware Change Package verification' {
    It 'accepts Simple mode with no repository package' {
        $root = New-PackageRoot
        $result = Invoke-PackageVerifier -Root $root

        $result.ExitCode | Should -Be 0 -Because $result.Output
        $result.Output | Should -Match '(?m)^CHANGE PACKAGE CHECK PASSED packages=0 warnings=0$'
    }

    It 'accepts a valid new Compact Standard package without Review padding' {
        $root = New-PackageRoot
        New-ValidPackage -Root $root | Out-Null
        $result = Invoke-PackageVerifier -Root $root

        $result.ExitCode | Should -Be 0 -Because $result.Output
        $result.Output | Should -Match '(?m)^\[PACKAGE\] changes/2026-07-16-example class=NEW mode=Standard contract=Compact$'
        $result.Output | Should -Match '(?m)^\[ROLE\] changes/2026-07-16-example Closeout source=99-archive\.md status=COMPLETE$'
    }

    It 'accepts a valid new Full High-Risk package with canonical Review' {
        $root = New-PackageRoot
        New-ValidPackage -Root $root -Mode High-Risk -Contract Full | Out-Null
        $result = Invoke-PackageVerifier -Root $root

        $result.ExitCode | Should -Be 0 -Because $result.Output
        $result.Output | Should -Match '(?m)^\[ROLE\] changes/2026-07-16-example Review source=07-review\.md status=PASS$'
        $result.Output | Should -Not -Match 'REVIEW_DECISION_CONFLICT'
    }

    It 'accepts a voluntarily declared Compact Simple package under its declared contract' {
        $root = New-PackageRoot
        New-ValidPackage -Root $root -Mode Simple -Contract Compact | Out-Null
        $result = Invoke-PackageVerifier -Root $root

        $result.ExitCode | Should -Be 0 -Because $result.Output
        $result.Output | Should -Not -Match 'SIMPLE_PACKAGE_FORBIDDEN'
    }

    It 'hard-fails missing or unidentifiable task/status ownership in a new package' {
        $root = New-PackageRoot
        $package = New-ValidPackage -Root $root
        $intakePath = Join-Path $package '00-intake.md'
        $updatedIntake = (Get-Content -LiteralPath $intakePath -Raw) -replace '(?m)^- Task/status SSOT:.*$', '- Task/status SSOT:'
        Set-Content -LiteralPath $intakePath -Value $updatedIntake -NoNewline
        $result = Invoke-PackageVerifier -Root $root

        $result.ExitCode | Should -Be 1
        $result.Output | Should -Match '(?m)^\[HARD\] changes/2026-07-16-example DECLARATION_MISSING file=00-intake\.md field=Task/status SSOT$'
    }

    It 'hard-fails an inaccessible task/status SSOT pointer' {
        $root = New-PackageRoot
        $package = New-ValidPackage -Root $root
        $intakePath = Join-Path $package '00-intake.md'
        (Get-Content -LiteralPath $intakePath -Raw) -replace 'Task/status SSOT: 04-plan.md', 'Task/status SSOT: missing-plan.md' |
            Set-Content -LiteralPath $intakePath -NoNewline
        $result = Invoke-PackageVerifier -Root $root

        $result.ExitCode | Should -Be 1
        $result.Output | Should -Match '(?m)^\[HARD\] changes/2026-07-16-example SSOT_UNIDENTIFIABLE file=00-intake\.md value=missing-plan\.md$'
    }

    It 'hard-fails duplicate lifecycle declarations in Intake' {
        $root = New-PackageRoot
        $package = New-ValidPackage -Root $root
        Add-Content -LiteralPath (Join-Path $package '00-intake.md') -Value "`n- Execution mode: Standard"
        $result = Invoke-PackageVerifier -Root $root

        $result.ExitCode | Should -Be 1
        $result.Output | Should -Match '(?m)^\[HARD\] changes/2026-07-16-example DECLARATION_DUPLICATE file=00-intake\.md field=Execution mode count=2$'
    }

    It 'hard-fails competing task/status SSOT declarations across package files' {
        $root = New-PackageRoot
        $package = New-ValidPackage -Root $root
        Add-Content -LiteralPath (Join-Path $package '04-plan.md') -Value "`n- Task/status SSOT: 02-decision-log.md"
        $result = Invoke-PackageVerifier -Root $root

        $result.ExitCode | Should -Be 1
        $result.Output | Should -Match '(?m)^\[HARD\] changes/2026-07-16-example SSOT_CONFLICT declarations=00-intake\.md:04-plan\.md,04-plan\.md:02-decision-log\.md$'
    }

    It 'hard-fails duplicate task/status SSOT ownership declarations even when values agree' {
        $root = New-PackageRoot
        $package = New-ValidPackage -Root $root
        Add-Content -LiteralPath (Join-Path $package '04-plan.md') -Value "`n- Task/status SSOT: 04-plan.md"
        $result = Invoke-PackageVerifier -Root $root

        $result.ExitCode | Should -Be 1
        $result.Output | Should -Match '(?m)^\[HARD\] changes/2026-07-16-example SSOT_DECLARATION_DUPLICATE declarations=00-intake\.md:04-plan\.md,04-plan\.md:04-plan\.md$'
    }

    It 'hard-fails an unidentifiable external tracker pointer' {
        $root = New-PackageRoot
        $package = New-ValidPackage -Root $root
        $intakePath = Join-Path $package '00-intake.md'
        $updated = (Get-Content -LiteralPath $intakePath -Raw) -replace 'External tracker: N/A', 'External tracker: the tracker'
        $updated = $updated -replace 'Task/status SSOT: 04-plan.md', 'Task/status SSOT: the tracker'
        Set-Content -LiteralPath $intakePath -Value $updated -NoNewline
        $result = Invoke-PackageVerifier -Root $root

        $result.ExitCode | Should -Be 1
        $result.Output | Should -Match '(?m)^\[HARD\] changes/2026-07-16-example EXTERNAL_TRACKER_UNIDENTIFIABLE file=00-intake\.md value=the tracker$'
    }

    It 'accepts one identifiable external tracker as the task/status SSOT' {
        $root = New-PackageRoot
        $package = New-ValidPackage -Root $root
        $intakePath = Join-Path $package '00-intake.md'
        $updated = (Get-Content -LiteralPath $intakePath -Raw) -replace 'External tracker: N/A', 'External tracker: owner/repo#42'
        $updated = $updated -replace 'Task/status SSOT: 04-plan.md', 'Task/status SSOT: owner/repo#42'
        Set-Content -LiteralPath $intakePath -Value $updated -NoNewline
        $result = Invoke-PackageVerifier -Root $root

        $result.ExitCode | Should -Be 0 -Because $result.Output
    }

    It 'hard-fails unchanged canonical templates used as Compact evidence' {
        $root = New-PackageRoot
        Install-CanonicalTemplates -Root $root
        $package = Join-Path $root 'changes\2026-07-16-example'
        Copy-Item -LiteralPath (Join-Path $root 'changes\_template') -Destination $package -Recurse
        Write-PackageFile -Package $package -Name '00-intake.md' -Content @'
# 00 Intake
## Lifecycle Declaration
- Task/status SSOT: 04-plan.md
- External tracker: N/A
- Execution mode: Standard
- Package trigger/reason: cross-session work
- Package contract: Compact
## Acceptance Criteria
- [ ] Verifier rejects unchanged templates.
'@
        $result = Invoke-PackageVerifier -Root $root

        $result.ExitCode | Should -Be 1
        $result.Output | Should -Match '(?m)^\[HARD\] changes/2026-07-16-example ROLE_TEMPLATE_UNCHANGED file=02-decision-log\.md contract=Compact$'
        $result.Output | Should -Not -Match '(?m)^\[ROLE\].*Closeout.*status=COMPLETE$'
    }

    It 'hard-fails a High-Risk package that omits Full required evidence' {
        $root = New-PackageRoot
        $package = New-ValidPackage -Root $root -Mode High-Risk -Contract Full
        Remove-Item -LiteralPath (Join-Path $package '06-impact-analysis.md')
        $result = Invoke-PackageVerifier -Root $root

        $result.ExitCode | Should -Be 1
        $result.Output | Should -Match '(?m)^\[HARD\] changes/2026-07-16-example REQUIRED_ROLE_MISSING file=06-impact-analysis\.md contract=Full$'
    }

    It 'uses a Git base ref to distinguish a historical package from a newly added package in CI' {
        $root = New-PackageRoot
        $history = Join-Path $root 'changes\2025-01-01-history'
        New-Item -ItemType Directory -Path $history -Force | Out-Null
        Write-PackageFile -Package $history -Name '00-intake.md' -Content "# Historical intake"
        & git -C $root init --quiet
        & git -C $root add changes
        & git -C $root -c user.name=fixture -c user.email=fixture@example.invalid commit --quiet -m baseline
        $base = (& git -C $root rev-parse HEAD).Trim()

        $newPackage = New-ValidPackage -Root $root -Name '2026-07-16-new' -Mode High-Risk -Contract Full
        Remove-Item -LiteralPath (Join-Path $newPackage '06-impact-analysis.md')
        $result = Invoke-PackageVerifier -Root $root -BaseRef $base

        $result.ExitCode | Should -Be 1
        $result.Output | Should -Match '(?m)^\[PACKAGE\] changes/2025-01-01-history class=HISTORICAL mode=UNKNOWN contract=LEGACY$'
        $result.Output | Should -Match '(?m)^\[PACKAGE\] changes/2026-07-16-new class=NEW mode=High-Risk contract=Full$'
        $result.Output | Should -Match '(?m)^\[HARD\] changes/2026-07-16-new REQUIRED_ROLE_MISSING file=06-impact-analysis\.md contract=Full$'
    }
}

Describe 'Phase 3 Review and Closeout semantic role compatibility' {
    It 'recognizes a historical legacy Review body with a compatibility warning' {
        $root = New-PackageRoot
        $package = Join-Path $root 'changes\2025-01-01-history'
        New-Item -ItemType Directory -Path $package -Force | Out-Null
        Write-PackageFile -Package $package -Name '05-review.md' -Content "# Historical Review`n## Summary`nLegacy evidence remains readable."
        $result = Invoke-PackageVerifier -Root $root

        $result.ExitCode | Should -Be 0 -Because $result.Output
        $result.Output | Should -Match '(?m)^\[PACKAGE\] changes/2025-01-01-history class=HISTORICAL mode=UNKNOWN contract=LEGACY$'
        $result.Output | Should -Match '(?m)^\[WARN\] changes/2025-01-01-history LEGACY_REVIEW source=05-review\.md$'
    }

    It 'does not infer historical Review completion from an empty file' {
        $root = New-PackageRoot
        $package = Join-Path $root 'changes\2025-01-01-history'
        New-Item -ItemType Directory -Path $package -Force | Out-Null
        Write-PackageFile -Package $package -Name '05-review.md' -Content ''
        $result = Invoke-PackageVerifier -Root $root

        $result.ExitCode | Should -Be 0 -Because $result.Output
        $result.Output | Should -Match '(?m)^\[WARN\] changes/2025-01-01-history ROLE_INCOMPLETE role=Review source=05-review\.md$'
        $result.Output | Should -Not -Match '(?m)^\[ROLE\].*Review.*status=PASS$'
    }

    It 'hard-fails two independent Review bodies' {
        $root = New-PackageRoot
        $package = New-ValidPackage -Root $root -WithReview
        Write-PackageFile -Package $package -Name '05-review.md' -Content "# Second Review`n## Summary`nIndependent body."
        $result = Invoke-PackageVerifier -Root $root

        $result.ExitCode | Should -Be 1
        $result.Output | Should -Match '(?m)^\[HARD\] changes/2026-07-16-example COMPETING_ROLE role=Review files=07-review\.md,05-review\.md$'
    }

    It 'accepts a canonical Review body plus exact pointer-only legacy alias' {
        $root = New-PackageRoot
        $package = New-ValidPackage -Root $root -WithReview
        Write-PackageFile -Package $package -Name '05-review.md' -Content (PointerAlias -Role Review -CanonicalFile '07-review.md')
        $result = Invoke-PackageVerifier -Root $root

        $result.ExitCode | Should -Be 0 -Because $result.Output
        $result.Output | Should -Match '(?m)^\[WARN\] changes/2026-07-16-example POINTER_ALIAS role=Review source=05-review\.md canonical=07-review\.md$'
    }

    It 'hard-fails two independent Closeout bodies' {
        $root = New-PackageRoot
        $package = New-ValidPackage -Root $root
        Write-PackageFile -Package $package -Name '99-closeout.md' -Content "# Second Closeout`n## Outcome`nIndependent body."
        $result = Invoke-PackageVerifier -Root $root

        $result.ExitCode | Should -Be 1
        $result.Output | Should -Match '(?m)^\[HARD\] changes/2026-07-16-example COMPETING_ROLE role=Closeout files=99-archive\.md,99-closeout\.md$'
    }

    It 'hard-fails invented actual merge evidence in a new pre-merge Closeout' {
        $root = New-PackageRoot
        $package = New-ValidPackage -Root $root
        Add-Content -LiteralPath (Join-Path $package '99-archive.md') -Value "`n- Actual merge evidence: merged SHA abc1234"
        $result = Invoke-PackageVerifier -Root $root

        $result.ExitCode | Should -Be 1
        $result.Output | Should -Match '(?m)^\[HARD\] changes/2026-07-16-example PREMERGE_MERGE_CLAIM file=99-archive\.md$'
    }

    It 'hard-fails unresolved High findings with a PASS Review decision' {
        $root = New-PackageRoot
        $package = New-ValidPackage -Root $root -Mode High-Risk -Contract Full
        $reviewPath = Join-Path $package '07-review.md'
        (Get-Content -LiteralPath $reviewPath -Raw) -replace 'High: None', 'High: Unresolved — authorization boundary is unclear.' |
            Set-Content -LiteralPath $reviewPath -NoNewline
        $result = Invoke-PackageVerifier -Root $root

        $result.ExitCode | Should -Be 1
        $result.Output | Should -Match '(?m)^\[HARD\] changes/2026-07-16-example REVIEW_DECISION_CONFLICT source=07-review\.md decision=PASS reason=unresolved-critical-high$'
    }

    It 'hard-fails a deterministic BLOCKED status with a PASS Review decision' {
        $root = New-PackageRoot
        $package = New-ValidPackage -Root $root -Mode High-Risk -Contract Full
        $reviewPath = Join-Path $package '07-review.md'
        (Get-Content -LiteralPath $reviewPath -Raw) -replace 'Required full/static/project gates: PASS', 'Required full/static/project gates: BLOCKED' |
            Set-Content -LiteralPath $reviewPath -NoNewline
        $result = Invoke-PackageVerifier -Root $root

        $result.ExitCode | Should -Be 1
        $result.Output | Should -Match '(?m)^\[HARD\] changes/2026-07-16-example REVIEW_DECISION_CONFLICT source=07-review\.md decision=PASS reason=deterministic-blocked$'
    }

    It 'records WARNING-only Review and Closeout evidence without blocking PASS_WITH_NOTES' {
        $root = New-PackageRoot
        $package = New-ValidPackage -Root $root -Mode High-Risk -Contract Full
        $reviewPath = Join-Path $package '07-review.md'
        $review = (Get-Content -LiteralPath $reviewPath -Raw) -replace 'Unavailable or unverified checks: None', 'Unavailable or unverified checks: WARNING — optional documentation check was unavailable.'
        $review = $review -replace '(?m)^- Decision: PASS$', '- Decision: PASS_WITH_NOTES'
        Set-Content -LiteralPath $reviewPath -Value $review -NoNewline
        $closeoutPath = Join-Path $package '99-archive.md'
        $closeout = (Get-Content -LiteralPath $closeoutPath -Raw) -replace 'Evidence gaps: None', 'Evidence gaps: WARNING — optional documentation check remains unavailable.'
        $closeout = $closeout -replace '(?m)^- Status: COMPLETE$', '- Status: COMPLETE_WITH_NOTES'
        $closeout = $closeout -replace '(?m)^- Decision: PASS$', '- Decision: PASS_WITH_NOTES'
        Set-Content -LiteralPath $closeoutPath -Value $closeout -NoNewline
        $result = Invoke-PackageVerifier -Root $root

        $result.ExitCode | Should -Be 0 -Because $result.Output
        $result.Output | Should -Match '(?m)^\[WARN\] changes/2026-07-16-example REVIEW_EVIDENCE_WARNING source=07-review\.md$'
        $result.Output | Should -Match '(?m)^\[WARN\] changes/2026-07-16-example CLOSEOUT_EVIDENCE_WARNING source=99-archive\.md$'
    }

    It 'hard-fails BLOCKED unavailable Review evidence with a PASS decision' {
        $root = New-PackageRoot
        $package = New-ValidPackage -Root $root -Mode High-Risk -Contract Full
        $reviewPath = Join-Path $package '07-review.md'
        (Get-Content -LiteralPath $reviewPath -Raw) -replace 'Unavailable or unverified checks: None', 'Unavailable or unverified checks: BLOCKED — required deterministic check is unavailable.' |
            Set-Content -LiteralPath $reviewPath -NoNewline
        $result = Invoke-PackageVerifier -Root $root

        $result.ExitCode | Should -Be 1
        $result.Output | Should -Match '(?m)^\[HARD\] changes/2026-07-16-example REVIEW_DECISION_CONFLICT source=07-review\.md decision=PASS reason=deterministic-blocked$'
    }

    It 'hard-fails a Closeout that retains canonical placeholders' {
        $root = New-PackageRoot
        Install-CanonicalTemplates -Root $root
        $package = New-ValidPackage -Root $root
        Copy-Item -LiteralPath (Join-Path $root 'changes\_template\99-archive.md') -Destination (Join-Path $package '99-archive.md') -Force
        $result = Invoke-PackageVerifier -Root $root

        $result.ExitCode | Should -Be 1
        $result.Output | Should -Match '(?m)^\[HARD\] changes/2026-07-16-example ROLE_TEMPLATE_UNCHANGED file=99-archive\.md contract=Compact$'
        $result.Output | Should -Match '(?m)^\[HARD\] changes/2026-07-16-example ROLE_INCOMPLETE role=Closeout source=99-archive\.md$'
    }

    It 'hard-fails merged delivery state or SHA claims anywhere in structured Closeout fields' {
        $root = New-PackageRoot
        $package = New-ValidPackage -Root $root
        $closeoutPath = Join-Path $package '99-archive.md'
        $updated = (Get-Content -LiteralPath $closeoutPath -Raw) -replace 'State: pre-merge', 'State: merged'
        $updated = $updated -replace 'Remote delivery evidence: Not available pre-merge\.', 'Remote delivery evidence: merge SHA abc1234'
        Set-Content -LiteralPath $closeoutPath -Value $updated -NoNewline
        $result = Invoke-PackageVerifier -Root $root

        $result.ExitCode | Should -Be 1
        $result.Output | Should -Match '(?m)^\[HARD\] changes/2026-07-16-example PREMERGE_MERGE_CLAIM file=99-archive\.md$'
    }

    It 'hard-fails an actual merged-state claim in narrative Closeout content' {
        $root = New-PackageRoot
        $package = New-ValidPackage -Root $root
        Add-Content -LiteralPath (Join-Path $package '99-archive.md') -Value "`nNarrative delivery note: actual merge result: COMPLETE."
        $result = Invoke-PackageVerifier -Root $root

        $result.ExitCode | Should -Be 1
        $result.Output | Should -Match '(?m)^\[HARD\] changes/2026-07-16-example PREMERGE_MERGE_CLAIM file=99-archive\.md$'
    }

    It 'hard-fails an actual merge-result claim hidden in a user-authored HTML comment' {
        $root = New-PackageRoot
        $package = New-ValidPackage -Root $root
        Add-Content -LiteralPath (Join-Path $package '99-archive.md') -Value "`n<!-- User-authored note: actual merge result: COMPLETE. -->"
        $result = Invoke-PackageVerifier -Root $root

        $result.ExitCode | Should -Be 1
        $result.Output | Should -Match '(?m)^\[HARD\] changes/2026-07-16-example PREMERGE_MERGE_CLAIM file=99-archive\.md$'
    }

    It 'accepts expected head final head and commit SHA evidence without treating it as a merge claim' {
        $root = New-PackageRoot
        $package = New-ValidPackage -Root $root
        Add-Content -LiteralPath (Join-Path $package '99-archive.md') -Value "`n- Expected head SHA: abc1234`n- Final head: def5678`n- Commit SHA: 0123abc"
        $result = Invoke-PackageVerifier -Root $root

        $result.ExitCode | Should -Be 0 -Because $result.Output
        $result.Output | Should -Not -Match 'PREMERGE_MERGE_CLAIM'
    }

    It 'hard-fails Review and Closeout decision disagreement' {
        $root = New-PackageRoot
        $package = New-ValidPackage -Root $root -Mode High-Risk -Contract Full
        $closeoutPath = Join-Path $package '99-archive.md'
        (Get-Content -LiteralPath $closeoutPath -Raw) -replace '(?m)^- Decision: PASS$', '- Decision: PASS_WITH_NOTES' |
            Set-Content -LiteralPath $closeoutPath -NoNewline
        $result = Invoke-PackageVerifier -Root $root

        $result.ExitCode | Should -Be 1
        $result.Output | Should -Match '(?m)^\[HARD\] changes/2026-07-16-example CLOSEOUT_STATUS_CONFLICT review=PASS closeout-review=PASS_WITH_NOTES$'
    }

    It 'hard-fails a Closeout Review-file pointer that disagrees with canonical Review evidence' {
        $root = New-PackageRoot
        $package = New-ValidPackage -Root $root -Mode High-Risk -Contract Full
        $closeoutPath = Join-Path $package '99-archive.md'
        (Get-Content -LiteralPath $closeoutPath -Raw) -replace 'Review file: `07-review.md`', 'Review file: N/A — independent review is not required' |
            Set-Content -LiteralPath $closeoutPath -NoNewline
        $result = Invoke-PackageVerifier -Root $root

        $result.ExitCode | Should -Be 1
        $result.Output | Should -Match '(?m)^\[HARD\] changes/2026-07-16-example CLOSEOUT_STATUS_CONFLICT review-file-mismatch expected=07-review\.md$'
    }

    It 'requires a BLOCKED Closeout outcome when Review is BLOCKED' {
        $root = New-PackageRoot
        $package = New-ValidPackage -Root $root -Mode High-Risk -Contract Full
        $reviewPath = Join-Path $package '07-review.md'
        $review = (Get-Content -LiteralPath $reviewPath -Raw) -replace 'High: None', 'High: Unresolved — authorization boundary remains unclear.'
        $review = $review -replace '(?m)^- Decision: PASS$', '- Decision: BLOCKED'
        Set-Content -LiteralPath $reviewPath -Value $review -NoNewline
        $closeoutPath = Join-Path $package '99-archive.md'
        (Get-Content -LiteralPath $closeoutPath -Raw) -replace '(?m)^- Decision: PASS$', '- Decision: BLOCKED' |
            Set-Content -LiteralPath $closeoutPath -NoNewline
        $result = Invoke-PackageVerifier -Root $root

        $result.ExitCode | Should -Be 1
        $result.Output | Should -Match '(?m)^\[HARD\] changes/2026-07-16-example REVIEW_BLOCKED source=07-review\.md$'
        $result.Output | Should -Match '(?m)^\[HARD\] changes/2026-07-16-example CLOSEOUT_STATUS_CONFLICT outcome=COMPLETE reason=review-blocked$'
    }

    It 'hard-fails deterministic blocked Closeout evidence with a COMPLETE outcome' {
        $root = New-PackageRoot
        $package = New-ValidPackage -Root $root
        $closeoutPath = Join-Path $package '99-archive.md'
        (Get-Content -LiteralPath $closeoutPath -Raw) -replace 'Tests/checks/gates: PASS', 'Tests/checks/gates: BLOCKED' |
            Set-Content -LiteralPath $closeoutPath -NoNewline
        $result = Invoke-PackageVerifier -Root $root

        $result.ExitCode | Should -Be 1
        $result.Output | Should -Match '(?m)^\[HARD\] changes/2026-07-16-example CLOSEOUT_STATUS_CONFLICT outcome=COMPLETE reason=deterministic-blocked$'
    }

    It 'hard-fails BLOCKED Closeout evidence gaps with a COMPLETE outcome' {
        $root = New-PackageRoot
        $package = New-ValidPackage -Root $root
        $closeoutPath = Join-Path $package '99-archive.md'
        (Get-Content -LiteralPath $closeoutPath -Raw) -replace 'Evidence gaps: None', 'Evidence gaps: BLOCKED — required deterministic evidence is missing.' |
            Set-Content -LiteralPath $closeoutPath -NoNewline
        $result = Invoke-PackageVerifier -Root $root

        $result.ExitCode | Should -Be 1
        $result.Output | Should -Match '(?m)^\[HARD\] changes/2026-07-16-example CLOSEOUT_STATUS_CONFLICT outcome=COMPLETE reason=deterministic-blocked$'
    }

    It 'accepts substantive applicable rollback or recovery evidence' {
        $root = New-PackageRoot
        New-ValidPackage -Root $root | Out-Null
        $result = Invoke-PackageVerifier -Root $root

        $result.ExitCode | Should -Be 0 -Because $result.Output
    }

    It 'accepts a substantive Rollback N/A reason instead of applicable evidence' {
        $root = New-PackageRoot
        $package = New-ValidPackage -Root $root
        $closeoutPath = Join-Path $package '99-archive.md'
        (Get-Content -LiteralPath $closeoutPath -Raw) -replace 'Evidence or N/A: Revert the scoped change\.', 'Evidence or N/A: N/A — documentation-only evidence has no runtime state to restore.' |
            Set-Content -LiteralPath $closeoutPath -NoNewline
        $result = Invoke-PackageVerifier -Root $root

        $result.ExitCode | Should -Be 0 -Because $result.Output
    }

    It 'hard-fails an empty Rollback or Recovery placeholder' {
        $root = New-PackageRoot
        $package = New-ValidPackage -Root $root
        $closeoutPath = Join-Path $package '99-archive.md'
        (Get-Content -LiteralPath $closeoutPath -Raw) -replace 'Evidence or N/A: Revert the scoped change\.', 'Evidence or N/A:' |
            Set-Content -LiteralPath $closeoutPath -NoNewline
        $result = Invoke-PackageVerifier -Root $root

        $result.ExitCode | Should -Be 1
        $result.Output | Should -Match '(?m)^\[HARD\] changes/2026-07-16-example ROLE_INCOMPLETE role=Closeout source=99-archive\.md$'
    }

    It 'does not mutate package files while verifying' {
        $root = New-PackageRoot
        New-ValidPackage -Root $root | Out-Null
        $before = @(Get-ChildItem -LiteralPath $root -Recurse -File | Sort-Object FullName | ForEach-Object { "{0}|{1}|{2}" -f $_.FullName, $_.Length, (Get-FileHash -LiteralPath $_.FullName).Hash })

        $result = Invoke-PackageVerifier -Root $root
        $after = @(Get-ChildItem -LiteralPath $root -Recurse -File | Sort-Object FullName | ForEach-Object { "{0}|{1}|{2}" -f $_.FullName, $_.Length, (Get-FileHash -LiteralPath $_.FullName).Hash })

        $result.ExitCode | Should -Be 0 -Because $result.Output
        $after | Should -Be $before
    }
}
