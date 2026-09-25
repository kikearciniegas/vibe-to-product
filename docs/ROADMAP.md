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
- Slice 6: brand (built 2026-09-25): `/v2p brand` between scavenge and mapping writes `.v2p/DESIGN.md` (sealed by `finalize-brand.sh`); the test project's guide is still pending, so it re-themes when `brand.pdf` arrives. Post-review iteration: `archive-cycle.sh` moves a reviewed cycle into `.v2p/cycles/<date>/` and mapping writes a short cycle-2 plan (no script parameters, nothing edited under a hash lock).
- A first test of the portable pack in ChatGPT or Gemini (slice-1 check 12).
- Slice 5 live: a Strix run (needs Docker) and the first real deploy of the fixture (needs a GitHub remote; use a throwaway copy).
- The duplicate `agent-reach` in `~/.agents/skills` (managed by `npx skills`), not cleaned up.
- `finalize-review.sh` should check PLAN.md against its receipt, as `finalize-deploy.sh` does: both re-run PLAN verifiers through `sh -c`.
- Re-verifying a finished task: `drift-check.sh` compares base..HEAD, so later tasks' commits always show as drift; needs a design choice.
- Guard hook false positive: a multi-line Bash command that mentions a `.v2p/` final on one line and a write on another is blocked.
- `finalize-execute.sh` has no check that the recorded head keeps up with the branch head.
- Implementer routing (`builder` vs `quick`) is prose in execute.md, not scripted.
- The slice-5 spec says the guard hook is not installed; it is (global settings), so the spec line is stale.

***
Copyright © 2026 Rafael Arciniegas. Licensed under the MIT License.
