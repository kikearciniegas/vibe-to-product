# v2p phase: review

## Purpose
Review the whole execute branch once with the phase-level checks, fix what they find, complete the standards evidence, and hand a receipt to deploy. Writes `.v2p/REVIEW.md`.

## Preconditions
- `.v2p/EXECUTE.md` must have passed execute's finalize step. Portable: it has a `checked:` line that is not `pending`. Otherwise print `Run /v2p execute first.` and stop.
<!-- claude-only -->
  In Claude Code this check is a script: `sh <this skill's dir>/scripts/check-pass.sh .v2p/EXECUTE.md .v2p/.execute-pass` must print `OK`.
<!-- /claude-only -->
- Existing `.v2p/REVIEW.md` with its receipt → offer: resume (keep) or re-run.
- Clean tree and HEAD on the branch named in the EXECUTE `checked:` line (`branch <b>`); otherwise print what differs and stop.
- Model guard (router §2).
- Checkpoints: `.v2p/work/review-<check>.md` is reusable when its line 1 `head:` equals the current `git rev-parse HEAD`; otherwise it is stale: overwrite it, never read it.

## Step 0 — Scope
`base` and `branch` come from the EXECUTE `checked:` line; the diff under review is `git diff <base>..HEAD`. A file changed on the branch that no PLAN task names (and no amendment grants) is finding #1.
<!-- claude-only -->
Claude Code: `sh <this skill's dir>/scripts/drift-check.sh --branch .v2p` (changed set against the union of every task's Files list plus `.v2p/PLAN-AMENDMENTS.md`).
<!-- /claude-only -->

## Step 1 — Runs
Each check writes a checkpoint first (line 1: `head: <sha> · check: <name> · run: <exact invocation>`, then one finding per line: `- <path:line> · <severity> · <one line>`), then one row in REVIEW.draft.md §1 (`references/review-template.md`).

| check | what runs | on | required |
|---|---|---|---|
| code-review | a code review of the branch diff | the diff | always |
| simplify | an over-engineering review of the diff, then of the whole repo | diff, then repo | always |
| security | a security review of the diff | the diff | always |
| verification | re-run the command cited by every `done` row of EXECUTE §2; output that no longer matches is a finding | evidence table | always |
| ux-laws | `references/ux-laws.md` checks plus a visual design review of the running preview against `.v2p/DESIGN.md` (frontmatter tokens are normative: a value in the token map is never a finding; a departure names the token) | UI | always (every profile has UI) |
| i18n | a translation-quality pass on the locale files named in PLAN | locale files | only when BRIEF §9 `Conditional blocks ON` contains `i18n` |
| codex | an independent second-opinion review of the diff (read-only; it never edits) | the diff | always; may be `unavailable: <reason>` |
| qa | a QA pass on the preview URL; re-checks after fixes | running app | web profiles; native-app: `manual: <who ran what on which device>` |

Portable: run each check yourself, as a separate pass with its own list; the codex row reads `unavailable: portable` unless the user pastes a second model's review.
<!-- claude-only -->
Claude Code invocations (verified on this machine 2026-09-24, see `references/skills-catalog.md`):
- code-review: gstack `/review` + `requesting-code-review-extras` (main thread).
- simplify: the Claude Code built-in `/simplify` on the branch diff (it applies fixes: each one becomes a fix commit under Step 2's rules), then the `ponytail-review` skill on `git diff <base>..HEAD`, then `ponytail-audit` on the repo (plugin `ponytail@ponytail` 4.9.0). `ponytail-review` = diff, `ponytail-audit` = whole repo.
- security: the Claude Code built-in `/security-review` (reviews the pending changes of the current branch), and the `claude-security` plugin at its lowest tier: ask the user to type `/claude-security scan changes --base <base> --effort low` (the plugin's menu skill has `disable-model-invocation: true`, so the model cannot start it; the explicit `--base` matters, because a bare sha is read as `--commit`). It asks its own fixed cost confirmation, needs the Workflow tool, and writes `CLAUDE-SECURITY-<timestamp>/CLAUDE-SECURITY-RESULTS.md` behind its own `.gitignore`. The full-effort scan is deploy's. The row's run cell names both invocations; findings = the sum.
- verification: `superpowers:verification-before-completion` + `verification-before-completion-extras` on EXECUTE §2.
- ux-laws: gstack `/design-review <preview URL>` + `gstack-extras`. Pass the URL explicitly: on a feature branch without one it switches to diff-aware mode. Its setup reads the root `DESIGN.md` (the symlink to `.v2p/DESIGN.md`) and compares the page with it; decline its offer to save a DESIGN.md. Then `make-interfaces-feel-better` in `full` mode on the branch's UI diff, and `review-animations` (emil) only when the diff matches `transition|animate|framer|motion|@keyframes`. Not `/impeccable audit` or `critique` (duplicates). All outputs go into `.v2p/work/review-ux-laws.md`; the run cell names `DESIGN.md` (e.g. `/design-review http://localhost:3101 against DESIGN.md + make-interfaces-feel-better full`). Never `mcp__claude-in-chrome__*`; `/browse` for anything that needs a click.
- i18n: the `translation-quality` skill.
- codex: `/codex review` with no text after `review` (any text there turns into custom instructions sent through `codex exec` instead of the scoped `codex review --base`). The skill resolves the base branch itself and probes auth in its Step 0.5; `AUTH_FAILED` or `MODEL_UNUSABLE` → the row reads `unavailable: <that reason>` and review continues (user decision). Codex findings enter §2 as rows the main thread adjudicates.
- qa: gstack `/qa` on the preview URL; `/qa-only` for re-checks.
Each skill's output is written to its checkpoint by the main thread on receipt.
<!-- /claude-only -->

## Step 2 — Adjudicate and fix
Every finding gets one row in REVIEW.draft.md §2 with a status: `fixed <sha>` (each fix its own commit, test first), `accepted: <reason>`, or `open: <reason>`. `open` is allowed only when the reason names the deploy task or a BRIEF §. A fix touches only the finding's paths; after each fix, check the branch scope again: a path outside every task's scope is itself a finding (its own §2 row, adjudicated like any other). Update the draft's `diff: <base>..<head>` after the last fix commit.
<!-- claude-only -->
Claude Code: fixes are implemented by `builder` (code) or `quick` (docs) under execute's dispatch rules, with the Files list = the finding's paths; `sh <this skill's dir>/scripts/drift-check.sh --branch .v2p` after each fix. `AskUserQuestion` before accepting any `open` finding.
<!-- /claude-only -->

## Step 3 — Standards evidence
Copy EXECUTE §2 into REVIEW.draft.md §3 and complete it: every row `done` with evidence (a command and its output from this phase, a path or a URL) or `N/A` citing `BRIEF §`; `pending` only as `pending | deferred to deploy: <what production state it needs>`.
<!-- claude-only -->
Claude Code: `planner` audits the table read-only and returns the rows whose evidence does not prove the item; the main thread fixes them. `AskUserQuestion` to confirm the deferred rows.
<!-- /claude-only -->

## Step 4 — Threat model and docs
`docs/threat-model.md` exists and names every entry point of PLAN `## Threat Model`; `docs/ARCHITECTURE.md` module map matches the tree (core.md Modularity item 1); the tidy check reports 0 violations, or each one is listed with a reason.

## Step 5 — Finalize
Portable: write `.v2p/REVIEW.md` from the draft; there is no receipt without the scripts; say so.
<!-- claude-only -->
Claude Code: `sh <this skill's dir>/scripts/finalize-review.sh .v2p` until it prints `PASS`. It checks every required run row, one §2 row per finding (fix commits exist), §3 against PLAN §4, the draft's head = HEAD, the branch and a clean tree, and, when the PLAN's Spec line names `.v2p/DESIGN.md`, that DESIGN.md still matches `.v2p/.brand-pass` and the ux-laws run cell names `DESIGN.md`; and it re-runs every mechanical PLAN verifier of the tasks EXECUTE did not skip or defer (expect minutes). A verifier that cannot pass as written (a plan defect, e.g. a raw `wc -l` comparison) is never edited: on the user's yes (`AskUserQuestion`, with the evidence that the property holds), add `ruling: task <n> · plan defect · <evidence>` to the draft; that verifier is not re-run and the count shows in the PASS line. It writes `REVIEW.md`, the receipt `.v2p/.review-pass`, and clears `.v2p/work/review-*`. Never write `REVIEW.md` by hand.
<!-- /claude-only -->

## Step 6 — Hand off
Print the path, findings fixed/accepted/open, standards done/N-A/deferred, `pre-deploy: pending (claude-security full scan + Strix pentest run by /v2p deploy)`, then `Next: /v2p deploy (not available in this version)`.

<!-- claude-only -->
## Claude Code note
- Main thread runs the gstack skills (they need `AskUserQuestion`); `planner` audits evidence; `/codex` runs through its skill only.
- `AskUserQuestion` for: accepting an `open` finding, `/codex` unavailable → continue without, deferred rows.
- Strix is deploy's (slice 5): not installed here; mention only.
<!-- /claude-only -->

***
Copyright © 2026 Rafael Arciniegas. Licensed under the MIT License.
