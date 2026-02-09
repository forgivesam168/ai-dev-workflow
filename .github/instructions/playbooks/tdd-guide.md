# TDD Guide (Red → Green → Refactor)

## Core loop
1) **Red**: write a failing test that describes the desired behavior.
2) **Green**: implement the smallest change to pass.
3) **Refactor**: improve design without changing behavior.

## What to test
- **Happy path** + **failure path** + **boundary conditions**
- Business rules (especially pricing, limits, rounding, timezone, idempotency)
- Regression tests for bugs

## Test naming (C#)
- Use: `MethodName_Condition_ExpectedResult`
- Keep tests small and deterministic.

## Unit vs Integration
- Unit: domain/application logic, no DB/network.
- Integration: DB mappings, repositories, HTTP endpoints, message queues.

## Coverage guidance
- Prefer **critical-path coverage** over chasing a number.
- High-risk areas (money, authZ, data migrations) must have tests.

## Refactoring safety
- Refactor only after tests are green.
- For brownfield: add characterization tests before changing behavior.

## PR expectation
- Every PR must include: what tests were added/updated and how to run them.
