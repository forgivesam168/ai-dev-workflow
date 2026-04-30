# Specification: AI 開發團隊擴張 v2

## Overview

擴展 ai-dev-workflow template 的 agent roster，加入 PM、Frontend Designer、DBA 三個新角色，同時修正 specification / prd 兩個 skill 的品質問題，並更新文件與 audit 腳本。

## Goals

1. 建立 PM agent（跨 session 狀態追蹤、workflow 路由、PRD 起草）
2. 建立 Frontend Designer agent（UI/UX 設計規格、component spec、accessibility）
3. 建立 DBA agent（schema 設計、migration safety、query optimization）
4. 修正 specification skill（Financial Systems 改為 (if applicable) 條件式）
5. 修正 prd skill（加入 change-package 整合：輸出路徑、stage 定位、next-step）
6. 更新 AGENTS.md（agent/skill count、roster table）
7. 更新 audit-catalog.ps1（$ExpectedAgentCount 6 → 9）

## Non-Goals

- Agency Swarm / 自動代理委派（L2/L3 自主化）
- 建立新 skill（使用現有 skill 配對）
- 修改現有 6 個 agent
- Profile/preset 系統（留待 Phase 3）

## User Stories

### PM Agent
**As a** 開發者管理多個並行專案，
**I want** 一個可以快速告訴我所有進行中 change package 當前階段的 agent，
**So that** 我不需要仰賴 session 記憶就能重建工作上下文。

**Acceptance Criteria**:
- [ ] pm.agent.md 存在，≤25 non-empty lines
- [ ] Agent 描述包含 stage detection 邏輯（透過 changes/ 目錄掃描）
- [ ] 配對 workflow-orchestrator skill
- [ ] 支援 PRD 起草（策略型專案）

### Frontend Designer Agent
**As a** 開發者需要 UI 設計規格，
**I want** 一個專注於 component spec 與 accessibility 的設計型 agent，
**So that** 前端實作有清楚的設計合約。

**Acceptance Criteria**:
- [ ] frontend-designer.agent.md 存在，≤25 non-empty lines
- [ ] 包含 4 個 Core Mandates（design-first / accessibility / design system / responsive）
- [ ] 配對 frontend-patterns skill

### DBA Agent
**As a** 開發者需要資料庫設計，
**I want** 一個專注於 schema 設計與 migration safety 的資料庫 agent，
**So that** schema 變更安全可追蹤。

**Acceptance Criteria**:
- [ ] dba.agent.md 存在，≤25 non-empty lines
- [ ] 包含 No Floats for Money mandate
- [ ] 包含 migration safety（up + down scripts）mandate
- [ ] 配對 sql.instructions.md

### Skill 修正
**Acceptance Criteria**:
- [ ] specification skill 的 Financial Systems section 改為 (if applicable) 條件式
- [ ] prd skill 包含輸出路徑（00-prd.md）、stage 定位（optional between brainstorm and spec）、next-step 指引

### 文件與腳本更新
**Acceptance Criteria**:
- [ ] AGENTS.md agent count = 9，skill count = 31
- [ ] AGENTS.md roster table 包含 pm-agent / frontend-designer-agent / dba-agent
- [ ] audit-catalog.ps1 $ExpectedAgentCount = 9
- [ ] sync-dotgithub.ps1 通過，9 agents 同步到 .github/agents/

## Technical Constraints

- 所有 agent 檔案必須 ≤25 non-empty lines（AGENTS.md 規範）
- 新 agent 必須有 YAML frontmatter: name / description / tools
- Sync 後 .github/agents/ 必須有 9 個 .agent.md 檔案
