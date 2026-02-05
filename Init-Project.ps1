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
    )
    foreach ($file in $ProjectFiles) {
        $SourceFile = Join-Path $TemplateSource $file
        if (Test-Path $SourceFile) {
            Copy-Item $SourceFile ".\$file" -Force
            Write-Host "📄 部署專案檔案: $file" -ForegroundColor Gray
        }
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
"@
if (!(Test-Path ".gitignore")) {
    Set-Content -Path ".gitignore" -Value $GitIgnoreContent -Encoding utf8
}

# 執行首次提交
git add .
git commit -m "Initial commit: 架構與 AI Agent 規則部署"
Write-Host "✅ 首次提交完成，已包含 AI Agent 與技術規範" -ForegroundColor Green


Write-Host "`n🚀 專案初始化成功！現在可以啟動 VS Code 並進入 Agent Mode。" -ForegroundColor Yellow
