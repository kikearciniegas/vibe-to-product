# v2p SLICE 3 — implementation spec (adopt + tidy + checkpoints + hook proposal)

## User decisions 2026-09-23 (locked)
- PLAN.md is covered: build `scripts/finalize-plan.sh` (§3.8) and the mapping edit, so every handoff file gets a receipt.
- Adopt offers `git switch -c v2p/adopt-<date>` only on a clean tree and only when the user says yes (§2 "Parallel-session safety" as written).
- No time-based refusal in quarantine.sh (§7, as advised). The hook is built into `skills/v2p/hooks/` but NOT installed; installing it is a separate user decision.

**Conclusion first.** Build 11 new files, edit 10. Adopt is **both** auto-detected (code present, no `.v2p/BRIEF.md`) and explicit (`/v2p adopt`); it replaces the handshake for existing code, reuses the handshake's own confirmation gate, and moves scavenge Q6 into its scan (no duplication). Every write that matters goes through a script gate that demands positive evidence: `tidy-check.sh` (read-only, exit 1 on violations), `quarantine.sh` (dry-run default, sha-verified moves, manifest + `restore.sh`, refuses never-touch/outside/symlink/gitignored/uncommitted), `finalize-audit.sh` (row counts vs standards files, evidence on every `done`, tidy output inserted by the script itself, merges verified, receipt `.v2p/.audit-pass`), and mapping refuses an AUDIT without a matching receipt via the existing `check-pass.sh`. Two scripts are **prototyped and tested** in this session against the fixture under both `sh` and `zsh` (byte-identical output); they are reproduced below verbatim so the builder copies rather than re-decides.

Three things the user should hear before the builder starts (details in §7): (1) the PreToolUse hook needs `.v2p/PLAN.md` to also get a finalize script, or PLAN must be dropped from the hook list — I include a 15-line `finalize-plan.sh` so the hook list matches the ask; (2) `quarantine.sh` does not refuse recently-modified untracked files; the only guards against clobbering a parallel session are pattern-scoped targeting, the uncommitted-changes refusal (tracked files), and the age column in the list the user approves — a time-based refusal is deliberately not built; (3) the `~/.agents/skills/` path the user's CLAUDE.md §7 treats as scatter is one of Gemini CLI's documented discovery locations (from search snippets of the official doc; page not fetched) — the plugin roadmap will collide with that rule.

Everything below was measured or run by me today unless marked `(unverified)` or "reported by coordinator". Live-session behaviour (dry-runs) is unverified by construction.

***

## 1. File tree delta

```
vibe-to-product/
├── build-portable.sh                       # MODIFIED: +3 parts (phases/adopt.md, references/audit-template.md, references/tidy-rules.md)
├── README.md                               # MODIFIED: phases table (adopt), file map, verify lines, item count
├── docs/specs/slice-3-spec.md              # NEW: this document, saved verbatim
├── tests/
│   ├── fixture-messy.sh                    # NEW (10 lines): builds the messy sample project
│   └── test-tidy.sh                        # NEW (~45 lines): runs tidy-check + quarantine falsifiers under sh and zsh
└── skills/v2p/
    ├── SKILL.md                            # MODIFIED: description, §1 runtime note, §2 entry (probe + adopt), §5 row, §6 refs
    ├── phases/
    │   ├── adopt.md                        # NEW (~120 lines)
    │   ├── handshake.md                    # MODIFIED: Q0 routes existing code to adopt; §10 states gain `inferred`
    │   ├── scavenge.md                     # MODIFIED: Q6 from AUDIT §1; checkpoints; resume; finalize requires work files
    │   └── mapping.md                      # MODIFIED: AUDIT receipt precondition; §4 copies AUDIT §2; PLAN.draft + finalize-plan
    ├── references/
    │   ├── audit-template.md               # NEW (~50 lines) — portable
    │   ├── tidy-rules.md                   # NEW (~75 lines) — portable
    │   ├── brief-template.md               # MODIFIED: §1 Code line, §10 header
    │   ├── model-routing.md                # MODIFIED: adopt row; "Drift checks (slice-4 contract)" section
    │   ├── skills-catalog.md               # MODIFIED: brownfield row install rule; Strix in security row
    │   └── standards/core.md               # MODIFIED: new "## Modularity" section (6 items) → item counts change
    ├── scripts/
    │   ├── tidy-check.sh                   # NEW (65 lines, tested)
    │   ├── quarantine.sh                   # NEW (65 lines, tested)
    │   ├── finalize-audit.sh               # NEW (~50 lines)
    │   ├── finalize-plan.sh                # NEW (~15 lines)
    │   └── finalize-scavenge.sh            # MODIFIED: +3 lines (require .v2p/work checkpoints; clear them on PASS)
    └── hooks/                              # NEW dir — PROPOSAL, nothing installed by the builder
        ├── guard-finals.sh                 # NEW (~15 lines)
        └── hooks.json                      # NEW (plugin-format snippet)
```

Conventions carried: `***` not `---`; copyright line last on every `.md`; `(verified: 2026-09)` with URL on the same line; `<!-- claude-only -->` blocks stripped by the build; scripts POSIX `sh`, no `[[ ]]`, no arrays, no `for x in $unquoted`, no `echo` of a value that may start with `-` (zsh prints nothing for `echo -`; use `printf '%s\n'` — found in testing).

Why 11 files and not fewer: each script is a gate the lesson says prose cannot replace; `hooks/` is a proposal the user asked to see in shippable form; `tests/` is the one runnable check the scripts leave behind and the seed of the roadmap's regression suite. Not built: a `finalize.sh` umbrella (would churn the live scavenge gate), a time-based "recent file" refusal, per-framework canonical layouts.

***

## 2. Design questions — answers

**Router entry.** Both. Auto-detect through a script, not a judgement: `sh <skill>/scripts/tidy-check.sh --probe` prints one line `root:<abs> code:yes|no git:none|clean|dirty:<n> branch:<b> brief:yes|none audit:yes|no`. `code:yes` = a manifest exists (package.json, pyproject.toml, requirements.txt, go.mod, Cargo.toml, Package.swift, pubspec.yaml, build.gradle(.kts), Gemfile, composer.json) or any source file (`ts tsx js jsx py go rs swift kt java rb php dart vue svelte`) outside `.git/`, `node_modules/`, `.v2p/`. Rules: `brief:yes` → existing resume logic; `brief:none code:yes` → `AskUserQuestion` "Existing code found: Adopt it (scan, derive BRIEF, audit, tidy) (Recommended) / Fresh handshake (ignores the code)"; `brief:none code:no` → handshake as today. `/v2p adopt` always runs adopt; with an existing BRIEF it skips derivation and runs audit + tidy only (this is also the manual re-tidy path). Docs-only folders (README + notes, no code) go to handshake; the router prints one hint line that `/v2p adopt` merges notes.

**BRIEF derivation.** A `quick` subagent scans (≤40 files, Serena → code-review-graph if installed → `rg`) and writes `.v2p/work/adopt-scan.md` itself. The main thread prefills the BRIEF from the scan with a fixed source table (§3.1 below); every prefilled value gets a §10 row `inferred` whose value cell names the source path. Then the **handshake gate from `phases/handshake.md` runs unchanged**: only questions whose value could not be inferred are asked (always: Q2 numbers, Q5 metric + acceptance, Q6 non-goals, Q9; plus the one disambiguator when login code exists), ≤3 per turn, explicit yes/ok/confirmed, §11 literally `none`. Not a second interview implementation — adopt.md says "run handshake.md §Confirmation gate and §Write step verbatim".

**AUDIT.md.** Template in §3.3: §1 inventory (the former Q6 line + module map), §2 one row per checklist item of the BRIEF §9 files (same count rule as PLAN §4), §3 modularity (one row per core.md Modularity item), §4 tidy (inserted by `finalize-audit.sh` from `tidy-check.sh`, plus the `quarantine:` line), §5 merges. Statuses: `done` only with evidence (`cmd → output`, path or URL); `N/A` cites `BRIEF §n`; everything else `pending`. Mapping copies §2 verbatim into PLAN §4, so the standards table exists in one authored place.

**Order.** adopt (scan → BRIEF → audit → canonical files + merges → quarantine → finalize) → scavenge → mapping. Scavenge Q6 is **moved**: its row becomes "brownfield: copy the inventory line from `.v2p/AUDIT.md` §1; if AUDIT is missing, print `Run /v2p adopt first.` and stop". The `quick` Q6 subagent in scavenge step 2 is deleted. Handshake Q0 "change to existing code" → stop and run adopt, so brownfield always has an AUDIT.

**Tidy rule set.** §3.2. Deny-list (debris, duplicates, logs, orphan build output, scattered notes, duplicate READMEs) + required-list (canonical files) + never-touch list. It does **not** flag unknown top-level entries (framework-owned dirs vary too much; false positives would train the user to rubber-stamp). Merges are lossless: the canonical file gains `## From <path> (merged <date>)` + verbatim content; the original is quarantined only after `quarantine.sh` finds that heading in the destination (script gate, not prose).

**Scripts.** §4. Tested under `sh` (bash 3.2 as sh) and `zsh 5.9` on macOS 27.

**Parallel-session safety.** Probe reports dirty/branch. Rules: v2p never stashes, commits, resets or switches when the tree is dirty; the branch offer (`git switch -c v2p/adopt-<YYYY-MM-DD>`) exists only on a clean tree and only on the user's yes; adopt's writes are additive (`.v2p/`, `docs/`, missing root files — never overwrite an existing file); `quarantine.sh` refuses any path with a non-`??` porcelain status (modified, staged, renamed) — mechanically "never touch another session's uncommitted files" for tracked files; untracked candidates reach the list only through debris/notes patterns and are shown with an `age_days` column before the user approves. Worktree considered and rejected: untracked debris is invisible from a worktree, and `.v2p/` has to live where the user works. Non-git folders: no branch, no tracked checks, quarantine still works.

**Modularity rules.** §3.4 — six `- [ ]` items with evidence hints; code-review-graph covers items 2, 3, 5 and the fan-in listing mechanically (`get_impact_radius` is the only tool name I take from the catalog; which of its 30 tools exposes raw import edges or cycles is `(unverified)`); Serena `find_referencing_symbols` for item 3; `rg` fallbacks given per item.

**Portable pack.** `phases/adopt.md`, `references/tidy-rules.md`, `references/audit-template.md` ship in the pack; scripts and hooks do not (files, not markdown). Degradation text in adopt.md: the model asks for `git status --short`, `find . -path ./node_modules -prune -o -type f -print | head -300`, the manifest, README.md and any NOTES/TODO/ideas files pasted; it produces the BRIEF draft, the AUDIT draft and the tidy list as tables with the same columns; the user moves files by hand with the manifest pattern (`mkdir -p ~/.v2p-backups/<p>/<ts>/<dir> && mv`), no receipts (portable has no gate; say so). Claude-only: the probe, the subagent split, `AskUserQuestion`, script invocations, receipts, code-review-graph install through `installing-third-party-tools` (with the user's OK, only when first needed), `model-routing.md`, `skills-catalog.md`, hooks.

**The `personal_skills/vibe-to-product` project itself.** Out of scope. Note only: adopt on it would flag `dist/` (tracked, generated → `orphan-build`, a false positive the user declines), `ivanvibecodes-extract/` and `.serena/` are gitignored → never touched, `facebook-video-suggested-actions.md` / `ivanvibecodes-video-suggested-actions.md` / `WORKFLOW.md` match no pattern → not flagged.

***

## 3. Per-file spec

### 3.1 `phases/adopt.md` (~120 lines) — writes `.v2p/BRIEF.md` and `.v2p/AUDIT.md`

**Purpose** (2 lines). Bring an existing or half-built project under v2p: scan, derive the BRIEF from what exists, audit it against the standards, create the missing canonical files, merge scattered notes, quarantine debris with approval. Nothing is refactored here.

**Preconditions.** Router ran the probe (claude-only: `sh <skill>/scripts/tidy-check.sh --probe`; portable: ask the user for `ls -a` and `git status --short`). `brief:yes` → skip Steps 1–3 (say "BRIEF kept; running audit + tidy"). `.v2p/AUDIT.md` exists with a receipt → offer resume (keep) or re-run.

**Step 0 — Git safety.**
- `git:none` → continue, no branch.
- `git:dirty:<n>` → print the n paths (`git status --porcelain | grep -v '^??'`), then: "Uncommitted changes stay untouched: no stash, no commit, no branch switch; quarantine will refuse these paths." Continue.
- `git:clean` → `AskUserQuestion`: "Create branch `v2p/adopt-<YYYY-MM-DD>` for adopt's files? (Recommended: one commit to review or drop) / Stay on `<branch>`". Yes → `git switch -c v2p/adopt-<date>`. v2p never commits; the closing message tells the user what to commit.

**Step 1 — Scan** (claude-only: `quick` subagent; budget ≤40 files, `rg`/Serena symbol lookups, code-review-graph `get_impact_radius` if installed; never the whole tree). **Resume rule:** if `.v2p/work/adopt-scan.md` exists with `written:` today and `brief:` matching (or `brief: none`), reuse it and spawn nothing; say "resuming from .v2p/work/adopt-scan.md". The subagent writes the file itself, first line `written: <YYYY-MM-DDTHH:MM> · phase: adopt · part: scan · brief: <BRIEF written date | none>`, then exactly these headings:
```
## Manifest & stack: <manifest path> · framework/runtime · notable deps (auth, payments, db, i18n, analytics, mobile)
## Entry points: <routes/pages/commands with paths, ≤15>
## Login: yes|no · evidence <path:line>
## Payments SDK: yes|no · evidence
## i18n: yes|no · evidence · locales seen
## Env vars referenced: <n> · names only (never values) · .env.example: present|missing
## Tests: <runner|none> · <n> test files
## Files >200 lines: <path:lines, ≤10>
## Docs found: README first heading + first paragraph verbatim · other .md/.txt notes: <path — one-line gist>
## Deps created <6 months: <pkg (created date)|none> — `npm view <pkg> time.created` or ecosystem equivalent
## TODO/FIXME: <n> (`rg -c 'TODO|FIXME'`)
## Module map: top-level dirs under src/ (or app/, lib/) with file counts · cross-module internal imports found: <n> (rg pattern from core.md Modularity item 3) · cycles: <n|not checked (tool)>
## Brand signals: theme/tokens/logo/tailwind config paths | none
```

**Step 2 — Prefill the BRIEF** (main thread). Source table — the builder copies it into adopt.md:

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
| §9 blocks | derived | payments/webhooks/i18n/AI feature from deps and env names | inferred |
| §2, §4, §5, §7 | — | cannot be inferred: always asked (Q2, Q5, Q6, Q9), ≤3 per turn | answered / defaulted |

Every `inferred` row's value cell ends with `← <source path>`. Gaps that block a section get `[NEEDS CLARIFICATION: …]` markers as in handshake.md.

**Step 3 — Gate and write.** "Run `phases/handshake.md` §Confirmation gate and §Write step verbatim." Extra: the running brief shows `(inferred)` after each inferred value so the user sees what to correct. Write `.v2p/BRIEF.md`; §1 Code = `existing at <root>`.

**Step 4 — Audit draft.** Write `.v2p/AUDIT.draft.md` from `references/audit-template.md` (never `AUDIT.md`): §1 from the scan; §2 one row per `- [ ]` item of the BRIEF §9 standards files, `done` only with evidence gathered now (a command run in this session with its output, or a path from the scan), `N/A — BRIEF §n` for blocks OFF, else `pending`; §3 one row per core.md Modularity item, evidence from the scan's module map; §4 left as the template placeholder (the finalize script fills it); §5 merges filled in Step 5. Claude-only: `quick` may write the draft; `planner` never writes.

**Step 5 — Canonical files and merges.** Run `tidy-check.sh` (human mode) and show the table. Create only the **missing** canonical files, never overwrite: `README.md` (BRIEF §1 vision + how to run, from the manifest), `CHANGELOG.md` (`## Unreleased` + one line "adopted by v2p <date>"), `docs/ARCHITECTURE.md` (module map from the scan + data flow line), `docs/DECISIONS.md` (merged notes or `none yet`), `.env.example` (env var names with empty values, only if `.env*` exists). For each `merge:<dest>` row: append to `<dest>` a section `## From <path> (merged <YYYY-MM-DD>)` with the original content verbatim (README duplicates: only the parts not already in README.md; say what was dropped), then show the added sections (`git diff -- <dest>` for tracked, or the section text) before anything moves. Portable: print the files in code blocks.

**Step 6 — Quarantine.** Always dry-run first: `sh <skill>/scripts/tidy-check.sh --tsv > .v2p/work/adopt-tidy.tsv; sh <skill>/scripts/quarantine.sh < .v2p/work/adopt-tidy.tsv`. Show `MOVE`/`REFUSE` lines. `AskUserQuestion`: "Quarantine these <n> items to `~/.v2p-backups/<project>/<ts>/` (restore command provided)? (Recommended) / Skip (record `quarantine: declined`)". Rows the user excludes are removed from the tsv (`grep -v`) before apply. On yes: `… quarantine.sh --apply < .v2p/work/adopt-tidy.tsv`; print its last three lines. Refused rows stay listed in AUDIT §4 as-is (they are the safety net, not failures). Write `quarantine: <manifest path>|declined` into the draft's §4.

**Step 7 — Finalize.** `sh <skill>/scripts/finalize-audit.sh .v2p` until `PASS`. It fills §4 from `tidy-check.sh`, checks counts and evidence, writes `AUDIT.md`, the receipt `.v2p/.audit-pass`, and clears `.v2p/work/adopt-*`. Never write `AUDIT.md` by hand.

**Step 8 — Hand off.** Print the paths written, the quarantine restore command, "commit: `.v2p/ docs/ README.md CHANGELOG.md .env.example .gitignore`", then `Next: /v2p scavenge`.

**Tools** (claude-only block): Serena installed (`find_symbol`, `get_symbols_overview`, `find_referencing_symbols`); code-review-graph not installed on this machine (measured: `command -v code-review-graph` empty, 2026-09-23) — offer to install through the `installing-third-party-tools` skill only when the scan needs impact radius or cycles and only on the user's yes; `rg` always. `claude-mem:learn-codebase` optional, never a source of findings (scavenge rule 6 applies: the scan file is the only legitimate resume source).

Copyright line.

### 3.2 `references/tidy-rules.md` (~75 lines) — portable

Header: "Checked by `scripts/tidy-check.sh` (read-only) and enforced by `scripts/quarantine.sh` (moves, never deletes). Every pattern below appears verbatim in one of the two scripts; the verification check greps for that. `<project>` = git toplevel or the directory v2p runs in."

**§1 Canonical set** (required rows are what `tidy-check.sh` reports as `missing`):

| Path | Required | Profile | Owner |
|---|---|---|---|
| `README.md` | yes | all | adopt creates from BRIEF if missing |
| `CHANGELOG.md` | yes | all | adopt creates `## Unreleased` |
| `.gitignore` | yes (git only) | all | must contain `.v2p/work/` and `.v2p/*.draft.md` |
| `.env.example` | when any `.env*` exists | all | names only, never values |
| `.v2p/BRIEF.md` | yes | all | handshake / adopt |
| `.v2p/SCAVENGE.md`, `PLAN.md`, `REVIEW.md`, `DEPLOY.md` | by their phase | all | finalize scripts only |
| `.v2p/AUDIT.md` | brownfield | all | `finalize-audit.sh` |
| `.v2p/work/` | transient | all | checkpoints; cleared by finalize; gitignored |
| `docs/ARCHITECTURE.md` | yes | all | module map + data flow |
| `docs/DECISIONS.md` | yes | all | merged notes/ADRs; `## From <path>` sections |
| `docs/threat-model.md` | before review phase | all with a backend | reported as `pending (review)`, never `missing` |
| `src/` or the framework's own roots (`app/`, `pages/`, `lib/`, `ios/`, `android/`, `public/`, `migrations/`) | — | framework-owned | never flagged |

Profile deltas: `native-app` adds `ios/`, `android/` as framework-owned; `landing` may omit `docs/threat-model.md` (`N/A — BRIEF §8 no backend`). No other profile differences exist; say so rather than inventing them.

**§2 Debris** (`kind` → `action quarantine`):
- `debris`: `.DS_Store`, `Thumbs.db`, `desktop.ini`, `._*`, `*~`, `*.swp`, `*.swo`, `.#*`, `*.orig`, `*.rej`, `*.bak`, `*.bak.*`, `*.backup`, `*_backup*`, `*.tmp`, `*.temp`, `*.pyc`
- `duplicate`: `*_old.*`, `*_old`, `*-old.*`, `*.old`, `*_copy.*`, `* copy.*`, `* copy`, `*_final*`, `*-final*`, `*final_v[0-9]*`, `*_v[0-9].*`, `*_v[0-9][0-9].*`, `* ([0-9]).*` — name-based; a legitimate `schema_v2.sql` will be listed and the user unticks it
- `log`: `*.log`, `npm-debug.log*`, `yarn-error.log*`, `lerna-debug.log*` (only when not gitignored)
- `orphan-build` (directory, only when not gitignored): `dist`, `build`, `out`, `.next`, `.nuxt`, `.output`, `.turbo`, `coverage`, `__pycache__`, `.pytest_cache`, `.mypy_cache`, `.parcel-cache`, `.cache`. The right fix is usually a `.gitignore` line; the row says so in the human output.
- `empty-dir`: any directory with no entries

**§3 Scattered notes** (`kind scattered` / `dup-readme` → `action merge:<dest>`):
- → `docs/DECISIONS.md`: files `NOTES*`, `notes*.md`, `TODO*`, `todo*.md`, `IDEAS*`, `ideas*.md`, `ROADMAP*`, `BACKLOG*`, `SCRATCH*`, `PLAN*`, `plan*.md`, `DECISIONS*`, `ADR*`, `*.notes.md`, `*.notes.txt`; directories `notes`, `ideas`, `adr`, `adrs`, `decisions`
- → `docs/ARCHITECTURE.md`: `ARCHITECTURE*`, `architecture*.md`, `DESIGN.md`, `design.md`
- → `CHANGELOG.md`: `CHANGES*`, `HISTORY*`
- → `README.md` (root only): `README_*`, `README-*`, `README.txt`, `README.old`, `readme*`, `Readme*`
- Exempt: `docs/DECISIONS.md`, `docs/ARCHITECTURE.md`, `docs/threat-model.md`, `CHANGELOG.md`, `README.md`, anything under `.v2p/`
- Merge rule: destination gains `## From <path> (merged <YYYY-MM-DD>)` + verbatim content; `quarantine.sh` refuses the original until that heading exists in the destination; the user sees the added sections before the move.

**§4 Never touch** (both scripts; `quarantine.sh` prints `REFUSE never-touch`): `.git/`, `.v2p/`, `.claude/`, `.serena/`, `.github/`, `.vscode/`, `.idea/`, `node_modules/`, `.venv/`, `venv/`, `vendor/`, `data/`, `uploads/`, `storage/`, the canonical files of §1, `.env` and `.env.*` (except `.env.example`, which is canonical), lockfiles (`package-lock.json`, `pnpm-lock.yaml`, `yarn.lock`, `bun.lockb`, `bun.lock`, `Cargo.lock`, `poetry.lock`, `uv.lock`, `Gemfile.lock`, `composer.lock`, `Podfile.lock`, `go.sum`), `*.sqlite`, `*.sqlite3`, `*.db`, **anything `git check-ignore` matches**, **symlinks** (never followed, never moved, refused if in the path), **anything outside the project root** (realpath prefix check), the quarantine directory itself (it lives in `$HOME`, and the script refuses to run with root `/` or `$HOME`).

**§5 Git-tracked vs untracked.** Tracked files are moved like any other; git then shows ` D <path>` and the user commits the removal (or runs `restore.sh`). A tracked file with uncommitted modifications is refused (`REFUSE uncommitted-changes`) — commit or discard first; v2p never does it for you. Untracked files are moved silently; ignored files are never touched. `tracked` and `age_days` columns are shown so recent, human-authored files stand out before approval.

**§6 Quarantine layout.** `~/.v2p-backups/<project>/<YYYY-MM-DD-HHMMSS>/` mirrors relative paths; `MANIFEST.tsv` (`path sha256 tracked reason restore`, header comment names root, time and the restore command); `restore.sh` (`mkdir -p … && mv …` per row; empty dirs as `mkdir -p`). v2p never empties it; the user does.

Copyright line.

### 3.3 `references/audit-template.md` (~50 lines) — portable

````
# AUDIT — <project name>
checked: pending   ← finalize-audit.sh replaces this line; a hand-written AUDIT.md has no receipt and mapping refuses it
written: <YYYY-MM-DD> by v2p adopt · reads: .v2p/BRIEF.md (<written date>) · root: <abs path> · git: <none|clean|dirty:n> · branch: <b>

## 1. Inventory
- stack <…> · entry points <…> · env vars referenced <n> (.env.example: present|missing) · tests <runner|none, n files> · deps created <6 months: <list|none> · TODO/FIXME <n> · files >200 lines <n: paths>
- Module map: <dir (n files)> … · cross-module internal imports <n> · cycles <n|not checked>

## 2. Standards (one row per item of the BRIEF §9 files; mapping copies this table into PLAN §4)
| item | file | status | evidence |
|---|---|---|---|
| <label> | core.md | done | `<command>` → <output> |
| <label> | web.md | pending | |
| <label> | landing.md | N/A | BRIEF §9 block OFF |
Rows: <n> = <core> + <web> + <profile> (finalize-audit.sh checks the sum against the standards files)

## 3. Modularity (one row per core.md "Modularity" item)
| item | status | evidence |
|---|---|---|

## 4. Tidy
<tidy-check.sh output — inserted by finalize-audit.sh; do not write by hand>
quarantine: <~/.v2p-backups/<project>/<ts>/MANIFEST.tsv | declined>

## 5. Merges (originals quarantined after the destination gained "## From <path>")
| source | destination |
|---|---|
| <path> | docs/DECISIONS.md |
(or: none)

Next: /v2p scavenge
````
Rule printed above the block: statuses are exactly `done`, `pending`, `N/A`; `done` needs evidence (`cmd → output`, a path, or a URL); `N/A` needs `BRIEF §n` in the evidence cell.

### 3.4 `references/standards/core.md` — new section, inserted before "## Conditional blocks"

```
## Modularity
- [ ] **Module map:** every top-level module (dir under `src/`, `app/` or `lib/`) is listed in `docs/ARCHITECTURE.md` with one line of responsibility and its allowed dependencies. Evidence: `ls -d src/*/ | wc -l` equals the listed count.
- [ ] **Dependency direction:** imports point inward (ui → features → domain → shared); `shared/`, `core/`, `lib/` never import from a feature or route. Evidence: `rg -n "from ['\"](\.\./)+(features|app|routes)" src/shared src/core src/lib` → 0 lines, or the graph tool's edge query.
- [ ] **No cross-module internals:** a module is imported only through its public surface (`index.*` or an explicit `exports` map). Evidence: `rg -nP "from ['\"]\.\.?/[\w-]+/(?!index)[\w/-]+['\"]" src` → 0, or an `import/no-internal-modules` / `no-restricted-paths` lint rule with `eslint . --max-warnings 0` → exit 0.
- [ ] **Feature folders** (when the project has 2+ features or more than 20 source files): code is grouped by feature (`features/<name>/{components,api,model}`), not by type at the top level. Evidence: the module map; `ls src` shows feature names, not `components/ services/ utils/` alone.
- [ ] **No import cycles.** Evidence: `npx madge --circular --extensions ts,tsx src` → "No circular dependency found" (JS/TS), `pydeps --show-cycles` (Python), or the graph tool's cycle report. (verified: 2026-09) https://github.com/pahen/madge
- [ ] **Single owner per concern:** one place reads env/config, one creates the DB client, one wires auth; no second copy. Evidence: `rg -l "process\.env\." src | grep -vc "config"` → 0; `rg -l "createClient\(" src | wc -l` → 1 (adapt the pattern to the stack).
```
Do not add a file-size item — Warnings 1 already holds it. This raises core from 96 to 102 items (re-measure; update mapping.md step 4 numbers and README's total).

**Graph tool note** (goes into skills-catalog.md brownfield row, not core.md): code-review-graph checks items 2, 3, 5 and fan-in mechanically once built (`code-review-graph build`), through `get_impact_radius` and its edge/cycle tools (`(unverified)` which of the 30 tools exposes edges and cycles by name); install only through `installing-third-party-tools`, on the user's yes, when the scan first needs it. Serena: `find_referencing_symbols` for item 3. `rg`: the hints above.

### 3.5 `scripts/tidy-check.sh` — tested (§4.1 for the tests)

Behaviour: read-only; `--probe` prints the one-line probe and exits 0; default human output = probe line + header + rows + `tidy: <n> violations`; `--tsv` prints rows only; exit 0 clean, 1 violations, 2 usage. Rows: `kind<TAB>path<TAB>action<TAB>tracked<TAB>age_days`. Root: argument, else git toplevel, else `$PWD`. Reference implementation (copy verbatim; 65 lines; identical output under `sh` and `zsh` on the fixture):

```sh
#!/bin/sh
# Read-only tidy check. Usage: sh tidy-check.sh [--tsv|--probe] [root]
# Exit 0 = clean, 1 = violations, 2 = usage. Runs under sh and zsh (no unquoted word-splitting).
mode=human; root=
for a in "$@"; do case $a in --tsv) mode=tsv ;; --probe) mode=probe ;; -*) echo "usage: tidy-check.sh [--tsv|--probe] [root]" >&2; exit 2 ;; *) root=$a ;; esac; done
[ -n "$root" ] || root=$(git rev-parse --show-toplevel 2>/dev/null) || root=$PWD
root=$(cd "$root" && pwd -P) || exit 2
cd "$root" || exit 2
git=none; branch=-; dirty=0
if git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
  branch=$(git rev-parse --abbrev-ref HEAD 2>/dev/null || echo detached)
  dirty=$(git status --porcelain 2>/dev/null | grep -vc '^??'); git=clean; [ "$dirty" -gt 0 ] && git="dirty:$dirty"
fi
code=no
for m in package.json pyproject.toml requirements.txt go.mod Cargo.toml Package.swift pubspec.yaml build.gradle build.gradle.kts Gemfile composer.json; do [ -f "$m" ] && code=yes; done
[ "$code" = no ] && [ -n "$(find . -path ./.git -prune -o -path ./node_modules -prune -o -path ./.v2p -prune -o -type f \( -name '*.ts' -o -name '*.tsx' -o -name '*.js' -o -name '*.jsx' -o -name '*.py' -o -name '*.go' -o -name '*.rs' -o -name '*.swift' -o -name '*.kt' -o -name '*.java' -o -name '*.rb' -o -name '*.php' -o -name '*.dart' -o -name '*.vue' -o -name '*.svelte' \) -print -quit)" ] && code=yes
brief=none; [ -f .v2p/BRIEF.md ] && brief=yes
audit=no; [ -f .v2p/AUDIT.md ] && grep -q '^checked:' .v2p/AUDIT.md && audit=yes
probe="root:$root code:$code git:$git branch:$branch brief:$brief audit:$audit"
[ "$mode" = probe ] && { echo "$probe"; exit 0; }

ignored() { [ "$git" != none ] && git check-ignore -q -- "$1"; }
tracked() { [ "$git" != none ] && git ls-files --error-unmatch -- "$1" >/dev/null 2>&1 && echo yes || echo no; }
age() { [ -e "$1" ] || { printf "%s\n" -; return; }; m=$(stat -f %m "$1" 2>/dev/null || stat -c %Y "$1" 2>/dev/null || echo 0); echo $(( ( $(date +%s) - m ) / 86400 )); }
row() { printf '%s\t%s\t%s\t%s\t%s\n' "$1" "$2" "$3" "$(tracked "$2")" "$(age "$2")"; }

{
# 1. canonical files that must exist
for f in README.md .gitignore CHANGELOG.md .v2p/BRIEF.md docs/ARCHITECTURE.md docs/DECISIONS.md; do [ -e "$f" ] || row missing "$f" create; done
[ -n "$(find . -maxdepth 1 -name '.env*' ! -name '.env.example' -print -quit)" ] && [ ! -f .env.example ] && row missing .env.example create
[ -d node_modules ] && ! ignored node_modules && row gitignore node_modules gitignore
[ "$git" != none ] && [ -f .gitignore ] && ! grep -q '^\.v2p/work/' .gitignore && row gitignore .v2p/work/ gitignore

# 2. walk (never descends into never-touch dirs; symlinks are skipped, never followed)
find . -mindepth 1 \( -name .git -o -name node_modules -o -name .venv -o -name venv -o -name vendor -o -name .v2p -o -name .claude -o -name .serena -o -name .github -o -name .vscode -o -name .idea -o -type l \) -prune -o -print | sed 's|^\./||' | sort | while IFS= read -r p; do
  ignored "$p" && continue
  b=${p##*/}; d=${p%/*}; [ "$d" = "$p" ] && d=.
  if [ -d "$p" ]; then
    case $b in
      dist|build|out|.next|.nuxt|.output|.turbo|coverage|__pycache__|.pytest_cache|.mypy_cache|.parcel-cache|.cache) row orphan-build "$p" quarantine; continue ;;
      notes|ideas|adr|adrs|decisions) row scattered "$p" merge:docs/DECISIONS.md; continue ;;
    esac
    [ -z "$(find "$p" -mindepth 1 -print -quit)" ] && row empty-dir "$p" quarantine
    continue
  fi
  case $d in dist|build|out|.next|.nuxt|.output|.turbo|coverage|__pycache__|.pytest_cache|.mypy_cache|.parcel-cache|.cache|notes|ideas|adr|adrs|decisions) continue ;; esac  # parent already listed
  case $b in
    .DS_Store|Thumbs.db|desktop.ini|._*|*~|*.swp|*.swo|.#*|*.orig|*.rej|*.bak|*.bak.*|*.backup|*_backup*|*.tmp|*.temp|*.pyc) row debris "$p" quarantine; continue ;;
    *_old.*|*_old|*-old.*|*.old|*_copy.*|*\ copy.*|*\ copy|*_final*|*-final*|*final_v[0-9]*|*_v[0-9].*|*_v[0-9][0-9].*|*\ \([0-9]\).*) row duplicate "$p" quarantine; continue ;;
    *.log|npm-debug.log*|yarn-error.log*|lerna-debug.log*) row log "$p" quarantine; continue ;;
  esac
  case $p in docs/DECISIONS.md|docs/ARCHITECTURE.md|docs/threat-model.md|CHANGELOG.md|README.md) continue ;; esac
  case $b in
    NOTES*|notes*.md|TODO*|todo*.md|IDEAS*|ideas*.md|ROADMAP*|BACKLOG*|SCRATCH*|PLAN*|plan*.md|DECISIONS*|ADR*|*.notes.md|*.notes.txt) row scattered "$p" merge:docs/DECISIONS.md ;;
    ARCHITECTURE*|architecture*.md|DESIGN.md|design.md) row scattered "$p" merge:docs/ARCHITECTURE.md ;;
    CHANGES*|HISTORY*) row scattered "$p" merge:CHANGELOG.md ;;
  esac
  [ "$d" = . ] && case $b in README_*|README-*|README.txt|README.old|readme*|Readme*) row dup-readme "$p" merge:README.md ;; esac
done
} > "${TMPDIR:-/tmp}/tidy.$$"
rows=$(grep -c . "${TMPDIR:-/tmp}/tidy.$$"); [ -n "$rows" ] || rows=0
if [ "$mode" = tsv ]; then cat "${TMPDIR:-/tmp}/tidy.$$"; else
  echo "$probe"; echo "kind	path	action	tracked	age_days"; cat "${TMPDIR:-/tmp}/tidy.$$"; echo "tidy: $rows violations"; fi
rm -f "${TMPDIR:-/tmp}/tidy.$$"
[ "$rows" -eq 0 ]
```
(The `.v2p/work/` gitignore row is the one line I added after testing; it follows the tested `node_modules` row pattern exactly. Builder: add `- .gitignore lacks .v2p/work/` to the fixture expectations, see §4.1.)

### 3.6 `scripts/quarantine.sh` — tested

Behaviour: reads tidy rows on stdin; handles only `action` = `quarantine` or `merge:<dest>`; dry-run by default (`MOVE <sha> <path>` / `MOVE dir <path>` / `REFUSE <reason> <path>` lines, nothing moved); `--apply` moves to `~/.v2p-backups/<project>/<YYYY-MM-DD-HHMMSS>/<relative path>`, verifies sha256 after each move, appends `MANIFEST.tsv` and `restore.sh`; directories are expanded to files first, then emptied dirs (deepest first) get a `-` sha row and `mkdir -p` restore; refusals: `outside-or-relative`, `missing`, `symlink`, `symlink-in-path-or-outside`, `never-touch`, `gitignored`, `uncommitted-changes`, `not-merged-into-<dest>`, `contains-symlink`; refuses to run with root `/` or `$HOME`. Exit 0 all rows handled, 1 any refusal/failure (a sha mismatch prints `FAIL sha mismatch after move: <p> (now at <q>)` — the file is at the quarantine path, never lost), 2 usage. Known ceiling (`# ponytail:` comment): `tracked` for emptied-dir rows reflects `git ls-files` on the directory, not the individual files.

```sh
#!/bin/sh
# Move approved tidy rows to ~/.v2p-backups/<project>/<ts>/ keeping relative paths. Never deletes.
# Usage: sh tidy-check.sh --tsv | sh quarantine.sh [--apply] [root]     (dry-run without --apply)
# Rows: kind<TAB>path<TAB>action ; only action=quarantine or merge:<dest> are handled.
# Exit 0 = all rows moved (or dry-run plan printed), 1 = at least one row refused/failed, 2 = usage.
apply=no; root=
for a in "$@"; do case $a in --apply) apply=yes ;; -*) echo "usage: quarantine.sh [--apply] [root]" >&2; exit 2 ;; *) root=$a ;; esac; done
[ -n "$root" ] || root=$(git rev-parse --show-toplevel 2>/dev/null) || root=$PWD
root=$(cd "$root" && pwd -P) || exit 2
case $root in /|"$HOME") echo "REFUSE root is $root" >&2; exit 2 ;; esac
cd "$root" || exit 2
git=no; git rev-parse --is-inside-work-tree >/dev/null 2>&1 && git=yes
sha() { shasum -a 256 "$1" 2>/dev/null | cut -d' ' -f1 || sha256sum "$1" | cut -d' ' -f1; }
ts=$(date +%Y-%m-%d-%H%M%S); q="$HOME/.v2p-backups/${root##*/}/$ts"; man="$q/MANIFEST.tsv"; res="$q/restore.sh"
bad=0; moved=0; tmp=${TMPDIR:-/tmp}/q.$$; trap 'rm -f "$tmp"' EXIT
refuse() { echo "REFUSE $1	$2"; bad=$((bad+1)); }
# one file: returns 0 if allowed
check() { p=$1
  case $p in /*|*/../*|../*|*/..|..|.|"") refuse "outside-or-relative" "$p"; return 1 ;; esac
  [ -e "$p" ] || [ -L "$p" ] || { refuse "missing" "$p"; return 1; }
  [ -L "$p" ] && { refuse "symlink" "$p"; return 1; }
  rp=$(realpath "$p" 2>/dev/null || (cd "$(dirname "$p")" && printf '%s/%s' "$(pwd -P)" "$(basename "$p")"))
  [ "$rp" = "$root/$p" ] || { refuse "symlink-in-path-or-outside" "$p"; return 1; }
  b=${p##*/}
  case $p in .git|.git/*|.v2p|.v2p/*|docs/DECISIONS.md|docs/ARCHITECTURE.md|docs/threat-model.md|README.md|CHANGELOG.md|.env.example|node_modules|node_modules/*|.venv|.venv/*|venv/*|vendor|vendor/*|.claude|.claude/*|.serena/*|.github/*|.vscode/*|.idea/*|data|data/*|uploads|uploads/*|storage|storage/*) refuse "never-touch" "$p"; return 1 ;; esac
  case $b in .env|.env.*|package-lock.json|pnpm-lock.yaml|yarn.lock|bun.lockb|bun.lock|Cargo.lock|poetry.lock|uv.lock|Gemfile.lock|composer.lock|Podfile.lock|go.sum|*.sqlite|*.sqlite3|*.db) refuse "never-touch" "$p"; return 1 ;; esac
  if [ $git = yes ]; then
    git check-ignore -q -- "$p" && { refuse "gitignored" "$p"; return 1; }
    [ -n "$(git status --porcelain -- "$p" | grep -v '^??')" ] && { refuse "uncommitted-changes" "$p"; return 1; }
  fi
  return 0
}
move() { m=$1; reason=$2   # file or empty dir, already checked
  if [ -d "$m" ]; then
    [ $apply = yes ] && { rmdir "$m" || { echo "FAIL rmdir $m"; bad=$((bad+1)); return; }; mkdir -p "$q/$m"; printf '%s\t-\t%s\t%s\tmkdir -p "%s"\n' "$m" "$tr" "$reason" "$root/$m" >> "$man"; printf 'mkdir -p "%s"\n' "$root/$m" >> "$res"; }
    echo "MOVE dir	$m"; moved=$((moved+1)); return; fi
  s1=$(sha "$m")
  if [ $apply = yes ]; then
    mkdir -p "$q/$(dirname "$m")" && mv "$m" "$q/$m" || { echo "FAIL mv $m"; bad=$((bad+1)); return; }
    s2=$(sha "$q/$m"); [ "$s1" = "$s2" ] || { echo "FAIL sha mismatch after move: $m (now at $q/$m)"; bad=$((bad+1)); return; }
    printf '%s\t%s\t%s\t%s\tmkdir -p "%s" && mv "%s" "%s"\n' "$m" "$s1" "$tr" "$reason" "$root/$(dirname "$m")" "$q/$m" "$root/$m" >> "$man"
    printf 'mkdir -p "%s" && mv "%s" "%s"\n' "$root/$(dirname "$m")" "$q/$m" "$root/$m" >> "$res"
  fi
  echo "MOVE $s1	$m"; moved=$((moved+1))
}
[ $apply = yes ] && { mkdir -p "$q" && printf '# root=%s created=%s restore: sh %s\n# path\tsha256\ttracked\treason\trestore\n' "$root" "$ts" "$res" > "$man" && printf '#!/bin/sh\n# restore everything quarantined on %s from %s\nset -e\n' "$ts" "$root" > "$res"; }
while IFS='	' read -r kind p action rest; do
  case $action in quarantine|merge:*) ;; *) continue ;; esac
  case $kind in \#*|kind|"") continue ;; esac
  p=${p#./}
  check "$p" || continue
  tr=no; [ $git = yes ] && git ls-files --error-unmatch -- "$p" >/dev/null 2>&1 && tr=yes
  case $action in merge:*) dest=${action#merge:}
    grep -qF "From $p" "$dest" 2>/dev/null || { refuse "not-merged-into-$dest" "$p"; continue; } ;; esac
  if [ -d "$p" ]; then
    find "$p" -type l -print | grep -q . && { refuse "contains-symlink" "$p"; continue; }
    find "$p" -type f -print | sort > "$tmp"
    while IFS= read -r f; do move "$f" "$action"; done < "$tmp"
    find "$p" -depth -type d -print > "$tmp"      # every dir under (and including) p, deepest first
    while IFS= read -r f; do [ -z "$(find "$f" -mindepth 1 -print -quit)" ] && move "$f" "$action"; done < "$tmp"
  else move "$p" "$action"; fi
done
[ $apply = yes ] && echo "manifest: $man" && echo "restore: sh $res" || echo "dry-run: nothing moved; add --apply to move to $q"
echo "moved: $moved refused/failed: $bad"
[ "$bad" -eq 0 ]
```

### 3.7 `scripts/finalize-audit.sh` (~50 lines; same shape as `finalize-scavenge.sh`)

```
usage: sh finalize-audit.sh [.v2p dir]
skill=$(cd "$(dirname "$0")/.." && pwd -P); d=${1:-.v2p}; draft=$d/AUDIT.draft.md; out=$d/AUDIT.md; fail=0
1  [ -f $draft ] || FAIL "draft missing" exit 1
2  BRIEF: [ -f $d/BRIEF.md ] and the first non-empty line after "## 11" is "none" (allow trailing " ←…") else FAIL
3  expected = for each name in `awk '/^## 9/{f=1;next} /^## /{f=0} f' BRIEF | grep -oE '[a-z-]+\.md'` that exists as $skill/references/standards/<name>: sum of `grep -c '^- \[ \]'`  (landing-10-sections/ux-laws are not standards files → skipped)
4  rows2 = table rows in draft §2 (`awk '/^## 2\./{f=1;next} /^## /{f=0} f && /^\| / && !/^\| item/ && !/^\|---/'`); [ rows2 -eq expected ] else FAIL "§2 rows $rows2/$expected"
5  for §2 rows with status cell `done` (3rd cell, trimmed): evidence cell (4th) must match `→|/|https?://` else FAIL listing the rows (cut -c1-100)
6  for §2 rows with status `N/A`: evidence cell must contain `BRIEF §` else FAIL listing
7  §3: rows3 == `awk '/^## Modularity/{f=1;next} /^## /{f=0} f' $skill/references/standards/core.md | grep -c '^- \[ \]'`; same done/N-A rules as 5–6
8  §4: qline = `grep -E '^quarantine: ' $draft`; must match `^quarantine: (declined|/.*/MANIFEST\.tsv)$` (accept a leading ~ expanded by the writer); if a path, `test -f` else FAIL. Then tidy=$(sh $skill/scripts/tidy-check.sh "$(dirname "$(cd $d/.. && pwd -P)")" 2>&1) — use the project root = parent of $d; v=$(printf '%s\n' "$tidy" | sed -n 's/^tidy: \([0-9]*\) violations/\1/p')
9  §5: for each row `| <src> | <dest> |` (not header/sep, not "none"): `grep -qF "From <src>" <dest>` else FAIL
10 [ fail -eq 0 ] || { echo "FAIL: $out not written"; exit 1; }
11 write $out: awk replaces the §4 body (between "## 4." and "## 5.") with $tidy + the qline; sed replaces `^checked: .*` with `checked: $rows2/$expected standards · $rows3 modularity · tidy $v violations · $qline`; rm $draft
12 shasum -a 256 $out | cut -d' ' -f1 > $d/.audit-pass; rm -f $d/work/adopt-*; echo "PASS: $rows2/$expected standards, tidy $v -> $out"
```
The tidy output inserted in step 8 is produced by the script, so §4 cannot be typed by hand; a hand-typed `checked:` line is overwritten; a hand-written AUDIT.md has no receipt.

### 3.8 `scripts/finalize-plan.sh` (~15 lines) — needed only because the hook covers PLAN.md

```
d=${1:-.v2p}; draft=$d/PLAN.draft.md; out=$d/PLAN.md
[ -f $draft ] || FAIL
tasks=$(grep -c '^### Task' $draft); ver=$(grep -c '^\*\*Verifier:\*\*' $draft); [ tasks -gt 0 ] && [ tasks -eq ver ] else FAIL "tasks $tasks / verifiers $ver"
rows=$(awk '/^## 4\./{f=1;next} /^## /{f=0} f && /^\| / && !/^\| item/ && !/^\|---/' $draft | grep -c .); expected computed as in finalize-audit step 3 from BRIEF §9; equal else FAIL
grep -q '^Next: /v2p execute' $draft else FAIL
mv $draft $out; shasum … > $d/.plan-pass; rm -f $d/work/mapping-*; echo "PASS: $tasks tasks, $rows standards rows -> $out"
```
mapping.md Step 5 changes to: write `.v2p/PLAN.draft.md`, run `finalize-plan.sh` until PASS. Slice 4's execute will run `check-pass.sh .v2p/PLAN.md .v2p/.plan-pass`. If the user prefers not to touch mapping in this slice, drop PLAN from the hook and this file — the hook must not name a file that has no finalize path.

### 3.9 `scripts/finalize-scavenge.sh` — 3 added lines (checkpoints)

After the draft-exists check:
```
for w in "$d/work/scavenge-q1-5.md" "$d/work/scavenge-q7.md"; do [ -f "$w" ] || { echo "FAIL: checkpoint $w missing: findings must come from this run's subagents (.v2p/work/), not from memory"; fail=1; }; done
```
(include Q6 no longer; brownfield inventory comes from AUDIT). After the receipt line: `rm -f "$d"/work/scavenge-*`.

### 3.10 Crash-safe checkpoints (all phases; spec for the scavenge.md and adopt.md edits)

- Location and names: `.v2p/work/<phase>-<part>.md` — `scavenge-q1-5.md` (planner result; **the main thread writes it the moment the result arrives, before any other action**), `scavenge-q7.md` (the `quick` subagent writes it itself before returning), `adopt-scan.md` (the `quick` scan subagent writes it itself), `adopt-tidy.tsv` (the approved list), `mapping-plan.md` (planner's PLAN body, written by the main thread on receipt).
- Header, line 1 of every checkpoint: `written: <YYYY-MM-DDTHH:MM> · phase: <phase> · part: <part> · brief: <BRIEF written date | none>`.
- Resume rule (Preconditions of each phase): list `.v2p/work/<phase>-*`; a file is **reusable** when its `written:` date is today (local) and its `brief:` equals the current BRIEF's `written:` date; print "resuming from <files>" and skip the corresponding subagent(s). Any other file is stale: overwritten, never read. **`.v2p/work/` files are the only legitimate resume source** (scavenge rule 6 extended to every phase): memory, claude-mem observations and prior-session summaries are leads to re-fetch, not evidence.
- Clearing: the phase's finalize script deletes `.v2p/work/<phase>-*` on PASS (and only then). `.gitignore` gets `.v2p/work/` and `.v2p/*.draft.md` (tidy-check reports the missing line).
- Gate: finalize scripts require the phase's checkpoint files to exist (§3.9, §3.7 step 12 does not require `adopt-scan.md` because `adopt` with an existing BRIEF skips the scan — it requires it only when the draft's §1 is non-empty; simplest rule: require `adopt-scan.md` unless `adopt-tidy.tsv`-only mode was used; builder implements as "require adopt-scan.md when BRIEF §1 Code says `existing`" ).

### 3.11 Hook proposal — `skills/v2p/hooks/` (defence in depth; nothing installed by the builder)

Receipts stop the **next** phase from accepting a hand-written file; only a hook can stop the write itself. Per the coordinator's doc check: SKILL.md frontmatter cannot declare hooks; hooks live in `settings.json` or in a plugin's `hooks/hooks.json` at the plugin root; PreToolUse receives stdin JSON with `tool_name` and `tool_input.file_path`; exit 2 blocks and stderr reaches the model. `skills/v2p` is the candidate plugin root, so `skills/v2p/hooks/hooks.json` is the right home; until the plugin exists the only install path is the user's `settings.json` (user decision).

`hooks/guard-finals.sh`:
```sh
#!/bin/sh
# PreToolUse guard: .v2p final handoff files are produced only by scripts/finalize-*.sh (mv from a .draft.md).
# stdin: hook JSON; exit 2 = block (stderr goes back to the model). Also blocks shell redirects/copies to the finals.
in=$(cat)
tool=$(printf '%s' "$in" | sed -n 's/.*"tool_name"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/p' | head -1)
case $tool in
  Write|Edit|MultiEdit)
    f=$(printf '%s' "$in" | sed -n 's/.*"file_path"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/p' | head -1)
    case $f in */.v2p/SCAVENGE.md|*/.v2p/AUDIT.md|*/.v2p/PLAN.md|.v2p/SCAVENGE.md|.v2p/AUDIT.md|.v2p/PLAN.md)
      echo "v2p: $f is written only by its finalize script. Write ${f%.md}.draft.md and run scripts/finalize-*.sh." >&2; exit 2 ;; esac ;;
  Bash)
    printf '%s' "$in" | grep -qE '(>|>>|tee|cp|mv|sed -i)[^;&|]*\.v2p/(SCAVENGE|AUDIT|PLAN)\.md' && { echo "v2p: shell writes to .v2p/{SCAVENGE,AUDIT,PLAN}.md are blocked; use the finalize script." >&2; exit 2; } ;;
esac
exit 0
```
`hooks/hooks.json` (plugin format; `${CLAUDE_PLUGIN_ROOT}` `(unverified)` — the guide found no documented plugin-root variable; if absent, the plugin build substitutes the absolute path):
```json
{"hooks":{"PreToolUse":[{"matcher":"Write|Edit|MultiEdit|Bash","hooks":[{"type":"command","command":"sh \"${CLAUDE_PLUGIN_ROOT}/hooks/guard-finals.sh\""}]}]}}
```
`settings.json` snippet for the user (same, with `$HOME/.claude/skills/v2p/hooks/guard-finals.sh`). Known gaps, stated in the file header: the sed JSON extraction breaks on paths containing `"`; a Bash command that builds the filename indirectly (`f=.v2p/PLAN.md; echo x > $f`) passes; reading the finals (`cat .v2p/PLAN.md`) is not blocked (tested pattern). Whether subagent tool calls fire the hook is `(unverified)` — the falsifier in §5 covers it.

### 3.12 Edits to existing files

- **`SKILL.md`**: description adds "…or adopt an existing/half-built codebase (scans it, derives the BRIEF, audits and tidies)". §1 adds one line: "Blocks between `<!-- claude-only -->` markers apply to Claude Code only; other runtimes skip them." §2: argument list gains `adopt`; "No argument" becomes the probe rules of §2 above (claude-only: the script; portable: ask). §5: row `| adopt | phases/adopt.md | .v2p/BRIEF.md + .v2p/AUDIT.md | available |`; keep the bold "read the phase file in full" sentence and add "— including `adopt`". §6: `references/tidy-rules.md` and `references/audit-template.md` at adopt; `scripts/` list (claude-only): `tidy-check.sh` (probe + tidy, reusable as the tidy drift check), `quarantine.sh`, `finalize-audit.sh`, `finalize-plan.sh`, `check-pass.sh`.
- **`phases/handshake.md`**: Q0 — "existing code → stop; run `phases/adopt.md` (it derives the BRIEF and comes back to this file's gate)". Gate item 2: statuses `answered / defaulted / deferred / skipped / inferred`.
- **`references/brief-template.md`**: §10 header `| item | answered / defaulted / deferred / inferred | value (inferred: ← source path) |`.
- **`phases/scavenge.md`**: Q6 row text → "brownfield: copy the inventory line from `.v2p/AUDIT.md` §1 (written by adopt). AUDIT missing → print `Run /v2p adopt first.` and stop." Preconditions: resume rule (§3.10). Execution step 2: delete the `quick` Q6 sentence; add "write the planner's result to `.v2p/work/scavenge-q1-5.md` immediately"; step 3: "the subagent writes `.v2p/work/scavenge-q7.md` itself before returning"; step 4 unchanged. Rule 6: add "in every phase".
- **`phases/mapping.md`**: Preconditions add "BRIEF §1 Code = `existing` → `sh <skill>/scripts/check-pass.sh .v2p/AUDIT.md .v2p/.audit-pass` must print `OK`; otherwise `Run /v2p adopt first.`". Step 4 §4: "brownfield: copy AUDIT §2 verbatim (statuses and evidence kept); greenfield: as before"; numbers re-measured after core.md changes (core 102 → landing 161, saas-web 158, internal-tool 153, native-app 114 — builder re-measures with `grep -c '^- \[ \]'`). Step 3: "also read `docs/DECISIONS.md`; every `## From …` section's open items become a task or an explicit non-goal in PLAN". Step 5: write `.v2p/PLAN.draft.md`, run `finalize-plan.sh` until PASS (claude-only); mapping-plan checkpoint.
- **`references/model-routing.md`**: row `| adopt | \`quick\` (Sonnet) scan → writes .v2p/work/adopt-scan.md; main thread derives BRIEF, runs the gate, writes drafts, runs the scripts | Sonnet | none; Serena; code-review-graph if installed |`. Note: "`quick` has Write — subagent checkpoints are written by the subagent; planner results are written by the main thread on receipt." New section:
  ```
  ## Drift checks — slice-4 contract (not built in slice 3)
  | Cadence | Runs | Notes |
  |---|---|---|
  | every task | `git diff` vs the PLAN task's Files list; `/ponytail-audit` on the diff; `sh scripts/tidy-check.sh` | ponytail plugin enabled (measured 2026-09-23) |
  | every phase end | `/code-review` (`~/.claude/commands/code-review.md`, ECC); `/simplify` (code-simplifier plugin cached-disabled; built-in existence unverified — check `/help`); `/security-review` (built-in, verify with `/help`); `/translation-quality` (installed skill) only if BRIEF §9 i18n ON; `superpowers:verification-before-completion` + `verification-before-completion-extras` (there is no `/verify`) | |
  | before deploy | claude-security full scan (plugin enabled; command name unverified — `~/.claude/commands/security-scan.md` exists, origin not checked); Strix pentest (not installed; needs Docker + an LLM key; install only via `installing-third-party-tools` on the user's yes) | |
  Also available: context7 (API-contract verification), `claude-mem:learn-codebase` (optional, never a source of findings).
  ```
- **`references/skills-catalog.md`**: brownfield row: "install only through the `installing-third-party-tools` skill, on the user's yes, when adopt/scavenge first needs it; not required"; security row adds "Strix — suggested for the pre-deploy pentest; not installed; Docker + LLM key".
- **`build-portable.sh`**: after `references/plan-template.md` insert `phases/adopt.md references/audit-template.md references/tidy-rules.md`.
- **`README.md`**: phases table gains `adopt` (available); file map rows for the 11 files; total item count re-measured; verify block gains the four one-liners from §5 checks 1, 3, 6, 9.

***

## 4. Verification plan (run from the project dir; expected output stated; falsifier per structural check and per script)

### 4.1 Fixture and script tests — `tests/fixture-messy.sh` and `tests/test-tidy.sh`

`tests/fixture-messy.sh <dir>` (tested today):
```sh
#!/bin/sh
# Builds the messy sample project used to test tidy-check.sh and quarantine.sh. Usage: sh fixture-messy.sh <dir>
set -eu; d=$1; rm -rf "$d"; mkdir -p "$d/src" "$d/notes" "$d/empty-dir" "$d/dist" "$d/build"; cd "$d"
git init -q; printf 'dist/\n.env\nnode_modules/\n' > .gitignore
echo 'export const x = 1' > src/index.ts; echo 'SECRET=1' > .env; echo 'KEY=' > .env.example
echo '- ship v1' > TODO.md; echo 'idea: dark mode' > notes/ideas.md; echo 'old' > src/index_old.ts; echo 'b' > src/app.ts.bak
echo 'dup readme' > README_final_v2.md; echo 'd' > dist/bundle.js; echo 'o' > build/out.js; : > .DS_Store; echo 'log' > debug.log
ln -s src/index.ts link.ts; echo '{}' > package-lock.json; echo '{"name":"fx"}' > package.json
git add .gitignore src/index.ts README_final_v2.md package-lock.json package.json; git -c user.email=a@b -c user.name=a commit -qm init
echo 'dirty' >> src/index.ts
```
Covers: debris (`.DS_Store`, `.bak`), duplicates (`_old`, `final_v2`, one tracked), stray log, empty dir, orphaned build output not ignored (`build/`) vs ignored (`dist/`), scattered notes (`TODO.md`, `notes/`), a git-tracked file, a gitignored file (`.env`, `dist/bundle.js`), a symlink, a modified tracked file (`src/index.ts`), lockfile, no README.

`tests/test-tidy.sh` runs, for `SH in sh zsh` (the fixture in `${TMPDIR:-/tmp}/v2p-fx.$$`, quarantine root redirected by `HOME=<tmp>` so the real `~/.v2p-backups` is untouched), and asserts — measured today, these are the actual numbers:
1. `tidy-check.sh --probe` → line contains `code:yes git:dirty:1 brief:none audit:no`.
2. `tidy-check.sh --tsv | wc -l` → **14** (13 measured + 1 for the new `.v2p/work/` gitignore row); exit **1**; `sh` and `zsh` outputs byte-identical (`cmp`). Kinds present: `missing`×5 (README, CHANGELOG, .v2p/BRIEF.md, docs/ARCHITECTURE.md, docs/DECISIONS.md), `debris`×2, `duplicate`×2 (one `tracked yes`), `log`×1, `empty-dir`×1, `orphan-build build`×1, `scattered`×2 (`TODO.md`, `notes`), `gitignore`×1. Absent: `dist`, `.env`, `link.ts`, `package-lock.json`, `src/index.ts`.
3. Falsifier: `touch fx/CHANGELOG.md README.md` etc. until only debris remains → count drops by exactly the files created; `rm` all debris → exit **0**, `tidy: 0 violations`.
4. Dry-run: `tidy-check.sh --tsv | quarantine.sh` → `MOVE` lines for `.DS_Store build/out.js debug.log README_final_v2.md src/app.ts.bak src/index_old.ts` + `MOVE dir empty-dir`; `REFUSE not-merged-into-docs/DECISIONS.md` for `notes` and `TODO.md`; `dry-run: nothing moved`; exit **1**; `find fx -newer fx/.gitignore -type f` unchanged (nothing moved).
5. Refusals (falsifier for every guard): feed extra rows `x\t.env\tquarantine`, `x\t../outside.txt\tquarantine`, `x\tlink.ts\tquarantine`, `x\tdist/bundle.js\tquarantine`, `x\tsrc/index.ts\tquarantine`, `x\tpackage-lock.json\tquarantine` → `REFUSE never-touch .env`, `REFUSE outside-or-relative ../outside.txt`, `REFUSE symlink link.ts`, `REFUSE gitignored dist/bundle.js`, `REFUSE uncommitted-changes src/index.ts`, `REFUSE never-touch package-lock.json` (all observed today).
6. Apply after merging: create `docs/DECISIONS.md` with `## From TODO.md (merged …)` and `## From notes (merged …)`; `--apply` → exit **0**, `moved: 11 refused/failed: 0` (8 files + 3 dirs: `build`, `empty-dir`, `notes`); `MANIFEST.tsv` has 8 sha rows + 3 `-` rows; every sha row's hash equals `shasum -a 256` of the quarantined file; `git status --short` shows ` D README_final_v2.md`; `tidy-check.sh --tsv` afterwards → only the `missing`/`gitignore` rows (measured: 4 before the gitignore row was added).
7. Re-apply the same list → `REFUSE missing` ×9, exit **1**, nothing new in the manifest.
8. `sh <q>/restore.sh` → exit 0; every fixture file back; `tidy-check.sh --tsv | wc -l` → 14 again (measured 13 + 1).
9. Sha falsifier: run a copy of `quarantine.sh` with `sha()` replaced by `od -An -N4 -tx1 /dev/urandom | tr -d ' \n'` on the `.DS_Store` row → `FAIL sha mismatch after move: .DS_Store (now at …)`, exit **1**, the file exists at the quarantine path (observed today).
10. Zsh word-splitting falsifier: a script that does `for u in $urls` prints `1` under zsh vs `3` under sh (observed); `grep -nE 'for [a-z]+ in \$[a-z]' skills/v2p/scripts/*.sh` → must list **only** `finalize-scavenge.sh` line 10 (pre-existing; runs under `sh` by instruction) — new scripts: no output.

### 4.2 Structural checks

1. Router: `grep -cE '^\| `adopt` \| `phases/adopt\.md` \| .*\| available' skills/v2p/SKILL.md` → 1; `grep -c 'not available in this version' skills/v2p/SKILL.md` → 4 (unchanged). Falsifier: change `available` to `planned` in a scratch copy → 0.
2. Referenced paths (slice-1 check 2, rerun over `phases/adopt.md`, `references/tidy-rules.md`, `references/audit-template.md`; also `scripts/[a-z-]+\.sh` and `hooks/[a-z-]+\.(sh|json)`) → no `MISSING`. Falsifier: reference `scripts/nope.sh` in scratch → `MISSING` once.
3. **Tidy rules ↔ scripts** (new, falsifier mandatory): every backticked token in `references/tidy-rules.md` §2–§4 that contains `*` or `.` (`grep -oE '`[^`]+`' | tr -d '`'`) is found with `grep -qF` in `tidy-check.sh` or `quarantine.sh` → 0 unmatched. Falsifier: add `` `*.zzz` `` to tidy-rules.md in scratch → 1 unmatched.
4. **Modularity count**: `awk '/^## Modularity/{f=1;next} /^## /{f=0} f' skills/v2p/references/standards/core.md | grep -c '^- \[ \]'` → 6; `grep -c '^- \[ \]' skills/v2p/references/standards/core.md` → 102; mapping.md step 4 states the re-measured totals; README total updated. Falsifier: delete one item in scratch → 5 and the finalize-audit §3 check fails on a 6-row draft.
5. No item lost (slice-1 check 3 rerun) → zero `LOST:`.
6. Checkpoints in text: `grep -c '\.v2p/work/' skills/v2p/phases/scavenge.md` ≥ 3; `phases/adopt.md` ≥ 2; `grep -c 'work/scavenge-q7.md' skills/v2p/scripts/finalize-scavenge.sh` → 1. Falsifier: remove the work check from the script in scratch and run it on a draft with no work files → PASS printed (wrong) — proves the check is what blocks.
7. Receipts: `grep -c 'audit-pass' skills/v2p/scripts/finalize-audit.sh skills/v2p/phases/mapping.md` → 1 each; `grep -c 'check-pass.sh' skills/v2p/phases/mapping.md` → 2 (scavenge + audit).
8. `***` / copyright / frontmatter: `grep -ln '^---$' <new .md files>` → none; `tail -1` each → copyright; SKILL.md still has exactly 2 frontmatter fences.
9. Portable build: `sh build-portable.sh`; `grep -c '<!-- source: phases/adopt.md -->' dist/v2p-portable.md` → 1; `grep -c 'tidy-rules\|audit-template' dist/…` ≥ 2; `grep -c 'AskUserQuestion\|claude-only\|check-pass\|finalize-audit\|quarantine.sh' dist/…` → 0 (script names live only in claude-only blocks); `grep -c 'Rafael Arciniegas'` → 1; size reported (expect < 160,000 bytes). Rebuild to a temp path and `diff` → empty.
10. Scripts syntax under both shells: `for s in skills/v2p/scripts/*.sh skills/v2p/hooks/*.sh; do sh -n "$s" && zsh -n "$s"; done` → no output.
11. Hook offline falsifiers: `printf '{"tool_name":"Write","tool_input":{"file_path":"/p/.v2p/AUDIT.md"}}' | sh skills/v2p/hooks/guard-finals.sh; echo $?` → stderr message, **2**; same with `AUDIT.draft.md` → **0**; `{"tool_name":"Bash","tool_input":{"command":"cat .v2p/PLAN.md"}}` → 0; `"command":"echo x > .v2p/PLAN.md"` → 2; `"command":"sh skills/v2p/scripts/finalize-scavenge.sh .v2p"` → 0; `"command":"mv .v2p/PLAN.draft.md .v2p/PLAN.md"` → 2.
12. finalize-audit falsifiers (scratch `.v2p/` with a landing BRIEF): a draft with 160 §2 rows when 161 are expected → `FAIL: §2 rows 160/161`; a `done` row with empty evidence → FAIL naming it; an `N/A` row without `BRIEF §` → FAIL; `quarantine: /nope/MANIFEST.tsv` → FAIL; a §5 row whose destination lacks `From <src>` → FAIL; a correct draft → PASS, `.v2p/AUDIT.md` line 1 starts `checked: 161/161`, `.v2p/.audit-pass` equals `shasum -a 256 .v2p/AUDIT.md`; then `echo x >> .v2p/AUDIT.md; sh scripts/check-pass.sh .v2p/AUDIT.md .v2p/.audit-pass` → `FAIL … changed after finalize`.
13. finalize-plan falsifier: a draft with 3 `### Task` and 2 `**Verifier:**` → FAIL; equal → PASS + `.plan-pass`.

### 4.3 Live test script (user, fresh session; the skill is live through `~/.claude/skills/v2p`)

Setup: `sh tests/fixture-messy.sh ~/tmp/v2p-live && cd ~/tmp/v2p-live && git add -A >/dev/null; git -c user.email=a@b -c user.name=a commit -qm base` (clean tree so the branch offer appears) — or skip the commit to test the dirty path.

1. `/v2p` → expect: the probe line printed (`code:yes … brief:none`), then the AskUserQuestion "Existing code found: Adopt …(Recommended)". Falsifier: run `/v2p` in an empty dir → goes straight to "What are we building?".
2. Choose Adopt → expect: branch question (clean) or the "uncommitted changes stay untouched" line (dirty); "spawning quick scan"; `.v2p/work/adopt-scan.md` appears with the header line; the running brief shows `(inferred)` values with `← package.json` style sources; only Q2/Q5/Q6/Q9 asked, ≤3 per turn; explicit confirmation requested; `.v2p/BRIEF.md` written with `Code: existing at …` and ≥3 `inferred` rows.
3. Expect the tidy table shown, `docs/DECISIONS.md` created with `## From TODO.md` and `## From notes/ideas.md` sections shown before any move, the dry-run `MOVE`/`REFUSE` lines, then the approval question. Approve → `manifest: ~/.v2p-backups/v2p-live/<ts>/MANIFEST.tsv`, `restore: sh …/restore.sh`. Check: `ls ~/.v2p-backups/v2p-live/*/` mirrors paths; `.env`, `link.ts`, `dist/` untouched.
4. Expect `PASS: … -> .v2p/AUDIT.md`, `checked:` on line 1, `.v2p/.audit-pass` present, `.v2p/work/` empty, `Next: /v2p scavenge`. Falsifier: `echo x >> .v2p/AUDIT.md` then `/v2p mapping` (after a scavenge) → `Run /v2p adopt first.` (check-pass FAIL).
5. Crash/resume falsifier: run `/v2p scavenge`; when `.v2p/work/scavenge-q1-5.md` exists, `/clear` (or end the session) and run `/v2p scavenge` again → "resuming from …" and no planner spawn; delete `.v2p/work/scavenge-q7.md` and run the finalize → `FAIL: checkpoint … missing`.
6. Hook (only if the user installs the settings.json snippet): "write `hello` to `.v2p/PLAN.md` with the Write tool" → blocked with the v2p message; then the same instruction to a `quick` subagent → records whether the block fires (this settles the `(unverified)` subagent question). Remove the snippet afterwards if it was only a test.
7. Second `/v2p adopt` with the BRIEF present → "BRIEF kept; running audit + tidy" and no interview.

***

## 5. Portability constraint — what in slice 3 would break under another agent

Layout stays Agent Skills-compatible: `SKILL.md` with `name` + `description`, relative paths, `scripts/` POSIX sh. Reported by search results, not fetched by me: Codex CLI reads `~/.codex/skills/` and `.codex/skills/` (third-party guides; `(unverified)` against OpenAI's docs); Gemini CLI discovers `~/.gemini/skills/`, `~/.agents/skills/`, `.gemini/skills/`, `.agents/skills/`, activates via `activate_skill`, and adds the skill dir to allowed read paths (snippet of the official `docs/cli/skills.md`; page not fetched). Sources: https://github.com/google-gemini/gemini-cli/blob/main/docs/cli/skills.md · https://geminicli.com/docs/cli/skills/ · https://agentskillshub.dev/guides/codex-skills/ · https://www.agensi.io/learn/codex-cli-skills-install-skill-md.

Would break / needs a per-agent build later:
- Everything in `<!-- claude-only -->` blocks is *visible* to an agent that reads SKILL.md raw (`AskUserQuestion`, `planner`/`quick`, superpowers/gstack names, script invocations phrased for Claude). The new SKILL.md §1 line tells other runtimes to skip those blocks; a per-agent build that strips them (like `build-portable.sh`) is the real fix — roadmap item.
- Hooks: Claude Code only (`settings.json` / plugin `hooks/hooks.json`); Codex/Gemini equivalents `(unverified)`. Receipts + `check-pass.sh` are the portable baseline and work anywhere a shell runs.
- Subagent split and model routing: Claude-only by design; portable text does the steps in one pass.
- `/v2p adopt` argument syntax: Claude Code slash-command convention; Gemini's `activate_skill` has no argument — the router's wording "argument, or the phase word in the user's message" covers it.
- `phases/` is not one of the conventional subdirs (`scripts/`, `references/`, `assets/`) — allowed as bundled files `(unverified against the spec text)`.
- Script dependencies: `git`, `curl` (finalize-scavenge), `shasum` or `sha256sum`, `realpath` (fallback to `pwd -P` is in the code), BSD/GNU `stat` both handled, `find -print -quit` (BSD + GNU; busybox `(unverified)`).
- `~/.agents/skills/` is a Gemini discovery path and the default of `npx skills add`; the user's CLAUDE.md §7 calls it scatter. The future plugin will have to symlink one canonical copy into each agent's path, which contradicts "one copy" only in spirit (symlinks, not copies).

***

## 6. Sources and machine state used

- Files read: the two specs, `SKILL.md`, `phases/{handshake,scavenge,mapping}.md`, `references/{brief,scavenge,plan}-template.md`, `model-routing.md`, `skills-catalog.md`, `standards/core.md`, `scripts/{finalize-scavenge,check-pass}.sh`, `build-portable.sh`, `README.md`, `docs/ROADMAP.md` (HEAD `a8e4380`).
- Measured 2026-09-23: macOS 27.0, `sh` = bash 3.2.57, zsh 5.9, git 2.55, `/bin/realpath` present, `shasum` + `/sbin/sha256sum` present, `rg` present, `code-review-graph` **absent**, `~/.claude/skills/installing-third-party-tools` present, ponytail plugin enabled with `ponytail-audit` command, `claude-security` + `security-guidance` + `playwright` + `last30days` + `superpowers` enabled, `code-review` + `code-simplifier` cached-disabled, `~/.claude/commands/code-review.md` and `security-scan.md` exist (origin ECC, not checked), `translation-quality` skill installed, `~/.claude/skills/v2p` → this project's `skills/v2p`.
- zsh `for x in $var` does not split (1 vs 3, tested); zsh `echo -` prints nothing (caused a sh/zsh diff until replaced by `printf`).
- Prototypes live in this session's scratchpad (`…/scratchpad/proto/{tidy-check.sh,quarantine.sh,fixture.sh}`) — session-scoped, so the full text is inlined above; test quarantine dirs under `~/.v2p-backups/fx` were removed.

***

## 7. Risks / pushback

- **Hook covering PLAN.md forces a mapping change** (draft + `finalize-plan.sh`). Either accept the 15-line script and the two-line mapping edit, or drop PLAN from the hook. A hook that blocks a file with no finalize path breaks the phase; do not ship that combination.
- **No time-based refusal in `quarantine.sh`.** An untracked `TODO.md` another session created ten minutes ago is listed like any other; protection = pattern scoping + the `age_days` column + the user's explicit approval. If the user wants a hard guard, add `REFUSE recent` for `age_days = 0` on `scattered`/`dup-readme` rows only (3 lines) — I advise against it by default because `.DS_Store`-style rows are always "recent" and the rule would train blanket overrides.
- **Branch creation in a shared checkout** is still a checkout switch. It is offered only on a clean tree and only on a yes; the user's own CLAUDE.md prefers worktrees, but a worktree cannot see untracked debris and `.v2p/` must live where the user works. If the user disagrees, delete Step 0's branch offer; nothing else depends on it.
- **Duplicate patterns are name-based** (`_v2`, `final`): legitimate `schema_v2.sql` or `openapi-v3.yaml` will appear in the list (`-v[0-9]` was deliberately excluded; `_v[0-9]` kept). Cost: an untick. `dist/` committed on purpose (this very project) is flagged `orphan-build`.
- **Merges are verbatim, not summarised** — DECISIONS.md may get long. That is the lossless choice; pruning is a later human edit. The gate only checks the `From <path>` heading exists, not that the content is complete; the "show the added sections before moving" step is the human check.
- **AUDIT §2 with 150+ rows is mostly `pending`** on a first adopt; that is honest, not a defect. The value is the `done` rows with evidence and the `N/A` rows; mapping inherits them instead of re-deriving.
- **The inferred profile can be wrong** (e.g. an internal tool with public-looking auth). The gate makes the user confirm; the disambiguator is always asked when login exists.
- **Item counts change** (core 96 → 102): mapping.md, README and slice-2 check 9 numbers must be re-measured, not copied from this spec.
- **Hook JSON parsing by `sed`** is deliberately dependency-free and therefore brittle on unusual paths; `jq` exists on this machine but is not a portable assumption. Subagent hook firing and `${CLAUDE_PLUGIN_ROOT}` are `(unverified)`; the live test 6 settles the first.
- **Live runs are unverified** (checks 4.3): they need a session. Everything in 4.1 was executed today with the numbers stated (13 rows before the added gitignore rule; the builder's first run should show 14 and must not "fix" the script to get 13).

Relevant absolute paths: `/Users/user/SynologyDrive/code/ai/claude/Projects/personal_skills/vibe-to-product/skills/v2p/SKILL.md`, `…/skills/v2p/phases/{handshake,scavenge,mapping}.md`, `…/skills/v2p/references/{brief-template,model-routing,skills-catalog}.md`, `…/skills/v2p/references/standards/core.md`, `…/skills/v2p/scripts/{finalize-scavenge,check-pass}.sh`, `…/build-portable.sh`, `…/README.md`, `…/docs/ROADMAP.md`, `…/docs/specs/slice-2-spec.md`; machine state: `/Users/user/.claude/settings.json` (enabledPlugins), `/Users/user/.claude/skills/installing-third-party-tools/SKILL.md`, `/Users/user/.claude/agents/{planner,quick}.md` (planner: no Write; quick: Sonnet, writes).
