# Standards validation: video-suggested actions (2026-09-23)

Sources: `facebook-video-suggested-actions.md`, `ivanvibecodes-video-suggested-actions.md`.
Three planner reports (product/UX/legal, engineering + AI, security) judged 314 actions against current frameworks. Their verbatim reports are Parts A–C below; Part 0 is the integration contract for `builder`.

## Part 0. Integration contract

### Cross-report dedupe (apply once, not twice)
1. **CSRF:** the engineering ADD "CSRF protection" and the security ADD "CSRF" become one item. Use the security wording (ASVS 5.0 3.5.x).
2. **Async work:** the product ADD "Background jobs" (queue + retries + DLQ) and the engineering ADD "Long-running work" (202 + status URL) become one item in core Backend.
3. **AI spend:** the product MERGE (70/90% cap alerts) and the engineering MERGE (token logging, budget, prompt caching) become one MERGE on the AI usage item.
4. **Mass assignment:** the engineering rewrite of "Prevention of sensitive field manipulation" (API3) goes in core.md and internal-tool.md. The security MERGE on "Server-side input validation" (`.strict()`) stays as a separate item. Each item cites the other and does not repeat its evidence.
5. **Admin surface:** the product "Admin routes" item (ASVS V4, no obscure path) and the security items "Auth by default" and "Debug surface off" stay separate. `/admin` evidence appears once, in "Debug surface off".
6. **Session Management:** saas-web.md duplicates the core.md item. The MERGE applies to both copies (surgical; do not delete the duplicate).

### Rules
- Every new or changed line carries its framework reference. `(verified: 2026-09)` goes only beside a URL on the same line. Anything else is `(unverified)`.
- Items resting on ASVS L2/L3 carry a level tag, e.g. `[ASVS L2]`, so the L1 self-check still reads cleanly.
- Rejected items (Parts A–C, REJECT tables) are not written.
- Out-of-scope items are not written. Skills-catalog candidates (product report) go to `references/skills-catalog.md` only if the user approves them separately.
- After writing: no-item-lost check against the pre-change files; re-measure the row counts in `phases/mapping.md` and `README.md`; run `build-portable.sh`; commit.

***
## Part A. Product / UX / legal report
Files judged: /Users/user/SynologyDrive/code/ai/claude/Projects/personal_skills/vibe-to-product/facebook-video-suggested-actions.md (L740–1114), .../ivanvibecodes-video-suggested-actions.md (L10–175, 302–372). Targets under .../skills/v2p/references/standards/ and .../skills/v2p/references/.

## 1. Counts
| verdict | fb | ivan | total |
|---|---|---|---|
| ADD | 4 | 2 | 6 |
| MERGE | 12 | 7 | 19 |
| COVERED | 6 | 3 | 9 |
| REJECT | 0 | 1 | 1 |
| OUT-OF-SCOPE | 35 | 8 | 43 |
| total | 57 | 21 | 78 |

## 2. ADD + MERGE
Format: src ids | target file · block | exact item text | framework ref + URL + marker

### ADD
1. fb4.3#2 | core.md · Conditional "If the product takes payments" | `- [ ] **Failed-payment recovery (subscriptions only):** automatic retries enabled (Stripe Smart Retries or a custom schedule), a failed-payment email sent on \`invoice.payment_failed\`, and a written grace period before access is cut. Evidence: the retry setting and one test \`invoice.payment_failed\` event handled.` | Stripe Smart Retries (recommended default 8 tries / 2 weeks; final state cancel/unpaid/past_due) https://docs.stripe.com/billing/revenue-recovery/smart-retries (verified: 2026-09)
2. fb7.1#1 | core.md · Privacy Additions | `- [ ] **Processor agreements (DPA):** every third party that touches personal data (hosting, DB, email, analytics, AI provider) is listed with its DPA accepted or signed, and the list is linked from the privacy policy. Evidence: \`docs/processors.md\` with one row per processor and the DPA link/date.` | GDPR Art. 28(3) https://eur-lex.europa.eu/eli/reg/2016/679/oj/eng (verified: 2026-09); Panama Ley 81 de 2019 (unverified). Correction: "AI drafts all three in an afternoon" and "90-day calendar" are process advice, not standards — dropped.
3. fb7.1#4 | core.md · Backend Additions | `- [ ] **Background jobs:** work not needed to answer the request (emails, outbound webhooks, PDFs, AI calls, provisioning) runs in a queue with retries and a dead-letter queue; queue depth and failure count are visible on the dashboard. Evidence: the handler that enqueues and returns, plus the queue metric.` | Nearest official ref: Stripe webhooks "Handle events asynchronously" / "Quickly return a 2xx response" https://docs.stripe.com/webhooks (verified: 2026-09). The general pattern is architecture practice with no standards body — flag if you want a stricter bar.
4. fb7.2#1 | core.md · Conditional blocks, new block "If the product handles health or other special-category data" | `- [ ] **Sensitive-data safeguards:** field-level encryption at rest and TLS in transit; role-based access; an audit-log row for every read and write of the sensitive record; a BAA (US/HIPAA) or DPA with every processor that can see it. Evidence: encryption call site, one audit row for a test read, and the BAA/DPA list.` | GDPR Art. 9 https://eur-lex.europa.eu/eli/reg/2016/679/oj/eng (verified: 2026-09); HIPAA Security Rule 45 CFR 164.312 https://www.ecfr.gov/current/title-45/section-164.312 (unverified: eCFR redirected to a block page)
5. iv5.3#27 | web.md · SEO: Metadata & Indexing | `- [ ] **Heading hierarchy:** exactly one \`h1\` per page and no skipped levels. Evidence: axe rules \`page-has-heading-one\` and \`heading-order\` pass on every route.` | WCAG 2.2 SC 1.3.1 (A), 2.4.6 (AA) https://www.w3.org/TR/WCAG22/ (verified: 2026-09)
6. iv3.3#13 | web.md · Forms & Validation | `- [ ] **Password fields:** show/hide toggle; paste and password managers are not blocked; \`autocomplete="current-password"\` / \`"new-password"\`. Evidence: DOM check and one paste test.` | NN/g "Stop Password Masking" (Nielsen, 2009) https://www.nngroup.com/articles/stop-password-masking/ (verified: 2026-09); WCAG 2.2 SC 3.3.8 (verified: 2026-09). Rest of iv13 is COVERED (web Forms, landing Contact form, core Bot protection, ux-laws Parkinson progress). Form autosave not added: no framework.

### MERGE
7. fb4.3#1 | saas-web.md · Pre-flight "Email Delivery" | append: `SPF and DKIM records exist and DMARC is published (\`p=none\` minimum) on the sending domain; transactional mail uses a dedicated subdomain. Evidence: \`dig TXT <domain>\`, \`dig TXT <selector>._domainkey.<domain>\`, \`dig TXT _dmarc.<domain>\`.` | Google Email sender guidelines (SPF or DKIM for all senders; SPF+DKIM+DMARC for bulk) https://support.google.com/a/answer/81126 (verified: 2026-09)
8. fb5.1#1 | native-app.md · "Secure storage" | append: `cleartext traffic disabled (\`android:usesCleartextTraffic="false"\`, no ATS exceptions in \`Info.plist\`). Evidence: grep of both manifests → 0 exceptions.` | OWASP MASVS-NETWORK-1 https://mas.owasp.org/MASVS/controls/MASVS-NETWORK-1/ (unverified: page body not returned)
9. fb5.1#8 | core.md · Quality Assurance "Unit Testing" | append: `a coverage threshold is enforced in CI (floor 60%, raise over time); unit and integration suites run as separate commands. Evidence: the threshold in the coverage config and a CI run that fails below it.` | Google Testing Blog "Code Coverage Best Practices" (60/75/90 acceptable/commendable/exemplary) https://testing.googleblog.com/2020/08/code-coverage-best-practices.html (unverified: body not returned)
10. fb5.1#10 | core.md · AI conditional "Output validation" | append: `model output is treated as untrusted input: schema-validated, encoded for its destination (HTML/SQL/shell), retried once with the validation error fed back, then a non-AI fallback; raw output is never rendered. Evidence: validator, retry branch and fallback path, plus a test that rejects bad output.` | OWASP LLM05:2025 Improper Output Handling https://genai.owasp.org/llmrisk/llm052025-improper-output-handling/ (verified: 2026-09)
11. fb5.2#1 | saas-web.md · "Onboarding + activation metric" | append: `time from sign-up to the activation event is measured against the BRIEF target; advanced options sit behind progressive disclosure so the first session shows only what reaches activation. Evidence: median time-to-activation from analytics and the first-session screen list.` | NN/g Progressive Disclosure https://www.nngroup.com/articles/progressive-disclosure/ (verified: 2026-09). Correction: "60 seconds" is not a benchmark; the BRIEF sets the target. Re-engagement triggers: not added (lifecycle marketing).
12. fb5.2#2 | saas-web.md · same item | append: `core usage events are tracked and a weekly retention cohort view exists. Evidence: the event list and one cohort report.` | GA4 Cohort exploration https://support.google.com/analytics/answer/9670133 (unverified). Drop-off alerts not added: project-specific.
13. fb5.2#3, fb7.1#3 | core.md · "Account deletion and retention policy" | append: `the deletion cascade is mapped across every store and processor (DB, backups, email provider, analytics, AI logs); soft-delete with a stated retention window, then hard delete; the request is fulfilled and confirmed within one month. Evidence: the cascade map plus a test that deletes a user and queries each store.` | GDPR Art. 17(1), Art. 12(3) "at the latest within one month" https://eur-lex.europa.eu/eli/reg/2016/679/oj/eng (verified: 2026-09); Ley 81 de 2019 (unverified)
14. fb6.1#1 | core.md · payments conditional "Server-side prices" | append: `checkout sessions are created server-side from provider Price IDs; access is provisioned only by the signature-verified \`checkout.session.completed\` / \`checkout.session.async_payment_succeeded\` webhook, idempotent per session id — never from the success redirect alone. Evidence: the fulfillment handler and a test calling it twice with the same session id.` | Stripe "Fulfill orders" — "Webhooks are required for fulfillment" https://docs.stripe.com/checkout/fulfillment (verified: 2026-09)
15. fb6.1#2, fb6.1#7 | core.md · AI conditional "Per-user AI usage limits" | append: `plus a monthly spend cap at the provider with an alert at 70% and a hard stop at 90%, and a cost breakdown by model. Evidence: provider budget settings and the cost dashboard.` | provider console docs only (unverified; no standards body). Model routing and caching not added: optimization, not a standard.
16. fb6.2#1 | core.md · Access & Authentication, new sub-line after "Strengthened authentication flow" | `- [ ] **Admin routes:** every admin route enforces an authenticated role check server-side and fails closed; admin accounts use MFA; every admin action is audit-logged. Evidence: unauthenticated \`curl\` of each admin route → 401/403; one audit row.` | OWASP ASVS 4.0.3 §4.1.1, 4.1.3, 4.1.5, 4.3.1 https://raw.githubusercontent.com/OWASP/ASVS/v4.0.3/4.0/en/0x12-V4-Access-Control.md (verified: 2026-09). Correction: "move to a non-guessable path" REJECTED — obscurity is not access control (ASVS 4.1.1 trusted service layer).
17. iv1.1#2 (whitespace), iv2.2#10 (spacing) | ux-laws.md · Proximity | add bullet: `Spacing follows one scale (multiples of 4 px); section padding is larger than the gap between elements inside the section. Measure: computed margin/padding values → 0 off-scale; section padding > intra-section gap.` | Material Design spacing / 8 dp grid https://m3.material.io/foundations/layout/understanding-layout/spacing (unverified: body not returned). iv1.1#2's other two bullets (component prompts, Manus) are OOS.
18. iv2.2#8, iv2.2#9, iv2.2#10 | landing.md · Anti-"made-by-AI" pass | extend trait list: `no emoji in headings; no badge/pill above the H1; no lorem ipsum; hierarchy by size and weight, not gradient or colour alone; no fade-in on every section. Evidence: \`grep -P '<h[1-6][^>]*>[^<]*\p{Emoji}'\` → 0; \`grep -riE 'lorem|ipsum'\` → 0; reviewer note for the rest.` | owner's taste rule (existing item); motion/contrast parts go to row 19. Font/icon-library traits (Inter, Lucide, shadcn, Space Grotesk, em dashes) not added: taste, no framework. "Too much empty space" contradicts iv1.1#2; not added.
19. iv2.2#8, iv2.2#10, iv3.4#14 | core.md · Accessibility item | append: `contrast checked in both light and dark schemes; \`prefers-reduced-motion\` disables non-essential animation, and auto-playing motion over 5 s can be paused (2.2.2); toasts/status messages use \`role="status"\` or \`aria-live\` (4.1.3); single-key shortcuts, if any, are remappable or can be turned off (2.1.4). Evidence: axe run per colour scheme; a reduced-motion emulation screenshot; DOM check of the toast container.` | WCAG 2.2 https://www.w3.org/TR/WCAG22/ (verified: 2026-09); web.dev prefers-reduced-motion https://web.dev/articles/prefers-reduced-motion (verified: 2026-09). Note: the fetch summary reported SC 4.1.3 as AAA; WCAG 2.1/2.2 list it as AA — recheck the level before writing it.
20. iv5.3#27 (rest) | web.md · "Structured Data" | append: `\`LocalBusiness\` JSON-LD with \`name\` and \`address\` when the site is a local business (BRIEF §2), validated with the Rich Results Test; visible name/address/phone match the schema.` | Google LocalBusiness https://developers.google.com/search/docs/appearance/structured-data/local-business (verified: 2026-09)
21. iv5.3#27 (rest) | web.md · "Broken link checking" | append: `every page is reachable through at least one crawlable \`<a href>\` with descriptive anchor text (no "click here"). Evidence: crawler report with 0 orphan pages.` | Google link best practices https://developers.google.com/search/docs/crawling-indexing/links-crawlable (verified: 2026-09)
22. iv5.3#27 (rest) | web.md · "Google Analytics" | append: `campaign links carry \`utm_source\`, \`utm_medium\`, \`utm_campaign\`. Evidence: one test hit attributed in the report.` | GA4 UTM https://support.google.com/analytics/answer/10917952 (verified: 2026-09)
23. iv5.4#28 | core.md · "Consent Management" | append: `no non-essential script fires before consent; "Reject all" is as prominent as "Accept all"; scrolling is not consent; no banner at all when only strictly-necessary cookies are set. Evidence: network log before consent → 0 third-party tags; screenshot of the banner.` | EDPB Guidelines 05/2020 on consent (unverified: PDF fetch failed); ePrivacy Directive 2002/58/EC Art. 5(3) (unverified); Ley 81 (unverified)
24. iv6.1#29 | landing-10-sections.md · §2 Social proof Check | append: `certifications and trust seals count only when real and linked to the issuer's verification page.` | FTC Endorsement Guides https://www.ftc.gov/business-guidance/resources/ftcs-endorsement-guides-what-people-are-asking (verified: 2026-09). Rest of iv29 COVERED (§1, §7, §8, §9, §10; landing Lead Magnet, Contact form, Share, WhatsApp; core Refund policy). Not added: response-time commitment, About page, intro video — no framework.

## 3. REJECT
| src | reason | URL |
|---|---|---|
| iv2.1#6 | Recommends glassmorphism, neumorphism, liquid glass as quality keywords; these styles fail text contrast 4.5:1 (SC 1.4.3) and non-text contrast 3:1 (SC 1.4.11) by construction unless every surface is measured. The source contradicts itself (iv2.2#8 lists the same styles as clichés). The remaining keywords are prompting vocabulary, not a standard. | https://www.w3.org/TR/WCAG22/ (verified: 2026-09) |
| fb6.2#1 (partial) | "Non-guessable admin path" — security through obscurity; rejected inside MERGE row 16. | ASVS 4.1.1 (verified: 2026-09) |

## 4a. COVERED
- fb5.1#2 → core AI "Prompt-injection defence" + saas-web "Query scoping"
- fb5.1#7 → core "Architecture Map" (+ load-test conditional for the "ceiling")
- fb5.2#5 → saas-web "Onboarding + activation metric"
- fb6.1#3 → landing "CRO Tooling" + core "Analytics Check" (vague; nothing to add)
- fb6.3#3 → internal-tool "CSV export / scheduled report"
- fb7.1#2 → core Privacy Policy / Terms pages (only ToS named; the other five unknown)
- iv3.1#11 → core Interface (micro-interactions, hover, skeletons, progress) + landing Polish (smooth scroll, hero animation, transitions, back-to-top); scroll-progress bar not added, no framework
- iv3.2#12 → web Layout & Responsiveness + "Skip-to-content"; sticky header not added and must respect core 2.4.11 focus-not-obscured
- iv3.4#15 → saas-web Account lifecycle / UI states / Onboarding; core Error Logging, Analytics, a11y; web responsiveness; payments conditional; permissions → saas-web Query scoping + RLS

## 4b. OUT-OF-SCOPE
- fb4.1#1–#6 → content marketing / AI readiness strategy
- fb4.2#1–#4 → adoption, change management, ROI measurement
- fb4.3#3 → personal productivity
- fb4.4#1, #2 → careers; vague ("route optimization")
- fb5.1#3, #4, #5, #9, #11 → market selection, discovery, support strategy, prioritization
- fb5.1#6 → "protect your code": unactionable
- fb5.2#4 → lifecycle marketing (re-engagement email)
- fb5.3#1 → vertical strategy
- fb5.4#1 → workflow (second-AI review) → WORKFLOW.md candidate, not a standard
- fb5.4#2, #3 → procurement / AI readiness
- fb6.1#4, #5, #6, #8 → finance, client selection, entity registration, ROI process
- fb6.2#2, #3 → automation triage
- fb6.3#1 → sales tax nexus: finance/jurisdiction-specific (possible BRIEF §8 question)
- fb6.3#2, #4 → sales process (proposals, change orders, SOW)
- fb6.4#1 → strategy wording
- fb7.2#2 → SOC 2 sales pitch ("60 days"); technical baseline already in core ASVS self-check
- iv1.1#1, #3 → component-prompt workflow → WORKFLOW.md candidate
- iv1.2#4 → prospecting workflow; caution: republishing a business's Google Maps photos without consent is a copyright/consent exposure
- iv1.2#5 → same workflow
- iv2.1#7 → prompting vocabulary
- iv6.2#30, #31 → skills-catalog candidates (below)
- iv6.3#32 → sponsored (Manus); "free for a limited time" unverified

## 5. Skills-catalog candidates (iv6.2)
Components/motion: motion.dev; React Bits; 21st.dev; Aceternity UI (name likely); shadcn/ui; "coconut.ui" (name unverified); Spline (3D); Haikei (backgrounds, name likely); unnamed charts site (screen-only).
Inspiration: Dribbble; Mobbin; "Vault Gallery" (name unverified).
Workflow candidates (not catalog, not standards): iv1.1#1 component-prompt workflow; fb5.4#1 review with a second model.

## Risks and unverified
- Verified this session (14): WCAG 2.2, web.dev reduced-motion, GDPR Arts 9/12/17/28, Stripe fulfillment + webhooks + Smart Retries, Google email sender guidelines, Google LocalBusiness + link best practices, ASVS 4.0.3 V4, NN/g password masking + progressive disclosure, OWASP LLM05:2025, GA4 UTM, FTC Endorsement Guides.
- Unverified after retries (6): EDPB 05/2020 + ePrivacy 5(3) (row 23), HIPAA 164.312 (row 4), MASVS-NETWORK-1 (row 8), Material spacing (row 17), Google coverage blog (row 9), GA4 cohorts (row 12). Ley 81 de 2019 cited from memory only. ASVS was verified at 4.0.3, not 5.0 (5.0 URL 404'd; IDs differ there).
- WCAG SC 4.1.3 level: fetch summary said AAA, I believe AA. Check before writing.
- Rows 3 and 15 rest on vendor docs, not a standards body; drop them if the bar is "framework-mandated only".
- Fetch budget: 26 calls (over the ~20 target) because 7 first attempts returned no body.
</agent-message>

***
## Part B. Engineering + AI report
### Conclusion
142 actions in the slice. 9 ADD items (17 actions) and 14 MERGE items (31 actions) survive; the rest are covered (38), out of scope (55) or rejected (1). All ADD/MERGE rows are checkable and carry a framework reference; 20 framework pages fetched and read this session (23 fetches incl. 3 redirects). Nothing was edited.

Files read: `/Users/user/SynologyDrive/code/ai/claude/Projects/personal_skills/vibe-to-product/skills/v2p/references/standards/{core,web,landing,saas-web,internal-tool,native-app}.md`, `facebook-video-suggested-actions.md` L325–739, `ivanvibecodes-video-suggested-actions.md` L276–301. Sub-bullets are `#n.m`; iv5.2#2 split into 2a (JS) / 2b (fonts).

### 1. Counts
| verdict | actions | distinct items |
|---|---|---|
| COVERED | 38 | — |
| ADD | 17 | 9 |
| MERGE | 31 | 14 |
| REJECT | 1 | 1 |
| OUT-OF-SCOPE | 55 | — |

### 2. ADD + MERGE table
`src ids | target file · block | exact item text | framework ref + URL + marker`

### ADD
| src | target | item text | framework |
|---|---|---|---|
| fb2.1#3, fb3.1#1 | core.md · AI feature block | `- [ ] **Evals in CI:** a held-out eval set (edge cases and injection attempts included) is graded automatically — exact-match or code check where possible, LLM-as-judge with a different model for subjective criteria — and runs in CI with a pass threshold; a score below it blocks the deploy. Evidence: the eval file path and the last CI run's score vs threshold.` Correction: evals add to deterministic tests, they do not "replace assertions". | Anthropic, Create strong empirical evaluations https://platform.claude.com/docs/en/docs/build-with-claude/develop-tests (verified: 2026-09); NIST AI RMF MEASURE https://www.nist.gov/itl/ai-risk-management-framework (unverified) |
| fb2.1#4.1 | core.md · "audience > 100 concurrent" block | `- [ ] **Progressive rollout:** a new version reaches a slice of traffic first (canary or feature-flag percentage) and the SLO alert is the promote/rollback gate. Evidence: rollout config and one promotion or rollback log.` | Google SRE Workbook, Canarying Releases https://sre.google/workbook/canarying-releases/ (verified: 2026-09) |
| fb2.2#4.2, #4.3 | core.md · payments block | `- [ ] **Disputes:** a webhook or provider notification fires on a new dispute (Stripe: \`charge.dispute.created\`) and a named owner submits evidence before the deadline. Evidence: the handler or notification setting and the owner's name.` | Stripe Disputes https://docs.stripe.com/disputes (verified: 2026-09; the event name comes from the Disputes API sub-page, not fetched — unverified) |
| fb2.2#7 | core.md · Vibe-to-Product Refactor › Code Hygiene | `- [ ] **No swallowed errors:** every \`catch\` logs with context or rethrows; no empty catch blocks. Evidence: \`rg -nU "catch\s*(\([^)]*\))?\s*\{\s*\}" src\` → 0, or ESLint \`no-empty\` (in \`recommended\`, \`allowEmptyCatch: false\`) with \`eslint . --max-warnings 0\` → exit 0.` | ESLint no-empty https://eslint.org/docs/latest/rules/no-empty (verified: 2026-09) |
| fb2.3#4.1, #4.2, fb2.4#16 | core.md · Backend Additions | `- [ ] **Long-running work:** no HTTP request runs past the platform timeout; work over ~10 s is enqueued and answered with \`202\` plus a status URL (\`Location\`, \`Retry-After\`) or a webhook. Evidence: the job handler and one \`202\` response with its status URL.` Correction: the video says "containerize"; the control is queue + status endpoint, hosting is irrelevant. | Azure Architecture Center, Asynchronous Request-Reply https://learn.microsoft.com/en-us/azure/architecture/patterns/async-request-reply (verified: 2026-09) |
| fb2.3#7, fb2.4#17 | core.md · Backend Additions | `- [ ] **Connection pooling:** serverless/edge code reaches Postgres through a pooler (Neon \`-pooler\` host, Supabase pooler, PgBouncer); migrations and admin tasks use the direct connection. Evidence: the runtime connection-string host and the pool size setting.` | Neon, Connection pooling https://neon.com/docs/connect/connection-pooling (verified: 2026-09) |
| fb2.4#7.1 | core.md · Security › Access & Authentication | `- [ ] **CSRF protection:** every cookie-authenticated state-changing endpoint requires a synchronizer or signed double-submit token, or rejects \`Sec-Fetch-Site: cross-site\`; session cookies are \`SameSite=Lax\` or stricter as defence in depth. N/A for bearer-token-only APIs. Evidence: a cross-origin POST without the token → 403.` Correction: "request signing on every mutating endpoint" is the inbound-webhook control (already in the webhooks block); for first-party sessions the control is CSRF. | OWASP CSRF Prevention Cheat Sheet https://cheatsheetseries.owasp.org/cheatsheets/Cross-Site_Request_Forgery_Prevention_Cheat_Sheet.html (verified: 2026-09) |
| fb3.2#1.1, #1.2, #1.3, fb3.2#6 | core.md · AI feature block | `- [ ] **Agent least privilege (OWASP LLM06):** each agent/tool runs on its own short-lived, minimum-scope credential in the acting user's context; high-impact actions (payments, deletes, outbound sends) wait for human approval; every tool call is logged with a run id; each run has a max step count and a timeout. Evidence: the credential scope, the approval code path, one run log, and the step/timeout config.` Note: the video's "NIST says" source is not identified; OWASP is the reference used. "State file / chunking" (fb3.2#6) is coding-agent workflow advice; the checkable product version is the step/timeout bound. | OWASP LLM06:2025 Excessive Agency https://genai.owasp.org/llmrisk/llm062025-excessive-agency/ (verified: 2026-09); LLM10:2025 for bounds https://genai.owasp.org/llmrisk/llm102025-unbounded-consumption/ (verified: 2026-09) |
| iv5.2#2b | web.md · Frontend Additions | `- [ ] **Font loading:** WOFF2, subset via \`unicode-range\`, \`font-display: swap\` or \`optional\`, \`preconnect\` to any third-party font origin. Evidence: Lighthouse "Ensure text remains visible during webfont load" passes and the CLS attribution shows no font-swap shift.` | web.dev Font best practices https://web.dev/articles/font-best-practices (verified: 2026-09) |

### MERGE
| src | existing item | added wording | framework |
|---|---|---|---|
| fb2.1#2.1, #8.1, #8.2 | core.md · **CI/CD Pipeline** | append: `; dev, staging and production are separate deployments with their own database and env vars, and production deploys only from CI after the test job passes. Evidence: the CI workflow with the test job as a required step, and the three environment names/URLs.` | Twelve-Factor X Dev/prod parity https://12factor.net/dev-prod-parity (verified: 2026-09) |
| fb2.1#6.1 | core.md · **Rollback Strategy** | append: `; rehearsed once before launch. Evidence: rehearsal log with timestamp and elapsed time.` Correction: "under 60 s" is the video's number; DORA defines failed-deployment recovery time but sets no threshold. | DORA metrics https://dora.dev/guides/dora-metrics-four-keys/ (verified: 2026-09) |
| fb2.2#3, #5.2, #5.3 | core.md · **Incident readiness** | append: `; an incident comms template (who posts, where, update cadence); post-mortems are blameless, filed in \`docs/incidents/\` within a fixed window (e.g. 48 h) and reviewed. Evidence: template path and the folder.` Note: 48 h is the video's number; the SRE book sets none. | SRE book, Managing Incidents https://sre.google/sre-book/managing-incidents/ and Postmortem Culture https://sre.google/sre-book/postmortem-culture/ (verified: 2026-09) |
| fb2.3#2.3 | saas-web.md + internal-tool.md · **Database Indexing Audit** | append: `; slow-query logging on (Postgres \`log_min_duration_statement\`, e.g. 250ms) and \`EXPLAIN ANALYZE\` of the top queries shows no sequential scan on large tables. Evidence: the setting value and one EXPLAIN output.` | PostgreSQL runtime-config-logging https://www.postgresql.org/docs/current/runtime-config-logging.html (verified: 2026-09) |
| fb2.3#12 | core.md · **Caching Strategy** | append: `; every cache entry has a TTL and an invalidation on write; personalized responses are \`Cache-Control: private, no-cache\`, never shared. Evidence: cache key list with TTLs, and one write followed by a read returning the new value.` | MDN HTTP caching https://developer.mozilla.org/en-US/docs/Web/HTTP/Guides/Caching (verified: 2026-09) |
| fb2.3#2.2, fb2.4#2.1, #2.2, #4.1, #4.2, #4.3 | core.md · **Prevention of sensitive field manipulation** (currently unlabeled, no evidence) | rewrite as: `- [ ] **Prevention of sensitive field manipulation (OWASP API3):** request bodies are schema-validated against an allow-list of writable fields; admin-only fields are never writable from user endpoints; responses and server-component props carry only the fields the client renders (no \`SELECT *\` / \`to_json()\` pass-through). Evidence: a test posting \`role\`/\`isAdmin\` → 400/403 with the record unchanged, and one response payload inspected for extra fields.` | OWASP API3:2023 https://api-security.owasp.org/editions/2023/en/0xa3-broken-object-property-level-authorization (verified: 2026-09) |
| fb2.4#5.2 | saas-web.md · **Query scoping** | append: `; record IDs exposed in URLs are non-sequential (UUID/ULID). Evidence: one URL.` | OWASP API1:2023 BOLA https://api-security.owasp.org/editions/2023/en/0xa1-broken-object-level-authorization (verified: 2026-09) |
| fb2.4#7.2, #7.3, #21.1–3, #22.1, #22.2 | core.md · **API Documentation** | append: `; when third parties call the API: path versioned (\`/v1/\`), a changelog, and breaking changes ship as a new version with \`Deprecation\`/\`Sunset\` headers on the old one. Evidence: OpenAPI path; \`curl -sI\` of a deprecated route showing \`Sunset\`.` Correction: "from day one" for a first-party-only API is speculative; conditional on external consumers. | RFC 8594 Sunset header https://www.rfc-editor.org/rfc/rfc8594 (unverified); Microsoft REST API Guidelines https://github.com/microsoft/api-guidelines (unverified) |
| fb2.4#9.2 | core.md · **Database Migrations** | append: `; schema changes follow expand-then-contract (add before remove), every migration has a tested down step, and runs on staging before production. Evidence: migration files with up/down and the staging run log.` | Prisma Data Guide, Expand and contract https://www.prisma.io/dataguide/types/relational/expand-and-contract-pattern (verified: 2026-09) |
| fb2.4#19 | core.md · **Graceful Degradation** | append: `; every outbound HTTP call has a timeout and a handled failure path with a visible fallback state. Evidence: a test with the upstream mocked to hang/fail shows the fallback.` | SRE book, Addressing Cascading Failures https://sre.google/sre-book/addressing-cascading-failures/ (unverified) |
| fb2.1#3 (cost part), fb3.1#2 | core.md · AI feature block · **Per-user AI usage limits** | append: `; per-request token usage is logged and a spend cap or budget alert is set at the provider; prompt caching is on for stable system prompts where supported. Evidence: the provider budget setting and one usage log line.` Correction: batch API and model tiering are cost optimizations, not gates. | OWASP LLM10:2025 Unbounded Consumption https://genai.owasp.org/llmrisk/llm102025-unbounded-consumption/ (verified: 2026-09) |
| fb3.2#2.1, #2.2, #2.3 | core.md · **Zero secrets exposed in frontend code** (currently no evidence) | append: `Evidence: \`grep -rE 'sk_live|service_role|SECRET' .next/static dist/\` → 0 on the production build; Next.js: secret-using modules \`import 'server-only'\` and no secret carries the \`NEXT_PUBLIC_\` prefix.` Correction: non-`NEXT_PUBLIC_` vars are replaced with empty strings in the client bundle; the real leak paths are the `NEXT_PUBLIC_` prefix or a server module imported into a client component, not Server Actions per se. | Next.js, Preventing environment poisoning https://nextjs.org/docs/app/getting-started/server-and-client-components#preventing-environment-poisoning (verified: 2026-09) |
| iv5.1#5 | web.md · **Removal of all placeholder texts** | append: `, including test contact details. Evidence: \`rg -in 'lorem|example\.com|555-|test@' src public\` → 0.` | none needed (QA grep) |
| iv5.1#10 | core.md · **Critical Path Test** | append: `in a fresh browser profile as a new user.` | none needed |

### 3. REJECT
| src | action | reason + URL |
|---|---|---|
| fb3.2#11 | "Start with orchestrator" | Pattern preference that contradicts Anthropic's guidance to start with the simplest solution and add multi-agent orchestration only when measured need appears. https://www.anthropic.com/research/building-effective-agents (unverified) |

### 4. COVERED
- fb2.1#1 → core CI/CD Pipeline
- fb2.2#1.1, #1.3 → core Observability ("error pages reveal nothing internal")
- fb2.2#1.2 → core Error Logging
- fb2.2#2.1 → core Log Structuring + Observability
- fb2.2#4.1 → core payments block Refund policy
- fb2.2#5.1 → core Incident readiness (post-mortem template)
- fb2.3#2.1 → saas-web/internal-tool Database Indexing Audit
- fb2.3#9.1, #9.2 → core Observability + Core Web Vitals Audit
- fb2.3#13 → core Architecture Map + Module map
- fb2.4#3.1 → saas-web/internal-tool RLS
- fb2.4#3.2 → saas-web Query scoping (user A/B evidence test)
- fb2.4#5.1, #5.3, #5.4, #5.5 → saas-web Query scoping
- fb2.4#6.1 → core Single owner per concern (one call site is the cheap "abstraction layer")
- fb2.4#20.1 → core Server-side input validation
- fb2.4#20.2, #20.3 → saas-web Query scoping
- fb3.2#8.1, #8.2 → core Error Logging (LogRocket) / landing CRO Tooling (Clarity)
- fb3.3#1.2 → core evidence rule (audit → fix → rerun is the v2p loop itself)
- fb3.3#3.1, #3.2 → core Architecture Map + Module map
- iv5.1#1 → web Broken link checking + Removal of unused navigation links
- iv5.1#2 → web Forms & Validation + saas-web UI states
- iv5.1#3 → web Layout & Responsiveness
- iv5.1#4 → web Cross-browser compatibility testing
- iv5.1#6 → web Copyright year current
- iv5.1#7 → web Clickable Logo, Phone, and Email
- iv5.1#8 → web Broken link checking + core Critical Path Test + saas-web Payment Test
- iv5.1#9 → core Accessibility (a11y) + Security section
- iv5.2#1 → core Image compression
- iv5.2#2a (JS) → web Bundle Size Analysis
- iv5.2#3 → core Core Web Vitals Audit (CLS)
- iv5.2#4 → core Page load time auditing + Lighthouse Audit

### 4b. OUT-OF-SCOPE
- fb2.1#2.2, #4.2, #6.2, fb2.2#1.4, #2.2, fb2.3#2.4, fb2.4#9.1, fb3.2#8.3, #8.4 → rhetorical, no action
- fb2.1#5, #7 → extraction artefacts ("Push to main", "Deploy again"), no actionable content
- fb2.2#6 → support-ops process
- fb2.3#1.1, #1.2, fb3.2#9.1, #9.2 → business opinion (rent vs own)
- fb2.3#3.1–#3.4 → cost/business, not checkable
- fb2.3#5, #6, #8, fb2.4#11, #12, #13, #14, #15.1, #15.2, #18 → vendor/architecture choice, not a standard
- fb2.3#10 → multi-region: project-specific; static path already covered by CDN Integration
- fb2.3#11.1–#11.3 → only with read replicas; project-specific
- fb2.4#1 → business opinion
- fb2.4#6.2 → BAA audit: HIPAA-specific
- fb2.4#8.1–#8.3 → enterprise multi-tenant; project-specific
- fb2.4#10.1, #10.2 → CDC: project-specific
- fb3.2#3.1, #3.2, #5.1, #5.2, #10 → developer tooling hygiene (MCPs, skills, instruction files), not a product standard
- fb3.2#4.1–#4.3 → product/business management
- fb3.2#7 → workforce/support tiers
- fb3.3#1.1, #2.1, #2.2 → product/marketing
- fb3.3#4 → "three gaps" unspecified
- fb3.4#1 → slogan

### Risks and unverified
- Unverified refs: NIST AI RMF page, RFC 8594, Microsoft REST guidelines, SRE "Addressing Cascading Failures", Anthropic "Building effective agents", Stripe event name `charge.dispute.created`. Everything else fetched and read this session.
- Assumption: BRIEF §9 already switches the ">100 concurrent" and "payments" blocks, so A2/A3 need no new switch. The API-versioning MERGE introduces an implicit condition ("third parties call the API") that has no BRIEF switch; if that matters, add it to §9 or fold into the OpenAPI item as written.
- The "Prevention of sensitive field manipulation" MERGE rewrites an unlabeled item; internal-tool.md repeats the same unlabeled line and should get the same text or a pointer to core.
- Ponytail judgement calls: A2 (canary) and M8 (versioning) are conditional on scale/external consumers; if the caller wants a leaner core, drop A2 first.
</agent-message>

***
## Part C. Security report
### Security slice — verdicts

Source files: `/Users/user/SynologyDrive/code/ai/claude/Projects/personal_skills/vibe-to-product/facebook-video-suggested-actions.md` (§1, lines 9–324) and `/Users/user/SynologyDrive/code/ai/claude/Projects/personal_skills/vibe-to-product/ivanvibecodes-video-suggested-actions.md` (§4, lines 176–273). Ivan ids: `iv4.2#1.b5` = section 4.2, item 1, bullet 5.
Standards: `/Users/user/SynologyDrive/code/ai/claude/Projects/personal_skills/vibe-to-product/skills/v2p/references/standards/{core,web,landing,saas-web,internal-tool,native-app}.md`.

#### 1. Counts (94 actions: 50 fb items, 44 ivan bullets)
| verdict | fb | ivan | total |
|---|---|---|---|
| ADD (into 18 distinct new items) | 17 | 14 | 31 |
| MERGE (into 13 existing items) | 14 | 9 | 23 |
| COVERED | 12 | 19 | 31 |
| REJECT | 1 | 0 | 1 (+2 sub-bullets rejected inside otherwise-accepted items) |
| OUT-OF-SCOPE | 6 | 2 | 8 |

Verification legend: ASVS 5.0 = `https://github.com/OWASP/ASVS/blob/master/5.0/en/<chapter file>` (verified: 2026-09 for V1, V2, V3, V4, V5, V6, V7, V8, V9, V10, V13, V16). NIST = SP 800-63B rev4, `https://pages.nist.gov/800-63-4/sp800-63b.html` (verified: 2026-09). API Top 10 2023 = `https://api-security.owasp.org/editions/2023/en/0x11-t10` (verified: 2026-09). LLM Top 10 2025 = `https://genai.owasp.org/llm-top-10/` (verified: 2026-09). OWASP Top 10:2025 page only returned a redirect stub → cited `(unverified)`.

### 2. ADD + MERGE table
`src ids | target file · block | exact item text | framework ref + URL + marker`

**ADD — new items**

| src | target | item text | framework |
|---|---|---|---|
| fb1.1#4, fb1.1#5, fb1.2#1, fb1.2#5, iv4.2#1.b1, iv4.6#2.b3 | core.md · Security › Access & Authentication | `- [ ] **Auth by default:** every route, RPC procedure, server action, realtime subscription/channel and cron/internal endpoint passes through one shared server-side guard; public routes are an explicit allowlist; scheduled endpoints require a secret bearer header (e.g. Vercel `CRON_SECRET`). Middleware-only checks don't count. Evidence: an automated test that calls every registered route unauthenticated and expects 401/403 except the allowlist; one realtime subscription test where user A never receives user B's events.` | ASVS 5.0 7.2.1, 8.2.1, 8.3.1 (L1) `0x16-V7`, `0x17-V8` (verified: 2026-09); API5:2023 (verified: 2026-09); Vercel `https://vercel.com/docs/cron-jobs/manage-cron-jobs#securing-cron-jobs` (verified: 2026-09) |
| fb1.1#6, fb1.1#14 | core.md · Security Additions (next to Session Management) | `- [ ] **Token verification** (when using JWT or other self-contained tokens): signature or MAC checked on every request; algorithm allowlist that excludes `none`; `exp`, `iss` and `aud` validated; keys only from the pre-configured issuer source. Evidence: a test sending a tampered payload and an `alg: none` token → 401.` | ASVS 5.0 9.1.1, 9.1.2, 9.1.3, 9.2.1 (L1), 9.2.3 `0x18-V9` (verified: 2026-09); RFC 8725 §3.1, 3.2, 3.8, 3.9 `https://www.rfc-editor.org/rfc/rfc8725.html` (verified: 2026-09) |
| fb1.1#7, fb1.1#18 | core.md · Security › Access & Authentication | `- [ ] **OAuth / social login** (when present): authorization-code flow with PKCE (S256) and a one-time `state`; redirect URIs registered as exact strings; only the scopes the app needs; access/refresh tokens stay server-side (BFF), never in browser JS. Evidence: the captured authorization request URL showing `code_challenge` and `state`, and the provider console's redirect-URI list.` | RFC 9700 §2.1, 2.1.1 `https://www.rfc-editor.org/rfc/rfc9700.html` (verified: 2026-09); ASVS 5.0 10.4.1 (L1), 10.2.1, 10.4.6, 10.1.1, 10.2.3 `0x19-V10` (verified: 2026-09) |
| fb1.1#3, iv4.2#1.b6, iv4.8#1.b5 | core.md · Security › Access & Authentication | `- [ ] **Reset and magic links:** password-reset, invite and magic-link tokens are random, expire within 1 hour (15 min preferred) and are invalidated on first use; reset does not bypass MFA. Evidence: a test that reuses a consumed link and one that uses an expired link, both rejected.` | ASVS 5.0 6.4.1 (L1), 6.4.3 `0x15-V6` (verified: 2026-09); OWASP Forgot Password Cheat Sheet `https://cheatsheetseries.owasp.org/cheatsheets/Forgot_Password_Cheat_Sheet.html` (unverified). Note: the 15-min figure is the video's; frameworks say "short", not a number. |
| iv4.8#1.b3 (breached passwords) | core.md · Security › Access & Authentication | `- [ ] **Password policy per NIST:** length-only policy (no composition rules, no periodic expiry); new and changed passwords are checked against a breached/common-password list (e.g. HIBP k-anonymity, ≥ top 3000). Evidence: setting `Password123!` is rejected; a long lowercase passphrase is accepted.` | NIST 800-63B r4 §3.1.1.2 (SHALL compare against blocklist; SHALL NOT impose composition rules or periodic change) (verified: 2026-09); ASVS 5.0 6.2.4 (L1), 6.2.12 (L2) (verified: 2026-09) |
| iv4.2#1.b7 | core.md · Security › Access & Authentication | `- [ ] **No user enumeration:** login, sign-up and password-reset return the same message and status whether or not the account exists. Evidence: reset for an unknown email returns the same body/status as for a known one.` | OWASP Authentication Cheat Sheet (identical messages) `https://cheatsheetseries.owasp.org/cheatsheets/Authentication_Cheat_Sheet.html` (verified: 2026-09); ASVS 5.0 6.3.8 (L3 — note level) (verified: 2026-09) |
| iv4.5#1.b3 | core.md · Security › Network & Headers | `- [ ] **CSRF:** state-changing requests need an anti-forgery token or a non-safelisted custom header / `Sec-Fetch-Site` check, and the session cookie is `SameSite=Lax` or `Strict`; sensitive actions never on GET. N/A for pure bearer-token APIs (cite BRIEF). Evidence: a cross-origin form POST from a test page → 403.` | ASVS 5.0 3.5.1, 3.5.3 (L1), 3.3.2 `0x12-V3` (verified: 2026-09) |
| fb1.2#3 | core.md · Security › Network & Headers | `- [ ] **Redirect allowlist:** every redirect target (`next`, `returnTo`, post-login, OAuth callback) is validated as same-origin or against an allowlist; encoded, protocol-relative and `javascript:` variants are rejected. Evidence: `?next=//evil.example` and `?next=%2F%2Fevil.example` both stay on the site.` | ASVS 5.0 3.7.2 (L2), 1.2.2 (L1) (verified: 2026-09); CWE-601 `https://cwe.mitre.org/data/definitions/601.html` (unverified) |
| fb1.1#2, fb1.2#10, iv4.3#1.b4 | core.md · Security Additions | `- [ ] **Backend service auth:** database, cache, queue and storage accept connections only with credentials and only from the app network; no default users/passwords; the app's DB role is least-privilege (not superuser/owner); cache ACLs limited to the commands used. Evidence: a connection attempt from outside the network is refused, and `SELECT rolsuper FROM pg_roles WHERE rolname = current_user` → `f` (or the store's equivalent).` | ASVS 5.0 13.2.1, 13.2.2, 13.2.3 (L2) `0x22-V13` (verified: 2026-09); OWASP Top 10 A05 Security Misconfiguration `https://owasp.org/Top10/` (unverified) |
| fb1.2#12 | core.md · Backend & API › Data & Logic | `- [ ] **Outbound URL allowlist (SSRF):** any server-side fetch of a user- or model-supplied URL is limited to allowlisted protocols/hosts, blocks private and link-local ranges (incl. `169.254.169.254`), and pins the resolved IP across redirects. Evidence: a test submitting `http://169.254.169.254/` and one redirecting to an internal host, both rejected.` | ASVS 5.0 1.3.6, 13.2.4, 13.2.5 (L2) (verified: 2026-09); API7:2023 SSRF (verified: 2026-09); LLM06:2025 Excessive Agency for agent tools (verified: 2026-09) |
| iv4.4#1.b4 | core.md · Backend & API › Data & Logic | `- [ ] **Dangerous sinks audit:** no shell command built from input, no `eval`/dynamic code, no unsafe deserialization of untrusted data (pickle, `yaml.load`, native Java/PHP), XML parsers with external entities off. Evidence: `rg -n "exec\(|execSync|shell: true|eval\(|pickle\.loads|yaml\.load\(|unserialize\("` → 0 hits, or each hit justified in `docs/threat-model.md`.` | ASVS 5.0 1.2.5, 1.3.2, 1.5.1 (L1), 1.5.2 (L2) `0x10-V1` (verified: 2026-09) |
| iv4.8#1.b1 | core.md · Backend & API › Backend Additions | `- [ ] **Security event log:** login success/failure, password/email change, privilege change and authorization denials are logged with who/when (UTC)/where/what, never with credentials or tokens, and shipped off-host. Evidence: one failed-login log line with user id, IP and UTC timestamp in the external log store.` | ASVS 5.0 16.2.1, 16.2.5, 16.3.1, 16.3.2, 16.4.3 (L2) `0x25-V16` (verified: 2026-09) |
| iv4.4#1.b7, iv4.8#1.b6 | core.md · Pre-flight › Environment & Config | `- [ ] **Debug surface off:** debug mode, directory listing, `.git`/source maps, TRACE, and default admin/docs/metrics routes are not reachable in production. Evidence: `curl -s -o /dev/null -w '%{http_code}' https://x/.git/HEAD` → 404, same for `/debug`, `/metrics`, and an unauthenticated `/admin` → 401/404.` | ASVS 5.0 13.4.1 (L1), 13.4.2–13.4.5 (L2) (verified: 2026-09) |
| fb1.2#19 | core.md · Quality Assurance | `- [ ] **DAST baseline:** OWASP ZAP baseline scan against staging with 0 FAIL. Evidence: `zap-baseline.py -t https://staging.x -J zap.json` exit code 0 (or 2 = warnings only) and the report path.` | ZAP baseline docs `https://www.zaproxy.org/docs/docker/baseline-scan/` (verified: 2026-09) |
| fb1.2#4 | core.md · Conditional blocks — new `### If the API is GraphQL` | `- [ ] **GraphQL hardening:** introspection disabled in production; query depth/complexity limit; field suggestions off in errors. Evidence: an introspection query in prod → error, and a 20-level nested query → rejected.` | ASVS 5.0 4.3.1, 4.3.2 (L2) `0x13-V4` (verified: 2026-09); field suggestions: OWASP GraphQL Cheat Sheet `https://cheatsheetseries.owasp.org/cheatsheets/GraphQL_Cheat_Sheet.html` (unverified) |
| iv4.4#1.b5 | core.md · Conditional blocks — new `### If the product accepts file uploads` | `- [ ] **Upload controls:** size cap; extension and content both checked against an allowlist; stored under a generated name outside the web root or in object storage; never executable; access via auth or signed URL. Evidence: `shell.php` renamed `.png` → rejected; direct URL to an uploaded file without auth → 401/403.` | ASVS 5.0 5.2.1, 5.2.2, 5.3.1, 5.3.2 (L1) `0x14-V5` (verified: 2026-09) |
| fb1.1#9, fb1.2#16.b2, iv4.5#1.b4 | web.md · Frontend Additions | `- [ ] **Third-party scripts:** every external script/origin is listed; static third-party assets carry `integrity` + `crossorigin`; login, checkout and admin pages load no third-party scripts. Evidence: the origin list from the CSP, `rg -c 'integrity="sha' ` on the rendered HTML, and a DevTools network capture of the login page showing no third-party JS.` | MDN SRI `https://developer.mozilla.org/en-US/docs/Web/Security/Subresource_Integrity` (verified: 2026-09); ASVS 5.0 3.6.1 (L3 — note level) (verified: 2026-09) |
| fb1.4#1.b1 | web.md · Pre-flight › DNS & Domain | `- [ ] **No dangling records:** every A/CNAME points at a resource you still control; records for decommissioned services are removed. Evidence: `dig +short` per record and each CNAME target resolving to a live, owned service.` | OWASP WSTG-CONF-10 Test for Subdomain Takeover `https://owasp.org/www-project-web-security-testing-guide/` (unverified — page 404'd on two paths) |

**MERGE — added wording on existing items**

| src | existing item (file) | added wording | framework |
|---|---|---|---|
| fb1.1#1, fb1.1#8.b2-3, fb1.1#11, fb1.1#12, fb1.1#16.b2, iv4.2#1.b4 | **Session Management** (core.md Security Additions; duplicate copy in saas-web.md Data & Logic — change both or drop the copy) | `…; a new session token is issued on every login and privilege change; logout, password change and account disable invalidate the session server-side; idle and absolute timeouts are written down (AAL2 reference: 1 h idle / 24 h absolute) and the UI warns before expiry. Evidence: log in, copy the session cookie, log out, replay it → 401.` | ASVS 5.0 7.2.4, 7.4.1, 7.4.2 (L1), 7.3.1, 7.3.2, 7.4.3 (L2) (verified: 2026-09); NIST 800-63B r4 AAL2 reauth (verified: 2026-09) |
| fb1.1#8.b1, fb1.2#11.b2, fb1.4#1.b2, iv4.2#1.b3, iv4.5#1.b6 | **HTTP-Only and Secure cookie flags** (core.md Data Protection) | `…plus `SameSite`; session cookie named with the `__Host-` prefix (no `Domain` scope); session tokens never in `localStorage`/`sessionStorage`. Evidence: `curl -sI` shows `Set-Cookie: __Host-…; Secure; HttpOnly; SameSite=Lax` and `rg -n "localStorage.*token"` → 0.` | ASVS 5.0 3.3.1 (L1), 3.3.2, 3.3.3, 3.3.4 (L2), 10.1.1 (verified: 2026-09) |
| fb1.2#2, fb1.2#15, fb1.2#26, iv4.5#1.b1-2 | **Implementation of Security Headers** (core.md Network & Headers) | `: HSTS max-age ≥ 1 year; `X-Content-Type-Options: nosniff`; `Referrer-Policy`; `Permissions-Policy`; CSP `frame-ancestors 'none'` (plus `X-Frame-Options: DENY` for old browsers). Evidence: `curl -sI https://x \| grep -ciE 'strict-transport\|nosniff\|referrer-policy\|frame-ancestors'` → 4.` | ASVS 5.0 3.4.1 (L1), 3.4.4, 3.4.5, 3.4.6 (L2) (verified: 2026-09) |
| fb1.2#16.b1,b3, iv4.5#1.b2 | **CSP Audit** (core.md Network & Headers) | `…; roll out as `Content-Security-Policy-Report-Only` with a `report-to` endpoint first, enforce once reports are clean; policy has `object-src 'none'`, `base-uri 'none'` and nonces/hashes or a strict allowlist. Evidence: the report endpoint's zero-violation log for 24 h before enforcing.` | ASVS 5.0 3.4.3 (L2), 3.4.7 (L3) (verified: 2026-09); MDN CSP Report-Only `https://developer.mozilla.org/en-US/docs/Web/HTTP/Reference/Headers/Content-Security-Policy-Report-Only` (unverified) |
| fb1.2#11, iv4.5#1.b5 | **CORS Policy** (core.md Security Additions) | `…; never `*` or a reflected origin together with `Access-Control-Allow-Credentials`; methods and headers restricted per endpoint. Evidence: `curl -H "Origin: https://evil.example" -I https://api.x` → no `Access-Control-Allow-Origin`.` | ASVS 5.0 3.4.2 (L1) (verified: 2026-09) |
| fb1.2#6, iv4.4#1.b1-2 | **Deep Sanitization** (core.md Data Protection) | `…; encode at output per context (HTML, attribute, JS/JSON, URL) rather than relying on input cleaning; email templates render user data as text and strip CR/LF from headers. Evidence: `<script>` and `%0d%0a` in every field of a test email arrive escaped.` | ASVS 5.0 1.1.2, 1.2.1 (L1), 1.3.11 (L2) (verified: 2026-09) |
| fb1.2#7, fb1.2#17, fb1.2#20, iv4.3#1.b2 | **Server-side input validation** (core.md Data & Logic) | `: schema-based (zod/valibot/pydantic) with unknown fields rejected (`.strict()`), so role/price/owner fields can't be set by the client; every route tested without the UI. Evidence: `POST` with an extra `role: "admin"` field → 400.` | ASVS 5.0 2.2.1, 2.2.2 (L1), 8.2.3 (L2) (verified: 2026-09); API3:2023 (verified: 2026-09) |
| fb1.2#9, iv4.4#1.b3 | **Use of parameterized queries** (core.md Data & Logic) | `…including raw queries through the ORM's tagged/parameterized method. Evidence: `rg -n "queryRawUnsafe\|executeRawUnsafe\|\$\{.*\}.*(SELECT\|INSERT\|UPDATE)"` → 0.` | ASVS 5.0 1.2.4 (L1) (verified: 2026-09) |
| fb1.2#13, iv4.2#1.b5, iv4.2#1.b6 (attempt limit), iv4.8#1.b4 | **Rate limiting for login attempts/Brute force protection** (core.md Access & Authentication) | `: throttle per account and per IP with progressive delay (or bot challenge) before any hard lockout; cap consecutive failures per authenticator at ≤ 100; a lockout must not let an attacker lock other users out (recovery flow still works); same limits on sign-up and reset. Evidence: 20 failed logins in 1 min → 429.` Correction to iv4.2#1.b5: "lock accounts after repeated failures" is allowed but is not the first control — throttling is, and lockout needs the DoS mitigation. | NIST 800-63B r4 §3.2.2 (verified: 2026-09); OWASP Authentication Cheat Sheet, lockout DoS note (verified: 2026-09); ASVS 5.0 6.3.1 (L1), 2.4.1 (L2) (verified: 2026-09) |
| fb1.2#21 | **Secrets Vault** (core.md Credentials & Secrets) | `…; each secret has an owner and a rotation schedule in `docs/secrets.md`; one rotation rehearsed. Evidence: the file plus the date of the last rotation.` | ASVS 5.0 13.1.4, 13.3.4 (L3 — note level) (verified: 2026-09) |
| fb1.1#16.b1 | **Strengthened authentication flow** (core.md Access & Authentication) | `: via a maintained auth library or provider (Auth.js, Clerk, Supabase Auth, Auth0…); no hand-written password or session code. Evidence: the dependency name and version.` Weak premise: the cheat sheet recommends maintained SDKs but does not forbid custom auth; keep as a soft rule. | OWASP Authentication Cheat Sheet (verified: 2026-09) |
| fb1.2#27 | **CDN Integration** (core.md Infrastructure Additions) | `…with the platform's WAF/DDoS protection enabled and the origin not reachable directly. Evidence: a request to the origin IP with the site's `Host` header is refused.` | ASVS 5.0 2.4.1 anti-automation (L2) (verified: 2026-09); vendor docs (Cloudflare/Vercel Firewall) (unverified) |
| iv4.4#1.b6 | **API Rate Limits** (core.md Pre-flight › Environment & Config) | `…and a request body size limit (default ≤ 1 MB, larger only on upload routes). Evidence: a 2 MB JSON body → 413.` | ASVS 5.0 5.2.1 for files (verified: 2026-09); OWASP Denial of Service Cheat Sheet `https://cheatsheetseries.owasp.org/cheatsheets/Denial_of_Service_Cheat_Sheet.html` (unverified) |

### 3. REJECT table
| src | what | reason + URL |
|---|---|---|
| fb1.2#25.b2 (item verdict REJECT; b1, b3 COVERED by native-app **Secure storage** / **Deep links**) | "Certificate pinning on every call" | Not a baseline requirement: MASVS-NETWORK-2 is a defence-in-depth/L2 control, not L1; a pin rotation mistake bricks every installed app. Keep TLS-only (already in native-app **Secure storage**). `https://mas.owasp.org/MASVS/controls/MASVS-NETWORK-2/` (unverified — page content not extractable this session) |
| fb1.2#24.b3 (sub-bullet; item COVERED) | "Endpoint protection with non-guessable URLs" for webhooks | Obscurity, not a control; signature verification is the requirement (core.md **Webhook signature verification**). ASVS 5.0 has no unguessable-URL requirement (verified: 2026-09) |
| iv4.2#1.b5 (sub-bullet; verdict MERGE with correction) | "lock accounts after repeated failures" as the primary control | Throttling first; hard lockout must carry a DoS mitigation. NIST 800-63B r4 §3.2.2 + OWASP Authentication Cheat Sheet (verified: 2026-09) |

### 4. COVERED
- fb1.1#13 → core.md **Session Management** (refresh rotation)
- fb1.1#15 → saas-web.md **Account lifecycle**, **UI states**; web.md Forms & Validation
- fb1.2#8 → core.md webhooks block **Idempotency** (same 24 h / event-id wording)
- fb1.2#13 → core.md **Rate limiting for login attempts** (see MERGE)
- fb1.2#14 → core.md **Hide all API keys**, **Purge secrets from Git history**
- fb1.2#15 → core.md **Global Error Boundaries**, **Security Headers**, **Server-side input validation**
- fb1.2#20 → core.md **Zero secrets exposed in frontend code**, **Server-side input validation**, payments **Server-side prices**
- fb1.2#22 → core.md **Supply chain**
- fb1.2#23 → saas-web.md / internal-tool.md **RLS**
- fb1.2#24 → core.md **Webhook signature verification**, **Idempotency** (b3 rejected)
- fb1.2#26 → core.md **Security Headers** (see MERGE)
- fb1.3#3 → saas-web.md **Query scoping** + **RLS** (ASVS 8.4.1)
- iv4.1#1.b1/b2/b3 → core.md **Hide all API keys**/**Zero secrets in frontend**, **Purge secrets**, **Proper usage of Database Public Keys**
- iv4.2#1.b2 → core.md **Secure password hashing**
- iv4.2#1.b8 → core.md **Bot protection**
- iv4.3#1.b1 → saas-web/internal-tool **RLS**; b2 → core.md **Prevention of sensitive field manipulation**; b3 → **Encryption of sensitive data at rest**; b5 → **Automated Backups and Backup Verification**
- iv4.4#1.b3 → core.md **Use of parameterized queries**
- iv4.5#1.b1 → core.md **Forced HTTPS redirection** + **Security Headers** (HSTS); b6 → **HTTP-Only and Secure cookie flags**
- iv4.6#1.b1/b2 → core.md **Endpoint Rate Limiting**, **API response limiting/pagination**
- iv4.6#2.b1/b2 → core.md AI block **Prompt-injection defence**, **Per-user AI usage limits**
- iv4.7#1.b1/b2 → core.md payments **Server-side prices**, webhooks **Webhook signature verification**
- iv4.8#1.b7 → core.md **Supply chain**, **Hallucinated-package check**

### OUT-OF-SCOPE
- fb1.1#10 → auth-provider "enterprise readiness": vendor/business choice, not checkable
- fb1.1#17 → Clerk vs Auth0: vendor opinion
- fb1.2#18 → "prompt/skill file supply chain": developer toolchain hygiene, not a product standard (LLM03:2025 applies to the product's own model supply chain, which is a different thing)
- fb1.3#1 → per-tenant forks vs config: architecture/business; per-tenant flags already in core.md **Feature flags**
- fb1.3#2 → SAML/SSO for enterprise buyers: sales-driven; internal-tool.md already mandates SSO for internal users
- fb1.3#4 → cyber insurance, platform terms: business
- iv4.8#1.b2 → canary tokens / honey endpoints: not in ASVS L1–L2, detection nicety
- iv4.8#1.b8 → "review AI-generated code": process, handled by the review phase; iv4.8#1.b3 "anomalous session detection" is ASVS 8.2.4 L3 → excluded (bots part is COVERED, breached-password part is an ADD)

### Risks / unverified
- OWASP Top 10:2025 category list not fetched (redirect stub only); cited only for A05 as `(unverified)`. Every ADD also carries a verified ASVS 5.0 id, so nothing rests on it.
- MASVS-NETWORK-2 and WSTG-CONF-10 pages not readable this session; the pinning REJECT and the dangling-DNS ADD rest on my recollection of those docs — flag if you want them re-checked.
- Reset-link "15 min" and body-size "1 MB" are conventions, not framework numbers; ASVS 6.4.1 says only "short period".
- Four ADD/MERGE items cite an ASVS L2/L3 requirement (SRI 3.6.1 L3, enumeration 6.3.8 L3, secrets rotation 13.1.4/13.3.4 L3, CSP report-to 3.4.7 L3). They are cheap and OWASP cheat sheets recommend them at any level, but they exceed the existing **OWASP ASVS Level 1 self-check** bar — decide whether the standards stay strictly L1.
- NIST 800-63B r4 also sets a minimum password length; I did not fetch that number, so the **Password policy** item leaves length unspecified.
- saas-web.md already duplicates core.md **Session Management** verbatim; any MERGE must hit both copies or delete the duplicate.
</agent-message>

***
Copyright © 2026 Rafael Arciniegas. Licensed under the MIT License.
