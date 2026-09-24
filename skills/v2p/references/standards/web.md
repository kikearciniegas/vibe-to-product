# Standards: web (landing, saas-web, internal-tool)

Loaded after `core.md` for every browser-based profile. Not loaded for `native-app`.

## Layout & Responsiveness
- [ ] Full responsiveness across all devices and screen sizes
- [ ] Mobile-specific navigation
- [ ] Hamburger menu implementation
- [ ] Fix mobile overflow issues
- [ ] Cross-browser compatibility testing

## Components & Content
- [ ] Custom 404 page (with suggested paths back to home/search)
- [ ] Clickable Logo, Phone, and Email
- [ ] Removal of all placeholder texts, including test contact details. Evidence: `rg -in 'lorem|example\.com|555-|test@' src public` → 0.
- [ ] Removal of unused navigation links
- [ ] **Device-specific Favicons** (Apple Touch Icon, Android Chrome, etc.)
- [ ] **Micro-copy Audit:** Action-oriented CTA text (e.g., "Get Started" $\rightarrow$ "Start My Free Trial")
- [ ] **Empty State Design:** Custom UI for "No data found" or "Your cart is empty" states (Avoid blank screens)
- [ ] **Skip-to-content link:** first focusable element on every page. Evidence: first `Tab` press focuses it.
- [ ] **Copyright year current:** footer year matches the current year. Evidence: `grep` of the rendered footer.

## Forms & Validation
- [ ] Client-side field validation for all inputs
- [ ] **Input field `autocomplete` attributes** for improved UX
- [ ] Clear success, error, and confirmation messages
- [ ] Explicit error states for form fields
- [ ] End-to-end form testing
- [ ] **Loading State Granularity:** Contextual loading messages (e.g., "Verifying Email...")
- [ ] **Request Debouncing/Throttling:** Prevent multiple identical submissions on rapid clicks
- [ ] **Password fields:** show/hide toggle; paste and password managers are not blocked; `autocomplete="current-password"` / `"new-password"`. Evidence: DOM check and one paste test. Source: NN/g, Stop Password Masking https://www.nngroup.com/articles/stop-password-masking/ (verified: 2026-09); WCAG 2.2 SC 3.3.8 https://www.w3.org/TR/WCAG22/ (verified: 2026-09).

## Frontend Additions
- [ ] **PWA Basics:** Implement `manifest.json` and a basic Service Worker for "Add to Home Screen".
- [ ] **State Management:** Implement global loading and error handling patterns.
- [ ] **Image Lazy Loading:** Implement native `loading="lazy"` or Intersection Observer for performance.
- [ ] **Bundle Size Analysis:** Run a bundle analyzer to remove heavy dependencies.
- [ ] **Font loading:** WOFF2, subset via `unicode-range`, `font-display: swap` or `optional`, `preconnect` to any third-party font origin. Evidence: Lighthouse "Ensure text remains visible during webfont load" passes and the CLS attribution shows no font-swap shift. Source: web.dev, Font best practices https://web.dev/articles/font-best-practices (verified: 2026-09).
- [ ] **Third-party scripts:** [ASVS L3] every external script/origin is listed; static third-party assets carry `integrity` + `crossorigin`; login, checkout and admin pages load no third-party scripts. Evidence: the origin list from the CSP, `rg -c 'integrity="sha'` on the rendered HTML, and a DevTools network capture of the login page showing no third-party JS. Source: MDN Subresource Integrity https://developer.mozilla.org/en-US/docs/Web/Security/Subresource_Integrity (verified: 2026-09); ASVS 5.0 3.6.1 (L3) https://github.com/OWASP/ASVS/blob/master/5.0/en/0x12-V3-Web-Frontend-Security.md (verified: 2026-09).

## SEO: Metadata & Indexing
- [ ] Custom Favicon configuration
- [ ] Correct Page Titles and Meta-descriptions per page
- [ ] Open Graph (OG) tags and custom images
- [ ] **OG Image Verification:** Use OpenGraph.xyz to verify social previews.
- [ ] Image Alt text implementation
- [ ] **Sitemap Generation:** Create and upload `sitemap.xml`.
- [ ] **Robots.txt:** Configure correct crawler access and point to the sitemap.
- [ ] **Heading hierarchy:** exactly one `h1` per page and no skipped levels. Evidence: axe rules `page-has-heading-one` and `heading-order` pass on every route. Source: WCAG 2.2 SC 1.3.1 (A), 2.4.6 (AA) https://www.w3.org/TR/WCAG22/ (verified: 2026-09).

## SEO Additions
- [ ] **Canonical Tags:** Prevent duplicate content issues.
- [ ] **Structured Data:** Implement JSON-LD for rich snippets. `LocalBusiness` JSON-LD with `name` and `address` when the site is a local business (BRIEF §2), validated with the Rich Results Test; visible name/address/phone match the schema. Source: Google, LocalBusiness structured data https://developers.google.com/search/docs/appearance/structured-data/local-business (verified: 2026-09).

## Analysis & External Tools
- [ ] **Google Search Console:** Setup and verify ownership.
- [ ] **Bing Webmaster Tools:** Setup and submit sitemap.
- [ ] **Google Analytics:** Setup and verify tracking codes. Campaign links carry `utm_source`, `utm_medium`, `utm_campaign`. Evidence: one test hit attributed in the report. Source: GA4 UTM parameters https://support.google.com/analytics/answer/10917952 (verified: 2026-09).
- [ ] **Broken link checking:** Final audit of all internal and external links. Every page is reachable through at least one crawlable `<a href>` with descriptive anchor text (no "click here"). Evidence: crawler report with 0 orphan pages. Source: Google, Link best practices https://developers.google.com/search/docs/crawling-indexing/links-crawlable (verified: 2026-09).

## Privacy
- [ ] Cookie consent banner

## Pre-flight
### DNS & Domain
- [ ] **DNS Propagation:** Verify A records, CNAME, and MX records.
- [ ] **SSL Verification:** Ensure the SSL certificate is active and auto-renews.
- [ ] **Custom Domain:** Ensure redirects from www to non-www (or vice-versa).
- [ ] **No dangling records:** every A/CNAME points at a resource you still control; records for decommissioned services are removed. Evidence: `dig +short` per record and each CNAME target resolving to a live, owned service. Source: OWASP WSTG-CONF-10 Test for Subdomain Takeover https://owasp.org/www-project-web-security-testing-guide/ (unverified).

### Environment & Config
- [ ] **Mixed Content Check:** Ensure no `http://` resources are called on an `https://` site.

***
Copyright © 2026 Rafael Arciniegas. Licensed under the MIT License.
