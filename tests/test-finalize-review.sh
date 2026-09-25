#!/bin/sh
# finalize-review.sh on the execute fixture after a finalize-execute PASS, under sh and zsh: the bad draft in
# tests/fixtures/finalize-review/REVIEW.md must FAIL every check, each FAIL must disappear as the copy is fixed one
# step at a time, and the verifier re-run, the receipt, the stale-head and the i18n rules are each shown refusing.
# Writes only under ${TMPDIR:-/tmp}/v2p-fr.<pid> (HOME points there too). Usage: sh tests/test-finalize-review.sh
here=$(cd "$(dirname "$0")/.." && pwd -P); S=$here/skills/v2p/scripts; src=$here/tests/fixtures/finalize-review/REVIEW.md
base=$(cd "${TMPDIR:-/tmp}" && pwd -P)/v2p-fr.$$; mkdir -p "$base/home"; HOME=$base/home; export HOME
GIT_AUTHOR_NAME=t GIT_AUTHOR_EMAIL=t@t GIT_COMMITTER_NAME=t GIT_COMMITTER_EMAIL=t@t; export GIT_AUTHOR_NAME GIT_AUTHOR_EMAIL GIT_COMMITTER_NAME GIT_COMMITTER_EMAIL
sum0=$(shasum -a 256 < "$src"); fails=0
is() { if [ "$2" = "$3" ]; then echo "PASS [$SH] $1"; else echo "FAIL [$SH] $1: got '$2' want '$3'"; fails=$((fails+1)); fi; }
has() { case $2 in *"$3"*) echo "PASS [$SH] $1" ;; *) echo "FAIL [$SH] $1: missing '$3' in: $(printf '%s' "$2" | head -c 400)"; fails=$((fails+1)) ;; esac; }
hasnt() { case $2 in *"$3"*) echo "FAIL [$SH] $1: still has '$3'"; fails=$((fails+1)) ;; *) echo "PASS [$SH] $1" ;; esac; }
FR() { out=$($SH "$S/finalize-review.sh" .v2p 2>&1); rc=$?; }
q() { sh "$S/task-record.sh" "$@" >/dev/null 2>&1 || { echo "ERROR: task-record.sh $* failed; test did not run"; exit 2; }; }
sub() { A=$1 B=$2 awk 'index($0, ENVIRON["A"]) { i = index($0, ENVIRON["A"]); $0 = substr($0, 1, i-1) ENVIRON["B"] substr($0, i+length(ENVIRON["A"])) } { print }' "$P" > "$P.new" && mv "$P.new" "$P"; }
ins() { RE=$1 T=$2 awk '!done && $0 ~ ENVIRON["RE"] { print ENVIRON["T"]; done = 1 } { print }' "$P" > "$P.new" && mv "$P.new" "$P"; }
M1="§1 missing security row"; M2="§1 missing qa row"; M3="§1 codex findings cell 'some'"; M4="§2 fix commit deadbeef not found"
M5="pending without deferred to deploy"; M6="no 'pre-deploy: pending"; M7="'---' rule"
for SH in sh zsh; do
  fx=$base/fx-$SH; sh "$here/tests/fixture-execute.sh" "$fx" >/dev/null 2>&1; cd "$fx" || exit 2
  # execute, the short way (test-execute.sh covers each step's refusals)
  q start 1; mkdir -p tests; printf 'echo hi\n' > src/greet.sh; printf '[ "$(sh src/greet.sh)" = hi ]\n' > tests/greet.test.sh; q verify 1
  git add -A; git commit -qm 'feat: greeting'; q ponytail 1 none
  q start 2; printf 'echo hi\n# greeting\n' > src/greet.sh; q verify 2; q manual 2 "saw hi"; git add -A; git commit -qm 'feat: comment'; q ponytail 2 none
  q skip 3 "handed to /v2p review"
  { printf '%s\n' '# EXECUTE — fixture' 'checked: pending' 'written: 2026-09-24' '' '## 1. Tasks' '' '## 2. Standards' '| item | file | status | evidence |' '|---|---|---|---|'
    awk '/^## 4\./{f=1;next} /^## /{f=0} f && /^\| / && !/^\| item/' .v2p/PLAN.md; printf '%s\n' '' 'Next: /v2p review'; } > .v2p/EXECUTE.draft.md
  o=$(sh "$S/finalize-execute.sh" .v2p) || { echo "ERROR: finalize-execute did not PASS: $o"; exit 2; }
  base0=$(sed -n 's/^checked: .* · base \([^ ]*\) .*/\1/p' .v2p/EXECUTE.md)
  # review work: the threat model doc lands as a review fix commit
  mkdir -p docs; echo '# Threat model: no entry points' > docs/threat-model.md; git add -A; git commit -qm 'docs: threat model'
  P=.v2p/REVIEW.draft.md; H=$(git rev-parse HEAD)
  awk '/^## 2\./{f=1;next} /^## /{f=0} f && /^\| / && !/^\| item/' .v2p/EXECUTE.md | awk -F'|' 'NR==1 {print "|" $2 "| " "core.md | pending | |"; next} {print "|" $2 "|" $3 "| done | src/greet.sh |"}' > "$base/rows-$SH"
  R=$base/rows-$SH awk '$0 == "{{STANDARDS_ROWS}}" { while ((getline l < ENVIRON["R"]) > 0) print l; next } { print }' "$src" | sed "s/{{BASE}}/$base0/; s/{{HEAD}}/$H/" > "$P"
  # 0. the bad draft fails every check and writes nothing
  FR; is "0 exit" $rc 1; for m in "$M1" "$M2" "$M3" "$M4" "$M5" "$M6" "$M7"; do has "0 $m" "$out" "$m"; done
  is "0 no REVIEW.md" "$(test -f .v2p/REVIEW.md && echo yes)" ""
  # 1. required rows
  ins '^\| codex ' '| security | /security-review; /claude-security scan changes --base '"$base0"' --effort low | 0 findings |'
  ins '^\| codex ' '| qa | /qa on http://localhost:8787 | 0 findings |'
  FR; hasnt "1 security row" "$out" "$M1"; hasnt "1 qa row" "$out" "$M2"
  # 2. codex findings count (also makes §2 rows = sum)
  sub '| codex | /codex review | some |' '| codex | /codex review | 2 findings |'; FR; hasnt "2 codex cell" "$out" "$M3"; hasnt "2 rows = sum" "$out" "§1 findings sum"
  # 3. the fix sha must be a real commit
  sub 'fixed deadbeef' "fixed $(git rev-parse --short HEAD)"; FR; hasnt "3 sha" "$out" "$M4"
  # 4. pending only as deferred to deploy
  first=$(head -n 1 "$base/rows-$SH"); sub "$first" "$(printf '%s\n' "$first" | sed 's/| pending | |$/| pending | deferred to deploy: needs prod URL |/')"
  FR; hasnt "4 deferred" "$out" "$M5"
  # 5. pre-deploy line
  ins '^Next: /v2p deploy' 'pre-deploy: pending (claude-security full scan + Strix pentest run by /v2p deploy)
'
  FR; hasnt "5 pre-deploy" "$out" "$M6"
  # 6. --- → ***
  sed 's/^---$/***/' "$P" > "$P.new" && mv "$P.new" "$P"; FR; hasnt "6 rule" "$out" "$M7"; is "6 exit (verifiers ran, all good)" $rc 0
  # the draft was consumed by that PASS; restore it for the falsifiers below
  cp .v2p/REVIEW.md "$base/review-$SH"; rm .v2p/REVIEW.md .v2p/.review-pass; sed 's/^checked: .*/checked: pending/' "$base/review-$SH" > "$P"; cp "$P" "$base/good-$SH"
  # 7. falsifier: no .execute-pass → refuse
  mv .v2p/.execute-pass "$base/xp"; FR; is "7 no receipt exit" $rc 1; has "7 no receipt" "$out" "EXECUTE.md does not match its receipt"; mv "$base/xp" .v2p/.execute-pass
  # 8. falsifier: a committed break in src/greet.sh → the verifier re-run refuses (head updated so only that fails)
  printf 'echo bye\n' > src/greet.sh; git commit -qam 'break'; sub "..$H" "..$(git rev-parse HEAD)"
  FR; is "8 exit" $rc 1; has "8 verifier re-run" "$out" "FAIL: verifier of task 1 fails after review fixes: sh tests/greet.test.sh exit 1"
  has "8 task 2 bare number" "$out" "run: task 2:"; hasnt "8 task 3 skipped" "$out" "run: task 3"
  git reset -q --hard HEAD~1; cp "$base/good-$SH" "$P"
  # 9. falsifier: a commit after the draft's diff head → stale review
  echo note >> docs/threat-model.md; git commit -qam 'docs: note'; FR; has "9 stale head" "$out" "is not HEAD"
  git reset -q --hard HEAD~1
  # 10. falsifier: i18n ON in BRIEF §9 → an i18n row is required
  cp .v2p/BRIEF.md "$base/brief"; printf '%s\n' '- Conditional blocks ON: i18n' >> "$base/brief.i18n"
  R=$base/brief.i18n awk '{print} /^## 9/{while ((getline l < ENVIRON["R"]) > 0) print l}' "$base/brief" > .v2p/BRIEF.md
  FR; has "10 i18n required" "$out" "§1 missing i18n row"
  ins '^\| codex ' '| i18n | translation-quality on messages/* | 0 findings |'; FR; hasnt "10 i18n row" "$out" "missing i18n row"; is "10 exit" $rc 0; has "10 runs 8/8" "$(grep '^checked: ' .v2p/REVIEW.md)" "runs 8/8"
  rm .v2p/REVIEW.md .v2p/.review-pass; rm -f "$base/brief.i18n"; cp "$base/brief" .v2p/BRIEF.md; cp "$base/good-$SH" "$P"
  # 11. final PASS
  FR; is "11 exit" $rc 0; has "11 PASS" "$out" "PASS: runs 7/7"
  has "11 checked" "$(grep '^checked: ' .v2p/REVIEW.md)" "checked: runs 7/7 · findings 3 (fixed 1 · accepted 1 · open 1) · standards done 192 · N/A 0 · deferred 1 · verifiers 2/2 pass"
  is "11 receipt" "$(cat .v2p/.review-pass)" "$(shasum -a 256 .v2p/REVIEW.md | cut -d' ' -f1)"; is "11 draft gone" "$(test -f "$P" && echo yes)" ""
  # 13. a deferred task's verifier is not re-run (live: it needs a credential that does not exist until deploy).
  # EXECUTE §1 row 1 re-written as deferred and re-sealed; a committed change breaks task 1's verifier only.
  rm .v2p/REVIEW.md .v2p/.review-pass; cp "$base/good-$SH" "$P"
  awk -F'|' -v OFS='|' '/^\| 1 \|/ { $5 = " deferred — VERCEL_TOKEN " } { print }' .v2p/EXECUTE.md > "$base/ex13" && cat "$base/ex13" > .v2p/EXECUTE.md
  shasum -a 256 .v2p/EXECUTE.md | cut -d' ' -f1 > .v2p/.execute-pass
  printf 'echo hi there\n' > src/greet.sh; git commit -qam 'change greeting'; sub "..$H" "..$(git rev-parse HEAD)"
  FR; is "13 deferred exit" $rc 0; hasnt "13 deferred not re-run" "$out" "run: task 1"; has "13 others still run" "$out" "run: task 2:"
  # 14. a verifier wrong as written is ruled a plan defect (live Task 5: raw `wc -l` padded on macOS): with the
  # user-approved ruling line it is not re-run and is counted; without it, or malformed, the review fails.
  rm .v2p/REVIEW.md .v2p/.review-pass
  printf 'echo bye\n' > src/greet.sh; git commit -qam 'break task 2 verifier'
  cp "$base/good-$SH" "$P"; sub "..$H" "..$(git rev-parse HEAD)"; cp "$P" "$base/p14-$SH"
  FR; is "14 no ruling exit" $rc 1; has "14 no ruling fails" "$out" "FAIL: verifier of task 2 fails"
  cp "$base/p14-$SH" "$P"; printf 'ruling: task 2 plan defect\n' >> "$P"
  FR; is "14 malformed exit" $rc 1; has "14 malformed msg" "$out" "FAIL: malformed ruling line"
  cp "$base/p14-$SH" "$P"; printf 'ruling: task 9 · plan defect · x\n' >> "$P"
  FR; is "14 unknown task exit" $rc 1; has "14 unknown task msg" "$out" "FAIL: ruling names task(s) not in PLAN: 9"
  cp "$base/p14-$SH" "$P"; printf 'ruling: task 2 · plan defect · grep target moved; property checked by hand\n' >> "$P"
  FR; is "14 ruled exit" $rc 0; has "14 ruled not re-run" "$out" "ruling: task 2 verifier not re-run (plan defect)"
  has "14 PASS counts it" "$out" "rulings 1 ->"; has "14 checked counts it" "$(grep '^checked:' .v2p/REVIEW.md)" "· rulings 1 ·"
  cd "$base"
done
SH=all; is "12 source untouched" "$(shasum -a 256 < "$src")" "$sum0"
echo "test-finalize-review: $fails failures (scratch: $base)"
[ "$fails" -eq 0 ]
