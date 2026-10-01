# v2p phase: mapping

## Purpose
Turn BRIEF + SCAVENGE + DESIGN into `.v2p/PLAN.md`: an executable plan with providers, skills, pre-filled standards rows, and tasks that each carry a verifier.
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
- `.v2p/DESIGN.md` must have passed brand's finalize step. Portable: it ends with `Next: /v2p mapping`. Otherwise print `Run /v2p brand first.` and stop. Its Overview `Status: placeholder` → print "DESIGN.md is a placeholder: the tokens task must keep a single swap point; re-theme later via /v2p brand".
<!-- claude-only -->
  In Claude Code: `sh <this skill's dir>/scripts/check-pass.sh .v2p/DESIGN.md .v2p/.brand-pass` must print `OK`.
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
3. Hosting: commercial use and budget. Ask "Is it commercial yet? (it sells, advertises or takes bookings/leads for a business; first sale, ads, paid client work)" and write the user's answer into PLAN §2, attributed to the user. If the BRIEF describes an existing trading business, or the site's one job serves a paid service (bookings, quotes, leads), the recommended option is Yes; Not yet is recommended only for a genuinely pre-revenue project. Yes → **Cloudflare Workers** ($0, commercial use allowed on Free; Next.js server rendering runs on Workers per wiring W28, Cloudflare Pages only for a static export); Netlify Personal ($9) when the app needs the Next.js Node runtime that Workers cannot run; Vercel Pro only when BRIEF §7 `Budget/month` covers it AND the plan has a Vercel-only need — name that need in the hosting row, or do not offer Vercel Pro. Not yet → Vercel Hobby (non-commercial only), with the switch trigger written in the hosting row: at the first commercial use, move to Cloudflare Workers. If `Budget/month` is `0` and the profile default has a paid-only requirement (Instatus custom domain → Pro; Clerk MFA → Pro), name it and ask.
4. Money model ≠ none → payments, country-aware. At run time, open each provider's official country list (URLs and list types in `references/stack/alternatives.md` §"Country eligibility") and check BRIEF §7 `Operating country` against it: on a supported list it must be listed; on an unsupported list it must be absent (absence is not approval: the provider still vets the seller). Offer only eligible providers. Global SaaS → merchant of record first (Paddle, Polar, Lemon Squeezy — existing accounts only, it is migrating to Stripe Managed Payments — Dodo Payments); Stripe only when the user has a legal entity in a Stripe account country. Offer a local payment rail only when the operating country matches one documented in alternatives.md. Write one line per provider checked in PLAN §2: `<provider>: <country> <listed|absent|not listed> on <URL>, checked <YYYY-MM-DD>`. Ask with the eligible options and the tax/entity trade-off in each; no eligible provider → say so and ask, never default.
5. Data sensitivity flags → region-aware picks: EU audience → Sentry EU org, PostHog EU, Supabase EU region, Plausible (EU, cookieless) instead of GA4; Clerk has no EU hosting → say so and offer Supabase Auth.
6. Messaging (SMS, phone OTP or WhatsApp in BRIEF §8 integrations): for each audience country, open the SMS provider's per-country pricing page (alternatives.md §"Country eligibility") and look for an SMS-capable local number type. None listed → prefer the WhatsApp Business Cloud API (check the country's rate-card market) and plan SMS as one-way outbound only. Record the check as in rule 4.

Closed choices are asked; everything else is defaulted with one line saying so.

## Step 2 — Skills for this project
Portable: write `none` in PLAN §3.
<!-- claude-only -->
From `references/skills-catalog.md`, list only rows whose "use when" matches the profile / blocks ON and whose status is `installed`. `suggested` rows appear under "Optional, install first"; never auto-installed.
Design rows, always when the plan has UI tasks: `impeccable | every UI task`, `make-interfaces-feel-better | UI task review (quick) and review (full)`, `apple-design | native-app or gesture UI tasks`, `ui-ux-pro-max + ui-ux-pro-max-extras | tokens task (stack query)`; `animate` (emil) only for an animation or transition task; `img2threejs` only for a 3D object from a photo.
<!-- /claude-only -->

## Step 3 — Write the plan
Read `docs/DECISIONS.md` too when it exists: every open item in a `## From …` section becomes a task or an explicit non-goal in the PLAN.
Portable: write the plan yourself from `references/plan-template.md`, using BRIEF as the spec. Do not run a separate brainstorm; the BRIEF is the spec.
<!-- claude-only -->
Planning runs in the `planner` agent: spawn it with the Agent tool and `subagent_type: "planner"`. Never a general-purpose agent and never a fork (both run on the caller's model). Pass it: BRIEF, SCAVENGE, DESIGN, `docs/DECISIONS.md` if present, the provider decisions, the skills list, the standards files from BRIEF §9, and this instruction: "Use `superpowers:writing-plans` and load `writing-plans-extras` in the same turn. Plan location: `.v2p/PLAN.md` (overrides the skill default). Spec line in the header: `**Spec:** .v2p/BRIEF.md · .v2p/SCAVENGE.md · .v2p/DESIGN.md`. Add the v2p sections from `references/plan-template.md` around the skill's own task structure. Do not run brainstorming — the BRIEF is the spec." Planner returns the PLAN body; the main thread writes it to `.v2p/work/mapping-plan.md` the moment it arrives (line 1: `written: <YYYY-MM-DDTHH:MM> · phase: mapping · part: plan · brief: <BRIEF written date>`), before any other action.
<!-- /claude-only -->

## Step 4 — v2p sections (the template enforces them)
- Architecture: `## Architecture`, a Mermaid `flowchart LR` block of the data flow from client to host to each §2 provider (node ids from `references/stack/overview.md` §4, edges labelled with what crosses them), then one line per hop (core.md "Architecture Map"). The gate refuses the section without the Mermaid block.
<!-- claude-only -->
  After the PLAN is sealed, offer once to render the block with gstack `/diagram` into `docs/architecture.svg` + `docs/architecture.excalidraw`; on a no, the Mermaid block is the diagram.
<!-- /claude-only -->
- Threat Model: `## Threat Model`, assets, entry points (one per §2 provider that receives traffic or webhooks), top 5 abuse cases with the task that mitigates each.
- §2 Providers: one row per provider with plan, monthly cost at launch (from the overview table), and the wiring rows it needs (row ids from `references/stack/wiring.md`). The hosting row states the commercial answer from rule 3. A row on a free tier with a limit names its growth trigger and the next rung: the middle rungs in overview §"Growth rungs" (e.g. Prisma Postgres $10, Trigger.dev $10, ImageKit $9, Kinde $25) come before any $99 tier. §2 ends with `Total monthly at launch: $<n>` (arithmetic shown). If it exceeds BRIEF §7 `Budget/month`, pick cheaper rows or ask the user; only on the user's approval add `Over budget approved by user: <reason>`.
- §4b (landing only): one row per section of `references/landing-10-sections.md`: kept or omitted (reason in BRIEF §10), and the task that meets its Check.
- §3 Skills: installed rows to use, and at which task.
- §4 Standards: brownfield (BRIEF §1 `Code: existing`): copy `.v2p/AUDIT.md` §2 verbatim, statuses and evidence kept. A copied `gap` row gets no task unless the BRIEF asks for that work. Greenfield: **one row per checklist item** of the loaded files (landing 193, saas-web 190, internal-tool 185, native-app 141 — measured with `grep -c '^- \[ \]'` on 2026-09-23: core 129, web 48, landing 16, saas-web 13, internal-tool 8, native-app 12), status `pending` or `N/A <reason citing BRIEF §>`; conditional blocks OFF in BRIEF §9 → `N/A`. Evidence column empty (execute fills it).
- §5 Tasks: the plan method's task structure plus a **Verifier** line per task: `` mechanical: `<command>` → `<expected>` `` or `manual: <who checks what>`. The backticks around each command are required: a mechanical Verifier with no backticked `` `<command>` → `` pair runs nothing, and finalize-plan refuses it. Only the mechanical part runs: a pair inside the `manual:` part is never run, and a mechanical Verifier whose every command holds a `<placeholder>` runs nothing and fails execute, review and deploy. Only `mechanical` tasks are eligible for an automated retry loop in execute (always with an iteration cap). A review task or a launch task does not belong in §5: review and deploy are phases.
- Verifier convention: prefer self-checking commands (`test "$(cmd)" = 4`, `grep -q`, `set -e` chains) — execute treats exit 0 as pass and only compares bare-number expecteds. Absence: `! grep -rqE '<re>' <path>`. Counts: `grep -c`, or `wc -l | tr -d ' '`; never compare raw `wc -l` (macOS left-pads it, so `test "$(… | wc -l)" = 0` never passes). No bare `&` in a Verifier (it backgrounds the whole `&&` chain and races the next command): a server is started by the test runner (e.g. Playwright `webServer`) or by a script with an explicit wait-for-port, on a private port (e.g. `-p 31<nn>`), never a shared default such as 3000. Every `curl` carries `-m <seconds>`. A Verifier command cannot contain a backtick: the parser ends the command there and runs a fragment (match a literal backtick with `.` instead). A verifier that requires several terms checks each one separately (`for w in a b c; do grep -qi "$w" f || exit 1; done`), never one combined count (`grep -c 'a|b|c'` ≥ N passes with one term missing). A code task (its Files name a `.ts`, `.tsx`, `.js`, `.py`, `.go`, `.sh` or similar file) adds a behavioural check to its Verifier: the existing test suite that exercises the changed behaviour, or a command that runs the code; a `grep` or `test -f` proves the text is there, not that it works.
- Files completeness: a scaffold or generator task (create-next-app and the like) lists the generator's output files, or a glob such as `src/app/*`. Every file path named in a task's **Interfaces:** line appears in that task's **Files:** or an earlier task's; name the file, not only the symbol (`publicEnv` in `src/lib/public-env.ts`). A `Modify` path is the full repo path of a file that exists now or that this or an earlier task creates (`src/app/globals.css`, never bare `globals.css`). A task that adds or changes user-facing text lists every locale file in Files (e.g. both `src/i18n/es.json` and `src/i18n/en.json`; 4 of 19 live tasks needed an amendment for this).
- Design tokens and UI (from `.v2p/DESIGN.md`; its frontmatter is normative, never re-invented): one **tokens task** early in the order. Files = the stylesheet or theme file the stack owns (Next.js + Tailwind v4: `src/app/globals.css`; native: the theme file) plus the font wiring file (fonts via `next/font/google` unless a DESIGN.md Sources `font:` line names another licence). Verifier (mechanical, self-checking): `sed -n '/^colors:/,/^[a-z]/p' .v2p/DESIGN.md | grep -oE '#[0-9a-fA-F]{6}' | sort -u | while read -r c; do grep -qi "$c" src/app/globals.css || exit 1; done` → exit 0, plus `for w in "<display face first word>" "<body face first word>"; do grep -q "$w" <font wiring file> || exit 1; done` → exit 0. A **logo task** when Logo Rules names files that do not exist, or says `pending` (a wordmark from `typography.display`; no skill draws a vector logo). An **imagery task** when Imagery names assets. Every UI task's steps name the design skill it loads (execute's dispatch lists them). The Must-Avoid bullets become the verifier terms of the landing `Anti-"made-by-AI"` row (`references/standards/landing.md`).
- Provenance: a decision the PLAN attributes to the owner cites a real BRIEF label (a `Qn` in the BRIEF §10 item column) or `BRIEF §n:line`, or says `inferred`; never a `Qn` the BRIEF does not have.
- §6 Review focus: the plan method's "five uncovered inputs" list, unchanged.

## Cycle 2+ (after a finished cycle was archived)
When `.v2p/cycles/*/REVIEW.md` exists and `.v2p/PLAN.md` does not (brand's re-theme archived the cycle):
- Header adds `cycle: <n> · previous: .v2p/cycles/<dir>`.
- §2 Providers is copied from the archived PLAN unless BRIEF §7 or §8 changed since (no re-asking); `## Architecture`, `## Threat Model` and §4b are copied.
- §4 Standards = the archived REVIEW §3 verbatim; the rows the new tasks touch go back to `pending` with the evidence cell emptied (the row count is unchanged).
- §5 holds only the tasks for the delta (re-theme: tokens, fonts, logo, imagery, copy/voice). Planner instruction: "scope: the DESIGN.md delta against `.v2p/work/brand-incumbent.md`; do not re-plan finished work."
- Execute and review then run unchanged on a new branch.

## Step 5 — Write and hand off
Write `.v2p/PLAN.md` (or print it in one code block if you cannot write files), print the path, the count of tasks (mechanical / manual), and `Next: /v2p execute`.
<!-- claude-only -->
In Claude Code, write `.v2p/PLAN.draft.md` instead (never `PLAN.md` directly) and run `sh <this skill's dir>/scripts/finalize-plan.sh .v2p` until it prints `PASS`. It checks one Verifier line per task, one §4 row per standards item, the §2 total against the BRIEF budget (or the override line), no `---` rule, the `## Architecture` and `## Threat Model` sections, `## 4b` for landing, the Verifier convention (a mechanical Verifier with no backticked command, raw `wc -l` in a comparison, a bare `&` in a mechanical verifier, `curl` without `-m`, a backtick inside a command), a one-line **Files:**, every `Qn` it cites is a label in BRIEF §10, a WARN for a code task whose mechanical Verifier names no test runner or run command, a WARN for a task whose Files name a regular root `DESIGN.md` (the project's own design doc, kept by brand in adopt mode), no `\|` inside backticks in a table row, and that every Interfaces path appears in a Files line up to its task; it renames the draft to `PLAN.md`, writes the receipt `.v2p/.plan-pass` and clears `.v2p/work/mapping-*`. Run it in the real repo (`.v2p` in the repo root): `Modify` paths are checked relative to the repo root, so a dry-run in an empty scratch directory false-fails them.
<!-- /claude-only -->

<!-- claude-only -->
## Claude Code note
- `AskUserQuestion` for: payments provider, commercial yet / paid-tier acceptance, over-budget approval, EU-region choice, scavenge-skip. Operating/audience countries are asked as plain text (no fixed options).
- Brainstorming only if BRIEF §10 has ≥3 `deferred` rows that affect architecture.
- `planner` never writes; `quick` may write the file if the main thread prefers.
<!-- /claude-only -->

***
Copyright © 2026 Rafael Arciniegas. Licensed under the MIT License.
