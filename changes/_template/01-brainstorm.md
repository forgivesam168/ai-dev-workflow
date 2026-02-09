# 01 Brainstorm（釐清與方案比較）
> 目的：在寫任何程式碼前，把「問題、範圍、成功標準、方案、技術棧與風險」先對齊，減少來回溝通。

## 需求與成功標準
- 目標（Goals）：
- 非目標（Non-goals）：
- 成功標準（Success criteria，可驗收）：
  - 

## 釐清問題（Questions to answer）
- 
- 

## 目前已知/未知
- 已知：
- 未知：

## 限制與約束（Constraints）
- 合規/法規：
- 資安（權限、資料敏感度、稽核）：
- 營運（維運人力、監控、備援）：
- 技術/環境（內網/封網、Windows/ Linux、既有系統相依）：

## 技術棧/架構選型（在這裡做出「可辯護」的決策）
> 原則：**先選能成功交付**的最小可行技術棧；例外要寫清楚理由。
- Frontend：
- Backend：
- Database / Storage：
- Integration / Messaging（如有）：
- CI/CD（先最小化）：
- Observability（Log/Metric/Tracing）：

### 候選方案（Options）
#### Option A（建議：沿用既有/團隊熟悉）
- 做法：
- 優點：
- 缺點/風險：
- 對新手的學習成本：

#### Option B（替代方案）
- 做法：
- 優點：
- 缺點/風險：
- 對新手的學習成本：

#### Option C（如需）
- 做法：
- 優點：
- 缺點/風險：
- 對新手的學習成本：

## 建議方案（Recommendation）
- 選擇：Option __
- 理由（請對齊成功標準與限制）：
- 風險與緩解（Mitigation）：
- 開放問題（Open questions）：

## 下一步（連結到計畫/規格）
- 將關鍵決策寫入 `02-decision-log.md`（append-only）
- 補齊 `03-spec.md`（驗收口徑、邊界條件、資料/介面）
- 產出 `04-plan.md` / `05-test-plan.md`
