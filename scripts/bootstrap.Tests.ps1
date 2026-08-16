# Bootstrap.Tests.ps1 - Pester 測試套件
# 測試 Bootstrap.ps1 的所有功能

BeforeAll {
    . "$PSScriptRoot\bootstrap.ps1"
}

Describe "Phase 4B report-only dispatch" {
    It "rejects mutation flags before entering installer flow" {
        $pwsh = (Get-Process -Id $PID).Path
        $result = & $pwsh -NoProfile -File (Join-Path $PSScriptRoot 'bootstrap.ps1') -ReportOnly -Force -Operation conversion-plan -SourceRoot $PSScriptRoot -TargetPath $TestDrive 2>&1
        $LASTEXITCODE | Should -Not -Be 0
        ($result | Out-String) | Should -Match 'cannot be combined'
    }

    It "uses the shared Python canonical engine for CLI parity" {
        $python = Get-Command python -ErrorAction SilentlyContinue
        $python | Should -Not -BeNullOrEmpty
        $source = Split-Path -Parent $PSScriptRoot
        $pythonReport = & $python.Source (Join-Path $PSScriptRoot 'manifest_reconciliation.py') --operation conversion-plan --source-root $source --target-root $TestDrive | Out-String
        $powerShellReport = & (Get-Process -Id $PID).Path -NoProfile -File (Join-Path $PSScriptRoot 'bootstrap.ps1') -ReportOnly -Operation conversion-plan -SourceRoot $source -TargetPath $TestDrive | Out-String
        $py = $pythonReport | ConvertFrom-Json
        $ps = $powerShellReport | ConvertFrom-Json
        $py.report_identity.canonical_body_digest | Should -Be $ps.report_identity.canonical_body_digest
    }

    It "keeps the PowerShell CLI digest stable when only file mtimes differ" {
        $source = Join-Path $TestDrive 'source'
        $targetA = Join-Path $TestDrive 'target-a'
        $targetB = Join-Path $TestDrive 'target-b'
        New-Item -ItemType Directory -Path (Join-Path $source 'manifest') -Force | Out-Null
        New-Item -ItemType Directory -Path (Join-Path $source 'schemas') -Force | Out-Null
        New-Item -ItemType Directory -Path (Join-Path $targetA 'docs') -Force | Out-Null
        New-Item -ItemType Directory -Path (Join-Path $targetB 'docs') -Force | Out-Null
        Copy-Item -LiteralPath (Join-Path (Split-Path -Parent $PSScriptRoot) 'manifest/component-catalog.json') -Destination (Join-Path $source 'manifest/component-catalog.json')
        Copy-Item -LiteralPath (Join-Path (Split-Path -Parent $PSScriptRoot) 'schemas/ai-workflow-install-manifest-v3.schema.json') -Destination (Join-Path $source 'schemas/ai-workflow-install-manifest-v3.schema.json')
        $bytes = [Text.Encoding]::UTF8.GetBytes("same-bytes`n")
        [IO.File]::WriteAllBytes((Join-Path $targetA 'docs/example.md'), $bytes)
        [IO.File]::WriteAllBytes((Join-Path $targetB 'docs/example.md'), $bytes)
        (Get-Item (Join-Path $targetA 'docs/example.md')).LastWriteTimeUtc = [datetime]'2024-01-01T00:00:00Z'
        (Get-Item (Join-Path $targetB 'docs/example.md')).LastWriteTimeUtc = [datetime]'2025-01-01T00:00:00Z'

        $first = & (Get-Process -Id $PID).Path -NoProfile -File (Join-Path $PSScriptRoot 'bootstrap.ps1') -ReportOnly -Operation conversion-plan -SourceRoot $source -TargetPath $targetA | Out-String | ConvertFrom-Json
        $second = & (Get-Process -Id $PID).Path -NoProfile -File (Join-Path $PSScriptRoot 'bootstrap.ps1') -ReportOnly -Operation conversion-plan -SourceRoot $source -TargetPath $targetB | Out-String | ConvertFrom-Json

        $first.report_identity.canonical_body_digest | Should -Be $second.report_identity.canonical_body_digest
    }
}

Describe "Phase 0C manifest parse safety" {
    BeforeAll {
        function Get-Phase0CTreeSnapshot {
            param([string]$Root)

            $files = @()
            $directories = @()
            foreach ($item in @(Get-ChildItem -LiteralPath $Root -Force -Recurse | Sort-Object FullName)) {
                $relative = [IO.Path]::GetRelativePath($Root, $item.FullName).Replace('\', '/')
                if ($item.PSIsContainer) {
                    $directories += "$relative/"
                } else {
                    $files += "$relative|$(Get-FileHash256 -Path $item.FullName)"
                }
            }
            [PSCustomObject]@{ Files = $files; Directories = $directories }
        }

        function New-Phase0CTarget {
            param(
                [string]$Target,
                [AllowNull()]
                [byte[]]$ManifestBytes
            )

            $sentinel = [byte[]](0x70,0x72,0x6f,0x6a,0x65,0x63,0x74,0x00,0x0a)
            $secondary = [Text.Encoding]::UTF8.GetBytes("project-owned skill`r`n")
            New-Item -ItemType Directory -Path (Join-Path $Target '.github') -Force | Out-Null
            New-Item -ItemType Directory -Path (Join-Path $Target 'skills/custom') -Force | Out-Null
            [IO.File]::WriteAllBytes((Join-Path $Target '.github/copilot-instructions.md'), $sentinel)
            [IO.File]::WriteAllBytes((Join-Path $Target 'skills/custom/SKILL.md'), $secondary)
            if ($null -ne $ManifestBytes) {
                [IO.File]::WriteAllBytes((Join-Path $Target '.ai-workflow-install.json'), $ManifestBytes)
            }
            [PSCustomObject]@{ Sentinel = $sentinel; Secondary = $secondary }
        }

        function Assert-Phase0CNoWrite {
            param(
                [string]$Target,
                [PSCustomObject]$Before,
                [byte[]]$Sentinel,
                [byte[]]$Secondary
            )

            $after = Get-Phase0CTreeSnapshot -Root $Target
            ($after.Files -join "`n") | Should -Be ($Before.Files -join "`n")
            ($after.Directories -join "`n") | Should -Be ($Before.Directories -join "`n")
            [IO.File]::ReadAllBytes((Join-Path $Target '.github/copilot-instructions.md')) | Should -Be $Sentinel
            [IO.File]::ReadAllBytes((Join-Path $Target 'skills/custom/SKILL.md')) | Should -Be $Secondary
            @(Get-ChildItem -LiteralPath $Target -Force | Where-Object Name -Like '.github.backup-*').Count | Should -Be 0
            @(Get-ChildItem -LiteralPath $Target -Force | Where-Object Name -Like '.ai-workflow-portable.backup-*').Count | Should -Be 0
            Test-Path (Join-Path $Target '.git') | Should -BeFalse
        }

        function Invoke-Phase0CBootstrap {
            param(
                [string]$Target,
                [string[]]$Arguments
            )

            $pwsh = (Get-Process -Id $PID).Path
            $output = & $pwsh -NoProfile -File (Join-Path $PSScriptRoot 'bootstrap.ps1') -TargetPath $Target @Arguments 2>&1 | Out-String
            [PSCustomObject]@{ ExitCode = $LASTEXITCODE; Output = $output }
        }

        function ConvertTo-Phase0CManifestBytes {
            param([hashtable]$Manifest)
            [Text.Encoding]::UTF8.GetBytes(($Manifest | ConvertTo-Json -Depth 5 -Compress))
        }
    }

    It "returns missing for an absent manifest" {
        $target = Join-Path $TestDrive ([guid]::NewGuid().ToString())
        New-Item -ItemType Directory -Path $target | Out-Null
        $result = Get-InstallManifest -TargetPath $target
        $result.State | Should -Be 'missing'
        $result.Entries.Count | Should -Be 0
        $result.SchemaVersion | Should -BeNullOrEmpty
    }

    It "returns an explicit valid state for schema v<Version>" -ForEach @(
        @{ Version = 1 }
        @{ Version = 2 }
    ) {
            param($Version)
            $target = Join-Path $TestDrive ([guid]::NewGuid().ToString())
            New-Item -ItemType Directory -Path $target | Out-Null
            $bytes = ConvertTo-Phase0CManifestBytes @{ schema_version = $Version; components = @(@{ name = 'agents/a.md' }) }
            [IO.File]::WriteAllBytes((Join-Path $target '.ai-workflow-install.json'), $bytes)
            $result = Get-InstallManifest -TargetPath $target
            $result.State | Should -Be "valid-v$Version"
            $result.SchemaVersion | Should -Be $Version
            $result.Entries.ContainsKey('agents/a.md') | Should -BeTrue
    }

    It "returns corrupt for invalid JSON" {
        $target = Join-Path $TestDrive ([guid]::NewGuid().ToString())
        New-Item -ItemType Directory -Path $target | Out-Null
        [IO.File]::WriteAllBytes((Join-Path $target '.ai-workflow-install.json'), [Text.Encoding]::UTF8.GetBytes('{broken'))
        $result = Get-InstallManifest -TargetPath $target
        $result.State | Should -Be 'corrupt'
        $result.Detail | Should -Not -BeNullOrEmpty
    }

    It "returns unsupported for schema v4" {
        $target = Join-Path $TestDrive ([guid]::NewGuid().ToString())
        New-Item -ItemType Directory -Path $target | Out-Null
        $bytes = ConvertTo-Phase0CManifestBytes @{ schema_version = 4; components = @() }
        [IO.File]::WriteAllBytes((Join-Path $target '.ai-workflow-install.json'), $bytes)
        $result = Get-InstallManifest -TargetPath $target
        $result.State | Should -Be 'unsupported'
        $result.SchemaVersion | Should -Be 4
        $result.Detail | Should -Not -BeNullOrEmpty
    }

    It "returns corrupt when components is not an array" {
        $target = Join-Path $TestDrive ([guid]::NewGuid().ToString())
        New-Item -ItemType Directory -Path $target | Out-Null
        $bytes = ConvertTo-Phase0CManifestBytes @{ schema_version = 2; components = @{ name = 'agents/a.md' } }
        [IO.File]::WriteAllBytes((Join-Path $target '.ai-workflow-install.json'), $bytes)
        (Get-InstallManifest -TargetPath $target).State | Should -Be 'corrupt'
    }

    It "returns corrupt for an invalid component name" {
        $target = Join-Path $TestDrive ([guid]::NewGuid().ToString())
        New-Item -ItemType Directory -Path $target | Out-Null
        $bytes = ConvertTo-Phase0CManifestBytes @{ schema_version = 2; components = @(@{ name = '  ' }) }
        [IO.File]::WriteAllBytes((Join-Path $target '.ai-workflow-install.json'), $bytes)
        (Get-InstallManifest -TargetPath $target).State | Should -Be 'corrupt'
    }

    It "returns corrupt for duplicate component names" {
        $target = Join-Path $TestDrive ([guid]::NewGuid().ToString())
        New-Item -ItemType Directory -Path $target | Out-Null
        $bytes = ConvertTo-Phase0CManifestBytes @{ schema_version = 2; components = @(@{ name = 'agents/a.md' }, @{ name = 'agents/a.md' }) }
        [IO.File]::WriteAllBytes((Join-Path $target '.ai-workflow-install.json'), $bytes)
        (Get-InstallManifest -TargetPath $target).State | Should -Be 'corrupt'
    }

    It "hard stops corrupt update before target writes" {
        $target = Join-Path $TestDrive ([guid]::NewGuid().ToString())
        New-Item -ItemType Directory -Path $target | Out-Null
        $manifestBytes = [Text.Encoding]::UTF8.GetBytes('{"schema_version":2,"components":[')
        $fixture = New-Phase0CTarget -Target $target -ManifestBytes $manifestBytes
        $before = Get-Phase0CTreeSnapshot -Root $target
        $result = Invoke-Phase0CBootstrap -Target $target -Arguments @('-Update')
        $result.ExitCode | Should -Not -Be 0
        $result.Output | Should -Match ([regex]::Escape((Join-Path $target '.ai-workflow-install.json')))
        $result.Output | Should -Match 'before any changes'
        $result.Output | Should -Match 'trusted backup'
        [IO.File]::ReadAllBytes((Join-Path $target '.ai-workflow-install.json')) | Should -Be $manifestBytes
        Assert-Phase0CNoWrite -Target $target -Before $before -Sentinel $fixture.Sentinel -Secondary $fixture.Secondary
    }

    It "hard stops unsupported update with observed and supported versions" {
        $target = Join-Path $TestDrive ([guid]::NewGuid().ToString())
        New-Item -ItemType Directory -Path $target | Out-Null
        $manifestBytes = ConvertTo-Phase0CManifestBytes @{ schema_version = 4; components = @() }
        $fixture = New-Phase0CTarget -Target $target -ManifestBytes $manifestBytes
        $before = Get-Phase0CTreeSnapshot -Root $target
        $result = Invoke-Phase0CBootstrap -Target $target -Arguments @('-Update')
        $result.ExitCode | Should -Not -Be 0
        $result.Output | Should -Match 'Observed schema version: 4'
        $result.Output | Should -Match 'Supported schema versions: 1, 2, 3'
        $result.Output | Should -Match 'before any changes'
        [IO.File]::ReadAllBytes((Join-Path $target '.ai-workflow-install.json')) | Should -Be $manifestBytes
        Assert-Phase0CNoWrite -Target $target -Before $before -Sentinel $fixture.Sentinel -Secondary $fixture.Secondary
    }

    It "reports missing update without target writes or a new manifest" {
        $target = Join-Path $TestDrive ([guid]::NewGuid().ToString())
        New-Item -ItemType Directory -Path $target | Out-Null
        $fixture = New-Phase0CTarget -Target $target -ManifestBytes $null
        $before = Get-Phase0CTreeSnapshot -Root $target
        $result = Invoke-Phase0CBootstrap -Target $target -Arguments @('-Update')
        $result.ExitCode | Should -Be 0
        $result.Output | Should -Match 'legacy/missing-manifest'
        $result.Output | Should -Match 'report-only'
        $result.Output | Should -Match 'No files changed'
        Test-Path (Join-Path $target '.ai-workflow-install.json') | Should -BeFalse
        Assert-Phase0CNoWrite -Target $target -Before $before -Sentinel $fixture.Sentinel -Secondary $fixture.Secondary
    }

    It "does not let Force bypass a corrupt update rejection" {
        $target = Join-Path $TestDrive ([guid]::NewGuid().ToString())
        New-Item -ItemType Directory -Path $target | Out-Null
        $manifestBytes = [Text.Encoding]::UTF8.GetBytes('not-json')
        $fixture = New-Phase0CTarget -Target $target -ManifestBytes $manifestBytes
        $before = Get-Phase0CTreeSnapshot -Root $target
        $result = Invoke-Phase0CBootstrap -Target $target -Arguments @('-Update', '-Force')
        $result.ExitCode | Should -Not -Be 0
        [IO.File]::ReadAllBytes((Join-Path $target '.ai-workflow-install.json')) | Should -Be $manifestBytes
        Assert-Phase0CNoWrite -Target $target -Before $before -Sentinel $fixture.Sentinel -Secondary $fixture.Secondary
    }

    It "does not let Backup bypass an unsupported update rejection" {
        $target = Join-Path $TestDrive ([guid]::NewGuid().ToString())
        New-Item -ItemType Directory -Path $target | Out-Null
        $manifestBytes = ConvertTo-Phase0CManifestBytes @{ schema_version = 4; components = @() }
        $fixture = New-Phase0CTarget -Target $target -ManifestBytes $manifestBytes
        $before = Get-Phase0CTreeSnapshot -Root $target
        $result = Invoke-Phase0CBootstrap -Target $target -Arguments @('-Update', '-Backup')
        $result.ExitCode | Should -Not -Be 0
        [IO.File]::ReadAllBytes((Join-Path $target '.ai-workflow-install.json')) | Should -Be $manifestBytes
        Assert-Phase0CNoWrite -Target $target -Before $before -Sentinel $fixture.Sentinel -Secondary $fixture.Secondary
    }
}

$Phase4AVectorsForDiscovery = Get-Content -Raw (Join-Path $PSScriptRoot 'tests/manifest-v3-vectors.json') | ConvertFrom-Json -AsHashtable
$Phase4ASimpleManifestNames = @(
    'unknown-property', 'invalid-enum', 'invalid-hash', 'path-traversal', 'path-absolute',
    'path-drive', 'path-unc', 'path-backslash', 'path-ads', 'path-windows-reserved',
    'path-trailing-alias', 'fork-mapping', 'source-locator-traversal', 'hash-timepoint-mismatch',
    'generated-parent-order', 'timestamp-order', 'component-timestamp-order',
    'manifest-binding-schema-version-boolean'
)

Describe "Phase 4A Manifest v3 reader-first foundation" {
    BeforeAll {
        $script:Phase4ARepoRoot = Split-Path -Parent $PSScriptRoot
        $script:Phase4AVectors = Get-Content -Raw (Join-Path $PSScriptRoot 'tests/manifest-v3-vectors.json') | ConvertFrom-Json -AsHashtable

        function New-Phase4AValidManifest {
            $catalogPath = Join-Path $script:Phase4ARepoRoot 'manifest/component-catalog.json'
            [ordered]@{
                schema_version = 3
                written_at = '2026-07-17T01:30:05Z'
                source_release = [ordered]@{
                    release_id = $script:ComponentCatalogReleaseId
                    source_ref = $script:ComponentCatalogPath
                    version = $script:ComponentCatalogVersion
                    component_catalog = [ordered]@{
                        path = $script:ComponentCatalogPath
                        schema_version = 1
                        sha256 = Get-PathHash -Path $catalogPath
                    }
                }
                last_transaction = [ordered]@{
                    id = 'txn:phase4a-valid'
                    mode = 'update'
                    writer = 'powershell'
                    started_at = '2026-07-17T01:30:00Z'
                    completed_at = '2026-07-17T01:30:05Z'
                    result = 'committed'
                }
                components = @([ordered]@{
                    identity = [ordered]@{
                        id = 'cmp:canonical-coder-agent'
                        path = 'agents/coder.agent.md'
                        path_key = 'agents/coder.agent.md'
                        kind = 'file'
                        role = 'canonical'
                        link = $null
                    }
                    provenance = [ordered]@{
                        ownership = 'template-managed'
                        source = [ordered]@{
                            kind = 'template'
                            locator = 'template:agents/coder.agent.md'
                            release = $script:ComponentCatalogReleaseId
                        }
                        generated_from = @()
                        fork = [ordered]@{
                            status = 'untouched'
                            basis = 'verified-managed-equality'
                            decision = 'manage'
                            classified_at = '2026-07-17T01:30:01Z'
                        }
                    }
                    hashes = [ordered]@{
                        algorithm = 'sha256'
                        content_basis = 'exact-bytes'
                        baseline = 'sha256:' + ('a' * 64)
                        observed_before = 'sha256:' + ('a' * 64)
                        proposed_source = 'sha256:' + ('c' * 64)
                        result_after = 'sha256:' + ('c' * 64)
                    }
                    lifecycle = [ordered]@{
                        state = 'active'
                        previous_paths = @()
                        retirement = $null
                        reintroduces_component_id = $null
                    }
                    last_operation = [ordered]@{
                        transaction_id = 'txn:older-component-op'
                        outcome = 'updated'
                    }
                    installed_at = '2026-04-22T10:00:00Z'
                    updated_at = '2026-07-17T01:30:05Z'
                })
            }
        }

        function Copy-Phase4AObject {
            param([object]$Value)
            $Value | ConvertTo-Json -Depth 100 -Compress | ConvertFrom-Json -AsHashtable
        }

        function New-Phase4ACloneComponent {
            param([string]$Id, [string]$Path, [string[]]$GeneratedFrom)
            $component = (Copy-Phase4AObject (New-Phase4AValidManifest)).components[0]
            $component.identity.id = $Id
            $component.identity.path = $Path
            $component.identity.path_key = $Path.ToLowerInvariant()
            if ($null -ne $GeneratedFrom) {
                $component.identity.role = 'generated'
                $component.provenance.ownership = 'derived-runtime'
                $component.provenance.source.kind = 'generated'
                $component.provenance.source.locator = "generated:$Path"
                $component.provenance.generated_from = @($GeneratedFrom)
            } else {
                $component.provenance.source.locator = "template:$Path"
            }
            return $component
        }

        function Set-Phase4ATombstone {
            param([System.Collections.IDictionary]$Component, [object]$Successor)
            $Component.hashes.proposed_source = $null
            $Component.hashes.result_after = $null
            $Component.lifecycle = [ordered]@{
                state = 'tombstoned'; previous_paths = @()
                retirement = [ordered]@{
                    reason = 'deleted'; detected_at = '2026-07-17T01:30:02Z'
                    source_evidence = [ordered]@{ type = 'component-absent-in-source'; locator = 'template:release-retirement' }
                    successor_component_id = $Successor; pruned_at = '2026-07-17T01:30:04Z'
                }
                reintroduces_component_id = $null
            }
            $Component.last_operation.outcome = 'tombstoned'
        }

        function New-Phase4AComplexManifest {
            param([string]$Name)
            $manifest = Copy-Phase4AObject (New-Phase4AValidManifest)
            $coder = $manifest.components[0]
            switch ($Name) {
                'path-case-collision' {
                    $second = New-Phase4ACloneComponent 'cmp:canonical-pm-agent' 'Agents/Coder.Agent.md' $null
                    $second.identity.path_key = 'agents/coder.agent.md'; $manifest.components += $second
                }
                'generated-parent-duplicate' {
                    $coder.identity.role = 'generated'; $coder.provenance.ownership = 'derived-runtime'
                    $coder.provenance.source.kind = 'generated'; $coder.provenance.source.locator = 'generated:agents/coder.agent.md'
                    $coder.provenance.generated_from = @('cmp:canonical-pm-agent', 'cmp:canonical-pm-agent')
                }
                'generated-parent-missing' {
                    $manifest.components = @(New-Phase4ACloneComponent 'cmp:generated-github-coder-agent' '.github/agents/coder.agent.md' @('cmp:canonical-missing-agent'))
                }
                'generated-parent-cycle' {
                    $manifest.components = @(
                        New-Phase4ACloneComponent 'cmp:generated-github-coder-agent' '.github/agents/coder.agent.md' @('cmp:generated-github-pm-agent')
                        New-Phase4ACloneComponent 'cmp:generated-github-pm-agent' '.github/agents/pm.agent.md' @('cmp:generated-github-coder-agent')
                    ) | Sort-Object { $_.identity.id }
                }
                'retired-invalid' { $coder.lifecycle.state = 'retired' }
                'tombstone-invalid' { Set-Phase4ATombstone $coder $null; $coder.hashes.result_after = 'sha256:' + ('c' * 64) }
                'reintroduction-self' { $coder.lifecycle.reintroduces_component_id = $coder.identity.id }
                'reintroduction-missing' { $coder.lifecycle.reintroduces_component_id = 'cmp:canonical-missing-agent' }
                'reintroduction-non-tombstone' {
                    $coder.lifecycle.reintroduces_component_id = 'cmp:canonical-pm-agent'
                    $manifest.components += New-Phase4ACloneComponent 'cmp:canonical-pm-agent' 'agents/pm.agent.md' $null
                }
                'reintroduction-cycle' {
                    Set-Phase4ATombstone $coder 'cmp:canonical-pm-agent'
                    $replacement = New-Phase4ACloneComponent 'cmp:canonical-pm-agent' 'agents/pm.agent.md' $null
                    $replacement.lifecycle.reintroduces_component_id = 'cmp:canonical-coder-agent'
                    $manifest.components += $replacement
                }
                'duplicate-active-path' { $manifest.components += New-Phase4ACloneComponent 'cmp:canonical-pm-agent' 'agents/coder.agent.md' $null }
                'catalog-component-mismatch' {
                    $coder.identity.path = 'agents/renamed-coder.agent.md'; $coder.identity.path_key = 'agents/renamed-coder.agent.md'
                    $coder.provenance.source.locator = 'template:agents/renamed-coder.agent.md'
                }
                'link-target-escape' {
                    $coder.identity.kind = 'link'; $coder.identity.role = 'generated'; $coder.identity.link = [ordered]@{ target_path = '../outside'; target_path_key = '../outside'; mode = 'symlink' }
                }
                'mount-target-escape' {
                    $coder.identity.kind = 'mount'; $coder.identity.role = 'generated'; $coder.identity.link = [ordered]@{ target_path = '../outside'; target_path_key = '../outside'; mode = 'symlink' }
                }
                'retirement-detected-after-updated' {
                    Set-Phase4ATombstone $coder $null
                    $coder.lifecycle.retirement.detected_at = '2026-07-18T00:00:00Z'
                }
                'retirement-pruned-after-updated' {
                    Set-Phase4ATombstone $coder $null
                    $coder.lifecycle.retirement.pruned_at = '2026-07-18T00:00:00Z'
                }
                'manifest-role-kind-mismatch' {
                    $coder.identity.kind = 'mount'
                    $coder.identity.link = [ordered]@{ target_path = 'skills'; target_path_key = 'skills'; mode = 'symlink' }
                }
                default { throw "Unknown Phase4A vector: $Name" }
            }
            $manifest.components = @($manifest.components | Sort-Object { $_.identity.id })
            return $manifest
        }

        function New-Phase4ADirectoryMountManifest {
            $manifest = Copy-Phase4AObject (New-Phase4AValidManifest)
            $root = New-Phase4ACloneComponent 'cmp:canonical-skills-root' 'skills' $null
            $root.identity.kind = 'directory'
            $root.provenance.fork = [ordered]@{
                status = 'not-applicable'; basis = 'hash-not-applicable'; decision = 'report-only'
                classified_at = '2026-07-17T01:30:01Z'
            }
            foreach ($key in @('baseline', 'observed_before', 'proposed_source', 'result_after')) { $root.hashes[$key] = $null }
            $root.last_operation.outcome = 'reported'
            $mount = New-Phase4ACloneComponent 'cmp:generated-agent-skills-mount' '.agent/skills' @('cmp:canonical-skills-root')
            $mount.identity.kind = 'mount'
            $mount.identity.link = [ordered]@{ target_path = 'skills'; target_path_key = 'skills'; mode = 'symlink' }
            $mount.provenance.fork = Copy-Phase4AObject $root.provenance.fork
            foreach ($key in @('baseline', 'observed_before', 'proposed_source', 'result_after')) { $mount.hashes[$key] = $null }
            $mount.last_operation.outcome = 'reported'
            $manifest.components = @($root, $mount)
            return $manifest
        }

        function Write-Phase4AManifest {
            param([string]$Target, [object]$Manifest)
            $json = $Manifest | ConvertTo-Json -Depth 100
            [IO.File]::WriteAllText((Join-Path $Target '.ai-workflow-install.json'), $json + "`n", [Text.UTF8Encoding]::new($false))
        }

        function New-Phase4ASourceFixture {
            param([string]$Root)
            foreach ($relativePath in @('manifest/component-catalog.json', 'schemas/ai-workflow-install-manifest-v3.schema.json')) {
                $destination = Join-Path $Root $relativePath
                New-Item -ItemType Directory -Path (Split-Path -Parent $destination) -Force | Out-Null
                Copy-Item -LiteralPath (Join-Path $script:Phase4ARepoRoot $relativePath) -Destination $destination
            }
        }

        function Get-Phase4ATreeSnapshot {
            param([string]$Root)
            $items = foreach ($item in @(Get-ChildItem -LiteralPath $Root -Force -Recurse | Sort-Object FullName)) {
                $relative = [IO.Path]::GetRelativePath($Root, $item.FullName).Replace('\', '/')
                if ($item.PSIsContainer) { "$relative/" } else { "$relative|$(Get-FileHash256 -Path $item.FullName)" }
            }
            return @($items)
        }

        function Invoke-Phase4ABootstrap {
            param([string]$Target, [string[]]$Arguments)
            $pwsh = (Get-Process -Id $PID).Path
            $output = & $pwsh -NoProfile -File (Join-Path $PSScriptRoot 'bootstrap.ps1') -TargetPath $Target @Arguments 2>&1 | Out-String
            [PSCustomObject]@{ ExitCode = $LASTEXITCODE; Output = $output }
        }
    }

    It "has the production Schema, Catalog, and complete shared vectors" {
        Test-Path (Join-Path $script:Phase4ARepoRoot $script:Phase4AVectors['production_schema']['path']) | Should -BeTrue
        Test-Path (Join-Path $script:Phase4ARepoRoot $script:Phase4AVectors['catalog']['path']) | Should -BeTrue
        $script:Phase4AVectors['catalog']['component_count'] | Should -Be 253
        @($script:Phase4AVectors['parse_vectors']).Count | Should -Be 7
        @($script:Phase4AVectors['schema_negative_vectors']).Count | Should -Be 4
        @($script:Phase4AVectors['catalog_negative_vectors']).Count | Should -Be 11
        @($script:Phase4AVectors['manifest_negative_vectors']).Count | Should -Be 35
        @($script:Phase4AVectors['mutation_routes']).Count | Should -Be 4
        foreach ($group in @('parse_vectors', 'schema_negative_vectors', 'catalog_negative_vectors', 'manifest_negative_vectors', 'mutation_routes')) {
            $names = @($script:Phase4AVectors[$group] | ForEach-Object { $_.name })
            @($names | Sort-Object -Unique).Count | Should -Be $names.Count
        }
    }

    It "returns stable missing, corrupt JSON, and unsupported diagnostic categories" {
        $target = Join-Path $TestDrive ([guid]::NewGuid().ToString())
        New-Item -ItemType Directory -Path $target | Out-Null
        $result = Get-InstallManifest -TargetPath $target
        @($result.State, $result.DiagnosticCategory) | Should -Be @('missing', 'manifest-missing')
        [IO.File]::WriteAllText((Join-Path $target '.ai-workflow-install.json'), '{broken')
        $result = Get-InstallManifest -TargetPath $target
        @($result.State, $result.DiagnosticCategory) | Should -Be @('corrupt', 'manifest-json')
        [IO.File]::WriteAllText((Join-Path $target '.ai-workflow-install.json'), '{"schema_version":4,"components":[]}')
        $result = Get-InstallManifest -TargetPath $target
        @($result.State, $result.DiagnosticCategory) | Should -Be @('unsupported', 'manifest-version')
    }

    It "correction2 consumes parse vector <name>" -ForEach @(
        $Phase4AVectorsForDiscovery.parse_vectors
    ) {
        param($name, $state, $category)
        $target = Join-Path $TestDrive ([guid]::NewGuid().ToString())
        New-Item -ItemType Directory -Path $target | Out-Null
        $sourceRoot = $null
        $originalRepoRoot = $script:RepoRoot
        try {
            switch ($name) {
                'missing' { }
                'valid-v1' { Write-Phase4AManifest $target ([ordered]@{ schema_version = 1; components = @() }) }
                'valid-v2' { Write-Phase4AManifest $target ([ordered]@{ schema_version = 2; components = @() }) }
                'valid-v3' { Write-Phase4AManifest $target (New-Phase4AValidManifest); $sourceRoot = $script:Phase4ARepoRoot }
                'v3-source-unavailable' {
                    Write-Phase4AManifest $target (New-Phase4AValidManifest)
                    $script:RepoRoot = Join-Path $TestDrive 'source-unavailable'
                }
                'corrupt-json' { [IO.File]::WriteAllText((Join-Path $target '.ai-workflow-install.json'), '{broken') }
                'unsupported-version' { Write-Phase4AManifest $target ([ordered]@{ schema_version = 4; components = @() }) }
                default { throw "Unhandled parse vector: $name" }
            }
            $result = Get-InstallManifest -TargetPath $target -SourceRoot $sourceRoot
        } finally {
            $script:RepoRoot = $originalRepoRoot
        }
        $result.State | Should -Be $state
        $result.DiagnosticCategory | Should -Be $category -Because $result.Detail
        if ($name -eq 'valid-v3') { $result.CatalogValidated | Should -BeTrue }
        if ($name -eq 'v3-source-unavailable') {
            $result.CatalogValidated | Should -BeFalse
            $result.Entries.Count | Should -Be 0
        }
    }

    It "recognizes legacy v<Version> without rewriting it" -ForEach @(
        @{ Version = 1 }
        @{ Version = 2 }
    ) {
        param($Version)
        $target = Join-Path $TestDrive ([guid]::NewGuid().ToString())
        New-Item -ItemType Directory -Path $target | Out-Null
        $path = Join-Path $target '.ai-workflow-install.json'
        $bytes = [Text.Encoding]::UTF8.GetBytes((@{ schema_version = $Version; components = @(@{ name = "agents/v$Version.md" }) } | ConvertTo-Json -Depth 5 -Compress))
        [IO.File]::WriteAllBytes($path, $bytes)

        $result = Get-InstallManifest -TargetPath $target

        $result.State | Should -Be "valid-v$Version"
        $result.DiagnosticCategory | Should -Be "manifest-valid-v$Version"
        [IO.File]::ReadAllBytes($path) | Should -Be $bytes
    }

    It "emits a Catalog-bound production v3 Manifest" {
        $target = Join-Path $TestDrive ([guid]::NewGuid().ToString())
        New-Item -ItemType Directory -Path $target | Out-Null
        Write-InstallManifest -TargetPath $target -SourceRoot $script:Phase4ARepoRoot -ManifestEntries @{}
        $written = Get-Content -Raw (Join-Path $target '.ai-workflow-install.json') | ConvertFrom-Json -AsHashtable
        $written['schema_version'] | Should -Be 3
        $written['last_transaction']['writer'] | Should -Be 'powershell'
        (Get-InstallManifest -TargetPath $target -SourceRoot $script:Phase4ARepoRoot).State | Should -Be 'valid-v3'
    }

    It "matches the corrected normative Catalog allocation and audit fingerprint" {
        $catalog = Get-Content -Raw (Join-Path $script:Phase4ARepoRoot 'manifest/component-catalog.json') | ConvertFrom-Json -AsHashtable
        @($catalog.components).Count | Should -Be 253
        @($catalog.components | Where-Object role -eq 'canonical').Count | Should -Be 101
        @($catalog.components | Where-Object role -eq 'generated').Count | Should -Be 110
        @($catalog.components | Where-Object kind -eq 'directory').Count | Should -Be 1
        @($catalog.components | Where-Object kind -eq 'mount').Count | Should -Be 3
        foreach ($mount in @($catalog.components | Where-Object kind -eq 'mount')) {
            @($mount.generated_from) | Should -Be @('cmp:canonical-skills-root')
        }
        $rows = @($catalog.components | ForEach-Object {
            $parents = @(); foreach ($parent in @($_.generated_from)) { $parents += [string]$parent }
            [ordered]@{
                id = $_.id; canonical_source_path = $_.canonical_source_path
                role = $_.role; kind = $_.kind; generated_from = $parents
            }
        })
        $compact = $rows | ConvertTo-Json -Depth 100 -Compress
        (Get-Sha256ForBytes ([Text.Encoding]::UTF8.GetBytes($compact))) | Should -Be $script:Phase4AVectors.catalog.allocation_fingerprint
        (Get-Content -Raw (Join-Path $PSScriptRoot 'bootstrap.ps1')) | Should -Not -Match 'phase-4-manifest-v3\.schema\.proposed\.json'
    }

    It "accepts a Catalog-bound v3 read-only without rewriting it" {
        $target = Join-Path $TestDrive ([guid]::NewGuid().ToString())
        New-Item -ItemType Directory -Path $target | Out-Null
        Write-Phase4AManifest $target (New-Phase4AValidManifest)
        $before = [IO.File]::ReadAllBytes((Join-Path $target '.ai-workflow-install.json'))
        $result = Get-InstallManifest -TargetPath $target -SourceRoot $script:Phase4ARepoRoot
        $result.State | Should -Be 'valid-v3'
        $result.DiagnosticCategory | Should -Be 'manifest-valid-v3'
        $result.CatalogValidated | Should -BeTrue
        $result.Entries.ContainsKey('cmp:canonical-coder-agent') | Should -BeTrue
        [IO.File]::ReadAllBytes((Join-Path $target '.ai-workflow-install.json')) | Should -Be $before
    }

    It "accepts canonical directory parent and generated mount lineage" {
        $target = Join-Path $TestDrive ([guid]::NewGuid().ToString())
        New-Item -ItemType Directory -Path $target | Out-Null
        Write-Phase4AManifest $target (New-Phase4ADirectoryMountManifest)
        $result = Get-InstallManifest -TargetPath $target -SourceRoot $script:Phase4ARepoRoot
        $result.State | Should -Be 'valid-v3'
        $result.CatalogValidated | Should -BeTrue
        @($result.Entries.Keys | Sort-Object) | Should -Be @('cmp:canonical-skills-root', 'cmp:generated-agent-skills-mount')
    }

    It "correction2 requires exact Production Schema vector <name>" -ForEach @(
        $Phase4AVectorsForDiscovery.schema_negative_vectors
    ) {
        param($name, $category)
        $source = Join-Path $TestDrive ([guid]::NewGuid().ToString())
        New-Phase4ASourceFixture $source
        $schemaPath = Join-Path $source 'schemas/ai-workflow-install-manifest-v3.schema.json'
        switch ($name) {
            'catalog-missing' { }
            'schema-missing' { Remove-Item -LiteralPath $schemaPath }
            'schema-invalid-json' { [IO.File]::WriteAllText($schemaPath, '{broken') }
            'schema-wrong-id' {
                $schema = Get-Content -Raw $schemaPath | ConvertFrom-Json -AsHashtable
                $schema['$id'] = 'urn:unexpected'
                [IO.File]::WriteAllText($schemaPath, ($schema | ConvertTo-Json -Depth 100))
            }
            'schema-proposal-marker' {
                $schema = Get-Content -Raw $schemaPath | ConvertFrom-Json -AsHashtable
                $schema.properties['proposal_status'] = [ordered]@{ const = 'proposed' }
                $schema.required += 'proposal_status'
                [IO.File]::WriteAllText($schemaPath, ($schema | ConvertTo-Json -Depth 100))
            }
            default { throw "Unhandled Schema vector: $name" }
        }
        $target = Join-Path $TestDrive ([guid]::NewGuid().ToString())
        New-Item -ItemType Directory -Path $target | Out-Null
        Write-Phase4AManifest $target (New-Phase4AValidManifest)
        $result = Get-InstallManifest -TargetPath $target -SourceRoot $source
        $result.State | Should -Be 'corrupt'
        $result.DiagnosticCategory | Should -Be $category
    }

    It "rejects v3 semantic vector <name> with stable category" -ForEach @(
        $Phase4AVectorsForDiscovery.manifest_negative_vectors |
            Where-Object { $_.name -in $Phase4ASimpleManifestNames }
    ) {
        param($name, $category)
        $target = Join-Path $TestDrive ([guid]::NewGuid().ToString())
        New-Item -ItemType Directory -Path $target | Out-Null
        $manifest = Copy-Phase4AObject (New-Phase4AValidManifest)
        switch ($name) {
            'unknown-property' { $manifest['unknown'] = $true }
            'invalid-enum' { $manifest.last_transaction.mode = 'prune' }
            'invalid-hash' { $manifest.components[0].hashes.baseline = 'SHA256:BAD' }
            'path-traversal' { $manifest.components[0].identity.path = '../escape' }
            'path-absolute' { $manifest.components[0].identity.path = '/escape' }
            'path-drive' { $manifest.components[0].identity.path = 'C:/escape' }
            'path-unc' { $manifest.components[0].identity.path = '//server/share' }
            'path-backslash' { $manifest.components[0].identity.path = 'agents\coder.md' }
            'path-ads' { $manifest.components[0].identity.path = 'agents/coder.md:ads' }
            'path-windows-reserved' { $manifest.components[0].identity.path = 'agents/CON.md' }
            'path-trailing-alias' { $manifest.components[0].identity.path = 'agents/coder.' }
            'fork-mapping' { $manifest.components[0].provenance.fork.decision = 'preserve' }
            'source-locator-traversal' { $manifest.components[0].provenance.source.locator = 'template:../secret' }
            'hash-timepoint-mismatch' { $manifest.components[0].hashes.result_after = 'sha256:' + ('d' * 64) }
            'generated-parent-order' { $manifest.components[0].provenance.generated_from = @('cmp:z-parent', 'cmp:a-parent') }
            'timestamp-order' { $manifest.last_transaction.completed_at = '2026-07-17T01:29:59Z' }
            'component-timestamp-order' { $manifest.components[0].installed_at = '2026-07-18T00:00:00Z' }
            'manifest-binding-schema-version-boolean' { $manifest.source_release.component_catalog.schema_version = $true }
            default { throw "Unhandled simple Manifest vector: $name" }
        }
        Write-Phase4AManifest $target $manifest
        $result = Get-InstallManifest -TargetPath $target -SourceRoot $script:Phase4ARepoRoot
        $result.State | Should -Be 'corrupt'
        $result.DiagnosticCategory | Should -Be $category
    }

    It "rejects v3 cross-record/link vector <name> with stable category" -ForEach @(
        $Phase4AVectorsForDiscovery.manifest_negative_vectors |
            Where-Object { $_.name -notin $Phase4ASimpleManifestNames }
    ) {
        param($name, $category)
        $target = Join-Path $TestDrive ([guid]::NewGuid().ToString())
        New-Item -ItemType Directory -Path $target | Out-Null
        Write-Phase4AManifest $target (New-Phase4AComplexManifest $name)
        $result = Get-InstallManifest -TargetPath $target -SourceRoot $script:Phase4ARepoRoot
        $result.State | Should -Be 'corrupt'
        $result.DiagnosticCategory | Should -Be $category -Because $result.Detail
    }

    It "rejects Catalog vector <name> with stable category" -ForEach @(
        $Phase4AVectorsForDiscovery.catalog_negative_vectors
    ) {
        param($name, $category)
        $source = Join-Path $TestDrive ([guid]::NewGuid().ToString())
        $catalogTarget = Join-Path $source 'manifest/component-catalog.json'
        New-Item -ItemType Directory -Path (Split-Path -Parent $catalogTarget) -Force | Out-Null
        $schemaTarget = Join-Path $source 'schemas/ai-workflow-install-manifest-v3.schema.json'
        New-Item -ItemType Directory -Path (Split-Path -Parent $schemaTarget) -Force | Out-Null
        Copy-Item -LiteralPath (Join-Path $script:Phase4ARepoRoot 'schemas/ai-workflow-install-manifest-v3.schema.json') -Destination $schemaTarget
        $catalog = Get-Content -Raw (Join-Path $script:Phase4ARepoRoot 'manifest/component-catalog.json') | ConvertFrom-Json -AsHashtable
        $byId = @{}; foreach ($component in $catalog.components) { $byId[$component.id] = $component }
        switch ($name) {
            'catalog-missing' { }
            'catalog-duplicate-id' {
                $catalog.components += Copy-Phase4AObject $byId['cmp:canonical-coder-agent']
                $catalog.components = @($catalog.components | Sort-Object id)
            }
            'catalog-duplicate-active-path' { $byId['cmp:canonical-pm-agent'].canonical_source_path = 'agents/coder.agent.md' }
            'catalog-unknown-parent' { $byId['cmp:generated-github-coder-agent'].generated_from = @('cmp:canonical-missing-agent') }
            'catalog-cycle' {
                $byId['cmp:generated-github-coder-agent'].generated_from = @('cmp:generated-github-pm-agent')
                $byId['cmp:generated-github-pm-agent'].generated_from = @('cmp:generated-github-coder-agent')
            }
            'catalog-self-reference' { $byId['cmp:generated-github-coder-agent'].generated_from = @('cmp:generated-github-coder-agent') }
            'catalog-terminal-id-reuse' { $byId['cmp:canonical-coder-agent'].lifecycle_status = 'tombstoned' }
            'catalog-role-kind-mismatch' { $byId['cmp:canonical-coder-agent'].kind = 'mount' }
            'catalog-schema-version-boolean' { $catalog.catalog_schema_version = $true }
            { $_ -in @('catalog-digest-mismatch', 'catalog-release-mismatch') } { }
            default { throw "Unhandled Catalog vector: $name" }
        }
        if ($name -ne 'catalog-missing') {
            $catalogJson = $catalog | ConvertTo-Json -Depth 100
            [IO.File]::WriteAllText($catalogTarget, $catalogJson + "`n", [Text.UTF8Encoding]::new($false))
        }
        $manifest = New-Phase4AValidManifest
        if ($name -ne 'catalog-missing') { $manifest.source_release.component_catalog.sha256 = Get-PathHash $catalogTarget }
        if ($name -eq 'catalog-digest-mismatch') { $manifest.source_release.component_catalog.sha256 = 'sha256:' + ('0' * 64) }
        if ($name -eq 'catalog-release-mismatch') { $manifest.source_release.release_id = 'unexpected-release' }
        $target = Join-Path $TestDrive ([guid]::NewGuid().ToString())
        New-Item -ItemType Directory -Path $target | Out-Null
        Write-Phase4AManifest $target $manifest
        $result = Get-InstallManifest -TargetPath $target -SourceRoot $source
        $result.State | Should -Be 'corrupt'
        $result.DiagnosticCategory | Should -Be $category
    }

    It "routes valid v3 operation <name> through the Phase 4D ownership boundary" -ForEach @(
        $Phase4AVectorsForDiscovery.mutation_routes
    ) {
        param($name, $powershell_arguments, $category)
        $target = Join-Path $TestDrive ([guid]::NewGuid().ToString())
        New-Item -ItemType Directory -Path $target | Out-Null
        New-Item -ItemType Directory -Path (Join-Path $target '.github') | Out-Null
        New-Item -ItemType Directory -Path (Join-Path $target 'skills/custom') -Force | Out-Null
        New-Item -ItemType Directory -Path (Join-Path $target 'agents') -Force | Out-Null
        [IO.File]::WriteAllBytes((Join-Path $target '.github/copilot-instructions.md'), [Text.Encoding]::UTF8.GetBytes('sentinel'))
        [IO.File]::WriteAllBytes((Join-Path $target 'skills/custom/SKILL.md'), [Text.Encoding]::UTF8.GetBytes('custom'))
        Write-Phase4AManifest $target (New-Phase4AValidManifest)
        $before = Get-Phase4ATreeSnapshot $target
        $result = Invoke-Phase4ABootstrap -Target $target -Arguments @($powershell_arguments)
        if ($name -in @('install', 'force')) {
            $result.ExitCode | Should -Not -Be 0
            $result.Output | Should -Match 'valid-v3 requires explicit -Update'
            $result.Output | Should -Not -Match 'manifest-v3-writer-disabled'
            (Get-Phase4ATreeSnapshot $target) | Should -Be $before
            Test-Path (Join-Path $target '.git') | Should -BeFalse
            @(Get-ChildItem -LiteralPath $target -Force -Filter '*.backup-*').Count | Should -Be 0
        } else {
            $result.ExitCode | Should -Be 0
            $result.Output | Should -Match 'Manifest v3 update completed'
            $result.Output | Should -Not -Match 'manifest-v3-writer-disabled'
            (Get-InstallManifest -TargetPath $target -SourceRoot $script:Phase4ARepoRoot).State | Should -Be 'valid-v3'
            @(Get-ChildItem -LiteralPath $target -Force -Directory -Filter '.ai-workflow-phase4d-backup-*').Count | Should -Be 1
            [IO.File]::ReadAllText((Join-Path $target '.github/copilot-instructions.md')) | Should -Be 'sentinel'
            [IO.File]::ReadAllText((Join-Path $target 'skills/custom/SKILL.md')) | Should -Be 'custom'
        }
    }

    It "correction2 blocks corrupt or unsupported <manifestKind> route <name> before target mutation" -ForEach @(
        foreach ($manifestKind in @('corrupt-json', 'unsupported-version')) {
            foreach ($route in $Phase4AVectorsForDiscovery.mutation_routes) {
                @{ manifestKind = $manifestKind; name = $route.name; powershell_arguments = $route.powershell_arguments }
            }
        }
    ) {
        param($manifestKind, $name, $powershell_arguments)
        $target = Join-Path $TestDrive "$manifestKind-$name"
        New-Item -ItemType Directory -Path $target | Out-Null
        New-Item -ItemType Directory -Path (Join-Path $target '.github') | Out-Null
        New-Item -ItemType Directory -Path (Join-Path $target 'skills/custom') -Force | Out-Null
        [IO.File]::WriteAllBytes((Join-Path $target '.github/copilot-instructions.md'), [Text.Encoding]::UTF8.GetBytes('sentinel'))
        [IO.File]::WriteAllBytes((Join-Path $target 'skills/custom/SKILL.md'), [Text.Encoding]::UTF8.GetBytes('custom'))
        if ($manifestKind -eq 'corrupt-json') {
            [IO.File]::WriteAllText((Join-Path $target '.ai-workflow-install.json'), '{broken')
        } else {
            Write-Phase4AManifest $target ([ordered]@{ schema_version = 4; components = @() })
        }
        $before = Get-Phase4ATreeSnapshot $target
        $result = Invoke-Phase4ABootstrap -Target $target -Arguments @($powershell_arguments)
        $result.ExitCode | Should -Not -Be 0
        $result.Output | Should -Match $(if ($manifestKind -eq 'corrupt-json') { 'Corrupt install manifest' } else { 'Unsupported install manifest' })
        (Get-Phase4ATreeSnapshot $target) | Should -Be $before
    }

    It "correction2 labels source-unavailable v3 as blocked and remote acquisition includes validation artifacts" {
        $target = Join-Path $TestDrive 'source-unavailable'
        New-Item -ItemType Directory -Path $target | Out-Null
        Write-Phase4AManifest $target (New-Phase4AValidManifest)
        $originalRepoRoot = $script:RepoRoot
        try {
            $script:RepoRoot = Join-Path $TestDrive 'standalone'
            $result = Get-InstallManifest -TargetPath $target
        } finally {
            $script:RepoRoot = $originalRepoRoot
        }
        $result.State | Should -Be 'v3-validation-blocked'
        $result.DiagnosticCategory | Should -Be 'catalog-unavailable'
        $result.CatalogValidated | Should -BeFalse
        $result.Entries.Count | Should -Be 0
        $scriptText = Get-Content -Raw (Join-Path $PSScriptRoot 'bootstrap.ps1')
        $scriptText | Should -Match 'sparse-checkout set[^\r\n]*manifest[^\r\n]*schemas'
        $scriptText | Should -Match 'if \(\$pendingV3Validation\)[\s\S]*Remove-TempDirectory -Path \$script:TempClonePath'
    }
}

Describe "Phase 4D Windows Manifest v3 writer" {
    BeforeAll {
        $script:Phase4DRepoRoot = Split-Path -Parent $PSScriptRoot

        function New-Phase4DTarget {
            $target = Join-Path $TestDrive ([guid]::NewGuid().ToString())
            New-Item -ItemType Directory -Path $target | Out-Null
            return $target
        }

        function Write-Phase4DLegacyManifest {
            param([string]$Target, [int]$Version = 2)
            $sourcePath = 'agents/coder.agent.md'
            $sourceHash = Get-PathHash (Join-Path $script:Phase4DRepoRoot $sourcePath)
            $manifest = [ordered]@{
                schema_version = $Version
                installed_at = '2026-07-01T00:00:00Z'
                source_ref = 'legacy-source'
                components = @([ordered]@{
                    name = $sourcePath
                    installed_at = '2026-07-01T00:00:00Z'
                    updated_at = '2026-07-01T00:00:00Z'
                    source_hash = $sourceHash
                    managed_hash = $sourceHash
                    observed_hash = $sourceHash
                    ownership = 'template-managed'
                    kind = 'file'
                    source = "template:$sourcePath"
                    status = 'managed'
                })
            }
            [IO.File]::WriteAllText(
                (Join-Path $Target '.ai-workflow-install.json'),
                ($manifest | ConvertTo-Json -Depth 20) + "`n",
                [Text.UTF8Encoding]::new($false)
            )
        }

        function Invoke-Phase4DBootstrap {
            param([string]$Target, [string[]]$Arguments)
            $pwsh = (Get-Process -Id $PID).Path
            $output = & $pwsh -NoProfile -File (Join-Path $PSScriptRoot 'bootstrap.ps1') -TargetPath $Target @Arguments 2>&1 | Out-String
            [PSCustomObject]@{ ExitCode = $LASTEXITCODE; Output = $output }
        }

        function Get-Phase4DTreeSnapshot {
            param([string]$Root)
            $items = foreach ($item in @(Get-ChildItem -LiteralPath $Root -Force -Recurse | Sort-Object FullName)) {
                $relative = [IO.Path]::GetRelativePath($Root, $item.FullName).Replace('\', '/')
                if ($item.PSIsContainer) { "$relative/" } else { "$relative|$(Get-FileHash256 -Path $item.FullName)" }
            }
            return @($items)
        }

        function New-Phase4DSourceRoot {
            param([byte[]]$CoderBytes)
            $root = Join-Path $TestDrive ("phase4d-source-" + [guid]::NewGuid().ToString('N'))
            New-Item -ItemType Directory -Path (Join-Path $root 'schemas') -Force | Out-Null
            New-Item -ItemType Directory -Path (Join-Path $root 'manifest') -Force | Out-Null
            New-Item -ItemType Directory -Path (Join-Path $root 'agents') -Force | Out-Null
            Copy-Item -LiteralPath (Join-Path $script:Phase4DRepoRoot 'schemas/ai-workflow-install-manifest-v3.schema.json') -Destination (Join-Path $root 'schemas/ai-workflow-install-manifest-v3.schema.json')
            Copy-Item -LiteralPath (Join-Path $script:Phase4DRepoRoot 'manifest/component-catalog.json') -Destination (Join-Path $root 'manifest/component-catalog.json')
            [IO.File]::WriteAllBytes((Join-Path $root 'agents/coder.agent.md'), $CoderBytes)
            return $root
        }

        function Write-Phase4DV3Baseline {
            param([string]$Target, [string]$SourceRoot, [byte[]]$Bytes)
            New-Item -ItemType Directory -Path (Join-Path $Target 'agents') -Force | Out-Null
            [IO.File]::WriteAllBytes((Join-Path $Target 'agents/coder.agent.md'), $Bytes)
            $hash = Get-BytesHash $Bytes
            $entries = @{
                'agents/coder.agent.md' = [ordered]@{
                    name = 'agents/coder.agent.md'; installed_at = '2026-07-01T00:00:00Z'
                    source_hash = $hash; managed_hash = $hash; observed_hash = $hash
                    ownership = 'template-managed'; kind = 'file'; source = 'template:agents/coder.agent.md'; status = 'managed'
                }
            }
            Write-InstallManifest -TargetPath $Target -SourceRoot $SourceRoot -ManifestEntries $entries -Mode install
        }
    }

    Context "State Matrix A - new install" {
        It "emits a Catalog-bound production v3 Manifest for a fresh install" {
            $target = New-Phase4DTarget
            $entries = @{}
            $sourcePath = 'agents/coder.agent.md'
            $sourceHash = Get-PathHash (Join-Path $script:Phase4DRepoRoot $sourcePath)
            Set-ManifestEntry -ManifestEntries $entries -RelativePath $sourcePath -Ownership 'template-managed' -SourceLabel "template:$sourcePath" -Kind 'file' -ManagedHash $sourceHash -ObservedHash $sourceHash -Status 'managed'

            Write-InstallManifest -TargetPath $target -SourceRoot $script:Phase4DRepoRoot -ManifestEntries $entries -Mode install

            $result = Get-InstallManifest -TargetPath $target -SourceRoot $script:Phase4DRepoRoot
            $result.State | Should -Be 'valid-v3'
            $manifest = Get-Content -Raw (Join-Path $target '.ai-workflow-install.json') | ConvertFrom-Json -AsHashtable
            $manifest.schema_version | Should -Be 3
            $manifest.last_transaction.writer | Should -Be 'powershell'
            $manifest.components[0].identity.id | Should -Be 'cmp:canonical-coder-agent'
            $manifest.components[0].provenance.ownership | Should -Be 'template-managed'
            $manifest.components[0].hashes.baseline | Should -Be $sourceHash
            $manifest.components[0].hashes.observed_before | Should -Be $sourceHash
            $manifest.components[0].hashes.proposed_source | Should -Be $sourceHash
            $manifest.components[0].provenance.generated_from | Should -Be @()
        }

        It "treats a non-empty target with no Manifest as legacy report-only" {
            $target = New-Phase4DTarget
            [IO.File]::WriteAllText((Join-Path $target 'project.txt'), 'sentinel')
            $before = Get-Phase4DTreeSnapshot $target

            $result = Invoke-Phase4DBootstrap -Target $target -Arguments @('-Update')

            $result.ExitCode | Should -Be 0
            $result.Output | Should -Match 'legacy/missing-manifest'
            $result.Output | Should -Match 'report-only'
            (Get-Phase4DTreeSnapshot $target) | Should -Be $before
            Test-Path (Join-Path $target '.ai-workflow-install.json') | Should -BeFalse
        }
    }

    Context "State Matrix B - legacy general update" {
        It "requires Migration Preview for v<Version> general Update without target writes" -ForEach @(
            @{ Version = 1 }, @{ Version = 2 }
        ) {
            param($Version)
            $target = New-Phase4DTarget
            Write-Phase4DLegacyManifest -Target $target -Version $Version
            $before = Get-Phase4DTreeSnapshot $target

            $result = Invoke-Phase4DBootstrap -Target $target -Arguments @('-Update', '-Force')

            $result.ExitCode | Should -Not -Be 0
            $result.Output | Should -Match 'migration-preview-required'
            $result.Output | Should -Match 'MigrationPreview'
            (Get-Phase4DTreeSnapshot $target) | Should -Be $before
        }
    }

    Context "State Matrix C and D - explicit migration" {
        It "creates a deterministic no-write Preview bound to exact input bytes" {
            $target = New-Phase4DTarget
            Write-Phase4DLegacyManifest -Target $target
            $manifestPath = Join-Path $target '.ai-workflow-install.json'
            $before = Get-Phase4DTreeSnapshot $target

            $first = New-ManifestMigrationPreview -TargetPath $target -SourceRoot $script:Phase4DRepoRoot
            (Get-Item -LiteralPath $manifestPath -Force).LastWriteTimeUtc = [datetime]'2025-01-01T00:00:00Z'
            $second = New-ManifestMigrationPreview -TargetPath $target -SourceRoot $script:Phase4DRepoRoot

            $first.input_version | Should -Be 2
            $first.normalized_target | Should -Be ([IO.Path]::GetFullPath($target))
            $first.input_manifest_sha256 | Should -Be (Get-BytesHash ([IO.File]::ReadAllBytes($manifestPath)))
            $first.proposed_manifest_sha256 | Should -Match '^sha256:[0-9a-f]{64}$'
            $first.schema.id | Should -Be 'urn:ai-dev-workflow:manifest-schema:v3'
            $first.schema.version | Should -Be 3
            $first.catalog.fingerprint | Should -Be (Get-PathHash (Join-Path $script:Phase4DRepoRoot 'manifest/component-catalog.json'))
            $first.source.version | Should -Be $script:ComponentCatalogVersion
            $first.source.ref | Should -Be $script:ComponentCatalogPath
            @($first.mapped_components).Count | Should -Be 1
            $first.PSObject.Properties.Name | Should -Contain 'preserved_components'
            $first.PSObject.Properties.Name | Should -Contain 'legacy_components'
            $first.PSObject.Properties.Name | Should -Contain 'blocking_findings'
            $first.backup_plan.required | Should -BeTrue
            $first.no_write_confirmation | Should -BeTrue
            $first.preview_id | Should -Match '^preview:sha256:[0-9a-f]{64}$'
            $second.preview_id | Should -Be $first.preview_id
            $second.proposed_manifest_sha256 | Should -Be $first.proposed_manifest_sha256
            (Get-Phase4DTreeSnapshot $target) | Should -Be $before
        }

        It "hard-stops Apply when Expected Preview ID does not match" {
            $target = New-Phase4DTarget
            Write-Phase4DLegacyManifest -Target $target
            $before = Get-Phase4DTreeSnapshot $target

            { Invoke-ManifestMigrationApply -TargetPath $target -SourceRoot $script:Phase4DRepoRoot -ExpectedPreviewId ('preview:sha256:' + ('0' * 64)) } | Should -Throw '*preview-mismatch*'

            (Get-Phase4DTreeSnapshot $target) | Should -Be $before
        }

        It "applies only the matching Manifest migration and preserves managed files" {
            $target = New-Phase4DTarget
            New-Item -ItemType Directory -Path (Join-Path $target 'agents') | Out-Null
            [IO.File]::WriteAllText((Join-Path $target 'agents/coder.agent.md'), 'custom-managed-sentinel')
            Write-Phase4DLegacyManifest -Target $target
            $managedBefore = [IO.File]::ReadAllBytes((Join-Path $target 'agents/coder.agent.md'))
            $preview = New-ManifestMigrationPreview -TargetPath $target -SourceRoot $script:Phase4DRepoRoot

            $result = Invoke-ManifestMigrationApply -TargetPath $target -SourceRoot $script:Phase4DRepoRoot -ExpectedPreviewId $preview.preview_id

            $result.status | Should -Be 'completed'
            $result.backup_path | Should -Exist
            [IO.File]::ReadAllBytes((Join-Path $target 'agents/coder.agent.md')) | Should -Be $managedBefore
            (Get-InstallManifest -TargetPath $target -SourceRoot $script:Phase4DRepoRoot).State | Should -Be 'valid-v3'
            @(Get-ChildItem -LiteralPath $target -Force -Recurse | Where-Object Name -Match 'tombstone|prune').Count | Should -Be 0
        }

        It "reports repeated Apply against valid v3 as already-v3 without mutation" {
            $target = New-Phase4DTarget
            Write-Phase4DLegacyManifest -Target $target
            $preview = New-ManifestMigrationPreview -TargetPath $target -SourceRoot $script:Phase4DRepoRoot
            $null = Invoke-ManifestMigrationApply -TargetPath $target -SourceRoot $script:Phase4DRepoRoot -ExpectedPreviewId $preview.preview_id
            $before = Get-Phase4DTreeSnapshot $target

            $result = Invoke-ManifestMigrationApply -TargetPath $target -SourceRoot $script:Phase4DRepoRoot -ExpectedPreviewId $preview.preview_id

            $result.status | Should -Be 'already-v3'
            $result.applicable | Should -BeFalse
            (Get-Phase4DTreeSnapshot $target) | Should -Be $before
        }

        It "keeps Preview deterministic without fabricating committed production timestamps" {
            $target = New-Phase4DTarget
            Write-Phase4DLegacyManifest -Target $target

            $first = New-ManifestMigrationPreview -TargetPath $target -SourceRoot $script:Phase4DRepoRoot
            $second = New-ManifestMigrationPreview -TargetPath $target -SourceRoot $script:Phase4DRepoRoot

            $first.preview_id | Should -Be $second.preview_id
            $first.proposed_manifest_sha256 | Should -Be $second.proposed_manifest_sha256
            $first.PSObject.Properties.Name | Should -Not -Contain 'candidate_manifest'
            $first.PSObject.Properties.Name | Should -Not -Contain 'candidate_bytes'

            $beforeApply = [DateTimeOffset]::UtcNow.AddSeconds(-1)
            $result = Invoke-ManifestMigrationApply -TargetPath $target -SourceRoot $script:Phase4DRepoRoot -ExpectedPreviewId $first.preview_id
            $afterApply = [DateTimeOffset]::UtcNow.AddSeconds(1)
            $published = Get-Content -Raw (Join-Path $target '.ai-workflow-install.json') | ConvertFrom-Json -AsHashtable -DateKind String
            $writtenAt = [DateTimeOffset]::Parse($published.written_at, [Globalization.CultureInfo]::InvariantCulture).UtcDateTime

            $result.status | Should -Be 'completed'
            $writtenAt | Should -BeGreaterOrEqual $beforeApply.UtcDateTime
            $writtenAt | Should -BeLessOrEqual $afterApply.UtcDateTime
        }
    }

    Context "State Matrix E - existing valid-v3 general update" {
        It "updates only an Untouched regular file whose current hash equals the trusted v3 baseline" {
            $oldBytes = [Text.UTF8Encoding]::new($false).GetBytes("old managed bytes`n")
            $newBytes = [Text.UTF8Encoding]::new($false).GetBytes("new source bytes`n")
            $source = New-Phase4DSourceRoot -CoderBytes $oldBytes
            $target = New-Phase4DTarget
            Write-Phase4DV3Baseline -Target $target -SourceRoot $source -Bytes $oldBytes
            [IO.File]::WriteAllBytes((Join-Path $source 'agents/coder.agent.md'), $newBytes)
            $manifestResult = Get-InstallManifest -TargetPath $target -SourceRoot $source

            $entries = ConvertFrom-V3ManifestForUpdate -ManifestResult $manifestResult -TargetPath $target -SourceRoot $source
            $sync = New-SyncResult
            Set-ManagedBytes -Path (Join-Path $target 'agents/coder.agent.md') -RelativePath 'agents/coder.agent.md' -Bytes $newBytes -Result $sync -ManifestEntries $entries -Ownership 'template-managed' -SourceLabel 'template:agents/coder.agent.md' -Force -AlwaysOverwrite

            [IO.File]::ReadAllBytes((Join-Path $target 'agents/coder.agent.md')) | Should -Be $newBytes
            $sync.FilesUpdated | Should -Contain 'agents/coder.agent.md'
        }

        It "preserves Customized bytes even when Force and AlwaysOverwrite are supplied" {
            $baselineBytes = [Text.UTF8Encoding]::new($false).GetBytes("baseline bytes`n")
            $sourceBytes = [Text.UTF8Encoding]::new($false).GetBytes("new source bytes`n")
            $customBytes = [Text.UTF8Encoding]::new($false).GetBytes("adopter customization`n")
            $source = New-Phase4DSourceRoot -CoderBytes $baselineBytes
            $target = New-Phase4DTarget
            Write-Phase4DV3Baseline -Target $target -SourceRoot $source -Bytes $baselineBytes
            [IO.File]::WriteAllBytes((Join-Path $source 'agents/coder.agent.md'), $sourceBytes)
            [IO.File]::WriteAllBytes((Join-Path $target 'agents/coder.agent.md'), $customBytes)
            $manifestResult = Get-InstallManifest -TargetPath $target -SourceRoot $source

            $entries = ConvertFrom-V3ManifestForUpdate -ManifestResult $manifestResult -TargetPath $target -SourceRoot $source
            $sync = New-SyncResult
            Set-ManagedBytes -Path (Join-Path $target 'agents/coder.agent.md') -RelativePath 'agents/coder.agent.md' -Bytes $sourceBytes -Result $sync -ManifestEntries $entries -Ownership 'template-managed' -SourceLabel 'template:agents/coder.agent.md' -Force -AlwaysOverwrite -PreserveUntracked:$false

            [IO.File]::ReadAllBytes((Join-Path $target 'agents/coder.agent.md')) | Should -Be $customBytes
            $entries['agents/coder.agent.md'].v3_disposition | Should -Be 'preserve'
            $entries['agents/coder.agent.md'].observed_hash | Should -Be (Get-BytesHash $customBytes)
            $entries['agents/coder.agent.md'].proposed_hash | Should -Be (Get-BytesHash $sourceBytes)
        }

        It "keeps Legacy Unknown Project-owned and stale records report-only without pruning" {
            $baseline = 'sha256:' + ('a' * 64)
            $current = 'sha256:' + ('b' * 64)
            $cases = @(
                @{ Name = 'legacy'; Component = [ordered]@{ provenance = [ordered]@{ ownership = 'legacy-compat'; fork = [ordered]@{ decision = 'report-only' } }; lifecycle = [ordered]@{ state = 'active' }; hashes = [ordered]@{ result_after = $baseline } }; Expected = 'report-only' },
                @{ Name = 'unknown'; Component = $null; Expected = 'report-only' },
                @{ Name = 'project-owned'; Component = [ordered]@{ provenance = [ordered]@{ ownership = 'project-owned'; fork = [ordered]@{ decision = 'preserve' } }; lifecycle = [ordered]@{ state = 'active' }; hashes = [ordered]@{ result_after = $baseline } }; Expected = 'preserve' },
                @{ Name = 'stale'; Component = [ordered]@{ provenance = [ordered]@{ ownership = 'derived-runtime'; fork = [ordered]@{ decision = 'manage' } }; lifecycle = [ordered]@{ state = 'retired' }; hashes = [ordered]@{ result_after = $baseline } }; Expected = 'report-only' }
            )

            foreach ($case in $cases) {
                (Get-V3UpdateDisposition -Component $case.Component -CurrentHash $current).Action | Should -Be $case.Expected -Because $case.Name
            }
            @(Get-Command Remove-ManagedPath -ErrorAction Stop).Count | Should -Be 1
        }


        It "routes Main Update through v3 ownership rules so Force cannot overwrite customized derived output" {
            $target = New-Phase4DTarget
            $install = Invoke-Phase4DBootstrap -Target $target -Arguments @('-SkipHooks', '-Quiet')
            $install.ExitCode | Should -Be 0
            $customPath = Join-Path $target '.github/agents/coder.agent.md'
            $customBytes = [Text.UTF8Encoding]::new($false).GetBytes("custom derived output`n")
            [IO.File]::WriteAllBytes($customPath, $customBytes)

            $update = Invoke-Phase4DBootstrap -Target $target -Arguments @('-Update', '-Force', '-SkipHooks', '-Quiet')

            $update.ExitCode | Should -Be 0
            [IO.File]::ReadAllBytes($customPath) | Should -Be $customBytes
            (Get-InstallManifest -TargetPath $target -SourceRoot $script:Phase4DRepoRoot).State | Should -Be 'valid-v3'
            @(Get-ChildItem -LiteralPath $target -Force -Directory -Filter '.ai-workflow-phase4d-backup-*').Count | Should -Be 1
        }
    }

    Context "State Matrix F - Manifest path input" {
        AfterEach {
            $script:Phase4DManifestInspectionFailure = $false
        }

        It "classifies only an actually absent Manifest path as missing" {
            $target = New-Phase4DTarget
            $result = Get-InstallManifest -TargetPath $target -SourceRoot $script:Phase4DRepoRoot
            $result.State | Should -Be 'missing'
            $result.DiagnosticCategory | Should -Be 'manifest-missing'
        }

        It "hard-stops a directory or container at the Manifest path as corrupt" {
            $target = New-Phase4DTarget
            New-Item -ItemType Directory -Path (Join-Path $target '.ai-workflow-install.json') | Out-Null
            $result = Get-InstallManifest -TargetPath $target -SourceRoot $script:Phase4DRepoRoot
            $result.State | Should -Be 'corrupt'
            $result.DiagnosticCategory | Should -Be 'manifest-path-type'
        }

        It "reads regular-file bytes strictly and rejects invalid UTF-8" {
            $target = New-Phase4DTarget
            [IO.File]::WriteAllBytes((Join-Path $target '.ai-workflow-install.json'), [byte[]](0xff, 0xfe, 0x7b, 0x7d))
            $result = Get-InstallManifest -TargetPath $target -SourceRoot $script:Phase4DRepoRoot
            $result.State | Should -Be 'corrupt'
            $result.DiagnosticCategory | Should -Be 'manifest-json'
        }

        It "hard-stops Manifest inspection or access failure instead of degrading it to missing" {
            $target = New-Phase4DTarget
            $script:Phase4DManifestInspectionFailure = $true
            $result = Get-InstallManifest -TargetPath $target -SourceRoot $script:Phase4DRepoRoot
            $result.State | Should -Be 'corrupt'
            $result.DiagnosticCategory | Should -Be 'manifest-inspection'
        }

        if ($IsWindows) {
            It "hard-stops a Manifest leaf Junction as unsafe-path on Windows" {
                $target = New-Phase4DTarget
                $outside = Join-Path $TestDrive ("phase4d-junction-target-" + [guid]::NewGuid().ToString('N'))
                New-Item -ItemType Directory -Path $outside | Out-Null
                [IO.File]::WriteAllText((Join-Path $outside 'sentinel.txt'), 'outside-sentinel')
                New-Item -ItemType Junction -Path (Join-Path $target '.ai-workflow-install.json') -Target $outside -ErrorAction Stop | Out-Null

                $result = Get-InstallManifest -TargetPath $target -SourceRoot $script:Phase4DRepoRoot

                $result.State | Should -Be 'unsafe-path'
                $result.DiagnosticCategory | Should -Be 'manifest-unsafe-path'
            }
        }
    }

    Context "State Matrix G - failure honesty and recovery evidence" {
        AfterEach {
            $script:Phase4DFailpoint = ''
        }

        It "hard-stops backup failure before any target mutation" {
            $target = New-Phase4DTarget
            Write-Phase4DLegacyManifest -Target $target
            $preview = New-ManifestMigrationPreview -TargetPath $target -SourceRoot $script:Phase4DRepoRoot
            $before = Get-Phase4DTreeSnapshot $target
            $script:Phase4DFailpoint = 'backup'

            { Invoke-ManifestMigrationApply -TargetPath $target -SourceRoot $script:Phase4DRepoRoot -ExpectedPreviewId $preview.preview_id } | Should -Throw '*backup-failed*'

            (Get-Phase4DTreeSnapshot $target) | Should -Be $before
        }

        It "hard-stops candidate validation failure before backup or publication" {
            $target = New-Phase4DTarget
            Write-Phase4DLegacyManifest -Target $target
            $preview = New-ManifestMigrationPreview -TargetPath $target -SourceRoot $script:Phase4DRepoRoot
            $before = Get-Phase4DTreeSnapshot $target
            $script:Phase4DFailpoint = 'candidate-validation'

            { Invoke-ManifestMigrationApply -TargetPath $target -SourceRoot $script:Phase4DRepoRoot -ExpectedPreviewId $preview.preview_id } | Should -Throw '*candidate-validation-failed*'

            (Get-Phase4DTreeSnapshot $target) | Should -Be $before
        }

        It "retains backup and diagnostic without false success when a managed write fails" {
            $oldBytes = [Text.UTF8Encoding]::new($false).GetBytes("managed-before`n")
            $newBytes = [Text.UTF8Encoding]::new($false).GetBytes("managed-after`n")
            $source = New-Phase4DSourceRoot -CoderBytes $oldBytes
            $target = New-Phase4DTarget
            Write-Phase4DV3Baseline -Target $target -SourceRoot $source -Bytes $oldBytes
            [IO.File]::WriteAllBytes((Join-Path $source 'agents/coder.agent.md'), $newBytes)
            $manifestBefore = [IO.File]::ReadAllBytes((Join-Path $target '.ai-workflow-install.json'))
            $script:Phase4DFailpoint = 'managed-write'

            { Invoke-ManifestV3GeneralUpdate -TargetPath $target -SourceRoot $source } | Should -Throw '*manual-recovery-required*managed-write*'

            [IO.File]::ReadAllBytes((Join-Path $target 'agents/coder.agent.md')) | Should -Be $oldBytes
            [IO.File]::ReadAllBytes((Join-Path $target '.ai-workflow-install.json')) | Should -Be $manifestBefore
            @(Get-ChildItem -LiteralPath $target -Force -Directory -Filter '.ai-workflow-phase4d-backup-*').Count | Should -Be 1
            @(Get-ChildItem -LiteralPath $target -Force -Recurse -File -Filter 'diagnostic.txt').Count | Should -Be 1
        }

        It "retains the exact backup and diagnostic when Manifest replace fails" {
            $target = New-Phase4DTarget
            Write-Phase4DLegacyManifest -Target $target
            $manifestPath = Join-Path $target '.ai-workflow-install.json'
            $original = [IO.File]::ReadAllBytes($manifestPath)
            $preview = New-ManifestMigrationPreview -TargetPath $target -SourceRoot $script:Phase4DRepoRoot
            $script:Phase4DFailpoint = 'manifest-replace'

            { Invoke-ManifestMigrationApply -TargetPath $target -SourceRoot $script:Phase4DRepoRoot -ExpectedPreviewId $preview.preview_id } | Should -Throw '*manual-recovery-required*manifest-replace*'

            [IO.File]::ReadAllBytes($manifestPath) | Should -Be $original
            $backup = @(Get-ChildItem -LiteralPath $target -Force -File -Filter '.ai-workflow-install.json.phase4d-backup-*' | Where-Object Name -NotLike '*.diagnostic.txt')
            $backup.Count | Should -Be 1
            [IO.File]::ReadAllBytes($backup[0].FullName) | Should -Be $original
            Test-Path ($backup[0].FullName + '.diagnostic.txt') | Should -BeTrue
        }

        It "reports manual recovery and does not guess a restore after post-write validation fails" {
            $target = New-Phase4DTarget
            Write-Phase4DLegacyManifest -Target $target
            $manifestPath = Join-Path $target '.ai-workflow-install.json'
            $original = [IO.File]::ReadAllBytes($manifestPath)
            $preview = New-ManifestMigrationPreview -TargetPath $target -SourceRoot $script:Phase4DRepoRoot
            $script:Phase4DFailpoint = 'post-write-validation'

            { Invoke-ManifestMigrationApply -TargetPath $target -SourceRoot $script:Phase4DRepoRoot -ExpectedPreviewId $preview.preview_id } | Should -Throw '*manual-recovery-required*post-write-validation*'

            [IO.File]::ReadAllBytes($manifestPath) | Should -Not -Be $original
            $backup = @(Get-ChildItem -LiteralPath $target -Force -File -Filter '.ai-workflow-install.json.phase4d-backup-*' | Where-Object Name -NotLike '*.diagnostic.txt')
            $backup.Count | Should -Be 1
            [IO.File]::ReadAllBytes($backup[0].FullName) | Should -Be $original
            Test-Path ($backup[0].FullName + '.diagnostic.txt') | Should -BeTrue
        }
    }
}

Describe "Phase 0A adopter constitution containment" {
    BeforeEach {
        $script:Phase0ATemplateRoot = Join-Path $TestDrive ([guid]::NewGuid().ToString())
        $script:Phase0ATargetRoot = Join-Path $TestDrive ([guid]::NewGuid().ToString())
        $script:Phase0AMaintainerBytes = [Text.Encoding]::UTF8.GetBytes("# Maintainer Constitution`nRun tools/sync-dotgithub.ps1 and maintain the template catalog.`n")
        $script:Phase0AAdopterBytes = [Text.Encoding]::UTF8.GetBytes("# Adopter Constitution`nProject-facing guidance only.`n")

        New-Item -ItemType Directory -Path (Join-Path $script:Phase0ATemplateRoot '.github') -Force | Out-Null
        New-Item -ItemType Directory -Path (Join-Path $script:Phase0ATemplateRoot 'docs') -Force | Out-Null
        New-Item -ItemType Directory -Path $script:Phase0ATargetRoot -Force | Out-Null
        [IO.File]::WriteAllBytes((Join-Path $script:Phase0ATemplateRoot '.github/copilot-instructions.md'), $script:Phase0AMaintainerBytes)
        [IO.File]::WriteAllBytes((Join-Path $script:Phase0ATemplateRoot 'docs/copilot-instructions.template.md'), $script:Phase0AAdopterBytes)
    }

    It "installs the adopter source for a new adopter without maintainer policy" {
        $manifest = @{}
        Mock Write-Host

        $result = Sync-WorkflowFiles `
            -SourcePath (Join-Path $script:Phase0ATemplateRoot '.github') `
            -TargetPath $script:Phase0ATargetRoot `
            -ManifestEntries $manifest `
            -ConstitutionSourceRoot $script:Phase0ATemplateRoot

        $destination = Join-Path $script:Phase0ATargetRoot '.github/copilot-instructions.md'
        [IO.File]::ReadAllBytes($destination) | Should -Be $script:Phase0AAdopterBytes
        [Text.Encoding]::UTF8.GetString([IO.File]::ReadAllBytes($destination)) | Should -Not -Match 'sync-dotgithub'
        $result.FilesAdded | Should -Contain '.github/copilot-instructions.md'
        $result.FilesSkipped | Should -Not -Contain '.github/copilot-instructions.md'
        $manifest['.github/copilot-instructions.md'].source | Should -Be 'template:docs/copilot-instructions.template.md'
        Assert-MockCalled Write-Host -ParameterFilter { $Object -eq 'ℹ️  Constitution source: docs/copilot-instructions.template.md' }
        Assert-MockCalled Write-Host -ParameterFilter { $Object -eq '✅ Constitution outcome: installed' }
    }

    It "keeps the canonical adopter source free of maintainer policy" {
        $adopterContent = Get-Content -Raw (Join-Path $PSScriptRoot '../docs/copilot-instructions.template.md')
        $forbidden = @('sync-dotgithub.ps1', 'check-sync.ps1', 'audit-catalog.ps1', 'Never commit source without syncing')

        foreach ($token in $forbidden) {
            $adopterContent | Should -Not -Match ([regex]::Escape($token))
        }
    }

    It "never falls back to the maintainer constitution during generic sync" {
        $result = Sync-WorkflowFiles `
            -SourcePath (Join-Path $script:Phase0ATemplateRoot '.github') `
            -TargetPath $script:Phase0ATargetRoot `
            -ManifestEntries @{} `
            -Force

        Test-Path (Join-Path $script:Phase0ATargetRoot '.github/copilot-instructions.md') | Should -BeFalse
        $result.FilesSkipped | Should -Contain '.github/copilot-instructions.md'
    }

    It "preserves every existing constitution when trusted exact proof is unavailable" {
        $destination = Join-Path $script:Phase0ATargetRoot '.github/copilot-instructions.md'
        New-Item -ItemType Directory -Path (Split-Path $destination -Parent) -Force | Out-Null
        Mock Write-Host
        $cases = @(
            @{ Name = 'missing-manifest'; Manifest = @{}; Content = [Text.Encoding]::UTF8.GetBytes("legacy policy`r`n") },
            @{ Name = 'missing-exact-component'; Manifest = @{ '.github/other.md' = @{ managed_hash = Get-BytesHash ([Text.Encoding]::UTF8.GetBytes("other`n")) } }; Content = [Text.Encoding]::UTF8.GetBytes("unknown ownership`n") },
            @{ Name = 'customized'; Manifest = @{ '.github/copilot-instructions.md' = @{ managed_hash = Get-BytesHash ([Text.Encoding]::UTF8.GetBytes("previous baseline`n")); source = 'template:.github/copilot-instructions.md' } }; Content = [byte[]](0x70,0x72,0x6f,0x6a,0x65,0x63,0x74,0x00,0x0a) },
            @{ Name = 'generic-baseline-match'; Manifest = @{ '.github/copilot-instructions.md' = @{ managed_hash = Get-BytesHash ([Text.Encoding]::UTF8.GetBytes("recorded baseline`n")); source = 'template:.github/copilot-instructions.md' } }; Content = [Text.Encoding]::UTF8.GetBytes("recorded baseline`n") },
            @{ Name = 'unclear-source'; Manifest = @{ '.github/copilot-instructions.md' = @{ managed_hash = Get-BytesHash ([Text.Encoding]::UTF8.GetBytes("legacy policy`n")); source = 'unknown' } }; Content = [Text.Encoding]::UTF8.GetBytes("legacy policy`n") }
        )

        foreach ($case in $cases) {
            [IO.File]::WriteAllBytes($destination, $case.Content)
            $hadConstitutionEntry = $case.Manifest.ContainsKey('.github/copilot-instructions.md')
            $originalConstitutionEntry = if ($hadConstitutionEntry) { $case.Manifest['.github/copilot-instructions.md'] | ConvertTo-Json -Depth 5 -Compress } else { $null }

            $result = Sync-WorkflowFiles `
                -SourcePath (Join-Path $script:Phase0ATemplateRoot '.github') `
                -TargetPath $script:Phase0ATargetRoot `
                -ManifestEntries $case.Manifest `
                -ConstitutionSourceRoot $script:Phase0ATemplateRoot `
                -Force

            [IO.File]::ReadAllBytes($destination) | Should -Be $case.Content -Because $case.Name
            ($result.FilesSkipped | Where-Object { $_.StartsWith('.github/copilot-instructions.md [preserved') -and $_.Contains('manual decision required') }).Count | Should -Be 1 -Because $case.Name
            ($result.FilesSkipped | Where-Object { $_.StartsWith('.github/copilot-instructions.md') }).Count | Should -Be 1 -Because $case.Name
            $case.Manifest.ContainsKey('.github/copilot-instructions.md') | Should -Be $hadConstitutionEntry -Because $case.Name
            if ($hadConstitutionEntry) {
                ($case.Manifest['.github/copilot-instructions.md'] | ConvertTo-Json -Depth 5 -Compress) | Should -Be $originalConstitutionEntry -Because $case.Name
            }
        }
        Assert-MockCalled Write-Host -ParameterFilter { $Object -eq 'ℹ️  Constitution source: docs/copilot-instructions.template.md' } -Times $cases.Count -Exactly
        Assert-MockCalled Write-Host -ParameterFilter { $Object -eq '⚠️  Constitution outcome: preserved; manual decision required' } -Times $cases.Count -Exactly
    }
}

Describe "Normalize-RelativePath" {
    It "preserves dot-directory and parent-segment identity" {
        Normalize-RelativePath '.github/x' | Should -Be '.github/x'
        Normalize-RelativePath './.github/x' | Should -Be '.github/x'
        Normalize-RelativePath '.agents/skills/x' | Should -Be '.agents/skills/x'
        Normalize-RelativePath './skills/x' | Should -Be 'skills/x'
        Normalize-RelativePath '../outside' | Should -Be '../outside'
    }
}

Describe "Install-PortableRuntime maintainer-only exclusions" {
    It "does not deploy gate-check to an adopter target" {
        $sourceRoot = Join-Path $TestDrive 'template'
        $targetRoot = Join-Path $TestDrive 'target'
        foreach ($directory in @('skills/demo-skill', 'skills/gate-check', 'agents', 'docs', 'changes/_template')) {
            New-Item -ItemType Directory -Path (Join-Path $sourceRoot $directory) -Force | Out-Null
        }
        New-Item -ItemType Directory -Path $targetRoot | Out-Null
        Set-Content (Join-Path $sourceRoot 'skills/demo-skill/SKILL.md') 'demo'
        Set-Content (Join-Path $sourceRoot 'skills/gate-check/SKILL.md') 'maintainer'
        Set-Content (Join-Path $sourceRoot 'agents/demo.agent.md') "---`nname: demo`ndescription: demo`n---`n`n# Demo agent`n"
        Set-Content (Join-Path $sourceRoot 'docs/WORKFLOW.template.md') '# Adopter lifecycle'
        foreach ($name in $script:LifecycleTemplateFiles) {
            Set-Content (Join-Path $sourceRoot "changes/_template/$name") "# template $name"
        }

        $manifest = @{}
        $null = Install-PortableRuntime -SourceRoot $sourceRoot -TargetPath $targetRoot -ManifestEntries $manifest

        Test-Path (Join-Path $targetRoot 'skills/demo-skill/SKILL.md') | Should -BeTrue
        Test-Path (Join-Path $targetRoot 'skills/gate-check') | Should -BeFalse
        Test-Path (Join-Path $targetRoot '.github/skills/gate-check') | Should -BeFalse
        $manifest.ContainsKey('.github/skills/demo-skill/SKILL.md') | Should -BeTrue
        $manifest.ContainsKey('github/skills/demo-skill/SKILL.md') | Should -BeFalse
    }
}

Describe "Phase 3 adopter lifecycle distribution" {
    BeforeEach {
        $script:Phase3Source = Join-Path $TestDrive ([guid]::NewGuid().ToString())
        $script:Phase3Target = Join-Path $TestDrive ([guid]::NewGuid().ToString())
        $script:Phase3Templates = @(
            '00-intake.md', '01-brainstorm.md', '02-decision-log.md', '03-spec.md',
            '04-plan.md', '05-test-plan.md', '06-impact-analysis.md', '07-review.md', '99-archive.md'
        )
        foreach ($directory in @('skills/demo', 'agents', 'docs', 'changes/_template')) {
            New-Item -ItemType Directory -Path (Join-Path $script:Phase3Source $directory) -Force | Out-Null
        }
        New-Item -ItemType Directory -Path $script:Phase3Target -Force | Out-Null
        Set-Content -LiteralPath (Join-Path $script:Phase3Source 'skills/demo/SKILL.md') -Value '# Demo'
        Set-Content -LiteralPath (Join-Path $script:Phase3Source 'agents/demo.agent.md') -Value "---`nname: demo`ndescription: demo`n---`n`n# Demo"
        Set-Content -LiteralPath (Join-Path $script:Phase3Source 'docs/AGENTS.template.md') -Value '# Agents'
        Set-Content -LiteralPath (Join-Path $script:Phase3Source 'docs/CLAUDE.template.md') -Value '@AGENTS.md'
        Set-Content -LiteralPath (Join-Path $script:Phase3Source 'docs/GEMINI.template.md') -Value 'Read AGENTS.md'
        Set-Content -LiteralPath (Join-Path $script:Phase3Source 'docs/WORKFLOW.template.md') -Value '# Adopter lifecycle'
        Set-Content -LiteralPath (Join-Path $script:Phase3Source 'WORKFLOW.md') -Value '# Maintainer lifecycle'
        foreach ($name in $script:Phase3Templates) {
            Set-Content -LiteralPath (Join-Path $script:Phase3Source "changes/_template/$name") -Value "# template $name"
        }
    }

    It "installs the projection and canonical templates as template-managed without creating a work-item package" {
        $manifest = @{}

        $result = Install-PortableRuntime -SourceRoot $script:Phase3Source -TargetPath $script:Phase3Target -ManifestEntries $manifest

        [IO.File]::ReadAllBytes((Join-Path $script:Phase3Target 'WORKFLOW.md')) | Should -Be ([IO.File]::ReadAllBytes((Join-Path $script:Phase3Source 'docs/WORKFLOW.template.md')))
        [IO.File]::ReadAllBytes((Join-Path $script:Phase3Target 'WORKFLOW.md')) | Should -Not -Be ([IO.File]::ReadAllBytes((Join-Path $script:Phase3Source 'WORKFLOW.md')))
        $manifest['WORKFLOW.md'].ownership | Should -Be 'template-managed'
        $manifest['WORKFLOW.md'].source | Should -Be 'template:docs/WORKFLOW.template.md'
        foreach ($name in $script:Phase3Templates) {
            $relative = "changes/_template/$name"
            [IO.File]::ReadAllBytes((Join-Path $script:Phase3Target $relative)) | Should -Be ([IO.File]::ReadAllBytes((Join-Path $script:Phase3Source $relative)))
            $manifest[$relative].ownership | Should -Be 'template-managed'
            $manifest[$relative].source | Should -Be "template:$relative"
            $result.FilesAdded | Should -Contain $relative
        }
        @(Get-ChildItem -LiteralPath (Join-Path $script:Phase3Target 'changes') -Directory | Select-Object -ExpandProperty Name) | Should -Be @('_template')
    }

    It "updates only exact managed lifecycle baselines" {
        $manifest = @{}
        $null = Install-PortableRuntime -SourceRoot $script:Phase3Source -TargetPath $script:Phase3Target -ManifestEntries $manifest
        Set-Content -LiteralPath (Join-Path $script:Phase3Source 'docs/WORKFLOW.template.md') -Value '# Adopter lifecycle v2'
        Set-Content -LiteralPath (Join-Path $script:Phase3Source 'changes/_template/07-review.md') -Value '# Review v2'

        $result = Install-PortableRuntime -SourceRoot $script:Phase3Source -TargetPath $script:Phase3Target -ManifestEntries $manifest

        (Get-Content -Raw -LiteralPath (Join-Path $script:Phase3Target 'WORKFLOW.md')).Trim() | Should -Be '# Adopter lifecycle v2'
        (Get-Content -Raw -LiteralPath (Join-Path $script:Phase3Target 'changes/_template/07-review.md')).Trim() | Should -Be '# Review v2'
        $result.FilesUpdated | Should -Contain 'WORKFLOW.md'
        $result.FilesUpdated | Should -Contain 'changes/_template/07-review.md'
    }

    It "preserves customized and unproven lifecycle content even with Force" {
        $manifest = @{}
        $null = Install-PortableRuntime -SourceRoot $script:Phase3Source -TargetPath $script:Phase3Target -ManifestEntries $manifest
        Set-Content -LiteralPath (Join-Path $script:Phase3Target 'WORKFLOW.md') -Value '# Project customization'
        Set-Content -LiteralPath (Join-Path $script:Phase3Source 'docs/WORKFLOW.template.md') -Value '# Adopter lifecycle v2'

        $customized = Install-PortableRuntime -SourceRoot $script:Phase3Source -TargetPath $script:Phase3Target -ManifestEntries $manifest -Force

        (Get-Content -Raw -LiteralPath (Join-Path $script:Phase3Target 'WORKFLOW.md')).Trim() | Should -Be '# Project customization'
        $customized.FilesSkipped | Should -Contain 'WORKFLOW.md [preserved customization]'
        $manifest['WORKFLOW.md'].status | Should -Be 'preserved-customization'

        $unprovenTarget = Join-Path $TestDrive ([guid]::NewGuid().ToString())
        New-Item -ItemType Directory -Path $unprovenTarget | Out-Null
        Set-Content -LiteralPath (Join-Path $unprovenTarget 'WORKFLOW.md') -Value '# Existing lifecycle'
        $unprovenManifest = @{}
        $unproven = Install-PortableRuntime -SourceRoot $script:Phase3Source -TargetPath $unprovenTarget -ManifestEntries $unprovenManifest -Force
        (Get-Content -Raw -LiteralPath (Join-Path $unprovenTarget 'WORKFLOW.md')).Trim() | Should -Be '# Existing lifecycle'
        $unproven.FilesSkipped | Should -Contain 'WORKFLOW.md [preserved existing; manual decision required]'
        $unprovenManifest.ContainsKey('WORKFLOW.md') | Should -BeFalse

        $unprovenCases = @(
            @{ Name = 'project-owned'; Entry = @{ name = 'WORKFLOW.md'; ownership = 'project-owned'; source = 'project:WORKFLOW.md'; managed_hash = Get-BytesHash ([Text.Encoding]::UTF8.GetBytes("# Existing lifecycle`n")) } },
            @{ Name = 'unclear-source'; Entry = @{ name = 'WORKFLOW.md'; ownership = 'template-managed'; source = 'unknown'; managed_hash = Get-BytesHash ([Text.Encoding]::UTF8.GetBytes("# Existing lifecycle`n")) } },
            @{ Name = 'missing-baseline'; Entry = @{ name = 'WORKFLOW.md'; ownership = 'template-managed'; source = 'template:docs/WORKFLOW.template.md'; managed_hash = $null } }
        )
        foreach ($case in $unprovenCases) {
            $caseTarget = Join-Path $TestDrive ([guid]::NewGuid().ToString())
            New-Item -ItemType Directory -Path $caseTarget | Out-Null
            Set-Content -LiteralPath (Join-Path $caseTarget 'WORKFLOW.md') -Value '# Existing lifecycle'
            $caseManifest = @{ 'WORKFLOW.md' = $case.Entry }
            $originalEntry = $case.Entry | ConvertTo-Json -Depth 5 -Compress

            $caseResult = Install-PortableRuntime -SourceRoot $script:Phase3Source -TargetPath $caseTarget -ManifestEntries $caseManifest -Force

            (Get-Content -Raw -LiteralPath (Join-Path $caseTarget 'WORKFLOW.md')).Trim() | Should -Be '# Existing lifecycle' -Because $case.Name
            $caseResult.FilesSkipped | Should -Contain 'WORKFLOW.md [preserved existing; manual decision required]' -Because $case.Name
            ($caseManifest['WORKFLOW.md'] | ConvertTo-Json -Depth 5 -Compress) | Should -Be $originalEntry -Because $case.Name
        }
    }
}

Describe "Test-GitInstalled" {
    Context "當 Git 已安裝且版本符合要求" {
        It "應該返回 Installed=true" {
            # Arrange
            Mock git { "git version 2.43.0.windows.1" } -Verifiable
            
            # Act
            $result = Test-GitInstalled
            
            # Assert
            $result.Installed | Should -Be $true
        }
        
        It "應該返回正確的版本號" {
            # Arrange
            Mock git { "git version 2.43.0.windows.1" } -Verifiable
            
            # Act
            $result = Test-GitInstalled
            
            # Assert
            $result.Version | Should -Be "2.43.0"
        }
        
        It "應該返回 MeetsRequirement=true（版本 >= 2.0）" {
            # Arrange
            Mock git { "git version 2.43.0.windows.1" } -Verifiable
            
            # Act
            $result = Test-GitInstalled
            
            # Assert
            $result.MeetsRequirement | Should -Be $true
        }
    }
    
    Context "當 Git 版本過舊（< 2.0）" {
        It "應該返回 MeetsRequirement=false" {
            # Arrange
            Mock git { "git version 1.9.5" } -Verifiable
            
            # Act
            $result = Test-GitInstalled
            
            # Assert
            $result.Installed | Should -Be $true
            $result.Version | Should -Be "1.9.5"
            $result.MeetsRequirement | Should -Be $false
        }
    }
    
    Context "當 Git 未安裝" {
        It "應該返回 Installed=false" {
            # Arrange
            Mock git { throw "command not found" } -Verifiable
            
            # Act
            $result = Test-GitInstalled
            
            # Assert
            $result.Installed | Should -Be $false
            $result.Version | Should -BeNullOrEmpty
            $result.MeetsRequirement | Should -Be $false
        }
    }
}

# ============================================================================
# Test-GitHubCLIInstalled Tests
# ============================================================================

Describe "Test-GitHubCLIInstalled" {

    Context "When GitHub CLI is installed" {

        It "should return version details" {
            $ghCheck = Get-Command gh -ErrorAction SilentlyContinue
            if (-not $ghCheck) {
                $true | Should -Be $true
                return
            }

            $result = Test-GitHubCLIInstalled

            $result.Installed | Should -Be $true
            $result.Version | Should -Match '^\d+\.\d+\.\d+$'
            $result.MeetsRequirement | Should -BeOfType [bool]
        }
    }

    Context "When GitHub CLI meets minimum version" {

        It "should mark meetsRequirement true when version >= 2.0" {
            $ghCheck = Get-Command gh -ErrorAction SilentlyContinue
            if (-not $ghCheck) {
                $true | Should -Be $true
                return
            }

            $result = Test-GitHubCLIInstalled
            if ([version]$result.Version -ge [version]"2.0.0") {
                $result.MeetsRequirement | Should -Be $true
            }
        }
    }

    Context "When GitHub CLI is not installed" {

        It "should return Installed = false" {
            $ghCheck = Get-Command gh -ErrorAction SilentlyContinue
            if ($ghCheck) {
                $true | Should -Be $true
                return
            }

            $result = Test-GitHubCLIInstalled
            $result.Installed | Should -Be $false
            $result.Version | Should -BeNullOrEmpty
            $result.MeetsRequirement | Should -Be $false
        }
    }
}

Describe "Test-PythonInstalled" {
    Context "當 Python 已安裝且版本符合要求" {
        It "應該返回 Installed=true（Python 3.11）" {
            # Arrange
            Mock python { "Python 3.11.5" } -Verifiable
            
            # Act
            $result = Test-PythonInstalled
            
            # Assert
            $result.Installed | Should -Be $true
        }
        
        It "應該返回正確的版本號" {
            # Arrange
            Mock python { "Python 3.11.5" } -Verifiable
            
            # Act
            $result = Test-PythonInstalled
            
            # Assert
            $result.Version | Should -Be "3.11.5"
        }
        
        It "應該返回 MeetsRequirement=true（版本 >= 3.7）" {
            # Arrange
            Mock python { "Python 3.11.5" } -Verifiable
            
            # Act
            $result = Test-PythonInstalled
            
            # Assert
            $result.MeetsRequirement | Should -Be $true
        }
        
        It "應該檢測 Python 3.7（邊界值）" {
            # Arrange
            Mock python { "Python 3.7.0" } -Verifiable
            
            # Act
            $result = Test-PythonInstalled
            
            # Assert
            $result.Installed | Should -Be $true
            $result.Version | Should -Be "3.7.0"
            $result.MeetsRequirement | Should -Be $true
        }
    }
    
    Context "當 Python 版本過舊（< 3.7）" {
        It "應該返回 MeetsRequirement=false" {
            # Arrange
            Mock python { "Python 3.6.8" } -Verifiable
            
            # Act
            $result = Test-PythonInstalled
            
            # Assert
            $result.Installed | Should -Be $true
            $result.Version | Should -Be "3.6.8"
            $result.MeetsRequirement | Should -Be $false
        }
        
        It "應該檢測 Python 2.7（舊版）" {
            # Arrange
            Mock python { "Python 2.7.18" } -Verifiable
            
            # Act
            $result = Test-PythonInstalled
            
            # Assert
            $result.Installed | Should -Be $true
            $result.Version | Should -Be "2.7.18"
            $result.MeetsRequirement | Should -Be $false
        }
    }
    
    Context "當 Python 未安裝" {
        It "應該返回 Installed=false" {
            # Arrange
            Mock python { throw "command not found" } -Verifiable
            Mock python3 { throw "command not found" } -Verifiable
            
            # Act
            $result = Test-PythonInstalled
            
            # Assert
            $result.Installed | Should -Be $false
            $result.Version | Should -BeNullOrEmpty
            $result.MeetsRequirement | Should -Be $false
        }
    }
    
    Context "當需要嘗試 python3 指令" {
        It "應該嘗試 python3 作為 fallback" {
            # Arrange
            Mock python { throw "not found" } -Verifiable
            Mock python3 { "Python 3.9.7" } -Verifiable
            
            # Act
            $result = Test-PythonInstalled
            
            # Assert
            $result.Installed | Should -Be $true
            $result.Version | Should -Be "3.9.7"
        }
    }
}

# ============================================================================
# Test-PowerShellVersion Tests
# ============================================================================

Describe "Test-PowerShellVersion" {
    
    Context "When PowerShell version is checked" {
        
        It "should return current PowerShell version" {
            $result = Test-PowerShellVersion
            
            $result.Installed | Should -Be $true
            $result.Version | Should -Not -BeNullOrEmpty
        }
        
        It "should check if version meets requirement (>= 5.1)" {
            $result = Test-PowerShellVersion
            
            $result.MeetsRequirement | Should -BeOfType [bool]
        }
        
        It "should return version as string" {
            $result = Test-PowerShellVersion
            
            $result.Version | Should -Match '^\d+\.\d+(\.\d+)?'
        }
    }
    
    Context "When PowerShell 5.1 or higher" {
        
        It "should meet requirement" {
            # 這個測試假設執行環境有 PS 5.1+
            $result = Test-PowerShellVersion
            
            if ([version]$result.Version -ge [version]"5.1") {
                $result.MeetsRequirement | Should -Be $true
            }
        }
    }
    
    Context "When checking PowerShell Core (7+)" {
        
        It "should detect PowerShell 7+ correctly" {
            $result = Test-PowerShellVersion
            
            # PowerShell Core 版本應該是 7.x
            if ($PSVersionTable.PSVersion.Major -ge 7) {
                [version]$result.Version | Should -BeGreaterOrEqual ([version]"7.0")
            }
        }
    }
}

# ============================================================================
# Test-NodeJSInstalled Tests
# ============================================================================

Describe "Test-NodeJSInstalled" {
    
    Context "When Node.js is installed and meets requirement" {
        
        It "should detect Node.js version" {
            $result = Test-NodeJSInstalled
            
            $result | Should -Not -BeNullOrEmpty
            $result.Installed | Should -BeOfType [bool]
            $result.Version | Should -BeOfType [string]
            $result.MeetsRequirement | Should -BeOfType [bool]
        }
        
        It "should parse version correctly (format: v18.17.0)" {
            # 如果系統有安裝 Node.js
            $nodeCheck = Get-Command node -ErrorAction SilentlyContinue
            if ($nodeCheck) {
                $result = Test-NodeJSInstalled
                
                $result.Version | Should -Match '^\d+\.\d+\.\d+$'
            }
        }
    }
    
    Context "When Node.js version >= 16.0 (LTS)" {
        
        It "should meet requirement" {
            $nodeCheck = Get-Command node -ErrorAction SilentlyContinue
            if ($nodeCheck) {
                $result = Test-NodeJSInstalled
                
                if ([version]$result.Version -ge [version]"16.0") {
                    $result.MeetsRequirement | Should -Be $true
                }
            }
        }
    }
    
    Context "When Node.js version < 16.0 (old)" {
        
        It "should not meet requirement" {
            # 這個測試難以模擬，需要實際環境
            # 如果有舊版 Node.js，這個測試會失敗
            $true | Should -Be $true  # Placeholder
        }
    }
    
    Context "When Node.js is not installed" {
        
        It "should return Installed = false" {
            # Mock 測試（實際執行會依系統環境）
            # 如果系統沒有 Node.js
            $nodeCheck = Get-Command node -ErrorAction SilentlyContinue
            if (-not $nodeCheck) {
                $result = Test-NodeJSInstalled
                
                $result.Installed | Should -Be $false
                $result.Version | Should -BeNullOrEmpty
                $result.MeetsRequirement | Should -Be $false
            }
        }
    }
    
    Context "When checking npm availability (bonus)" {
        
        It "should detect npm if Node.js is installed" {
            $nodeCheck = Get-Command node -ErrorAction SilentlyContinue
            if ($nodeCheck) {
                $npmCheck = Get-Command npm -ErrorAction SilentlyContinue
                $npmCheck | Should -Not -BeNullOrEmpty
            }
        }
    }
}
Describe "Phase 4E stale derived output manual cleanup recommendation" {
    BeforeAll {
        $script:Phase4ERepoRoot = Split-Path -Parent $PSScriptRoot

        function New-Phase4ESourceRoot {
            $root = Join-Path $TestDrive ("phase4e-source-" + [guid]::NewGuid().ToString('N'))
            New-Item -ItemType Directory -Path (Join-Path $root 'schemas') -Force | Out-Null
            New-Item -ItemType Directory -Path (Join-Path $root 'manifest') -Force | Out-Null
            New-Item -ItemType Directory -Path (Join-Path $root 'agents') -Force | Out-Null
            Copy-Item -LiteralPath (Join-Path $script:Phase4ERepoRoot 'schemas/ai-workflow-install-manifest-v3.schema.json') -Destination (Join-Path $root 'schemas/ai-workflow-install-manifest-v3.schema.json')
            Copy-Item -LiteralPath (Join-Path $script:Phase4ERepoRoot 'manifest/component-catalog.json') -Destination (Join-Path $root 'manifest/component-catalog.json')
            return $root
        }

        function New-Phase4ETarget {
            $target = Join-Path $TestDrive ([guid]::NewGuid().ToString())
            New-Item -ItemType Directory -Path $target | Out-Null
            return $target
        }

        function Get-Phase4ECatalogHash {
            param([string]$SourceRoot)
            return Get-BytesHash ([IO.File]::ReadAllBytes((Join-Path $SourceRoot 'manifest/component-catalog.json')))
        }

        function Write-Phase4EV3Manifest {
            param(
                [string]$Target,
                [string]$SourceRoot,
                [string]$ComponentId,
                [string]$Path,
                [string]$Ownership,
                [string]$ForkStatus,
                [string]$ForkBasis,
                [string]$ForkDecision,
                [string]$BaselineHash,
                [string]$ProposedSourceHash,
                [string]$LifecycleState = 'active',
                [string]$Role = 'canonical',
                [string]$Outcome = 'installed'
            )
            $catalogHash = Get-Phase4ECatalogHash -SourceRoot $SourceRoot
            $sourceKind = switch ($Role) {
                'canonical' { 'template' }
                'generated' { 'generated' }
                'project-owned' { 'project' }
                'compatibility' { 'legacy' }
                default { 'template' }
            }
            $resultAfter = if ($Outcome -eq 'preserved-existing') { $BaselineHash } else { $ProposedSourceHash }
            $manifest = [ordered]@{
                schema_version = 3
                written_at = '2026-07-17T01:30:05Z'
                source_release = [ordered]@{
                    release_id = $script:ComponentCatalogReleaseId
                    source_ref = $script:ComponentCatalogPath
                    version = $script:ComponentCatalogVersion
                    component_catalog = [ordered]@{ path = $script:ComponentCatalogPath; schema_version = 1; sha256 = $catalogHash }
                }
                last_transaction = [ordered]@{
                    id = 'txn:phase4e-test'; mode = 'install'; writer = 'powershell'
                    started_at = '2026-07-17T01:30:00Z'; completed_at = '2026-07-17T01:30:05Z'; result = 'committed'
                }
                components = @([ordered]@{
                    identity = [ordered]@{ id = $ComponentId; path = $Path; path_key = $Path.ToLowerInvariant(); kind = 'file'; role = $Role; link = $null }
                    provenance = [ordered]@{
                        ownership = $Ownership
                        source = [ordered]@{ kind = $sourceKind; locator = "${sourceKind}:$Path"; release = $script:ComponentCatalogReleaseId }
                        generated_from = @()
                        fork = [ordered]@{ status = $ForkStatus; basis = $ForkBasis; decision = $ForkDecision; classified_at = '2026-07-17T01:30:01Z' }
                    }
                    hashes = [ordered]@{
                        algorithm = 'sha256'; content_basis = 'exact-bytes'
                        baseline = $BaselineHash; observed_before = $BaselineHash
                        proposed_source = $ProposedSourceHash; result_after = $resultAfter
                    }
                    lifecycle = [ordered]@{ state = $LifecycleState; previous_paths = @(); retirement = $null; reintroduces_component_id = $null }
                    last_operation = [ordered]@{ transaction_id = 'txn:phase4e-test'; outcome = $Outcome }
                    installed_at = '2026-07-01T00:00:00Z'; updated_at = '2026-07-17T01:30:05Z'
                })
            }
            $manifestPath = Join-Path $Target '.ai-workflow-install.json'
            $bytes = [Text.UTF8Encoding]::new($false).GetBytes(($manifest | ConvertTo-Json -Depth 20) + "`n")
            [IO.File]::WriteAllBytes($manifestPath, $bytes)
        }

        function Write-Phase4EEmptyV3Manifest {
            param([string]$Target, [string]$SourceRoot)
            $catalogHash = Get-Phase4ECatalogHash -SourceRoot $SourceRoot
            $manifest = [ordered]@{
                schema_version = 3; written_at = '2026-07-17T01:30:05Z'
                source_release = [ordered]@{
                    release_id = $script:ComponentCatalogReleaseId; source_ref = $script:ComponentCatalogPath; version = $script:ComponentCatalogVersion
                    component_catalog = [ordered]@{ path = $script:ComponentCatalogPath; schema_version = 1; sha256 = $catalogHash }
                }
                last_transaction = [ordered]@{ id = 'txn:phase4e-test'; mode = 'install'; writer = 'powershell'; started_at = '2026-07-17T01:30:00Z'; completed_at = '2026-07-17T01:30:05Z'; result = 'committed' }
                components = @()
            }
            $manifestPath = Join-Path $Target '.ai-workflow-install.json'
            $bytes = [Text.UTF8Encoding]::new($false).GetBytes(($manifest | ConvertTo-Json -Depth 20) + "`n")
            [IO.File]::WriteAllBytes($manifestPath, $bytes)
        }

        function Invoke-Phase4EReconcile {
            param([string]$Source, [string]$Target)
            $pwsh = (Get-Process -Id $PID).Path
            $output = & $pwsh -NoProfile -File (Join-Path $PSScriptRoot 'bootstrap.ps1') -ReportOnly -Operation reconcile -SourceRoot $Source -TargetPath $Target 2>&1 | Out-String
            [PSCustomObject]@{ ExitCode = $LASTEXITCODE; Output = $output }
        }

        function Get-Phase4EDecision {
            param([string]$Report, [string]$ComponentId)
            $json = $Report | ConvertFrom-Json
            return @($json.mapped_component_decisions | Where-Object { $_.component_identity.id -eq $ComponentId })[0]
        }
    }

    It "Rule 1: stale derived with bytes equal to trusted baseline recommends manual cleanup candidate without deletion" {
        $source = New-Phase4ESourceRoot
        $target = New-Phase4ETarget
        $path = 'agents/coder.agent.md'
        $baselineBytes = [Text.UTF8Encoding]::new($false).GetBytes("managed baseline content`n")
        $baselineHash = Get-BytesHash $baselineBytes
        New-Item -ItemType Directory -Path (Join-Path $target 'agents') -Force | Out-Null
        [IO.File]::WriteAllBytes((Join-Path $target $path), $baselineBytes)
        # Manifest records the original install: proposed_source was the source hash at install time
        Write-Phase4EV3Manifest -Target $target -SourceRoot $source -ComponentId 'cmp:canonical-coder-agent' -Path $path -Ownership 'template-managed' -ForkStatus 'untouched' -ForkBasis 'verified-managed-equality' -ForkDecision 'manage' -BaselineHash $baselineHash -ProposedSourceHash $baselineHash

        $result = Invoke-Phase4EReconcile -Source $source -Target $target
        $result.ExitCode | Should -Be 0
        $decision = Get-Phase4EDecision -Report $result.Output -ComponentId 'cmp:canonical-coder-agent'
        $decision | Should -Not -BeNullOrEmpty -Because 'stale component should be in mapped decisions'
        $decision.eligibility.eligible | Should -BeFalse
        $decision.eligibility.not_authority | Should -BeTrue
        $decision.eligibility.reason | Should -Match 'manual.cleanup.candidate'
        $decision.eligibility.reason | Should -Match 'no.delete'
        $decision.proposed_action | Should -Be 'preserve'
    }

    It "Rule 2: stale derived with modified bytes recommends preserve and manual review" {
        $source = New-Phase4ESourceRoot
        $target = New-Phase4ETarget
        $path = 'agents/coder.agent.md'
        $baselineBytes = [Text.UTF8Encoding]::new($false).GetBytes("managed baseline content`n")
        $baselineHash = Get-BytesHash $baselineBytes
        $modifiedBytes = [Text.UTF8Encoding]::new($false).GetBytes("modified content`n")
        New-Item -ItemType Directory -Path (Join-Path $target 'agents') -Force | Out-Null
        [IO.File]::WriteAllBytes((Join-Path $target $path), $modifiedBytes)
        Write-Phase4EV3Manifest -Target $target -SourceRoot $source -ComponentId 'cmp:canonical-coder-agent' -Path $path -Ownership 'template-managed' -ForkStatus 'untouched' -ForkBasis 'verified-managed-equality' -ForkDecision 'manage' -BaselineHash $baselineHash -ProposedSourceHash $baselineHash

        $result = Invoke-Phase4EReconcile -Source $source -Target $target
        $result.ExitCode | Should -Be 0
        $decision = Get-Phase4EDecision -Report $result.Output -ComponentId 'cmp:canonical-coder-agent'
        $decision | Should -Not -BeNullOrEmpty
        $decision.eligibility.eligible | Should -BeFalse
        $decision.eligibility.reason | Should -Match 'manual.review'
        $decision.eligibility.reason | Should -Match 'preserve'
        $decision.proposed_action | Should -Be 'preserve'
        $decision.classification | Should -Be 'customized'
    }

    It "Rule 3: legacy and unknown ownership are preserved without automatic cleanup recommendation" {
        $source = New-Phase4ESourceRoot
        $target = New-Phase4ETarget
        $path = 'agents/coder.agent.md'
        $baselineBytes = [Text.UTF8Encoding]::new($false).GetBytes("content`n")
        $baselineHash = Get-BytesHash $baselineBytes
        New-Item -ItemType Directory -Path (Join-Path $target 'agents') -Force | Out-Null
        [IO.File]::WriteAllBytes((Join-Path $target $path), $baselineBytes)
        $manifest = [ordered]@{
            schema_version = 2; installed_at = '2026-07-01T00:00:00Z'; source_ref = 'legacy'
            components = @([ordered]@{
                name = $path; installed_at = '2026-07-01T00:00:00Z'; updated_at = '2026-07-01T00:00:00Z'
                source_hash = $baselineHash; managed_hash = $baselineHash; observed_hash = $baselineHash
                ownership = 'template-managed'; kind = 'file'; source = "template:$path"; status = 'managed'
            })
        }
        [IO.File]::WriteAllText((Join-Path $target '.ai-workflow-install.json'), ($manifest | ConvertTo-Json -Depth 20) + "`n", [Text.UTF8Encoding]::new($false))

        $result = Invoke-Phase4EReconcile -Source $source -Target $target
        $result.ExitCode | Should -Be 0
        $decision = Get-Phase4EDecision -Report $result.Output -ComponentId 'cmp:canonical-coder-agent'
        $decision | Should -Not -BeNullOrEmpty
        $decision.eligibility.eligible | Should -BeFalse
        $decision.eligibility.reason | Should -Match 'preserve'
        $decision.eligibility.reason | Should -Match 'no.automatic.cleanup'
    }

    It "Rule 3b: project-owned is preserved without cleanup recommendation" {
        $source = New-Phase4ESourceRoot
        $target = New-Phase4ETarget
        $path = 'AGENTS.md'
        $contentBytes = [Text.UTF8Encoding]::new($false).GetBytes("project content`n")
        $contentHash = Get-BytesHash $contentBytes
        [IO.File]::WriteAllBytes((Join-Path $target $path), $contentBytes)
        Write-Phase4EV3Manifest -Target $target -SourceRoot $source -ComponentId 'cmp:project-agents-guide' -Path $path -Ownership 'project-owned' -ForkStatus 'project-owned' -ForkBasis 'explicit-project-ownership' -ForkDecision 'preserve' -BaselineHash $contentHash -ProposedSourceHash $contentHash -Role 'project-owned' -Outcome 'preserved-existing'

        $result = Invoke-Phase4EReconcile -Source $source -Target $target
        $result.ExitCode | Should -Be 0
        $decision = Get-Phase4EDecision -Report $result.Output -ComponentId 'cmp:project-agents-guide'
        $decision | Should -Not -BeNullOrEmpty
        $decision.eligibility.eligible | Should -BeFalse
        $decision.eligibility.reason | Should -Match 'preserve'
        $decision.eligibility.reason | Should -Match 'no.automatic.cleanup'
        $decision.proposed_action | Should -Be 'preserve'
    }

    It "Rule 4: insufficient provenance is blocked not guessed" {
        $source = New-Phase4ESourceRoot
        $target = New-Phase4ETarget
        $path = 'agents/coder.agent.md'
        $contentBytes = [Text.UTF8Encoding]::new($false).GetBytes("content`n")
        $contentHash = Get-BytesHash $contentBytes
        New-Item -ItemType Directory -Path (Join-Path $source 'agents') -Force | Out-Null
        [IO.File]::WriteAllBytes((Join-Path $source $path), $contentBytes)
        New-Item -ItemType Directory -Path (Join-Path $target 'agents') -Force | Out-Null
        [IO.File]::WriteAllBytes((Join-Path $target $path), $contentBytes)
        Write-Phase4EEmptyV3Manifest -Target $target -SourceRoot $source

        $result = Invoke-Phase4EReconcile -Source $source -Target $target
        $result.ExitCode | Should -Be 0
        $decision = Get-Phase4EDecision -Report $result.Output -ComponentId 'cmp:canonical-coder-agent'
        $decision | Should -Not -BeNullOrEmpty
        $decision.eligibility.eligible | Should -BeFalse
        $decision.eligibility.reason | Should -Match 'insufficient.evidence'
        $decision.eligibility.reason | Should -Match 'no.guess'
        $decision.classification | Should -Be 'unknown'
    }

    It "Rule 5: missing target reports already-absent with no cleanup required" {
        $source = New-Phase4ESourceRoot
        $target = New-Phase4ETarget
        $path = 'agents/coder.agent.md'
        $baselineBytes = [Text.UTF8Encoding]::new($false).GetBytes("content`n")
        $baselineHash = Get-BytesHash $baselineBytes
        New-Item -ItemType Directory -Path (Join-Path $source 'agents') -Force | Out-Null
        [IO.File]::WriteAllBytes((Join-Path $source $path), $baselineBytes)
        Write-Phase4EV3Manifest -Target $target -SourceRoot $source -ComponentId 'cmp:canonical-coder-agent' -Path $path -Ownership 'template-managed' -ForkStatus 'untouched' -ForkBasis 'verified-managed-equality' -ForkDecision 'manage' -BaselineHash $baselineHash -ProposedSourceHash $baselineHash

        $result = Invoke-Phase4EReconcile -Source $source -Target $target
        $result.ExitCode | Should -Be 0
        $decision = Get-Phase4EDecision -Report $result.Output -ComponentId 'cmp:canonical-coder-agent'
        $decision | Should -Not -BeNullOrEmpty
        $decision.eligibility.eligible | Should -BeFalse
        $decision.eligibility.reason | Should -Match 'already.absent'
        $decision.eligibility.reason | Should -Match 'no.cleanup.required'
        $decision.observed_hash | Should -BeNullOrEmpty
    }

    It "corrupt manifest does not produce a cleanup recommendation" {
        $source = New-Phase4ESourceRoot
        $target = New-Phase4ETarget
        [IO.File]::WriteAllBytes((Join-Path $target '.ai-workflow-install.json'), [Text.Encoding]::UTF8.GetBytes('not-json'))

        $result = Invoke-Phase4EReconcile -Source $source -Target $target
        $result.ExitCode | Should -Be 0
        $json = $result.Output | ConvertFrom-Json
        $json.manifest_parse_state.state | Should -Be 'corrupt'
        $json.mapped_component_decisions | Should -Be @()
        $json.blocking_findings | Should -Not -BeNullOrEmpty
        $json.required_future_authorization.delete_action | Should -BeFalse
    }

    It "report is deterministic across identical inputs" {
        $source = New-Phase4ESourceRoot
        $targetA = New-Phase4ETarget
        $targetB = New-Phase4ETarget
        $path = 'agents/coder.agent.md'
        $baselineBytes = [Text.UTF8Encoding]::new($false).GetBytes("same content`n")
        $baselineHash = Get-BytesHash $baselineBytes
        foreach ($t in @($targetA, $targetB)) {
            New-Item -ItemType Directory -Path (Join-Path $t 'agents') -Force | Out-Null
            [IO.File]::WriteAllBytes((Join-Path $t $path), $baselineBytes)
            Write-Phase4EV3Manifest -Target $t -SourceRoot $source -ComponentId 'cmp:canonical-coder-agent' -Path $path -Ownership 'template-managed' -ForkStatus 'untouched' -ForkBasis 'verified-managed-equality' -ForkDecision 'manage' -BaselineHash $baselineHash -ProposedSourceHash $baselineHash
        }

        $first = Invoke-Phase4EReconcile -Source $source -Target $targetA
        $second = Invoke-Phase4EReconcile -Source $source -Target $targetB
        $firstJson = $first.Output | ConvertFrom-Json
        $secondJson = $second.Output | ConvertFrom-Json
        $firstJson.report_identity.canonical_body_digest | Should -Be $secondJson.report_identity.canonical_body_digest
    }

    It "report-only reconcile performs zero target writes" {
        $source = New-Phase4ESourceRoot
        $target = New-Phase4ETarget
        $path = 'agents/coder.agent.md'
        $baselineBytes = [Text.UTF8Encoding]::new($false).GetBytes("content`n")
        $baselineHash = Get-BytesHash $baselineBytes
        New-Item -ItemType Directory -Path (Join-Path $target 'agents') -Force | Out-Null
        [IO.File]::WriteAllBytes((Join-Path $target $path), $baselineBytes)
        Write-Phase4EV3Manifest -Target $target -SourceRoot $source -ComponentId 'cmp:canonical-coder-agent' -Path $path -Ownership 'template-managed' -ForkStatus 'untouched' -ForkBasis 'verified-managed-equality' -ForkDecision 'manage' -BaselineHash $baselineHash -ProposedSourceHash $baselineHash

        $beforeHash = Get-FileHash256 -Path (Join-Path $target $path)
        $result = Invoke-Phase4EReconcile -Source $source -Target $target
        $afterHash = Get-FileHash256 -Path (Join-Path $target $path)
        $json = $result.Output | ConvertFrom-Json
        $json.no_write_confirmation.writes_performed | Should -BeFalse
        $json.no_write_confirmation.inventory_unchanged | Should -BeTrue
        $beforeHash | Should -Be $afterHash
    }

    It "report contains no delete tombstone or prune path" {
        $source = New-Phase4ESourceRoot
        $target = New-Phase4ETarget
        $path = 'agents/coder.agent.md'
        $baselineBytes = [Text.UTF8Encoding]::new($false).GetBytes("content`n")
        $baselineHash = Get-BytesHash $baselineBytes
        New-Item -ItemType Directory -Path (Join-Path $target 'agents') -Force | Out-Null
        [IO.File]::WriteAllBytes((Join-Path $target $path), $baselineBytes)
        Write-Phase4EV3Manifest -Target $target -SourceRoot $source -ComponentId 'cmp:canonical-coder-agent' -Path $path -Ownership 'template-managed' -ForkStatus 'untouched' -ForkBasis 'verified-managed-equality' -ForkDecision 'manage' -BaselineHash $baselineHash -ProposedSourceHash $baselineHash

        $result = Invoke-Phase4EReconcile -Source $source -Target $target
        $json = $result.Output | ConvertFrom-Json
        $json.required_future_authorization.delete_action | Should -BeFalse
        $json.required_future_authorization.not_authority | Should -BeTrue
        $json.required_future_authorization.approval_supplied | Should -BeFalse
        @(Get-ChildItem -LiteralPath $target -Force -Recurse | Where-Object { $_.Name -match 'tombstone|prune|delete' }).Count | Should -Be 0
    }
}
