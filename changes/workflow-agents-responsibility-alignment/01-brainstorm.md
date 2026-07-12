# 01 Brainstorm — Completed Architecture Analysis Summary

## Status

This document records the completed read-only analysis. It does not reopen architecture discovery and does not authorize implementation.

## Rejected Models

### Rejected: Single Policy Layer

Global governance, maintainer product rules, adopter project rules, distribution policy, and CLI runtime have different owners and lifecycles. Treating them as one layer creates policy leakage and unsafe update assumptions.

Evidence: `AGENTS.md` — Ownership classes; `scripts/bootstrap.py` — ownership values; `docs/AGENTS.template.md` — project-owned guidance.

### Rejected: Full Global AGENTS Mirror

Adopter Project AGENTS must remain independently safe but must not duplicate the complete user-level governance document. Full mirroring creates drift and assumes the template repository owns user policy.

Selected direction: project-specific contract plus approximately 6–10 fallback safety rules.

### Rejected: Full Workflow for Every Task

The existing Fast Path definitions conflict and still over-process small work. A localized, reversible task does not need all lifecycle artifacts, but still needs lightweight Understand, Implement, Prove, and Deliver controls.

Evidence: `WORKFLOW.md` — paths; `skills/workflow-orchestrator/SKILL.md` — Workflow Paths and Stage Skip Rules; `prompts/workflow.prompt.md` — Fast Path vs Standard Path.

### Rejected: Thick Agent Model

Custom Agents must not duplicate Skills, Workflow, Global governance, or authorization policy. Line count alone is not a reliable correctness gate; structural ownership is.

Evidence: `AGENTS.md` — Persona vs Behavior; `agents/pm.agent.md` — Stage Detection; `agents/plan.agent.md` — Guardrails and Output Gate; `agents/code-reviewer.agent.md` — Review Priorities.

### Rejected: Automatic Stale Prune

Absence from the newest canonical tree is insufficient proof that an adopter runtime file is safe to delete. Legacy or customized files must be reported, not removed.

Selected direction: detect → dry-run → report → explicit approval → narrowly proven prune.

### Rejected: Silent Manifest Reset

Treating malformed manifest state as an empty manifest destroys provenance and can misclassify managed files as unknown existing content.

Selected direction: corrupt/unsupported manifest during update is a hard stop; a legacy project without a manifest is warning plus report-only.

### Rejected: Pure Post-Merge Archive as Default

A repository artifact created only after merge requires another write and may imply unauthorized commit/push behavior. It also splits lifecycle completion from the original PR.

Selected direction: Hybrid closeout. Repository lifecycle evidence is prepared pre-merge; PR/release/issue holds authoritative merge evidence; deployment/migration may require a separately authorized operational record.

### Rejected: Full Bash Parity Rewrite as Default

Maintaining a third ownership, manifest, preservation, generation, and migration implementation has high cost and duplicates the supported Python path on Linux/macOS.

Selected direction: deprecate Bash, reject `--update`, direct Linux/macOS to Python, and optionally retain a temporary thin initial-install wrapper.

## Selected Architecture Direction

1. Separate Global, maintainer, adopter, distribution, canonical, and derived responsibilities.
2. Make `WORKFLOW.md` the lifecycle SSOT.
3. Use only Simple, Standard, and High-Risk execution modes.
4. Keep Agents thin and Skills methodological.
5. Keep Prompts as routers and Instructions path/domain scoped.
6. Make Change Package lifecycle evidence with a single declared task/status SSOT.
7. Use risk-adaptive self-evaluation without replacing independent review.
8. Preserve adopter content unless a safe managed transition is proven.
9. Make manifest parse and provenance failures explicit.
10. Treat cross-CLI adapters as representations of one canonical capability contract.

## Remaining Open Decisions

- D-06 complete manifest JSON schema and version number.
- D-03 / D-07 adopter-facing lifecycle source for Phase 3: an adopter-specific template, a shared canonical core with maintainer/adopter projections, or a shared document proven fully generic through maintainer/adopter difference review. Root maintainer `WORKFLOW.md` is not presumed to be the installed adopter contract, and no target filename/path is selected here.
- D-08 Archive artifact name: retain `99-archive.md`, rename to `99-closeout.md`, or support compatibility aliases.
- D-09 exact final rubric dimensions and thresholds for named High-Risk gates.
- D-10 current official Codex and Antigravity capability evidence and adapter design.
- D-11 Bash removal timing and duration of any initial-install wrapper.
- D-07 eventual canonical Review filename; semantic role and legacy aliases are approved, numeric filename is not.

## Non-Decision Notes

- Codex and Antigravity capability claims remain **Not observed** until the D-10 evidence phase.
- No implementation phase is active.
- `04-plan.md` is the task/status SSOT for this Change Package.
