# 06 Impact Analysis — Workflow–AGENTS Responsibility Alignment

## Status

- **Risk**: High-Risk
- **Implementation**: Not started
- **Migration**: Not authorized
- **Purpose**: Identify distribution, compatibility, policy-loss, and operational impact before each separately approved phase.

## Impact Surface

### Template Maintainer Repository

Proposed changes affect responsibility ownership, canonical source boundaries, lifecycle contract, catalog/generation expectations, installer support, and maintainer gates.

Risk: a partial change can leave root guidance, adopter templates, canonical assets, mirrors, and tests semantically inconsistent.

Required control: canonical-first changes, sync verification, independent review, and one phase/PR boundary at a time.

Evidence: `AGENTS.md`; `WORKFLOW.md`; `tools/sync-dotgithub.ps1`; `tools/check-sync.ps1`; `tools/audit-catalog.ps1`.

### Bootstrap Distribution

Impacted behaviors:

- adopter constitution source;
- lifecycle asset packaging;
- ownership classification;
- project-owned preservation;
- template-managed fork detection;
- manifest failure handling;
- derived generation and retirement;
- Linux/macOS installer guidance.

Primary risk: incorrect classification can overwrite policy or conceal provenance loss.

Phase 3 has an additional design prerequisite: approve the adopter-facing lifecycle source after maintainer/adopter difference review. Bootstrap must not directly install root maintainer `WORKFLOW.md` merely because it is the current maintainer lifecycle owner. The eventual source may be an adopter-specific template, shared core with projections, or a document proven fully generic; this Change Package does not select its path.

### Existing Adopters

Existing adopters may contain:

- project-owned AGENTS/wrappers;
- untouched template-managed files;
- customized Agents/Skills/Instructions/Prompts;
- manually edited derived runtime;
- legacy layouts or missing manifests;
- historical Change Packages using old filenames.

No existing adopter is eligible for automatic migration solely because its files resemble the newest template.

### Project-Owned AGENTS

Project AGENTS remains project-owned. New defaults may improve fallback behavior, but existing files must receive a proposed/manual alignment path rather than replacement.

Policy-loss risk: overwriting project domain rules, commands, repository structure, or stricter safety requirements.

### Customized Agent / Skill Content

Customized canonical Agent/Skill content may intentionally diverge from the template. Thin-Agent alignment must not treat such divergence as stale derived output.

Required behavior: preserve, report template delta, and require manual adoption decision.

### Generated Runtime

Impacted outputs can include `.github/agents`, `.github/skills`, `.codex/agents`, `.claude/agents`, and Skill mounts.

Risks:

- stale retired output remains loadable;
- manual derived changes are overwritten;
- rename produces both old and new runtime identities;
- copy-fallback mounts become independent stale copies.

Required behavior: provenance-aware dry-run and explicitly approved safe prune only.

### Manifest Migration

Current tracked manifest is schema v1 while supported installers emit schema v2. Future lineage requirements imply another versioned design, but no complete schema is approved.

Risks:

- silent parse reset;
- loss of previous baseline;
- false untouched/customized classification;
- stale component entries;
- unsafe prune eligibility.

Required behavior: v1/v2 compatibility, explicit parse state, hard stop for corrupt/unsupported update, and report-only legacy adoption.

### Python / PowerShell Parity

Both are supported installer implementations and must share ownership, preservation, manifest, generation, failure, and retirement semantics.

Risk: implementing a safety rule in only one installer creates platform-dependent policy loss.

Required behavior: equivalent fixtures and Windows/Ubuntu matrix verification.

### Bash Users

Current Bash updater enables force and does not implement the current ownership/manifest model.

Proposed behavior:

- reject update of existing adopters;
- show deprecation warning;
- direct Linux/macOS users to Python;
- optionally retain a thin initial-install wrapper temporarily.

Migration risk: automation invoking Bash update will fail after containment. This is intentional safe failure and requires release notes.

## CLI Surface Impact

### GitHub Copilot

Likely impacted assets include `.github/copilot-instructions.md`, `.github/agents`, `.github/skills`, `.github/prompts`, and `.github/instructions`.

Primary impact: separating maintainer/adopter constitution and removing duplicate lifecycle policy from Prompt/Agent surfaces.

### Codex

Repository code generates `.codex/agents` and shares `.agents/skills`, but current official capability evidence is **Not observed** in this Change Package.

Impact remains Deferred under D-10. No runtime change is authorized.

### Claude

Likely impacted assets include project-owned `CLAUDE.md`, `.claude/skills`, and generated `.claude/agents`.

Project-owned wrapper updates require manual adoption. Generated Agent changes follow canonical Agent changes only.

### Antigravity

Repository guidance references `GEMINI.md`, `.agents/skills`, and `.agent/skills`, but current official project-rule capability is **Not observed** here.

Impact remains Deferred under D-10.

### No-Custom-Agent Surfaces

These surfaces depend on Project AGENTS plus relevant Skills. They benefit from the short standalone fallback and canonical Workflow/Skill contract.

Risk: moving essential behavior exclusively into Custom Agents would break the portable baseline; D-04 prohibits that outcome.

## Historical Change Package Impact

Historical packages may use `05-review.md`, `99-archive.md`, incomplete older layouts, or status inferred from filenames.

Required compatibility:

- semantic Review role recognizes legacy filename;
- no bulk rename;
- Archive/Closeout name decision includes alias strategy;
- historical evidence remains readable;
- new validators distinguish legacy acceptance from new-package requirements.

## CI / Catalog / Sync Impact

Potentially affected controls:

- source-to-`.github` sync parity;
- Agent/Prompt/Skill catalog counts;
- maintainer-only exclusion;
- Change Package contract verification;
- Python/Pester installer suites;
- Windows/Ubuntu gate matrix.

The current Change Package verifier is not the architecture SSOT. Future verifier changes must implement the approved mode/artifact contract rather than forcing the contract to match old checks.

## Documentation and Release Impact

Required future communication includes:

- maintainer versus adopter constitution distinction;
- supported installer matrix;
- Bash deprecation and Python migration;
- risk modes and removal of Fast Path terminology;
- existing adopter preservation/report behavior;
- manifest recovery and stale-output dry-run behavior;
- lifecycle/Review/Archive compatibility notes.

## Adopter-Class Migration Matrix

### New Adopter

- **Current behavior**: Receives current bootstrap defaults, including the risk of maintainer constitution leakage and missing promised lifecycle assets.
- **Proposed behavior**: Receives adopter constitution, supported canonical assets, explicit ownership, and full provenance.
- **Automatic migration eligibility**: N/A; new install.
- **Manual decision**: Only project customization after install.
- **Rollback**: Remove the new install in the test/initialization transaction or restore pre-install backup where applicable.
- **Data/policy loss risk**: Low if target is truly new; must still detect pre-existing files.

### Existing Untouched Adopter

- **Current behavior**: Hash-aware update may refresh template-managed content; project-owned guidance is skipped.
- **Proposed behavior**: Eligible for constitution automatic migration only when a trusted existing manifest records a verifiable previous managed baseline for that exact component and current content equals it.
- **Automatic migration eligibility**: Conditional on exact recorded component baseline proof; content similarity, reconstructed lineage, or a generic manifest record is insufficient.
- **Manual decision**: Required when the component baseline is absent; manifest is missing, corrupt, or unsupported; source identity is unclear; only similarity is available; baseline was reconstructed/guessed; content is customized; ownership is unknown; or project-owned content is involved. Preserve and report first.
- **Rollback**: Restore backed-up managed content and prior manifest.
- **Data/policy loss risk**: Medium if lineage is incomplete.

### Existing Customized Adopter

- **Current behavior**: Python/PowerShell generally preserve recognized customization; derived outputs may still overwrite by design.
- **Proposed behavior**: Preserve canonical customization, report template delta, regenerate derived only after canonical adoption decision.
- **Automatic migration eligibility**: No for customized canonical policy.
- **Manual decision**: Required per customization group.
- **Rollback**: Restore canonical and derived backup generated before an approved migration.
- **Data/policy loss risk**: High if customized canonical or derived content is misclassified.

### Legacy Adopter

- **Current behavior**: Missing/corrupt provenance may be treated as empty manifest; legacy layouts may be seeded incompletely.
- **Proposed behavior**: Warning + report-only for missing manifest; hard stop for corrupt/unsupported manifest; no inferred ownership.
- **Automatic migration eligibility**: No. Missing/corrupt/unsupported manifest, absent exact component baseline, unclear source identity, reconstructed/guessed lineage, and unknown ownership cannot establish untouched eligibility in Phase 0A.
- **Manual decision**: Required for adoption, mapping, and retirement.
- **Rollback**: No write should occur during report-only; preserve original layout.
- **Data/policy loss risk**: Critical if force, silent reset, or automatic prune is used.

## Rollout Principles

1. Contain immediate unsafe behavior before broad architecture cleanup.
2. Release each phase independently with explicit migration notes.
3. Use dry-run/report before any adopter update behavior changes.
4. Keep default actions additive or preserving.
5. Stop on ambiguous ownership rather than guessing.
6. Keep Phase 0C manifest containment and Phase 0D Archive authorization containment in separate approval, implementation, verification, review, and PR boundaries.

## Rollback Principles

- Roll back one phase/PR at a time.
- Restore both canonical and generated outputs when a synchronized phase is reverted.
- Preserve manifest backups and never silently downgrade provenance.
- Do not delete newly classified legacy/custom content during rollback.
- Validate rollback using the same adopter-class fixtures used for rollout.

## Monitoring and Validation Signals

- No maintainer-only text in new adopter constitution.
- Zero overwritten customized/legacy fixtures.
- Explicit counts for preserved, updated, conflicted, stale, and blocked components.
- Zero silent manifest resets.
- Zero prune operations without recorded approval.
- Python/PowerShell parity across the reviewed fixture matrix.
- No lifecycle or quality downgrade on a surface lacking Custom Agents.

## Remaining Uncertainty

- Complete manifest schema and migration encoding.
- Canonical Review filename.
- Archive/Closeout artifact name.
- Final High-Risk rubric thresholds.
- Current official Codex and Antigravity capabilities.
- Bash wrapper removal timing.
