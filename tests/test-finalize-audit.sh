#!/bin/sh
# finalize-audit.sh §2/§3 status rules on a minimal adopt draft (BRIEF §9 = core.md), under sh and zsh: a good draft
# passes; `not adopted` and `gap` rows pass only when they cite a path that exists in the repo; unknown statuses fail.
# Writes only under ${TMPDIR:-/tmp}/v2p-fa.<pid> (HOME points there too). Usage: sh tests/test-finalize-audit.sh
here=$(cd "$(dirname "$0")/.." && pwd -P); S=$here/skills/v2p/scripts; core=$here/skills/v2p/references/standards/core.md
base=$(cd "${TMPDIR:-/tmp}" && pwd -P)/v2p-fa.$$; mkdir -p "$base/home"; HOME=$base/home; export HOME
fails=0
is() { if [ "$2" = "$3" ]; then echo "PASS [$SH] $1"; else echo "FAIL [$SH] $1: got '$2' want '$3'"; fails=$((fails+1)); fi; }
has() { case $2 in *"$3"*) echo "PASS [$SH] $1" ;; *) echo "FAIL [$SH] $1: missing '$3' in: $(printf '%s' "$2" | head -c 300)"; fails=$((fails+1)) ;; esac; }
hasnt() { case $2 in *"$3"*) echo "FAIL [$SH] $1: still has '$3'"; fails=$((fails+1)) ;; *) echo "PASS [$SH] $1" ;; esac; }
FA() { out=$($SH "$S/finalize-audit.sh" .v2p 2>&1); rc=$?; }
# plant <row 1 replacement>: the good draft with §2 row 1 (std1) replaced; any earlier AUDIT.md removed
plant() { rm -f .v2p/AUDIT.md .v2p/.audit-pass; R=$1 awk '!done && $0 == "| std1 | core.md | pending | |" { print ENVIRON["R"]; done = 1; next } { print }' "$G" > .v2p/AUDIT.draft.md; }
for SH in sh zsh; do
  fx=$base/fx-$SH; mkdir -p "$fx/.v2p"; cd "$fx" || exit 2; G=$base/good-$SH
  echo '# fixture' > README.md; echo '- [ ] passkeys: rejected, see docs' > BACKLOG.md
  printf '%s\n' '# BRIEF' '' '## 9. Standards' '- core.md' '' '## 11. Open questions' 'none' > .v2p/BRIEF.md
  { printf '%s\n' '# AUDIT — fixture' 'checked: pending' '' '## 2. Standards' '| item | file | status | evidence |' '|---|---|---|---|'
    grep '^- \[ \]' "$core" | awk '{print "| std" NR " | core.md | pending | |"}'
    printf '%s\n' '' '## 3. Modularity' '| item | status | evidence |' '|---|---|---|'
    awk '/^## Modularity/{f=1;next} /^## /{f=0} f' "$core" | grep '^- \[ \]' | awk '{print "| mod" NR " | pending | |"}'
    printf '%s\n' '' '## 4. Tidy' 'backup: declined' 'quarantine: declined' '' '## 5. Merges' '| source | destination |' '|---|---|' '| none | |'; } > "$G"
  # 1. the good draft passes (the fixture is valid)
  plant '| std1 | core.md | pending | |'; FA; is "1 good exit" $rc 0; has "1 PASS" "$out" "PASS: "
  # 2. not adopted: an owner decision cited by an existing path passes (status cell or evidence cell)
  plant '| std1 | core.md | not adopted — README.md §Auth | |'; FA; is "2 not adopted, path in status exit" $rc 0
  plant '| std1 | core.md | not adopted | BACKLOG.md:1 |'; FA; is "2 not adopted, path in evidence exit" $rc 0
  # 3. not adopted citing a missing, absolute or outside path fails
  plant '| std1 | core.md | not adopted — docs/DECISIONS.md §Auth | |'; FA; is "3 missing path exit" $rc 1; has "3 missing path" "$out" "not adopted cites no existing path"
  plant '| std1 | core.md | not adopted — /etc/hosts | |'; FA; is "3 absolute path exit" $rc 1; has "3 absolute path" "$out" "not adopted cites no existing path"
  plant '| std1 | core.md | not adopted — ../fx-sh/README.md | |'; FA; is "3 outside path exit" $rc 1; has "3 outside path" "$out" "not adopted cites no existing path"
  plant '| std1 | core.md | not adopted | |'; FA; is "3 no ref exit" $rc 1; has "3 no ref" "$out" "not adopted cites no existing path"
  # 4. gap: a known gap carried to an existing backlog path passes
  plant '| std1 | core.md | gap — BACKLOG.md:1 | |'; FA; is "4 gap exit" $rc 0
  # 5. gap with a bogus ref fails
  plant '| std1 | core.md | gap — TICKET-42 | |'; FA; is "5 bogus gap exit" $rc 1; has "5 bogus gap" "$out" "gap cites no existing path"
  # 6. an unknown status still fails
  plant '| std1 | core.md | met-by | README.md |'; FA; is "6 unknown exit" $rc 1; has "6 unknown" "$out" "status not done/pending/N/A"
  # 7. §3 (modularity) shares the rules
  rm -f .v2p/AUDIT.md .v2p/.audit-pass; sed 's/^| mod1 | pending | |$/| mod1 | gap — nowhere.md | |/' "$G" > .v2p/AUDIT.draft.md
  FA; is "7 §3 bogus gap exit" $rc 1; has "7 §3 bogus gap" "$out" "gap cites no existing path"
  # 9. V1 loose ends: `N/A — BRIEF §n` in the status cell (adopt.md's form) passes; the template's N/A row, with the
  # evidence cell emptied as execute's copy does, still passes; a hyphen works like the em dash after not adopted / gap
  plant '| std1 | core.md | N/A — BRIEF §9 block OFF | |'; FA; is "9 N/A reason in status exit" $rc 0
  plant '| std1 | core.md | N/A — not needed | |'; FA; is "9 N/A without BRIEF exit" $rc 1; has "9 N/A without BRIEF" "$out" "N/A without BRIEF §"
  trow=$(grep -m1 '^| <label> | [a-z-]*\.md | N/A' "$here/skills/v2p/references/audit-template.md" | awk -F'|' -v OFS='|' '{$2=" std1 "; $5=" "; print}')
  plant "$trow"; FA; is "9 template N/A row survives an emptied evidence cell" $rc 0
  plant '| std1 | core.md | not adopted - README.md §Auth | |'; FA; is "9 not adopted hyphen exit" $rc 0
  plant '| std1 | core.md | gap - BACKLOG.md:1 | |'; FA; is "9 gap hyphen exit" $rc 0
  # 8. a §2 done row's `cmd` → expected pair runs here (field test V2: slash-literal patterns "→ 0" proved nothing):
  # same parser and comparison as task-record.sh, run in the repo root; an arrow with nothing run fails
  plant '| std1 | core.md | done | `grep -c fixture README.md` → 1 |'; FA; is "8 matching output exit" $rc 0
  has "8 runs counted" "$(grep '^checked: ' .v2p/AUDIT.md 2>/dev/null)" "evidence runs 1/1"
  plant '| std1 | core.md | done | `grep -c fixture README.md` → 2 |'; FA; is "8 differing output exit" $rc 1
  has "8 differing output" "$out" 'FAIL: §2 std1: `grep -c fixture README.md` → 1 (expected 2)'
  plant '| std1 | core.md | done | `test -f nowhere.md` → exit 0 |'; FA; is "8 failing command exit" $rc 1; has "8 failing command" "$out" '`test -f nowhere.md` exit 1'
  plant "| std1 | core.md | done | rg 'queryRawUnsafe/executeRawUnsafe' → 0 |"; FA; is "8 unbackticked arrow exit" $rc 1; has "8 unbackticked arrow" "$out" "nothing ran"
  plant '| std1 | core.md | done | `<command>` → <output> |'; FA; is "8 placeholder only exit" $rc 1; has "8 placeholder only" "$out" "nothing ran"
  plant '| std1 | core.md | done | `test -f README.md` → exit 0 |'; out=$(cd / && $SH "$S/finalize-audit.sh" "$fx/.v2p" 2>&1); rc=$?; is "8 runs in the repo root exit" $rc 0
  # 8b. lint: a done evidence accepted only as a path whose slash word holds a quote, pipe or regex character
  plant "| std1 | core.md | done | rg 'queryRawUnsafe/sql\\.unsafe' 0 hits |"; FA; is "8b pattern as path exit" $rc 1; has "8b pattern as path" "$out" "a pattern, not a path"
  plant '| std1 | core.md | done | src/app/[locale]/(shop)/page.tsx:3 sets it |'; FA; is "8b route-group path passes" $rc 0
  # 8c. an absence claim without a positive control is a WARN, not a FAIL
  plant '| std1 | core.md | done | `! grep -q lorem README.md` → exit 0 |'; FA; is "8c absence exit" $rc 0; has "8c absence warns" "$out" "WARN: §2 std1: absence claim"
  plant '| std1 | core.md | done | `! grep -q lorem README.md` → exit 0 · control: `grep -c fixture README.md` → 1 |'; FA; is "8c control exit" $rc 0; hasnt "8c control no warn" "$out" "WARN"
  # 8d. trust boundary: a draft tracked by git came from the repo, not this session; its commands never run
  plant '| std1 | core.md | done | `touch pwned` → exit 0 |'; git init -q; git add -f .v2p/AUDIT.draft.md; FA; rm -rf .git
  is "8d tracked draft exit" $rc 1; has "8d tracked draft" "$out" "tracked by git"; is "8d nothing ran" "$(test -f pwned && echo yes)" ""
  # 8e. `\|` inside a backticked cell fails here, as finalize-plan's V30 lint does later (the copied command keeps the
  # backslash); a `\|` outside backticks is plain text (control)
  plant "| std1 | core.md | done | \`echo 'a\\|b'\` → exit 0 |"; FA; is "8e escaped pipe in a done cell exit" $rc 1; has "8e escaped pipe" "$out" 'has `\|` inside backticks'
  plant "| std1 | core.md | pending | \`grep -E 'a\\|b' README.md\` later |"; FA; is "8e escaped pipe in a pending cell exit" $rc 1; has "8e pending names the line" "$out" "FAIL: line "
  plant "| std1 | core.md | pending | grep -E 'a\\|b' later |"; FA; is "8e escaped pipe outside backticks exit" $rc 0
  # 8f. §3 (modularity) done evidence runs like §2's: same loop, same trust boundary
  m3() { rm -f .v2p/AUDIT.md .v2p/.audit-pass; R=$1 awk '!done && $0 == "| mod1 | pending | |" { print ENVIRON["R"]; done = 1; next } { print }' "$G" > .v2p/AUDIT.draft.md; }
  m3 '| mod1 | done | `grep -c fixture README.md` → 2 |'; FA; is "8f §3 differing output exit" $rc 1
  has "8f §3 differing output" "$out" 'FAIL: §3 mod1: `grep -c fixture README.md` → 1 (expected 2)'
  m3 '| mod1 | done | `grep -c fixture README.md` → 1 |'; FA; is "8f §3 matching exit" $rc 0; has "8f §3 runs counted" "$out" "evidence runs 1/1"
  m3 "| mod1 | done | rg 'big/file' → 0 |"; FA; is "8f §3 unbackticked arrow exit" $rc 1; has "8f §3 unbackticked arrow" "$out" "FAIL: §3 mod1: done evidence has → but no backticked"
  m3 '| mod1 | done | `touch pwned` → exit 0 |'; git init -q; git add -f .v2p/AUDIT.draft.md; FA; rm -rf .git
  is "8f §3 tracked draft exit" $rc 1; is "8f §3 nothing ran" "$(test -f pwned && echo yes)" ""
  cd "$base"
  # B. §4 backup line: exactly one, declined|none|existing archive
  cd "$fx" || exit 2
  bk() { sed "s#^backup: .*#$1#" "$G" > .v2p/AUDIT.draft.md; rm -f .v2p/AUDIT.md .v2p/.audit-pass; }
  bk 'backup: none'; FA; is "B none exit" $rc 0
  is "B backup line kept in §4" "$(grep -c '^backup: none$' .v2p/AUDIT.md 2>/dev/null)" 1
  mkdir -p "$HOME/.v2p-backups/p"; : > "$HOME/.v2p-backups/p/2026-10-01-000000-original.tar.gz"
  bk "backup: $HOME/.v2p-backups/p/2026-10-01-000000-original.tar.gz"; FA; is "B archive exit" $rc 0
  bk 'backup: ~/.v2p-backups/p/2026-10-01-000000-original.tar.gz'; FA; is "B ~ archive exit" $rc 0
  bk 'backup: ~/.v2p-backups/p/missing-original.tar.gz'; FA; is "B missing archive exit" $rc 1; has "B missing archive" "$out" "not found"
  bk 'backup: yes'; FA; is "B bad value exit" $rc 1; has "B bad value" "$out" "backup:"
  sed 's#^backup: declined#backup: declined\nbackup: none#' "$G" > .v2p/AUDIT.draft.md; rm -f .v2p/AUDIT.md .v2p/.audit-pass; FA; is "B two lines exit" $rc 1
  grep -v '^backup: ' "$G" > .v2p/AUDIT.draft.md; rm -f .v2p/AUDIT.md .v2p/.audit-pass; FA; is "B no line exit" $rc 1
  # Q. portable values: a copy the user made, items the user moved by hand (each path must exist)
  mkdir -p "$HOME/copies/proj" "$HOME/.v2p-backups/p/by-hand"
  bk 'backup: user copy at ~/copies/proj'; FA; is "Q user copy exit" $rc 0
  bk "backup: user copy at $HOME/copies/proj"; FA; is "Q user copy abs exit" $rc 0
  bk 'backup: user copy at ~/copies/missing'; FA; is "Q user copy missing exit" $rc 1; has "Q user copy missing" "$out" "not found"
  bk 'backup: user copy at'; FA; is "Q user copy no path exit" $rc 1
  qk() { sed "s#^quarantine: .*#$1#" "$G" > .v2p/AUDIT.draft.md; rm -f .v2p/AUDIT.md .v2p/.audit-pass; }
  qk 'quarantine: by hand to ~/.v2p-backups/p/by-hand'; FA; is "Q by hand exit" $rc 0; has "Q by hand stamped" "$(sed -n 2p .v2p/AUDIT.md)" "quarantine: by hand to ~/.v2p-backups/p/by-hand"
  qk 'quarantine: by hand to ~/.v2p-backups/p/gone'; FA; is "Q by hand missing exit" $rc 1; has "Q by hand missing" "$out" "not found"
  qk 'quarantine: moved'; FA; is "Q bad value exit" $rc 1; has "Q bad value" "$out" "quarantine:"
  # Q2. none: quarantine.sh found nothing to quarantine
  qk 'quarantine: none'; FA; is "Q none exit" $rc 0; has "Q none stamped" "$(grep '^checked: ' .v2p/AUDIT.md 2>/dev/null)" "quarantine: none"
  qk 'quarantine: nothing'; FA; is "Q nothing exit" $rc 1; has "Q nothing" "$out" "'quarantine: declined|none|<path>/MANIFEST.tsv|by hand to <dir>'"
  qk 'quarantine: ~/.v2p-backups/p/missing/MANIFEST.tsv'; FA; is "Q missing manifest exit" $rc 1
done
SH=all; echo "test-finalize-audit: $fails failures (scratch: $base)"
[ "$fails" -eq 0 ] && rm -rf "$base"
[ "$fails" -eq 0 ]
