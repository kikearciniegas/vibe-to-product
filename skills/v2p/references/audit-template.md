# AUDIT template

Adopt writes this as `.v2p/AUDIT.draft.md`, never as `AUDIT.md`; the finalize step checks it and produces `AUDIT.md`. Replace every `<…>`.

Statuses are exactly `done`, `pending`, `N/A`. `done` needs evidence: `cmd → output`, a path, or a URL. `N/A` needs `BRIEF §n` in the evidence cell.
<!-- claude-only -->
The finalize step is `sh <skill>/scripts/finalize-audit.sh .v2p`: it checks the row counts against the standards files, the evidence rules above and the §5 merges, inserts the `tidy-check.sh` output into §4, stamps the `checked:` line and writes the receipt `.v2p/.audit-pass`.
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
| <label> | landing.md | N/A | BRIEF §9 block OFF |
Rows: <n> = <core> + <web> + <profile> (the finalize step checks the sum against the standards files)

## 3. Modularity (one row per core.md "Modularity" item)
| item | status | evidence |
|---|---|---|

## 4. Tidy
<tidy check output — inserted by the finalize step; do not write by hand>
quarantine: <~/.v2p-backups/<project>/<ts>/MANIFEST.tsv | declined>

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
