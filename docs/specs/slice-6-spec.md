# v2p SLICE 6 — implementation spec (`/v2p brand`: DESIGN.md, receipt, routing to design skills)

**Conclusion first.** Build 5 new files, edit 17. `brand` becomes a phase **between scavenge and mapping** (not between mapping and execute — reasons in §2.1): it writes `.v2p/DESIGN.md` in Google's DESIGN.md format (YAML frontmatter with normative tokens + the eight canonical sections) plus five v2p sections (Voice, Logo Rules, Imagery, Must-Avoid, Sources; Motion optional), sealed only by `scripts/finalize-brand.sh` → receipt `.v2p/.brand-pass`. Mapping requires that receipt and writes the tokens/UI tasks from DESIGN.md; execute refuses to start any task whose Files touch UI files unless the receipt still matches (`task-record.sh start`); review's `ux-laws` row runs gstack `/design-review` against DESIGN.md and `finalize-review.sh` re-checks the receipt. The finalize script runs the pinned linter **offline from the npx cache** (measured working today), fails on linter errors and on the four warnings that matter (`contrast-ratio`, `section-order`, `missing-primary`, `missing-typography`), and does its own checks the linter does not do (duplicate sections, required tokens, hex colors, Must-Avoid = BRIEF §6, Sources with guide checksum, no `---` rule outside the frontmatter fence). A root `DESIGN.md -> .v2p/DESIGN.md` symlink makes every design skill find the file with zero configuration (tidy-check prunes symlinks; gstack resolves them by design; impeccable uses `fs.existsSync`). Re-theme of an already-reviewed project = archive the finished cycle into `.v2p/cycles/<date>/`, re-run brand, then mapping in "cycle 2" mode writes a short PLAN from the DESIGN.md delta; execute and review run unchanged. No script gains a `--plan` parameter and nothing is ever edited under a hash lock.

Five things to hear before the builder starts (details in §7):
1. Ordering: brand must precede mapping, or the PLAN's tokens task cannot name files, fonts or hex values (PLAN is hash-locked at `finalize-plan.sh:103-105`; `mapping.md:57-58` require concrete Files and self-checking Verifiers). Your sketch said "between mapping and execute"; the spec puts it before mapping and explains why. The execute gate you asked for is still built.
2. The live project's brand is `existing (source: pending brand.pdf)`. A fourth state is unavoidable: **placeholder** DESIGN.md (the neutral tokens Task 4 already shipped), so that a pending guide never blocks mapping (handshake already says "don't block", `handshake.md:39`). Re-theme replaces it.
3. gstack `/design-consultation` writes root `DESIGN.md` and appends a section to `CLAUDE.md` itself. v2p uses it for the `to-create` proposal, then moves its output into `.v2p/DESIGN.draft.md`. That mv is the price of not re-implementing it (SKILL.md §1 rule).
4. Routing `/impeccable` into execute UI tasks means `PRODUCT.md` must exist, or impeccable stops to run `init` mid-task (impeccable SKILL.md:74). Brand runs `/impeccable init` once, answered from the BRIEF.
5. The linter does not catch duplicated sections (measured), missing `name` (measured) or `---` rules (measured). v2p's script does. Nothing in the receipt depends on the linter beyond `broken-ref` and `contrast-ratio`.

Everything marked **(measured)** was run by me on this machine on 2026-09-25; **(file)** cites a file read today; **(assumed)** is stated as such. Live-session behaviour of the routed skills is unverified by construction.

***

## 0. Verified facts vs assumptions

**Measured today**
- `npx --offline -y -p @google/design.md@0.4.0 designmd lint <f> --format json` runs from the npx cache (`~/.npm/_npx/453056feeae89689`, version 0.4.0) with no network. Only option: `--format json|text`.
- Exit code 1 iff an `error` finding exists (`broken-ref`). Warnings and infos exit 0.
- Not flagged at all: a duplicated `## Overview`, a missing `name:`, `version: 1.0`, a `---` rule in the body, an unknown top-level frontmatter key (`v2p:`), an unknown section (`## Must-Avoid`).
- Flagged as warning: `contrast-ratio` (only on a `components.<x>` that has both `backgroundColor` and `textColor`; refs are resolved, e.g. `{colors.primary}`), `section-order` (Colors before Overview), `orphaned-tokens` (a color no component references), `missing-typography`, `missing-primary`. Info: `token-summary`, `missing-sections` (rounded/spacing). Rule ids in the bundle: broken-ref, contrast-ratio, declared-omission, missing-primary, missing-sections, missing-typography, orphaned-tokens, redundant-omission, section-order, unknown-key, unknown-omission.
- Google's example `examples/paws-and-paths/DESIGN.md` uses **non-canonical headings** (`Brand & Style`, `Layout & Spacing`, `Buttons & Inputs`…) and lints clean → "lints 0/0" says nothing about section names. The v2p fixture must use the canonical eight (gstack's parser aliases `brand & style` → Overview, `~/.claude/skills/gstack/lib/design-md.ts:36-46`).
- ui-ux-pro-max `search.py … --design-system --json` runs (python3); for "dog grooming studio booking landing warm friendly" it returned a dark neumorphic palette (`background #000000`) → its output is a candidate, never the decision.
- Installed and enabled: superpowers 6.4.1, impeccable 4.1.3, ui-ux-pro-max 2.13.0, ponytail 4.9.0; gstack `design/dist/design` and `browse/dist/browse` binaries exist; `bun`, `markitdown`, `python3` on PATH; `aside` not on PATH.
- Live project found at `/Users/user/tmp/v2p-exec/.worktrees/v2p-execute-2026-09-24/` (not under `personal_skills/v2p` as slice-4 wrote): BRIEF §6 `Status: existing (source: pending brand.pdf)`, `Must-avoid: default AI traits (gradient text, fake testimonials, generic three-card rows)`; REVIEW.md finalized (commit `15ff1f3`); `src/app/globals.css` has `@theme inline` mapping `--color-accent/on-accent/background/foreground/muted/surface/line` to `:root` vars and `--font-sans: var(--font-geist-sans)`; PLAN Task 4 (line 477) and Task 12 (727) own `globals.css`; no `brand.pdf` present.
- tidy-check prunes symlinks (`tidy-check.sh:35`, `-type l`) and flags a regular root `DESIGN.md` as scattered (`tidy-check.sh:55`, `tidy-rules.md:39`). gstack's design-md tool resolves `DESIGN.md` through symlinks on purpose (`gstack-design-md.ts:15-19`). impeccable finds `DESIGN.md` at the project root via `fs.existsSync` (`context.mjs:45,846-850`), fallback dirs `.agents/context`, `docs` (`:47`), or `$IMPECCABLE_CONTEXT_DIR` (`:21`).

**Assumed**
- tidy-check does not flag a root `PRODUCT.md` (inferred from the case list at `tidy-check.sh:55`; verify with the fixture, §8 check 6).
- `/design-consultation` behaves as its SKILL.md says (writes `DESIGN.md` + `CLAUDE.md` section at Q-final; `proposal-and-preview.md:419-559`); the `$D` design binary needs API credits (unverified).
- `npx --offline` exists in the user's npm (measured here; other machines unverified).

***

## 1. File tree delta

```
vibe-to-product/
├── build-portable.sh                          # MOD: +phases/brand.md, +references/design-template.md (before phases/mapping.md)
├── README.md                                  # MOD: phases table (+brand), file map (+5), verify block (+3 lines)
├── docs/ROADMAP.md                            # MOD: open item "Brand-creation phase" → built; cycles note
├── docs/specs/slice-brand-spec.md             # NEW: this document
├── tests/
│   ├── fixtures/finalize-brand/BRIEF.md       # NEW (~55 lines): landing BRIEF with a §6 Must-avoid line
│   ├── fixtures/finalize-brand/DESIGN.md      # NEW (~120 lines): deliberately bad draft (paws-and-paths-like, canonical headings)
│   ├── test-finalize-brand.sh                 # NEW (~110 lines): fix-one-step → PASS, then one falsifier per check, sh and zsh
│   ├── fixture-execute.sh                     # MOD (+3): copies a good DESIGN.md + .brand-pass so Task 2 (tsx) can start
│   ├── test-execute.sh                        # MOD (+4): UI gate falsifiers (receipt removed → start 2 refuses; start 1 still ok)
│   ├── test-finalize-review.sh                # MOD (+6): brand receipt + ux-laws/DESIGN.md checks when PLAN names DESIGN.md
│   └── test-guard.sh                          # MOD (+6): DESIGN.md / .brand-pass block cases, finalize-brand allow, symlink case
└── skills/v2p/
    ├── SKILL.md                               # MOD: §2 argument list + Next resolution + model guard; §5 row; §6 refs/scripts
    ├── phases/
    │   ├── brand.md                           # NEW (~130 lines)
    │   ├── mapping.md                         # MOD (+14): DESIGN.md precondition; tokens/UI task rules; "Cycle 2+" block; Spec line
    │   ├── execute.md                         # MOD (+7): UI gate in preconditions/preflight; /impeccable + apple-design in the dispatch
    │   └── review.md                          # MOD (+4): ux-laws row against DESIGN.md; make-interfaces-feel-better; finalize check
    ├── references/
    │   ├── design-template.md                 # NEW (~120 lines) — portable; the DESIGN.md schema + required tokens
    │   ├── brief-template.md                  # MOD (+1): §6 wording "pending brand phase" → what brand fills / placeholder
    │   ├── plan-template.md                   # MOD (+2): Spec line adds .v2p/DESIGN.md; tokens-task verifier example
    │   ├── model-routing.md                   # MOD: +brand row; execute/review rows name impeccable, apple-design, make-interfaces-feel-better
    │   └── skills-catalog.md                  # MOD: "UI design system" row rewritten (VoltAgent rule replaced); brand row; markitdown row
    ├── scripts/
    │   ├── finalize-brand.sh                  # NEW (~120 lines)
    │   ├── archive-cycle.sh                   # NEW (~35 lines): git mv PLAN/EXECUTE/REVIEW/PLAN-AMENDMENTS + receipts → .v2p/cycles/<date>/
    │   ├── task-record.sh                     # MOD (+6): UI-files gate in `start`
    │   └── finalize-review.sh                 # MOD (+6): brand receipt + ux-laws run cell names DESIGN.md (when PLAN names it)
    └── hooks/guard-finals.sh                  # MOD (+3): DESIGN.md in both case lists and the regex; symlinked root DESIGN.md blocked
```

Conventions carried from slices 2–4: `***` not `---` in v2p files (the DESIGN.md frontmatter fence is the one documented exemption, §3.3 check 9); copyright line last; `(verified: 2026-09)` on the same line as a URL; `<!-- claude-only -->` blocks balanced (tests/test-build.sh checks it); POSIX sh, no `[[ ]]`, no arrays, never `case $f in $pat)`.

Not built (YAGNI): a `--plan` parameter on execute scripts; a separate `BRAND.md` prose file; `.impeccable/design.json` sidecar generation (impeccable's own concern; `CONTEXT_STALE` is reported, not acted on, impeccable SKILL.md:85); a v2p copy of any skill's palette/font logic; VoltAgent fetch automation.

***

## 2. Design answers

### 2.1 Where brand sits: after scavenge, before mapping
Order: `handshake → (adopt) → scavenge → brand → mapping → execute → review`.
- `PLAN.md` is hash-locked once (`finalize-plan.sh:103-105`) and never edited (`execute.md:13`). Mapping's task rules need concrete paths and self-checking verifiers (`mapping.md:57-58`): the tokens task must list the font files, the logo format, the hex values it greps for. Those exist only after DESIGN.md.
- The user's sentence "mapping plans the tokens/UI tasks from DESIGN.md" is satisfied only in this order. Putting brand after mapping would force a second plan write or a generic task, and a re-run of mapping for every project.
- Mapping need not re-run after brand in the normal flow. It re-runs only in the re-theme case, in "cycle 2" mode (§6).
- Brand preconditions: BRIEF required (§11 = `none`), SCAVENGE optional (same one-line question as `mapping.md:9`). For `Code: existing`, AUDIT receipt required (its "Brand signals" row feeds the `existing` path, `adopt.md:40,52`).
- Router "Next" resolution (`SKILL.md:27`) becomes: BRIEF and no SCAVENGE → `scavenge`; SCAVENGE and no `.v2p/DESIGN.md` → `brand`; DESIGN and no PLAN → `mapping`; …unchanged after that. Model guard list (`SKILL.md:18`) adds `brand`.

### 2.2 Four brand states from BRIEF §6 (`brief-template.md:29-33`)
| BRIEF §6 Status | Path | Direction source | Skills at the point of use |
|---|---|---|---|
| `existing (source: <path/url>)`, file readable | **Transcribe** | the guide | `markitdown` (ingest), `ui-ux-pro-max` (`--domain google-fonts` / `--domain typography` to verify faces and fallbacks), `make-interfaces-feel-better` + `apple-design` (Motion), `/impeccable init` |
| `existing (source: pending …)` or unreadable | **Placeholder** | none: neutral tokens, `description: PLACEHOLDER — …` | `ui-ux-pro-max --design-system --variance 2` for a neutral set; `/impeccable init`; everything else deferred |
| `to-create` | **Propose** | 3 adjectives + reference sites + must-avoid | `superpowers:brainstorming` + `brainstorming-extras`, `ui-ux-pro-max` (3 candidate systems), `/design-consultation` (research, proposal, preview, Q-final), `/design-shotgun` (optional mockups), `make-interfaces-feel-better` + `apple-design` (Motion), `/impeccable init` |
| `none` (internal-tool, org UI kit) | **Document the kit** | the organisation's kit or the stack default | `ui-ux-pro-max --design-system --density 8` (dashboard defaults) or the kit's tokens, `/impeccable init`; `/impeccable document` when kit code exists |
| any, after a finished cycle (re-theme) | **Re-theme** | new guide or new direction | `/impeccable document` (scan the incumbent tokens first), then the row above that matches |

### 2.3 Where DESIGN.md lives, and how skills find it
`.v2p/DESIGN.md` (user decision). `finalize-brand.sh` also creates `DESIGN.md -> .v2p/DESIGN.md` at the project root. Why a symlink and not configuration: gstack `check DESIGN.md` resolves symlinks by design (`gstack-design-md.ts:15-19`); `/design-review` and `/design-shotgun` `cat DESIGN.md` at the root (`design-review/SKILL.md:428-438`, `design-shotgun/SKILL.md:504`); impeccable's loader looks at the root and follows symlinks (`context.mjs:846-850`); tidy-check never sees symlinks (`tidy-check.sh:35`). drift-check allows `.v2p/*` always (`drift-check.sh:69`), and the symlink is created before execute, so no task's scope is affected. A skill that offers to *write* DESIGN.md (`/design-review` Phase 2 offer, `design-review/SKILL.md:1042`; `/impeccable document`) must be declined; a write through the symlink would break the receipt and be caught by `check-pass.sh` at the next phase, and the hook proposal blocks it (§3.9).

### 2.4 Linter policy and "unavailable"
- Pinned `@google/design.md@0.4.0`, `npx --offline` first, plain `npx` second (one network attempt). Neither yields JSON with a `findings` key → **FAIL**, not degraded. Reason: the cache is populated on this machine (measured); the two checks only the linter performs (`broken-ref`, `contrast-ratio`) are the ones review relies on; a degraded receipt would mean less than every other `.*-pass`, and nothing else in v2p has a degraded mode. The script's own checks still print on that run, so the user sees everything at once.
- FAIL on: any `error`; warnings `contrast-ratio`, `section-order`, `missing-primary`, `missing-typography`, `unknown-key`. NOTE (printed, allowed): `orphaned-tokens` (a palette ramp is used by CSS, not by `components`), `*-omission`, all infos. The extras skill's rule applies: the floor is the linter's 4.5:1 measurement, not a ban.

### 2.5 Required frontmatter (minimum set) — chosen so the linter's contrast check fires and mapping's verifier can grep
`name`, `description`; `colors.primary`, `colors.on-primary`, `colors.surface`, `colors.on-surface`; `typography.display.fontFamily`, `typography.body.fontFamily`; `rounded.md`; `spacing.md`; `components.button-primary.{backgroundColor,textColor}` = `{colors.primary}`/`{colors.on-primary}`; `components.page.{backgroundColor,textColor}` = `{colors.surface}`/`{colors.on-surface}`. Every `colors.*` value is 6-digit hex (measured: the tokens verifier in §3.4 greps hex literals; the impeccable reference recommends hex as the portable default, `document.md:46`). `version` is omitted (optional per spec; measured: the linter ignores it; the spec's only documented value is `alpha`). Two-space YAML indentation, one key per line (the template enforces it; the script parses by indentation).

### 2.6 Approval flow (Claude Code)
One `AskUserQuestion` per decision point, batched only when independent (`brainstorming-extras`): (1) direction choice among ≤3 candidates with `preview` = each candidate's token table + font sample line (the user compares concrete artefacts), (2) research yes/no + mockups yes/no (`/design-shotgun`) in one call, (3) the draft approval after showing the full draft and the preview page/mockup paths, (4) in re-theme: which incumbent tokens are kept. gstack skills fire their own decision briefs; v2p does not duplicate them.

### 2.7 Checkpoints
`.v2p/work/brand-guide.md` (markitdown output + sha256 line 1), `.v2p/work/brand-candidates.md` (ui-ux-pro-max `-f markdown` outputs, line 1 `written: … · brief: <BRIEF written date>`), `.v2p/work/brand-direction.md` (approved direction + rationale), `.v2p/work/brand-incumbent.md` (impeccable document output in re-theme). Reusable when line-1 `brief:` equals the BRIEF's `written:` date and, for candidates, the same day (same rule as `mapping.md:19`). `finalize-brand.sh` clears `.v2p/work/brand-*`.

***

## 3. Per-file spec

### 3.1 `references/design-template.md` (portable, ~120 lines)
Rule block above the template: frontmatter is normative; hex colors; required tokens (§2.5); the eight canonical sections in spec order, each exactly once; then the v2p sections in this order: `## Motion` (optional), `## Voice`, `## Logo Rules`, `## Imagery`, `## Must-Avoid`, `## Sources`; each exactly once; `Must-Avoid` first bullet is literally `- BRIEF §6: <the BRIEF's Must-avoid text>`; `Sources` bullets use only the kinds below; the frontmatter fence is the only `---` allowed; last line `Next: /v2p mapping`.

````
---
name: <project name>
description: <one line: mood, material, energy — or "PLACEHOLDER — neutral tokens until <guide> arrives">
colors:
  primary: "#RRGGBB"
  on-primary: "#RRGGBB"
  surface: "#RRGGBB"
  on-surface: "#RRGGBB"
  <more descriptive slugs; every value 6-digit hex>
typography:
  display:
    fontFamily: "<face>, <fallback>"
    fontWeight: 700
    fontSize: clamp(2rem, 5vw, 3.5rem)
    letterSpacing: -0.02em
  body:
    fontFamily: "<face>, <fallback>"
    fontSize: 1rem
    lineHeight: 1.5
rounded:
  sm: 4px
  md: 8px
  lg: 12px
spacing:
  sm: 8px
  md: 16px
  lg: 24px
components:
  button-primary:
    backgroundColor: "{colors.primary}"
    textColor: "{colors.on-primary}"
    rounded: "{rounded.md}"
  page:
    backgroundColor: "{colors.surface}"
    textColor: "{colors.on-surface}"
---

# <project name>

## Overview
Status: <final | placeholder> · brand case: <existing | to-create | none> · profile: <BRIEF §1>
Creative north star: <one sentence>. Mode per surface: <Persuade/Operate/Read/Experience per BRIEF §1 profile>.

## Colors
<strategy and roles; light/dark decision; which token signals action>

## Typography
<faces, roles, loading (next/font, self-hosted), scale rationale; overused-list exception if any>

## Layout
<max width, grid, breakpoints, density>

## Elevation & Depth
<shadow or tonal layering; "flat" is a valid answer>

## Shapes
<radius hierarchy; nested inner radius = outer − gap>

## Components
<button/input/card/nav states: hover, focus-visible, active, disabled>

## Do's and Don'ts
- Do: <3–5 checkable rules>
- Don't: <3–5 anti-patterns; include BRIEF §6 must-avoid items again in plain words>

## Motion
- Approach: <minimal-functional | intentional | expressive>; easing enter ease-out / exit ease-in / move ease-in-out; durations micro 50–100ms, short 150–250ms, medium 250–400ms
- Press: scale(0.96); never `transition: all`; `prefers-reduced-motion` → cross-fade only
- Springs (native-app or gesture UI): damping 1.0 / response 0.3–0.4 by default; bounce only after a flick

## Voice
- Adjectives: <BRIEF §6 adjectives> · register: <tú/usted, formal/informal> · locales: <BRIEF §6>
- Do say / don't say: <3 each>

## Logo Rules
- Files: <public/logo.svg …> · clear space: <n × mark height> · min size: <px> · on dark: <variant> · never: <stretch, recolor, effects>

## Imagery
- Style: <real photos of …; no stock clichés> · treatment: <…> · alt-text rule: <…>

## Must-Avoid
- BRIEF §6: <verbatim from BRIEF §6 Must-avoid, or "none">
- <brand-specific additions>

## Sources
- guide: <relative path> · sha256: <64 hex>        ← existing, local file
- guide: <url>                                       ← existing, URL
- reference: <url> · <what was taken: mood/structure only>
- inspired: VoltAgent/awesome-design-md/<path>@<commit sha> · mood/structure only, no tokens or fonts copied
- generated: ui-ux-pro-max 2.13.0 --design-system "<query>" · candidate <A|B|C> chosen
- kit: <org UI kit name/url>
- placeholder: brand guide pending (<name>)
- schema: google-labs-code/design.md spec, linted with @google/design.md 0.4.0

Next: /v2p mapping
````

### 3.2 `phases/brand.md` (~130 lines) — writes `.v2p/DESIGN.md`

**Purpose** (2 lines). Turn BRIEF §6 into `.v2p/DESIGN.md`: normative tokens plus the rules later phases check against. Nothing is built here; the design skills do the design work, v2p adds the checks and the receipt.

**Preconditions**
- `.v2p/BRIEF.md` with §11 `none`, else `Run /v2p handshake first.`
- SCAVENGE optional: ask once "Run scavenge first (recommended) or brand without it?"; note `scavenge: skipped` in DESIGN.md Overview. Claude-only: `check-pass.sh .v2p/SCAVENGE.md .v2p/.scavenge-pass` when present.
- BRIEF §1 `Code: existing` → AUDIT receipt (`check-pass.sh .v2p/AUDIT.md .v2p/.audit-pass`), else `Run /v2p adopt first.`
- Existing `.v2p/DESIGN.md` with receipt → offer resume (keep) / re-run. Existing `.v2p/REVIEW.md` with receipt → **re-theme mode** (§6): say so and run `archive-cycle.sh` only after the new DESIGN.md passes (so a failed brand run leaves the finished cycle intact).
- Checkpoints per §2.7. Model guard (router §2).
- Read `references/design-template.md` in full before the first question.

**Step 0 — Classify** (all cases). Print the case from BRIEF §6 Status (the four states of §2.2) and the profile. Portable and Claude Code alike: if `Status: existing (source: pending …)` and the file is not readable → `placeholder` path, and say "placeholder: re-run `/v2p brand` when <guide> exists; it re-themes."

**Step 1 — Product context for the design skills** (all cases, Claude Code). Run `/impeccable init`; answer its interview rounds from BRIEF §1–§8 (vision, audience, one job, constraints, stack) and say "taking X from the BRIEF"; it writes root `PRODUCT.md`. Why: impeccable's loader (`context.mjs`) needs PRODUCT.md, or every execute UI task that loads `/impeccable` stops to run init (impeccable SKILL.md:74). Portable: skip; write nothing.

**Step 2 — Per case**

*Existing (transcribe).*
1. Ingest: `markitdown <guide> > .v2p/work/brand-guide.md` (PDF/DOCX; catalog row "Doc ingestion"); line 1 `sha256: $(shasum -a 256 <guide> | cut -d' ' -f1)`. A URL: fetch, save the text, no checksum. Portable: ask the user to paste the guide's palette, type, voice and logo rules.
2. Extract into the template: colors (hex; convert Pantone/CMYK only when the guide gives no hex, and mark `derived` in the Colors prose), type roles, voice, logo rules, imagery, must-avoid.
3. Verify faces: `python3 "<plugin root>/.claude/skills/ui-ux-pro-max/scripts/search.py" "<face>" --domain google-fonts` and `--domain typography` for the pairing; load `ui-ux-pro-max-extras` in the same turn (it governs the contrast/token checks below). A face the guide names but Google Fonts lacks → `## Typography` records the licence/self-host decision.
4. Gaps the guide leaves (rounded, spacing, elevation, components): `search.py "<3 adjectives> <profile>" --domain style` and `--domain ux`; mark each filled section `derived` in its prose.
5. Motion: from `make-interfaces-feel-better` (§4–7, 12–15, 19: interruptible transitions, exits softer than enters, press scale 0.96, no `transition: all`, motion never the only feedback) and, when BRIEF §1 profile is `native-app` or BRIEF names sheets/drag/gestures, `apple-design` (springs damping 1.0 / response 0.3–0.4, velocity hand-off, reduced-motion cross-fade). Write `## Motion`; omit the section only when the guide forbids motion.
6. Go to Step 3.

*Placeholder.*
1. `search.py "<profile> neutral minimal" --design-system --variance 2 -f markdown > .v2p/work/brand-candidates.md`; take its neutral palette and a system font stack; `description: PLACEHOLDER — neutral tokens until <guide> arrives`; Overview `Status: placeholder`; Sources `- placeholder: brand guide pending (<name>)`; Voice/Logo/Imagery: one line each `pending <guide>`. Must-Avoid from BRIEF §6. Motion: the make-interfaces-feel-better defaults only. Go to Step 3.

*To-create (propose).*
1. Load `superpowers:brainstorming` + `brainstorming-extras` in the same turn. Say out loud: "bounded: one artefact, `.v2p/DESIGN.md`; the design is presented in chat and approved before writing; no spec file, no writing-plans (mapping is v2p's plan step)." Its "understanding the idea" step: confirm the three adjectives, reference sites and must-avoid from BRIEF §6 ("taking X from the BRIEF"); ask only what changes DESIGN.md content; independent unknowns in one `AskUserQuestion` (extras rule), dependent ones one at a time.
2. Candidates: three `search.py "<adjectives> <profile> <industry>" --design-system --variance <3|6|9> -f markdown` runs (never `--persist`: it writes `design-system/<slug>/MASTER.md` into the project), saved to `.v2p/work/brand-candidates.md`. Treat them as candidates: measured today, a "warm friendly dog grooming" query returned a black neumorphic palette.
3. Reference sites named in BRIEF §6 that match a brand in VoltAgent/awesome-design-md: fetch the raw file pinned to a commit sha (`https://raw.githubusercontent.com/VoltAgent/awesome-design-md/<sha>/<path>`), read it for mood and section structure only; never copy its tokens or fonts (names altered, fonts proprietary); never `npx getdesign`. Record `- inspired: …@<sha>` in Sources. Portable: same, by hand.
4. Run gstack `/design-consultation` (main thread; needs `AskUserQuestion`). Give it: the BRIEF, the candidates file, the must-avoid list, and "the design must serve BRIEF §3 (the one job)". Its Phase 1 takes product context from `PRODUCT.md` (Step 1) and asks the memorable-thing question; Phase 2 research runs in the browser when the user says yes (Aside absent here → its `$B` fallback, `design-consultation/SKILL.md:529-543`); Phase 3–5 propose the system, validate coherence, verify fonts, and render a preview page (HTML Path B; AI mockups when its design binary and credits work); Phase 6 asks Q-final and writes root `DESIGN.md` in the spec format plus a `## Design System` section in `CLAUDE.md` (`proposal-and-preview.md:419-559`). At Q-final: **A) Approve**. Then `mv DESIGN.md .v2p/DESIGN.draft.md` (root, regular file, written by the skill; in re-theme the root symlink was removed in Step 0). Keep the CLAUDE.md section (it points at the symlink finalize creates). Portable: do Phases 1–6 yourself from the template, no research tooling.
5. Optional, offered once together with the research question: `/design-shotgun` for the first screen (hero for landing, main view otherwise) when the user wants to see directions; it generates N variants through the same design binary, opens a comparison board, and saves `approved.json` under `~/.gstack/projects/<slug>/designs/` (`design-shotgun/SKILL.md:610-856`); the approved variant's feedback feeds design-consultation's proposal ("I'll follow DESIGN.md by default", `:519-521`). Skip when `DESIGN_NOT_AVAILABLE`.
6. Add the v2p sections (Motion as in the existing path; Voice from the adjectives; Logo Rules: `pending: no logo yet — mapping plans a wordmark task` when none exists; Imagery; Must-Avoid; Sources with `generated:` + `reference:` + `inspired:` lines). Go to Step 3.

*None (org UI kit).*
1. Kit tokens exist (a package, a Figma export, a CSS file): transcribe them (existing path steps 2–5, source `- kit: <name>`); code with the kit already in the repo → `/impeccable document` (scan mode extracts CSS custom properties, Tailwind theme, components into the spec format, `document.md:80-114`), then `mv DESIGN.md .v2p/DESIGN.draft.md`, decline its sidecar refresh offer.
2. No kit: `search.py "internal <domain> dashboard" --design-system --density 8 -f markdown` (dense scale), system font stack, `--domain ux "keyboard focus table"` for the Operate-mode rules; Overview `Mode per surface: Operate`. Go to Step 3.

**Step 3 — Show and approve.** Print the whole draft (or its path), the preview page / mockup paths, and a 6-line summary (primary/on-primary/surface/on-surface, display/body faces, motion approach). Claude Code: `AskUserQuestion` "Approve DESIGN.md (Recommended) / Change tokens / Change direction". Change → back to the step named, re-show. Write only on approve.

**Step 4 — Finalize.** Portable: write `.v2p/DESIGN.md` from the draft, then create the symlink `ln -sfn .v2p/DESIGN.md DESIGN.md`, say there is no receipt. Claude Code: `sh <skill>/scripts/finalize-brand.sh .v2p` until `PASS` (checks in §3.3). A refusal is a stop-and-ask with the script output verbatim; never hand-write `.v2p/DESIGN.md` or `.v2p/.brand-pass`. Re-theme: on PASS, `sh <skill>/scripts/archive-cycle.sh .v2p` (§6).

**Step 5 — Hand off.** Print the path, the counts from the PASS line, `Status: final|placeholder`, then `Next: /v2p mapping`.

**Claude Code note** (claude-only block): main thread runs `/design-consultation`, `/design-shotgun`, `/impeccable init|document` (they need `AskUserQuestion` and the browser); `quick` may run the three `search.py` calls and write `.v2p/work/brand-candidates.md`; `planner` never writes. Load `ui-ux-pro-max-extras` with `ui-ux-pro-max`, `brainstorming-extras` with `superpowers:brainstorming`, `gstack-extras` with any gstack skill. Decline every skill's offer to write or refresh `DESIGN.md`/sidecars after Step 3: `.v2p/DESIGN.md` is sealed by the script. Never `mcp__claude-in-chrome__*`; `/browse` for anything that needs a click.

### 3.3 `scripts/finalize-brand.sh` (~120 lines)
```
usage: sh finalize-brand.sh [.v2p]   exit 0 PASS · 1 FAIL
```
1. `draft=$d/DESIGN.draft.md` exists; `$d/BRIEF.md` exists; else FAIL and exit.
2. Frontmatter: line 1 is `---`; a closing `^---$` exists; `fm` = lines between. `name:` and `description:` present with non-empty values → else `FAIL: frontmatter missing name|description`.
3. Required tokens (§2.5) by indentation (awk: group at column 0, key at 2 spaces, prop at 4): each absent path → `FAIL: frontmatter missing <path>`. Component pairs must be the refs `{colors.primary}`/`{colors.on-primary}` and `{colors.surface}`/`{colors.on-surface}` → `FAIL: components.<c>.<prop> must be {colors.<x>}` (that pairing is what makes the linter's contrast check fire; measured).
4. Every line under `colors:` at 2-space indent matches `^  [a-z0-9-]+: "#[0-9a-fA-F]{6}"$` → else `FAIL: colors.<k> is not 6-digit hex (<v>)`.
5. Linter: `out=$(npx --offline -y -p @google/design.md@0.4.0 designmd lint "$draft" --format json 2>&1); rc=$?`; if `$out` lacks `"findings"` → retry without `--offline`; still lacking → `FAIL: designmd linter unavailable (npx cache has no @google/design.md@0.4.0 and no network): run 'npx -p @google/design.md@0.4.0 designmd --help' once online` (`fail=1`, continue). With JSON: awk over the findings blocks collecting `severity`, `rule`, `message`; `error` → `FAIL: lint error <rule>: <message>`; warning with rule in `contrast-ratio section-order missing-primary missing-typography unknown-key` → `FAIL: lint warning <rule>: <message>`; other warnings → `NOTE: lint <rule>: <message>`; `rc` non-zero with no error line → `FAIL: designmd exit <rc>` (belt for a future rule).
6. Sections: for each of `Overview Colors Typography Layout "Elevation & Depth" Shapes Components "Do's and Don'ts" Voice "Logo Rules" Imagery Must-Avoid Sources`: `grep -c "^## <name>$"` must be 1 → `FAIL: section '<name>' appears <n> times (want 1)`; `## Motion` count ≤ 1. Line of the first v2p heading > line of `## Do's and Don'ts` → else `FAIL: v2p sections (Motion, Voice, Logo Rules, Imagery, Must-Avoid, Sources) must follow the eight canonical sections`. (Order among the canonical eight is the linter's `section-order`, failed in step 5.)
7. Must-Avoid: `want=$(grep -m1 -o 'Must-avoid:.*' "$d/BRIEF.md" | sed 's/^Must-avoid: *//; s/ *$//')`; empty or `<…>` → `want=none`. `got` = first non-empty line after `^## Must-Avoid$`. `[ "$got" = "- BRIEF §6: $want" ]` → else `FAIL: Must-Avoid first bullet is '<got>' (want '- BRIEF §6: <want>')`. Byte comparison, no normalisation.
8. Sources: bullets after `^## Sources$` up to the next `^## ` or `^Next:`; count ≥ 1 → else `FAIL: Sources is empty`; each bullet must start with `- (guide|reference|inspired|generated|kit|placeholder|schema): ` → else `FAIL: Sources bullet kind unknown: <line>`; a `- guide: <path> · sha256: <hex>` with a non-URL path: file must exist at `<root>/<path>` and `shasum -a 256` must equal → `FAIL: Sources guide <path> missing|sha256 mismatch`.
9. `---` rules: every `^---$` line other than line 1 and the frontmatter close → `FAIL: '---' rule on lines <n…> (use ***)` (same message shape as `finalize-plan.sh:29`).
10. `grep -q '^Next: /v2p mapping$'` → else `FAIL: no 'Next: /v2p mapping' line`.
11. Root `DESIGN.md` exists and is a regular file (not a symlink) → `FAIL: root DESIGN.md is a regular file; move it aside (it will be a symlink to .v2p/DESIGN.md)`.
12. `fail` → `FAIL: DESIGN.md not written`, exit 1. Else `mv draft DESIGN.md`; `shasum -a 256 … > .brand-pass`; `ln -sfn .v2p/DESIGN.md "$root/DESIGN.md"`; `rm -f $d/work/brand-*`; print `PASS: <n> colors, <t> typography roles, <c> components, lint 0 errors / <w> warnings noted, status <final|placeholder> -> .v2p/DESIGN.md (+ DESIGN.md symlink)` where status comes from the Overview `Status:` line (`placeholder` if the description starts with `PLACEHOLDER`).

Header comment: `# ponytail: YAML read by indentation (2-space, one key per line — the template's rule), not a YAML parser; a flow-style frontmatter fails check 3 and says so.`

### 3.4 `scripts/archive-cycle.sh` (~35 lines) — re-theme support (§6)
`usage: sh archive-cycle.sh [.v2p]`: requires `check-pass.sh REVIEW.md .review-pass` OK and `check-pass.sh DESIGN.md .brand-pass` OK (a new brand must have passed first); `dest=$d/cycles/$(date +%Y-%m-%d)`; refuses if `dest` exists; `git mv` (or `mv` when untracked) `PLAN.md EXECUTE.md REVIEW.md PLAN-AMENDMENTS.md .plan-pass .execute-pass .review-pass` into it (each only if present); prints `archived: <dest> (<k> files); Next: /v2p mapping (cycle 2)`. Never touches BRIEF, SCAVENGE, AUDIT, DESIGN.

### 3.5 Edits to `phases/mapping.md`
- Preconditions: `.v2p/DESIGN.md` must have passed brand's finalize step. Portable: it ends with `Next: /v2p mapping`. Claude-only: `check-pass.sh .v2p/DESIGN.md .v2p/.brand-pass` → `OK`, else `Run /v2p brand first.` and stop. Placeholder status → print "DESIGN.md is a placeholder: the tokens task must keep a single swap point; re-theme later via /v2p brand".
- Step 3 planner prompt: add DESIGN.md to the inputs and `**Spec:** .v2p/BRIEF.md · .v2p/SCAVENGE.md · .v2p/DESIGN.md` in the header (plan-template line 13 edit). `finalize-plan.sh` gains no new check (the receipt check lives in mapping's precondition; review re-verifies it).
- Step 4 §5 tasks, new rule "Design tokens and UI": one **tokens task** early in the order: Files = the stylesheet or theme file the stack owns (Next.js + Tailwind v4: `src/app/globals.css`; native: the theme file) plus the font wiring file; Verifier (mechanical, self-checking, no backtick, no `&`): `sed -n '/^colors:/,/^[a-z]/p' .v2p/DESIGN.md | grep -oE '#[0-9a-fA-F]{6}' | sort -u | while read -r c; do grep -qi "$c" src/app/globals.css || exit 1; done` → exit 0, plus the display and body `fontFamily` first words grepped in the font wiring file. A **logo task** when Logo Rules names files that do not exist (or `pending`: a wordmark from `typography.display`). An **imagery task** when Imagery names assets. Every UI task's Steps line names `/impeccable` and, for `native-app`, `apple-design`. The Must-Avoid bullets become the landing `Anti-"made-by-AI"` row's verifier terms (`standards/landing.md:18`).
- §3 Skills rows (Claude Code): `impeccable | every UI task`, `make-interfaces-feel-better | the polish task and review`, `apple-design | native-app UI tasks`, `ui-ux-pro-max + extras | tokens task (stack query)`.
- New block **Cycle 2+ (after `archive-cycle.sh`)**: when `.v2p/cycles/*/REVIEW.md` exists and PLAN.md is absent: header `cycle: <n> · previous: .v2p/cycles/<dir>`; §2 Providers copied from the archived PLAN unless BRIEF §7/§8 changed (no re-asking); `## Architecture`, `## Threat Model`, §4b copied; §4 Standards = the archived REVIEW §3 verbatim, then rows the new tasks touch set back to `pending` with the evidence cell emptied (row count unchanged, so `finalize-plan.sh:15-16` still holds); §5 = only the tasks for the delta (re-theme: tokens, fonts, logo, imagery, copy/voice); planner instruction "scope: the DESIGN.md delta against `.v2p/work/brand-incumbent.md`; do not re-plan finished work".

### 3.6 Edits to `phases/execute.md` and `scripts/task-record.sh`
- Preconditions: "UI gate: a task whose Files include a UI file (`*.tsx *.jsx *.vue *.svelte *.css *.scss *.html *.swift *.kt *.dart tailwind.config.*`) starts only while `.v2p/DESIGN.md` matches its receipt. Portable: no DESIGN.md → stop before the first UI task and print `Run /v2p brand first.`" Claude-only: `task-record.sh start` enforces it.
- `task-record.sh start` (after `fresh`/resume handling, before `write_start`): compute the task's Files tokens (the same `bt`/`sed` extraction `write_start` already does for the `files:` line); `printf '%s\n' "$tokens" | grep -qE '\.(tsx|jsx|vue|svelte|css|scss|html|swift|kt|dart)$|(^|/)tailwind\.config\.'` and `sh "$S/check-pass.sh" "$d/DESIGN.md" "$d/.brand-pass" >/dev/null` fails → `ERROR: task <n> touches UI files (<first token>) and .v2p/DESIGN.md has no valid receipt: run /v2p brand` exit 2. Comment: `# ponytail: extension heuristic; a .ts styling file (vanilla-extract) passes — extend the list when it bites.`
- Step 2.2 dispatch, appended sentence for UI tasks: "Load `/impeccable` (it reads `PRODUCT.md` and `DESIGN.md` through its `context.mjs`; follow `craft-floor.md` before editing UI); `apple-design` when the BRIEF profile is `native-app`; tokens come from `.v2p/DESIGN.md` frontmatter, never invented." Step 2.7 task-reviewer prompt for UI tasks: "also run `make-interfaces-feel-better` in `quick` mode on the task's diff and report its table."
- Step 1 preflight: one line "if any task is a UI task, run the check above once now, so a stale DESIGN.md stops before Task 1."

### 3.7 Edits to `phases/review.md`, `references/review-template.md`, `scripts/finalize-review.sh`
- Step 1 table, `ux-laws` row "what runs": "`references/ux-laws.md` checks plus a visual design review of the running preview **against `.v2p/DESIGN.md` (frontmatter tokens are normative; a value in the token map is never a finding, a departure names the token)**". Claude-only invocation: "gstack `/design-review <preview URL>` + `gstack-extras` (pass the URL explicitly: on a feature branch with no URL it switches to diff-aware mode, `design-review/SKILL.md:973-979`; its Setup reads root `DESIGN.md` — the symlink — and runs `gstack-design-md.ts check/tokens`, `:428-438`; its detector's `design-system-*` rows compare the page with this repo's DESIGN.md, `:1123`); decline its Phase 2 offer to save a DESIGN.md (`:1042`); then `make-interfaces-feel-better` in `full` mode on the branch's UI diff. Both outputs go into `.v2p/work/review-ux-laws.md`; findings enter §2 as usual." No new `brand` row: it would be a second shape-only row; the receipt check below is the mechanical part.
- review-template.md rule line: "the ux-laws run cell names `DESIGN.md`".
- `finalize-review.sh`, after step 3: if `grep -q '\.v2p/DESIGN\.md' "$plan"` (the Spec line mapping now writes) then `check-pass.sh "$d/DESIGN.md" "$d/.brand-pass"` must be OK → else `FAIL: DESIGN.md does not match its receipt (run /v2p brand again or restore it)`; and the ux-laws row's run cell must contain `DESIGN.md` → else `FAIL: §1 ux-laws run cell does not name DESIGN.md`. Plans without the Spec mention (pre-brand projects like the live one) skip both: backward compatible, and the PLAN is hash-locked so the mention cannot be removed to dodge the check.

### 3.8 `SKILL.md`, `model-routing.md`, `skills-catalog.md`, `brief-template.md`, `build-portable.sh`, README, ROADMAP
- **SKILL.md**: §2 argument list adds `brand`; model guard list adds `brand`; Next resolution per §2.1; §5 row `| brand | phases/brand.md | .v2p/DESIGN.md (+ root DESIGN.md symlink) | available |`; §6 "DESIGN layout: `references/design-template.md` (brand)"; claude-only scripts list adds `finalize-brand.sh`, `archive-cycle.sh`; description sentence "+ writes the brand's DESIGN.md before planning". The `---` source rule line gains "(the DESIGN.md frontmatter fence is the one exception)".
- **model-routing.md**: row `brand | main thread (design skills need AskUserQuestion and the browser); quick may run the ui-ux-pro-max searches into .v2p/work/brand-candidates.md; planner never | per skill; Sonnet | /impeccable init (+document in re-theme), ui-ux-pro-max + ui-ux-pro-max-extras, superpowers:brainstorming + brainstorming-extras (to-create), /design-consultation, /design-shotgun (optional), make-interfaces-feel-better + apple-design (Motion), gstack-extras`. execute row skills: `+ /impeccable on UI tasks; apple-design for native-app; make-interfaces-feel-better (quick) in the UI task review`. review row: `/design-review against DESIGN.md + make-interfaces-feel-better (full)`.
- **skills-catalog.md** "UI design system" row (line 10) rewritten: default `impeccable` (execute UI tasks; `init` at brand; `document` at re-theme); `ui-ux-pro-max + extras` (brand candidates and stack queries; never `--persist`); `/design-consultation` (to-create proposal, writes root DESIGN.md + CLAUDE.md section, v2p moves it into the draft); `/design-shotgun` (optional mockups; artefacts under `~/.gstack`); **VoltAgent/awesome-design-md (MIT, 117.8k★, content last changed 2026-06-08)**: "reference only, when a BRIEF §6 reference site matches a listed brand: fetch the raw file at a pinned commit sha for mood/structure; never copy tokens or fonts (names altered, fonts proprietary); never `npx getdesign` (unpinned, telemetry)"; SpaceZephyr/brand-design-md rejected (no licence, one-day repo, wraps unpinned npx); Google `google-labs-code/design.md` (Apache-2.0, 28.1k★, pushed 2026-09-14): the schema and linter, pinned `@google/design.md@0.4.0` via `npx --offline` (`(verified: 2026-09)` https://github.com/google-labs-code/design.md). "Image generation (brand phase, later slice)" row: banana-claude stays `cached-disabled`; logo/imagery generation is not routed in this slice. Doc ingestion row: markitdown now cited by `phases/brand.md`.
- **brief-template.md** §6 line 31: `- Palette / type / voice / logo: <… | pending brand phase (brand writes .v2p/DESIGN.md; "existing (source: pending …)" yields a placeholder DESIGN.md until the guide arrives)>`.
- **plan-template.md**: Spec line `.v2p/BRIEF.md · .v2p/SCAVENGE.md · .v2p/DESIGN.md`; a one-line tokens-task verifier example (the `sed … while read` shape from §3.5).
- **build-portable.sh** line 11: insert `phases/brand.md references/design-template.md` before `phases/mapping.md`. The template's fenced block contains `---` lines: they are inside a code fence, not v2p rules; `build-portable.sh:20-21` strips frontmatter only when line 1 of a source file is `---`, which no v2p file is.
- **README.md**: phases table +brand; file map +5; verify block +3 lines (§8 checks 1, 3, 10).
- **docs/ROADMAP.md**: open item → "Slice 6: brand (built <date>)"; note `.v2p/cycles/` as the post-review iteration mechanism.

### 3.9 `hooks/guard-finals.sh` (+3 lines)
Add `DESIGN.md` to both `case` lists (`:18`) and to the regex alternation (`:23`: `(SCAVENGE|AUDIT|PLAN|EXECUTE|REVIEW|PLAN-AMENDMENTS|DESIGN)`); `.v2p/.brand-pass` is already covered by `.*-pass`. New case for a symlinked root file: `*/DESIGN.md|DESIGN.md) [ -L "$f" ] && { echo "v2p: $f is a symlink to .v2p/DESIGN.md, written only by finalize-brand.sh (a design skill's offer to write DESIGN.md must be declined)." >&2; exit 2; } ;;` placed after the `.v2p/` cases. Still not installed (user's decision, `:12`).

***

## 4. What each routed skill actually does (from its file)

| Skill | What it does (file) | Where v2p uses it |
|---|---|---|
| `ui-ux-pro-max` 2.13.0 | A local searchable database (79 styles, 192 palettes, 74 font pairings, 119 UX rules, 22 stacks) queried with `search.py "<terms>" --design-system|--domain <d>|--stack <s>`; `--design-system` returns pattern, style, colors, typography, effects, anti-patterns; dials `--variance/--motion/--density`; `--persist` writes `design-system/<slug>/MASTER.md` into the project (SKILL.md:39-131). Sibling sub-skills `brand` and `design-system` (claudekit) are token/brand-guideline tooling around `docs/brand-guidelines.md` — not used (they define a second source of truth). | brand: candidates, font verification, kit/none defaults; mapping: stack query for the tokens task |
| `ui-ux-pro-max-extras` | Two rules for turning a UI decision into a check: a control must remove the cause and be seen to fail; a threshold is a measured floor, not a ban on a family (SKILL.md:18-93). | brand (finalize's lint policy), mapping (tokens verifier), review |
| `impeccable` 4.1.3 | Design-director skill with a context loader (`context.mjs` reads PRODUCT.md, DESIGN.md, surface briefs), commands `init` (PRODUCT.md), `document` (DESIGN.md from code, spec format + `.impeccable/design.json` sidecar), `extract`, `critique`, `audit`, `polish`, `shape`, `live`…; craft floor loaded before editing UI; bounded verification passes (SKILL.md:12-85; document.md:1-62,251-255). Missing PRODUCT.md routes new work through `init` (:74). | brand: `init` (all cases), `document` (re-theme, kit code); execute: every UI task |
| `make-interfaces-feel-better` | 19 polish principles (concentric radius, optical alignment, shadows vs borders, interruptible transitions, stagger 100ms, exits softer, icon animation values, font smoothing, tabular nums, `text-wrap`, image outlines, press scale 0.96, no `transition: all`, `will-change` sparingly, 44/40px hit areas, icon stroke to text weight, currentColor icons, motion restraint) plus a review mode (`quick` cap 5 / `full` cap 15) with a fixed findings table and verdict (SKILL.md:25-188). | brand: Motion defaults; execute: UI task review (`quick`); review: `full` on the UI diff |
| `apple-design` | Apple's fluid-interface rules translated to the web: pointer-down response, 1:1 tracking, interruptibility, springs (damping/response values), velocity hand-off, momentum projection function, rubber-banding, materials, reduced-motion/transparency/contrast media queries, size-specific tracking/leading, the eight design principles (SKILL.md:20-283). | brand: Motion section for native-app or gesture UI; execute: native-app UI tasks |
| `superpowers:brainstorming` 6.4.1 | Classifies a request (spike / bounded / architectural) out loud, gathers intent, one question per message, 2–3 approaches with a recommendation, hard approval gate before any implementation; architectural path writes a spec and hands to writing-plans (SKILL.md:14-189). | brand `to-create`: the direction dialogue, bounded path, approval before the draft |
| `brainstorming-extras` | Amends "one question per message": batch independent blocking unknowns in one structured-question call; split at any dependency (SKILL.md:18-45). | with brainstorming |
| gstack `/design-consultation` | Checks for an existing DESIGN.md (update/fresh/cancel, format check with `gstack-design-md.ts`), gathers product context (PRODUCT.md, README, office-hours), optional competitive research in a browser (Aside, else `$B` headless), memorable-thing question, taste profile, then (sections file) proposal, coherence validation, font verification, preview page or AI mockups, Q-final, writes root `DESIGN.md` in the Google spec format with `# gstack: design-md-format=spec` marker and Motion/Decisions Log sections, and appends a `## Design System` section to `CLAUDE.md` (SKILL.md:429-837; proposal-and-preview.md:419-559). | brand `to-create` (and `existing` when the guide is logo-only) |
| gstack `/design-shotgun` | Generates N visual variants through the gstack design binary (`$D generate|variants|compare|evolve`), enforces anti-convergence, opens a comparison board with feedback JSON, confirms the understanding, writes `approved.json` and updates a taste profile under `~/.gstack`; follows DESIGN.md by default (SKILL.md:396-899). | brand `to-create`, optional, first screen |
| gstack `/design-review` 2.0 | Live-site designer's QA: reads root DESIGN.md (format + flat token map; tokens are never findings), extracts the rendered design system, audits pages against an ~80-item checklist and the DOM detector (with `design-system-*` rows against this repo's DESIGN.md), then fixes findings in source with atomic commits and before/after screenshots; offers to save an inferred DESIGN.md (SKILL.md:409-1930). | review `ux-laws` row |
| `gstack-extras` | Amendments for browse/scrape/qa/review/design-review: pattern anchoring, positive controls, and (Section 5) measuring a rendered property above any resize step; "zero found" needs a planted control (SKILL.md:179-216). | with every gstack skill |

***

## 5. Tests

**`tests/fixtures/finalize-brand/BRIEF.md`**: landing BRIEF (copy of `tests/fixtures/finalize-plan/BRIEF.md` if it has a §6 `Must-avoid:` line; otherwise the same with `- Adjectives: warm, precise, local · References: none · Must-avoid: gradient text, fake testimonials, three-icon-card rows`).

**`tests/fixtures/finalize-brand/DESIGN.md`**: paws-and-paths-like content (invented pet brand, canonical headings, Plus Jakarta Sans, orange/blue) made bad on purpose: `colors.on-primary: "#eeeeee"` on `primary: "#f2f2f2"` (contrast), `components.button-primary.textColor: "{colors.on-primari}"` (broken ref), `## Colors` twice, no `## Voice`, Must-Avoid first bullet `- BRIEF §6: gradient text` (wrong), `## Sources` empty, a `---` rule between Layout and Elevation, `colors.surface: oklch(98% 0.01 80)`, no `components.page`, no `Next:` line.

**`tests/test-finalize-brand.sh`** (style of `test-finalize-plan.sh`: copy to `${TMPDIR:-/tmp}/v2p-fb-test.<pid>`, `for SH in sh zsh`, source files hashed before/after; exit 2 "did not run" when the fixture is missing **or when `npx --offline … designmd lint --help` does not run**, printed as `ERROR: designmd 0.4.0 not in the npx cache; run it once online`):
0. Original → exit 1; output has: `lint error broken-ref`, `lint warning contrast-ratio`, `section 'Colors' appears 2 times`, `section 'Voice' appears 0 times`, `Must-Avoid first bullet`, `Sources is empty`, `'---' rule on lines`, `colors.surface is not 6-digit hex`, `frontmatter missing components.page`, `no 'Next: /v2p mapping'`; no `DESIGN.md`, no `.brand-pass` written.
1–10. Fix one at a time (sed/awk insertions as `ins`/`rep` in the plan test) and assert the matching FAIL disappears and the FAIL count drops by exactly one each time; final → exit 0, `PASS: <n> colors, 2 typography roles, 2 components, lint 0 errors`, draft gone, `.brand-pass` = `shasum` of `DESIGN.md`, `DESIGN.md` symlink at the fixture root points to `.v2p/DESIGN.md`, `.v2p/work/brand-x.md` removed.
11. Falsifiers on the good file (each replaces one line and expects the named FAIL, exit 1, no write): duplicate `## Motion`; `## Overview` moved after `## Colors` → `lint warning section-order`; `- BRIEF §6: gradient text, fake testimonials, three-icon-card rows ` (trailing space) → Must-Avoid FAIL (byte equality); BRIEF without a `Must-avoid:` value and DESIGN `- BRIEF §6: none` → PASS; `- guide: brand.pdf · sha256: <wrong>` with a real `brand.pdf` in the fixture → `sha256 mismatch`; correct sha → PASS; `- guide: brand.pdf …` with no file → `missing`; `- mood: x` → `Sources bullet kind unknown`; `## Voice` placed before `## Do's and Don'ts` → "must follow the eight canonical sections"; a color `unused: "#123456"` → PASS with `NOTE: lint orphaned-tokens`; a regular file `DESIGN.md` at the root → `root DESIGN.md is a regular file`; `PATH=/usr/bin:/bin sh finalize-brand.sh` (no npx) → `designmd linter unavailable`, exit 1, and the script's own FAIL lines still present when one is planted; `description: PLACEHOLDER — …` → PASS line says `status placeholder`.
12. `check-pass.sh` after `echo x >> .v2p/DESIGN.md` → `changed after finalize`.
13. `archive-cycle.sh` on a fixture with REVIEW.md + `.review-pass` + DESIGN receipt → files moved into `.v2p/cycles/<date>/`, `check-pass.sh .v2p/cycles/<date>/PLAN.md .v2p/cycles/<date>/.plan-pass` still `OK`; second run → refuses (dest exists); without `.brand-pass` → refuses.

**`tests/fixture-execute.sh`** +3 lines: copy the *good* DESIGN.md (the test's step-10 result is not available to the fixture — keep a second file `tests/fixtures/finalize-brand/DESIGN.good.md` that `finalize-brand.sh` passes; the brand test asserts that too) to `.v2p/DESIGN.md` and write `.brand-pass` with `shasum` (same bytes the script writes), before the commit. **`tests/test-execute.sh`** +4: after step 7, `rm .v2p/.brand-pass; task-record.sh start 2` → exit 2, `touches UI files (app/[locale]/page.tsx)`; `start 1` (only `.sh` files) → exit 0; restore the receipt → `start 2` exit 0. **`tests/test-finalize-review.sh`** +6: a PLAN copy whose Spec line names `.v2p/DESIGN.md` (re-seal `.plan-pass` in the test), no `.brand-pass` → `DESIGN.md does not match its receipt`; receipt present but ux-laws run cell `/design-review` only → `ux-laws run cell does not name DESIGN.md`; cell `/design-review http://localhost:3101 against DESIGN.md` → PASS. **`tests/test-guard.sh`** +6: `W 2 Write "$P/.v2p/DESIGN.md"`, `W 2 Edit .v2p/.brand-pass`, `B "mv DESIGN.md .v2p/DESIGN.md"`, `B "echo x > .v2p/.brand-pass"`, `A "sh $S/finalize-brand.sh .v2p"`, `W 0 Write "$P/.v2p/DESIGN.draft.md"`, and with a real temp symlink `ln -s .v2p/DESIGN.md $tmp/DESIGN.md`: `W 2 Write "$tmp/DESIGN.md"`, and a regular `$tmp2/DESIGN.md`: `W 0 Write "$tmp2/DESIGN.md"`.

***

## 6. Re-theme flow (the live case)

State: REVIEW finalized on branch `v2p/execute-2026-09-24` (worktree `/Users/user/tmp/v2p-exec/.worktrees/v2p-execute-2026-09-24`), BRIEF §6 `existing (source: pending brand.pdf)`, placeholder tokens in `src/app/globals.css` (`:root` vars mapped through `@theme inline`, Geist via `next/font`), placeholder icon/manifest (BRIEF §10 Brand row).

Options weighed: (a) a PLAN amendment — `PLAN-AMENDMENTS.md` is scope grants written by `task-record.sh allow` only (`execute.md:56`), not tasks; (b) a mini-plan `PLAN-BRAND.md` with a `--plan` argument in `task-record.sh`, `drift-check.sh`, `finalize-execute.sh`, `finalize-review.sh` — four scripts, every receipt path parameterised; (c) overwrite PLAN.md by re-running mapping — loses the record that cycle 1 happened, and its receipts point at a vanished plan; (d) **archive the finished cycle and run a short second cycle with the existing machinery** (recommended): `archive-cycle.sh` moves `PLAN.md, EXECUTE.md, REVIEW.md, PLAN-AMENDMENTS.md` + their receipts into `.v2p/cycles/2026-09-25/` (hashes still verify there); the router then offers `mapping` (PLAN absent); mapping's "Cycle 2+" block (§3.5) copies providers, architecture, threat model and the standards table from the archived REVIEW §3 and plans only the delta; execute and review run unchanged on a new branch; nothing is edited under any hash lock. (e) doing it outside v2p with `/impeccable` + `/design-review` — no receipts; rejected.

Steps for the live project once `brand.pdf` exists (checked into the repo root or `docs/brand/brand.pdf`): `/v2p brand` on the reviewed branch → re-theme mode: `rm DESIGN.md` if a symlink exists (none today); `/impeccable document` scan → `.v2p/work/brand-incumbent.md` (the placeholder tokens, kept for the "which tokens survive" question); existing path: `markitdown brand.pdf`, transcribe, verify faces, Motion; `AskUserQuestion` approve; `finalize-brand.sh` → `.v2p/DESIGN.md`, `.brand-pass`, root symlink; `archive-cycle.sh`; `Next: /v2p mapping`.

Cycle-2 PLAN tasks (what mapping should produce; Files must exist or be created, `mapping.md:58`):
1. **Tokens**: Modify `src/app/globals.css` (replace the `:root` and dark values with DESIGN.md colors; keep the `@theme inline` names), `src/app/[locale]/layout.tsx` (fonts via `next/font`, `--font-sans`), `tests/e2e/shell.spec.ts` — Verifier: the hex-grep loop from §3.5 + `for w in "<display first word>" "<body first word>"; do grep -q "$w" src/app/[locale]/layout.tsx || exit 1; done` + `npm run build`.
2. **Logo**: Create `public/logo.svg` (from the guide), Modify `src/app/icon.png`, `src/app/apple-icon.png`, `src/app/manifest.ts`, `src/components/Header.tsx` — Verifier: `test -s public/logo.svg && grep -q 'logo.svg' src/components/Header.tsx` + build.
3. **Imagery**: Create `public/images/*` per DESIGN.md Imagery; Modify `src/sections/*.tsx` — Verifier: `! grep -rqiE 'placeholder|lorem' src/sections` + e2e.
4. **Voice/copy**: Modify `src/i18n/es.json`, `src/i18n/en.json` per `## Voice` (stop-slop) — Verifier: the landing anti-traits greps (`standards/landing.md:18`) + manual.
Then `/v2p execute` (new branch `v2p/execute-<date>` from the reviewed head; UI gate passes because the receipt is fresh) and `/v2p review` (`/design-review` against the new DESIGN.md; §3 from the archived REVIEW with the four tasks' rows re-earned).

***

## 7. Open questions for the user (each changes the design; recommended option first)

1. **Order.** (a) `scavenge → brand → mapping` **(Recommended: the PLAN can name files, fonts and hex values; one plan write; no re-run)**; (b) `mapping → brand → execute` as first sketched: the tokens task stays generic and mapping must re-run to name anything, or `finalize-plan.sh` learns a second pass.
2. **Placeholder DESIGN.md when the guide is pending.** (a) Allowed, marked `Status: placeholder`, re-theme later **(Recommended: matches `handshake.md:39` "don't block" and what the live run did)**; (b) `pending` blocks mapping until the guide exists; (c) execute allows placeholder but review refuses to finalize on one (forces the re-theme before review).
3. **Root `DESIGN.md` symlink created by `finalize-brand.sh`.** (a) Yes **(Recommended: every routed skill finds the file with no per-invocation path; tidy ignores symlinks; the guard blocks writes through it)**; (b) no symlink; every skill invocation carries the path (`gstack-design-md.ts check .v2p/DESIGN.md`, `IMPECCABLE_CONTEXT_DIR=.v2p`) — prose routing that weaker models skip, the lesson this slice is meant to avoid.
4. **`/impeccable init` writing `PRODUCT.md` at brand time.** (a) Yes, answered from the BRIEF **(Recommended: without it, `/impeccable` on an execute UI task stops to interview)**; (b) do not route `/impeccable` into execute; keep it for `document` at re-theme only.
5. **Linter unavailable → FAIL.** (a) FAIL **(Recommended: the cache is populated here; a degraded receipt would be the only weak receipt in v2p)**; (b) `PASS (degraded: no linter)` with the status written into the PASS line and the receipt.
6. **Re-theme mechanism.** (a) archive the cycle + short cycle-2 plan **(Recommended: zero script parameters; history preserved; generalises to any post-review iteration)**; (b) `PLAN-BRAND.md` mini-plan with `--plan` in four scripts.

***

## 8. Verification plan for the builder (expected output; falsifier per structural check)

1. Router: `grep -cE '^\| `brand` \| `phases/brand\.md` \| .*\| available' skills/v2p/SKILL.md` → 1; `grep -c 'not available in this version' skills/v2p/SKILL.md` → 2 (unchanged). Falsifier: `available`→`planned` in a scratch copy → 0.
2. Referenced paths over `phases/brand.md`, `references/design-template.md` (`scripts/[a-z-]+\.sh`, `references/…`) → no `MISSING` (slice-1 check 2). Falsifier: reference `scripts/nope.sh` in scratch → one `MISSING`.
3. `sh tests/test-finalize-brand.sh | tail -1` → `test-finalize-brand: 0 failures`; `sh tests/test-execute.sh`, `test-finalize-review.sh`, `test-guard.sh`, `test-finalize-plan.sh`, `test-tidy.sh`, `test-build.sh` → 0 failures each.
4. Lint policy against the linter itself (fresh scratch files, not the fixture): a `{colors.nope}` ref → `FAIL: lint error broken-ref`; `#eeeeee` on `#ffffff` in `components.page` → `FAIL: lint warning contrast-ratio`; Colors before Overview → `section-order`; unused color → `NOTE: lint orphaned-tokens` and PASS otherwise. Falsifier for the parser: rename `"rule"` to `"rulx"` in a captured JSON fed through the awk → every lint FAIL disappears (proves the awk reads the field, not the exit code alone).
5. Syntax: `for s in skills/v2p/scripts/*.sh skills/v2p/hooks/*.sh tests/*.sh; do sh -n "$s" && zsh -n "$s"; done` → no output; zsh-safety grep (slice-4 check 4) → only the pre-existing `finalize-scavenge.sh` line.
6. Tidy: on the execute fixture after `finalize-brand.sh` (symlink present) and `/impeccable init`'s `PRODUCT.md` (create an empty one in the fixture), `sh skills/v2p/scripts/tidy-check.sh --tsv | grep -c 'DESIGN.md\|PRODUCT.md'` → 0. Falsifier: replace the symlink with a regular `DESIGN.md` → 1 (`scattered … merge:docs/ARCHITECTURE.md`).
7. Skill reachability (this machine): `bun --no-env-file run ~/.claude/skills/gstack/bin/gstack-design-md.ts check DESIGN.md` in the fixture root → `DESIGN_MD_FORMAT: spec`; `node <impeccable>/scripts/context.mjs` from the fixture root prints the DESIGN.md content (reads through the symlink). Falsifier: `rm DESIGN.md` → `missing` / `WORLD_DISCOVERY_REQUIRED`.
8. Hook offline falsifiers (test-guard) for `.v2p/DESIGN.md` → 2, `.v2p/DESIGN.draft.md` → 0, symlinked root `DESIGN.md` → 2, regular root `DESIGN.md` → 0.
9. Portable build: `sh build-portable.sh`; `grep -c '<!-- source: phases/brand.md -->' dist/v2p-portable.md` → 1; `grep -c 'design-template' dist/…` ≥ 1; `grep -c 'AskUserQuestion\|claude-only\|finalize-brand\|search.py\|subagent_type' dist/…` → 0; copyright count 1. Falsifier: unbalance one marker in a scratch copy → test-build FAIL.
10. README verify lines: `grep -c '| [a]vailable |' README.md` → 7; `grep -c 'brand' skills/v2p/references/model-routing.md` ≥ 2; `grep -c 'awesome-design-md' skills/v2p/references/skills-catalog.md` → 1 and `grep -c 'drop one DESIGN.md' …` → 0.
11. Live test (user, fresh session, on a **copy** of the live worktree, never the real one; `brand.pdf` provided or a stand-in PDF): `/v2p brand` → probe, re-theme mode announced, `/impeccable document` output in `.v2p/work/brand-incumbent.md`, `markitdown` line with the sha, one approval question, `finalize-brand.sh … PASS`, root symlink, `archive-cycle.sh … archived`, `Next: /v2p mapping`. Falsifiers: `echo x >> .v2p/DESIGN.md` then `/v2p mapping` → `Run /v2p brand first.`; remove `.brand-pass` before `task-record.sh start` of a tsx task → the UI-gate error; `/design-review` invoked without a URL → it enters diff-aware mode (why review.md passes the URL).

***

## 9. Risks, pushback, unverified

- **`/design-consultation` writes outside `.v2p/`** (root DESIGN.md, CLAUDE.md section). The mv step and the symlink absorb it; if the user prefers no CLAUDE.md edit, brand.md can `git checkout -- CLAUDE.md` after Q-final (one line; not the default).
- **Design binary credits/keys (unverified)**: `$D generate` may fail with auth or rate limits; both gstack skills degrade to an HTML preview / inline concepts by their own text. v2p depends on neither.
- **Aside absent on this machine**: design-consultation's research falls back to WebSearch + `$B` headless (its own §"Browser fallback"). Unverified live.
- **ui-ux-pro-max candidates can be off-brief** (measured). The phase text says candidates, never decisions; the approval question is the gate.
- **The UI-files heuristic** in `task-record.sh` misses `.ts` styling files; documented `ponytail:` ceiling.
- **Must-Avoid byte equality** is strict on purpose: a BRIEF re-run that rewords the list invalidates nothing mechanically (BRIEF has no receipt), but the next `finalize-brand.sh` run catches the drift; mapping's checkpoint rule already ties checkpoints to the BRIEF date (`mapping.md:19`).
- **`orphaned-tokens` allowed** means an unused palette entry passes; the tokens verifier greps every DESIGN.md color in the stylesheet, so an unused token at least exists in CSS.
- **Cycle-2 mapping** is a new prose rule for the planner; `finalize-plan.sh` keeps its row-count check (copying REVIEW §3 keeps the count) — verify on the fixture that a REVIEW §3 copied into PLAN §4 passes the `rows()` parser (both use the same `| item | file | status | evidence |` shape, `finalize-review.sh:14,46`).
- **Hook proposal**: three names added; still uninstalled; subagent hook firing still unverified (slice-3).
- **Not run end-to-end**: no script prototyped this session; the linter behaviours the script depends on were measured (§0); the shell shapes copy `finalize-plan.sh`/`finalize-review.sh`.

**Relevant absolute paths.** Repo: `/Users/user/SynologyDrive/code/ai/claude/Projects/personal_skills/vibe-to-product/` — `skills/v2p/SKILL.md`, `skills/v2p/phases/{handshake,mapping,execute,review}.md`, `skills/v2p/references/{brief-template,plan-template,review-template,skills-catalog,model-routing,tidy-rules}.md`, `skills/v2p/scripts/{finalize-plan,finalize-review,check-pass,task-record,drift-check,tidy-check}.sh`, `skills/v2p/hooks/guard-finals.sh`, `build-portable.sh`, `tests/{test-finalize-plan,test-guard,test-build,fixture-execute}.sh`, `docs/specs/slice-4-spec.md`, `docs/ROADMAP.md`, `README.md`. Live project: `/Users/user/tmp/v2p-exec/.worktrees/v2p-execute-2026-09-24/{.v2p/BRIEF.md,.v2p/PLAN.md,.v2p/REVIEW.md,src/app/globals.css}`. Skills: `/Users/user/.claude/plugins/cache/ui-ux-pro-max-skill/ui-ux-pro-max/2.13.0/.claude/skills/ui-ux-pro-max/{SKILL.md,scripts/search.py}`, `/Users/user/.claude/plugins/cache/impeccable/impeccable/4.1.3/skills/impeccable/{SKILL.md,reference/document.md,reference/init.md,scripts/context.mjs}`, `/Users/user/.claude/plugins/cache/claude-plugins-official/superpowers/6.4.1/skills/brainstorming/SKILL.md`, `/Users/user/.claude/skills/{ui-ux-pro-max-extras,brainstorming-extras,make-interfaces-feel-better,apple-design,design-consultation,design-shotgun,design-review,gstack-extras}/SKILL.md`, `/Users/user/.claude/skills/design-consultation/sections/proposal-and-preview.md`, `/Users/user/.claude/skills/gstack/bin/gstack-design-md.ts`, `/Users/user/.claude/skills/gstack/lib/design-md.ts`. Linter cache: `/Users/user/.npm/_npx/453056feeae89689/node_modules/@google/design.md/` (0.4.0).

***
Copyright © 2026 Rafael Arciniegas. Licensed under the MIT License.
## 10. User decisions (2026-09-25)

- Q1 order: **scavenge → brand → mapping** (a).
- Q2 pending guide: **placeholder DESIGN.md allowed**, re-theme later (a).
- Q3 root symlink: **yes** (a).
- Q4 `/impeccable init` at brand time: **yes** (a), defaulted as recommended, not asked.
- Q5 linter unavailable: **FAIL** (a), defaulted as recommended, not asked.
- Q6 re-theme: **archive cycle + short cycle-2 plan** (a).
- Design skills to route (user, 2026-09-25): /ui-ux-pro-max (+extras), /impeccable, /superpowers:brainstorming (+brainstorming-extras), /make-interfaces-feel-better, /apple-design; plus gstack /design-consultation, /design-shotgun, /design-review.
