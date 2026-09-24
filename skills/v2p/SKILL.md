---
name: v2p
description: Turn an idea or AI prototype into a production product. Use when the user says "v2p", "vibe to product", wants to start/plan/harden/ship an app, landing page, SaaS, internal tool or mobile app, or asks "what are we building". Runs a short interview (handshake) that writes .v2p/BRIEF.md, or adopts an existing/half-built codebase (scans it, derives the BRIEF, audits and tidies), then routes to later phases.
---

# v2p — vibe to product (router)

## 1. What this does
v2p is a thin orchestrator: each phase reads the previous handoff file and writes one of its own in `<project>/.v2p/`.
It never reimplements what superpowers or gstack already do; later phases call them.
Portable pack: if this arrives as one pasted document, the files named below follow it as sections. Run the handshake first and use only the standards sections for the chosen profile.
Blocks between `<!-- claude-only -->` markers apply to Claude Code only; other runtimes skip them.

## 2. Entry
Optional argument: `handshake | adopt | scavenge | mapping | execute | review | deploy`.

**Before asking the first question of any phase — including `adopt` — read that phase's file (table in §5) in full and follow it step by step.** This router only says which phase to run. Every question, template and gate lives in the phase file; never improvise them from the table.

No argument: probe the directory first. Portable: ask the user whether this folder has code and whether `.v2p/BRIEF.md` exists.
<!-- claude-only -->
Claude Code: run `sh <this skill's dir>/scripts/tidy-check.sh --probe` and print its one line (`root:… code:yes|no git:… branch:… brief:yes|none audit:yes|no`); decide from it, not by judgement.
<!-- /claude-only -->
- BRIEF exists → print its §1 Profile line and its "Next" line, then offer: resume, or re-run the handshake.
  - "Next" resolution: BRIEF exists and no `.v2p/SCAVENGE.md` → offer `scavenge`; SCAVENGE exists and no `.v2p/PLAN.md` → offer `mapping`.
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
AI features, payments, webhooks and i18n are conditional blocks inside the standards, not profiles.

## 5. Phases
| Phase | File | Writes | Status |
|---|---|---|---|
| `handshake` | `phases/handshake.md` | `.v2p/BRIEF.md` | available |
| `adopt` | `phases/adopt.md` | `.v2p/BRIEF.md` + `.v2p/AUDIT.md` | available |
| `scavenge` | `phases/scavenge.md` | `.v2p/SCAVENGE.md` | available |
| `mapping` | `phases/mapping.md` | `.v2p/PLAN.md` | available |
| `execute` | none | none | not available in this version |
| `review` | none | `.v2p/REVIEW.md` | not available in this version |
| `deploy` | none | none | not available in this version |

For a phase marked "not available in this version", reply exactly that and stop. Do not improvise the phase.

## 6. When to load references
- Standards: per the profile mapping below, at the end of the handshake (to fill BRIEF §9) and by later phases.

| Profile | Files loaded (in order) | Also |
|---|---|---|
| landing | `references/standards/core.md`, `references/standards/web.md`, `references/standards/landing.md` | `references/landing-10-sections.md`, `references/ux-laws.md` |
| saas-web | `references/standards/core.md`, `references/standards/web.md`, `references/standards/saas-web.md` | `references/ux-laws.md` at review |
| internal-tool | `references/standards/core.md`, `references/standards/web.md`, `references/standards/internal-tool.md` | `references/ux-laws.md` at review |
| native-app | `references/standards/core.md`, `references/standards/native-app.md` | none |

- `references/landing-10-sections.md`: only for `landing`.
- `references/ux-laws.md`: at any UI review.
- BRIEF layout: `references/brief-template.md`.
- SCAVENGE and PLAN layouts: `references/scavenge-template.md` (scavenge), `references/plan-template.md` (mapping).
- Adopt: `references/tidy-rules.md` (what should exist, what is debris, what is never touched) and `references/audit-template.md` (layout of `.v2p/AUDIT.md`).
- Startup stack: `references/stack/overview.md` at mapping step 1; `references/stack/wiring.md` and `references/stack/security.md` by execute/review (mapping reads them only to cite row ids).
<!-- claude-only -->
- `references/model-routing.md`: before delegating any phase work.
- `references/skills-catalog.md`: at mapping step 2.
- `scripts/`: `tidy-check.sh` (probe + tidy; reusable as the tidy drift check), `quarantine.sh`, `finalize-scavenge.sh`, `finalize-audit.sh`, `finalize-plan.sh`, `check-pass.sh`.
<!-- /claude-only -->
- Source rule for every v2p file: no `---` horizontal rules (use `***`).

<!-- claude-only -->
## 7. Delegation (Claude Code)
- Run the interview on the main thread: it needs `AskUserQuestion`.
- Read `references/model-routing.md` before spawning any agent.
- Fable reasoning only via the `planner` agent, never a fork (a fork inherits the parent's model).
<!-- /claude-only -->

***
Copyright © 2026 Rafael Arciniegas. Licensed under the MIT License.
