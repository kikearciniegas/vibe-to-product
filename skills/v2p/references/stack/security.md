# Startup stack — security and privacy per provider

Read at execute and review. Row ids `W<n>` refer to `references/stack/wiring.md`.

## GitHub
- 2FA on the account; fine-grained PATs scoped to one repo, expiring; branch protection on `main`; Dependabot alerts (free on public; private repos: enable Dependabot, and run `gitleaks`/`osv-scanner` in Actions because secret scanning/push protection are paid for private repos) (verified: 2026-09) https://docs.github.com/en/code-security/secret-scanning/introduction/about-secret-scanning

## Cloudflare
- WAF: managed free ruleset + up to 5 custom rules and 1 rate-limiting rule on Free (verified: 2026-09) https://developers.cloudflare.com/waf/custom-rules/ · https://developers.cloudflare.com/waf/rate-limiting-rules/
- Turnstile on every public form, server-side siteverify only, tokens single-use/300 s (verified: 2026-09) https://developers.cloudflare.com/turnstile/get-started/server-side-validation/
- DKIM records DNS-only (W8). Host record per host: Vercel → DNS-only (W2); Cloudflare Workers → no manual record, Cloudflare creates it on an active zone you own (W31; proxy status of that record (unverified)); Netlify → DNS-only as in W2 (W34; unverified: the Netlify page read does not mention Cloudflare proxying). Account 2FA (unverified: not fetched).

## Vercel
- Platform DDoS mitigation on all plans; WAF custom rules, IP blocking, managed rulesets, Attack Mode (plan limits (unverified)) (verified: 2026-09) https://vercel.com/docs/vercel-firewall
- Sensitive env vars + team policy (W27); runtime logs kept 1 h on Hobby → ship logs to Sentry/PostHog (verified: 2026-09) https://vercel.com/docs/limits
- Hobby is non-commercial (verified: 2026-09) https://vercel.com/docs/limits/fair-use-guidelines

## Supabase
- RLS on every table, policies keyed on `auth.jwt()->>'sub'` (with Clerk) or `auth.uid()`; `sb_secret_` never in the client; dashboard TOTP MFA; org-wide MFA enforcement on Pro/Team/Enterprise; no recovery codes → register a backup TOTP (verified: 2026-09) https://supabase.com/docs/guides/platform/multi-factor-authentication
- Region chosen at project creation (EU for EU audiences) (unverified: regions page not fetched); DPA at supabase.com/legal/dpa (unverified).

## Clerk
- End-user MFA is Pro-only; allowlist/blocklist Pro-only (verified: 2026-09) https://clerk.com/pricing
- **US-only hosting, no region selection; SOC 2 Type 2 + HIPAA; GDPR via EU-U.S. DPF; DPA public** (verified: 2026-09, via https://clerk.com/security surfaced in search — read the page before quoting in a DPA)
- Webhook signature via `verifyWebhook()` (W4); dashboard 2FA (unverified).

## Upstash
- HTTPS-only REST; read-only token for read paths; TLS on the Redis port; IP allowlist; encryption at rest; SOC 2/HIPAA (verified: 2026-09, docs pages via search: https://upstash.com/docs/redis/features/restapi · https://upstash.com/docs/redis/troubleshooting/readonly_connection).

## Resend
- Send from a subdomain; DKIM DNS-only; SPF `~all`; DMARC `p=none` → `quarantine` → `reject` (W8, W9) (verified: 2026-09) https://resend.com/docs/dashboard/domains/dmarc
- Sending-only, domain-scoped API key (scopes (unverified)).

## Sentry
- Region immutable at org creation (W16); DSN public but rotate/revoke if abused; server-side data scrubber on by default + Advanced Data Scrubbing rules; SDK `beforeSend` to drop/redact; SDK v10 `dataCollection` option replaces deprecated `sendDefaultPii` — keep `userInfo` off unless needed (verified: 2026-09) https://docs.sentry.io/security-legal-pii/scrubbing/ · https://docs.sentry.io/platforms/javascript/configuration/options/
- `tunnelRoute` to bypass blockers is not a privacy control.

## PostHog
- EU Cloud (Frankfurt); `cookieless_mode: 'always' | 'on_reject'` (no cookies/storage, server-side hash) or `persistence: 'memory'`; replay: `maskAllInputs` true by default, `maskTextSelector: "*"` to mask all text, `ph-no-capture` class; DPA at app.posthog.com/legal (verified: 2026-09) https://posthog.com/docs/libraries/js/config · https://posthog.com/docs/session-replay/privacy · https://posthog.com/docs/privacy

## Paddle
- Scoped API keys, replace legacy 50-char keys; client tokens only open checkout/preview prices; verify `Paddle-Signature` on every webhook; secrets `pdl_ntfset_` per destination (verified: 2026-09) https://developer.paddle.com/api-reference/about/authentication · https://developer.paddle.com/webhooks/signature-verification
- As MoR Paddle holds the customer PII/payment data — your DPA is with Paddle (unverified wording); dashboard 2FA (unverified).

## Payments alternatives
- Stripe: verify `Stripe-Signature`, IP allowlist Stripe's published IPs, roll `whsec_` periodically, 5-min timestamp tolerance (verified: 2026-09) https://docs.stripe.com/webhooks
- Stripe Dashboard 2FA with passkeys/security keys/authenticator/SMS and team-wide enforcement (verified: 2026-09, support pages via search: https://support.stripe.com/questions/require-two-step-authentication-for-your-team).
- Lemon Squeezy: `X-Signature` HMAC-SHA256, secret you choose 6–40 chars (verified: 2026-09) https://docs.lemonsqueezy.com/help/webhooks/signing-requests

## Instatus
- Keep it on a separate host (design of the standard); SAML SSO not on Free (verified: 2026-09) https://instatus.com/pricing
- Subscribers' emails are PII → mention in the privacy policy.

## Help Scout
- Beacon secure mode (HMAC signature) whenever you identify users, so a visitor cannot impersonate another customer's history (verified: 2026-09) https://developer.helpscout.com/beacon-2/web/javascript-api/
- 2FA/SSO for agents (unverified).

## Google (GSC, GA4/GTM, Ads)
- GA4 retention 2 months default / 14 max (verified: 2026-09) https://support.google.com/analytics/answer/9019185
- Consent banner must block GTM until consent (web.md item); for EU audiences prefer Plausible/PostHog cookieless; Google Ads conversion tags only through GTM with consent mode (consent-mode page (unverified)).

## Analytics alternatives
- Plausible: no cookies, no persistent identifiers, EU-only processing (verified: 2026-09) https://plausible.io/#pricing

## Dev tools
- Orca (optional agent desktop): sends anonymous telemetry by default; opt out in its privacy settings (reported by the user 2026-09-23).

## Cross-cutting (from core.md)
- Every secret lives in the host's secret store: Vercel → Sensitive var (W27); Cloudflare Workers → Worker secret, runtime not Build variables (W30); Netlify → **Contains secret values** (W33). `.env.example` lists names only; webhook idempotency block ON whenever W4/W12/W13/W14 exist; threat model names each provider as an entry point.

***
Copyright © 2026 Rafael Arciniegas. Licensed under the MIT License.
