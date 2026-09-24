# Standards: saas-web

Loaded after `core.md` and `web.md`. Backend Additions and Security (including Session Management) live in `core.md`; they apply here in full.

## Data & Logic
- [ ] Database Row Level Security (RLS) configuration
- [ ] API response limiting/pagination
- [ ] **Database Indexing Audit:** Verify that all high-frequency query columns are indexed for performance at scale; slow-query logging on (Postgres `log_min_duration_statement`, e.g. 250ms) and `EXPLAIN ANALYZE` of the top queries shows no sequential scan on large tables. Evidence: the setting value and one EXPLAIN output. Source: PostgreSQL, Error Reporting and Logging https://www.postgresql.org/docs/current/runtime-config-logging.html (verified: 2026-09).
- [ ] **Query scoping:** every query is scoped to the authenticated user or tenant. Evidence: a test where user A requests user B's record and gets 403/404. Also record IDs exposed in URLs are non-sequential (UUID/ULID). Evidence: one URL. Source: OWASP API1:2023 BOLA https://api-security.owasp.org/editions/2023/en/0xa1-broken-object-level-authorization (verified: 2026-09).
- [ ] **Session Management:** Implement JWT expiration and secure refresh token rotation. A new session token is issued on every login and privilege change; logout, password change and account disable invalidate the session server-side; idle and absolute timeouts are written down (AAL2 reference: 1 h idle / 24 h absolute) and the UI warns before expiry. Evidence: log in, copy the session cookie, log out, replay it → 401. Source: ASVS 5.0 7.2.4, 7.4.1, 7.4.2 (L1), 7.3.1, 7.3.2, 7.4.3 (L2) https://github.com/OWASP/ASVS/blob/master/5.0/en/0x16-V7-Session-Management.md (verified: 2026-09); NIST SP 800-63B rev4 AAL2 reauthentication https://pages.nist.gov/800-63-4/sp800-63b.html (verified: 2026-09).

## Accounts and activation
- [ ] **Account lifecycle:** sign-up, login, email verification, password recovery and account deletion all work end to end. Evidence: one E2E test per flow.
- [ ] **Onboarding + activation metric:** the activation event is defined and tracked. Evidence: the event name and one recorded occurrence. Also time from sign-up to the activation event is measured against the BRIEF target; advanced options sit behind progressive disclosure so the first session shows only what reaches activation. Evidence: median time-to-activation from analytics and the first-session screen list. Source: NN/g, Progressive Disclosure https://www.nngroup.com/articles/progressive-disclosure/ (verified: 2026-09). Core usage events are tracked and a weekly retention cohort view exists. Evidence: the event list and one cohort report. Source: GA4 Cohort exploration https://support.google.com/analytics/answer/9670133 (unverified).
- [ ] **UI states:** every data view has empty, loading, error and offline states. Evidence: screenshot or story per state.

## Pre-flight
- [ ] **Payment Test:** Perform one real transaction in production (and refund it).
- [ ] **Email Delivery:** Confirm that welcome emails are arriving in the inbox. SPF and DKIM records exist and DMARC is published (`p=none` minimum) on the sending domain; transactional mail uses a dedicated subdomain. Evidence: `dig TXT <domain>`, `dig TXT <selector>._domainkey.<domain>`, `dig TXT _dmarc.<domain>`. Source: Google, Email sender guidelines https://support.google.com/a/answer/81126 (verified: 2026-09).

## Conditional
- [ ] Language selector/i18n implementation — only if BRIEF §6 lists more than one locale.
- [ ] **Money model:** prices are computed server-side — only if BRIEF §8 has a paid money model. Evidence: the checkout handler reading prices from the server.

## Polish — optional, do last
- [ ] **Dark/Light mode toggle animation** (Modern Polish)

***
Copyright © 2026 Rafael Arciniegas. Licensed under the MIT License.
