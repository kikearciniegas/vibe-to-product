# v2p phase: execute

## Purpose
Implement `.v2p/PLAN.md` task by task with a scope gate, a verifier record and a commit per task; fill the standards evidence as tasks earn it. Writes `.v2p/EXECUTE.md` (and `.v2p/PLAN-AMENDMENTS.md` when scope changes).
The execution loop itself belongs to a plan-execution method (superpowers in Claude Code); v2p adds the gates around it.

## Preconditions
- `.v2p/PLAN.md` must have passed mapping's finalize step. Portable: it contains the line `Next: /v2p execute`. Otherwise print `PLAN.md failed its check: re-run /v2p mapping.` and stop.
<!-- claude-only -->
  In Claude Code this check is a script: `sh <this skill's dir>/scripts/check-pass.sh .v2p/PLAN.md .v2p/.plan-pass` must print `OK`. A PLAN.md edited after finalize fails, even if its text looks right.
<!-- /claude-only -->
- Existing `.v2p/EXECUTE.md` with its receipt → offer: resume (go to `/v2p review`) or re-run.
- `.v2p/PLAN-AMENDMENTS.md`, if present: read it. Every line in it is scope already granted. PLAN.md itself is never edited during execute.
<!-- claude-only -->
- Records: list `.v2p/work/execute-task-*.md`. A record is reusable when its `plan:` value equals the content of `.v2p/.plan-pass` (not "today": execution spans days). Print `resuming: tasks <list> done, <list> started` and continue from the first task whose record has no `verifier: pass`. A record with another `plan:` is stale; `task-record.sh start` overwrites it. `.v2p/work/` records are the only resume source.
<!-- /claude-only -->
- Model guard (router §2).

## Step 0 — Git safety
- Tracked changes outside `.v2p/` (`git status --porcelain`, ignoring `??` lines and `.v2p/` paths) → print the paths and "Commit or discard these yourself; v2p never stashes or commits another session's changes." Stop.
- Clean tree → choose where to work. `.v2p/PLAN.md` tracked in git (`git ls-files --error-unmatch .v2p/PLAN.md` succeeds) → a new worktree on a new branch, so the handoff files travel with the branch. Not tracked → a new branch in place: `git switch -c v2p/execute-<YYYY-MM-DD>`. Never work on the default branch.
- Do not rebase the execute branch while execute runs: each task's scope is measured from its recorded base commit.
- Portable: tell the user to create the branch and confirm before Step 1.
<!-- claude-only -->
Claude Code: the worktree is created through `superpowers:using-git-worktrees` (SDD's own setup step); ask once with `AskUserQuestion` ("Worktree on a new branch (Recommended) / Branch in this checkout"), the recommendation following the tracked/untracked rule above. Record nothing yet: `task-record.sh start` captures the branch and base.
<!-- /claude-only -->

## Step 1 — Preflight (before Task 1)
The scan executes; it is not skipped because the plan looks fine.
1. Copy PLAN §4 into `.v2p/EXECUTE.draft.md` using `references/execute-template.md` (statuses and N/A reasons kept, evidence empty).
2. Run the plan's empirical claims: every mechanical Verifier command that can run on the current tree is expected to FAIL now (red before green). A verifier that passes before its task exists is a plan defect: record a ruling in the execution ledger and tell the user.
3. Scope sanity: a task whose steps `cd` into a new directory (for example a scaffold command that creates a subfolder), or whose Files are outside the project root, is a plan defect. Ruling: scaffold into `.` (adapt the command) or stop and ask.
4. Task triage: a task whose title starts with `Review`, or whose Verifier needs production URLs or DNS (`<domain>`-style placeholders in every command), is not executed here. List them in one question and, only on the user's yes, mark each skipped with the reason `handed to /v2p review` or `handed to /v2p deploy`.
<!-- claude-only -->
   Claude Code: one `AskUserQuestion` listing them; on yes, `sh <this skill's dir>/scripts/task-record.sh skip <n> "handed to /v2p review"` (or `"handed to /v2p deploy"`) per task.
<!-- /claude-only -->

## Step 2 — Task loop
Order: PLAN §6 `Order:` line. Independent tasks run in parallel only through the execution method's own fan-out rules. Per task `<n>`:
1. Start the task record (base commit, branch, tidy count).
2. Implement with test-driven development: failing test first, then the code. Change only the files in the task's **Files:** list. A needed path outside it is reported with the reason, never touched first.
3. A reported path: decide. Granted → record the amendment (path + reason) before touching it. Refused → revert it.
4. The implementer commits once its own tests pass, on the execute branch only, with the branch check in the same command.
5. Then, against the committed head, check the changed files (`git diff --name-only <base>`) against the task's **Files:** list and run the task's Verifier commands; record the observed output. A failure → fix commit(s) on the same branch (a fix round, back to step 2), then verify again. A server the check needs runs on a private port (e.g. `-p 31<nn>`) and is stopped by the PID this session saved; never `lsof -ti:<port> | xargs kill` (the live run did that 15 times on the shared port 3000).
6. Manual part of the Verifier not `none` → ask the user what they saw, where and when; record their words, attributed to them.
7. Task review, including an over-engineering pass on the task's diff (`git diff <base>..HEAD`); record its result in one line: `none` or `<k> findings, <a> applied, <d> deferred, <r> rejected: <one line>` with a + d + r = k (applied = changed in this task's commits; deferred = left for a named later task or review; rejected = not a problem, reason in the line).
8. Standards rows this task satisfies (PLAN §4 rows the task names, or rows whose evidence hint the verifier output covers): set `done` in `EXECUTE.draft.md` §2 with evidence = the command and its observed output from this run, or a path or URL. Never `[x]`.

Portable: you run the loop yourself. After each task print one row (`task | files changed | verifier command → output the user pasted | manual observation | commit`) and ask the user to run the verifier commands and paste the output; that paste is the evidence. There is no scope gate or receipt without the scripts; say so once.
<!-- claude-only -->
Claude Code, per task `<n>` (the numbers match the steps above):
1. `sh <this skill's dir>/scripts/task-record.sh start <n>` → writes `.v2p/work/execute-task-<n>.md` + its receipt. A current record prints `resume: task <n> (base <sha>)` and keeps the base. `start` runs before dispatching the implementer; if it was missed, recover with `start <n> --base <pre-dispatch sha> "<reason>"` (audited in PLAN-AMENDMENTS.md; verifier, manual and ponytail lines must be re-earned), never by editing the record.
2. Dispatch the SDD implementer prompt to `builder` when the task's Files include code, `quick` when every Files token is under `docs/` or ends in `.md` (Agent tool with `subagent_type`; never pass a model). Append these lines to the prompt: "Change only the files in this task's `**Files:**` list. If you must touch another path, stop and report the path and why; do not touch it. Run `sh <this skill's dir>/scripts/drift-check.sh <n>` before you commit. Commit only with the branch check in the same command (below). Use `superpowers:test-driven-development` for every step that writes code." The commit command:
   `[ "$(git rev-parse --abbrev-ref HEAD)" = "$(sed -n 's/^branch: \([^ ]*\) .*/\1/p' .v2p/work/execute-task-<n>.md)" ] && git add -A && git commit -m "<type>: <task title>"`
   Inline mode (`superpowers:executing-plans`, only when the user chose it): the main thread follows the same lines.
3. Granted path: `sh <this skill's dir>/scripts/task-record.sh allow <n> <path> "<reason>"` (appends to `.v2p/PLAN-AMENDMENTS.md`; nothing else writes that file or PLAN.md).
4. The implementer commits with the one-liner above, after its own tests pass (`git add -A` is safe only because `drift-check` passed first). The controller checks `git log -1 --format=%H` differs from the base afterwards. Commits are automatic (user decision): no confirmation per task.
5. `sh <this skill's dir>/scripts/task-record.sh verify <n>` against the committed head → runs `drift-check.sh <n>` (files changed in `base..HEAD` plus anything uncommitted, branch, base, tidy delta), then every mechanical Verifier command; writes `verifier:`, `head:`, `drift:`, `output:`. Exit 1 → the implementer adds fix commit(s) with the same one-liner, then `verify` again.
6. `AskUserQuestion` for the observation, then `sh <this skill's dir>/scripts/task-record.sh manual <n> "<their words>"`. Evidence the controller gathered itself goes in `task-record.sh note <n> "<what ran, what it showed>"` (stamped `by controller`), never in `manual`, which stamps `by user`.
7. Dispatch the SDD task-reviewer prompt to `planner` (read-only) with one extra line: "Also load the `ponytail-review` skill on `git diff <base>..HEAD` and report its findings as a separate list." Then `sh <this skill's dir>/scripts/task-record.sh ponytail <n> "<k> findings, <a> applied, <d> deferred, <r> rejected: <one line>"` (or `"none"`; the script checks a + d + r = k), after `verify` passes: it also records `head:`, so the task's range is `base..head`. This line is the weakest gate: the script checks its shape, not that the skill ran; the reviewer's report is the truth.
8. Cite the record's `verifier:` line verbatim as evidence where it proves the row.
<!-- /claude-only -->

## Step 3 — Failing verifier
Inside a task the implementer iterates test-first; the execution method's fix rounds apply (at most 5). The verifier may be re-run any number of times; the last run wins and the attempt count is kept. After 3 failed runs on one task: stop and debug systematically. If the verifier itself is wrong, that is a plan defect: record a ruling in the execution ledger and mark the task skipped with the reason only on the user's yes; never "fix" the verifier (PLAN.md is hash-locked). A skip is never silent: it needs the user's yes and the reason is printed in EXECUTE.md §1. A verifier that needs a credential this session lacks (a token, a dashboard login) is deferred, not skipped: on the user's yes, record `deferred — <credential>`; EXECUTE.md §1 lists it with the credential and `/v2p deploy` re-checks it.
A gate that refuses or blocks is a stop-and-ask, including when the gate itself looks wrong: show the user its output and wait. Never hand-write a record or receipt, and never alter a verifier command, to get past it.
<!-- claude-only -->
Claude Code: SDD's "rulings, not stalls" does not cover verifier skips: a skip needs the user's yes (above). A deferral: `sh <this skill's dir>/scripts/task-record.sh defer <n> "<credential>"`.
Claude Code: when any v2p script refuses or blocks (`drift-check.sh`, `task-record.sh`, `finalize-*.sh`), stop and report to the user with the script's output verbatim. Never write, edit or seal `.v2p/work/` records or any `.v2p/.*-pass` / `.v2p/work/.*-pass` file by hand (Write/Edit, `>`, `shasum … >`): a tool defect is fixed in the tool, not worked around in the records.
Claude Code: load `superpowers:systematic-debugging` + `systematic-debugging-extras`. A task listed in PLAN §6 as `/ralph-loop` eligible may run as `/ralph-loop "sh <this skill's dir>/scripts/task-record.sh verify <n>" --max-iterations 5`; the verify script is the loop's verifier. Never without `--max-iterations`.
<!-- /claude-only -->

## Step 4 — Finalize
Before finalizing, check each `done` row in the draft: a green result is evidence about the check's reach, not about the item. Portable: write `.v2p/EXECUTE.md` from the draft as the template says (fill §1 yourself; say there is no receipt).
<!-- claude-only -->
Claude Code: `superpowers:verification-before-completion` + `verification-before-completion-extras` on the §2 evidence rows, then `sh <this skill's dir>/scripts/finalize-execute.sh .v2p` until it prints `PASS`. It requires a sealed record for every PLAN task (pass, skipped with a reason, or deferred with the credential; `manual:` and `ponytail-review:` where due), one branch equal to HEAD's, a clean tree outside `.v2p/`, and §2 with the same items as PLAN §4 (`done` ⇒ evidence, `N/A` ⇒ `BRIEF §`). It generates §1 from the records, writes `EXECUTE.md` + the receipt `.v2p/.execute-pass`, and clears `.v2p/work/execute-*`. Never write `EXECUTE.md` by hand.
<!-- /claude-only -->

## Step 5 — Hand off
Print the path of `.v2p/EXECUTE.md`, tasks done/skipped, standards done/N-A/pending counts, the branch and `base..head`, the amendments count, then `Next: /v2p review`.

<!-- claude-only -->
## Claude Code note
- Execution default (user decision): `superpowers:subagent-driven-development` + `subagent-driven-development-extras`, loaded in the same turn; read the `fan-out.md` reference of `subagent-driven-development-extras` before any parallel dispatch. Inline `superpowers:executing-plans` only when the user asks for it.
- SDD keeps its own ledger (`progress.md` in its workspace) for rulings on plan defects; v2p's records are not a second ledger. They hold what SDD's ledger does not: the scope diff, the verifier's observed output, the user's manual observation, the ponytail-review line.
- Agents: implementer `builder` (code) or `quick` (docs-only Files); task reviewer `planner`. Invoke by name; never pass a model (`references/model-routing.md`).
- `superpowers:test-driven-development` in every implementer dispatch.
- context7 for any API contract a task relies on (core.md "API Contract Verification" evidence). `claude-mem:learn-codebase` is optional and never a source of findings.
- Hooks: `hooks/guard-finals.sh` (proposal, not installed) also blocks direct writes to `EXECUTE.md`, `REVIEW.md`, `PLAN-AMENDMENTS.md`, the `.v2p/work/execute-task-*.md` records and every `.*-pass` seal.
<!-- /claude-only -->

***
Copyright © 2026 Rafael Arciniegas. Licensed under the MIT License.
