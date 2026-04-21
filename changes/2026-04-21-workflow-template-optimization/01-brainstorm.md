# Brainstorm — Workflow Template Optimization

## Problem

目前模板已有六階段流程、change package、source-of-truth / `.github/**` sync、agent/skill 分層載入等優勢，但研究顯示本專案還缺少幾個高槓桿基礎能力：

1. catalog truth / 文件漂移防呆不足
2. bootstrap 缺少可規劃安裝、升級、repair、doctor 能力
3. 缺少 repo-persisted session memory / handoff surface
4. 缺少 deterministic gate-check 與前期 artifact-free explore 模式

此外，README、AGENTS、WORKFLOW、changes 規約之間已出現局部不一致，代表模板本身已進入 brownfield 狀態，若不先補治理層，後續再加功能只會放大摩擦。

## Intake & Risk Classification

- **Work item 類型**：模板優化 / brownfield workflow refactor
- **觸發原因**：依據外部研究報告，發現本 repo 與高信號專案之間存在可補強能力差距
- **影響面**：README、WORKFLOW、AGENTS、instructions、skills、bootstrap scripts、sync tooling、未來 dist/profile surface
- **Brownfield**：是；此 repo 已有既有結構、文件讀者、部署腳本與 runtime mirror
- **Risk Level**：**High**
- **Workflow Path**：**Standard**

## Need-to-Answer Questions

1. 這個模板短期目標是 **Copilot-first**，還是要直接走向 **multi-harness first**？
2. repo memory 要不要預設安裝，還是保持 **opt-in**？
3. deterministic gate-check 是要先做 **報告模式**，還是直接做 **阻擋 handoff / merge 前 hard stop**？
4. install state 要先用 **JSON 檔** 還是直接上 **SQLite state store**？
5. `dist/` / bundle layer 這一輪是否要進 scope，還是先把 source 與 `.github/**` 收斂好？
6. catalog audit 是要只檢查 **count / contract**，還是連文件內的表格與對外說明也一起比對？
7. explore 模式是否允許產出臨時研究筆記，還是嚴格不落盤？

## Assumptions

- 先以 **Copilot surface 為主**，multi-harness 支援先做架構預留，不一次完成
- repo memory 先採 **opt-in**，避免增加預設安裝複雜度
- gate-check 第一版先支援 **deterministic report + clear verdict**，之後再決定是否升級為強制阻擋
- install state 第一版優先用 **JSON manifest**，若未來需要 query / analytics 再升級 SQLite
- 這一輪不做大規模 agent roster 擴張，先補平台基礎層

## Constraints

- 必須維持目前 source-of-truth 與 `.github/**` mirror 的運作模式
- 不應一次把 repo 改造成 ECC 規模；保持模板收斂性優先
- 變更需兼顧 CLI 與 VS Code 使用者說明
- brownfield 安全優先：先修 drift，再加新能力

## Non-Goals

- 本輪不追求引入大量新 agents / 100+ skills
- 本輪不直接重寫整個六階段流程
- 本輪不把專案全面改造成 OpenSpec 原生 workflow
- 本輪不實作完整 external service memory backend
- 本輪不先做大規模 multi-harness 發布矩陣

## Options

### Option A — Foundation First（先補治理與平台基礎）

- **Complexity**：Medium
- **內容**：
  1. 對齊 README / AGENTS / WORKFLOW / changes contract
  2. 新增 catalog audit script
  3. 新增 `install-plan` / `install-apply` / `doctor` 設計
  4. 新增 repo memory skeleton
  5. 新增 `explore` 與 `gate-check` 能力
- **優點**：
  - 先處理現有 drift，降低後續功能擴充摩擦
  - 對使用者價值立即可見
  - 最符合研究報告中的高槓桿建議
- **缺點**：
  - 不會立刻讓模板看起來「功能暴增」
  - 需要跨文件、腳本、skills 多點修改
- **Dependencies**：
  - 現有 bootstrap / sync 架構
  - README / AGENTS / WORKFLOW 的現況對齊
- **Rollback**：
  - 分 workstream 小步提交
  - install / audit / memory 新增檔案可逐步回退

### Option B — Platform Leap（直接做完整安裝器 + state store）

- **Complexity**：High
- **內容**：
  - 一次導入 manifest-driven installer、install state、doctor、repair、memory、dist surface
- **優點**：
  - 中長期架構最完整
  - 更接近 ECC / spec-kit 等成熟專案的產品化表面
- **缺點**：
  - 風險高，變動範圍大
  - 在現有 drift 未收斂前，很容易疊加複雜度
- **Dependencies**：
  - 清楚的 profile / component model
  - 安裝面與文件面全面重寫
- **Rollback**：
  - 困難；多個新概念會互相耦合

### Option C — Workflow Productization First（先抽 schema / profile / dist）

- **Complexity**：High
- **內容**：
  - 先做 profile / preset / dist 分層，延後 gate-check 與 memory
- **優點**：
  - 對「模板平台化」敘事很強
  - 對未來 multi-harness 支援有利
- **缺點**：
  - 先解外部擴展，不先解內部 drift
  - 會讓現有文件與 bootstrap 更快失配
- **Dependencies**：
  - 清楚的 canonical catalog 與 contract
  - bundle/runtime 對應矩陣
- **Rollback**：
  - 中等；可回退，但會殘留半成品結構

## Recommendation

選擇 **Option A — Foundation First**。

理由：

1. 它直接對應研究結論中的最高槓桿缺口：catalog drift、installer、memory、gate-check
2. 它最符合 brownfield 安全演進：**先保一致性，再擴能力**
3. 它能為後續 Option B / C 提供穩定基座，而不是在不一致的文件與 contract 上疊更大平台層

## Proposed Delivery Waves

### Wave 1 — Drift & Truth
- 對齊 README / AGENTS / WORKFLOW / changes contract
- 新增 catalog audit script

### Wave 2 — Install Surface
- 設計 `install-plan` / `install-apply` / `doctor`
- 先保留 `Init-Project.ps1`，逐步轉為 wrapper

### Wave 3 — Workflow Enhancements
- 新增 `explore` skill / mode
- 新增 deterministic `gate-check`
- 補 subagent status protocol 到 agent 指令

### Wave 4 — Memory & Future-proofing
- 新增 `.ai-workflow-memory/` skeleton
- 評估 `profiles/` 與 `dist/` 是否進下一輪 scope

### Wave 5 — Superpowers Execution Protocol
- 補 subagent status protocol 到 coder-agent / plan-agent / architect-agent
- 制定 two-stage review ordering：spec compliance 優先，code quality 其次
- 評估 git worktree isolation 是否需要獨立 skill

> **研究依據**：源自 Superpowers `subagent-driven-development/SKILL.md` 的 `DONE / DONE_WITH_CONCERNS / NEEDS_CONTEXT / BLOCKED` 協定，以及 two-stage review ordering 規範（先 spec compliance，再 code quality）。  
> **排在 Wave 5 的原因**：此能力依賴 Wave 3 的 gate-check（提供 spec compliance 判定基礎）；Wave 1–2 drift 收斂後，agent 執行紀律才能可靠執行。

### Future Scope（明確不在本輪）
- `profiles/` preset / profile layer（對應不同團隊：finance、general-web、internal-platform）
- `dist/` bundle surface（對應多 harness：Copilot CLI、VS Code、Claude Code、Codex）
- schema-driven workflow customization（參考 OpenSpec `config.yaml` + artifact graph）
- delta spec pattern（`specs/` vs `changes/` 分離，brownfield-friendly）

## Rollback / Mitigation

- 每個 wave 分開提交，避免單一超大 PR
- 先新增 audit / doctor，再讓它開始阻擋流程
- 所有新 surface 預設 non-breaking、opt-in 為主
- 若 install surface 改動造成使用摩擦，可暫時保留舊 `Init-Project.ps1` 為相容入口

## Brainstorm Summary

**Problem**: 模板已具備不錯骨架，但缺少 installer、memory、deterministic gates 與 catalog drift guard 等高槓桿基礎能力。  
**Risk Level**: High  
**Workflow Path**: Standard  
**Chosen Approach**: Option A — Foundation First；先收斂 drift 與治理層，再逐步補 installer / memory / gate-check。

**Open Questions**:
- multi-harness 支援是否要列入這一輪
- gate-check 是否第一版就阻擋 handoff
- install state 先用 JSON 還是 SQLite

**Assumptions**:
- Copilot-first，multi-harness 後移
- memory 先 opt-in
- gate-check 第一版先做 deterministic report

**Non-goals**:
- 不大幅擴 agent roster
- 不全面改寫六階段流程
- 不一次引入完整 dist/profile 生態
