# Database Reviewer Checklist (Financial Systems)

Use this when reviewing schema/SQL/migrations.

## Security
- [ ] **Least privilege**: app user has minimum permissions.
- [ ] **Row-level restrictions** where required (e.g., tenant/customer scoping).
- [ ] **No dynamic SQL injection** paths; parameterize queries.
- [ ] **PII**: encrypt at rest where policy requires; mask in logs/exports.

## Schema design
- [ ] Proper **primary keys** and **unique constraints**.
- [ ] Foreign keys with correct `ON DELETE/UPDATE` behavior.
- [ ] Normalize where it matters; avoid inconsistent denormalization.

## Performance
- [ ] Indexes match query patterns (WHERE/JOIN/ORDER BY).
- [ ] Avoid N+1 patterns; check common reporting queries.
- [ ] Large tables: consider partitioning/archiving strategy.

## Migrations
- [ ] Migrations are **reversible** or have a clear rollback plan.
- [ ] Online-safe changes (avoid long locks): add nullable column → backfill → add constraint.
- [ ] Data backfill scripts are idempotent and resumable.

## Auditing / compliance
- [ ] Critical tables have audit fields (created/updated/by) where required.
- [ ] Retention & purge policy is documented.
- [ ] Change is referenced in the relevant `changes/**/03-spec.md` and `06-impact-analysis.md`.

## Verification
- [ ] Provide the exact validation steps (e.g., explain plan, benchmark, row counts).
