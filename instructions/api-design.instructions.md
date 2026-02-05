---
description: "Universal REST API Design Standards & Contracts for Financial Systems (Language/Framework Agnostic)"
applyTo: "**/*.cs, **/*.py, **/*.go, **/*.ts, **/*.java, **/*.kt, **/*.js, **/*.sql, **/*.yaml, **/*.yml, **/*.json"
---

# Universal REST API Design Standards (Financial Contract)

> This document defines **API contracts**, not framework- or language-specific implementations.  
> In case of conflict with any framework guideline or code style, this contract **takes precedence**, unless an explicit exception (ADR) is approved.

---

## 0. Contract First (SSOT)

- API contracts (OpenAPI / JSON Schema) are the **Single Source of Truth**.
- All request/response fields, types, optionality, and nullability **must be explicitly defined** in the contract.
- **Non-breaking changes**: only adding optional fields.
- **Breaking changes** (removal, rename, type change) require a new API version.

---

## 1. Resource Naming & URI Style

- **Kebab-case URLs**: lowercase with hyphens (e.g. `/api/v1/user-accounts`)
- **Plural nouns** for resources (`/orders`, not `/order`)
- **Nesting depth ≤ 2** (e.g. `/customers/{id}/orders`)
- **No verbs in URIs** — actions are expressed via HTTP methods
- **Query semantics**: filtering and searching belong in query parameters, not path segments

---

## 2. HTTP Semantics

- **GET**: Read-only, no side effects
- **POST**: Create resources (transactional endpoints require idempotency)
- **PUT**: Full replacement (contract must define required vs optional fields)
- **PATCH**: Partial update (JSON Merge Patch or explicit DTO)
- **DELETE**: Delete or deactivate (financial data usually requires soft delete)

---

## 3. Request & Response Format (JSON)

- **JSON naming**: default `camelCase`; if an existing contract uses `snake_case`, it must be consistent globally
- **Date/Time**: ISO 8601 with UTC (`2024-01-30T10:00:00Z`)
- **Nullability rules**:
  - Optional fields: SHOULD be omitted when absent
  - Required fields: MUST NOT be omitted or null unless explicitly allowed
  - Collections: return empty arrays (`[]`), never `null`
- **Field order** is not guaranteed; clients must not rely on ordering

---

## 4. Financial Data Precision (Critical)

- **Money (Primary strategy)**:
  - Use **integer minor units** (e.g. `amountMinor: 10050`)
  - Contract must define `currency` and minor unit rules
- **Money (Alternative strategy)**:
  - Decimal values MUST be represented as **string**
  - Floating-point types (`float` / `double`) are **strictly forbidden**
- **Identifiers**:
  - Any ID that may exceed JavaScript safe integer range MUST be a string
  - UUID / ULID MUST be string
- **Rounding rules** must be explicitly defined in the contract or ADR

---

## 5. Standard Error Responses (RFC 7807)

- All APIs MUST adopt **Problem Details for HTTP APIs (RFC 7807)**.
- Allowed extensions: `traceId`, `errors` (field-level), `code` (internal error code)

```json
{
  "type": "https://example.com/probs/out-of-credit",
  "title": "Insufficient credit",
  "status": 403,
  "detail": "Balance 30, required 50",
  "instance": "/api/v1/accounts/12345/transactions",
  "traceId": "00-f9b0..."
}
```

---

## 6. Correlation & Auditing (Required)

- Request header: `X-Correlation-Id`
  - Client MAY provide it
  - Server MUST generate one if absent
- Response MUST echo the same `X-Correlation-Id`
- All transactional APIs MUST be traceable for audit and incident investigation

---

## 7. Idempotency (Transaction Safety)

- All endpoints that create financial transactions MUST support `Idempotency-Key`
- Behavior requirements:
  - Same key + same payload → same result
  - Same key + different payload → `409 Conflict` or `422 Unprocessable Entity`
- Recommended key TTL: **at least 24 hours**

---

## 8. Pagination & Filtering

- Pagination strategy MUST be consistent within a service:
  - `page` + `pageSize` OR `limit` + `offset`
- Recommended list response envelope:

```json
{
  "data": [],
  "meta": {
    "page": 1,
    "pageSize": 20,
    "total": 500
  }
}
```

- Filtering and sorting MUST be explicitly whitelisted in the contract

---

## 9. Security Requirements (CISO Mandate)

- HTTPS is mandatory; downgrade is forbidden
- Sensitive financial responses MUST include:
  - `Cache-Control: no-store`
  - `X-Content-Type-Options: nosniff`
  - `Strict-Transport-Security` (per deployment policy)
- Authentication and authorization schemes MUST be defined in the contract
- Access control rules (RBAC / ABAC / policy-based) MUST be auditable

---

## 10. Versioning

- **URI versioning is mandatory** (`/api/v1/...`)
- Breaking changes → new major version (`v2`)
- Non-breaking changes (adding optional fields) stay in the same version
- Deprecated fields MUST define a deprecation and sunset policy

---

> This document represents a **non-negotiable API contract** for financial systems.  
> Implementation details may vary by language or framework, but **contract compliance is mandatory**.
