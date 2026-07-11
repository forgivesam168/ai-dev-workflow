# Installation Guide

This guide helps new team members install and configure the AI development workflow in their projects.

## 📋 Prerequisites

### Required
- **Git**: Version 2.0 or higher
- **PowerShell 7+** (Windows) or **Python 3.7+** (macOS/Linux)

### Optional
- **Node.js**: Version 16+ (required for MCP servers like context7, memory)
- **GitHub CLI**: Version 2.0+ (optional, for template features)

### Check Your Environment

```bash
# Windows (PowerShell)
git --version
pwsh --version
node --version

# macOS/Linux
git --version
python3 --version
node --version
```

---

## 🚀 Installation Scenarios

### Scenario A: Add Workflow to Existing Project (Recommended)

This is the most common use case: adding the AI workflow to your existing project without disrupting your current setup.

#### Option 1: Direct Bootstrap with Auto Remote Mode (Quickest) ⭐ NEW

The bootstrap script now automatically detects when it's not in the template repository and downloads files from GitHub.

**Windows (PowerShell):**

⚠️ **First-time users**: PowerShell may block script execution. Use Bypass mode:

```powershell
# Navigate to your project
cd C:\Projects\YourProject

# Download bootstrap script
Invoke-WebRequest -Uri "https://raw.githubusercontent.com/forgivesam168/ai-dev-workflow/main/scripts/bootstrap.ps1" -OutFile "bootstrap.ps1"

# Run with Bypass mode (recommended for first-time users)
pwsh -ExecutionPolicy Bypass -File .\bootstrap.ps1

# Clean up
Remove-Item bootstrap.ps1
```

**Alternative: Set execution policy once** (requires user permission):
```powershell
# One-time setup (only needed once per machine)
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser

# Then you can run scripts normally
.\bootstrap.ps1
```

**Explicit Remote Mode (Custom Repository):**
```powershell
# If you have a fork or custom template repository
pwsh -ExecutionPolicy Bypass -File .\bootstrap.ps1 -RemoteRepo "https://github.com/your-org/your-template.git"
```

**macOS/Linux (Python):**
```bash
# Navigate to your project
cd ~/Projects/YourProject

# Download and run bootstrap
curl -O https://raw.githubusercontent.com/forgivesam168/ai-dev-workflow/main/scripts/bootstrap.py
python3 bootstrap.py

# Clean up
rm bootstrap.py
```

**Linux/macOS (Bash):**
```bash
# Navigate to your project
cd ~/Projects/YourProject

# Download and run bootstrap
curl -O https://raw.githubusercontent.com/forgivesam168/ai-dev-workflow/main/scripts/bootstrap.sh
chmod +x bootstrap.sh
./bootstrap.sh

# Clean up
rm bootstrap.sh
```

#### Option 2: Clone Template and Bootstrap

```bash
# Clone the template repository (one-time setup)
git clone https://github.com/forgivesam168/ai-dev-workflow.git ~/ai-dev-workflow

# Navigate to your project
cd ~/Projects/YourProject

# Run bootstrap from template
pwsh ~/ai-dev-workflow/scripts/bootstrap.ps1
# Or: python3 ~/ai-dev-workflow/scripts/bootstrap.py
# Or: bash ~/ai-dev-workflow/scripts/bootstrap.sh
```

**What Gets Installed:**
- Legacy `.github/` compatibility layer for Copilot / VS Code workflows
- Shared `skills/` library at the project root
- Shared `agents/` persona source at the project root
- `.agents/skills/`, `.claude/skills/`, `.agent/skills/` mounts that point to the shared skill library
- Generated `.codex/agents/` and `.claude/agents/` custom agents
- `AGENTS.md`, `CLAUDE.md`, `GEMINI.md` project guidance files
- `.ai-workflow-install.json` ownership/update manifest
- `.gitattributes` for cross-platform line ending normalization
- Git repository initialization (if not already present)

**Session reload note:**
- After first install or update, start a new Codex / Claude session so the new skills and generated custom agents are loaded.
- In Codex CLI, use `/skills` to inspect installed skills and `$skill-name` for explicit invocation.

**What Gets Preserved:**
- `.github/workflows/` (your CI/CD pipelines)
- `.github/CODEOWNERS` (your code owners)
- `.github/dependabot.yml` (your dependency config)

**Ownership rules after installation:**
- Edit and commit workflow customizations in `skills/` and `agents/`.
- Treat `.github/skills/`, `.github/agents/`, `.codex/agents/`, `.claude/agents/`, and the skill mounts as derived runtime.
- Treat `AGENTS.md`, `CLAUDE.md`, and `GEMINI.md` as project-owned guidance files.

---

### Scenario B: Create New Project from Template

#### Option 1: GitHub Template (Easiest)

1. Visit https://github.com/forgivesam168/ai-dev-workflow
2. Click **"Use this template"** → **"Create a new repository"**
3. Fill in repository details and create
4. Clone your new repository:
   ```bash
   git clone https://github.com/your-org/your-new-project.git
   cd your-new-project
   ```

#### Option 2: Manual Clone and Bootstrap

```bash
# Clone the template as a starting point
git clone https://github.com/forgivesam168/ai-dev-workflow.git my-new-project
cd my-new-project

# Remove original git history and start fresh
rm -rf .git
git init -b main

# Deploy workflow assets from the cloned template
pwsh -ExecutionPolicy Bypass -File .\scripts\bootstrap.ps1 -TargetPath .

# Commit initial setup
git add .
git commit -m "chore: initialize project with AI workflow"
```

---

### Scenario C: Reference Only (No Installation)

If you just want to learn or reference the workflow:

```bash
git clone https://github.com/forgivesam168/ai-dev-workflow.git
cd ai-dev-workflow

# Browse documentation
cat README.md          # Project overview
cat QUICKSTART.md      # 5-minute quick start
cat WORKFLOW.md        # Complete workflow documentation
cat BOOTSTRAP-GUIDE.md # Bootstrap usage guide
```

---

## ✅ Post-Installation Verification

### Step 1: Check File Structure

```bash
# Verify legacy compatibility layer
ls .github/agents/
ls .github/skills/
ls .github/instructions/
ls .github/prompts/

# Verify portable runtime
ls skills/
ls agents/
ls .agents/skills/
ls .claude/skills/
ls .codex/agents/
cat AGENTS.md
cat CLAUDE.md
cat GEMINI.md

# Verify root files
cat .gitattributes
cat .github/mcp.json
```

### Step 2: Verify Agent Files

```bash
# Legacy compatibility examples:
# .github/agents/architect.agent.md
# .github/agents/coder.agent.md
#
# Portable runtime examples:
# .codex/agents/coder.toml
# .claude/agents/coder.md
```

### Step 3: Initial Commit

```bash
# Stage all workflow files
git add .github/ skills/ agents/ .agents/ .agent/ .claude/ .codex/ AGENTS.md CLAUDE.md GEMINI.md .ai-workflow-install.json .gitattributes

# Commit
git commit -m "chore: initialize AI development workflow

- Add agents (architect, coder, code-reviewer, plan, spec)
- Add 34 adopter skills for specialized capabilities (`gate-check` remains maintainer-only and is not deployed)
- Add instructions for coding standards
- Add MCP configuration (context7, memory)
- Add .gitattributes for line ending normalization"

# Push to remote
git push origin main
```

---

## 🔧 MCP Server Configuration (Optional)

The workflow includes MCP (Model Context Protocol) server configuration for enhanced AI capabilities.

### Included MCP Servers

| Server | Purpose | Requirements |
|--------|---------|--------------|
| `context7` | Library documentation lookup | Node.js + npx |
| `memory` | Conversation memory across sessions | Node.js + npx |

### Configuration Files

- **GitHub Copilot CLI**: `.github/mcp.json` (automatically used)
- **VS Code**: `.vscode/mcp.json` (needs manual copy)

### Setup for VS Code Users

```bash
# Copy MCP config to VS Code directory
cp .github/mcp.json .vscode/mcp.json

# Note: .vscode/ is gitignored, so this is per-developer
```

### Verify MCP Servers

**Copilot CLI:**
```bash
copilot
> /mcp show
```

**VS Code:**
- Restart VS Code
- Open Copilot Chat
- MCP tools should appear automatically

### Adding Custom MCP Servers

Edit `.github/mcp.json` (and `.vscode/mcp.json` if using VS Code):

```json
{
  "mcpServers": {
    "context7": { /* existing config */ },
    "memory": { /* existing config */ },
    "your-custom-server": {
      "type": "stdio",
      "command": "npx",
      "args": ["-y", "@your-org/your-mcp-server"],
      "tools": ["*"]
    }
  }
}
```

For servers requiring API keys, use environment variables:

```json
{
  "mcpServers": {
    "brave-search": {
      "type": "stdio",
      "command": "npx",
      "args": ["-y", "@modelcontextprotocol/server-brave-search"],
      "env": {
        "BRAVE_API_KEY": "${BRAVE_API_KEY}"
      },
      "tools": ["*"]
    }
  }
}
```

Set environment variables:

```powershell
# Windows
$env:BRAVE_API_KEY = "your-api-key-here"

# macOS/Linux
export BRAVE_API_KEY="your-api-key-here"
```

---

## 🤖 Custom Model Providers

Copilot CLI supports connecting to custom AI model providers for compliance or offline scenarios.

### Minimum Requirements

Your model must support:
- **Context window**: 128k+ tokens
- **Tool calling**: Required for agent functionality
- **Streaming**: Required for real-time output

### Azure OpenAI

```bash
# Set environment variables
export COPILOT_PROVIDER_TYPE=azure-openai
export COPILOT_PROVIDER_BASE_URL=https://your-resource.openai.azure.com
export AZURE_OPENAI_API_KEY=your-api-key
export AZURE_OPENAI_DEPLOYMENT=gpt-4o

# Start Copilot CLI with Azure OpenAI
gh copilot chat
```

### Ollama (Local Models)

For fully offline development:

```bash
# Start Ollama with a compatible model
ollama pull qwen2.5-coder:32b

# Configure Copilot CLI
export COPILOT_PROVIDER_TYPE=ollama
export COPILOT_PROVIDER_BASE_URL=http://localhost:11434
export COPILOT_PROVIDER_MODEL=qwen2.5-coder:32b

gh copilot chat
```

> **Note**: Local models may have reduced capability compared to cloud models. Ensure your chosen model supports tool calling.

### Environment Variables Reference

| Variable | Required | Description |
|----------|----------|-------------|
| `COPILOT_PROVIDER_TYPE` | Yes | Provider type: `azure-openai`, `ollama`, `openai-compatible` |
| `COPILOT_PROVIDER_BASE_URL` | Yes | Base URL for the API endpoint |
| `COPILOT_PROVIDER_MODEL` | No | Model name (provider-specific) |
| `AZURE_OPENAI_API_KEY` | Azure only | API key for Azure OpenAI |
| `AZURE_OPENAI_DEPLOYMENT` | Azure only | Deployment name in Azure OpenAI |

---

## 📚 Getting Started After Installation

### 1. Read Quick Start Guide

```bash
cat QUICKSTART.md
```

This 5-minute guide covers the essential workflow.

### 2. Test the Workflow Orchestrator

**Copilot CLI:**
```bash
copilot
> /workflow
```

**VS Code:**
```
Open Copilot Chat and type:
@workspace /workflow
```

This shows your current workflow stage and suggests next steps.

### 3. Start Your First Feature

**Copilot CLI:**
```bash
copilot
> 我要開始一個新功能的 brainstorming
```

**VS Code:**
```
In Copilot Chat:
@workspace /brainstorm
```

The system will guide you through the 6-stage workflow.

---

## 🔄 Updating the Workflow

To update to the latest workflow version:

> **Note**: If you used Scenario A Option 1 (download → run → delete), you no longer have `bootstrap.ps1` locally. Re-download it to your project root and the script will automatically enter Remote Mode, pulling the latest template from GitHub.

**Windows (PowerShell) — Re-download and update:**

```powershell
# Navigate to your project
cd C:\Projects\YourProject

# Re-download bootstrap script
Invoke-WebRequest -Uri "https://raw.githubusercontent.com/forgivesam168/ai-dev-workflow/main/scripts/bootstrap.ps1" -OutFile "bootstrap.ps1"

# Run in update mode (auto-detects remote mode, creates backup)
pwsh -ExecutionPolicy Bypass -File .\bootstrap.ps1 -Update

# Review changes
git diff .github/ skills/ agents/ .agents/ .agent/ .claude/ .codex/ AGENTS.md CLAUDE.md GEMINI.md .ai-workflow-install.json

# Commit if satisfied
git add .github/ skills/ agents/ .agents/ .agent/ .claude/ .codex/ AGENTS.md CLAUDE.md GEMINI.md .ai-workflow-install.json
git commit -m "chore: update AI workflow to latest version"
git push

# Clean up
Remove-Item bootstrap.ps1
```

**macOS/Linux — Re-download and update:**

```bash
# Navigate to your project
cd ~/Projects/YourProject

# Re-download and run in update mode
curl -O https://raw.githubusercontent.com/forgivesam168/ai-dev-workflow/main/scripts/bootstrap.py
python3 bootstrap.py --update

# Review and commit
git diff .github/ skills/ agents/ .agents/ .agent/ .claude/ .codex/ AGENTS.md CLAUDE.md GEMINI.md .ai-workflow-install.json
git add .github/ skills/ agents/ .agents/ .agent/ .claude/ .codex/ AGENTS.md CLAUDE.md GEMINI.md .ai-workflow-install.json
git commit -m "chore: update AI workflow to latest version"
git push

# Clean up
rm bootstrap.py
```

**If you have the template repo cloned locally:**

```powershell
# Run update directly from your local clone
pwsh ~/ai-dev-workflow/scripts/bootstrap.ps1 -Update
```

**Update mode features:**
- Automatically creates backup (`.github.backup-YYYYMMDD-HHMMSS/`)
- Creates a portable runtime backup when shared paths already exist (`.ai-workflow-portable.backup-YYYYMMDD-HHMMSS/`)
- Checks for uncommitted changes before updating
- Prompts for confirmation if changes detected
- Preserves project-forked template-managed files by default
- Refreshes derived runtime from `skills/` and `agents/`
- Script auto-detects Remote Mode when run from project root (no local clone needed)
- Existing `AGENTS.md`, `CLAUDE.md`, and `GEMINI.md` are preserved; merge manually if you want new template wording

---

## 🔄 Migration Notes

### `gate-check` skill removed from deployed projects (v1.x+)

If you bootstrapped an earlier version of this template, your project's `.github/skills/` folder may contain a `gate-check` directory. This skill is a **template maintainer tool** and is no longer deployed to adopter projects.

**Safe to delete:**
```powershell
# Remove gate-check from your project if it was installed by an older bootstrap
Remove-Item -Recurse -Force .\.github\skills\gate-check
```

Running the updater (`bootstrap.ps1 -Update`) will not remove it automatically (the updater never deletes existing files). Manual cleanup is safe — your workflow is unaffected.

---

## 🆘 Troubleshooting

### Issue: "Scripts are disabled on this system" (PowerShell)

**Symptom:**
```
.\bootstrap.ps1 : 無法載入，因為在此系統上已停用指令碼執行。
File cannot be loaded because running scripts is disabled on this system.
```

**Cause:** PowerShell execution policy blocks unsigned scripts (default Windows security).

**Solution (Choose One):**

**Option A: Use Bypass mode (Recommended - No system changes)**
```powershell
# Run with Bypass for this execution only
pwsh -ExecutionPolicy Bypass -File .\bootstrap.ps1
```

**Option B: Set execution policy for current user (One-time setup)**
```powershell
# Allow signed scripts for your user account
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser

# Then run normally
.\bootstrap.ps1
```

**Option C: Use Python instead (Cross-platform alternative)**
```bash
# Download and run Python version
curl -sO https://raw.githubusercontent.com/forgivesam168/ai-dev-workflow/main/scripts/bootstrap.py
python bootstrap.py
```

---

### Issue: "Git is required but not found"

**Solution:**
```bash
# Install Git
# Windows: winget install Git.Git
# macOS: brew install git
# Linux: sudo apt-get install git
```

### Issue: "Python version too old"

**Solution:**
```bash
# Upgrade Python to 3.7+
# Windows: winget install Python.Python.3
# macOS: brew install python@3.11
# Linux: sudo apt-get install python3.11
```

### Issue: "MCP servers not loading"

**Solution:**
```bash
# Install Node.js
# Windows: winget install OpenJS.NodeJS
# macOS: brew install node
# Linux: sudo apt-get install nodejs npm

# Verify installation
node --version  # Should be >= 16.0
npx --version
```

### Issue: "Permission denied" (macOS/Linux)

**Solution:**
```bash
# Make script executable
chmod +x bootstrap.sh

# Or run with explicit interpreter
bash bootstrap.sh
```

### Issue: ".github/workflows/ was overwritten"

**Explanation:** This should NOT happen. Bootstrap explicitly excludes `workflows/`, `CODEOWNERS`, and `dependabot.yml`.

**If it happens:**
```bash
# Restore from backup
mv .github.backup-YYYYMMDD-HHMMSS/workflows/ .github/

# Or restore from Git
git checkout HEAD -- .github/workflows/
```

### Issue: "Conflicts detected but not overwritten"

**Explanation:** Bootstrap detected files with different content but didn't overwrite them (safe mode).

**Solution:**
```bash
# Option 1: Review conflicts and decide manually
git diff .github/ skills/ agents/ .agents/ .agent/ .claude/ .codex/ AGENTS.md CLAUDE.md GEMINI.md .ai-workflow-install.json

# Option 2: Force overwrite template-managed files
pwsh bootstrap.ps1 -Force -Backup

# Option 3: Update mode (preserves project forks, refreshes derived runtime)
pwsh bootstrap.ps1 -Update
```

**Rule of thumb:**
- If you customized a shared workflow capability, edit `skills/` or `agents/`.
- Do not hand-edit `.github/skills/`, `.github/agents/`, `.codex/agents/`, or `.claude/agents/`; bootstrap will regenerate them.
- Commit `.ai-workflow-install.json` so the next `--update` knows which files are still safe to refresh automatically.

---

## 🎯 Next Steps

After successful installation:

1. **Review the Workflow**: Read `WORKFLOW.md` for detailed workflow documentation
2. **Explore Skills**: Browse `skills/` (source of truth) to understand available capabilities
3. **Customize Instructions**: Edit `.github/instructions/` plus `AGENTS.md` / `CLAUDE.md` / `GEMINI.md` for your team and toolchain
4. **Try the Agents**: Use `/workflow` to start your first feature
5. **Share with Team**: Send this guide to new team members

---

## 📞 Support

For issues or questions:

1. Check this guide first
2. Review `BOOTSTRAP-GUIDE.md` for technical details
3. Check `QUICKSTART.md` for workflow basics
4. Open an issue in the repository
5. Contact your team's AI workflow maintainer

---

**Version**: February 2026  
**Compatible with**: Windows 10+, macOS 12+, Linux (Ubuntu 20.04+)  
**Requirements**: Git 2.0+, PowerShell 7+ or Python 3.7+  
**Repository**: https://github.com/forgivesam168/ai-dev-workflow
