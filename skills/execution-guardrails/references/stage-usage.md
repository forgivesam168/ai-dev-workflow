# Execution Guardrails by Workflow Stage

Use this reference when you want to apply the same guardrails differently depending on the stage.

| Stage | Primary question | What good looks like | Common failure mode |
|-------|------------------|----------------------|---------------------|
| Brainstorm | Are we separating facts from assumptions? | Open questions are explicit; 2–3 real options are compared before recommendation | Agent silently picks one interpretation and runs with it |
| Spec | Are requirements distinct from assumptions and non-goals? | ACs are testable; assumptions are labeled; unresolved questions are visible | Assumptions are written as if they were confirmed requirements |
| Plan | Does each step map to current scope and have verification? | Steps are concrete, ordered, and testable; speculative scope is excluded | Plan includes future-proofing or architecture work not required by the spec |
| TDD / Code | Is this the smallest diff that satisfies the target test? | Minimal implementation, no unrelated edits, no speculative abstractions | Bug fix expands into broad refactor or framework-like abstraction |
| Review | Did the review inspect hidden assumptions and diff drift? | Review flags overengineering, unrelated edits, and unverifiable claims | Review only comments on style or security and misses scope drift |

## Quick Checks

### Brainstorm
- Which statements are confirmed facts?
- Which statements are assumptions?
- What remains unknown?

### Spec
- Which ACs are verifiable?
- Which business rules are assumed but not confirmed?
- What is explicitly out of scope?

### Plan
- Which steps are directly tied to an AC or requirement?
- Which steps have explicit verification?
- Which steps would disappear if a hidden assumption proved false?

### Code
- Which diff hunks are strictly required to satisfy the request?
- Did the change add configurability or abstraction without a present need?
- Did the change clean up only what it created?

### Review
- Did the review call out hidden assumptions?
- Did it inspect unrelated edits or drive-by refactors?
- Did each finding include an actionable correction?
