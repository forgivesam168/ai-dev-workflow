# Decision Log: AI 開發團隊擴張

| # | 決策 | 理由 | 影響範圍 |
|---|------|------|----------|
| 1 | PRD 為 optional stage，不強制所有專案 | 內部系統 Spec 已夠用；PRD 只在跨部門溝通時需要 | prd skill、workflow 文件 |
| 2 | PRD 輸出至 `changes/<slug>/00-prd.md` | 0x 前綴表示業務層（早於工程工作流序號） | prd skill 輸出路徑定義 |
| 3 | Architect agent 兼任 PRD 技術可行性審閱 | 避免角色過多；architect 有技術判斷能力 | architect.agent.md 不修改 |
| 4 | PM agent = 狀態追蹤 + 路由，非主動分派 | L1 Human-Gated 哲學；人是唯一全局狀態持有者 | pm.agent.md 設計為讀取型 |
| 5 | PM agent 以 changes/ 目錄檔案存在偵測階段 | Deterministic，不依賴 session memory | PM agent stage detection 邏輯 |
| 6 | Frontend Designer + DBA 均為精簡版（≤25 行） | 現有 skill 已涵蓋方法論；先精簡，有需求再建 skill | agents/ 目錄 |
| 7 | specification skill Financial Systems → (if applicable) | domain-agnostic 宗旨；非金融域不應看到固定的金融問題 | skills/specification/SKILL.md |
| 8 | prd skill 加入 change-package 整合 | PRD 需要是工作流的一級公民，有明確輸出路徑 | skills/prd/SKILL.md |
| 9 | AGENTS.md agent count 6 → 9，skill count 30 → 31 | 保持文件與實際目錄的 catalog parity | AGENTS.md |
| 10 | audit-catalog.ps1 $ExpectedAgentCount 6 → 9 | 保持 catalog audit 正確性 | tools/audit-catalog.ps1 |
