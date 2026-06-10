# Project Context

## 專案目的
AI 開發工作流模板（ai-dev-workflow）— 提供六階段工作流、Agent 分層、Skill 系統，並同時支援 Copilot、Codex、Claude Code、Antigravity 的可攜工作流。

## 技術棧
- PowerShell 7+（主要工具腳本）
- Python 3.7+（跨平台 bootstrap fallback）
- Markdown（agents, skills, instructions, prompts, guides）
- Multi-CLI runtime：GitHub Copilot / VS Code Copilot Chat / OpenAI Codex / Anthropic Claude Code / Google Antigravity

## 關鍵架構決策
- Source-of-truth：`agents/`、`skills/`、`instructions/`、`prompts/`、`copilot-instructions.md`
- Portable runtime：`skills/`、`agents/`、`.agents/skills/`、`.claude/skills/`、`.agent/skills/`、`.codex/agents/`、`.claude/agents/`
- Legacy runtime mirror：`.github/**`（由 `tools/sync-dotgithub.ps1` 維護；adopter repo 則由 bootstrap 產生）
- Ownership model：`skills/` / `agents/` 為 template-managed baseline，`AGENTS.md` / `CLAUDE.md` / `GEMINI.md` 為 project-owned，CLI runtime 為 derived runtime
- Update model：`bootstrap --update` 依 `.ai-workflow-install.json` 判斷哪些檔案仍可安全更新，避免覆蓋 adopter repo 的 forked workflow customizations
- 六階段工作流：Brainstorm → Spec → Plan → TDD → Review → Archive
- Change package 存放於 `changes/YYYY-MM-DD-<slug>/`

## 重要工具
- `tools/sync-dotgithub.ps1` — 同步 template repo source 到 `.github/`
- `scripts/bootstrap.ps1` / `scripts/bootstrap.py` — 安裝與更新 adopter repo runtime，並寫入 `.ai-workflow-install.json`
- `tools/audit-catalog.ps1` — 檢查 agent/skill/prompt 數量一致性
- `tools/check-sync.ps1` — 確認有無未同步的漂移
