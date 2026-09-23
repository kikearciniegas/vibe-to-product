# v2p phase: mapping

## Purpose
Turn BRIEF + SCAVENGE into `.v2p/PLAN.md`: an executable plan with providers, skills, pre-filled standards rows, and tasks that each carry a verifier.
Plan-writing itself follows a plan-writing method (superpowers in Claude Code); v2p adds the sections below.

## Preconditions
- `.v2p/BRIEF.md` required, with §11 = `none`. Otherwise print `Run /v2p handshake first.` and stop.
- `.v2p/SCAVENGE.md` optional: if absent, ask once "Run scavenge first (recommended) or plan without it?"; if planning without it, record `scavenge: skipped` in the PLAN.md header.
- Existing `.v2p/PLAN.md` → offer resume (keep) or re-run.

## Step 1 — Provider selection
Five rules, in order. Each records a `defaulted` or `answered` row in PLAN §2.
1. BRIEF §8 must-have / won't-accept / existing accounts win over any default.
2. Profile default set from `references/stack/overview.md` §"Happy path per profile".
3. Commercial use and budget. Ask "Is it commercial yet? (first sale, ads, paid client work)" and write the answer into PLAN §2. Not yet → Vercel Hobby, with the switch trigger written in the Vercel row: at the first commercial use, move to Vercel Pro or Cloudflare Pages. Yes → Vercel Pro or Cloudflare Pages now. If `Budget/month` (§7) is `0` and the profile default has a paid-only requirement (Vercel commercial use → Pro; Instatus custom domain → Pro; Clerk MFA → Pro), name it and ask.
4. Money model ≠ none → payments provider: default **Paddle** (MoR; Panama is not on its unsupported-country list). Stripe only if the user has a US/supported-country entity. Lemon Squeezy only for an existing account (in migration to Stripe Managed Payments). Ask with the three options and the tax/entity trade-off in each.
5. Data sensitivity flags → region-aware picks: EU audience → Sentry EU org, PostHog EU, Supabase EU region, Plausible (EU, cookieless) instead of GA4; Clerk has no EU hosting → say so and offer Supabase Auth.

Closed choices are asked; everything else is defaulted with one line saying so.

## Step 2 — Skills for this project
Portable: write `none` in PLAN §3.
<!-- claude-only -->
From `references/skills-catalog.md`, list only rows whose "use when" matches the profile / blocks ON and whose status is `installed`. `suggested` rows appear under "Optional, install first"; never auto-installed.
<!-- /claude-only -->

## Step 3 — Write the plan
Portable: write the plan yourself from `references/plan-template.md`, using BRIEF as the spec. Do not run a separate brainstorm; the BRIEF is the spec.
<!-- claude-only -->
Spawn `planner` with: BRIEF, SCAVENGE, the provider decisions, the skills list, the standards files from BRIEF §9, and this instruction: "Use `superpowers:writing-plans` and load `writing-plans-extras` in the same turn. Plan location: `.v2p/PLAN.md` (overrides the skill default). Spec path in the header: `.v2p/BRIEF.md` + `.v2p/SCAVENGE.md`. Add the v2p sections from `references/plan-template.md` around the skill's own task structure. Do not run brainstorming — the BRIEF is the spec." Planner returns the PLAN body; the main thread writes the file.
<!-- /claude-only -->

## Step 4 — v2p sections (the template enforces them)
- §2 Providers: one row per provider with plan, monthly cost at launch (from the overview table), and the wiring rows it needs (row ids from `references/stack/wiring.md`). The Vercel row states the commercial answer from rule 3.
- §3 Skills: installed rows to use, and at which task.
- §4 Standards: **one row per checklist item** of the loaded files (landing 155, saas-web 152, internal-tool 147, native-app 108 — measured with `grep -c '^- \[ \]'` on 2026-09-23: core 96, web 43, landing 16, saas-web 13, internal-tool 8, native-app 12), status `pending` or `N/A <reason citing BRIEF §>`; conditional blocks OFF in BRIEF §9 → `N/A`. Evidence column empty (execute fills it).
- §5 Tasks: the plan method's task structure plus a **Verifier** line per task: `mechanical: <command> → <expected>` or `manual: <who checks what>`. Only `mechanical` tasks are eligible for an automated retry loop in execute (always with an iteration cap).
- §6 Review focus: the plan method's "five uncovered inputs" list, unchanged.

## Step 5 — Write and hand off
Write `.v2p/PLAN.md` (or print it in one code block if you cannot write files), print the path, the count of tasks (mechanical / manual), and `Next: /v2p execute (not available in this version)`.
Do **not** ask how to execute the plan; execute is not available yet.

<!-- claude-only -->
## Claude Code note
- `AskUserQuestion` for: payments provider, commercial yet / paid-tier acceptance, EU-region choice, scavenge-skip.
- Brainstorming only if BRIEF §10 has ≥3 `deferred` rows that affect architecture.
- `planner` never writes; `quick` may write the file if the main thread prefers.
<!-- /claude-only -->

***
Copyright © 2026 Rafael Arciniegas. Licensed under the MIT License.
