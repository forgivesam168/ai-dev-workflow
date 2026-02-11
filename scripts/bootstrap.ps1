# Bootstrap.ps1 - 跨平台 AI 工作流安裝器
# 用途：將 AI 開發工作流初始化到任何專案中

param(
    [switch]$Force,
    [switch]$Update,
    [switch]$Backup,
    [switch]$SkipHooks,
    [switch]$Verbose,
    [switch]$Quiet
)

# 全域變數
$script:RepoRoot = Split-Path -Parent $PSScriptRoot

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
    
    .PARAMETER Force
    強制覆蓋現有檔案
    
    .PARAMETER Backup
    在同步前備份現有 .github 目錄
    
    .OUTPUTS
    PSCustomObject with properties: FilesAdded, FilesUpdated, FilesSkipped, FilesConflicted
    
    .EXAMPLE
    $result = Sync-WorkflowFiles -SourcePath ".\.github" -TargetPath "C:\Projects\MyApp"
    #>
    
    param(
        [Parameter(Mandatory=$true)]
        [string]$SourcePath,
        
        [Parameter(Mandatory=$true)]
        [string]$TargetPath,
        
        [switch]$Force,
        
        [switch]$Backup
    )
    
    # 排除清單（不複製這些檔案）
    $excludePatterns = @(
        "workflows",        # 保留現有 CI/CD
        "CODEOWNERS",       # 保留現有 code owners
        "dependabot.yml"    # 保留現有 dependabot 設定
    )
    
    # 確保源目錄存在
    if (-not (Test-Path $SourcePath)) {
        throw "Source path not found: $SourcePath"
    }
    
    # 解析完整路徑
    $resolvedSourcePath = (Resolve-Path $SourcePath).Path
    
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
    
    # 統計
    $filesAdded = @()
    $filesUpdated = @()
    $filesSkipped = @()
    $filesConflicted = @()
    
    # 取得所有檔案
    $allFiles = Get-ChildItem -Path $resolvedSourcePath -Recurse -File
    
    foreach ($file in $allFiles) {
        # 計算相對路徑
        $relativePath = $file.FullName.Substring($resolvedSourcePath.Length).TrimStart('\')
        
        # 檢查是否在排除清單中
        $shouldExclude = $false
        foreach ($pattern in $excludePatterns) {
            if ($relativePath -like "*$pattern*") {
                $shouldExclude = $true
                break
            }
        }
        
        if ($shouldExclude) {
            $filesSkipped += $relativePath
            continue
        }
        
        # 目標檔案路徑
        $targetFile = Join-Path $targetGithubPath $relativePath
        $targetDir = Split-Path $targetFile -Parent
        
        # 確保目標目錄存在
        if (-not (Test-Path $targetDir)) {
            New-Item -ItemType Directory -Path $targetDir -Force | Out-Null
        }
        
        # 檢查檔案是否已存在
        if (Test-Path $targetFile) {
            # 檢查檔案內容是否相同
            if (Test-FilesIdentical -Path1 $file.FullName -Path2 $targetFile) {
                $filesSkipped += $relativePath
            } elseif ($Force) {
                Copy-Item -Path $file.FullName -Destination $targetFile -Force
                $filesUpdated += $relativePath
            } else {
                # 衝突：檔案存在且內容不同，但未強制覆蓋
                $filesConflicted += $relativePath
            }
        } else {
            Copy-Item -Path $file.FullName -Destination $targetFile
            $filesAdded += $relativePath
        }
    }
    
    # Copy root-level template files (e.g. .gitattributes, .editorconfig) into target project root
    $rootFiles = @('.gitattributes', '.editorconfig')
    foreach ($rf in $rootFiles) {
        $srcRootFile = Join-Path $script:RepoRoot $rf
        $dstRootFile = Join-Path $TargetPath $rf
        if (Test-Path $srcRootFile) {
            if (-not (Test-Path $dstRootFile)) {
                Copy-Item -Path $srcRootFile -Destination $dstRootFile -Force
                $filesAdded += $rf
            } else {
                # If exists, compare contents
                if (Test-FilesIdentical -Path1 $srcRootFile -Path2 $dstRootFile) {
                    # identical -> skip
                } elseif ($Force) {
                    Copy-Item -Path $srcRootFile -Destination $dstRootFile -Force
                    $filesUpdated += $rf
                } else {
                    $filesConflicted += $rf
                }
            }
        }
    }

    return [PSCustomObject]@{
        FilesAdded = $filesAdded
        FilesUpdated = $filesUpdated
        FilesSkipped = $filesSkipped
        FilesConflicted = $filesConflicted
    }
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
        
        $initOutput = git init 2>&1
        
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
        [string]$InstallUrl = ""
    )
    
    if ($Result.Installed) {
        if ($Result.MeetsRequirement) {
            Write-Host "✅ $Name $($Result.Version) detected" -ForegroundColor Green
        } else {
            Write-Host "⚠️  $Name $($Result.Version) (建議升級到 >= 2.0)" -ForegroundColor Yellow
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

# ============================================================================
# 主程式進入點
# ============================================================================

function Main {
    Write-Host "🚀 Bootstrap AI Workflow Installer" -ForegroundColor Cyan
    Write-Host ""
    
    # 檢查 Update 模式
    $forceMode = $Force -or $Update
    $backupMode = $Backup -or $Update  # Update 模式自動啟用備份
    
    if ($Update -and -not $Force) {
        Write-Host "ℹ️  執行 --update 模式（將檢查衝突並建立備份）" -ForegroundColor Cyan
        Write-Host ""
    }
    
    # 環境檢測
    Write-Host "環境檢測:" -ForegroundColor Cyan
    
    $git = Test-GitInstalled
    Write-EnvironmentCheck -Name "Git" -Result $git -InstallUrl "https://git-scm.com/downloads"
    
    $python = Test-PythonInstalled
    Write-EnvironmentCheck -Name "Python" -Result $python -InstallUrl "https://www.python.org/downloads/"
    
    $powershell = Test-PowerShellVersion
    Write-EnvironmentCheck -Name "PowerShell" -Result $powershell -InstallUrl "https://aka.ms/powershell"
    
    $node = Test-NodeJSInstalled
    Write-EnvironmentCheck -Name "Node.js" -Result $node -InstallUrl "https://nodejs.org"

    $ghCLI = Test-GitHubCLIInstalled
    Write-EnvironmentCheck -Name "GitHub CLI" -Result $ghCLI -InstallUrl "https://cli.github.com/"
    
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
    # 檔案同步
    # ========================================================================
    
    # 取得當前專案根目錄（假設 bootstrap.ps1 在 scripts/ 目錄下）
    $currentPath = Get-Location
    $templateSourcePath = Join-Path $script:RepoRoot ".github"
    
    # 檢查是否在模板 repo 內執行（避免自我覆蓋）
    if ($currentPath.Path -eq $script:RepoRoot) {
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
        $targetGithubPath = Join-Path $currentPath.Path ".github"
        if (Test-Path $targetGithubPath) {
            $hasChanges = Test-GitUncommittedChanges -TargetPath $currentPath.Path -Directory ".github"
            if ($hasChanges) {
                Write-Host "⚠️  檢測到 .github/ 目錄有未提交的變更" -ForegroundColor Yellow
                Write-Host "   建議先提交變更後再執行 --update" -ForegroundColor Gray
                $continue = Read-Host "是否繼續更新? (y/n)"
                if ($continue -ne 'y') {
                    Write-Host "已取消。" -ForegroundColor Gray
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
        $syncResult = Sync-WorkflowFiles -SourcePath $templateSourcePath -TargetPath $currentPath.Path -Force:$forceMode -Backup:$backupMode
        
        # 顯示同步結果
        if ($syncResult.FilesAdded.Count -gt 0) {
            Write-Host "✅ 新增 $($syncResult.FilesAdded.Count) 個檔案" -ForegroundColor Green
        }
        
        if ($syncResult.FilesUpdated.Count -gt 0) {
            Write-Host "✅ 更新 $($syncResult.FilesUpdated.Count) 個檔案" -ForegroundColor Yellow
        }
        
        if ($syncResult.FilesSkipped.Count -gt 0) {
            Write-Host "⏭️  跳過 $($syncResult.FilesSkipped.Count) 個檔案（workflows/CODEOWNERS 或內容相同）" -ForegroundColor Gray
        }
        
        if ($syncResult.FilesConflicted.Count -gt 0) {
            Write-Host "⚠️  偵測到 $($syncResult.FilesConflicted.Count) 個衝突檔案（內容不同但未覆蓋）" -ForegroundColor Yellow
            if ($Verbose) {
                foreach ($file in $syncResult.FilesConflicted) {
                    Write-Host "   - $file" -ForegroundColor Gray
                }
            }
            Write-Host ""
            Write-Host "提示：使用 -Force 或 -Update 參數強制覆蓋衝突檔案" -ForegroundColor Cyan
        }
        
        Write-Host ""
        
        # 顯示詳細清單（如果 Verbose）
        if ($Verbose) {
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
        exit 1
    }
    
    # ========================================================================
    # Git 初始化
    # ========================================================================
    
    if (-not $SkipHooks) {
        Write-Host "檢查 Git 初始化..." -ForegroundColor Cyan
        Write-Host ""
        
        try {
            $gitResult = Initialize-GitRepo -TargetPath $currentPath.Path
            
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
    
    Write-Host "✅ Bootstrap completed!" -ForegroundColor Green
}

# 執行主程式
if ($MyInvocation.InvocationName -ne '.') {
    Main
}
