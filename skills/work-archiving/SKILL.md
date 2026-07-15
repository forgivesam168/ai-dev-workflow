---
name: work-archiving
description: Finalize and document completed change packages at Stage 6. Use when asked to archive changes, finalize work, or close change-package documentation.
license: See LICENSE.txt in repository root
---

# Work Archiving Skill

## When to Use This Skill

Use this skill at **Stage 6 (Archive)** of the workflow when:
- Code review is approved and the change has merge evidence
- Need to finalize and document completed work
- Time to close out the change package documentation
- Asked to archive, finalize, or close out this work
- Completing the 6-stage workflow cycle

## Authorization Boundary

An Archive request authorizes only the requested local archive documentation scope. It does not authorize protected Git or remote actions.

### Archive-authorized local documentation

When the current task requests it, Archive work may:
- Create or update the requested archive document or archive summary.
- Update the requested work log or `CHANGELOG.md` entry.
- Read-only inspect existing commit, PR, and Issue evidence.

### Separately protected actions

Archive must not perform these actions because of the Archive request alone:
- commit
- push
- tag
- merge
- local branch deletion
- remote branch deletion
- remote Issue closure
- remote PR closure
- release or any other remote mutation

Every protected action requires explicit, current-task, action-specific user approval. One approval does not authorize another protected action. Approval for commit does not authorize push. Approval for push does not authorize tag. Approval for merge does not authorize branch deletion. Approval for documentation does not authorize remote closure.

When approval is missing, do not execute the protected action. Report the exact required action-specific approval, complete safe local documentation when requested, then stop or hand off. Do not produce a command list that could be mistaken for an automatically authorized action.

## Prerequisites

Before archiving:
- [ ] Code review status and existing merge evidence are available for read-only inspection
- [ ] Tests are passing, if applicable
- [ ] The requested documentation scope is clear

## Archiving Workflow

### Step 1: Review Change Package Status

Check the change package folder (`changes/<YYYY-MM-DD>-<slug>/`) for completeness:
- `01-brainstorm.md` — Initial requirements and risk assessment
- `02-decision-log.md` — Key decisions made
- `03-spec.md` — Specification (if standard path)
- `04-plan.md` — Implementation plan
- `05-review.md` — Code review results

Record only evidence that already exists. Do not treat the presence of an Archive request as authorization for a protected action.

### Step 2: Create Archive Summary

When the current task requests the archive document, create `changes/<YYYY-MM-DD>-<slug>/99-archive.md`:

```markdown
# Archive: [Feature Name]

**Date Completed**: YYYY-MM-DD
**Status**: Completed / Completed with Known Issues

## Summary
Brief description of what was implemented.

## Key Outcomes
- Outcome 1
- Outcome 2

## Commits
- Existing commit evidence and message

## Related Issues/PRs
- Existing Issue or PR reference

## Known Issues / Technical Debt
- Issue 1 (tracked in the existing evidence)

## Lessons Learned
- What went well
- What could be improved
- Recommendations for future work
```

The current Archive output structure and `99-archive.md` filename remain unchanged in this phase. Historical Archive artifacts remain readable.

### Step 3: Record Requested Local Documentation

Update `docs/WORK_LOG.md` or `CHANGELOG.md` only when the current task explicitly requests that local documentation. If the task does not request one of these files, leave it unchanged and report that no update was requested.

### Step 4: Verify Authorization and Handoff

Before any separately protected action, verify all three requirements for that specific action: explicit approval, current-task authorization, and action-specific authorization. If any requirement is missing, do not execute it; report the exact missing approval and finish safe local documentation or stop with a safe handoff.

## Output Format

### Archive Document (`99-archive.md`)

| Section | Required | Description |
|---------|----------|-------------|
| Summary | Yes | Brief description of completed work |
| Key Outcomes | Yes | Bullet list of deliverables |
| Commits | Yes | Existing commit evidence and hashes, if available |
| Related Issues/PRs | If applicable | Existing references only; no remote closure |
| Known Issues | If applicable | Technical debt or limitations |
| Lessons Learned | Recommended | Retrospective notes |

## Troubleshooting

| Problem | Solution |
|---------|----------|
| Change package incomplete | Review missing local documentation and report the gap |
| Protected action approval missing | Report the exact action-specific approval required, then stop or hand off |
| Review not approved | Return to Stage 5 (Review) to address feedback |
| No `CHANGELOG.md` exists | Create one only when the current task explicitly requests it; otherwise leave it unchanged |

## Integration with Workflow

This skill completes the documentation work for the 6-stage workflow:
1. Brainstorm → 2. Specification → 3. Planning → 4. Implementation → 5. Review → **6. Archive**

After archiving, the change package serves as:
- **Audit trail** for regulatory/compliance needs
- **Knowledge base** for future similar work
- **Onboarding material** for new team members
- **Reference** for technical decisions

Archive documentation does not grant authorization for a later protected action.

## Related Resources

- [WORKFLOW.md](../../WORKFLOW.md) — Complete workflow documentation
- [Specification Skill](../specification/SKILL.md) — Stage 2
- [Implementation Planning Skill](../implementation-planning/SKILL.md) — Stage 3
- [TDD Workflow Skill](../tdd-workflow/SKILL.md) — Stage 4
- [Code & Security Review Skill](../code-security-review/SKILL.md) — Stage 5

## Security Considerations

- Never include secrets, credentials, PII, or sensitive data in archive documents
- Redact customer/user information from examples
- If archiving includes security fixes, coordinate disclosure timing through separately authorized channels
- Ensure compliance with data retention policies

## ADR Section（架構決策記錄）

Write an ADR only when **all three conditions are true**. AI must verify each condition — do NOT skip.

| # | Condition | Must Confirm |
|---|-----------|-------------|
| 1 | **Hard to reverse** — changing this decision later will be costly or disruptive | ☐ |
| 2 | **Future confusion** — a future team member will likely ask "why was this done this way?" | ☐ |
| 3 | **Real trade-off** — a genuine alternative was considered and there is a real cost to the chosen path | ☐ |

**All three must be true.** If any condition is false, record the decision in the PR description or `99-archive.md` instead. Do NOT write a full ADR.

### ADR Template（Minimal）

```markdown
## ADR: [Decision Title]

**Date**: YYYY-MM-DD
**Status**: Accepted

**Context**: [What problem prompted this decision?]
**Decision**: [What was decided?]
**Alternatives Considered**: [What else was evaluated?]
**Consequences**: [What are the trade-offs?]
```

### Anti-Pattern: ADR Inflation

Writing ADRs for every decision creates noise and reduces the signal value of the ADR catalog. Routine implementation choices (library version bumps, naming decisions, config tweaks) do NOT qualify — use the PR description.

## Verification

Before completing the requested local documentation, confirm:

- [ ] The requested archive document exists at `changes/<slug>/99-archive.md`, when requested
- [ ] `docs/WORK_LOG.md` and `CHANGELOG.md` were updated only when explicitly requested
- [ ] All architecture decisions were checked against the three ADR conditions
- [ ] Code review status and existing merge evidence are recorded without inventing new evidence
- [ ] Sensitive data (secrets, credentials, PII) is not present in archive documents
- [ ] The change package contains the required files for its selected workflow path
- [ ] Remaining Open Questions are clearly marked
- [ ] Any missing protected-action approval is reported with a safe stop or handoff
