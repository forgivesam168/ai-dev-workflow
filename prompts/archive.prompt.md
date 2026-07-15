---
description: 'Finalize documentation, record existing merge evidence, and close change-package documentation.'
---

# Archive Command

Use `/archive` after PR is merged to finalize documentation, record existing merge evidence, and close change-package documentation.

## Authorization Boundary

This Archive invocation authorizes only the requested local archive documentation scope. It does not authorize protected Git or remote actions.

Archive-authorized local documentation may include create or update operations for the requested archive document or archive summary, the requested `docs/WORK_LOG.md` or `CHANGELOG.md` entry, and `99-archive.md`, plus read-only inspection of existing commit, PR, and Issue evidence.

The following actions remain separately protected and are not authorized by Archive:
- commit
- push
- tag
- merge
- local branch deletion
- remote branch deletion
- remote Issue closure
- remote PR closure
- release or other remote mutation

Every protected action requires explicit, current-task, action-specific user approval. One approval does not authorize another protected action. Approval for commit does not authorize push. Approval for push does not authorize tag. Approval for merge does not authorize branch deletion. Approval for documentation does not authorize remote closure.

If any approval is missing, do not execute the protected action. Report the exact required action-specific approval, finish safe local documentation when requested, then stop or hand off. Do not produce a command list that could be mistaken for an automatically authorized action.

## Process

### Step 1: Generate Work Log Entry

Update `docs/WORK_LOG.md` only when the current task explicitly requests it:

```markdown
## [YYYY-MM-DD HH:MM] {Task Name}

### 📋 Schema/Contract Changes
- **[None / Yes]**: {If yes, list modified OpenAPI/Schema files and fields}

### 🛠️ Implementation Summary
- **{File path}**: {Change description}

### 🔍 TDD Status
- **Test Coverage**: {Boundary cases tested}
- **Status**: Pass / Fail

### 🛡️ Compliance Checklist
- [x] Financial precision (Decimal)
- [x] Input validation
- [x] Security review passed
```

### Step 2: Finalize Change Package

When requested by the current task, create `changes/<...>/99-archive.md` using the existing Archive output structure:

```markdown
# Archive: {Feature Name}

## Outcome
- **Status**: Completed / Partial / Cancelled
- **PR**: Existing PR reference
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

The current `99-archive.md` filename remains unchanged in this phase, and historical Archive artifacts remain readable.

### Step 3: Record Evidence and Check Authorization

Record existing merge evidence only; do not invent evidence or perform protected actions. Before any separately protected action, verify explicit, current-task, action-specific approval for that specific action. If any requirement is missing, do not execute it, report the exact required approval, and finish safe local documentation or stop with a safe handoff.

## Rules

- Do not include secrets, PII, or sensitive customer/transaction data
- Keep archive documentation concise but complete for future reference
- Record relevant existing PR and Issue references without remote closure
- Update `CHANGELOG.md` only when explicitly requested by the current task

## Next Step

After the requested local documentation is complete, stop or hand off any separately protected action that lacks its own approval.

✅ **Change Package Lifecycle**: Local documentation closed; protected actions remain separately authorized
