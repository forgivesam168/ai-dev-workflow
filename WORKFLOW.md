# AI 開發工作流（團隊標準 v2）
> 目標：讓「新手也能穩定交付」——把需求釐清、規格、計畫、測試與審查 **變成可版控的產物**，降低反覆溝通成本，並在 MVP 很快變棕地時仍能安全演進。

本工作流整合：
- **Superpowers 精神**：先 brainstorm / 再 plan / 再 TDD / 再 review / 再重構與驗證
- **OpenSpec 精神（輕量版）**：把需求/決策/計畫留在 repo，形成長期上下文（可稽核）

---

## 1) 六階段標準流程

```
┌─────────────┐    ┌─────────────┐    ┌─────────────┐
│ 1.Brainstorm│ -> │   2.Spec    │ -> │   3.Plan    │
│  釐清需求   │    │  規格文件   │    │  任務拆解   │
│  風險判定   │    │  安全需求   │    │  測試策略   │
│ 標準/快速路 │    │  驗收標準   │    │  影響分析   │
└─────────────┘    └─────────────┘    └─────────────┘
                                            │
        ┌───────────────────────────────────┘
        v
┌─────────────┐    ┌─────────────┐    ┌─────────────┐
│ 4.Implement │ -> │  5.Review   │ -> │  6.Archive  │
│     TDD     │    │ Code Review │    │    驗收     │
│ Red-Green-  │    │   +並行+    │    │    歸檔     │
│  Refactor   │    │Security Rev │    │    紀錄     │
└─────────────┘    └─────────────┘    └─────────────┘
```

### 對應指令

| 階段 | 指令 | 說明 |
|------|------|------|
| 1 | `/brainstorm` | 風險分類、需求釐清、建立 change package |
| 2 | `/spec` | 產出規格文件 |
| 3 | `/create-plan` | 產出可執行計畫（含測試策略、影響分析） |
| 4 | `/tdd` | TDD 實作（Red-Green-Refactor） |
| 5 | `/code-review` | Code Review + Security Review（並行） |
| 6 | `/archive` | 驗收歸檔 |

**⚠️ 環境差異說明**:

本工作流程在 **Copilot CLI** 和 **VS Code** 中略有不同：

**Copilot CLI**:
- 使用**自然語言**觸發 skills（例：「產生 spec」）
- 使用 `/agent` 選擇角色
- Skills 自動依關鍵字載入
- **不支援斜線指令**（如 `/spec`）

**VS Code Copilot Chat**:
- 可使用**斜線指令**快速觸發（例：`/spec`）
- 也支援自然語言（同 CLI）
- Agent 選擇：`@workspace #agent-name`

**詳細使用指南請參考** [README.zh-TW.md - CLI vs VS Code 使用差異](./README.zh-TW.md)

---

## 2) 兩種路徑：標準路 vs 快速路

### A. 標準路（建議：中高風險 / 棕地 / 跨模組）
> **Brainstorm → Spec → Plan → Implement(TDD) → Review → Archive**

適用情境：
- 需求不清楚、反覆變更
- 多檔案、多模組、跨系統
- 涉及安全/權限/資料流/外部整合/CI/CD/供應鏈
- 任何棕地（已上線或已有使用者/依賴者）

### B. 快速路（允許：低風險的小修）
> **Plan → Implement → Review**

適用情境：
- 文案/註解/小修
- 明確的低風險 bug（影響面可一眼看完）
- 不改動介面契約、不改資料流、不動 workflow/權限

**快速路仍需：**
- PR 內寫清楚驗證方式（手動也可）
- 風險與回滾說明（可很短）

---

## 3) 每次變更都要留下「Change Package」
我們把每次需求/變更封裝成一個資料夾（可版控、可查詢、可稽核）：

`changes/<YYYY-MM-DD>-<slug>/`

檔案結構：
- `01-brainstorm.md`（需求釐清 + 選項分析）
- `02-decision-log.md`（關鍵決策與理由，**append-only**）
- `03-spec.md`（規格、安全需求、驗收標準）
- `04-plan.md`（可執行步驟 + 測試策略 + 影響分析）
- `05-review.md`（Code Review + Security Review 結果）
- `99-archive.md`（驗收 + 歸檔）

> **核心原則：** 需求變動時，更新 spec；決策變動時，追加 decision log（不要覆寫歷史）。

---

## 4) Definition of Ready（DoR）：什麼才准進開發？
至少滿足：
- 目標與非目標明確（`01-brainstorm.md`）
- 至少一個驗證方式（`03-spec.md` 或 `04-plan.md`）
- 風險等級已判定（Low/Med/High）
- 棕地：已包含影響分析（在 `04-plan.md` 中）

---

## 5) Definition of Done（DoD）：什麼才算做完？
至少滿足：
- 有測試（或寫明為何不寫 + 手動驗證步驟）
- PR 有：Change Package 路徑、驗證方式、風險與回滾
- Review 通過（`05-review.md`）
- 改動涉及「危險區」時有 CODEOWNERS 審核：
  - `.github/workflows/**`
  - 權限/驗證/授權
  - 資料輸入輸出（API、檔案、DB）

---

## 6) 棕地防呆（MVP → Brownfield 的安全演進）
- **分批 PR**：重構與功能不要混在同一支 PR
- **先保行為，再改內部**：必要時用 feature flag / toggle
- **回歸清單**：列出最重要的 5～10 條使用路徑（在 `04-plan.md`）
- **可回滾**：至少寫「怎麼回到上一版」或「為何不需要回滾」（在 `04-plan.md`）

---

## 7) 建議你們的最小節奏（適合 5 人小隊）
- 新需求：先開 Issue（或一張 task）
- 先 `/brainstorm`（產出 01/02/03 草稿）
- `/spec`（完善 03-spec.md）
- `/create-plan`（產出 04-plan.md）
- 進入 TDD 實作 → `/code-review` → Merge
- 合併後 `/archive`（5 分鐘完成）

---

## 8) 快速開始（模板）
請參考 `changes/README.md` 與 `changes/_template/`。

---

## 9) Copilot Memory 共存策略

### 什麼是 Copilot Memory

Copilot CLI 的 **Memory** 功能會自動從 session 中學習你的偏好與 pattern，並在未來 session 中自動應用。記憶有效期為 **28 天**，到期後自動失效。

### Memory vs Instructions 的定位

| 面向 | Memory | Instructions |
|------|--------|-------------|
| 來源 | AI 自動學習 | 人工維護、版本控制 |
| 確定性 | 非確定性（AI 判斷是否套用） | 確定性（每次載入都生效） |
| 生命週期 | 28 天過期 | 永久（直到手動刪除） |
| 範圍 | 個人帳號層級 | 專案 / 組織層級 |

> **衝突優先序**：當 Memory 與 instructions 內容矛盾時，**instructions 優先**。
> Instructions（`copilot-instructions.md` + `agents/` + `skills/`）是本專案的 **SSOT（單一真實來源）**。

### 管理者操作

```bash
# 檢視所有 Memory
gh copilot memory list

# 刪除特定 Memory
gh copilot memory delete <id>

# 清空全部 Memory
gh copilot memory clear
```

也可在 [GitHub Copilot 設定頁面](https://github.com/settings/copilot) 中管理 Memory。

### 建議策略

1. **啟用 Memory**：讓 Copilot 自動學習個人習慣（如偏好的變數命名、慣用框架）
2. **以 Instructions 為 SSOT**：團隊標準、架構規範、安全規則一律寫在 `copilot-instructions.md`、`agents/`、`skills/`
3. **定期檢視**：每月檢查 Memory 清單，刪除過時或與團隊規範衝突的項目

---

## 10) Copilot CLI 互動模式

### Plan Mode（計畫模式）

- **觸發**：在 CLI 中按 `Shift+Tab` 切換進入
- **用途**：AI 只規劃、不直接執行操作，適合複雜任務的設計階段
- **離開**：再按 `Shift+Tab` 或輸入 `/exit-plan`

> 💡 建議在 `/brainstorm` 和 `/create-plan` 階段使用 Plan Mode，確保 AI 先規劃再行動。

### Autopilot Mode（自動駕駛模式，experimental）

- **觸發**：啟動時加上 `--autopilot` 或 `-y` 旗標
- **行為**：AI 自動批准所有操作，不請求使用者確認
- **⚠️ 風險**：不建議在 production 環境使用
- **適用**：完全信任的自動化 CI/CD 場景

```bash
# 自動駕駛模式（謹慎使用）
gh copilot chat --autopilot
```

### Session 管理

| 操作 | 指令 | 說明 |
|------|------|------|
| 繼續上次 session | `gh copilot chat --continue` 或 `/resume` | 恢復上次未完成的對話 |
| 壓縮 context | `/compact` | 節省 token，適合長 session |
| 清除 session | `/clear` | 清空對話歷史，重新開始 |

### Context 管理

| 操作 | 指令 | 說明 |
|------|------|------|
| 查看當前 context | `/context` | 顯示已載入的檔案與工具 |
| 手動加入檔案 | `/add <file>` | 將特定檔案加入 context |
| 自動壓縮 | （自動） | 當 context 接近上限時自動觸發 |

> 💡 長時間工作時，善用 `/compact` 壓縮 context，避免 token 超限導致回應品質下降。

---

## 11) MCP 配置說明

### GitHub MCP Server（內建）

Copilot CLI **預設內建** GitHub MCP Server，無需額外配置即可直接使用 GitHub API 功能：

- Issues / Pull Requests 管理
- Repository 搜尋與瀏覽
- Code Search
- Actions / Workflows 操作

確認已登入即可使用：

```bash
gh auth status
```

### 自訂 MCP Server 配置

除內建的 GitHub MCP Server 外，可透過配置檔新增自訂 MCP Server。

**配置檔位置**（依優先序）：

| 位置 | 範圍 | 說明 |
|------|------|------|
| `.github/copilot-mcp.json` | 專案層級 | 隨 repo 版控，團隊共用 |
| `~/.config/gh/copilot-mcp.json` | 使用者層級 | 個人全域設定 |

### 配置格式範例

```json
{
  "mcpServers": {
    "context7": {
      "command": "npx",
      "args": ["-y", "@upstash/context7-mcp@latest"],
      "env": {}
    },
    "sequential-thinking": {
      "command": "npx",
      "args": ["-y", "@modelcontextprotocol/server-sequential-thinking"]
    }
  }
}
```

### 常見 MCP Server 範例

| Server | 用途 | 安裝方式 |
|--------|------|----------|
| `context7` | 函式庫文件即時查詢 | `npx -y @upstash/context7-mcp@latest` |
| `sequential-thinking` | 結構化思考輔助 | `npx -y @modelcontextprotocol/server-sequential-thinking` |
| `brave-search` | 網路搜尋 | 需要 `BRAVE_API_KEY` 環境變數 |

### 驗證 MCP Server

```bash
# 在 Copilot CLI 中檢視已載入的 MCP Server
/mcp
```

> 💡 新增或修改 MCP 配置後，需重新啟動 Copilot CLI 才會生效。
