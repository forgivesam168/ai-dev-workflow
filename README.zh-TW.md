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
