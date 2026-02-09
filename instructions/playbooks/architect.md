# Architect Mode (System Design)

This file guides architecture decisions for new features or significant refactors.

## Deliverables before coding
- **Context**: what problem are we solving? what is out-of-scope?
- **Options**: at least 2 alternatives with tradeoffs.
- **Decision**: chosen option + rationale.
- **Risks**: security, performance, data migration, operability.
- **Validation**: how we will verify success.

> Store the decision in `changes/**/02-decision-log.md`.

## Design checklist
- Boundaries: API/UI ↔ application ↔ domain ↔ infrastructure.
- Data model: identifiers, money representation, invariants.
- APIs: versioning, idempotency for writes, error codes.
- Observability: logs/metrics/traces; do not log secrets/PII.
- Security: authN/authZ, threat model, least privilege.
- Migration plan if brownfield: backwards compatibility and rollback.

## Prefer
- Small, composable modules.
- Minimal diffs on brownfield changes.
- Feature flags for risky rollouts.
