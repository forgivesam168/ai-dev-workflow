# Specification: Trustworthy Baseline Recovery

## Acceptance Criteria

Status terms:

- Windows-local: verified on this workstation before local commit.
- Cross-platform CI: configured in workflow, but not observed until a separately approved push runs GitHub Actions.

### AC-1 Read-only sync checker

- Compares only `.github/copilot-instructions.md`, `.github/agents/**`, `.github/instructions/**`, `.github/prompts/**`, and `.github/skills/**`.
- Reports missing, extra, and content-mismatched managed files and exits nonzero on drift.
- Ignores unmanaged `.github` paths.
- Generates expected output in a temporary directory using the existing sync generator.
- Leaves `git status --porcelain=v1` unchanged.
- Windows-local status: verified.
- Cross-platform CI status: configured, not yet observed.

### AC-2 Catalog contract

- Reports 35 total, 34 adopter, and one maintainer-only `gate-check` skill separately.
- Fails clearly when a skill is added or removed without updating the reviewed contract.
- Confirms `gate-check` exists in source and is absent from the deployed mirror.
- Windows-local status: verified.
- Cross-platform CI status: configured, not yet observed.

### AC-3 Relative path identity

Python and PowerShell both satisfy:

- `.github/x` -> `.github/x`
- `./.github/x` -> `.github/x`
- `.agents/skills/x` -> `.agents/skills/x`
- `./skills/x` -> `skills/x`
- `../outside` -> `../outside`

The normalizer is not a path-traversal sanitizer.

- Windows-local status: verified.
- Cross-platform CI status: configured, not yet observed.

### AC-4 Reproducible tests

- Python bootstrap tests pass with pytest 8.3.5.
- Windows PowerShell tests pass with explicitly imported Pester 5.6.1.
- Ubuntu installer-specific differences are classified as OS_CONTRACT or TEST_PORTABILITY rather than redesigned here.
- Windows-local status: verified.
- Cross-platform CI status: configured, not yet observed.

### AC-5 Gate closure

- CI covers Windows and Ubuntu for checker, catalog, fixture tests, Python tests, normalization regression, `git diff --check`, and worktree invariance.
- `run-gate-check.ps1` installs nothing and fails with `ENVIRONMENT_PREREQUISITE_MISSING` when prerequisites are absent.
- Windows-local status: verified.
- Cross-platform CI status: configured, not yet observed.
