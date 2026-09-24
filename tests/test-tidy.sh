#!/bin/sh
# Runs tidy-check.sh and quarantine.sh against the messy fixture under sh and zsh (slice-3 spec §4.1).
# Writes only under ${TMPDIR:-/tmp}/v2p-test.<pid>; HOME points there, so the real ~/.v2p-backups is never touched.
# Usage: sh tests/test-tidy.sh   (exit 0 = all PASS)
here=$(cd "$(dirname "$0")/.." && pwd -P); S=$here/skills/v2p/scripts
base=$(cd "${TMPDIR:-/tmp}" && pwd -P)/v2p-test.$$; mkdir -p "$base/home"; HOME=$base/home; export HOME
fails=0; T=$(printf '\t')
is() { if [ "$2" = "$3" ]; then echo "PASS [$SH] $1"; else echo "FAIL [$SH] $1: got '$2' want '$3'"; fails=$((fails+1)); fi; }
has() { case $2 in *"$3"*) echo "PASS [$SH] $1" ;; *) echo "FAIL [$SH] $1: missing '$3'"; fails=$((fails+1)) ;; esac; }
files() { find . -path ./.git -prune -o -print | sort; }
for SH in sh zsh; do
  fx=$base/v2p-fixture-$$-$SH; sh "$here/tests/fixture-messy.sh" "$fx"; cd "$fx" || exit 2
  # 1-2. probe, row count, kinds, absences
  p=$($SH "$S/tidy-check.sh" --probe); has "1 probe" "$p" "code:yes git:dirty:1 branch:"; has "1 probe" "$p" "brief:none audit:no"
  $SH "$S/tidy-check.sh" --tsv > "$base/tsv-$SH"; is "2 exit" $? 1
  is "2 rows" "$(grep -c . "$base/tsv-$SH")" 15
  is "2 kinds" "$(cut -f1 "$base/tsv-$SH" | sort | uniq -c | tr -s ' ' | tr '\n' ',')" " 2 debris, 2 duplicate, 1 empty-dir, 1 gitignore, 1 log, 5 missing, 1 orphan-build, 2 scattered,"
  is "2 tracked duplicate" "$(grep -c "^duplicate${T}.*${T}yes${T}" "$base/tsv-$SH")" 1
  is "2 absent" "$(cut -f2 "$base/tsv-$SH" | grep -cxE 'dist|dist/bundle.js|\.env|link\.ts|package-lock\.json|src/index\.ts')" 0
  # 3. falsifier: fixing each finding drops the count to 0 (separate copy)
  f3=$base/f3-$SH; sh "$here/tests/fixture-messy.sh" "$f3"; cd "$f3"
  mkdir -p .v2p docs; touch README.md CHANGELOG.md .v2p/BRIEF.md docs/ARCHITECTURE.md docs/DECISIONS.md
  is "3 after creating 5" "$($SH "$S/tidy-check.sh" --tsv | grep -c .)" 10
  printf '.v2p/work/\n' >> .gitignore; rm -rf .DS_Store build debug.log empty-dir notes README_final_v2.md src/app.ts.bak src/index_old.ts TODO.md
  out=$($SH "$S/tidy-check.sh"); is "3 clean exit" $? 0; has "3 clean" "$out" "tidy: 0 violations"
  cd "$fx"
  # 4. dry-run moves nothing
  before=$(files); dry=$($SH "$S/tidy-check.sh" --tsv | $SH "$S/quarantine.sh"); is "4 dry exit" $? 1
  is "4 MOVE" "$(printf '%s\n' "$dry" | grep '^MOVE' | cut -f2 | tr '\n' ' ')" ".DS_Store build/out.js debug.log empty-dir README_final_v2.md src/app.ts.bak src/index_old.ts "
  is "4 REFUSE" "$(printf '%s\n' "$dry" | grep -c '^REFUSE not-merged-into-docs/DECISIONS.md')" 2
  has "4 dry" "$dry" "dry-run: nothing moved"; is "4 untouched" "$(files)" "$before"
  # 5. every guard refuses
  r=$(printf 'x\t.env\tquarantine\nx\t../outside.txt\tquarantine\nx\tlink.ts\tquarantine\nx\tdist/bundle.js\tquarantine\nx\tsrc/index.ts\tquarantine\nx\tpackage-lock.json\tquarantine\n' | $SH "$S/quarantine.sh" --apply)
  is "5 refusals" "$(printf '%s\n' "$r" | grep '^REFUSE' | tr '\t' ' ' | tr '\n' ',')" "REFUSE never-touch .env,REFUSE outside-or-relative ../outside.txt,REFUSE symlink link.ts,REFUSE gitignored dist/bundle.js,REFUSE uncommitted-changes src/index.ts,REFUSE never-touch package-lock.json,"
  # 6. apply after merging
  mkdir -p docs; printf '## From TODO.md (merged 2026-09-23)\n- ship v1\n## From notes (merged 2026-09-23)\nidea: dark mode\n' > docs/DECISIONS.md
  $SH "$S/tidy-check.sh" --tsv > "$base/list-$SH"; before=$(files)
  a=$($SH "$S/quarantine.sh" --apply < "$base/list-$SH"); is "6 apply exit" $? 0; has "6 apply" "$a" "moved: 11 refused/failed: 0"
  man=$(printf '%s\n' "$a" | sed -n 's/^manifest: //p'); q=${man%/MANIFEST.tsv}
  is "6 sha rows" "$(grep -v '^#' "$man" | awk -F'\t' '$2!="-"' | grep -c .)" 8
  is "6 dir rows" "$(grep -v '^#' "$man" | awk -F'\t' '$2=="-"' | grep -c .)" 3
  is "6 sha verified" "$(grep -v '^#' "$man" | awk -F'\t' '$2!="-"{print $1"\t"$2}' | while IFS="$T" read -r f h; do [ "$(shasum -a 256 "$q/$f" | cut -d' ' -f1)" = "$h" ] && echo ok; done | grep -c ok)" 8
  has "6 git D" "$(git status --short)" " D README_final_v2.md"
  is "6 after" "$($SH "$S/tidy-check.sh" --tsv | cut -f1 | sort | uniq -c | tr -s ' ' | tr '\n' ',')" " 1 gitignore, 4 missing,"
  # 7. re-apply: everything missing, first manifest unchanged
  m1=$(cat "$man"); r=$($SH "$S/quarantine.sh" --apply < "$base/list-$SH"); is "7 exit" $? 1
  is "7 missing" "$(printf '%s\n' "$r" | grep -c '^REFUSE missing')" 9; is "7 manifest unchanged" "$(cat "$man")" "$m1"
  # 8. restore
  sh "$q/restore.sh"; is "8 restore exit" $? 0; is "8 files back" "$(files)" "$before"
  is "8 tidy again" "$($SH "$S/tidy-check.sh" --tsv)" "$(grep -v "docs/DECISIONS.md${T}create" "$base/tsv-$SH")"
  # 9. sha falsifier: a mismatch is reported and the file stays in quarantine
  awk '/^sha\(\) /{print "sha() { od -An -N4 -tx1 /dev/urandom | tr -d \" \\n\"; }"; next} {print}' "$S/quarantine.sh" > "$base/q-bad.sh"
  r=$(printf 'debris\t.DS_Store\tquarantine\n' | $SH "$base/q-bad.sh" --apply); is "9 exit" $? 1
  has "9 FAIL" "$r" "FAIL sha mismatch after move: .DS_Store (now at "
  q9=$(printf '%s\n' "$r" | sed -n 's/^manifest: //p'); is "9 kept" "$(test -f "${q9%/MANIFEST.tsv}/.DS_Store" && echo yes)" yes
  # 9b. two applies in the same second keep both manifests (regression: the second used to truncate the first)
  n1=$(find "$HOME/.v2p-backups" -name MANIFEST.tsv | wc -l)
  printf 'log\tdebug.log\tquarantine\n' | $SH "$S/quarantine.sh" --apply >/dev/null; printf 'debris\tsrc/app.ts.bak\tquarantine\n' | $SH "$S/quarantine.sh" --apply >/dev/null
  is "9b two manifests" "$(( $(find "$HOME/.v2p-backups" -name MANIFEST.tsv | wc -l) - n1 ))" 2
  cd "$base"
done
# 10. zsh does not word-split unquoted expansions; new scripts must not rely on it
SH=zsh; is "10 zsh split" "$(zsh -c 'u="a b c"; n=0; for x in $u; do n=$((n+1)); done; echo $n')" 1
SH=sh; is "10 sh split" "$(sh -c 'u="a b c"; n=0; for x in $u; do n=$((n+1)); done; echo $n')" 3
SH=all; is "10 for-in-unquoted" "$(cd "$S" && grep -nE 'for [a-z]+ in \$[a-z]' *.sh | cut -d: -f1 | tr '\n' ' ')" "finalize-scavenge.sh "
echo "test-tidy: $fails failures (scratch: $base)"
[ "$fails" -eq 0 ]
