# Vibe-to-Product (v2p)

v2p turns an idea or an AI-generated prototype into a production product. It starts with a short interview (the handshake) that writes `.v2p/BRIEF.md` in your project: profile, the one job, success criteria, scope, brand, constraints, stack and the standards that apply. Later phases read that file instead of re-asking.

It is a thin orchestrator. In Claude Code, planning, execution and review are delegated to the superpowers and gstack skills; v2p decides what runs when and what each phase hands to the next.

## Two runtimes
**Claude Code (skill).** Install by symlink, then type `/v2p`:

```sh
ln -s "$PWD/skills/v2p" ~/.claude/skills/v2p
```

**Portable (any chat model).** Paste `dist/v2p-portable.md` into ChatGPT, Gemini or another chat, then say what you are building. The pack tells the model to run the handshake and use only the standards for your profile.

## Phases
| Phase | Writes | Status |
|---|---|---|
| `handshake` | `.v2p/BRIEF.md` | available |
| `scavenge` | `.v2p/SCAVENGE.md` | planned |
| `mapping` | `.v2p/PLAN.md` | planned |
| `execute` | none | planned |
| `review` | `.v2p/REVIEW.md` | planned |
| `deploy` | none | planned |

## Profiles
| Profile | Shape | Standards loaded |
|---|---|---|
| `landing` | one-action page, no login | core, web, landing + 10-section checks + UX laws |
| `saas-web` | logged-in, users outside your organisation | core, web, saas-web |
| `internal-tool` | logged-in, users work for you | core, web, internal-tool |
| `native-app` | iOS/Android binary | core, native-app |

The standards hold 188 checklist items across six files (`grep -c '^- \[ \]' skills/v2p/references/standards/*.md`), each claimed with evidence rather than a tick.

## File map
| Path | Role |
|---|---|
| `skills/v2p/SKILL.md` | router: entry, profiles, phases, when to load what |
| `skills/v2p/phases/handshake.md` | the interview and its confirmation gate |
| `skills/v2p/references/brief-template.md` | layout of `.v2p/BRIEF.md` |
| `skills/v2p/references/standards/` | `core.md`, `web.md`, and one file per profile |
| `skills/v2p/references/landing-10-sections.md` | per-section checks for landing pages |
| `skills/v2p/references/ux-laws.md` | UX laws as measurable checks |
| `skills/v2p/references/model-routing.md` | which agent and model runs each phase (Claude Code only) |
| `WORKFLOW.md` | the Architect / Executor / Auditor loop and failure-recovery rule |
| `build-portable.sh` | builds `dist/v2p-portable.md` |
| `dist/v2p-portable.md` | generated portable pack; never edit by hand |

## Build
```sh
sh build-portable.sh
```

## Verify
Run from the project directory:

```sh
grep -cE '^(name|description): ' skills/v2p/SKILL.md          # 2
grep -ciE 'custom cursor|urgency|whatsapp|back-to-top' skills/v2p/references/standards/core.md   # 0
grep -n 'FID' skills/v2p/references/standards/*.md              # no output
grep -rniE 'refuse any request|maximum 200 lines' skills/v2p    # no output
grep -rc '(verified: 2026-09)' skills/v2p/references            # total 8 or more
grep -rn 'PERSON[A]' README.md WORKFLOW.md skills/                # no output
sh build-portable.sh && grep -c 'Rafael Arciniegas' dist/v2p-portable.md   # 1
```

The full list, including the referenced-path and no-item-lost checks, is in `docs/specs/slice-1-spec.md` §6.

## Models
Claude Code: see `skills/v2p/references/model-routing.md`. Portable: any strong reasoning model.

**Stop vibing. Start engineering.**

***
Copyright © 2026 Rafael Arciniegas. Licensed under the MIT License.
