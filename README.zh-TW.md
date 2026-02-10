# AI 開發工作流範本（繁體中文）

本範本供團隊迅速部署一致的 AI 開發工作流程，特別為金融級專案設計，包含團隊憲章、Agent 人物、指令/提示庫、技能（Skills）與初始化部署腳本。

你會得到：

- `copilot-instructions.md`：團隊憲法與行為準則（繁中說明 + 英文程式碼範例）
- `agents/`：各角色（Architect、Planner、Coder、Reviewer、PRD Specialist）定義
- `instructions/`：語言與領域規則（例如 Python / C# / SQL / API）
- `prompts/`：標準化 prompt 與工作流程範例
- `skills/`：可插拔技能（測試、視覺檢查、markdown 轉換等）
- `Init-Project.ps1`：將範本部署到新專案的初始化腳本

快速上手

1. 將此範本內容複製或合併到目標儲存庫的根目錄。
2. 使用 PowerShell 執行初始化腳本以部署預設檔案與結構：

```powershell
pwsh -File .\Init-Project.ps1
```

可選參數範例：

```powershell
# 只部署指定元件
pwsh -File .\Init-Project.ps1 -Include copilot,agents,instructions,prompts,skills,project-files

# 部署全部但排除 skills
pwsh -File .\Init-Project.ps1 -Exclude skills
```

目錄說明

- `copilot-instructions.md`：團隊憲章與指令優先權（閱讀以瞭解互動語言）
- `agents/`：Agent 人物與工作流程
- `instructions/`：技術、流程與安全規範
- `prompts/`：可重複使用的 prompt 範例
- `skills/`：技能說明、腳本與參考資料
- `Init-Project.ps1`：自動部署腳本（可傳入 Include/Exclude 參數）

注意事項

- 請勿將敏感資訊（API 金鑰、密碼等）提交到版本控制，務必使用環境變數或專用的密鑰管理服務。
- 本範本以「通用性」與「保守配置」為原則；新增或移除 skills 應由各團隊依技術棧裁剪。
- 使用說明與註解建議採繁體中文撰寫以符合團隊內部溝通習慣，程式碼與範例仍以英文為主。

聯絡與貢獻

如需協助或想要新增技能，請在本專案建立 issue 或提交 PR，並在 PR 描述中包含測試說明與風險評估。


## 建議流程（Brainstorm → Spec → Plan → Implement）

本範本建議在中高風險變更時採用以下順序：

1. `/brainstorm`：先釐清需求、限制與替代方案，產出決策紀錄（Decision Log）與 specs 起始檔案
2. `specs/<YYYY-MM-DD>-<slug>/`：沉澱 `proposal.md / tasks.md / decision-log.md`
3. `/plan`：由 `plan-agent` 讀取 specs 後，輸出可執行計畫（每步含驗收方式）
4. Implement（TDD）→ PR review

完整流程與判斷準則請見：`WORKFLOW.md`。


## 工作流程摘要（建議給新手看）

- **標準路**：Intake → Brainstorm → Spec → Plan → Implement(TDD) → Review → Archive  
- **快速路**：Intake → Plan → Implement → Review（僅低風險）

每次需求/變更都建立一個 **Change Package**：
- `changes/<YYYY-MM-DD>-<slug>/`

詳見：
- `WORKFLOW.md`
- `changes/README.md`

---

## 🔀 CLI 與 VS Code 使用差異

本專案的 AI 工作流程支援 **Copilot CLI** 和 **VS Code Copilot** 兩種環境。兩者有不同的使用方式：

### Copilot CLI 使用方式
- **Skills 自動載入**: 輸入包含關鍵字的自然語言，系統會自動載入對應 skill
  - 範例：「我要產生 spec」→ 載入 specification skill
- **Agent 選擇**: 使用 `/agent` 命令手動選擇 agent
  - 範例：輸入 `/agent` → 選擇 `spec-agent`
- **檢視 skills**: 使用 `/skills list` 查看已安裝的 skills
- **注意**: CLI 不支援斜線指令（如 `/spec`），需使用自然語言觸發

### VS Code Copilot Chat 使用方式
- **兩種方式**:
  1. **自然語言**（同 CLI）：輸入關鍵字觸發 skill
  2. **斜線指令**（快捷方式）：使用 `/spec`, `/tdd`, `/code-review` 等快速指令
- **Agent 選擇**: 在 Chat 輸入框使用 `@workspace` 並選擇 `#agent-name`
- **提示**: 斜線指令僅在 VS Code 有效，CLI 中需使用自然語言

### 通用規則
- **Agents** 定義「誰來做」（角色與專長）
- **Skills** 定義「怎麼做」（方法論與工具）
- **Instructions** 定義「遵守什麼規範」（coding standards）

### 推薦工作流程
1. 使用自然語言描述需求（觸發對應 skill）
2. 根據 skill 推薦選擇合適的 agent
3. 讓 agent 依 skill 指引執行任務

---

## 📖 六階段工作流程使用指南

### 階段 0: 流程協調（Workflow Orchestrator）
**觸發關鍵字**: "workflow", "what's next", "工作流程", "下一步"

**CLI 使用**:
```
> 我想知道目前在哪個階段
[系統載入 workflow-orchestrator skill]
→ 偵測到 01-brainstorm.md，建議進行 Spec
→ 推薦使用 spec-agent
```

**VS Code 使用**:
- 方式 1: 輸入「workflow 狀態」
- 方式 2: 使用 `/workflow` 指令（快捷）

---

### 階段 1: Brainstorm
**觸發關鍵字**: "brainstorm", "討論需求", "探索方案"

**CLI 使用**:
```
> 我要開始一個新功能的 brainstorming
[系統載入 brainstorming skill]
→ 建議使用 architect-agent 或 spec-agent
→ /agent → 選擇 architect-agent
```

**VS Code 使用**:
- 方式 1: 輸入「brainstorm 新功能」
- 方式 2: 使用 `/brainstorm` 指令

**產出**: `changes/<date>-<slug>/01-brainstorm.md`

---

### 階段 2: Spec（規格文件）
**觸發關鍵字**: "spec", "PRD", "requirements", "規格", "需求文件"

**CLI 使用**:
```
> 產生 spec 文件
[系統載入 specification skill]
→ 建議使用 spec-agent
→ /agent → 選擇 spec-agent
> 繼續對話以產生完整 spec
```

**VS Code 使用**:
- 方式 1: 輸入「產生 spec」
- 方式 2: 使用 `/spec` 指令

**產出**: `changes/.../03-spec.md`

---

### 階段 3: Plan（實作計畫）
**觸發關鍵字**: "plan", "implementation plan", "任務拆解", "執行計畫"

**CLI 使用**:
```
> 幫我規劃實作計畫
[系統載入 implementation-planning skill]
→ 建議使用 plan-agent
→ /agent → 選擇 plan-agent
```

**VS Code 使用**:
- 方式 1: 輸入「規劃實作計畫」
- 方式 2: 使用 `/create-plan` 指令

**產出**: `changes/.../04-plan.md`

---

### 階段 4: TDD 實作
**觸發關鍵字**: "TDD", "test-driven", "寫測試", "implement"

**CLI 使用**:
```
> 開始 TDD 實作
[系統載入 tdd-workflow skill]
→ 建議使用 coder-agent
→ /agent → 選擇 coder-agent
```

**VS Code 使用**:
- 方式 1: 輸入「TDD 開發」
- 方式 2: 使用 `/tdd` 指令

**產出**: 測試程式碼 + 實作程式碼

---

### 階段 5: Review（審核）
**觸發關鍵字**: "review", "code review", "審核", "檢查程式碼"

**CLI 使用**:
```
> review 我的 code
[系統載入 code-security-review skill]
→ 建議使用 code-reviewer-agent
→ /agent → 選擇 code-reviewer-agent
```

**VS Code 使用**:
- 方式 1: 輸入「review code」
- 方式 2: 使用 `/code-review` 指令

**產出**: `changes/.../05-review.md`

---

### 階段 6: Archive（歸檔）
**觸發關鍵字**: "archive", "finalize", "完成", "歸檔"

**CLI 使用**:
```
> 我要 archive 這個 change package
[系統載入 work-archiving skill]
→ 產生 work log entry
→ 建立 99-archive.md
```

**VS Code 使用**:
- 方式 1: 輸入「archive」
- 方式 2: 使用 `/archive` 指令

**產出**: `changes/.../99-archive.md`, `docs/WORK_LOG.md` 更新

---

### 快速參考表

| 階段 | CLI 關鍵字 | VS Code 快捷 | 推薦 Agent |
|------|-----------|-------------|-----------|
| 0. Orchestrator | "workflow", "下一步" | - | - |
| 1. Brainstorm | "brainstorm", "探索" | `/brainstorm` | architect / spec |
| 2. Spec | "spec", "PRD", "規格" | `/spec` | spec-agent |
| 3. Plan | "plan", "規劃" | `/create-plan` | plan-agent |
| 4. TDD | "TDD", "實作" | `/tdd` | coder-agent |
| 5. Review | "review", "審核" | `/code-review` | code-reviewer-agent |
| 6. Archive | "archive", "歸檔" | `/archive` | - |

---

## ❓ 常見問題 FAQ

### Q1: 為什麼我在 CLI 中輸入 `/spec` 沒反應？
A: CLI 不支援斜線指令（那是 VS Code 專用）。請改用自然語言：「產生 spec」或「我要寫規格文件」。

### Q2: 如何知道哪個 skill 被載入了？
A: CLI 會在回應中提示載入的 skill。也可以使用 `/skills list` 查看所有已安裝的 skills。

### Q3: 我一定要切換到推薦的 agent 嗎？
A: 不一定。預設 agent 也能執行，但專用 agent 會更精準且符合角色定位。

### Q4: Skill 和 Prompt 有什麼差別？
A: 
- **Skill**: CLI + VS Code 通用，依關鍵字自動載入
- **Prompt**: VS Code 專用的斜線指令快捷方式

### Q5: 如何在 CLI 中使用 workflow？
A: 輸入「我想知道目前在哪個階段」或「what's next」，系統會載入 workflow-orchestrator skill 並提供指引。

### Q6: 可以跳過某些階段嗎？
A: 低風險變更可跳過 Spec，直接從 Brainstorm → Plan。但 Med/High 風險必須完整走完所有階段。

### Q7: 如何同步 skills 到 .github 目錄？
A: 執行 `pwsh -File .\tools\sync-dotgithub.ps1` 將 source 複製到 `.github/`，讓 VS Code 和 CLI 讀取最新設定。

### Q8: CLI 和 VS Code 可以混用嗎？
A: 可以！兩者共享相同的 agents、skills 和 instructions。選擇你習慣的工具即可。
