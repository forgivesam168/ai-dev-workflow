# Implementation Plan: Install Surface Implementation

**Spec Reference**: `docs/install-surface-design.md`  
**Risk Level**: Medium  
**Workflow Path**: 🟢 Fast

## 交付物

| 檔案 | 用途 |
|------|------|
| `tools/install-helpers.psm1` | 共用模組（元件枚舉、hash 比對、狀態判斷）|
| `tools/install-plan.ps1` | Dry-run 預覽 |
| `tools/install-apply.ps1` | 實際安裝 + manifest 寫入 |
| `tools/doctor.ps1` | Drift 檢查 + 目錄 parity |

## 實作順序

1. install-helpers.psm1（共用邏輯）
2. install-plan.ps1（最簡單，只讀）
3. doctor.ps1（自身 check，整合 audit-catalog.ps1）
4. install-apply.ps1（寫入 + manifest）
5. 端對端驗證（自身模式 + 模擬 target 模式）

## 驗收標準

- [ ] `install-plan`（無 --Target）顯示 source vs .github/** 狀態
- [ ] `install-plan --Target <path>`顯示 template vs 目標 repo 狀態
- [ ] `install-apply`（無 --Target）與 sync-dotgithub.ps1 結果一致（skip-if-exists 模式）
- [ ] `install-apply --Force`（無 --Target）全數覆蓋（等同 sync-dotgithub.ps1）
- [ ] `install-apply --Target <path>`寫入 manifest `.ai-workflow-install.json`
- [ ] `install-apply --EnableMemory`建立 `.ai-workflow-memory/` skeleton
- [ ] `doctor`（無 --Target）: DOCTOR PASSED on clean repo
- [ ] `doctor`（無 --Target）: DOCTOR FAILED 當 source 與 .github/** 有 drift
- [ ] `audit-catalog.ps1` 通過（tools/ 下只有 .ps1，不計入 skill/agent count）
