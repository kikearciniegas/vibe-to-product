# v2p phase: deploy

## Purpose
Ship the reviewed branch behind a full security scan, complete the deferred evidence on the live site, and seal a receipt. v2p owns the gates; the shipping itself is delegated. Writes `.v2p/DEPLOY.md`.

## Preconditions
- `.v2p/REVIEW.md` must have passed review's finalize step. Portable: it has a `checked:` line that is not `pending`. Otherwise print `Run /v2p review first.` and stop.
<!-- claude-only -->
  In Claude Code this check is a script: `sh <this skill's dir>/scripts/check-pass.sh .v2p/REVIEW.md .v2p/.review-pass` must print `OK`.
<!-- /claude-only -->
- Clean tree and HEAD on the branch named in the REVIEW `checked:` line (`branch <b>`); otherwise print what differs and stop.
- When the PLAN's Spec line names `.v2p/DESIGN.md`, DESIGN.md is still the one brand finalized.
<!-- claude-only -->
  Claude Code: `sh <this skill's dir>/scripts/check-pass.sh .v2p/DESIGN.md .v2p/.brand-pass` must print `OK`.
<!-- /claude-only -->
- A git remote on GitHub and an authenticated GitHub CLI (`gh auth status`): the merge-and-deploy step is GitHub-only and needs a pull request. Otherwise take the portable path below (merge by hand) and say there is no receipt.
- Existing `.v2p/DEPLOY.md` with its receipt → print `live since <written date> at <target>` and offer: resume (keep it) or redeploy. A redeploy of the same reviewed cycle moves the old receipt aside first (`.v2p/DEPLOY.<date>.md`, on the user's yes); it is never overwritten silently. A re-theme archives it with its cycle.
- Model guard (router §2).
- Checkpoints: `.v2p/work/deploy-<step>.md` is reusable when its line 1 `head:` equals the current `git rev-parse HEAD`; otherwise it is stale: overwrite it, never read it.

## Step 0 — Scope
Print: the PLAN §2 hosting row, `Total monthly at launch`, the commercial answer, the BRIEF §7 budget; the PLAN task execute handed to deploy (EXECUTE §1 `skipped — handed to /v2p deploy`) and its steps; EXECUTE §1 `deferred — <credential>` rows; the count of REVIEW §3 `deferred to deploy` rows and every REVIEW §2 `open:` row (each is closed here: a fix commit, or `accepted:` in §2 of this draft). Start `.v2p/DEPLOY.draft.md` from `references/deploy-template.md` and write `## 0. Target`.
<!-- claude-only -->
Claude Code: `sh <this skill's dir>/scripts/drift-check.sh --branch .v2p` as the scope baseline.
<!-- /claude-only -->

## Step 1 — Security gate
1. Full security scan of the whole repository at its high effort tier, on a clean tree at HEAD (a scan of a dirty tree does not count). Every finding becomes one §2 row (`id`, `severity`, `path:line`). Record the scan's output directory as `scan:` on the `written:` line and the count in the §1 security-full row.
2. Fixes: each finding is fixed in its own commit (test first; only the finding's paths), or accepted with a reason. A CRITICAL or HIGH finding is accepted only with the user's reason in their words. Nothing is left `open`. Every commit made after the scan must be a §2 `fixed <sha>`; any other commit means the scan runs again.
3. Strix (optional white-box pentest of the repository, before the merge; never against production): offered only when Docker runs and an LLM key is configured (check the variable names only; never print a value). Not installed → ask once whether to install it; its installer is `curl -sSL https://strix.ai/install | bash` (verified: 2026-09), so it is read before it runs. Declined or not possible → the strix row reads `unavailable: <reason>`. Run `strix --target .`; each finding is a §2 row with check `strix`.
Portable: run whatever scanner the user has (or none) and say so; the strix row reads `unavailable: portable`; there is no receipt.
<!-- claude-only -->
Claude Code:
- The scan: `/claude-security scan codebase --effort high` (no `--scope`). Plugin 0.12.0 has no `disable-model-invocation`: the model may invoke this scan when the user's request accepted its time or token cost in words. Otherwise it asks its own whole-repository and cost confirmation; if that still blocks, ask for the scan in the phase's opening prompt (Preconditions). It runs minutes to tens of minutes (keep waiting). It writes `CLAUDE-SECURITY-<ts>/` with `CLAUDE-SECURITY-RESULTS.{md,jsonl,sarif}` and the stamp `CLAUDE-SECURITY-REVISION-<sha12>.json` behind its own `.gitignore`. The §1 run cell is that exact invocation; §2 rows come from the JSONL.
- Fixes: `builder` (code) or `quick` (docs) under execute's dispatch rules, Files = the finding's paths, `superpowers:test-driven-development`, one commit per fix with the branch check in the same command (`[ "$(git rev-parse --abbrev-ref HEAD)" = <review branch> ] && git add -A -- . ':(exclude).v2p' && git commit -m "fix: <finding id> <one line>"`), then `sh <this skill's dir>/scripts/drift-check.sh --branch .v2p`. `AskUserQuestion` before accepting any finding; for CRITICAL/HIGH record the user's reason verbatim. This line is the weakest gate: the script checks the `accepted:` shape, not who accepted it.
- Strix: probe `command -v docker && docker info` and whether `STRIX_LLM` and `LLM_API_KEY` are set (names only). Install only through the `installing-third-party-tools` skill, on the user's yes to one `AskUserQuestion`. Its `strix_runs/` may hold `*.log` files the tidy check flags; leave them for the user.
<!-- /claude-only -->

## Step 2 — Provisioning (the PLAN deploy task)
Walk the deploy task's steps with the user: dashboards, DNS, and secrets into the host's secret store (`references/stack/wiring.md` W27, W30, W33). The user types every value; v2p never asks for, prints or stores one. Write or verify `docs/secrets.md`: every `.env.example` name with its owner, rotation and where it lives, and no value. Then configure the deploy: platform, production URL, deploy trigger, health check, merge method. Copy the production URL's host to `target: https://<host>` on the `written:` line. The credentials of EXECUTE §1 `deferred — <credential>` rows are confirmed as set before the verifiers re-run.
Portable: the same steps, by hand.
<!-- claude-only -->
Claude Code: gstack `/setup-deploy` + `gstack-extras`. It writes `## Deploy Configuration (configured by /setup-deploy)` into the project's `CLAUDE.md`; its `- Production URL:` line is the one `target:` must equal. Vercel and Netlify are detected from their config files. Cloudflare Workers is not in its detection list: take its Custom/Manual path and answer from PLAN §2 (trigger: auto-deploy on push through Workers Builds, W29; health check: the production URL; merge method: the repository setting). Its URL check reports the site unreachable before the first deploy; that is expected and does not block. A platform that differs from the PLAN §2 hosting row is a stop-and-ask. `AskUserQuestion`: "These credentials are now set in the host's store: <EXECUTE §1 deferred list> — confirm before the verifiers re-run."
<!-- /claude-only -->

## Step 3 — Go live
The one-way door: ask once, "Scan clean, runbook done. Open the pull request and deploy now?" On yes: open a pull request from the review branch into the base branch and record `pr: #<n> · base: <base>` on the `written:` line; merge it, wait for the deploy, verify the production URL once, and write the deploy report (verdict `DEPLOYED AND VERIFIED` required). Then watch the site for 10 minutes (overall status `HEALTHY` required). Record both report paths in §1.
Portable: merge by hand, `curl -m 10 -sI https://<host>` and paste the output; there is no receipt.
<!-- claude-only -->
Claude Code: `AskUserQuestion` for the go-live, then `gh pr create --base <base> --head <branch> --title "<project>: v2p cycle <n>" --body "REVIEW.md <hash12> · scan <sha12>"` (not `/ship`: its review army, version bump and CHANGELOG edits duplicate or alter what review sealed). Then gstack `/land-and-deploy https://<host>` + `gstack-extras`:
- first run: it shows a dry run and asks to confirm the infrastructure; answer A when it matches `## 0. Target`, C to re-run `/setup-deploy`.
- readiness gate: when it reports the review RECENT or STALE because of the Step 1 fix commits, answer **C (skip)** citing REVIEW.md and the scan: a fix made there would bypass §2 and the commit accounting.
- staging first: **A** when a staging or preview target exists.
- Vercel/Netlify: it waits 60 s, then runs its single-pass canary (no Aside here: its `$B` headless browser is the fallback). Workers: the same, through the health-check URL.
- verdict: `REVERTED` → back to Step 1 with the cause as a finding. `DEPLOYED (UNVERIFIED)` → run `/canary https://<host> --quick`, show the user, and stop: the gate needs `DEPLOYED AND VERIFIED`.
Then `/canary https://<host> --duration 10m` (default pages); its JSON `status` must be `HEALTHY`. The reports land in `.gstack/deploy-reports/` and `.gstack/canary-reports/`.
<!-- /claude-only -->

## Step 4 — Rollback rehearsal
The user promotes the previous deployment and rolls forward again (Vercel: Deployments → Promote to Production; Cloudflare Workers: Deployments → Rollback, or `npx wrangler rollback`; Netlify: Deploys → Publish deploy). Ask for the timestamp, the elapsed seconds and the method, and write `rollback: rehearsed <ISO timestamp> · elapsed <n>s · method: <text> · by user`. Also write the same evidence into the log the PLAN names (e.g. `docs/slo.md`) as part of the deploy task's docs commit, before the merge.
<!-- claude-only -->
Claude Code: `AskUserQuestion` for the three values; the line is attributed to the user and only its shape is checked.
<!-- /claude-only -->

## Step 5 — Standards
Copy REVIEW §3 into draft §3. Every `deferred to deploy` row becomes `done` with evidence from this phase (a command and its output, a report path, a URL), `N/A` citing `BRIEF §`, or `pending | post-launch: <trigger and date>` for what only traffic produces (Core Web Vitals field data, a CSP Report-Only window). `not adopted` and `gap` rows are carried unchanged (same path rule; a gap ships knowingly and is counted, not blocked). Confirm the post-launch set and the gap rows with the user.
<!-- claude-only -->
Claude Code: `planner` audits the table read-only and returns the rows whose evidence does not prove the item; the main thread fixes them. `AskUserQuestion` to confirm the post-launch rows.
<!-- /claude-only -->

## Step 6 — Finalize
Portable: write `.v2p/DEPLOY.md` from the draft; there is no receipt without the scripts; say so.
<!-- claude-only -->
Claude Code: `sh <this skill's dir>/scripts/finalize-deploy.sh .v2p` until it prints `PASS`. It checks: REVIEW.md and PLAN.md match their receipts; the `target:` host is a plain hostname equal to `CLAUDE.md`'s Production URL; the scan stamp (mode `scan`, no scope, effort `high` or `max`, `verified`, not `-dirty`, scanned commit an ancestor of HEAD, every later commit a §2 `fixed` sha, finding totals equal); §2 statuses; the deploy report verdict and the canary status; HEAD merged into `origin/<base>` (it fetches); a clean tree (ignoring `.gstack/`, `CLAUDE-SECURITY-*/`, `strix_runs/`); every mechanical PLAN verifier re-run with `<domain>`/`<url>` substituted, including the tasks handed to deploy and the deferred ones (REVIEW's `ruling:` lines honoured); `https://<host>/` answers 200 and `http://` redirects to https; §3 against REVIEW §3; the rollback line; `docs/secrets.md` covering `.env.example` and no secret-looking value. Expect minutes. A verifier that cannot pass as written is never edited: on the user's yes (`AskUserQuestion`, with evidence the property holds), add `ruling: task <n> · plan defect · <evidence>` to the draft. It writes `DEPLOY.md`, the receipt `.v2p/.deploy-pass`, and clears `.v2p/work/deploy-*`. A refusal is a stop-and-ask with its output verbatim; never write `DEPLOY.md` or `.deploy-pass` by hand.
<!-- /claude-only -->

## Step 7 — Hand off
Print the path, the `checked:` counts, `live: https://<host>`, then `Next: live — commit .v2p/DEPLOY.md and .v2p/.deploy-pass on this branch and open the follow-up pull request "chore: deploy receipt"; re-theme with /v2p brand; redeploy with /v2p deploy`.

<!-- claude-only -->
## Claude Code note
- Main thread runs the gstack skills and asks the questions (they need `AskUserQuestion`); the main thread invokes `/claude-security …` (Step 1's cost rule); `builder`/`quick` fix; `planner` audits §3 read-only. Load `gstack-extras` with any gstack skill.
- `AskUserQuestion` for: the Strix offer, accepting a finding, the deferred credentials, the go-live, the rollback values, the post-launch rows. gstack skills ask their own; not duplicated.
- Never `mcp__claude-in-chrome__*`; `/browse` for anything that needs a click. Never read `.env*`; never echo a value from a dashboard into the transcript.
- Strix only through `installing-third-party-tools`, on the user's yes.
- Hooks: `hooks/guard-finals.sh` (installed in global settings when the user opted in) also blocks direct writes to `DEPLOY.md` and `.deploy-pass`.
<!-- /claude-only -->

***
Copyright © 2026 Rafael Arciniegas. Licensed under the MIT License.
