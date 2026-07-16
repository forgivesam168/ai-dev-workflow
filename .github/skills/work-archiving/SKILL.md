---
name: work-archiving
description: Finalize and document completed change packages at Stage 6. Use when asked to archive changes, finalize work, or close change-package documentation.
license: See LICENSE.txt in repository root
---

# Work Archiving Skill

## When to Use This Skill

Use this skill at **Stage 6 (Closeout / Archive)** of the workflow when:
- A triggered Standard or High-Risk package is ready for pre-merge lifecycle closeout
- Required Review is `PASS` or `PASS_WITH_NOTES`, and deterministic gates are green
- Need to finalize the requested local package documentation in the original implementation PR
- Asked to archive, finalize, or close out this work
- Completing the 6-stage workflow cycle

Simple and Standard without a package do not require a repository Archive/Closeout. A voluntarily created package follows its declared Compact or Full contract. Do not create package files merely to pad a filename list.

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

Before closeout:
- [ ] Selected execution mode, Compact/Full package contract, and single task/status SSOT are declared
- [ ] Required Review content/status is available when independent Review applies
- [ ] Tests are passing, if applicable
- [ ] The requested documentation scope is clear
- [ ] Actual merge evidence is either absent/unknown pre-merge or read-only remote evidence already exists; it is never invented

## Archiving Workflow

### Step 1: Review Change Package Status

Check the declared package contract and semantic roles, not filename existence alone:

- Compact: Intake, decision evidence, plan/lifecycle evidence, exactly one task/status SSOT, Review only when independent Review is required, and pre-merge Closeout. Brainstorm, Spec, separate Test Plan, and Impact Analysis are included only when selected by stage/risk.
- Full: `00-intake.md` through `06-impact-analysis.md`, canonical `07-review.md`, and canonical `99-archive.md`.
- Historical `05-review.md` remains readable as Review. `99-closeout.md` is a compatibility alias. Canonical and alias files may coexist only with the documented pointer-only alias; two independent semantic bodies are blocking.

Record only evidence that already exists. Do not treat the presence of an Archive request as authorization for a protected action.

### Step 2: Create Archive Summary

When the current task requests the archive document, create `changes/<YYYY-MM-DD>-<slug>/99-archive.md`:

```markdown
# Closeout: [Feature Name]

## Outcome
- Status: COMPLETE | COMPLETE_WITH_NOTES | BLOCKED
- Summary: [verified result without overstating delivery]

## Approved Scope
- Completed: [approved scope completed]
- Excluded: [preserved boundaries]

## Verification Evidence
- Tests/checks/gates: PASS — evidence | BLOCKED — evidence | N/A — reason
- Evidence gaps: None | WARNING — non-blocking evidence | BLOCKED — required deterministic evidence

## Review Status
- Review file: `07-review.md` | N/A — reason
- Decision: PASS | PASS_WITH_NOTES | BLOCKED | N/A — reason

## Delivery Status
- State: pre-merge | unmerged
- Remote delivery evidence: Not available pre-merge.

## Remaining or Deferred Work
- Remaining: None | [remaining work]
- Deferred: None | [deferred or separately authorized work]

## Authorization Boundary
- Local documentation authorization and any separately approved protected action.

## Rollback or Recovery
- Evidence or N/A: [substantive rollback/restore/compensation/recovery/safe-stop evidence] | N/A — [reason]
```

Every structured field appears exactly once and replaces its option list with one substantive selected value. `WARNING` is recorded without blocking and supports `COMPLETE_WITH_NOTES`. A blocked Review or required deterministic failure requires Outcome `BLOCKED`. Pre-merge Closeout keeps authoritative merge-result evidence external and must not claim an actual merged state, merge SHA, or `mergedAt` anywhere in the artifact. Expected head SHA, final head, and commit SHA evidence remain allowed. Do not create a post-merge commit or push merely to add merge-result evidence. Historical Archive artifacts remain readable.

### Step 3: Record Requested Local Documentation

Update `docs/WORK_LOG.md` or `CHANGELOG.md` only when the current task explicitly requests that local documentation. If the task does not request one of these files, leave it unchanged and report that no update was requested.

### Step 4: Verify Authorization and Handoff

Before any separately protected action, verify all three requirements for that specific action: explicit approval, current-task authorization, and action-specific authorization. If any requirement is missing, do not execute it; report the exact missing approval and finish safe local documentation or stop with a safe handoff.

## Output Format

### Archive Document (`99-archive.md`)

| Section | Required | Description |
|---------|----------|-------------|
| Outcome | Yes | Verified outcome without overstating delivery |
| Approved Scope | Yes | Scope completed and boundaries preserved |
| Verification Evidence | Yes | Deterministic commands/checks and observed results |
| Review Status | Yes | PASS / PASS_WITH_NOTES / BLOCKED / N/A with reason |
| Delivery Status | Yes | Accurate pre-merge or observed external delivery state |
| Remaining or Deferred Work | Yes | Unverified, unmerged, deferred, or separately authorized work |
| Authorization Boundary | Yes | Local documentation scope and separate protected approvals |
| Rollback or Recovery | Yes | Applicable rollback/restore/compensation/recovery/safe-stop evidence, or `N/A — reason` |

## Troubleshooting

| Problem | Solution |
|---------|----------|
| Change package incomplete | Review missing local documentation and report the gap |
| Protected action approval missing | Report the exact action-specific approval required, then stop or hand off |
| Review or deterministic gate blocked | Set Closeout delivery status to `BLOCKED` and return to the owning stage |
| Actual merge evidence unavailable | Record it as unavailable/unknown pre-merge; do not invent it |
| No `CHANGELOG.md` exists | Create one only when the current task explicitly requests it; otherwise leave it unchanged |

## Integration with Workflow

This skill completes applicable pre-merge documentation for the 6-stage workflow:
1. Brainstorm → 2. Specification → 3. Planning → 4. Implementation → 5. Review → **6. Closeout / Archive**

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
- [ ] Review content/status and deterministic evidence were validated, not inferred from filenames
- [ ] Actual merge evidence is read from PR/Issue/Release evidence when available, or explicitly unavailable/unknown pre-merge; it is never invented
- [ ] Sensitive data (secrets, credentials, PII) is not present in archive documents
- [ ] The Change Package contains the semantic roles required by its Compact/Full contract without empty padding
- [ ] Remaining Open Questions are clearly marked
- [ ] Any missing protected-action approval is reported with a safe stop or handoff
