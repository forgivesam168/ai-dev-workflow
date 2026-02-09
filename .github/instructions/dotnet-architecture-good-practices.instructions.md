---
applyTo: "**/*.cs"
description: ".NET / C# Architecture Good Practices (DDD, SOLID, Clean Architecture) for Financial Systems"
---

# .NET Architecture Good Practices (Financial Systems)

> Goal: keep the codebase **safe to change** as MVP becomes brownfield.

## Principles
- **Boundaries first**: UI/API → Application → Domain → Infrastructure. Dependencies flow inward.
- **Domain is pure**: no IO, no DB, no HTTP, no time access directly.
- **SOLID & low coupling**: small interfaces, explicit dependencies, prefer composition.
- **Decision records**: before large changes, write an ADR (see `changes/**/02-decision-log.md`).

## Layering / Folder conventions (suggested)
- `Api/` or `Web/` (controllers, DTOs, auth filters)
- `Application/` (use-cases, commands/queries, validators)
- `Domain/` (entities, value objects, domain services, domain events)
- `Infrastructure/` (EF Core, repositories, message bus, external clients)

## DDD guidelines
- Identify **bounded contexts** (e.g., Accounts, Orders, Pricing, Risk).
- Use **value objects** for money, currency, identifiers. Avoid primitive obsession.
- Raise domain events for cross-aggregate side effects.

## Financial correctness
- Money must use **decimal** (C#). Never use float/double.
- Prefer storing money as **minor units** (int/long) + currency, or decimal with precision.
- Be explicit about timezone; prefer UTC in storage and logs.

## Error handling & idempotency
- For write endpoints, support **Idempotency-Key** where applicable.
- Use deterministic error codes (not only messages).

## Testing posture
- Every change should have tests: unit for domain/application, integration for DB/APIs.
- Keep tests deterministic; avoid time/network unless isolated.

## Security posture
- No secrets in code. Use secret stores/CI secrets.
- Validate all external input; protect against injection and authZ gaps.
