# Intake: Trustworthy Baseline Recovery

## Goal

Restore a read-only, reproducible, and green maintainer verification baseline before any lifecycle or architecture redesign.

## Scope

- Read-only source-to-`.github` drift checker
- Catalog contract: 35 total / 34 adopter / 1 maintainer-only (`gate-check`)
- Python and PowerShell relative-path identity fix
- Reproducible pytest 8.3.5 and Pester 5.6.1 test baseline
- Windows and Ubuntu CI-equivalent verification

## Explicit Non-Goals

No Global AGENTS V5 alignment, lifecycle manifest, archive redesign, agent-ID migration, installer parity, skill splitting, prune/tombstone, or user/system Codex configuration.

## Risk

Medium. The main risks are a checker that mutates the worktree, stale tests masking a product defect, and existing adopter manifests containing legacy normalized keys.
