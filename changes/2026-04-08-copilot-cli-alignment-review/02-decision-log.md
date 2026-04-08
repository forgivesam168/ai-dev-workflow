# 決策日誌：Copilot CLI 官方文件對齊審查

> **規則**：此日誌為 append-only，決策變更時追加新條目，不覆寫歷史。

---

## Decision #1 — 選擇「安全優先升級」路徑

- **日期**：2026-04-08
- **決策者**：專案維護者
- **背景**：深度研究 Copilot CLI 官方文件後，發現 15+ 項功能缺口，其中 3 項涉及安全與合規（Hooks、Copilot Memory、Custom Model Providers）。
- **選項**：
  - A. 最小修補（覆蓋 ~40%，低風險）
  - B. 安全優先升級（覆蓋 ~80%，中風險）⭐ 已選
  - C. 全面升級（覆蓋 ~95%，高風險）
- **決定**：選項 B — 安全優先升級
- **理由**：
  1. 本專案定位為「金融等級 AI 開發工作流模板」，安全機制缺失不可接受
  2. Hooks 是 Copilot CLI 原生提供的安全層，應優先整合
  3. Copilot Memory 可能與精心設計的 instructions 產生非預期互動，需明確策略
  4. Azure OpenAI 支援對金融合規場景至關重要
  5. 投入產出比最佳：中等工作量覆蓋 80% 缺口
- **風險**：
  - Hooks 需要充分測試才能確保不阻塞開發流程
  - Copilot Memory 仍在 Preview，策略文件可能需要隨官方更新調整
- **回滾策略**：
  - Hooks：刪除 `.github/hooks/` 目錄即可停用
  - 文件更新：Git revert

## Decision #2 — Hooks 安全策略

- **日期**：2026-04-08
- **決策者**：專案維護者
- **背景**：Copilot CLI 支援 8 種 Hook 類型，需決定初始實作範圍。
- **決定**：初期實作 3 種 Hook
  - `preToolUse`：攔截危險命令、secret scanning（**最高優先**）
  - `sessionStart`：稽核日誌
  - `postToolUse`：執行結果記錄
- **理由**：
  - `preToolUse` 是唯一能「阻止」操作的 hook，對安全最關鍵
  - `sessionStart` 提供基本的稽核追蹤能力
  - `postToolUse` 提供事後審計能力
  - 其餘 hooks（`sessionEnd`、`errorOccurred` 等）留待後續迭代
- **風險**：hook 執行時間需控制在 5 秒內以避免影響開發體驗

## Decision #3 — Copilot Memory 共存策略

- **日期**：2026-04-08
- **決策者**：專案維護者
- **背景**：Copilot Memory 會自動學習 repo 的 patterns，可能與手動維護的 instructions 產生衝突。
- **決定**：
  - 建議團隊「啟用 Memory，但以 instructions 為 SSOT」
  - 在文件中明確說明 Memory 是「輔助」角色，instructions 是「權威」
  - 提供管理者如何檢視 / 刪除 Memory 的操作指引
- **理由**：
  - Memory 的自動學習能力可以補充 instructions 未覆蓋的細節
  - 但 Memory 28 天過期、非確定性行為不適合作為 SSOT
  - 金融系統需要明確的「規範來源」，instructions 已承擔此角色

## Decision #4 — 指令架構重構：Pointer-Style Guidance

- **日期**：2026-04-08
- **決策者**：專案維護者
- **背景**：審計發現 copilot-instructions.md（131 行）有 56%+ 的內容與 agents/skills/WORKFLOW.md 重複。在 LLM 系統中，copilot-instructions.md 是「每次互動都載入」的唯一檔案，重複內容直接浪費 context window、稀釋注意力、導致行為不確定。
- **選項**：
  - A. 維持現狀（接受重複，但 ~1,365 tokens 浪費/次）
  - B. Pointer-Style Guidance（精簡至 ≤40 行，用指標替代細節）⭐ 已選
  - C. 單一大檔案（全部塞入 copilot-instructions.md，刪除分散檔案）
- **決定**：選項 B — Pointer-Style Guidance
- **設計原則**：
  1. **copilot-instructions.md** = 憲法（Constitution）：安全紅線 + 語言規範 + 財務精度，≤40 行
  2. **agents/*.agent.md** = 角色定義（WHO）：人格、專注領域、核心原則，每個 ≤25 行
  3. **skills/*/SKILL.md** = 操作手冊（HOW）：詳細流程、模板、腳本，不限長度（漸進式載入）
  4. **instructions/*.instructions.md** = 編碼規範（WHAT）：語言/框架特定規範（已良好設計，不變）
- **理由**：
  1. Skills 使用漸進式載入（Progressive Loading）— 只有相關時才消耗 context
  2. copilot-instructions.md 每次都載入 — 越短越好
  3. Agent 選擇後才載入 — 不應包含程序性細節（那是 skill 的工作）
  4. 人類可讀性透過 WORKFLOW.md / README / QUICKSTART 保障（不受影響）
- **預估效益**：copilot-instructions.md 從 ~1,965 tokens → ~600 tokens（節省 69%/次）
- **風險**：
  - 新團隊成員可能不知道去哪裡找詳細規範 → 在 QUICKSTART.md 補充導覽
  - 指標指向的 skill 如果被刪除會失效 → 加入 sync 檢查
- **回滾策略**：Git revert 恢復原始 copilot-instructions.md

## Decision #5 — 合併 plan-from-spec 至 implementation-planning

- **日期**：2026-04-08
- **決策者**：專案維護者
- **背景**：審計發現 `plan-from-spec` skill 是 `implementation-planning` skill 的子集，兩者 80%+ 內容重複。
- **決定**：合併 plan-from-spec 至 implementation-planning，新增「Simplified Mode」章節
- **理由**：
  - 兩個 skill 的 description 都會被掃描（Level 1 Discovery），浪費辨識資源
  - LLM 面對兩個幾乎相同的 skill 會產生選擇不確定性
  - 合併後可在 implementation-planning 中加入「有 spec 直接使用 / 無 spec 先引導」的分支邏輯
- **風險**：引用 plan-from-spec 的現有 prompt 需要更新
- **回滾策略**：保留 plan-from-spec 目錄但標記 deprecated

## Decision #6 — Hooks failBehavior 策略

- **日期**：2026-04-08
- **決策者**：專案維護者
- **背景**：Copilot Hooks 腳本可能逾時或語法錯誤，需決定預設的失敗行為。
- **選項**：
  - A. fail-closed：Hook 失敗 → 阻止操作（最安全，但可能阻塞開發）
  - B. fail-open：Hook 失敗 → 允許操作並記錄警告（使用者友善）⭐ 已選
- **決定**：開發環境預設 fail-open（warn），文件同時說明兩種策略供 production 選擇
- **理由**：
  - 此為開發工具模板，開發體驗不應被 hook 腳本 bug 阻塞
  - 文件中說明 production 環境可改用 fail-closed 策略
  - warn 模式仍記錄所有攔截事件，不會遺失稽核資訊

## Decision #7 — Copilot Memory 指引位置

- **日期**：2026-04-08
- **決策者**：專案維護者
- **背景**：需決定 Copilot Memory 共存指引放在哪個文件中。
- **選項**：
  - A. 獨立檔案 `MEMORY.md`
  - B. WORKFLOW.md 新章節 ⭐ 已選
  - C. copilot-instructions.md 中加入
- **決定**：在 WORKFLOW.md 新增 Copilot Memory 章節
- **理由**：
  - Memory 是工作流的一部分（影響 Copilot 如何理解專案），放在 WORKFLOW.md 最合邏輯
  - 不值得獨立檔案（內容預估 20-30 行）
  - copilot-instructions.md 正在精簡，不應增加內容

## Decision #8 — Severity 命名統一

- **日期**：2026-04-08
- **決策者**：專案維護者
- **背景**：code-reviewer.agent.md 使用 BLOCKER/WARNING/NIT，code-security-review skill 使用 Critical/High/Medium/Low，兩套命名不一致。
- **決定**：統一為 🔴 Critical / 🟡 High / 🟢 Medium / ⚪ Low
- **理由**：
  - 業界通用的 severity 分級更直覺
  - Emoji 前綴提供視覺辨識度
  - 與 skill 已使用的命名一致，減少變更範圍

## Decision #9 — 自動計數 Skills

- **日期**：2026-04-08
- **決策者**：專案維護者
- **背景**：文件中 skills 數量標示為 24，實際為 29（合併後 28），數字不一致問題容易再次發生。
- **決定**：在 `tools/sync-dotgithub.ps1` 中加入 skills 計數驗證
- **理由**：
  - sync 腳本已是每次變更後必執行的工具
  - 自動計數可避免人為疏忽
  - 若計數與文件不符，腳本應輸出警告（不阻塞同步）
