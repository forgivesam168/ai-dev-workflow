# Phase 4 — Manifest Schema Proposal

**Status: SCHEMA APPROVED — NOT IMPLEMENTED**

Approval evidence: Amendment A-07 approves OD-01 through OD-17 and the complete technical contract recorded at exact Proposal head `16aa063139431cbd07cba147d81be1d2cb3da609`. Candidate artifacts remain non-runtime evidence; the production Schema has not been created, Phase 4 product implementation is not authorized, production writers still emit v2, and no migration, prune, or real-adopter operation is authorized.

This document and its companion JSON files are decision evidence only. Production readers and writers still support the existing v1/v2 contract, and production writers still emit v2. Nothing in this proposal authorizes importing the proposed schema into runtime code, changing a gate, migrating a manifest, pruning a component, or operating on a real adopter repository.

Companion artifacts:

- `phase-4-manifest-v3.schema.proposed.json` — exact machine-readable candidate.
- `phase-4-schema-examples/valid-v1-observed.json` — synthetic but shape-faithful v1 evidence, including the observed uppercase digest and nullable directory hash forms. Its `proposal_status` is proposal-only metadata, not a v1 writer field.
- `phase-4-schema-examples/valid-v2-observed.json` — reconstruction from the current writer contract, not a runtime capture. Its `proposal_status` is proposal-only metadata, not a v2 writer field.
- The seven `v3-*.json` / `valid-v3-proposed.json` files — proposed v3 scenarios, not production fixtures. `v3-reintroduced-component.json` is a hypothetical post-authorized-reinstall snapshot, not evidence that authorization was granted or execution occurred.

## 1. Current Inventory: Facts, Inferences, and Unknowns

### Facts

The governing evidence is `02-decision-log.md` (D-05 and D-06), `03-spec.md` (especially AC-14 through AC-17), `04-plan.md` (Phase 4 inventory and boundary), `05-test-plan.md`, `06-impact-analysis.md`, the current Python and PowerShell manifest readers/writers, and the tracked `.ai-workflow-install.json`.

- Current readers recognize only `schema_version` 1 and 2. Current writers emit v2.
- The tracked v1 manifest has top-level `schema_version`, `installed_at`, `source_ref`, and `components`. Its component records contain `name`, `installed_at`, and nullable `source_hash`. It contains 58 component records: 27 with hashes and 31 with `null` hashes.
- The observed v1 digest text includes uppercase hexadecimal. Production-created v2 hashes use lowercase `sha256:` values.
- The v2 writer uses the same four top-level fields and emits component fields `name`, `installed_at`, `updated_at`, `source_hash`, `managed_hash`, `observed_hash`, `ownership`, `kind`, `source`, and `status`.
- Current readers validate only a limited envelope: top-level object, supported version, component array, component objects, non-empty names, and exact case-sensitive duplicate names. They do not fully validate version-specific shapes, hash syntax, unknown fields, traversal, normalized identity, or case-folded collisions.
- Current writers normalize separators and leading `./`, but do not establish a complete cross-platform path security boundary for `..`, reserved Windows names, aliases, or links.
- Existing hash helpers hash exact bytes. Some text is normalized before it reaches those helpers, so the byte representation being hashed is not always self-evident from a field name.
- `source_hash`, `managed_hash`, and `observed_hash` do not unambiguously preserve the four timepoints needed for safe reconciliation: prior managed baseline, pre-operation observation, newly proposed source, and committed post-operation result.
- Existing ownership vocabulary includes template-managed, project-owned, derived-runtime, and legacy compatibility concepts. Existing `kind` values include file and mount. Current status vocabulary is operational rather than a complete lifecycle model.
- Derived Agent/Skill copies are associated with canonical project sources, but the manifest cannot prove a complete derivation graph. Mount entries may have null hashes, and directories are not independently inventoried in a way that proves their contents.
- Loader outcomes are `valid`, `missing`, `corrupt`, and `unsupported`. Missing during update is warning/report-only; corrupt or unsupported is a hard stop; failure paths must not rewrite the manifest.
- v1/v2 are loaded in memory. Read-only operations do not migrate. A later successful current update can write v2.
- There is no complete persisted reconciliation state for `generated_from`, fork/customization classification, retirement, tombstones, stale detection, or prune proof.
- Python and PowerShell agree on intended manifest semantics, but currently differ in formatting, timestamp details, and write mechanics. Existing writes do not provide the full atomic publication and recovery protocol proposed here.

### Inferences

- Adding more overloaded flat fields to v2 would preserve short-term familiarity but increase the chance that the two implementations interpret nulls and transitions differently.
- A stored `prune_eligible: true` bit would become stale between observation and deletion. Eligibility should therefore be computed from immutable evidence plus a fresh precondition check, not trusted as durable authority.
- Parse state cannot reliably live only inside the manifest: a missing or corrupt document cannot truthfully describe its own parse state. It needs a loader/report envelope outside the persisted manifest payload.
- Stable component identity must be distinct from path identity; otherwise a rename looks identical to delete-plus-create and cannot carry a safe successor chain.

### Unknowns requiring approval

- The final v3 structure, strictness, identity allocation, path character policy, transaction protocol, legacy conversion rules, and safe-prune approval UX are not approved.
- No evidence currently proves that every historical v1/v2 variant can be losslessly classified as managed, customized, or project-owned.
- The Phase 3 lifecycle source contract was approved by Amendment A-06 and merged through PR #10; this proposal does not change that approved contract. Only the v3 Manifest schema and its Phase 4 implementation decisions remain unapproved here.

## 2. Goals and Non-Goals

Goals of the candidate:

- preserve four explicit hash timepoints and their byte basis;
- distinguish stable component identity from current path identity;
- bind every source release to one version-controlled canonical component catalog;
- represent canonical, generated, project-owned, compatibility, fork, retirement, and tombstone provenance without overloading one status string;
- let a future reader safely accept v1/v2 before any v3 writer is enabled;
- make dry-run, stale detection, and prune evidence deterministic and auditable;
- define Python/PowerShell parity at the semantic and serialized-byte boundaries;
- fail safely for missing, corrupt, unsupported, ambiguous, or unsafe input;
- permit atomic, recoverable publication without fabricating a committed state.

Non-goals:

- no production implementation, test/gate import, v3 write enablement, or migration in this Phase;
- no prune, delete, rename, real adopter execution, deployment, production operation, or archive filename redesign;
- no D-10 adapter implementation and no claim that a proposed `generated` record proves adapter capability;
- no automatic inference that unknown legacy content is managed;
- no authorization encoded by a CLI flag, manifest field, report, hash, self-evaluation, or tool availability.

## 3. Architecture Options and Recommendation

| Option | Shape | Complexity | Migration and rollback | Human readability | Python/PowerShell parity |
|---|---|---|---|---|---|
| A. Flat v2 extension | Add more nullable fields to each existing component | Lowest initial code change; highest semantic coupling as fields interact | Easy to append, hard to prove which combinations are valid; rollback risks losing overloaded meaning | Familiar but null-heavy and ambiguous | Many combination rules would live outside schema and can drift |
| B. Structured v3 manifest | Separate `identity`, `provenance`, `hashes`, `lifecycle`, and `last_operation` | Moderate, explicit validation and conversion work | Reader-first compatibility and one-way writer enablement are clear; prior bytes remain recoverable | More verbose, but every value has one role | Shared JSON Schema plus semantic vectors make parity testable |
| C. Event log plus materialized manifest | Append immutable events and derive current state | Highest operational and recovery complexity | Strong audit history, but requires event versioning, compaction, replay, and two implementations | Excellent audit trail; poor direct inspection of current state without tooling | Replay ordering and crash recovery are large cross-runtime surfaces |

Recommendation: Option B, the structured v3 manifest. It is the smallest design that resolves the known four-timepoint, provenance, lifecycle, and parity ambiguities without introducing an event-sourcing subsystem. Option A cannot express safe state combinations cleanly. Option C may be justified for a future audit product, but is disproportionate to an installer manifest.

The recommendation is still a proposal. Approval of this document must identify the accepted choices in Section 18 before implementation planning starts.

## 4. Exact Candidate Schema Contract

The exact candidate is `phase-4-manifest-v3.schema.proposed.json`, using JSON Schema Draft 2020-12. Every machine example deliberately includes `proposal_status: "PROPOSED — NOT APPROVED — NOT IMPLEMENTED"` so it cannot be mistaken for current production evidence. In the v1/v2 examples this is extra proposal-only metadata accepted by the current permissive top-level readers; it is not an observed legacy field and is not emitted by either legacy writer.

Top-level contract:

| Field | Candidate meaning |
|---|---|
| `schema_version` | Integer constant `3` |
| `written_at` | UTC `Z` timestamp for the committed serialized document |
| `source_release` | `{release_id, source_ref, version, component_catalog}` identifying the candidate source set and exact catalog bytes |
| `last_transaction` | The most recent transaction that successfully committed the complete Manifest, including writer runtime and start/end times |
| `components` | Component records sorted by stable `identity.id` |

Component contract:

| Object | Required meaning |
|---|---|
| `identity` | Stable `id`, logical `path`, lowercase collision key, kind, role, and optional link target |
| `provenance` | Ownership, source locator/release, `generated_from` edges, and fork classification |
| `hashes` | Exact-byte SHA-256 values for baseline, observed-before, proposed-source, and result-after |
| `lifecycle` | Active/retired/tombstoned state, prior paths, and retirement evidence |
| `last_operation` | The last operation that affected this component; its transaction reference may be older than the Manifest's `last_transaction` |
| `installed_at`, `updated_at` | First known installation time (nullable for imported unknowns) and latest committed classification time |

Top-level `last_transaction` and component `last_operation` have intentionally different scopes. `last_transaction` identifies only the most recent successful commit of the complete Manifest. Each component's `last_operation` identifies the operation that most recently affected that component, so unchanged historical components do not have their references rewritten and their transaction IDs are not required to equal the top-level ID. A terminal tombstone retains the transaction reference for the operation that created that tombstone even when a later Manifest transaction adds another component. Future semantic validators must not treat that inequality as an error. The transaction ID is an auditable reference to bounded external journal/audit evidence when destructive proof is required; the Manifest does not embed an event log or unbounded transaction history.

The schema rejects unknown object properties, malformed lowercase v3 hashes, unsafe logical path syntax, incompatible role/ownership combinations, active records with retirement data, and tombstones with a remaining result hash. Semantic validation, which JSON Schema cannot fully express, must additionally reject duplicate IDs, duplicate active path keys, invalid tombstone/active path-key pairing, unsorted records, unresolved component/catalog references, source-kind/locator mismatches, invalid timestamp ordering, path-key mismatch, Windows aliases/reserved names, and link targets escaping the adopter root.

JSON object member order is not semantic. Canonical writer output should nevertheless use a fixed property order, UTF-8 without BOM, LF, two-space indentation, and exactly one final newline so Python and PowerShell can produce byte-identical golden output.

### Candidate-to-production schema artifact contract

The Change Package candidate deliberately retains its proposal marker, proposal wording, and non-production `$id` under `https://example.invalid/`. It is design evidence only and must never become a runtime import or dependency.

If the schema is later approved, a separately authorized implementation creates the production artifact at `schemas/ai-workflow-install-manifest-v3.schema.json` with Draft 2020-12 and stable `$id` `urn:ai-dev-workflow:manifest-schema:v3`. Schema approval alone does not create that artifact, change a reader, enable a writer, migrate a manifest, or authorize any runtime behavior. The implementation removes `proposal_status` from top-level `required` and `properties`, removes proposal-only title/description wording, replaces the candidate identity with the stable production `$id`, and preserves every approved structural validation rule.

Candidate-to-production validation is deterministic: parse both schemas; remove only the top-level `proposal_status` property/requirement; apply only the canonical `$id`/title/description substitutions; canonicalize both JSON objects; require deep equality; then run equivalent positive/negative vectors against each. Any other schema diff is blocking. The production reader must not import the Change Package candidate. Python and PowerShell must either consume the production artifact or prove identical behavior from the same versioned vectors.

Each production positive vector is derived from its candidate example by removing only the top-level `proposal_status`; every other scenario field and value remains unchanged. Candidate validation uses the marked example, while production validation uses that marker-free derived representation. For every negative vector, apply the same semantic mutation to both representations after performing only that marker derivation for the production copy. This prevents the invalid comparison of a proposal-marked candidate example directly against the production schema while preserving identical behavioral coverage.

The production schema artifact revision/digest is release metadata and is separate from manifest `schema_version: 3`; revising descriptions or validator packaging must not silently create a new manifest format. Reader support for v3 remains distinct from writer enablement. Until writer enablement is separately approved, production writers continue to emit v2.

## 5. Component Identity and Path Model

`identity.id` is the durable identity; `identity.path` is the current repository-relative logical location. A rename keeps the ID and moves the old normalized path into `lifecycle.previous_paths`. IDs must not be derived solely from the path.

The canonical source-side identity SSOT is fixed at the version-controlled path `manifest/component-catalog.json`; its location is not deferred to implementation. The proposed catalog top level contains at least:

| Field | Exact contract |
|---|---|
| `catalog_schema_version` | Integer `1`, versioning the catalog shape independently |
| `catalog_version` | Non-empty immutable release-scoped catalog revision |
| `source_release` | The catalog's `{release_id, source_ref, version}` |
| `components` | Records sorted by stable component ID |

Every catalog component contains at least:

| Field | Exact contract |
|---|---|
| `id` | Stable `cmp:` ID |
| `canonical_source_path` | Normalized canonical source-side path |
| `role`, `kind` | The same role/kind vocabulary enforced by the Manifest schema |
| `lifecycle_status` | `active`, `retired`, or `tombstoned` source identity state |
| `previous_paths` | Sorted, duplicate-free normalized prior source paths |
| `generated_from` | Sorted, duplicate-free parent component IDs |
| `successor_component_id` | Nullable rename/supersession relationship |
| `reintroduces_component_id` | Nullable relationship from a new identity to a permanently tombstoned identity |
| `introduced_release` | Release ID that first allocated this identity |
| `retired_release` | Optional/nullable release ID that retired the identity |

Allocation and validation rules are fixed:

1. Every template-managed and derived-runtime identity is allocated by this catalog.
2. Python and PowerShell read the same catalog bytes and catalog schema/version; neither has a private identity table.
3. Readers/writers never derive IDs from path hashes, paths, timestamps, adopter content, or runtime-specific generators.
4. A canonical rename retains the same ID and appends the prior path; it does not allocate a replacement merely because the path changed.
5. Retired and tombstoned IDs are permanently reserved and never reused.
6. A genuinely new component and an authorized reintroduction each receive a new ID; reintroduction points to the old tombstone.
7. Duplicate IDs, duplicate active path keys, unknown parents, relationship cycles, self-reference, and illegal ID reuse are blocking catalog errors.
8. Ambiguous v1/v2 paths or lineage are never guessed into an ID; they remain legacy/unknown and report-only until an approved mapping exists.
9. Every catalog source change is version-controlled, reviewed, and subject to sync/catalog validation against both runtimes and generated mirrors.
10. The catalog is evidence, not migration, overwrite, prune, reinstall, or other protected-action authorization, and it is never reverse-generated from adopter content.

Every v3 `source_release.component_catalog` binds `{path: "manifest/component-catalog.json", schema_version: 1, sha256: <lowercase exact-byte SHA-256>}`. Semantic validation requires the digest to match the release's catalog bytes and every Manifest identity, role, kind, lifecycle, source path, `generated_from`, successor, and reintroduction relationship to agree with that bound catalog.

Paths use `/`, are relative to the adopter root, and contain no empty, `.` or `..` segment, backslash, drive prefix, UNC prefix, or alternate-data-stream separator. The candidate restricts path text to a conservative ASCII set. `path_key` is the ASCII-lowercase normalized path. Duplicate active path keys are blocking on every operating system, including Linux, so Windows and Ubuntu cannot accept different active inventories. A single tombstoned record and a new active record may share a path key only when the new record explicitly reintroduces that tombstone and the old tombstoned target is not materialized; two active records or an unrelated collision remain blocking.

For `mount` or `link`, `identity.link.target_path` is also root-relative. It records the logical target and materialization mode (`symlink`, `junction`, or `copy-fallback`) rather than raw host-specific link text. Readers must inspect without following a target outside the adopter root.

## 6. Four-Timepoint Hash Semantics

Every hash is either `null` because the relevant bytes do not exist/cannot be proven, or lowercase `sha256:` plus 64 hexadecimal characters. v3 hashes always cover exact bytes. A producer that performs text normalization must perform it before the hash boundary and must hash the exact bytes it proposes to write.

| Field | Timepoint | Meaning |
|---|---|---|
| `baseline` | Prior committed transaction | Last exact bytes that the workflow proved it managed for this component |
| `observed_before` | Immediately before the current decision | Exact bytes found at the target before any mutation |
| `proposed_source` | Current source release | Exact bytes the current source would materialize; `null` when the source retires the component |
| `result_after` | After the committed transaction | Exact bytes observed after publication; `null` when verified absent or when the component kind has no approved single-byte hash, and required to be null for a committed tombstone |

Nullability is evidence-specific, not a wildcard. A missing target has `observed_before: null`; a successful install then has a non-null `result_after`, while a verified authorized prune has `result_after: null` and persists a tombstone. A retired source has `proposed_source: null`. A failed, blocked, or dry-run operation does not publish a new `result_after` at all. A directory, mount, or link may use null hash timepoints only when the approved hashing contract defines no single content byte stream for that kind; a regular file with observed bytes must not use null to avoid comparison. A null `baseline` means lineage is unproven, so it can never establish `untouched`, equality, or prune eligibility. Null directory/mount/link hashes never prove tree or target safety; destructive action requires separately validated child inventory, target containment, and exact preconditions.

Core reconciliation truth table:

| Evidence | Classification | Allowed default |
|---|---|---|
| `observed_before == baseline`, source still active | Untouched managed | Install/update may proceed; verify `result_after == proposed_source` |
| `observed_before != baseline` with both known | `customized` for canonical or `derived-customized` for generated | Preserve; report divergence; never overwrite/prune automatically |
| Baseline or observation is unavailable | `unknown`, `legacy`, or `not-applicable` when the kind has no approved byte hash | Report-only; no destructive action |
| Project ownership is explicit | Project-owned | Preserve regardless of hash equality |
| Source is retired and `observed_before == baseline` | Stale, potentially pruneable | Report only until all Section 14 gates and fresh rehash pass |
| Source is retired and observation diverges | Stale but modified | Preserve; never mark pruneable |

Hash equality proves byte equality only; it does not prove authorization, ownership, source authenticity, semantic safety, or that a deletion remains safe at execution time.

## 7. Provenance and Derivation

`provenance.ownership` uses five explicit classes: `template-managed`, `project-owned`, `derived-runtime`, `legacy-compat`, and `unknown`. `provenance.source` records a typed logical locator plus the release that supplied or classified it; it must not contain local absolute paths, user names, credentials, or token-bearing URLs.

`generated_from` is semantically a set of stable component IDs; a canonical writer emits it sorted and duplicate-free. A `generated` role requires `derived-runtime` ownership and at least one resolvable parent. A `canonical` role requires `template-managed` ownership and no parent. A project-owned component cannot become managed merely because its bytes happen to equal template bytes.

Derivation evidence answers “what source records produced this record,” not “which runtime can consume it.” In particular, an example generated mirror is not evidence for D-10 adapter support.

Directories or mounts with no single meaningful content blob may have null hash timepoints, but their provenance and target relationship still require validation. A future implementation must not synthesize directory safety from a null hash; child inventory or a separately approved tree-digest model would be needed for destructive action.

## 8. Fork and Customization Classification

`provenance.fork` keeps classification separate from ownership and lifecycle. The following eight mappings are exhaustive and machine-testable; a status/basis/decision combination outside this table is invalid:

| `status` | Required `basis` | Required `decision` | Meaning |
|---|---|---|---|
| `untouched` | `verified-managed-equality` | `manage` | Managed baseline and observed bytes are known and equal |
| `customized` | `hash-divergence` | `preserve` | A canonical/template-managed target diverged from its baseline |
| `project-owned` | `explicit-project-ownership` | `preserve` | Project policy explicitly owns the target |
| `legacy` | `legacy-import` | `report-only` | v1/v2 evidence cannot support a stronger classification |
| `unknown` | `missing-lineage` | `report-only` | Required lineage or observation evidence is missing |
| `derived-customized` | `derived-hash-divergence` | `preserve` | A derived-runtime target diverged from its derived baseline |
| `conflicted` | `conflicting-evidence` | `block` | Two or more material ownership, identity, source, or hash facts conflict |
| `not-applicable` | `hash-not-applicable` | `report-only` | This component kind has no approved single-byte hash comparison |

`none` is not a valid synonym for `untouched`. `derived-customized` remains distinct from canonical `customized` so a derived mirror cannot hide local modifications behind a generic managed status. `conflicted` is deterministically blocking, while `not-applicable` cannot be promoted to managed equality or prune eligibility.

Classification is evidence-based and timestamped. `result_after` for a preserved customization must equal the pre-operation observation. No writer may “heal” a customization by changing the baseline to the customized bytes, because that would launder project edits into managed ownership.

An explicit, separately approved adoption operation could later convert a fork class, but this proposal neither designs nor authorizes that operation.

## 9. Retirement, Rename, and Tombstone Model

Persisted source lifecycle has exactly three states. `active` means the source still intends the component. `retired` means a source retirement/rename/delete fact has been recorded but adopter bytes remain present. `tombstoned` means a separately authorized prune transaction removed the target and committed `result_after: null` plus `pruned_at`.

Retirement evidence is typed as a rename map, component absence in a named source release, or an explicit release retirement record. A rename preserves the component ID, records prior paths, and may point to a successor component. A missing file in a working checkout is not by itself authoritative retirement evidence.

Lifecycle, computed report states, and operation results are deliberately separate:

| Term | Persisted where? | Required evidence | Allowed action |
|---|---|---|---|
| `active` | `lifecycle.state` | Stable ID is present in the approved source release | Manage only according to fork/ownership evidence; otherwise preserve/report/block |
| `retired` | `lifecycle.state` | Typed rename/delete/source-retirement evidence; target still present | Report/preserve; prune can only be proposed after independent eligibility checks |
| `tombstoned` | `lifecycle.state` | Task-authorized prune completed, target absence verified, `pruned_at` and journal result committed | Terminal for that ID; retain audit evidence and never transition it to active/retired |
| `stale-detected` | Computed report state, never lifecycle authority | Persisted retirement plus an adopter target still present | Report only and evaluate customization/eligibility |
| `prune-eligible` | Computed report field only, never persisted authority | Every D-05/AC-17 proof currently passes, including unchanged bytes and exact retirement evidence | Propose exact component selection; still requires external current-task approval and execution-time revalidation |
| `preserved-customization` | Operation/report result; may be the persisted `last_operation.outcome`, not lifecycle | Canonical or derived hash divergence with preserved pre-operation bytes | Preserve and report; never overwrite or prune automatically |
| `pruned` | Successful operation/report result; persisted lifecycle becomes `tombstoned` and `last_operation.outcome` becomes `tombstoned` | Authorized deletion, verified absence, atomic commit | Record tombstone and audit result only after success |

Lifecycle state is evidence, not an instruction. `retired` never authorizes deletion. `tombstoned` may only be written after deletion, fresh absence verification, atomic manifest commit, and all Section 14 requirements. Customized, derived-customized, project-owned, unknown, legacy, conflicted, and not-applicable records cannot be treated as automatically pruneable.

Tombstone identity is permanent audit identity. A tombstoned component ID can never transition back to `active` or `retired`, can never be reused, and keeps its lifecycle, `pruned_at`, retirement evidence, hashes, and `last_operation` unchanged.

If its source reappears, the default result is report-only: do not restore, recreate, overwrite, remove the tombstone, or materialize a target. A future reinstall requires separate explicit, current-task, action-specific authorization. After that authorized reinstall succeeds, the active component has a brand-new ID and sets `lifecycle.reintroduces_component_id` to the old tombstoned ID; every persisted field of the old tombstone component remains unchanged. The complete Manifest may be reserialized because it now has a new top-level transaction and component, so no claim is made that the old component's raw JSON byte slice is preserved. This relationship is not `generated_from`, is not a rename `successor_component_id`, and never constitutes authorization.

Future semantic validators treat the following as hard failures: self-reference; a missing or non-tombstoned reintroduction target; a relationship cycle; reuse or mutation of the old ID; a reintroduction field on a retired/tombstoned record; two active records with the same path key; or a tombstone/active same-path pair without the exact reintroduction link and verified absence of the tombstoned materialized target. Draft 2020-12 cannot express these cross-record conditions, so the candidate schema supplies the structural property and comments while the Proposal fixes the required semantics.

`v3-reintroduced-component.json` retains the old terminal tombstone and its historical `last_operation`, adds a different active ID linked through `reintroduces_component_id`, and binds the source catalog containing both identities. It is a hypothetical post-authorized-reinstall snapshot only. Source reappearance itself still produces a report, and the example/report/schema does not supply the separate authorization required for actual reinstall.

## 10. Persisted State Versus Loader/Operation Outcomes

Persisted manifest state contains only the last successfully committed source, component, lifecycle, and transaction facts. It must not claim a failed or interrupted operation committed.

The loader/report envelope, outside the manifest payload, uses `manifest_parse_state`:

- `valid-v1`, `valid-v2`, or `valid-v3` after complete structural and semantic validation;
- `missing`, which is warning/report-only for update and causes no implicit migration or reset;
- `corrupt`, which is blocking and causes zero writes;
- `unsupported`, which is blocking and causes zero writes.

Operation reports separately distinguish `dry-run`, `blocked`, `interrupted-before-commit`, `committed`, and `recovery-required`. This separation is necessary because a corrupt manifest cannot safely be edited to say that it was corrupt, and a dry-run cannot truthfully append a transaction to production state.

## 11. v1/v2/Legacy Compatibility State Machine

| Input state | Reader result | Mutation allowed by default | Next persisted state |
|---|---|---|---|
| Missing | Warning plus report | None during read/update planning; initial-install behavior remains current until separately changed | Missing |
| Valid v1 | Load legacy fields in memory; preserve original bytes | No read-time migration | v1 |
| Valid v2 | Load v2 fields in memory; preserve original bytes | No read-time migration | v2 |
| Valid v3 | Only after reader support is separately approved; validate schema and semantics | No mutation merely because it parsed | v3 |
| Corrupt any version | Blocking diagnostic | Zero writes, deletes, or reset | Original bytes unchanged |
| Unsupported version | Blocking diagnostic | Zero writes, deletes, or downgrade | Original bytes unchanged |
| Safe operation later succeeds while production writers are still v2 | Current behavior only | Existing approved v2 write path | v2 |
| Future explicitly approved v3 migration succeeds | Convert through a reviewed mapping, publish atomically, retain recovery evidence | Only within that task-specific authorization | v3 |

Legacy uppercase SHA-256 text may be accepted by the v1 compatibility reader and normalized only in memory. It must not cause a read-only rewrite. Unsafe paths, duplicates after normalization, ambiguous ownership, or lossy field combinations are blocking for mutation and remain report-only evidence; they must not be silently upgraded to managed v3 records.

Downgrade from v3 to v2 is not proposed because v2 cannot losslessly encode the four hashes, stable IDs, provenance graph, or lifecycle evidence. Rollback restores the prior complete manifest bytes rather than serializing a lossy v2 approximation.

## 12. Reader-First, Writer-Later Rollout

Recommended sequence, each requiring its own approval:

1. Freeze the approved schema and shared semantic vectors.
2. Implement read-only v3 parsing in Python and PowerShell behind no write-path change. Keep writers at v2.
3. Prove v1/v2 behavior preservation, malformed/unsupported zero-write behavior, normalized identity rejection, and cross-runtime parity.
4. Add a deterministic conversion planner that emits reports only. Do not write v3.
5. Rehearse conversion against synthetic and copied fixtures with byte-for-byte rollback evidence.
6. Enable a v3 writer only under a separately approved migration/update operation with atomic publication and recovery.
7. Consider safe prune only after lifecycle evidence and task-scoped authorization are independently proven.

Reader support must not auto-enable writer support. Schema recognition, conversion planning, v3 publication, and prune are four distinct capabilities and four distinct authorization boundaries.

## 13. Deterministic No-Write Dry-Run Contract

A dry-run snapshots the manifest digest, source release ID, normalized component inventory, pre-operation file hashes, and requested operation. Its canonical decision body contains these exact fields:

- `plan_identity`: report contract version, tool version, requested operation, input manifest digest, source release ID, selected component IDs, and a digest of the normalized input snapshot;
- `report_identity`: deterministic report ID derived from the canonical decision-body digest; the digest itself is carried beside the hashed body to avoid self-reference;
- `component_identity`: stable ID, normalized path/path key, kind, and role;
- `ownership`: explicit ownership class;
- `observed_hash`, `baseline`, and `proposed_source_hash` as separate values;
- `source` and sorted, duplicate-free `generated_from` provenance;
- `classification`: fork status/basis/decision plus persisted lifecycle state;
- `stale_or_retirement_reason`: typed source evidence or explicit `not-stale`;
- `proposed_action`: one of preserve, report, block, install, update, retire, or exact-component prune proposal;
- `eligibility`: `eligible` boolean, computation version, and an explicit `not_authority: true` marker;
- `blocking_proofs`: one entry for every required proof, each with proof ID, pass/fail/unknown state, and evidence reference; a missing/unknown proof is blocking;
- `required_approval`: protected action, exact component scope, required current-task authorization state, and approval reference when one actually exists; the report itself never supplies approval;
- `no_write_confirmation`: `writes_performed: false` plus pre/post manifest digest, selected-target hashes, and inventory comparison proving the dry-run did not mutate the adopter repository.

The canonical decision body is sorted first by stable component ID and then by proof ID, serialized with the same canonical JSON rules as Section 4, and hashed without volatile values. With identical input bytes, source release, requested component set, and tool version, Python and PowerShell must produce the same semantic report and canonical report hash. Wall-clock display time, host presentation, and human-readable formatting belong in a volatile non-hashed envelope.

Default dry-run output is stdout. Unless the user explicitly chooses a report path, it writes no adopter-repository file, manifest, backup, lock, journal, generated mirror, or source file. It never changes lifecycle state, never records `last_transaction`, and never treats a report as execution authorization.

A dry-run report becomes invalid for execution if the manifest digest, source release, selected component set, normalized target identity, or any observed hash changes. Execution must recompute these preconditions.

## 14. Safe-Prune UX Options and Recommendation

All options share non-negotiable rules from D-05 and AC-16/AC-17: detect → dry-run → report; require managed/generated proof, unchanged bytes, source retirement/rename evidence, and explicit current-task authorization; never automatically delete customized, project-owned, unknown, or legacy content.

| Option | UX | Benefits | Risks |
|---|---|---|---|
| A. Exact component selection plus report hash | User authorizes named component IDs against a canonical dry-run report hash | Narrow, auditable, automation-friendly, strong TOCTOU preconditions | More verbose approval and a second command |
| B. Reviewed prune-plan file | Tool writes a plan; user supplies the exact reviewed plan path/digest to execution | Easy to archive and review in teams | The file can be mistaken for authorization; requires safe storage and freshness checks |
| C. Interactive per-component confirmation | Tool prompts for every candidate immediately before deletion | Visible local intent | Weak for non-interactive agents/CI, difficult to audit, prompt acceptance may be ambiguous |

Recommendation: Option A. The execution request must name exact component IDs, the exact dry-run report identity/hash, and an external explicit, current-task, action-specific approval reference. `--prune`, `--yes`, a manifest state, a report, or agent/tool identity is never authorization by itself. There is no `--prune-all` mode.

Before the first deletion, perform an all-selected preflight: bind the exact report identity/hash and approval reference, verify every selected ID is still retired and `untouched`, re-prove ownership/generated lineage and retirement evidence, re-resolve every root-contained target without following an escape, rehash current bytes, prove no selected/unselected path collision, and prepare journal/backup recovery for the whole selection. Modified/derived-customized, project-owned, legacy, unknown, conflicted, and not-applicable records are refused. Any failed or unknown proof aborts before mutation.

Immediately before each deletion, repeat the target-specific identity, containment, and TOCTOU hash checks. Delete only the exact selected file/link; remove a directory only if it is itself explicitly selected, proven workflow-managed, and empty after selected child operations. After deletion, verify absence before recording a successful result.

If a failure occurs after deletion has begun, stop all subsequent selected actions and use the journal/backups to roll back every completed mutation. If complete rollback cannot be proven, return `recovery-required`, preserve the report, approval reference, journal, backups, and error evidence, and do not commit false tombstones or a successful transaction. Audit evidence must include selected component IDs, report identity/hash, approval reference, pre/post hashes, attempted action per component, observed result, rollback result, and final recovery state.

## 15. Atomicity, Concurrency, Crash Recovery, and Rollback

Recommended publication protocol:

1. Acquire a repository-scoped manifest lock without stealing an active lock.
2. Read and retain the exact previous manifest bytes and digest; validate complete input state.
3. Stage component writes and a recovery journal inside the adopter root on the same filesystem. No production manifest claim is changed yet.
4. Verify staged exact-byte hashes and all expected preconditions.
5. Publish component changes using same-filesystem atomic replacement where supported, recording enough journal state to restore prior bytes.
6. Serialize the complete manifest canonically to an exclusive temporary file in the manifest directory; flush file data, then atomically replace the manifest, then flush directory metadata where the platform supports it.
7. Re-open and validate the committed manifest and result hashes before marking the operation successful and removing recoverable journal material.

Windows and Ubuntu implementations must expose equivalent success/failure semantics even where primitives differ. If atomic replacement, durable flush, lock acquisition, or rollback storage cannot be established, the operation blocks before mutation. A crash before manifest replacement preserves the prior manifest and invokes recovery from journaled component backups; a crash after replacement requires validation against the committed transaction ID and result hashes.

No implementation may truncate the live manifest in place, silently discard a corrupt/unsupported manifest, claim `committed` before publication, or downgrade v3 to v2 for rollback. Recovery/rollback restores the exact prior bytes and verifies both the manifest digest and affected component hashes.

## 16. Security, Privacy, and Authorization Boundaries

- Treat every manifest and source-release value as untrusted input. Enforce size/count limits before expensive processing.
- Reject traversal, absolute/UNC/drive paths, backslashes, alternate data streams, Windows reserved device names, trailing-dot/space aliases, case collisions, root escapes, and link cycles before any mutation.
- Resolve targets relative to an already established adopter root. Never accept a manifest-provided absolute root.
- Do not follow links during hashing/deletion unless the selected component kind and validated logical target explicitly require it. Never cross filesystem/repository ownership boundaries silently.
- Do not store credentials, tokens, user home paths, machine names, PII, or raw environment values. Redact suspicious source refs and diagnostics before remote delivery.
- SHA-256 is an integrity comparison, not source authentication or authorization. Source releases need a separately approved trust mechanism if authenticity is required.
- Commit, push, merge, migration, prune, deployment, production operation, and other protected actions each require explicit, current-task, action-specific authorization. One action never implies another.
- Deterministic test/build/static/security/data-integrity failures block delivery. Self-evaluation cannot replace independent review or override a failing gate.

## 17. Required Test and Evidence Matrix Before Any Implementation Is Complete

| Area | Minimum cases | Required evidence |
|---|---|---|
| Valid versions | Valid v1 with uppercase/null hashes; valid writer-derived v2 with `template:` source; valid v3 | Same accept/normalize-without-write result in Python and PowerShell; original legacy bytes unchanged |
| Parse outcomes | Missing manifest; corrupt JSON; unsupported version | Missing is warning/report-only; corrupt/unsupported are blocking; all prove zero repository writes |
| Schema rejection | Duplicate component identity ID; duplicate normalized path identity; invalid enum; invalid/uppercase v3 hash; missing/extra/wrong-type field | Same reject vector and diagnostic class in Python and PowerShell |
| Identity security | Traversal; absolute/drive/UNC path; backslash; Windows reserved/alias path; case collision; long path; escaping/cyclic link | Windows and Ubuntu parity with zero writes |
| Component catalog | Valid exact-byte binding; wrong/missing digest; duplicate ID; duplicate active path key; unknown parent; generated/source cycle; self-reference; retired/tombstoned ID reuse; ambiguous v1/v2 mapping | Both runtimes read `manifest/component-catalog.json`; every invalid catalog is blocking and produces zero writes |
| Hash semantics | Missing target; all relevant four-timepoint equal/different/null combinations; null-baseline; no-single-byte-stream kind | Exact-byte golden vectors; no null value infers untouched or prune safety |
| Classification | Untouched managed; customized canonical; project-owned; derived runtime; modified derived (`derived-customized`); legacy; unknown; conflicted; not-applicable | All eight status/basis/decision mappings enforced; no ownership laundering |
| Provenance graph | Valid canonical/generated graph; missing parent; duplicate parent; cycle; source-kind mismatch | Unresolved or conflicting graph blocks mutation |
| Canonical lifecycle | Canonical rename preserving stable ID; canonical delete; source retirement; retired source reappears; tombstone retention; attempted tombstone transition/ID reuse | Tombstone ID/evidence remain terminal; reappearance reports only and never auto-restores/overwrites |
| Reintroduction | Valid old tombstone + distinct new active ID/link; self-reference; missing/non-tombstone target; cycle; mutated old evidence; duplicate active path; unrelated tombstone/active path collision | Only the valid relationship is accepted, and only after separate reinstall authorization; no relationship grants authority |
| Stale lifecycle | Unmodified stale target; modified stale canonical target; modified stale derived target | Only unmodified/evidence-complete target can be reported as computed prune-eligible; modified targets preserved |
| Dry-run | Repeat identical inputs; volatile timestamp separation; changed manifest/source/file after report | Identical canonical report hashes; stale report rejection; no-write inventory/hash proof |
| Prune authorization | Prune without approval; prune missing each individual proof; exact approved prune proposal; no-prune-all; CLI flag without external authorization | Zero delete for missing approval/proof; approved case binds exact IDs/report hash/approval reference and revalidates TOCTOU |
| Prune target safety | Unselected sibling; non-empty directory; link escape; modified/unknown/legacy target; TOCTOU change | Whole-selection preflight blocks before deletion; false tombstone never commits |
| Atomicity/recovery | Interrupted migration; atomic write failure before stage, mid-component publish, before manifest replace, after replace, during flush; competing lock; rollback failure | Exact prior-byte restoration or explicit recovery-required with preserved journal/evidence; no partial silent success |
| Serialization | UTF-8/LF/final newline/property order/component sort/timestamp precision | Byte-identical Python/PowerShell golden manifests and reports |
| Candidate/production schema | Candidate production misuse/import; deterministic allowlisted transformation; unexpected structural diff; wrong production path/`$id`; artifact revision independent from manifest version | Runtime imports only `schemas/ai-workflow-install-manifest-v3.schema.json`; transformed structures/vectors are identical or blocking |
| Runtime/platform parity | Every preceding vector in Python and PowerShell on Windows and Ubuntu | Same semantic result, diagnostics class, canonical bytes/report hash, and write/no-write inventory |
| Repository integration | Targeted tests, relevant full tests, sync/catalog/static checks, full repository gate, worktree invariance | All deterministic gates green; no generated drift or scope leakage |
| Independent review | Correctness, security, path/link handling, recovery, migration, authorization, parity | No unresolved Critical/High finding before delivery |

Scenario files in this proposal cover observed v1, writer-derived v2, a valid v3 candidate, customization, derivation, retirement, stale-but-modified, and a proposed prune candidate. They are design inputs, not evidence that runtime tests already exist or pass.

## 18. Centralized Approved Decisions

OD-01 through OD-17 are approved by Amendment A-07 as the internally consistent Manifest v3 Schema Design recorded at exact Proposal head `16aa063139431cbd07cba147d81be1d2cb3da609`. This approval does not make the Candidate artifacts runtime dependencies or authorize implementation or execution.

| ID | Decision | Recommendation | Alternatives and trade-off |
|---|---|---|---|
| OD-01 | Manifest architecture | Structured v3 (Option B) | Flat extension is initially cheaper but ambiguous; event log is stronger auditability but disproportionate complexity |
| OD-02 | Exact production schema artifact | If later approved, create Draft 2020-12 `schemas/ai-workflow-install-manifest-v3.schema.json` with `$id` `urn:ai-dev-workflow:manifest-schema:v3` through the allowlisted deterministic transformation/diff contract in Section 4; candidate remains non-runtime | Importing the Change Package candidate conflates proposal and runtime; hand-coded-only validators reduce portability; any broader transform hides structural drift |
| OD-03 | Stable identity allocation and catalog SSOT | Version-controlled `manifest/component-catalog.json` with catalog schema version 1, exact release digest binding, and all ten allocation rules in Section 5 | Path/random/runtime-generated IDs break rename/reuse/parity guarantees; adopter-derived catalogs can launder ambiguous ownership |
| OD-04 | Path character/collision policy | Conservative ASCII paths plus global ASCII-lower collision keys | Unicode NFC/case-fold supports more names but has cross-runtime/platform edge cases requiring a larger proof set |
| OD-05 | Hash model | Four exact-byte SHA-256 timepoints with lowercase v3 encoding | Three overloaded hashes preserve compatibility but cannot prove before/source/after; tree hashes need a separate directory design |
| OD-06 | Provenance/fork model | Structured ownership, typed source, derivation edges, and the exhaustive eight-state status/basis/decision mapping in Section 8 | A smaller status set is shorter but conflates untouched, canonical customization, derived customization, conflict, and non-hashable kinds |
| OD-07 | Lifecycle/reintroduction model | Tombstone is terminal and permanently reserves its ID; source reappearance reports only; a separately authorized reinstall allocates a new active ID linked by `reintroduces_component_id` while preserving the old tombstone | Reactivating/reusing the old ID destroys audit identity; automatic restore turns source presence into unauthorized mutation; persisted eligibility becomes stale authority |
| OD-08 | Parse-state location | Loader/report envelope, not self-reported inside the manifest | Persisting it inside the payload fails for missing/corrupt inputs and risks rewriting evidence |
| OD-09 | Legacy policy | Reader-first v1/v2 compatibility; no read-time migration; ambiguous records remain report-only | Eager migration simplifies later code but can destroy evidence and has no safe inference for all records |
| OD-10 | Writer enablement | Separate approval after dual-runtime reader/parity proof and migration rehearsal | Enabling reader/writer together shortens rollout but increases rollback and compatibility risk |
| OD-11 | Dry-run format | Canonical deterministic decision body with report hash; volatile display envelope excluded | Hashing timestamps makes reports non-repeatable; omitting a digest weakens freshness binding |
| OD-12 | Safe-prune UX | Exact component IDs + exact report hash + external current-task action authorization; no prune-all | Plan files improve team review but can be mistaken for authority; prompts are less auditable |
| OD-13 | Atomic publication | Same-filesystem stage/journal, durable temp write, atomic replace, post-commit revalidation | Best-effort in-place writes are simpler but cannot satisfy crash recovery or honest completion |
| OD-14 | Rollback | Restore exact prior manifest/component bytes and verify digests | Serializing a v2 downgrade is lossy; delete-and-reinstall can overwrite customization |
| OD-15 | Link/mount handling | Root-relative logical target, explicit materialization mode, no escape-following | Raw OS link text is more direct but non-portable and can expose host paths |
| OD-16 | Source authenticity | Keep SHA-256 as integrity only; approve a separate trust mechanism if authenticity is required | Treating a digest as authenticity is unsafe; mandatory signatures now would expand scope and dependencies |
| OD-17 | Migration/deployment execution | N/A — no migration or deployment execution is authorized in this Phase | Any real execution requires a later exact scope, rollback/recovery evidence, and action-specific approval |

OD-01 through OD-17 are approved as one internally consistent v3 contract. Phase 4 remains **SCHEMA APPROVED — NOT IMPLEMENTED**: Candidate artifacts remain non-runtime, the production Schema has not been created, production writers remain v2, and Phase 4 product implementation, migration, prune, and real-adopter operation require separate explicit current-task authorization.
