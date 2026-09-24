# v2p SLICE 4 — implementation spec (execute + review, tiered drift checks)

**Conclusion first.** Build 10 new files, edit 9. Execute is a thin wrapper around `superpowers:subagent-driven-development` (+ extras) with three v2p additions that prose cannot enforce: (1) a per-task **scope gate** (`drift-check.sh`: the working-tree diff since the task's recorded base must fall inside the PLAN task's `**Files:**` list plus an explicit amendment record), (2) a per-task **record written only by a script** (`task-record.sh`: base/branch at start, verifier commands actually run with exit codes and output, manual observations attributed to the user, ponytail line), and (3) a **phase receipt** (`finalize-execute.sh` → `.v2p/EXECUTE.md` + `.execute-pass`) that review refuses without. Review runs the phase-tier set once over the whole branch diff (gstack `/review` + `requesting-code-review-extras`, `ponytail-review` as the simplify pass, claude-security plugin (with `/security-review` if `/help` lists it), `translation-quality` when i18n is ON, `references/ux-laws.md` for UI, `/codex review` as the only Codex role), adjudicates findings into fix commits, completes the standards evidence table (no `pending` except `deferred to deploy`), and `finalize-review.sh` **re-runs every mechanical PLAN verifier itself** before writing `.v2p/REVIEW.md` + `.review-pass`. PLAN.md is never edited mid-execute: scope changes go to an append-only `.v2p/PLAN-AMENDMENTS.md` written by the script, so `check-pass.sh` on PLAN keeps holding.

Four things the user should hear before the builder starts (details in §8): (a) the ROADMAP's "ponytail-audit on the diff" names the wrong skill — measured today: `ponytail-audit` is repo-wide, `ponytail-review` is the diff one; the cadence uses `ponytail-review` per task and `ponytail-audit` once at review. (b) `/security-review` and `/simplify` as Claude Code built-ins are still `(unverified)` (the `claude` binary is a shell function on this machine; not greppable); the design does not depend on them — fallbacks are `claude-security` (plugin enabled) and `ponytail-review`. (c) The real PLAN (`personal_skills/v2p/.v2p/PLAN.md`) contains a launch task (13) and a review task (14) and its Task 1 scaffolds into a **subdirectory** (`create-next-app grooming-landing && cd grooming-landing`) — execute's preflight must catch this; the spec adds a `skip <n> "<reason>"` record so 13/14 are handed to `/v2p review` / `/v2p deploy` visibly, not run. (d) Standards evidence cannot be written into PLAN.md (hash-locked); it lives in `.v2p/EXECUTE.md` §2 and is completed in `.v2p/REVIEW.md` §3.

Everything below was measured or run by me today (2026-09-24) unless marked `(unverified)`. Live-session behaviour is unverified by construction. The two glob/parse behaviours the scripts depend on were tested under `sh` (bash 3.2) and `zsh 5.9` (§3.5).

***

## 1. File tree delta

```
vibe-to-product/
├── build-portable.sh                        # MODIFIED: +4 parts (phases/execute.md, phases/review.md, references/execute-template.md, references/review-template.md)
├── README.md                                # MODIFIED: phases table (execute/review available), file map (+10), verify lines (+4)
├── docs/ROADMAP.md                          # MODIFIED: slice 4 → built; cadence wording corrected (ponytail-review per task)
├── docs/specs/slice-4-spec.md               # NEW: this document
├── tests/
│   ├── fixture-execute.sh                   # NEW (~30 lines): tiny git project + landing BRIEF + 3-task PLAN with receipt
│   ├── test-execute.sh                      # NEW (~90 lines): drift-check + task-record + finalize-execute falsifiers, sh and zsh
│   ├── fixtures/finalize-review/REVIEW.md   # NEW: deliberately bad draft (like fixtures/finalize-plan)
│   └── test-finalize-review.sh              # NEW (~70 lines): fix-one-step-at-a-time to PASS, sh and zsh
└── skills/v2p/
    ├── SKILL.md                             # MODIFIED: description, §2 Next resolution + model guard list, §5 rows, §6 refs
    ├── phases/
    │   ├── execute.md                       # NEW (~140 lines)
    │   ├── review.md                        # NEW (~110 lines)
    │   └── mapping.md                       # MODIFIED: Step 5 hand-off line; Verifier convention note
    ├── references/
    │   ├── execute-template.md              # NEW (~40 lines) — portable
    │   ├── review-template.md               # NEW (~45 lines) — portable
    │   ├── plan-template.md                 # MODIFIED: Next line; Verifier convention (self-checking commands)
    │   ├── model-routing.md                 # MODIFIED: execute/review rows replace stubs; drift table → "built"
    │   └── skills-catalog.md                # MODIFIED: ponytail-review vs -audit; execute row; security row
    ├── scripts/
    │   ├── drift-check.sh                   # NEW (~55 lines, read-only)
    │   ├── task-record.sh                   # NEW (~90 lines, the only writer of execute records and PLAN-AMENDMENTS.md)
    │   ├── finalize-execute.sh              # NEW (~70 lines)
    │   └── finalize-review.sh               # NEW (~75 lines)
    └── hooks/guard-finals.sh                # MODIFIED: +EXECUTE.md, +REVIEW.md in the guarded list (proposal stays uninstalled)
```

Conventions carried from slices 2–3: `***` not `---`; copyright line last on every `.md`; `(verified: 2026-09)` with URL on the same line; `<!-- claude-only -->` blocks stripped by the build; scripts POSIX `sh`, no `[[ ]]`, no arrays, no `for x in $unquoted`, `printf '%s\n'` over `echo` for values, and — new, measured today — **never `case $f in $pat)` with a pattern in a variable** (zsh matches it literally; §3.5 gives the tested `match()` function).

Why 4 scripts and not 2: `drift-check.sh` is read-only and callable by the main thread at any time (also by review on the whole branch); `task-record.sh` is the single writer of records so a record cannot be typed; the two finalize scripts follow the receipts pattern every phase already uses. Not built: a `/ralph-loop` wrapper (the PLAN already names eligible tasks; the phase file gives the exact invocation), an `EVIDENCE.md` separate from EXECUTE.md, a per-task hook.

***

## 2. Design answers

**Execution mode.** Default `superpowers:subagent-driven-development` + `subagent-driven-development-extras` (both present: plugin 6.4.1 active per `installed_plugins.json`; extras at `~/.claude/skills/`). Inline `superpowers:executing-plans` (6.4.1: "your human partner chose inline") when the user picks it (open question 1). v2p adds nothing to the loop's shape; it adds what the dispatch carries and what the controller runs between dispatches (§3.1 Step 2). SDD keeps its own ledger (`<workspace>/progress.md`, SKILL.md 6.4.1 lines ~134–152); v2p's records are not a second ledger — they hold what SDD's ledger does not: the scope diff, the verifier's observed output, the manual observation, the ponytail line. Execute.md says which is which.

**Drift model.** Per task, base = `HEAD` at `task-record.sh start <n>`. Changed set = `git diff --name-only <base>` (tracked, committed or not) ∪ `git ls-files --others --exclude-standard` (untracked). Allowed set = backticked tokens of the task's `**Files:**` line (cut at `**Interfaces:**`; first word of each token; `<…>` → `*`) ∪ `.v2p/PLAN-AMENDMENTS.md` lines for that task ∪ always: `.v2p/*` and the lockfiles list from `tidy-rules.md` §4. Anything else → `DRIFT file <path>`, exit 1. Also `DRIFT branch` (checkout switched since start — parallel-session guard) and `DRIFT tidy` (new `tidy-check.sh --tsv` rows since start). Measured on the real PLAN: the Files line parses for all 14 tasks (7–17 tokens each); `[locale]` paths need the string-equality-first matcher (§3.5).

**Where evidence lives.** PLAN §4 is copied into `.v2p/EXECUTE.draft.md` §2 by the main thread at Step 1 (statuses and N/A reasons kept); execute fills rows as tasks satisfy them; `finalize-execute.sh` checks shape (same items as PLAN §4, `done` ⇒ evidence, `N/A` ⇒ `BRIEF §`) and copies the table into EXECUTE.md; review completes it in REVIEW.md §3 with the rule "no `pending` unless the evidence cell says `deferred to deploy: <why>`". Real-PLAN fact: N/A reasons sit in the **status** cell (`N/A — BRIEF §1 …`) with an empty evidence cell; the check accepts `BRIEF §` in either cell.

**Amendments, not edits.** `task-record.sh allow <n> <path> "<reason>"` appends `- <ISO> · task <n> · files += \`<path>\` · <reason>` to `.v2p/PLAN-AMENDMENTS.md`. Nothing else may write PLAN.md or the amendments file (hook proposal extended). Rulings on plan defects go in the SDD/executing-plans ledger as those skills prescribe; v2p records only scope.

**Failing verifier.** Inside a task: the implementer iterates with TDD; SDD's fix rounds apply (R ≤ 5). `task-record.sh verify <n>` may be run any number of times; each run overwrites the verifier lines (last run wins, and the record keeps `attempts: <k>`). Policy in execute.md: 3 failed `verify` runs on one task → stop, load `superpowers:systematic-debugging` (+ extras), and if the verifier itself is wrong, that is a plan defect: ruling in the ledger, `skip` with reason only on the user's yes — never "fix" the verifier (PLAN is hash-locked anyway). Mechanical tasks may run under `/ralph-loop "<task-record verify n>" --max-iterations 5`; the verify script is the loop's verifier.

**Commit discipline.** One commit per task, after `verify` passes and before the task reviewer is dispatched (SDD's own order: "implements, tests, commits, self-reviews"). The commit command carries the branch check: `[ "$(git rev-parse --abbrev-ref HEAD)" = "$(sed -n 's/^branch: //p' .v2p/work/execute-task-<n>.md)" ] && git add -A && git commit -m "<type>: <task title>"`. `git add -A` is safe only because `drift-check` ran first (nothing outside scope exists). `finalize-execute.sh` requires a clean tree (excluding `.v2p/`) — the positive evidence that discipline held. Whether the commit is automatic or user-confirmed: open question 2.

**Parallel-session safety.** Execute refuses to start on a dirty tree (`git status --porcelain | grep -v '^??' | grep -v '^.. .v2p/'` non-empty → print the paths and stop; v2p never stashes). Default working location: a worktree via `superpowers:using-git-worktrees` (SDD's own setup step) **iff** `.v2p/PLAN.md` is tracked (`git ls-files --error-unmatch .v2p/PLAN.md`), because `.v2p/work/` is gitignored and per-worktree while the handoff files must travel; otherwise a branch in place (`git switch -c v2p/execute-<date>`, clean tree only). Open question 3. Records store the branch; drift-check and both finalize scripts compare it.

**Codex.** Review-only, as decided: `/codex review` (gstack skill, Step 2A "Review mode", `codex review --base <base>`; binary present at `~/.local/bin/codex`, auth `(unverified)` — the skill probes it in its Step 0.5). Its findings enter REVIEW.md §2 as rows adjudicated by the main thread; Codex never edits. Unavailable → the Runs row reads `unavailable: <reason>`; `finalize-review.sh` accepts that only for the codex row. Open question 4.

**Model routing.** Main thread orchestrates (needs `AskUserQuestion`, Agent tool). Implementer: `builder` (Opus) when the task's Files include code; `quick` (Sonnet) when every Files token is under `docs/` or ends in `.md`. Task reviewer: `planner` (Fable, read-only — the right shape for a reviewer; has Bash to re-run tests). Review phase: gstack skills on the main thread; standards-evidence audit by `planner`; `/codex` via its skill. Model guard extends to `execute` and `review`.

**Portable.** `phases/execute.md`, `phases/review.md`, both templates ship in the pack; scripts do not. Portable text: the model runs the loop itself, prints the per-task table and the evidence table, the user runs verifier commands and pastes output; no receipts ("portable has no gate; say so").

**Tiered cadence → triggers.** §4.

***

## 3. Per-file spec

### 3.1 `phases/execute.md` (~140 lines) — writes `.v2p/EXECUTE.md` (+ `.v2p/PLAN-AMENDMENTS.md` when scope changes)

**Purpose** (2 lines). Implement `.v2p/PLAN.md` task by task with a scope gate, a verifier record and a commit per task; fill standards evidence as tasks earn it. The execution loop is superpowers' job; v2p adds the gates.

**Preconditions.**
- `.v2p/PLAN.md` passed mapping's finalize. Portable: header `Next: /v2p execute` present. Claude-only: `sh <skill>/scripts/check-pass.sh .v2p/PLAN.md .v2p/.plan-pass` prints `OK`; else `PLAN.md failed its check: re-run /v2p mapping.` and stop.
- `.v2p/EXECUTE.md` exists with a receipt → offer resume (go to review) or re-run.
- Records: list `.v2p/work/execute-task-*.md`. A record is reusable when its `plan:` line equals the content of `.v2p/.plan-pass` (not "today" — execution spans days); print "resuming: tasks <list> done, <list> started" and continue from the first task without `verifier: pass`. Any record with another `plan:` is stale: `task-record.sh start` overwrites it.
- `.v2p/PLAN-AMENDMENTS.md` if present: read it; every line is scope already granted.
- Model guard (router).

**Step 0 — Git safety.** Dirty tree (tracked changes outside `.v2p/`) → print the paths, "Commit or discard these yourself; v2p never stashes or commits another session's changes.", stop. Clean → worktree or branch per §2 (claude-only: `AskUserQuestion` once; portable: tell the user to create the branch). Record nothing yet; `task-record.sh start` captures branch and base.

**Step 1 — Preflight** (before Task 1; SDD-extras rule "the scan executes"). Main thread:
1. Copy PLAN §4 into `.v2p/EXECUTE.draft.md` from `references/execute-template.md` (statuses kept; evidence empty).
2. Run the PLAN's empirical claims: every `**Verifier:**` mechanical command that can run on an empty tree is expected to FAIL now (red before green); a verifier that passes before the task exists is a plan defect → ruling in the ledger.
3. Scope sanity: a task whose steps `cd` into a new directory, or whose Files are outside the project root, is a plan defect (the real PLAN's Task 1 does this) → ruling: scaffold into `.` (adapt the command) or stop and ask.
4. Task triage: a task whose title starts with `Review` or whose Verifier needs production URLs/DNS (`<domain>` placeholders in every command) is not executed here: `task-record.sh skip <n> "handed to /v2p review"` / `"handed to /v2p deploy"`, only on the user's yes (`AskUserQuestion`, one question listing them).

**Step 2 — Task loop** (order from PLAN §6 `Order:` line; independent tasks may run in parallel only through SDD's own fan-out rules — read `subagent-driven-development-extras/references/fan-out.md` first). Per task `<n>`:
1. `sh <skill>/scripts/task-record.sh start <n>` → writes the record (§3.6). Resume: prints `resume` and keeps the base.
2. Dispatch (SDD implementer prompt) with these v2p lines appended: "Change only the files in this task's `**Files:**` list. If you must touch another path, stop and report the path and why; do not touch it. Run `sh <skill>/scripts/drift-check.sh <n>` before you report. Commit only with the branch check in the same command (text from §2). Use `superpowers:test-driven-development` for every step that writes code." Inline mode: the main thread does the same.
3. Implementer reports a needed path → main thread decides; if granted: `task-record.sh allow <n> <path> "<reason>"`; else the implementer reverts it.
4. `sh <skill>/scripts/task-record.sh verify <n>` → runs drift-check, then every verifier command (§3.6), writes the result. Exit 1 → back to 2 (fix round). Three failed runs → Failing-verifier policy (§2).
5. Manual part of the Verifier ≠ `none` → `AskUserQuestion` asks the user for the observation (what they saw, where, when); `task-record.sh manual <n> "<their words>"`.
6. Commit (the one-liner with the branch check). SDD: the implementer commits; the controller checks `git log -1 --format=%H` ≠ base afterwards.
7. Task review (SDD task-reviewer prompt) with one v2p line: "Also load the `ponytail-review` skill on `git diff <base>..HEAD` and report its findings as a separate list." Controller writes `task-record.sh ponytail <n> "<k> findings, <m> cut, <k-m> accepted: <one line>"` (or `"none"`).
8. Standards rows this task satisfies (PLAN §4 rows named in the task, or rows whose evidence hint the verifier output covers): set `done` in `EXECUTE.draft.md` §2 with evidence = the command and its observed output from this run (the record's `verifier:` line is citable verbatim), or a path/URL. Never `[x]`.

**Step 3 — Failing verifier.** Text of §2 "Failing verifier" verbatim, plus: "a `skip` is never silent: it needs the user's yes and the reason is printed in EXECUTE.md §1."

**Step 4 — Finalize.** Portable: write `.v2p/EXECUTE.md` from the draft as the template says. Claude-only: `sh <skill>/scripts/finalize-execute.sh .v2p` until `PASS`. It requires a record with receipt for every PLAN task, a clean tree, the branch, and the §2 shape; it generates §1 from the records; writes `EXECUTE.md` + `.v2p/.execute-pass`; clears `.v2p/work/execute-*`. Never write `EXECUTE.md` by hand.

**Step 5 — Hand off.** Print `.v2p/EXECUTE.md`, tasks done/skipped, standards done/N-A/pending counts, the branch and `base..head`, the amendments count, then `Next: /v2p review`.

**Claude Code note** (claude-only block): SDD + extras (load in the same turn); TDD skill in every implementer dispatch; agents per §2 (never pass a model); `superpowers:verification-before-completion` + extras before Step 4 on the evidence rows ("a green result is evidence about the check's reach"); `/ralph-loop` only for tasks listed in PLAN §6 as eligible, prompt = `sh <skill>/scripts/task-record.sh verify <n>`, always `--max-iterations`; context7 for any API contract a task relies on (core.md "API Contract Verification" row evidence); `claude-mem:learn-codebase` optional, never a source of findings; `.v2p/work/` records are the only resume source.

Copyright line.

### 3.2 `phases/review.md` (~110 lines) — writes `.v2p/REVIEW.md`

**Purpose.** Review the whole execute branch once with the phase-tier set, fix what it finds, complete the standards evidence, and hand a receipt to deploy.

**Preconditions.** Claude-only: `check-pass.sh .v2p/EXECUTE.md .v2p/.execute-pass` → `OK`, else `Run /v2p execute first.`; portable: EXECUTE.md with `checked:` line. Existing REVIEW.md with receipt → resume/re-run. Clean tree, same branch as EXECUTE header (`branch:`), else stop. Model guard. Checkpoints `.v2p/work/review-<check>.md` reusable when line 1 `head:` equals current `git rev-parse HEAD`.

**Step 0 — Scope.** `base` and `branch` from EXECUTE.md `checked:` line; diff = `git diff <base>..HEAD`; also `sh <skill>/scripts/drift-check.sh --branch` (whole-branch mode: changed set vs the union of all PLAN Files + amendments; a file outside every task's scope is finding #1).

**Step 1 — Runs** (each writes `.v2p/work/review-<check>.md` first line `head: <sha> · check: <name> · run: <exact invocation>`, then findings as `- <path:line> · <severity> · <one line>`; the producing agent/skill writes it or the main thread writes it on receipt):

| check | runs | on | required |
|---|---|---|---|
| code-review | gstack `/review` + `requesting-code-review-extras` (main thread) | the branch diff | always |
| simplify | `/simplify` if `/help` lists it `(unverified)`; else `ponytail-review` on the branch diff, then `ponytail-audit` on the repo (installed: plugin `ponytail@ponytail` 4.9.0, enabled) | diff, then repo | always |
| security | `/security-review` if `/help` lists it `(unverified)`; always the `claude-security` plugin (enabled, 0.11.0; invocation `(unverified)` — its README describes effort tiers; use the lowest here, the full scan is deploy's) | repo | always |
| verification | `superpowers:verification-before-completion` + extras on EXECUTE.md §2 evidence rows: for each `done` row re-run the cited command; mismatch → finding | evidence table | always |
| ux-laws | `references/ux-laws.md` checks + gstack `/design-review` (+ `gstack-extras`) on the running preview | UI | always (all four profiles have UI) |
| i18n | `translation-quality` skill (installed at `~/.claude/skills/translation-quality`) on `messages/*` or the locale files named in PLAN | locale files | only if BRIEF §9 "Conditional blocks ON" contains `i18n` |
| codex | `/codex review` (review mode, `--base <base>`) | diff | always; may be `unavailable: <reason>` |
| qa | gstack `/qa` on the preview URL; `/qa-only` for re-checks | running app | always for web profiles; native-app: `manual: <who ran what on which device>` |

**Step 2 — Adjudicate and fix.** Every finding gets one row in REVIEW.draft.md §2: `fixed <sha>` (each fix its own commit with its test, TDD), `accepted: <reason>` or `open: <reason>`. `open` is allowed only when the reason names the deploy task or a BRIEF §. Fixes are implemented by `builder`/`quick` under the same dispatch rules as execute (Files list = the finding's paths; `drift-check.sh --branch` after each).

**Step 3 — Standards evidence.** Copy EXECUTE.md §2 into REVIEW.draft.md §3 and complete it: every row `done` with evidence (command + output from this phase, path or URL) or `N/A` citing `BRIEF §`; `pending` only as `pending | deferred to deploy: <what production state it needs>`. `planner` audits the table (read-only) and returns rows whose evidence does not prove the item; the main thread fixes them.

**Step 4 — Threat model and docs.** `docs/threat-model.md` exists and names every §2 provider entry point (PLAN `## Threat Model`); `docs/ARCHITECTURE.md` module map matches `ls` (core.md Modularity item 1); `tidy-check.sh` → 0 violations or each listed with a reason.

**Step 5 — Finalize.** Claude-only: `sh <skill>/scripts/finalize-review.sh .v2p` until `PASS` (it re-runs every mechanical PLAN verifier — expect minutes). Portable: write REVIEW.md from the draft.

**Step 6 — Hand off.** Print path, findings fixed/accepted/open, standards done/N-A/deferred, `pre-deploy: pending (claude-security full scan + Strix pentest run by /v2p deploy)`, `Next: /v2p deploy (not available in this version)`.

**Claude Code note.** `AskUserQuestion` for: accepting an `open` finding, `/codex` unavailable → continue without, deferred rows. Never `mcp__claude-in-chrome__*`; `/browse` for anything needing a click. Strix: slice 5 only; not installed; mention only.

Copyright line.

### 3.3 `references/execute-template.md` — portable

````
# EXECUTE — <project name>
checked: pending   ← finalize-execute.sh replaces this line: tasks <done>/<total> · skipped <k> · standards done <d> · N/A <a> · pending <p> · branch <b> · base <sha> · head <sha>
written: <YYYY-MM-DD> by v2p execute · reads: .v2p/PLAN.md (<plan hash, first 12>) · mode: subagent-driven | inline · amendments: <n> (.v2p/PLAN-AMENDMENTS.md | none)

## 1. Tasks
<generated by finalize-execute.sh from .v2p/work/execute-task-*.md; do not write by hand>
| task | base..head | drift | verifier | manual | ponytail-review |
|---|---|---|---|---|---|

## 2. Standards (copied from PLAN §4; execute fills evidence; review completes it)
| item | file | status | evidence |
|---|---|---|---|
Rows: <n> (must equal PLAN §4)

Next: /v2p review
````
Rule above the block: statuses exactly `done`, `pending`, `N/A` (an `N/A — <reason>` status cell is accepted when it or the evidence cell contains `BRIEF §`); `done` needs `cmd → output`, a path, or a URL; never `[x]`.

### 3.4 `references/review-template.md` — portable

````
# REVIEW — <project name>
checked: pending   ← finalize-review.sh replaces: runs <r>/<required> · findings <f> (fixed <x> · accepted <a> · open <o>) · standards done <d> · N/A <n> · deferred <k> · verifiers <v>/<v> pass · branch <b> · head <sha>
written: <YYYY-MM-DD> by v2p review · reads: .v2p/EXECUTE.md (<hash, first 12>) · diff: <base>..<head>

## 1. Runs
| check | run (exact command or skill invocation) | findings |
|---|---|---|
| code-review | /review … | 3 findings |
| codex | codex review --base <sha> | 2 findings   ← or: unavailable: <reason> |
Required rows: code-review, simplify, security, verification, ux-laws, codex, qa (+ i18n when BRIEF §9 has i18n ON)

## 2. Findings
| # | check | path:line | severity | status |
|---|---|---|---|---|
| 1 | code-review | app/api/contact/route.ts:41 | high | fixed a1b2c3d |
| 2 | codex | … | low | accepted: <reason> |
Rows: <f> = sum of §1 findings counts

## 3. Standards evidence (complete)
| item | file | status | evidence |
|---|---|---|---|
| Uptime Monitoring | core.md | pending | deferred to deploy: needs the production URL |
Rows: <n> = PLAN §4

## 4. Pre-deploy
pre-deploy: pending (claude-security full scan + Strix pentest run by /v2p deploy)

Next: /v2p deploy (not available in this version)
````

### 3.5 `scripts/drift-check.sh` (~55 lines, read-only)

```
usage: sh drift-check.sh <n> [.v2p]     |  sh drift-check.sh --branch [.v2p]
exit 0 clean · 1 drift · 2 usage/no record
```
1. `d=${2:-.v2p}`; root = parent of `$d`; `cd root`. Task mode: record `$d/work/execute-task-<n>.md` must exist → `base:`, `branch:`, `tidy:` read from it. Branch mode: base/branch from `EXECUTE.md` `checked:` line if present, else from the lowest-numbered record; allowed = union over all tasks.
2. `[ "$(git rev-parse --abbrev-ref HEAD)" = "$branch" ]` else `DRIFT branch <now> (recorded <branch>)`.
3. `git merge-base --is-ancestor "$base" HEAD` else `DRIFT base <base> not an ancestor of HEAD (rebased?)`.
4. changed = `{ git diff --name-only "$base" -- .; git ls-files --others --exclude-standard; } | sort -u`.
5. allowed = Files tokens of task n (awk as measured: `awk -v n=N '$0 ~ "^### Task "n":" {f=1;next} f && /^\*\*Files:\*\*/ {sub(/\*\*Interfaces:\*\*.*/,""); print; exit}' PLAN.md | grep -o '`[^`]*`' | tr -d '`' | sed 's/ .*//; s/<[^>]*>/*/g'`) + `grep "· task $n · files += " $d/PLAN-AMENDMENTS.md` tokens + always `.v2p/*` and the lockfile names of `tidy-rules.md` §4 (verbatim list, so the existing README tidy-rules↔scripts grep check can be extended to this script).
6. Matcher — **copy verbatim; tested today, identical results under `sh` and `zsh` on the six cases below**:
```sh
match() { f=$1; p=$2; [ "$f" = "$p" ] && return 0; case $p in *\**) ;; *) return 1;; esac
  e=$(printf '%s' "$p" | sed 's/\[/\\[/g; s/\]/\\]/g'); eval "case \"\$f\" in $e) return 0;; esac"; return 1; }
```
Cases: `components/landing/x.tsx`~`components/landing/*.tsx` → match; `app/[locale]/page.tsx`~itself → match; `app/l/page.tsx`~`app/[locale]/page.tsx` → no; `app/[locale]/x/page.tsx`~`app/[locale]/*.tsx` → match (`*` crosses `/` — accepted, documented); `docs/reviews/2026-09-24-qa.md`~`docs/reviews/*-qa.md` → match; `src/other.ts`~`src/*.tsx` → no. Measured: a raw `case $f in $p)` matches the glob under `sh` but **not** under `zsh` — hence the `eval`.
7. Each changed path not matched by any allowed pattern → `DRIFT file <path>`. A directory token (`notes/`) matches by prefix (`case $f in "$p"*`).
8. Tidy: `sh <skill>/scripts/tidy-check.sh --tsv | grep -c .` > recorded `tidy:` → `DRIFT tidy +<k>` and the new rows (`comm -13` against the rows stored in the record? simpler: store the count only; print the current rows).
9. No DRIFT lines → `OK: <k> changed paths within Task <n> scope (<a> allowed by amendments)`, exit 0.

### 3.6 `scripts/task-record.sh` (~90 lines) — sole writer of `.v2p/work/execute-task-<n>.md`, its receipt `.v2p/work/.execute-task-<n>-pass`, and `.v2p/PLAN-AMENDMENTS.md`

```
usage: sh task-record.sh start|verify|manual|ponytail|allow|skip <n> [args] [.v2p]   (exit 0 ok · 1 fail · 2 usage)
```
Common: `check-pass.sh PLAN.md .plan-pass` must be OK (else exit 2: "PLAN has no valid receipt"); task `<n>` must exist (`grep -c "^### Task $n:" PLAN.md` = 1); `mkdir -p $d/work`; after every write: `shasum -a 256 record | cut -d' ' -f1 > $d/work/.execute-task-<n>-pass`.

- `start <n>`: if the record exists and its `plan:` equals `cat .plan-pass` → print `resume: task <n> (base <sha>)`, exit 0, no write. Else write:
  ```
  written: <ISO> · phase: execute · part: task-<n> · plan: <cat .plan-pass>
  task: <n> · title: <text after "### Task n: ">
  branch: <abbrev-ref> · base: <HEAD sha> · tidy: <tidy-check --tsv row count>
  files: <allowed tokens, space-separated>
  verifier: pending · attempts: 0
  ```
- `verify <n>`: `drift-check.sh <n>` → non-zero → replace `verifier:` line with `verifier: blocked by drift · attempts: <k+1>`, append the DRIFT lines under `drift:`, exit 1. Else parse the Verifier line: commands = `grep -oE '`[^`]+` *→ *`?[^`,;|]*'` (**measured on the real PLAN**: this strict "backtick immediately followed by →" rule yields 1/1/3/2/1/5/5 commands for tasks 1/3/8/9/12/13/14, and drops the prose-quoted `/es/nope`, `/.git/HEAD` that a naive backtick grep counted); manual = text after `manual:` (`none` or free text). For each command: contains `<` → `skipped: placeholder` (counts as needing `manual:`); else `sh -c "<cmd>" > out 2>&1; rc=$?`; pass iff `rc=0` **and**, when the expected text is a bare number `N` (Task 8 `→ 4`, `→ 404` — 11 such expecteds in the real PLAN), the last non-empty output line equals `N`. Write `verifier: pass|fail · attempts: <k+1> · exit <rc> · \`<cmd>\` → <last line> [; …]`, `head: <sha>`, `drift: none | allowed <a>`, `tidy-delta: 0`, and `output:` (last 20 lines, indented two spaces). Exit 0 iff every command passed.
- `manual <n> "<text>"`: text non-empty and ≠ `none` → `manual: <text> · by user · <date>`; else exit 2.
- `ponytail <n> "<text>"`: text matches `^(none|[0-9]+ findings)` → `ponytail-review: <text>`; else exit 2 with the expected shape.
- `allow <n> <path> "<reason>"`: reason non-empty → append `- <ISO> · task <n> · files += \`<path>\` · <reason>` to `$d/PLAN-AMENDMENTS.md` (create with header `# PLAN amendments — scope granted during execute (PLAN.md itself is never edited)`), and add the path to the record's `files:` line.
- `skip <n> "<reason>"`: reason non-empty → `verifier: skipped — <reason>`; `head: <sha>`.

`# ponytail:` comment in the script: "expected-output check covers exit code and bare numbers only; `→ passed`/`→ all passed` rely on the command's exit code — mapping's Verifier convention (plan-template edit) asks for self-checking commands."

### 3.7 `scripts/finalize-execute.sh` (~70 lines)

```
usage: sh finalize-execute.sh [.v2p]
1  check-pass PLAN.md .plan-pass → OK else FAIL
2  draft $d/EXECUTE.draft.md exists; has `^checked: ` line; else FAIL
3  tasks = `grep -o '^### Task [0-9]*' PLAN.md | awk '{print $3}'`; for each n: record exists; receipt matches (sha); `plan:` = cat .plan-pass; `verifier:` is `pass` or `skipped — <non-empty>`; if PLAN's Verifier line has `manual:` not followed by `none` and the task is not skipped → `manual:` line present; not skipped → `ponytail-review:` line present. FAIL lists `task <n>: <what is missing>`.
4  branch: all records' `branch:` equal, equal to `git rev-parse --abbrev-ref HEAD`; else FAIL
5  tree: `git status --porcelain | grep -v '^?? .v2p/' | grep -v '^.. .v2p/'` empty else FAIL "uncommitted: <paths>"
6  base = task 1 record's `base:`; head = HEAD; `git merge-base --is-ancestor base HEAD` else FAIL
7  §2: rows in draft §2 (awk as finalize-plan step 4) == rows in PLAN §4; item cells (2nd) sorted equal (`comm -3` empty) else FAIL listing extra/missing items; per row: status cell trimmed; `done` ⇒ evidence matches `→|/|https?://`; status starts with `N/A` ⇒ status cell or evidence cell contains `BRIEF §`; `pending` ok; anything else FAIL
8  fail → "FAIL: EXECUTE.md not written", exit 1
9  §1 generated: one row per task from its record: `| n | <base sha7>..<head sha7> | none / allowed a / — | pass · exit 0 · <cmds> / skipped — <reason> | <manual text or —> | <ponytail text or —> |`
10 write EXECUTE.md = draft with §1 body replaced and `checked:` replaced by `tasks <done>/<total> · skipped <k> · standards done <d> · N/A <a> · pending <p> · branch <b> · base <sha> · head <sha>`; rm draft
11 shasum → .execute-pass; rm -f work/execute-task-* work/.execute-task-*; echo "PASS: <done>/<total> tasks, <d> done rows -> EXECUTE.md"
```

### 3.8 `scripts/finalize-review.sh` (~75 lines)

```
1  check-pass EXECUTE.md .execute-pass → OK else FAIL
2  draft REVIEW.draft.md exists, `checked:` line
3  required = code-review simplify security verification ux-laws codex qa; BRIEF §9 line "Conditional blocks ON" contains `i18n` → + i18n. §1 rows (check cell) must contain each required name; each `findings` cell matches `^[0-9]+ findings$`, except the codex row which may match `^unavailable: .+`; `run` cell non-empty. FAIL lists missing/malformed rows.
4  §2 rows == sum of the §1 numeric findings; every status cell matches `^fixed [0-9a-f]{7,40}$|^accepted: .+|^open: .+`; each `fixed <sha>` → `git cat-file -e <sha>^{commit}` else FAIL "fix commit <sha> not found"; `open:` reason must contain `deploy` or `BRIEF §`
5  §3 rows == PLAN §4 rows, same items (comm), statuses: done ⇒ evidence regex; N/A ⇒ BRIEF §; pending ⇒ evidence starts `deferred to deploy: `; else FAIL
6  `docs/threat-model.md` exists when PLAN has `^## Threat Model` (always by finalize-plan) else FAIL
7  `^pre-deploy: pending (claude-security full scan + Strix` line present else FAIL
8  branch/head: `git rev-parse --abbrev-ref HEAD` equals EXECUTE `checked:` branch; tree clean (as 3.7 step 5)
9  verifiers: for every PLAN task not `skipped` in EXECUTE §1: run each strict-parsed mechanical command without `<` (same parser as task-record verify, factored into the script or copied — copy, 6 lines; no shared lib file); any non-zero exit → FAIL "verifier of task <n> fails after review fixes: <cmd> exit <rc>"; count v/v
10 fail → exit 1 without writing
11 write REVIEW.md with `checked:` = `runs <r>/<required> · findings <f> (fixed <x> · accepted <a> · open <o>) · standards done <d> · N/A <n> · deferred <k> · verifiers <v>/<v> pass · branch <b> · head <sha>`; rm draft; shasum → .review-pass; rm -f work/review-*; echo "PASS: …"
```

### 3.9 Edits to existing files

- **`SKILL.md`**: description "+ …then executes the plan with per-task drift checks and reviews the branch". §2 model guard: `adopt`, `scavenge`, `mapping`, `execute` or `review`. "Next" resolution: PLAN and no EXECUTE → `execute`; EXECUTE and no REVIEW → `review`; REVIEW → `deploy (not available in this version)`. §5 rows: `| execute | phases/execute.md | .v2p/EXECUTE.md (+ .v2p/PLAN-AMENDMENTS.md) | available |`, `| review | phases/review.md | .v2p/REVIEW.md | available |`. §6: templates at their phases; `ux-laws.md` "at review"; claude-only scripts list + `drift-check.sh`, `task-record.sh`, `finalize-execute.sh`, `finalize-review.sh`. `grep -c 'not available in this version'` becomes **2** (deploy row + the sentence) — README verify line updated.
- **`phases/mapping.md`** Step 5: `Next: /v2p execute` (drop the parenthesis; `finalize-plan.sh` greps `^Next: /v2p execute` — still passes); delete "Do not ask how to execute the plan"; add: "Verifier convention: prefer self-checking commands (`test "$(cmd)" = 4`, `grep -q`, `set -e` chains) — execute treats exit 0 as pass and only compares bare-number expecteds." Step 4 §5: "a review task or a launch task does not belong in §5 (review and deploy are phases)". (Reference: the real PLAN's Tasks 13–14.)
- **`references/plan-template.md`**: `Next: /v2p execute`; Verifier line comment as above.
- **`references/model-routing.md`**: rows `execute` and `review` replace `(stub)` (text from §2 "Model routing"); "Drift checks" section retitled `## Drift checks — built in slice 4` with the concrete table of §4; note "`ponytail-audit` = repo-wide, `ponytail-review` = diff (measured 2026-09-24)". `grep -c '(stub)'` → **1** (deploy).
- **`references/skills-catalog.md`**: Code review row: add `ponytail-review` (diff) beside `ponytail-audit` (repo) with the measured description; `/simplify` fallback = `ponytail-review`. Execute row: status "execute phase (slice 4): SDD + extras; `executing-plans` for inline; `test-driven-development`; `using-git-worktrees`". Security row: `claude-security` 0.11.0 enabled — agents only (`agents/claude-security.md`), invocation `(unverified)`; `/security-review` built-in `(unverified)`. Testing row: `/qa` at review.
- **`hooks/guard-finals.sh`**: add `EXECUTE.md`, `REVIEW.md`, `PLAN-AMENDMENTS.md` to both `case` lists and the Bash regex (`(SCAVENGE|AUDIT|PLAN|EXECUTE|REVIEW|PLAN-AMENDMENTS)`). Still not installed.
- **`build-portable.sh`**: after `references/tidy-rules.md` insert `phases/execute.md phases/review.md references/execute-template.md references/review-template.md`.
- **`README.md`**: phases table (execute → `.v2p/EXECUTE.md` available; review available); file map +10 rows; verify block +4 lines (§6 checks 1, 3, 9, 11).
- **`docs/ROADMAP.md`**: "## Slice 4: execute + review (built <date> · <sha> · live test pending)" with the trigger table of §4; correct "ponytail-audit on the diff"; keep Strix/claude-security full scan under slice 5.

***

## 4. Tiered cadence → concrete triggers

| Tier | Trigger (who runs it, when) | What runs | Evidence it leaves | Gate that refuses without it |
|---|---|---|---|---|
| every task | main thread, after the implementer reports and before commit | `task-record.sh verify <n>` (= `drift-check.sh <n>` + verifier commands + tidy delta + branch check) | record lines `drift:`, `verifier:`, `output:` + receipt | `finalize-execute.sh` step 3 |
| every task | task reviewer dispatch (SDD) or main thread (inline) | `ponytail-review` on `git diff <base>..HEAD` | `ponytail-review:` line via `task-record.sh ponytail` | `finalize-execute.sh` step 3 |
| every task | implementer, inside the task | `superpowers:test-driven-development` (red → green) | the verifier's own test files in the commit | reviewer prompt (SDD) — not scripted |
| every phase (execute end) | main thread before `finalize-execute.sh` | `verification-before-completion` + extras on §2 rows | corrected rows | `finalize-execute.sh` step 7 (shape only) |
| every phase (review) | review Step 1, once over `<base>..HEAD` | `/review` (+extras), `ponytail-review` → `ponytail-audit`, `claude-security` (+`/security-review` if present), `translation-quality` (i18n ON), ux-laws + `/design-review`, `/qa`, `/codex review` | `.v2p/work/review-<check>.md`, REVIEW §1 rows, §2 findings with fix shas | `finalize-review.sh` steps 3–4, 9 (re-runs verifiers) |
| before deploy | slice 5 | `claude-security` full scan + Strix | — | REVIEW §4 line is the hand-off; deploy will require `.review-pass` |

"Every phase" is realised once per execute→review cycle; re-entering execute after review (new tasks) re-runs the task tier and a new review re-runs the phase tier — `finalize-review` refuses a REVIEW draft whose `head:` is not the current HEAD, so a stale review cannot be finalised.

***

## 5. Tests

**`tests/fixture-execute.sh <dir>`** (~30 lines): `git init`, `.gitignore` with `.v2p/work/` and `.v2p/*.draft.md`, `README.md`, `CHANGELOG.md`, `docs/{ARCHITECTURE,DECISIONS}.md` (so tidy = 0), `src/hello.sh` (`printf ok`), `.v2p/BRIEF.md` copied from `tests/fixtures/finalize-plan/BRIEF.md` (landing), `.v2p/PLAN.md` with `## Architecture`, `## Threat Model`, §4 rows generated from the live standards exactly as `test-finalize-plan.sh` does (`{{STANDARDS_ROWS}}`), `## 4b`, and three tasks:
- Task 1 `**Files:** Create: \`src/greet.sh\`, \`tests/greet.test.sh\`  **Interfaces:** …` · `**Verifier:** mechanical: \`sh tests/greet.test.sh\` → exit 0   |   manual: none`
- Task 2 `**Files:** Modify: \`src/*.sh\`, \`app/[locale]/page.tsx\`` · `**Verifier:** mechanical: \`sh -c 'grep -c hi src/greet.sh'\` → 1   |   manual: the user opens it`
- Task 3 `Review phase` · `**Verifier:** manual: …`
Then `## 6. Handoff` + `Next: /v2p execute`, one commit, receipt written with `shasum -a 256 .v2p/PLAN.md | cut -d' ' -f1 > .v2p/.plan-pass` (same bytes finalize-plan would write).

**`tests/test-execute.sh`** runs for `SH in sh zsh` in `${TMPDIR:-/tmp}/v2p-ex.$$` and asserts (every step names its falsifier):
1. `task-record.sh start 1` → record exists, `plan:` = receipt, `base:` = HEAD, receipt file sha matches; exit 0. Falsifier: corrupt `.plan-pass` → exit 2, no record.
2. `drift-check.sh 1` on a clean tree → `OK: 0 changed paths`, exit 0.
3. Create `src/greet.sh` + `tests/greet.test.sh` (test prints `hi` check) → `drift-check.sh 1` → OK; create `stray.txt` → `DRIFT file stray.txt`, exit 1; `task-record.sh verify 1` → record `verifier: blocked by drift`, exit 1. Remove `stray.txt`.
4. `verify 1` with a failing test → `verifier: fail · attempts: 2 · exit 1`, exit 1; fix → `verifier: pass · attempts: 3`, exit 0; `output:` block present.
5. `git switch -c other` → `drift-check.sh 1` → `DRIFT branch other (recorded main)` (or `master`), exit 1; switch back.
6. `task-record.sh allow 1 docs/notes.md "reviewer asked for a note"` → amendments file has the line; create `docs/notes.md` → `drift-check.sh 1` OK.
7. `ponytail 1 "junk"` → exit 2, record unchanged (sha equal); `ponytail 1 "none"` → line present.
8. Commit; `start 2`; modify `src/greet.sh`, create `app/[locale]/page.tsx` → `drift-check.sh 2` OK (bracket path via string equality); create `app/l/page.tsx` → DRIFT (falsifier for the bracket escape). `verify 2` → bare-number expected `1`: command prints `1` → pass; falsifier: make the file contain `hi` twice → last line `2` → `verifier: fail` although exit 0.
9. `manual 2 ""` → exit 2; `manual 2 "opened, saw hi"` → line present. Commit.
10. `finalize-execute.sh` with no record for task 3 → `FAIL … task 3: no record`; `skip 3 "handed to /v2p review"` → then draft missing → FAIL; write `EXECUTE.draft.md` from the template with §2 = PLAN §4 rows → FAIL only if a row is malformed: falsifiers `| x | core.md | done | |` → "done without evidence", `| x | core.md | N/A | nothing |` → "N/A without BRIEF §", one row deleted → "rows n-1/n", one item renamed → "items differ"; dirty tree (`echo x >> README.md`) → FAIL "uncommitted"; clean + correct → `PASS`, `EXECUTE.md` §1 has 3 rows (`skipped — handed to /v2p review` on row 3), `checked: tasks 2/3 · skipped 1 …`, `.execute-pass` = sha, `work/execute-task-*` gone, `PLAN-AMENDMENTS.md` kept.
11. `echo x >> .v2p/EXECUTE.md; check-pass.sh .v2p/EXECUTE.md .v2p/.execute-pass` → `FAIL … changed after finalize`.
12. `sh` vs `zsh`: the generated `EXECUTE.md` bodies (minus dates/shas) `cmp` equal.

**`tests/fixtures/finalize-review/REVIEW.md`** — deliberately bad: §1 missing `security` and `qa` rows, codex row `findings: some`, §2 a `fixed deadbeef` sha, §3 a `pending` row without `deferred to deploy:`, no `pre-deploy:` line, `---` rule. **`tests/test-finalize-review.sh`** (on the execute fixture after a PASS of step 10, plus `docs/threat-model.md` created): original → FAIL naming all six; fix one at a time (add rows; `2 findings`; replace the sha with `git rev-parse HEAD`; `deferred to deploy: needs prod URL`; add the line; `***`) → each FAIL disappears; final → `PASS`, `checked: runs 7/7 · … · verifiers 2/2 pass`; falsifier for step 9: break `src/greet.sh` → `FAIL: verifier of task 1 fails after review fixes`; i18n falsifier: set BRIEF §9 `Conditional blocks ON: i18n` → FAIL "missing i18n row" until added.

***

## 6. Verification checklist (from the project dir; expected output; falsifier per structural check)

1. Router: `grep -cE '^\| `(execute|review)` \| `phases/(execute|review)\.md` \| .*\| available' skills/v2p/SKILL.md` → 2; `grep -c 'not available in this version' skills/v2p/SKILL.md` → 2. Falsifier: `available`→`planned` in a scratch copy → 1.
2. Referenced paths (slice-1 check 2) over the two new phases, two templates, `scripts/[a-z-]+\.sh` → no `MISSING`. Falsifier: reference `scripts/nope.sh` in scratch → `MISSING` once.
3. Script tests: `sh tests/test-execute.sh` → `test-execute: 0 failures`; `sh tests/test-finalize-review.sh` → `0 failures`; `sh tests/test-finalize-plan.sh` and `sh tests/test-tidy.sh` still 0 failures (mapping/plan-template edits must not break `^Next: /v2p execute`).
4. Zsh safety: `grep -nE 'for [a-z]+ in \$[a-z]|case \$[a-z]+ in \$[a-z]' skills/v2p/scripts/*.sh` → only the pre-existing `finalize-scavenge.sh` line 11. Falsifier: add `case $f in $p)` to a scratch copy → listed.
5. Syntax: `for s in skills/v2p/scripts/*.sh skills/v2p/hooks/*.sh tests/*.sh; do sh -n "$s" && zsh -n "$s"; done` → no output.
6. Lockfile list ↔ scripts: the README tidy-rules grep check extended to `drift-check.sh` → no `UNMATCHED`.
7. Receipts wiring: `grep -c 'execute-pass' skills/v2p/scripts/finalize-execute.sh skills/v2p/phases/review.md` → ≥1 each; `grep -c 'review-pass' skills/v2p/scripts/finalize-review.sh` → 1; `grep -c 'check-pass.sh' skills/v2p/phases/execute.md skills/v2p/phases/review.md` → ≥1 each.
8. Hook offline falsifiers (as slice-3 check 11) with `/p/.v2p/EXECUTE.md` → 2, `EXECUTE.draft.md` → 0, `"command":"echo x >> .v2p/PLAN-AMENDMENTS.md"` → 2, `"command":"sh skills/v2p/scripts/task-record.sh allow 1 x y"` → 0.
9. Portable build: `sh build-portable.sh`; `grep -c '<!-- source: phases/\(execute\|review\)\.md -->' dist/v2p-portable.md` → 2; `grep -c 'execute-template\|review-template' dist/…` ≥ 2; `grep -c 'AskUserQuestion\|claude-only\|task-record\|drift-check\|finalize-execute\|finalize-review\|subagent_type' dist/…` → 0; copyright count 1; size reported (expect < 175,000 bytes; slice 3 measured under 160,000). Rebuild to temp + `diff` → empty.
10. `***` / copyright / no frontmatter on new `.md` (as slice-3 check 8).
11. model-routing: `grep -c '(stub)' skills/v2p/references/model-routing.md` → 1; `grep -c 'ponytail-review' skills/v2p/references/model-routing.md skills/v2p/references/skills-catalog.md` → ≥1 each.
12. Real-PLAN parse (no live session needed): the Files awk of §3.5 over `personal_skills/v2p/.v2p/PLAN.md` tasks 1–14 → token counts 10 9 16 7 11 5 8 7 17 10 7 7 8 4 (measured today); the strict verifier grep → tasks 1/3/8/9/12/13/14 = 1/1/3/2/1/5/5. Falsifier: remove the `→` after a command in a scratch copy → count drops by one.
13. Live test (user, fresh session, on a copy of `personal_skills/v2p` — never the real one): `/v2p execute` → probe + `OK: .v2p/PLAN.md matches its receipt`, dirty-tree refusal if applicable, the worktree/branch question, preflight lists Task 1's subdirectory defect and asks about Tasks 13–14, then `task-record.sh start 1` visible in the transcript, an SDD dispatch containing the drift sentence, `verify 1` output, one commit with the branch check in the same command, `ponytail-review:` line. Falsifiers: `echo x >> .v2p/PLAN.md` before start → `PLAN.md failed its check`; create `stray.txt` during Task 1 → the implementer/controller reports `DRIFT file stray.txt` and no commit lands until it is removed or allowed; end the session mid-task and re-run → "resuming: tasks …" with the same `base:`.
14. Live review: `/v2p review` after a finalised EXECUTE → the seven Runs rows appear with `run:` invocations, `/codex review` either produces findings or `unavailable: <reason>`; `finalize-review.sh` re-runs the verifiers (transcript shows the commands); `.v2p/REVIEW.md` `checked:` has `verifiers n/n pass`; then `/v2p deploy` → "not available in this version".

***

## 7. Open questions for the user (each changes the design; recommended option first)

1. **Execution default.** (a) `subagent-driven-development` + extras, implementer `builder`/`quick`, reviewer `planner` **(Recommended: fresh context per task and a reviewer that cannot write; costs one dispatch pair per task)**; (b) inline `executing-plans` on the main thread, one final review. The phase file supports both; the default sets which the router offers first and what model-routing's execute row says.
2. **Commit per task automatically?** (a) Yes: the implementer commits after `verify` passes, branch check in the same command, on the v2p branch/worktree only **(Recommended: SDD's own order; finalize needs a clean tree; nothing touches `main`)**; (b) the controller shows the diff and asks before every commit (one `AskUserQuestion` per task — slows a 14-task plan to 14 stops).
3. **Where execute works.** (a) Worktree via `using-git-worktrees` when `.v2p/PLAN.md` is tracked; else a branch in place **(Recommended: matches your CLAUDE.md worktree rule; needs `.v2p/` committed, which the router already recommends)**; (b) always a branch in the current checkout (simpler; a parallel session switching the checkout is caught by `DRIFT branch`, not prevented).
4. **Codex.** (a) `/codex review` runs in review when the skill's own auth probe passes; otherwise the row records `unavailable: <reason>` and the phase continues **(Recommended: keeps the "Claude everywhere, Codex review-only" decision without making review depend on an OpenAI login)**; (b) Codex row mandatory (finalize refuses `unavailable`); (c) drop Codex from v2p.

***

## 8. Risks, pushback, unverified

- **`/security-review` and `/simplify` built-ins `(unverified)`**: `claude` is a shell function here (`type claude`), Claude Code 2.1.281; I could not grep the binary. The design never depends on them; the builder checks `/help` once and records the answer in skills-catalog.
- **`claude-security` invocation `(unverified)`**: plugin 0.11.0 enabled, ships `agents/` and `hooks/` only (no `commands/`, no `skills/`); the README describes effort tiers. review.md says "invoke the plugin's scan at its lowest tier; full tier is deploy's" — exact wording to be fixed by the builder after one dry run.
- **Codex auth `(unverified)`**: binary present; the gstack skill probes auth/model in Step 0.5.
- **The ponytail line is the weakest gate**: it checks shape (`N findings`), not that the skill ran. Truth comes from the SDD reviewer report; say so in execute.md rather than pretending.
- **Evidence rows are model-written**: the finalize gates check shape (command + output present), not truth; review Step 1 "verification" re-runs each cited command, and `finalize-review.sh` step 9 re-runs every PLAN verifier — those two are the truth checks. A fabricated `→ output` survives execute but not review.
- **`finalize-review.sh` re-running verifiers** may take minutes and needs whatever the commands need (the real PLAN's e2e starts its own preview server via Playwright `webServer`; `curl http://localhost:8787` lines rely on it running — Task 8's two curl commands would fail outside an e2e run). Mitigation: the strict parser skips `<placeholder>` commands only; the builder should confirm on the fixture that a `curl localhost` verifier fails loudly rather than hangs (`curl -m` is the PLAN author's job — mapping convention note).
- **Real PLAN defects the preflight must surface** (measured): Task 1 scaffolds into `grooming-landing/`; Tasks 13–14 are deploy/review work inside §5; 6 placeholder commands in Task 13, 3 in Task 12, 1 in Task 14; `next/font` appears as a Files token (harmless over-allow). These are mapping-template issues; this slice handles them at execute time and proposes the mapping edits in §3.9.
- **`git diff <base>` after a rebase**: base no longer an ancestor → `DRIFT base`; recovery = `task-record.sh start <n>` cannot reset base without losing the scope diff, so the phase file says "do not rebase the v2p branch during execute".
- **Worktree + `.v2p/work/`**: gitignored, so records live in the worktree; finalize clears them; EXECUTE.md travels with the branch. If the user picks (b) in Q3, nothing else changes.
- **`*` crosses `/` in the matcher** (measured): `components/landing/*.tsx` also allows `components/landing/x/y.tsx`. Accepted; documented in drift-check's header.
- **Hook proposal** gains three file names; still uninstalled; subagent hook firing still `(unverified)` (slice-3 live test 6).
- **Portable pack** grows by ~4 files; size cap is a measured number (check 9), not a limit.
- **Not verified**: any script run end-to-end (no prototype built this session — the two behaviours that decide correctness, the Files/Verifier parse on the real PLAN and the sh/zsh glob matcher, were measured; the rest follows the tested `finalize-plan.sh`/`finalize-audit.sh` shapes verbatim); live sessions (checks 13–14).

Relevant absolute paths: `/Users/user/SynologyDrive/code/ai/claude/Projects/personal_skills/vibe-to-product/skills/v2p/SKILL.md`, `…/skills/v2p/phases/{mapping,adopt,scavenge}.md`, `…/skills/v2p/references/{plan-template,model-routing,skills-catalog}.md`, `…/skills/v2p/references/standards/core.md` (evidence rule, lines 5–16), `…/skills/v2p/scripts/{check-pass,finalize-plan,finalize-audit,finalize-scavenge,tidy-check}.sh`, `…/skills/v2p/hooks/guard-finals.sh`, `…/tests/test-finalize-plan.sh`, `…/tests/fixtures/finalize-plan/{BRIEF,PLAN}.md`, `…/build-portable.sh`, `…/README.md`, `…/docs/ROADMAP.md`, `…/docs/specs/slice-{2,3}-spec.md`; real PLAN `/Users/user/SynologyDrive/code/ai/claude/Projects/personal_skills/v2p/.v2p/PLAN.md` (1287 lines, 14 tasks, receipt `0eed0bc4…` matches); machine state: `/Users/user/.claude/plugins/installed_plugins.json` (superpowers 6.4.1, ponytail 4.9.0, claude-security 0.11.0), `/Users/user/.claude/plugins/cache/claude-plugins-official/superpowers/6.4.1/skills/{subagent-driven-development,executing-plans,verification-before-completion,test-driven-development,using-git-worktrees}/SKILL.md`, `/Users/user/.claude/plugins/cache/ponytail/ponytail/4.9.0/skills/{ponytail-review,ponytail-audit}/SKILL.md`, `/Users/user/.claude/skills/{codex,review,qa,qa-only,design-review,translation-quality,subagent-driven-development-extras,verification-before-completion-extras,requesting-code-review-extras,gstack-extras}/SKILL.md`, `/Users/user/.claude/agents/{builder,quick,planner}.md`, `/Users/user/.local/bin/codex`; plugins `code-review` and `code-simplifier` cached-disabled; `~/.claude/commands/code-review.md` (ECC) exists.
***
## 9. User decisions (2026-09-24)

1. Execution default: subagent-driven-development + extras (implementer builder/quick, reviewer planner).
2. Auto-commit per task after verify passes, branch check in the same command, v2p branch/worktree only.
3. Worktree via using-git-worktrees when .v2p/PLAN.md is tracked; else a branch in place.
4. Codex: /codex review runs when its auth probe passes; otherwise the Runs row records `unavailable: <reason>` and review continues.

***
Copyright © 2026 Rafael Arciniegas. Licensed under the MIT License.
