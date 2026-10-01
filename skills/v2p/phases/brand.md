# v2p phase: brand

## Purpose
Turn BRIEF §6 into `.v2p/DESIGN.md`: normative tokens plus the rules later phases check against. It runs after scavenge and before mapping, so the plan's tokens task can name files, fonts and hex values.
Nothing is built here. The design skills do the design work; v2p adds the checks and the receipt.

## Preconditions
- `.v2p/BRIEF.md` required, with §11 = `none`. Otherwise print `Run /v2p handshake first.` and stop.
- `.v2p/SCAVENGE.md` optional: if absent, ask once "Run scavenge first (recommended) or brand without it?"; branding without it → `scavenge: skipped` on the DESIGN.md Overview `Status:` line.
<!-- claude-only -->
  When present, `sh <this skill's dir>/scripts/check-pass.sh .v2p/SCAVENGE.md .v2p/.scavenge-pass` must print `OK`.
<!-- /claude-only -->
- BRIEF §1 `Code: existing …` → `.v2p/AUDIT.md` must have passed adopt's finalize step (its "Brand signals" row feeds the existing path). Otherwise print `Run /v2p adopt first.` and stop.
<!-- claude-only -->
  In Claude Code: `sh <this skill's dir>/scripts/check-pass.sh .v2p/AUDIT.md .v2p/.audit-pass` must print `OK`.
<!-- /claude-only -->
- Existing `.v2p/DESIGN.md` → offer resume (keep) or re-run.
- Existing `.v2p/REVIEW.md` that passed review → **re-theme mode**: say so. The finished cycle is archived only after the new DESIGN.md passes (Step 4), so a failed brand run leaves it intact.
- Checkpoints: `.v2p/work/brand-guide.md` (the ingested guide, line 1 `sha256: <hex>`), `.v2p/work/brand-candidates.md` (line 1 `written: <YYYY-MM-DDTHH:MM> · phase: brand · part: candidates · brief: <BRIEF written date>`), `.v2p/work/brand-direction.md` (approved direction + rationale), `.v2p/work/brand-incumbent.md` (re-theme: the tokens in use now). A checkpoint is reusable when its `brief:` equals the BRIEF's `written:` date and, for candidates, it was written today; otherwise overwrite it, never read it. The finalize step clears `.v2p/work/brand-*`.
- Model guard (router §2).
- Read `references/design-template.md` in full before the first question.

## Step 0 — Classify
Print the case and the BRIEF §1 profile. The case comes from BRIEF §6 `Status:`:

| BRIEF §6 Status | Case | Direction source |
|---|---|---|
| `existing (source: <path/url>)`, readable | **existing** (transcribe) | the guide; a logo-only guide → **to-create** with the logo as a fixed constraint |
| `existing (source: pending …)`, or unreadable | **placeholder** | none: neutral tokens; say "placeholder: re-run `/v2p brand` when <guide> exists; it re-themes." In re-theme mode the placeholder is the incumbent tokens as shipped (no candidates, no direction question): it records them and the reviewed cycle stays current. |
| `to-create` | **to-create** (propose) | the three adjectives, reference sites and must-avoid of BRIEF §6 |
| `none` (internal tool, org UI kit) | **none** (document the kit) | the organisation's kit, or the stack default |
| any, in re-theme mode | **re-theme** | first record the tokens in use now, then the row above that matches |

Re-theme: a root `DESIGN.md` that is a symlink to `.v2p/DESIGN.md` is removed first (`rm DESIGN.md`, the link only), so no skill writes through it.

## Step 1 — Draft per case
Portable: follow the case below by hand; the user pastes what a tool would have produced (the guide's palette, type, voice and logo rules; candidate palettes). Take BRIEF answers as given and say "taking X from the BRIEF".
- **existing**: transcribe the guide into the template: colors (hex; convert Pantone/CMYK only when the guide gives no hex and mark it `derived` in the Colors prose), type roles, voice, logo rules, imagery, must-avoid. A transcription is not re-opinionated: no taste or reference-site skill runs. Gaps the guide leaves (rounded, spacing, elevation, components) are filled and marked `derived`. Sources: `guide:` (a local file with its sha256) and one `font:` line per face. In adopt mode (BRIEF §1 `Code: existing …`) the guide is often the project's own root `DESIGN.md`: transcribe it, never move or edit it (its guards may read it).
- **placeholder**: a neutral palette and a system font stack; `description: PLACEHOLDER — neutral tokens until <guide> arrives`; Overview `Status: placeholder`; Sources `- placeholder: brand guide pending (<name>)`; Voice, Logo Rules and Imagery one line each `pending <guide>`. Must-Avoid from BRIEF §6. Motion: the defaults in the template only.
- **to-create**: confirm the adjectives, reference sites and must-avoid from BRIEF §6; ask only what changes DESIGN.md content. Present up to three candidate directions (token table + a font sample line each), the user picks one, then write the full draft. Reference sites give mood and structure only: no token, font or mark is copied. Logo Rules: `pending: no logo yet — mapping plans a wordmark task` when none exists.
- **none**: transcribe the kit's tokens (source `- kit: <name>`), or, with no kit, a dense scale and a system font stack; Overview `Mode per surface: Operate`.
- **re-theme**: write the incumbent tokens (the ones the code uses now) to `.v2p/work/brand-incumbent.md`, then run the matching case; ask which incumbent tokens are kept.

Every case: Must-Avoid first bullet `- BRIEF §6: <verbatim>`; Motion from the template's defaults (springs only for `native-app` or gesture UI); no skill draws a vector logo, so Logo Rules transcribe the guide or record a decision.
<!-- claude-only -->

### Skill routing (Claude Code)
Every Bash command an impeccable script runs gets the prefix `IMPECCABLE_NO_UPDATE_CHECK=1 IMPECCABLE_NO_TELEMETRY=1` (it contacts impeccable.style otherwise). `ui-ux-pro-max` = `python3 "<plugin root>/.claude/skills/ui-ux-pro-max/scripts/search.py"`, loaded with `ui-ux-pro-max-extras`; never `--persist` (it writes `design-system/<slug>/MASTER.md` into the project). Its output is a candidate, never the decision (measured: a "warm friendly dog grooming" query returned a black neumorphic palette).

| Case | Skills, in order | Never |
|---|---|---|
| existing (readable) | `markitdown <guide> > .v2p/work/brand-guide.md` (line 1 `sha256: $(shasum -a 256 <guide> \| cut -d' ' -f1)`; a URL: fetch and save the text) → write the draft from `references/design-template.md` → `search.py "<face>" --domain google-fonts` (faces and fallbacks only) → Motion: `make-interfaces-feel-better` defaults; `apple-design` only when the BRIEF profile is `native-app` or names gestures → `/impeccable init` | taste skills, stitch, awesome-design-md (a transcription is not re-opinionated) |
| placeholder | re-theme mode: none (the incumbent tokens are the placeholder) → `/impeccable init`; otherwise `search.py "<profile> neutral minimal" --design-system --variance 2 -f markdown > .v2p/work/brand-candidates.md` → `/impeccable init` | everything else (deferred to the re-theme) |
| to-create | `superpowers:brainstorming` + `brainstorming-extras` (bounded: one artefact, `.v2p/DESIGN.md`; approval in chat before writing; no spec file, no writing-plans) → three `search.py "<adjectives> <profile> <industry>" --design-system --variance <3\|6\|9> -f markdown` runs into `.v2p/work/brand-candidates.md` → gstack `/design-consultation` + `gstack-extras` (give it the BRIEF, the candidates, the must-avoid list and "the design must serve BRIEF §3"; at Q-final choose Approve; then `mv DESIGN.md .v2p/DESIGN.draft.md` and remove the `## Design System` section it appended to `CLAUDE.md`, nothing else) → optional, only on the user's yes: `/design-shotgun` for the first screen when gstack reports `DESIGN_READY` (needs its OpenAI key); `banana-claude` for `## Imagery` only when the plugin is enabled and has its key (it asks its own approval per call) → Motion as in existing → `/impeccable init` | `npx getdesign`; copying a reference site's tokens or fonts |
| none (org kit) | kit tokens, else `search.py "internal <domain> dashboard" --design-system --density 8 -f markdown` and `--domain ux "keyboard focus table"` → `/impeccable document` when kit code exists (copy its output into the template; decline its sidecar refresh) → `/impeccable init` | writing through the root symlink |
| re-theme | `/impeccable document` (scan mode) → move its root `DESIGN.md` to `.v2p/work/brand-incumbent.md` → the matching row above → Step 4 archives the cycle | editing the archived PLAN/EXECUTE/REVIEW |

`/impeccable init` answers its interview from BRIEF §1–§8 (vision, audience, one job, constraints, stack) and writes root `PRODUCT.md`: without it, every execute UI task that loads `/impeccable` stops to run init.
<!-- /claude-only -->

## Step 2 — Questions
One question per decision point; independent ones together:
1. Direction (to-create, re-theme): up to three candidates, each shown as its token table and a font sample line.
2. Extras (to-create), one multi-select: competitive research? mockups of the first screen? generated imagery? Offer mockups only when gstack reports `DESIGN_READY`, and imagery only when `banana-claude` is enabled with its key; otherwise leave the option out (user decision 2026-09-25: no paid image tools for now; previews are HTML, images come from the user).
3. Re-theme: which incumbent tokens are kept.
<!-- claude-only -->
Claude Code: `AskUserQuestion`; question 1 with `preview` = each candidate's token table + font line; question 2 with `multiSelect: true`. gstack skills ask their own decision briefs; do not duplicate them.
<!-- /claude-only -->

## Step 3 — Show and approve
Write the draft to `.v2p/DESIGN.draft.md`. Print it (or its path), the preview page or mockup paths, and a six-line summary: primary / on-primary / surface / on-surface, display and body faces, motion approach. Ask "Approve DESIGN.md (Recommended) / Change tokens / Change direction". A change → back to the step named, then show again. Nothing is final before approval.

## Step 4 — Finalize
Portable: rename the draft to `.v2p/DESIGN.md`, create the root link (`ln -sfn .v2p/DESIGN.md DESIGN.md`; not when BRIEF §1 says `Code: existing …` and root `DESIGN.md` is a regular file: that is the project's own, kept as is) and say there is no receipt.
<!-- claude-only -->
Claude Code: `sh <this skill's dir>/scripts/finalize-brand.sh .v2p` until it prints `PASS`. It checks the frontmatter (name, description, the required tokens and the component pairs), quoted 6-digit hex colors, the pinned linter `@google/design.md@0.4.0` run offline from the npx cache (any error, or a `contrast-ratio`, `section-order`, `missing-primary`, `missing-typography` or `unknown-key` warning, fails; a missing linter fails too), each section once and the v2p ones after Do's and Don'ts, Must-Avoid = BRIEF §6 byte for byte, the Sources kinds (a local guide's sha256), no `---` rule outside the fence, the `Next:` line, and no regular root `DESIGN.md` unless BRIEF §1 says `Code: existing …`. It renames the draft, writes the receipt `.v2p/.brand-pass`, links root `DESIGN.md -> .v2p/DESIGN.md` (design skills read the root file) unless that root file is the project's own (adopt: kept byte for byte, PASS line `root DESIGN.md: project-owned, kept`), and clears `.v2p/work/brand-*`. A refusal is a stop-and-ask with the output verbatim; never hand-write `.v2p/DESIGN.md` or `.v2p/.brand-pass`.
Re-theme: on PASS, `sh <this skill's dir>/scripts/archive-cycle.sh .v2p` moves PLAN, EXECUTE, REVIEW, PLAN-AMENDMENTS and their receipts into `.v2p/cycles/<date>/`; mapping then writes the cycle-2 plan. A placeholder DESIGN.md is not archived over: the script prints `kept: …` and the reviewed cycle stays current (`Next: /v2p deploy`).
<!-- /claude-only -->

## Step 5 — Hand off
Print the path, the counts from the PASS line (or the token counts), `Status: final|placeholder`, then `Next: /v2p mapping` (a placeholder over a reviewed cycle: `Next: /v2p deploy`, and the draft's Next line says so).

<!-- claude-only -->
## Claude Code note
- Main thread runs `/design-consultation`, `/design-shotgun` and `/impeccable init|document` (they need `AskUserQuestion` and the browser); `quick` may run the `search.py` calls and write `.v2p/work/brand-candidates.md`; `planner` never writes.
- Load `ui-ux-pro-max-extras` with `ui-ux-pro-max`, `brainstorming-extras` with `superpowers:brainstorming`, `gstack-extras` with any gstack skill.
- After Step 3, decline every skill's offer to write or refresh `DESIGN.md` or a sidecar: `.v2p/DESIGN.md` is sealed by the script, and a write through the root symlink breaks its receipt (the guard hook blocks it).
- Never `mcp__claude-in-chrome__*`; `/browse` for anything that needs a click.
<!-- /claude-only -->

***
Copyright © 2026 Rafael Arciniegas. Licensed under the MIT License.
