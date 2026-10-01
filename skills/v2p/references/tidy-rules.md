# Tidy rules

Which files and folders a v2p project should have, which ones are debris, and which ones are never touched. The tidy check reads this list and never changes anything; the quarantine step moves approved items out of the project and never deletes them. `<project>` = the git toplevel, or the directory v2p runs in.
<!-- claude-only -->
In Claude Code both are scripts: `scripts/tidy-check.sh` (read-only; `--probe`, `--tsv`) and `scripts/quarantine.sh` (dry-run unless `--apply`). Every pattern in §2–§4 appears verbatim in one of the two scripts; the slice-3 verification greps for that, so edit both together.
<!-- /claude-only -->

## 1. Canonical set
Required rows are what the tidy check reports as `missing`.

| Path | Required | Profile | Owner |
|---|---|---|---|
| `README.md` | yes | all | adopt creates it from the BRIEF if missing |
| `CHANGELOG.md` | yes | all | adopt creates `## Unreleased` |
| `.gitignore` | yes (git only) | all | must contain `.v2p/work/` and `.v2p/*.draft.md` |
| `.env.example` | when any `.env*` exists | all | names only, never values |
| `.v2p/BRIEF.md` | yes | all | handshake / adopt |
| `.v2p/SCAVENGE.md`, `PLAN.md`, `REVIEW.md`, `DEPLOY.md` | by their phase | all | the phase's finalize step only |
| `.v2p/AUDIT.md` | brownfield | all | adopt's finalize step |
| `.v2p/work/` | transient | all | checkpoints; cleared by the finalize step; gitignored |
| `docs/ARCHITECTURE.md` | yes | all | module map + data flow |
| `docs/DECISIONS.md` | yes | all | merged notes/ADRs; `## From <path>` sections |
| `docs/threat-model.md` | before the review phase | all with a backend | reported as `pending (review)`, never `missing` |
| `src/` or the framework's own roots (`app/`, `pages/`, `lib/`, `ios/`, `android/`, `public/`, `migrations/`) | — | framework-owned | never flagged |

Profile deltas: `native-app` adds `ios/` and `android/` as framework-owned; `landing` may omit `docs/threat-model.md` (`N/A — BRIEF §8 no backend`). No other profile differences exist.

## 2. Debris
Each `kind` below has the action `quarantine`.
- `debris`: `.DS_Store`, `Thumbs.db`, `desktop.ini`, `._*`, `*~`, `*.swp`, `*.swo`, `.#*`, `*.orig`, `*.rej`, `*.bak`, `*.bak.*`, `*.backup`, `*_backup*`, `*.tmp`, `*.temp`, `*.pyc`
- `duplicate`: `*_old.*`, `*_old`, `*-old.*`, `*.old`, `*_copy.*`, `* copy.*`, `* copy`, `*_final*`, `*-final*`, `*final_v[0-9]*`, `*_v[0-9].*`, `*_v[0-9][0-9].*`, `* ([0-9]).*`. Name-based: a legitimate schema_v2.sql will be listed and the user unticks it. (`-v[0-9]` is deliberately not a pattern.)
- `log`: `*.log`, `npm-debug.log*`, `yarn-error.log*`, `lerna-debug.log*` (only when not gitignored)
- `orphan-build` (directory, only when not gitignored): `dist`, `build`, `out`, `.next`, `.nuxt`, `.output`, `.turbo`, `coverage`, `__pycache__`, `.pytest_cache`, `.mypy_cache`, `.parcel-cache`, `.cache`. The right fix is usually a `.gitignore` line; say so next to the row.
- `empty-dir`: any directory with no entries

## 3. Scattered notes
`kind` `scattered` or `dup-readme`, action `merge:<dest>`.
- → `docs/DECISIONS.md`: files `NOTES*`, `notes*.md`, `TODO*`, `todo*.md`, `IDEAS*`, `ideas*.md`, `ROADMAP*`, `BACKLOG*`, `SCRATCH*`, `PLAN*`, `plan*.md`, `DECISIONS*`, `ADR*`, `*.notes.md`, `*.notes.txt`; directories `notes`, `ideas`, `adr`, `adrs`, `decisions`
- → `docs/ARCHITECTURE.md`: `ARCHITECTURE*`, `architecture*.md`, `DESIGN.md`, `design.md`
- → `CHANGELOG.md`: `CHANGES*`, `HISTORY*`
- → `README.md` (root only): `README_*`, `README-*`, `README.txt`, `README.old`, `readme*`, `Readme*`
- Exempt: `docs/DECISIONS.md`, `docs/ARCHITECTURE.md`, `docs/threat-model.md`, `CHANGELOG.md`, `README.md`, anything under `.v2p/`
- Merge rule: the destination gains `## From <path> (merged <YYYY-MM-DD>)` + the original content verbatim; the quarantine step refuses the original until that heading exists in the destination; the user sees the added sections before anything moves.

## 4. Never touch
Neither step lists or moves these; the quarantine step prints `REFUSE never-touch` (or the reason below).
- Directories: `.git/`, `.v2p/`, `.claude/`, `.serena/`, `.github/`, `.vscode/`, `.idea/`, `node_modules/`, `.venv/`, `venv/`, `vendor/`, `data/`, `uploads/`, `storage/`
- The canonical files of §1; `.env` and `.env.*` (except `.env.example`, which is canonical)
- Lockfiles: `package-lock.json`, `pnpm-lock.yaml`, `yarn.lock`, `bun.lockb`, `bun.lock`, `Cargo.lock`, `poetry.lock`, `uv.lock`, `Gemfile.lock`, `composer.lock`, `Podfile.lock`, `go.sum`
- Databases: `*.sqlite`, `*.sqlite3`, `*.db`
- Anything git ignores (`REFUSE gitignored`). Without git, the tidy check reads `.gitignore` itself: each entry hides that name or path and everything under it, at any depth; glob (`*`) and negation (`!`) entries are skipped.
- Symlinks: never followed, never moved, refused anywhere in the path (`REFUSE symlink`)
- Anything outside the project root (realpath prefix check; `REFUSE outside-or-relative`)
- The quarantine directory itself: it lives in the home directory, and the step refuses to run with the project root set to `/` or the home directory.

## 5. Git-tracked vs untracked
Tracked files are moved like any other; git then shows ` D <path>` and the user commits the removal (or restores). A tracked file with uncommitted modifications is refused (`REFUSE uncommitted-changes`): commit or discard first; v2p never does it for you. Untracked files are moved; ignored files are never touched. The `tracked` and `age_days` columns are shown so recent, human-authored files stand out before approval. v2p never stashes, commits, resets or switches branches on a dirty tree.

## 6. Quarantine layout
`~/.v2p-backups/<project>/<YYYY-MM-DD-HHMMSS>/` mirrors the relative paths. `MANIFEST.tsv` has one row per item (`path sha256 tracked reason restore`; a header comment names the root, the time and the restore command). `restore.sh` has one `mkdir -p … && mv …` per file and one `mkdir -p` per emptied directory. Each move is verified by sha256. v2p never empties the quarantine; the user does.

Portable (no scripts): list the rows as a table with the columns `kind path action tracked age_days`, and the user moves approved items by hand with `mkdir -p ~/.v2p-backups/<project>/<ts>/<dir> && mv <path> ~/.v2p-backups/<project>/<ts>/<path>`. There is no receipt without the scripts; say so.

***
Copyright © 2026 Rafael Arciniegas. Licensed under the MIT License.
