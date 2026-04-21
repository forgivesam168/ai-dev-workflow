# 🚀 Quick Start Guide

## 5 分鐘上手 AI 工作流程

### Step 1: 選擇你的環境

- **Copilot CLI**: 終端機使用者 → 使用自然語言觸發
- **VS Code**: 編輯器內使用者 → 可用斜線指令快捷

### Step 2: 開始一個新功能

**CLI**:
```bash
copilot
> 我要開始一個新功能的 brainstorming
```

**VS Code**:
```
在 Copilot Chat 輸入：
/brainstorm 或「我要開始 brainstorming」
```

### Step 3: 依序完成六階段

```
1. Brainstorm → 2. Spec → 3. Plan → 4. TDD → 5. Review → 6. Archive
```

每個階段完成後，輸入「what's next」查看下一步。

### Step 4: 使用推薦的 Agent

系統會推薦合適的 agent（例如：spec-agent）

**CLI**: `/agent` → 選擇推薦的 agent

**VS Code**: `@workspace #spec-agent`

---

## 📋 快速參考

### 六階段指令對照

| 階段 | CLI 輸入（自然語言） | VS Code 輸入（斜線指令） | 推薦 Agent |
|------|---------------------|--------------------------|-----------|
| 0. 流程狀態 | what's next / 我想知道目前在哪個階段 | - | - |
| 1. Brainstorm | 我想開始 brainstorming / 我要開始一個新功能的 brainstorming | `/brainstorm` | brainstorm-agent |
| 2. Spec | 產生 spec / 幫我寫規格文件 | `/spec` | spec-agent |
| 3. Plan | 規劃實作計畫 / 幫我拆解任務 | `/create-plan` | plan-agent |
| 4. TDD | 開始 TDD 實作 / 寫測試並實作 | `/tdd` | coder-agent |
| 5. Review | review 我的 code / 幫我審核程式碼 | `/code-review` | code-reviewer-agent |
| 6. Archive | archive 這個 change package / 幫我歸檔 | `/archive` | - |

---

## 💡 重要概念

### Agents（角色）
定義「誰來做」，例如：
- **brainstorm-agent**: 需求探索與風險分類
- **spec-agent**: 規格文件撰寫
- **architect-agent**: 系統設計與架構（跨階段技術顧問）
- **plan-agent**: 實作計畫規劃
- **coder-agent**: TDD 實作
- **code-reviewer**: 程式碼品質與安全審核

### Skills（方法論）
定義「怎麼做」，每個階段有對應 skill 自動載入：

| 階段 | 自動載入 | 代表 Skills |
|------|----------|------------|
| Brainstorm | `brainstorming` | 結構化需求探索、風險分類、決策紀錄 |
| Spec | `specification`, `prd` | PRD / 規格文件生成、驗收標準 |
| Plan | `implementation-planning` | 任務拆解、測試策略、影響分析 |
| Implement | `tdd-workflow` + 語言 patterns | Red-Green-Refactor + `coding-standards`, `backend-patterns`, `frontend-patterns`, `python-patterns` |
| Review | `code-security-review`, `security-review` | 程式碼品質 + 安全審核 |
| Archive | `work-archiving`, `git-commit` | 歸檔紀錄 + Conventional Commit |

> 💡 **Skill 沒自動載入？** 可在 CLI 中直接輸入 `/skill-name` 手動觸發，例如 `/brainstorming`、`/implementation-planning`。
> 每個 Agent 的 Skill Integration 區塊也會提示對應的 skill 指令。

**品質閘門（agentic-eval）— 階段交接前的自動品質驗證：**

各 agent 在完成主技能後，會自動執行 `agentic-eval` 做一道品質驗證，**阻止有缺陷的產出物流入下一階段**。使用者不需要手動觸發——agent 會自己做，並告知結果。

| 觸發時機 | 執行 Agent | 驗證內容 | FAIL 時的行為 |
|---------|-----------|---------|-------------|
| Spec 完成 → handoff 前 | spec-agent（自評）| AC 是否可測試、需求是否可追溯 | 自動修正後再 handoff；嚴重問題直接阻擋 |
| Plan 開始前（收到 spec）| plan-agent（交叉驗證）| spec 從規劃者視角能否寫出具體步驟 | 在 04-plan.md 頂部標記 gap，繼續執行 |
| Code 完成 → Review 前 | coder-agent（自評）| Green Build、Financial Precision、AC 覆蓋 | **Financial Precision FAIL = 強制停止**，不得進入 Review |
| Plan/Spec 完成後（中高風險）| architect-agent（外部仲裁）| 架構合規、依賴順序、規格覆蓋 | 啟動子代理對抗批評，修正後再進行 |

> ⚠️ **Financial Precision 是唯一的強制阻擋規則**：若 coder-agent 偵測到使用 float/double 處理金額，
> 會明確拒絕進入 Review 並要求修正。其他 FAIL 維度則標記後繼續執行。
>
> 💡 **中高風險變更**：Plan 完成後可主動請 architect-agent 做架構仲裁：
> 輸入「請 architect-agent 審查這份 plan」或切換到 `/agent architect-agent`。

**隨時可引用的輔助 Skills：**
`excalidraw-diagram-generator` / `web-design-reviewer` / `webapp-testing` / `gh-cli` / `github-issues` / `refactor` / `chrome-devtools` / `microsoft-docs`

### Instructions（規範）
定義「遵守什麼標準」，例如：
- C# coding standards
- API design principles
- Financial precision rules (no floats for money!)

---

## 🎯 使用範例

### 範例 1: 新功能開發（完整流程）

```
1. CLI 輸入: "我要開發一個新的交易功能"
   → 系統載入 brainstorming skill
   → 推薦切換到 brainstorm-agent
   → 風險判定為「High」→ 走標準路徑

2. 產出 01-brainstorm.md 後，輸入: "產生 spec"
   → 系統載入 specification skill
   → 推薦切換到 spec-agent
   → 產出 03-spec.md
   → ✅ [品質閘門] spec-agent 自動執行 AC 可測性自評
      若 Testability FAIL → 自動修正後再 handoff

3. 產出 03-spec.md 後，輸入: "規劃實作計畫"
   → plan-agent 先從規劃者視角交叉驗證 spec
      發現無法寫出具體步驟的需求 → 在 04-plan.md 頂部標記 gap
   → 系統載入 implementation-planning skill
   → 推薦切換到 plan-agent
   → 產出 04-plan.md
   → ✅ [品質閘門] 可請 architect-agent 做架構仲裁（高風險強烈建議）
      輸入：「請 architect-agent 審查這份 plan」

4. 產出 04-plan.md 後，輸入: "開始 TDD 實作"
   → 系統載入 tdd-workflow skill
   → 推薦切換到 coder-agent
   → 完成實作
   → ✅ [品質閘門] coder-agent 自動執行 Pre-Review 自評
      🔴 Financial Precision FAIL → 強制停止，不得進入 Review
      其他 FAIL → 修正後繼續

5. 品質自評通過後，輸入: "review 我的 code"
   → 系統載入 code-security-review skill
   → 推薦切換到 code-reviewer-agent

6. Review 通過後，輸入: "archive"
   → 產生 99-archive.md 與 WORK_LOG 條目
```

### 範例 2: 檢查當前進度

```
輸入: "我現在在哪個階段？"
或: "what's next?"

系統回應:
→ 偵測到 03-spec.md 已存在
→ 建議下一步: 規劃實作計畫
→ 推薦使用 plan-agent
→ CLI: /agent → 選擇 plan-agent
```

### 範例 3: 低風險快速修復（Fast Path）

```
1. 輸入: "我要修一個小 bug"
   → 系統詢問風險等級
   → 確認為低風險
   → 建議快速路（跳過 Spec）
   
2. 直接輸入: "規劃修復計畫"
   → 產生 04-plan.md
   
3. 輸入: "開始 TDD"
   → 寫測試 → 實作 → 重構
   
4. 輸入: "review"
   → 審核通過
   
5. 輸入: "archive"
   → 完成
```

---

## ⚠️ 常見錯誤

### ❌ 錯誤 1: 在 CLI 使用工作流程 Prompt 的斜線指令
```
> /spec
[系統無反應]
```
**正確方式**: 使用自然語言 → `產生 spec`，或使用 skill 引用語法 → `Use the /specification skill`

> 📌 `/spec`、`/create-plan`、`/code-review` 等是 VS Code prompt 捷徑，非 CLI 斜線指令。
> CLI 內建斜線指令（如 `/plan` 計畫模式、`/review` Code Review）與這些不同。

### ❌ 錯誤 2: 忘記切換 Agent
```
> 產生 spec
[系統推薦 spec-agent]
[使用者繼續對話但未切換 agent]
```
**正確方式**: 輸入 `/agent` 並選擇推薦的 agent

### ❌ 錯誤 3: 跳過必要階段
```
高風險變更直接跳到 TDD（跳過 Brainstorm + Spec）
```
**正確方式**: 
- 低風險才能跳 Spec
- 中高風險必須完整流程

---

## 🔧 進階技巧

### 技巧 1: 查看已安裝的 Skills

CLI（自然語言）:

輸入："列出已安裝的 skills" 或 "show installed skills"，系統會回應可用或已載入的 skills。

VS Code（斜線指令快捷）:
```bash
/skills list
/skills info brainstorming
```

### 技巧 2: 同步最新設定
```powershell
# 將 source 同步到 .github/
pwsh -File .\tools\sync-dotgithub.ps1
```

### 技巧 3: 平行使用 CLI 與 VS Code
- CLI: 用於探索、brainstorm、規劃
- VS Code: 用於實作、review、除錯
- 兩者共享相同的 agents、skills、instructions

---

## 📚 完整指南

想深入了解更多？查看這些文檔：

1. **[README.zh-TW.md](./README.zh-TW.md)** - 完整專案說明
   - CLI vs VS Code 使用差異
   - 六階段詳細指南
   - 常見問題 FAQ

2. **[WORKFLOW.md](./WORKFLOW.md)** - 工作流程詳細說明
   - 標準路 vs 快速路
   - Change Package 結構
   - 驗收與歸檔

3. **[AGENTS.md](./AGENTS.md)** - Agents 與 Skills 對照表
   - 6 個 Agents 說明
   - 核心與工具 Skills
   - 觸發關鍵字參考

4. **[copilot-instructions.md](./copilot-instructions.md)** - 團隊憲章
   - 開發原則與標準
   - Agent 與 Workflow 規則
   - 金融系統特殊要求

---

## 🎉 開始使用

1. **確保環境設置完成**:
   - Copilot CLI 已安裝並登入
   - 或 VS Code 已安裝 GitHub Copilot 擴充功能

2. **同步最新設定**:
   ```powershell
   pwsh -File .\tools\sync-dotgithub.ps1
   ```

3. **啟動 CLI（如使用 CLI）**:
   ```bash
   copilot
   ```

4. **開始你的第一個工作流程**:
   ```
   > 我要開始一個新功能的 brainstorming
   ```

5. **遇到問題？**
   - 輸入「help」或查看 [常見問題 FAQ](./README.zh-TW.md)
   - 使用「what's next」隨時檢查當前階段

---

**祝開發順利！** 🚀

有任何問題或建議，歡迎在專案中建立 issue。
