# Startup stack — alternatives

Everything outside the happy path in `references/stack/overview.md`: growth ladders (free → first paid → enterprise, with the upgrade trigger), provider rows in the overview's column format, rejects with the reason, and the official country-eligibility lists for payments and messaging.
Read by mapping only when a BRIEF constraint (must-have, won't-accept, budget, country) or a growth trigger needs a provider outside the overview, and for the country checks in mapping rules 4 and 6.
Source: `docs/specs/provider-research.md` (2026-09-24), Parts A–C; Part D (terms of service and country lists) wins on conflict. Only facts that carry a URL are marked verified; everything else is `(unverified)`.

Commercial use on a free tier, one of:
- **explicit yes**: the provider says so in writing (named document).
- **no restriction in <doc>**: the named terms were read (Part D) and hold no non-commercial clause.
- **pricing page only (ToS not read)**: no restriction on the pricing page; a ban could still sit in the terms (Vercel's does). Read the terms before adopting.
- **n/a**: no free tier.

## 1. Hosting
Ladder: Cloudflare Pages/Workers Free (overview) → Netlify Personal $9 (Node runtime; overview) or Railway Hobby $5 / DigitalOcean container $5 (Docker, WebSockets, long-running process) → Cloud Run pay-as-you-go or Railway Pro $20 (regions, autoscale, enterprise paperwork). Trigger: free credits exhausted; a Node-only library on Workers; a buyer asks for SLA/SSO/HIPAA. Vercel Hobby is non-commercial only (overview).

| Provider | Role | Free tier / entry price | Strengths | Weaknesses | Pick the alternative when |
|---|---|---|---|---|---|
| Railway | hosting (Docker, long-running) | Commercial: pricing page only (ToS not read). Free: $0/mo + $1 usage credit; Trial $5 one-time/30 days; Hobby $5/mo incl. $5 usage; Pro $20/mo/workspace incl. $20; Enterprise: SSO, RBAC, HIPAA BAA, contractual SLAs via committed spend (verified: 2026-09) https://railway.com/pricing — SOC 2, regions (unverified) | Dockerfile in, URL out; DBs/cron/workers in one project | $1 credit runs nothing: treat the entry price as $5/mo | Cloud Run when you want GCP's compliance paper trail on the same image |
| Google Cloud Run | hosting (Docker, serverless) | Commercial: no restriction in the free-tier doc, which applies the free tier to a "Paid billing account or Free Trial billing account". Always-free: 2M requests, 360,000 GB-s, 180,000 vCPU-s, 1 GB egress from North America/mo; card required (verified: 2026-09) https://docs.cloud.google.com/free/docs/free-cloud-features — paid per-request rates (unverified) | Docker = no lock-in; scale to zero | card required; egress outside North America billed; console complexity | Railway for one bill and no IAM |
| DigitalOcean App Platform | hosting (static + containers) | Commercial: pricing page only (ToS not read). Free: 3 static-site apps, 1 GiB transfer/app; container from $5/mo; Dev Postgres $7/mo (verified: 2026-09) https://www.digitalocean.com/pricing/app-platform — regions, SOC 2 (unverified) | flat, predictable prices | free tier is static-only | Railway for usage-based DBs/workers |
| Render | hosting (PaaS) | Commercial: pricing/docs page only (ToS not read); docs say "Do not use them for production applications". Free: 750 instance-hours/mo; pauses after 15 min idle, ~1 min wake; free Postgres expires 30 days after creation (verified: 2026-09) https://render.com/docs/free | Heroku-like DX | free tier unfit for anything user-facing | Railway or Cloud Run |
| Coolify + Hetzner | self-hosted PaaS | Commercial: explicit yes on the pricing page ("Free Forever… No limitation or restrictions"); Coolify Cloud $5/mo (2 servers) + $3/server (verified: 2026-09) https://coolify.io/pricing · Hetzner Cloud locations: Germany, Finland, Singapore, USA (verified: 2026-09) https://www.hetzner.com/cloud/ — server prices, and ID/advance-payment verification at signup (unverified) | cheapest per vCPU; Docker portability | you are the ops team: patches, backups, uptime | any managed host until there is a second engineer |

Rejects: **Fly.io** — nothing verified (site unreachable during research); do not add from memory. **AWS as a free start** — Free Tier is now credits over 6 months; the account closes "6 months after you open it or when your credits run out" https://aws.amazon.com/free/ (verified: 2026-09). **Render Free for production** — see row. **Railway Free as a free tier** — the real entry is Hobby $5.

## 2. Database
Ladder: Supabase/Neon Free (overview) → Prisma Postgres Starter $10 (first daily backups; overview growth rungs) or PlanetScale single-node $5 → PlanetScale HA $15 (replicas/failover) → Prisma Business $129 (SOC 2 + ISO 27001). Trigger: real users (backups); >500 MB; high availability; an auditor asks for a SOC 2 report. Turso only when per-tenant or edge SQLite is the design.

| Provider | Role | Free tier / entry price | Strengths | Weaknesses | Pick the alternative when |
|---|---|---|---|---|---|
| Prisma Postgres | Postgres | Commercial: no restriction in Terms of Service (Oct 15, 2024) https://www.prisma.io/terms (verified: 2026-09). Free: 50 DBs, 500 MB, 200k ops/mo; Starter $10/mo: 10 GB, 1M ops, 7-day daily backups; Pro $49 GDPR/HIPAA; Business $129 SOC 2 + ISO 27001, 30-day backups (verified: 2026-09) https://www.prisma.io/pricing — regions, PITR (unverified) | daily backups from $10; compliance ladder on the price sheet | operations-based billing; free = no backups | Neon for CU-hour billing and branching |
| PlanetScale Postgres | Postgres, HA | Commercial: n/a (no free tier). Single-node from $5/mo; HA 3-node from $15/mo; 25+ AWS/GCP regions (verified: 2026-09) https://planetscale.com/pricing — branching/PITR, SOC 2, SLA (unverified) | cheapest managed HA Postgres seen ($15) | no free rung | Supabase Pro when you also need auth and storage |
| Turso | SQLite/libSQL edge DB | Commercial: pricing page only (ToS not read). Free: 100 DBs, 5 GB, 500M row reads, 10M row writes/mo, 1-day PITR; Developer $4.99/mo; SOC 2 and HIPAA listed (verified: 2026-09) https://turso.tech/pricing | embedded replicas, per-tenant DBs | not Postgres: migration cost later | any Postgres unless per-user/edge DBs are the design |

Rejects: **Nile** — backups, branching and SOC 2 "Coming soon" https://www.thenile.dev/pricing (verified: 2026-09). **Xata Cloud** — no free managed tier ($9/mo minimum) https://xata.io/pricing (verified: 2026-09). **PlanetScale as a free start** — no free tier (row above).

## 3. Jobs, queues, cron
Ladder: Cloudflare Queues (Workers Free) or QStash Free → Trigger.dev Hobby $10 (retries + logs) → Trigger.dev Pro $50 / Inngest Pro $99 → Enterprise (SSO + SOC 2 report). Trigger: >1k messages/day, >24 h retention, run observability, SSO.

| Provider | Role | Free tier / entry price | Strengths | Weaknesses | Pick the alternative when |
|---|---|---|---|---|---|
| Trigger.dev | background jobs, cron | Commercial: no restriction in Terms of Service (Jun 29, 2026) https://trigger.dev/legal (verified: 2026-09). Free: $5/mo compute credit, 20 concurrent runs; Hobby $10/mo (50 concurrent, 7-day logs); Pro $50/mo; Enterprise: SOC 2 report, SSO; Apache 2.0 self-host (verified: 2026-09) https://trigger.dev/pricing | durable runs with retries; $10 middle rung; self-host exit | free credit can run out mid-month | Inngest when event-driven fan-out matters more than long jobs |
| Inngest | event-driven jobs | Commercial: pricing page only (ToS not read). Free: 50k executions/mo, 5 concurrent steps; Pro from $99/mo; Enterprise: SAML, HIPAA, SOC 2 Type II (verified: 2026-09) https://www.inngest.com/pricing | works on serverless hosts | $0 → $99 cliff | Trigger.dev for a $10 rung |
| QStash / Cloudflare Queues | queues, cron, webhooks | Commercial: QStash — no restriction in Upstash Terms (Apr 2025) https://upstash.com/trust/terms.pdf (verified: 2026-09); CF Queues — no restriction in the Developer Platform terms https://www.cloudflare.com/service-specific-terms-developer-platform/ (verified: 2026-09). QStash Free: 1,000 msgs/day, 10 schedules; PAYG $1/100K msgs (verified: 2026-09) https://upstash.com/pricing/qstash · CF Queues on Workers Free: 10,000 ops/day, 24 h retention (verified: 2026-09) https://developers.cloudflare.com/queues/platform/pricing/ | HTTP-native, no worker process to host | 24 h retention on CF Free; 10 QStash schedules | Trigger.dev/Inngest once retries need observability |

## 4. Object storage and images
Ladder: R2 Free 10 GB → R2 pay-as-you-go; backups to B2 → images: ImageKit Free → Lite $9 (overview growth rungs) → Cloudinary Plus $99 (DAM/video) → Enterprise. Trigger: >10 GB stored; >20 GB/mo image bandwidth; video pipeline; SSO.

| Provider | Role | Free tier / entry price | Strengths | Weaknesses | Pick the alternative when |
|---|---|---|---|---|---|
| Cloudflare R2 | object storage (S3 API) | Commercial: no restriction in the Developer Platform terms https://www.cloudflare.com/service-specific-terms-developer-platform/ (verified: 2026-09). Free/mo: 10 GB-month, 1M Class A, 10M Class B; $0.015/GB-month; egress free (verified: 2026-09) https://developers.cloudflare.com/r2/pricing/ | zero egress; S3 API = portable | data-location guarantees (unverified) | Backblaze B2 for cold backups |
| Backblaze B2 | backups, cold storage (S3 API) | Commercial: yes — "First 10GB storage is always free" is the standard allowance, not a plan https://www.backblaze.com/cloud-storage/pricing (verified: 2026-09). $6.95/TB/mo; egress free up to 3× stored and unlimited via Cloudflare/bunny.net/Fastly (verified: 2026-09) same URL | cheapest per TB | US/EU only (unverified) | R2 for app-served objects |
| ImageKit | image CDN | Commercial: no restriction in Terms of Use (27 June 2025) https://imagekit.io/terms/ (verified: 2026-09). Free: 20 GB bandwidth, 3 GB storage; Lite $9/mo; SOC 2 Type II, ISO 27001 badges (verified: 2026-09) https://imagekit.io/plans | $9 first rung; can front R2/S3 | small free storage | Cloudinary for a full DAM/video pipeline |
| Cloudinary | media pipeline, DAM | Commercial: no restriction in ToS ("Cloudinary offers some of its plans free of charge") https://cloudinary.com/tos (verified: 2026-09). Free: 25 credits/mo; Plus $99/mo; Advanced $249/mo (verified: 2026-09) https://cloudinary.com/pricing | richest transforms/video | $0 → $99 cliff | ImageKit for the $9 rung |
| UploadThing | file uploads (Next.js) | Commercial: pricing page only (ToS not read). Free: 2 GB storage; 100 GB app $10/mo; usage-based $25/mo (verified: 2026-09) https://uploadthing.com/pricing | fastest Next.js upload DX | proprietary API; no compliance page | R2 + presigned URLs when portability matters |

## 5. CDN and WAF
Ladder: Cloudflare Free → Cloudflare Pro (overview) → bunny.net for media-heavy egress → Fastly for enterprise edge + WAF. Trigger: video or large downloads (bunny.net); enterprise edge compute or a contractual SLA (Fastly).

| Provider | Role | Free tier / entry price | Strengths | Weaknesses | Pick the alternative when |
|---|---|---|---|---|---|
| bunny.net | CDN, storage, DNS | Commercial: n/a (14-day trial, $1/mo minimum). CDN $0.01/GB EU+NA, South America $0.045/GB, Asia/Oceania $0.03, MEA $0.06 (verified: 2026-09) https://bunny.net/pricing/ | cheapest egress for media | no free rung; regional price spread | Cloudflare Free for HTML/API |
| Fastly | CDN, edge compute, WAF | Commercial: pricing page only (ToS not read; "for prototyping, learning, and smaller workloads"). Free/mo: 100 GB + 1M requests, 10M Compute requests (verified: 2026-09) https://www.fastly.com/pricing | enterprise-grade edge on a free rung | pricing beyond free opaque | Cloudflare unless you need Fastly's enterprise edge |

## 6. Auth
Ladder: Better Auth (in your DB) or Clerk Hobby (overview) → Kinde Pro $25 / Clerk Pro $25 (MFA, custom domains) → WorkOS SSO $125/connection or Kinde Plus $75 unlimited SAML (first enterprise SSO/SCIM request). Auth0 only when a customer names it.

| Provider | Role | Free tier / entry price | Strengths | Weaknesses | Pick the alternative when |
|---|---|---|---|---|---|
| Kinde | auth | Commercial: explicit yes — ToS: "solely for your limited commercial use" https://docs.kinde.com/trust-center/agreements/terms-of-service/ (verified: 2026-09). Free: 10,500 MAU, MFA, social login; Pro $25/mo (SOC 2 report); Plus $75/mo unlimited enterprise SSO; SCIM "Coming soon"; data-residency choice on all plans (verified: 2026-09) https://kinde.com/pricing/ | region choice free; unlimited SAML at $75 | SCIM not shipped | WorkOS when SCIM is the ask |
| WorkOS AuthKit | auth + enterprise SSO/SCIM | Commercial: pricing page only (ToS not read). Free: first 1,000,000 MAU; SSO $125/connection/mo; Enterprise 99.99% SLA (verified: 2026-09) https://workos.com/pricing | $0 until the first enterprise customer | $125/mo per SAML customer | Kinde for a SOC 2 report + residency at $25 |
| Auth0 | auth | Commercial: pricing page only (ToS not read). Free: 25,000 MAU, 1 enterprise connection, no MFA; B2C Essentials $35/mo; B2B Essentials $150/mo (verified: 2026-09) https://auth0.com/pricing | largest free MAU with SAML | B2B tiers jump fast; MFA paid | Kinde/WorkOS for cheaper SAML |
| Better Auth | auth library (self-hosted) | Commercial: explicit yes (MIT library) https://www.better-auth.com/pricing (verified: 2026-09); acquired by Vercel 2026-07-07, library stays MIT (verified: 2026-09) https://vercel.com/blog/vercel-acquires-better-auth | no MAU bill; data in your Postgres | you run the security surface; roadmap risk | Clerk/Kinde for hosted UI and support |

## 7. Email
Ladder: Resend Free (overview) → Resend Pro $20 / Postmark Basic $15 (daily cap or deliverability) → Amazon SES $0.10/1k with a dedicated IP (>100k/mo). Marketing: Loops Free → Loops paid (price unverified).

| Provider | Role | Free tier / entry price | Strengths | Weaknesses | Pick the alternative when |
|---|---|---|---|---|---|
| Postmark | transactional email | Commercial: pricing page only (ToS not read). Free: 100 emails/mo; Basic $15/mo 10k (verified: 2026-09) https://postmarkapp.com/pricing | deliverability reputation; separate streams | 100/mo is a test tier | Resend for 3,000/mo free |
| Amazon SES | bulk/transactional email | Commercial: n/a (no perpetual free tier: up to $200 credits for 6 months); $0.10/1,000 emails (verified: 2026-09) https://aws.amazon.com/ses/pricing/ | cheapest per email at volume | sandbox exit, DKIM, bounces are yours | Resend/Postmark until >50k/mo |
| Loops | marketing + transactional | Commercial: pricing page only (ToS not read). Free: 4,000 emails/30 days to 1,000 contacts, "Powered by Loops" footer (verified: 2026-09) https://loops.so/pricing — paid prices (unverified) | one tool for newsletter + transactional | paid pricing opaque | Resend if you only need transactional |
| Brevo | marketing email + SMS/WhatsApp | (unverified — pricing page not readable during research) | one bill for email + SMS + WhatsApp | daily cap shared by transactional and campaigns | Loops/Resend |

## 8. SMS and WhatsApp
Ladder: WhatsApp Business Cloud API direct (service messages free) → Twilio outbound SMS (OTP or SMS fallback) → multi-channel inbox (Twilio/Brevo). Trigger: SMS fallback needed; then one inbox for all channels. Mapping rule 6: where the SMS provider's per-country page shows no SMS-capable local number type, prefer WhatsApp and plan SMS as one-way outbound.

| Provider | Role | Free tier / entry price | Strengths | Weaknesses | Pick the alternative when |
|---|---|---|---|---|---|
| Twilio | SMS, voice, WhatsApp | Commercial: n/a (pay per message). Per-country SMS pricing page carries the "Phone number type" table (which local types can send SMS) https://www.twilio.com/en-us/sms/pricing/{cc} · per-country regulatory page lists the number types that can be provisioned https://www.twilio.com/en-us/guidelines/{cc}/regulatory (URL patterns verified: 2026-09 with cc=pa) | one API for SMS, WhatsApp, Verify | carrier fees extra; a country may have no SMS-capable local number (§12) | WhatsApp Cloud API when WhatsApp is the only channel |
| WhatsApp Business Cloud API (Meta) | WhatsApp | Commercial: n/a (pay per template message). Per-message pricing by template category since 2025-07-01; "All non-template messages are free"; rate card by recipient calling code (verified: 2026-09) https://developers.facebook.com/docs/whatsapp/pricing | no middleman markup | Meta Business verification; template approval; no SMS | Twilio/Brevo for SMS fallback in one API |

## 9. Payments
Ladder: merchant of record for global SaaS (Paddle — overview; Polar, Lemon Squeezy, Dodo Payments) → Stripe through an entity in a Stripe account country when volume makes ~2% matter. A local rail for domestic buyers only when the operating country matches one in §12. Every pick passes mapping rule 4's country check first.

| Provider | Role | Free tier / entry price | Strengths | Weaknesses | Pick the alternative when |
|---|---|---|---|---|---|
| Polar | payments, MoR | Commercial: n/a (per-transaction). 5% + 50¢, +1.5% non-US cards, +0.5% subscriptions; payouts 0.25% + $0.25 + $2/mo active payout (verified: 2026-09) https://polar.sh/docs/merchant-of-record/fees | open-source, developer-first MoR | payout fees on top | Paddle for a mature MoR with enterprise invoicing |
| Dodo Payments | payments, MoR | Commercial: n/a (per-transaction). 4% + 40¢ US domestic, +1.5% international, +0.5% subscriptions; no monthly fee (verified: 2026-09) https://dodopayments.com/pricing — SOC 2/PCI (unverified) | cheapest MoR headline rate; eligibility by ID-document country | young company (seed-stage 2025, unverified) | Paddle/Polar for a longer track record |
| PayPal | payments (PSP, not MoR) | Commercial: n/a. Availability list by country https://www.paypal.com/pa/webapps/mpp/country-worldwide (verified: 2026-09; /us/ variant exists) — business-account eligibility and fees per country (unverified) | buyer trust | not MoR; the list does not separate business from personal accounts | an MoR for global SaaS |
| dLocal | Latin American PSP | Commercial: n/a. Coverage list https://dlocal.com/coverage/ (verified: 2026-09) — pricing and minimum volume (unverified) | one contract for many local methods | enterprise, sales-led | only at multi-country Latin American scale |

Rejects: **Lemon Squeezy for a new integration** — migrating merchants to Stripe Managed Payments (overview row).

## 10. Other application services
### Scheduling
Ladder: Cal.com Free → Teams $12/user → Organizations $28/user with SAML/SCIM/SOC 2. Trigger: team round-robin, then SSO. Calendly Enterprise ($15k/yr, 50-seat minimum) is the anti-ladder.

| Provider | Role | Free tier / entry price | Strengths | Weaknesses | Pick the alternative when |
|---|---|---|---|---|---|
| Cal.com | scheduling | Commercial: no restriction in Terms of Service (effective 04/14/2021) https://cal.com/terms (verified: 2026-09). Free: 1 user, unlimited event types; Teams $12/user/mo; Organizations $28/user/mo: SAML, SCIM, SOC 2 (verified: 2026-09) https://cal.com/pricing — self-host licence (unverified) | self-host escape; SSO at $28 | per-seat Orgs | Calendly when buyers expect its brand |
| Calendly | scheduling | Commercial: pricing page only (ToS not read). Free: 1 event type; Standard $10/seat/mo; Enterprise from $15k/yr, 50 seats (verified: 2026-09) https://calendly.com/pricing | brand recognition | SSO only at $15k/yr | Cal.com |
| SavvyCal | scheduling | Commercial: n/a (trial only). Basic $10/user/mo (verified: 2026-09) https://savvycal.com/pricing | overlay-calendar UX | no free, no SSO story | Cal.com |

### Forms and CMS
Ladder: Tally Free → Pro $24 (branding, custom domain). Sanity Free → Growth $15/seat (editor roles, private datasets) → Enterprise (SSO, regions). Payload is self-host only.

| Provider | Role | Free tier / entry price | Strengths | Weaknesses | Pick the alternative when |
|---|---|---|---|---|---|
| Tally | forms | Commercial: pricing page only (ToS not read); "within our fair use guidelines". Free: unlimited forms and submissions; Pro $24/mo; Business $74/mo (verified: 2026-09) https://tally.so/pricing | genuinely unlimited free; EU-based | no SSO | Formspree for a form backend (prices unverified) |
| Sanity | headless CMS | Commercial: pricing page only (ToS not read). Free: 20 seats, 10k documents, public datasets only; Growth $15/seat/mo; Enterprise: SAML, SOC 2, SLA, regions (verified: 2026-09) https://www.sanity.io/pricing | generous free; portable export | per-seat at Growth | Payload when the CMS belongs in your Next.js repo |
| Payload | headless CMS (self-hosted) | MIT, $0 self-hosted; Payload Cloud paused for new projects after the Figma acquisition https://www.figma.com/blog/payload-joins-figma/ (verified: 2026-09, URL only) | Next.js-native, your Postgres | no managed hosting | Sanity for hosted content |

### Search
Ladder: Postgres full-text/pgvector → Algolia Free → Grow pay-as-you-go (relevance tooling) → Meilisearch Cloud / Typesense (open-source portability) → Algolia Elevate / Meilisearch Enterprise (SLA/SSO).

| Provider | Role | Free tier / entry price | Strengths | Weaknesses | Pick the alternative when |
|---|---|---|---|---|---|
| Algolia | search | Commercial: pricing page only (ToS not read; page names "launching a startup, running a small online store"). Free: 10k search requests/mo, 50k records; Grow $0.50/extra 1k requests (verified: 2026-09) https://www.algolia.com/pricing | best relevance tooling | request billing on chatty UIs | Meilisearch/Typesense for portability |
| Meilisearch Cloud | search | Commercial: n/a (14-day trial). From $20/month; SOC 2 Type II, SAML on enterprise (verified: 2026-09) https://www.meilisearch.com/pricing — self-host licence (unverified) | open-source core | no free cloud | Typesense Cloud (price unverified) https://cloud.typesense.org/pricing |

### AI gateway and vectors
Ladder: Vercel AI Gateway or Cloudflare AI Gateway free → paid credits/BYOK (rate limits) → Enterprise invoicing + zero data retention. Vectors: pgvector → Pinecone Starter → Standard $50 minimum → Enterprise (SLA/HIPAA).

| Provider | Role | Free tier / entry price | Strengths | Weaknesses | Pick the alternative when |
|---|---|---|---|---|---|
| Vercel AI Gateway | LLM gateway | Commercial: pricing page only (ToS not read); availability on Hobby (unverified). "no markup and no platform fee on tokens"; free tier = model subset with rate limits; BYOK on paid (verified: 2026-09) https://vercel.com/docs/ai-gateway/pricing | 0% markup; budgets per key | ties spend to Vercel | OpenRouter off Vercel |
| OpenRouter | LLM gateway | Commercial: pricing page only (ToS not read). Credits fee 5.5% ($0.80 min); BYOK free up to $25k/mo then 5% (verified: 2026-09) https://openrouter.ai/docs/faq | 300+ models, one key | 5.5% on prepaid | Vercel AI Gateway on Vercel |
| Cloudflare AI Gateway | LLM gateway | Commercial: no restriction in the Developer Platform terms (verified: 2026-09) https://www.cloudflare.com/service-specific-terms-developer-platform/. Core features free; Unified Billing 5% fee (verified: 2026-09, URL only) https://developers.cloudflare.com/ai-gateway/reference/pricing/ | free proxy/cache for any provider | 5% if Cloudflare bills | pairs with Cloudflare Pages |
| pgvector | vectors | $0 — a Postgres extension in the database you already pay for | no new vendor; RLS applies | scale ceiling (opinion) | Pinecone past it |
| Pinecone | vectors | Commercial: pricing page only (ToS not read). Starter free: 2 GB, 5 indexes, AWS us-east-1 only; Standard $50/mo minimum; Enterprise: 99.95% SLA, SAML, SOC 2, HIPAA (verified: 2026-09) https://www.pinecone.io/pricing/ | clear enterprise tier | free = one US region | pgvector until it hurts |

Rejects: **Turbopuffer** — no free tier (third-party, unverified).

### Support
Ladder: Help Scout Free (overview) → Crisp Free / Chatwoot Hacker (live-chat widget) → Crisp Mini $45 / Chatwoot Startups $19/agent (WhatsApp channel) → Plain $35/seat (B2B Slack support) → Intercom only on contractual demand.

| Provider | Role | Free tier / entry price | Strengths | Weaknesses | Pick the alternative when |
|---|---|---|---|---|---|
| Crisp | support chat | Commercial: pricing page only (ToS not read; "For solopreneurs and entrepreneurs"). Free: 2 seats, website chat, shared inbox; Mini $45/workspace/mo; EU hosting + DPA on Plus $295 (verified: 2026-09) https://crisp.chat/en/pricing/ | free widget + inbox | jump to $45 | Chatwoot for open source/self-host |
| Chatwoot | support chat (open source) | Commercial: pricing page only (ToS not read). Cloud Hacker free: 2 agents, 500 conversations/mo; Startups $19/agent/mo (adds WhatsApp); cloud on AWS US (verified: 2026-09) https://www.chatwoot.com/pricing — self-host licence (unverified) | self-host = data at home | US-only cloud | Crisp for a polished widget |
| Plain | support (B2B) | Commercial: n/a (7-day trial). Foundation $35/seat/mo; SOC 2 Type II (verified: 2026-09) https://www.plain.com/pricing | Slack/Discord-native | no free tier | Help Scout until you sell B2B |

Rejects: **Intercom** — seats plus a per-resolution fee (prices third-party, unverified); only when a contract demands it.

## 11. Operations and security
### Observability (logs, metrics, traces)
Ladder: Grafana Cloud Free or Axiom Personal → Axiom Cloud $25 or Grafana Pro $19 + usage → Grafana Enterprise ($25k/yr) / Datadog (unverified). Trigger: retention >14 days (Grafana) or >30 days (Axiom); a 4th engineer needing Grafana access.

| Provider | Role | Free tier / entry price | Strengths | Weaknesses | Pick the alternative when |
|---|---|---|---|---|---|
| Grafana Cloud | logs, metrics, traces, k6, on-call | Commercial: no restriction in Grafana Labs Terms (Jul 10, 2026) https://grafana.com/legal/terms/ (verified: 2026-09) — Cloud-specific schedule (unverified). Free: 50 GB logs + 50 GB traces/mo, 10k metric series, 14-day retention, 3 users, 500 k6 VU-hours; Pro $19/mo + usage; Enterprise from $25,000/yr (verified: 2026-09) https://grafana.com/pricing/ | one bill incl. load test and on-call; OSS exit | 14-day retention on free | Axiom for 30-day retention and a flat $25 tier |
| Axiom | logs/events (OTel) | Commercial: no restriction in Terms of Service and AUP https://axiom.co/terms (verified: 2026-09). Personal: 500 GB/mo ingest, 30-day retention; Axiom Cloud $25/mo; SOC 2 Type II, ISO 27001 (verified: 2026-09) https://axiom.co/pricing | highest free ingest seen | no self-host; SSO paid add-on | Grafana for metrics + on-call in one place |
| Honeycomb | tracing (OTel-native) | Commercial: pricing page only (ToS not read). Free: 20M events/mo, unlimited seats; Pro from $150/mo (verified: 2026-09) https://www.honeycomb.io/pricing | best trace query UX | $150 jump | Grafana/Axiom when log volume drives cost |
| New Relic | full-stack APM | Commercial: pricing page only (ToS not read). Free: 100 GB ingest/mo, 1 full user; Standard $10 first user then $99/user; EU data centre option (verified: 2026-09) https://newrelic.com/pricing | generous ingest; EU region | $99/user at the 2nd full user | Grafana Cloud for >1 engineer |

### Errors
Ladder: Sentry Developer (overview) → Sentry Team $26 → Sentry Business. Alternate: GlitchTip self-host $0 (Sentry-SDK compatible) → GlitchTip hosted / Rollbar (prices unverified; pages https://glitchtip.com/pricing · https://rollbar.com/pricing-for-agents). Trigger: 5k errors/mo cap or a 2nd user on Sentry free.
Rejects: **Bugsnag** — weakest free tier in the category and the first paid price is not readable on its page (unverified) https://www.bugsnag.com/pricing/.

### Uptime, status and on-call
Ladder: UptimeRobot Free + Instatus Free (overview) → UptimeRobot Solo $9 or Better Stack Responder $29–34 (adds on-call) → PagerDuty Professional $21/user. Trigger: the first paying customer with an SLA clause.

| Provider | Role | Free tier / entry price | Strengths | Weaknesses | Pick the alternative when |
|---|---|---|---|---|---|
| UptimeRobot | uptime | Commercial: explicit yes — ToS §3 "available for any use, including commercial and business use" https://uptimerobot.com/terms/ (verified: 2026-09). Free: 50 monitors @5 min, 1 status page; Solo $9/mo yearly (60 s interval) (verified: 2026-09) https://uptimerobot.com/pricing/ | most free monitors; cheapest paid tier | 5-min interval on free; no on-call | Checkly for API/browser checks as code (Hobby free; Starter $24/mo) https://www.checklyhq.com/pricing/ (verified: 2026-09) |
| Better Stack | uptime + on-call + logs | Commercial: no restriction in Terms of Use (Feb 14, 2025) https://betterstack.com/terms (verified: 2026-09). Free: 10 monitors @30 s, 1 status page, 3 GB logs (3-day); Responder $34/mo ($29 yearly); SOC 2 Type II (verified: 2026-09) https://betterstack.com/pricing — telemetry bundle names (unverified) | uptime + status + on-call in one bill | 3-day log retention on free | UptimeRobot for cheap monitors only |
| PagerDuty | on-call | Commercial: pricing page only (ToS not read). Free: 5 users, 1 schedule; Professional $21/user/mo yearly (verified: 2026-09) https://www.pagerduty.com/pricing/ | the on-call tool buyers recognise | per-user pricing | Better Stack/Grafana IRM when already paid for |

Rejects: **OpenStatus** — 1 monitor @10 min free, Starter $30/mo; Instatus + UptimeRobot beat it at both rungs https://www.openstatus.dev/pricing (verified: 2026-09).

### Analytics
Ladder: Cloudflare Web Analytics $0 (or Vercel Web Analytics on Hobby, non-commercial) → Plausible Starter $9 / Fathom $15 → Plausible Business $19 → Enterprise (SSO, managed proxy). Trigger: custom events/API, or Vercel Hobby's 50k events/mo.

| Provider | Role | Free tier / entry price | Strengths | Weaknesses | Pick the alternative when |
|---|---|---|---|---|---|
| Plausible / Fathom | cookieless analytics | Commercial: n/a (trials only). Plausible Starter $9/mo 10k pageviews, Business $19/mo; EU-hosted (verified: 2026-09) https://plausible.io/#pricing · Fathom $15/mo 100k pageviews (verified: 2026-09) https://usefathom.com/pricing | no consent banner needed | no free tier | Cloudflare Web Analytics when the budget is 0 |
| Cloudflare Web Analytics | pageviews | Commercial: pricing/docs page only ("available on all plans"). Free on all plans; limits not documented (verified: 2026-09) https://developers.cloudflare.com/web-analytics/ | $0, no DNS change needed | limits undocumented | Plausible for goals and API |
| Vercel Web Analytics | pageviews/events | Commercial: inherits Vercel Hobby's non-commercial rule on Hobby. Hobby 50k events/mo; Pro $0.03/1k events (verified: 2026-09) https://vercel.com/docs/analytics/limits-and-pricing | built into Vercel | Hobby = non-commercial | Cloudflare Web Analytics on Cloudflare Pages |

Rejects: **Umami Cloud** — site unreachable during research; nothing verified.

### Feature flags
Ladder: PostHog free flags (overview) → GrowthBook Pro $40/seat or Flagsmith Start-Up $40/mo → Statsig Pro $150 → LaunchDarkly Foundation. Trigger: experiment statistics beyond PostHog, or a buyer's procurement list naming LaunchDarkly.

| Provider | Role | Free tier / entry price | Strengths | Weaknesses | Pick the alternative when |
|---|---|---|---|---|---|
| GrowthBook / Flagsmith | flags + experiments | Commercial: pricing page only (ToS not read). GrowthBook Starter: 3 seats, unlimited flags; Pro $40/seat/mo; self-host free (verified: 2026-09) https://www.growthbook.io/pricing · Flagsmith Free: 50k API req/mo; Start-Up $40/mo (verified: 2026-09) https://www.flagsmith.com/pricing | both open source | PostHog already covers most cases | Statsig (Pro $150, SOC 2) https://www.statsig.com/pricing (verified: 2026-09); LaunchDarkly only for enterprise procurement https://launchdarkly.com/pricing/ (verified: 2026-09) |

Rejects: **Unleash hosted** — $75/seat/mo, trial only; self-host is the free path https://www.getunleash.io/pricing (verified: 2026-09).

### Secrets
Ladder: host Sensitive env vars + GitHub Environments ($0) → Doppler Developer (3 users free) or Infisical self-host → Doppler Team $21/user / Infisical Pro $20/identity → Enterprise. Trigger: a 2nd person deploying, or the first key-rotation incident.

| Provider | Role | Free tier / entry price | Strengths | Weaknesses | Pick the alternative when |
|---|---|---|---|---|---|
| Doppler / Infisical | secrets management | Commercial: pricing page only (ToS not read); Infisical "MIT-licensed core is self-hostable at no cost". Doppler Developer: 3 users, 10 projects; Team $21/user/mo (verified: 2026-09) https://www.doppler.com/pricing · Infisical Free: 5 identities; Pro $20/identity/mo yearly (verified: 2026-09) https://infisical.com/pricing | one source of truth synced to host + CI | per-user pricing | host env vars while one person deploys |

### CI
Ladder: GitHub Actions 2,000 min (overview) → Depot Developer $20/mo (Docker builds) → GitHub Team / GitLab Premium $29/user. Trigger: builds >10 min, or Actions minutes exhausted two months running.

| Provider | Role | Free tier / entry price | Strengths | Weaknesses | Pick the alternative when |
|---|---|---|---|---|---|
| GitLab / CircleCI / Depot | CI beyond GitHub Actions | Commercial: pricing pages only (ToS not read). GitLab Free: 400 compute min/mo; Premium $29/user/mo (verified: 2026-09) https://about.gitlab.com/pricing/ · CircleCI Free: 30,000 credits/mo (verified: 2026-09) https://circleci.com/pricing/ · Depot: 7-day trial, Developer $20/mo (verified: 2026-09) https://depot.dev/pricing | Depot = faster Docker builds without leaving Actions | switching CI = rewriting pipelines | stay on GitHub Actions; GitLab only if the org lives there |

### Security scanning
Ladder: Aikido Free + Semgrep OSS in CI + `gitleaks` → GitGuardian Free (secrets, 25 devs) → Semgrep Teams $30/contributor or Snyk Team $25/mo → Aikido Basic $300/mo or GitHub Advanced Security (unverified). Trigger: a 3rd developer (Aikido cap) or a customer asking for a scan report.

| Provider | Role | Free tier / entry price | Strengths | Weaknesses | Pick the alternative when |
|---|---|---|---|---|---|
| Aikido / Semgrep / Socket / GitGuardian / Snyk | SAST, SCA, secrets | Commercial: pricing pages only (ToS not read). Aikido Free: 2 users, 10 repos, SCA + SAST + secrets + IaC; Basic $300/mo (verified: 2026-09) https://www.aikido.dev/pricing · Semgrep Community: 10 contributors, no Secrets; Teams $30/contributor/mo (verified: 2026-09) https://semgrep.dev/pricing · Socket Free: 1 private repo; Team $25/dev/mo, min 5 (verified: 2026-09) https://socket.dev/pricing · GitGuardian Free: 25 developers (verified: 2026-09) https://www.gitguardian.com/pricing · Snyk Free: 5 projects; Team from $25/mo (verified: 2026-09) https://snyk.io/plans/ | Aikido free covers the OWASP list; GitGuardian closes the private-repo secret-scanning gap | Aikido jumps to $300/mo | GitHub Advanced Security only when already on GitHub Team/Enterprise (unverified) |

### Backups
Ladder: provider-native daily backups (Supabase Pro, overview) → SimpleBackups Basic free (off-provider copy) → Lite $49/mo. Trigger: DB >1 GB, or an RPO under 24 h.

| Provider | Role | Free tier / entry price | Strengths | Weaknesses | Pick the alternative when |
|---|---|---|---|---|---|
| SimpleBackups | off-provider DB/storage backups | Commercial: pricing page only (ToS not read). Basic free: 1 daily job, 1 GB DB max; Lite $49/mo; destination your own bucket (verified: 2026-09) https://simplebackups.com/pricing | provider-independent copy (core.md disaster recovery) | $49 jump | provider-native backups; Supabase PITR / Neon restore window (unverified) |

### Load testing
Ladder: k6 OSS locally → Grafana Cloud k6 500 VU-hours free → $0.15/VU-hour. Trigger: a launch rehearsal over 500 VU-hours.

| Provider | Role | Free tier / entry price | Strengths | Weaknesses | Pick the alternative when |
|---|---|---|---|---|---|
| Grafana k6 / Artillery | load tests | Commercial: k6 — see Grafana Cloud; Artillery pricing page only (ToS not read). k6 OSS free; Grafana Cloud 500 VU-hours/mo free (verified: 2026-09) https://grafana.com/pricing/ · Artillery Cloud Free: 30 reports/mo; Team $199/mo (verified: 2026-09) https://www.artillery.io/pricing | scripts live in the repo | Artillery paid ladder is steep | Artillery when tests must run in your own AWS account |

### Compliance (SOC 2 step)
Ladder: nothing → Comp AI self-host (AGPL, unverified) → Comp AI paid / Vanta / Drata (quote-only, unverified). Trigger: a security questionnaire that requires a SOC 2 report.

| Provider | Role | Free tier / entry price | Strengths | Weaknesses | Pick the alternative when |
|---|---|---|---|---|---|
| Comp AI | evidence + policies | No public rate card: "we prepare your exact number and present it on a 20-minute call" (verified: 2026-09) https://trycomp.ai/pricing — open-source repo licence (unverified; search snippet only) https://github.com/trycompai/comp | self-host = $0 evidence collection before an audit | the audit itself is a separate CPA fee | Vanta/Drata when the buyer names one (unverified) |

Rejects: **Highlight.io** — its product page redirected to launchdarkly.com during research; no standalone pricing (LaunchDarkly row under Feature flags). **1Password Secrets Automation, Datadog, Vanta, Drata, Secureframe, Buildkite, OWASP ZAP, GHAS/CodeQL, AWS Secrets Manager, Contentful, Storyblok, Stytch, Descope, Firebase Auth, Vonage** — not fetched during research; do not add rows from memory.

## 12. Country eligibility
Mapping rules 4 and 6 open these pages at run time and check BRIEF §7 `Operating country` (payments) or `Audience countries` (messaging). Lists change; never answer from this file alone. Every list URL below was verified 2026-09.

| Provider | Role | Official list | List type | Notes |
|---|---|---|---|---|
| Paddle | MoR | https://www.paddle.com/help/start/intro-to-paddle/which-countries-are-supported-by-paddle | **unsupported** list (suppliers and buyers) | "Paddle is unable to support suppliers operating from the below countries"; absence is not approval (sellers are vetted) |
| Polar | MoR | https://polar.sh/docs/merchant-of-record/supported-countries | **supported** seller/payout list (~125) | requires Stripe Connect Express availability |
| Lemon Squeezy | MoR | https://docs.lemonsqueezy.com/help/getting-started/supported-countries | **supported** seller-payout lists (bank ≈130; PayPal 200+) + unsupported buyer list | India bank payouts invite-only |
| Dodo Payments | MoR | https://docs.dodopayments.com/miscellaneous/accepted-countries-and-territories | **supported** merchant acceptance + payouts list (177) | eligibility follows the country of the ID document you verify with, not company registration |
| Stripe | PSP | https://stripe.com/global | **supported account** countries (50) | India, Indonesia in preview |
| PayPal | PSP | https://www.paypal.com/pa/webapps/mpp/country-worldwide | **availability** list by region (read from the /pa/ page; /us/ variant: https://www.paypal.com/us/webapps/mpp/country-worldwide) | does not separate business from personal accounts; business eligibility per country (unverified) |
| Twilio | SMS/voice numbers | SMS: https://www.twilio.com/en-us/sms/pricing/{cc} · regulatory: https://www.twilio.com/en-us/guidelines/{cc}/regulatory | per-country "Phone number type" table (SMS) + provisionable number types (regulatory) | the numbers catalogue https://help.twilio.com/articles/223183068-Twilio-international-phone-number-availability-and-their-capabilities needs a browser (unverified content) |
| WhatsApp Cloud API | WhatsApp | https://developers.facebook.com/docs/whatsapp/pricing | rate card by recipient calling code, grouped into markets | "If a country is not listed below, it maps to Other"; Meta's country restrictions live elsewhere (unverified) |

Country-matched examples (offer only when the operating or audience country matches):
- **Panama — payments.** Paddle: absent from the unsupported list; Polar, Lemon Squeezy (bank payouts) and Dodo Payments: listed; Stripe: not an account country (verified: 2026-09, lists above). Local rails: **Yappy Botón de Pago** (Banco General) — "comisión de 1% + ITBMS del monto de la transacción (comisión mínima $0.02)" https://www.yappy.com.pa/faq-items/cuanto-cuesta-cobrar-por-yappy-comercial/ (verified: 2026-09); needs a Banco General commercial account; no subscriptions, not an MoR; a $10.70 cap (unverified). **PagueloFacil** — 3.5% + $0.50 per approved transaction, $0.35 per declined, cards + Clave + Yappy, PCI DSS https://www.paguelofacil.com/ (verified: 2026-09). **Tilopay** — no monthly fee, Panama via Yappy, per-transaction fee not published https://tilopay.com/ (verified: 2026-09).
- **Panama — messaging.** Twilio's SMS page lists only International Numbers ($0.1836 outbound) — no SMS-capable Panama type https://www.twilio.com/en-us/sms/pricing/pa (verified: 2026-09); the regulatory page lists Local and Toll-free (+507800) types, capabilities not stated https://www.twilio.com/en-us/guidelines/pa/regulatory (verified: 2026-09). WhatsApp bills +507 under "Rest of Latin America" (verified: 2026-09). Rule 6 therefore prefers WhatsApp there.

## 13. Removed from the overview
None: every provider in the overview table before 2026-09-24 is still there. The stale-defaults line in overview (AWS/SES credits, Railway, Payload Cloud, Highlight.io, PlanetScale) has its sources in §1–§11 above.

***
Copyright © 2026 Rafael Arciniegas. Licensed under the MIT License.
