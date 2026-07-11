# Decision Log

## 2026-07-11 — Baseline contract

- Catalog semantics are **35 total skills = 34 adopter skills + 1 maintainer-only `gate-check` skill**.
- Sync drift checking is read-only and limited to destinations managed by `sync-dotgithub.ps1`.
- Sync result and manifest paths are target-root-relative, including `.github/` when applicable.
- Existing legacy-compat files without manifest lineage remain `preserved-existing`; they are not overwritten merely to make an old test pass.
- pytest 8.3.5 and Pester 5.6.1 are direct test-runner pins, not a complete transitive lock.
- Path normalization handles representation only and is not a traversal sanitizer.
- Existing adopter manifest migration is deferred; this change does not rewrite external manifests.
- Ubuntu/GitHub Actions evidence is still pending; Windows-local green is not cross-platform green.

## 2026-07-11 — Review hardening

- Pester success requires a non-empty suite, `Result=Passed`, and zero failed, skipped, not-run, inconclusive, or failed-container results.
- Pester runs in an isolated child PowerShell process so gate strict-mode settings cannot contaminate product tests.
- Fixture fingerprints cover directories and file hashes on both clean and drift exits.
- The required invariant is exact `git status --porcelain=v1` equality; this is a status invariant, not a general content fingerprint for an already-dirty tracked file.
