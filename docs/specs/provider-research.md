# Provider research for the stack guide (2026-09-24)

Four planner reports, verbatim. Part A: hosting, data, infra. Part B: application services. Part C: operations, observability, security. Part D: terms-of-service and country-eligibility verification, which supersedes A–C where they conflict.
Caveat for A–C: commercial-use verdicts there come from pricing pages; Part D reads the actual terms for the recommended providers.

***
## Part A. Hosting, data, infra

<agent-message from="a371f2c0fd71e5066">


### Conclusion
- **Free-and-commercial-safe starting points exist in every category**: Cloudflare Pages/Workers (dev-platform terms carry **no commercial restriction** — this upgrades the existing Cloudflare row from "user decision" to verified), Netlify Free (staff-confirmed commercial OK), Google Cloud Run always-free (applies to paid billing accounts), R2 10 GB, ImageKit 20 GB, Prisma Postgres 500 MB, Trigger.dev $5 credit, QStash 1k msgs/day.
- **No candidate in this slice has a Vercel-style "non-commercial only" clause.** Caveat: for most, the verdict is "no restriction found on pricing + terms pages", not an explicit grant — only Netlify and GCP are explicit.
- **Material recent changes seen**: Railway now has a permanent Free plan ($1/mo credit — cosmetic); Netlify moved to credit-based pricing with a $9 "Personal" tier; AWS Free Tier is now a 6-month/$200-credit clock (account closes unless upgraded) → AWS is not a "free start"; PlanetScale has no free tier and sells single-node Postgres from $5; Xata pivoted (self-host free, Cloud from $9/mo minimum).
- **Rejects for this skill**: Fly.io (unverifiable this session — DNS fail), Nile (backups/branching "coming soon"), Xata Cloud and PlanetScale as *free* starts (no free tier), AWS as free start, Bunny as free start (trial only), Render Free for production ("Do not use them for production applications", ~1 min cold start, DB expires at 30 days).

***

### 1. Proposed rows (overview.md column format)

| Provider | Role | Free tier / entry price | Strengths | Weaknesses | Pick the alternative when |
|---|---|---|---|---|---|
| Netlify | hosting (Next.js/static) | Free ("Individual"): 300 credits/mo, credit-based (15 credits per production deploy, 10 credits per GB-hour compute); **commercial use allowed** — staff: "Yes, you can use the free plan for commercial projects… you can't resell it" (verified: 2026-09) https://www.netlify.com/pricing/ · https://answers.netlify.com/t/can-we-use-netlify-free-plan-for-commercial-purposes/41545 ; Personal $9/mo; Enterprise: 99.99% SLA, SSO & SCIM (verified: 2026-09) https://www.netlify.com/pricing/ — SOC 2 (unverified); what 300 credits buy in GB/build-minutes (unverified) | commercial on free; cheapest paid Next.js host at $9 | credit model is opaque; ToS has no free-plan clause (commercial OK rests on a staff forum answer, 2021, reconfirmed 2025 per that thread) | Cloudflare Pages when budget is $0 and you accept Workers runtime (OpenNext) |
| Railway | hosting (Docker, long-running) | Free: $0/mo + $1 usage credit; Trial $5 one-time/30 days; Hobby $5/mo incl. $5 usage; Pro $20/mo/workspace incl. $20; $20/vCPU-mo, $10/GB-mo, egress $0.05/GB; Enterprise: SSO, RBAC, HIPAA BAA, contractual SLAs via committed spend (verified: 2026-09) https://railway.com/pricing — SOC 2, regions, commercial-use wording (unverified, not on page) | Dockerfile in, URL out; DBs/cron/workers in one project | $1 free credit ≈ nothing (a 0.5 GB service ≈ $5/mo) → treat as $5/mo | Cloud Run when you want GCP's enterprise paper trail on the same Docker image |
| Google Cloud Run | hosting (Docker, serverless) | Always-free: 2M requests, 360,000 GB-s, 180,000 vCPU-s, 1 GB egress **from North America**/mo; needs an active billing account (card); $300 trial/90 days; free tier applies to "Paid billing account or Free Trial billing account" (verified: 2026-09) https://docs.cloud.google.com/free/docs/free-cloud-features — paid per-request rates (unverified: pricing page truncated); LatAm region (unverified) | Docker = zero lock-in; scale to zero; GCP SOC 2/ISO/DPA inherited (unverified here) | card required; egress outside NA billed; console complexity | Railway for a solo founder who wants one bill and no IAM |
| DigitalOcean App Platform | hosting (static + containers) | Free: 3 static-site apps, 1 GiB transfer/app; container from $5/mo (1 shared vCPU, 512 MiB); overage $0.02/GiB; Dev Postgres $7/mo (verified: 2026-09) https://www.digitalocean.com/pricing/app-platform — regions, SOC 2/SSO, commercial-use wording (unverified) | flat, predictable prices | no LatAm region (unverified); free tier is static-only | Railway for usage-based DBs/workers |
| Render | hosting (PaaS) | Free: 750 instance-hours/workspace/mo; web services pause after 15 min idle, ~1 min wake; free Postgres **expires 30 days** after creation (+14-day grace); doc: "Do not use them for production applications" (verified: 2026-09) https://render.com/docs/free — paid instance prices (unverified: pricing page returned navigation only) | Heroku-like DX; no commercial restriction found | free tier unfit for anything user-facing | Railway or Cloud Run |
| Coolify + Hetzner | self-host PaaS | Coolify self-hosted: "Free Forever… No limitation or restrictions", open source; Coolify Cloud $5/mo (2 servers) + $3/server (verified: 2026-09) https://coolify.io/pricing · Hetzner Cloud locations: Germany, Finland, Singapore, USA (Hillsboro, Ashburn) (verified: 2026-09) https://www.hetzner.com/cloud/ — server prices (unverified: not rendered); [PA] Hetzner may require ID-document or advance-card verification before first order (search snippet, not fetched) https://docs.hetzner.com/general/security-and-identify/fraud-prevention-faq/ | cheapest $/vCPU; full portability (Docker) | you are the ops team: patches, backups, uptime; [PA] account-verification friction; no LatAm DC | any managed host until you have a second engineer |
| Prisma Postgres | Postgres alt | Free: 50 DBs, 500 MB, 200k operations/mo, unlimited transfer; Starter $10/mo: 10 GB (+$2/GB), 1M ops (+$8/M), 7-day daily backups; Pro $49/mo GDPR/HIPAA; Business $129/mo SOC 2 + ISO 27001, 30-day backups (verified: 2026-09) https://www.prisma.io/pricing — regions, PITR, direct-TCP connection, SSO/SLA (unverified) | daily backups from $10; compliance ladder on the price sheet | operations-based billing (surprise vector like Upstash); free = no backups | Neon (existing row) when you want CU-hour billing and branching |
| PlanetScale Postgres | Postgres, HA | **No free tier**; single-node from $5/mo (PS-5, 1/16 vCPU, 512 MiB); HA 3-node (1 primary + 2 replicas) from $15/mo; 25+ AWS/GCP regions (verified: 2026-09) https://planetscale.com/pricing — branching/PITR/backups, SOC 2/SSO/SLA (unverified, not on pricing page) | cheapest managed HA Postgres seen ($15) | no free rung; standard-Postgres claims unverified here | Supabase Pro when you also need auth/storage |
| Turso | SQLite/libSQL edge DB | Free: 100 DBs, 5 GB, 500M row reads, 10M row writes/mo, 1-day PITR; Developer $4.99/mo: 9 GB (+$0.75/GB), 10-day PITR; SSO/BYOK on Developer+; SOC 2 and HIPAA listed; open-source self-host (verified: 2026-09) https://turso.tech/pricing — SLA (unverified) | embedded replicas, per-tenant DBs | **not Postgres** (SQLite dialect) → migration cost later | any Postgres above unless per-user/edge DBs are the design |
| Trigger.dev | background jobs, cron | Free: $5/mo compute credits, 20 concurrent runs, 5 members, 1-day logs; Hobby $10/mo (50 concurrent, 7-day logs); Pro $50/mo (200+ concurrent, 30-day logs); per-second compute from $0.0000169 + $0.000025/run; Enterprise: SOC 2 report, SSO, RBAC, pen-test report; Apache 2.0 self-host (verified: 2026-09) https://trigger.dev/pricing | durable runs with retries; cheap first paid rung; self-host exit | free credit can run out mid-month | Inngest when event-driven fan-out matters more than long-running jobs |
| Inngest | event-driven jobs | Free: 50k executions/mo, 5 concurrent steps, 5 seats, 24-h traces; Pro from $99/mo: 1M executions, 100+ concurrent, 7-day traces; Enterprise: SAML, RBAC, HIPAA, SOC 2 Type II badge (verified: 2026-09) https://www.inngest.com/pricing | serverless-friendly (works on Vercel/Cloudflare) | $0 → $99 cliff | Trigger.dev for a $10 middle rung |
| QStash / Cloudflare Queues | queues, cron, webhooks | QStash Free: 1,000 msgs/day, 10 schedules, 7-day max delay, DLQ 3 days; PAYG $1/100K msgs, 50 GB bandwidth free; Fixed 1M $180/mo (verified: 2026-09) https://upstash.com/pricing/qstash · Cloudflare Queues on **Workers Free**: 10,000 ops/day, 24-h retention; Paid: 1M ops/mo + $0.40/M, retention 4–14 days (verified: 2026-09) https://developers.cloudflare.com/queues/platform/pricing/ | HTTP-native, no worker process to host | 24-h retention on CF Free; QStash 10 schedules | Trigger.dev/Inngest once you need retries with observability |
| Cloudflare R2 | object storage (S3 API) | Free/mo: 10 GB-month, 1M Class A, 10M Class B (Standard class only); $0.015/GB-month, $4.50/M A, $0.36/M B; **egress free** (verified: 2026-09) https://developers.cloudflare.com/r2/pricing/ — Workers Paid requirement (not mentioned on page) | zero egress; S3 API = portable | no LatAm data-location guarantee (unverified) | Backblaze B2 for cold backups at $6.95/TB |
| Backblaze B2 | backups, cold storage (S3 API) | First 10 GB free; $6.95/TB/mo; egress free up to 3× stored, unlimited via Cloudflare/bunny.net/Fastly, else $0.01/GB; Class A/B/C calls free, Class D $0.004/10k after 2,500/day; rates shown for US West (verified: 2026-09) https://www.backblaze.com/cloud-storage/pricing — EU region, SOC 2 (unverified) | cheapest $/TB; free egress into the CDNs in this table | US/EU only | R2 for app-served objects |
| ImageKit | image CDN + DAM | Free: 20 GB bandwidth/mo, 3 GB storage, 2 users, 500 video units, 500 purges; Lite $9/mo: 40 GB (+$0.5/GB), 10 GB storage (+$0.1/GB), 3 users; SOC 2 Type II, ISO 27001, GDPR badges; SSO + custom SLAs on Enterprise; free plan "for low-traffic websites and apps, side projects, or just testing" (verified: 2026-09) https://imagekit.io/plans | $9 first rung; can front R2/S3 as origin | small free storage | Cloudinary when you need a full DAM/video pipeline |
| Cloudinary | media pipeline, DAM | Free: 25 credits/mo (1 credit = 1,000 transformations OR 1 GB storage OR 1 GB bandwidth), 3 users; Plus $99/mo (225 credits), Advanced $249/mo; Enterprise: SSO, SLAs, compliance review; ToS: no free-plan commercial restriction, "Cloudinary offers some of its plans free of charge" (verified: 2026-09) https://cloudinary.com/pricing · https://cloudinary.com/tos | richest transforms/video | $0 → $99 cliff | ImageKit for the $9 rung |
| UploadThing | file uploads (Next.js) | Free: 2 GB storage, unlimited uploads/downloads, 7-day audit logs; 100 GB app $10/mo; Usage-based $25/mo: 250 GB + $0.08/GB; regions + private files paid-only (verified: 2026-09) https://uploadthing.com/pricing — enterprise features, underlying storage/S3 API (unverified) | fastest Next.js upload DX | proprietary API; no compliance page | R2 + presigned URLs when portability matters |
| bunny.net | CDN, storage, DNS | **No free tier**: 14-day trial, $1/mo minimum; CDN $0.01/GB EU+NA, **South America $0.045/GB**, Asia/Oceania $0.03, MEA $0.06; Volume network $0.005/GB (verified: 2026-09) https://bunny.net/pricing/ — Storage/DNS/Shield-WAF prices (unverified, separate pages) | cheapest egress for media/video; B2 egress free into it | [PA] LatAm traffic 4.5× EU/NA rate; no free rung | Cloudflare Free for HTML/API; Bunny only for heavy media |
| Fastly | CDN, edge compute, WAF | Free tier/mo: 100 GB + 1M requests delivery, 10M Compute requests, 100k Image Optimizer, 5 GB object storage, 500k DDoS-protected requests, 5 TLS domains; "for prototyping, learning, and smaller workloads"; Growth usage-based; Enterprise custom (verified: 2026-09) https://www.fastly.com/pricing — SOC 2/PCI/SLA/SSO, commercial-use wording (unverified) | enterprise-grade edge on a real free rung | no explicit commercial grant; pricing beyond free opaque | Cloudflare unless you already need Fastly's enterprise edge |

**Amendment to the existing Cloudflare row**: add "Developer Platform Service-Specific Terms: no commercial-use or content-type restriction on Free for Workers/Pages/R2/Queues/D1 (verified: 2026-09) https://www.cloudflare.com/service-specific-terms-developer-platform/" — replaces "per user decision 2026-09-23" in the Vercel row with a verified fact.

### 2. Growth ladder per category
- **Hosting (Next.js/general)**: Cloudflare Pages/Workers Free (commercial OK, verified) → Netlify Personal $9 (Next.js runtime, still commercial) or Railway Hobby $5 / DO $5 (need Docker, WebSockets, long-running process) → Cloud Run PAYG or Railway Pro $20 (need regions, autoscale, enterprise paper: GCP compliance / Railway SSO+SLA via committed spend). Trigger up: free credits exhausted; runtime incompatibility (Node-only libs on Workers); need SLA/SSO/HIPAA.
- **Postgres**: Supabase/Neon Free (existing) → Prisma Postgres Starter $10 (first *daily backups*) or PlanetScale single-node $5 → PlanetScale HA $15 (need replicas/failover) → Prisma Business $129 (SOC 2 + ISO 27001 on the sheet) / PlanetScale or Aurora enterprise (unverified). Trigger up: launch with real users = backups; > 500 MB; HA; auditor asks for a SOC 2 report. Turso only when per-tenant/edge SQLite is the design.
- **Jobs/queues/cron**: Cloudflare Queues (Workers Free) or QStash Free → Trigger.dev Hobby $10 (retries + logs) → Inngest Pro $99 / Trigger.dev Pro $50 → Enterprise SSO + SOC 2 report (both). Trigger up: >1k msgs/day, need >24-h retention, need run observability, need SSO.
- **Object storage / images**: R2 Free 10 GB (S3 API, zero egress) → R2 PAYG $0.015/GB; backups to B2 $6.95/TB → images: ImageKit Free 20 GB → Lite $9 → Cloudinary Plus $99 (DAM/video) → Enterprise SSO/SLA. Trigger up: >10 GB stored; >20 GB image bandwidth; video pipeline; SSO.
- **DNS/CDN/WAF**: Cloudflare Free (existing) → Cloudflare Pro (existing row) → Bunny for media-heavy egress ($0.01/GB EU/NA; watch LatAm $0.045) → Fastly Growth/Enterprise for enterprise edge + WAF. Trigger up: video/large downloads (Bunny), enterprise edge compute or contractual SLA (Fastly).

### 3. Commercial-use-on-free-tier verdicts
| Provider | Allowed? | Quote | URL |
|---|---|---|---|
| Netlify | **Yes (explicit, staff)** | "Yes, you can use the free plan for commercial projects… you can't resell it" | https://answers.netlify.com/t/can-we-use-netlify-free-plan-for-commercial-purposes/41545 |
| Cloudflare Pages/Workers/R2/Queues/D1 | **Yes (no restriction in service-specific terms)** | terms contain no free-plan or content-type restriction; closest clause is subdomain renaming | https://www.cloudflare.com/service-specific-terms-developer-platform/ |
| Google Cloud Run | **Yes (explicit by construction)** | free tier requires "a Paid billing account or Free Trial billing account… active and in good standing" | https://docs.cloud.google.com/free/docs/free-cloud-features |
| Cloudinary | Yes (no restriction in ToS) | "Cloudinary offers some of its plans free of charge." | https://cloudinary.com/tos |
| Render | No restriction found; production discouraged | "Do not use them for production applications." | https://render.com/docs/free |
| Railway | No restriction found (pricing page only) | — | https://railway.com/pricing |
| DigitalOcean | No restriction found (pricing page only) | — | https://www.digitalocean.com/pricing/app-platform |
| Prisma Postgres | No restriction found (pricing page only) | — | https://www.prisma.io/pricing |
| Turso | No restriction found (pricing page only) | — | https://turso.tech/pricing |
| Nile | No restriction found | free tier "For prototyping or side projects" | https://www.thenile.dev/pricing |
| Inngest | No restriction found | "Generous monthly limits to prove it before production" | https://www.inngest.com/pricing |
| Trigger.dev | No restriction found (pricing page only) | — | https://trigger.dev/pricing |
| QStash / CF Queues | No restriction found | — | https://upstash.com/pricing/qstash · https://developers.cloudflare.com/queues/platform/pricing/ |
| R2 | Yes (covered by CF dev-platform terms) | see Cloudflare | https://developers.cloudflare.com/r2/pricing/ |
| Backblaze B2 | Yes (10 GB is standard PAYG allowance, not a plan) | "First 10GB storage is always free." | https://www.backblaze.com/cloud-storage/pricing |
| UploadThing | No restriction found (pricing page only) | — | https://uploadthing.com/pricing |
| ImageKit | No restriction found | free plan is "for low-traffic websites and apps, side projects, or just testing" | https://imagekit.io/plans |
| Fastly | No restriction found | "for prototyping, learning, and smaller workloads" | https://www.fastly.com/pricing |
| bunny.net | N/A — no free tier (14-day trial) | "$1 monthly minimum" | https://bunny.net/pricing/ |
| PlanetScale | N/A — no free tier | — | https://planetscale.com/pricing |
| Xata Cloud | N/A — no free managed tier ($9/mo minimum); self-host free | "Self-host on your own infrastructure" | https://xata.io/pricing |
| AWS | N/A as free start — 6-month credit clock | account closes "6 months after you open it or when your credits run out, whichever comes first" | https://aws.amazon.com/free/ |
| Coolify self-host | Yes | "Free Forever… No limitation or restrictions" | https://coolify.io/pricing |

"No restriction found" = checked pricing page (and terms where listed); a separate AUP/fair-use page was not fetched. Only Netlify's and Cloudflare's terms were read.

### 4. Rejects
- **Fly.io** — `getaddrinfo ENOTFOUND fly.io` from this environment; nothing verified. Do not add from memory.
- **Nile** — branching and backups "Coming soon" on every tier; SOC 2 "Coming soon". Not production-grade yet.
- **Xata Cloud** — pivoted; no free managed tier (Micro $9/mo minimum). Self-host viable but that is Coolify-class ops.
- **AWS (S3/Aurora Serverless) as a free start** — Free Tier is now $100 + up to $100 credits over 6 months; Free-plan account closes at 6 months. Aurora pricing not fetched. Keep AWS only as an enterprise rung (unverified here).
- **Render Free for anything user-facing** — ~1 min cold start, Postgres deleted after 30+14 days, workspace suspended when 750 h run out.
- **Railway Free as a "free tier"** — $1/mo credit cannot run a service; honest entry price is Hobby $5.
- **bunny.net as a free rung** — trial only; keep as paid media-CDN option.
- **Cloudinary / Inngest as first paid rung** — $0 → $99 cliffs; ImageKit $9 / Trigger.dev $10 cover the middle.

### 5. Unverified / risks
- Netlify: SOC 2, DPA, what 300 credits buy in GB/minutes, behaviour when credits run out (FAQ not rendered); commercial permission is a support-forum staff answer, not a ToS clause — ToS has no free-plan clause at all.
- Railway, DigitalOcean, Fastly, UploadThing: SOC 2 / DPA / regions not on pricing pages.
- Cloud Run paid per-request rates (page truncated); LatAm region existence.
- Hetzner: server prices not rendered; ID/advance-payment verification cited from a search snippet of the Fraud-prevention FAQ, not fetched. [PA] risk: onboarding from Panama may be gated.
- PlanetScale: branching/PITR/backups, SOC 2, SLA — pricing page silent.
- Prisma Postgres: PITR, regions, direct-TCP vs Accelerate — not on page.
- R2: whether Workers Paid is required (page silent; historically not).
- Backblaze: EU region and SOC 2 not on pricing page; rates quoted are US West.
- Bunny: Storage/DNS/Shield prices on separate pages, not fetched.
- "Reconfirmed May 2025" on the Netlify thread is the extractor's reading of the thread; not independently checked.
- Recent-change dates (Netlify credits, Railway Free, AWS credits, PlanetScale $5 Postgres) are observed states, not dated changelog entries.
- [PA] general: Cloud Run free egress is NA-only; Bunny LatAm is 4.5× EU/NA; Hetzner/B2 have no LatAm locations; DO LatAm region unverified.

Source file read (format reference): /Users/user/SynologyDrive/code/ai/claude/Projects/personal_skills/vibe-to-product/skills/v2p/references/stack/overview.md — no files edited.
</agent-message>

***
## Part B. Application services

<agent-message from="aa9b5fa78eb82a099">
### Conclusion
41 fetches (≈6 over budget; Brevo, Vonage, PayPal-PA and Payload pages failed and cost retries). No free tier in this slice carries an explicit non-commercial clause on its pricing page (ToS not read — see §6). Material findings: (a) **Better Auth was acquired by Vercel 2026-07-07**, library stays MIT; (b) **Payload Cloud is paused post-Figma**, self-host only; (c) **Amazon SES no longer has a perpetual free tier** ($200 credits/6 months); (d) [PA] **Twilio sells no Panama numbers** — outbound only at $0.1836/SMS; WhatsApp Cloud API covers +507 under "Rest of Latin America"; (e) [PA] **Polar lists Panama for sellers**, Dodo's Panama listing is buyers-only, Yappy is the only 1% local rail but needs a Banco General account. Source file format: `/Users/user/SynologyDrive/code/ai/claude/Projects/personal_skills/vibe-to-product/skills/v2p/references/stack/overview.md`.

### 1. Proposed rows (overview.md §2 column format)

| Provider | Role | Free tier / entry price | Strengths | Weaknesses | Pick the alternative when |
|---|---|---|---|---|---|
| WorkOS AuthKit | auth + enterprise SSO/SCIM | Free: first 1,000,000 MAU (email/password, social, passkeys, MFA, magic link); staging free, only production billed; SSO $125/connection/mo (1–15), down to $65 at 51–100; Directory Sync same; Enterprise 99.99% SLA (verified: 2026-09) https://workos.com/pricing | MFA free; per-connection billing means $0 until the first enterprise customer | $125/mo per SAML customer; SOC 2/DPA/regions not on pricing page (unverified) | Kinde when you want SOC 2 report + data residency at $25/mo |
| Kinde | auth | Free: 10,500 MAU, MFA (email/authenticator), social login, 5 organizations; Pro $25/mo (SOC 2 report from Pro); Plus $75/mo and Scale $250/mo: unlimited enterprise SSO "No additional costs"; SCIM "Coming soon"; data residency choice on all plans (verified: 2026-09) https://kinde.com/pricing/ | region choice free; unlimited SAML at $75/mo | SCIM not shipped; free-tier SSO-connection count ambiguous on page (unverified) | WorkOS when SCIM is the ask |
| Auth0 | auth | Free: 25,000 MAU, 1 custom domain, 5 organizations, 1 enterprise connection, SCIM, no MFA; B2C Essentials $35/mo (500 MAU); B2B Essentials $150/mo (500 MAU, 3 SSO connections, $100/mo each extra, max 30); Enterprise 99.99% SLA, private deployment (verified: 2026-09) https://auth0.com/pricing | largest free MAU with SAML; SCIM on free | B2B tiers jump to $150+/mo fast; MFA paid | Kinde/WorkOS for cheaper SAML |
| Better Auth | auth (self-hosted library) | Library free, MIT; managed infra Starter $0, Pro $20/mo, Enterprise custom (MSA, DPA, RBAC, log drain) (verified: 2026-09) https://www.better-auth.com/pricing · **acquired by Vercel 2026-07-07**, library stays MIT (verified: 2026-09) https://better-auth.com/blog/better-auth-joins-vercel · https://vercel.com/blog/vercel-acquires-better-auth | zero vendor MAU bill; plugins: 2FA, passkeys, organization, SSO/SAML 2.0, OIDC; data stays in your Postgres | you run the security surface; Vercel ownership → roadmap risk if you leave Vercel | Clerk/Kinde when you want hosted UI and support |
| Postmark | transactional email alt | Free: 100 emails/mo, never expires; Basic $15/mo 10k, $1.80/extra 1k; 45-day retention on Free/Basic/Pro; DMARC monitoring add-on $14+/mo/domain (verified: 2026-09) https://postmarkapp.com/pricing | deliverability reputation; separate transactional/broadcast streams | 100/mo free is a test tier; SOC 2/SLA/EU region not on pricing page (unverified) | Resend for the 3,000/mo free tier |
| Amazon SES | bulk/transactional email | **No perpetual free tier**: new accounts get up to $200 Free Tier credits for 6 months; $0.10/1,000 emails à la carte (Essentials $0.16/1k); dedicated IP $24.95/mo; VDM $1,250/mo (verified: 2026-09) https://aws.amazon.com/ses/pricing/ | cheapest per-email at volume; Resend is SES-backed anyway | sandbox exit, DKIM, bounce handling are yours; IAM sprawl | Resend/Postmark until >50k/mo |
| Loops | marketing + transactional email | Free: 4,000 emails per rolling 30 days to your 1,000 newest contacts, "Powered by Loops" footer, transactional counted in the 4,000; paid tiers not shown on page (unverified); SOC 2 and DPA linked (verified: 2026-09) https://loops.so/pricing | one tool for newsletter + transactional; React-friendly | paid pricing opaque; SSO/SLA/region not stated (unverified) | Resend + Resend Broadcasts if you only need transactional |
| Brevo | marketing email + SMS/WhatsApp | (unverified — pricing page JS-only, help center 403) third-party: 300 emails/day free, 100k contacts, Brevo logo, Starter ≈$9/mo | one bill for email + SMS + WhatsApp | daily cap shared by transactional and campaigns | Loops/Resend for developer-first |
| Twilio | SMS/WhatsApp | [PA] outbound SMS to Panama $0.1836/msg; **no Panama long code/short code/toll-free numbers listed**, only international numbers from $1.15/mo (verified: 2026-09) https://www.twilio.com/en-us/sms/pricing/pa | one API for SMS, WhatsApp, Verify | [PA] no local sender → no 2-way SMS with a +507 number; carrier fees extra | WhatsApp Cloud API directly when WhatsApp is the only channel |
| WhatsApp Business Cloud API (Meta) | WhatsApp | Per-message pricing since 2025-07-01 by template category; "All non-template messages are free"; utility templates free inside an open service window; [PA] Panama (+507) billed under "Rest of Latin America" rate card (verified: 2026-09) https://developers.facebook.com/docs/whatsapp/pricing | no middleman markup; free service conversations | Meta Business verification; template approval; no SMS | Twilio/Brevo when you need SMS fallback in one API |
| Polar | payments, MoR | 5% + 50¢ (Starter), +1.5% non-US cards, +0.5% subscriptions (Early Member); payouts 0.25% + $0.25 + $2/mo active payout (verified: 2026-09) https://polar.sh/docs/merchant-of-record/fees · [PA] Panama listed in supported seller countries (verified: 2026-09) https://polar.sh/docs/merchant-of-record/supported-countries | open-source, developer-first MoR; [PA] payouts | payout fees on top; pricing page 404 (marketing site) | Paddle for a mature MoR with sales-approval and enterprise invoicing |
| Dodo Payments | payments, MoR | 4% + 40¢ US domestic, +1.5% international, +0.5% subscriptions, +3% BNPL/PayPal; no monthly fee; Enterprise custom (verified: 2026-09) https://dodopayments.com/pricing · [PA] Panama on the **buyer** list only ("countries from which we accept payments") https://docs.dodopayments.com/miscellaneous/list-of-countries-we-accept-payments-from (verified: 2026-09); seller/payout eligibility for Panama **unverified** (third-party lists say yes) | cheapest MoR headline rate | young (seed-stage 2025); SOC 2/PCI not on pricing page (unverified) | Polar/Paddle where seller-country support is documented |
| PayPal | payments (PSP) | [PA] Panama country site exists https://www.paypal.com/pa/ ; withdrawal page for Panama (MetroBank real-time) exists but content not extractable (verified URL only: 2026-09) https://www.paypal.com/pa/webapps/mpp/withdraw-funds/impesa-metrobank ; Panama merchant fee, limits ($2k/day, $10k/mo per search snippet) **unverified** | buyer trust; [PA] a local withdrawal rail | not MoR; fee for PA unverified; withdrawal caps | Yappy for local, Polar/Paddle for global |
| Yappy Botón de Pago (Banco General) | [PA] local payments | Fee 1% + ITBMS, min $0.02 (search snippet of Yappy FAQ, **unverified on page**); requires Banco General commercial online banking (Merchant ID + secret key); WooCommerce plugin, PHP SDK, transaction APIs (verified: 2026-09) https://www.yappy.com.pa/comercial/desarrolladores/boton-de-pago-yappy/woocommerce/ · https://www.bgeneral.com/desarrolladores/boton-de-pago-yappy/sdk-en-php/ | 1% is the cheapest rail in Panama; ubiquitous locally | Panama-only; needs BG account; no subscriptions/MoR | PagueloFacil when you need cards + Yappy in one gateway |
| PagueloFacil | [PA] local gateway | 3.5% + $0.50 per approved transaction; $0.35 per declined; $1.00 per bank withdrawal; PCI DSS; REST API, SDKs, plugins; methods: cards, Clave, PagoCash, QR (verified: 2026-09) https://www.paguelofacil.com/ | Panama cards + Clave + Yappy in one; free tech support | declined-transaction fee; requirements (RUC, bank) not on page (unverified) | Tilopay for multi-country CA presence |
| Tilopay | [PA]/CA gateway | "Sin mensualidades ni costos fijos", free affiliation; 33 markets in CA & Caribbean; Panama via Yappy partnership; cards, Apple/Google Pay; 90+ platforms, API/SDK; PCI DSS; **per-transaction fee not published** (verified: 2026-09) https://tilopay.com/ | multi-country CA; Shopify/Wix/WooCommerce | fee opaque; enterprise features unverified | PagueloFacil for published pricing |
| dLocal | LatAm PSP | [PA] Panama listed in LatAm coverage (verified: 2026-09) https://dlocal.com/coverage/ ; pricing and minimum volume not published (unverified) | one contract for all LatAm local methods | enterprise sales-led; volume minimums (unverified) | only at multi-country LatAm scale |
| Cal.com | scheduling | Free: 1 user, unlimited event types, Stripe/PayPal; Teams $12/user/mo (yearly); Organizations $28/user/mo: SAML SSO, SCIM, "SOC 2, HIPAA, ISO 27001"; Enterprise custom: SLA, dedicated DB (verified: 2026-09) https://cal.com/pricing ; self-host license (unverified this session; AGPL per memory) | self-host escape hatch; SSO/SCIM at $28 not $15k | Orgs price per seat; self-host = your ops | Calendly when buyers expect its brand |
| Calendly | scheduling alt | Free: 1 event type, 1 calendar connection; Standard $10/seat/mo (yearly); Teams $16; Enterprise from $15k/yr, min 50 seats: SSO/SAML, SCIM, domain control, audit logs, deletion API (verified: 2026-09) https://calendly.com/pricing | brand recognition | free tier is 1 event type; SSO only at $15k/yr | Cal.com |
| SavvyCal | scheduling alt | No free plan (trial); Basic $10/user/mo, Premium $17; DPA linked; SSO/SOC 2 not on page (unverified) (verified: 2026-09) https://savvycal.com/pricing | overlay-calendar UX | no free, no SSO story | Cal.com |
| Tally | forms | Free: unlimited forms and submissions "within our fair use guidelines", Tally branding; Pro $24/mo (no branding, custom domain); Business $74/mo (retention controls, email verification); Belgium-based, GDPR; SSO/SOC 2/SLA not on page (unverified) (verified: 2026-09) https://tally.so/pricing | genuinely unlimited free; EU | no SSO; enterprise = "contact" | Formspree for a form backend you own (free 50 subs/mo, Basic $10/mo, Plus $25/mo — third-party, unverified) |
| Sanity | headless CMS | Free: 20 seats (admin/viewer only), 10k documents, 1M CDN req/mo, 250k API req/mo, 100 GB bandwidth, 2 public datasets; Growth $15/seat/mo (≤50 seats); Enterprise: SAML SSO, SOC 2/GDPR/CCPA, uptime SLA, DPA, custom data regions (verified: 2026-09) https://www.sanity.io/pricing | generous free; real-time; portable export | free = public datasets only; per-seat at Growth | Payload when you want the CMS inside your Next.js repo |
| Payload | headless CMS (self-hosted) | MIT, $0 self-hosted; **Payload Cloud paused for new projects after Figma acquisition (2025-06-17)**, pricing page 404 (third-party + Figma blog, verified URL only: 2026-09) https://www.figma.com/blog/payload-joins-figma/ | Next.js-native, your Postgres | no managed hosting path; Figma roadmap risk | Sanity when you want hosted content infra |
| Algolia | search | Free: 10k search req/mo, 50k records, 5k recommend req; Grow PAYG $0.50/extra 1k requests, $0.40/extra 1k records; Elevate: 99.99% availability, SSO, global regions (lower tiers US/UK/EU West); SOC 2 not on page (unverified) (verified: 2026-09) https://www.algolia.com/pricing | best relevance tooling; PAYG bridge | request billing on chatty UIs; proprietary index | Meilisearch/Typesense for OSS portability |
| Meilisearch Cloud | search | No free tier: 14-day trial; Cloud "Starting at $20/month" (usage $30/mo for 100k docs/50k searches; XS instance $23/mo); SOC 2 Type II, SSO SAML, up to 99.999% SLA on enterprise; self-hosting free (license unverified; MIT per memory) (verified: 2026-09) https://www.meilisearch.com/pricing | OSS core → self-host escape | no free cloud | Typesense Cloud for a lower entry (price unverified: calculator only; regions list confirmed; SOC 2 reports on request) https://cloud.typesense.org/pricing |
| Vercel AI Gateway | LLM gateway | "no markup and no platform fee on tokens"; free tier = subset of models with per-model rate limits, monthly free credit ends once you buy credits; BYOK only on paid tier, no fee; ZDR and provider allowlist Pro/Enterprise ($0.10/1k req team-wide); Enterprise invoiced (verified: 2026-09) https://vercel.com/docs/ai-gateway/pricing | 0% markup; budgets per key/project | Hobby availability not stated (unverified); ties spend to Vercel | OpenRouter when off-Vercel |
| OpenRouter | LLM gateway | Credits fee 5.5% ($0.80 min), crypto 5%; BYOK free up to $25k/mo then 5% (Enterprise $200k/mo); free models 50 req/day, 1,000/day with ≥$10 credits; SOC 2/SLA/DPA not on FAQ (unverified) (verified: 2026-09) https://openrouter.ai/docs/faq | 300+ models one key; BYOK free at startup scale | 5.5% on prepaid; enterprise terms unverified | Vercel AI Gateway on Vercel (0%) |
| Cloudflare AI Gateway | LLM gateway | Core (analytics, caching, rate limiting) free; Unified Billing 5% fee on credits; Workers AI + AI Gateway shared credits since 2026-08-07 (Cloudflare docs via search, verified URL only: 2026-09) https://developers.cloudflare.com/ai-gateway/reference/pricing/ · https://developers.cloudflare.com/changelog/post/2026-08-07-workers-ai-unified-billing/ | free proxy/cache in front of any provider | 5% if you let CF bill | pairs with the Cloudflare Pages path in overview |
| pgvector (Supabase/Neon) | vectors | $0 — Postgres extension inside the DB you already pay for (no fetch; extension, not a vendor) | no new vendor; RLS applies to embeddings | scale ceiling ~millions of vectors (opinion) | Pinecone past that |
| Pinecone | vectors | Starter free: 2 GB, 2M write units/mo, 1M read units/mo, 5 indexes, AWS us-east-1 only; Standard $50/mo minimum, WU $4–4.50/M, RU $16–18/M, $0.33/GB/mo; Enterprise: 99.95% SLA, SSO SAML, SOC 2, HIPAA, BYOC (verified: 2026-09) https://www.pinecone.io/pricing/ | serverless; clear enterprise tier | free = one US region; $50 floor | pgvector until it hurts; Turbopuffer has no free tier (floor $16/mo per third-party, unverified) |
| Crisp | support chat | Free: 2 seats, website chat, shared inbox, mobile apps, "For solopreneurs and entrepreneurs"; Mini $45/workspace/mo (4 seats), Essentials $95 (10), Plus $295 (20); extra seat $10/mo; WhatsApp from Mini; EU hosting + DPA on Plus/Enterprise; Enterprise: SLA (verified: 2026-09) https://crisp.chat/en/pricing/ | free 2-seat widget + inbox | jump to $45; EU/DPA only at $295 | Chatwoot for OSS/self-host |
| Chatwoot | support chat (OSS) | Cloud Hacker free: 2 agents, 500 conversations/mo, live chat only, 30-day retention; Startups $19/agent/mo (adds WhatsApp); Business $39; Enterprise: SSO/SAML, audit logs, SLA, 3-yr retention; cloud on AWS US (verified: 2026-09) https://www.chatwoot.com/pricing ; self-host license (unverified; MIT per memory) | self-host = data at home; WhatsApp at $19 | US-only cloud; 500 conv cap | Crisp for a polished widget |
| Plain | support (B2B) | No free plan (7-day trial); Foundation $35/seat/mo; Frontier: SSO + SCIM, support/uptime SLAs; SOC 2 Type II; DPA (verified: 2026-09) https://www.plain.com/pricing | Slack/Discord-native B2B support | no free tier | Help Scout free until you sell B2B |
| Intercom | support (enterprise endpoint) | (unverified, third-party) Essential ≈$29/seat/mo, Fin $0.99/resolution with 50-outcome minimum | Fin AI agent | per-resolution bill exceeds seats at volume | only when a customer contract demands it |

### 2. Growth ladders (free → first paid → enterprise; trigger)
- **Auth**: Better Auth in your DB or Clerk Hobby → Kinde Pro $25 / Clerk Pro $25 (trigger: MFA, custom domains) → WorkOS SSO $125/connection or Kinde Plus $75 unlimited SAML (trigger: first enterprise SSO/SCIM RFP). Auth0 only if a customer names it.
- **Email**: Resend free 3k → Resend Pro $20 / Postmark Basic $15 (trigger: 100/day cap or deliverability) → SES at $0.10/1k with dedicated IP (trigger: >100k/mo). Marketing: Loops free → Loops paid (price unverified) → Brevo/Customer.io (unverified).
- **SMS/WhatsApp [PA]**: WhatsApp Cloud API direct (free service messages) → Twilio outbound SMS $0.18 (trigger: OTP/SMS fallback) → Twilio Enterprise/Brevo (trigger: multi-channel inbox). No local Panama number on Twilio — design for one-way SMS.
- **Payments [PA]**: Yappy 1% for local B2C → PagueloFacil 3.5%+50¢ for cards → Polar/Paddle 5%+50¢ MoR for global SaaS (trigger: foreign customers/VAT) → Stripe via US entity (trigger: volume where 2% matters).
- **Scheduling**: Cal.com free → Teams $12/user → Organizations $28/user with SAML/SCIM/SOC 2 (trigger: team round-robin, then SSO). Calendly Enterprise $15k/yr min 50 seats is the anti-ladder.
- **Forms/CMS**: Tally free → Pro $24 (trigger: branding/custom domain). Sanity free → Growth $15/seat (trigger: editor roles, private datasets) → Enterprise (SSO, regions). Payload = self-host all the way, no cloud rung.
- **Search**: Postgres FTS/pgvector → Algolia free 10k req → Grow PAYG (trigger: relevance tooling) → Meilisearch Cloud $20+/Typesense (trigger: OSS portability) → Algolia Elevate/Meilisearch Enterprise (SLA/SSO).
- **AI gateway/vectors**: Vercel AI Gateway free tier (0% markup) or Cloudflare AI Gateway free → paid credits/BYOK (trigger: rate limits) → Enterprise invoicing + ZDR. Vectors: pgvector → Pinecone Starter → Standard $50 min → Enterprise (SLA/HIPAA).
- **Support**: Help Scout free → Crisp free/Chatwoot Hacker (trigger: live chat widget) → Crisp Mini $45 / Chatwoot Startups $19/agent (trigger: WhatsApp channel) → Plain $35/seat (B2B Slack support) → Intercom (contractual demand only).

### 3. Commercial use on free tier
| Provider | Allowed? | Quote | URL |
|---|---|---|---|
| WorkOS | No restriction found | "Staging environments: Free for testing. Only production environments are billed" — production is billed, not prohibited | https://workos.com/pricing |
| Kinde | No restriction found | — | https://kinde.com/pricing/ |
| Auth0 | No restriction found | — | https://auth0.com/pricing |
| Better Auth | Yes | MIT library; "free and open source" | https://www.better-auth.com/pricing |
| Postmark | No restriction found | "plan never expires" | https://postmarkapp.com/pricing |
| Amazon SES | N/A | no perpetual free tier ($200 credits, 6 months) | https://aws.amazon.com/ses/pricing/ |
| Loops | No restriction found | "Includes a small 'Powered by Loops' footer" | https://loops.so/pricing |
| Cal.com | No restriction found | — | https://cal.com/pricing |
| Calendly | No restriction found | — | https://calendly.com/pricing |
| Tally | Yes, fair-use | "unlimited forms and submissions for free within our fair use guidelines" | https://tally.so/pricing |
| Sanity | No restriction found | "For individuals experimenting or shipping smaller projects" | https://www.sanity.io/pricing |
| Algolia | Yes (implied) | "launching a startup, running a small online store" | https://www.algolia.com/pricing |
| Vercel AI Gateway | No restriction found | free tier = model subset + rate limits | https://vercel.com/docs/ai-gateway/pricing |
| OpenRouter | No restriction found | free models 50 req/day | https://openrouter.ai/docs/faq |
| Pinecone | No restriction found | "For trying out and for small applications" | https://www.pinecone.io/pricing/ |
| Crisp | Yes | "For solopreneurs and entrepreneurs. Your first shared inbox." (targeted re-check: "NO RESTRICTION FOUND"; an earlier summary claimed a restriction without a quote — discarded) | https://crisp.chat/en/pricing/ |
| Chatwoot | No restriction found | — | https://www.chatwoot.com/pricing |
| Plain, SavvyCal, Meilisearch Cloud, Turbopuffer | N/A | no free tier | see rows |
Caveat: only pricing pages were read; ToS/AUP not fetched for any provider.

### 4. Panama availability
| Provider | Supported? | Evidence |
|---|---|---|
| Polar (seller/payout) | Yes | https://polar.sh/docs/merchant-of-record/supported-countries |
| Dodo (seller/payout) | Unverified — Panama only on buyer list | https://docs.dodopayments.com/miscellaneous/list-of-countries-we-accept-payments-from |
| PayPal (PA account, withdrawal) | Yes (country site + MetroBank withdrawal page exist); fees/limits unverified | https://www.paypal.com/pa/webapps/mpp/withdraw-funds/impesa-metrobank |
| Yappy Botón de Pago | Yes (PA-only) | https://www.yappy.com.pa/comercial/desarrolladores/boton-de-pago-yappy/woocommerce/ |
| PagueloFacil | Yes (PA-native) | https://www.paguelofacil.com/ |
| Tilopay | Yes (via Yappy partnership; fees unpublished) | https://tilopay.com/ |
| dLocal | Yes (coverage list; commercial terms unverified) | https://dlocal.com/coverage/ |
| Twilio SMS | Outbound yes ($0.1836); **no Panama numbers** | https://www.twilio.com/en-us/sms/pricing/pa |
| WhatsApp Cloud API | Yes (+507, "Rest of Latin America") | https://developers.facebook.com/docs/whatsapp/pricing |
| Vonage SMS | Unverified (HTTP 403) | https://www.vonage.com/communications-apis/sms/pricing/ |
| Brevo SMS/WhatsApp | Unverified (page not readable) | https://www.brevo.com/pricing/ |

### 5. Rejects
- **Turbopuffer**: no free tier; commitment floor (third-party). **Plain, SavvyCal, Meilisearch Cloud**: no free tier — listed only as later rungs.
- **Calendly Enterprise**: $15k/yr, 50-seat minimum — not a solo-founder ladder.
- **Intercom**: seats + $0.99/resolution; enterprise endpoint only.
- **Payload Cloud**: paused; Payload survives only as self-host.
- **Contentful, Storyblok, Stytch, Descope, Firebase Auth, Orama, Keystatic, TidyCal, Formspree, Vonage**: not verified this session (budget/403) — do not add rows from memory. TidyCal ($29 lifetime via AppSumo) and Formspree (free 50/mo) have third-party numbers only.
- **Dodo Payments** as the [PA] MoR pick: seller eligibility undocumented; Polar documents it.

### 6. Unverified / risks
- Kinde: whether the 1 enterprise SSO connection sits on Free or Pro — page rendering ambiguous; SCIM "coming soon".
- WorkOS, Postmark, Loops, Tally, Algolia, OpenRouter: SOC 2/DPA/SLA/region facts absent from pricing pages — need trust/security pages.
- Vercel AI Gateway on the Hobby plan: doc says "every Vercel team account"; Hobby is a personal account — unverified. Matters because overview keeps Hobby pre-revenue.
- Yappy 1% + ITBMS fee is from a search snippet of the Yappy FAQ, not a fetched page. PayPal PA limits ($2k/day, $10k/mo) same.
- Cal.com self-host license (AGPL per memory), Meilisearch/Chatwoot self-host licenses (MIT per memory) not verified this session.
- SES "no perpetual free tier" reflects the AWS Free Tier change; re-check if the account predates it (older accounts may keep 3,000/mo for 12 months).
- Better Auth → Vercel: library stays MIT today; the managed dashboard is the lock-in vector. Twilio's missing Panama numbers should be re-checked on the phone-numbers catalogue, not just the SMS pricing page, before writing "none" as fact.
- Fetch overrun: 41 vs ~35 budget.
</agent-message>

***
## Part C. Operations and security

<agent-message from="a79431183281921ed">
**Conclusion first:** 12 new rows are ready for `overview.md` (one per category, alternates folded into the last column like the existing rows). Every free tier in this slice is usable commercially as far as the providers' *pricing pages* state — none carries a Vercel-Hobby-style clause — but I read pricing pages only, not ToS, so the verdict is "no restriction found on the pricing page", not "permitted by contract". Material changes seen: **Highlight.io is gone** (308 redirect to launchdarkly.com; its limits now live in LaunchDarkly's Developer tier), **Vercel Web Analytics cut prices up to 80%** (Hobby 50k events/mo, Pro $0.03/1k), **Comp AI no longer publishes a rate card** (quote-only on a 20-min call; the AGPL-3.0 repo still exists). Umami could not be reached (DNS failure on 3 hosts) → unverified.

File this feeds: `/Users/user/SynologyDrive/code/ai/claude/Projects/personal_skills/vibe-to-product/skills/v2p/references/stack/overview.md` (section 2 table, section 0 "Not yet verified" list). No files edited.

Fetch budget: 39 fetches + 3 searches (budget was ~35; the 4 extra were the Highlight redirect, Rollbar's agent page, and two failed Umami hosts).

***

### 1. Proposed rows (exact column format)

| Provider | Role | Free tier / entry price | Strengths | Weaknesses | Pick the alternative when |
|---|---|---|---|---|---|
| Grafana Cloud | logs, metrics, traces, k6, synthetics, on-call | Free: 50 GB logs + 50 GB traces + 50 GB profiles/mo, 10k metric series, 14-day retention, 3 users, 3 IRM users, 500 k6 VU-hours, 100k API synthetics; Pro $19/mo platform fee + usage (logs $0.05/GB process + $0.40/GB write + $0.10/GB retain; $8/active user); Enterprise from $25,000/yr commit (verified: 2026-09) https://grafana.com/pricing/ | one bill for OTel logs/metrics/traces + load test + on-call; OSS stack (Loki/Tempo/Mimir) = self-host exit | 14-day retention on free; per-user fee on Pro; SOC 2/ISO/DPA not on the pricing page (unverified) | Axiom when you want longer retention (30 d) and a flat $25 first tier; Honeycomb when you trace-first (20M events free) |
| Axiom | logs / events (OTel) | Personal: 500 GB/mo ingest, 25 GB storage, 30-day retention, no card; Axiom Cloud $25/mo (1 TB ingest, 100 GB storage) + usage; SSO +$100/mo, RBAC +$50/mo; SOC 2 Type II, ISO 27001, GDPR, HIPAA BAA add-on; regional selection (verified: 2026-09) https://axiom.co/pricing | highest free ingest in the slice; 30-day retention free | no self-host; SSO is a paid add-on | Grafana Cloud when you need metrics/traces UI + k6 + on-call in one place |
| Honeycomb | tracing / observability (OTel-native) | Free: 20M events/mo, 100M metric points, 2 triggers, unlimited seats; Pro from $150/mo (750M events, 2 SLOs); Enterprise: PrivateLink, private cloud, 100 SLOs (verified: 2026-09) https://www.honeycomb.io/pricing | best trace query UX; unlimited seats free; OTel first-class | $150 jump; SOC 2/ISO/DPA/regions not on pricing page (unverified) | Grafana/Axiom when logs volume, not traces, is the cost driver |
| New Relic | full-stack APM (enterprise ladder) | Free: 100 GB ingest/mo, 1 full-platform user, unlimited basic users, 8-day retention; Standard $10 first user then $99/user (max 5), $0.40/GB over 100 GB; EU data center +$0.05/GB; SAML SSO from Standard; FedRAMP/HIPAA with Data Plus (verified: 2026-09) https://newrelic.com/pricing | generous ingest; EU region option | $99/user cliff at the 2nd full user; per-GB overage | Grafana Cloud when >1 engineer needs full access |
| Better Stack | uptime + on-call + logs/traces | Free: 10 monitors @30 s, 1 status page, 3 GB logs (3-day), 3 GB traces (3-day), 100k exceptions/mo, 5k replays; Responder $34/mo ($29 yearly); SSO Azure/Okta $5/user/mo; SOC 2 Type II, GDPR, EU region (verified: 2026-09) https://betterstack.com/pricing | uptime + status + on-call + logs in one bill; 30 s checks free | 3-day log retention on free; extractor reported an alternate "Nano $30/mo EU" telemetry bundle — layout ambiguous, re-check before quoting | UptimeRobot when you only need cheap monitors; Instatus (existing row) already covers the status page |
| UptimeRobot | uptime monitoring | Free: 50 monitors @5 min, 1 status page, 3-month retention, 5 integrations, no SMS; Solo $9/mo yearly ($10 monthly): 60 s interval, 3 status pages, 12-month retention; SOC 2, GDPR DPA (verified: 2026-09) https://uptimerobot.com/pricing/ | most free monitors; cheapest paid tier | 5-min interval on free; no on-call product | Better Stack when you want on-call + 30 s checks free; Checkly when you need browser/API checks as code (Hobby: 10k API + 1k browser checks/mo, 1 user; Starter $24/mo; SOC 2 Type II, 99.9% SLA) https://www.checklyhq.com/pricing/ (verified: 2026-09) |
| PagerDuty | on-call / incident (enterprise ladder) | Free: 5 users, 1 schedule, 1 escalation policy, 100 SMS/phone per mo; Professional $21/user/mo yearly ($25 monthly); SAML SSO, SOC 2 (verified: 2026-09) https://www.pagerduty.com/pricing/ | the enterprise-recognised on-call tool; free covers a 5-person team | 1 schedule on free; per-user pricing | Grafana IRM (3 free users) or Better Stack when you already pay them; PagerDuty only when a customer contract names it |
| Plausible / Fathom | cookieless analytics (paid) | Plausible: no free plan, 30-day trial, Starter $9/mo 10k pageviews 1 site, Business $19/mo 10 sites + Stats API + 5-yr retention, Enterprise SSO/managed proxy; EU-hosted; "No need for cookie banners or GDPR consent" (verified: 2026-09) https://plausible.io/#pricing · Fathom: no free plan, 7-day trial (card), $15/mo 100k pageviews, 50 sites, "No cookie banners required" (verified: 2026-09) https://usefathom.com/pricing | no consent banner (web.md); Plausible is open source (self-host exit) | no free tier either; SOC 2/SLA not on either pricing page (unverified) | Vercel Web Analytics on Hobby (50k events/mo free, 1-month window; Pro $0.03/1k events, Plus +$10/mo team, 24-month window) https://vercel.com/docs/analytics/limits-and-pricing (verified: 2026-09; page dated 2026-08-25, "up to 80% price reduction" changelog) or Cloudflare Web Analytics (free on all plans, works without proxy/DNS change; limits not documented) https://developers.cloudflare.com/web-analytics/ (verified: 2026-09) when the budget is 0 |
| Feature flags: GrowthBook / Flagsmith | flags + experiments (beyond PostHog) | GrowthBook Starter: 3 seats, unlimited flags/experiments, 1M CDN req/mo, 1 project; Pro $40/seat/mo; self-host free unlimited; SOC 2 Type II, 99.99% SLA, OIDC SSO/SCIM on Enterprise (verified: 2026-09) https://www.growthbook.io/pricing · Flagsmith Free: 50k API req/mo, 1 seat, 1 project; Start-Up $40/mo ($45 monthly); SOC 2, 8 regions, on-prem (verified: 2026-09) https://www.flagsmith.com/pricing | both open source (self-host exit); warehouse-native experiments (GrowthBook) | PostHog free flags (1M req) already cover most saas-web cases → these are for statistics rigor or self-host | Statsig when you want unlimited flag checks + 2M events + 50k replays free, Pro $150/mo, SOC 2 T2, EU hosting, warehouse-native https://www.statsig.com/pricing (verified: 2026-09); LaunchDarkly only for enterprise procurement: Developer free 5 service connections, 1k client MAU, 10M logs + 10M traces, 5k replays + 5k errors; Foundation $10/service connection + $8.33/1k MAU, no seat fee; SOC 2/ISO/HIPAA https://launchdarkly.com/pricing/ (verified: 2026-09) |
| Doppler / Infisical | secrets management | Doppler Developer: 3 users ($8/mo extra), 10 projects, 4 envs, 50 service tokens, 5 config syncs, 3-day activity log; Team $21/user/mo; Enterprise: SAML SSO, SCIM, EKM, on-prem, 99.95% SLO (verified: 2026-09) https://www.doppler.com/pricing · Infisical Free: 5 identities, 3 envs, 10 secret syncs, unlimited projects; Pro $20/identity/mo yearly ($23 monthly); SAML/OIDC, 99.99% SLA, US/EU cloud; "MIT-licensed core is self-hostable at no cost on any plan" (verified: 2026-09) https://infisical.com/pricing | one source of truth for env vars → Vercel/GitHub Actions syncs; Infisical self-host exit | both charge per user/identity; Doppler 3-day audit log on free; SOC 2 not on either pricing page (unverified) | Vercel Sensitive env vars + GitHub Environments secrets while one person deploys; adopt a manager at the 2nd deployer or the 1st rotation incident |
| CI/CD alt: GitLab / CircleCI / Depot | CI beyond GitHub Actions | GitLab Free: 400 compute min/mo, 10 GiB storage, 5 users per private top-level group; Premium $29/user/mo yearly; self-managed CE/EE; Dedicated = regional residency (verified: 2026-09) https://about.gitlab.com/pricing/ · CircleCI Free: 30,000 credits/mo, 5 users, 30× concurrency; Performance from $15/mo; SSO only on Scale (verified: 2026-09) https://circleci.com/pricing/ · Depot: 7-day trial only (500 Docker min, 2,000 Actions min, 25 GB cache), Developer $20/mo; drop-in `docker build` / Actions runner replacement; SAML/SCIM on Business (verified: 2026-09) https://depot.dev/pricing | GitHub Actions 2,000 min already exceeds GitLab Free's 400; Depot = fastest Docker builds without leaving Actions | switching CI = rewrite pipelines; Depot has no free tier; SOC 2/ISO not on any of the three pricing pages (unverified) | stay on GitHub Actions; add Depot when Docker build time is the bottleneck (>10 min/build); GitLab only if the org already lives there |
| Security scanning: Semgrep / Aikido / Socket / GitGuardian | SAST, SCA, secrets | Semgrep Community: 10 contributors, 10 private repos, Code + Supply Chain (no Secrets); Teams $30/contributor/mo (up to 500 repos); SSO on Enterprise (verified: 2026-09) https://semgrep.dev/pricing · Aikido Free: 2 users, 10 repos, 1 cloud account, 1 domain, rescan every 3 days, SCA + SAST + secrets + CSPM + IaC + 10 AI autofixes; Basic $300/mo (10 users); SOC 2/ISO 27001, 99.5% SLA, SAML (verified: 2026-09) https://www.aikido.dev/pricing · Socket Free: 1 developer, 1 private repo, 3 members, 1,000 scans/mo; Team $25/dev/mo (min 5); SOC 2 T2, SSO/SCIM (verified: 2026-09) https://socket.dev/pricing · GitGuardian Free: 25 developers, 1 GB repo scanning, 500 historical detections, 10k API calls/mo; Growth = contact sales; US/EU hosting + SAML/SCIM from Growth (verified: 2026-09) https://www.gitguardian.com/pricing · Snyk Free: 5 projects, 100 Code tests/mo; Team from $25/mo (≤10 devs, 1,000 Code tests); Enterprise regions US-1/US-2/EU/AU (verified: 2026-09) https://snyk.io/plans/ | Aikido free bundles the whole OWASP checklist (SAST/SCA/secrets/IaC/CSPM); GitGuardian closes the private-repo secret-scanning gap in the GitHub row for 25 devs free; Semgrep OSS engine runs in CI with no account | Aikido jumps to $300/mo; Socket Team min 5 seats; Semgrep free excludes Secrets | GitHub Advanced Security only when you already pay GitHub Team/Enterprise (not fetched this session — unverified); OWASP ZAP for DAST in CI (free OSS, not fetched — unverified) |
| SimpleBackups | DB/storage backups off-provider | Basic (free): 1 backup job, daily, 1 GB DB max, 1 GB SimpleStorage, 25k-object storage backups; Lite $49/mo: 5 jobs, 12-h interval, 50 GB; ISO 27001, GDPR, SAML SSO + SLA on enterprise; sources Postgres/MySQL/Mongo/Redis/S3-compatible, destination your own bucket (verified: 2026-09) https://simplebackups.com/pricing | provider-independent copy = the DR item in core.md; ships to your own R2/S3 | free = 1 job ≤1 GB; $49 jump | provider-native: Supabase Pro daily backups (existing row); Supabase PITR add-on and Neon restore window not verified this session |
| Load testing: Grafana k6 / Artillery | load tests | k6: OSS CLI free; Grafana Cloud free 500 VU-hours/mo, then $0.15/VU-hour on Pro (verified: 2026-09) https://grafana.com/pricing/ · Artillery: OSS CLI; Cloud Free 30 reports/mo, 2 members, 5 workers/test, 30-min max; Team $199/mo; Enterprise SSO/audit/MSA from $1,199/mo; BYOC on your AWS (verified: 2026-09) https://www.artillery.io/pricing | both scripts are plain JS/YAML in the repo (no lock-in); k6 free hours cover a launch rehearsal | Artillery paid ladder is steep for a solo founder | k6 by default; Artillery when tests must run inside your own AWS account |
| Compliance automation (SOC 2 step) | evidence + policies | Comp AI: **no public rate card** — "we prepare your exact number and present it on a 20-minute call"; frameworks SOC 2, ISO 27001, HIPAA, GDPR, PCI, ISO 42001; raised $34M Series A 2026 (verified: 2026-09) https://trycomp.ai/pricing · repo `trycompai/comp` AGPL-3.0, open-core, updated 2026-09-22 (verified via search snippet only; repo page not fetched) https://github.com/trycompai/comp · Vanta / Drata / Secureframe: not fetched — quote-only, entry price (unverified) | Comp AI self-host = $0 evidence collection before an audit is booked | the audit itself is a separate CPA fee on every vendor; self-host means you run the integrations | do nothing until a prospect's security questionnaire asks for SOC 2 (core.md trigger); then Comp AI self-host first, Vanta/Drata when the buyer names one |

Rows fold in alternates already (Checkly, Statsig, LaunchDarkly, Vercel/Cloudflare analytics, Snyk) to keep the table at 12 new rows instead of ~30.

### 2. Growth ladders (free → first paid → enterprise; upgrade trigger)

- **Logs/metrics/traces:** Grafana Cloud free (or Axiom Personal) → Axiom Cloud $25/mo or Grafana Pro $19 + usage → Grafana Enterprise ($25k/yr) / Datadog (not fetched; unverified). Trigger: retention need >14 d (Grafana) or >30 d (Axiom), or a 4th engineer needing Grafana access ($8/user).
- **Error tracking:** Sentry Developer (existing) → Sentry Team $26 → Sentry Business. Alternate ladder: GlitchTip self-host $0 (Sentry-SDK compatible, US/EU cloud) → GlitchTip Small $15/mo 100k events → Rollbar Essentials $9/mo 10k events / Bugsnag Select. Trigger: 5k errors/mo cap or a 2nd user on Sentry free.
- **Uptime/status/on-call:** UptimeRobot free 50 monitors + Instatus free page (existing) → Better Stack Responder $29–34/mo (adds on-call) or UptimeRobot Solo $9 → PagerDuty Professional $21/user. Trigger: first paying customer with an SLA clause (needs 1-min checks + on-call escalation).
- **Privacy analytics:** Vercel Web Analytics Hobby 50k events / Cloudflare Web Analytics $0 → Plausible Starter $9 / Fathom $15 → Plausible Business $19 → Plausible Enterprise (SSO, managed proxy). Trigger: >50k events/mo on Vercel Hobby (collection pauses after 3-day grace), or need for custom events/API.
- **Feature flags:** PostHog free 1M flag requests (existing) → GrowthBook Pro $40/seat or Flagsmith Start-Up $40/mo → Statsig Pro $150 → LaunchDarkly Foundation. Trigger: need for experiment statistics beyond PostHog, or a buyer's procurement list naming LaunchDarkly.
- **Secrets:** Vercel Sensitive env vars + GitHub Environments ($0) → Doppler Developer (3 users free) or Infisical self-host → Doppler Team $21/user / Infisical Pro $20/identity → Enterprise (SAML, SCIM, on-prem). Trigger: 2nd person deploying, or first key rotation incident.
- **CI/CD:** GitHub Actions 2,000 min → Depot Developer $20/mo (Docker builds) → GitHub Team / GitLab Premium $29/user. Trigger: build time >10 min or Actions minutes exhausted 2 months running.
- **Security scanning:** Aikido Free (2 users, 10 repos) + Semgrep OSS in CI + `gitleaks` (existing) → GitGuardian Free (25 devs) for secrets at scale → Semgrep Teams $30/contributor or Snyk Team $25/mo → Aikido Basic $300/mo or GHAS. Trigger: 3rd developer (Aikido cap) or a customer asking for a scan report.
- **Backups:** Supabase Pro daily backups (existing) → SimpleBackups Basic free 1 job (off-provider copy) → Lite $49/mo. Trigger: DB >1 GB, or RPO <24 h required.
- **Load testing:** k6 OSS local → Grafana Cloud k6 500 VU-hours free → $0.15/VU-hour. Trigger: a launch/campaign rehearsal exceeding 500 VU-hours.
- **Compliance:** nothing → Comp AI self-host (AGPL) → Comp AI paid / Vanta / Drata (all quote-only). Trigger: a security questionnaire that requires a SOC 2 report.

### 3. Commercial-use-on-free-tier verdict

Method: each provider's *pricing page* was scanned for a restriction clause. **No Terms-of-Service page was fetched** (budget), so "allowed" below means "no restriction on the pricing page", not "contractually confirmed".

| Provider | Allowed? | Quote / evidence | URL |
|---|---|---|---|
| Grafana Cloud | no restriction found | none on page | https://grafana.com/pricing/ |
| Axiom | no restriction found | "Personal" plan name; no clause | https://axiom.co/pricing |
| Better Stack | no restriction found | none | https://betterstack.com/pricing |
| Honeycomb | no restriction found | none | https://www.honeycomb.io/pricing |
| New Relic | no restriction found | none | https://newrelic.com/pricing |
| Bugsnag | no restriction found | none | https://www.bugsnag.com/pricing/ |
| Rollbar | no restriction found | "no clauses limiting commercial use" | https://rollbar.com/pricing-for-agents |
| GlitchTip | no restriction found | none | https://glitchtip.com/pricing |
| UptimeRobot | no restriction found | none | https://uptimerobot.com/pricing/ |
| Checkly | no restriction found (positioning only) | Hobby is "Perfect for personal projects and learning" — descriptive, not a prohibition | https://www.checklyhq.com/pricing/ |
| OpenStatus | no restriction found | none | https://www.openstatus.dev/pricing |
| PagerDuty | no restriction found | none | https://www.pagerduty.com/pricing/ |
| Plausible / Fathom | n/a — no free tier (trials only) | — | see rows |
| Vercel Web Analytics (Hobby) | **inherits Vercel Hobby non-commercial rule** (existing row) | analytics page itself has no clause; Hobby fair-use applies | https://vercel.com/docs/analytics/limits-and-pricing |
| Cloudflare Web Analytics | no restriction found | "available on all plans" | https://developers.cloudflare.com/web-analytics/ |
| Statsig | no restriction found | none | https://www.statsig.com/pricing |
| GrowthBook | no restriction found | none | https://www.growthbook.io/pricing |
| Flagsmith | no restriction found | "fair usage policy applies" | https://www.flagsmith.com/pricing |
| LaunchDarkly | no restriction found | none | https://launchdarkly.com/pricing/ |
| Unleash | no restriction found | "Unleash Open Source is free, self-hosted, and has no limit on seats" | https://www.getunleash.io/pricing |
| Doppler | no restriction found | none | https://www.doppler.com/pricing |
| Infisical | no restriction found | "MIT-licensed core is self-hostable at no cost on any plan" | https://infisical.com/pricing |
| GitLab | no restriction found | none | https://about.gitlab.com/pricing/ |
| CircleCI | no restriction found | none | https://circleci.com/pricing/ |
| Depot | n/a — 7-day trial only | — | https://depot.dev/pricing |
| Snyk | no restriction found | none | https://snyk.io/plans/ |
| Semgrep | no restriction found | none | https://semgrep.dev/pricing |
| Socket | no restriction found | none | https://socket.dev/pricing |
| GitGuardian | no restriction found | none | https://www.gitguardian.com/pricing |
| Aikido | no restriction found | none | https://www.aikido.dev/pricing |
| SimpleBackups | no restriction found | none | https://simplebackups.com/pricing |
| Artillery | no restriction found | none | https://www.artillery.io/pricing |
| Umami | **unverified** | site unreachable this session | — |

### 4. Rejects (with reason)

- **Highlight.io** — product page 308-redirects to launchdarkly.com; no standalone pricing. Use LaunchDarkly Observability limits instead (row above).
- **Bugsnag (SmartBear)** — free tier is the weakest in the category (7.5k events, 1 user, 7-day retention) and the first paid tier's price is not readable on the page ("Select — starting at $0/month"). Rollbar/GlitchTip dominate.
- **OpenStatus** — free tier is 1 monitor @10 min, Starter $30/mo; Instatus (existing) + UptimeRobot beat it at both rungs. Pricing page dated 2025-11-10.
- **Unleash** — hosted PAYG is $75/seat/mo, 14-day trial only; the free path is self-host only. Fine as an OSS exit, not as a hosted first rung.
- **Depot** — no free tier (7-day trial); listed as an add-on, not a CI replacement.
- **GitLab CI as a replacement** — 400 min/mo vs GitHub's 2,000; only worth it if the org already lives on GitLab.
- **Comp AI hosted** — quote-only; only the self-host is a viable free rung.
- **1Password Secrets Automation, Datadog, Vanta, Drata, Secureframe, Buildkite, OWASP ZAP, GHAS/CodeQL, AWS Secrets Manager** — not fetched (budget); do not add rows from memory.

### 5. Unverified / risks

- **ToS not read for any provider.** A commercial-use ban can live in Terms, not on pricing (Vercel's does). Before publishing the verdict table as "allowed", spot-check ToS for the 3–4 providers actually adopted in the happy path.
- **Extraction was done by a small model on rendered pages**; ambiguous outputs flagged inline: Better Stack "Nano $30/mo EU" bundle, Bugsnag "Select $0", Grafana enterprise compliance (page silent on SOC 2/ISO/DPA), Honeycomb retention/compliance, Semgrep OSS license, GitGuardian ggshield license.
- **Umami Cloud**: DNS resolution failed for umami.is, cloud.umami.is, docs.umami.is (environment issue, not necessarily the site). Add to section 0 as unverified.
- **Provider-native PITR** (Supabase PITR add-on price, Neon restore window) not fetched — the backups row leans on SimpleBackups only.
- **Datadog** (as enterprise ceiling), **GHAS/CodeQL** pricing, **OWASP ZAP**, **Vanta/Drata/Secureframe** entry prices: not fetched; the ladders name them only as "buyer-named" endpoints.
- **Rollbar** prices come from the `pricing-for-agents` page ("generated from billing plan catalog July 8, 2026"); the human pricing page hid the numbers.
- **Comp AI open-source status** comes from a search snippet (GitHub repo AGPL-3.0, updated 2026-09-22), not from fetching the repo — mark `(verified via search snippet)` or re-fetch before relying on it.
- **Recency of pricing**: no provider page in this slice announced a change in the last 6 months except Vercel Web Analytics (price cut; docs dated 2026-08-25) and GitLab (Flex Commitment + AI credits, no date on page). Highlight→LaunchDarkly redirect is confirmed but undated.
- Suggested section-0 additions: Umami Cloud limits; Better Stack telemetry bundle names; Bugsnag Select price; Supabase PITR price; Vanta/Drata/Secureframe entry price; Datadog; GHAS pricing; ToS commercial-use clauses for adopted providers.
</agent-message>

***
## Part D. Terms-of-service and country-eligibility verification

<agent-message from="a848e1a846fdbcf99">
### Conclusion first

- **No default in the guide carries a Vercel-style non-commercial clause in its ToS/AUP.** 16 of 17 Task-1 providers verified from the governing document this session; two are *explicit grants* (UptimeRobot, Kinde), the rest "no restriction in <doc>". Netlify is the weak one: only the *Website* Terms of Use + AUP were readable; the platform subscription agreement URL 404s.
- **Three findings contradict provider-research.md**: (a) Dodo Payments **does** list Panama on its seller/merchant list (research said unverified/buyer-only); (b) Twilio's Panama regulatory page lists **Local and Toll-free number types** — "no Panama numbers" as written is not supported, though the SMS pricing page still shows no SMS-capable Panama type; (c) Yappy 1% + ITBMS is now verified on-page (was a snippet).
- **Process warning**: the WebFetch extractor fabricated an Upstash "Section 2.2 … non-commercial, personal, hobby … only" clause by echoing my prompt. Grep of the actual PDF text: zero hits for non-commercial/hobby/non-production. Any verdict in the research docs that came from a small-model summary without a verbatim quote should be treated as unverified.
- Budget: 27 WebFetch calls + ~19 raw `curl` loads/probes (Yappy, PayPal, Twilio route probes, five companion docs). Over the ~30 mark; the overrun bought the Upstash falsification and the Twilio/Yappy/PayPal raw reads.

### 1. ToS verdict table (all verified: 2026-09 unless marked)

| Provider | Commercial on free? | Governing clause / finding | Doc URL |
|---|---|---|---|
| Netlify | yes (conditional — platform agreement not located) | No restriction in "Netlify Website Terms of Use" (Mar 26, 2026; §4 Acceptable Use, §11 Policies) nor in AUP (Mar 8, 2023: spam, storage-only use, reverse engineering, "commercial exploitation" *of the Service* = resale, scraping, unlawful use). `/legal/terms-of-service/` → 404. Staff-forum answer in research stays the only affirmative statement. | https://www.netlify.com/legal/terms-of-use/ · https://www.netlify.com/legal/acceptable-use-policy/ |
| Supabase | yes | No restriction in Terms of Service (no date on page). §2(a): service provided "for Customer's internal business purposes" — standard licence scope (your business, no resale), not a non-commercial clause. | https://supabase.com/terms |
| Neon | yes (partial read) | No restriction in "Product Specific Schedule (Neon)" (Aug 5, 2026; Self-Service Plans, Fees, SLA). Master terms document not reached at this URL — (unverified). | https://neon.com/terms-of-service |
| Prisma Postgres | yes | No restriction in Terms of Service (Oct 15, 2024). §4: "Free Tier access depends on usage limits and feature availability. Prisma may suspend abusive users and restrict support or premium features to paid plans." §15 Fair Use: no circumvention of limits, credential sharing, illegal use, degrading performance. | https://www.prisma.io/terms |
| Clerk | yes | No restriction in Clerk Standard Terms and Conditions (Jul 2, 2026). §6 Free Trials: "subject to a usage cap that cannot be exceeded without becoming a paid Customer." | https://clerk.com/legal/terms |
| Kinde | yes (explicit) | ToS (no date on page): "We authorize you to use Our Intellectual Property solely for your limited commercial use." §3.4 licence is "personal, non-exclusive, royalty-free, revocable, worldwide, non-transferable" (boilerplate, not a use restriction). Only Beta Services are "for evaluation purposes only and not for production use." §17.1(a): no use that competes with Kinde. | https://docs.kinde.com/trust-center/agreements/terms-of-service/ |
| Resend | yes | No restriction in ToS (2026-08-27; §6 Free Tier and Free Trial, §10 Prohibited Uses, §28) nor in AUP (2026-08-27): spam, phishing, restricted industries (adult, pharma, gambling, MLM, payday loans…), high bounce/complaint rates, multi-account circumvention of limits. | https://resend.com/legal/terms-of-service · https://resend.com/legal/acceptable-use |
| Upstash (Redis + QStash) | yes | No restriction in Upstash Terms of Service (PDF, "Last Update Date: April, 2025") — verified by grepping the PDF text, not the extractor. Relevant clauses: "Fair Use: …We reserve the right to shut down or limit any activities that are creating an unreasonable burden"; "Excessive Bandwidth Use… suspend… throttle… or charge"; "Resource Inactivity: …inactive if it doesn't get any requests for a period of 1 week for free plans" → deletion. | https://upstash.com/trust/terms.pdf |
| Trigger.dev | yes | No restriction in Terms of Service (Jun 29, 2026). §15.4 free-tier support "entirely at Trigger.dev's option and discretion"; §17.1 AS IS. | https://trigger.dev/legal |
| Sentry | yes | No restriction in Terms of Service 3.0.0 (Feb 12, 2024). §17 "No-Charge Products are optional and either party may terminate No-Charge Products at any time for any reason." AUP grep: no commercial/personal/hobby wording. | https://sentry.io/terms/ · https://sentry.io/legal/aup/ |
| PostHog | yes | No restriction in "Terms, PostHog style" (no date on page); only prohibited-activity and plan-level compliance clauses. | https://posthog.com/terms |
| Cal.com | yes | No restriction in Terms of Service (effective 04/14/2021 — stale). | https://cal.com/terms |
| ImageKit | yes | No restriction in Terms of Use (27 June 2025). §9 AUP: illegal, infringing, malware, "excessively burden the service through multiple accounts", "Build a competing product or Service." Pricing-page "side projects, or just testing" is positioning only. | https://imagekit.io/terms/ |
| Better Stack | yes | No restriction in Terms of Use (Feb 14, 2025; Acceptable Use lists prohibited activities only). | https://betterstack.com/terms |
| UptimeRobot | yes (explicit) | ToS (May 26, 2026) §3: "UptimeRobot is available for any use, including commercial and business use." Fair Use Policy: "available for any use, including commercial and business use, by individuals, teams, and organizations of any size… applies to all accounts, on any plan". | https://uptimerobot.com/terms/ · https://uptimerobot.com/terms-fair-use/ |
| Axiom | yes | No restriction in Terms of Service (no date on page; §1.3 Trials, §1.4(v) → AUP). AUP grep: only spam/abuse conduct; "Personal" plan name has no ToS meaning. | https://axiom.co/terms · https://axiom.co/docs/legal/acceptable-use-policy |
| Grafana Cloud | yes (general ToS only) | No restriction in Grafana Labs Terms of Service (Jul 10, 2026; §9 Your Obligations and Use Restrictions). §1 says MSAs/specific terms apply to some areas; `/legal/grafana-cloud-terms/` → 404, so a Cloud-specific schedule was not read (unverified). | https://grafana.com/legal/terms/ |

Note for the guide: every "yes" above is "no restriction in the named document" plus, where quoted, the closest clause. Only UptimeRobot and Kinde affirmatively say "commercial". Cloudflare skipped per instruction.

### 2. Country-eligibility source table (verified: 2026-09)

| Provider | Role | Official list URL | List type | Notes |
|---|---|---|---|---|
| Paddle | MoR | https://www.paddle.com/help/start/intro-to-paddle/which-countries-are-supported-by-paddle | **Unsupported** list (applies to suppliers AND buyers) | 28 entries incl. Afghanistan, Belarus, Cuba, Haiti, Iran, Iraq, Libya, Nicaragua, North Korea, Russia, Somalia, Sudan, Syria, Venezuela, Yemen, Zimbabwe, occupied Ukraine regions. "Paddle is unable to support suppliers operating from the below countries". Absence ≠ guaranteed approval (Paddle vets sellers). Panama absent. |
| Polar | MoR | https://polar.sh/docs/merchant-of-record/supported-countries | Supported **seller/payout** list (~125 countries) | Requires Stripe Connect Express availability. Excluded: Cuba, Russia, Iran, North Korea, Syria (US sanctions). Panama listed. |
| Stripe | PSP | https://stripe.com/global | Supported **account** countries (50) | India, Indonesia = Preview (contact sales). Latin America: Brazil, Mexico only. Panama absent. Also lists Côte d'Ivoire, Kenya, Nigeria, South Africa, Gibraltar, UAE, Thailand, Malaysia. |
| Lemon Squeezy | MoR | https://docs.lemonsqueezy.com/help/getting-started/supported-countries | Supported **seller payout** lists (bank ≈130 countries; PayPal "200+") + "Unsupported countries for purchases" (17, buyer side) | India bank payouts invite-only via Stripe since May 2024. Panama on bank-payout list. |
| Dodo Payments | MoR | https://docs.dodopayments.com/miscellaneous/accepted-countries-and-territories | Supported **merchant acceptance + payouts** list (177 countries/territories) | "Eligibility is based on the country that issued the government-issued identity document you verify with, not on where your company is registered". Grandfathered under enhanced monitoring: Bangladesh, Egypt, Equatorial Guinea, Eritrea, Marshall Islands, Micronesia, Morocco, Nauru, Nigeria, Tuvalu, Ukraine. No explicit prohibited list on page. Panama = entry #119. |
| PayPal | PSP | https://www.paypal.com/pa/webapps/mpp/country-worldwide (US variant: /us/…) | **Availability** list by region with language (≈179 entries) | Does NOT distinguish business vs personal accounts or receive-only/send-only limits; business-account eligibility per country must come from PayPal's per-country user agreement (unverified). Panama listed under Central America (English / Español). Extractor could not read this page; raw HTML grep did. |
| Twilio | SMS/voice numbers | Catalogue: https://help.twilio.com/articles/223183068-Twilio-international-phone-number-availability-and-their-capabilities (linked from the SMS pricing page as "View the list of international numbers and capabilities") · per-country regulatory: https://www.twilio.com/en-us/guidelines/{cc}/regulatory | Numbers by country + capability | **Catalogue content unverified**: page is a 4 KB JS shell (help.twilio.com) / 403 (support.twilio.com); needs a browser (`/browse`). `/en-us/phone-numbers/pricing/{cc}` is a dead route for every country (US also 404). Per-country SMS pricing pages (`/en-us/sms/pricing/{cc}`) carry a "Phone number type" table usable at run time. |
| WhatsApp Cloud API (Meta) | WhatsApp | https://developers.facebook.com/docs/whatsapp/pricing (rate cards CSV/PDF linked) | Rate card by recipient calling code, grouped into markets | Groups: North America; Rest of Africa/Asia Pacific/Central & Eastern Europe/Western Europe/Latin America/Middle East; Other; ~30 named markets. "If a country is not listed below, it maps to Other." No unsupported list on this page; Meta's sanctions/availability restrictions live elsewhere (unverified). |

### 3. Panama spot checks

- **Yappy Botón de Pago fee — verified on page**: https://www.yappy.com.pa/faq-items/cuanto-cuesta-cobrar-por-yappy-comercial/ (FAQ dated 3 marzo 2022): "Por cada pago que recibas en tu negocio a través de cualquier método de cobro de Yappy Comercial, se cobrará una comisión de 1% + ITBMS del monto de la transacción (comisión mínima $0.02). La comisión se calcula por transacción y se realiza un solo débito diario a la cuenta que tengas asociada a tu negocio… Tus clientes no pagan por esta comisión." The "máximo $10.70" cap appeared only in a search snippet of https://www.bgeneral.com/yappycomercial/yappy-comercial-costos/ — (unverified).
- **Twilio Panama numbers — conditional**:
  - https://www.twilio.com/en-us/guidelines/pa/regulatory (200): lists **Local numbers** and **Toll-Free numbers (+507800)** for Panama, each with individual/business identity + Panama address requirements and a Letter of Declaration. Capabilities (voice/SMS) not stated on that page.
  - https://www.twilio.com/en-us/sms/pricing/pa (200): "Phone number type" table shows only **International Numbers** ($0.1836 outbound) — i.e., no SMS-capable Panama number type. Voice pricing page has no number table.
  - Consistent reading: Twilio can provision Panama local/toll-free numbers (likely voice-only); no SMS-enabled +507 number. Final word needs the catalogue (unverified, see §2).

### 4. Contradictions / corrections to provider-research.md

1. **Part B, Dodo row and §4**: "seller/payout eligibility for Panama unverified", "Panama on the buyer list only" → **wrong/outdated**. Official "Countries Eligible for Merchant Acceptance" lists Panama (177-country seller list, ID-document-country rule). Dodo is now documented at parity with Polar for Panama.
2. **Part B, Twilio row / §4 / conclusion (d)**: "Twilio sells no Panama numbers" → **overstated**. Regulatory page lists Local + Toll-free types for Panama. Correct claim: "no SMS-capable Panama number type on the SMS pricing page; local/toll-free exist per regulatory guidelines (capabilities unverified)".
3. **Part B §6, Yappy**: fee now verified on the Yappy page (1% + ITBMS, min $0.02); drop "(search snippet)"; keep the $10.70 max as unverified.
4. **Part A, Netlify**: "ToS has no free-plan clause" holds, but note the doc read is the *Website* Terms of Use; the platform agreement URL is dead. Verdict should stay "conditional: forum staff answer + no restriction in ToU/AUP".
5. **Parts A–C "no restriction found (pricing page only)"** for Prisma, Trigger.dev, QStash/Upstash, Kinde, Cal.com, ImageKit, Better Stack, UptimeRobot, Axiom, Grafana, Sentry, PostHog, Clerk, Supabase, Neon, Resend → upgradeable to the ToS-level verdicts in §1 (UptimeRobot and Kinde to "explicit yes").
6. **Overview Stripe row** "only Latin American countries are Brazil and Mexico" — still true on today's 50-country list.
7. **Overview Paddle row** — confirmed: Paddle's page is an unsupported list covering suppliers and buyers; Panama absent.

### Unverified / risks

- Twilio numbers catalogue content (JS-only); Grafana Cloud-specific terms (404); Neon master terms (only the Product Specific Schedule loaded); Netlify platform subscription agreement (404); PayPal business-account eligibility per country (availability page only); Meta's WhatsApp country restrictions beyond the rate card; Yappy $10.70 cap; Kinde/Axiom/PostHog/Supabase ToS effective dates (not shown on page).
- Extractor reliability: verdicts here that carry a verbatim quote were either quoted by the extractor or grepped from raw text; "NO RESTRICTION" answers from the extractor were accepted after it listed section headings — a residual risk that a clause was missed remains for Supabase, Neon, Trigger.dev, PostHog, Cal.com, Better Stack, Grafana, where I did not grep the raw HTML.
- Files read, none edited: /Users/user/SynologyDrive/code/ai/claude/Projects/personal_skills/vibe-to-product/docs/specs/provider-research.md · /Users/user/SynologyDrive/code/ai/claude/Projects/personal_skills/vibe-to-product/skills/v2p/references/stack/overview.md. Upstash PDF text saved at /private/tmp/claude-501/-Users-user-SynologyDrive-code-ai-claude-Projects-personal-skills-vibe-to-product/1492274f-1077-4d53-8aed-91b2c72d5216/scratchpad/upstash.txt.
</agent-message>

***
Copyright © 2026 Rafael Arciniegas. Licensed under the MIT License.
