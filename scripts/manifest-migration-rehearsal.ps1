[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [string]$SourceFixture,

    [string]$WorkspaceParent = [IO.Path]::GetTempPath(),

    [Parameter(DontShow)]
    [ValidateSet(
        '',
        'catalog-read',
        'replace',
        'replace-uncertain',
        'post-write-validation',
        'diagnostic-write',
        'manifest-inspection'
    )]
    [string]$TestFailpoint = ''
)

$ErrorActionPreference = 'Stop'
$script:ManifestName = '.ai-workflow-install.json'
$script:BackupName = '.ai-workflow-install.json.phase4c-backup'
$script:DiagnosticName = 'rehearsal-diagnostic.json'
$script:FixedTimestamp = '1970-01-01T00:00:00Z'
$script:RepoRoot = Split-Path -Parent $PSScriptRoot
$script:SchemaPath = Join-Path $script:RepoRoot 'schemas/ai-workflow-install-manifest-v3.schema.json'
$script:CatalogPath = Join-Path $script:RepoRoot 'manifest/component-catalog.json'

function Get-Sha256 {
    param([Parameter(Mandatory = $true)][byte[]]$Bytes)

    return 'sha256:' + [Convert]::ToHexString(
        [Security.Cryptography.SHA256]::HashData($Bytes)
    ).ToLowerInvariant()
}

function ConvertTo-CanonicalBytes {
    param([Parameter(Mandatory = $true)]$Value)

    $json = $Value | ConvertTo-Json -Depth 40 -Compress
    return [Text.UTF8Encoding]::new($false).GetBytes($json + "`n")
}

function Write-JsonResult {
    param(
        [Parameter(Mandatory = $true)]$Value,
        [Parameter(Mandatory = $true)][int]$ExitCode
    )

    [Console]::Out.WriteLine(($Value | ConvertTo-Json -Depth 40 -Compress))
    exit $ExitCode
}

function New-BaseResult {
    param(
        [string]$Status,
        [string]$Classification,
        [string]$Workspace = ''
    )

    return [ordered]@{
        status = $Status
        classification = $Classification
        committed = $false
        workspace = $Workspace
        rehearsal_only = $true
        no_real_adopter_operation = $true
        not_execution_authorization = $true
    }
}

function Test-IsUnderPath {
    param(
        [Parameter(Mandatory = $true)][string]$Candidate,
        [Parameter(Mandatory = $true)][string]$Parent
    )

    $candidateFull = [IO.Path]::GetFullPath($Candidate).TrimEnd('\', '/')
    $parentFull = [IO.Path]::GetFullPath($Parent).TrimEnd('\', '/')
    if ($candidateFull.Equals($parentFull, [StringComparison]::OrdinalIgnoreCase)) {
        return $true
    }
    return $candidateFull.StartsWith(
        $parentFull + [IO.Path]::DirectorySeparatorChar,
        [StringComparison]::OrdinalIgnoreCase
    )
}

function Test-PathsOverlap {
    param(
        [Parameter(Mandatory = $true)][string]$First,
        [Parameter(Mandatory = $true)][string]$Second
    )

    return (
        (Test-IsUnderPath -Candidate $First -Parent $Second) -or
        (Test-IsUnderPath -Candidate $Second -Parent $First)
    )
}

function Assert-NoReparsePoint {
    param(
        [Parameter(Mandatory = $true)][string]$Path,
        [switch]$ScanChildren
    )

    $full = [IO.Path]::GetFullPath($Path)
    $current = $full
    while ($current) {
        if (Test-Path -LiteralPath $current) {
            $item = Get-Item -LiteralPath $current -Force
            if (($item.Attributes -band [IO.FileAttributes]::ReparsePoint) -ne 0) {
                throw "ReparsePoint paths are not supported: $current"
            }
        }
        $parent = Split-Path -Parent $current
        if (-not $parent -or $parent -eq $current) {
            break
        }
        $current = $parent
    }
    if ($ScanChildren) {
        foreach ($item in Get-ChildItem -LiteralPath $full -Force -Recurse) {
            if (($item.Attributes -band [IO.FileAttributes]::ReparsePoint) -ne 0) {
                throw "ReparsePoint content is not supported: $($item.FullName)"
            }
        }
    }
}

function Assert-SafeSourceFixture {
    param([Parameter(Mandatory = $true)][string]$Path)

    if (@($Path -split '[\\/]' | Where-Object { $_ -in @('.', '..') }).Count -gt 0) {
        throw 'SourceFixture contains a traversal segment.'
    }
    if ($Path.StartsWith('\\') -or $Path.StartsWith('//')) {
        throw 'UNC source fixtures are not supported.'
    }
    if (-not (Test-Path -LiteralPath $Path -PathType Container)) {
        throw 'SourceFixture must be an existing directory.'
    }
    $full = [IO.Path]::GetFullPath($Path).TrimEnd('\', '/')
    $root = [IO.Path]::GetPathRoot($full).TrimEnd('\', '/')
    if ($full.Equals($root, [StringComparison]::OrdinalIgnoreCase)) {
        throw 'A filesystem root cannot be used as SourceFixture.'
    }
    Assert-NoReparsePoint -Path $full -ScanChildren
    return $full
}

function Assert-SafeWorkspaceParent {
    param([Parameter(Mandatory = $true)][string]$Path)

    if (@($Path -split '[\\/]' | Where-Object { $_ -in @('.', '..') }).Count -gt 0) {
        throw 'WorkspaceParent contains a traversal segment.'
    }
    if ($Path.StartsWith('\\') -or $Path.StartsWith('//')) {
        throw 'UNC workspace parents are not supported.'
    }
    $full = [IO.Path]::GetFullPath($Path)
    $temp = [IO.Path]::GetFullPath([IO.Path]::GetTempPath())
    if (-not (Test-IsUnderPath -Candidate $full -Parent $temp)) {
        throw 'WorkspaceParent must be located under Windows Temp.'
    }
    Assert-NoReparsePoint -Path $full
    return $full.TrimEnd('\', '/')
}

function New-RehearsalWorkspace {
    param(
        [Parameter(Mandatory = $true)][string]$Parent,
        [Parameter(Mandatory = $true)][string]$Source
    )

    $path = Join-Path $Parent ('phase4c-rehearsal-' + [Guid]::NewGuid().ToString('N'))
    if (Test-PathsOverlap -First $path -Second $Source) {
        throw 'Generated workspace overlaps SourceFixture.'
    }
    if (Test-Path -LiteralPath $path) {
        throw 'Generated workspace already exists.'
    }
    [IO.Directory]::CreateDirectory($path) | Out-Null
    if (@(Get-ChildItem -LiteralPath $path -Force).Count -ne 0) {
        throw 'Generated workspace is not empty.'
    }
    return $path
}

function Copy-Fixture {
    param(
        [Parameter(Mandatory = $true)][string]$Source,
        [Parameter(Mandatory = $true)][string]$Workspace
    )

    foreach ($item in Get-ChildItem -LiteralPath $Source -Force) {
        Copy-Item -LiteralPath $item.FullName -Destination $Workspace -Recurse -Force
    }
}

function Get-ManifestClassification {
    param([string]$ManifestPath)

    try {
        if ($TestFailpoint -eq 'manifest-inspection') {
            throw [IO.IOException]::new('Injected Manifest path inspection failure.')
        }
        $item = Get-Item -LiteralPath $ManifestPath -Force -ErrorAction Stop
        $attributes = $item.Attributes
        $isContainer = [bool]$item.PSIsContainer
        $isRegularFile = $item -is [IO.FileInfo]
    } catch [Management.Automation.ItemNotFoundException] {
        return [ordered]@{ state = 'missing'; version = $null; value = $null }
    } catch {
        return [ordered]@{
            state = 'corrupt'
            version = $null
            value = $null
            reason = "Unable to inspect the Manifest path safely: $($_.Exception.Message)"
        }
    }
    if (($attributes -band [IO.FileAttributes]::ReparsePoint) -ne 0) {
        return [ordered]@{
            state = 'unsafe-path'
            version = $null
            value = $null
            reason = 'The Manifest path is a ReparsePoint, Junction, or SymbolicLink.'
        }
    }
    if ($isContainer) {
        return [ordered]@{
            state = 'corrupt'
            version = $null
            value = $null
            reason = 'Expected a regular Manifest file but found a directory or container.'
        }
    }
    if (-not $isRegularFile) {
        return [ordered]@{
            state = 'corrupt'
            version = $null
            value = $null
            reason = 'The expected Manifest path is not a supported regular file.'
        }
    }
    try {
        $bytes = [IO.File]::ReadAllBytes($item.FullName)
        $strictUtf8 = [Text.UTF8Encoding]::new($false, $true)
        $value = $strictUtf8.GetString($bytes) | ConvertFrom-Json -AsHashtable
    } catch {
        return [ordered]@{ state = 'corrupt'; version = $null; value = $null }
    }
    if ($value -isnot [Collections.IDictionary]) {
        return [ordered]@{ state = 'wrong-top-level'; version = $null; value = $null }
    }
    $version = $value.schema_version
    if (
        ($version -isnot [int] -and $version -isnot [long]) -or
        $value.components -isnot [array]
    ) {
        return [ordered]@{ state = 'corrupt'; version = $version; value = $null }
    }
    $componentNames = [Collections.Generic.HashSet[string]]::new(
        [StringComparer]::Ordinal
    )
    foreach ($component in $value.components) {
        if ($component -isnot [Collections.IDictionary]) {
            return [ordered]@{ state = 'corrupt'; version = $version; value = $null }
        }
        $name = if ($component.Contains('name')) { $component['name'] } else { $null }
        if (
            $name -isnot [string] -or
            [string]::IsNullOrWhiteSpace($name) -or
            -not (Test-SafeRelativePath $name) -or
            -not $componentNames.Add($name)
        ) {
            return [ordered]@{ state = 'corrupt'; version = $version; value = $null }
        }
    }
    if ($version -notin @(1, 2)) {
        return [ordered]@{ state = 'unsupported'; version = $version; value = $null }
    }
    return [ordered]@{ state = "valid-v$version"; version = $version; value = $value }
}

function Get-NormalizedHash {
    param($Value)

    if ($Value -is [string] -and $Value -match '^sha256:[0-9a-f]{64}$') {
        return $Value
    }
    return $null
}

function Test-SafeRelativePath {
    param($Value)

    if ($Value -isnot [string] -or -not $Value) {
        return $false
    }
    $normalized = $Value.Replace('\', '/')
    if (
        $normalized.StartsWith('/') -or
        $normalized -match '^[A-Za-z]:' -or
        $normalized.Contains('//')
    ) {
        return $false
    }
    foreach ($part in $normalized.Split('/')) {
        if (-not $part -or $part -in @('.', '..') -or $part.EndsWith('.') -or $part.EndsWith(' ')) {
            return $false
        }
    }
    return $normalized -match '^[A-Za-z0-9@+_.-]+(?:/[A-Za-z0-9@+_.-]+)*$'
}

function Get-ForkRecord {
    param(
        [Parameter(Mandatory = $true)][Collections.IDictionary]$Entry,
        [Parameter(Mandatory = $true)][string]$Role,
        [Parameter(Mandatory = $true)][string]$Kind
    )

    if ($Role -eq 'project-owned') {
        return [ordered]@{ status = 'project-owned'; basis = 'explicit-project-ownership'; decision = 'preserve'; classified_at = $script:FixedTimestamp }
    }
    if ($Role -eq 'compatibility') {
        return [ordered]@{ status = 'legacy'; basis = 'legacy-import'; decision = 'report-only'; classified_at = $script:FixedTimestamp }
    }
    if ($Kind -ne 'file') {
        return [ordered]@{ status = 'not-applicable'; basis = 'hash-not-applicable'; decision = 'report-only'; classified_at = $script:FixedTimestamp }
    }
    if ($Entry.managed_hash -eq $Entry.observed_hash) {
        return [ordered]@{ status = 'untouched'; basis = 'verified-managed-equality'; decision = 'manage'; classified_at = $script:FixedTimestamp }
    }
    if ($Role -eq 'generated') {
        return [ordered]@{ status = 'derived-customized'; basis = 'derived-hash-divergence'; decision = 'preserve'; classified_at = $script:FixedTimestamp }
    }
    return [ordered]@{ status = 'customized'; basis = 'hash-divergence'; decision = 'preserve'; classified_at = $script:FixedTimestamp }
}

function New-ComponentRecord {
    param(
        [Parameter(Mandatory = $true)][Collections.IDictionary]$Entry,
        [Parameter(Mandatory = $true)][Collections.IDictionary]$CatalogComponent,
        [Parameter(Mandatory = $true)][string]$TransactionId,
        [Parameter(Mandatory = $true)][string]$CandidateTimestamp
    )

    $roleOwnership = @{
        canonical = 'template-managed'
        generated = 'derived-runtime'
        'project-owned' = 'project-owned'
        compatibility = 'legacy-compat'
    }
    $roleSource = @{
        canonical = 'template'
        generated = 'generated'
        'project-owned' = 'project'
        compatibility = 'legacy'
    }
    $role = [string]$CatalogComponent.role
    $kind = [string]$CatalogComponent.kind
    $path = [string]$CatalogComponent.canonical_source_path
    $sourceKind = $roleSource[$role]
    $release = if ($role -in @('canonical', 'generated')) { 'ai-dev-workflow:component-catalog:1' } else { $null }
    $baseline = if ($kind -eq 'file') { Get-NormalizedHash $Entry.managed_hash } else { $null }
    $observed = if ($kind -eq 'file') { Get-NormalizedHash $Entry.observed_hash } else { $null }
    $proposed = if ($kind -eq 'file') { Get-NormalizedHash $Entry.proposed_source_hash } else { $null }
    $installedAt = if ($Entry.installed_at -is [string] -and $Entry.installed_at.EndsWith('Z')) {
        $Entry.installed_at
    } else {
        $null
    }

    return [ordered]@{
        identity = [ordered]@{
            id = $CatalogComponent.id
            path = $path
            path_key = $path.ToLowerInvariant()
            kind = $kind
            role = $role
            link = $null
        }
        provenance = [ordered]@{
            ownership = $roleOwnership[$role]
            source = [ordered]@{
                kind = $sourceKind
                locator = "${sourceKind}:$path"
                release = $release
            }
            generated_from = @($CatalogComponent.generated_from)
            fork = Get-ForkRecord -Entry $Entry -Role $role -Kind $kind
        }
        hashes = [ordered]@{
            algorithm = 'sha256'
            content_basis = 'exact-bytes'
            baseline = $baseline
            observed_before = $observed
            proposed_source = $proposed
            result_after = $observed
        }
        lifecycle = [ordered]@{
            state = 'active'
            previous_paths = @($CatalogComponent.previous_paths)
            retirement = $null
            reintroduces_component_id = $CatalogComponent.reintroduces_component_id
        }
        last_operation = [ordered]@{
            transaction_id = $TransactionId
            outcome = 'reported'
        }
        installed_at = $installedAt
        updated_at = $CandidateTimestamp
    }
}

function Get-CandidateTimestamp {
    param([Parameter(Mandatory = $true)][Collections.IDictionary]$Legacy)

    $latest = [DateTimeOffset]::Parse(
        $script:FixedTimestamp,
        [Globalization.CultureInfo]::InvariantCulture
    )
    $values = @($Legacy.installed_at)
    foreach ($entry in $Legacy.components) {
        if ($entry -is [Collections.IDictionary]) {
            $values += @($entry.installed_at, $entry.updated_at)
        }
    }
    foreach ($value in $values) {
        if ($value -isnot [string]) {
            continue
        }
        $parsed = [DateTimeOffset]::MinValue
        if (
            [DateTimeOffset]::TryParse(
                $value,
                [Globalization.CultureInfo]::InvariantCulture,
                [Globalization.DateTimeStyles]::AssumeUniversal,
                [ref]$parsed
            ) -and
            $parsed -gt $latest
        ) {
            $latest = $parsed
        }
    }
    return $latest.ToUniversalTime().ToString(
        'yyyy-MM-ddTHH:mm:ss.fffffffZ',
        [Globalization.CultureInfo]::InvariantCulture
    )
}

function Get-FreshFileEvidence {
    param(
        [Parameter(Mandatory = $true)][string]$Workspace,
        [Parameter(Mandatory = $true)][string]$RelativePath
    )

    $nativeRelative = $RelativePath.Replace('/', [IO.Path]::DirectorySeparatorChar)
    $path = Join-Path $Workspace $nativeRelative
    if (-not (Test-IsUnderPath -Candidate $path -Parent $Workspace)) {
        return [ordered]@{ valid = $false; hash = $null }
    }
    try {
        Assert-NoReparsePoint -Path $path
        if (-not (Test-Path -LiteralPath $path -PathType Leaf)) {
            return [ordered]@{ valid = $false; hash = $null }
        }
        $bytes = [IO.File]::ReadAllBytes($path)
        return [ordered]@{ valid = $true; hash = Get-Sha256 $bytes }
    } catch {
        return [ordered]@{ valid = $false; hash = $null }
    }
}

function Get-CurrentRepositorySourceEvidence {
    param([Parameter(Mandatory = $true)][Collections.IDictionary]$CatalogComponent)

    $relativePath = [string]$CatalogComponent.canonical_source_path
    if (-not (Test-SafeRelativePath $relativePath)) {
        return [ordered]@{ valid = $false; hash = $null }
    }
    $nativeRelative = $relativePath.Replace('/', [IO.Path]::DirectorySeparatorChar)
    $path = Join-Path $script:RepoRoot $nativeRelative
    if (-not (Test-IsUnderPath -Candidate $path -Parent $script:RepoRoot)) {
        return [ordered]@{ valid = $false; hash = $null }
    }
    try {
        Assert-NoReparsePoint -Path $path
        if (-not (Test-Path -LiteralPath $path -PathType Leaf)) {
            return [ordered]@{ valid = $false; hash = $null }
        }
        return [ordered]@{
            valid = $true
            hash = Get-Sha256 ([IO.File]::ReadAllBytes($path))
        }
    } catch {
        return [ordered]@{ valid = $false; hash = $null }
    }
}

function New-V3Candidate {
    param(
        [Parameter(Mandatory = $true)][Collections.IDictionary]$Legacy,
        [Parameter(Mandatory = $true)][Collections.IDictionary]$Catalog,
        [Parameter(Mandatory = $true)][byte[]]$CatalogBytes,
        [Parameter(Mandatory = $true)][string]$Workspace
    )

    $catalogByPath = [Collections.Generic.Dictionary[string, object]]::new(
        [StringComparer]::Ordinal
    )
    foreach ($component in $Catalog.components) {
        $catalogByPath[[string]$component.canonical_source_path] = $component
    }
    $seed = ConvertTo-CanonicalBytes $Legacy
    $combined = [byte[]]::new($seed.Length + $CatalogBytes.Length)
    [Array]::Copy($seed, 0, $combined, 0, $seed.Length)
    [Array]::Copy($CatalogBytes, 0, $combined, $seed.Length, $CatalogBytes.Length)
    $transactionId = 'txn:phase4c.' + (Get-Sha256 $combined).Substring(7, 24)
    $candidateTimestamp = Get-CandidateTimestamp -Legacy $Legacy
    $eligible = @()
    $manual = @()
    $seen = @{}
    foreach ($entry in $Legacy.components) {
        if ($entry -isnot [Collections.IDictionary] -or -not (Test-SafeRelativePath $entry.name)) {
            $manual += ,([ordered]@{ path = '<invalid>'; reason = 'unsafe-component-path' })
            continue
        }
        $path = ([string]$entry.name).Replace('\', '/')
        if ($seen.ContainsKey($path)) {
            $manual += ,([ordered]@{ path = $path; reason = 'duplicate-component-path' })
            continue
        }
        $seen[$path] = $true
        if (-not $catalogByPath.ContainsKey($path)) {
            $manual += ,([ordered]@{ path = $path; reason = 'not-in-component-catalog' })
            continue
        }
        $catalogComponent = $catalogByPath[$path]
        $reason = $null
        if (
            -not [string]::Equals([string]$catalogComponent.role, 'canonical', [StringComparison]::Ordinal) -or
            -not [string]::Equals([string]$catalogComponent.kind, 'file', [StringComparison]::Ordinal) -or
            -not [string]::Equals([string]$catalogComponent.lifecycle_status, 'active', [StringComparison]::Ordinal)
        ) {
            $reason = 'unsupported-legacy-role'
        } elseif (
            -not [string]::Equals([string]$entry.ownership, 'template-managed', [StringComparison]::Ordinal) -or
            -not [string]::Equals([string]$entry.kind, 'file', [StringComparison]::Ordinal)
        ) {
            $reason = 'missing-or-untrusted-lineage'
        } elseif (
            -not [string]::Equals(
                [string]$entry.source,
                "template:$path",
                [StringComparison]::Ordinal
            )
        ) {
            $reason = 'source-locator-not-exact'
        } elseif (
            (
                -not (Get-NormalizedHash $entry.managed_hash) -or
                -not (Get-NormalizedHash $entry.observed_hash) -or
                -not (Get-NormalizedHash $entry.source_hash)
            )
        ) {
            $reason = 'missing-or-untrusted-lineage'
        } elseif (
            -not [string]::Equals(
                [string]$entry.source_hash,
                [string]$entry.managed_hash,
                [StringComparison]::Ordinal
            )
        ) {
            $reason = 'source-hash-not-baseline'
        }
        $currentSource = $null
        if (-not $reason) {
            $currentSource = Get-CurrentRepositorySourceEvidence -CatalogComponent $catalogComponent
            if (-not $currentSource.valid) {
                $reason = 'current-source-unavailable'
            }
        }
        if ($reason) {
            $manual += ,([ordered]@{ path = $path; reason = $reason })
            continue
        }
        $effectiveEntry = [ordered]@{}
        foreach ($key in $entry.Keys) {
            $effectiveEntry[$key] = $entry[$key]
        }
        $effectiveEntry['proposed_source_hash'] = $currentSource.hash
        if ($catalogComponent.kind -eq 'file') {
            $fresh = Get-FreshFileEvidence -Workspace $Workspace -RelativePath $path
            if (-not $fresh.valid) {
                $manual += ,([ordered]@{ path = $path; reason = 'current-file-missing-or-unreadable' })
                continue
            }
            $effectiveEntry['observed_hash'] = $fresh.hash
        }
        $eligible += ,([ordered]@{ entry = $effectiveEntry; catalog = $catalogComponent })
    }

    $eligibleIds = @{}
    foreach ($item in $eligible) {
        $eligibleIds[[string]$item.catalog.id] = $true
    }
    $components = @()
    foreach ($item in $eligible) {
        $missingParent = $false
        foreach ($parent in $item.catalog.generated_from) {
            if (-not $eligibleIds.ContainsKey([string]$parent)) {
                $missingParent = $true
            }
        }
        if ($missingParent) {
            $manual += ,([ordered]@{ path = $item.catalog.canonical_source_path; reason = 'generated-parent-not-migrated' })
            continue
        }
        $components += ,(New-ComponentRecord -Entry $item.entry -CatalogComponent $item.catalog -TransactionId $transactionId -CandidateTimestamp $candidateTimestamp)
    }
    $components = @($components | Sort-Object { $_.identity.id })
    $manual = @($manual | Sort-Object { "$($_.path)`0$($_.reason)" })
    $candidate = [ordered]@{
        schema_version = 3
        written_at = $candidateTimestamp
        source_release = [ordered]@{
            release_id = $Catalog.source_release.release_id
            source_ref = $Catalog.source_release.source_ref
            version = $Catalog.source_release.version
            component_catalog = [ordered]@{
                path = 'manifest/component-catalog.json'
                schema_version = $Catalog.catalog_schema_version
                sha256 = Get-Sha256 $CatalogBytes
            }
        }
        last_transaction = [ordered]@{
            id = $transactionId
            mode = 'migration'
            writer = 'powershell'
            started_at = $candidateTimestamp
            completed_at = $candidateTimestamp
            result = 'committed'
        }
        components = $components
    }
    return [ordered]@{ manifest = $candidate; manual_decisions = $manual }
}

function Assert-Candidate {
    param(
        [Parameter(Mandatory = $true)][byte[]]$CandidateBytes,
        [Parameter(Mandatory = $true)][Collections.IDictionary]$Catalog,
        [Parameter(Mandatory = $true)][byte[]]$CatalogBytes
    )

    $json = [Text.Encoding]::UTF8.GetString($CandidateBytes)
    if (
        $CandidateBytes.Length -eq 0 -or
        $CandidateBytes[$CandidateBytes.Length - 1] -ne 10 -or
        ($CandidateBytes.Length -ge 3 -and $CandidateBytes[0] -eq 0xef -and $CandidateBytes[1] -eq 0xbb -and $CandidateBytes[2] -eq 0xbf) -or
        $json.TrimEnd("`n").Contains("`r") -or
        $json.TrimEnd("`n").Contains("`n")
    ) {
        throw 'Candidate serialization is not canonical UTF-8/LF JSON.'
    }
    if (-not ($json | Test-Json -SchemaFile $script:SchemaPath)) {
        throw 'Candidate does not validate against the Production Schema.'
    }
    $candidate = $json | ConvertFrom-Json -AsHashtable
    $binding = $candidate.source_release.component_catalog
    if (
        $binding.path -ne 'manifest/component-catalog.json' -or
        $binding.schema_version -ne $Catalog.catalog_schema_version -or
        $binding.sha256 -ne (Get-Sha256 $CatalogBytes)
    ) {
        throw 'Candidate Component Catalog binding is invalid.'
    }
    if (
        $candidate.source_release.release_id -ne $Catalog.source_release.release_id -or
        $candidate.source_release.source_ref -ne $Catalog.source_release.source_ref -or
        $candidate.source_release.version -ne $Catalog.source_release.version
    ) {
        throw 'Candidate source release disagrees with the Component Catalog.'
    }
    $catalogById = @{}
    foreach ($component in $Catalog.components) {
        $catalogById[[string]$component.id] = $component
    }
    $previousId = ''
    $seen = @{}
    foreach ($component in $candidate.components) {
        $id = [string]$component.identity.id
        if ($seen.ContainsKey($id) -or ($previousId -and [string]::CompareOrdinal($previousId, $id) -gt 0)) {
            throw 'Candidate component IDs are not unique and sorted.'
        }
        $seen[$id] = $true
        $previousId = $id
        if (-not $catalogById.ContainsKey($id)) {
            throw "Candidate component is absent from the Component Catalog: $id"
        }
        $catalogComponent = $catalogById[$id]
        if (
            $component.identity.path -ne $catalogComponent.canonical_source_path -or
            $component.identity.kind -ne $catalogComponent.kind -or
            $component.identity.role -ne $catalogComponent.role -or
            (@($component.provenance.generated_from) -join "`0") -ne (@($catalogComponent.generated_from) -join "`0")
        ) {
            throw "Candidate component disagrees with the Component Catalog: $id"
        }
    }
}

function Write-Diagnostic {
    param(
        [Parameter(Mandatory = $true)][string]$Workspace,
        [Parameter(Mandatory = $true)][string]$Classification,
        [Parameter(Mandatory = $true)][string]$Message
    )

    if ($TestFailpoint -eq 'diagnostic-write') {
        throw 'Injected diagnostic write failure.'
    }
    $diagnostic = [ordered]@{
        classification = $Classification
        message = $Message
        rehearsal_only = $true
        no_real_adopter_operation = $true
        not_execution_authorization = $true
    }
    [IO.File]::WriteAllBytes(
        (Join-Path $Workspace $script:DiagnosticName),
        (ConvertTo-CanonicalBytes $diagnostic)
    )
}

$workspace = ''
$backupCreated = $false
$published = $false
$legacyBackupBytes = $null
$candidateBytes = $null
$temporaryPath = ''
try {
    if ($TestFailpoint -and $env:AI_WORKFLOW_PHASE4C_TEST_MODE -ne '1') {
        throw 'TestFailpoint is available only to the focused test harness.'
    }
    $source = Assert-SafeSourceFixture $SourceFixture
    $workspaceRoot = Assert-SafeWorkspaceParent $WorkspaceParent
    if (Test-PathsOverlap -First $source -Second $workspaceRoot) {
        throw 'SourceFixture and WorkspaceParent must not overlap.'
    }
    [IO.Directory]::CreateDirectory($workspaceRoot) | Out-Null
    Assert-NoReparsePoint -Path $workspaceRoot
    $workspace = New-RehearsalWorkspace -Parent $workspaceRoot -Source $source
    Copy-Fixture -Source $source -Workspace $workspace

    $manifestPath = Join-Path $workspace $script:ManifestName
    $classification = Get-ManifestClassification $manifestPath
    if ($classification.state -eq 'missing') {
        $result = New-BaseResult -Status 'report-only' -Classification 'missing' -Workspace $workspace
        Write-JsonResult -Value $result -ExitCode 0
    }
    if ($classification.state -notin @('valid-v1', 'valid-v2')) {
        $message = if ($classification.reason) {
            [string]$classification.reason
        } else {
            'Input manifest is not eligible for rehearsal.'
        }
        Write-Diagnostic -Workspace $workspace -Classification $classification.state -Message $message
        $result = New-BaseResult -Status 'blocked' -Classification $classification.state -Workspace $workspace
        if ($classification.reason) {
            $result.error = [string]$classification.reason
        }
        $result.diagnostic = $script:DiagnosticName
        Write-JsonResult -Value $result -ExitCode 2
    }

    $backupPath = Join-Path $workspace $script:BackupName
    $legacyBackupBytes = [IO.File]::ReadAllBytes($manifestPath)
    [IO.File]::WriteAllBytes($backupPath, $legacyBackupBytes)
    $backupCreated = $true

    if ($TestFailpoint -eq 'catalog-read') {
        throw 'Injected Catalog read failure.'
    }
    if ($TestFailpoint -eq 'diagnostic-write') {
        throw 'Injected failure before diagnostic persistence.'
    }
    $catalogBytes = [IO.File]::ReadAllBytes($script:CatalogPath)
    $catalog = [Text.Encoding]::UTF8.GetString($catalogBytes) | ConvertFrom-Json -AsHashtable
    if ($catalog.catalog_schema_version -ne 1 -or $catalog.components -isnot [array]) {
        throw 'Production Component Catalog is invalid.'
    }
    $conversion = New-V3Candidate -Legacy $classification.value -Catalog $catalog -CatalogBytes $catalogBytes -Workspace $workspace
    $candidateBytes = ConvertTo-CanonicalBytes $conversion.manifest
    Assert-Candidate -CandidateBytes $candidateBytes -Catalog $catalog -CatalogBytes $catalogBytes

    $temporaryPath = Join-Path $workspace ('.phase4c-' + [Guid]::NewGuid().ToString('N') + '.tmp')
    [IO.File]::WriteAllBytes($temporaryPath, $candidateBytes)
    if ($TestFailpoint -eq 'replace') {
        throw 'Injected replace failure.'
    }
    $stagedBytes = [IO.File]::ReadAllBytes($temporaryPath)
    if ($TestFailpoint -eq 'post-write-validation') {
        throw 'Injected staging validation failure.'
    }
    Assert-Candidate -CandidateBytes $stagedBytes -Catalog $catalog -CatalogBytes $catalogBytes
    if ([Convert]::ToHexString($stagedBytes) -ne [Convert]::ToHexString($candidateBytes)) {
        throw 'Staged candidate bytes changed during reopen validation.'
    }
    [IO.File]::Move($temporaryPath, $manifestPath, $true)
    if ($TestFailpoint -eq 'replace-uncertain') {
        throw 'Injected uncertain replacement failure.'
    }
    $published = $true
    $reopened = [IO.File]::ReadAllBytes($manifestPath)
    Assert-Candidate -CandidateBytes $reopened -Catalog $catalog -CatalogBytes $catalogBytes
    if ([Convert]::ToHexString($reopened) -ne [Convert]::ToHexString($candidateBytes)) {
        throw 'Published candidate bytes changed during reopen validation.'
    }

    $result = New-BaseResult -Status 'committed' -Classification $classification.state -Workspace $workspace
    $result.committed = $true
    $result.input_version = $classification.version
    $result.output_version = 3
    $result.backup = $script:BackupName
    $result.candidate_sha256 = Get-Sha256 $reopened
    $result.manual_decisions = $conversion.manual_decisions
    Write-JsonResult -Value $result -ExitCode 0
} catch {
    $message = $_.Exception.Message
    $stagingUncertain = $false
    if (-not $published -and $temporaryPath -and (Test-Path -LiteralPath $temporaryPath)) {
        try {
            $retainedStagingBytes = [IO.File]::ReadAllBytes($temporaryPath)
            if (
                $null -eq $candidateBytes -or
                [Convert]::ToHexString($retainedStagingBytes) -ne
                [Convert]::ToHexString($candidateBytes)
            ) {
                $stagingUncertain = $true
            } else {
                Remove-Item -LiteralPath $temporaryPath -Force
                if (Test-Path -LiteralPath $temporaryPath) {
                    $stagingUncertain = $true
                }
            }
        } catch {
            $stagingUncertain = $true
        }
    }
    $workspaceManifestProvenLegacy = $false
    if ($workspace -and $backupCreated) {
        try {
            $currentManifestBytes = [IO.File]::ReadAllBytes((Join-Path $workspace $script:ManifestName))
            $workspaceManifestProvenLegacy = (
                [Convert]::ToHexString($currentManifestBytes) -eq
                [Convert]::ToHexString($legacyBackupBytes)
            )
        } catch {
            $workspaceManifestProvenLegacy = $false
        }
    }
    $uncertain = (
        $published -or
        $stagingUncertain -or
        ($backupCreated -and -not $workspaceManifestProvenLegacy)
    )
    $classificationName = if (-not $workspace) {
        'unsafe-path'
    } elseif ($uncertain) {
        'post-write-failure'
    } else {
        'write-failure'
    }
    $diagnosticWritten = $false
    $diagnosticFailure = ''
    if ($workspace) {
        try {
            Write-Diagnostic -Workspace $workspace -Classification $classificationName -Message $message
            $diagnosticWritten = Test-Path -LiteralPath (Join-Path $workspace $script:DiagnosticName) -PathType Leaf
        } catch {
            $diagnosticFailure = $_.Exception.Message
        }
    }
    $status = if ($uncertain) { 'manual-recovery-required' } else { 'blocked' }
    $result = New-BaseResult -Status $status -Classification $classificationName -Workspace $workspace
    $result.error = $message
    if ($diagnosticWritten) {
        $result.diagnostic = $script:DiagnosticName
    }
    if ($diagnosticFailure) {
        $result.diagnostic_error = $diagnosticFailure
    }
    if ($backupCreated) {
        $result.backup = $script:BackupName
    }
    Write-JsonResult -Value $result -ExitCode 2
}
