---
description: 'Comprehensive Code Review + Security Review (parallel). Check for security vulnerabilities, code quality, and financial compliance.'
---

# Code Review Command

> **💡 Recommended Agent**: This command works best with `code-reviewer` (Quality & Security Auditor). Use `/agent` in CLI or select from agent dropdown in VS Code.
>
> **⚠️ Note for CLI users**: Use `/code-review` to avoid conflict with CLI's built-in `/review` command.

Use this command after implementation to perform Code Review and Security Review in parallel.

## Scope
Reviews uncommitted changes: `git diff --name-only HEAD`

## Review Checklist

### 🔴 Security Issues (CRITICAL - Block Commit)
- Hardcoded credentials, API keys, tokens
- SQL injection vulnerabilities
- XSS vulnerabilities
- Missing input validation
- Insecure dependencies
- Path traversal risks
- Authentication/Authorization gaps
- Sensitive data exposure

### 🟠 Financial Compliance (CRITICAL)
- Float/double used for money (must use decimal/integer minor units)
- Missing idempotency for transactions
- Race conditions in financial operations
- Missing audit trail
- Timezone handling issues

### 🟡 Code Quality (HIGH)
- Functions > 50 lines
- Files > 800 lines
- Nesting depth > 4 levels
- Missing error handling
- console.log / print statements left in code
- TODO/FIXME comments unaddressed
- Missing documentation for public APIs

### 🔵 Best Practices (MEDIUM)
- Mutation patterns (prefer immutable)
- Missing tests for new code
- Accessibility issues (a11y)
- Code duplication

## Output Format

Generate `changes/<...>/05-review.md` with:

```markdown
# Review Report

## Summary
- Total issues: X
- Critical: X | High: X | Medium: X | Low: X
- Recommendation: ✅ Approve / ⚠️ Approve with comments / ❌ Request changes

## Issues

### [CRITICAL] {Issue Title}
- **File**: `path/to/file.ts:42`
- **Issue**: Description
- **Fix**: Suggested resolution

### [HIGH] {Issue Title}
...
```

## Rules
- **NEVER approve code with CRITICAL security vulnerabilities**
- All CRITICAL and HIGH issues must be resolved before merge
- Financial precision issues are always CRITICAL

## Next Step
After review completion and fixes applied:
- If **CRITICAL issues found**: Fix immediately, do not proceed
- If **approved**: Run `/archive` to finalize change package
- Or use `/workflow` for guided progression

⚠️ **BLOCK MERGE** if any CRITICAL security or financial compliance issues remain
