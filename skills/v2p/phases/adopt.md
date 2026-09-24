# v2p phase: adopt

## Purpose
Bring an existing or half-built project under v2p: scan it, derive the BRIEF from what exists, audit it against the standards, create the missing canonical files, merge scattered notes, and quarantine debris with the user's approval.
Nothing is refactored here. Writes `.v2p/BRIEF.md` and `.v2p/AUDIT.md`.

## Preconditions
- The router ran the probe. Portable: ask the user to paste `ls -a` and `git status --short`.
<!-- claude-only -->
  Claude Code: `sh <this skill's dir>/scripts/tidy-check.sh --probe` prints `root:<abs> code:yes|no git:none|clean|dirty:<n> branch:<b> brief:yes|none audit:yes|no`.
<!-- /claude-only -->
- `.v2p/BRIEF.md` exists → say "BRIEF kept; running audit + tidy", run Step 0 and Step 1, then skip Steps 2–3. (This is also the manual re-tidy path.) Step 1 still runs because AUDIT §1 and §3 come from the scan.
- `.v2p/AUDIT.md` exists and passed its check → offer resume (keep) or re-run.
<!-- claude-only -->
  "Passed its check" = `sh <this skill's dir>/scripts/check-pass.sh .v2p/AUDIT.md .v2p/.audit-pass` prints `OK`.
<!-- /claude-only -->
- Checkpoints: list `.v2p/work/adopt-*`. A file is reusable when its line-1 `written:` date is today and its `brief:` equals the current BRIEF's `written:` date (or `none` when there is no BRIEF yet); print "resuming from <files>" and skip the step that wrote it. Any other file is stale: overwrite it, never read it. `.v2p/work/` files are the only legitimate resume source; memory and prior-session summaries are leads to re-check, not evidence.

## Step 0 — Git safety
- No git → continue, no branch.
- Dirty tree → print the changed tracked paths (`git status --porcelain | grep -v '^??'`), then: "Uncommitted changes stay untouched: no stash, no commit, no branch switch; quarantine will refuse these paths." Continue.
- Clean tree → ask: "Create branch `v2p/adopt-<YYYY-MM-DD>` for adopt's files? (Recommended: one commit to review or drop) / Stay on `<branch>`". Only on yes: `git switch -c v2p/adopt-<YYYY-MM-DD>`.
- v2p never commits, stashes, resets or switches on a dirty tree. The closing message tells the user what to commit.

## Step 1 — Scan
Budget: read ≤40 files, never the whole tree; use search and symbol lookups. Write `.v2p/work/adopt-scan.md`; line 1 is `written: <YYYY-MM-DDTHH:MM> · phase: adopt · part: scan · brief: <BRIEF written date | none>`, then exactly these headings:
```
## Manifest & stack: <manifest path> · framework/runtime · notable deps (auth, payments, db, i18n, analytics, mobile, graphql, uploads/storage)
## Entry points: <routes/pages/commands with paths, ≤15>
## Login: yes|no · evidence <path:line>
## Payments SDK: yes|no · evidence
## i18n: yes|no · evidence · locales seen
## Env vars referenced: <n> · names only (never values) · .env.example: present|missing
## Tests: <runner|none> · <n> test files
## Files >200 lines: <path:lines, ≤10>
## Docs found: README first heading + first paragraph verbatim · other .md/.txt notes: <path — one-line gist>
## Deps created <6 months: <pkg (created date)|none> — `npm view <pkg> time.created` or the ecosystem equivalent
## TODO/FIXME: <n> (`rg -c 'TODO|FIXME'`)
## Module map: top-level dirs under src/ (or app/, lib/) with file counts · cross-module internal imports found: <n> (rg pattern from core.md Modularity item 3) · cycles: <n|not checked (tool)>
## Brand signals: theme/tokens/logo/tailwind config paths | none
```
Portable: ask the user to paste `git status --short`, `find . -path ./node_modules -prune -o -type f -print | head -300`, the manifest, README.md and any NOTES/TODO/ideas files; fill the headings from those.

## Step 2 — Prefill the BRIEF
| BRIEF field | From scan | Rule | §10 status |
|---|---|---|---|
| §1 Profile | Login, Payments, Manifest (Expo/RN/Swift/Kotlin/Flutter) | mobile framework → `native-app`; no login and one form/CTA → `landing`; login → `saas-web` or `internal-tool` (ask the disambiguator "Do users work for you?") | inferred (+ answered for the disambiguator) |
| §1 Code | root | `existing at <root>` | inferred |
| §1 Vision / Breaks without it | README first paragraph | verbatim; "breaks" asked if README does not say | inferred / asked |
| §3 The one job | Entry points | main route or command, one line; confirm at the gate | inferred |
| §6 Brand | Brand signals | signals → `existing (source: <path>)`; none → `to-create` | inferred |
| §6 Locales | i18n | locales seen, else `one` | inferred / defaulted |
| §8 Must-have | Manifest & stack | framework + db + auth as found | inferred |
| §8 Existing accounts | Env var names | prefixes → providers (`STRIPE_`, `SUPABASE_`, `CLERK_`, `RESEND_`, `SENTRY_`, `POSTHOG_`, `PADDLE_` …) | inferred |
| §8 Money model | Payments SDK | present → ask which model; absent → `none` | asked / inferred |
| §8 Integrations | Env vars + deps | list | inferred |
| §9 blocks | derived | payments/webhooks/i18n/AI feature from deps and env names; GraphQL from graphql deps or `*.graphql` schema files; file uploads from multipart/upload handlers or a storage SDK; special-category data from health/medical fields in the schema | inferred |
| §2, §4, §5, §7 | — | cannot be inferred: always asked (Q2, Q5, Q6, Q9), ≤3 per turn | answered / defaulted |

Every `inferred` row's value cell ends with `← <source path>`. Gaps that block a section get `[NEEDS CLARIFICATION: …]` markers as in `phases/handshake.md`.

## Step 3 — Gate and write
Run `phases/handshake.md` §Confirmation gate and §Write step verbatim. Extra: the running brief shows `(inferred)` after each inferred value so the user sees what to correct. §1 Code = `existing at <root>`.

## Step 4 — Audit draft
Write `.v2p/AUDIT.draft.md` from `references/audit-template.md` (never `AUDIT.md`):
- §1 from the scan.
- §2 one row per `- [ ]` item of the BRIEF §9 standards files. `done` only with evidence gathered now (a command run in this session with its output, or a path from the scan); `N/A — BRIEF §n` for blocks OFF; else `pending`.
- §3 one row per core.md "Modularity" item, evidence from the scan's module map.
- §4 left as the template placeholder; the finalize step fills it.
- §5 filled in Step 5.

## Step 5 — Canonical files and merges
Run the tidy check (`references/tidy-rules.md`) and show its table. Create only the **missing** canonical files; never overwrite:
- `README.md`: BRIEF §1 vision + how to run, from the manifest.
- `CHANGELOG.md`: `## Unreleased` + one line "adopted by v2p <YYYY-MM-DD>".
- `docs/ARCHITECTURE.md`: module map from the scan + one data-flow line.
- `docs/DECISIONS.md`: merged notes, or `none yet`.
- `.env.example`: env var names with empty values, only if a `.env*` file exists.
- `.gitignore` lines `.v2p/work/` and `.v2p/*.draft.md` when missing.

For each `merge:<dest>` row, append to `<dest>` a section `## From <path> (merged <YYYY-MM-DD>)` with the original content verbatim. README duplicates: only the parts not already in README.md; say what was dropped. Show the added sections (`git diff -- <dest>` when tracked, or the section text) before anything moves, and list the pair in AUDIT §5.
Portable: print each new file in a code block.

## Step 6 — Quarantine
Always dry-run first and show every `MOVE` / `REFUSE` line. Then ask: "Quarantine these <n> items to `~/.v2p-backups/<project>/<ts>/` (restore command provided)? (Recommended) / Skip (record `quarantine: declined`)". Rows the user excludes are removed from the list before applying. Refused rows stay listed in AUDIT §4 as they are: they are the safety net, not failures. Write `quarantine: <manifest path>` or `quarantine: declined` into the draft's §4.
Portable: move approved items by hand as described in `references/tidy-rules.md` §6; no receipts.
<!-- claude-only -->
Commands: `mkdir -p .v2p/work && sh <skill>/scripts/tidy-check.sh --tsv > .v2p/work/adopt-tidy.tsv; sh <skill>/scripts/quarantine.sh < .v2p/work/adopt-tidy.tsv` (dry-run). Excluded rows: `grep -v` them out of `adopt-tidy.tsv`. On yes: `sh <skill>/scripts/quarantine.sh --apply < .v2p/work/adopt-tidy.tsv`, then print its last three lines (manifest, restore, counts). Use `AskUserQuestion` for the branch question (Step 0) and this approval.
<!-- /claude-only -->

## Step 7 — Finalize
Portable: write `.v2p/AUDIT.md` from the draft as `references/audit-template.md` says.
<!-- claude-only -->
Run `sh <skill>/scripts/finalize-audit.sh .v2p` until it prints `PASS`. It fills §4 from `tidy-check.sh`, checks the §2/§3 counts, the evidence and the merges, writes `AUDIT.md` and the receipt `.v2p/.audit-pass`, and clears `.v2p/work/adopt-*`. On `FAIL`, fix what it names and run it again. Never write `AUDIT.md` by hand.
<!-- /claude-only -->

## Step 8 — Hand off
Print the paths written, the quarantine restore command, "commit: `.v2p/ docs/ README.md CHANGELOG.md .env.example .gitignore`", then `Next: /v2p scavenge`.

<!-- claude-only -->
## Claude Code note
- Step 1 runs in a `quick` subagent (Sonnet), which writes `.v2p/work/adopt-scan.md` itself before returning. On resume, spawn nothing.
- Tools: Serena is installed (`find_symbol`, `get_symbols_overview`, `find_referencing_symbols`); `rg` always. code-review-graph is not installed on this machine (measured 2026-09-23: `command -v code-review-graph` empty); offer to install it through the `installing-third-party-tools` skill only when the scan needs impact radius or cycles, and only on the user's yes.
- `claude-mem:learn-codebase` is optional and never a source of findings: the scan file is the only legitimate resume source.
- The main thread runs the gate (it needs `AskUserQuestion`) and the scripts. `quick` may write the audit draft; `planner` never writes.
<!-- /claude-only -->

***
Copyright © 2026 Rafael Arciniegas. Licensed under the MIT License.
