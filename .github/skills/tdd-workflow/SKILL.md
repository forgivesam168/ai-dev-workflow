---
name: tdd-workflow
description: Test-Driven Development workflow enforcement skill. Use when explicitly asked for TDD methodology, test-first development, red-green-refactor cycle, or TDD implementation. Triggers on keywords like "start TDD", "test-driven development", "write tests first", or in Chinese "開始 TDD", "測試先行", "TDD 實作". Provides comprehensive TDD patterns, coverage requirements, and Red-Green-Refactor workflow guidance.
---

# Test-Driven Development Workflow

> 💡 **Recommended Agent**: `coder-agent` (TDD Implementation Specialist)
> - **CLI**: Input `/agent` then select `coder-agent`
> - **VS Code**: Use `@workspace #coder-agent` in Chat
>
> **Note**: CLI users use natural language, VS Code users can use `/tdd` shortcut.

This skill ensures all code development follows TDD principles with comprehensive test coverage.

## When to Use This Skill

Use this skill when:
- Implementation plan is ready and TDD development starts
- Writing new features following Red-Green-Refactor cycle
- Fixing bugs (write failing test first to reproduce)
- Refactoring existing code with test safety net

## Prerequisites

**Required**:
- Implementation plan (`04-plan.md`) with tasks and test strategies
  - Verify `**Plan Status**: ✅ Approved` before starting. If `⏳ Awaiting Approval`, stop and ask the user to review and approve the plan first.

**Recommended**:
- Development environment setup
- Test framework configured
- Code coverage tools enabled
- `05-test-plan.md` (when present, read for overall testing strategy before starting Phase 1)

## Phase Execution Protocol

> **Engineering contract**: execute exactly the Phase assigned — no more, no less. Like a professional engineer following a work order.

### Before Starting a Phase
1. Read `04-plan.md` fully: understand Phase scope, task list, dependency order, and Exit Criteria
2. Read `03-spec.md`: align on Acceptance Criteria for tasks in this Phase
3. Confirm which Phase to execute (as instructed by user)
4. Follow the documented dependency order — do **NOT** reorder or skip tasks

### During Execution
1. Execute tasks in the order documented in `04-plan.md`
2. Strict scope: implement ONLY what belongs to the current Phase
3. One task at a time: complete RED→GREEN→REFACTOR before moving to the next task
4. Scope discipline: if you spot work that belongs to a future Phase, note it in your report — do not implement it

### Phase Completion Gate
Before stopping, verify ALL of the following:
- [ ] All Phase tasks completed
- [ ] All L1 tests GREEN (zero failures, zero unintentional skips)
- [ ] L2 tests: GREEN or explicitly flagged `PENDING_REAL_CREDS` (credentials needed, environment is fine)
- [ ] L3 tests: GREEN only after human confirms staging environment is ready — cannot be `PENDING_REAL_CREDS`
- [ ] Coverage ≥80%
- [ ] Drift check: no code from next Phase scope introduced
- [ ] Phase Exit Criteria in plan: ALL satisfied
- [ ] Build passes clean

> After gate passes: run agentic-eval self-review → report progress → **stop**. Do NOT auto-advance to the next Phase.

## Environment Standards

The coder-agent delegates environment configuration here. Always apply these before starting TDD:

| Language / Stack | Runtime | Tool |
|-----------------|---------|------|
| **PowerShell** | PowerShell 7.5+ (`$PSVersionTable.PSVersion`) | `pwsh`, not `powershell` |
| **Python** | Isolated venv via `uv` or standard `venv` | `uv venv && uv pip install ...` preferred; fallback `python -m venv .venv` |
| **.NET / C#** | .NET SDK (`dotnet --version`) | `dotnet test`, `dotnet build` |
| **Node / TypeScript** | Node 20+ | `npm ci` for reproducible installs |

**File size constraint**: Keep implementation files **200–400 lines**. If a file exceeds 400 lines, extract into modules before the next task. Oversized files are a refactoring signal, not a style preference.

## Core Principles

### 1. Tests BEFORE Code
ALWAYS write tests first, then implement code to make tests pass.

### 2. Coverage Requirements
- Minimum 80% coverage (unit + integration + E2E)
- All edge cases covered
- Error scenarios tested
- Boundary conditions verified

### 3. Test Tier Classification

Tests are categorized into three tiers based on infrastructure requirements. The tier determines whether human confirmation is required before Phase completion.

| Tier | Type | Execution Context | Phase Completion Gate |
|------|------|------------------|-----------------------|
| **L1** | Unit Tests (fully mocked) | Runs anywhere — local, CI/CD, no credentials needed | **Must ALL be GREEN** — hard stop if any fail |
| **L2** | Integration Tests (real infrastructure) | Requires: DB connection strings, API keys, real service endpoints | GREEN if credentials available; flag `PENDING_REAL_CREDS` if not |
| **L3** | E2E / Full Stack Tests | Requires full deployment environment | **Human must confirm** environment ready and tests pass |

#### L1 — Unit Tests
- All external dependencies mocked (in-memory DB, WireMock, service stubs)
- No network calls, no file system access in production paths
- Deterministic — same result every run
- ✅ Must ALL pass before Phase completion

#### L2 — Infrastructure Integration Tests
- Connects to real database, external API, message queue, SMTP server, etc.
- Requires environment variables or config not available in CI by default
- **False Green Risk**: L1 mocks pass but real connection fails — this tier catches that gap
- Code Agent responsibilities:
  - Mark these tests clearly (see marking conventions below)
  - Skip them if credentials are unavailable; flag as `PENDING_REAL_CREDS`
  - Report exactly which credentials are needed and where to set them
  - Phase status remains `DONE_WITH_CONCERNS` until human confirms L2 tests pass

#### L3 — E2E / Full Environment Tests
- Full system running (web server, database, external services all live)
- Cannot be automated-verified without human involvement
- Phase is **NOT considered DONE** until human confirms: tests passed in real environment

#### Test Marking Conventions

Choose the approach that fits your language and framework — either or both are acceptable:

**Option A — Attribute/Marker** (recommended for .NET, Python)
```csharp
[Test, Category("Integration")]  // C#
public void TestDatabaseConnection() { }
```
```python
@pytest.mark.integration         # Python
def test_database_connection(): ...
```

**Option B — File naming convention**
```
UserServiceTests.cs                // L1
UserServiceIntegrationTests.cs     // L2 — requires real DB
user.unit.test.ts                  // L1
user.integration.test.ts           // L2 — requires real API
```

> What matters: L2/L3 tests must be **identifiable** so they can be selectively skipped when credentials are unavailable, and clearly communicated to the human.

## TDD Workflow Steps

### Step 1: Write User Journeys
```
As a [role], I want to [action], so that [benefit]

Example:
As a user, I want to search for markets semantically,
so that I can find relevant markets even without exact keywords.
```

### Step 2: Generate Test Cases
For each user journey, create comprehensive test cases:

```typescript
describe('Semantic Search', () => {
  it('returns relevant markets for query', async () => {
    // Test implementation
  })

  it('handles empty query gracefully', async () => {
    // Test edge case
  })

  it('falls back to substring search when Redis unavailable', async () => {
    // Test fallback behavior
  })

  it('sorts results by similarity score', async () => {
    // Test sorting logic
  })
})
```

### Step 3: Run Tests (They Should Fail)
```bash
npm test
# Tests should fail - we haven't implemented yet
```

### Step 4: Implement Code
Write minimal code to make tests pass:

```typescript
// Implementation guided by tests
export async function searchMarkets(query: string) {
  // Implementation here
}
```

### Step 5: Run Tests Again
```bash
npm test
# Tests should now pass
```

### Step 6: Refactor
Improve code quality while keeping tests green:
- Remove duplication
- Improve naming
- Optimize performance
- Enhance readability

### Step 7: Verify Coverage
```bash
npm run test:coverage
# Verify 80%+ coverage achieved
```

## Testing Patterns

### Unit Test Pattern (Jest/Vitest)
```typescript
import { render, screen, fireEvent } from '@testing-library/react'
import { Button } from './Button'

describe('Button Component', () => {
  it('renders with correct text', () => {
    render(<Button>Click me</Button>)
    expect(screen.getByText('Click me')).toBeInTheDocument()
  })

  it('calls onClick when clicked', () => {
    const handleClick = jest.fn()
    render(<Button onClick={handleClick}>Click</Button>)

    fireEvent.click(screen.getByRole('button'))

    expect(handleClick).toHaveBeenCalledTimes(1)
  })

  it('is disabled when disabled prop is true', () => {
    render(<Button disabled>Click</Button>)
    expect(screen.getByRole('button')).toBeDisabled()
  })
})
```

### API Integration Test Pattern
```typescript
import { NextRequest } from 'next/server'
import { GET } from './route'

describe('GET /api/markets', () => {
  it('returns markets successfully', async () => {
    const request = new NextRequest('http://localhost/api/markets')
    const response = await GET(request)
    const data = await response.json()

    expect(response.status).toBe(200)
    expect(data.success).toBe(true)
    expect(Array.isArray(data.data)).toBe(true)
  })

  it('validates query parameters', async () => {
    const request = new NextRequest('http://localhost/api/markets?limit=invalid')
    const response = await GET(request)

    expect(response.status).toBe(400)
  })

  it('handles database errors gracefully', async () => {
    // Mock database failure
    const request = new NextRequest('http://localhost/api/markets')
    // Test error handling
  })
})
```

### E2E Test Pattern (Playwright)
```typescript
import { test, expect } from '@playwright/test'

test('user can search and filter markets', async ({ page }) => {
  // Navigate to markets page
  await page.goto('/')
  await page.click('a[href="/markets"]')

  // Verify page loaded
  await expect(page.locator('h1')).toContainText('Markets')

  // Search for markets
  await page.fill('input[placeholder="Search markets"]', 'election')

  // Wait for debounce and results
  await page.waitForTimeout(600)

  // Verify search results displayed
  const results = page.locator('[data-testid="market-card"]')
  await expect(results).toHaveCount(5, { timeout: 5000 })

  // Verify results contain search term
  const firstResult = results.first()
  await expect(firstResult).toContainText('election', { ignoreCase: true })

  // Filter by status
  await page.click('button:has-text("Active")')

  // Verify filtered results
  await expect(results).toHaveCount(3)
})

test('user can create a new market', async ({ page }) => {
  // Login first
  await page.goto('/creator-dashboard')

  // Fill market creation form
  await page.fill('input[name="name"]', 'Test Market')
  await page.fill('textarea[name="description"]', 'Test description')
  await page.fill('input[name="endDate"]', '2025-12-31')

  // Submit form
  await page.click('button[type="submit"]')

  // Verify success message
  await expect(page.locator('text=Market created successfully')).toBeVisible()

  // Verify redirect to market page
  await expect(page).toHaveURL(/\/markets\/test-market/)
})
```

## Test File Organization

```
src/
├── components/
│   ├── Button/
│   │   ├── Button.tsx
│   │   ├── Button.test.tsx          # Unit tests
│   │   └── Button.stories.tsx       # Storybook
│   └── MarketCard/
│       ├── MarketCard.tsx
│       └── MarketCard.test.tsx
├── app/
│   └── api/
│       └── markets/
│           ├── route.ts
│           └── route.test.ts         # Integration tests
└── e2e/
    ├── markets.spec.ts               # E2E tests
    ├── trading.spec.ts
    └── auth.spec.ts
```

## Mocking External Services

### Supabase Mock
```typescript
jest.mock('@/lib/supabase', () => ({
  supabase: {
    from: jest.fn(() => ({
      select: jest.fn(() => ({
        eq: jest.fn(() => Promise.resolve({
          data: [{ id: 1, name: 'Test Market' }],
          error: null
        }))
      }))
    }))
  }
}))
```

### Redis Mock
```typescript
jest.mock('@/lib/redis', () => ({
  searchMarketsByVector: jest.fn(() => Promise.resolve([
    { slug: 'test-market', similarity_score: 0.95 }
  ])),
  checkRedisHealth: jest.fn(() => Promise.resolve({ connected: true }))
}))
```

### OpenAI Mock
```typescript
jest.mock('@/lib/openai', () => ({
  generateEmbedding: jest.fn(() => Promise.resolve(
    new Array(1536).fill(0.1) // Mock 1536-dim embedding
  ))
}))
```

## Infrastructure-Gated Test Protocol

When L2/L3 tests cannot be run due to missing credentials, follow this protocol — do NOT let them silently fail or silently pass with mocks.

### Step 1: Identify and Skip Explicitly
Mark tests with the chosen convention (attribute or file naming). Skip them explicitly — never let infrastructure tests run against mocks and report false greens.

### Step 2: Report to Human

Include this block in your Progress Report:

```
⚠️ Infrastructure-Gated Tests (PENDING_REAL_CREDS)

The following tests require real credentials and are currently skipped:

| Test | Required Credential | Where to Set |
|------|--------------------|-----------  |
| TestDatabaseConnection | `DB_CONNECTION_STRING` | `.env` or `appsettings.Development.json` |
| TestSendEmailIntegration | `SMTP_PASSWORD` | `.env` or user secrets |
| TestExternalApiCall | `EXTERNAL_API_KEY` | `.env` |

Action Required: Fill in the above credentials and run:
  # .NET
  dotnet test --filter "Category=Integration"
  # Python
  pytest -m "integration"
  # Node
  npm test -- --testPathPattern="integration"

Confirm all pass before this Phase is considered DONE.
```

### Step 3: Set Correct Phase Status
- L1 all GREEN + L2 `PENDING_REAL_CREDS`: → **`DONE_WITH_CONCERNS`**
- Elevate to `DONE` only after human confirms L2/L3 tests pass in real environment

## Test Coverage Verification

### Run Coverage Report
```bash
npm run test:coverage
```

### Coverage Thresholds
```json
{
  "jest": {
    "coverageThresholds": {
      "global": {
        "branches": 80,
        "functions": 80,
        "lines": 80,
        "statements": 80
      }
    }
  }
}
```

## Common Testing Mistakes to Avoid

### ❌ WRONG: Testing Implementation Details
```typescript
// Don't test internal state
expect(component.state.count).toBe(5)
```

### ✅ CORRECT: Test User-Visible Behavior
```typescript
// Test what users see
expect(screen.getByText('Count: 5')).toBeInTheDocument()
```

### ❌ WRONG: Brittle Selectors
```typescript
// Breaks easily
await page.click('.css-class-xyz')
```

### ✅ CORRECT: Semantic Selectors
```typescript
// Resilient to changes
await page.click('button:has-text("Submit")')
await page.click('[data-testid="submit-button"]')
```

### ❌ WRONG: No Test Isolation
```typescript
// Tests depend on each other
test('creates user', () => { /* ... */ })
test('updates same user', () => { /* depends on previous test */ })
```

### ✅ CORRECT: Independent Tests
```typescript
// Each test sets up its own data
test('creates user', () => {
  const user = createTestUser()
  // Test logic
})

test('updates user', () => {
  const user = createTestUser()
  // Update logic
})
```

## Continuous Testing

### Watch Mode During Development
```bash
npm test -- --watch
# Tests run automatically on file changes
```

### Pre-Commit Hook
```bash
# Runs before every commit
npm test && npm run lint
```

### CI/CD Integration
```yaml
# GitHub Actions
- name: Run Tests
  run: npm test -- --coverage
- name: Upload Coverage
  uses: codecov/codecov-action@v3
```

## Best Practices

1. **Write Tests First** - Always TDD
2. **One Assert Per Test** - Focus on single behavior
3. **Descriptive Test Names** - Explain what's tested
4. **Arrange-Act-Assert** - Clear test structure
5. **Mock External Dependencies** - Isolate unit tests
6. **Test Edge Cases** - Null, undefined, empty, large
7. **Test Error Paths** - Not just happy paths
8. **Keep Tests Fast** - Unit tests < 50ms each
9. **Clean Up After Tests** - No side effects
10. **Review Coverage Reports** - Identify gaps

## Success Metrics

- 80%+ code coverage achieved
- All tests passing (green)
- No skipped or disabled tests
- Fast test execution (< 30s for unit tests)
- E2E tests cover critical user flows
- Tests catch bugs before production

---

## Pre-Review Self-Eval Gate

Run this **before handing off to `code-reviewer`**. All 🔴 items must PASS.

| Check | How to Verify | Threshold |
|-------|--------------|-----------|
| 🔴 **Build passes** | `dotnet build` / `npm run build` / `python -m pytest --collect-only` exits 0 | **HARD STOP** if fail |
| 🔴 **All tests green** | `dotnet test` / `npm test` / `pytest` — zero failures, zero skipped | **HARD STOP** if fail |
| 🔴 **Coverage ≥80%** | Coverage report (lcov/Coverlet) shows ≥80% line coverage | Block if below |
| 🟡 **No float for money** | Search `grep -rn "float\|double" --include="*.cs"` on financial domain files | Fix before review |
| 🟡 **No secrets committed** | `git diff --cached` — no API keys, tokens, passwords | Fix before review |
| 🟡 **File sizes ≤400 lines** | `wc -l` or `(Get-Content file).Count` on edited files | Refactor if exceeded |

**If any 🔴 check fails**: stop, fix, re-run. Do NOT send to code-reviewer with a red build.

**After all PASS**: Run agentic-eval self-review, then report using the Progress Report Format below.

**agentic-eval Self-Review** (run `/agentic-eval` with `#code` rubric from `stage-rubrics.md`):
- 🔴 Financial Precision FAIL → **mandatory stop** — fix before any other action
- 🔴 Security FAIL → fix before proceeding
- 🟡 Other dimension FAILs: iterate up to 2 times; if unresolved → `DONE_WITH_CONCERNS`

After agentic-eval: update documents and memory (see Document & Memory Update Protocol below), then **stop and wait for human approval** before next Phase.

---

## Progress Report Format

Use this standard format when completing or blocking on a Phase:

```markdown
## Phase {N} — {Phase Name}: Completion Report

### ✅ Completed Tasks
- {Task ID}: {what was implemented}
- {Task ID}: {what was implemented}

### ⚠️ Blockers / Concerns
- {Description and impact — omit section if none}

### 🧪 Infrastructure-Gated Tests (if any)
- {Test name}: requires `{CREDENTIAL_NAME}` — PENDING_REAL_CREDS

### 📊 Quality Status
| Check | Result |
|-------|--------|
| Build | PASS / FAIL |
| L1 Tests | {n} passing, {n} failing |
| L2 Tests | PASS / PENDING_REAL_CREDS |
| Coverage | {n}% |
| Exit Criteria | MET / NOT MET |
| agentic-eval | PASS / PASS_WITH_CONCERNS / FAIL |

### 🏷️ Status
`DONE` | `DONE_WITH_CONCERNS` | `NEEDS_CONTEXT` | `BLOCKED`

### 🔜 Suggested Next Step
→ Phase {N+1}: {Phase Name} — pending human approval
```

---

## Document & Memory Update Protocol

After Phase completion, update these artifacts before stopping:

### 04-plan.md
- Mark completed tasks with ✅
- If implementation deviated from plan, add a note under the task: `📝 Implementation note: {reason for deviation}`
- Update Phase-level status (e.g., `Phase 0: ✅ Completed`)

### Memory Update (if `.ai-workflow-memory/` exists)
Update `CURRENT_STATE.md` with:

```markdown
## Current Development State
- **Active Phase**: Phase {N} — {completed / in_progress}
- **Next Phase**: Phase {N+1} — {name}
- **Pending Actions**: {e.g., "User needs to fill L2 credentials and confirm"}
- **Last Session**: {brief summary of what was implemented}
- **Coverage**: {n}%
- **Branch**: {branch name}
```

> This enables cross-session continuity: when returning to this project (or switching back from another project), reading `CURRENT_STATE.md` immediately restores context without re-reading all history.

---

**Remember**: Tests are not optional. They are the safety net that enables confident refactoring, rapid development, and production reliability.
