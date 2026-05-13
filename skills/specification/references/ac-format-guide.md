# AC Format Guide: Observable Outcome Examples

**Trigger**: Load this guide when writing or reviewing Acceptance Criteria, or when asked for Observable Outcome samples.

Every AC must have an **Observable Outcome**: a concrete, verifiable description of what an automated test or human check can observe to confirm the criterion passes.

---

## Format

```markdown
- [ ] {Testable criterion} — **Observable Outcome**: {what exact output/state/response confirms this passes}
```

---

## Example Pairs by Domain

### API Domain

#### ❌ Bad — no Observable Outcome
```markdown
- [ ] The endpoint handles invalid input gracefully
```
**Problem**: "gracefully" is not verifiable. What response? What status code?

#### ✅ Good
```markdown
- [ ] The endpoint rejects requests with missing `amount` field
  — **Observable Outcome**: POST /api/v1/transactions with no `amount` returns HTTP 400 with body `{"error": "amount is required"}`
```

---

#### ❌ Bad
```markdown
- [ ] Idempotency is supported for the transaction endpoint
```
**Problem**: No observable test action described.

#### ✅ Good
```markdown
- [ ] Submitting the same request twice with identical `Idempotency-Key` does not create duplicate records
  — **Observable Outcome**: Second POST with same `Idempotency-Key` returns HTTP 200 with the original transaction ID; database count of records with that key remains 1
```

---

### Performance Domain

#### ❌ Bad
```markdown
- [ ] The export feature is fast enough for production use
```
**Problem**: "fast enough" is not measurable.

#### ✅ Good
```markdown
- [ ] Exporting 10,000 transaction records completes within acceptable time
  — **Observable Outcome**: `GET /api/v1/export?rows=10000` p99 latency ≤ 3000ms under 50 concurrent users (verified by k6 load test with `threshold: p99 < 3000`)
```

---

#### ❌ Bad
```markdown
- [ ] The dashboard loads quickly
```

#### ✅ Good
```markdown
- [ ] The dashboard initial render completes within the performance budget
  — **Observable Outcome**: Lighthouse performance score ≥ 85; LCP ≤ 2.5s on a 4G throttled connection (Chrome DevTools audit)
```

---

### UI / UX Domain

#### ❌ Bad
```markdown
- [ ] The error message is clear to the user
```
**Problem**: "clear" is subjective and untestable.

#### ✅ Good
```markdown
- [ ] Users see a descriptive error when login fails due to invalid credentials
  — **Observable Outcome**: Submitting incorrect password renders the text "Email or password is incorrect" below the submit button; no redirect occurs; password field is cleared
```

---

#### ❌ Bad
```markdown
- [ ] Accessibility requirements are met
```

#### ✅ Good
```markdown
- [ ] The form is navigable by keyboard and announced correctly by screen readers
  — **Observable Outcome**: Tab sequence follows visual order; all inputs have associated `<label>` or `aria-label`; axe-core audit returns 0 violations at `wcag2aa` level
```

---

## Summary Checklist

For each AC, verify:
- [ ] Can a test runner assert pass/fail on this Observable Outcome?
- [ ] Is the expected value / state / response explicitly stated (not "appropriate" or "correct")?
- [ ] Does it reference a specific tool, assertion, or check method?
- [ ] Is it domain-appropriate (HTTP status for API, ms threshold for performance, visual element for UI)?

> If any answer is NO, rewrite the Observable Outcome before handoff to plan-agent.
