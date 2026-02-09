# Security Reviewer Checklist (Financial Systems)

Use this for PR review and risk assessment.

## Secrets / credentials
- [ ] No secrets committed (keys, tokens, connection strings).
- [ ] CI secrets are scoped and rotated; no secrets printed in logs.

## Input validation / injection
- [ ] Validate all external input; reject unexpected formats.
- [ ] Parameterize SQL; avoid dynamic query concatenation.
- [ ] Prevent SSRF / unsafe URL fetches where applicable.

## AuthN / AuthZ
- [ ] Authentication is enforced where needed.
- [ ] Authorization is **explicit** (RBAC/ABAC) and tested.
- [ ] Least privilege for service accounts and DB users.

## Data protection
- [ ] Avoid logging PII; mask where necessary.
- [ ] Encryption at rest/in transit where required.
- [ ] Data retention and purge policy considered.

## Supply chain / CI
- [ ] Dependencies are pinned/locked; avoid untrusted actions.
- [ ] `.github/workflows/**` changes are reviewed by owners.
- [ ] No dangerous workflow patterns (e.g., running untrusted PR code with secrets).

## Verification
- [ ] Security tests/checks executed (SAST/secret scan if available).
- [ ] Threat model updated for high-risk changes.
