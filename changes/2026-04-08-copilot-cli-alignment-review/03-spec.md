# Specification: Copilot CLI 對齊 + 指令架構重構

> **狀態**：Ready for Review
> **日期**：2026-04-08
> **關聯 Brainstorm**：`01-brainstorm.md`
> **關聯決策**：`02-decision-log.md`（Decision #1–#9）

---

## Overview

本專案 `ai-dev-workflow` 定位為「金融等級 AI 開發工作流模板」，經深度審計 Copilot CLI 官方文件後發現 **15+ 項功能缺口** 及 **指令架構層級疊加問題**（copilot-instructions.md 有 56% 內容與 agents/skills/WORKFLOW.md 重複）。此規格涵蓋兩大工作包：**Part A — 功能缺口修補**（安全機制、文件補充）、**Part B — 指令架構重構**（Pointer-Style Guidance）。

## Context

- Copilot CLI 與 VS Code Copilot 功能已高度一致，本專案的 skills/agents/instructions 需同時適用兩個平台
- `copilot-instructions.md` 在每次互動都載入（~1,965 tokens），其中 56%+ 內容在 agents/skills 中重複
- 現有 29 個 skills，但文件標示為 24 個；`plan-from-spec` 與 `implementation-planning` 功能重複
- `SECURITY.md` 僅 5 行 placeholder，不符合金融級模板定位

## Goals

1. **安全強化**：透過 Copilot Hooks 實現命令攔截、secret scanning、稽核日誌
2. **文件完整**：補充 Copilot Memory、Custom Model Provider、MCP、Plan Mode 等缺失文件
3. **架構精簡**：將 copilot-instructions.md 從 ~108 行精簡至 ≤40 行（Pointer-Style Guidance）
4. **消除重複**：精簡 5 個 agent 檔案，合併重複 skill，統一 severity 命名
5. **數字一致**：所有文件中的 skills/agents 數量統一正確

## Non-Goals

- 不重寫 6-Stage Workflow 核心設計
- 不新增 `.agents/skills/` 目錄位置支援（LOW，留待未來）
- 不整合 ACP (Agent Communication Protocol)
- 不新增 Programmatic CLI CI/CD 範例
- 不全面審查所有 skill 的 `allowed-tools` frontmatter
- 不變更 `instructions/*.instructions.md` 的內容（已良好設計）

---

## User Stories

### Story 1: 模板使用者 需要安全防護

**As a** 金融工程團隊的開發者
**I want** Copilot CLI 自動攔截危險命令（如 `rm -rf /`、`DROP TABLE`、`git push --force`）
**So that** 我不會在 AI 協作開發中誤執行破壞性操作

**Acceptance Criteria**:
- [ ] AC-1.1: `.github/hooks/` 目錄存在且包含有效的 hook 設定檔
- [ ] AC-1.2: `preToolUse` hook 能攔截至少 5 類危險命令模式
- [ ] AC-1.3: `preToolUse` hook 能掃描輸出中的 secret patterns（API keys、tokens）
- [ ] AC-1.4: `sessionStart` hook 記錄 session 啟動（使用者、時間、模式）
- [ ] AC-1.5: `postToolUse` hook 記錄工具執行結果（command、exit code）
- [ ] AC-1.6: Hook 設定有對應的 skill 文件說明如何自訂

**Edge Cases**:
- Hook 腳本執行逾時（>5 秒）→ 應自動放行並記錄警告（fail-open，依 Decision #6）
- Hook 腳本語法錯誤 → 應 fail-open（不阻塞開發）並記錄錯誤
- 使用者使用 `--yolo` 模式 → Hook 仍應執行但可設定為 warn-only

### Story 2: 模板使用者 需要了解 Copilot Memory 的影響

**As a** 團隊 Tech Lead
**I want** 清楚理解 Copilot Memory 與現有 instructions 的關係
**So that** 我能決定是否啟用 Memory 且不會與精心設計的規範產生衝突

**Acceptance Criteria**:
- [ ] AC-2.1: 文件說明 Copilot Memory 是什麼、自動學習機制、28 天過期特性
- [ ] AC-2.2: 文件明確定位 Memory 為「輔助」、instructions 為「SSOT」
- [ ] AC-2.3: 文件包含管理者操作：如何檢視、刪除 Memory
- [ ] AC-2.4: 文件包含建議策略（啟用 Memory + instructions 作為 SSOT）

**Edge Cases**:
- Memory 學到的 pattern 與 instruction 衝突 → 文件應說明 instructions 優先
- Enterprise 管理者禁用 Memory → 文件應說明如何確認 Memory 狀態

### Story 3: 合規敏感團隊 需要 Azure OpenAI 配置指引

**As a** 在受監管環境工作的開發者
**I want** 知道如何將 Copilot CLI 連接到 Azure OpenAI（資料駐留合規）
**So that** 程式碼不會離開指定的資料中心

**Acceptance Criteria**:
- [ ] AC-3.1: INSTALL.md 包含 Custom Model Provider 設定章節
- [ ] AC-3.2: 包含 Azure OpenAI 完整配置範例（環境變數）
- [ ] AC-3.3: 說明 Ollama 本地模型配置（離線/開發場景）
- [ ] AC-3.4: 說明模型最低需求（128k+ context、tool calling、streaming）
- [ ] AC-3.5: 說明 `COPILOT_PROVIDER_BASE_URL`、`COPILOT_PROVIDER_TYPE` 環境變數

**Edge Cases**:
- 模型不支援 tool calling → 文件應說明降級行為
- API endpoint 不可達 → 文件應說明 fallback 策略

### Story 4: LLM 需要精簡的指令上下文

**As a** Copilot 底層的 LLM
**I want** copilot-instructions.md 只包含安全紅線和語言規範（≤40 行）
**So that** 我的 context window 不會被重複內容浪費，能更專注於使用者的實際需求

**Acceptance Criteria**:
- [ ] AC-4.1: `copilot-instructions.md` ≤40 非空行
- [ ] AC-4.2: 保留 Communication Style 完整內容（繁體中文、Git commit 格式、語氣）
- [ ] AC-4.3: 保留 Financial Precision Safety Check（no float、verify boundaries）
- [ ] AC-4.4: §1 Rule of Law 精簡為 1-2 行指標（→ `instructions/` 目錄）
- [ ] AC-4.5: §2 Agent Personas 完全替換為 1 行指標（→ `agents/*.agent.md`）
- [ ] AC-4.6: §3 6-Stage Workflow 完全替換為 2 行指標（→ `WORKFLOW.md` + `skills/workflow-orchestrator/`）
- [ ] AC-4.7: 重構前後所有現有 skill/agent 功能不受影響（行為不變）

**Edge Cases**:
- 新使用者未讀過 WORKFLOW.md 直接用 Copilot → 指標應包含足夠引導
- 指標指向的 skill 被刪除 → 在 sync 腳本中加入 link 檢查

### Story 5: Agent 需要精簡的角色定義

**As a** 被選中的 agent（如 plan-agent）
**I want** 我的 agent 檔案只定義我是誰（WHO）和我專注什麼
**So that** 我不會載入與 skill 重複的程序性細節，節省 context 給實際工作

**Acceptance Criteria**:
- [ ] AC-5.1: `plan.agent.md` ≤25 非空行（現 57 行），保留角色定義和核心原則
- [ ] AC-5.2: `spec.agent.md` ≤25 非空行（現 36 行），保留 persona 和 Core Principles
- [ ] AC-5.3: `architect.agent.md` ≤25 非空行（現 34 行），保留 persona 和專注領域
- [ ] AC-5.4: `coder.agent.md` ≤25 非空行（現 29 行），保留環境設定
- [ ] AC-5.5: `code-reviewer.agent.md` ≤25 非空行（現 27 行），保留 enforcement persona
- [ ] AC-5.6: 每個 agent 包含 `→ 詳細流程見 skills/xxx/` 的指標
- [ ] AC-5.7: 精簡後所有 agent 的 prompt 觸發和 skill 載入行為不變

**Edge Cases**:
- Agent 的指標指向不存在的 skill → 在 sync 腳本中檢查
- 使用者選擇 agent 但不觸發 skill → agent 仍需提供足夠上下文完成基本任務

### Story 6: 重複 Skill 需要合併

**As a** 專案維護者
**I want** `plan-from-spec` 合併至 `implementation-planning`
**So that** LLM 不會在兩個幾乎相同的 skill 之間產生選擇不確定性

**Acceptance Criteria**:
- [ ] AC-6.1: `implementation-planning/SKILL.md` 新增「Simplified Mode」章節
- [ ] AC-6.2: `skills/plan-from-spec/` 目錄被刪除
- [ ] AC-6.3: 所有引用 `plan-from-spec` 的 prompt 檔案更新為引用 `implementation-planning`
- [ ] AC-6.4: `implementation-planning` description 涵蓋原 plan-from-spec 的觸發關鍵字
- [ ] AC-6.5: 合併後 skill 的 Level 1 Discovery（name + description）不超過 1024 字元

**Edge Cases**:
- 使用者習慣輸入 "plan from spec" → description 需包含此關鍵字
- `.github/skills/plan-from-spec/` 同步鏡像也需刪除

### Story 7: 文件數字需要一致

**As a** 新加入團隊的開發者
**I want** README、INSTALL、AGENTS.md 中的 skills/agents 數量一致且正確
**So that** 我不會對專案規模產生錯誤認知

**Acceptance Criteria**:
- [ ] AC-7.1: 合併後 skills 數量為 28，所有文件統一標示 28
- [ ] AC-7.2: 受影響檔案：`README.md`、`README.zh-TW.md`、`INSTALL.md`、`INSTALL.zh-TW.md`、`AGENTS.md`
- [ ] AC-7.3: Agents 數量維持 5，所有文件一致

### Story 8: SECURITY.md 需要充實

**As a** 安全審計人員
**I want** SECURITY.md 包含完整的安全策略
**So that** 我能評估此模板是否符合金融級安全要求

**Acceptance Criteria**:
- [ ] AC-8.1: 包含 Copilot CLI 安全考量（trusted directories、tool approval）
- [ ] AC-8.2: 包含 Hooks 安全策略（引用 `.github/hooks/`）
- [ ] AC-8.3: 包含 Secrets 管理規範（no hardcoded、use env vars）
- [ ] AC-8.4: 包含 `--allow-all-tools` / `--yolo` 風險說明
- [ ] AC-8.5: 包含漏洞通報流程（保留現有 email + response time）
- [ ] AC-8.6: 包含 `.github/workflows/` CODEOWNERS 要求

### Story 9: WORKFLOW.md 需要補充 CLI 互動模式

**As a** 使用 Copilot CLI 的團隊成員
**I want** WORKFLOW.md 說明 Plan Mode、Autopilot、Session 管理
**So that** 我能有效利用 Copilot CLI 的進階功能

**Acceptance Criteria**:
- [ ] AC-9.1: 說明 Plan Mode（Shift+Tab）的觸發與使用場景
- [ ] AC-9.2: 說明 Autopilot Mode（experimental）及其風險
- [ ] AC-9.3: 說明 Session 管理：`/resume`、`--continue`、`/compact`
- [ ] AC-9.4: 說明 Context 管理：`/context`、auto-compaction 機制
- [ ] AC-9.5: 說明 GitHub MCP server 是 CLI 內建的（不需額外配置）

### Story 10: AGENTS.md 需要同步新架構

**As a** 貢獻者
**I want** AGENTS.md 反映 Pointer-Style Guidance 架構
**So that** 我理解 agent/skill/instruction 的分工原則

**Acceptance Criteria**:
- [ ] AC-10.1: 說明四層架構：Constitution → Role → Playbook → Code Style
- [ ] AC-10.2: 說明每層的載入行為（always / on-select / progressive / applyTo）
- [ ] AC-10.3: Skills 數量更新為 28
- [ ] AC-10.4: 說明 agent = WHO, skill = HOW 的設計原則

---

## Functional Requirements

### Part A — 功能缺口修補

| ID | 需求 | 優先級 | 依賴 |
|----|------|--------|------|
| FR-A1 | 建立 `.github/hooks/` 安全配置（preToolUse, sessionStart, postToolUse） | Must-Have | — |
| FR-A2 | 建立 Copilot Memory 共存指引（WORKFLOW.md 新章節，依 Decision #7） | Must-Have | — |
| FR-A3 | 在 INSTALL.md 新增 Custom Model Provider 章節 | Must-Have | — |
| FR-A4 | 更新 WORKFLOW.md 補充 CLI 互動模式 | Should-Have | FR-A2 |
| FR-A5 | 修正所有文件中的 skills 數量為 28 | Should-Have | FR-B3 |
| FR-A6 | 充實 SECURITY.md 為完整安全策略文件 | Should-Have | FR-A1 |
| FR-A7 | 更新 MCP 配置說明（GitHub MCP 為 CLI 內建） | Should-Have | — |

### Part B — 指令架構重構

| ID | 需求 | 優先級 | 依賴 |
|----|------|--------|------|
| FR-B1 | 精簡 `copilot-instructions.md` 至 ≤40 非空行（Pointer-Style） | Must-Have | — |
| FR-B2 | 精簡 5 個 agent 檔案至每個 ≤25 非空行 | Must-Have | — |
| FR-B3 | 合併 `plan-from-spec` 至 `implementation-planning` | Must-Have | — |
| FR-B4 | 更新 `AGENTS.md` 反映新架構 | Should-Have | FR-B1, FR-B2, FR-B3 |
| FR-B5 | 執行 `sync-dotgithub.ps1` 同步 `.github/` 鏡像 | Must-Have | FR-B1 ~ FR-B4 |

---

## Technical Considerations

### Architecture: Pointer-Style Guidance

```
載入順序（每次互動）:
  ① copilot-instructions.md  (≤40 行, ~600 tokens)  ← 每次都載入
  ② AGENTS.md                (精簡)                   ← 每次都載入
  ③ agents/xxx.agent.md      (≤25 行, ~375 tokens)   ← 選擇 agent 時
  ④ instructions/*.md        (按 applyTo 匹配)        ← 檔案類型匹配時
  ⑤ skills/*/SKILL.md        (Level 1→2→3 漸進)       ← 相關時才載入
```

### Hooks 技術設計

**preToolUse 攔截規則**:

| 模式 | 類型 | 動作 |
|------|------|------|
| `rm -rf /` | 檔案系統破壞 | REJECT |
| `DROP TABLE`, `TRUNCATE` | 資料庫破壞 | REJECT |
| `git push --force` | Git 歷史覆寫 | REJECT |
| `chmod 777` | 權限開放 | REJECT |
| `curl \| sh`, `wget \| bash` | 遠端執行 | REJECT |
| API key / token patterns | Secret 洩漏 | WARN + 記錄 |

### Severity 命名統一（依 Decision #8）

統一為：🔴 Critical / 🟡 High / 🟢 Medium / ⚪ Low

---

## Impact Analysis (Brownfield)

### 受影響檔案清單

| 檔案 | 變更類型 | 風險 |
|------|---------|------|
| `copilot-instructions.md` | **重寫** | 🔴 High |
| `agents/plan.agent.md` | **大幅精簡** | 🟡 Medium |
| `agents/spec.agent.md` | 精簡 | 🟢 Low |
| `agents/architect.agent.md` | 精簡 | 🟢 Low |
| `agents/coder.agent.md` | 精簡 | 🟢 Low |
| `agents/code-reviewer.agent.md` | 精簡 | 🟢 Low |
| `AGENTS.md` | 更新 | 🟢 Low |
| `skills/implementation-planning/SKILL.md` | 新增章節 | 🟡 Medium |
| `skills/plan-from-spec/` | **刪除** | 🟡 Medium |
| `SECURITY.md` | **重寫** | 🟢 Low |
| `WORKFLOW.md` | 新增章節 | 🟢 Low |
| `INSTALL.md` / `INSTALL.zh-TW.md` | 新增章節 | 🟢 Low |
| `README.md` / `README.zh-TW.md` | 數字修正 | ⚪ Low |
| `.github/hooks/` | **新增** | 🟡 Medium |
| `.github/**` (sync mirror) | 自動同步 | ⚪ Low |
| `tools/sync-dotgithub.ps1` | 微調 | ⚪ Low |

### Rollback Strategy

- Git revert 可完整回滾所有變更
- Hooks：刪除 `.github/hooks/` 即可停用
- 精簡檔案：Git revert 恢復原始版本

---

## Success Metrics

1. **Context 節省**：copilot-instructions.md tokens 減少 ≥60%（從 ~1,620 → ≤650 tokens）
2. **零功能退化**：重構後所有 skill/agent 觸發行為與重構前一致
3. **安全覆蓋**：Hooks 能攔截 5+ 類危險命令模式
4. **文件完整**：所有 HIGH/MEDIUM 功能缺口補齊
5. **數字一致**：所有文件中的 skills/agents 數量一致

---

## Open Questions（已決議）

| # | 問題 | 決議 | Decision # |
|---|------|------|-----------|
| 1 | Hooks fail-closed vs fail-open？ | 開發環境 fail-open，文件說明兩種策略 | #6 |
| 2 | Memory 指引位置？ | WORKFLOW.md 新章節 | #7 |
| 3 | Severity 命名統一？ | 🔴 Critical / 🟡 High / 🟢 Medium / ⚪ Low | #8 |
| 4 | 自動計數 skills？ | 在 sync 腳本中加入計數驗證 | #9 |

---

## References

- Brainstorm: `01-brainstorm.md`
- Decision Log: `02-decision-log.md`（Decision #1–#9）
- [Copilot CLI Hooks](https://docs.github.com/en/copilot/customizing-copilot/adding-repository-custom-instructions-for-github-copilot)
- [Copilot Memory](https://docs.github.com/en/copilot/customizing-copilot/copilot-memory)
- [Agent Skills](https://docs.github.com/en/copilot/customizing-copilot/copilot-agent-skills)
