# Impact Analysis: Trustworthy Baseline Recovery

## Affected Components

- Maintainer sync and catalog tooling
- Bootstrap path bookkeeping and tests
- Maintainer CI
- Catalog wording in maintainer and adopter documentation

## Preserved Behavior

- The real sync generator remains mutation-oriented and unchanged.
- Bootstrap ownership policy and external manifest migration are unchanged.
- Existing adopter manifests may contain old incorrectly normalized keys such as `github/...`; this change does not migrate or rewrite them.
- Unmanaged `.github` paths remain outside the sync checker contract.
- No lifecycle, archive, agent-ID, or installer-parity decisions are implemented.

## Risks and Mitigations

| Risk | Mitigation |
|---|---|
| Checker mutates the worktree | Run generator only in system temp; assert status before/after |
| Dot-directory identity changes old manifest lookup | Report compatibility impact; no external migration in this change |
| CI dependency drift | CI adds direct test dependency resolution from PyPI (`pytest==8.3.5`) and PSGallery (`Pester==5.6.1`); do not claim a transitive lock |
| Cross-platform bootstrap assumptions | Windows blocking; Ubuntu/GitHub Actions evidence is still pending and must be observed before claiming cross-platform green |

## Rollback

Rollback is scoped to files listed in this Change Package. It requires separate approval and must not use reset, clean, stash, or recursive repository overwrite.

Boundaries:

- Revert only this local commit or apply explicit reverse patches to the files listed by the commit.
- Do not delete sibling directories under `changes/`.
- Do not overwrite the repository from an external backup directory.
- Temporary Pester module cleanup is independent of repository rollback.
