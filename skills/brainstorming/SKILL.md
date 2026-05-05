---
name: brainstorming
description: 'Start a work item: triage risk, run structured brainstorming to clarify requirements, compare solution options, and produce a decision log + change package skeleton.'
license: MIT
---

# Brainstorming

> 💡 **Recommended Agent**: `brainstorm-agent` (Requirements Explorer)
> - **CLI**: Input `/agent` and select `brainstorm-agent`
> - **VS Code**: Use `@workspace #brainstorm-agent` in Chat

## When to Use
Use this skill at the **start of any request/change** when:
- Requirements are ambiguous or incomplete
- The change touches security, auth/authz, data flow, CI/CD, or supply chain
- There are multiple plausible implementation approaches
- You need a rationale trail (auditability)

## Workflow

### Phase 0 — Intake & Risk Classification
- Clarify goals/non-goals and acceptance criteria
- Classify risk: **Low** / **Med** / **High**
- Determine if this is brownfield (existing system)
- Decide workflow path:
  - **Standard**: brainstorm → plan → tdd → review
  - **Fast** (low-risk only): plan → tdd → review

### Phase 1 — Clarify
- In each new brainstorming round, ask at least 5 targeted questions before options/recommendation unless the user explicitly says assumptions are acceptable
- If the user cannot answer immediately, list assumptions separately and label what remains unknown

### Phase 2 — Explore Options
- Produce 2–3 options
- For each: complexity (L/M/H), risks, dependencies, rollback strategy

### Phase 3 — Decide & Record
- Recommend one option and justify
- Produce a **Decision Log** entry (append-only)

### Phase 4 — Change Package Skeleton
- Use shell to create `changes/<YYYY-MM-DD>-<slug>/` directory first
- Then write stub files (do NOT use `edit` on non-existent files):
  - `01-brainstorm.md`
  - `02-decision-log.md`
  - `03-spec.md` (draft)
- If shell is unavailable, output file contents in response for manual creation

## Must-Ask Questions

Apply to **every project** regardless of domain:

In a normal kickoff, cover at least five of these categories before recommending a path or solution. If the user explicitly allows assumptions, say that you are switching to assumption-driven brainstorming.

| Category | Question | Purpose |
|----------|----------|---------|
| **Problem** | What problem are we solving? How is it handled today? | Avoid solving the wrong problem |
| **Users** | Who will use this? What are the different roles? | Define personas |
| **Non-goals** | What are we explicitly NOT doing in this iteration? | Prevent scope creep |
| **Failure scenario** | If this feature breaks, what's the worst case? | Risk awareness |
| **Existing system** | What existing components will this touch or depend on? | Greenfield vs brownfield |
| **Acceptance** | How will we know it's done? How will we verify it works? | Seed acceptance criteria |
| **Rollback** | If we ship this and it causes problems, can we revert? | Safety net |

## Conditional Follow-up Questions

Trigger these based on the user's answers:

| Trigger | Follow-up Questions |
|---------|---------------------|
| Involves money / pricing | Precision rules? Which currencies? Rounding strategy? Idempotency? |
| Involves personal data | Privacy requirements? Who can access? Retention policy? |
| Involves permissions / roles | Who can read, write, approve? Audit trail needed? |
| Brownfield system | Which modules are affected? Dependent systems? Migration needed? |
| Multi-system integration | API contracts? Failure/retry behavior? Eventual consistency acceptable? |
| Scheduled / batch processing | What if it runs twice? Timeout handling? Partial failure recovery? |
| Reporting / audit | Who reads the reports? How far back must data be queryable? |
| Workflow / approvals | What are the state transitions? Who can approve or reject? |

## Risk Classification

| Level | Criteria | Recommended Path |
|-------|----------|--------------------|
| **Low** | Single file or isolated component, no existing users, no data flow changes, easily reverted | Fast Path: Plan → TDD → Review |
| **Med** | Multiple files, touches existing features, some external dependencies | Standard Path: Spec → Plan → TDD → Review → Archive |
| **High** | Cross-module, security/permissions, data migration, regulatory, or production-critical | Standard Path (mandatory): all 6 stages, CODEOWNERS review |

## Output Template

- Risk Classification (Low/Med/High)
- Workflow Path Recommendation (Standard/Fast)
- Questions Asked (at least 5 unless the user explicitly allowed assumptions)
- Assumptions & Constraints
- Options (2–3)
- Recommendation
- Decision Log
- Change Package Skeleton (file stubs)

### Brainstorm Summary Format

Use this structure in `01-brainstorm.md`:

```markdown
## Brainstorm Summary

**Problem**: [one sentence]
**Risk Level**: Low / Med / High
**Workflow Path**: Fast / Standard
**Chosen Approach**: [option name and one-line reason]
**Discovery Questions Covered**: [at least five categories, or note that the user explicitly allowed assumptions]
**Open Questions**: [anything still unresolved]
**Assumptions**: [what we're assuming to be true]
**Non-goals**: [explicitly out of scope]
```

## Output Mapping (Change Package)
Write results into:
- `changes/<YYYY-MM-DD>-<slug>/01-brainstorm.md`
- `changes/<YYYY-MM-DD>-<slug>/02-decision-log.md`
- Draft/Update `changes/<...>/03-spec.md` (minimum scope + verification)

**Directory creation**: Always create the target directory with shell (`mkdir -p` / `New-Item -ItemType Directory -Force`) before writing files. The `edit` tool CANNOT create new files — use shell or `create` tool instead.
If shell is unavailable, output file contents in response for manual creation.
