# Install Surface Design

**Status**: Design Specification (pre-implementation)
**Spec Reference**: `changes/2026-04-21-workflow-template-optimization/03-spec.md` — AC-3

---

## Overview

This document defines the responsibilities, behaviors, and compatibility constraints for the next-generation install surface of the AI development workflow template. It does not implement these behaviors — it specifies them for future implementation.

The current entry point (`Init-Project.ps1`) is preserved as a compatible wrapper throughout.

---

## 1. `install-plan` Behavior

`install-plan` performs a **dry-run inspection** of what would be installed. It produces no side effects.

### Output Format

Default (human-readable table):

```
Component           Source                      Target                      Status
---------           ------                      ------                      ------
copilot-instructions.md  ./copilot-instructions.md  .github/copilot-instructions.md  NEW
agents/coder.agent.md    ./agents/coder.agent.md    .github/agents/coder.agent.md    EXISTS (skip)
skills/tdd-workflow/     ./skills/tdd-workflow/     .github/skills/tdd-workflow/     EXISTS (skip)
...
```

Machine-readable (with `--json` flag):

```json
{
  "schema_version": 1,
  "components": [
    {
      "name": "copilot-instructions.md",
      "source": "./copilot-instructions.md",
      "target": ".github/copilot-instructions.md",
      "status": "NEW"
    }
  ]
}
```

### What `install-plan` Lists

- All components that would be installed (agents, instructions, prompts, skills, copilot-instructions.md)
- Source path vs. target path diff
- Status per component: `NEW`, `EXISTS (skip)`, `EXISTS (overwrite with --force)`, `MISSING SOURCE`

### What `install-plan` Does NOT Do

- Does not write any files
- Does not modify `.github/**`
- Does not create `.ai-workflow-memory/`
- Does not update `sync-manifest.json`

---

## 2. `install-apply` Behavior

`install-apply` executes the installation defined by `install-plan`.

### Conflict Resolution

| Scenario | Default Behavior | With `--force` |
|----------|-----------------|----------------|
| Target file does not exist | Copy source → target | Same |
| Target file exists, identical content | Skip (no-op) | Same |
| Target file exists, different content | **Skip** (preserve local customization) | **Overwrite** with source |
| Source file missing | Error + abort component | Same (hard error) |

Default conflict behavior is `skip-if-exists` to protect local customizations in adopter repos.

### Rollback Guidance

- Before running `install-apply --force`, back up the target directory: `Copy-Item .github .github.bak -Recurse`
- On partial failure: re-run `install-apply` (idempotent); already-installed components are skipped
- To undo: restore from `.github.bak` or `git checkout -- .github/`

### Compatibility with `Init-Project.ps1`

`Init-Project.ps1` remains the supported entry point and compatible wrapper. The new install surface does not replace it — it provides a more granular API underneath. `Init-Project.ps1` may delegate to `install-plan` / `install-apply` internally in a future version.

### `--enable-memory` Flag

When `install-apply` is invoked with `--enable-memory`, it additionally creates the `.ai-workflow-memory/` skeleton directory structure. Without this flag, **no memory directory is created** (opt-in only).

See [`docs/repo-memory-design.md`](./repo-memory-design.md) for the full specification of the repo memory structure, update rules, and lifecycle.

---

## 3. `doctor` Behavior

`doctor` audits the deployed state of the template against the source and `.github/**`.

### What `doctor` Checks

1. **Source vs `.github/**` parity**: each source file in `agents/`, `instructions/`, `prompts/`, `skills/`, `copilot-instructions.md` has a corresponding `.github/**` mirror with matching content
2. **Deployed-target parity** (if `sync-manifest.json` exists): installed components match the manifest record
3. **Catalog integrity**: agent / prompt / skill counts match expected values from `tools/audit-catalog.ps1`

### Verdict Format

Aligned with gate-check verdict semantics:

| Verdict | Meaning | Action |
|---------|---------|--------|
| `DOCTOR PASSED` | All checks pass; no drift detected | None required |
| `DOCTOR PASSED WITH NOTES` | Minor issues (e.g., extra files not in manifest); non-blocking | Log to `02-decision-log.md` if in a change package |
| `DOCTOR FAILED` | Drift or missing files detected; template may be inconsistent | Run `sync-dotgithub.ps1` or `install-apply` to remediate |

### Example Output

```
DOCTOR PASSED
  ✅ Source vs .github/** parity: 6 agents, 10 prompts, 28 skills — all in sync
  ✅ Catalog integrity: counts match expected (6 / 10 / 28)
```

```
DOCTOR FAILED
  ❌ Source vs .github/** drift detected:
       agents/coder.agent.md → .github/agents/coder.agent.md: MODIFIED (run sync-dotgithub.ps1)
  ✅ Catalog integrity: counts match expected
```

---

## 4. JSON Manifest Minimum Schema

The install manifest (`sync-manifest.json` or `.ai-workflow-install.json`) tracks what was installed and when.

```json
{
  "schema_version": 1,
  "installed_at": "2026-04-21T14:30:00Z",
  "source_ref": "abc1234",
  "components": [
    {
      "name": "agents/coder.agent.md",
      "installed_at": "2026-04-21T14:30:00Z",
      "source_hash": "sha256:..."
    }
  ]
}
```

**Schema rules**:
- `schema_version` **must be the first field** in the JSON object
- `installed_at` is ISO 8601 UTC
- `source_ref` is a Git commit SHA or tag name
- Schema is **forwards-compatible**: new fields may be added without breaking existing state files (NFR-04)
- Readers must ignore unknown fields

---

## 5. Compatibility Summary

| Surface | Current | New | Breaking? |
|---------|---------|-----|-----------|
| `Init-Project.ps1` | Primary entry point | Preserved; compatible wrapper | ❌ No |
| `tools/sync-dotgithub.ps1` | Sync tool | Unchanged | ❌ No |
| `tools/audit-catalog.ps1` | Audit script (new in Phase 1) | Invoked by `doctor` | ❌ No |
| `install-plan` | Not yet implemented | New optional surface | ❌ No |
| `install-apply` | Not yet implemented | New optional surface | ❌ No |
| `doctor` | Not yet implemented | New optional surface | ❌ No |

---

## Future Scope (Deferred)

The following are explicitly **out of scope** for this design document and deferred to future work:

- **Multi-harness distribution** (npm package, GitHub Release zip): packaging for distribution beyond Git clone/copy
- **Profile presets** (e.g., `--profile fintech`, `--profile hr`): pre-configured component sets for domain-specific deployments
- **Remote diff**: comparing local deployed state against a remote template version
- **Auto-update**: pull and merge template changes into an already-deployed repo
