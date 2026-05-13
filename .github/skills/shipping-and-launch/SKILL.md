---
name: shipping-and-launch
description: >
  Production deployment and launch management skill. Use when preparing to ship
  a feature to production: staged rollout planning, rollback plan design,
  production readiness checklists, launch go/no-go decisions, and post-launch
  monitoring setup. Triggers on: "deploy to production", "ship this feature",
  "launch plan", "rollout strategy", "rollback plan", "production checklist",
  "go-live", "staged rollout".
  Do NOT use for internal code finalization (use work-archiving),
  CI/CD pipeline design (use ci-cd-and-automation), or code review (use code-security-review).
---

# Shipping and Launch

Safe, controlled production deployments with rollback readiness.

## Scope vs work-archiving

| This Skill | work-archiving |
|------------|----------------|
| External deployment to production | Internal change package finalization |
| Rollout strategy, monitoring, go/no-go | 99-archive.md, CHANGELOG, ADR |
| Customer-facing launch coordination | Team-facing knowledge archiving |

Use **work-archiving** to close out the change package internally, then use this skill to manage the actual production deployment.

---

## When to Use

- Feature is code-review approved and ready for production
- Planning a staged or phased rollout (canary, blue-green, feature flag)
- Need a rollback plan before deploying
- Running a production readiness checklist
- Deciding go / no-go for a launch

---

## Process

### Step 1: Pre-Launch Readiness Check

Before any deployment:

- [ ] All tests passing (CI green on the target branch)
- [ ] Security review completed (Quick Gate ≥ 8/10)
- [ ] Feature flags configured (if using staged rollout)
- [ ] Rollback plan documented (see Step 2)
- [ ] Monitoring / alerting in place for this feature
- [ ] On-call engineer identified and available

### Step 2: Rollback Plan（必須先寫，才能部署）

Document the rollback plan **before** deployment begins:

```markdown
## Rollback Plan: [Feature Name]

**Rollback Trigger**: [Condition that triggers rollback — e.g., "error rate > 1% for 5 min"]
**Rollback Method**: [How to revert — feature flag off / git revert / DB migration down]
**Rollback Owner**: [Who executes — on-call engineer]
**Rollback Time Estimate**: [How long to revert — e.g., "< 5 minutes"]
**Data Impact**: [Any data written during deployment that needs cleanup?]
```

### Step 3: Staged Rollout Strategy

Choose a rollout strategy based on risk level:

| Strategy | Risk Level | Description |
|----------|------------|-------------|
| **Full Deploy** | Low | All users at once; simple features with low blast radius |
| **Feature Flag** | Medium | Enable for % of users or specific segments; toggle off on incident |
| **Canary** | Medium-High | Deploy to small % of traffic first; monitor before expanding |
| **Blue-Green** | High | Run two environments; switch traffic atomically; easy rollback |

### Step 4: Go / No-Go Decision

Before flipping traffic:

| Check | Owner | Status |
|-------|-------|--------|
| CI passing on deploy branch | Eng | ☐ |
| Rollback plan documented | Eng | ☐ |
| Monitoring dashboards ready | Ops | ☐ |
| Stakeholder sign-off (if customer-facing) | PM | ☐ |
| Peak traffic window avoided | Eng | ☐ |

**Any unchecked → No-Go.** Do NOT deploy until all checks pass.

### Step 5: Post-Launch Monitoring

Watch for the first **30 minutes** after deployment:

- Error rate vs baseline (≤ 0.1% increase acceptable)
- P99 latency vs baseline (≤ 20% increase acceptable)
- Key business metrics (conversion, signups, payments — no regression)

If any threshold breached → execute rollback plan immediately.

---

## Common Rationalizations

在準備上線過程中，AI 可能以下列藉口略過安全步驟：

| 常見藉口 | 反制說明 |
|---------|---------|
| "功能已測試通過，直接上線就好" | ⛔ 測試通過 ≠ 上線準備完成——測試確認行為正確，上線準備確認系統容忍失敗；rollback plan 是非談判項目 |
| "這個功能很小，不需要 staged rollout" | 影響範圍是衡量標準，不是功能大小——任何觸及支付/認證/資料遷移的「小功能」都需要至少 feature flag 保護 |
| "rollback 我知道怎麼做，不用寫下來" | 事故發生時的壓力會讓「我知道」消失——rollback plan 必須是可被任何 on-call 工程師執行的書面文件 |
| "監控之後再設，先把功能上了" | 無監控的部署是盲飛——監控必須在 go-live 前就位，否則無法在 30 分鐘窗口內偵測回歸 |

---

## Verification

在執行任何生產部署前，逐項確認：

- [ ] `Test-Path docs/rollback-plan.md` 或 rollback plan 已記錄於 `99-archive.md` 回傳 True
- [ ] Go / No-Go 清單所有項目均已確認（無未檢查項目）
- [ ] 監控 / 告警已就位，並在部署前進行煙霧測試驗證
- [ ] 選擇的 rollout 策略與功能風險等級匹配（High risk → Canary 或 Blue-Green）
- [ ] 部署時間視窗已確認：非尖峰時段、on-call 工程師在線
- [ ] 若有資料遷移，已確認正向 + 反向遷移腳本均通過測試
