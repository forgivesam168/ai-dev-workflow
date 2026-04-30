# Brainstorm: AI 開發團隊擴張

## 背景

ai-dev-workflow 已完成 Phase 1（catalog alignment、change-package contract、audit script）及 agent 精簡（6 個 agent 均 ≤25 non-empty lines）。在 skill audit 補齊（brainstorming / implementation-planning / tdd-workflow）後，討論下一步架構方向。

## 觸發問題

- 公司內部系統開發需求增加，需要更完整的 AI 開發團隊分工
- 現有 workflow 缺少：PM 角色（狀態追蹤）、前端設計師、DBA
- 需要釐清 PRD vs Spec 的角色定位與工作流層次
- specification skill 仍有 domain-specific 的硬編問題（Financial Systems 固定 section）
- prd skill 無法整合到 change-package 工作流

## 核心討論

### PRD vs Spec 差異

| 維度 | PRD | Spec |
|---|---|---|
| 受眾 | 管理層、利害關係人、PM | 工程師、測試、架構師 |
| 語言 | 業務語言（WHY/WHO/WHAT/KPI） | 工程語言（AC/constraints/data models）|
| 適用 | 跨部門溝通、策略型專案 | 大多數內部系統開發 |

**結論**：Spec 足以應付大多數內部需求；PRD 是 optional 的業務對齊層。

### 工作流三層

- 🔴 策略型：Brainstorm → PRD → Spec → Plan → TDD → Review → Archive
- 🟡 標準型：Brainstorm → Spec → Plan → TDD → Review → Archive
- 🟢 快速通道：Spec → Plan → TDD → Review

### AI 開發團隊自主化哲學（L1 Human-Gated）

> AI 寫文件 → 人確認 → AI 執行 → AI 自審 → 人最終確認

- 不急著進化到 agency-swarm L2/L3（自動代理委派）
- 人是唯一全局狀態持有者；每個 agent 只負責自己的 stage
- 先讓 L1 穩定可信，再考慮自主化

### PM Agent 的核心洞見

- 跨 session 狀態追蹤不依賴 session memory
- 使用 `changes/` 目錄的**檔案存在情況**作為 deterministic 狀態指標
- 智慧助理型 PM，非主動分派型 CEO agent

### 參考

- agency-agents (msitarzewski): 角色型 agent 定義文件庫，install.sh 多工具部署 → 同等方向
- docs/research/openspec-sdd-ai-agent-research.md: ECC harness / Priority 2 repo memory

## Brainstorm Summary

**Problem**: Workflow 缺少 PM、前端設計師、DBA 角色；PRD 定位不清；specification/prd skill 有品質問題
**Risk Level**: Low（template 自身演進，不影響外部系統）
**Workflow Path**: Fast
**Chosen Approach**: 建立 3 個新 agent + 修正 2 個 skill + 更新文件與腳本
**Open Questions**: 未來是否需要 profile/preset 系統（finance / web / internal-platform）
**Assumptions**: 維持 L1 Human-Gated 哲學，不急著自動化代理協調
**Non-goals**: Agency Swarm Python runtime（遠期）；harness/state store 層（遠期）；profile 系統（Phase 3）
