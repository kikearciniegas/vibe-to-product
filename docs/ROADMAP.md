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
- Slice 6: brand (built 2026-09-25): `/v2p brand` between scavenge and mapping writes `.v2p/DESIGN.md` (sealed by `finalize-brand.sh`). Post-review iteration: `archive-cycle.sh` moves a reviewed cycle into `.v2p/cycles/<date>/` and mapping writes a short cycle-2 plan (no script parameters, nothing edited under a hash lock).
- A first test of the portable pack in ChatGPT or Gemini (slice-1 check 12).
- Slice 5 live: a Strix run (needs Docker) and the first real deploy of the fixture (needs a GitHub remote; use a throwaway copy).
- **Done 2026-10-01 (951c00d..75e3b46):** V0, V27, V28, V30, and finalize-review now checks the PLAN.md receipt. Live runs recorded before this have vacuous `verifier: pass` lines.
- **Done 2026-10-01 (aca5da7..79492e1):** V1. Audit, execute, review and deploy accept `not adopted — <path>` (owner decided otherwise) and `gap — <path>` (known, not built), each checked by `check-refs.sh` for an existing repo path; deploy counts gaps without blocking. Older receipts keep the old `checked:` format; nothing parses it.
- **Done 2026-10-01 (8c13260..f1b4b84):** V2, V3, V4 and the V1 loose ends (N/A form in audit, N/A reason in the status cell, hyphen accepted, copied `gap` rows get no task). finalize-audit runs §2 `done` evidence pairs and refuses a git-tracked draft (the draft is unsealed; its trust boundary is that this session wrote it); finalize-plan fails a `Qn` not in BRIEF §10 and warns on grep-only Verifiers for code tasks.
- **Done 2026-10-01 (batch 4, ends d1f20bd):** V6, V7 (task commit chains drift-check before `git add -A`; Step 0 clears untracked files), V8 (`--head <sha>`), V9, V12, the finalize-execute head check, and the verifier loose ends (all-placeholder Verifiers fail; commands in `manual:` never run).
- **Done 2026-10-01 (f2a56d9):** adopt offers a full project backup (`backup.sh`, `~/.v2p-backups/<project>/<ts>-original.tar.gz`) before any write; AUDIT §4 `backup:` line is gated.
- **Done 2026-10-01 (batches 5–7, ends ddaef6e and this push):** V5 (adopt keeps a project-owned root DESIGN.md; finalize-plan warns when a task's Files name it), V19–V23 (probe `git:empty` and `writable:`; `.gitignore` read without git; referenced notes get `keep:refs=<n>`; `docs/decisions/` or `docs/adr*/` is the decisions home; root DESIGN.md never merged or quarantined), V10, V11, V13–V17 and project gate commands (prose in review, mapping and execute; review lists skills set `off` in `skillOverrides`; `preview:` line in the review template).
- **Done 2026-10-01:** review suggests how to create a preview (project dev/preview command, local production build, host preview deploy) and gates exactly one `preview:` line; when none can be created, `preview: none — <reason>` lets ux-laws and qa read `unavailable:` (2b337d5). Brand suggests Dribbble, Awwwards, Behance and Pinterest when BRIEF §6 has no reference sites; the catalog lists scroll-craft for scroll-driven sites. Decided: CHANGELOG stays required for every project.
- **Done 2026-10-01 (batches 8–11, ends 826d867):** V18 (no-response links retried, then `UNREACHABLE` and kept), V24 (scavenge runs the last30days engine directly, `--quick --emit compact`), V25 (`]` no longer swallowed), V29 (guard hook blocks write targets, not mentions; `f=…; > $f` now blocked too). Loose ends: commits stage only the project minus `.v2p/` (execute and deploy); only `verify` writes `head:`; finalize-plan lints read only the mechanical part; finalize-audit fails `\|` in backticked cells and runs §3 evidence; deploy's high-effort scan follows review's accept-the-cost rule; review.md/SKILL.md describe a project-owned root DESIGN.md; an empty `.git/` inside a parent repo no longer resolves to the parent; quarantine honours `.gitignore` without git; scattered notes merge into `<decisions home>/from-<name>.md`; slice-5 spec carries a dated hook note.
- Dropped 2026-10-01: implementer routing as a script (the controller reads prose either way); content-matching cited § / Qn decisions (existence checks stay); finalize-plan running Verifiers at plan time (unsealed commands, slow on real repos; execute preflight catches an already-passing verifier).
- **Done 2026-10-01 (batches 12–14, ends this push):** guard hook blocks touch/ln/truncate/rsync, `.v2p/` directory destinations, inline interpreters (`python -c`, `perl -e`, … on mention), `sudo -u/-g`, and unresolved targets that could still name a final (bare `$f`, or a literal tail ending in a final name or `.v2p/`); `cp -t /tmp <final>` allowed. finalize-execute requires the verified tasks' `base..head` ranges to cover `base..HEAD`. finalize-plan checks the mechanical part of manual-first Verifier lines. The probe prints one `branch:` line in a repo with no commits (`detached` when detached). Scavenge passes last30days a one-subquery `--plan` (verified in mock mode: no warning blocks, URLs kept) and no longer claims the engine has a WebSearch fallback.
- Open (minor): guard hook still misses a command-substitution target (`cp x $(echo …)`), a final that appears only after expansion (`.v2p/$n.md`), interpreters running a script file or stdin, directory-contents copies (`rsync -a src/ .v2p/`), and option arguments other than `-t`/`-u`/`-g`; `ln -s <final>` with one operand is a known false block; hook untested under gawk/mawk/busybox and inside subagents. `task-record.sh verify` detects a no-command mechanical Verifier only at line start (finalize-plan refuses such plans first). The exec base is the first PLAN task's base, so out-of-order tasks can leave earlier commits unchecked. last30days `--plan` is untested on live data.

***
Copyright © 2026 Rafael Arciniegas. Licensed under the MIT License.
