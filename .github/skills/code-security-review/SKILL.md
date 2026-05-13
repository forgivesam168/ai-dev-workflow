---
name: code-security-review
description: 'Comprehensive code quality and security audit for financial systems. Use when asked to "review code", "code review", "security audit", "check for issues", "審核程式碼", "檢查安全性", or before merging changes. Focuses on DDD compliance, financial precision (no floats for money), security vulnerabilities, and test coverage.'
license: See LICENSE.txt in repository root
---

# Code & Security Review

> 💡 **Recommended Agent**: `code-reviewer-agent` (Senior Code Quality Auditor)
> - **CLI**: Input `/agent` and select `code-reviewer-agent`
> - **VS Code**: Use `@workspace #code-reviewer-agent` in Chat
>
> **⚠️ CLI Note**: Use natural language like "review 我的 code". VS Code users can use `/code-review` shortcut.

## When to Use This Skill

Use this skill when:
- Implementation is complete and ready for review
- Before creating pull request
- After TDD implementation phase
- Suspicious code or security concerns
- 實作完成,準備提交 PR 前
- 需要檢查程式碼品質與安全性

## Prerequisites

**Required**:
- Code changes committed or staged (`git status` shows modifications)
- Implementation phase complete

**Recommended**:
- `04-plan.md` to verify all tasks completed
- Tests passing and coverage ≥80%

## Review Priorities (High → Low)

### 🔴 Critical (Must Fix)
1. **Security vulnerabilities** (injection, auth bypass, secrets)
2. **Financial precision errors** (float/double for money)
3. **Data integrity risks** (race conditions, lost updates)
4. **Breaking changes** (undocumented API changes)

### 🟡 High (Should Fix)
5. **Test coverage** (<80%)
6. **DDD violations** (anemic models, leaked domain logic)
7. **SOLID violations** (tight coupling, god classes)
8. **Error handling gaps** (unhandled exceptions)

### 🟢 Medium (Nice to Fix)
9. **Naming conventions** (unclear variable names)
10. **Code duplication** (DRY violations)
11. **Performance issues** (N+1 queries)

### ⚪ Low (Optional)
12. **Style inconsistencies** (formatting, minor refactoring)

## Step-by-Step Review Process

### Step 1: Get Code Changes

```bash
# Check git status
git status

# View staged/unstaged changes
git diff

# Or compare branch
git diff main...feature-branch
```

### Step 2: Run Security Audit

Check for **Critical Security Issues**:

| Issue | How to Detect | Fix |
|-------|--------------|-----|
| **Secrets in code** | Search for API keys, passwords, tokens | Move to environment variables |
| **SQL injection** | Raw SQL with string concatenation | Use parameterized queries |
| **XSS vulnerabilities** | Unescaped user input in HTML | Sanitize inputs, escape outputs |
| **Auth bypass** | Missing authorization checks | Add RBAC/ABAC checks |
| **Insecure dependencies** | `npm audit` / `pip-audit` | Update vulnerable packages |

**Financial Systems Specific**:
- ✅ Money fields use `decimal` (NOT float/double)
- ✅ Idempotency keys validated for transactions
- ✅ Audit logging present for sensitive operations
- ✅ Timezone handling (store UTC, display local)

### Step 3: Code Quality Audit

**DDD Compliance**:
- [ ] Entities have identity and behavior (not anemic)
- [ ] Value objects are immutable
- [ ] Domain logic in domain layer (not controllers/API)
- [ ] Aggregates enforce invariants
- [ ] Domain events for cross-aggregate communication

**SOLID Principles**:
- [ ] Single Responsibility: Each class/function one purpose
- [ ] Open/Closed: Extendable without modification
- [ ] Liskov Substitution: Subtypes are substitutable
- [ ] Interface Segregation: Small, focused interfaces
- [ ] Dependency Inversion: Depend on abstractions

**Naming Conventions** (C#):
- [ ] PascalCase for classes, methods, properties
- [ ] camelCase for local variables, parameters
- [ ] Interfaces prefixed with `I`
- [ ] Test methods: `MethodName_Condition_ExpectedResult`

### Step 4: Test Coverage Check

```bash
# Run tests with coverage
npm test -- --coverage
# Or
dotnet test /p:CollectCoverage=true
```

**Coverage Requirements**:
- **80% minimum** for all code
- **100% required** for:
  - Financial calculations
  - Authentication/authorization logic
  - Security-critical code
  - Core business logic

**Test Quality**:
- [ ] Tests verify behavior (not implementation)
- [ ] Edge cases covered
- [ ] Error scenarios tested
- [ ] Integration tests for critical paths

### Step 5: Generate Review Document

Create `changes/<YYYY-MM-DD>-<slug>/05-review.md`:

---

**Template**:

```markdown
# Code Review: {Feature Name}

**Date**: {YYYY-MM-DD}
**Reviewer**: {Name or "AI Agent"}
**Status**: 🔴 Needs Work / 🟡 Minor Issues / 🟢 Approved

---

## Summary
{Brief overview of changes and overall assessment}

**Files Changed**: {X files}
**Lines Added**: {+Y}
**Lines Removed**: {-Z}

---

## Critical Issues 🔴 (Must Fix Before Merge)

### Issue 1: {Title}
**Severity**: Critical
**File**: `{path/to/file.ts}:{line}`
**Problem**: {Description of the issue}
**Risk**: {What could go wrong}
**Fix**: {How to resolve}

**Code**:
```typescript
// ❌ BAD
double price = 19.99; // Floating point for money
```

**Recommended**:
```typescript
// ✅ GOOD
decimal price = 19.99M; // Decimal for money
```

---

### Issue 2: {Title}
{Repeat structure}

---

## High Priority Issues 🟡 (Should Fix)

### Issue 3: {Title}
**Severity**: High
**File**: `{path/to/file.ts}:{line}`
**Problem**: {Description}
**Fix**: {Solution}

---

## Medium Priority Issues 🟢 (Nice to Fix)

### Issue 4: {Title}
**Severity**: Medium
**File**: `{path/to/file.ts}:{line}`
**Problem**: {Description}
**Fix**: {Solution}

---

## Security Checklist

- [ ] No secrets or credentials in code
- [ ] SQL injection prevented (parameterized queries)
- [ ] XSS prevented (input sanitization, output escaping)
- [ ] Authorization checks present
- [ ] Dependencies up to date (no known vulnerabilities)
- [ ] Money fields use decimal (NOT float/double)
- [ ] Idempotency implemented for transactions
- [ ] Audit logging for sensitive operations

---

## Financial Precision Checklist

- [ ] Money stored as `decimal` or integer minor units
- [ ] Currency explicitly stored (ISO 4217 code)
- [ ] Idempotency-Key supported for transactional endpoints
- [ ] Timezone: UTC storage, local display
- [ ] Audit trail: Who, What, When logged

---

## Code Quality Assessment

### DDD Compliance
- [ ] Entities have behavior (not anemic models)
- [ ] Value objects are immutable
- [ ] Domain logic in domain layer
- [ ] Aggregates enforce invariants

### SOLID Principles
- [ ] Single Responsibility
- [ ] Open/Closed
- [ ] Liskov Substitution
- [ ] Interface Segregation
- [ ] Dependency Inversion

### Naming & Style
- [ ] Clear, descriptive names
- [ ] Consistent formatting
- [ ] No magic numbers/strings
- [ ] Appropriate comments (why, not what)

---

## Test Coverage

**Overall Coverage**: {X%}

| Module | Coverage | Status |
|--------|----------|--------|
| `lib/transactions.ts` | 95% | ✅ Pass |
| `api/v1/transactions` | 82% | ✅ Pass |
| `lib/notifications.ts` | 75% | ⚠️ Below 80% |

**Missing Coverage**:
- {File/function 1}: {Why not covered}
- {File/function 2}: {Recommendation}

---

## Performance Concerns

### Issue 1: {N+1 Query Problem}
**File**: `{path}:{line}`
**Problem**: {Description}
**Impact**: {Performance degradation}
**Fix**: {Use join or eager loading}

---

## Breaking Changes

⚠️ **API Breaking Change Detected**

**Endpoint**: `POST /api/v1/users`
**Change**: Response schema adds `notificationPreferences` field
**Impact**: External clients with strict schema validation may break
**Recommendation**: 
- Version bump to `/api/v2/users`
- Maintain v1 for 2 weeks (deprecation period)
- Announce to API consumers

---

## Recommendations

### Must Do (Before Merge)
1. {Critical issue 1}
2. {Critical issue 2}

### Should Do (Current PR)
1. {High priority issue 1}
2. {High priority issue 2}

### Nice to Do (Future PR)
1. {Medium priority issue}
2. {Refactoring opportunity}

---

## Approval Status

**Reviewer Decision**: {Choose one}
- 🔴 **Request Changes**: Critical issues must be fixed
- 🟡 **Approve with Comments**: Minor issues, can merge after fixes
- 🟢 **Approve**: No blocking issues, ready to merge

**Next Steps**:
1. {Action item 1}
2. {Action item 2}
3. After fixes, run review again or proceed to archive

---

## Related Artifacts
- Spec: `03-spec.md`
- Plan: `04-plan.md`
- Test Plan: `05-test-plan.md` (if exists)
- Git branch: `feature/{branch-name}`
```

---

## Review Checklist Template

Use this checklist during review:

```markdown
## Code Review Checklist

### Security ✅
- [ ] No secrets/credentials in code
- [ ] SQL injection prevented
- [ ] XSS prevented (input sanitization)
- [ ] Authorization checks present
- [ ] Dependencies secure (npm audit / pip-audit)

### Financial Precision ✅
- [ ] Money uses decimal (NOT float/double)
- [ ] Currency stored explicitly
- [ ] Idempotency for transactions
- [ ] Audit logging present
- [ ] Timezone handling correct (UTC storage)

### Code Quality ✅
- [ ] DDD: Domain logic in domain layer
- [ ] SOLID principles followed
- [ ] Clear naming conventions
- [ ] No code duplication (DRY)
- [ ] Error handling complete

### Testing ✅
- [ ] Test coverage ≥80%
- [ ] Edge cases tested
- [ ] Integration tests for critical paths
- [ ] Tests verify behavior (not implementation)

### Performance ✅
- [ ] No N+1 query problems
- [ ] Database indexes appropriate
- [ ] Caching where beneficial
- [ ] No memory leaks

### Breaking Changes ✅
- [ ] API changes documented
- [ ] Migration guide provided (if needed)
- [ ] Deprecation warnings added
- [ ] Versioning strategy followed
```

## Common Issues & Fixes

### Issue: Float/Double for Money
```csharp
// ❌ BAD
double totalPrice = orderItems.Sum(x => x.Price * x.Quantity);

// ✅ GOOD
decimal totalPrice = orderItems.Sum(x => x.Price * x.Quantity);
```

### Issue: Missing Idempotency
```csharp
// ❌ BAD
[HttpPost("transactions")]
public async Task<IActionResult> CreateTransaction([FromBody] TransactionDto dto)
{
    var transaction = await _service.CreateAsync(dto);
    return Ok(transaction);
}

// ✅ GOOD
[HttpPost("transactions")]
public async Task<IActionResult> CreateTransaction(
    [FromBody] TransactionDto dto,
    [FromHeader(Name = "Idempotency-Key")] string idempotencyKey)
{
    if (string.IsNullOrEmpty(idempotencyKey))
        return BadRequest("Idempotency-Key required");
    
    var transaction = await _service.CreateOrGetAsync(dto, idempotencyKey);
    return Ok(transaction);
}
```

### Issue: Anemic Domain Model
```csharp
// ❌ BAD (Anemic)
public class Order
{
    public decimal Total { get; set; }
    public OrderStatus Status { get; set; }
}

// Service does all the logic
public class OrderService
{
    public void CompleteOrder(Order order)
    {
        order.Status = OrderStatus.Completed;
        order.Total = CalculateTotal(order);
    }
}

// ✅ GOOD (Rich domain model)
public class Order
{
    public decimal Total { get; private set; }
    public OrderStatus Status { get; private set; }
    
    public void Complete()
    {
        if (Status == OrderStatus.Cancelled)
            throw new InvalidOperationException("Cannot complete cancelled order");
        
        Status = OrderStatus.Completed;
        Total = CalculateTotalInternal();
    }
    
    private decimal CalculateTotalInternal() { /* domain logic */ }
}
```

## Next Step

After review completion:

**If issues found**:
```
Fix critical issues → Re-run tests → Request re-review
```

**If approved**:

**CLI**:
```
Input: "archive 這個 change package"
[System loads work-archiving skill]
→ Generate 99-archive.md and WORK_LOG entry
```

**VS Code**:
```
Input: /archive
Or: "finalize and archive"
```

Or use workflow orchestrator:
```
Input: "what's next?"
[System detects review complete, recommends archive stage]
```

## Troubleshooting

### "Too many issues found, overwhelming"
**Solution**: Fix critical (🔴) first, then high (🟡). Medium (🟢) can be separate PR.

### "How strict should I be?"
**Solution**: 
- Critical & High: Block merge
- Medium: Accept with follow-up issue
- Low: Optional, nice to have

### "Should I review everything?"
**Solution**: Focus on:
- Business logic changes (high risk)
- Security-critical code
- Financial calculations
- Skip: Auto-generated code, minor formatting

## Related Documentation

- [Implementation Planning Skill](../implementation-planning/SKILL.md) - Previous stage
- [Work Archiving Skill](../work-archiving/SKILL.md) - Next stage
- [Security Review Playbook](../../instructions/playbooks/security-reviewer.md)
- [DDD Good Practices](../../instructions/dotnet-architecture-good-practices.instructions.md)

---

💡 **Tip**: A good review finds issues before they reach production. Be thorough but pragmatic—perfection is the enemy of shipping.

## Common Rationalizations

在程式碼審查過程中，AI 可能以下列藉口略過關鍵步驟：

| 常見藉口 | 反制說明 |
|---------|---------|
| "我已從作者角度完整審查" | ⛔ 不能只從程式碼作者視角審查——必須依序切換至少 3 個 Specialist Lens（Security、Performance、Future Maintainer）再完成審查 |
| "測試覆蓋率 80%，這個模組邏輯簡單不需要 100%" | Financial / Auth / Security 核心路徑要求 100% 覆蓋——沒有例外，「簡單」不是降低標準的理由 |
| "這只是小改動，不需要完整安全稽核" | 改動大小與安全風險無關——任何接觸認證、授權、金融精度的程式碼均需完整安全步驟 |
| "PR 已通過所有自動測試，審查可以快速完成" | 自動測試無法捕捉所有安全弱點——必須手動執行 Specialist Lens Review，不得以 CI green 替代人工審查 |

## Verification

在產出 `05-review.md` 前，逐項確認（Gate = 交付前閘門；Verification = 自我完成確認）：

- [ ] 已依序切換 Security、Performance、Future Maintainer 三個 Specialist Lens，各視角均有記錄輸出
- [ ] 所有 🔴 Critical 問題已列出且有具體修復方案（不得只說「有問題」）
- [ ] Financial Precision 檢查完成：所有金錢欄位確認無 float/double（`rg "float\|double" <changed-files>` 無命中）
- [ ] 測試覆蓋率已量測，核心路徑 100%、整體 ≥80%（或明確說明例外理由）
- [ ] Security Checklist 所有項目已逐條確認（無靜默略過）
- [ ] `05-review.md` 已建立，Approval Status 已填寫（🔴 / 🟡 / 🟢 其中之一）
- [ ] 若 Approval Status 為 🔴，已明確列出 Must Fix 項目清單
