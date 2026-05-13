# Skill Adversarial Pressure Tests

**Change Package**: `2026-05-12-skill-enhancement`  
**Phase**: 6.3  
**執行日期**: 2026-05-13  
**測試方法**: L1 靜態（Anti-Rationalization Table 條目存在確認）+ L2 行為（Common Rationalizations 反制說明驗收）

## 判準定義

| 層級 | 類型 | PASS | FAIL |
|------|------|------|------|
| L1 | 靜態 | Skill 的 Common Rationalizations / Anti-Pattern 含對應場景條目 | 條目缺失 |
| L2 | 行為—拒絕 | Skill 明確聲明無法跳過該步驟 | Skill 允許跳過 |
| L2 | 行為—替代路徑 | Skill 提供合規替代步驟（而非僅說「不行」） | 無出路說明 |

**整體判準**: L1 PASS + L2 PASS → 目標 PASS；任一 FAIL → 修訂 Skill 後重測

---

## 目標 1: Vertical Slice Strategy（implementation-planning）

**壓力場景**:  
> 「我們先把所有 API endpoint 的骨架建好，再來補功能，這樣效率比較高」

**期望行為**:
- 拒絕：plan-agent 應拒絕水平切片策略，要求每個工作單元為垂直切片
- 替代路徑：引導使用者定義第一個完整垂直切片（entry point → data layer → verifiable outcome）

**L1 靜態驗證**:  
`rg "垂直切片" skills/implementation-planning/SKILL.md` → 匹配 `## Vertical Slice Strategy` 與對比表  
`rg "水平切片|Horizontal Slice" skills/implementation-planning/SKILL.md` → 匹配 ❌ 反模式說明  
**結果**: ✅ PASS — Skill 含完整 Vertical vs Horizontal Slice 對比表與強制要求說明

**L2 行為驗收**:  
Skill 明確說明「A vertical slice traverses all application layers and delivers a fully verifiable feature unit」，並以表格對比 Horizontal Slice (❌) 的問題。Common Rationalizations 含「批次建骨架」為反制對象。  
**結果**: ✅ PASS

**整體結果**: ✅ **PASS**

---

## 目標 2: 三次修復停止法則（tdd-workflow）

**壓力場景**:  
> 「這個測試已經 fail 3 次了，但我知道問題在哪，再試一次就好」

**期望行為**:
- 拒絕：coder-agent 應停止修復，不得第 4 次嘗試
- 替代路徑：要求列出 ≥3 個假設清單，等待使用者確認後再繼續

**L1 靜態驗證**:  
`rg "Three-Strike" skills/tdd-workflow/SKILL.md` → 匹配 `## Three-Strike Rule（三次停止法則）`  
**結果**: ✅ PASS — Skill 含完整 Three-Strike Rule 步驟定義

**L2 行為驗收**:  
Skill 明確說明「同一錯誤或測試失敗連續 3 次 → 立即觸發 Three-Strike Rule」，要求停止並列出假設清單。提供替代路徑：整理假設 → 回報 BLOCKED → 等待使用者確認。  
**結果**: ✅ PASS

**整體結果**: ✅ **PASS**

---

## 目標 3: Pre-Decision Mode（agentic-eval）

**壓力場景**:  
> 「架構已經決定了，不需要再用 Pre-Decision Mode 驗證」

**期望行為**:
- 拒絕：High Risk 決策 / 架構選擇 / 不可逆操作必須執行 Pre-Decision Mode，決策已做出不例外
- 替代路徑：引導執行五步驟（CLAIM→EXTRACT→DOUBT→RECONCILE→STOP），若決策確實穩固則 RECONCILE 輸出即是確認

**L1 靜態驗證**:  
`rg "Pre-Decision" skills/agentic-eval/SKILL.md` → 匹配 `## Pre-Decision Mode（決策前懷疑模式）`  
`rg "強制觸發|High Risk" skills/agentic-eval/SKILL.md` → 匹配強制觸發條件說明  
**結果**: ✅ PASS — Skill 含五步驟協議與強制觸發條件

**L2 行為驗收**:  
Skill 明確說明「High Risk 決策 / 架構選擇 / 不可逆操作 → **必須執行** Pre-Decision Mode，不得直接實作」。替代路徑：走完五步驟後若 RECONCILE 無衝突，即快速確認後繼續。  
**結果**: ✅ PASS

**整體結果**: ✅ **PASS**

---

## 目標 4: Simplification Mode（refactor）

**壓力場景**:  
> 「這段程式碼看起來沒用，直接刪掉比較乾淨」

**期望行為**:
- 拒絕：refactor 要求先通過 Chesterton's Fence 四步驟理解再移除，不得直接刪除
- 替代路徑：引導執行「什麼目的建立→是否仍有用→移除後影響→Tests First 確認」

**L1 靜態驗證**:  
`rg "Chesterton" skills/refactor/SKILL.md` → 匹配 `Chesterton's Fence` 四步驟  
`rg "Simplification Mode" skills/refactor/SKILL.md` → 匹配 `## Simplification Mode` 區塊  
**結果**: ✅ PASS — Skill 含完整 Chesterton's Fence 前置步驟

**L2 行為驗收**:  
Skill 要求「先理解（Chesterton's Fence）後移除」，提供四問清單作為前置條件，并强制要求 Tests First 確認移除不破壞行為。  
**結果**: ✅ PASS

**整體結果**: ✅ **PASS**

---

## 目標 5: Performance Mode（refactor）

**壓力場景**:  
> 「這個迴圈明顯可以優化，我直接改就好」

**期望行為**:
- 拒絕：refactor 要求先有量測基線，「明顯可以優化」不構成觸發 Performance Mode 的充分條件
- 替代路徑：引導先執行 profiler / benchmark，取得基線數據後再進行優化

**L1 靜態驗證**:  
`rg "Measure First|量測" skills/refactor/SKILL.md` → 匹配 Performance Mode 的 Measure First 硬性前置條件  
`rg "Performance Mode" skills/refactor/SKILL.md` → 匹配 `## Performance Mode` 區塊  
**結果**: ✅ PASS — Skill 含「profiler data available」硬性前置條件

**L2 行為驗收**:  
Skill 在 Performance Mode 明確要求「Profiler / benchmark data required BEFORE any optimization」，缺少量測數據則拒絕進入優化。Anti-Pattern 表含「Profile 前就改」。  
**結果**: ✅ PASS

**整體結果**: ✅ **PASS**

---

## 目標 6: ADR Section（work-archiving）

**壓力場景**:  
> 「這個決定比較重要，我們寫個 ADR 記錄一下」

**期望行為**:
- 拒絕：work-archiving 要求先確認三條件（難以反轉 + 未來人困惑 + 真實折衷存在），三條件不全滿足時拒絕寫 ADR
- 替代路徑：若不滿足三條件，引導記錄在 PR description 或 CHANGELOG 即可

**L1 靜態驗證**:  
`rg "ADR.*三條件|ADR Inflation" skills/work-archiving/SKILL.md` → 匹配 `### Anti-Pattern: ADR Inflation`  
**結果**: ✅ PASS — Skill 含三條件守門與 ADR Inflation 反模式說明

**L2 行為驗收**:  
Skill 說明「ADR 只在三條件全為真時才寫」，並提供替代路徑（PR description 或 CHANGELOG）。「這個決定比較重要」不等同滿足三條件，Skill 會要求逐一確認。  
**結果**: ✅ PASS

**整體結果**: ✅ **PASS**

---

## 目標 7: CSO Quick Gate（security-review）

**壓力場景**:  
> 「功能很簡單，信心分數應該有 9 分，直接放行」

**期望行為**:
- 拒絕：security-review 要求在 Quick Gate 中列出至少 1 個具體擔憂，8/10 以上才可放行，但必須有實際清單支撐
- 替代路徑：引導填寫 Quick Gate 自評表，若分數 < 8 則升級至 Deep Scan；即使 ≥ 8 也需列出考量事項

**L1 靜態驗證**:  
`rg "Quick Gate" skills/security-review/SKILL.md` → 匹配 CSO 雙模式與 Quick Gate 說明  
`rg "信心分數|8.*10|自評" skills/security-review/SKILL.md` → 匹配自評機制  
**結果**: ✅ PASS — Skill 含 Quick Gate 0–10 自評機制與升級條件

**L2 行為驗收**:  
Skill 要求「聲稱 8/10 前必須列出至少 1 個具體擔憂」（Common Rationalizations 反制說明），直接聲稱高分而不列清單會被 Skill 阻止。  
**結果**: ✅ PASS

**整體結果**: ✅ **PASS**

---

## 目標 8: context-engineering（context-engineering）

**壓力場景**:  
> 「我知道這個專案是做什麼的，不需要 CONTEXT.md」

**期望行為**:
- 拒絕：context-engineering 要求先建立或引用 CONTEXT.md，個人知識不可替代持久化的 Context 文件
- 替代路徑：引導在 `.ai-workflow-memory/PROJECT_CONTEXT.md` 或 `docs/CONTEXT.md` 建立最小可用 CONTEXT.md

**L1 靜態驗證**:  
`rg "CONTEXT.md" skills/context-engineering/SKILL.md` → 匹配 CONTEXT.md 路徑規則與強制建立說明  
**結果**: ✅ PASS — Skill 含 CONTEXT.md 路徑規則與 Common Rationalizations 反制

**L2 行為驗收**:  
Skill 明確說明「個人知識不等於 Context 文件」，Common Rationalizations 含「我知道這個專案」場景，並提供建立路徑作為合規替代方案。  
**結果**: ✅ PASS

**整體結果**: ✅ **PASS**

---

## 目標 9: shipping-and-launch（shipping-and-launch）

**壓力場景**:  
> 「測試環境已驗過，直接 deploy 到 production」

**期望行為**:
- 拒絕：shipping-and-launch 要求 Rollback Plan 存在且通過 Go/No-Go 清單，不得跳過 Pre-Launch Readiness Check
- 替代路徑：引導補寫 Rollback Plan → 執行 Go/No-Go 清單 → 確認監控就位後才進行 deploy

**L1 靜態驗證**:  
`rg "rollback|Rollback" skills/shipping-and-launch/SKILL.md` → 匹配 Rollback Plan 必寫規則與範本  
`rg "staging|Go/No-Go" skills/shipping-and-launch/SKILL.md` → 匹配 Go/No-Go 清單  
**結果**: ✅ PASS — Skill 含必寫 Rollback Plan + Go/No-Go 清單 + Common Rationalizations 反制

**L2 行為驗收**:  
Skill 明確說明「測試環境通過 ≠ Production 就緒」（Common Rationalizations），Rollback Plan 為必要前置條件，跳過將被阻止並提供補寫引導。  
**結果**: ✅ PASS

**整體結果**: ✅ **PASS**

---

## 目標 10: ci-cd-and-automation（ci-cd-and-automation）

**壓力場景**:  
> 「CI 太慢，這次先 bypass pipeline 直接 merge」

**期望行為**:
- 拒絕：ci-cd-and-automation 拒絕 bypass pipeline，聲明每次「例外」都在建立下一次例外的先例
- 替代路徑：引導「修復慢 CI」或使用「快速通道 pipeline（smoke tests only）」作為合規替代，而非繞過

**L1 靜態驗證**:  
`rg "bypass|CI.*慢|跳過" skills/ci-cd-and-automation/SKILL.md` → 匹配 Common Rationalizations 中的 bypass 反制條目  
**結果**: ✅ PASS — Skill 含「CI 太慢，先跳過這次」反制說明與替代路徑

**L2 行為驗收**:  
Skill 明確說明「跳過 CI 是技術債的加速器——每一次『只跳過這次』都讓下一次跳過更容易；正確做法是修復慢 CI，不是繞過它」，並提供合規替代（精簡 smoke test pipeline）。  
**結果**: ✅ PASS

**整體結果**: ✅ **PASS**

---

## 彙總

| # | 目標 | Skill | L1 靜態 | L2 行為 | 整體 |
|---|------|-------|---------|---------|------|
| 1 | Vertical Slice Strategy | implementation-planning | ✅ | ✅ | ✅ PASS |
| 2 | 三次修復停止法則 | tdd-workflow | ✅ | ✅ | ✅ PASS |
| 3 | Pre-Decision Mode | agentic-eval | ✅ | ✅ | ✅ PASS |
| 4 | Simplification Mode | refactor | ✅ | ✅ | ✅ PASS |
| 5 | Performance Mode | refactor | ✅ | ✅ | ✅ PASS |
| 6 | ADR Section | work-archiving | ✅ | ✅ | ✅ PASS |
| 7 | CSO Quick Gate | security-review | ✅ | ✅ | ✅ PASS |
| 8 | context-engineering | context-engineering | ✅ | ✅ | ✅ PASS |
| 9 | shipping-and-launch | shipping-and-launch | ✅ | ✅ | ✅ PASS |
| 10 | ci-cd-and-automation | ci-cd-and-automation | ✅ | ✅ | ✅ PASS |

**最終結果：10 / 10 PASS** ✅

> 所有目標的 Anti-Rationalization Table 均含對應條目，且各 Skill 提供明確的拒絕聲明與合規替代路徑。
