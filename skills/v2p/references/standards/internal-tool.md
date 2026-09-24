# Standards: internal-tool

Loaded after `core.md` and `web.md`. Users work for you; the bar is correctness and traceability, not growth.

## Data & Access
- [ ] Database Row Level Security (RLS) configuration
- [ ] **Database Indexing Audit:** Verify that all high-frequency query columns are indexed for performance at scale; slow-query logging on (Postgres `log_min_duration_statement`, e.g. 250ms) and `EXPLAIN ANALYZE` of the top queries shows no sequential scan on large tables. Evidence: the setting value and one EXPLAIN output. Source: PostgreSQL, Error Reporting and Logging https://www.postgresql.org/docs/current/runtime-config-logging.html (verified: 2026-09).
- [ ] Restricted access to system logs
- [ ] Prevention of sensitive field manipulation (OWASP API3): request bodies accept only an allow-list of writable fields; admin-only fields are never writable from user endpoints; responses and server-component props carry only the fields the client renders (no `SELECT *` / `to_json()` pass-through). Rejecting unknown fields is **Server-side input validation**. Evidence: after that item's extra-field `POST`, the stored record is unchanged; one response payload inspected for extra fields. Source: OWASP API3:2023 https://api-security.owasp.org/editions/2023/en/0xa3-broken-object-property-level-authorization (verified: 2026-09).
- [ ] **SSO via the existing identity provider:** never a custom login for colleagues. Evidence: IdP app registration and one SSO login.
- [ ] **Expensive-to-undo actions:** a confirmation step plus an immutable audit log entry (who, what, when, before/after). Evidence: audit log row for one test action.
- [ ] **Soft deletes:** records are marked deleted, not removed. Evidence: schema column and a restore test.
- [ ] **CSV export / scheduled report:** the numbers people ask for leave the tool without a developer. Evidence: one exported file.

## Pre-answered N/A
| item | status | reason |
|---|---|---|
| SEO (Metadata & Indexing, SEO Additions, Analysis & External Tools) | N/A | internal audience |
| Conversion & Lead Generation (CRO) | N/A | internal audience |
| Cookie consent banner | N/A | internal audience |

***
Copyright © 2026 Rafael Arciniegas. Licensed under the MIT License.
