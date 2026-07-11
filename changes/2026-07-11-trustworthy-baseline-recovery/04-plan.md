# Implementation Plan: Trustworthy Baseline Recovery

**Status**: Approved by user on 2026-07-11
**Risk**: Medium
**Scope**: P0 baseline recovery only

## Phase 1 — Runner compatibility

- [x] Import Pester 5.6.1 from a uniquely named temporary directory.
- [x] Move bootstrap test dot-source into Pester `BeforeAll`.
- [x] Verify the unchanged suite passes: 27/27.

## Phase 2 — Read-only sync gate

- [x] Add isolated fixture tests for clean, drift, unmanaged paths, and non-mutation.
- [x] Add `tools/check-sync.ps1` using temporary generation through the existing sync script.
- [x] Point gate-check automation and documentation at the read-only checker.

## Phase 3 — Catalog truth

- [x] Add 35/34/1 fixture tests, including unreviewed add/remove failures.
- [x] Update the audit and necessary catalog documentation.

## Phase 4 — Path identity and Python baseline

- [x] Add equivalent Python and PowerShell regression tests.
- [x] Replace unsafe leading-character trimming.
- [x] Update only test expectations proven stale by the target-root-relative contract.

## Phase 5 — CI and proof

- [x] Add Windows/Ubuntu baseline matrix with pinned direct test runners.
- [x] Run source sync, then prove cleanliness with the read-only checker.
- [x] Run catalog, Python, PowerShell, fixture tests, `git diff --check`, and worktree invariance on Windows.
- [x] Complete independent correctness, test-contract, cross-language parity, and non-mutating-gate reviews.
- [ ] Observe the Windows/Ubuntu GitHub Actions matrix after a separately approved commit/push. Local Ubuntu execution was unavailable (no WSL distribution; Docker daemon unavailable).

## Current Verification Evidence

- Python: 59 passed, 0 failed.
- Pester 5.6.1: 39 passed, 0 failed/skipped/not-run/inconclusive; 0 failed containers.
- Catalog: 9 agents / 10 prompts / 35 total / 34 adopter / 1 maintainer-only; PASS.
- Sync checker: PASS; status before/after identical.
- Gate: exit 0 on Windows local environment.
- Cross-platform status: CI matrix configured but not yet observed; do not claim Ubuntu green.
