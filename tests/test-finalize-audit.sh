#!/bin/sh
# finalize-audit.sh §2/§3 status rules on a minimal adopt draft (BRIEF §9 = core.md), under sh and zsh: a good draft
# passes; `not adopted` and `gap` rows pass only when they cite a path that exists in the repo; unknown statuses fail.
# Writes only under ${TMPDIR:-/tmp}/v2p-fa.<pid> (HOME points there too). Usage: sh tests/test-finalize-audit.sh
here=$(cd "$(dirname "$0")/.." && pwd -P); S=$here/skills/v2p/scripts; core=$here/skills/v2p/references/standards/core.md
base=$(cd "${TMPDIR:-/tmp}" && pwd -P)/v2p-fa.$$; mkdir -p "$base/home"; HOME=$base/home; export HOME
fails=0
is() { if [ "$2" = "$3" ]; then echo "PASS [$SH] $1"; else echo "FAIL [$SH] $1: got '$2' want '$3'"; fails=$((fails+1)); fi; }
has() { case $2 in *"$3"*) echo "PASS [$SH] $1" ;; *) echo "FAIL [$SH] $1: missing '$3' in: $(printf '%s' "$2" | head -c 300)"; fails=$((fails+1)) ;; esac; }
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
    printf '%s\n' '' '## 4. Tidy' 'quarantine: declined' '' '## 5. Merges' '| source | destination |' '|---|---|' '| none | |'; } > "$G"
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
  cd "$base"
done
SH=all; echo "test-finalize-audit: $fails failures (scratch: $base)"
[ "$fails" -eq 0 ] && rm -rf "$base"
[ "$fails" -eq 0 ]
