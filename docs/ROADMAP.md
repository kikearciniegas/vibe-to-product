# v2p roadmap

Status as of 2026-09-24. Decisions come from the user; each slice gets a spec in `docs/specs/` before it is built.

## Done
- **Slice 1:** router, handshake, standards by profile, portable pack.
- **Slice 2:** scavenge (with the `finalize-scavenge.sh` gate and Q7 = /last30days + official changelog), mapping, stack guide, skills catalog.

## Slice 3: adopt + tidy (built 2026-09-23 · b8d250f · live test pending)
- **Adopt:** v2p runs in any folder (empty, new, existing, half-built). For existing code it scans the project, derives a BRIEF with every value marked `inferred`, writes an AUDIT, creates the missing files, and merges scattered notes into the standard files.
- **Layout:** `.v2p/` for phase handoffs (BRIEF, SCAVENGE, PLAN, REVIEW, DEPLOY, AUDIT); `docs/` for ARCHITECTURE, DECISIONS and threat-model; README, CHANGELOG and .env.example at the root.
- **Tidy:** a rule set of which files and folders should exist, checked by `tidy-check.sh`. Cleanup goes through `quarantine.sh`: you approve the list, the files move to `~/.v2p-backups/<project>/<timestamp>/` with a manifest and a restore command, and nothing is ever hard-deleted.
- **Modularity:** rules in `core.md` plus an audit section.
- **Code graph:** code-review-graph, with Serena for symbols and `rg` as the fallback.
- **Crash-safe checkpoints:** subagent results are saved to `.v2p/work/` so a re-run resumes instead of starting over.
- **Hook-enforced gates (proposal):** a PreToolUse hook blocks direct writes to the handoff files. Installing it into global settings is a separate decision for you.

## Slice 4: execute + review (built 2026-09-24 · 1fce294 · live test pending)
- **Execute:** runs the PLAN task by task through superpowers subagent-driven development (implementer `builder`/`quick`, reviewer `planner`), one commit per task after its verifier passes, on a v2p branch or worktree. Scope changes go to `.v2p/PLAN-AMENDMENTS.md`; PLAN.md is never edited.
- **Review:** one pass over the whole branch; findings are fixed, accepted or left open for deploy; the standards evidence is completed; the gate re-runs every PLAN verifier before it writes `.v2p/REVIEW.md`.

Checks run on a tiered cadence (spec: `docs/specs/slice-4-spec.md` §4):

| Tier | Trigger | What runs | Gate |
|---|---|---|---|
| every task | main thread, before the commit | `task-record.sh verify` = `drift-check.sh` (diff vs the task's Files list, branch, base, tidy delta) + the task's verifier commands | `finalize-execute.sh` |
| every task | task reviewer | `ponytail-review` on the task's diff (the diff skill; `ponytail-audit` is the whole-repo one) | `finalize-execute.sh` (shape only) |
| every task | implementer | test-driven development | reviewer prompt (not scripted) |
| every phase | review, once over the branch | `/review`, `/simplify` + `ponytail-review` → `ponytail-audit`, `/security-review` + `claude-security` (low effort), `translation-quality` when i18n is on, ux-laws + `/design-review`, `/qa`, `/codex review` | `finalize-review.sh` (runs, findings, verifier re-run) |
| before deploy | slice 5 | a full `claude-security` scan plus a Strix pentest | REVIEW §4 hand-off line |

Also available: context7 and `claude-mem:learn-codebase`. There is no `/verify` skill; `superpowers:verification-before-completion` is the equivalent.

## Slice 5: deploy
- Pre-deploy audit and provider choice.
- Strix: not installed; it needs Docker and an LLM API key. It is installed through the installing-third-party-tools skill when first needed.

## Cross-cutting
- **Regression suite:** fixture projects (empty, landing brief, messy brownfield) run headless with `claude -p`. They assert that phase files were read, that the `PASS` lines appear, and that the gates hold. This replaces the manual testing done today.
- **Refresh routine:** a monthly scheduled job re-verifies every `(verified: YYYY-MM)` item and the skills catalog, and proposes a diff for you to approve.
- **Plugin packaging:** a versioned plugin that ships the skill, scripts and hooks. It targets:
  - Claude Code
  - other agents that support the open Agent Skills layout (Codex CLI, Gemini CLI, Cursor; support per agent unverified)
  - desktop apps (Claude Desktop / claude.ai skill upload)
  - ChatGPT and Gemini apps, through `dist/v2p-portable.md`

  To keep this possible, the source stays compatible with that layout: relative paths, POSIX sh scripts, and Claude-only behaviour confined to claude-only blocks and hooks.

## Open items
- Brand-creation phase (the brand guide is still pending in the test project).
- A first test of the portable pack in ChatGPT or Gemini (slice-1 check 12).
- The duplicate `agent-reach` in `~/.agents/skills` (managed by `npx skills`), not cleaned up.

***
Copyright © 2026 Rafael Arciniegas. Licensed under the MIT License.
