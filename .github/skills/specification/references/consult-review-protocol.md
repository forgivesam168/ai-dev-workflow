# Consult Review Protocol: dba-agent & frontend-designer-agent

**Trigger**: Load this reference when the spec involves database schema design, complex queries, or frontend UI/component design that warrants specialist review before handoff to plan-agent.

---

## When to Invoke a Consultant Agent

| Condition | Invoke |
|-----------|--------|
| Spec defines new entities, schema changes, or non-trivial query patterns | `dba-agent` |
| Spec defines UI components, design system integration, or accessibility requirements | `frontend-designer-agent` |
| Spec involves both DB + UI work of medium/high complexity | Both |
| Simple CRUD with no schema changes, standard UI patterns | Skip (note in spec) |

> **Rule**: If in doubt, invoke — a 10-minute consult prevents hours of rework in the plan and code stages.

---

## Protocol: dba-agent Consult

### When
- New table or column added
- Index strategy uncertain (query involves JOIN, WHERE, ORDER BY on large tables)
- Migration safety concern (adding NOT NULL column to live table, changing column type)
- Soft-delete vs hard-delete pattern decision
- Financial data precision requirements (Decimal precision, minor units)

### How to Invoke (CLI)
```
Input: "請 dba-agent 審查以下 schema 設計：[paste entity definitions from spec]"
Or: /agent → select dba-agent
```

### What to Ask
1. "Is the proposed schema normalized appropriately for this access pattern?"
2. "What indexes are needed for the queries implied by these user stories?"
3. "Are there migration safety concerns with these changes?"
4. "Does the data model correctly handle [financial precision / soft deletes / etc.]?"

### Output to Capture
Record the dba-agent's recommendations in the spec under **Technical Considerations → API/Schema Contracts**:

```markdown
#### Schema Review (dba-agent)
- Reviewed by: dba-agent
- Recommendations:
  - [Add index on `user_id, created_at` for Story 2 query pattern]
  - [Use `DECIMAL(19,4)` not `FLOAT` for `amount` column]
  - [Migration: add column as nullable first, backfill, then add NOT NULL constraint]
- Open Questions resolved: [list]
```

---

## Protocol: frontend-designer-agent Consult

### When
- New UI component with non-trivial interaction state (multi-step forms, drag-and-drop, real-time updates)
- Design system integration: confirm which existing component to reuse vs create new
- Accessibility requirements (WCAG AA compliance needed)
- UX Lens found gaps in the spec that require design decisions
- Mobile/responsive behavior is non-trivial

### How to Invoke (CLI)
```
Input: "請 frontend-designer-agent 審查以下 UI 需求：[paste User Stories + UX AC from spec]"
Or: /agent → select frontend-designer-agent
```

### What to Ask
1. "Which existing design system components map to these user stories?"
2. "What interaction patterns (loading states, error states, empty states) are missing from the spec?"
3. "What are the accessibility requirements for this feature at WCAG AA?"
4. "Is this UX flow consistent with the rest of the product experience?"

### Output to Capture
Record recommendations under **Technical Considerations → UX/Frontend**:

```markdown
#### UI/UX Review (frontend-designer-agent)
- Reviewed by: frontend-designer-agent
- Component mapping:
  - Story 1 form → use `<DataTable>` with `<FilterPanel>` from design system
  - Story 2 modal → new `<ConfirmDialog>` component (no existing equivalent)
- Missing states added as AC:
  - [Loading skeleton while fetching → Observable Outcome: ...]
  - [Empty state with CTA → Observable Outcome: ...]
- Accessibility notes: [all form fields need aria-required; error messages need role="alert"]
```

---

## Recording the Consult

After each consult, add a review block to the spec and update the Assumptions section:

```markdown
## Specialist Consults
| Agent | Date | Scope | Status |
|-------|------|-------|--------|
| dba-agent | YYYY-MM-DD | Schema + migration safety | ✅ Complete |
| frontend-designer-agent | YYYY-MM-DD | Component mapping + accessibility | ✅ Complete |
```

Remove corresponding `[ASSUMED]` items that were resolved by the consult.

---

## Escalation

If a consult reveals a fundamental scope conflict (e.g., proposed schema is incompatible with existing database), **STOP** and surface the conflict to the user before continuing the spec. Do not paper over conflicts with assumptions.
