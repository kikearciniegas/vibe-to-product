# Standards: core (every profile)

Loaded for every profile, first. Profile files add to this list; they never remove from it.

## How to claim an item (evidence rule)
One row per claimed item, in a table at the end of every delivery:

| item | done / N/A / pending / not adopted / gap | evidence |
|---|---|---|
| Security headers | done | `curl -sI https://staging.x \| grep -cE 'strict-transport\|content-security'` → 2 |
| RLS | N/A | landing has no database (BRIEF §8) |

- Evidence is one of: a runnable command plus its observed output or exit code, an artefact path, or a URL.
- `N/A` needs a reason that cites a BRIEF section.
- `not adopted — <path §section or path:line>`: the owner decided otherwise, and that repo file records it (adopt: the project's own CLAUDE.md, decisions or backlog). Not `N/A`, which means the item does not apply.
- `gap — <path:line>`: known and not built, tracked in that repo file (a backlog entry). An item met another way is `done` with the path as evidence.
- The finalize steps check that the cited path exists in the repo, not what it says. Write the ref in the status cell: later phases copy statuses and empty the evidence.
- A ticked box with no evidence is a defect, not a claim.
- The delivery footer is named **Standards evidence**.

## Warnings (not gates)
1. A file over 200 lines gets a review comment and a split proposal. Split when a reader can no longer hold the file in their head, not because of the count.
2. A request that violates a security or performance item: name the item and the consequence, proceed only on an explicit user override, and record the override in BRIEF §10.
3. Hard rules that stay: no `any` types; no secrets in client code.

## Interface (any UI)
- [ ] Button micro-interactions
- [ ] Hover states for buttons and links
- [ ] Loading skeletons/shimmer effects
- [ ] Progress bar for page loading/form submission
- [ ] Dark mode support with system preference detection
- [ ] **Custom Tooltips** for complex UI elements (Modern Polish)
- [ ] **Accessibility (a11y):** Ensure ARIA labels, keyboard navigation, and color contrast ratios (WCAG). Target WCAG 2.2 AA: contrast 4.5:1; keyboard-only pass; focus not obscured (2.4.11); target size at least 24×24 CSS px (2.5.8); non-drag alternative (2.5.7); no redundant entry (3.3.7); accessible authentication (3.3.8); axe-core clean. Evidence: axe-core report with 0 violations plus a keyboard-only walkthrough note. (verified: 2026-09) Also: contrast checked in both light and dark schemes; `prefers-reduced-motion` disables non-essential animation, and auto-playing motion over 5 s can be paused (2.2.2, A); toasts/status messages use `role="status"` or `aria-live` (4.1.3, AA); single-key shortcuts, if any, are remappable or can be turned off (2.1.4, A). Evidence: axe run per colour scheme; a reduced-motion emulation screenshot; DOM check of the toast container. Source: WCAG 2.2 https://www.w3.org/TR/WCAG22/ (verified: 2026-09); web.dev prefers-reduced-motion https://web.dev/articles/prefers-reduced-motion (verified: 2026-09).

## Security
### Credentials & Secrets
- [ ] Hide all API keys from version control
- [ ] Purge secrets from Git history
- [ ] Proper usage of Database Public Keys
- [ ] Zero secrets exposed in frontend code. Evidence: `grep -rE 'sk_live|service_role|SECRET' .next/static dist/` → 0 on the production build; Next.js: secret-using modules `import 'server-only'` and no secret carries the `NEXT_PUBLIC_` prefix. Source: Next.js, Preventing environment poisoning https://nextjs.org/docs/app/getting-started/server-and-client-components#preventing-environment-poisoning (verified: 2026-09).
- [ ] **Secrets Vault:** Use a secure manager (AWS Secrets Manager, HashiCorp Vault) for production. [ASVS L3] Each secret has an owner and a rotation schedule in `docs/secrets.md`; one rotation rehearsed. Evidence: the file plus the date of the last rotation. Source: ASVS 5.0 13.1.4, 13.3.4 (L3) https://github.com/OWASP/ASVS/blob/master/5.0/en/0x22-V13-Configuration.md (verified: 2026-09).

### Data Protection
- [ ] Encryption of sensitive data at rest
- [ ] Secure password hashing (e.g., Argon2 or bcrypt)
- [ ] HTTP-Only and Secure cookie flags, plus `SameSite`; session cookie named with the `__Host-` prefix (no `Domain` scope); session tokens never in `localStorage`/`sessionStorage`. Evidence: `curl -sI` shows `Set-Cookie: __Host-…; Secure; HttpOnly; SameSite=Lax` and `rg -n "localStorage.*token"` → 0. Source: ASVS 5.0 3.3.1 (L1), 3.3.2, 3.3.3, 3.3.4 (L2), 10.1.1 https://github.com/OWASP/ASVS/blob/master/5.0/en/0x12-V3-Web-Frontend-Security.md (verified: 2026-09).
- [ ] **Deep Sanitization:** Prevent XSS and NoSQL injection in all user-generated content. Encode at output per context (HTML, attribute, JS/JSON, URL) rather than relying on input cleaning; email templates render user data as text and strip CR/LF from headers. Evidence: `<script>` and `%0d%0a` in every field of a test email arrive escaped. Source: ASVS 5.0 1.1.2, 1.2.1 (L1), 1.3.11 (L2) https://github.com/OWASP/ASVS/blob/master/5.0/en/0x10-V1-Encoding-and-Sanitization.md (verified: 2026-09).
- [ ] File system access restrictions

### Access & Authentication
- [ ] Strengthened authentication flow: via a maintained auth library or provider (Auth.js, Clerk, Supabase Auth, Auth0…); no hand-written password or session code (a soft rule: the cheat sheet recommends maintained libraries but does not forbid custom auth). Evidence: the dependency name and version. Source: OWASP Authentication Cheat Sheet https://cheatsheetseries.owasp.org/cheatsheets/Authentication_Cheat_Sheet.html (verified: 2026-09).
- [ ] **Admin routes:** every admin route enforces an authenticated role check server-side and fails closed; admin accounts use MFA; every admin action is audit-logged. Evidence: one audit row for a test admin action and the MFA setting on admin accounts (the unauthenticated `/admin` probe is under **Debug surface off**). Source: OWASP ASVS 4.0.3 §4.1.1, 4.1.3, 4.1.5, 4.3.1 https://raw.githubusercontent.com/OWASP/ASVS/v4.0.3/4.0/en/0x12-V4-Access-Control.md (verified: 2026-09).
- [ ] Rate limiting for login attempts/Brute force protection: throttle per account and per IP with progressive delay (or bot challenge) before any hard lockout; cap consecutive failures per authenticator at ≤ 100; a lockout must not let an attacker lock other users out (recovery flow still works); same limits on sign-up and reset. Evidence: 20 failed logins in 1 min → 429. Source: NIST SP 800-63B rev4 §3.2.2 https://pages.nist.gov/800-63-4/sp800-63b.html (verified: 2026-09); OWASP Authentication Cheat Sheet, lockout DoS note https://cheatsheetseries.owasp.org/cheatsheets/Authentication_Cheat_Sheet.html (verified: 2026-09); ASVS 5.0 6.3.1 (L1), 2.4.1 (L2) https://github.com/OWASP/ASVS/blob/master/5.0/en/0x15-V6-Authentication.md (verified: 2026-09).
- [ ] Bot protection (CAPTCHA/Turnstile)
- [ ] Restricted access to system logs
- [ ] Prevention of sensitive field manipulation (OWASP API3): request bodies accept only an allow-list of writable fields; admin-only fields are never writable from user endpoints; responses and server-component props carry only the fields the client renders (no `SELECT *` / `to_json()` pass-through). Rejecting unknown fields is **Server-side input validation**. Evidence: after that item's extra-field `POST`, the stored record is unchanged; one response payload inspected for extra fields. Source: OWASP API3:2023 https://api-security.owasp.org/editions/2023/en/0xa3-broken-object-property-level-authorization (verified: 2026-09).
- [ ] **Endpoint Rate Limiting:** Strict limits on high-cost endpoints (Search, Auth) to prevent scraping.
- [ ] **OWASP ASVS Level 1 self-check:** for every profile with login. Evidence: `docs/asvs-l1.md` with one row per requirement. https://github.com/OWASP/ASVS/tree/master/5.0/en (verified: 2026-09)
- [ ] **Auth by default:** every route, RPC procedure, server action, realtime subscription/channel and cron/internal endpoint passes through one shared server-side guard; public routes are an explicit allowlist; scheduled endpoints require a secret bearer header (e.g. Vercel `CRON_SECRET`). Middleware-only checks don't count. Evidence: an automated test that calls every registered route unauthenticated and expects 401/403 except the allowlist; one realtime subscription test where user A never receives user B's events. Source: ASVS 5.0 7.2.1, 8.2.1, 8.3.1 (L1) https://github.com/OWASP/ASVS/blob/master/5.0/en/0x17-V8-Authorization.md (verified: 2026-09); OWASP API5:2023 https://api-security.owasp.org/editions/2023/en/0x11-t10 (verified: 2026-09); Vercel cron https://vercel.com/docs/cron-jobs/manage-cron-jobs#securing-cron-jobs (verified: 2026-09).
- [ ] **OAuth / social login** (when present): authorization-code flow with PKCE (S256) and a one-time `state`; redirect URIs registered as exact strings; only the scopes the app needs; access/refresh tokens stay server-side (BFF), never in browser JS. Evidence: the captured authorization request URL showing `code_challenge` and `state`, and the provider console's redirect-URI list. Source: RFC 9700 §2.1, 2.1.1 https://www.rfc-editor.org/rfc/rfc9700.html (verified: 2026-09); ASVS 5.0 10.4.1 (L1), 10.2.1, 10.4.6, 10.1.1, 10.2.3 https://github.com/OWASP/ASVS/blob/master/5.0/en/0x19-V10-OAuth-and-OIDC.md (verified: 2026-09).
- [ ] **Reset and magic links:** password-reset, invite and magic-link tokens are random, short-lived (default: 15 min, 1 h at most) and invalidated on first use; reset does not bypass MFA. Evidence: a test that reuses a consumed link and one that uses an expired link, both rejected. Source: ASVS 5.0 6.4.1 (L1), 6.4.3 https://github.com/OWASP/ASVS/blob/master/5.0/en/0x15-V6-Authentication.md (verified: 2026-09; ASVS says "short", the minutes are a convention); OWASP Forgot Password Cheat Sheet https://cheatsheetseries.owasp.org/cheatsheets/Forgot_Password_Cheat_Sheet.html (unverified).
- [ ] **Password policy per NIST:** length-only policy (no composition rules, no periodic expiry); new and changed passwords are checked against a breached/common-password list (e.g. HIBP k-anonymity, ≥ top 3000). Evidence: setting `Password123!` is rejected; a long lowercase passphrase is accepted. Source: NIST SP 800-63B rev4 §3.1.1.2 https://pages.nist.gov/800-63-4/sp800-63b.html (verified: 2026-09); ASVS 5.0 6.2.4 (L1), 6.2.12 (L2) https://github.com/OWASP/ASVS/blob/master/5.0/en/0x15-V6-Authentication.md (verified: 2026-09).
- [ ] **No user enumeration:** [ASVS L3] login, sign-up and password-reset return the same message and status whether or not the account exists. Evidence: reset for an unknown email returns the same body/status as for a known one. Source: OWASP Authentication Cheat Sheet https://cheatsheetseries.owasp.org/cheatsheets/Authentication_Cheat_Sheet.html (verified: 2026-09); ASVS 5.0 6.3.8 (L3) https://github.com/OWASP/ASVS/blob/master/5.0/en/0x15-V6-Authentication.md (verified: 2026-09).

### Network & Headers
- [ ] Implementation of Security Headers (CSP, HSTS, X-Frame-Options): HSTS max-age ≥ 1 year; `X-Content-Type-Options: nosniff`; `Referrer-Policy`; `Permissions-Policy`; CSP `frame-ancestors 'none'` (plus `X-Frame-Options: DENY` for old browsers). Evidence: `curl -sI https://x | grep -ciE 'strict-transport|nosniff|referrer-policy|frame-ancestors'` → 4. Source: ASVS 5.0 3.4.1 (L1), 3.4.4, 3.4.5, 3.4.6 (L2) https://github.com/OWASP/ASVS/blob/master/5.0/en/0x12-V3-Web-Frontend-Security.md (verified: 2026-09).
- [ ] Forced HTTPS redirection
- [ ] Valid SSL Certificate installation
- [ ] **CSP Audit:** Verify the Content Security Policy doesn't block essential scripts. [ASVS L3] Roll out as `Content-Security-Policy-Report-Only` with a `report-to` endpoint first, enforce once reports are clean; the policy has `object-src 'none'`, `base-uri 'none'` and nonces/hashes or a strict allowlist. Evidence: the report endpoint's zero-violation log for 24 h before enforcing. Source: ASVS 5.0 3.4.3 (L2), 3.4.7 (L3) https://github.com/OWASP/ASVS/blob/master/5.0/en/0x12-V3-Web-Frontend-Security.md (verified: 2026-09); MDN CSP Report-Only https://developer.mozilla.org/en-US/docs/Web/HTTP/Reference/Headers/Content-Security-Policy-Report-Only (unverified).
- [ ] **CSRF:** state-changing requests need an anti-forgery token or a non-safelisted custom header / `Sec-Fetch-Site` check, and the session cookie is `SameSite=Lax` or `Strict`; sensitive actions never on GET. N/A for pure bearer-token APIs (cite BRIEF). Evidence: a cross-origin form POST from a test page → 403. Source: ASVS 5.0 3.5.1, 3.5.3 (L1), 3.3.2 https://github.com/OWASP/ASVS/blob/master/5.0/en/0x12-V3-Web-Frontend-Security.md (verified: 2026-09); OWASP CSRF Prevention Cheat Sheet https://cheatsheetseries.owasp.org/cheatsheets/Cross-Site_Request_Forgery_Prevention_Cheat_Sheet.html (verified: 2026-09).
- [ ] **Redirect allowlist:** [ASVS L2] every redirect target (`next`, `returnTo`, post-login, OAuth callback) is validated as same-origin or against an allowlist; encoded, protocol-relative and `javascript:` variants are rejected. Evidence: `?next=//evil.example` and `?next=%2F%2Fevil.example` both stay on the site. Source: ASVS 5.0 3.7.2 (L2), 1.2.2 (L1) https://github.com/OWASP/ASVS/blob/master/5.0/en/0x12-V3-Web-Frontend-Security.md (verified: 2026-09); CWE-601 https://cwe.mitre.org/data/definitions/601.html (unverified).

### Security Additions
- [ ] **CORS Policy:** Strictly define allowed origins for API requests. Never `*` or a reflected origin together with `Access-Control-Allow-Credentials`; methods and headers restricted per endpoint. Evidence: `curl -H "Origin: https://evil.example" -I https://api.x` → no `Access-Control-Allow-Origin`. Source: ASVS 5.0 3.4.2 (L1) https://github.com/OWASP/ASVS/blob/master/5.0/en/0x12-V3-Web-Frontend-Security.md (verified: 2026-09).
- [ ] **Dependency Scanning:** Implement `npm audit` or Snyk to find vulnerable packages.
- [ ] **Session Management:** Implement JWT expiration and secure refresh token rotation. A new session token is issued on every login and privilege change; logout, password change and account disable invalidate the session server-side; idle and absolute timeouts are written down (AAL2 reference: 1 h idle / 24 h absolute) and the UI warns before expiry. Evidence: log in, copy the session cookie, log out, replay it → 401. Source: ASVS 5.0 7.2.4, 7.4.1, 7.4.2 (L1), 7.3.1, 7.3.2, 7.4.3 (L2) https://github.com/OWASP/ASVS/blob/master/5.0/en/0x16-V7-Session-Management.md (verified: 2026-09); NIST SP 800-63B rev4 AAL2 reauthentication https://pages.nist.gov/800-63-4/sp800-63b.html (verified: 2026-09).
- [ ] **Token verification** (when using JWT or other self-contained tokens): signature or MAC checked on every request; algorithm allowlist that excludes `none`; `exp`, `iss` and `aud` validated; keys only from the pre-configured issuer source. Evidence: a test sending a tampered payload and an `alg: none` token → 401. Source: ASVS 5.0 9.1.1, 9.1.2, 9.1.3, 9.2.1 (L1), 9.2.3 https://github.com/OWASP/ASVS/blob/master/5.0/en/0x18-V9-Self-contained-Tokens.md (verified: 2026-09); RFC 8725 §3.1, 3.2, 3.8, 3.9 https://www.rfc-editor.org/rfc/rfc8725.html (verified: 2026-09).
- [ ] **ReDoS Audit:** Review AI-generated Regular Expressions for potential Denial of Service.
- [ ] **Threat model:** assets, entry points and the top 5 abuse cases, written to `docs/threat-model.md` before the review phase. Evidence: the file path.
- [ ] **Supply chain:** lockfile committed; `npm audit` / `pnpm audit` / `osv-scanner` clean; versions pinned. Evidence: the audit command and its exit code.
- [ ] **Hallucinated-package check:** every AI-added dependency exists on the registry, was created more than 6 months ago and has a maintained repo. Evidence: `npm view <pkg> time.created` per package.
- [ ] **Backend service auth:** [ASVS L2] database, cache, queue and storage accept connections only with credentials and only from the app network; no default users/passwords; the app's DB role is least-privilege (not superuser/owner); cache ACLs limited to the commands used. Evidence: a connection attempt from outside the network is refused, and `SELECT rolsuper FROM pg_roles WHERE rolname = current_user` → `f` (or the store's equivalent). Source: ASVS 5.0 13.2.1, 13.2.2, 13.2.3 (L2) https://github.com/OWASP/ASVS/blob/master/5.0/en/0x22-V13-Configuration.md (verified: 2026-09); OWASP Top 10 A05 Security Misconfiguration https://owasp.org/Top10/ (unverified).

## Backend & API
### Data & Logic
- [ ] Use of parameterized queries to prevent SQL Injection, including raw queries through the ORM's tagged/parameterized method. Evidence: `rg -n "queryRawUnsafe|executeRawUnsafe|\$\{.*\}.*(SELECT|INSERT|UPDATE)"` → 0. Source: ASVS 5.0 1.2.4 (L1) https://github.com/OWASP/ASVS/blob/master/5.0/en/0x10-V1-Encoding-and-Sanitization.md (verified: 2026-09).
- [ ] Server-side input validation: schema-based (zod/valibot/pydantic) with unknown fields rejected (`.strict()`), so role/price/owner fields can't be set by the client; every route tested without the UI. Which fields are writable at all is **Prevention of sensitive field manipulation**. Evidence: `POST` with an extra `role: "admin"` field → 400. Source: ASVS 5.0 2.2.1, 2.2.2 (L1), 8.2.3 (L2) https://github.com/OWASP/ASVS/blob/master/5.0/en/0x11-V2-Validation-and-Business-Logic.md (verified: 2026-09).
- [ ] API response limiting/pagination
- [ ] **Outbound URL allowlist (SSRF):** [ASVS L2] any server-side fetch of a user- or model-supplied URL is limited to allowlisted protocols/hosts, blocks private and link-local ranges (incl. `169.254.169.254`), and pins the resolved IP across redirects. Evidence: a test submitting `http://169.254.169.254/` and one redirecting to an internal host, both rejected. Source: ASVS 5.0 1.3.6, 13.2.4, 13.2.5 (L2) https://github.com/OWASP/ASVS/blob/master/5.0/en/0x22-V13-Configuration.md (verified: 2026-09); OWASP API7:2023 SSRF https://api-security.owasp.org/editions/2023/en/0x11-t10 (verified: 2026-09); LLM06:2025 Excessive Agency for agent tools https://genai.owasp.org/llmrisk/llm062025-excessive-agency/ (verified: 2026-09).
- [ ] **Dangerous sinks audit:** no shell command built from input, no `eval`/dynamic code, no unsafe deserialization of untrusted data (pickle, `yaml.load`, native Java/PHP), XML parsers with external entities off. Evidence: `rg -n "exec\(|execSync|shell: true|eval\(|pickle\.loads|yaml\.load\(|unserialize\("` → 0 hits, or each hit justified in `docs/threat-model.md`. Source: ASVS 5.0 1.2.5, 1.3.2, 1.5.1 (L1), 1.5.2 (L2) https://github.com/OWASP/ASVS/blob/master/5.0/en/0x10-V1-Encoding-and-Sanitization.md (verified: 2026-09).

### Backend Additions
- [ ] **API Documentation:** Implement Swagger/OpenAPI for endpoint documentation. When third parties call the API: path versioned (`/v1/`), a changelog, and breaking changes ship as a new version with `Deprecation`/`Sunset` headers on the old one. Evidence: OpenAPI path; `curl -sI` of a deprecated route showing `Sunset`. Source: RFC 8594 Sunset header https://www.rfc-editor.org/rfc/rfc8594 (unverified); Microsoft REST API Guidelines https://github.com/microsoft/api-guidelines (unverified).
- [ ] **Caching Strategy:** Implement Redis or server-side caching for frequent queries. Every cache entry has a TTL and an invalidation on write; personalized responses are `Cache-Control: private, no-cache`, never shared. Evidence: cache key list with TTLs, and one write followed by a read returning the new value. Source: MDN HTTP caching https://developer.mozilla.org/en-US/docs/Web/HTTP/Guides/Caching (verified: 2026-09).
- [ ] **Error Logging:** Integrate Sentry or LogRocket for real-time error tracking.
- [ ] **Log Structuring:** Transition from `console.log` to structured logging (Winston, Pino) for production searchability.
- [ ] **Database Migrations:** Implement a version-controlled migration system. Schema changes follow expand-then-contract (add before remove), every migration has a tested down step, and runs on staging before production. Evidence: migration files with up/down and the staging run log. Source: Prisma Data Guide, Expand and contract https://www.prisma.io/dataguide/types/relational/expand-and-contract-pattern (verified: 2026-09).
- [ ] **Global Error Boundaries:** Unified handler to prevent app crashes on unhandled exceptions.
- [ ] **Observability:** OpenTelemetry traces, metrics and structured logs; the trace id is echoed in error responses; error pages reveal nothing internal. Evidence: one error response showing the trace id and the matching trace. https://opentelemetry.io/docs/concepts/signals/ (verified: 2026-09)
- [ ] **Feature flags:** a kill switch for every risky feature; per-tenant if multi-tenant. Evidence: flag list with the owner of each switch.
- [ ] **Background jobs:** work not needed to answer the request (emails, outbound webhooks, PDFs, AI calls, provisioning) runs in a queue with retries and a dead-letter queue; no HTTP request runs past the platform timeout: work over ~10 s is enqueued and answered with `202` plus a status URL (`Location`, `Retry-After`) or a webhook; queue depth and failure count are visible on the dashboard. Evidence: the handler that enqueues and returns one `202` with its status URL, plus the queue metric. Source: Azure Architecture Center, Asynchronous Request-Reply https://learn.microsoft.com/en-us/azure/architecture/patterns/async-request-reply (verified: 2026-09); Stripe webhooks "Handle events asynchronously" https://docs.stripe.com/webhooks (verified: 2026-09).
- [ ] **Connection pooling:** serverless/edge code reaches Postgres through a pooler (Neon `-pooler` host, Supabase pooler, PgBouncer); migrations and admin tasks use the direct connection. Evidence: the runtime connection-string host and the pool size setting. Source: Neon, Connection pooling https://neon.com/docs/connect/connection-pooling (verified: 2026-09).
- [ ] **Security event log:** [ASVS L2] login success/failure, password/email change, privilege change and authorization denials are logged with who/when (UTC)/where/what, never with credentials or tokens, and shipped off-host. Evidence: one failed-login log line with user id, IP and UTC timestamp in the external log store. Source: ASVS 5.0 16.2.1, 16.2.5, 16.3.1, 16.3.2, 16.4.3 (L2) https://github.com/OWASP/ASVS/blob/master/5.0/en/0x25-V16-Security-Logging-and-Error-Handling.md (verified: 2026-09).

## Infrastructure & Performance
### Optimization
- [ ] General load speed optimization
- [ ] Image compression and modern formats (WebP/AVIF)
- [ ] Page load time auditing
- [ ] Responsive/Adaptive versioning
- [ ] **Core Web Vitals Audit:** Verify LCP, INP, and CLS are in the "Green" zone. Evidence: field or lab report with all three values. https://web.dev/articles/vitals (verified: 2026-09)

### Infrastructure Additions
- [ ] **CDN Integration:** Use a Content Delivery Network for static assets. [ASVS L2] The platform's WAF/DDoS protection is enabled and the origin is not reachable directly. Evidence: a request to the origin IP with the site's `Host` header is refused. Source: ASVS 5.0 2.4.1 anti-automation (L2) https://github.com/OWASP/ASVS/blob/master/5.0/en/0x11-V2-Validation-and-Business-Logic.md (verified: 2026-09); vendor docs (Cloudflare/Vercel Firewall) (unverified).
- [ ] **CI/CD Pipeline:** Automate tests and deployment via GitHub Actions/GitLab CI. Dev, staging and production are separate deployments with their own database and env vars, and production deploys only from CI after the test job passes. Evidence: the CI workflow with the test job as a required step, and the three environment names/URLs. Source: Twelve-Factor X Dev/prod parity https://12factor.net/dev-prod-parity (verified: 2026-09).
- [ ] **Automated Backups** and **Backup Verification:** Schedule daily database backups; trigger one manual backup and verify restoration. State RPO and RTO, and rehearse one restore. Evidence: restore log with timestamp and row count.
- [ ] **Rollback Strategy:** Implement a one-click rollback to the previous stable version, rehearsed once before launch. Evidence: rehearsal log with timestamp and elapsed time. Source: DORA metrics (failed-deployment recovery time; no threshold set) https://dora.dev/guides/dora-metrics-four-keys/ (verified: 2026-09).
- [ ] **Graceful Degradation:** Ensure non-critical feature failures (e.g. a widget) don't crash the entire page. Every outbound HTTP call has a timeout and a handled failure path with a visible fallback state. Evidence: a test with the upstream mocked to hang/fail shows the fallback. Source: SRE book, Addressing Cascading Failures https://sre.google/sre-book/addressing-cascading-failures/ (unverified).
- [ ] **SLOs:** availability and p95 latency per critical endpoint, with an alert on error-budget burn. Evidence: SLO definition file and alert rule.
- [ ] **Incident readiness:** status page on a separate host; post-mortem template in the repo. Evidence: status page URL and template path. Also an incident comms template (who posts, where, update cadence); post-mortems are blameless, filed in `docs/incidents/` within a fixed window (default: 48 h) and reviewed. Evidence: comms template path and the folder. Source: SRE book, Managing Incidents https://sre.google/sre-book/managing-incidents/ and Postmortem Culture https://sre.google/sre-book/postmortem-culture/ (verified: 2026-09).

## Privacy & Legal
### Compliance
- [ ] Privacy Policy page
- [ ] Terms and Conditions page
- [ ] Refund/Return Policy page
- [ ] Contact information protection from scrapers

### Privacy Additions
- [ ] **GDPR/CCPA Compliance:** Implement a way for users to request data deletion.
- [ ] **Consent Management:** Link cookie banner to actual script blocking. No non-essential script fires before consent; "Reject all" is as prominent as "Accept all"; scrolling is not consent; no banner at all when only strictly-necessary cookies are set. Evidence: network log before consent → 0 third-party tags; screenshot of the banner. Source: EDPB Guidelines 05/2020 on consent (unverified); ePrivacy Directive 2002/58/EC Art. 5(3) (unverified); the personal-data law of the BRIEF §7 operating and audience countries, e.g. Ley 81 de 2019 (PA) (unverified).
- [ ] **Account deletion and retention policy:** users can delete their account; the retention period per data type is written down. Evidence: deletion flow path and policy URL. Also the deletion cascade is mapped across every store and processor (DB, backups, email provider, analytics, AI logs); soft-delete with a stated retention window, then hard delete; the request is fulfilled and confirmed within one month. Evidence: the cascade map plus a test that deletes a user and queries each store. Source: GDPR Art. 17(1), Art. 12(3) https://eur-lex.europa.eu/eli/reg/2016/679/oj/eng (verified: 2026-09); the personal-data law of the BRIEF §7 operating and audience countries, e.g. Ley 81 de 2019 (PA) (unverified).
- [ ] **Processor agreements (DPA):** every third party that touches personal data (hosting, DB, email, analytics, AI provider) is listed with its DPA accepted or signed, and the list is linked from the privacy policy. Evidence: `docs/processors.md` with one row per processor and the DPA link/date. Source: GDPR Art. 28(3) https://eur-lex.europa.eu/eli/reg/2016/679/oj/eng (verified: 2026-09); the personal-data law of the BRIEF §7 operating and audience countries, e.g. Ley 81 de 2019 (PA) (unverified).

## Quality Assurance
- [ ] **Unit Testing:** Core business logic covered by tests. A coverage threshold is enforced in CI (floor 60%, raise over time); unit and integration suites run as separate commands. Evidence: the threshold in the coverage config and a CI run that fails below it. Source: Google Testing Blog, Code Coverage Best Practices https://testing.googleblog.com/2020/08/code-coverage-best-practices.html (unverified).
- [ ] **Integration Testing:** Critical API flows tested.
- [ ] **E2E Testing:** Core user journeys automated (Playwright/Cypress).
- [ ] **a11y Testing:** Automated accessibility scan (axe-core).
- [ ] **Stress Testing:** Input boundaries (max chars, emoji injection, invalid formats) to prevent crashes.
- [ ] **DAST baseline:** OWASP ZAP baseline scan against staging with 0 FAIL. Evidence: `zap-baseline.py -t https://staging.x -J zap.json` exit code 0 (or 2 = warnings only) and the report path. Source: ZAP baseline scan https://www.zaproxy.org/docs/docker/baseline-scan/ (verified: 2026-09).

## Vibe-to-Product Refactor (AI-code stabilization)
### Code Hygiene & Technical Debt
- [ ] **Redundancy Audit:** Remove duplicate logic/functions generated across different files.
- [ ] **Dead Code Purge:** Remove all commented-out AI suggestions and unused variables.
- [ ] **Component Decomposition:** Break down "Mega-Components" into small, reusable atomic pieces.
- [ ] **Type Strengthening:** Replace all `any` types with strict interfaces (TypeScript).
- [ ] **Dependency Audit:** Verify AI-suggested packages are necessary, stable, and up-to-date.
- [ ] **No swallowed errors:** every `catch` logs with context or rethrows; no empty catch blocks. Evidence: `rg -nU "catch\s*(\([^)]*\))?\s*\{\s*\}" src` → 0, or ESLint `no-empty` (in `recommended`, `allowEmptyCatch: false`) with `eslint . --max-warnings 0` → exit 0. Source: ESLint no-empty https://eslint.org/docs/latest/rules/no-empty (verified: 2026-09).

### Maintainability & Documentation
- [ ] **"The Why" Documentation:** Document the reasoning behind complex logic, not just the "what."
- [ ] **Environment Mapping:** Create a `.env.example` file for effortless setup.
- [ ] **Architecture Map:** Document the data flow (e.g., Frontend $\rightarrow$ API $\rightarrow$ DB).
- [ ] **API Contract Verification:** Verify AI-generated API calls against current official documentation.

## Pre-flight (before "Live")
### Environment & Config
- [ ] **Prod Env Vars:** Switch all keys from `development/staging` to `production`.
- [ ] **API Rate Limits:** Set reasonable limits to prevent DDoS or cost spikes, and a request body size limit (default: ≤ 1 MB, larger only on upload routes). Evidence: a 2 MB JSON body → 413. Source: ASVS 5.0 5.2.1 for files https://github.com/OWASP/ASVS/blob/master/5.0/en/0x14-V5-File-Handling.md (verified: 2026-09); OWASP Denial of Service Cheat Sheet https://cheatsheetseries.owasp.org/cheatsheets/Denial_of_Service_Cheat_Sheet.html (unverified).
- [ ] **Logs:** Ensure logging is set to `error` or `warn` level.
- [ ] **Debug surface off:** debug mode, directory listing, `.git`/source maps, TRACE, and default admin/docs/metrics routes are not reachable in production. Evidence: `curl -s -o /dev/null -w '%{http_code}' https://x/.git/HEAD` → 404, same for `/debug`, `/metrics`, and an unauthenticated `/admin` → 401/404. Source: ASVS 5.0 13.4.1 (L1), 13.4.2–13.4.5 (L2) https://github.com/OWASP/ASVS/blob/master/5.0/en/0x22-V13-Configuration.md (verified: 2026-09).

### QA & Smoke Testing
- [ ] **Critical Path Test:** Manually perform every core user action in a fresh browser profile as a new user.
- [ ] **Lighthouse Audit:** Run a final Google Lighthouse report.

### Monitoring & Maintenance
- [ ] **Uptime Monitoring:** Setup BetterStack/UptimeRobot for alerts.
- [ ] **Analytics Check:** Confirm that the first "Live" visit is recorded.

## Modularity
- [ ] **Module map:** every top-level module (dir under `src/`, `app/` or `lib/`) is listed in `docs/ARCHITECTURE.md` with one line of responsibility and its allowed dependencies. Evidence: `ls -d src/*/ | wc -l` equals the listed count.
- [ ] **Dependency direction:** imports point inward (ui → features → domain → shared); `shared/`, `core/`, `lib/` never import from a feature or route. Evidence: `rg -n "from ['\"](\.\./)+(features|app|routes)" src/shared src/core src/lib` → 0 lines, or the graph tool's edge query.
- [ ] **No cross-module internals:** a module is imported only through its public surface (`index.*` or an explicit `exports` map). Evidence: `rg -nP "from ['\"]\.\.?/[\w-]+/(?!index)[\w/-]+['\"]" src` → 0, or an `import/no-internal-modules` / `no-restricted-paths` lint rule with `eslint . --max-warnings 0` → exit 0.
- [ ] **Feature folders** (when the project has 2+ features or more than 20 source files): code is grouped by feature (`features/<name>/{components,api,model}`), not by type at the top level. Evidence: the module map; `ls src` shows feature names, not `components/ services/ utils/` alone.
- [ ] **No import cycles.** Evidence: `npx madge --circular --extensions ts,tsx src` → "No circular dependency found" (JS/TS), `pydeps --show-cycles` (Python), or the graph tool's cycle report. (verified: 2026-09) https://github.com/pahen/madge
- [ ] **Single owner per concern:** one place reads env/config, one creates the DB client, one wires auth; no second copy. Evidence: `rg -l "process\.env\." src | grep -vc "config"` → 0; `rg -l "createClient\(" src | wc -l` → 1 (adapt the pattern to the stack).

## Conditional blocks (switched on by BRIEF §9)
### If the product has an AI feature
OWASP Top 10 for LLM Applications. https://genai.owasp.org/llm-top-10/ (verified: 2026-09)
- [ ] **Prompt-injection defence:** untrusted input never reaches the system prompt unmarked; tools the model can call are allow-listed. Evidence: injection test cases and their results.
- [ ] **Per-user AI usage limits:** a cap per user per period. Evidence: the limit config and one rejected over-limit request. Also per-request token usage is logged; a monthly spend cap at the provider alerts and then stops (default: alert at 70%, hard stop at 90%), with a cost breakdown by model; prompt caching is on for stable system prompts where supported. Evidence: the provider budget settings, the cost dashboard and one usage log line. Source: OWASP LLM10:2025 Unbounded Consumption https://genai.owasp.org/llmrisk/llm102025-unbounded-consumption/ (verified: 2026-09); cap thresholds from provider console docs (unverified).
- [ ] **Output validation:** model output is validated before it reaches users. Evidence: the validator and a test that rejects bad output. Also model output is treated as untrusted input: schema-validated, encoded for its destination (HTML/SQL/shell), retried once with the validation error fed back, then a non-AI fallback; raw output is never rendered. Evidence: validator, retry branch and fallback path. Source: OWASP LLM05:2025 Improper Output Handling https://genai.owasp.org/llmrisk/llm052025-improper-output-handling/ (verified: 2026-09).
- [ ] **Evals in CI:** a held-out eval set (edge cases and injection attempts included) is graded automatically (exact-match or code check where possible, LLM-as-judge with a different model for subjective criteria) and runs in CI with a pass threshold; a score below it blocks the deploy. Evals add to deterministic tests; they do not replace assertions. Evidence: the eval file path and the last CI run's score vs threshold. Source: Anthropic, Create strong empirical evaluations https://platform.claude.com/docs/en/docs/build-with-claude/develop-tests (verified: 2026-09); NIST AI RMF MEASURE https://www.nist.gov/itl/ai-risk-management-framework (unverified).
- [ ] **Agent least privilege (OWASP LLM06):** each agent/tool runs on its own short-lived, minimum-scope credential in the acting user's context; high-impact actions (payments, deletes, outbound sends) wait for human approval; every tool call is logged with a run id; each run has a max step count and a timeout. Evidence: the credential scope, the approval code path, one run log, and the step/timeout config. Source: OWASP LLM06:2025 Excessive Agency https://genai.owasp.org/llmrisk/llm062025-excessive-agency/ (verified: 2026-09); LLM10:2025 for bounds https://genai.owasp.org/llmrisk/llm102025-unbounded-consumption/ (verified: 2026-09).

### If the product takes payments
- [ ] **Server-side prices:** the client never sends the amount charged. Evidence: the checkout handler reading prices from the server. Also checkout sessions are created server-side from provider Price IDs; access is provisioned only by the signature-verified `checkout.session.completed` / `checkout.session.async_payment_succeeded` webhook, idempotent per session id, never from the success redirect alone. Evidence: the fulfillment handler and a test calling it twice with the same session id. Source: Stripe, Fulfill orders https://docs.stripe.com/checkout/fulfillment (verified: 2026-09).
- [ ] **Payment test:** one real transaction in production, then refunded. Evidence: provider transaction id.
- [ ] **Refund policy:** linked from checkout. Evidence: URL.
- [ ] **Failed-payment recovery (subscriptions only):** automatic retries enabled (Stripe Smart Retries or a custom schedule), a failed-payment email sent on `invoice.payment_failed`, and a written grace period before access is cut. Evidence: the retry setting and one test `invoice.payment_failed` event handled. Source: Stripe Smart Retries https://docs.stripe.com/billing/revenue-recovery/smart-retries (verified: 2026-09).
- [ ] **Disputes:** a webhook or provider notification fires on a new dispute (Stripe: `charge.dispute.created`) and a named owner submits evidence before the deadline. Evidence: the handler or notification setting and the owner's name. Source: Stripe Disputes https://docs.stripe.com/disputes (verified: 2026-09; event name unverified).

### If the product receives inbound webhooks
- [ ] **Webhook signature verification:** on every inbound webhook. Evidence: a test that rejects an unsigned request.
- [ ] **Idempotency:** store the event id before processing; 24 h replay window; duplicates return success without reprocessing. Evidence: a test that sends one event twice.

### If the product is multilingual (i18n)
- [ ] **Locales:** every user-facing string comes from a locale file; dates, numbers and currency are formatted per locale. Evidence: a string-extraction lint with 0 hard-coded strings.

### If audience > 100 concurrent users (load test)
- [ ] **Load test:** k6 against staging with the p95 target from BRIEF §4. Evidence: k6 summary with p95 below target. https://grafana.com/docs/k6/latest/using-k6/thresholds/ (verified: 2026-09)
- [ ] **Progressive rollout:** a new version reaches a slice of traffic first (canary or feature-flag percentage) and the SLO alert is the promote/rollback gate. Evidence: rollout config and one promotion or rollback log. Source: Google SRE Workbook, Canarying Releases https://sre.google/workbook/canarying-releases/ (verified: 2026-09).

### If the product handles health or other special-category data
- [ ] **Sensitive-data safeguards:** field-level encryption at rest and TLS in transit; role-based access; an audit-log row for every read and write of the sensitive record; a BAA (US/HIPAA) or DPA with every processor that can see it. Evidence: encryption call site, one audit row for a test read, and the BAA/DPA list. Source: GDPR Art. 9 https://eur-lex.europa.eu/eli/reg/2016/679/oj/eng (verified: 2026-09); HIPAA Security Rule 45 CFR 164.312 https://www.ecfr.gov/current/title-45/section-164.312 (unverified).

### If the API is GraphQL
- [ ] **GraphQL hardening:** [ASVS L2] introspection disabled in production; query depth/complexity limit; field suggestions off in errors. Evidence: an introspection query in prod → error, and a 20-level nested query → rejected. Source: ASVS 5.0 4.3.1, 4.3.2 (L2) https://github.com/OWASP/ASVS/blob/master/5.0/en/0x13-V4-API-and-Web-Service.md (verified: 2026-09); field suggestions: OWASP GraphQL Cheat Sheet https://cheatsheetseries.owasp.org/cheatsheets/GraphQL_Cheat_Sheet.html (unverified).

### If the product accepts file uploads
- [ ] **Upload controls:** size cap; extension and content both checked against an allowlist; stored under a generated name outside the web root or in object storage; never executable; access via auth or signed URL. Evidence: `shell.php` renamed `.png` → rejected; direct URL to an uploaded file without auth → 401/403. Source: ASVS 5.0 5.2.1, 5.2.2, 5.3.1, 5.3.2 (L1) https://github.com/OWASP/ASVS/blob/master/5.0/en/0x14-V5-File-Handling.md (verified: 2026-09).

***
Copyright © 2026 Rafael Arciniegas. Licensed under the MIT License.
