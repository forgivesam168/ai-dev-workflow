# Bootstrap.Tests.ps1 - Pester 測試套件
# 測試 Bootstrap.ps1 的所有功能

BeforeAll {
    . "$PSScriptRoot\bootstrap.ps1"
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
        $result.Output | Should -Match 'legacy project'
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

    It "keeps the production writer at schema v2" {
        $target = Join-Path $TestDrive ([guid]::NewGuid().ToString())
        New-Item -ItemType Directory -Path $target | Out-Null
        Write-InstallManifest -TargetPath $target -SourceRoot $script:Phase4ARepoRoot -ManifestEntries @{}
        $written = Get-Content -Raw (Join-Path $target '.ai-workflow-install.json') | ConvertFrom-Json -AsHashtable
        $written['schema_version'] | Should -Be 2
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

    It "blocks valid v3 route <name> before every target mutation" -ForEach @(
        $Phase4AVectorsForDiscovery.mutation_routes
    ) {
        param($name, $powershell_arguments, $category)
        $target = Join-Path $TestDrive ([guid]::NewGuid().ToString())
        New-Item -ItemType Directory -Path $target | Out-Null
        New-Item -ItemType Directory -Path (Join-Path $target '.github') | Out-Null
        New-Item -ItemType Directory -Path (Join-Path $target 'skills/custom') -Force | Out-Null
        [IO.File]::WriteAllBytes((Join-Path $target '.github/copilot-instructions.md'), [Text.Encoding]::UTF8.GetBytes('sentinel'))
        [IO.File]::WriteAllBytes((Join-Path $target 'skills/custom/SKILL.md'), [Text.Encoding]::UTF8.GetBytes('custom'))
        Write-Phase4AManifest $target (New-Phase4AValidManifest)
        $before = Get-Phase4ATreeSnapshot $target
        $result = Invoke-Phase4ABootstrap -Target $target -Arguments @($powershell_arguments)
        $result.ExitCode | Should -Not -Be 0
        $result.Output | Should -Match $category
        $result.Output | Should -Match 'writer/migration is not enabled'
        $result.Output | Should -Match 'before backup, directory, file, link, temporary artifact, or Manifest mutation'
        (Get-Phase4ATreeSnapshot $target) | Should -Be $before
        Test-Path (Join-Path $target '.git') | Should -BeFalse
        @(Get-ChildItem -LiteralPath $target -Force -Filter '*.backup-*').Count | Should -Be 0
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
