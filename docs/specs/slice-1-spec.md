# v2p SLICE 1 — implementation spec

Written 2026-09-23 by the planner agent; approved by the user the same day.

## User decisions (locked)
- Runtime: BOTH — Claude Code skill + generated portable pack.
- Multi-LLM: Claude everywhere + Codex (`/codex`) as review-only second opinion.
- Backbone: superpowers + gstack; v2p phases are thin orchestrators.
- Skill shape: ONE skill dir `skills/v2p/`, phases as files (`/v2p <phase>`).
- Old root `SKILL.md` and `STANDARDS.md`: DELETE after the loss check passes (backup: `~/.claude-backups/v2p-pre-slice1-2026-09-23/`).
- Install: symlink `~/.claude/skills/v2p -> <project>/skills/v2p` after checks pass.
- Git: `git init` locally, no remote; exclude `ivanvibecodes-extract/` and `.serena/`.
- `web.md` as a shared web standards file: accepted.
- PERSONA.md: fold into router, do not create.

## 1. File tree (source of truth: this project dir)

```
vibe-to-product/
├── README.md                          # rewritten (h)
├── WORKFLOW.md                        # untouched except line 58: "PERSONA.md" → "references/standards/core.md"
├── build-portable.sh                  # NEW, generates dist/
├── dist/v2p-portable.md               # GENERATED; never hand-edited
├── docs/specs/slice-1-spec.md         # this file
├── skills/v2p/
│   ├── SKILL.md                       # router (a)
│   ├── phases/handshake.md            # interview (b)
│   └── references/
│       ├── brief-template.md
│       ├── model-routing.md           # Claude-only, excluded from dist
│       ├── landing-10-sections.md
│       ├── ux-laws.md
│       └── standards/{core,web,landing,saas-web,internal-tool,native-app}.md
└── (untouched) facebook-video-suggested-actions.md, ivanvibecodes-video-suggested-actions.md, ivanvibecodes-extract/, .serena/
DELETED after verification: SKILL.md (root), STANDARDS.md (root)
```

Root SKILL.md content is redistributed: Triad + failure loop already live in WORKFLOW.md; "Mandatory Output Format" → evidence rule in core.md; "Guardrails" → core.md "Warnings" block.

Portable runtime: user pastes `dist/v2p-portable.md` into ChatGPT/Gemini and says what they are building; the router's first section tells the model to run the handshake and load only the matching profile section.

Marker for dated/versioned items: plain text `(verified: 2026-09)` at end of line.

Every source `.md` keeps as last line: `Copyright © 2026 Rafael Arciniegas. Licensed under the MIT License.` (build script de-duplicates in dist). Sources must not use `---` as a horizontal rule (use `***`).

## 2. Per-file spec

### 2.1 `skills/v2p/SKILL.md` — router (~70 lines)
Frontmatter:
```yaml
---
name: v2p
description: Turn an idea or AI prototype into a production product. Use when the user says "v2p", "vibe to product", wants to start/plan/harden/ship an app, landing page, SaaS, internal tool or mobile app, or asks "what are we building". Runs a short interview (handshake) that writes .v2p/BRIEF.md, then routes to later phases.
---
```
Sections:
1. What this does (3 lines): thin orchestrator; one handoff file per phase in `<project>/.v2p/`; never reimplements superpowers/gstack.
2. Entry: optional arg `handshake|scavenge|mapping|execute|review|deploy`. None: if `.v2p/BRIEF.md` exists → print its §1 line and "Next" line, offer resume or re-run; else ask "What are we building? One paragraph." then start handshake.
3. Target dir rule: BRIEF → `$PWD/.v2p/BRIEF.md`. If `$PWD` has no code and no `.v2p/`, ask once whether this dir is the project. Never scaffold a project. Recommend committing `.v2p/` (it is the contract).
4. Profiles table: `landing` (one-action page, no login), `saas-web` (logged-in, users outside your org), `internal-tool` (logged-in, users work for you), `native-app` (iOS/Android binary). Disambiguators: internal vs saas → "Do users work for you?"; landing vs saas → "Does anyone log in?"; native vs saas → "If I handed you a finished API tomorrow, how much work remains?". No fit: nearest profile, record gap in BRIEF §10, never invent a profile. AI features, payments, webhooks, i18n are conditional blocks in standards, not profiles.
5. Phase table: `handshake` → `phases/handshake.md` → `.v2p/BRIEF.md` (available). `scavenge` (SCAVENGE.md), `mapping` (PLAN.md), `execute` (none), `review` (REVIEW.md), `deploy` (none) → "not available in this version"; router replies so, no improvisation.
6. When to load references: standards per the §4 mapping table (at handshake end to fill BRIEF §9, and by later phases); `landing-10-sections.md` only for landing; `ux-laws.md` at any UI review; `model-routing.md` when delegating. Source rule: no `---` horizontal rules.
7. `<!-- claude-only -->` delegation rule: interview on main thread (needs `AskUserQuestion`); read `references/model-routing.md` before spawning; Fable reasoning only via `planner`, never a fork. `<!-- /claude-only -->`
8. Copyright line.

### 2.2 `skills/v2p/phases/handshake.md` (~110 lines)
Sections: Purpose · Discipline · Question list (§3 verbatim) · Confirmation gate · Write step · claude-only note (use `AskUserQuestion` for closed choices: profile confirm, brand status, money model; free text for vision/success) · Copyright.
Discipline (adapted, paraphrased, from github.com/Hainrixz/the-architect):
- Max 3 questions per turn.
- Skip anything the opening already answered; say "taking X from what you said".
- Relevance test: only ask if the answer changes BRIEF content.
- Opinionated defaults: when the user shrugs, state the default and record it `defaulted`.
- Gaps marked `[NEEDS CLARIFICATION: <q> — blocks <what>]`; each resolves answered / defaulted / deferred-to-non-goal before writing.
- After each turn restate a running brief ≤10 lines.
- Mirror the user's language in questions and BRIEF.
Gate: show running brief + decisions log; write only on explicit yes/ok/confirmed; a change request or question re-enters the loop. Then write `.v2p/BRIEF.md` from the template, print path and `Next: /v2p mapping (not available yet in this version)`.

### 2.3 `references/brief-template.md` — see §3.

### 2.4 `references/standards/core.md` (~230 lines)
Header block:
- **How to claim an item (evidence rule).** One row per claimed item: `| item | done / N/A / pending | evidence |`. Evidence = runnable command + observed output/exit code, artefact path, or URL. `N/A` needs a reason citing a BRIEF section. `[x]` without evidence = defect. Examples: `Security headers | done | curl -sI https://staging.x | grep -cE 'strict-transport|content-security' → 2`; `RLS | N/A | landing has no database (BRIEF §8)`. Delivery footer name: **Standards evidence**.
- **Warnings (not gates).** (1) Files >200 lines get a review comment + split proposal; split when a reader can't hold the file, not by count. (2) A request violating a security/performance item: name item and consequence, proceed only on explicit user override, record override in BRIEF §10. (3) Hard rules that stay: no `any`; no secrets in client code.
- Checklist sections, original wording VERBATIM for moved items (loss check depends on it): Security (Credentials, Data protection, Access & auth, Network & headers, Security additions) · Backend & API · Infrastructure & Performance · Privacy & Legal · QA · Vibe-to-Product Refactor · Pre-flight.
Edits/additions (each a `- [ ]` item with one-line evidence hint):
- Core Web Vitals: `LCP, INP, and CLS` (was FID) `(verified: 2026-09)`; keep label "Core Web Vitals Audit".
- Threat model: assets, entry points, top 5 abuse cases → `docs/threat-model.md` before review phase.
- OWASP ASVS Level 1 self-check for every profile with login `(verified: 2026-09)`; OWASP Top 10 for LLM Applications — conditional block "if the product has an AI feature": prompt-injection defence, per-user AI usage limits, output validation before it reaches users `(verified: 2026-09)`.
- Supply chain: lockfile committed; `npm audit`/`pnpm audit`/`osv-scanner` clean; hallucinated-package check — every AI-added dependency exists on the registry, created >6 months ago, maintained repo; evidence `npm view <pkg> time.created`; versions pinned.
- Observability: OpenTelemetry traces + metrics + structured logs; trace id echoed in error responses; error pages reveal nothing `(verified: 2026-09)`.
- Load test: k6 against staging with p95 target from BRIEF §4 — conditional "if audience > 100 concurrent users" `(verified: 2026-09)`.
- SLOs: availability + p95 latency per critical endpoint; alert on burn.
- Backups: merge "Automated Backups" + "Backup Verification" (keep both labels verbatim) with RPO/RTO stated and one restore rehearsed.
- Webhook signature verification on every inbound webhook; idempotency: store event id before processing, 24 h replay window, success on duplicates (conditional block: inbound webhooks).
- Feature flags: kill switch for every risky feature; per-tenant if multi-tenant.
- Accessibility WCAG 2.2 AA (expands the original a11y item, keep its label): contrast 4.5:1, keyboard-only pass, focus not obscured (2.4.11), target size ≥24×24 CSS px (2.5.8), non-drag alternative (2.5.7), no redundant entry (3.3.7), accessible authentication (3.3.8), axe-core clean `(verified: 2026-09)`.
- Incident readiness: status page on separate host; post-mortem template.
- Account deletion + retention policy (Privacy).
- Conditional blocks (switched on by BRIEF §9): AI feature, payments (server-side prices, payment test, refund policy), inbound webhooks, i18n, load test.

### 2.5 `standards/web.md` (~60 lines) — landing, saas-web, internal-tool
Moved verbatim: Layout & Responsiveness (all 5); Components & Content minus profile-only ones; Forms & Validation (all); Frontend Additions PWA / lazy loading / bundle analysis / state management; SEO Metadata & Indexing; SEO Additions; Analysis & External Tools; cookie consent banner; Pre-flight DNS & Domain + Mixed Content Check. New: skip-to-content link; copyright year current.

### 2.6 `standards/landing.md` (~40 lines)
Moved: Conversion & CRO (Lead Magnet, CRO Tooling, Thank You Page, Referral Loop), Testimonials, Contact form, Social media buttons, Share button. **Polish — optional, do last** (downgraded, with condition): smooth scroll animations, hero animations, section transitions; custom cursor (only if brand guide asks); urgency/scarcity (only true, dated claims; fake ones removed); WhatsApp/chat floating button (local business or sales-led only); back-to-top (page longer than 3 screens). Pointer to `../landing-10-sections.md`. Anti-"made-by-AI" item: no gradient headline text, no default 3-icon-card row, no fake testimonials, no "it's not X, it's Y" copy.

### 2.7 `standards/saas-web.md` (~35 lines)
Moved: RLS, pagination, indexing (also listed here as saas-relevant), Backend additions reference, Session Management, Language selector/i18n (conditional), Payment Test, Email Delivery, Dark/Light mode toggle animation (polish). New: onboarding + activation metric tracked; sign-up / login / email verification / password recovery / account deletion; empty/loading/error/offline states; money-model conditional (server-side prices); query scoping to the authenticated user/tenant.

### 2.8 `standards/internal-tool.md` (~25 lines)
Moved: RLS, indexing, restricted logs access, prevention of sensitive field manipulation. New: SSO via existing IdP (never custom login for colleagues); confirmation + immutable audit log for expensive-to-undo actions; soft deletes; CSV export / scheduled report. Pre-answered N/A rows: SEO, CRO, cookie banner — reason "internal audience".

### 2.9 `standards/native-app.md` (~45 lines), `(verified: 2026-09)` on tooling lines
Expo SDK + EAS Build/Submit/Update with OTA rollback plan; store review readiness: iOS privacy manifest + Android data-safety form, in-app account deletion, demo account for reviewers; push via expo-notifications: permission asked in context, token rotation; deep links: universal/app links verified (AASA / assetlinks.json served), validate every callback parameter; offline: read-only cache vs write queue with conflict policy; secure storage Keychain/Keystore, no secrets in bundle, TLS only; crash reporting; app-size budget; device matrix tested. Moved: Interactive Feedback on mobile; dark mode with system preference detection (also stays in core if the loss-check mapping puts it there — one home per item; pick core).

### 2.10 `references/landing-10-sections.md` (~70 lines)
Global rules: sections may be omitted, omission recorded in BRIEF §10 with reason; exactly one primary action page-wide (= BRIEF §3); one `h2` per section. Per section: purpose (1 line) + **Check** (pass condition + how measured):
1. Hero — H1 states the outcome for the BRIEF audience in ≤12 words; single primary CTA = BRIEF §3 action, visible without scrolling at 375×667 and 1440×900 (Playwright `boundingBox().y + height < viewport.height`); no gradient headline text.
2. Social proof — ≥3 real, attributable logos/numbers, each traceable to a source file with source URL; zero placeholder names (`grep -riE 'lorem|acme|john doe'` → 0).
3. Problem — audience pain in their words (BRIEF §2), ≤3 bullets.
4. Solution — one sentence "we do X so you get Y"; links forward to Features.
5. Features — 3–6, each = benefit + how; not the default three-icon-card row unless the brand guide asks.
6. How it works — ≤3 steps, each starts with a verb.
7. Testimonials — name + role + company or photo, consent recorded in repo; none exist → omit, never fake.
8. Pricing — plans side by side, price visible without click, one CTA per plan, refund/return policy linked; lead-gen pages may omit with reason.
9. FAQ — ≥5 questions from real objections; `<details>` or ARIA accordion, keyboard-operable; "last updated" date.
10. Final CTA — repeats hero CTA text verbatim; sticky CTA on mobile; submission lands on a thank-you page with the next step.

### 2.11 `references/ux-laws.md` (~55 lines)
Header: "Source: general UX literature (Laws of UX); not derived from the project's extraction files." Each law = check + measurement, no definitions:
- Fitts — primary CTA hit area ≥44×44 CSS px; mobile sticky CTA in bottom third; destructive control ≥8 px from and styled unlike the primary. Measure: Playwright `boundingBox()`, axe `target-size`.
- Hick — ≤1 primary CTA per viewport; ≤7 top-level nav items; ≤4 pricing plans; one question per step on mobile forms. Measure: element counts.
- Jakob — logo top-left links home; login/account top-right; search top; conventional form patterns; no custom cursor unless brand demands. Measure: DOM position assertions.
- Miller — lists chunked ≤7 (features 3–6, steps ≤5); card/phone inputs grouped. Measure: child counts.
- Parkinson — every form field maps to a BRIEF requirement or is removed; multi-step forms show progress; `autocomplete` on every eligible input. Measure: field list vs requirements; eligible `input:not([autocomplete])` → 0.
- Proximity — label-to-input gap < field-to-field gap (≤8 px vs ≥16 px); plan and its CTA in one container. Measure: computed margins.
- Von Restorff — exactly one primary-styled element per viewport; alerts/destructive use a distinct style. Measure: primary-style count per viewport == 1.
When to run: landing always; any UI at review phase against staging.

### 2.12 `references/model-routing.md` (~45 lines, Claude-only, excluded from dist)
Table phase → executor → model → skills:
- handshake → main thread → whatever `/model` set → none.
- scavenge (stub) → `quick` (Sonnet) inventory, `planner` (Fable) assessment.
- mapping (stub) → `planner` (Fable) → `superpowers:brainstorming` + `brainstorming-extras`, `superpowers:writing-plans` + `writing-plans-extras`.
- execute (stub) → `builder` (Opus) via `superpowers:subagent-driven-development` + extras; `quick` for mechanical steps; `/ralph-loop` only for tasks with a mechanical verifier, always with `--max-iterations`.
- review (stub) → gstack `/review`, `/qa` + `gstack-extras`; `superpowers:verification-before-completion` + extras; second opinion `/codex` (OpenAI Codex) — review only, never authors.
- deploy (stub) → gstack `/ship`, `/land-and-deploy`, `/cso`.
Notes: `/model-route` (`~/.claude/commands/model-route.md`) only prints a haiku/sonnet/opus tier recommendation and does not know Fable — ignore it for v2p; main-thread model changes only via the user's `/model`; agent models fixed in `~/.claude/agents/{planner,builder,quick}.md`; a fork inherits the parent's model, so Fable reasoning = `planner`, never a fork. Load `*-extras` companions with their parent skills.

### 2.13 `README.md` (~70 lines, rewritten)
What it is · Two runtimes: Claude Code (symlink install command, `/v2p`) and portable (`dist/v2p-portable.md`) · Phases table with status (handshake available; five planned) · Profiles table · File map · Build: `sh build-portable.sh` · Verify: commands from §6 · Models: "Claude Code: see `skills/v2p/references/model-routing.md`. Portable: any strong reasoning model." Remove Claude 3.5 / GPT-4o, "150+" (state the measured count), PERSONA.md, "upload four files". Keep "Stop vibing. Start engineering." and the copyright line.

### 2.14 `build-portable.sh` (~20 lines)
Ordered parts: `skills/v2p/SKILL.md`, `phases/handshake.md`, `references/brief-template.md`, `references/standards/{core,web,landing,saas-web,internal-tool,native-app}.md`, `references/landing-10-sections.md`, `references/ux-laws.md`. Per part: strip frontmatter, drop `<!-- claude-only -->…<!-- /claude-only -->` blocks, drop copyright lines. Prepend `# v2p portable pack (generated <date>; do not edit)`; append copyright once; write `dist/v2p-portable.md`. Must run under both bash and zsh (`sh build-portable.sh`).

## 3. Handshake interview
Turns ≤3 questions; (S) skippable; (P) wording varies by profile.

Turn 0 — context
- Q0 (S if `$PWD` obviously has code or is empty) — New from zero or a change to existing code? Which directory? (`brownfield: yes` → later scavenge.)
- Q1 (S if given at entry) — What are we building, one paragraph? What breaks if it doesn't exist?
- Q2 — Who uses it, roughly how many and how often?

Turn 1 — classification
- Q3 — "This looks like <profile> because <signal>. Correct?" Two candidates → ask the one disambiguator.
- Q4 (P) — The one job. landing: the single visitor action (demo/trial/buy/join list). saas-web: the core weekly verb. internal-tool: view numbers, edit records or approve — any action expensive to undo? native-app: core loop; must it work offline?

Turn 2 — success and scope
- Q5 — (a) the one number that must move in 90 days; (b) day-1 acceptance, 3–7 lines `WHEN <trigger> THE SYSTEM SHALL <observable response>`. Reject "it works"/"looks right".
- Q6 — What is explicitly NOT in v1?

Turn 3 — brand and locale
- Q7 — Brand guide? `existing` (path/URL/file; record palette, type, voice, logo in BRIEF §6) / `new` (3 adjectives, 1–2 reference sites, must-avoid list — default = anti-"made-by-AI" traits in `standards/landing.md`; `brand: to-create`, created in a later phase) / `none needed` (internal-tool default: org UI kit).
- Q8 (S; default one language) — One language or several? Translated or per-market content?

Turn 4 — constraints and stack
- Q9 — deadline; monthly infra budget ceiling; data sensitivity (personal data, payments, health/financial, minors, public-sector/EU accessibility obligation); operator after launch (solo/team).
- Q10 — Stack must-have, won't-accept, existing accounts (hosting, domain, payments, Apple/Google developer). No preference → state profile default, record `defaulted`.
- Q11 (S; skip for landing and internal-tool) — Money model: free / flat / per-seat / usage / IAP.
- Q12 (S; default none) — Integrations: email, payments, calendar, Slack, external APIs, inbound webhooks. Any yes → webhook/idempotency block ON in BRIEF §9.

Gate — running brief + decisions log + markers; explicit confirmation; write BRIEF.md.

`references/brief-template.md`:
```
# BRIEF — <project name>
written: <YYYY-MM-DD> by v2p handshake · language: <xx>

## 1. Project
- Profile: <landing|saas-web|native-app|internal-tool> · secondary: <profile|none>
- Code: <greenfield | existing at <path>>
- Vision: <one paragraph>
- Breaks without it: <one line>

## 2. Audience and scale
- Who: <…> · How many / how often: <…>

## 3. The one job
- <primary action or core verb>; expensive-to-undo actions: <list|none>; offline: <yes|no|n/a>

## 4. Success criteria
- 90-day metric: <number + how measured>
- Day-1 acceptance:
  - WHEN <trigger> THE SYSTEM SHALL <observable response>

## 5. Non-goals (v1)
- <…>

## 6. Brand
- Status: <existing (source: <path/url>) | to-create | none>
- Palette / type / voice / logo: <… | pending brand phase>
- Adjectives: <…> · References: <…> · Must-avoid: <…>
- Locales: <one | list; translated | per-market>

## 7. Constraints
- Deadline: <…> · Budget/month: <…> · Data sensitivity: <flags|none> · Operator after launch: <solo|team>

## 8. Stack
- Must-have: <…> · Won't-accept: <…> · Existing accounts: <…>
- Money model: <…|none> · Integrations: <…|none>

## 9. Standards loaded
- references/standards/core.md + <web.md +> <profile>.md <+ landing-10-sections.md>
- Conditional blocks ON: <AI feature | payments | webhooks/idempotency | i18n | offline | load test | none>

## 10. Decisions log
| item | answered / defaulted / deferred | value |
|---|---|---|

## 11. Open markers
none  ← must be literally "none" for the file to be written

Next: /v2p mapping (not available in this version)
```

## 4. Profile → standards mapping
| Profile | Files loaded (in order) | Also |
|---|---|---|
| landing | core.md, web.md, landing.md | landing-10-sections.md, ux-laws.md |
| saas-web | core.md, web.md, saas-web.md | ux-laws.md at review |
| internal-tool | core.md, web.md, internal-tool.md | ux-laws.md at review |
| native-app | core.md, native-app.md | — |

Original-section → destination: Visuals & Interactions → hover / micro-interactions / skeletons / progress bar / tooltips / dark mode (system preference) → core; decorative rest → landing.md Polish (toggle animation → saas-web.md polish); Interactive Feedback → native-app.md. Layout → web.md. Components & Content → web.md except Testimonials / Social / WhatsApp / Contact form / Share → landing.md, i18n → saas-web.md conditional. Forms → web.md. Frontend Additions: a11y → core (expanded), PWA/lazy/bundle/state → web.md. Backend Data & Logic: RLS, indexing → saas-web.md + internal-tool.md; parameterized queries, server-side validation, pagination → core. Backend Additions → core. All Security → core. Infra & Performance → core. SEO → web.md except CRO → landing.md. Privacy & Legal → core (cookie banner → web.md). QA → core. Refactor → core. Pre-flight → core except DNS & Domain / Mixed Content → web.md, Payment Test / Email Delivery → saas-web.md.

## 5. Sources adapted
- the-architect (paraphrased via WebFetch summaries — do not quote verbatim): greenfield/brownfield gate, disambiguation pairs, shape-specific deep-dives, ≤3 questions/turn, skip-if-answered, relevance test, opinionated defaults, NEEDS CLARIFICATION markers, running brief, confirmation gate, language mirroring, EARS acceptance format, output to user cwd.
- ivanvibecodes-video-suggested-actions.md §2.2, 3.1, 3.2, 3.4, 4.3, 4.6, 4.7, 4.8, 5.1, 6.1.
- facebook-video-suggested-actions.md §1.2, 1.3, 2.2, 5.1, 5.2, 6.3.
- Not in either extraction file: UX laws, threat model, OTel, k6, SLO, RPO/RTO, WCAG specifics, Expo/EAS, brand guides → general knowledge.

## 6. Verification (run from project dir; each names expected output)
1. Frontmatter: first line of `skills/v2p/SKILL.md` is `---`; `grep -cE '^(name|description): ' skills/v2p/SKILL.md` → 2; `name: v2p`; description line < 1024 chars.
2. Every referenced path exists: `grep -ohE '(references|phases)/[A-Za-z0-9_./-]+\.md' skills/v2p/SKILL.md skills/v2p/phases/*.md skills/v2p/references/*.md | sort -u` → each `test -f skills/v2p/<p>` (resolve `standards/`-relative and `../` forms correctly) → no MISSING. Falsifier: fake path in a scratch copy → MISSING printed.
3. No item lost (BEFORE deleting root STANDARDS.md): extract the 141 `- [ ]` labels (text after `- [ ] `, strip `**`, cut at first `:` or `(`, trim) → each found case-insensitively in the concatenation of `skills/v2p/references/standards/*.md` → zero `LOST:`. Expect 141 lines in (maybe fewer unique). Falsifier (mandatory): delete one line from web.md in a scratch copy → exactly one `LOST:`.
4. Downgrades: `grep -ciE 'custom cursor|urgency|whatsapp|back-to-top' core.md` → 0; landing.md → ≥4; `grep -n 'FID' standards/*.md` → 0; `INP` in core.md ≥1.
5. Warnings not gates: `grep -rniE 'refuse any request|maximum 200 lines' skills/v2p` → 0.
6. Evidence alignment: `grep -rc '\[x\]' skills/v2p` → 0; `grep -c -i 'evidence' core.md` ≥3; `Checklist Alignment` absent from README.md, WORKFLOW.md, skills/.
7. `grep -rc '(verified: 2026-09)' skills/v2p/references` total ≥8.
8. `grep -rn 'PERSONA' README.md WORKFLOW.md skills/` → 0.
9. Portable build: `sh build-portable.sh`; in dist: `^(name|description): ` → 0; `claude-only` → 0; `AskUserQuestion` → 0; `Rafael Arciniegas` → 1; size < 80000 bytes; `^---$` in skills/ only as frontmatter fences. Rebuild to a temp path and diff → empty.
10. Symlink: `ln -s "$PWD/skills/v2p" ~/.claude/skills/v2p`; `readlink`; `git -C ~/.claude check-ignore -v skills/v2p` result reported.
11. Dry-run handshake (new session, empty scratch dir): "/v2p" then "A landing page for my dog-grooming studio in Bogotá. Brand guide is in brand.pdf. Goal: bookings." Expected: landing chosen with a stated signal; ≤3 questions/turn; Q1 and brand status not re-asked; Q11 skipped; explicit confirmation requested; `.v2p/BRIEF.md` written with §11 `none`, ≥1 `defaulted` row, §9 lists core/web/landing/landing-10-sections; second `/v2p` offers resume. Falsifier: a change request at the gate → no file written, gate re-asked.
12. Portable dry-run in ChatGPT/Gemini (user-run).

## 7. Known risks
- WebFetch paraphrase of the-architect: no verbatim attributions.
- Relative-path resolution through a symlinked skill dir and description length are assumptions exercised by checks 1, 10, 11.
- Gate accepts explicit yes/ok/confirmed; stricter than natural speech would fight the user.

***
Copyright © 2026 Rafael Arciniegas. Licensed under the MIT License.
