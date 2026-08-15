# Phase 4 Windows-First Execution Profile

## Status and Authority

- **Status**: Approved by Amendment A-14 on 2026-07-26.
- **Purpose**: This file is the Acceptance Boundary SSOT for the remaining Phase 4 implementation tranches: Phase 4C, Phase 4D, and Phase 4E.
- **Schema boundary**: This profile does not replace or modify `schemas/ai-workflow-install-manifest-v3.schema.json`.
- **Identity boundary**: This profile does not replace or modify `manifest/component-catalog.json` or any Stable Component ID.
- **History boundary**: Amendments A-07 through A-13, OD-01 through OD-17, earlier findings, failed tests, and superseded Gate evidence remain historical evidence. Amendment A-14 changes the remaining implementation and review contract without claiming that the earlier Phase 4C candidate was delivered.

## Supported Environment

- Windows 11.
- PowerShell 7.x is the primary installer and Product writer.
- Pester 5.6.1.
- A local fixed disk with ordinary Windows paths.
- One Bootstrap or Migration operation at a time.
- A trusted single user with ordinary project read/write permission.
- No UNC or network-share target.
- No malicious concurrent process replacing files, directories, locks, or backups.
- The user reads Preview evidence before explicitly choosing whether to apply Migration.

Python retains its existing Reader, report-only, regression, Schema-validation, reference, and test-utility roles. Python is not required to become a Production v3 Writer or to have mutation parity with PowerShell in this Program. Existing Linux/macOS read/report behavior must not be deliberately broken, but Linux/macOS v3 writer and migration support are Deferred.

## Preserved Product Contract

The following requirements remain applicable:

1. The Manifest v3 data model and Production Schema remain valid.
2. Stable Component IDs and the Component Catalog remain valid.
3. Reader-first and report-only results remain valid.
4. Ownership, managed baseline, observed hash, source hash, generated relationship, lifecycle, and parse state remain represented.
5. Customized content is preserved and is never overwritten automatically.
6. Legacy or unknown ownership is never inferred from path or content similarity.
7. Missing Manifest is warning/report-only for an existing adopter and never creates false lineage.
8. Corrupt or unsupported Manifest blocks before any managed-file or Manifest write and retains its original bytes.
9. Migration is an explicit named operation, never an implicit effect of general Update.
10. Real-adopter Migration, Restore, Cleanup, deployment, or production execution requires a separate exact-target, action-specific authorization.
11. A failed operation never reports false success or records `committed` before the committed result is proven.
12. Backup and diagnostics remain available until the result is known; uncertain recovery stops for manual decision.

### Ownership Classes

- **Untouched**: May update only when a trusted Manifest contains the previous managed baseline for that exact component and the current exact bytes/hash still equal that baseline.
- **Customized**: Preserve current bytes, do not overwrite, show baseline/current/source differences, and require manual decision.
- **Legacy / Unknown**: Preserve, do not overwrite or delete, report missing lineage, and require an explicit ownership decision.
- **Corrupt / Unsupported**: Stop before writes; never treat as missing, empty, resettable, or downgradeable.

## Replaced, Deferred, and Manual Requirements

| Requirement | Windows-first disposition |
|---|---|
| Validation of exact target, root containment, traversal/absolute/UNC/drive rejection, and pre-existing ReparsePoint escape | Still applicable |
| Deterministic v1/v2-to-v3 conversion, Schema/Catalog validation, backup, post-write validation, and honest result | Still applicable |
| Customized preservation, conservative legacy ownership, corrupt/unsupported hard stop | Still applicable |
| Malicious post-validation rename, symlink, junction, inode, active-lock, or ancestor replacement | Deferred |
| Atomic compare-and-delete, POSIX descriptor-chain sandbox, `openat` / `unlinkat` proof | Out of current Windows support contract |
| Windows/Linux Production Writer parity | Deferred |
| Python/PowerShell Production mutation parity | Deferred |
| Durable `fsync`-level crash consistency | Deferred |
| Automatic Restore from untrusted or corrupt Journal | Deferred |
| Production-grade automatic recovery engine | Deferred |
| Transactional automatic Prune and Tombstone mutation | Deferred |
| Linux/macOS v3 Production Writer or Migration | Deferred |
| Uncertain Recovery, Cleanup, or Ownership decision | Manual decision |
| Real-adopter Migration, Restore, or Cleanup | Out of this Program unless separately authorized |

Missing a Deferred capability is not a Phase blocker. The same defect remains blocking when it can cause wrong-target writes, data loss, false success, Manifest corruption, loss of backup, customized overwrite, or legacy ownership inference during ordinary single-user Windows operation.

## Applicable Threat Model

The implementation must protect against:

- program defects and wrong target selection;
- writes outside the tool-created rehearsal workspace or approved exact target;
- obvious absolute, UNC, drive, traversal, filesystem-root, symlink, junction, or ReparsePoint escape present before operation;
- corrupt JSON, corrupt Manifest, unsupported schema, and wrong top-level JSON;
- ordinary file-in-use, permission, and disk-write failures;
- user or process interruption;
- ordinary repeated execution;
- customized overwrite and legacy misclassification;
- false committed/success results;
- premature backup deletion; and
- real-adopter operation without separate authorization.

The implementation does not claim protection against a malicious concurrent local process, hostile rename/junction/lock/inode replacement, kernel-level manipulation, local-administrator bypass, durable transaction semantics across crashes, or cross-platform atomic filesystem equivalence.

## Phase 4C Acceptance Boundary

### Exact Governance Allowlist

- `changes/workflow-agents-responsibility-alignment/02-decision-log.md`
- `changes/workflow-agents-responsibility-alignment/04-plan.md`
- `changes/workflow-agents-responsibility-alignment/phase-4-manifest-schema-proposal.md`
- `changes/workflow-agents-responsibility-alignment/phase-4-windows-first-execution-profile.md`

`03-spec.md`, `05-test-plan.md`, and `06-impact-analysis.md` are permitted only if a later evidence gap requires a minimal Windows-first clarification. They are not part of the initial Phase 4C diff.

### Exact Product/Test Allowlist

- `scripts/manifest_migration_rehearsal.py`
- `scripts/manifest-migration-rehearsal.ps1`
- `scripts/tests/test_manifest_migration_rehearsal.py`
- `scripts/manifest-migration-rehearsal.Tests.ps1`

Production installers, the Production Schema, Component Catalog, normal writers, generated mirrors, CI, and unrelated files are immutable in Phase 4C.

### Candidate Disposition

The seven-path dirty baseline is preserved as evidence and is not treated as delivered. The three tracked governance candidates are retained and superseded through append-only A-14/profile/status updates. The four untracked Product/Test candidates are classified as follows:

| Candidate | Disposition |
|---|---|
| `scripts/manifest_migration_rehearsal.py` | **Rewritten**: retain reusable conversion, canonical serialization, Schema/Catalog validation, backup, diagnostic, and ordinary path-safety logic; remove lock/journal/automatic-Restore machinery that exists only for the superseded hostile-concurrency or production-recovery contract. |
| `scripts/manifest-migration-rehearsal.ps1` | **Rewritten**: become the public Windows rehearsal entry point; it must not present Python as a Production migration entry point or enable normal writer behavior. |
| `scripts/tests/test_manifest_migration_rehearsal.py` | **Rewritten**: retain deterministic conversion, validation, source-invariance, backup, no-false-success, and regression coverage; remove or reclassify tests that assert only hostile-concurrency, POSIX descriptor-chain, untrusted-Journal automatic Restore, or Linux mutation parity. |
| `scripts/manifest-migration-rehearsal.Tests.ps1` | **Rewritten and expanded**: execute the supported Windows entry point and prove the Windows-first contract. |

Removed candidate code or tests are recorded as superseded by this profile, not as passed or delivered. Hostile lock replacement, hostile rename/inode races, POSIX link races, durable flush, corrupt-Journal automatic recovery, Linux mutation parity, automatic Prune, and Tombstone tests are Deferred categories and do not consume the new Phase 4C correction budget.

### Supported Rehearsal Flow

1. Accept a read-only source fixture or copied fixture.
2. Never write inside the source fixture.
3. Create a fresh, unique, empty child workspace under Windows Temp.
4. Copy the fixture into that workspace.
5. Reject unsafe source/workspace paths before reading or writing.
6. Classify v1, v2, missing, corrupt, unsupported, and wrong-top-level input.
7. Create an exact-byte Manifest backup in the temporary workspace.
8. Produce a deterministic v3 candidate.
9. Validate Production Schema, Component Catalog binding, Stable Component IDs, provenance, and canonical serialization.
10. Publish in the temporary workspace using a Windows-supported temporary-file plus replace/move sequence.
11. Reopen and validate the candidate.
12. Return `committed` only after successful reopen validation.
13. On failure, retain the temporary workspace, backup, and diagnostic; use `manual-recovery-required` when safety is uncertain.
14. Mark every result `rehearsal-only`, `no real adopter operation`, and `not execution authorization`.

The public entry point is `scripts/manifest-migration-rehearsal.ps1`. The Python helper may remain a conversion/validation/reference utility but is not a Production migration entry point and is not required to become a Production v3 Writer.

### Minimum Phase 4C Evidence

- valid v1 and v2 rehearsal;
- deterministic v3 candidate;
- source exact bytes unchanged;
- tool-created unique temporary workspace;
- rejection of a non-empty user-selected output target;
- corrupt and unsupported hard stop;
- missing report-only;
- structured wrong-top-level JSON handling;
- pre-operation obvious symlink/junction/ReparsePoint rejection;
- backup creation;
- Production Schema and Component Catalog validation;
- write/replace and post-write validation failures never report success;
- failure retains backup and diagnostic;
- normal writers still emit v2; and
- Phase 4B report-only behavior remains unchanged.

## Later Phase Boundaries

### Phase 4D

PowerShell is the Windows-first Production v3 Writer for new installs and explicit Preview-bound Migration. The actual CLI is `pwsh -File scripts/bootstrap.ps1 -TargetPath <target> -MigrationPreview` followed, only after reviewing the deterministic no-write result, by `pwsh -File scripts/bootstrap.ps1 -TargetPath <target> -ApplyMigration -ExpectedPreviewId <preview-id>`. General v1/v2 `-Update` does not migrate. Existing valid-v3 Update preserves Untouched/Customized/Legacy/Unknown/Project-owned rules and creates a backup bundle; `-Force` and `-AlwaysOverwrite` cannot bypass v3 ownership. Corrupt/Unsupported/unsafe input hard-stops before writes, Manifest publication is last, and failure retains backup/diagnostic without false success. Python valid-v3 mutation remains safely blocked; Python/Linux v3 writer work is Deferred.

#### Phase 4D Build Candidate Status — 2026-08-14

- **Status**: In progress / Build candidate. This is not Phase 4D Complete and not Awaiting Acceptance until the non-Draft PR is actually created. Phase 4 overall remains Incomplete.
- **Frozen scope**: State Matrix A–G only. No new CLI operation, prune/delete/tombstone, automatic restore, Lock/Journal/Recovery Engine, hostile-concurrency capability, Python/Linux writer, or real-adopter operation.
- **Preservation/failure boundary**: New Install emits v3; v1/v2 general Update remains report/stop; deterministic Preview is no-write and Apply binds to a recomputed Preview ID; valid-v3 Untouched alone may update; Customized/Legacy/Unknown/Project-owned/stale content is preserved/reported; corrupt/unsupported/unsafe input stops before writes; Manifest is last; backup/diagnostic remains after failure.
- **Evidence and handoff**: Existing focused evidence is Pester 5.6.1 `23 passed / 0 failed / 0 skipped`; Product/Test are unchanged in this governance pass. One Repository Full Gate follows. No real migration, restore, cleanup, deployment, or real-adopter operation was executed. Independent Acceptance belongs to a new Session.

#### Phase 4D Gate disposition — 2026-08-14

- The single Repository Full Gate failed with Python `76 passed / 12 failed` and pinned Pester `323 total / 317 passed / 6 failed / 0 skipped`; sync, Catalog, lifecycle, Change Package, Agent structure, and diff-check passed.
- The candidate is **Blocked** pending a future authorized correction session. No commit, push, PR, CI, independent acceptance, merge, auto-merge, admin bypass, branch deletion, or real-adopter operation occurred.

#### Phase 4D Triage Correction — 2026-08-16

- The prior Pester failures were attributed: Python Phase 0B is baseline environment-only; six Pester assertions were stale against the approved Phase 4D A–G contract. Only `scripts/bootstrap.Tests.ps1` was corrected.
- Minimal evidence is green: Python Phase 0B `13/13`, corrected Pester cases `6/6`, and Phase 4D focused `23/23`, all with zero skips. The final Repository Full Gate is pending and remains the only next verification action.

#### Phase 4D Final Gate — 2026-08-16

- The one Repository Full Gate returned `GATE PASSED WITH NOTES`: Python `188 passed`; Pester `323 passed / 0 failed / 0 skipped`; required sync, Catalog, lifecycle, Change Package, Agent structure, JSON/Schema/parser/compile, and diff-check passed with worktree invariant.
- Only pre-existing Agent line-count warnings remain. Product/Test are frozen after the Gate; Phase 4D remains In progress / Build candidate and is not Complete or delivered.

### Phase 4E

The report-only stale/retirement evidence becomes a human-readable manual Cleanup recommendation. The tool performs no Delete, Prune, Tombstone, automatic directory cleanup, or automatic rollback. If the existing Phase 4B report is already sufficient, Phase 4E may be governance/documentation-only.

## Roles, Review, and Delivery

- Sol owns governance, exact allowlists, audit, Git, PR, CI, guarded merge, and `main` synchronization; Sol does not edit Product files.
- A new unique Luna is the sole Product writer for each Phase and may edit only that Phase's exact Product/Test allowlist.
- A new independent read-only Reviewer evaluates the stable exact diff and classifies findings as Applicable blocker, Applicable non-blocking improvement, Deferred by this profile, or Out of Phase scope.
- Each Phase receives one main Luna implementation plus at most three bounded Product corrections.
- Each Phase uses its own branch, local commit, normal feature-branch push, non-Draft PR, CI proof, expected-head guarded squash merge, ff-only `main` synchronization, and retained local/remote feature branch.

Phase 4C is Complete / merged, with PR #14 as the authoritative merge evidence. Phase 4D is the active In progress / Build candidate and remains not Complete until its own non-Draft PR and later independent acceptance. Production writers continue to emit v2 outside the Phase 4D Windows-first scope. No real-adopter operation is authorized.
