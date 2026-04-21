# Project Context

## 專案目的
AI 開發工作流模板（ai-dev-workflow）— 提供六階段工作流、Agent 分層、Skill 系統給 Copilot-first 開發團隊。

## 技術棧
- PowerShell 7+（工具腳本）
- GitHub Copilot CLI / VS Code Copilot Chat
- Markdown（agents, skills, instructions, prompts）

## 關鍵架構決策
- Source-of-truth：gents/, skills/, instructions/, prompts/（頂層）
- Runtime mirror：.github/**（由 	ools/sync-dotgithub.ps1 同步）
- 六階段工作流：Brainstorm → Spec → Plan → TDD → Review → Archive
- Change package 存放於 changes/YYYY-MM-DD-<slug>/

## 重要工具
- 	ools/sync-dotgithub.ps1 — 同步 source 到 .github/
- 	ools/audit-catalog.ps1 — 檢查 agent/skill/prompt 數量一致性
- 	ools/check-sync.ps1 — 確認有無未同步的漂移