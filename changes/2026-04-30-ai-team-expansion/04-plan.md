# Implementation Plan: AI 開發團隊擴張

## Overview

本計畫描述 2026-04-30 執行的 AI 開發團隊擴張工作。底層哲學：L1 Human-Gated，AI 寫文件 → 人確認 → AI 執行 → AI 自審。

**Spec Reference**: `03-spec.md`

## Implementation Strategy

### Approach
Bottom-up: 先建 agent files → 修 skills → 更新 AGENTS.md → 更新 audit script → sync → commit

---

## Phase 1: 修正現有 Skills

### Task 1.1: specification skill — Financial Systems 條件化
- **File**: `skills/specification/SKILL.md`
- **Change**: "Financial Systems Specific" → "Domain-Specific (if applicable)" 包含金融/個資/法遵三種條件區塊
- **Acceptance**: 非金融域開發者不會看到強制的金融問題

### Task 1.2: prd skill — change-package 整合
- **File**: `skills/prd/SKILL.md`
- **Change**: 加入 stage position note、output path (00-prd.md)、when-to-use 更新、next-step 指引
- **Acceptance**: prd skill 是工作流的一級公民，有明確輸出路徑

---

## Phase 2: 建立新 Agent Files

### Task 2.1: PM Agent
- **File**: `agents/pm.agent.md`
- **Content**: Stage detection table（changes/ 掃描邏輯）、Core Duties（狀態追蹤/路由/PRD）
- **Acceptance**: ≤25 non-empty lines，配 workflow-orchestrator skill

### Task 2.2: Frontend Designer Agent
- **File**: `agents/frontend-designer.agent.md`
- **Content**: 4 Core Mandates（design-first/accessibility/design system/responsive）、Deliverables
- **Acceptance**: ≤25 non-empty lines，配 frontend-patterns skill

### Task 2.3: DBA Agent
- **File**: `agents/dba.agent.md`
- **Content**: 4 Core Mandates（schema-first/migration safety/no floats/index discipline）、Deliverables
- **Acceptance**: ≤25 non-empty lines，配 sql.instructions.md

---

## Phase 3: 更新文件與腳本

### Task 3.1: AGENTS.md
- agent count: 6 → 9
- skill count: 30 → 31（修正已存在的 drift）
- roster table: 新增 pm-agent / frontend-designer-agent / dba-agent

### Task 3.2: audit-catalog.ps1
- $ExpectedAgentCount: 6 → 9
- 新增 phase comment

---

## Phase 4: 同步與驗證

- `pwsh -File .\tools\sync-dotgithub.ps1`
- 確認 .github/agents/ 有 9 個 .agent.md 檔案
- 確認 audit-catalog.ps1 全部 PASS

---

## Dependencies

- 無外部依賴（只修改 template 內部文件）
- 新 agent 依賴現有 skill（frontend-patterns / sql.instructions / workflow-orchestrator）

## Exit Criteria

- [ ] audit-catalog.ps1 全部 PASS（9 agents / 10 prompts / 31 skills）
- [ ] sync-dotgithub.ps1 通過
- [ ] 所有 agent ≤25 non-empty lines
- [ ] commit 包含 source + .github/** 同步產物
