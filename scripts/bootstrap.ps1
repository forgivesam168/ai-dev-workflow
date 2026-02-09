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
    # TODO: 檔案同步
    # TODO: Git 初始化
    
    Write-Host "✅ Bootstrap completed!" -ForegroundColor Green
}

# 執行主程式
if ($MyInvocation.InvocationName -ne '.') {
    Main
}
