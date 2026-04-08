# Implementation Plan: Copilot CLI 對齊 + 指令架構重構

## Overview

實作 Copilot CLI 功能缺口修補（Part A）及指令架構重構（Part B），涵蓋安全機制、文件補充、架構精簡三大面向。

**Spec Reference**: `03-spec.md`

## Implementation Strategy

### Approach

Phase 1 建立核心架構基礎（精簡 copilot-instructions.md、plan.agent.md、合併 skill），Phase 2–4 平行推進（agent 精簡 / 安全機制 / 文件補充），Phase 5 統一收尾驗證。

### Phases

5 個 Phase，19 個 Task

### Sequencing

```
Phase 1 ──→ ┬── Phase 2 (Agent Slimming)  ──→ Phase 5
             ├── Phase 3 (Security Infra)  ──→ Phase 5
             └── Phase 4 (Doc Gaps)        ──→ Phase 5
```

---

## Phase 1: 核心架構基礎（🔴 Critical）

### Objective

建立 Pointer-Style Guidance 架構核心：精簡永久載入的文件、合併重複 skill。

### Task 1.1: 精簡 copilot-instructions.md

**目標**：從 ~108 非空行精簡至 ≤40 行

**重寫策略**：

保留：
- §4 Communication Style（繁體中文、Git commit 格式、語氣）
- Safety Check（no float for money、verify boundaries、no secrets）

替換為指標：
- §1 Rule of Law → 1-2 行指向 `instructions/` 目錄
- §2 Agent Personas → 1 行指向 `agents/*.agent.md`
- §3 6-Stage Workflow → 2 行指向 `WORKFLOW.md` + `skills/workflow-orchestrator/`

**Acceptance Criteria**:
- [ ] ≤40 非空行
- [ ] 包含完整 Communication Style
- [ ] 包含 Safety Check
- [ ] 不包含 Agent Persona 描述
- [ ] 不包含 Workflow 步驟

---

### Task 1.2: 精簡 plan.agent.md

**目標**：從 57 非空行精簡至 ≤25 行

**重寫策略**：保留 WHO（角色定義 + 核心原則 + 必要輸入輸出），移除 HOW（詳細流程→指向 skills）

**Acceptance Criteria**:
- [ ] ≤25 非空行
- [ ] 保留角色定義和核心原則
- [ ] 包含指向 implementation-planning / brainstorming / specification skills 的指標
- [ ] 不包含詳細步驟流程

---

### Task 1.3: 合併 plan-from-spec 至 implementation-planning

**步驟**：
1. 讀取 `skills/plan-from-spec/SKILL.md` 的獨特內容
2. 在 `skills/implementation-planning/SKILL.md` 新增「Simplified Mode（from Spec）」章節
3. 更新 description 涵蓋 plan-from-spec 觸發關鍵字
4. 刪除 `skills/plan-from-spec/` 目錄
5. 刪除 `.github/skills/plan-from-spec/` 鏡像目錄
6. 搜尋並更新所有引用 plan-from-spec 的檔案

**Acceptance Criteria**:
- [ ] `skills/plan-from-spec/` 不存在
- [ ] `.github/skills/plan-from-spec/` 不存在
- [ ] `implementation-planning/SKILL.md` 包含 Simplified Mode 章節
- [ ] description 包含 "plan from spec" 關鍵字
- [ ] 無檔案引用已刪除的 plan-from-spec

---

### Phase 1 Exit Criteria

- [ ] `copilot-instructions.md` ≤40 非空行
- [ ] `plan.agent.md` ≤25 非空行
- [ ] `plan-from-spec` 已合併並刪除
- [ ] 無 broken references

---

## Phase 2: Agent 精簡（🟡 High）

### Objective

將剩餘 4 個 agent 精簡至 ≤25 行，統一 severity 命名。

### Task 2.1: 精簡 spec.agent.md

**目標**：從 36 行精簡至 ≤25 行
**策略**：保留 persona + 3 Core Principles，移除詳細流程→指向 specification skill

**Acceptance Criteria**:
- [ ] ≤25 非空行
- [ ] 包含 skill 指標

---

### Task 2.2: 精簡 architect.agent.md

**目標**：從 34 行精簡至 ≤25 行
**策略**：保留 persona + 3 responsibilities，移除 ADR 模板→指向 brainstorming skill

**Acceptance Criteria**:
- [ ] ≤25 非空行
- [ ] 包含 skill 指標

---

### Task 2.3: 精簡 coder.agent.md

**目標**：從 29 行精簡至 ≤25 行
**策略**：保留 persona + 核心守則 + 環境標準，指向 tdd-workflow skill

**Acceptance Criteria**:
- [ ] ≤25 非空行
- [ ] 包含 skill 指標

---

### Task 2.4: 精簡 code-reviewer.agent.md + 統一 Severity

**目標**：從 27 行精簡至 ≤25 行 + Severity 命名統一
**策略**：
- 保留 enforcement persona + 審查優先順序
- BLOCKER → 🔴 Critical, WARNING → 🟡 High, NIT → 🟢 Medium
- 指向 code-security-review skill

**Acceptance Criteria**:
- [ ] ≤25 非空行
- [ ] 不包含 BLOCKER/WARNING/NIT（改用 Critical/High/Medium/Low）
- [ ] 包含 skill 指標

---

### Phase 2 Exit Criteria

- [ ] 所有 5 個 agent ≤25 非空行
- [ ] Severity 命名統一

---

## Phase 3: 安全基礎設施（🟡 High）

### Objective

建立 Copilot Hooks 安全機制，充實 SECURITY.md。

### Task 3.1: 建立 Hooks 設定檔

**檔案**：`.github/hooks/copilot-hooks.json`

**內容**：定義 3 個 hooks（preToolUse、sessionStart、postToolUse），每個指向對應腳本。

**Acceptance Criteria**:
- [ ] JSON 語法正確
- [ ] 定義 3 個 hooks
- [ ] failBehavior 設為 warn（依 Decision #6）

---

### Task 3.2: 撰寫 preToolUse hook 腳本

**檔案**：`.github/hooks/pre-tool-use.sh`（或 .ps1）

**攔截規則**：
- 檔案系統破壞（rm -rf /）
- 資料庫破壞（DROP TABLE, TRUNCATE）
- Git 歷史覆寫（git push --force）
- 權限開放（chmod 777）
- 遠端執行（curl|sh, wget|bash）
- Secret patterns（API key, token）

**Acceptance Criteria**:
- [ ] 攔截 ≥5 類危險命令模式
- [ ] Secret scanning 功能
- [ ] 輸出符合 Copilot Hooks 協議格式

---

### Task 3.3: 撰寫 sessionStart + postToolUse hook 腳本

**檔案**：`.github/hooks/session-start.sh`、`.github/hooks/post-tool-use.sh`

**Acceptance Criteria**:
- [ ] sessionStart 記錄使用者、時間、模式
- [ ] postToolUse 記錄命令和執行結果
- [ ] 日誌寫入 `.copilot/audit.log`（或 stdout）

---

### Task 3.4: 充實 SECURITY.md

**目標**：從 5 行 placeholder 擴充為完整安全策略

**章節**：
1. Copilot CLI 安全考量（trusted directories、tool approval）
2. Hooks 安全策略（引用 `.github/hooks/`）
3. Secrets 管理規範
4. `--allow-all-tools` / `--yolo` 風險說明
5. 漏洞通報流程（保留現有 email + response time）
6. CODEOWNERS 要求

**Acceptance Criteria**:
- [ ] ≥50 行非空內容
- [ ] 涵蓋上述 6 個章節
- [ ] 引用 Hooks 設定

---

### Phase 3 Exit Criteria

- [ ] `.github/hooks/` 目錄存在且包含 3+ 檔案
- [ ] SECURITY.md 完整

---

## Phase 4: 文件缺口補充（🟢 Medium）

### Objective

補充 Copilot Memory、CLI 互動模式、Custom Model Provider、MCP 相關文件。

### Task 4.1: WORKFLOW.md 新增 Copilot Memory 章節

**位置**：WORKFLOW.md 的 Safety / 進階功能區域

**內容**：
- Memory 是什麼、自動學習機制、28 天過期
- Memory vs instructions 的定位（輔助 vs SSOT）
- 管理者操作：檢視、刪除
- 建議策略

**Acceptance Criteria**:
- [ ] WORKFLOW.md 包含 Copilot Memory 章節
- [ ] 明確說明 instructions 為 SSOT

---

### Task 4.2: WORKFLOW.md 新增 CLI 互動模式章節

**內容**：
- Plan Mode（Shift+Tab）
- Autopilot Mode（experimental + 風險）
- Session 管理：/resume、--continue、/compact
- Context 管理：/context、auto-compaction
- GitHub MCP server 為 CLI 內建

**Acceptance Criteria**:
- [ ] WORKFLOW.md 包含 CLI 互動模式章節

---

### Task 4.3: INSTALL.md 新增 Custom Model Provider 章節

**內容**：
- Azure OpenAI 配置範例（環境變數）
- Ollama 本地模型配置
- 模型最低需求（128k+ context、tool calling、streaming）
- 環境變數說明

**Acceptance Criteria**:
- [ ] INSTALL.md 和 INSTALL.zh-TW.md 都包含 Custom Model Provider 章節

---

### Task 4.4: MCP 配置說明

**位置**：WORKFLOW.md 或 INSTALL.md（視內容量決定）

**內容**：
- GitHub MCP server 為 CLI 內建
- 自訂 MCP server 配置方式
- `.github/copilot-mcp.json` 格式

**Acceptance Criteria**:
- [ ] MCP 配置說明存在

---

### Phase 4 Exit Criteria

- [ ] WORKFLOW.md 含 Memory + CLI 互動模式 2 個新章節
- [ ] INSTALL.md 含 Custom Model Provider 章節
- [ ] MCP 說明完成

---

## Phase 5: 同步與收尾驗證（Final）

### Objective

修正數字、更新 AGENTS.md、強化 sync 腳本、全面驗證。

### Task 5.1: 修正 skills 數量

**受影響檔案**：README.md, README.zh-TW.md, INSTALL.md, INSTALL.zh-TW.md, AGENTS.md
**變更**：24 → 28

**Acceptance Criteria**:
- [ ] 所有文件中 skills 數量一致為 28

---

### Task 5.2: 更新 AGENTS.md

**變更**：
- 新增四層架構說明（Constitution → Role → Playbook → Code Style）
- 說明每層載入行為
- Skills 數量更新
- agent = WHO, skill = HOW 設計原則
- 移除已不存在的 plan-from-spec 引用

**Acceptance Criteria**:
- [ ] 反映 Pointer-Style Guidance 架構
- [ ] 數字正確

---

### Task 5.3: 強化 sync-dotgithub.ps1

**新增功能**：
- 自動計數 `skills/` 目錄下的 SKILL.md 檔案
- 若計數與預期不符，輸出警告

**Acceptance Criteria**:
- [ ] 腳本執行時輸出 skills 計數
- [ ] 計數不符時輸出警告（不阻塞同步）

---

### Task 5.4: 執行 sync + 全面驗證

**步驟**：
1. 執行 `pwsh -File .\tools\sync-dotgithub.ps1`
2. 驗證 `.github/` 鏡像完整
3. grep 搜尋 broken references（plan-from-spec、舊 severity 名稱）
4. 確認所有檔案行數符合限制

**Acceptance Criteria**:
- [ ] sync 成功無錯誤
- [ ] 無 broken references
- [ ] 無 BLOCKER/WARNING/NIT 殘留
- [ ] copilot-instructions.md ≤40 行、所有 agents ≤25 行

---

### Phase 5 Exit Criteria

- [ ] 全面驗證通過
- [ ] `.github/` 鏡像與 source-of-truth 一致

---

## Dependencies

### Internal

- Phase 2, 3, 4 依賴 Phase 1 完成
- Phase 5 依賴 Phase 2, 3, 4 全部完成
- Task 5.1 (數量修正) 依賴 Task 1.3 (合併完成後才能確認最終數量)
- Task 3.4 (SECURITY.md) 依賴 Task 3.1–3.3 (Hooks 建立)

### External

- 無外部依賴

### Sequencing

- Phase 1 must complete before Phase 2, 3, 4
- Phase 2, 3, 4 can run in parallel
- Phase 5 requires all preceding phases

---

## Impact Analysis (Brownfield Changes)

### Affected Components

| Component | Type | Impact Level | Action Required |
|-----------|------|-------------|----------------|
| `copilot-instructions.md` | Rewrite | 🔴 Critical | 從 108→≤40 行 |
| `agents/plan.agent.md` | Rewrite | 🟡 High | 從 57→≤25 行 |
| `agents/spec.agent.md` | Slim | 🟢 Medium | 從 36→≤25 行 |
| `agents/architect.agent.md` | Slim | 🟢 Medium | 從 34→≤25 行 |
| `agents/coder.agent.md` | Slim | 🟢 Medium | 從 29→≤25 行 |
| `agents/code-reviewer.agent.md` | Slim | 🟢 Medium | 從 27→≤25 行 + severity |
| `skills/plan-from-spec/` | Delete | 🟡 High | 合併後刪除 |
| `skills/implementation-planning/SKILL.md` | Update | 🟡 High | 新增 Simplified Mode |
| `.github/hooks/` | New | 🟡 High | 全新目錄 |
| `SECURITY.md` | Rewrite | 🟢 Medium | 從 5 行擴充 |
| `WORKFLOW.md` | Append | 🟢 Medium | 新增 2 章節 |
| `INSTALL.md` / `INSTALL.zh-TW.md` | Append | 🟢 Low | 新增章節 |
| `AGENTS.md` | Update | 🟢 Medium | 反映新架構 |
| 5+ doc files | Fix numbers | ⚪ Low | 24→28 |

### Breaking Changes

- `plan-from-spec` skill 刪除 → 使用者需改用 `implementation-planning`
- `copilot-instructions.md` 重寫 → Agent 行為可能微調（但核心規範不變）
- Severity 命名變更 → 現有 review 報告格式改變

### Rollback Strategy

1. Git revert commit(s)
2. 執行 sync-dotgithub.ps1 恢復 .github/ 鏡像
3. Hooks：刪除 .github/hooks/ 即可停用

---

## Risks & Mitigations

| Risk | Likelihood | Impact | Mitigation |
|------|-----------|--------|------------|
| copilot-instructions 精簡過頭導致行為退化 | Medium | 🔴 Critical | 逐步驗證每個 agent 的觸發行為 |
| Hook 腳本在某些 OS 不相容 | Medium | 🟡 High | 同時提供 .sh 和 .ps1 版本 |
| 合併 skill 後觸發關鍵字遺漏 | Low | 🟢 Medium | grep 搜尋所有引用確保無遺漏 |
| 文件數字再次不一致 | Medium | 🟢 Medium | sync 腳本自動計數驗證 |

---

## Approval & Next Steps

**Plan Status**: ✅ Approved

**Next Step**: 開始 Phase 1 實作
→ Task 1.1: 精簡 copilot-instructions.md
→ Task 1.2: 精簡 plan.agent.md
→ Task 1.3: 合併 plan-from-spec
