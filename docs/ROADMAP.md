# v2p roadmap

Status as of 2026-09-25. Decisions come from the user; each slice gets a spec in `docs/specs/` before it is built.

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

## Slice 4: execute + review (built 2026-09-24 · 1fce294 · live-tested 2026-09-25 on the landing fixture: execute PASS 11/19, review PASS with 1 ruling; the fixes it surfaced are merged)
- **Execute:** runs the PLAN task by task through superpowers subagent-driven development (implementer `builder`/`quick`, reviewer `planner`), one commit per task after its verifier passes, on a v2p branch or worktree. Scope changes go to `.v2p/PLAN-AMENDMENTS.md`; PLAN.md is never edited.
- **Review:** one pass over the whole branch; findings are fixed, accepted or left open for deploy; the standards evidence is completed; the gate re-runs every PLAN verifier before it writes `.v2p/REVIEW.md`.

Checks run on a tiered cadence (spec: `docs/specs/slice-4-spec.md` §4):

| Tier | Trigger | What runs | Gate |
|---|---|---|---|
| every task | main thread, before the commit | `task-record.sh verify` = `drift-check.sh` (diff vs the task's Files list, branch, base, tidy delta) + the task's verifier commands | `finalize-execute.sh` |
| every task | task reviewer | `ponytail-review` on the task's diff (the diff skill; `ponytail-audit` is the whole-repo one) | `finalize-execute.sh` (shape only) |
| every task | implementer | test-driven development | reviewer prompt (not scripted) |
| every phase | review, once over the branch | `/review`, `/simplify` + `ponytail-review` → `ponytail-audit`, `/security-review` + `claude-security` (low effort), `translation-quality` when i18n is on, ux-laws + `/design-review`, `/qa`, `/codex review` | `finalize-review.sh` (runs, findings, verifier re-run) |
| before deploy | deploy, once over the whole repo | a full `claude-security` scan (effort high), Strix when Docker and an LLM key exist, then gstack `/setup-deploy`, `/land-and-deploy`, `/canary` | `finalize-deploy.sh` |

Also available: context7 and `claude-mem:learn-codebase`. There is no `/verify` skill; `superpowers:verification-before-completion` is the equivalent.

## Slice 5: deploy (built 2026-09-25 · live test pending)
- **Gate first:** deploy reads the sealed REVIEW.md, runs the full `claude-security` scan (whole repo, effort high) and fixes or accepts every finding; Strix is optional (Docker + an LLM key, installed only on your yes).
- **Shipping is delegated:** the PLAN's deploy runbook is walked with you (values never pass through v2p), then gstack `/setup-deploy`, a `gh pr create`, `/land-and-deploy <url>` and `/canary <url>`; no per-provider deploy script.
- **Receipt:** `finalize-deploy.sh` checks the scan stamp and commit accounting, the deploy and canary reports, the merge into `origin/<base>`, every PLAN verifier re-run against the live host, two live curls, the rollback line and the secrets register, then writes the deploy receipt.

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
- **First adopt-mode field test on a mature project (field test, 2026-09-30):** 31 issues with evidence, root cause, fix and acceptance test in `docs/field-tests/2026-09-30-field test-adopt.md`. Two are P0. V0: no mechanical Verifier has ever run, because the backtick-only extractor matched 0 of 14 and every `verifier: pass` was vacuous. V1: review Step 3 cannot finalize on a mature project. Fix these before any further live test. Index (fix order and details in the field test):
  - **P0** V0 no verifier command ever runs · V1 review Step 3 has no honest status for "not built" / "owner decided otherwise"
  - **P1** V2 audit "done" evidence never executed · V3 mapping invents decision provenance, carries unverified gaps as facts · V4 structural verifiers pass while behaviour is broken · V5 brand in adopt mode overwrites the repo's design-system doc
  - **P2 execute** V6 commit uses `git add -A` · V7 drift-check counts files untracked before the task · V8 drift-check always measures `base..HEAD`, so re-verifying a finished task shows later tasks as drift · V9 finalize-execute deletes task records · V10 `task-record manual` can't say decision vs observation · V11 no-op task not stopped · V12 draft not enforced at execute start
  - **P2 review** V13 named skills disabled for model invocation · V14 claude-security low scan needs a typed command + 60 s confirm · V15 preview URL assumed, never declared
  - **P2 research** V16 official legal sites block fetches · V17 scavenged numeric obligations never checked · V18 link check deletes unreachable evidence
  - **P3** V19 empty `.git` · V20 tidy-check without git · V21 merge proposals for heavily referenced files · V22 ignores existing decision/changelog homes · V23 probe skips writability · V24 last30days overflows subagent · V25 `]` swallowed by URL regex · V26 source cap vs jurisdictions · V27 Files as bullets · V28 finalize-plan dry-run needs repo tree · V29 guard hook blocks any command that mentions a `.v2p/` final · V30 commands in table cells
- Slice 6: brand (built 2026-09-25): `/v2p brand` between scavenge and mapping writes `.v2p/DESIGN.md` (sealed by `finalize-brand.sh`); the test project's guide is still pending, so it re-themes when `brand.pdf` arrives. Post-review iteration: `archive-cycle.sh` moves a reviewed cycle into `.v2p/cycles/<date>/` and mapping writes a short cycle-2 plan (no script parameters, nothing edited under a hash lock).
- A first test of the portable pack in ChatGPT or Gemini (slice-1 check 12).
- Slice 5 live: a Strix run (needs Docker) and the first real deploy of the fixture (needs a GitHub remote; use a throwaway copy).
- The duplicate `agent-reach` in `~/.agents/skills` (managed by `npx skills`), not cleaned up.
- `finalize-review.sh` should check PLAN.md against its receipt, as `finalize-deploy.sh` does: both re-run PLAN verifiers through `sh -c`.
- `finalize-execute.sh` has no check that the recorded head keeps up with the branch head.
- Implementer routing (`builder` vs `quick`) is prose in execute.md, not scripted.
- The slice-5 spec says the guard hook is not installed; it is (global settings), so the spec line is stale.

***
Copyright © 2026 Rafael Arciniegas. Licensed under the MIT License.
