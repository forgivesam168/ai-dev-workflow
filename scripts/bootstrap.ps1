#Requires -Version 7.0
# Bootstrap.ps1 - 跨平台 AI 工作流安裝器
# 用途：將 AI 開發工作流初始化到任何專案中

param(
    [switch]$Force,
    [switch]$Update,
    [switch]$Backup,
    [switch]$SkipHooks,   # 跳過 git init 步驟（參數名稱保留以向後相容）
    [switch]$Quiet,       # 抑制所有進度輸出（適合 CI 環境）
    [switch]$EnableMemory, # 建立 .ai-workflow-memory/ 骨架（opt-in 記憶功能）
    
    [Parameter(Mandatory=$false)]
    [string]$RemoteRepo = "https://github.com/forgivesam168/ai-dev-workflow.git",
    
    [Parameter(Mandatory=$false)]
    [string]$TargetPath = ""
)

# 全域變數
# Auto-detect RepoRoot: 腳本在 repo 根目錄時 $PSScriptRoot 即為 root；
# 在子目錄（如 scripts/）時向上一層取 parent。
$script:RepoRoot = if ($PSScriptRoot -and (Test-Path (Join-Path $PSScriptRoot ".github"))) {
    $PSScriptRoot                      # 腳本位於 repo 根目錄
} elseif ($PSScriptRoot) {
    Split-Path -Parent $PSScriptRoot   # 腳本位於子目錄（如 scripts/）
} else {
    (Get-Location).Path                # 互動模式 fallback
}
$script:IsRemoteMode = $false
$script:TempClonePath = ""
$script:PortableRuntimePaths = @(
    '.github',
    'skills',
    'agents',
    '.claude',
    '.codex',
    '.agent',
    '.agents',
    'AGENTS.md',
    'CLAUDE.md',
    'GEMINI.md',
    'WORKFLOW.md',
    'changes/_template',
    '.ai-workflow-install.json'
)
$script:LifecycleTemplateFiles = @(
    '00-intake.md',
    '01-brainstorm.md',
    '02-decision-log.md',
    '03-spec.md',
    '04-plan.md',
    '05-test-plan.md',
    '06-impact-analysis.md',
    '07-review.md',
    '99-archive.md'
)
$script:PortableBackupPaths = @($script:PortableRuntimePaths | Where-Object { $_ -ne '.github' })
$script:PortableSkillLinks = @(
    '.agents/skills',
    '.claude/skills',
    '.agent/skills'
)
$script:SupportedManifestSchemaVersions = @(1, 2)
$script:LegacyRuntimeExcludes = @(
    'workflows',
    'CODEOWNERS',
    'dependabot.yml',
    'skills',
    'agents'
)

# -Quiet 模式：在 script scope 覆寫 Write-Host，抑制所有進度輸出。
# Write-Error / Write-Warning 不受影響，錯誤訊息仍正常顯示。
if ($Quiet) {
    function script:Write-Host {
        param(
            [object]$Object,
            [switch]$NoNewline,
            [System.ConsoleColor]$ForegroundColor,
            [System.ConsoleColor]$BackgroundColor,
            [object[]]$Separator
        )
        # 靜音模式：捨棄所有標準進度輸出
    }
}

# ============================================================================
# 環境檢測函數
# ============================================================================

function Test-GitInstalled {
    <#
    .SYNOPSIS
    檢測 Git 是否已安裝且版本符合要求
    
    .DESCRIPTION
    檢查系統是否安裝 Git，版本是否 >= 2.0
    
    .OUTPUTS
    PSCustomObject with properties: Installed, Version, MeetsRequirement
    
    .EXAMPLE
    $git = Test-GitInstalled
    if ($git.Installed -and $git.MeetsRequirement) {
        Write-Host "✅ Git $($git.Version) detected"
    }
    #>
    
    try {
        # 執行 git --version
        $versionOutput = git --version 2>&1
        
        # 解析版本號（格式：git version 2.43.0.windows.1）
        if ($versionOutput -match 'git version (\d+\.\d+\.\d+)') {
            $versionString = $matches[1]
            $version = [version]$versionString
            $minVersion = [version]"2.0.0"
            $meetsRequirement = $version -ge $minVersion
            
            return [PSCustomObject]@{
                Installed = $true
                Version = $versionString
                MeetsRequirement = $meetsRequirement
            }
        } else {
            # 無法解析版本號
            return [PSCustomObject]@{
                Installed = $false
                Version = $null
                MeetsRequirement = $false
            }
        }
    } catch {
        # Git 未安裝或不在 PATH 中
        return [PSCustomObject]@{
            Installed = $false
            Version = $null
            MeetsRequirement = $false
        }
    }
}

function Test-PythonInstalled {
    <#
    .SYNOPSIS
    檢測 Python 是否已安裝且版本符合要求
    
    .DESCRIPTION
    檢查系統是否安裝 Python，版本是否 >= 3.7
    嘗試 python 和 python3 指令
    
    .OUTPUTS
    PSCustomObject with properties: Installed, Version, MeetsRequirement
    
    .EXAMPLE
    $python = Test-PythonInstalled
    if ($python.Installed) {
        Write-Host "✅ Python $($python.Version) detected"
    }
    #>
    
    # 嘗試 python 和 python3 指令
    $commands = @('python', 'python3')
    
    foreach ($cmd in $commands) {
        try {
            # 執行 python --version
            $versionOutput = & $cmd --version 2>&1
            
            # 解析版本號（格式：Python 3.11.5）
            if ($versionOutput -match 'Python (\d+\.\d+\.\d+)') {
                $versionString = $matches[1]
                $version = [version]$versionString
                $minVersion = [version]"3.7.0"
                $meetsRequirement = $version -ge $minVersion
                
                return [PSCustomObject]@{
                    Installed = $true
                    Version = $versionString
                    MeetsRequirement = $meetsRequirement
                }
            }
        } catch {
            # 繼續嘗試下一個指令
            continue
        }
    }
    
    # 所有指令都失敗
    return [PSCustomObject]@{
        Installed = $false
        Version = $null
        MeetsRequirement = $false
    }
}

function Test-PowerShellVersion {
    <#
    .SYNOPSIS
    檢測 PowerShell 版本是否符合要求
    
    .DESCRIPTION
    檢查 PowerShell 版本是否 >= 5.1（建議 7+）
    
    .OUTPUTS
    PSCustomObject with properties: Installed, Version, MeetsRequirement
    
    .EXAMPLE
    $ps = Test-PowerShellVersion
    if ($ps.MeetsRequirement) {
        Write-Host "✅ PowerShell $($ps.Version) detected"
    }
    #>
    
    # PowerShell 總是安裝（因為腳本正在執行）
    $currentVersion = $PSVersionTable.PSVersion
    
    # 格式化版本號字串（處理 Build 可能為 -1 或空值的情況）
    $build = if ($currentVersion.Build -ge 0) { $currentVersion.Build } else { 0 }
    $versionString = "$($currentVersion.Major).$($currentVersion.Minor).$build"
    
    # 最低要求版本 5.1
    $minVersion = [version]"5.1.0"
    $version = [version]$versionString
    $meetsRequirement = $version -ge $minVersion
    
    return [PSCustomObject]@{
        Installed = $true
        Version = $versionString
        MeetsRequirement = $meetsRequirement
    }
}

function Test-NodeJSInstalled {
    <#
    .SYNOPSIS
    檢測 Node.js 是否已安裝且版本符合要求
    
    .DESCRIPTION
    檢查系統是否安裝 Node.js，版本是否 >= 16.0（LTS）
    Node.js 為可選依賴，部分 Skills 需要
    
    .OUTPUTS
    PSCustomObject with properties: Installed, Version, MeetsRequirement
    
    .EXAMPLE
    $node = Test-NodeJSInstalled
    if ($node.Installed) {
        Write-Host "✅ Node.js $($node.Version) detected"
    }
    #>
    
    try {
        # 執行 node --version
        $versionOutput = node --version 2>&1
        
        # 解析版本號（格式：v18.17.0，注意有 v 前綴）
        if ($versionOutput -match 'v?(\d+\.\d+\.\d+)') {
            $versionString = $matches[1]
            $version = [version]$versionString
            $minVersion = [version]"16.0.0"
            $meetsRequirement = $version -ge $minVersion
            
            return [PSCustomObject]@{
                Installed = $true
                Version = $versionString
                MeetsRequirement = $meetsRequirement
            }
        }
    } catch {
        # Node.js 未安裝或執行失敗
    }
    
    # 未安裝或檢測失敗
    return [PSCustomObject]@{
        Installed = $false
        Version = $null
        MeetsRequirement = $false
    }
}

function Test-GitHubCLIInstalled {
    <#
    .SYNOPSIS
    檢測 GitHub CLI 是否已安裝且版本符合要求
    
    .DESCRIPTION
    透過 `gh --version` 取得版本，最低要求 2.0.0
    
    .OUTPUTS
    PSCustomObject with properties: Installed, Version, MeetsRequirement
    #>

    try {
        # 執行 gh --version（輸出為陣列，取第一行）
        $versionOutput = gh --version 2>&1
        
        # 處理陣列或字串
        $firstLine = if ($versionOutput -is [array]) { $versionOutput[0] } else { $versionOutput }
        
        # 解析版本號（格式：gh version 2.86.0 (2026-01-21)）
        if ($firstLine -match 'gh version (\d+\.\d+\.\d+)') {
            $versionString = $matches[1]
            $version = [version]$versionString
            $minVersion = [version]"2.0.0"
            $meetsRequirement = $version -ge $minVersion

            return [PSCustomObject]@{
                Installed = $true
                Version = $versionString
                MeetsRequirement = $meetsRequirement
            }
        }
    } catch {
        # GitHub CLI 未安裝或執行錯誤
    }

    return [PSCustomObject]@{
        Installed = $false
        Version = $null
        MeetsRequirement = $false
    }
}

# ============================================================================
# 遠端下載函數
# ============================================================================

function Get-RemoteTemplate {
    <#
    .SYNOPSIS
    從遠端 GitHub repo 下載模板到臨時目錄
    
    .PARAMETER RemoteRepo
    GitHub repo URL (e.g., https://github.com/user/repo.git)
    
    .OUTPUTS
    PSCustomObject with properties: Success, TempPath, Message
    
    .EXAMPLE
    $result = Get-RemoteTemplate -RemoteRepo "https://github.com/user/repo.git"
    if ($result.Success) {
        $templatePath = $result.TempPath
    }
    #>
    param(
        [Parameter(Mandatory=$true)]
        [string]$RemoteRepo
    )
    
    # 建立臨時目錄
    $timestamp = Get-Date -Format "yyyyMMdd-HHmmss"
    $tempPath = Join-Path ([System.IO.Path]::GetTempPath()) "ai-workflow-bootstrap-$timestamp"
    
    Write-Host "📥 從遠端下載模板..." -ForegroundColor Cyan
    Write-Host "   來源: $RemoteRepo" -ForegroundColor Gray
    Write-Host "   暫存: $tempPath" -ForegroundColor Gray
    Write-Host ""
    
    try {
        # 使用 shallow clone 加速下載（只下載最新版本）
        $cloneArgs = @(
            "clone",
            "--depth", "1",
            "--filter=blob:none",  # 不下載 blob，只下載樹結構（更快）
            "--no-checkout",        # 不自動 checkout
            $RemoteRepo,
            $tempPath
        )
        
        $cloneOutput = & git @cloneArgs 2>&1
        
        if ($LASTEXITCODE -ne 0) {
            throw "Git clone failed: $cloneOutput"
        }
        
        # Sparse checkout 下載相容層與 portable runtime 所需來源
        Push-Location $tempPath
        try {
            git sparse-checkout init --cone 2>&1 | Out-Null
            git sparse-checkout set .github agents skills docs .gitattributes .editorconfig 2>&1 | Out-Null
            git checkout 2>&1 | Out-Null
            
            if ($LASTEXITCODE -ne 0) {
                throw "Git sparse-checkout failed"
            }
        } finally {
            Pop-Location
        }
        
        Write-Host "✅ 遠端模板下載完成" -ForegroundColor Green
        Write-Host ""
        
        return [PSCustomObject]@{
            Success = $true
            TempPath = $tempPath
            Message = "Remote template downloaded successfully"
        }
        
    } catch {
        # 清理失敗的臨時目錄
        if (Test-Path $tempPath) {
            Remove-Item -Path $tempPath -Recurse -Force -ErrorAction SilentlyContinue
        }
        
        return [PSCustomObject]@{
            Success = $false
            TempPath = $null
            Message = "Failed to download remote template: $($_.Exception.Message)"
        }
    }
}

function Remove-TempDirectory {
    <#
    .SYNOPSIS
    清理臨時目錄
    
    .PARAMETER Path
    臨時目錄路徑
    #>
    param(
        [Parameter(Mandatory=$true)]
        [string]$Path
    )
    
    if (Test-Path $Path) {
        try {
            Write-Host "🧹 清理臨時目錄..." -ForegroundColor Gray
            Remove-Item -Path $Path -Recurse -Force -ErrorAction Stop
            Write-Host "✅ 臨時目錄已清理" -ForegroundColor Green
        } catch {
            Write-Host "⚠️  無法清理臨時目錄: $Path" -ForegroundColor Yellow
            Write-Host "   請手動刪除: $Path" -ForegroundColor Gray
        }
    }
}

# ============================================================================
# 檔案同步函數
# ============================================================================

function Sync-WorkflowFiles {
    <#
    .SYNOPSIS
    同步 .github/ 工作流檔案到目標專案
    
    .DESCRIPTION
    將模板 repo 的 .github/ 內容複製到目標專案，並保留現有 CI/CD
    
    .PARAMETER SourcePath
    源 .github/ 路徑
    
    .PARAMETER TargetPath
    目標專案根目錄
    
    .PARAMETER ConstitutionSourceRoot
    Template repository root containing docs/copilot-instructions.template.md.

    .PARAMETER Force
    強制覆蓋現有檔案
    
    .PARAMETER Backup
    在同步前備份現有 .github 目錄
    
    .OUTPUTS
    PSCustomObject with properties: FilesAdded, FilesUpdated, FilesSkipped, FilesConflicted
    
    .EXAMPLE
    $result = Sync-WorkflowFiles -SourcePath ".\.github" -TargetPath "C:\Projects\MyApp" -ConstitutionSourceRoot "."
    #>
    
    param(
        [Parameter(Mandatory=$true)]
        [string]$SourcePath,
        
        [Parameter(Mandatory=$true)]
        [string]$TargetPath,

        [Parameter(Mandatory=$true)]
        [hashtable]$ManifestEntries,

        [string]$ConstitutionSourceRoot,
        
        [switch]$Force,
        
        [switch]$Backup
    )

    # 確保源目錄存在
    if (-not (Test-Path $SourcePath)) {
        throw "Source path not found: $SourcePath"
    }

    # 建立目標 .github 目錄
    $targetGithubPath = Join-Path $TargetPath ".github"
    
    # 如果需要備份且目標存在
    if ($Backup -and (Test-Path $targetGithubPath)) {
        $backupResult = Backup-Directory -SourcePath $targetGithubPath
        if ($backupResult.Success) {
            Write-Host "✅ $($backupResult.Message)" -ForegroundColor Green
        } else {
            Write-Host "⚠️  $($backupResult.Message)" -ForegroundColor Yellow
        }
    }
    
    if (-not (Test-Path $targetGithubPath)) {
        New-Item -ItemType Directory -Path $targetGithubPath -Force | Out-Null
    }

    $legacyExcludes = @($script:LegacyRuntimeExcludes) + @('copilot-instructions.md')

    $result = Sync-DirectoryWithPolicy `
        -SourcePath $SourcePath `
        -TargetPath $TargetPath `
        -BaseRelative '.github' `
        -ManifestEntries $ManifestEntries `
        -Ownership 'legacy-compat' `
        -SourceLabelPrefix 'template:.github' `
        -Force:$Force `
        -ExcludePatterns $legacyExcludes

    if ($ConstitutionSourceRoot) {
        $constitutionResult = Install-AdopterConstitution `
            -SourceRoot $ConstitutionSourceRoot `
            -TargetPath $TargetPath `
            -ManifestEntries $ManifestEntries
        $result.FilesSkipped = @($result.FilesSkipped | Where-Object { $_ -ne '.github/copilot-instructions.md' })
        $result = Merge-SyncResults $result $constitutionResult
    }

    # Copy root-level template files (e.g. .gitattributes, .editorconfig) into target project root
    $rootFiles = @('.gitattributes', '.editorconfig')
    foreach ($rf in $rootFiles) {
        $srcRootFile = Join-Path $script:RepoRoot $rf
        if (Test-Path $srcRootFile) {
            $bytes = [System.IO.File]::ReadAllBytes($srcRootFile)
            Set-ManagedBytes `
                -Path (Join-Path $TargetPath $rf) `
                -RelativePath $rf `
                -Bytes $bytes `
                -Result $result `
                -ManifestEntries $ManifestEntries `
                -Ownership 'legacy-compat' `
                -SourceLabel "template:$rf" `
                -Force:$Force
        }
    }

    return $result
}

function Initialize-GitRepo {
    <#
    .SYNOPSIS
    初始化 Git repository
    
    .DESCRIPTION
    檢測目標目錄是否已有 .git，如果沒有則執行 git init
    
    .PARAMETER TargetPath
    目標專案目錄
    
    .OUTPUTS
    PSCustomObject with properties: IsNew, GitDir, Message
    
    .EXAMPLE
    $result = Initialize-GitRepo -TargetPath "C:\Projects\MyApp"
    if ($result.IsNew) {
        Write-Host "Git repository initialized"
    }
    #>
    
    param(
        [Parameter(Mandatory=$true)]
        [string]$TargetPath
    )
    
    # 檢查 .git 目錄
    $gitDir = Join-Path $TargetPath ".git"
    
    if (Test-Path $gitDir) {
        # Git repo 已存在
        return [PSCustomObject]@{
            IsNew = $false
            GitDir = $gitDir
            Message = "Git repository already exists"
        }
    }
    
    # 執行 git init
    try {
        Push-Location $TargetPath
        
        # 嘗試 -b main 指定預設分支（需 git >= 2.28）；舊版以 symbolic-ref 回退
        $initOutput = git init -b main 2>&1
        if ($LASTEXITCODE -ne 0) {
            $initOutput = git init 2>&1
            git symbolic-ref HEAD refs/heads/main 2>&1 | Out-Null
        }
        
        Pop-Location
        
        # 驗證 .git 目錄是否建立成功
        if (Test-Path $gitDir) {
            return [PSCustomObject]@{
                IsNew = $true
                GitDir = $gitDir
                Message = "Git repository initialized successfully"
            }
        } else {
            throw "git init executed but .git directory not found"
        }
        
    } catch {
        Pop-Location
        throw "Failed to initialize Git repository: $($_.Exception.Message)"
    }
}

function Get-FileHash256 {
    <#
    .SYNOPSIS
    計算檔案的 SHA256 雜湊值
    
    .PARAMETER Path
    檔案路徑
    
    .OUTPUTS
    String - SHA256 雜湊值
    #>
    param(
        [Parameter(Mandatory=$true)]
        [string]$Path
    )
    
    if (-not (Test-Path $Path)) {
        return $null
    }
    
    $hash = Get-FileHash -Path $Path -Algorithm SHA256
    return $hash.Hash
}

function Test-FilesIdentical {
    <#
    .SYNOPSIS
    檢查兩個檔案內容是否相同
    
    .PARAMETER Path1
    第一個檔案路徑
    
    .PARAMETER Path2
    第二個檔案路徑
    
    .OUTPUTS
    Boolean - 檔案內容相同則回傳 $true
    #>
    param(
        [Parameter(Mandatory=$true)]
        [string]$Path1,
        
        [Parameter(Mandatory=$true)]
        [string]$Path2
    )
    
    if (-not (Test-Path $Path1) -or -not (Test-Path $Path2)) {
        return $false
    }
    
    $hash1 = Get-FileHash256 -Path $Path1
    $hash2 = Get-FileHash256 -Path $Path2
    
    return $hash1 -eq $hash2
}

function Backup-Directory {
    <#
    .SYNOPSIS
    備份目錄到時間戳命名的備份目錄
    
    .PARAMETER SourcePath
    要備份的來源目錄
    
    .PARAMETER BackupName
    備份目錄名稱（可選，預設為 <原目錄名>.backup-<時間戳>）
    
    .OUTPUTS
    PSCustomObject with properties: Success, BackupPath, Message
    #>
    param(
        [Parameter(Mandatory=$true)]
        [string]$SourcePath,
        
        [Parameter(Mandatory=$false)]
        [string]$BackupName
    )
    
    if (-not (Test-Path $SourcePath)) {
        return [PSCustomObject]@{
            Success = $false
            BackupPath = $null
            Message = "Source directory not found: $SourcePath"
        }
    }
    
    # 產生備份名稱
    if (-not $BackupName) {
        $timestamp = Get-Date -Format "yyyyMMdd-HHmmss"
        $sourceName = Split-Path $SourcePath -Leaf
        $BackupName = "$sourceName.backup-$timestamp"
    }
    
    $parentPath = Split-Path $SourcePath -Parent
    $backupPath = Join-Path $parentPath $BackupName
    
    # 檢查備份目錄是否已存在
    if (Test-Path $backupPath) {
        return [PSCustomObject]@{
            Success = $false
            BackupPath = $null
            Message = "Backup already exists: $backupPath"
        }
    }
    
    try {
        Copy-Item -Path $SourcePath -Destination $backupPath -Recurse -Force
        
        return [PSCustomObject]@{
            Success = $true
            BackupPath = $backupPath
            Message = "Backup created: $backupPath"
        }
    } catch {
        return [PSCustomObject]@{
            Success = $false
            BackupPath = $null
            Message = "Backup failed: $($_.Exception.Message)"
        }
    }
}

function Backup-ManagedPaths {
    param(
        [Parameter(Mandatory = $true)]
        [string]$TargetPath,
        [string[]]$RelativePaths,
        [string]$BackupPrefix = '.ai-workflow-portable'
    )

    $existingPaths = @()
    foreach ($relativePath in $RelativePaths) {
        $fullPath = Join-Path $TargetPath $relativePath
        if (Test-Path $fullPath) {
            $existingPaths += [PSCustomObject]@{
                RelativePath = $relativePath
                FullPath = $fullPath
            }
        }
    }

    if ($existingPaths.Count -eq 0) {
        return [PSCustomObject]@{
            Success = $true
            BackupPath = $null
            Message = 'No portable runtime paths to backup'
        }
    }

    $timestamp = Get-Date -Format 'yyyyMMdd-HHmmss'
    $backupRoot = Join-Path $TargetPath "$BackupPrefix.backup-$timestamp"

    if (Test-Path $backupRoot) {
        return [PSCustomObject]@{
            Success = $false
            BackupPath = $null
            Message = "Backup already exists: $backupRoot"
        }
    }

    try {
        New-Item -ItemType Directory -Path $backupRoot -Force | Out-Null

        foreach ($item in $existingPaths) {
            $destination = Join-Path $backupRoot $item.RelativePath
            $destinationParent = Split-Path $destination -Parent
            if ($destinationParent -and -not (Test-Path $destinationParent)) {
                New-Item -ItemType Directory -Path $destinationParent -Force | Out-Null
            }

            if (Test-Path $item.FullPath -PathType Container) {
                Copy-Item -LiteralPath $item.FullPath -Destination $destination -Recurse -Force
            } else {
                Copy-Item -LiteralPath $item.FullPath -Destination $destination -Force
            }
        }

        return [PSCustomObject]@{
            Success = $true
            BackupPath = $backupRoot
            Message = "Backup created: $backupRoot"
        }
    } catch {
        return [PSCustomObject]@{
            Success = $false
            BackupPath = $null
            Message = "Backup failed: $($_.Exception.Message)"
        }
    }
}

function Test-GitUncommittedChanges {
    <#
    .SYNOPSIS
    檢查目錄是否有未提交的 Git 變更
    
    .PARAMETER TargetPath
    專案根目錄
    
    .PARAMETER Directory
    要檢查的子目錄（預設為 .github）
    
    .OUTPUTS
    Boolean - 有未提交變更則回傳 $true
    #>
    param(
        [Parameter(Mandatory=$true)]
        [string]$TargetPath,
        
        [Parameter(Mandatory=$false)]
        [string]$Directory = ".github"
    )
    
    try {
        Push-Location $TargetPath
        
        $status = git status --porcelain $Directory 2>&1
        
        Pop-Location
        
        # 如果輸出不為空，表示有未提交變更
        return -not [string]::IsNullOrWhiteSpace($status)
        
    } catch {
        Pop-Location
        return $false
    }
}

function Write-EnvironmentCheck {
    <#
    .SYNOPSIS
    輸出環境檢測結果（格式化）
    
    .PARAMETER Name
    工具名稱
    
    .PARAMETER Result
    檢測結果物件
    
    .PARAMETER InstallUrl
    安裝連結（可選）
    #>
    param(
        [string]$Name,
        [PSCustomObject]$Result,
        [string]$InstallUrl = "",
        [string]$MinVersion = "2.0"
    )
    
    if ($Result.Installed) {
        if ($Result.MeetsRequirement) {
            Write-Host "✅ $Name $($Result.Version) detected" -ForegroundColor Green
        } else {
            Write-Host "⚠️  $Name $($Result.Version) (建議升級到 >= $MinVersion)" -ForegroundColor Yellow
            if ($InstallUrl) {
                Write-Host "   Install: $InstallUrl" -ForegroundColor Gray
            }
        }
    } else {
        Write-Host "❌ $Name 未安裝" -ForegroundColor Red
        if ($InstallUrl) {
            Write-Host "   請安裝: $InstallUrl" -ForegroundColor Yellow
        }
    }
}

function New-SyncResult {
    return [PSCustomObject]@{
        FilesAdded = @()
        FilesUpdated = @()
        FilesSkipped = @()
        FilesConflicted = @()
    }
}

function Merge-SyncResults {
    param(
        [Parameter(ValueFromRemainingArguments = $true)]
        [object[]]$Results
    )

    $merged = New-SyncResult
    foreach ($result in $Results) {
        if (-not $result) { continue }
        $merged.FilesAdded += @($result.FilesAdded)
        $merged.FilesUpdated += @($result.FilesUpdated)
        $merged.FilesSkipped += @($result.FilesSkipped)
        $merged.FilesConflicted += @($result.FilesConflicted)
    }
    return $merged
}

function Add-SyncRecord {
    param(
        [Parameter(Mandatory = $true)]
        [pscustomobject]$Result,
        [Parameter(Mandatory = $true)]
        [ValidateSet('added', 'updated', 'skipped', 'conflicted')]
        [string]$Status,
        [Parameter(Mandatory = $true)]
        [string]$Path,
        [string]$Suffix = ''
    )

    $normalized = $Path -replace '\\', '/'
    if ($Suffix) {
        $normalized = "$normalized $Suffix"
    }

    switch ($Status) {
        'added'      { $Result.FilesAdded += $normalized }
        'updated'    { $Result.FilesUpdated += $normalized }
        'skipped'    { $Result.FilesSkipped += $normalized }
        'conflicted' { $Result.FilesConflicted += $normalized }
    }
}

function Normalize-RelativePath {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Path
    )

    # Representation normalization only; this is not a path traversal sanitizer.
    $normalized = $Path -replace '\\', '/'
    while ($normalized.StartsWith('./', [StringComparison]::Ordinal)) {
        $normalized = $normalized.Substring(2)
    }

    return $normalized
}

function Test-ShouldExcludeRelative {
    param(
        [Parameter(Mandatory = $true)]
        [string]$RelativePath,
        [string[]]$ExcludePatterns = @()
    )

    $normalized = (Normalize-RelativePath $RelativePath).ToLowerInvariant()
    $parts = $normalized -split '/'

    foreach ($pattern in $ExcludePatterns) {
        $candidate = (Normalize-RelativePath $pattern).ToLowerInvariant().Trim('/')
        if ($candidate.Contains('/')) {
            if ($normalized.StartsWith($candidate)) {
                return $true
            }
            continue
        }

        if ($candidate -in @('codeowners', 'dependabot.yml')) {
            if ($parts[-1] -eq $candidate) {
                return $true
            }
            continue
        }

        if ($parts -contains $candidate) {
            return $true
        }
    }

    return $false
}

function Normalize-TextContent {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Content
    )

    if ($Content.EndsWith("`n")) {
        return $Content
    }
    return "$Content`n"
}

function Get-BytesHash {
    param(
        [Parameter(Mandatory = $true)]
        [byte[]]$Bytes
    )

    $sha256 = [System.Security.Cryptography.SHA256]::Create()
    try {
        $hashBytes = $sha256.ComputeHash($Bytes)
        return "sha256:$([Convert]::ToHexString($hashBytes).ToLowerInvariant())"
    } finally {
        $sha256.Dispose()
    }
}

function Get-PathHash {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Path
    )

    if (-not (Test-Path $Path) -or (Test-Path $Path -PathType Container)) {
        return $null
    }

    $hash = Get-FileHash256 -Path $Path
    if (-not $hash) {
        return $null
    }

    return "sha256:$($hash.ToLowerInvariant())"
}

function Get-InstallManifest {
    param(
        [Parameter(Mandatory = $true)]
        [string]$TargetPath
    )

    $manifestPath = Join-Path $TargetPath '.ai-workflow-install.json'
    $entries = @{}

    if (-not (Test-Path $manifestPath)) {
        return [PSCustomObject]@{
            State         = 'missing'
            Entries       = $entries
            SchemaVersion = $null
            Detail        = $null
            ManifestPath  = $manifestPath
        }
    }

    try {
        $manifest = Get-Content -Raw $manifestPath | ConvertFrom-Json -AsHashtable
    } catch {
        return [PSCustomObject]@{
            State         = 'corrupt'
            Entries       = $entries
            SchemaVersion = $null
            Detail        = 'Manifest could not be read or parsed as JSON.'
            ManifestPath  = $manifestPath
        }
    }

    if ($manifest -isnot [System.Collections.IDictionary]) {
        return [PSCustomObject]@{
            State         = 'corrupt'
            Entries       = $entries
            SchemaVersion = $null
            Detail        = 'Manifest top level must be an object.'
            ManifestPath  = $manifestPath
        }
    }

    $schemaVersion = if ($manifest.Contains('schema_version')) { $manifest['schema_version'] } else { $null }
    $integerTypes = @([byte], [sbyte], [int16], [uint16], [int32], [uint32], [int64], [uint64])
    if ($null -eq $schemaVersion -or $integerTypes -notcontains $schemaVersion.GetType()) {
        return [PSCustomObject]@{
            State         = 'corrupt'
            Entries       = $entries
            SchemaVersion = $null
            Detail        = 'Manifest schema_version must be an integer.'
            ManifestPath  = $manifestPath
        }
    }

    if ($script:SupportedManifestSchemaVersions -notcontains $schemaVersion) {
        return [PSCustomObject]@{
            State         = 'unsupported'
            Entries       = $entries
            SchemaVersion = $schemaVersion
            Detail        = "Schema version $schemaVersion is not supported."
            ManifestPath  = $manifestPath
        }
    }

    $components = $null
    if ($manifest.Contains('components')) {
        $components = $manifest['components']
    }
    if ($components -isnot [System.Array]) {
        return [PSCustomObject]@{
            State         = 'corrupt'
            Entries       = $entries
            SchemaVersion = $schemaVersion
            Detail        = 'Manifest components must be an array.'
            ManifestPath  = $manifestPath
        }
    }

    $componentNames = [Collections.Generic.HashSet[string]]::new([StringComparer]::Ordinal)
    foreach ($component in $components) {
        if ($component -isnot [System.Collections.IDictionary]) {
            return [PSCustomObject]@{
                State         = 'corrupt'
                Entries       = @{}
                SchemaVersion = $schemaVersion
                Detail        = 'Every manifest component must be an object.'
                ManifestPath  = $manifestPath
            }
        }
        $name = if ($component.Contains('name')) { $component['name'] } else { $null }
        if ($name -isnot [string] -or [string]::IsNullOrWhiteSpace($name)) {
            return [PSCustomObject]@{
                State         = 'corrupt'
                Entries       = @{}
                SchemaVersion = $schemaVersion
                Detail        = 'Every manifest component must have a non-empty string name.'
                ManifestPath  = $manifestPath
            }
        }
        if (-not $componentNames.Add($name)) {
            return [PSCustomObject]@{
                State         = 'corrupt'
                Entries       = @{}
                SchemaVersion = $schemaVersion
                Detail        = "Manifest contains duplicate component name: $name"
                ManifestPath  = $manifestPath
            }
        }
        $entries[$name] = $component
    }

    return [PSCustomObject]@{
        State         = 'valid'
        Entries       = $entries
        SchemaVersion = $schemaVersion
        Detail        = $null
        ManifestPath  = $manifestPath
    }
}

function Set-ManifestEntry {
    param(
        [Parameter(Mandatory = $true)]
        [hashtable]$ManifestEntries,
        [Parameter(Mandatory = $true)]
        [string]$RelativePath,
        [Parameter(Mandatory = $true)]
        [string]$Ownership,
        [Parameter(Mandatory = $true)]
        [string]$SourceLabel,
        [Parameter(Mandatory = $true)]
        [string]$Kind,
        [string]$ManagedHash,
        [string]$ObservedHash,
        [Parameter(Mandatory = $true)]
        [string]$Status
    )

    $normalized = Normalize-RelativePath $RelativePath
    $previous = if ($ManifestEntries.ContainsKey($normalized)) { $ManifestEntries[$normalized] } else { $null }
    $installedAt = if ($previous -and $previous.installed_at) { $previous.installed_at } else { (Get-Date).ToString('o') }

    $ManifestEntries[$normalized] = [ordered]@{
        name         = $normalized
        installed_at = $installedAt
        updated_at   = (Get-Date).ToString('o')
        source_hash  = $ManagedHash
        managed_hash = $ManagedHash
        observed_hash = $ObservedHash
        ownership    = $Ownership
        kind         = $Kind
        source       = $SourceLabel
        status       = $Status
    }
}

function Write-InstallManifest {
    param(
        [Parameter(Mandatory = $true)]
        [string]$TargetPath,
        [Parameter(Mandatory = $true)]
        [string]$SourceRoot,
        [Parameter(Mandatory = $true)]
        [hashtable]$ManifestEntries
    )

    $sourceRef = (& git -C $SourceRoot rev-parse --short HEAD 2>$null)
    if (-not $sourceRef) {
        $sourceRef = 'unknown'
    }

    $components = foreach ($name in ($ManifestEntries.Keys | Sort-Object)) {
        $ManifestEntries[$name]
    }

    $manifest = [ordered]@{
        schema_version = 2
        installed_at   = (Get-Date).ToString('o')
        source_ref     = $sourceRef
        components     = @($components)
    }

    $manifestPath = Join-Path $TargetPath '.ai-workflow-install.json'
    $manifest | ConvertTo-Json -Depth 6 | Set-Content -Path $manifestPath -Encoding UTF8
}

function Set-ManagedBytes {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Path,
        [Parameter(Mandatory = $true)]
        [string]$RelativePath,
        [Parameter(Mandatory = $true)]
        [byte[]]$Bytes,
        [Parameter(Mandatory = $true)]
        [pscustomobject]$Result,
        [Parameter(Mandatory = $true)]
        [hashtable]$ManifestEntries,
        [Parameter(Mandatory = $true)]
        [string]$Ownership,
        [Parameter(Mandatory = $true)]
        [string]$SourceLabel,
        [switch]$Force,
        [switch]$AlwaysOverwrite,
        [bool]$PreserveUntracked = $true
    )

    $normalizedRelative = Normalize-RelativePath $RelativePath
    $previous = if ($ManifestEntries.ContainsKey($normalizedRelative)) { $ManifestEntries[$normalizedRelative] } else { $null }
    $previousManagedHash = if ($previous) {
        if ($previous.managed_hash) { $previous.managed_hash } else { $previous.source_hash }
    } else {
        $null
    }
    $currentHash = if (Test-Path $Path -PathType Leaf) { Get-PathHash -Path $Path } else { $null }
    $desiredHash = Get-BytesHash -Bytes $Bytes

    if (-not (Test-Path $Path -PathType Leaf)) {
        $parent = Split-Path $Path -Parent
        if ($parent -and -not (Test-Path $parent)) {
            New-Item -ItemType Directory -Path $parent -Force | Out-Null
        }
        [System.IO.File]::WriteAllBytes($Path, $Bytes)
        Add-SyncRecord -Result $Result -Status 'added' -Path $normalizedRelative
        Set-ManifestEntry -ManifestEntries $ManifestEntries -RelativePath $normalizedRelative -Ownership $Ownership -SourceLabel $SourceLabel -Kind 'file' -ManagedHash $desiredHash -ObservedHash $desiredHash -Status 'managed'
        return
    }

    if ($currentHash -eq $desiredHash) {
        Add-SyncRecord -Result $Result -Status 'skipped' -Path $normalizedRelative
        Set-ManifestEntry -ManifestEntries $ManifestEntries -RelativePath $normalizedRelative -Ownership $Ownership -SourceLabel $SourceLabel -Kind 'file' -ManagedHash $desiredHash -ObservedHash $desiredHash -Status 'in-sync'
        return
    }

    if ($AlwaysOverwrite -or $Force -or ($previousManagedHash -and $currentHash -eq $previousManagedHash)) {
        $parent = Split-Path $Path -Parent
        if ($parent -and -not (Test-Path $parent)) {
            New-Item -ItemType Directory -Path $parent -Force | Out-Null
        }
        [System.IO.File]::WriteAllBytes($Path, $Bytes)
        Add-SyncRecord -Result $Result -Status 'updated' -Path $normalizedRelative
        Set-ManifestEntry -ManifestEntries $ManifestEntries -RelativePath $normalizedRelative -Ownership $Ownership -SourceLabel $SourceLabel -Kind 'file' -ManagedHash $desiredHash -ObservedHash $desiredHash -Status 'managed'
        return
    }

    if ($PreserveUntracked) {
        $suffix = if ($previousManagedHash) { '[preserved customization]' } else { '[preserved existing]' }
        $manifestStatus = if ($previousManagedHash) { 'preserved-customization' } else { 'preserved-existing' }
        Add-SyncRecord -Result $Result -Status 'skipped' -Path $normalizedRelative -Suffix $suffix
        Set-ManifestEntry -ManifestEntries $ManifestEntries -RelativePath $normalizedRelative -Ownership $Ownership -SourceLabel $SourceLabel -Kind 'file' -ManagedHash $previousManagedHash -ObservedHash $currentHash -Status $manifestStatus
        return
    }

    Add-SyncRecord -Result $Result -Status 'conflicted' -Path $normalizedRelative
    Set-ManifestEntry -ManifestEntries $ManifestEntries -RelativePath $normalizedRelative -Ownership $Ownership -SourceLabel $SourceLabel -Kind 'file' -ManagedHash $previousManagedHash -ObservedHash $currentHash -Status 'conflicted'
}

function Install-AdopterConstitution {
    param(
        [Parameter(Mandatory = $true)]
        [string]$SourceRoot,
        [Parameter(Mandatory = $true)]
        [string]$TargetPath,
        [Parameter(Mandatory = $true)]
        [hashtable]$ManifestEntries
    )

    $relativePath = '.github/copilot-instructions.md'
    $sourceRelative = 'docs/copilot-instructions.template.md'
    $sourcePath = Join-Path $SourceRoot $sourceRelative
    $destinationPath = Join-Path $TargetPath $relativePath
    $result = New-SyncResult

    if (-not (Test-Path $sourcePath -PathType Leaf)) {
        throw "Source path not found: $sourcePath"
    }

    Write-Host "ℹ️  Constitution source: $sourceRelative" -ForegroundColor Cyan

    if (Test-Path $destinationPath) {
        # Phase 0A cannot prove manifest trust state, so every existing
        # constitution requires an explicit adoption decision.
        $previous = if ($ManifestEntries.ContainsKey($relativePath)) { $ManifestEntries[$relativePath] } else { $null }
        $previousManagedHash = if ($previous) {
            if ($previous.managed_hash) { $previous.managed_hash } else { $previous.source_hash }
        } else {
            $null
        }
        $previousSource = if ($previous) { $previous.source } else { $null }
        $currentHash = if (Test-Path $destinationPath -PathType Leaf) { Get-PathHash -Path $destinationPath } else { $null }

        $preservationClass = if (-not $previousManagedHash -or -not $previousSource -or $previousSource -eq 'unknown') {
            'legacy/unknown'
        } elseif ($currentHash -ne $previousManagedHash) {
            'customization'
        } else {
            'existing-unproven'
        }

        Add-SyncRecord `
            -Result $result `
            -Status 'skipped' `
            -Path $relativePath `
            -Suffix "[preserved $preservationClass; manual decision required]"
        Write-Host '⚠️  Constitution outcome: preserved; manual decision required' -ForegroundColor Yellow
        return $result
    }

    $bytes = [IO.File]::ReadAllBytes($sourcePath)
    Set-ManagedBytes `
        -Path $destinationPath `
        -RelativePath $relativePath `
        -Bytes $bytes `
        -Result $result `
        -ManifestEntries $ManifestEntries `
        -Ownership 'template-managed' `
        -SourceLabel 'template:docs/copilot-instructions.template.md'
    Write-Host '✅ Constitution outcome: installed' -ForegroundColor Green
    return $result
}

function Install-LifecycleAsset {
    param(
        [Parameter(Mandatory = $true)]
        [string]$SourcePath,
        [Parameter(Mandatory = $true)]
        [string]$TargetPath,
        [Parameter(Mandatory = $true)]
        [string]$RelativePath,
        [Parameter(Mandatory = $true)]
        [string]$SourceLabel,
        [Parameter(Mandatory = $true)]
        [hashtable]$ManifestEntries
    )

    if (-not (Test-Path -LiteralPath $SourcePath -PathType Leaf)) {
        throw "Source path not found: $SourcePath"
    }

    $result = New-SyncResult
    $normalized = Normalize-RelativePath $RelativePath
    $destination = Join-Path $TargetPath $normalized
    $previous = if ($ManifestEntries.ContainsKey($normalized)) { $ManifestEntries[$normalized] } else { $null }

    if (-not (Test-Path -LiteralPath $destination -PathType Leaf)) {
        Set-ManagedBytes `
            -Path $destination `
            -RelativePath $normalized `
            -Bytes ([IO.File]::ReadAllBytes($SourcePath)) `
            -Result $result `
            -ManifestEntries $ManifestEntries `
            -Ownership 'template-managed' `
            -SourceLabel $SourceLabel
        return $result
    }

    $previousManagedHash = if ($previous) {
        if ($previous.managed_hash) { $previous.managed_hash } else { $previous.source_hash }
    } else { $null }
    $validPrevious = $previous -and `
        $previous.ownership -eq 'template-managed' -and `
        $previous.source -eq $SourceLabel -and `
        -not [string]::IsNullOrWhiteSpace([string]$previousManagedHash)
    $currentHash = Get-PathHash -Path $destination

    if ($validPrevious -and $currentHash -eq $previousManagedHash) {
        Set-ManagedBytes `
            -Path $destination `
            -RelativePath $normalized `
            -Bytes ([IO.File]::ReadAllBytes($SourcePath)) `
            -Result $result `
            -ManifestEntries $ManifestEntries `
            -Ownership 'template-managed' `
            -SourceLabel $SourceLabel
        return $result
    }

    if ($validPrevious) {
        Add-SyncRecord -Result $result -Status 'skipped' -Path $normalized -Suffix '[preserved customization]'
        Set-ManifestEntry `
            -ManifestEntries $ManifestEntries `
            -RelativePath $normalized `
            -Ownership 'template-managed' `
            -SourceLabel $SourceLabel `
            -Kind 'file' `
            -ManagedHash $previousManagedHash `
            -ObservedHash $currentHash `
            -Status 'preserved-customization'
        return $result
    }

    Add-SyncRecord -Result $result -Status 'skipped' -Path $normalized -Suffix '[preserved existing; manual decision required]'
    return $result
}

function Install-LifecycleAssets {
    param(
        [Parameter(Mandatory = $true)]
        [string]$SourceRoot,
        [Parameter(Mandatory = $true)]
        [string]$TargetPath,
        [Parameter(Mandatory = $true)]
        [hashtable]$ManifestEntries
    )

    $result = Install-LifecycleAsset `
        -SourcePath (Join-Path $SourceRoot 'docs/WORKFLOW.template.md') `
        -TargetPath $TargetPath `
        -RelativePath 'WORKFLOW.md' `
        -SourceLabel 'template:docs/WORKFLOW.template.md' `
        -ManifestEntries $ManifestEntries
    foreach ($name in $script:LifecycleTemplateFiles) {
        $relative = "changes/_template/$name"
        $result = Merge-SyncResults `
            $result `
            (Install-LifecycleAsset `
                -SourcePath (Join-Path $SourceRoot $relative) `
                -TargetPath $TargetPath `
                -RelativePath $relative `
                -SourceLabel "template:$relative" `
                -ManifestEntries $ManifestEntries)
    }
    return $result
}

function Sync-DirectoryWithPolicy {
    param(
        [Parameter(Mandatory = $true)]
        [string]$SourcePath,
        [Parameter(Mandatory = $true)]
        [string]$TargetPath,
        [Parameter(Mandatory = $true)]
        [string]$BaseRelative,
        [Parameter(Mandatory = $true)]
        [hashtable]$ManifestEntries,
        [Parameter(Mandatory = $true)]
        [string]$Ownership,
        [Parameter(Mandatory = $true)]
        [string]$SourceLabelPrefix,
        [switch]$Force,
        [switch]$AlwaysOverwrite,
        [bool]$PreserveUntracked = $true,
        [string[]]$ExcludePatterns = @()
    )

    if (-not (Test-Path $SourcePath)) {
        throw "Source path not found: $SourcePath"
    }

    $resolvedSourcePath = (Resolve-Path $SourcePath).Path
    $result = New-SyncResult

    Get-ChildItem -Path $resolvedSourcePath -Recurse -File | ForEach-Object {
        $relativePath = $_.FullName.Substring($resolvedSourcePath.Length).TrimStart([char[]]@('\', '/'))
        $recordPath = Normalize-RelativePath (Join-Path $BaseRelative $relativePath)
        if (Test-ShouldExcludeRelative -RelativePath $relativePath -ExcludePatterns $ExcludePatterns) {
            Add-SyncRecord -Result $result -Status 'skipped' -Path $recordPath
            return
        }

        $bytes = [System.IO.File]::ReadAllBytes($_.FullName)
        Set-ManagedBytes `
            -Path (Join-Path $TargetPath $recordPath) `
            -RelativePath $recordPath `
            -Bytes $bytes `
            -Result $result `
            -ManifestEntries $ManifestEntries `
            -Ownership $Ownership `
            -SourceLabel "$SourceLabelPrefix/$($relativePath -replace '\\', '/')" `
            -Force:$Force `
            -AlwaysOverwrite:$AlwaysOverwrite `
            -PreserveUntracked:$PreserveUntracked
    }

    return $result
}

function Seed-DirectoryFromLegacyRuntime {
    param(
        [Parameter(Mandatory = $true)]
        [string]$TargetPath,
        [Parameter(Mandatory = $true)]
        [string]$RelativeDirectory,
        [string[]]$ExcludePatterns = @()
    )

    $legacySource = Join-Path $TargetPath ".github\$RelativeDirectory"
    $targetDirectory = Join-Path $TargetPath $RelativeDirectory

    if ((Test-Path $targetDirectory) -or (-not (Test-Path $legacySource))) {
        return (New-SyncResult)
    }

    return Sync-DirectoryTree -SourcePath $legacySource -TargetPath $targetDirectory -ExcludePatterns $ExcludePatterns
}

function Sync-DirectoryTree {
    param(
        [Parameter(Mandatory = $true)]
        [string]$SourcePath,
        [Parameter(Mandatory = $true)]
        [string]$TargetPath,
        [switch]$Force,
        [string[]]$ExcludePatterns = @()
    )

    if (-not (Test-Path $SourcePath)) {
        throw "Source path not found: $SourcePath"
    }

    $resolvedSourcePath = (Resolve-Path $SourcePath).Path
    if (-not (Test-Path $TargetPath)) {
        New-Item -ItemType Directory -Path $TargetPath -Force | Out-Null
    }

    $result = New-SyncResult

    Get-ChildItem -Path $resolvedSourcePath -Recurse -File | ForEach-Object {
        $relativePath = $_.FullName.Substring($resolvedSourcePath.Length).TrimStart([char[]]@('\', '/'))
        if (Test-ShouldExcludeRelative -RelativePath $relativePath -ExcludePatterns $ExcludePatterns) {
            $result.FilesSkipped += (Normalize-RelativePath $relativePath)
            return
        }

        $targetFile = Join-Path $TargetPath $relativePath
        $targetDir = Split-Path $targetFile -Parent
        if (-not (Test-Path $targetDir)) {
            New-Item -ItemType Directory -Path $targetDir -Force | Out-Null
        }

        if (Test-Path $targetFile) {
            if (Test-FilesIdentical -Path1 $_.FullName -Path2 $targetFile) {
                $result.FilesSkipped += (Normalize-RelativePath $relativePath)
            } elseif ($Force) {
                Copy-Item -Path $_.FullName -Destination $targetFile -Force
                $result.FilesUpdated += (Normalize-RelativePath $relativePath)
            } else {
                $result.FilesConflicted += (Normalize-RelativePath $relativePath)
            }
        } else {
            Copy-Item -Path $_.FullName -Destination $targetFile -Force
            $result.FilesAdded += (Normalize-RelativePath $relativePath)
        }
    }

    return $result
}

function Unquote-FrontmatterValue {
    param([string]$Value)

    $trimmed = $Value.Trim()
    if ($trimmed.Length -ge 2 -and $trimmed[0] -eq $trimmed[$trimmed.Length - 1] -and $trimmed[0] -in @('"', "'")) {
        return $trimmed.Substring(1, $trimmed.Length - 2)
    }
    return $trimmed
}

function Get-AgentDefinition {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Path
    )

    $raw = Get-Content -Raw $Path
    $match = [regex]::Match($raw, '(?s)^---\r?\n(.*?)\r?\n---\r?\n?(.*)$')
    if (-not $match.Success) {
        throw "Invalid agent file: $Path"
    }

    $frontmatter = $match.Groups[1].Value
    $body = $match.Groups[2].Value.Trim()
    $descriptionMatch = [regex]::Match($frontmatter, '(?m)^description:\s*(.+)$')
    $description = if ($descriptionMatch.Success) {
        Unquote-FrontmatterValue $descriptionMatch.Groups[1].Value
    } else {
        ''
    }
    $name = ((Split-Path $Path -Leaf) -replace '\.agent\.md$', '')

    return [PSCustomObject]@{
        Name = $name
        Description = $description
        Body = $body
    }
}

function Build-ClaudeAgentContent {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Name,
        [Parameter(Mandatory = $true)]
        [string]$Description,
        [Parameter(Mandatory = $true)]
        [string]$Body
    )

    $nameLiteral = $Name | ConvertTo-Json -Compress
    $descriptionLiteral = $Description | ConvertTo-Json -Compress

    return (@(
        '---'
        "name: $nameLiteral"
        "description: $descriptionLiteral"
        '---'
        ''
        $Body.TrimEnd()
        ''
    ) -join "`n")
}

function Build-CodexAgentContent {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Name,
        [Parameter(Mandatory = $true)]
        [string]$Description,
        [Parameter(Mandatory = $true)]
        [string]$Body
    )

    $nameLiteral = $Name | ConvertTo-Json -Compress
    $descriptionLiteral = $Description | ConvertTo-Json -Compress
    $escapedBody = $Body.TrimEnd() -replace '"""', '\"""'

    return (@(
        "name = $nameLiteral"
        "description = $descriptionLiteral"
        'developer_instructions = """'
        $escapedBody
        '"""'
        ''
    ) -join "`n")
}

function Set-ManagedTextFile {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Path,
        [Parameter(Mandatory = $true)]
        [string]$Content,
        [switch]$Force
    )

    $normalized = if ($Content.EndsWith("`n")) { $Content } else { "$Content`n" }

    if (Test-Path $Path) {
        $existing = Get-Content -Raw $Path
        if ($existing -eq $normalized) {
            return 'skipped'
        }
        if (-not $Force) {
            return 'conflicted'
        }
        $status = 'updated'
    } else {
        $status = 'added'
    }

    $parent = Split-Path $Path -Parent
    if ($parent -and -not (Test-Path $parent)) {
        New-Item -ItemType Directory -Path $parent -Force | Out-Null
    }
    Set-Content -Path $Path -Value $normalized -Encoding UTF8
    return $status
}

function Remove-ManagedPath {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Path
    )

    if (-not (Test-Path $Path)) {
        return
    }

    Remove-Item -LiteralPath $Path -Recurse -Force
}

function Ensure-SkillLink {
    param(
        [Parameter(Mandatory = $true)]
        [string]$LinkPath,
        [Parameter(Mandatory = $true)]
        [string]$TargetPath,
        [switch]$Force
    )

    $suffix = ''
    if (Test-Path $LinkPath) {
        try {
            $resolvedLink = (Resolve-Path $LinkPath).Path
            $resolvedTarget = (Resolve-Path $TargetPath).Path
            if ($resolvedLink -eq $resolvedTarget) {
                return [PSCustomObject]@{ Status = 'skipped'; Suffix = $suffix }
            }
        } catch {
            # Ignore resolution errors and treat as drift
        }

        if (-not $Force) {
            return [PSCustomObject]@{ Status = 'conflicted'; Suffix = $suffix }
        }

        Remove-ManagedPath -Path $LinkPath
        $status = 'updated'
    } else {
        $status = 'added'
    }

    $parent = Split-Path $LinkPath -Parent
    if (-not (Test-Path $parent)) {
        New-Item -ItemType Directory -Path $parent -Force | Out-Null
    }

    try {
        if ($IsWindows) {
            New-Item -ItemType Junction -Path $LinkPath -Target $TargetPath -Force | Out-Null
        } else {
            $relativeTarget = [IO.Path]::GetRelativePath($parent, $TargetPath)
            New-Item -ItemType SymbolicLink -Path $LinkPath -Target $relativeTarget -Force | Out-Null
        }
    } catch {
        Copy-Item -Path $TargetPath -Destination $LinkPath -Recurse -Force
        $suffix = '[copy fallback]'
    }

    return [PSCustomObject]@{ Status = $status; Suffix = $suffix }
}

function Install-PortableRuntime {
    param(
        [Parameter(Mandatory = $true)]
        [string]$SourceRoot,
        [Parameter(Mandatory = $true)]
        [string]$TargetPath,
        [Parameter(Mandatory = $true)]
        [hashtable]$ManifestEntries,
        [switch]$Force
    )

    $sourceRootResolved = (Resolve-Path $SourceRoot).Path
    $targetPathResolved = (Resolve-Path $TargetPath).Path
    $skillExcludes = if ($sourceRootResolved -ne $targetPathResolved) { @('gate-check') } else { @() }

    $result = Merge-SyncResults `
        (Seed-DirectoryFromLegacyRuntime -TargetPath $TargetPath -RelativeDirectory 'skills' -ExcludePatterns $skillExcludes) `
        (Seed-DirectoryFromLegacyRuntime -TargetPath $TargetPath -RelativeDirectory 'agents') `
        (Sync-DirectoryWithPolicy -SourcePath (Join-Path $SourceRoot 'skills') -TargetPath $TargetPath -BaseRelative 'skills' -ManifestEntries $ManifestEntries -Ownership 'template-managed' -SourceLabelPrefix 'template:skills' -Force:$Force -ExcludePatterns $skillExcludes) `
        (Sync-DirectoryWithPolicy -SourcePath (Join-Path $SourceRoot 'agents') -TargetPath $TargetPath -BaseRelative 'agents' -ManifestEntries $ManifestEntries -Ownership 'template-managed' -SourceLabelPrefix 'template:agents' -Force:$Force)

    $guideTemplates = @(
        @{ RelativePath = 'AGENTS.md';  Template = Join-Path $SourceRoot 'docs\AGENTS.template.md' },
        @{ RelativePath = 'CLAUDE.md'; Template = Join-Path $SourceRoot 'docs\CLAUDE.template.md' },
        @{ RelativePath = 'GEMINI.md'; Template = Join-Path $SourceRoot 'docs\GEMINI.template.md' }
    )

    foreach ($guide in $guideTemplates) {
        if (-not (Test-Path $guide.Template)) { continue }
        $normalized = Normalize-TextContent (Get-Content -Raw $guide.Template)
        $guidePath = Join-Path $TargetPath $guide.RelativePath
        $guideBytes = [System.Text.Encoding]::UTF8.GetBytes($normalized)

        if (Test-Path $guidePath -PathType Leaf) {
            Add-SyncRecord -Result $result -Status 'skipped' -Path $guide.RelativePath -Suffix '[project-owned]'
            Set-ManifestEntry -ManifestEntries $ManifestEntries -RelativePath $guide.RelativePath -Ownership 'project-owned' -SourceLabel "template:docs/$([IO.Path]::GetFileName($guide.Template))" -Kind 'file' -ManagedHash (Get-BytesHash -Bytes $guideBytes) -ObservedHash (Get-PathHash -Path $guidePath) -Status 'project-owned'
            continue
        }

        $parent = Split-Path $guidePath -Parent
        if ($parent -and -not (Test-Path $parent)) {
            New-Item -ItemType Directory -Path $parent -Force | Out-Null
        }
        [System.IO.File]::WriteAllBytes($guidePath, $guideBytes)
        Add-SyncRecord -Result $result -Status 'added' -Path $guide.RelativePath
        Set-ManifestEntry -ManifestEntries $ManifestEntries -RelativePath $guide.RelativePath -Ownership 'project-owned' -SourceLabel "template:docs/$([IO.Path]::GetFileName($guide.Template))" -Kind 'file' -ManagedHash (Get-BytesHash -Bytes $guideBytes) -ObservedHash (Get-PathHash -Path $guidePath) -Status 'project-owned'
    }

    $result = Merge-SyncResults `
        $result `
        (Install-LifecycleAssets -SourceRoot $SourceRoot -TargetPath $TargetPath -ManifestEntries $ManifestEntries)

    $sharedSkills = Join-Path $TargetPath 'skills'
    foreach ($relativeLink in $script:PortableSkillLinks) {
        $linkResult = Ensure-SkillLink -LinkPath (Join-Path $TargetPath $relativeLink) -TargetPath $sharedSkills -Force
        Add-SyncRecord -Result $result -Status $linkResult.Status -Path $relativeLink -Suffix $linkResult.Suffix
        Set-ManifestEntry -ManifestEntries $ManifestEntries -RelativePath $relativeLink -Ownership 'derived-runtime' -SourceLabel 'project:skills' -Kind 'mount' -ManagedHash $null -ObservedHash $null -Status 'derived-runtime'
    }

    $targetAgentsDir = Join-Path $TargetPath 'agents'
    if (Test-Path $targetAgentsDir) {
        Get-ChildItem -Path $targetAgentsDir -Filter '*.agent.md' | Sort-Object Name | ForEach-Object {
            $definition = Get-AgentDefinition -Path $_.FullName

            $claudeRelative = ".claude/agents/$($definition.Name).md"
            $claudeBytes = [System.Text.Encoding]::UTF8.GetBytes((Normalize-TextContent (Build-ClaudeAgentContent -Name $definition.Name -Description $definition.Description -Body $definition.Body)))
            Set-ManagedBytes `
                -Path (Join-Path $TargetPath $claudeRelative) `
                -RelativePath $claudeRelative `
                -Bytes $claudeBytes `
                -Result $result `
                -ManifestEntries $ManifestEntries `
                -Ownership 'derived-runtime' `
                -SourceLabel "project:agents/$($_.Name)" `
                -AlwaysOverwrite `
                -PreserveUntracked:$false

            $codexRelative = ".codex/agents/$($definition.Name).toml"
            $codexBytes = [System.Text.Encoding]::UTF8.GetBytes((Normalize-TextContent (Build-CodexAgentContent -Name $definition.Name -Description $definition.Description -Body $definition.Body)))
            Set-ManagedBytes `
                -Path (Join-Path $TargetPath $codexRelative) `
                -RelativePath $codexRelative `
                -Bytes $codexBytes `
                -Result $result `
                -ManifestEntries $ManifestEntries `
                -Ownership 'derived-runtime' `
                -SourceLabel "project:agents/$($_.Name)" `
                -AlwaysOverwrite `
                -PreserveUntracked:$false
        }
    }

    $result = Merge-SyncResults `
        $result `
        (Sync-DirectoryWithPolicy -SourcePath (Join-Path $TargetPath 'skills') -TargetPath $TargetPath -BaseRelative '.github/skills' -ManifestEntries $ManifestEntries -Ownership 'derived-runtime' -SourceLabelPrefix 'project:skills' -AlwaysOverwrite -PreserveUntracked:$false) `
        (Sync-DirectoryWithPolicy -SourcePath (Join-Path $TargetPath 'agents') -TargetPath $TargetPath -BaseRelative '.github/agents' -ManifestEntries $ManifestEntries -Ownership 'derived-runtime' -SourceLabelPrefix 'project:agents' -AlwaysOverwrite -PreserveUntracked:$false)

    return $result
}

# ============================================================================
# Repo Memory 初始化
# ============================================================================

function Initialize-RepoMemory {
    <#
    .SYNOPSIS
    建立 .ai-workflow-memory/ 骨架（opt-in 記憶功能）
    
    .PARAMETER TargetPath
    目標專案目錄
    #>
    param(
        [Parameter(Mandatory=$true)]
        [string]$TargetPath
    )
    
    $memDir     = Join-Path $TargetPath '.ai-workflow-memory'
    $journalDir = Join-Path $memDir 'session-journal'

    foreach ($d in @($memDir, $journalDir)) {
        if (-not (Test-Path $d)) { New-Item -ItemType Directory -Force -Path $d | Out-Null }
    }

    $contextFile = Join-Path $memDir 'PROJECT_CONTEXT.md'
    if (-not (Test-Path $contextFile)) {
        @'
# Project Context

> This file is maintained by AI agents. Update when project fundamentals change.

## Project Overview
<!-- Describe the project purpose and scope -->

## Tech Stack
<!-- List key technologies, frameworks, languages -->

## Key Decisions
<!-- Log major architectural or design decisions -->

## Important Files
<!-- Reference key files and their purpose -->
'@ | Set-Content -Path $contextFile -Encoding UTF8
    }

    $stateFile = Join-Path $memDir 'CURRENT_STATE.md'
    if (-not (Test-Path $stateFile)) {
        @"
# Current State

> Updated at the end of each AI session.

**Last Updated**: $(Get-Date -Format 'yyyy-MM-dd')
**Current Stage**: Initial setup

## What's Done
- Memory skeleton initialized via: bootstrap.ps1 -EnableMemory

## What's Next
<!-- Describe the next planned action -->

## Open Questions
<!-- List any unresolved questions or decisions -->
"@ | Set-Content -Path $stateFile -Encoding UTF8
    }

    $gitkeep = Join-Path $journalDir '.gitkeep'
    if (-not (Test-Path $gitkeep)) { '' | Set-Content -Path $gitkeep -Encoding UTF8 }

    # 更新 .gitignore：只 gitignore session-journal，讓 PROJECT_CONTEXT 與 CURRENT_STATE 納入版控
    $gitignorePath = Join-Path $TargetPath '.gitignore'
    $journalIgnoreEntry = '.ai-workflow-memory/session-journal/'
    $fullDirIgnoreEntry = '.ai-workflow-memory/'

    if (Test-Path $gitignorePath) {
        $ignoreContent = Get-Content $gitignorePath -Raw
        if ($ignoreContent -match [regex]::Escape($fullDirIgnoreEntry)) {
            # 已有完整目錄 ignore → 替換為只 ignore journal
            $ignoreContent = $ignoreContent -replace [regex]::Escape($fullDirIgnoreEntry), $journalIgnoreEntry
            Set-Content -Path $gitignorePath -Value $ignoreContent.TrimEnd() -Encoding UTF8
        } elseif (-not ($ignoreContent -match [regex]::Escape($journalIgnoreEntry))) {
            Add-Content -Path $gitignorePath -Value "`n# Repo Memory - session journal only (PROJECT_CONTEXT and CURRENT_STATE are committed)`n$journalIgnoreEntry"
        }
    } else {
        @"
# Repo Memory - session journal only (PROJECT_CONTEXT and CURRENT_STATE are committed)
$journalIgnoreEntry
"@ | Set-Content -Path $gitignorePath -Encoding UTF8
    }

    Write-Host "🧠 Memory skeleton initialized: .ai-workflow-memory/" -ForegroundColor Magenta
}

# ============================================================================
# AGENTS.md 骨架初始化
# ============================================================================

function Initialize-AgentsGuide {
    <#
    .SYNOPSIS
    建立 AGENTS.md 骨架（skip if exists — 保護既有客製化）
    
    .PARAMETER TargetPath
    目標專案目錄
    
    .PARAMETER SourceRoot
    模板來源根目錄（本地或遠端暫存）
    #>
    param(
        [Parameter(Mandatory=$true)]
        [string]$TargetPath,
        [Parameter(Mandatory=$true)]
        [string]$SourceRoot
    )
    
    $agentsFile   = Join-Path $TargetPath 'AGENTS.md'
    if (Test-Path $agentsFile) {
        Write-Host "  ⏭  AGENTS.md 已存在，跳過（保護既有客製化）" -ForegroundColor DarkGray
        return
    }
    
    $templateFile = Join-Path $SourceRoot 'docs' 'AGENTS.template.md'
    if (-not (Test-Path $templateFile)) {
        Write-Host "  ⚠️  AGENTS.md 模板不存在，跳過" -ForegroundColor Yellow
        return
    }
    
    Copy-Item -Path $templateFile -Destination $agentsFile -ErrorAction Stop
    Write-Host "✅ AGENTS.md 骨架已建立（請填入專案資訊）" -ForegroundColor Green
}

# ============================================================================
# 主程式進入點
# ============================================================================

function Main {
    $targetProjectPath = if ($TargetPath) { $TargetPath } else { (Get-Location).Path }
    $manifestResult = Get-InstallManifest -TargetPath $targetProjectPath
    if ($Update) {
        if ($manifestResult.State -eq 'missing') {
            Write-Warning "Legacy project manifest is missing: $($manifestResult.ManifestPath)"
            Write-Warning 'Update is report-only because managed-file provenance is unavailable.'
            Write-Warning 'No files changed; no ownership was inferred and no manifest was created.'
            return
        }
        if ($manifestResult.State -eq 'unsupported') {
            Write-Error "Unsupported install manifest: $($manifestResult.ManifestPath)" -ErrorAction Continue
            Write-Error "Observed schema version: $($manifestResult.SchemaVersion)" -ErrorAction Continue
            Write-Error "Supported schema versions: $($script:SupportedManifestSchemaVersions -join ', ')" -ErrorAction Continue
            Write-Error 'Update aborted before any changes; the manifest was not downgraded or rebuilt.' -ErrorAction Continue
            exit 1
        }
        if ($manifestResult.State -eq 'corrupt') {
            Write-Error "Corrupt install manifest: $($manifestResult.ManifestPath)" -ErrorAction Continue
            Write-Error $manifestResult.Detail -ErrorAction Continue
            Write-Error 'Update aborted before any changes; the manifest was not deleted or rebuilt.' -ErrorAction Continue
            Write-Error 'Inspect the manifest manually or restore it from a trusted backup.' -ErrorAction Continue
            exit 1
        }
    }
    $manifestEntries = $manifestResult.Entries

    Write-Host "🚀 Bootstrap AI Workflow Installer" -ForegroundColor Cyan
    Write-Host ""
    
    # 檢查 Update 模式
    $forceMode = $Force
    $backupMode = $Backup -or $Update  # Update 模式自動啟用備份
    
    if ($Update -and -not $Force) {
        Write-Host "ℹ️  執行 --update 模式（將保留專案客製化並建立備份）" -ForegroundColor Cyan
        Write-Host ""
    }
    
    # 環境檢測
    Write-Host "環境檢測:" -ForegroundColor Cyan
    
    $git = Test-GitInstalled
    Write-EnvironmentCheck -Name "Git" -Result $git -InstallUrl "https://git-scm.com/downloads" -MinVersion "2.28"
    
    $python = Test-PythonInstalled
    Write-EnvironmentCheck -Name "Python" -Result $python -InstallUrl "https://www.python.org/downloads/" -MinVersion "3.7"
    
    $powershell = Test-PowerShellVersion
    Write-EnvironmentCheck -Name "PowerShell" -Result $powershell -InstallUrl "https://aka.ms/powershell" -MinVersion "5.1"
    
    $node = Test-NodeJSInstalled
    Write-EnvironmentCheck -Name "Node.js" -Result $node -InstallUrl "https://nodejs.org" -MinVersion "16.0"

    $ghCLI = Test-GitHubCLIInstalled
    Write-EnvironmentCheck -Name "GitHub CLI" -Result $ghCLI -InstallUrl "https://cli.github.com/" -MinVersion "2.0"
    
    Write-Host ""
    
    # 檢查 Git 是否為必需
    if (-not $git.Installed) {
        Write-Host "❌ Git is required but not found." -ForegroundColor Red
        Write-Host "Please install Git and try again." -ForegroundColor Yellow
        exit 1
    }
    
    if (-not $git.MeetsRequirement) {
        Write-Host "⚠️  Git version is too old. Recommended: >= 2.0" -ForegroundColor Yellow
        $continue = Read-Host "Continue anyway? (y/n)"
        if ($continue -ne 'y') {
            Write-Host "Aborted." -ForegroundColor Gray
            exit 0
        }
        Write-Host ""
    }
    
    # PowerShell 版本檢查（警告但不中斷）
    if (-not $powershell.MeetsRequirement) {
        Write-Host "⚠️  PowerShell $($powershell.Version) detected (recommended: >= 5.1)" -ForegroundColor Yellow
        Write-Host "   Some features may not work correctly." -ForegroundColor Gray
        Write-Host ""
    }
    
    # Python 為可選依賴（建議但非必需）
    if (-not $python.Installed) {
        Write-Host "ℹ️  Python not detected (optional, used for cross-platform fallback)" -ForegroundColor Cyan
    } elseif (-not $python.MeetsRequirement) {
        Write-Host "ℹ️  Python $($python.Version) detected (recommended: >= 3.7)" -ForegroundColor Cyan
    }
    
    # Node.js 為可選依賴（部分 Skills 需要）
    if (-not $node.Installed) {
        Write-Host "ℹ️  Node.js not detected (optional, required by some skills)" -ForegroundColor Cyan
    } elseif (-not $node.MeetsRequirement) {
        Write-Host "ℹ️  Node.js $($node.Version) detected (recommended: >= 16.0 LTS)" -ForegroundColor Cyan
    }
    
    # GitHub CLI 為可選依賴（Template / gh 工具）
    if (-not $ghCLI.Installed) {
        Write-Host "ℹ️  GitHub CLI not detected (optional, required for gh template tooling)" -ForegroundColor Cyan
    } elseif (-not $ghCLI.MeetsRequirement) {
        Write-Host "ℹ️  GitHub CLI $($ghCLI.Version) detected (recommended: >= 2.0)" -ForegroundColor Cyan
    }

    Write-Host ""
    
    # ========================================================================
    # 判斷執行模式（本地或遠端）
    # ========================================================================
    
    # 決定目標路徑
    $templateSourcePath = Join-Path $script:RepoRoot ".github"
    
    # 檢查是否需要使用遠端模式
    $needRemoteMode = $false
    
    # 情況 1: 明確指定 RemoteRepo 參數
    if ($PSBoundParameters.ContainsKey('RemoteRepo')) {
        $needRemoteMode = $true
        Write-Host "ℹ️  使用遠端模式（RemoteRepo 參數已指定）" -ForegroundColor Cyan
    }
    # 情況 2: 自動偵測 - 源目錄不存在
    elseif (-not (Test-Path $templateSourcePath)) {
        $needRemoteMode = $true
        Write-Host "ℹ️  自動啟用遠端模式（本地模板目錄不存在）" -ForegroundColor Cyan
        Write-Host "   將從 $RemoteRepo 下載模板" -ForegroundColor Gray
    }
    # 情況 3: 腳本在目標專案內執行（不在 scripts/ 目錄下）
    elseif ($PSScriptRoot -eq $targetProjectPath) {
        $needRemoteMode = $true
        Write-Host "ℹ️  自動啟用遠端模式（腳本不在模板 repo 內）" -ForegroundColor Cyan
        Write-Host "   將從 $RemoteRepo 下載模板" -ForegroundColor Gray
    }
    
    Write-Host ""
    
    # ========================================================================
    # 遠端模式：下載模板
    # ========================================================================
    
    if ($needRemoteMode) {
        $script:IsRemoteMode = $true
        
        # 下載模板到臨時目錄
        $downloadResult = Get-RemoteTemplate -RemoteRepo $RemoteRepo
        
        if (-not $downloadResult.Success) {
            Write-Host "❌ 遠端模板下載失敗: $($downloadResult.Message)" -ForegroundColor Red
            exit 1
        }
        
        # 更新來源路徑為臨時目錄
        $script:TempClonePath = $downloadResult.TempPath
        $script:RepoRoot = $script:TempClonePath
        $templateSourcePath = Join-Path $script:TempClonePath ".github"
        
        # 驗證下載的模板是否有效
        if (-not (Test-Path $templateSourcePath)) {
            Write-Host "❌ 下載的模板無效（缺少 .github/ 目錄）" -ForegroundColor Red
            Remove-TempDirectory -Path $script:TempClonePath
            exit 1
        }
    }
    
    # ========================================================================
    # 檔案同步
    # ========================================================================
    
    # 檢查是否在模板 repo 內執行（避免自我覆蓋）
    if (-not $needRemoteMode -and $targetProjectPath -eq $script:RepoRoot) {
        Write-Host "⚠️  警告：正在模板 repo 內執行 bootstrap" -ForegroundColor Yellow
        Write-Host "   建議：請在目標專案目錄執行此腳本" -ForegroundColor Gray
        $continue = Read-Host "是否繼續（將會複製到目前目錄）? (y/n)"
        if ($continue -ne 'y') {
            Write-Host "已取消。" -ForegroundColor Gray
            exit 0
        }
    }
    
    # 檢查未提交的變更（Update 模式）
    if ($Update) {
        $managedTargets = @($script:PortableRuntimePaths | Where-Object { Test-Path (Join-Path $targetProjectPath $_) })
        $hasChanges = $false
        foreach ($managedTarget in $managedTargets) {
            if (Test-GitUncommittedChanges -TargetPath $targetProjectPath -Directory $managedTarget) {
                $hasChanges = $true
                break
            }
        }

        if ($hasChanges) {
            if ($Force) {
                # -Force 旗標：跳過確認，直接繼續（備份仍會自動建立）
                Write-Host "⚠️  檢測到 AI workflow 管理目錄有未提交的變更（-Force 已指定，略過確認）" -ForegroundColor Yellow
                Write-Host ""
            } else {
                Write-Host "⚠️  檢測到 AI workflow 管理目錄有未提交的變更" -ForegroundColor Yellow
                Write-Host "   提示 1：先執行 'git add .github skills agents .claude .codex .agent .agents AGENTS.md CLAUDE.md GEMINI.md && git commit' 再更新可避免此提示" -ForegroundColor Gray
                Write-Host "   提示 2：加上 -Force 旗標可自動跳過此確認" -ForegroundColor Gray
                $continue = Read-Host "是否繼續更新? (y/n)"
                if ($continue -ne 'y') {
                    Write-Host "已取消。" -ForegroundColor Gray
                    if ($script:IsRemoteMode) {
                        Remove-TempDirectory -Path $script:TempClonePath
                    }
                    exit 0
                }
                Write-Host ""
            }
        }
    }
    
    Write-Host "同步工作流檔案..." -ForegroundColor Cyan
    Write-Host ""
    
    try {
        # 執行檔案同步
        $syncResult = Sync-WorkflowFiles -SourcePath $templateSourcePath -TargetPath $targetProjectPath -ManifestEntries $manifestEntries -ConstitutionSourceRoot $script:RepoRoot -Force:$forceMode -Backup:$backupMode
        if ($backupMode) {
            $portableBackupResult = Backup-ManagedPaths -TargetPath $targetProjectPath -RelativePaths $script:PortableBackupPaths
            if ($portableBackupResult.BackupPath) {
                if ($portableBackupResult.Success) {
                    Write-Host "✅ $($portableBackupResult.Message)" -ForegroundColor Green
                } else {
                    Write-Host "⚠️  $($portableBackupResult.Message)" -ForegroundColor Yellow
                }
            }
        }
        $portableResult = Install-PortableRuntime -SourceRoot $script:RepoRoot -TargetPath $targetProjectPath -ManifestEntries $manifestEntries -Force:$forceMode
        $syncResult = Merge-SyncResults $syncResult $portableResult

        if (([IO.Path]::GetFullPath($targetProjectPath)) -ne ([IO.Path]::GetFullPath($script:RepoRoot))) {
            Write-InstallManifest -TargetPath $targetProjectPath -SourceRoot $script:RepoRoot -ManifestEntries $manifestEntries
        }
        
        # 顯示同步結果
        if ($syncResult.FilesAdded.Count -gt 0) {
            Write-Host "✅ 新增 $($syncResult.FilesAdded.Count) 個檔案" -ForegroundColor Green
        }
        
        if ($syncResult.FilesUpdated.Count -gt 0) {
            Write-Host "✅ 更新 $($syncResult.FilesUpdated.Count) 個檔案" -ForegroundColor Yellow
        }
        
        if ($syncResult.FilesSkipped.Count -gt 0) {
            Write-Host "⏭️  跳過 $($syncResult.FilesSkipped.Count) 個檔案（保留既有客製、排除項或內容相同）" -ForegroundColor Gray
        }
        
        if ($syncResult.FilesConflicted.Count -gt 0) {
            Write-Host "⚠️  偵測到 $($syncResult.FilesConflicted.Count) 個衝突檔案（內容不同但未覆蓋）" -ForegroundColor Yellow
            if ($VerbosePreference -eq 'Continue') {
                foreach ($file in $syncResult.FilesConflicted) {
                    Write-Host "   - $file" -ForegroundColor Gray
                }
            }
            Write-Host ""
            Write-Host "提示：使用 -Force 參數強制覆蓋模板管理的衝突檔案" -ForegroundColor Cyan
        }
        
        Write-Host ""
        
        # 顯示詳細清單（如果 Verbose）
        if ($VerbosePreference -eq 'Continue') {
            if ($syncResult.FilesAdded.Count -gt 0) {
                Write-Host "新增的檔案:" -ForegroundColor Cyan
                $syncResult.FilesAdded | ForEach-Object {
                    Write-Host "  + $_" -ForegroundColor Green
                }
                Write-Host ""
            }
            
            if ($syncResult.FilesUpdated.Count -gt 0) {
                Write-Host "更新的檔案:" -ForegroundColor Cyan
                $syncResult.FilesUpdated | ForEach-Object {
                    Write-Host "  ~ $_" -ForegroundColor Yellow
                }
                Write-Host ""
            }
        }
        
    } catch {
        Write-Host "❌ 檔案同步失敗: $($_.Exception.Message)" -ForegroundColor Red
        
        # 清理遠端模式的臨時目錄
        if ($script:IsRemoteMode -and $script:TempClonePath) {
            Remove-TempDirectory -Path $script:TempClonePath
        }
        
        exit 1
    }
    
    # ========================================================================
    # Git 初始化
    # ========================================================================
    
    if (-not $SkipHooks) {
        Write-Host "檢查 Git repository 初始化..." -ForegroundColor Cyan
        Write-Host "   （使用 -SkipHooks 可略過此步驟）" -ForegroundColor Gray
        Write-Host ""
        
        try {
            $gitResult = Initialize-GitRepo -TargetPath $targetProjectPath
            
            if ($gitResult.IsNew) {
                Write-Host "✅ Git repository 已初始化" -ForegroundColor Green
            } else {
                Write-Host "ℹ️  Git repository 已存在" -ForegroundColor Cyan
            }
            
            Write-Host ""
            
        } catch {
            Write-Host "⚠️  Git 初始化失敗: $($_.Exception.Message)" -ForegroundColor Yellow
            Write-Host "   您可以稍後手動執行 'git init'" -ForegroundColor Gray
            Write-Host ""
        }
    }
    
    # ========================================================================
    # Repo Memory 初始化（opt-in）
    # ========================================================================
    
    if ($EnableMemory) {
        Write-Host "初始化 Repo Memory..." -ForegroundColor Cyan
        Write-Host ""
        
        try {
            Initialize-RepoMemory -TargetPath $targetProjectPath
            Write-Host ""
        } catch {
            Write-Host "⚠️  Repo Memory 初始化失敗: $($_.Exception.Message)" -ForegroundColor Yellow
            Write-Host ""
        }
    }
    
    # AGENTS.md 骨架（always — skip if exists to protect project customizations）
    try {
        Initialize-AgentsGuide -TargetPath $targetProjectPath -SourceRoot $script:RepoRoot
    } catch {
        Write-Host "⚠️  AGENTS.md 骨架建立失敗: $($_.Exception.Message)" -ForegroundColor Yellow
    }
    Write-Host ""
    
    Write-Host "✅ Bootstrap completed!" -ForegroundColor Green
    Write-Host ""
    
    # ========================================================================
    # 清理臨時目錄（遠端模式）
    # ========================================================================
    
    if ($script:IsRemoteMode -and $script:TempClonePath) {
        Write-Host ""
        Remove-TempDirectory -Path $script:TempClonePath
    }
}

# 執行主程式
if ($MyInvocation.InvocationName -ne '.') {
    Main
}
