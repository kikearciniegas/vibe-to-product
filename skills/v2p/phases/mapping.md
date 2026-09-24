# v2p phase: mapping

## Purpose
Turn BRIEF + SCAVENGE into `.v2p/PLAN.md`: an executable plan with providers, skills, pre-filled standards rows, and tasks that each carry a verifier.
Plan-writing itself follows a plan-writing method (superpowers in Claude Code); v2p adds the sections below.

## Preconditions
- `.v2p/BRIEF.md` required, with §11 = `none`. Otherwise print `Run /v2p handshake first.` and stop.
- `.v2p/SCAVENGE.md` optional: if absent, ask once "Run scavenge first (recommended) or plan without it?"; if planning without it, record `scavenge: skipped` in the PLAN.md header.
- If `.v2p/SCAVENGE.md` exists, its §7 must read `links: n/n ok` (the two numbers equal) and its §6 must not contain "not searched". Otherwise print `SCAVENGE.md failed its checks: re-run /v2p scavenge.` and stop.
<!-- claude-only -->
  In Claude Code this check is a script: `sh <this skill's dir>/scripts/check-pass.sh .v2p/SCAVENGE.md .v2p/.scavenge-pass` must print `OK`. A SCAVENGE.md written by hand has no receipt and fails, even if its text looks right.
<!-- /claude-only -->
- BRIEF §1 `Code: existing …` → `.v2p/AUDIT.md` must exist and have passed adopt's finalize step. Otherwise print `Run /v2p adopt first.` and stop.
<!-- claude-only -->
  In Claude Code: `sh <this skill's dir>/scripts/check-pass.sh .v2p/AUDIT.md .v2p/.audit-pass` must print `OK`.
<!-- /claude-only -->
- Existing `.v2p/PLAN.md` → offer resume (keep) or re-run.
- Checkpoint: `.v2p/work/mapping-plan.md` is reusable when its line-1 `written:` date is today and its `brief:` equals the current BRIEF's `written:` date; print "resuming from .v2p/work/mapping-plan.md" and do not re-plan. Otherwise it is stale: overwrite it, never read it.

## Step 0 — Resolve SCAVENGE markers
Every `[CONFLICT]`, `[CHECK]` and `[OPEN]` in SCAVENGE.md gets one outcome before providers are picked: decided (state which source wins and why), or turned into a task with its own verifier. None are carried silently into the plan.

## Step 1 — Provider selection
Six rules, in order. Each records a `defaulted` or `answered` row in PLAN §2.
BRIEF §7 `Operating country` or `Audience countries` is `unknown` or absent → ask for it before rule 3 and record the answer in PLAN §2. Read `references/stack/alternatives.md` only when a BRIEF constraint (must-have, won't-accept, budget, country) or a growth trigger needs a provider outside the overview, and for the country lists that rules 4 and 6 check.
1. BRIEF §8 must-have / won't-accept / existing accounts win over any default.
2. Profile default set from `references/stack/overview.md` §"Happy path per profile".
3. Hosting: commercial use and budget. Ask "Is it commercial yet? (it sells, advertises or takes bookings/leads for a business; first sale, ads, paid client work)" and write the user's answer into PLAN §2, attributed to the user. If the BRIEF describes an existing trading business, or the site's one job serves a paid service (bookings, quotes, leads), the recommended option is Yes; Not yet is recommended only for a genuinely pre-revenue project. Yes → **Cloudflare Pages** ($0, commercial use allowed on Free); Netlify Personal ($9) when the app needs the Next.js Node runtime that Workers cannot run; Vercel Pro only when BRIEF §7 `Budget/month` covers it AND the plan has a Vercel-only need — name that need in the hosting row, or do not offer Vercel Pro. Not yet → Vercel Hobby (non-commercial only), with the switch trigger written in the hosting row: at the first commercial use, move to Cloudflare Pages. If `Budget/month` is `0` and the profile default has a paid-only requirement (Instatus custom domain → Pro; Clerk MFA → Pro), name it and ask.
4. Money model ≠ none → payments, country-aware. At run time, open each provider's official country list (URLs and list types in `references/stack/alternatives.md` §"Country eligibility") and check BRIEF §7 `Operating country` against it: on a supported list it must be listed; on an unsupported list it must be absent (absence is not approval: the provider still vets the seller). Offer only eligible providers. Global SaaS → merchant of record first (Paddle, Polar, Lemon Squeezy — existing accounts only, it is migrating to Stripe Managed Payments — Dodo Payments); Stripe only when the user has a legal entity in a Stripe account country. Offer a local payment rail only when the operating country matches one documented in alternatives.md. Write one line per provider checked in PLAN §2: `<provider>: <country> <listed|absent|not listed> on <URL>, checked <YYYY-MM-DD>`. Ask with the eligible options and the tax/entity trade-off in each; no eligible provider → say so and ask, never default.
5. Data sensitivity flags → region-aware picks: EU audience → Sentry EU org, PostHog EU, Supabase EU region, Plausible (EU, cookieless) instead of GA4; Clerk has no EU hosting → say so and offer Supabase Auth.
6. Messaging (SMS, phone OTP or WhatsApp in BRIEF §8 integrations): for each audience country, open the SMS provider's per-country pricing page (alternatives.md §"Country eligibility") and look for an SMS-capable local number type. None listed → prefer the WhatsApp Business Cloud API (check the country's rate-card market) and plan SMS as one-way outbound only. Record the check as in rule 4.

Closed choices are asked; everything else is defaulted with one line saying so.

## Step 2 — Skills for this project
Portable: write `none` in PLAN §3.
<!-- claude-only -->
From `references/skills-catalog.md`, list only rows whose "use when" matches the profile / blocks ON and whose status is `installed`. `suggested` rows appear under "Optional, install first"; never auto-installed.
<!-- /claude-only -->

## Step 3 — Write the plan
Read `docs/DECISIONS.md` too when it exists: every open item in a `## From …` section becomes a task or an explicit non-goal in the PLAN.
Portable: write the plan yourself from `references/plan-template.md`, using BRIEF as the spec. Do not run a separate brainstorm; the BRIEF is the spec.
<!-- claude-only -->
Planning runs in the `planner` agent: spawn it with the Agent tool and `subagent_type: "planner"`. Never a general-purpose agent and never a fork (both run on the caller's model). Pass it: BRIEF, SCAVENGE, `docs/DECISIONS.md` if present, the provider decisions, the skills list, the standards files from BRIEF §9, and this instruction: "Use `superpowers:writing-plans` and load `writing-plans-extras` in the same turn. Plan location: `.v2p/PLAN.md` (overrides the skill default). Spec path in the header: `.v2p/BRIEF.md` + `.v2p/SCAVENGE.md`. Add the v2p sections from `references/plan-template.md` around the skill's own task structure. Do not run brainstorming — the BRIEF is the spec." Planner returns the PLAN body; the main thread writes it to `.v2p/work/mapping-plan.md` the moment it arrives (line 1: `written: <YYYY-MM-DDTHH:MM> · phase: mapping · part: plan · brief: <BRIEF written date>`), before any other action.
<!-- /claude-only -->

## Step 4 — v2p sections (the template enforces them)
- Architecture: `## Architecture`, the data flow from client to host to each §2 provider (core.md "Architecture Map").
- Threat Model: `## Threat Model`, assets, entry points (one per §2 provider that receives traffic or webhooks), top 5 abuse cases with the task that mitigates each.
- §2 Providers: one row per provider with plan, monthly cost at launch (from the overview table), and the wiring rows it needs (row ids from `references/stack/wiring.md`). The hosting row states the commercial answer from rule 3. A row on a free tier with a limit names its growth trigger and the next rung: the middle rungs in overview §"Growth rungs" (e.g. Prisma Postgres $10, Trigger.dev $10, ImageKit $9, Kinde $25) come before any $99 tier. §2 ends with `Total monthly at launch: $<n>` (arithmetic shown). If it exceeds BRIEF §7 `Budget/month`, pick cheaper rows or ask the user; only on the user's approval add `Over budget approved by user: <reason>`.
- §4b (landing only): one row per section of `references/landing-10-sections.md`: kept or omitted (reason in BRIEF §10), and the task that meets its Check.
- §3 Skills: installed rows to use, and at which task.
- §4 Standards: brownfield (BRIEF §1 `Code: existing`): copy `.v2p/AUDIT.md` §2 verbatim, statuses and evidence kept. Greenfield: **one row per checklist item** of the loaded files (landing 193, saas-web 190, internal-tool 185, native-app 141 — measured with `grep -c '^- \[ \]'` on 2026-09-23: core 129, web 48, landing 16, saas-web 13, internal-tool 8, native-app 12), status `pending` or `N/A <reason citing BRIEF §>`; conditional blocks OFF in BRIEF §9 → `N/A`. Evidence column empty (execute fills it).
- §5 Tasks: the plan method's task structure plus a **Verifier** line per task: `mechanical: <command> → <expected>` or `manual: <who checks what>`. Only `mechanical` tasks are eligible for an automated retry loop in execute (always with an iteration cap).
- §6 Review focus: the plan method's "five uncovered inputs" list, unchanged.

## Step 5 — Write and hand off
Write `.v2p/PLAN.md` (or print it in one code block if you cannot write files), print the path, the count of tasks (mechanical / manual), and `Next: /v2p execute (not available in this version)`.
Do **not** ask how to execute the plan; execute is not available yet.
<!-- claude-only -->
In Claude Code, write `.v2p/PLAN.draft.md` instead (never `PLAN.md` directly) and run `sh <this skill's dir>/scripts/finalize-plan.sh .v2p` until it prints `PASS`. It checks one Verifier line per task, one §4 row per standards item, the §2 total against the BRIEF budget (or the override line), no `---` rule, the `## Architecture` and `## Threat Model` sections, and `## 4b` for landing; it renames the draft to `PLAN.md`, writes the receipt `.v2p/.plan-pass` and clears `.v2p/work/mapping-*`.
<!-- /claude-only -->

<!-- claude-only -->
## Claude Code note
- `AskUserQuestion` for: payments provider, commercial yet / paid-tier acceptance, over-budget approval, EU-region choice, scavenge-skip. Operating/audience countries are asked as plain text (no fixed options).
- Brainstorming only if BRIEF §10 has ≥3 `deferred` rows that affect architecture.
- `planner` never writes; `quick` may write the file if the main thread prefers.
<!-- /claude-only -->

***
Copyright © 2026 Rafael Arciniegas. Licensed under the MIT License.
