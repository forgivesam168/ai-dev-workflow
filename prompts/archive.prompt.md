---
description: '[Admin] Archive completed work: generate work log entry and finalize change package.'
---

# Archive Command

Use `/archive` after PR is merged to finalize the change package and generate documentation.

## Process

### Step 1: Generate Work Log Entry

Append to `docs/WORK_LOG.md`:

```markdown
## [YYYY-MM-DD HH:MM] {Task Name}

### 📋 Schema/Contract Changes
- **[None / Yes]**: {If yes, list modified OpenAPI/Schema files and fields}

### 🛠️ Implementation Summary
- **{File path}**: {Change description}

### 🔍 TDD Status
- **Test Coverage**: {Boundary cases tested}
- **Status**: 🟢 Pass / 🔴 Fail

### 🛡️ Compliance Checklist
- [x] Financial precision (Decimal)
- [x] Input validation
- [x] Security review passed
```

### Step 2: Finalize Change Package

Create `changes/<...>/99-archive.md`:

```markdown
# Archive: {Feature Name}

## Outcome
- **Status**: ✅ Completed / ⚠️ Partial / ❌ Cancelled
- **PR**: #{PR number} or link
- **Merged**: YYYY-MM-DD

## Summary
{Brief description of what was delivered}

## Artifacts
- Spec: `03-spec.md`
- Plan: `04-plan.md`
- Review: `05-review.md`

## Follow-up Items
- {Any remaining tasks or tech debt}

## Lessons Learned
- {Optional: what went well, what to improve}
```

## Rules
- Do not include secrets or sensitive customer/transaction data
- Keep archive concise but complete for future reference
- Link to relevant PRs and issues
