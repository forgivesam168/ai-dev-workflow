# Brainstorm: Trustworthy Baseline Recovery

## Selected Approach

1. Generate the expected `.github` mirror only in a uniquely named system temporary directory by reusing `tools/sync-dotgithub.ps1`.
2. Compare only generator-managed destinations; ignore workflows, CODEOWNERS, Dependabot, and all other unmanaged `.github` paths.
3. Keep the catalog contract as small explicit constants with fixture tests rather than introducing a catalog manifest.
4. Normalize path representation only: convert separators and remove complete `./` prefixes while preserving dot-directory names and `../`.
5. Pin test runners in CI, but do not treat direct pins as a transitive lock.

## Rejected

- Running sync against the real repository and checking the diff afterward: mutating and cannot prove pre-sync cleanliness.
- Reimplementing the complete sync mapping in the checker: creates a second drift-prone mapping.
- Expanding this change into lifecycle or installer-contract redesign.
