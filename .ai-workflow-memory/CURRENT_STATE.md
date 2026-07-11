# Current State

## Status as of 2026-07-11

- **Active work**: Trustworthy Baseline Recovery (`changes/2026-07-11-trustworthy-baseline-recovery/`)
- **Stage**: P0 implementation and Windows-local baseline green; cross-platform CI observation pending
- **Last action**: 新增唯讀 sync checker、35/34/1 catalog contract、relative-path regression、pinned test gate 與 Windows/Ubuntu CI matrix
- **Next step**: 在另行核准 commit/push 後觀察 Windows/Ubuntu GitHub Actions matrix；未實跑前不得宣稱 cross-platform baseline green
- **Blockers**: 本機沒有可用 Ubuntu runtime（無 WSL distro；Docker daemon unavailable），且本輪禁止 push，因此 Ubuntu matrix 尚未實際執行
- **Latest progress**:
  - `tools/check-sync.ps1` 僅檢查 generator-managed `.github` destinations，並以 isolated fixtures 覆蓋 clean / drift / unmanaged paths
  - Catalog contract 固定為 35 total / 34 adopter / 1 maintainer-only `gate-check`
  - Python / PowerShell relative-path normalization 保留 dot-directory 與 `../` identity
  - Windows-local baseline green ✅（Python 59 / Pester 39 / catalog 9 agents, 10 prompts, 35 total skills = 34 adopter + 1 maintainer-only）
  - Read-only checker ✅ clean，執行前後 `git status --porcelain=v1` 完全相同
  - Windows/Ubuntu CI matrix configured，但 Ubuntu 尚未 observed
  - Cross-platform baseline 尚不能宣稱 green
