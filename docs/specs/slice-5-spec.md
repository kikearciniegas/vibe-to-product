# v2p SLICE 5 — implementation spec (`/v2p deploy`: security gate, provisioning, delegated ship, live receipt)

**Conclusion first.** Build 5 new files, edit 15. `deploy` becomes the last phase: it reads `.v2p/REVIEW.md` (receipt required), runs the **full `claude-security` codebase scan** as a hard gate (findings fixed or explicitly accepted, no `open`), offers **Strix** only when Docker and its LLM key exist (installed only on the user's yes), walks the PLAN's deploy runbook (dashboards, secrets into the host's store — v2p never sees values), then **delegates the shipping to gstack**: `/setup-deploy` (writes `## Deploy Configuration` into the project's CLAUDE.md, which is where the production URL comes from), `gh pr create`, `/land-and-deploy https://<host>` (merge, wait, single-pass canary, deploy report), `/canary https://<host>` (10-minute watch). v2p owns the gates and the receipt: `.v2p/DEPLOY.draft.md` → `scripts/finalize-deploy.sh` → `.v2p/DEPLOY.md` + `.v2p/.deploy-pass`. The gate checks mechanically: review receipt; scan stamp (mode `scan`, no scope, effort `high|max`, `verified`, not `-dirty`, scanned sha ⊆ HEAD with every later commit a `fixed` sha); findings accounted; the deploy report says `DEPLOYED AND VERIFIED` and the canary JSON `HEALTHY`; HEAD merged into `origin/<base>`; **every mechanical PLAN verifier re-run, now with `<domain>`/`<url>` substituted from the draft's `target:` line** (validated charset, cross-checked against CLAUDE.md's `Production URL`), including the tasks execute handed to deploy and the `deferred — <credential>` ones; REVIEW's `ruling:` lines honoured; two live `curl -m 10` checks (200 over https, http→https redirect); rollback-rehearsal line shape; `docs/secrets.md` present and covering `.env.example` names; no secret-looking value in the draft. No per-provider deploy script is written. Tests are script/fixture only with a fake `curl`, a fake scan directory and fake gstack reports; a falsifier per check. No real deploy in this slice.

Five things to hear before the builder starts (details in §7):
1. `/land-and-deploy` is **GitHub-only** and **needs an existing PR** (`land-and-deploy/SKILL.md:558-563,632-636`; GitLab/unknown → STOP at `:555`). The live fixture has **no git remote** (measured) — deploy cannot run there until the repo is on GitHub. The spec creates the PR with `gh pr create`, not `/ship` (Q1).
2. `/setup-deploy` does **not** detect Cloudflare Workers (its list: fly, render, vercel, netlify, heroku, railway, GitHub Actions; `setup-deploy/SKILL.md:437-448`). v2p's default host therefore goes through its Custom/Manual path, answered from PLAN §2 + wiring W29 (auto-deploy on push via Workers Builds; health check = production URL).
3. Placeholders get values from **one line in the draft** (`target: https://<host>`) that must equal the `Production URL` `/setup-deploy` wrote after the user confirmed it; the host is charset-validated before it is substituted into a command run by `sh -c`. Only `<domain>` and `<url>` are substituted; any other placeholder stays skipped and is counted.
4. gstack's readiness gate reads its own review dashboard (`sections/readiness-gate.md:13-63`); security fix commits after `/review` make it report RECENT/STALE and offer an inline quick review. deploy.md answers **C (skip)** citing REVIEW.md + the scan, so no unledgered fix commit appears between the scan and the merge (the gate would refuse it).
5. Strix is **not installed, Docker is absent, no `STRIX_LLM`/`LLM_API_KEY` in the environment** (measured). Its installer is `curl -sSL https://strix.ai/install | bash` (README via fetch) — never run by v2p; only through `installing-third-party-tools` on the user's yes. Its `strix` row reads `unavailable: <reason>` on this machine today.

**(measured)** = run by me on this machine 2026-09-25; **(file)** = a file read today with `path:line`; **(assumed)** stated as such. Live behaviour of the routed skills is unverified by construction (decision 3: no real deploy).

***

## 0. Verified facts vs assumptions

**Measured / read today**
- Router: `deploy` is listed as an argument (`SKILL.md:16`), absent from the model guard (`:18`), §5 row `| deploy | none | none | not available in this version |` (`:64`), the "not available" rule at `:66`, Next resolution ends `REVIEW exists → deploy (status in §5)` (`:27`).
- Review hand-off: `review.md:72` prints `pre-deploy: pending (claude-security full scan + Strix pentest run by /v2p deploy)` then `Next: /v2p deploy (not available in this version)`; `finalize-review.sh:68` greps the `pre-deploy:` line; `review-template.md:36-38`; fixture `tests/fixtures/finalize-review/REVIEW.md` last line; `test-finalize-review.sh:50` inserts before `^Next: /v2p deploy` (regex prefix — still matches after the edit).
- REVIEW §2 `open:` must name `deploy` or a `BRIEF §` (`finalize-review.sh:49`); §3 `pending` only as `deferred to deploy: …` (`:61`); `ruling: task <n> · plan defect · <evidence>` lines are parsed at `:85-92` and the ruled task is not re-run; verifier re-run loop `:90-105` skips EXECUTE §1 rows whose verifier cell starts `skipped|deferred` (`:80`); placeholder rule = an unquoted `<word>` (`:97`, same as `task-record.sh:91`).
- Execute: preflight hands `<domain>`-verifier tasks to deploy via `task-record.sh skip <n> "handed to /v2p deploy"` (`execute.md:38-40`); `defer <n> "<credential>"` writes `verifier: deferred — <credential>` (`task-record.sh:133-136`); `finalize-execute.sh:32` counts them; `execute-template.md:17` says deploy re-checks them.
- Live fixture (`/Users/user/tmp/v2p-exec/.worktrees/v2p-execute-2026-09-24`, HEAD `15ff1f3`, tree clean but `?? .serena/`): REVIEW `checked: runs 8/8 · findings 4 (fixed 4 · accepted 0 · open 0) · standards done 95 · N/A 64 · deferred 34 · verifiers 10/10 pass · rulings 1 · branch v2p/execute-2026-09-24 · head 77c6260…`; one ruling (task 5, raw `wc -l`); EXECUTE: 8 skipped, **0 deferred**, Task 18 `skipped — handed to /v2p deploy`; PLAN Task 18 is a 9-step dashboard runbook whose Verifier is `manual: … then mechanical sub-checks:` six commands, all with `<domain>` (`curl -m 10 -sI https://<domain> | grep -q 'HTTP/2 200'`, http→https location, two `dig +short TXT`, `/.git/HEAD` → 404, CORS header count → 0); placeholders across all PLAN verifiers: `<domain>` ×6, `<loc>` ×2 (quoted → runs). PLAN §2 hosting row: Vercel Pro $20, `Commercial yet: yes`, `Total monthly at launch: $20`, budget $25. `.env.example` has 13 names; `docs/` has `slo.md`, `processors.md`, `threat-model.md`, `ARCHITECTURE.md`; no `CLAUDE.md ## Deploy Configuration`; **no git remote**.
- claude-security 0.11.0 (plugin cache): menu skill `disable-model-invocation: true` (`skills/claude-security/SKILL.md:4`); jobs `scan-codebase.md` args `--scope dirs`, `--effort low|medium|high|max` (default medium) (`jobs/scan-codebase.md:14-15`); a whole-repo scan always asks one confirming question (`:40`); it writes `CLAUDE-SECURITY-<ts>/` with `CLAUDE-SECURITY-RESULTS.{md,jsonl,sarif}` and the stamp `CLAUDE-SECURITY-REVISION-<sha12>[-dirty].json` behind its own `.gitignore` (README:49-56; `render_report.py:114,453-463,823`). Stamp keys (`render_report.py:771-791`): `mode` (`scan|changes|commit`, `lib/plugin.py:17`), `scope` (list), `revision` (`commit`, `dirty`, `branch`… from `write_scan_meta.py:250-262`), `effort`, `findings` (`total`, `critical`, `high`, `medium`, `low`), `verification` (`status` = `verified|unverified`, `:431`). JSONL records carry `id`, `severity` (`CRITICAL|HIGH|MEDIUM|LOW`), `file`, `line`, `title` (`lib/finding.py:305-320,49`). Review already calls `/claude-security scan changes --base <base> --effort low` (`review.md:41`).
- gstack (installed under `~/.claude/skills/`): `/setup-deploy` writes `## Deploy Configuration (configured by /setup-deploy)` with `- Platform:`, `- Production URL:`, `- Post-deploy health check:` etc. into CLAUDE.md (`setup-deploy/SKILL.md:546-568`), verifies the URL with `curl -sf` (`:572-576`), never exposes secrets (`:608`). `/land-and-deploy [#N] [url]`: gh auth required (`:618-621`), no PR → STOP (`:632`), first-run dry-run saves a fingerprint under `~/.gstack/projects/<slug>/land-deploy-confirmed` (`:641-676`), CI must pass (`:676-697`), platform from CLAUDE.md else config files (`sections/merge-and-deploy.md:166-200`), staging-first offer (`:231-259`), Vercel/Netlify = wait 60 s then canary (`:808-811`), single-pass canary needs Aside or the `$B` headless browser (`:833-897`; `$B` exists at `~/.claude/skills/gstack/browse/dist/browse`, measured), revert path (`:899-919`), report `.gstack/deploy-reports/{date}-pr{number}-deploy.md` with `VERDICT: <DEPLOYED AND VERIFIED / DEPLOYED (UNVERIFIED) / STAGING VERIFIED / REVERTED>` (`:921-980`), deletes the branch after merge (`:1016`). `/canary <url> [--duration 1m..30m] [--baseline] [--pages] [--quick]` writes `.gstack/canary-reports/{date}-canary.{md,json}` with `status` `HEALTHY|DEGRADED|BROKEN` (`canary/SKILL.md:504-509,660-697`), read-only (`:717`). `/ship` = merge base, tests, review army, version bump, CHANGELOG, commit, push, PR (`ship/SKILL.md:26-31,473-492,989-1002`).
- Strix (README fetched via WebFetch, summarised): install `curl -sSL https://strix.ai/install | bash`; needs Docker running + an LLM key; env `STRIX_LLM`, `LLM_API_KEY`, optional `LLM_API_BASE`; `strix --target ./dir | https://url | <github url>`; results in `strix_runs/<run>`; Apache-2.0; ~64.8k★. On this machine: `strix` absent, `docker` absent, no key env vars (measured).
- CLIs here: `gh` present and authenticated (github.com), `dig`, `curl`, `jq`, `python3`, `bun` present; `aside`, `vercel`, `wrangler`, `netlify` absent (measured).
- tidy-check prunes `.git node_modules .venv venv vendor .v2p .claude .serena .github .vscode .idea` and symlinks (`tidy-check.sh:35`); **`.gstack/`, `CLAUDE-SECURITY-*/`, `strix_runs/` are walked**; `.md/.json/.jpg` report files match no scattered pattern (`:47-58`); a `*.log` inside `strix_runs/` would be flagged `log quarantine` (`:50`).
- Guard hook lists finals and seals (`guard-finals.sh:19-25`); `archive-cycle.sh:19` moves `PLAN.md EXECUTE.md REVIEW.md PLAN-AMENDMENTS.md .plan-pass .execute-pass .review-pass`; `build-portable.sh:11-16` file order; `test-build.sh` checks marker balance over every file with `claude-only`.
- Standards items deploy completes (`core.md`): Secrets Vault (`:38` — `docs/secrets.md`, owner + rotation), CI/CD (`:112`), Backups (`:113`), Rollback Strategy (`:114` — "rehearsal log with timestamp and elapsed time"), DAST (`:138`), Env mapping (`:151`), Prod Env Vars (`:157`), Uptime (`:167`), Progressive rollout (`:203`); `web.md` DNS & Domain (`:65-66`), GSC/Bing/broken links (`:57-59`).

**Assumed**
- `curl -sI https://<host>` prints `HTTP/2 200` on Vercel/Cloudflare/Netlify (Task 18's own expectation; unverified live). The gate's own live check uses `-w '%{http_code}'` and does not depend on the protocol line.
- `.gstack/` is untracked in a v2p project (gstack does not gitignore it; the gate's clean-tree check excludes it explicitly, so the assumption only affects tidiness).
- The stamp's JSON is pretty-printed with `"key": value` on its own line (`strictjson.text(stamp, indent=2)`, `render_report.py:824`); the gate greps that shape, verified against a stamp captured in the test fixture (§5, check 14-style parser falsifier).
- gstack's dashboard registers v2p review's `/review` run as a review for the readiness gate (inferred from `readiness-gate.md:16-31`; unverified).

***

## 1. File tree delta

```
vibe-to-product/
├── build-portable.sh                          # MOD (+1 token): phases/deploy.md references/deploy-template.md after references/review-template.md
├── README.md                                  # MOD: deploy row → available; file map +4; verify block +2
├── docs/ROADMAP.md                            # MOD: Slice 5 built; tier row "before deploy" → built; open item Strix live test
├── docs/specs/slice-5-spec.md                 # NEW: this document
├── tests/
│   ├── fixtures/finalize-deploy/DEPLOY.md     # NEW (~45 lines): deliberately bad draft
│   ├── test-finalize-deploy.sh                # NEW (~150 lines): fix-one-step → PASS, then falsifiers; fake curl, fake scan dir, fake gstack reports; sh and zsh
│   ├── test-finalize-review.sh                # MOD (0–1): unchanged unless the fixture's Next line grep needs it (it does not)
│   └── test-guard.sh                          # MOD (+3): DEPLOY.md / .deploy-pass block cases, finalize-deploy allow
└── skills/v2p/
    ├── SKILL.md                               # MOD: description; model guard +deploy; Next resolution; §5 row; drop :66; §6 template + scripts list
    ├── phases/
    │   ├── deploy.md                          # NEW (~115 lines)
    │   └── review.md                          # MOD (+2 −2): Step 6 Next line; Claude Code note Strix line
    ├── references/
    │   ├── deploy-template.md                 # NEW (~45 lines) — portable
    │   ├── review-template.md                 # MOD (1): `Next: /v2p deploy`
    │   ├── model-routing.md                   # MOD: deploy row replaces the stub; drift table last row
    │   └── skills-catalog.md                  # MOD: Deploy row; Security row Strix details
    ├── scripts/
    │   ├── finalize-deploy.sh                 # NEW (~150 lines)
    │   └── archive-cycle.sh                   # MOD (+0 lines, 1 edit): DEPLOY.md .deploy-pass in the list
    └── hooks/guard-finals.sh                  # MOD (3 edits): DEPLOY in both case lists and the regex
```
Also `tests/fixtures/finalize-review/REVIEW.md` last line → `Next: /v2p deploy` (1 edit).

Conventions carried: `***` not `---`; copyright last; POSIX sh, no arrays; `<!-- claude-only -->` balanced; `(verified: 2026-09)` beside URLs. Not built (YAGNI): a `deploy-record.sh` writer (the draft is main-thread-written like REVIEW's; the gate checks shape), per-provider deploy/rollback commands, a Strix wrapper, a DNS checker beyond the PLAN's own `dig` verifiers, a second scan after fixes (the commit-accounting rule covers it).

***

## 2. Design answers

### 2.1 Mechanism (decision 2)
v2p = preconditions + security gate + runbook walk + draft + `finalize-deploy.sh`. gstack = `/setup-deploy` (config), `/land-and-deploy` (merge, wait, canary once, report, revert), `/canary` (watch). The PR is created with `gh pr create --base <base> --head <review branch>` from the phase (Q1). `/ship` is not routed: its review army, version bump and CHANGELOG steps duplicate or alter what v2p review already sealed.

### 2.2 Security gate (decision 1)
- Required: `/claude-security scan codebase --effort high` (the user types it: `disable-model-invocation`), whole repository (no `--scope`), on a clean tree at HEAD. Gate: stamp `mode` = `scan`, `scope` = `[]`, `effort` ∈ `high|max`, `verification.status` = `verified`, filename without `-dirty`, `revision.commit` = S with `git merge-base --is-ancestor S HEAD`, and `git rev-list S..HEAD` ⊆ the set of §2 `fixed <sha>` commits (so a fix after the scan is accounted, an unrelated commit is not). `findings.total` = §1 `security-full` count = §2 rows with check `security-full`; JSONL line count = total (belt). Statuses: `fixed <sha>` (commit exists) or `accepted: <reason>`; **no `open`** at deploy. CRITICAL/HIGH accepted only through `AskUserQuestion` — prose rule, shape-checked only (stated as the weakest gate, like the ponytail line, `execute.md:65`).
- Optional Strix: offered only when `command -v docker && docker info` succeeds and `STRIX_LLM`+`LLM_API_KEY` are set (names only checked, values never printed). Not installed → one `AskUserQuestion` "Install Strix through `installing-third-party-tools`? Its installer is `curl | bash` — read first"; on yes install, else `unavailable: not installed (user declined)`. Run white-box against the repo before the merge: `strix --target .`; never against production; against a preview URL only on the user's yes. Row `strix | strix --target . (strix_runs/<run>) | <n> findings` or `unavailable: <reason>`; each finding a §2 row with check `strix`.

### 2.3 Placeholders (`<domain>`, `<url>`)
Source of truth: the draft's `written:` line carries `target: https://<host>`. The gate: parses the host; requires `^[A-Za-z0-9.-]+$` and no `..`; requires the project `CLAUDE.md` `## Deploy Configuration` section's `- Production URL:` host to be identical (that line was confirmed by the user inside `/setup-deploy`, `setup-deploy/SKILL.md:520-523,606`); substitutes `<domain>` → host and `<url>` → `https://host` in each verifier command with `sed "s|<domain>|$host|g; s|<url>|https://$host|g"` (safe: the charset excludes `|`, `&`, `\`, newline); a command that still contains an unquoted `<word>` is skipped and counted in `placeholders left <k>`. Values never come from env vars, `.env` or secrets. A wrong host fails the live checks anyway.

### 2.4 Which verifiers deploy re-runs
Same loop as `finalize-review.sh:90-105`, three changes: (a) EXECUTE §1 rows `skipped — handed to /v2p deploy` and `deferred — …` **are** run (everything else `skipped — …` is not); (b) substitution per §2.3; (c) rulings come from **REVIEW.md** (hash-locked, so honoured as-is: `ruling: task <n>` → not re-run, counted) plus the draft's own `ruling:` lines for deploy-handed tasks whose sub-check is wrong as written (same shape, same user-yes rule). All other mechanical verifiers re-run too (fix commits happened since review; minutes, as at review).

### 2.5 Other inputs
- DESIGN.md receipt when PLAN's Spec names `.v2p/DESIGN.md` (same rule as `finalize-review.sh:33-34`). Cycles: deploy reads the current `.v2p/REVIEW.md`; `.v2p/cycles/` is history; `archive-cycle.sh` gains `DEPLOY.md .deploy-pass` so a re-theme after launch archives the receipt with its cycle.
- PLAN §2 hosting row, `Total monthly at launch`, commercial answer, BRIEF §7 budget: printed at Step 0 and copied into the draft's `## 0. Target` block; `/setup-deploy`'s platform must match the hosting row's provider (a mismatch is a stop-and-ask, not a gate: the row is prose).
- REVIEW §3 `deferred to deploy` rows (34 live) → draft §3 with `done` + evidence from this phase, `N/A` citing `BRIEF §`, or `pending | post-launch: <trigger, date>` (CWV field data, CSP flip after 24 h; Q4). Gate: items = REVIEW §3 items; statuses as above.
- Secrets: `docs/secrets.md` (core.md `:38`) lists every `.env.example` name with owner/rotation/where-it-lives; the draft records `secrets: docs/secrets.md · <n> names · values: none`; the gate refuses any `<NAME>=<value>` for those names and the vendor prefixes from `wiring.md:3` in the draft or the register.

### 2.6 Where DEPLOY.md lands
The phase runs in the review worktree on the review branch (precondition, like review). After `/land-and-deploy` merges the PR (and deletes the remote branch), `finalize-deploy.sh` still runs on that branch; it requires `git fetch origin <base>` then `git merge-base --is-ancestor HEAD origin/<base>` (the exact scanned+fixed code is live). The hand-off tells the user to commit `.v2p/DEPLOY.md` + `.v2p/.deploy-pass` on this branch and open `chore: deploy receipt` as a follow-up PR (Q5). `base:` and `pr:` are recorded on the draft's `written:` line.

### 2.7 Checkpoints and AskUserQuestion points
Checkpoints `.v2p/work/deploy-<step>.md` (line 1 `head: <sha> · step: <name>`; stale when `head:` ≠ HEAD; cleared by finalize). Questions: (1) Strix offer; (2) accepting a finding; (3) "these credentials are now set in the host's store: <list from EXECUTE §1 deferred rows> — confirm before the verifiers re-run"; (4) go-live (the one-way door): "Scan clean, runbook done. Create the PR and run /land-and-deploy now?"; (5) rollback rehearsal words (timestamp, elapsed, method); (6) post-launch rows confirmation. gstack skills ask their own; not duplicated.

***

## 3. Per-file spec

### 3.1 `references/deploy-template.md` (portable, ~45 lines)
Rules line: §1 has the five rows; results are `<n> findings` (security-full, strix; strix may be `unavailable: <reason>`) or a path (setup-deploy → `CLAUDE.md`, land-and-deploy → `.gstack/deploy-reports/<file>.md`, canary → `.gstack/canary-reports/<file>.json`). §2 one row per security/strix finding, status `fixed <sha>` or `accepted: <reason>` — never `open`. §3 = REVIEW §3 items; `pending` only as `post-launch: <trigger and date>`. §4 lines are literal shapes. No secret value anywhere. Last line `Next: live`.

````
# DEPLOY — <project name>
checked: pending   ← finalize replaces: scan <effort> <sha12> · findings <f> (fixed <x> · accepted <a>) · verifiers <v>/<v> pass · placeholders left <k> · rulings <r> · standards done <d> · N/A <n> · post-launch <p> · live 2/2 · canary HEALTHY · rollback <s>s · branch <b> · head <sha>
written: <YYYY-MM-DD> by v2p deploy · reads: .v2p/REVIEW.md (<hash, first 12>) · target: https://<host> · scan: CLAUDE-SECURITY-<ts> · pr: #<n> · base: <base branch>

## 0. Target
host: <PLAN §2 hosting row provider/plan> · commercial: <yes/no, PLAN §2> · total monthly: $<n> (PLAN §2) · budget: $<n> (BRIEF §7) · deploy task: PLAN Task <n> · deferred verifiers: <task list or none>

## 1. Runs
| check | run (exact command or skill invocation) | result |
|---|---|---|
| security-full | /claude-security scan codebase --effort high | 2 findings |
| strix | strix --target . (strix_runs/<run>) | 0 findings   ← or: unavailable: <reason> |
| setup-deploy | /setup-deploy | CLAUDE.md ## Deploy Configuration (platform <p>) |
| land-and-deploy | /land-and-deploy https://<host> | .gstack/deploy-reports/<date>-pr<n>-deploy.md |
| canary | /canary https://<host> --duration 10m | .gstack/canary-reports/<date>-canary.json |

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

### 3.2 `phases/deploy.md` (~115 lines) — writes `.v2p/DEPLOY.md`

**Purpose.** Ship the reviewed branch behind a full security scan, complete the deferred evidence on the live site, and seal a receipt. v2p owns the gates; gstack ships.

**Preconditions.**
- `.v2p/REVIEW.md` passed review's finalize. Portable: `checked:` not `pending`. Claude-only: `check-pass.sh .v2p/REVIEW.md .v2p/.review-pass` → `OK`, else `Run /v2p review first.` and stop.
- Clean tree and HEAD on the branch named in REVIEW's `checked:` line (`branch <b>`), else print what differs and stop (same as `review.md:12`).
- DESIGN receipt when PLAN's Spec names `.v2p/DESIGN.md` (claude-only `check-pass.sh`).
- Git remote on GitHub and `gh auth status` OK (`/land-and-deploy` is GitHub-only). Otherwise: portable path (merge by hand), and say there is no receipt.
- Existing `.v2p/DEPLOY.md` with receipt → offer: resume (keep, print `live since <written>`), redeploy (re-run; the old receipt is archived by the next `archive-cycle.sh`, not overwritten silently — a redeploy on the same reviewed cycle writes a new draft and the script refuses while `DEPLOY.md` exists: `mv` it aside to `.v2p/DEPLOY.<date>.md` on the user's yes).
- Model guard (router §2). Checkpoints per §2.7.

**Step 0 — Scope.** Print: PLAN §2 hosting row, `Total monthly at launch`, commercial answer, BRIEF §7 budget; the PLAN task execute handed to deploy (EXECUTE §1 `skipped — handed to /v2p deploy`) and its steps; EXECUTE §1 `deferred — <credential>` rows; REVIEW §3 `deferred to deploy` count and §2 `open:` rows (each must be closed here: a fix commit or `accepted:` in §2 of this draft, cross-referenced). Write `## 0. Target`. Claude-only: `drift-check.sh --branch .v2p` baseline.

**Step 1 — Security gate.**
1. Claude Code: ask the user to type `/claude-security scan codebase --effort high` (no `--scope`; the plugin asks its own whole-repo confirmation and fixed cost question; it runs minutes to tens of minutes; `keep-waiting`). Tree must be clean (a `-dirty` stamp fails the gate). On completion record `scan: CLAUDE-SECURITY-<ts>` on the `written:` line and the row in §1. Read `CLAUDE-SECURITY-RESULTS.md`; every finding → a §2 row (`id`, `severity`, `path:line` from the JSONL).
2. Fixes: `builder` (code) / `quick` (docs) under execute's dispatch rules, Files = the finding's paths, test first, one commit per fix with the branch-check one-liner (`execute.md:59`), `drift-check.sh --branch .v2p` after each. `accepted:` only via `AskUserQuestion`; CRITICAL/HIGH accepted needs the user's reason verbatim.
3. Strix (§2.2): probe Docker and the key names; offer; run; record.
Portable: run whatever scanner the user has (or none) and say so; the row reads `unavailable: portable`; no receipt.

**Step 2 — Provisioning (the PLAN deploy task).** Walk the deploy task's steps with the user (dashboards, DNS, secrets into the host's store per W27/W30/W33 — the user types values; v2p never asks for, prints or stores a value). Produce/verify `docs/secrets.md` (names, owner, rotation, location) covering `.env.example`. Then `/setup-deploy` + `gstack-extras`: for Cloudflare Workers answer its Custom/Manual questions from PLAN §2 (trigger: auto on push, Workers Builds W29; health check: the production URL; merge method: repo setting); for Vercel/Netlify it detects the config file. Its Step 5 curls the URL; a `UNREACHABLE` at this point is expected before the first deploy — it does not block. Copy `Production URL` → `target:` on the `written:` line. Deferred credentials: `AskUserQuestion` (3). Portable: same, by hand.

**Step 3 — Go live.** `AskUserQuestion` (4). Then `gh pr create --base <base> --head <branch> --title "<project>: v2p cycle <n>" --body "REVIEW.md <hash12> · scan <sha12>"`; record `pr:`/`base:`. `/land-and-deploy https://<host>` + `gstack-extras`: first run shows its dry-run and asks to confirm the infrastructure (answer A when it matches `## 0. Target`; C reruns `/setup-deploy`); readiness gate: if it reports the review RECENT/STALE because of the fix commits, choose **C (skip)** citing REVIEW.md and the scan — a fix made there would bypass §2 and the gate's commit accounting; staging-first offer: **A** when a staging/preview target exists (recommended); Vercel/Netlify: it waits 60 s then runs its single-pass canary (Aside absent here → `$B` headless, its own fallback); Workers: same, the health check is the URL. Its verdict must be `DEPLOYED AND VERIFIED`; `REVERTED` → back to Step 1 with the cause as a finding; `DEPLOYED (UNVERIFIED)` → run `/canary … --quick` and, if healthy, ask the user whether to accept (recorded as `accepted:` on a §2 row with check `land-and-deploy`? No — keep §2 to scan findings: an unverified deploy is a stop-and-ask, and the row's path must contain `DEPLOYED AND VERIFIED` to pass). Then `/canary https://<host> --duration 10m` (default pages); `HEALTHY` required. Record both report paths in §1. Portable: merge by hand, `curl -m 10 -sI https://<host>` and say there is no receipt.

**Step 4 — Rollback rehearsal.** The user promotes the previous deployment (Vercel: Deployments → Promote to Production; Cloudflare Workers: Deployments → Rollback or `npx wrangler rollback`; Netlify: Deploys → Publish deploy) and rolls forward; `AskUserQuestion` (5) captures timestamp, elapsed seconds, method; write the `rollback:` line (§3.1) attributed `by user`. Also write the same evidence into the PLAN's named log (live: `docs/slo.md`) as part of the deploy task's docs commit.

**Step 5 — Standards.** Copy REVIEW §3 into draft §3; every `deferred to deploy` row → `done` with evidence from this phase (a command and its output, a report path, a URL), `N/A` citing `BRIEF §`, or `pending | post-launch: <trigger, date>` (`AskUserQuestion` (6) to confirm the post-launch set). Claude-only: `planner` audits read-only, returns rows whose evidence does not prove the item; main thread fixes them.

**Step 6 — Finalize.** Portable: write `.v2p/DEPLOY.md` from the draft; say there is no receipt. Claude-only: `sh <skill>/scripts/finalize-deploy.sh .v2p` until `PASS` (checks §3.3; it re-runs every mechanical PLAN verifier with `<domain>` substituted and curls the live site — expect minutes). A refusal is a stop-and-ask with the output verbatim; never hand-write `DEPLOY.md` or `.deploy-pass`.

**Step 7 — Hand off.** Print the path, the `checked:` counts, `live: https://<host>`, then `Next: live — commit .v2p/DEPLOY.md + .v2p/.deploy-pass on this branch and open the follow-up PR "chore: deploy receipt"; re-theme with /v2p brand; redeploy with /v2p deploy`.

**Claude Code note** (claude-only): main thread runs the gstack skills and asks the questions; the user types `/claude-security …`; `builder`/`quick` fix; `planner` audits §3 read-only. Load `gstack-extras` with any gstack skill. Never `mcp__claude-in-chrome__*`; `/browse` for anything that needs a click. Never read `.env*`; never echo a value from a dashboard into the transcript. Strix only through `installing-third-party-tools`, on the user's yes.

### 3.3 `scripts/finalize-deploy.sh` (~150 lines) — `usage: sh finalize-deploy.sh [.v2p]`, exit 0 PASS · 1 FAIL
Header comment: purpose; `# ponytail: shape checks on the draft (rollback line, accepted reasons) are prose gates — the report files, the stamp, the merge and the live curls are the mechanical ones.` Structure mirrors `finalize-review.sh` (`rows()`, `trim()`, `tmp` files, `fail=0`, all checks printed, write only at the end).
1. `check-pass.sh REVIEW.md .review-pass` OK → else `FAIL: REVIEW.md does not match its receipt (run /v2p review first)`, exit 1. `[ -e DEPLOY.md ] → FAIL: DEPLOY.md exists (redeploy: move it aside first)`, exit 1. Draft exists with `checked:` line.
2. `written:` line: `target: https://<host>` → `host`; `printf '%s' "$host" | grep -qE '^[A-Za-z0-9.-]+$'` and no `..` → else `FAIL: target host '<host>' is not a plain hostname`. `pr: #<n>` and `base: <b>` present → else `FAIL: written: line needs 'pr: #<n> · base: <branch>'`. `sed -n '/^## Deploy Configuration/,/^## /p' CLAUDE.md | sed -n 's/^- Production URL: *//p'` → strip scheme/path → must equal `host` → else `FAIL: target <host> ≠ CLAUDE.md Deploy Configuration Production URL '<u>' (run /setup-deploy)`; no section → `FAIL: CLAUDE.md has no '## Deploy Configuration' (run /setup-deploy)`.
3. DESIGN receipt when `grep -q '\.v2p/DESIGN\.md' PLAN.md` (as `finalize-review.sh:33-34`).
4. §1 rows: `security-full strix setup-deploy land-and-deploy canary` each present with a non-empty run cell → `FAIL: §1 missing <c> row`; security-full result `^[0-9]+ findings?$` → `fs`; strix `^[0-9]+ findings?$` → `fx`, or `^unavailable: .+` → else FAIL; setup-deploy result contains `Deploy Configuration`; land-and-deploy result is a path matching `^\.gstack/deploy-reports/.*\.md$`, file exists, `grep -q '^VERDICT: DEPLOYED AND VERIFIED' <file>` → else `FAIL: deploy report <path> verdict is not DEPLOYED AND VERIFIED`; canary result path `^\.gstack/canary-reports/.*\.json$` exists and `grep -qE '"status": *"HEALTHY"'` → else `FAIL: canary report <path> status is not HEALTHY`.
5. Scan: `scan: CLAUDE-SECURITY-<ts>` on the `written:` line, directory exists; exactly one `CLAUDE-SECURITY-REVISION-*.json` → else FAIL; name contains `-dirty` or `UNVERSIONED` → `FAIL: scan ran on a dirty/unversioned tree`; from the stamp (grep on `"key": value` lines): `"mode": "scan"` else `FAIL: scan mode '<m>' (need a codebase scan)`; `"scope": []` else `FAIL: scan was scoped (need the whole repository)`; `"effort": "high"|"max"` else `FAIL: scan effort '<e>' (need high or max)`; `"status": "verified"` inside the `verification` block else `FAIL: scan verification '<s>'`; `"commit": "<sha>"` inside `revision` → `S`; `git merge-base --is-ancestor S HEAD` else `FAIL: scanned commit <S> is not an ancestor of HEAD`; `"total": <n>` == `fs` else `FAIL: §1 security-full says <fs>, stamp says <n>`; `wc -l` of `CLAUDE-SECURITY-RESULTS.jsonl` == `n` (belt).
6. §2 rows: count == `fs + fx` else `FAIL: §2 rows <k>, §1 findings sum <fs+fx>`; check cell ∈ `security-full|strix`; status `fixed <sha>` (`git cat-file -e`) or `accepted: <reason>`; anything else (incl. `open:`) → `FAIL: §2 status '<s>' (deploy allows fixed <sha> | accepted: <reason>)`. Commit accounting: for each `git rev-list S..HEAD` sha, its full id must equal `git rev-parse` of some `fixed` sha → else `FAIL: commit <sha> after the scan is not a §2 fix (re-run the scan or account for it)`.
7. §3 = REVIEW §3 items (`comm`); `done` ⇒ evidence regex (`→|/|https?://`); `N/A` ⇒ `BRIEF §`; `pending` ⇒ evidence starts `post-launch: `; else FAIL. Counts `sd sa sp`.
8. `rollback:` line matches `^rollback: rehearsed [0-9]{4}-[0-9]{2}-[0-9]{2}T[0-9]{2}:[0-9]{2}(:[0-9]{2})?Z? · elapsed [0-9]+s · method: [^ ].* · by user$` → else `FAIL: rollback line (want 'rollback: rehearsed <ISO> · elapsed <n>s · method: <text> · by user')`; `rs` = seconds.
9. Secrets: `docs/secrets.md` exists else FAIL; names = `sed -n 's/^\([A-Z_][A-Z0-9_]*\)=.*/\1/p' .env.example`; each `grep -q "$name" docs/secrets.md` else `FAIL: docs/secrets.md does not list <name>`; the draft and `docs/secrets.md`: any line matching `<NAME>=[^ <|]` for a listed name, or `sb_secret_|pdl_live_apikey_|pdl_sdbx_apikey_|pdl_ntfset_|whsec_|sk_live_|sk_test_|-----BEGIN ` → `FAIL: secret-looking value in <file>:<line>`; `secrets:` line present with `values: none`.
10. No `^---$`; `grep -q '^Next: live'`.
11. Branch/merge/clean: `xb` = REVIEW `checked:` branch; HEAD on it else FAIL; `git fetch -q origin <base>` (failure → `FAIL: cannot fetch origin/<base>`); `git merge-base --is-ancestor HEAD origin/<base>` else `FAIL: HEAD is not merged into origin/<base> (run /land-and-deploy)`; dirty check as `finalize-review.sh:75-77` but also excluding `.gstack/`, `CLAUDE-SECURITY-*/`, `strix_runs/`.
12. Verifier re-run: rulings = REVIEW.md `ruling:` task numbers ∪ draft `ruling:` lines (draft lines validated as `finalize-review.sh:85-89`); `skipped` = EXECUTE §1 rows whose verifier cell starts `skipped — ` **except** those containing `handed to /v2p deploy`; for each PLAN task not skipped/ruled: extract commands as `finalize-review.sh:93-95`; `c=$(printf '%s\n' "$c" | sed "s|<domain>|$host|g; s|<url>|https://$host|g")`; still an unquoted `<word>` → `left=$((left+1))`, print `skip: task n: <c> (placeholder)`; else run via `sh -c` (`< /dev/null`, output to tmp), same pass rule (exit 0 + bare-number expected) → `FAIL: verifier of task n fails on the live target: <c> exit <r>`; `vp/vt`.
13. Live: `code=$(curl -m 10 -sS -o /dev/null -w '%{http_code}' "https://$host/")` = `200` else `FAIL: https://<host>/ → <code> (want 200)`; `curl -m 10 -sI "http://$host/" | grep -qi '^location: https://'` else `FAIL: http://<host>/ does not redirect to https`. (`curl` from PATH — the tests stub it.)
14. `fail` → `FAIL: DEPLOY.md not written`, exit 1. Else stamp `checked:` (§3.1 shape, `scan <effort> <sha12>`), `mv` draft → `DEPLOY.md`, `shasum -a 256 > .deploy-pass`, `rm -f .v2p/work/deploy-*`, print `PASS: scan <effort> <sha12>, findings <f> (fixed x · accepted a), verifiers <vp>/<vt>, placeholders left <k>, standards done <sd>, post-launch <sp>, canary HEALTHY -> .v2p/DEPLOY.md`.

### 3.4 `hooks/guard-finals.sh` (3 edits)
Add `DEPLOY.md` to both Write/Edit case lists at `:19` (`*/.v2p/DEPLOY.md|.v2p/DEPLOY.md`) and to the Bash regex alternation at `:25` (`(SCAVENGE|AUDIT|PLAN|EXECUTE|REVIEW|PLAN-AMENDMENTS|DESIGN|DEPLOY)`); `.deploy-pass` is already covered by `\.[A-Za-z0-9_.-]*-pass`. Header comment line 2: add `DEPLOY.md`. Still not installed.

### 3.5 `SKILL.md`
- Description: append "…reviews the branch, and ships it behind a full security scan with a live receipt."
- `:18` model guard list adds `deploy`. `:27` Next resolution: `… REVIEW exists and no .v2p/DEPLOY.md → offer deploy; DEPLOY exists → print "live since <written date> at <target>" and offer: redeploy (deploy) or re-theme (brand)`.
- `:64` row → `| deploy | phases/deploy.md | .v2p/DEPLOY.md | available |`. Delete `:66` (no phase is unavailable). `:83` add `DEPLOY layout: references/deploy-template.md (deploy)`. `:89` scripts list adds `finalize-deploy.sh`. `:85` stack refs: "… by execute/review/deploy".

### 3.6 `phases/review.md`, `references/review-template.md`, fixtures
- `review.md:72`: `Next: /v2p deploy`. `:78`: `- Strix is deploy's: optional, needs Docker + an LLM key; never installed here.` `review-template.md:38`: `Next: /v2p deploy`. `tests/fixtures/finalize-review/REVIEW.md` last line the same. `finalize-review.sh` unchanged (it never greps the Next line).

### 3.7 `references/model-routing.md`, `skills-catalog.md`, README, ROADMAP, `build-portable.sh`, `archive-cycle.sh`
- model-routing `:15` → `| deploy | main thread runs the gstack skills and the questions; the user types /claude-security (disable-model-invocation); fixes by builder/quick; planner audits §3 read-only; finalize-deploy.sh by the main thread | per skill; Opus/Sonnet; Fable | /claude-security scan codebase --effort high (required); Strix (optional, Docker + key, installing-third-party-tools on yes); gstack /setup-deploy, /land-and-deploy <url>, /canary <url> + gstack-extras; gh pr create |`. Drift table `:38` → built: what runs = the above; evidence = `CLAUDE-SECURITY-<ts>/` stamp + JSONL, `.gstack/{deploy,canary}-reports/`, DEPLOY §1–§4; gate = `finalize-deploy.sh`.
- skills-catalog Deploy row `:23`: default `/setup-deploy`, `/land-and-deploy`, `/canary` (installed, `~/.claude/skills/<name>`; GitHub-only; PR required; Aside absent → `$B` headless; writes `.gstack/`); `/ship` present but not routed (review army/version bump duplicate v2p review; PR via `gh pr create`); `/cso` not routed. Security row `:20`: Strix — `usestrix/strix` (Apache-2.0, ~64.8k★ per README 2026-09-25; installer `curl -sSL https://strix.ai/install | bash` — read before running; Docker running + `STRIX_LLM`/`LLM_API_KEY`; `strix --target .`; results `strix_runs/<run>`; view `strix view`); status `suggested`, not installed, Docker absent here; the full `claude-security` scan (`--effort high`, whole repo) is the deploy gate.
- README `:26` → `| deploy | .v2p/DEPLOY.md | available |`; file map +`phases/deploy.md`, `references/deploy-template.md`, `scripts/finalize-deploy.sh`, `tests/test-finalize-deploy.sh` + fixture; verify block +2 lines (§8 checks 1, 3).
- ROADMAP: `## Slice 5: deploy (built <date>)` — the paragraph of this spec's conclusion in three lines; tier table `:30` "before deploy" → `finalize-deploy.sh`; open item "Strix live test (Docker) and the first real deploy of the fixture (needs a GitHub remote)".
- `build-portable.sh:14`: `phases/execute.md phases/review.md phases/deploy.md references/execute-template.md references/review-template.md references/deploy-template.md`.
- `archive-cycle.sh:19`: list becomes `PLAN.md EXECUTE.md REVIEW.md DEPLOY.md PLAN-AMENDMENTS.md .plan-pass .execute-pass .review-pass .deploy-pass` (each only if present; `test-finalize-brand.sh:77` still sees 7 files).

***

## 4. What each routed tool does (from its file)

| Tool | What it does | Where deploy uses it |
|---|---|---|
| `claude-security` 0.11.0 | Menu → `scan codebase [--scope] [--effort low|medium|high|max]`; confirms cost once; researchers + 3-voter panel; writes `CLAUDE-SECURITY-<ts>/` (MD, JSONL, SARIF, revision stamp) behind its own `.gitignore`; never commits (`jobs/scan-codebase.md`, README) | Step 1, required; stamp parsed by the gate |
| Strix | Docker-run AI pentest agents; `strix --target <dir|url>`; `strix_runs/<run>` (README) | Step 1, optional, white-box on the repo |
| `/setup-deploy` | Detects platform (no Workers rule), asks URL/trigger/health/merge method, writes CLAUDE.md `## Deploy Configuration`, curls the URL (`SKILL.md:419-604`) | Step 2; source of `target:` |
| `gh pr create` | PR from the review branch | Step 3 |
| `/land-and-deploy <url>` | gh auth, PR, first-run dry-run + fingerprint, CI wait, readiness gate, merge (`gh pr merge --delete-branch`), deploy wait per platform, single-pass canary (Aside/`$B`), revert path, report + verdict (`SKILL.md:614-999`) | Step 3 |
| `/canary <url> --duration 10m` | page discovery, 60 s rounds, alerts on change vs baseline, report MD+JSON with `status` (`SKILL.md:511-707`) | Step 3 |
| `gstack-extras` | pattern anchoring, positive controls, "zero found needs a planted control" | with every gstack skill |

***

## 5. Tests (one falsifier per check)

**`tests/fixtures/finalize-deploy/DEPLOY.md`** (~45 lines, bad on purpose): `target: https://fixture.test;rm` (bad charset — fixed first so later checks see a host), no `canary` row, strix result `maybe`, §2 row `open: later`, §3 first row `pending | |`, `rollback: soon`, a line `RESEND_API_KEY=re_abcdefghijklmnopqrstuvwxyz`, a `---` rule, no `Next: live`. Placeholders `{{HEAD}}`, `{{SCAN}}`, `{{STANDARDS_ROWS}}` filled at test time.

**`tests/test-finalize-deploy.sh`** (~150 lines; style of `test-finalize-review.sh`: scratch under `${TMPDIR:-/tmp}/v2p-fd.<pid>`, `HOME` redirected, `for SH in sh zsh`, source hashes before/after, `is/has/hasnt`):
Setup per shell: `fixture-execute.sh`; append `### Task 4: Deploy runbook` (`**Files:** Modify: \`docs/secrets.md\``, `**Verifier:** manual: dashboards; then mechanical: \`curl -m 10 -sI https://<domain> | grep -q 'HTTP/2 200'\` → exit 0`) and `### Task 5: Chunk map` (Verifier `curl -m 10 -sI https://<domain>/_next/<chunk>.js.map | grep -q 404` → stays a placeholder) to PLAN, re-seal `.plan-pass`; execute short path: task 1 pass, `defer 2 "VERCEL_TOKEN"`, `skip 3 "handed to /v2p review"`, `skip 4 "handed to /v2p deploy"`, `skip 5 "handed to /v2p deploy"`; finalize-execute; review draft from the good review fixture path (as test-finalize-review steps 1–6) → finalize-review PASS. Then: `docs/secrets.md` listing `RESEND_API_KEY`; `.env.example` with `RESEND_API_KEY=`; `CLAUDE.md` with `## Deploy Configuration` `- Production URL: https://fixture.test`; commit; bare `origin.git`, `git push -q origin HEAD:main`; fake `curl` in `$fk/curl` (prints `HTTP/2 200` for `-I https://…`, `location: https://fixture.test/` for `http://…`, `200` for `-w`, and `500`/no location when `FAKE_DOWN=1`), `PATH=$fk:$PATH` only for the gate runs; scan dir `CLAUDE-SECURITY-20260925-120000/` with `CLAUDE-SECURITY-RESULTS.md`, one-line `.jsonl` (`{"id":"F1","severity":"HIGH",…}`), stamp `CLAUDE-SECURITY-REVISION-<HEAD12>.json` written with the real key shape (`"mode": "scan"`, `"scope": []`, `"revision": {"commit": "<HEAD>", "dirty": false}`, `"effort": "high"`, `"findings": {"total": 1, …}`, `"verification": {"status": "verified"}`); `.gstack/deploy-reports/2026-09-25-pr1-deploy.md` with `VERDICT: DEPLOYED AND VERIFIED`; `.gstack/canary-reports/2026-09-25-canary.json` with `"status": "HEALTHY"`.
0. Bad draft → exit 1; output has: `target host`, `§1 missing canary row`, `strix … 'maybe'`, `§2 status 'open: later'`, `pending without post-launch`, `rollback line`, `secret-looking value in .v2p/DEPLOY.draft.md`, `'---' rule`, `no 'Next: live'`; no `DEPLOY.md`, no `.deploy-pass`.
1–9. Fix one at a time; each named FAIL disappears; final exit 0, `PASS: scan high <HEAD12>, findings 1 (fixed 1 · accepted 0), verifiers 3/3, placeholders left 1, …, canary HEALTHY`; `run: task 2:` (deferred re-run) and `run: task 4: curl -m 10 -sI https://fixture.test` present; `skip: task 5:` present; draft gone; receipt = shasum; `.v2p/work/deploy-x.md` removed.
10. Falsifiers on the good draft (restore between; each expects exit 1 + the named FAIL, nothing written): stamp renamed `…-dirty.json` → `dirty/unversioned`; `"effort": "medium"` → `scan effort`; `"scope": ["src"]` → `scoped`; `"status": "unverified"` → `scan verification`; stamp `commit` = `HEAD~1` with the top commit **not** a §2 fix → `commit … after the scan is not a §2 fix`; same with the top commit listed as `fixed <sha>` → PASS; `VERDICT: REVERTED` → `verdict is not`; canary `"status": "DEGRADED"` → `status is not HEALTHY`; origin reset to `HEAD~1` (`git push -f origin HEAD~1:main`) → `not merged into origin/main`; `FAKE_DOWN=1` → `https://fixture.test/ → 500` and `verifier of task 4 fails on the live target`; `Production URL: https://other.test` in CLAUDE.md → `≠ CLAUDE.md`; remove the section → `no '## Deploy Configuration'`; `docs/secrets.md` without `RESEND_API_KEY` → `does not list`; `sb_secret_abc` in `docs/secrets.md` → `secret-looking value in docs/secrets.md`; a REVIEW `ruling: task 2 · plan defect · x` (re-seal `.review-pass` in the test, as test-finalize-review does) → `ruling: task 2 verifier not re-run` and `rulings 1`; `rm .v2p/.review-pass` → exit 1 `does not match its receipt`; existing `DEPLOY.md` → `exists (redeploy`; `git status` with `?? .gstack/x` → still PASS (excluded) while `?? src/new` → `uncommitted`.
11. Parser falsifier (as brand test 14): rename `"mode"` → `"modx"` in the stamp → `scan mode ''`; proves the grep reads the field, not the file's presence.
12. Source fixture untouched (hash).

**`tests/test-guard.sh`** +3: `W 2 Write "$P/.v2p/DEPLOY.md"`, `B "echo x > .v2p/.deploy-pass"`, `A "sh $S/finalize-deploy.sh .v2p"`, `W 0 Write "$P/.v2p/DEPLOY.draft.md"`.
`tests/test-build.sh`: no edit; it already checks marker balance for every file with `claude-only` and that `AskUserQuestion`/`subagent_type` never reach the pack.

***

## 6. The live case (grooming fixture)
State: REVIEW sealed at `77c6260`, HEAD `15ff1f3`, 34 deferred rows, Task 18 handed to deploy, 0 deferred credentials, no remote, no `CLAUDE.md` deploy config, hosting Vercel Pro (BRIEF must-have). Path once a GitHub remote exists: `/v2p deploy` → Step 1 scan (tens of minutes on ~19-task repo; ask `high`) → Step 2 = Task 18 steps 1–9 with the user (Vercel import, Cloudflare DNS-only, Resend DNS, Cal.com webhook, Sentry/PostHog/GTM/GSC, WAF rule, uptime, `docs/secrets.md`, DPAs) then `/setup-deploy` (detects `.vercel`/`vercel.json` or asks; URL = the custom domain) → Step 3 PR + `/land-and-deploy https://<domain>` (Vercel: 60 s wait, `$B` canary) + `/canary` → Step 4 rollback via Vercel "Promote to Production", logged in `docs/slo.md` → Step 5: 34 rows (DNS/SSL/HTTPS/GSC/Bing/broken links/DAST via the CI `preview-audit` job/Lighthouse on the live URL → `done`; CWV, CSP enforcing, Analytics first hit → `post-launch:`) → finalize: Task 18's six sub-checks run with `<domain>` substituted (the `dig` ones need the real DNS), review's ruling for task 5 honoured.

***

## 7. Open questions (recommended first)

1. **PR creation.** (a) `gh pr create` from the phase **(Recommended: v2p review already reviewed and sealed; `/ship` re-reviews, bumps VERSION and edits CHANGELOG — commits outside v2p's ledger)**; (b) `/ship`, accepting its extra commits as `fixed`-style rows.
2. **Full-scan tier.** (a) `--effort high`, gate accepts `high|max` **(Recommended: the plugin's own top-but-one tier; `max` cost unknown)**; (b) require `max`.
3. **Strix target.** (a) repo only, before the merge **(Recommended: white-box, no traffic to a live site; decision 2 keeps v2p provider-agnostic)**; (b) also the preview/staging URL on the user's yes; (c) production — no.
4. **Rows that need traffic.** (a) `pending | post-launch: <trigger, date>` allowed and counted **(Recommended: CWV field data and a 24 h CSP Report-Only window cannot exist at launch; the count is in the receipt)**; (b) every deferred row must be `done` (blocks launch on things launch produces).
5. **Where the receipt lands.** (a) commit on the review branch + follow-up PR `chore: deploy receipt` **(Recommended: never on the default branch; the merged code is verified by the `origin/<base>` ancestry check, not by where the receipt sits)**; (b) switch to `<base>` and commit there.
6. **Rollback evidence.** (a) user-attributed `rollback:` line, shape-checked, plus the PLAN's log doc **(Recommended: provider-agnostic; same strength as `manual:` records)**; (b) a mechanical version probe during the rehearsal (needs a per-provider header/version endpoint — contradicts decision 2).
7. **Readiness-gate answer.** (a) answer C (skip inline review) citing REVIEW.md + scan **(Recommended: keeps the commit accounting exact)**; (b) answer A (quick checklist) and, if it commits fixes, re-run the scan before the merge.

***

## 8. Verification plan for the builder

1. Router: `grep -cE '^\| `deploy` \| `phases/deploy\.md` \| `\.v2p/DEPLOY\.md` \| available' skills/v2p/SKILL.md` → 1; `grep -rc 'not available in this version' skills/v2p tests/fixtures README.md` → 0 everywhere. Falsifier: `available`→`planned` in a scratch copy → 0.
2. Referenced paths in `phases/deploy.md`, `references/deploy-template.md` (`scripts/[a-z-]+\.sh`, `references/…`) all exist → no `MISSING`. Falsifier: `scripts/nope.sh` in scratch → one `MISSING`.
3. `sh tests/test-finalize-deploy.sh | tail -1` → `test-finalize-deploy: 0 failures`; `test-guard.sh`, `test-finalize-review.sh`, `test-finalize-brand.sh`, `test-execute.sh`, `test-finalize-plan.sh`, `test-tidy.sh`, `test-build.sh` → 0 failures each.
4. Syntax: `for s in skills/v2p/scripts/*.sh skills/v2p/hooks/*.sh tests/*.sh; do sh -n "$s" && zsh -n "$s"; done` → no output.
5. Stamp parser against a **real** stamp: run `python3 <plugin>/scripts/render_report.py --help` to confirm the CLI, or take a stamp from any prior `CLAUDE-SECURITY-*/` directory on this machine (`find ~ -maxdepth 4 -name 'CLAUDE-SECURITY-REVISION-*.json' 2>/dev/null | head -1`) and feed it to the gate's grep block in a scratch shell: `mode`, `scope`, `effort`, `verification.status`, `revision.commit` all resolve. Falsifier: rename a key → empty value → FAIL text names it.
6. Substitution safety: `host='fixture.test'` → `sed` output equals the command with the host; `host='a;b'` → check 2 refuses before any `sh -c` runs (grep `run:` absent in the output). Falsifier: bypass check 2 in a scratch copy and confirm the `;` would have reached `sh -c` (proves the check is load-bearing).
7. Hook: test-guard cases for `.v2p/DEPLOY.md` → 2, `.v2p/DEPLOY.draft.md` → 0, `echo x > .v2p/.deploy-pass` → 2, `sh …/finalize-deploy.sh .v2p` → 0.
8. Portable build: `sh build-portable.sh`; `grep -c '<!-- source: phases/deploy.md -->' dist/v2p-portable.md` → 1; `grep -c 'deploy-template' dist/…` ≥ 1; `grep -c 'AskUserQuestion\|claude-only\|finalize-deploy\|subagent_type\|/claude-security' dist/…` → 0 (the `/claude-security` invocation lives in a claude-only block); copyright count 1.
9. Tidy on the deploy fixture after the fake reports exist: `sh skills/v2p/scripts/tidy-check.sh --tsv | grep -c 'gstack\|CLAUDE-SECURITY'` → 0. Falsifier: `touch strix_runs/x.log` → 1 (`log … quarantine`) — documents the Strix caveat.
10. README: `grep -c '| available |' README.md` → 8; `grep -c 'deploy' skills/v2p/references/model-routing.md` ≥ 3; `grep -c 'strix.ai/install' skills/v2p/references/skills-catalog.md` → 1.
11. Live (user, later, on a **copy** of the fixture pushed to a throwaway GitHub repo; never the real one): `/v2p deploy` → preconditions print; `/claude-security scan codebase --effort high` produces a stamp with `"mode": "scan"`; a §2 fix commit → gate accounts it; `/setup-deploy` writes the section; `gh pr create`; `/land-and-deploy <url>` → `DEPLOYED AND VERIFIED`; `/canary` → `HEALTHY`; `finalize-deploy.sh … PASS`. Falsifiers: `echo x >> .v2p/REVIEW.md` → `Run /v2p review first.`; `--effort medium` → the gate refuses; a commit after the scan without a §2 row → refuses.

***

## 9. Risks, pushback, unverified

- **No real deploy was run** (decision 3): every gstack step above is from its SKILL.md; the report and JSON shapes the gate greps (`VERDICT:` line, `"status": "HEALTHY"`) are the documented ones at `land-and-deploy/SKILL.md:962-979` and `canary/SKILL.md:687-691`; a future gstack release that changes them breaks check 4 loudly (FAIL), not silently.
- **GitHub-only, PR-required** (`land-and-deploy`): GitLab and no-remote projects get the portable path (no receipt). The live fixture is in that state today.
- **Cloudflare Workers via setup-deploy's Custom path**: the questions are answered from PLAN §2; unverified live. Workers Builds auto-deploys on push (W29), so land-and-deploy's "wait 60 s then canary" strategy applies by the URL health check, not by platform detection (its Strategy D reads the custom hooks from CLAUDE.md, `:812-814`).
- **`$B` headless browser** instead of Aside on this machine: canary/land-and-deploy translate their scripts (`canary/SKILL.md:410-455`); first use may need `./setup` (10 s build) — the skill asks.
- **Strix**: README-level facts only (fetched, summarised); `curl | bash` installer flagged; Docker absent here, so the row is `unavailable` until the user installs Docker. Its `strix_runs/` may hold logs tidy flags.
- **Prose gates**: `rollback:` line, `accepted:` reasons, `by user` attribution — shape-checked only (stated). Everything else in the receipt is mechanical.
- **Secret regex** is a denylist (vendor prefixes from `wiring.md:3` + `NAME=value` for `.env.example` names): a value with no known prefix under a name not in `.env.example` passes. Ceiling documented in the script header.
- **Commit accounting** requires the scan to run on committed HEAD; a `-dirty` stamp fails by design; users who scan first and commit later must rescan.
- **`git fetch` in the gate** needs network; tests use a local bare remote.
- **Hook still uninstalled**; subagent hook firing unverified (slice 3 note).

**Paths.** Repo `/Users/user/SynologyDrive/code/ai/claude/Projects/personal_skills/vibe-to-product/`: `skills/v2p/SKILL.md`, `skills/v2p/phases/{review,execute,brand,mapping}.md`, `skills/v2p/references/{review-template,execute-template,plan-template,model-routing,skills-catalog}.md`, `skills/v2p/references/stack/{wiring,security,overview}.md`, `skills/v2p/references/standards/{core,web}.md`, `skills/v2p/scripts/{finalize-review,finalize-execute,check-pass,task-record,archive-cycle,tidy-check,drift-check}.sh`, `skills/v2p/hooks/{guard-finals.sh,hooks.json}`, `tests/{test-finalize-review,test-finalize-brand,test-guard,test-build,fixture-execute}.sh`, `tests/fixtures/finalize-review/REVIEW.md`, `build-portable.sh`, `README.md`, `docs/ROADMAP.md`, `docs/specs/slice-6-spec.md`. Live fixture `/Users/user/tmp/v2p-exec/.worktrees/v2p-execute-2026-09-24/{.v2p/REVIEW.md,.v2p/EXECUTE.md,.v2p/PLAN.md,.env.example,docs/}`. Skills `/Users/user/.claude/skills/{setup-deploy,land-and-deploy,canary,ship}/SKILL.md`, `/Users/user/.claude/skills/gstack/land-and-deploy/sections/{readiness-gate,merge-and-deploy,first-run-validation}.md`, `/Users/user/.claude/skills/gstack/browse/dist/browse`. Plugin `/Users/user/.claude/plugins/cache/claude-plugins-official/claude-security/0.11.0/{README.md,skills/claude-security/SKILL.md,skills/claude-security/jobs/scan-codebase.md,skills/claude-security/specs/report-spec.md,scripts/render_report.py,scripts/write_scan_meta.py,scripts/lib/{finding,plugin}.py}`.