# 00 Intake — Workflow–AGENTS Responsibility Alignment

## Status

- **Work type**: Architecture and distribution alignment
- **Risk**: High-Risk
- **Current stage**: Change Package creation; implementation has not started
- **Baseline branch**: `refactor/workflow-agents-alignment`
- **Baseline SHA**: `c7d999bd3f2ac111da695a51aa760a69a7a1052b`
- **Task/status SSOT**: `04-plan.md`
- **Approval source**: Current Alignment approval instruction

## Problem Statement

The repository is simultaneously a maintainer source repository, bootstrap distribution source, cross-CLI workflow package, adopter update mechanism, and canonical-to-derived runtime generator. Current policy, lifecycle, and distribution responsibilities overlap across `AGENTS.md`, `WORKFLOW.md`, Agents, Skills, Prompts, Instructions, bootstrap installers, manifest handling, and generated runtime.

Observed inconsistencies can distribute maintainer-only policy to adopters, reference lifecycle assets that are not installed, overwrite adopter content through the legacy Bash updater, lose ownership provenance after manifest parse failures, retain stale derived runtime, or imply Git/remote authorization through Archive behavior.

## Product Context

This repository owns five distinct domains that must not be collapsed:

1. **User-level Global AGENTS** — user-owned cross-repository governance.
2. **Template maintainer repository** — canonical workflow product and maintainer contract.
3. **Bootstrap distribution boundary** — packaging, ownership, preservation, migration, and generation.
4. **Adopter project canonical sources** — project-owned rules and editable shared workflow sources.
5. **CLI-specific derived runtime** — generated mirrors, mounts, wrappers, and compatibility representations.

Evidence: `AGENTS.md` — Cross-CLI Constitutional Baseline, Source-of-truth vs runtime locations, Ownership classes; `scripts/bootstrap.py` — `install_portable_runtime()`; `scripts/bootstrap.ps1` — `Install-PortableRuntime`.

## Verified Critical Product Defects

| ID | Observed defect | Evidence |
|---|---|---|
| C-01 | Maintainer constitution may be distributed to adopters instead of the intended adopter constitution. | `AGENTS.md` — Deployed constitution vs maintainer constitution; `tools/sync-dotgithub.ps1`; `scripts/bootstrap.py` — `template_source`; `scripts/bootstrap.ps1` — `$templateSourcePath` |
| C-02 | `bootstrap.sh --update` enables force and lacks ownership-preserving manifest behavior. | `scripts/bootstrap.sh` — argument parsing and `sync_workflow_files()` |
| C-03 | Adopter guidance requires `WORKFLOW.md` and Change Package assets that bootstrap does not install. | `docs/AGENTS.template.md` — 6-Stage Workflow; `scripts/bootstrap.py`; `scripts/bootstrap.ps1`; `changes/_template/` |
| C-04 | Manifest parse failure is silently treated as an empty manifest. | `scripts/bootstrap.py` — `load_install_manifest()`; `scripts/bootstrap.ps1` — `Get-InstallManifest` |
| C-05 | Canonical Agent/Skill rename or deletion does not reconcile stale derived runtime. | `scripts/bootstrap.py` — derived generation loops; `scripts/bootstrap.ps1` — `Install-PortableRuntime` |
| C-06 | Archive behavior may be interpreted as authorization for Git or remote writes. | `skills/work-archiving/SKILL.md` — Steps 4–6; `prompts/archive.prompt.md`; `WORKFLOW.md` — Archive mapping |

## Approved Architecture Decisions

| Decision | Approved status | Summary |
|---|---|---|
| D-01 | Approved | Global keeps full governance; Project AGENTS uses project contract plus 6–10 fallback rules. |
| D-02 | Approved — Critical | Separate maintainer/adopter constitutions; preserve existing adopter content. |
| D-03 | Approved | Only Simple, Standard, and High-Risk execution modes remain. |
| D-04 | Approved with revision | Thin Agents; line count is a soft target, responsibility structure is a hard gate. |
| D-05 | Approved | Detect → dry-run → report; prune only after proof and explicit approval. |
| D-06 | Direction approved only | Manifest capabilities and failure policy approved; complete JSON schema is not approved. |
| D-07 | Approved with revision | Change Package is lifecycle evidence; one task/status SSOT; Review uses semantic role plus legacy aliases. |
| D-08 | Hybrid direction approved | Pre-merge repository closeout plus authoritative external merge evidence; operational post-merge record when needed. |
| D-09 | Direction approved | `agentic-eval` is risk-adaptive self-evaluation and never replaces independent review. |
| D-10 | Deferred | Gather current official Codex and Antigravity evidence before adapter implementation. |
| D-11 | Approved — Deprecated | Python is the Linux/macOS installer; Bash update is rejected and Bash parity is no longer claimed. |

## In Scope

- Align responsibility ownership across Global, maintainer, adopter, lifecycle, methodology, distribution, and runtime layers.
- Contain C-01 through C-06 through separately approved implementation phases.
- Define risk-adaptive execution modes and lifecycle artifact responsibilities.
- Define safe adopter migration classes and manifest/provenance requirements.
- Preserve existing adopter customization by default.
- Establish independent PR and approval boundaries for every implementation phase.
- Maintain a deferred evidence backlog for D-10.

## Out of Scope

- Immediate implementation of any phase.
- Full manifest JSON schema design.
- Automatic adopter migration or stale-output pruning.
- Selecting `07-review.md`, renaming `99-archive.md`, or removing legacy aliases in this stage.
- Runtime adapter changes without current official evidence.
- Rewriting Bash as a third full installer implementation.
- P0 trustworthy baseline repair.
- Commit, push, PR, deployment, production access, or remote settings changes.

## Stakeholders and Adopter Classes

- Template maintainers and reviewers.
- New adopters receiving current defaults.
- Existing untouched adopters whose files still match a proven managed baseline.
- Existing customized adopters with project forks.
- Legacy adopters without a trustworthy manifest or using older layouts/installers.
- GitHub Copilot, Codex, Claude, Antigravity, and no-custom-agent surfaces.

## Constraints

- No user-level Global AGENTS modification by this product.
- Project AGENTS must work safely when Global AGENTS is absent.
- Existing adopter files must not be overwritten based on assumption alone.
- Derived runtime must not become a policy source.
- Git/remote/destructive actions require explicit task-scoped authorization.
- Cross-CLI claims must distinguish Observed, Proposed, Deferred, and Not observed.
- Critical defects must not be combined into one implementation PR.

## Success Criteria

1. Each approved decision D-01 through D-11 has one canonical implementation owner and phase.
2. New adopters cannot receive maintainer-only constitution content.
3. Untouched, customized, and legacy adopters follow distinct, testable update behavior.
4. Simple tasks can complete safely without the six-stage lifecycle or Change Package.
5. High-Risk work requires full lifecycle, approvals, independent review, and operational evidence.
6. Agents cannot own full methodology, workflow policy, or authorization rules.
7. Manifest update cannot silently recover from corrupt or unsupported state.
8. Derived retirement cannot delete unknown or modified content.
9. Archive cannot imply Git or remote authorization.
10. Python/PowerShell remain the supported installer implementations; Bash update is refused.
11. D-10 runtime work remains blocked until current official evidence is reviewed and separately approved.

## Migration Safety

No automatic adopter migration is authorized by this Change Package. Every future automatic action must first prove the adopter class, managed baseline, current content state, and applicable compatibility rule.

For an existing constitution component, **untouched migration candidate** has a narrow meaning: a currently valid and trusted manifest already records a verifiable previous managed baseline for that exact component, and the current content equals that recorded baseline. Component baseline absent, missing/corrupt/unsupported manifest, unclear source identity, content similarity alone, reconstructed or guessed baseline, customized content, or unknown legacy ownership are not proof. Those states must follow preserve → report → manual decision. Phase 0A must not invent D-06 lineage to create eligibility.
