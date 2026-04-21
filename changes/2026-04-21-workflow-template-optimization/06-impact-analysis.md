# Impact Analysis: Workflow Template Optimization

**Spec Reference**: `03-spec.md`
**Plan Reference**: `04-plan.md`
**Risk Level**: High
**Brownfield**: Yes

---

## Summary

This change package modifies documentation, agents, skills, and tooling across a live template repository. No runtime application code is changed; all changes are to the template's governance layer. The primary risk is **documentation drift** (changes that introduce new inconsistencies) and **sync failure** (forgetting to mirror source changes to `.github/**`).

---

## New Files Created

| File | Phase | Purpose |
|------|-------|---------|
| `tools/audit-catalog.ps1` | 1 | Automated catalog count and contract parity check |
| `docs/install-surface-design.md` | 2 | Design spec for install-plan, install-apply, doctor |
| `docs/repo-memory-design.md` | 4 | Design spec for opt-in repo memory surface |
| `skills/explore/SKILL.md` | 3 | Explore mode skill specification |
| `skills/gate-check/SKILL.md` | 3 | Deterministic gate-check skill specification |
| `skills/gate-check/scripts/run-gate-check.ps1` | 3 | Gate-check script stub |
| `skills/debug/SKILL.md` | 5 | Systematic debug skill specification |

**New skill count after this change**: 31 (28 existing + explore + gate-check + debug)
**⚠️ Action required**: Update canonical count in `AGENTS.md` (and README files) to reflect 31 skills.
> Note: This is a known consequence of Phase 3/5. Catalog alignment in Phase 1 should document the *pre-change* count and then update again after all skills are added.

---

## Modified Files

### Source-of-Truth Files (require sync to `.github/**`)

| File | Impact Level | Change Summary | Sync Required |
|------|-------------|----------------|--------------|
| `agents/coder-agent.md` | Medium | Add Subagent Status Protocol section; add NFR-05 reference | ✅ Yes |
| `agents/plan-agent.md` | Medium | Add Subagent Status Protocol section | ✅ Yes |
| `agents/architect-agent.md` | Medium | Add Subagent Status Protocol section; add NFR-05 reference | ✅ Yes |
| `skills/agentic-eval/SKILL.md` | Medium | Add stage-transition (2-iter) vs general-purpose (3–5-iter) ceiling distinction | ✅ Yes |
| `instructions/changes.instructions.md` | Low | Align change-package contract with WORKFLOW.md (if discrepancies found) | ✅ Yes |

### Documentation Files (no `.github/**` mirror)

| File | Impact Level | Change Summary | Sync Required |
|------|-------------|----------------|--------------|
| `README.md` | Low | Align catalog count statements | ❌ No |
| `README.zh-TW.md` | Low | Align catalog count statements (Chinese) | ❌ No |
| `AGENTS.md` | Low–Medium | Align counts; designate canonical source; update skill count post Phase 3/5 | ❌ No |
| `WORKFLOW.md` | Low | Align change-package contract; reference canonical source | ❌ No |
| `docs/install-surface-design.md` | Low | Update after Phase 4 to add --enable-memory cross-reference | ❌ No |

---

## Mirror Files Automatically Updated by Sync

Running `pwsh -File .\tools\sync-dotgithub.ps1` will automatically update:

| Source | Mirror |
|--------|--------|
| `agents/coder-agent.md` | `.github/agents/coder-agent.md` |
| `agents/plan-agent.md` | `.github/agents/plan-agent.md` |
| `agents/architect-agent.md` | `.github/agents/architect-agent.md` |
| `skills/agentic-eval/SKILL.md` | `.github/skills/agentic-eval/SKILL.md` |
| `skills/explore/SKILL.md` | `.github/skills/explore/SKILL.md` |
| `skills/gate-check/SKILL.md` | `.github/skills/gate-check/SKILL.md` |
| `skills/gate-check/scripts/run-gate-check.ps1` | `.github/skills/gate-check/scripts/run-gate-check.ps1` |
| `skills/debug/SKILL.md` | `.github/skills/debug/SKILL.md` |
| `instructions/changes.instructions.md` | `.github/instructions/changes.instructions.md` |

---

## Breaking Changes Assessment

| Change | Breaking? | Impact | Migration Path |
|--------|----------|--------|----------------|
| Catalog count update in README / AGENTS | ❌ No | Documentation only; no behavioral change | None |
| Change-package contract alignment | ❌ No | Aligns two already-correct documents; additive only | None |
| New audit script `tools/audit-catalog.ps1` | ❌ No | New tool; optional use; does not affect existing scripts | None |
| New `docs/` design files | ❌ No | New files; nothing depends on them | None |
| New `skills/explore/`, `skills/gate-check/`, `skills/debug/` | ❌ No | Additive; no existing skill modified | None |
| Agent file updates (Subagent Status Protocol + NFR-05 refs) | ❌ No | Additive; existing agent behavior unchanged | None |
| `skills/agentic-eval/SKILL.md` iteration ceiling | ❌ No | Clarifying addition; existing ceiling (3–5 iter) unchanged; stage-gate cap (2 iter) is new rule | Agents following existing rules continue to function; stage-gate cap is a new constraint |

**Overall breaking change assessment**: No breaking changes. All modifications are additive or clarifying.

---

## Pre-Existing Violations Noted (Do Not Fix in This Change Package)

| Issue | Location | Severity | Recommendation |
|-------|----------|----------|----------------|
| Agent files exceed ≤25 non-empty lines guideline | `agents/coder-agent.md` (~28), `agents/plan-agent.md` (~30), `agents/architect-agent.md` (~38) | Low | Track as separate cleanup task; do not refactor in this change |
| `docs/` directory only contains `research/` folder with no top-level docs | `docs/` | Low | Resolved by this change package (install-surface-design.md + repo-memory-design.md added) |

---

## Catalog Count Side Effect

This change package adds **3 new skills** (explore, gate-check, debug). The skill count will change from **28 → 31**. This creates a secondary drift risk if the count update in AGENTS.md is not synchronized with the actual delivery.

**Mitigation**: Phase 1 establishes the audit script. After Phase 3 and Phase 5 add new skills, re-run `audit-catalog.ps1` to catch count drift. Update `AGENTS.md` in the same commit that adds the new skills.

**Recommended update sequence**:
1. Phase 1: Audit script captures baseline at 28 skills; docs aligned
2. Phase 3: Add explore + gate-check skills → update constant in `audit-catalog.ps1` to 30; update AGENTS.md to 30
3. Phase 5: Add debug skill → update constant to 31; update AGENTS.md to 31

---

## Rollback Strategy

### Per-Phase Rollback

Since each phase is independently committed, rollback is granular:

| Phase | Rollback Action |
|-------|----------------|
| Phase 1 | `git revert <commit>` — reverts count alignment and removes audit script |
| Phase 2 | `git revert <commit>` — removes `docs/install-surface-design.md` |
| Phase 3 | `git revert <commit>` — removes 3 new skill directories and reverts agent file additions |
| Phase 4 | `git revert <commit>` — removes `docs/repo-memory-design.md` and cross-ref edit |
| Phase 5 | `git revert <commit>` — removes debug skill and reverts agentic-eval + agent file changes |

### Full Rollback

```powershell
# Revert all 5 phase commits (in reverse order)
git revert HEAD~4..HEAD --no-edit
pwsh -File .\tools\sync-dotgithub.ps1
```

### Partial Rollback Safety

- New `docs/` files have no dependents — safe to delete independently
- New `skills/` directories have no dependents — safe to delete independently
- Agent file additions (Protocol section + NFR-05 ref) are additive text; revert is a clean delete of those sections
- `skills/agentic-eval/SKILL.md` changes: revert the added section; existing content unchanged

---

## Risk Matrix

| Risk | Likelihood | Impact | Mitigation | Owner |
|------|-----------|--------|------------|-------|
| Catalog count drifts after new skills added in Phase 3/5 | Medium | Low | Update `audit-catalog.ps1` constant in the same commit; re-run script | Implementer |
| Agent files grow further above ≤25 non-empty lines limit | High | Low | Use compact table format for Protocol section (≈8–10 lines); accept pre-existing violation; log for future cleanup | Implementer |
| Sync forgotten after agent/skill changes | Medium | Medium | Sync step is in every phase's exit criteria and commit protocol; `check-sync.ps1` will detect post-hoc | Implementer |
| `docs/install-surface-design.md` Phase 2 cross-ref missed in Phase 4 | Low | Low | Task 4.2 is an explicit verification step | Implementer |
| Install surface design spills into profile/dist scope | Low | High | Spec non-goals explicitly exclude profile/dist; design doc must include Future Scope section to delineate boundary | Implementer |
| Repo memory feature created by default (breaking for adopters) | Low | High | AC-6 + design doc explicitly requires opt-in; Phase 4 exit criteria checks default-off behavior | Implementer |
| Existing inconsistencies broader than currently observed | Medium | Medium | Phase 1 audit script will surface additional drift; use decision-log to record and decide whether to expand scope or defer | Implementer |

---

## Deployment Considerations

- No runtime service changes; this is a template repo
- All adopters who have already bootstrapped this template into their repos are unaffected until they pull the updated template (opt-in adoption)
- The new `skills/explore/`, `skills/gate-check/`, and `skills/debug/` are purely additive — they do not modify behavior of existing skills or agents
- The `skills/agentic-eval/SKILL.md` change adds a new constraint (stage-gate 2-iteration cap) that was not previously documented. This is a behavioral tightening, not a relaxation. Any agent currently iterating more than 2 times at stage gates would now be in violation — but since model-driven agents self-govern, this is enforced by prompt behavior, not a hard technical gate.

---

## Dependencies on External Resources

| Resource | Required | Notes |
|----------|----------|-------|
| PowerShell 7+ (pwsh) | Yes | Required for `audit-catalog.ps1` and `run-gate-check.ps1` |
| `tools/sync-dotgithub.ps1` | Yes | Existing tool; must continue to work |
| `tools/check-sync.ps1` | Yes | Existing tool; used for regression verification |
| Git | Yes | For commit + revert operations |

No new external service dependencies introduced.
