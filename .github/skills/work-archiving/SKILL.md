---
name: work-archiving
description: Finalize and archive completed change packages. Use when asked to "archive changes", "finalize work", "close change package", or after code review approval. Handles Git commits, changelog generation, branch cleanup, and documentation updates.
license: See LICENSE.txt in repository root
---

# Work Archiving Skill

## When to Use This Skill

Use this skill at **Stage 6 (Archive)** of the workflow when:
- Code review is approved and all changes are merged
- Need to finalize and document completed work
- Time to close out the change package
- Asked to "archive", "finalize", "close out this work"
- Completing the 6-stage workflow cycle

## Prerequisites

Before archiving:
- [ ] Code review completed (05-review.md exists with approval)
- [ ] All changes committed and pushed
- [ ] Tests passing (if applicable)
- [ ] Documentation updated

## Archiving Workflow

### Step 1: Review Change Package Status

Check the change package folder (`changes/<YYYY-MM-DD>-<slug>/`) for completeness:
- `01-brainstorm.md` — Initial requirements and risk assessment
- `02-decision-log.md` — Key decisions made
- `03-spec.md` — Specification (if standard path)
- `04-plan.md` — Implementation plan
- `05-review.md` — Code review results

### Step 2: Create Archive Summary

Create `changes/<YYYY-MM-DD>-<slug>/99-archive.md`:

```markdown
# Archive: [Feature Name]

**Date Completed**: YYYY-MM-DD
**Status**: ✅ Completed / ⚠️ Completed with Known Issues

## Summary
Brief description of what was implemented.

## Key Outcomes
- Outcome 1
- Outcome 2

## Commits
- [commit-hash] commit message
- [commit-hash] commit message

## Related Issues/PRs
- Closes #123
- Related to #456

## Known Issues / Technical Debt
- Issue 1 (tracked in #789)
- Issue 2 (documented in decision log)

## Lessons Learned
- What went well
- What could be improved
- Recommendations for future work
```

### Step 3: Update CHANGELOG

If `CHANGELOG.md` exists, add entry:

```markdown
## [Version] - YYYY-MM-DD

### Added
- Feature description

### Changed
- Change description

### Fixed
- Fix description

### Security
- Security improvement description
```

If no CHANGELOG exists, consider creating one following [Keep a Changelog](https://keepachangelog.com/) format.

### Step 4: Commit and Tag (if applicable)

```bash
# Commit archive document
git add changes/<YYYY-MM-DD>-<slug>/99-archive.md
git commit -m "docs: archive change package for <feature-name>"

# Optional: Create release tag
git tag -a v1.2.3 -m "Release version 1.2.3"
git push origin v1.2.3
```

### Step 5: Close Related Issues/PRs

If using GitHub:
- Close related issues with reference to commits
- Update project boards
- Link PRs to completed work

### Step 6: Clean Up (Optional)

- [ ] Remove temporary files or branches
- [ ] Archive old change packages (if many exist)
- [ ] Update team documentation

## Output Format

### Archive Document (`99-archive.md`)

| Section | Required | Description |
|---------|----------|-------------|
| Summary | Yes | Brief description of completed work |
| Key Outcomes | Yes | Bullet list of deliverables |
| Commits | Yes | List of Git commits with hashes |
| Related Issues/PRs | If applicable | References to GitHub issues/PRs |
| Known Issues | If applicable | Technical debt or limitations |
| Lessons Learned | Recommended | Retrospective notes |

## Troubleshooting

| Problem | Solution |
|---------|----------|
| Change package incomplete | Review missing files and complete them before archiving |
| Commits not yet pushed | Push changes to remote before finalizing |
| Review not approved | Return to Stage 5 (Review) to address feedback |
| No CHANGELOG exists | Create one or document in 99-archive.md |

## Integration with Workflow

This skill completes the 6-stage workflow:
1. Brainstorm → 2. Specification → 3. Planning → 4. Implementation → 5. Review → **6. Archive**

After archiving, the change package serves as:
- **Audit trail** for regulatory/compliance needs
- **Knowledge base** for future similar work
- **Onboarding material** for new team members
- **Reference** for technical decisions

## Related Resources

- [WORKFLOW.md](../../WORKFLOW.md) — Complete workflow documentation
- [Specification Skill](../specification/SKILL.md) — Stage 2
- [Implementation Planning Skill](../implementation-planning/SKILL.md) — Stage 3
- [TDD Workflow Skill](../tdd-workflow/SKILL.md) — Stage 4
- [Code & Security Review Skill](../code-security-review/SKILL.md) — Stage 5

## Security Considerations

- Never commit secrets, credentials, or sensitive data in archive documents
- Redact customer/user information from examples
- If archiving includes security fixes, coordinate disclosure timing
- Ensure compliance with data retention policies

## ADR Section（架構決策記錄）

Write an ADR (Architecture Decision Record) only when **all three conditions are true**. AI must verify each condition — do NOT skip.

| # | Condition | Must Confirm |
|---|-----------|-------------|
| 1 | **Hard to reverse** — changing this decision later will be costly or disruptive | ☐ |
| 2 | **Future confusion** — a future team member will likely ask "why was this done this way?" | ☐ |
| 3 | **Real trade-off** — a genuine alternative was considered and there is a real cost to the chosen path | ☐ |

**All three must be true.** If any condition is false → record the decision in the PR description or `99-archive.md` instead. Do NOT write a full ADR.

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

Writing ADRs for every decision creates noise and reduces the signal value of the ADR catalog. Routine implementation choices (library version bumps, naming decisions, config tweaks) do NOT qualify — use PR description.

---

## Common Rationalizations

在執行工作歸檔過程中，AI 可能以下列藉口略過關鍵步驟：

| 常見藉口 | 反制說明 |
|---------|---------|
| "口頭記錄就夠了，不需要寫 ADR" | ⛔ 口頭記錄不可查——任何影響未來維護者的架構決策必須書面化；「能記住」不等於「能交接」 |
| "這個功能已上線，不需要再歸檔了" | 歸檔是讓下一個工程師（或未來的你）能快速理解決策脈絡的保障——上線後歸檔才是最重要的時機 |
| "CHANGELOG 太繁瑣，直接看 git log 就好" | git log 無法傳達「為什麼這樣做」——CHANGELOG 記錄業務語境，git log 記錄技術細節；兩者不可替代 |
| "這個決定不重要，不需要寫 ADR" | ADR 只在三條件全為真時才寫：(1) 難以反轉 (2) 未來的人會感到困惑 (3) 真正的折衷取捨存在——若不滿足，記錄在 PR description 即可 |

## Verification

在完成歸檔工作前，逐項確認（Gate = 交付前閘門；Verification = 自我完成確認）：

- [ ] `Test-Path changes/<slug>/06-archive.md` 回傳 True（或對應的 `99-archive.md` / `WORK_LOG.md` 已建立）
- [ ] CHANGELOG.md 已更新，含本次變更的業務語境說明（非僅 commit hash）
- [ ] 所有架構決策已確認三條件（難以反轉 / 未來困惑 / 折衷存在），三條件滿足才寫 ADR
- [ ] 程式碼 review 已通過，無未解 Critical issue
- [ ] 敏感資料（secrets、credentials、PII）未混入歸檔文件
- [ ] change package 目錄下所有必要文件（01–05）均已存在
- [ ] 若有 Open Questions 殘留，已在歸檔文件中明確標記狀態
