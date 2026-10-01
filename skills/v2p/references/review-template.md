# REVIEW template

Copy the block below into `.v2p/REVIEW.draft.md` at review Step 1 and replace every `<…>`. §3 starts as a copy of EXECUTE §2 and must end complete.
<!-- claude-only -->
In Claude Code, the `checked:` line is written by `scripts/finalize-review.sh`, which also re-runs every mechanical PLAN verifier; leave it as below.
<!-- /claude-only -->

Rules: §1 has one row per required check, findings cell `<n> findings` (the codex row may read `unavailable: <reason>`). §2 has one row per finding, status `fixed <commit sha>`, `accepted: <reason>` or `open: <reason naming the deploy task or a BRIEF §>`. §3 statuses: `done` with evidence (`<command> → <output>`, a path or a URL), `N/A` citing `BRIEF §`, `not adopted — <path §/line>` or `gap — <path:line>` (the path exists in the repo), or `pending` only with evidence `deferred to deploy: <what production state it needs>`. Update the `diff:` head after the last fix commit. The ux-laws run cell names `DESIGN.md` (the visual review ran against it).

````
# REVIEW — <project name>
checked: pending   ← the finalize step replaces: runs <r>/<required> · findings <f> (fixed <x> · accepted <a> · open <o>) · standards done <d> · N/A <n> · not adopted <x> · gap <g> · deferred <k> · verifiers <v>/<v> pass · branch <b> · head <sha>
written: <YYYY-MM-DD> by v2p review · reads: .v2p/EXECUTE.md (<hash, first 12>) · diff: <base>..<head>

## 1. Runs
| check | run (exact command or skill invocation) | findings |
|---|---|---|
| code-review | /review … | 3 findings |
| codex | /codex review | 2 findings   ← or: unavailable: <reason> |
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

Next: /v2p deploy
````

***
Copyright © 2026 Rafael Arciniegas. Licensed under the MIT License.
