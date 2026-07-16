---
description: 'Python-file delta for repository-consistent typing, precision, resource safety, and verification.'
applyTo: '**/*.py'
---

# Python Instructions

## Scope

Apply this delta only to Python source and test files. Honor the Python version, dependency declarations, formatter, linter, type checker, and test runner already configured by the repository.

## Canonical Method

Follow [python-patterns](../skills/python-patterns/SKILL.md) for reusable Python implementation and testing methodology.

## Scoped Delta

Use readable PEP 8 naming, explicit boundary types, specific exceptions, and context managers for owned resources. Preserve exact financial values with `Decimal`, integer minor units, or strings at external boundaries; never introduce `float` for money. Do not add or resolve dependencies without the required authorization.

## Scoped Verification

Run the repository-declared targeted Python tests and applicable formatting, lint, and type checks for changed files, then the required broader gate. Record exact outcomes and treat every known deterministic failure as blocking.
