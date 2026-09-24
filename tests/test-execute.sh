#!/bin/sh
# drift-check.sh, task-record.sh and finalize-execute.sh on the execute fixture (tests/fixture-execute.sh), under
# sh and zsh. Every gate is shown refusing a planted defect before it passes. Writes only under
# ${TMPDIR:-/tmp}/v2p-ex.<pid> (HOME points there too). Usage: sh tests/test-execute.sh   (exit 0 = all PASS)
here=$(cd "$(dirname "$0")/.." && pwd -P); S=$here/skills/v2p/scripts
base=$(cd "${TMPDIR:-/tmp}" && pwd -P)/v2p-ex.$$; mkdir -p "$base/home"; HOME=$base/home; export HOME
GIT_AUTHOR_NAME=t GIT_AUTHOR_EMAIL=t@t GIT_COMMITTER_NAME=t GIT_COMMITTER_EMAIL=t@t; export GIT_AUTHOR_NAME GIT_AUTHOR_EMAIL GIT_COMMITTER_NAME GIT_COMMITTER_EMAIL
fails=0
is() { if [ "$2" = "$3" ]; then echo "PASS [$SH] $1"; else echo "FAIL [$SH] $1: got '$2' want '$3'"; fails=$((fails+1)); fi; }
has() { case $2 in *"$3"*) echo "PASS [$SH] $1" ;; *) echo "FAIL [$SH] $1: missing '$3' in: $(printf '%s' "$2" | head -c 300)"; fails=$((fails+1)) ;; esac; }
hasnt() { case $2 in *"$3"*) echo "FAIL [$SH] $1: still has '$3'"; fails=$((fails+1)) ;; *) echo "PASS [$SH] $1" ;; esac; }
sha() { shasum -a 256 "$1" | cut -d' ' -f1; }
TR() { out=$($SH "$S/task-record.sh" "$@" 2>&1); rc=$?; }
DC() { out=$($SH "$S/drift-check.sh" "$@" 2>&1); rc=$?; }
FE() { out=$($SH "$S/finalize-execute.sh" .v2p 2>&1); rc=$?; }
rec1=.v2p/work/execute-task-1.md
for SH in sh zsh; do
  fx=$base/fx-$SH; sh "$here/tests/fixture-execute.sh" "$fx" >/dev/null 2>&1; cd "$fx" || exit 2
  main=$(git rev-parse --abbrev-ref HEAD)
  # 1. start records base/branch/plan and seals it; falsifier: a corrupt PLAN receipt → exit 2, no record
  cp .v2p/.plan-pass "$base/pp"; echo 0 > .v2p/.plan-pass
  TR start 1; is "1 bad receipt exit" $rc 2; has "1 bad receipt msg" "$out" "PLAN has no valid receipt"; is "1 no record" "$(test -f $rec1 && echo yes)" ""
  cp "$base/pp" .v2p/.plan-pass
  TR start 1; is "1 start exit" $rc 0
  is "1 plan:" "$(sed -n 's/.* · plan: //p' $rec1)" "$(cat .v2p/.plan-pass)"
  is "1 base:" "$(sed -n 's/.* · base: \([^ ]*\) .*/\1/p' $rec1)" "$(git rev-parse HEAD)"
  is "1 receipt" "$(cat .v2p/work/.execute-task-1-pass)" "$(sha $rec1)"
  TR start 1; has "1 resume" "$out" "resume: task 1"
  # 2. clean tree → OK
  DC 1; is "2 exit" $rc 0; has "2 OK" "$out" "OK: 0 changed paths"
  # 3. in-scope files OK; stray file → DRIFT file; verify blocked by drift
  mkdir -p src tests; printf 'echo hi\n' > src/greet.sh; printf '[ "$(sh src/greet.sh)" = hi ]\n' > tests/greet.test.sh
  DC 1; is "3 in-scope exit" $rc 0; has "3 in-scope" "$out" "OK: 2 changed paths within Task 1 scope"
  echo x > stray.txt; DC 1; is "3 stray exit" $rc 1; has "3 stray" "$out" "DRIFT file stray.txt"
  TR verify 1; is "3 verify exit" $rc 1; has "3 blocked" "$(cat $rec1)" "verifier: blocked by drift · attempts: 1"
  rm stray.txt
  # 4. failing test → fail (attempt 2); fixed → pass (attempt 3); task-record never records pass without exit 0
  printf 'echo bye\n' > src/greet.sh; TR verify 1; is "4 fail exit" $rc 1; has "4 fail line" "$(cat $rec1)" "verifier: fail · attempts: 2 · exit 1"
  printf 'echo hi\n' > src/greet.sh; TR verify 1; is "4 pass exit" $rc 0; has "4 pass line" "$(cat $rec1)" "verifier: pass · attempts: 3 · exit 0"
  has "4 output block" "$(cat $rec1)" "output:
  \$ sh tests/greet.test.sh   (exit 0)"
  # 4b. a hand-edited record is refused (receipt) — the record cannot be typed
  cp $rec1 "$base/rec"; sed 's/^verifier: .*/verifier: pass/' "$base/rec" > $rec1; TR ponytail 1 none; is "4b tamper exit" $rc 2; has "4b tamper" "$out" "changed outside task-record.sh"; cp "$base/rec" $rec1
  # 5. branch switch → DRIFT branch
  git switch -q -c other; DC 1; is "5 exit" $rc 1; has "5 branch" "$out" "DRIFT branch other (recorded $main)"; git switch -q "$main"
  # 6. amendment: out-of-scope file OK only after allow
  mkdir -p docs; echo usage > docs/usage.md; DC 1; has "6 before allow" "$out" "DRIFT file docs/usage.md"
  TR allow 1 docs/usage.md "reviewer asked for a usage note"; is "6 allow exit" $rc 0
  has "6 amendment line" "$(cat .v2p/PLAN-AMENDMENTS.md)" "· task 1 · files += \`docs/usage.md\` · reviewer asked for a usage note"
  DC 1; is "6 after allow exit" $rc 0; has "6 after allow" "$out" "(1 allowed by amendments)"
  # 7. ponytail shape
  s0=$(sha $rec1); TR ponytail 1 junk; is "7 junk exit" $rc 2; is "7 unchanged" "$(sha $rec1)" "$s0"
  TR verify 1; is "7 re-verify" $rc 0
  git add -A; git commit -qm 'feat: greeting script'
  TR ponytail 1 none; is "7 none exit" $rc 0; has "7 line" "$(cat $rec1)" "ponytail-review: none"; has "7 head = task commit" "$(cat $rec1)" "head: $(git rev-parse HEAD)"
  # 8. task 2: glob + bracket path; bracket falsifier; bare-number expected
  TR start 2; is "8 start 2" $rc 0
  printf 'echo hi\n# greeting\n' > src/greet.sh; mkdir -p 'app/[locale]'; echo p > 'app/[locale]/page.tsx'
  DC 2; is "8 scope exit" $rc 0; has "8 scope" "$out" "OK: 2 changed paths within Task 2 scope"
  mkdir -p app/l; echo p > app/l/page.tsx; DC 2; is "8 bracket falsifier exit" $rc 1; has "8 bracket falsifier" "$out" "DRIFT file app/l/page.tsx"; rm -r app/l
  TR verify 2; is "8 verify 1" $rc 0; has "8 → 1" "$(cat .v2p/work/execute-task-2.md)" "verifier: pass · attempts: 1 · exit 0 · \`sh -c 'grep -c hi src/greet.sh'\` → 1"
  printf 'echo hi\necho hi\n' > src/greet.sh; TR verify 2; is "8 two exit" $rc 1; has "8 exit 0 but wrong number" "$(cat .v2p/work/execute-task-2.md)" "verifier: fail · attempts: 2 · exit 0"
  printf 'echo hi\n# greeting\n' > src/greet.sh; TR verify 2; is "8 re-pass" $rc 0
  # 9. manual observation
  TR manual 2 ""; is "9 empty exit" $rc 2; TR manual 2 none; is "9 none exit" $rc 2
  TR manual 2 "opened it, saw hi"; is "9 exit" $rc 0; has "9 line" "$(cat .v2p/work/execute-task-2.md)" "manual: opened it, saw hi · by user ·"
  git add -A; git commit -qm 'feat: locale page'
  TR ponytail 2 "1 findings, 1 cut, 0 accepted: dropped an unused helper"; is "9 ponytail" $rc 0
  # 10. finalize-execute
  FE; is "10 no record exit" $rc 1; has "10 no record" "$out" "task 3: no record"
  TR skip 3 "handed to /v2p review"; is "10 skip" $rc 0
  FE; has "10 no draft" "$out" "EXECUTE.draft.md missing"
  { printf '%s\n' '# EXECUTE — fixture' 'checked: pending' 'written: 2026-09-24 by v2p execute · reads: .v2p/PLAN.md · mode: subagent-driven · amendments: 1' '' '## 1. Tasks' '<generated>' '' '## 2. Standards' '| item | file | status | evidence |' '|---|---|---|---|'
    awk '/^## 4\./{f=1;next} /^## /{f=0} f && /^\| / && !/^\| item/' .v2p/PLAN.md; printf '%s\n' '' 'Next: /v2p review'; } > "$base/draft"
  D=.v2p/EXECUTE.draft.md; row1=$(grep -m1 '| core.md | pending | |' "$base/draft"); it1=$(printf '%s\n' "$row1" | cut -d'|' -f2)
  plant() { R1=$row1 R2=$1 awk '$0 == ENVIRON["R1"] { print ENVIRON["R2"]; next } { print }' "$base/draft" > $D; }
  plant "|$it1| core.md | done | |"; FE; is "10 done-no-evidence exit" $rc 1; has "10 done without evidence" "$out" "done without evidence"
  plant "|$it1| core.md | N/A | nothing |"; FE; has "10 N/A without BRIEF" "$out" "N/A without BRIEF §"
  plant "|$it1| core.md | [x] | |"; FE; has "10 [x]" "$out" "status not done/pending/N/A"
  grep -vF "$row1" "$base/draft" > $D; FE; has "10 row deleted" "$out" "§2 rows 192/193"
  plant "| renamed item | core.md | pending | |"; FE; has "10 item renamed" "$out" "items differ from PLAN §4"
  plant "|$it1| core.md | done | \`sh tests/greet.test.sh\` → exit 0 |"; echo x >> README.md; FE; is "10 dirty exit" $rc 1; has "10 dirty" "$out" "uncommitted: README.md"; hasnt "10 only dirty" "$out" "§2"
  git checkout -q README.md
  FE; is "10 PASS exit" $rc 0; has "10 PASS" "$out" "PASS: 2/3 tasks (1 skipped), 1 done rows"
  E=.v2p/EXECUTE.md
  is "10 §1 rows" "$(awk '/^## 1\./{f=1;next} /^## /{f=0} f && /^\| [0-9]/' $E | grep -c .)" 3
  has "10 row 3 skipped" "$(grep '^| 3 |' $E)" "skipped — handed to /v2p review"
  has "10 checked" "$(grep '^checked: ' $E)" "checked: tasks 2/3 · skipped 1 · standards done 1 · N/A 0 · pending 192 · branch $main"
  is "10 receipt" "$(cat .v2p/.execute-pass)" "$(sha $E)"; is "10 draft gone" "$(test -f $D && echo yes)" ""
  is "10 records gone" "$(find .v2p/work -name '*execute-task-*' | grep -c .)" 0; is "10 amendments kept" "$(test -f .v2p/PLAN-AMENDMENTS.md && echo yes)" yes
  # 10b. branch mode (review): the union of task scopes + amendments is OK; a stray file is not
  DC --branch .v2p; is "10b branch exit" $rc 0; has "10b branch OK" "$out" "OK: 7 changed paths within the union of PLAN task scopes (1 allowed by amendments)"
  echo x > stray.txt; DC --branch .v2p; is "10b stray exit" $rc 1; has "10b stray" "$out" "DRIFT file stray.txt"; rm stray.txt
  # 11. EXECUTE.md edited after finalize → check-pass refuses
  cp $E "$base/E-$SH"; echo x >> $E; out=$(sh "$S/check-pass.sh" $E .v2p/.execute-pass); has "11 tamper" "$out" "changed after finalize"; cp "$base/E-$SH" $E
  # 13. a curl verifier against a closed localhost port fails fast (no hang); separate copy with a re-sealed PLAN
  f13=$base/f13-$SH; sh "$here/tests/fixture-execute.sh" "$f13" >/dev/null 2>&1; cd "$f13"
  sed "s|^\*\*Verifier:\*\* mechanical: \`sh -c 'grep -c hi src/greet.sh'\` → 1|**Verifier:** mechanical: \`curl -sS -o /dev/null -w '%{http_code}' http://127.0.0.1:9/\` → 200|" .v2p/PLAN.md > "$base/p13" && mv "$base/p13" .v2p/PLAN.md
  shasum -a 256 .v2p/PLAN.md | cut -d' ' -f1 > .v2p/.plan-pass; git add -A; git commit -qm 'plan: curl verifier'
  TR start 2; t0=$(date +%s); TR verify 2; t1=$(date +%s)
  is "13 curl verifier fails" $rc 1; has "13 curl exit" "$(cat .v2p/work/execute-task-2.md)" "verifier: fail · attempts: 1 · exit 7 · \`curl"
  is "13 under 5s" "$([ $((t1 - t0)) -lt 5 ] && echo yes)" yes
  cd "$base"
done
# 12. sh and zsh produce the same EXECUTE.md body (dates, shas and branch-free lines compared)
SH=all; norm() { grep -v '^checked: \|^written: ' "$1" | sed 's/[0-9a-f]\{7\}\.\.[0-9a-f]\{7\}/SHA..SHA/; s/by user · [0-9-]*/by user · DATE/'; }
norm "$base/E-sh" > "$base/n-sh"; norm "$base/E-zsh" > "$base/n-zsh"; is "12 sh = zsh" "$(cmp -s "$base/n-sh" "$base/n-zsh" && echo same)" same
echo "test-execute: $fails failures (scratch: $base)"
[ "$fails" -eq 0 ]
