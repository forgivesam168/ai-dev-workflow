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

PowerShell becomes the Windows Production v3 Writer for new installs and explicit Preview-bound Migration. General v1/v2 Update does not migrate. Existing valid-v3 Update preserves Untouched/Customized/Legacy rules and creates a backup bundle. Python valid-v3 mutation remains safely blocked unless separately implemented later. Exact Product allowlist is derived from the merged Phase 4C `main` before delegating Phase 4D.

### Phase 4E

The report-only stale/retirement evidence becomes a human-readable manual Cleanup recommendation. The tool performs no Delete, Prune, Tombstone, automatic directory cleanup, or automatic rollback. If the existing Phase 4B report is already sufficient, Phase 4E may be governance/documentation-only.

## Roles, Review, and Delivery

- Sol owns governance, exact allowlists, audit, Git, PR, CI, guarded merge, and `main` synchronization; Sol does not edit Product files.
- A new unique Luna is the sole Product writer for each Phase and may edit only that Phase's exact Product/Test allowlist.
- A new independent read-only Reviewer evaluates the stable exact diff and classifies findings as Applicable blocker, Applicable non-blocking improvement, Deferred by this profile, or Out of Phase scope.
- Each Phase receives one main Luna implementation plus at most three bounded Product corrections.
- Each Phase uses its own branch, local commit, normal feature-branch push, non-Draft PR, CI proof, expected-head guarded squash merge, ff-only `main` synchronization, and retained local/remote feature branch.

Phase 4C remains incomplete until the focused/full verification, invariant Full Gate, independent review, PR CI, guarded merge, and `main` synchronization succeed. Production writers continue to emit v2 until Phase 4D is separately delivered. No real-adopter operation is authorized.
