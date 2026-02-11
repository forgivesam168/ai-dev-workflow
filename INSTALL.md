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

#### Option 1: Direct Bootstrap (Quickest)

**Windows (PowerShell):**
```powershell
# Navigate to your project
cd C:\Projects\YourProject

# Download and run bootstrap
Invoke-WebRequest -Uri "https://raw.githubusercontent.com/forgivesam168/ai-dev-workflow/main/scripts/bootstrap.ps1" -OutFile "bootstrap.ps1"
.\bootstrap.ps1

# Clean up
Remove-Item bootstrap.ps1
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
- `.github/` directory with agents, instructions, prompts, skills
- `.github/mcp.json` for MCP server configuration
- `.gitattributes` for cross-platform line ending normalization
- Git repository initialization (if not already present)

**What Gets Preserved:**
- `.github/workflows/` (your CI/CD pipelines)
- `.github/CODEOWNERS` (your code owners)
- `.github/dependabot.yml` (your dependency config)

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

#### Option 2: Manual Clone and Initialize

```bash
# Clone the template
git clone https://github.com/forgivesam168/ai-dev-workflow.git my-new-project
cd my-new-project

# Remove original git history (optional)
rm -rf .git
git init

# Deploy workflow to .github/
pwsh .\Init-Project.ps1

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
# Verify .github directory
ls .github/agents/      # Should have 5 agent files
ls .github/skills/      # Should have 24 skill directories
ls .github/instructions/ # Should have instruction files
ls .github/prompts/     # Should have 10 prompt files

# Verify root files
cat .gitattributes      # Line ending normalization config
cat .github/mcp.json    # MCP server configuration
```

### Step 2: Verify Agent Files

```bash
# Should exist:
# .github/agents/architect.agent.md
# .github/agents/coder.agent.md
# .github/agents/code-reviewer.agent.md
# .github/agents/plan.agent.md
# .github/agents/spec.agent.md
```

### Step 3: Initial Commit

```bash
# Stage all workflow files
git add .github/ .gitattributes

# Commit
git commit -m "chore: initialize AI development workflow

- Add agents (architect, coder, code-reviewer, plan, spec)
- Add 24 skills for specialized capabilities
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

```bash
# Navigate to your project
cd ~/Projects/YourProject

# Run bootstrap in update mode (creates automatic backup)
pwsh ~/ai-dev-workflow/scripts/bootstrap.ps1 --update

# Review changes
git diff .github/

# Commit if satisfied
git add .github/
git commit -m "chore: update AI workflow to latest version"
git push
```

**Update mode features:**
- Automatically creates backup (`.github.backup-YYYYMMDD-HHMMSS/`)
- Checks for uncommitted changes before updating
- Prompts for confirmation if changes detected
- Force overwrites conflicting files

---

## 🆘 Troubleshooting

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
git diff .github/

# Option 2: Force overwrite (creates backup first)
pwsh bootstrap.ps1 --force --backup

# Option 3: Update mode (checks Git status first)
pwsh bootstrap.ps1 --update
```

---

## 🎯 Next Steps

After successful installation:

1. **Review the Workflow**: Read `WORKFLOW.md` for detailed workflow documentation
2. **Explore Skills**: Browse `.github/skills/` to understand available capabilities
3. **Customize Instructions**: Edit `.github/instructions/` for your tech stack
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
