BeforeAll {
    $script:RepoRoot = Split-Path -Parent $PSScriptRoot
    $script:EntryPoint = Join-Path $PSScriptRoot 'manifest-migration-rehearsal.ps1'
    $script:SchemaPath = Join-Path $script:RepoRoot 'schemas/ai-workflow-install-manifest-v3.schema.json'
    $script:CatalogPath = Join-Path $script:RepoRoot 'manifest/component-catalog.json'
    $script:ManifestName = '.ai-workflow-install.json'
    $script:BackupName = '.ai-workflow-install.json.phase4c-backup'

function Get-Sha256 {
    param([byte[]]$Bytes)
    return 'sha256:' + [Convert]::ToHexString([Security.Cryptography.SHA256]::HashData($Bytes)).ToLowerInvariant()
}

function New-LegacyFixture {
    param(
        [string]$Root,
        [int]$Version = 2
    )

    $fixture = Join-Path $Root ([Guid]::NewGuid().ToString('N'))
    $componentPath = Join-Path $fixture 'agents/architect.agent.md'
    [IO.Directory]::CreateDirectory((Split-Path -Parent $componentPath)) | Out-Null
    $componentBytes = [Text.UTF8Encoding]::new($false).GetBytes("architect fixture`n")
    [IO.File]::WriteAllBytes($componentPath, $componentBytes)
    $digest = Get-Sha256 $componentBytes
    $manifest = [ordered]@{
        schema_version = $Version
        installed_at = '2026-01-01T00:00:00Z'
        source_ref = 'fixture-ref'
        components = @(
            [ordered]@{
                name = 'agents/architect.agent.md'
                installed_at = '2026-01-01T00:00:00Z'
                updated_at = '2026-01-01T00:00:00Z'
                source_hash = $digest
                managed_hash = $digest
                observed_hash = $digest
                ownership = 'template-managed'
                kind = 'file'
                source = 'template:agents/architect.agent.md'
                status = 'synced'
            }
        )
    }
    $json = $manifest | ConvertTo-Json -Depth 10 -Compress
    [IO.File]::WriteAllBytes(
        (Join-Path $fixture $script:ManifestName),
        [Text.UTF8Encoding]::new($false).GetBytes($json + "`n")
    )
    return $fixture
}

function Get-FixtureDigest {
    param([string]$Root)
    $records = foreach ($file in Get-ChildItem -LiteralPath $Root -File -Recurse | Sort-Object FullName) {
        $relative = [IO.Path]::GetRelativePath($Root, $file.FullName).Replace('\', '/')
        "$relative=$(Get-Sha256 ([IO.File]::ReadAllBytes($file.FullName)))"
    }
    return Get-Sha256 ([Text.Encoding]::UTF8.GetBytes(($records -join "`n")))
}

function Get-FullInventory {
    param([string]$Root)
    $records = foreach ($item in Get-ChildItem -LiteralPath $Root -Force -Recurse | Sort-Object FullName) {
        $relative = [IO.Path]::GetRelativePath($Root, $item.FullName).Replace('\', '/')
        if ($item.PSIsContainer) {
            "directory|$relative"
        } else {
            "file|$relative|$($item.Length)|$(Get-Sha256 ([IO.File]::ReadAllBytes($item.FullName)))"
        }
    }
    return @($records)
}

function Invoke-RehearsalProcess {
    param(
        [string]$SourceFixture,
        [string]$WorkspaceParent,
        [string]$TestFailpoint
    )

    $arguments = @(
        '-NoProfile',
        '-File', $script:EntryPoint,
        '-SourceFixture', $SourceFixture,
        '-WorkspaceParent', $WorkspaceParent
    )
    if ($TestFailpoint) {
        $arguments += @('-TestFailpoint', $TestFailpoint)
    }
    $output = & (Get-Process -Id $PID).Path @arguments 2>&1
    return [pscustomobject]@{
        ExitCode = $LASTEXITCODE
        Text = [string]::Join("`n", @($output))
    }
}
}

Describe 'Phase 4C Windows-first manifest migration rehearsal' {
    BeforeEach {
        $script:WorkspaceParent = Join-Path $TestDrive ([Guid]::NewGuid().ToString('N'))
        [IO.Directory]::CreateDirectory($script:WorkspaceParent) | Out-Null
        $env:AI_WORKFLOW_PHASE4C_TEST_MODE = $null
    }

    AfterEach {
        $env:AI_WORKFLOW_PHASE4C_TEST_MODE = $null
    }

    It '[Path-Type] runs regular valid v1 and v2 manifests through the normal rehearsal without changing source bytes' -ForEach @(1, 2) {
        $fixture = New-LegacyFixture -Root $TestDrive -Version $_
        $before = Get-FixtureDigest $fixture

        $firstProcess = Invoke-RehearsalProcess $fixture $script:WorkspaceParent
        $secondProcess = Invoke-RehearsalProcess $fixture $script:WorkspaceParent
        $first = $firstProcess.Text | ConvertFrom-Json -AsHashtable
        $second = $secondProcess.Text | ConvertFrom-Json -AsHashtable

        $firstProcess.ExitCode | Should -Be 0
        $secondProcess.ExitCode | Should -Be 0
        $first.status | Should -Be 'committed'
        $first.input_version | Should -Be $_
        $first.rehearsal_only | Should -BeTrue
        $first.no_real_adopter_operation | Should -BeTrue
        $first.not_execution_authorization | Should -BeTrue
        $first.workspace | Should -Not -Be $second.workspace
        (Split-Path -Parent $first.workspace) | Should -Be ([IO.Path]::GetFullPath($script:WorkspaceParent).TrimEnd('\'))
        (Get-FixtureDigest $fixture) | Should -Be $before

        $firstCandidate = [IO.File]::ReadAllBytes((Join-Path $first.workspace $script:ManifestName))
        $secondCandidate = [IO.File]::ReadAllBytes((Join-Path $second.workspace $script:ManifestName))
        [Convert]::ToHexString($firstCandidate) | Should -Be ([Convert]::ToHexString($secondCandidate))
        ([Text.Encoding]::UTF8.GetString($firstCandidate) | Test-Json -SchemaFile $script:SchemaPath) | Should -BeTrue
    }

    It 'retains an exact-byte backup and binds the production Component Catalog' {
        $fixture = New-LegacyFixture -Root $TestDrive
        $original = [IO.File]::ReadAllBytes((Join-Path $fixture $script:ManifestName))

        $process = Invoke-RehearsalProcess $fixture $script:WorkspaceParent
        $result = $process.Text | ConvertFrom-Json -AsHashtable
        $backup = [IO.File]::ReadAllBytes((Join-Path $result.workspace $result.backup))
        $candidate = Get-Content -Raw (Join-Path $result.workspace $script:ManifestName) | ConvertFrom-Json -AsHashtable

        [Convert]::ToHexString($backup) | Should -Be ([Convert]::ToHexString($original))
        $candidate.source_release.component_catalog.path | Should -Be 'manifest/component-catalog.json'
        $candidate.source_release.component_catalog.schema_version | Should -Be 1
        $candidate.source_release.component_catalog.sha256 | Should -Be (Get-Sha256 ([IO.File]::ReadAllBytes($script:CatalogPath)))
        $candidate.components[0].identity.id | Should -Be 'cmp:canonical-architect-agent'
        $candidate.components[0].hashes.proposed_source | Should -Be (
            Get-Sha256 ([IO.File]::ReadAllBytes((Join-Path $script:RepoRoot 'agents/architect.agent.md')))
        )
        $candidate.components[0].hashes.proposed_source | Should -Not -Be $candidate.components[0].hashes.baseline
    }

    It 'classifies fresh customized bytes instead of trusting stale Manifest observed hash' {
        $fixture = New-LegacyFixture -Root $TestDrive
        $componentPath = Join-Path $fixture 'agents/architect.agent.md'
        $freshBytes = [Text.UTF8Encoding]::new($false).GetBytes("locally customized`n")
        [IO.File]::WriteAllBytes($componentPath, $freshBytes)
        $before = Get-FixtureDigest $fixture

        $process = Invoke-RehearsalProcess $fixture $script:WorkspaceParent
        $result = $process.Text | ConvertFrom-Json -AsHashtable
        $candidate = Get-Content -Raw (Join-Path $result.workspace $script:ManifestName) | ConvertFrom-Json -AsHashtable
        $component = $candidate.components[0]

        $process.ExitCode | Should -Be 0
        $component.provenance.fork.status | Should -Be 'customized'
        $component.provenance.fork.decision | Should -Be 'preserve'
        $component.hashes.observed_before | Should -Be (Get-Sha256 $freshBytes)
        $component.hashes.result_after | Should -Be (Get-Sha256 $freshBytes)
        $component.hashes.proposed_source | Should -Be (
            Get-Sha256 ([IO.File]::ReadAllBytes((Join-Path $script:RepoRoot 'agents/architect.agent.md')))
        )
        (Get-FixtureDigest $fixture) | Should -Be $before
    }

    It 'reports a missing current component for manual decision without mapping it' {
        $fixture = New-LegacyFixture -Root $TestDrive
        Remove-Item -LiteralPath (Join-Path $fixture 'agents/architect.agent.md')
        $before = Get-FixtureDigest $fixture

        $process = Invoke-RehearsalProcess $fixture $script:WorkspaceParent
        $result = $process.Text | ConvertFrom-Json -AsHashtable
        $candidate = Get-Content -Raw (Join-Path $result.workspace $script:ManifestName) | ConvertFrom-Json -AsHashtable

        $process.ExitCode | Should -Be 0
        @($candidate.components).Count | Should -Be 0
        @($result.manual_decisions).Count | Should -Be 1
        $result.manual_decisions[0].path | Should -Be 'agents/architect.agent.md'
        $result.manual_decisions[0].reason | Should -Be 'current-file-missing-or-unreadable'
        (Get-FixtureDigest $fixture) | Should -Be $before
    }

    It '[Path-Type] reports an absent manifest as missing without inventing lineage or writing a manifest' {
        $fixture = Join-Path $TestDrive ([Guid]::NewGuid().ToString('N'))
        [IO.Directory]::CreateDirectory($fixture) | Out-Null

        $process = Invoke-RehearsalProcess $fixture $script:WorkspaceParent
        $result = $process.Text | ConvertFrom-Json -AsHashtable

        $process.ExitCode | Should -Be 0
        $result.status | Should -Be 'report-only'
        $result.classification | Should -Be 'missing'
        Test-Path -LiteralPath (Join-Path $result.workspace $script:ManifestName) | Should -BeFalse
    }

    It '[Path-Type] hard stops a directory at the manifest path as corrupt without backup or candidate publication' {
        $fixture = Join-Path $TestDrive ([Guid]::NewGuid().ToString('N'))
        $manifestDirectory = Join-Path $fixture $script:ManifestName
        [IO.Directory]::CreateDirectory($manifestDirectory) | Out-Null
        $before = Get-FullInventory $fixture

        $process = Invoke-RehearsalProcess $fixture $script:WorkspaceParent
        $result = $process.Text | ConvertFrom-Json -AsHashtable

        $process.ExitCode | Should -Not -Be 0
        $result.status | Should -Be 'blocked'
        $result.classification | Should -Be 'corrupt'
        $result.error | Should -Match 'expected a regular Manifest file but found a directory or container'
        $result.committed | Should -BeFalse
        Test-Path -LiteralPath (Join-Path $result.workspace $script:BackupName) | Should -BeFalse
        Test-Path -LiteralPath (Join-Path $result.workspace $script:ManifestName) -PathType Container | Should -BeTrue
        @(Get-ChildItem -LiteralPath $result.workspace -Force -Filter '.phase4c-*.tmp').Count | Should -Be 0
        @(Get-FullInventory $fixture) | Should -Be $before
    }

    It '[Path-Type] hard stops a manifest inspection failure instead of degrading it to missing' {
        $fixture = New-LegacyFixture -Root $TestDrive
        $before = Get-FullInventory $fixture
        $env:AI_WORKFLOW_PHASE4C_TEST_MODE = '1'

        $process = Invoke-RehearsalProcess $fixture $script:WorkspaceParent 'manifest-inspection'
        $result = $process.Text | ConvertFrom-Json -AsHashtable

        $process.ExitCode | Should -Not -Be 0
        $result.status | Should -Be 'blocked'
        $result.classification | Should -Be 'corrupt'
        $result.error | Should -Match 'Unable to inspect the Manifest path'
        $result.committed | Should -BeFalse
        Test-Path -LiteralPath (Join-Path $result.workspace $script:BackupName) | Should -BeFalse
        @(Get-ChildItem -LiteralPath $result.workspace -Force -Filter '.phase4c-*.tmp').Count | Should -Be 0
        @(Get-FullInventory $fixture) | Should -Be $before
    }

    It 'rejects source and workspace overlap before creating any path or changing source bytes' -ForEach @(
        @{ Relationship = 'equal' },
        @{ Relationship = 'workspace-ancestor' },
        @{ Relationship = 'workspace-descendant' }
    ) {
        $caseRoot = Join-Path $TestDrive ([Guid]::NewGuid().ToString('N'))
        [IO.Directory]::CreateDirectory($caseRoot) | Out-Null
        $fixture = New-LegacyFixture -Root $caseRoot
        $workspaceParent = switch ($_.Relationship) {
            'equal' { $fixture }
            'workspace-ancestor' { $caseRoot }
            'workspace-descendant' { Join-Path $fixture 'not-yet-created-workspaces' }
        }
        $before = Get-FullInventory $fixture

        $process = Invoke-RehearsalProcess $fixture $workspaceParent
        $result = $process.Text | ConvertFrom-Json -AsHashtable

        $process.ExitCode | Should -Not -Be 0
        $result.status | Should -Be 'blocked'
        $result.classification | Should -Be 'unsafe-path'
        @(Get-FullInventory $fixture) | Should -Be $before
    }

    It 'hard stops corrupt unsupported and wrong-top-level manifests before candidate publication' -ForEach @(
        @{ Bytes = [Text.Encoding]::UTF8.GetBytes('{'); Classification = 'corrupt' },
        @{ Bytes = [Text.Encoding]::UTF8.GetBytes('[]'); Classification = 'wrong-top-level' },
        @{ Bytes = [Text.Encoding]::UTF8.GetBytes('{"schema_version":4,"components":[]}'); Classification = 'unsupported' }
    ) {
        $fixture = Join-Path $TestDrive ([Guid]::NewGuid().ToString('N'))
        [IO.Directory]::CreateDirectory($fixture) | Out-Null
        [IO.File]::WriteAllBytes((Join-Path $fixture $script:ManifestName), $_.Bytes)
        $before = Get-FixtureDigest $fixture

        $process = Invoke-RehearsalProcess $fixture $script:WorkspaceParent
        $result = $process.Text | ConvertFrom-Json -AsHashtable

        $process.ExitCode | Should -Not -Be 0
        $result.status | Should -Be 'blocked'
        $result.classification | Should -Be $_.Classification
        $result.committed | Should -BeFalse
        Test-Path -LiteralPath (Join-Path $result.workspace 'rehearsal-diagnostic.json') | Should -BeTrue
        (Get-FixtureDigest $fixture) | Should -Be $before
    }

    It 'strictly rejects malformed legacy component structure without backup or candidate' -ForEach @(
        @{
            Label = 'invalid-utf8'
            Bytes = [byte[]](0x7b,0x22,0x73,0x63,0x68,0x65,0x6d,0x61,0x5f,0x76,0x65,0x72,0x73,0x69,0x6f,0x6e,0x22,0x3a,0x32,0x2c,0x22,0x63,0x6f,0x6d,0x70,0x6f,0x6e,0x65,0x6e,0x74,0x73,0x22,0x3a,0x5b,0x5d,0x2c,0x22,0x78,0x22,0x3a,0x22,0xc3,0x28,0x22,0x7d)
        },
        @{ Label = 'null-component'; Bytes = [Text.Encoding]::UTF8.GetBytes('{"schema_version":2,"components":[null]}') },
        @{ Label = 'missing-name'; Bytes = [Text.Encoding]::UTF8.GetBytes('{"schema_version":2,"components":[{}]}') },
        @{ Label = 'blank-name'; Bytes = [Text.Encoding]::UTF8.GetBytes('{"schema_version":2,"components":[{"name":"  "}]}') },
        @{ Label = 'unsafe-name'; Bytes = [Text.Encoding]::UTF8.GetBytes('{"schema_version":2,"components":[{"name":"../outside"}]}') },
        @{ Label = 'duplicate-name'; Bytes = [Text.Encoding]::UTF8.GetBytes('{"schema_version":2,"components":[{"name":"agents/a.md"},{"name":"agents/a.md"}]}') }
    ) {
        $fixture = Join-Path $TestDrive ([Guid]::NewGuid().ToString('N'))
        [IO.Directory]::CreateDirectory($fixture) | Out-Null
        [IO.File]::WriteAllBytes((Join-Path $fixture $script:ManifestName), $_.Bytes)
        $before = Get-FullInventory $fixture

        $process = Invoke-RehearsalProcess $fixture $script:WorkspaceParent
        $result = $process.Text | ConvertFrom-Json -AsHashtable

        $process.ExitCode | Should -Not -Be 0
        $result.status | Should -Be 'blocked'
        $result.classification | Should -Be 'corrupt'
        $result.ContainsKey('backup') | Should -BeFalse
        Test-Path -LiteralPath (Join-Path $result.workspace '.ai-workflow-install.json.phase4c-backup') | Should -BeFalse
        @(Get-ChildItem -LiteralPath $result.workspace -Force -File -Filter '*.tmp').Count | Should -Be 0
        @(Get-FullInventory $fixture) | Should -Be $before
    }

    It 'keeps a narrow v1 record without ownership as a manual decision' {
        $fixture = New-LegacyFixture -Root $TestDrive -Version 1
        $manifestPath = Join-Path $fixture $script:ManifestName
        $manifest = Get-Content -Raw $manifestPath | ConvertFrom-Json -AsHashtable
        $manifest.components[0].Remove('ownership')
        $legacyJson = ConvertTo-Json $manifest -Depth 10 -Compress
        [IO.File]::WriteAllBytes(
            $manifestPath,
            [Text.UTF8Encoding]::new($false).GetBytes($legacyJson + "`n")
        )
        $before = Get-FullInventory $fixture

        $process = Invoke-RehearsalProcess $fixture $script:WorkspaceParent
        $result = $process.Text | ConvertFrom-Json -AsHashtable
        $candidate = Get-Content -Raw (Join-Path $result.workspace $script:ManifestName) | ConvertFrom-Json -AsHashtable

        $process.ExitCode | Should -Be 0
        @($candidate.components).Count | Should -Be 0
        $result.manual_decisions[0].path | Should -Be 'agents/architect.agent.md'
        $result.manual_decisions[0].reason | Should -Be 'missing-or-untrusted-lineage'
        @(Get-FullInventory $fixture) | Should -Be $before
    }

    It 'keeps unproven legacy source evidence manual without creating a v3 component' -ForEach @(
        @{ Label = 'conflicting-locator'; Name = $null; Source = 'template:agents/coder.agent.md'; SourceHash = $null },
        @{ Label = 'case-mismatched-locator'; Name = $null; Source = 'template:Agents/architect.agent.md'; SourceHash = $null },
        @{ Label = 'case-mismatched-name'; Name = 'Agents/architect.agent.md'; Source = 'template:agents/architect.agent.md'; SourceHash = $null },
        @{ Label = 'empty-locator'; Name = $null; Source = ''; SourceHash = $null },
        @{ Label = 'prefix-only-locator'; Name = $null; Source = 'template:any/arbitrary.md'; SourceHash = $null },
        @{ Label = 'fabricated-source-hash'; Name = $null; Source = 'template:agents/architect.agent.md'; SourceHash = ('sha256:' + ('0' * 64)) }
    ) {
        $fixture = New-LegacyFixture -Root $TestDrive
        $manifestPath = Join-Path $fixture $script:ManifestName
        $manifest = Get-Content -Raw $manifestPath | ConvertFrom-Json -AsHashtable
        if ($null -ne $_.Name) {
            $manifest.components[0].name = $_.Name
        }
        $manifest.components[0].source = $_.Source
        if ($null -ne $_.SourceHash) {
            $manifest.components[0].source_hash = $_.SourceHash
        }
        $legacyJson = ConvertTo-Json $manifest -Depth 10 -Compress
        [IO.File]::WriteAllBytes(
            $manifestPath,
            [Text.UTF8Encoding]::new($false).GetBytes($legacyJson + "`n")
        )
        $before = Get-FullInventory $fixture

        $process = Invoke-RehearsalProcess $fixture $script:WorkspaceParent
        $result = $process.Text | ConvertFrom-Json -AsHashtable
        $candidate = Get-Content -Raw (Join-Path $result.workspace $script:ManifestName) | ConvertFrom-Json -AsHashtable

        $process.ExitCode | Should -Be 0
        @($candidate.components).Count | Should -Be 0
        @($result.manual_decisions).Count | Should -Be 1
        $result.manual_decisions[0].path | Should -Be 'agents/architect.agent.md'
        @(Get-FullInventory $fixture) | Should -Be $before
    }

    It 'does not accept a caller-selected non-empty output target' {
        $fixture = New-LegacyFixture -Root $TestDrive
        $selected = Join-Path $TestDrive 'selected-output'
        [IO.Directory]::CreateDirectory($selected) | Out-Null
        $sentinel = Join-Path $selected 'sentinel.txt'
        [IO.File]::WriteAllText($sentinel, 'keep')

        $output = & (Get-Process -Id $PID).Path -NoProfile -File $script:EntryPoint `
            -SourceFixture $fixture -OutputPath $selected 2>&1

        $LASTEXITCODE | Should -Not -Be 0
        [IO.File]::ReadAllText($sentinel) | Should -Be 'keep'
        @($output) -join "`n" | Should -Match 'OutputPath'
    }

    It 'rejects raw traversal segments before path normalization' -ForEach @(
        @{ PathKind = 'source' },
        @{ PathKind = 'workspace' }
    ) {
        $fixture = New-LegacyFixture -Root $TestDrive
        $source = $fixture
        $workspaceParent = $script:WorkspaceParent
        if ($_.PathKind -eq 'source') {
            $source = Join-Path $fixture ("..\{0}" -f (Split-Path -Leaf $fixture))
        } else {
            $workspaceParent = Join-Path $script:WorkspaceParent ("..\{0}" -f (Split-Path -Leaf $script:WorkspaceParent))
        }

        $process = Invoke-RehearsalProcess $source $workspaceParent
        $result = $process.Text | ConvertFrom-Json -AsHashtable

        $process.ExitCode | Should -Not -Be 0
        $result.status | Should -Be 'blocked'
        $result.classification | Should -Be 'unsafe-path'
    }

    It 'rejects a pre-existing junction fixture before reading its manifest' {
        $actual = New-LegacyFixture -Root $TestDrive
        $junction = Join-Path $TestDrive 'fixture-junction'
        try {
            New-Item -ItemType Junction -Path $junction -Target $actual -ErrorAction Stop | Out-Null
        } catch {
            Set-ItResult -Skipped -Because "Junction creation unavailable: $($_.Exception.Message)"
            return
        }

        $process = Invoke-RehearsalProcess $junction $script:WorkspaceParent
        $result = $process.Text | ConvertFrom-Json -AsHashtable

        $process.ExitCode | Should -Not -Be 0
        $result.status | Should -Be 'blocked'
        $result.classification | Should -Be 'unsafe-path'
    }

    It '[Path-Type] hard stops a leaf junction at the manifest path without reading or changing its target' {
        $fixture = Join-Path $TestDrive ([Guid]::NewGuid().ToString('N'))
        $target = Join-Path $TestDrive ([Guid]::NewGuid().ToString('N'))
        [IO.Directory]::CreateDirectory($fixture) | Out-Null
        [IO.Directory]::CreateDirectory($target) | Out-Null
        $sentinel = Join-Path $target 'outside-sentinel.txt'
        [IO.File]::WriteAllText($sentinel, 'outside-leaf-junction-sentinel')
        $targetBefore = Get-FullInventory $target
        $fixtureBefore = $null
        try {
            New-Item -ItemType Junction -Path (Join-Path $fixture $script:ManifestName) -Target $target -ErrorAction Stop | Out-Null
            $fixtureBefore = Get-FullInventory $fixture
        } catch {
            Set-ItResult -Skipped -Because "Junction creation unavailable: $($_.Exception.Message)"
            return
        }

        $process = Invoke-RehearsalProcess $fixture $script:WorkspaceParent
        $result = $process.Text | ConvertFrom-Json -AsHashtable

        $process.ExitCode | Should -Not -Be 0
        $result.status | Should -Be 'blocked'
        $result.classification | Should -Be 'unsafe-path'
        $result.committed | Should -BeFalse
        $result.workspace | Should -Be ''
        $process.Text | Should -Not -Match 'outside-leaf-junction-sentinel'
        @(Get-FullInventory $fixture) | Should -Be $fixtureBefore
        @(Get-FullInventory $target) | Should -Be $targetBefore
    }

    It 'never reports committed when replace publication fails and retains backup and diagnostic' {
        $fixture = New-LegacyFixture -Root $TestDrive
        $env:AI_WORKFLOW_PHASE4C_TEST_MODE = '1'

        $process = Invoke-RehearsalProcess $fixture $script:WorkspaceParent 'replace'
        $result = $process.Text | ConvertFrom-Json -AsHashtable

        $process.ExitCode | Should -Not -Be 0
        $result.status | Should -Be 'blocked'
        $result.committed | Should -BeFalse
        Test-Path -LiteralPath (Join-Path $result.workspace $result.backup) | Should -BeTrue
        Test-Path -LiteralPath (Join-Path $result.workspace 'rehearsal-diagnostic.json') | Should -BeTrue
    }

    It 'retains an exact backup when Catalog-stage failure occurs' {
        $fixture = New-LegacyFixture -Root $TestDrive
        $original = [IO.File]::ReadAllBytes((Join-Path $fixture $script:ManifestName))
        $env:AI_WORKFLOW_PHASE4C_TEST_MODE = '1'

        $process = Invoke-RehearsalProcess $fixture $script:WorkspaceParent 'catalog-read'
        $result = $process.Text | ConvertFrom-Json -AsHashtable
        $backup = [IO.File]::ReadAllBytes((Join-Path $result.workspace $result.backup))

        $process.ExitCode | Should -Not -Be 0
        $result.status | Should -Be 'blocked'
        $result.committed | Should -BeFalse
        [Convert]::ToHexString($backup) | Should -Be ([Convert]::ToHexString($original))
        Test-Path -LiteralPath (Join-Path $result.workspace $result.diagnostic) | Should -BeTrue
    }

    It 'treats replacement that throws before publication authority as manual recovery' {
        $fixture = New-LegacyFixture -Root $TestDrive
        $env:AI_WORKFLOW_PHASE4C_TEST_MODE = '1'

        $process = Invoke-RehearsalProcess $fixture $script:WorkspaceParent 'replace-uncertain'
        $result = $process.Text | ConvertFrom-Json -AsHashtable

        $process.ExitCode | Should -Not -Be 0
        $result.status | Should -Be 'manual-recovery-required'
        $result.committed | Should -BeFalse
        Test-Path -LiteralPath (Join-Path $result.workspace $result.backup) | Should -BeTrue
        Test-Path -LiteralPath (Join-Path $result.workspace $result.diagnostic) | Should -BeTrue
    }

    It 'keeps live legacy state when staging validation fails before publication' {
        $fixture = New-LegacyFixture -Root $TestDrive
        $legacyBytes = [IO.File]::ReadAllBytes((Join-Path $fixture $script:ManifestName))
        $env:AI_WORKFLOW_PHASE4C_TEST_MODE = '1'

        $process = Invoke-RehearsalProcess $fixture $script:WorkspaceParent 'post-write-validation'
        $result = $process.Text | ConvertFrom-Json -AsHashtable
        $liveBytes = [IO.File]::ReadAllBytes((Join-Path $result.workspace $script:ManifestName))

        $process.ExitCode | Should -Not -Be 0
        $result.status | Should -Be 'blocked'
        $result.committed | Should -BeFalse
        [Convert]::ToHexString($liveBytes) | Should -Be ([Convert]::ToHexString($legacyBytes))
        Test-Path -LiteralPath (Join-Path $result.workspace $result.backup) | Should -BeTrue
        Test-Path -LiteralPath (Join-Path $result.workspace 'rehearsal-diagnostic.json') | Should -BeTrue
        foreach ($file in Get-ChildItem -LiteralPath $result.workspace -Force -File) {
            [Text.Encoding]::UTF8.GetString([IO.File]::ReadAllBytes($file.FullName)) | Should -Not -Match '"result":"committed"'
        }
    }

    It 'does not claim a diagnostic artifact when diagnostic persistence fails' {
        $fixture = New-LegacyFixture -Root $TestDrive
        $env:AI_WORKFLOW_PHASE4C_TEST_MODE = '1'

        $process = Invoke-RehearsalProcess $fixture $script:WorkspaceParent 'diagnostic-write'
        $result = $process.Text | ConvertFrom-Json -AsHashtable

        $process.ExitCode | Should -Not -Be 0
        $result.committed | Should -BeFalse
        $result.ContainsKey('diagnostic') | Should -BeFalse
        $result.diagnostic_error | Should -Match 'Injected diagnostic write failure'
        Test-Path -LiteralPath (Join-Path $result.workspace 'rehearsal-diagnostic.json') | Should -BeFalse
    }

    It 'contains no Python launch and does not expose lock journal restore prune or tombstone operations' {
        $source = Get-Content -Raw $script:EntryPoint

        $source | Should -Not -Match '(?i)python(?:3|\.exe)?'
        $source | Should -Not -Match '(?i)acquire-lock|journal|rollback|restore-|prune|tombstone'
    }
}
