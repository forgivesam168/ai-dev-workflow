# Specialist Lens Review: Full Checklist & Output Template

**Trigger**: Load this reference when executing the Specialist Lens Review step in `SKILL.md` Step 3 Validation, or when asked for the full 4-perspective checklist.

---

## How to Execute

For each lens:
1. Switch perspective — adopt the role (Security Engineer, Performance Engineer, QA Engineer, UX Designer)
2. Scan the **entire spec** from that single perspective
3. Record output using the format below
4. If a gap is found: either confirm it is explicitly covered, OR add a new AC to the relevant User Story

> Do not combine lenses into a single pass. Sequential switching is required.

---

## 🔒 Security Lens

**Role**: You are a security engineer looking for vulnerabilities in the spec.

**Checklist**:
- [ ] Authentication mechanism explicitly specified (session, JWT, OAuth2, API key)?
- [ ] Authorization model defined (who can access what, per role or resource)?
- [ ] Input validation requirements stated for all user-facing fields?
- [ ] PII / sensitive data handling: encryption at rest and in transit?
- [ ] Secrets (API keys, passwords) never returned in response bodies?
- [ ] Rate limiting or abuse prevention mentioned for public endpoints?
- [ ] SQL injection / XSS / CSRF protections addressed (if applicable)?
- [ ] Audit trail requirements defined (who did what, when)?

**Output Format**:
```
🔒 Security:
  ✅ Covered: [list covered items]
  ⚠️  Gap found → New AC added to Story [N]: "[AC text with Observable Outcome]"
  N/A: [items not applicable, with reason]
```

---

## ⚡ Performance Lens

**Role**: You are a performance engineer evaluating whether the spec will meet production load.

**Checklist**:
- [ ] Latency targets defined (p50 / p99 / max)?
- [ ] Throughput targets stated (requests/sec, concurrent users)?
- [ ] Scalability strategy mentioned (horizontal, vertical, caching)?
- [ ] Database query patterns considered (N+1 risk, pagination)?
- [ ] Payload size limits specified (for file uploads, bulk operations)?
- [ ] Background job / async processing for slow operations defined?
- [ ] Caching strategy mentioned where applicable?
- [ ] Performance budgets defined for UI (LCP, FID, CLS)?

**Output Format**:
```
⚡ Performance:
  ✅ Covered: [list covered items]
  ⚠️  Gap found → New AC added to Story [N]: "[AC text with Observable Outcome]"
  N/A: [items not applicable, with reason]
```

---

## 🧪 QA Lens

**Role**: You are a QA engineer trying to write tests from this spec.

**Checklist**:
- [ ] Every AC has an Observable Outcome (verifiable pass/fail state)?
- [ ] Happy path is fully specified?
- [ ] Error conditions and rejection cases documented per input/endpoint?
- [ ] Edge cases identified (empty input, max values, concurrent access)?
- [ ] State transitions documented (if stateful flow)?
- [ ] Test data requirements mentioned (fixtures, seeds)?
- [ ] Regression scope identifiable from spec (what existing behavior must not break)?
- [ ] Contract between frontend and API explicit (request/response schema)?

**Output Format**:
```
🧪 QA:
  ✅ Covered: [list covered items]
  ⚠️  Gap found → New AC added to Story [N]: "[AC text with Observable Outcome]"
  N/A: [items not applicable, with reason]
```

---

## 🎨 UX Lens

**Role**: You are a UX designer reviewing whether the spec defines a usable, accessible interface.

**Checklist**:
- [ ] Error messages defined (text, placement, trigger conditions)?
- [ ] Loading / pending states specified for async operations?
- [ ] Empty states defined (no data, first-time user)?
- [ ] Success feedback specified (confirmation messages, redirects)?
- [ ] Form validation: inline vs on-submit; field-level vs form-level?
- [ ] Accessibility requirements stated (WCAG level, keyboard nav, screen reader)?
- [ ] Responsive design breakpoints mentioned (if applicable)?
- [ ] Destructive actions have confirmation step?

**Output Format**:
```
🎨 UX:
  ✅ Covered: [list covered items]
  ⚠️  Gap found → New AC added to Story [N]: "[AC text with Observable Outcome]"
  N/A: [items not applicable, with reason]
```

---

## Completion Gate

The Specialist Lens Review is complete when **all 4 lenses have an output block** and every `⚠️ Gap found` has a corresponding new AC added to the spec.

Do NOT proceed to `agentic-eval` until this gate passes.
