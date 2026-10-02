# Portable pack test kit (slice-1 check 12)

A user-run test of `dist/v2p-portable.md` in ChatGPT or Gemini: no Claude Code, no scripts, no receipts. It checks that another model can follow the pack phase by phase and that every phase hands off to the next one. Run it once per runtime; fill one results table per run.

Two parts. **Part A** is chat only (handshake → scavenge → brand → mapping, about 30 minutes). **Part B** is optional and needs a local folder you run commands in (execute → review). Deploy is out of scope.

***

## 0. Setup
1. Use a fresh chat with the strongest model available (ChatGPT: a GPT-5-class reasoning model; Gemini: 2.5 Pro or later). The pack's model guard should refuse a mini/flash/lite tier: if you have one handy, try it first and record whether it refuses (check A0).
2. **Upload** `dist/v2p-portable.md` as a file; do not paste it. It is about 250 KB (about 60k tokens), which is over most paste limits.
3. Record the pack's line 1 (`generated <date>`) and the repo commit in the results table.
4. First message, verbatim:

   > This file is a skill pack called v2p. Follow it exactly as written, phase by phase. You cannot run scripts or write files: print every file you would write in one code block. Start: `/v2p`. The folder is empty: no code, no `.v2p/BRIEF.md`.

***

## Part A: chat only

### A1. Handshake
After the model asks "What are we building?", send:

> A one-page site for Harbor Street Bike Repair, a single-location bike shop. Cyclists book a tune-up slot online. If it doesn't exist we lose bookings to the chain store across town. No brand guide yet.

Answer the questions it asks with these (answer only what it asks; never volunteer the rest):

| topic | answer |
|---|---|
| users | local cyclists, ~300 visits a month, mostly on phones |
| profile check | yes, landing |
| the one job | book a tune-up slot |
| 90-day number | 40 online bookings a month |
| acceptance | WHEN a visitor submits the booking form with a free slot THE SYSTEM SHALL confirm on screen and email the shop within 1 minute |
| not in v1 | payments, accounts, a parts shop |
| brand | new: adjectives "sturdy, friendly, precise"; reference sites: none; must-avoid: take your default |
| language | one, English |
| deadline / budget / data | 3 weeks; $25/month; name and email only; operated solo; business and audience in the US |
| stack | no preference |
| integrations | email notification to the shop only |

At the confirmation gate, first send a change request ("Change the budget to $30"), then "confirmed".

| # | check | pass when |
|---|---|---|
| A0 | model guard (optional) | a mini/flash tier replies only "This phase needs a larger model…" |
| A1.1 | entry | it asks "What are we building? One paragraph." (empty folder, no BRIEF) |
| A1.2 | ≤ 3 questions per turn | never more than 3 in one message |
| A1.3 | no re-asking | it does not ask again what the opening paragraph said (what, why, brand status); it says "taking X from what you said" |
| A1.4 | profile | proposes `landing` and names the signal |
| A1.5 | Q11 skipped | it never asks about the money model (landing) |
| A1.6 | running brief | ≤ 10 lines after each turn |
| A1.7 | gate | shows the brief plus a decisions log with one row per Q0–Q12 (answered / defaulted / deferred / skipped / inferred) |
| A1.8 | change request | after "Change the budget to $30" it shows the gate again and writes **nothing** |
| A1.9 | BRIEF | after "confirmed": one code block; §9 lists core.md, web.md, landing.md and landing-10-sections; email webhook/idempotency block decided; §11 is literally `none`; at least one `defaulted` row (stack) |
| A1.10 | hand-off | ends with `Next: /v2p scavenge` |

### A2. Scavenge
Send `/v2p scavenge`.

| # | check | pass when |
|---|---|---|
| A2.1 | one pass | does steps 1–4 itself without asking you to run tools |
| A2.2 | sources | every claim carries a URL; numbers are not invented (a model without browsing must say it could not search, not make URLs up) |
| A2.3 | output | SCAVENGE in one code block, ending `Next: /v2p brand` |

### A3. Brand
Send `/v2p brand`. When it asks for candidate palettes or what a tool would produce, paste:

> Palette: primary #1F4E79, on-primary #FFFFFF, surface #F7F5F0, on-surface #1B1B1B, error #B3261E, on-error #FFFFFF. Display face: Archivo. Body face: Inter. Motion: minimal, 150–200 ms ease-out.

| # | check | pass when |
|---|---|---|
| A3.1 | case | classifies the brand as `to-create` from the BRIEF and says "taking X from the BRIEF" |
| A3.2 | inspiration | with no reference sites in the BRIEF, it suggests Dribbble, Awwwards, Behance and Pinterest |
| A3.3 | approval | shows an 8-line summary including **error / on-error**, then asks Approve / Change tokens / Change direction |
| A3.4 | DESIGN.md | after "Approve": frontmatter with `colors.error`, `colors.on-error` and `components.alert-error`; no `---` rules in the body (only the frontmatter fence); the root `DESIGN.md` link step mentioned; says there is no receipt |
| A3.5 | hand-off | ends with `Next: /v2p mapping` |

### A4. Mapping
Send `/v2p mapping`.

| # | check | pass when |
|---|---|---|
| A4.1 | precondition | accepts the DESIGN.md because it ends with `Next: /v2p mapping` |
| A4.2 | no brainstorm | writes the plan itself from the template, BRIEF as the spec; §3 is `none` |
| A4.3 | §4 standards | one row per checklist item of the loaded files (landing: 193), statuses `pending` or `N/A <reason citing BRIEF §>` |
| A4.4 | §4b | one row per landing section, an omitted section's reason in its own row |
| A4.5 | tasks | each task has `**Files:**` with full paths and a `**Verifier:**` with backticked `` `cmd` → expected `` pairs; one early tokens task |
| A4.6 | §6 | an `Order:` line naming every task number once |
| A4.7 | hand-off | ends with `Next: /v2p execute` |

Part A passes when every row passes or has a stated reason (e.g. no browsing for A2.2).

***

## Part B (optional): execute and review
Needs an empty local folder with git, and the BRIEF, DESIGN and PLAN code blocks from Part A saved as `.v2p/BRIEF.md`, `.v2p/DESIGN.md`, `.v2p/PLAN.md`. Send `/v2p execute` in the same chat.

| # | check | pass when |
|---|---|---|
| B1.1 | branch | asks you to create a branch and confirm before Step 1 |
| B1.2 | per task | prints one row per task and asks you to run the verifier commands and paste the output; it uses your paste as the evidence, never its own claim |
| B1.3 | UI gate | does not start a UI task without `.v2p/DESIGN.md` |
| B1.4 | EXECUTE.md | §1 one row per PLAN task from what actually ran; says there is no receipt |
| B2.1 | review starts | `/v2p review` accepts the EXECUTE.md (see the predicted failure below) |
| B2.2 | checks | each check is a separate pass; the codex row reads `unavailable: portable` |
| B2.3 | preview | asks for a preview or writes `preview: none — <reason>` with ux-laws/qa `unavailable:` and one §2 `open:` row for the gap |

**Predicted failure (found by reading the pack, 2026-10-02):** portable execute writes EXECUTE.md from the template, whose `checked:` line says `pending`, and nothing tells a portable run to replace it; review's portable precondition requires a `checked:` line that is **not** `pending`, so review should refuse with "Run /v2p execute first." The same holds for review → deploy. Record what the model actually does: refuses (confirms the defect), or proceeds anyway (the model ignored the precondition, also worth recording).

***

## Results table (copy once per runtime)
```
runtime: <ChatGPT|Gemini> · model: <name> · date: <YYYY-MM-DD> · pack: generated <date> · repo commit: <sha>
| # | pass/fail | note (quote the model when it fails) |
|---|---|---|
| A0 | | |
| A1.1 … A4.7 | | |
| B1.1 … B2.3 | | |
other observations: <anything that confused the model, contradictions it pointed out, where it stalled>
```
Paste the filled table, plus the transcript of any failed step, into a Claude Code session in this repo to triage the defects.

***
Copyright © 2026 Rafael Arciniegas. Licensed under the MIT License.
