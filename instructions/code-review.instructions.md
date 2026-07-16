---
description: 'Source-file review delta that routes reusable review methodology to code-security-review.'
applyTo: '**/*.c, **/*.cc, **/*.cpp, **/*.cs, **/*.go, **/*.h, **/*.hpp, **/*.java, **/*.js, **/*.jsx, **/*.kt, **/*.kts, **/*.php, **/*.py, **/*.rb, **/*.rs, **/*.swift, **/*.ts, **/*.tsx'
excludeAgent: ["coding-agent"]
---

# Source Code Review Instructions

## Scope

Apply this delta only while reviewing matching source files. Use the closest language, framework, and project Instructions for file-specific contracts.

## Canonical Method

Follow [code-security-review](../skills/code-security-review/SKILL.md) for the reusable review procedure, severity rubric, checklist, security and financial lenses, and report format.

## Scoped Delta

Respond in Traditional Chinese while preserving code and technical identifiers in English. Tie each source-code finding to a path, line or symbol, affected behavior, and concrete evidence; do not infer repository-wide policy from this file.

## Scoped Verification

Use the repository-declared build, lint, type, static-analysis, and test commands applicable to the reviewed source. Report unavailable or unexecuted checks honestly, and never let prose or self-evaluation override a deterministic failure.
