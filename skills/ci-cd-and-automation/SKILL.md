---
name: ci-cd-and-automation
description: >
  CI/CD pipeline design and automation quality gates. Use when designing or
  reviewing continuous integration pipelines, setting up quality gates,
  implementing Shift Left testing strategies, automating deployment workflows,
  or diagnosing slow/broken pipelines. Triggers on: "CI/CD", "pipeline design",
  "quality gate", "Shift Left", "automate deployment", "GitHub Actions",
  "pipeline slow", "build pipeline", "continuous integration", "continuous deployment".
  Do NOT use for production launch decisions (use shipping-and-launch),
  code review (use code-security-review), or infrastructure provisioning.
---

# CI/CD and Automation

Fast, reliable pipelines that catch defects early — not in production.

## When to Use

- Designing a new CI/CD pipeline from scratch
- Adding quality gates to an existing pipeline
- Diagnosing slow or flaky pipelines
- Implementing Shift Left testing strategy
- Automating deployment workflows (staging, production promotion)

---

## Core Principle: Shift Left

> Move quality checks as early as possible — catch defects when they are cheapest to fix.

| Stage | Cost to Fix Defect |
|-------|--------------------|
| Developer's machine (pre-commit) | Lowest |
| CI pipeline (PR) | Low |
| Staging environment | Medium |
| Production | Highest |

**Rule**: Every quality check that can run in CI should run in CI — not just in staging or production.

---

## Pipeline Design

### Recommended Stage Order

```
1. Fast Feedback (< 3 min)
   └── Lint + format check
   └── Unit tests (L1)
   └── Type check / build

2. Integration Gates (< 10 min)
   └── Integration tests (L2)
   └── Security scan (SAST)
   └── Dependency vulnerability check

3. Deployment Gate
   └── Staging deploy
   └── Smoke tests against staging
   └── Performance baseline check (if applicable)

4. Promotion (manual approval or auto, based on risk)
   └── Production deploy
   └── Post-deploy health check
```

### Quality Gate Rules

Each stage is a **hard gate** — pipeline fails and stops if any check fails:

| Gate | Fail Condition | Action |
|------|---------------|--------|
| Lint | Any lint error | Block merge |
| Unit tests | Any test failure | Block merge |
| Coverage | Coverage drops below threshold | Block merge |
| Security scan | Critical/High vulnerability found | Block merge |
| Staging smoke | Smoke test failure | Block production promotion |

### Performance Targets

| Metric | Target | Alert Threshold |
|--------|--------|-----------------|
| Total pipeline duration | < 15 min | > 20 min → investigate |
| Unit test suite | < 3 min | > 5 min → parallelize |
| Flaky test rate | < 1% | > 3% → quarantine + fix |

---

## Shift Left Implementation Checklist

- [ ] Pre-commit hooks: lint, format, secret detection (`git-secrets`, `gitleaks`)
- [ ] PR pipeline: unit tests, type check, build — must complete in < 3 min
- [ ] Security scanning integrated in PR pipeline (not just nightly)
- [ ] Dependency scanning on every PR (`Dependabot`, `Snyk`, `pip-audit`)
- [ ] Coverage gate enforced in CI (not just reported)
- [ ] Flaky tests identified and quarantined (not silently retried)

---

## Anti-Patterns

| Anti-Pattern | Consequence | Fix |
|-------------|------------|-----|
| Tests only run on main branch | Defects merge undetected | Run on every PR |
| Security scan is nightly only | Vulnerabilities ship to production first | Add to PR pipeline |
| Flaky tests retried silently | False confidence; real failures missed | Quarantine + fix |
| Pipeline > 20 min | Engineers skip CI locally; defeats Shift Left | Parallelize; split stages |
| Manual deployment with no automation | Human error; inconsistent environments | Automate all environment promotions |

---

## Common Rationalizations

在設計和維護 CI/CD 管道時，AI 可能以下列藉口降低品質閘門標準：

| 常見藉口 | 反制說明 |
|---------|---------|
| "CI 太慢，先跳過這次" | ⛔ 跳過 CI 是技術債的加速器——每一次「只跳過這次」都讓下一次跳過更容易；正確做法是修復慢 CI，不是繞過它 |
| "這個測試只是 flaky，重跑一次就好" | Flaky 測試不是無害雜訊——它們掩蓋真實的競態條件和環境問題；必須隔離並修復，不得無限重跑 |
| "安全掃描在 nightly 跑就夠了，PR 上不用" | 漏洞在合併後才被發現，修復成本是合併前的 10 倍——安全掃描必須在 PR 上執行，nightly 是補充不是替代 |
| "staging 測試通過了，不用再跑 smoke test" | Staging 環境與 production 永遠存在差異——production smoke test 是確認部署本身正確，不是確認功能正確 |

---

## Verification

在 CI/CD 配置完成或修改後，逐項確認：

- [ ] `Test-Path .github/workflows/*.yml` 或 `Test-Path .gitlab-ci.yml` 至少一項回傳 True（pipeline 配置檔存在）
- [ ] 每個 PR 觸發 unit test + lint + build（不只是 push to main）
- [ ] Coverage gate 已設定且閾值 ≥80%（或符合專案標準）
- [ ] Security / dependency scan 已整合於 PR pipeline（非僅 nightly）
- [ ] 所有 stage 均為 hard gate（失敗即停止，不得 `continue-on-error: true`）
- [ ] Pipeline 總時長 < 15 分鐘（`Fast Feedback` stage < 3 分鐘）
- [ ] Flaky 測試隔離機制存在（quarantine tag 或分離 job）
