---
name: v2p
description: Turn an idea or AI prototype into a production product. Use when the user says "v2p", "vibe to product", wants to start/plan/harden/ship an app, landing page, SaaS, internal tool or mobile app, or asks "what are we building". Runs a short interview (handshake) that writes .v2p/BRIEF.md, or adopts an existing/half-built codebase (scans it, derives the BRIEF, audits and tidies), then routes to later phases, writes the brand's DESIGN.md before planning, then executes the plan with per-task drift checks, reviews the branch, and ships it behind a full security scan with a live receipt.
---

# v2p — vibe to product (router)

## 1. What this does
v2p is a thin orchestrator: each phase reads the previous handoff file and writes one of its own in `<project>/.v2p/`.
It never reimplements what superpowers or gstack already do; later phases call them.
Portable pack: if this arrives as one pasted document, the files named below follow it as sections. Run the handshake first and use only the standards sections for the chosen profile.
Receipts, every phase: when a v2p script or gate refuses or blocks, stop and show the user its output; never write, edit or seal a `.v2p/` handoff file, `.v2p/work/` record or `.*-pass` receipt by hand.
Blocks between `<!-- claude-only -->` markers apply to Claude Code only; other runtimes skip them.

## 2. Entry
Optional argument: `handshake | adopt | scavenge | brand | mapping | execute | review | deploy`.

**Model guard:** before `adopt`, `scavenge`, `brand`, `mapping`, `execute`, `review` or `deploy`, if you are a small/fast model tier (Haiku-class, or any runtime's mini/flash/lite tier), stop before reading the phase file and reply only: "This phase needs a larger model. Switch model (Claude Code: `/model` → Sonnet or Opus) and run it again."

**Before asking the first question of any phase — including `adopt` — read that phase's file (table in §5) in full and follow it step by step.** This router only says which phase to run. Every question, template and gate lives in the phase file; never improvise them from the table.

No argument: probe the directory first. Portable: ask the user whether this folder has code and whether `.v2p/BRIEF.md` exists.
<!-- claude-only -->
Claude Code: run `sh <this skill's dir>/scripts/tidy-check.sh --probe` and print its one line (`root:… code:yes|no git:… branch:… brief:yes|none audit:yes|no writable:yes|no`); decide from it, not by judgement.
<!-- /claude-only -->
- BRIEF exists → print its §1 Profile line and its "Next" line, then offer: resume, or re-run the handshake.
  - "Next" resolution: BRIEF exists and no `.v2p/SCAVENGE.md` → offer `scavenge`; SCAVENGE exists and no `.v2p/DESIGN.md` → offer `brand`; DESIGN exists and no `.v2p/PLAN.md` → offer `mapping`; PLAN exists and no `.v2p/EXECUTE.md` → offer `execute`; EXECUTE exists and no `.v2p/REVIEW.md` → offer `review`; REVIEW exists and no `.v2p/DEPLOY.md` → offer `deploy`; DEPLOY exists → print `live since <written date> at <target>` and offer: redeploy (`deploy`) or re-theme (`brand`).
- No BRIEF and code present (a manifest such as package.json, pyproject.toml, go.mod, Cargo.toml, or source files) → ask: "Existing code found: Adopt it (scan, derive BRIEF, audit, tidy) (Recommended) / Fresh handshake (ignores the code)". Adopt → `phases/adopt.md`.
- No BRIEF and no code → ask "What are we building? One paragraph." and start the handshake. A docs-only folder (README and notes, no code) also goes here; add one line: "`/v2p adopt` merges existing notes into docs/."
- `/v2p adopt` always runs adopt; with an existing BRIEF it keeps it and runs audit + tidy only.

## 3. Target directory
- The BRIEF goes to `$PWD/.v2p/BRIEF.md`.
- If `$PWD` has no code and no `.v2p/`, ask once whether this directory is the project.
- Never scaffold a project.
- Recommend committing `.v2p/`: it is the contract between phases.

## 4. Profiles
| Profile | Shape |
|---|---|
| `landing` | one-action page, no login |
| `saas-web` | logged-in, users outside your organisation |
| `internal-tool` | logged-in, users work for you |
| `native-app` | iOS/Android binary |

Disambiguators (ask only the one that separates the two candidates):
- internal-tool vs saas-web → "Do users work for you?"
- landing vs saas-web → "Does anyone log in?"
- native-app vs saas-web → "If I handed you a finished API tomorrow, how much work remains?"

No fit: pick the nearest profile and record the gap in BRIEF §10. Never invent a profile.
AI features, payments, webhooks, i18n, special-category data, GraphQL and file uploads are conditional blocks inside the standards, not profiles.

## 5. Phases
| Phase | File | Writes | Status |
|---|---|---|---|
| `handshake` | `phases/handshake.md` | `.v2p/BRIEF.md` | available |
| `adopt` | `phases/adopt.md` | `.v2p/BRIEF.md` + `.v2p/AUDIT.md` | available |
| `scavenge` | `phases/scavenge.md` | `.v2p/SCAVENGE.md` | available |
| `brand` | `phases/brand.md` | `.v2p/DESIGN.md` (+ root `DESIGN.md` symlink) | available |
| `mapping` | `phases/mapping.md` | `.v2p/PLAN.md` | available |
| `execute` | `phases/execute.md` | `.v2p/EXECUTE.md` (+ `.v2p/PLAN-AMENDMENTS.md`) | available |
| `review` | `phases/review.md` | `.v2p/REVIEW.md` | available |
| `deploy` | `phases/deploy.md` | `.v2p/DEPLOY.md` | available |

## 6. When to load references
- Standards: per the profile mapping below, at the end of the handshake (to fill BRIEF §9) and by later phases.

| Profile | Files loaded (in order) | Also |
|---|---|---|
| landing | `references/standards/core.md`, `references/standards/web.md`, `references/standards/landing.md` | `references/landing-10-sections.md`, `references/ux-laws.md` |
| saas-web | `references/standards/core.md`, `references/standards/web.md`, `references/standards/saas-web.md` | `references/ux-laws.md` at review |
| internal-tool | `references/standards/core.md`, `references/standards/web.md`, `references/standards/internal-tool.md` | `references/ux-laws.md` at review |
| native-app | `references/standards/core.md`, `references/standards/native-app.md` | none |

- `references/landing-10-sections.md`: only for `landing`.
- `references/ux-laws.md`: at any UI review, and at review.
- BRIEF layout: `references/brief-template.md`.
- SCAVENGE and PLAN layouts: `references/scavenge-template.md` (scavenge), `references/plan-template.md` (mapping).
- DESIGN layout: `references/design-template.md` (brand).
- EXECUTE and REVIEW layouts: `references/execute-template.md` (execute), `references/review-template.md` (review).
- DEPLOY layout: `references/deploy-template.md` (deploy).
- Adopt: `references/tidy-rules.md` (what should exist, what is debris, what is never touched) and `references/audit-template.md` (layout of `.v2p/AUDIT.md`).
- Startup stack: `references/stack/overview.md` at mapping step 1; `references/stack/alternatives.md` only when a BRIEF constraint or a growth trigger needs a non-default provider or the country-eligibility lists; `references/stack/wiring.md` and `references/stack/security.md` by execute/review/deploy (mapping reads them only to cite row ids).
<!-- claude-only -->
- `references/model-routing.md`: before delegating any phase work.
- `references/skills-catalog.md`: at mapping step 2.
- `scripts/`: `tidy-check.sh` (probe + tidy; reusable as the tidy drift check), `backup.sh` (adopt: full project archive before any write), `quarantine.sh`, `finalize-scavenge.sh`, `finalize-audit.sh`, `finalize-brand.sh`, `archive-cycle.sh` (re-theme: archives a reviewed cycle), `finalize-plan.sh`, `check-pass.sh`, `drift-check.sh` (read-only scope gate), `task-record.sh` (sole writer of execute records and `.v2p/PLAN-AMENDMENTS.md`), `finalize-execute.sh`, `finalize-review.sh`, `finalize-deploy.sh`.
<!-- /claude-only -->
- Source rule for every v2p file: no `---` horizontal rules (use `***`); the DESIGN.md frontmatter fence is the one exception.

<!-- claude-only -->
## 7. Delegation (Claude Code)
- Run the interview on the main thread: it needs `AskUserQuestion`.
- Read `references/model-routing.md` before spawning any agent.
- Fable reasoning only via the `planner` agent, never a fork (a fork inherits the parent's model).
<!-- /claude-only -->

***
Copyright © 2026 Rafael Arciniegas. Licensed under the MIT License.
