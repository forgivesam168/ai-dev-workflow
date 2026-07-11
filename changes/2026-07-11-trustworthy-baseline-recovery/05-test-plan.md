# Test Plan: Trustworthy Baseline Recovery

## Required Commands

```powershell
pwsh -NoProfile -File .\tools\check-sync.ps1
pwsh -NoProfile -File .\tools\audit-catalog.ps1
python -m pytest .\scripts\tests\test_bootstrap.py -q -p no:cacheprovider
Invoke-Pester -Path .\scripts,.\tools -Output Detailed
pwsh -NoProfile -File .\skills\gate-check\scripts\run-gate-check.ps1
git diff --check
```

## Windows-Local Evidence

Latest observed before pre-commit audit:

| Command | Exit code | Observed result |
|---|---:|---|
| `python -m pytest .\scripts\tests\test_bootstrap.py -q -p no:cacheprovider` | 0 | 59 passed |
| `Invoke-Pester -Path .\scripts,.\tools -Output Detailed` | 0 | Total 39 / Passed 39 / Failed 0 / Skipped 0 / NotRun 0 / Inconclusive 0 / FailedContainers 0 |
| `pwsh -NoProfile -File .\tools\audit-catalog.ps1` | 0 | 9 agents / 10 prompts / 35 total / 34 adopter / 1 maintainer-only |
| `pwsh -NoProfile -File .\tools\check-sync.ps1` | 0 | Managed `.github` destinations match generated output; status invariant held |
| `pwsh -NoProfile -File .\skills\gate-check\scripts\run-gate-check.ps1` | 0 | Required gate passed; status invariant held |
| `git diff --check` | 0 | No whitespace errors |

## Fixtures

- Clean managed mirror passes.
- Changed, missing, and extra files inside managed destinations fail with path summaries.
- Unmanaged workflow, CODEOWNERS, and Dependabot files do not cause drift.
- Checker leaves the fixture and real repository status unchanged.
- Catalog passes at 35/34/1 and fails after an isolated skill addition or removal.
- Python and PowerShell share the five required normalization cases.

## Platform Expectations

- Windows is blocking for the PowerShell bootstrap suite.
- Ubuntu runs the same suite; installer-specific Windows assumptions are recorded as OS_CONTRACT or TEST_PORTABILITY if they exceed this P0 scope.
- Ubuntu/GitHub Actions matrix is configured but not yet observed. Do not claim cross-platform baseline green until that evidence exists.
