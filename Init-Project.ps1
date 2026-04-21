# ==============================================================================
# 金融專案初始化腳本 - 自動部署 Agents 與 Instructions
# ==============================================================================

param(
    [string]$TemplateSource = $PSScriptRoot,
    [string[]]$Include = @(),
    [string[]]$Exclude = @()
)

# 設定來源路徑 (Template 位置)
if (!(Test-Path $TemplateSource)) {
    Write-Error "Template 路徑不存在: $TemplateSource"
    exit 1
}

# 環境檢查：檢查並可使用 winget 安裝缺少的工具 (git, gh, pwsh)
function Test-Command {
    param([string]$Name)
    try { Get-Command $Name -ErrorAction Stop | Out-Null; return $true } catch { return $false }
}
function Install-With-Winget {
    param([string]$Id, [string]$Display, [switch]$Auto)
    if (-not (Test-Command 'winget')) {
        Write-Host "winget 未找到，無法自動安裝 $Display，請手動安裝。" -ForegroundColor Yellow
        return $false
    }
    $args = "install --id $Id -e --accept-package-agreements --accept-source-agreements"
    if ($Auto) { $args += " --silent" }
    Write-Host "執行: winget $args"
    $proc = Start-Process -FilePath winget -ArgumentList $args -NoNewWindow -Wait -PassThru -ErrorAction SilentlyContinue
    if ($proc -and $proc.ExitCode -eq 0) {
        Write-Host "$Display 安裝成功。" -ForegroundColor Green
        return $true
    } else {
        Write-Host "$Display 安裝失敗 (ExitCode: $($proc.ExitCode))." -ForegroundColor Red
        return $false
    }
}

$tools = @{
    'git' = @{ id='Git.Git'; display='Git' }
    'gh'  = @{ id='GitHub.cli'; display='GitHub CLI' }
    'pwsh' = @{ id='Microsoft.PowerShell'; display='PowerShell (pwsh)' }
    'node' = @{ id='OpenJS.NodeJS.LTS'; display='Node.js (含 npm, npx)' }
}

# 額外檢查：如果 node 已安裝但 npm 或 npx 不存在，提示安裝 Node.js
function Test-NodeTools {
    $nodeExists = Test-Command 'node'
    $npmExists = Test-Command 'npm'
    $npxExists = Test-Command 'npx'
    return @{ node=$nodeExists; npm=$npmExists; npx=$npxExists }
}

$nodeTools = Test-NodeTools
if (-not $nodeTools.node -or -not $nodeTools.npm -or -not $nodeTools.npx) {
    Write-Host "Node.js 或 npm/npx 未完整安裝。"
    $ans = Read-Host "是否使用 winget 安裝 Node.js LTS（含 npm, npx）？(Y/n)"
    if ($ans -notmatch '^[nN]') {
        $ok = Install-With-Winget $tools['node'].id $tools['node'].display
        if (-not $ok) { Write-Host "無法安裝 Node.js，請手動安裝後重新執行腳本。" -ForegroundColor Red; exit 1 }
    } else {
        Write-Host "跳過安裝 Node.js。若需要 Node 功能請手動安裝。" -ForegroundColor Yellow
    }
} else {
    Write-Host "node/npm/npx 已存在。" -ForegroundColor Green
}

foreach ($cmd in $tools.Keys) {
    if (-not (Test-Command $cmd)) {
        $info = $tools[$cmd]
        $ans = Read-Host "$($info.display) 未偵測到，是否使用 winget 安裝？(Y/n)"
        if ($ans -match '^[nN]') {
            Write-Host "跳過安裝 $($info.display)。" -ForegroundColor Yellow
        } else {
            $ok = Install-With-Winget $info.id $info.display
            if (-not $ok) { Write-Host "無法安裝 $($info.display)。請手動安裝後重新執行腳本。" -ForegroundColor Red; exit 1 }
        }
    } else {
        Write-Host "$cmd 已存在。" -ForegroundColor Green
    }
}

# 可選：將專案內容移入子資料夾（避免移動 .git 與此腳本）
$target = Read-Host "請輸入要搬移到的資料夾名稱（留空則不搬移）"
if (-not [string]::IsNullOrWhiteSpace($target)) {
    if (Test-Path $target) {
        $confirm = Read-Host "資料夾 '$target' 已存在，是否清空並繼續？(y/N)"
        if ($confirm -match '^[yY]') { Remove-Item -LiteralPath $target -Recurse -Force } else { Write-Host "已取消。" -ForegroundColor Yellow; exit 1 }
    }
    New-Item -ItemType Directory -Path $target | Out-Null
    $scriptName = Split-Path -Leaf $MyInvocation.MyCommand.Path
    $items = Get-ChildItem -LiteralPath . -Force | Where-Object { $_.Name -ne $target -and $_.Name -ne '.git' -and $_.Name -ne $scriptName }
    foreach ($it in $items) {
        Move-Item -LiteralPath $it.FullName -Destination $target -Force
    }
    Set-Location $target
}

function Test-ComponentEnabled {
    param([string]$Name)

    if ($Include -and $Include.Count -gt 0) {
        if (!($Include -contains $Name)) {
            return $false
        }
    }

    if ($Exclude -and ($Exclude -contains $Name)) {
        return $false
    }

    return $true
}

# 1. 建立必要目錄結構
$Directories = @(
    ".github/instructions",
    ".github/agents",
    ".github/prompts",
    ".github/skills",
    ".github/ISSUE_TEMPLATE",
    "docs"
    "changes",
    "changes/_template",
    ".vscode",
)

foreach ($dir in $Directories) {
    if (!(Test-Path $dir)) {
        New-Item -Path $dir -ItemType Directory -Force | Out-Null
        Write-Host "✅ 建立目錄: $dir" -ForegroundColor Green
    }
}

# 2. 複製 Template 檔案到專案對應位置
# 複製核心 Agent 憲法
if (Test-ComponentEnabled "copilot") {
    $CopilotInstructions = Join-Path $TemplateSource "copilot-instructions.md"
    if (Test-Path $CopilotInstructions) {
        Copy-Item $CopilotInstructions ".github/copilot-instructions.md" -Force
        Write-Host "🛡️ 部署核心 Agent 憲法完成" -ForegroundColor Cyan
    }
}

if (Test-ComponentEnabled "agents") {
    $AgentFiles = Get-ChildItem -Path (Join-Path $TemplateSource "agents") -Filter "*.agent.md"
    foreach ($file in $AgentFiles) {
        Copy-Item $file.FullName ".github/agents/$($file.Name)" -Force
        Write-Host "🧩 部署 Agent: $($file.Name)" -ForegroundColor Gray
    }
}

# 複製所有指令檔案 (SQL, C#, Web API, Python, Review, Skills)
if (Test-ComponentEnabled "instructions") {
    $InstructionFiles = Get-ChildItem -Path (Join-Path $TemplateSource "instructions") -Filter "*.instructions.md"
    foreach ($file in $InstructionFiles) {
        Copy-Item $file.FullName ".github/instructions/$($file.Name)" -Force
        Write-Host "📝 部署指令: $($file.Name)" -ForegroundColor Gray
    }
}

if (Test-ComponentEnabled "prompts") {
    $PromptFiles = Get-ChildItem -Path (Join-Path $TemplateSource "prompts")
    foreach ($file in $PromptFiles) {
        Copy-Item $file.FullName ".github/prompts/$($file.Name)" -Force
        Write-Host "🧭 部署 Prompt: $($file.Name)" -ForegroundColor Gray
    }
}

if (Test-ComponentEnabled "skills") {
    $SkillsPath = Join-Path $TemplateSource "skills"
    if (Test-Path $SkillsPath) {
        Copy-Item (Join-Path $SkillsPath "*") ".github/skills" -Recurse -Force
        Write-Host "🧰 部署 Skills 完成" -ForegroundColor Gray
    }
}

if (Test-ComponentEnabled "project-files") {
    $ProjectFiles = @(
        ".editorconfig",
        "README.md",
        "SECURITY.md"
        "WORKFLOW.md",
        "README.zh-TW.md",
    )
    foreach ($file in $ProjectFiles) {
        $SourceFile = Join-Path $TemplateSource $file
        if (Test-Path $SourceFile) {
            Copy-Item $SourceFile ".\$file" -Force
            Write-Host "📄 部署專案檔案: $file" -ForegroundColor Gray
        }
    }


    # 部署 VS Code 專案設定（建議：讓 Copilot/Instruction Files 一致）
    $VSCodeFolder = Join-Path $TemplateSource ".vscode"
    if (Test-Path $VSCodeFolder) {
        if (!(Test-Path ".vscode")) { New-Item -Path ".vscode" -ItemType Directory -Force | Out-Null }
        Copy-Item (Join-Path $VSCodeFolder "*") ".vscode" -Recurse -Force
        Write-Host "🧩 部署 .vscode 設定完成" -ForegroundColor Gray
    }

    # 部署 Change Package 模板（changes/_template）
    $ChangesFolder = Join-Path $TemplateSource "changes"
    if (Test-Path $ChangesFolder) {
        if (!(Test-Path "changes")) { New-Item -Path "changes" -ItemType Directory -Force | Out-Null }
        # 只覆蓋模板與 README，避免覆蓋既有 change folders
        Copy-Item (Join-Path $ChangesFolder "README.md") "changes\README.md" -Force -ErrorAction SilentlyContinue
        if (!(Test-Path "changes\_template")) { New-Item -Path "changes\_template" -ItemType Directory -Force | Out-Null }
        Copy-Item (Join-Path $ChangesFolder "_template\*") "changes\_template" -Recurse -Force
        Write-Host "📦 部署 Change Package 模板完成" -ForegroundColor Gray
    }

    $PullRequestTemplate = Join-Path $TemplateSource ".github\PULL_REQUEST_TEMPLATE.md"
    if (Test-Path $PullRequestTemplate) {
        Copy-Item $PullRequestTemplate ".github\PULL_REQUEST_TEMPLATE.md" -Force
        Write-Host "📄 部署 PR Template 完成" -ForegroundColor Gray
    }

    $Codeowners = Join-Path $TemplateSource ".github\CODEOWNERS"
    if (Test-Path $Codeowners) {
        Copy-Item $Codeowners ".github\CODEOWNERS" -Force
        Write-Host "📄 部署 CODEOWNERS 完成" -ForegroundColor Gray
    }

    $IssueTemplatePath = Join-Path $TemplateSource ".github\ISSUE_TEMPLATE"
    if (Test-Path $IssueTemplatePath) {
        Copy-Item (Join-Path $IssueTemplatePath "*") ".github\ISSUE_TEMPLATE" -Force
        Write-Host "📄 部署 Issue Templates 完成" -ForegroundColor Gray
    }
}

# 3. 初始化 Work-log 與 README
$WorkLogPath = "docs/WORK_LOG.md"
$CurrentDate = Get-Date -Format "yyyy-MM-dd"
$InitialContent = @"
# Work Log

## [$CurrentDate] Project Initialized
- 使用 $TemplateSource 範本完成專案初始化。
- 已配置核心 Agent (copilot-instructions.md) 與技術規範 (Instructions)。
- 角色設定：資深金融軟體架構師 & CISO。
"@

if (!(Test-Path $WorkLogPath)) {
    Set-Content -Path $WorkLogPath -Value $InitialContent -Encoding utf8
    Write-Host "📓 初始化 docs/WORK_LOG.md 完成" -ForegroundColor Cyan
}

# 4. Git 初始化與首次提交
if (!(Test-Path ".git")) {
    git init -b main
    Write-Host "📦 Git 初始化完成 (Branch: main)" -ForegroundColor Cyan
}

# 建立預設 .gitignore (避免上傳敏感資訊)
$GitIgnoreContent = @"
.vs/
.vscode/
bin/
obj/
*.user
*.suo
.env

# AI workflow memory (repo-local; opt-in per project — remove this line to commit your memory)
.ai-workflow-memory/
"@
if (!(Test-Path ".gitignore")) {
    Set-Content -Path ".gitignore" -Value $GitIgnoreContent -Encoding utf8
}

# 執行首次提交（檢查是否有變更與 git config）
$hasChanges = (git status --porcelain) -ne ''
if ($hasChanges) {
    $name = git config --get user.name
    $email = git config --get user.email
    if (-not $name -or -not $email) {
        Write-Host "git user.name 或 user.email 未設定，將使用臨時值以執行提交。" -ForegroundColor Yellow
        git config user.name "Init Script"
        git config user.email "init@example.com"
        $restoreConfig = $true
    }

    git add .
    $commitOk = $false
    try {
        git commit -m "Initial commit: 架構與 AI Agent 規則部署"
        $commitOk = $true
    } catch {
        Write-Host "git commit 失敗：$($_.Exception.Message)" -ForegroundColor Red
    }

    if ($restoreConfig) {
        git config --unset user.name
        git config --unset user.email
    }

    if ($commitOk) { Write-Host "✅ 首次提交完成，已包含 AI Agent 與技術規範" -ForegroundColor Green }
    else { Write-Host "⚠️ 首次提交未完成，請手動檢查 git 狀態。" -ForegroundColor Yellow }
} else {
    Write-Host "無變更可提交，跳過首次提交。" -ForegroundColor Yellow
}


Write-Host "`n🚀 專案初始化成功！現在可以啟動 VS Code 並進入 Agent Mode。" -ForegroundColor Yellow
