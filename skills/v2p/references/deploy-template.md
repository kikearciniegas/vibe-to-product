# DEPLOY template

Copy the block below into `.v2p/DEPLOY.draft.md` at deploy Step 0 and replace every `<…>`. §3 starts as a copy of REVIEW §3 and must end complete.
<!-- claude-only -->
In Claude Code, the `checked:` line is written by `scripts/finalize-deploy.sh`, which also re-runs every mechanical PLAN verifier against the live target and reads the scan stamp and the gstack reports; leave it as below. The security-full run cell is `/claude-security scan codebase --effort high`; the `scan:` value is the directory that run wrote.
<!-- /claude-only -->

Rules: §1 has the five rows. Results are `<n> findings` (security-full, strix; strix may read `unavailable: <reason>`) or a path (setup-deploy → the project `CLAUDE.md` `## Deploy Configuration` section, land-and-deploy → `.gstack/deploy-reports/<file>.md`, canary → `.gstack/canary-reports/<file>.json`). §2 has one row per security-full or strix finding, status `fixed <commit sha>` or `accepted: <reason>`, never `open`. §3 statuses: `done` with evidence (`<command> → <output>`, a path or a URL), `N/A` citing `BRIEF §`, `not adopted`/`gap` carried from REVIEW §3 (the path exists in the repo), or `pending` only with evidence `post-launch: <trigger and date>`. §4 lines are literal shapes. `target:` is `https://` plus the bare production host, the same host as the project `CLAUDE.md` `Production URL`. No secret value anywhere: names only.

````
# DEPLOY — <project name>
checked: pending   ← the finalize step replaces: scan <effort> <sha12> · findings <f> (fixed <x> · accepted <a>) · verifiers <v>/<v> pass · placeholders left <k> · rulings <r> · standards done <d> · N/A <n> · not adopted <x> · gap <g> · post-launch <p> · live 2/2 · canary HEALTHY · rollback <s>s · branch <b> · head <sha>
written: <YYYY-MM-DD> by v2p deploy · reads: .v2p/REVIEW.md (<hash, first 12>) · target: https://<host> · scan: CLAUDE-SECURITY-<ts> · pr: #<n> · base: <base branch>

## 0. Target
host: <PLAN §2 hosting row provider/plan> · commercial: <yes/no, PLAN §2> · total monthly: $<n> (PLAN §2) · budget: $<n> (BRIEF §7) · deploy task: PLAN Task <n> · deferred verifiers: <task list or none>

## 1. Runs
| check | run (exact command or skill invocation) | result |
|---|---|---|
| security-full | <full-repository security scan, effort high> | 2 findings |
| strix | strix --target . (strix_runs/<run>) | 0 findings   ← or: unavailable: <reason> |
| setup-deploy | <deploy configuration step> | CLAUDE.md ## Deploy Configuration (platform <p>) |
| land-and-deploy | <merge + deploy + verify> https://<host> | .gstack/deploy-reports/<date>-pr<n>-deploy.md |
| canary | <post-deploy watch> https://<host> --duration 10m | .gstack/canary-reports/<date>-canary.json |

## 2. Findings
| # | check | id | severity | path:line | status |
|---|---|---|---|---|---|
| 1 | security-full | F1 | HIGH | src/app/api/contact/route.ts:41 | fixed a1b2c3d |
Rows: <f> = §1 security-full + strix counts

## 3. Standards (complete)
| item | file | status | evidence |
|---|---|---|---|
| Rollback Strategy | core.md | done | rehearsed 2026-09-26T10:12:00Z · 41s · Vercel promote previous |
| Core Web Vitals Audit | core.md | pending | post-launch: 28 days of field data, 2026-10-24 |
Rows: <n> = REVIEW §3

## 4. Live
rollback: rehearsed <YYYY-MM-DDTHH:MM:SSZ> · elapsed <n>s · method: <what was promoted where> · by user
secrets: docs/secrets.md · <n> names · values: none

Next: live
````

***
Copyright © 2026 Rafael Arciniegas. Licensed under the MIT License.
