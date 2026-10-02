# AUDIT template

Adopt writes this as `.v2p/AUDIT.draft.md`, never as `AUDIT.md`; the finalize step checks it and produces `AUDIT.md`. Replace every `<…>`.

Statuses are exactly `done`, `pending`, `N/A — <reason citing BRIEF §n>`, `not adopted — <path §/line>`, `gap — <path:line>`. `done` needs evidence: `` `cmd` → expected `` (any `→` makes it a command claim, so a path is written without one), a path, or a URL. A cell command has no pipe (a cell needs `\|`, which is copied into PLAN §4 and reads there as a literal pipe): use `grep -c`, `rg -e a -e b`. An absence claim (`→ 0`, `` `! …` ``) carries a positive control in the same cell: `` control: `cmd` → n ``. `N/A` carries its `BRIEF §n` reason in the status cell, never in the evidence cell: execute empties the evidence of every row but `done` when it copies the table. `not adopted` (owner decision) and `gap` (known, not built) cite a path that exists in the repo.
<!-- claude-only -->
The finalize step is `sh <skill>/scripts/finalize-audit.sh .v2p`: it checks the row counts against the standards files, the evidence rules above and the §5 merges, runs every §2 and §3 `done` row's `` `cmd` → expected `` pair in the repo root (exit 0; a bare-number expected must equal the last output line; a `→` with nothing run fails; a path-only evidence whose path word holds a quote, pipe, `\`, `^` or `$` fails as a pattern; an absence claim without `control:` only warns), fails a `\|` inside a backticked table cell (a copied command keeps the backslash), inserts the `tidy-check.sh` output into §4, stamps the `checked:` line and writes the receipt `.v2p/.audit-pass`.
<!-- /claude-only -->

````
# AUDIT — <project name>
checked: pending   ← the finalize step replaces this line; a hand-written AUDIT.md has no receipt and mapping refuses it
written: <YYYY-MM-DD> by v2p adopt · reads: .v2p/BRIEF.md (<written date>) · root: <abs path> · git: <none|clean|dirty:n> · branch: <b>

## 1. Inventory
- stack <…> · entry points <…> · env vars referenced <n> (.env.example: present|missing) · tests <runner|none, n files> · deps created <6 months: <list|none> · TODO/FIXME <n> · files >200 lines <n: paths>
- Module map: <dir (n files)> … · cross-module internal imports <n> · cycles <n|not checked>

## 2. Standards (one row per item of the BRIEF §9 files; mapping copies this table into PLAN §4)
| item | file | status | evidence |
|---|---|---|---|
| <label> | core.md | done | `<command>` → <output> |
| <label> | web.md | pending | |
| <label> | landing.md | N/A — BRIEF §9 block OFF | |
| <label> | core.md | not adopted — docs/DECISIONS.md §Sessions | |
Rows: <n> = <core> + <web> + <profile> (the finalize step checks the sum against the standards files)

## 3. Modularity (one row per core.md "Modularity" item)
| item | status | evidence |
|---|---|---|

## 4. Tidy
<tidy check output — inserted by the finalize step; do not write by hand>
backup: <~/.v2p-backups/<project>/<ts>-original.tar.gz | declined | none | user copy at <abs path of the user's copy or zip>>
quarantine: <~/.v2p-backups/<project>/<ts>/MANIFEST.tsv | declined | none | by hand to <abs dir the user moved the items into>>

## 5. Merges (originals quarantined after the destination gained "## From <path>")
| source | destination |
|---|---|
| <path> | docs/DECISIONS.md |
(or: none)

Next: /v2p scavenge
````

Portable: there is no finalize step. Write `.v2p/AUDIT.md` directly (or print it in one code block), leave `checked: pending`, paste the tidy table into §4, and say that nothing verified the counts.

***
Copyright © 2026 Rafael Arciniegas. Licensed under the MIT License.
