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
  # 7. ponytail shape; commit first, then verify against the committed head (execute.md Step 2 order)
  s0=$(sha $rec1); TR ponytail 1 junk; is "7 junk exit" $rc 2; is "7 unchanged" "$(sha $rec1)" "$s0"
  git add -A; git commit -qm 'feat: greeting script'
  TR verify 1; is "7 verify on committed head" $rc 0; has "7 verify head = commit" "$(cat $rec1)" "head: $(git rev-parse HEAD)"
  has "7 verify drift" "$(cat $rec1)" "drift: allowed 1"
  TR ponytail 1 none; is "7 none exit" $rc 0; has "7 line" "$(cat $rec1)" "ponytail-review: none"; has "7 head = task commit" "$(cat $rec1)" "head: $(git rev-parse HEAD)"
  # 7b. a record written by the previous task-record.sh (old ponytail format), re-sealed as that version did
  sed 's/^ponytail-review: none$/ponytail-review: 2 findings, 1 cut, 1 accepted: old-format line from an earlier run/' $rec1 > "$base/r1" && mv "$base/r1" $rec1
  sha $rec1 > .v2p/work/.execute-task-1-pass
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
  s0=$(sha .v2p/work/execute-task-2.md)
  TR ponytail 2 "1 findings, 1 cut, 0 accepted: dropped an unused helper"; is "9 old format refused" $rc 2
  has "9 old format msg shows new" "$out" "<k> findings, <a> applied, <d> deferred, <r> rejected: <one line>"
  TR ponytail 2 "3 findings, 1 applied, 1 deferred, 0 rejected: sum is short"; is "9 a+d+r != k refused" $rc 2; has "9 sum msg" "$out" "1 applied + 1 deferred + 0 rejected != 3 findings"
  TR ponytail 2 "1 findings, 1 applied, 0 deferred, 0 rejected:"; is "9 empty summary refused" $rc 2
  is "9 record unchanged by refusals" "$(sha .v2p/work/execute-task-2.md)" "$s0"
  TR ponytail 2 "3 findings, 1 applied, 1 deferred, 1 rejected: dropped an unused helper; inlined config later (Task 5); kept retry"; is "9 ponytail" $rc 0
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
  has "10 old-format ponytail kept" "$(grep '^| 1 |' $E)" "2 findings, 1 cut, 1 accepted: old-format line"
  has "10 new-format ponytail kept" "$(grep '^| 2 |' $E)" "3 findings, 1 applied, 1 deferred, 1 rejected:"
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
  # 14. drift-check refuses a pattern with shell-unsafe characters instead of eval'ing it (fail closed).
  # Planted straight into PLAN-AMENDMENTS.md so the test covers the matcher itself, not just the `allow` gate
  # in front of it. Falsifier checked by hand against the pre-fix script: same payload → exit 0 and a PWNED file.
  f14=$base/f14-$SH; sh "$here/tests/fixture-execute.sh" "$f14" >/dev/null 2>&1; cd "$f14"
  TR start 1; rm -f PWNED
  printf -- '- 2026-09-24T00:00:00 · task 1 · files += `*) ;; esac; touch PWNED; case 1 in 1` · malicious\n' >> .v2p/PLAN-AMENDMENTS.md
  DC 1; is "14 injection blocked exit" $rc 1; has "14 injection blocked msg" "$out" "DRIFT pattern"; is "14 no PWNED via drift-check" "$(test -f PWNED && echo yes)" ""
  TR verify 1; is "14 verify blocked exit" $rc 1; is "14 no PWNED via verify" "$(test -f PWNED && echo yes)" ""
  cd "$base"
  # 15. task-record allow refuses an absolute path, a `..` segment or an unsafe character before any write
  f15=$base/f15-$SH; sh "$here/tests/fixture-execute.sh" "$f15" >/dev/null 2>&1; cd "$f15"
  TR start 1
  TR allow 1 '../secret' r; is "15 traversal exit" $rc 2; has "15 traversal msg" "$out" "ERROR: unsafe path"
  TR allow 1 '/etc/passwd' r; is "15 absolute exit" $rc 2; has "15 absolute msg" "$out" "ERROR: unsafe path"
  TR allow 1 'a;b' r; is "15 unsafe char exit" $rc 2; has "15 unsafe char msg" "$out" "ERROR: unsafe path"
  is "15 amendments untouched" "$(test -f .v2p/PLAN-AMENDMENTS.md && echo yes)" ""
  TR allow 1 docs/note.md "reviewer asked"; is "15 legit path still allowed" $rc 0
  cd "$base"
  # 16. task-record's <n> check (already `case $n in ''|*[!0-9]*)`) applies ahead of every subcommand's file writes
  f16=$base/f16-$SH; sh "$here/tests/fixture-execute.sh" "$f16" >/dev/null 2>&1; cd "$f16"
  TR verify '../../x'; is "16 verify bad n exit" $rc 2
  TR start '1a'; is "16 start bad n exit" $rc 2
  is "16 no work dir writes" "$(find .v2p/work -type f 2>/dev/null | grep -c .)" 0
  cd "$base"
  # 17. verify runs against the committed head: an out-of-scope file that was already committed still blocks it
  f17=$base/f17-$SH; sh "$here/tests/fixture-execute.sh" "$f17" >/dev/null 2>&1; cd "$f17"
  TR start 1; echo x > stray.txt; git add stray.txt; git commit -qm 'stray'
  TR verify 1; is "17 committed stray exit" $rc 1; has "17 committed stray" "$(cat .v2p/work/execute-task-1.md)" "DRIFT file stray.txt"
  cd "$base"
  # 18. brace shorthand in Files (live PLAN Tasks 4/5 wrote `src/components/{Hero,Proof,...}.tsx`) expands to one
  # pattern per alternative, one or more groups per token; nested/unclosed braces and unsafe alternatives fail closed.
  f18=$base/f18-$SH; sh "$here/tests/fixture-execute.sh" "$f18" >/dev/null 2>&1; cd "$f18"
  sed 's|^\*\*Files:\*\* Modify: `src/\*\.sh`, `app/\[locale\]/page\.tsx`$|**Files:** Create `src/components/{Hero,Proof}.tsx`, `{a,b}/{x,y}.ts`|' .v2p/PLAN.md > "$base/p18" && mv "$base/p18" .v2p/PLAN.md
  shasum -a 256 .v2p/PLAN.md | cut -d' ' -f1 > .v2p/.plan-pass; git add -A; git commit -qm 'plan: brace Files'
  TR start 2; mkdir -p src/components a b; for p in src/components/Hero.tsx src/components/Proof.tsx a/x.ts b/y.ts; do echo x > $p; done
  DC 2; is "18 braces in scope exit" $rc 0; has "18 braces in scope" "$out" "OK: 4 changed paths within Task 2 scope"
  echo x > src/components/Other.tsx; DC 2; is "18 Other.tsx exit" $rc 1; has "18 Other.tsx drift" "$out" "DRIFT file src/components/Other.tsx"
  hasnt "18 Hero.tsx still in scope" "$out" "DRIFT file src/components/Hero.tsx"; rm src/components/Other.tsx
  echo x > a/z.ts; DC 2; is "18 two groups a/z.ts exit" $rc 1; has "18 two groups a/z.ts drift" "$out" "DRIFT file a/z.ts"; rm a/z.ts
  printf -- '- 2026-09-24T00:00:00 · task 2 · files += `src/{a,{b,c}}.ts` · nested\n' > .v2p/PLAN-AMENDMENTS.md
  DC 2; is "18 nested exit" $rc 1; has "18 nested msg" "$out" "DRIFT pattern src/{a,{b,c}}.ts (nested braces)"
  printf -- '- 2026-09-24T00:00:00 · task 2 · files += `src/{a,b.ts` · unclosed\n' > .v2p/PLAN-AMENDMENTS.md
  DC 2; is "18 unclosed exit" $rc 1; has "18 unclosed msg" "$out" "DRIFT pattern src/{a,b.ts (unclosed brace)"
  rm -f PWNED; printf -- '- 2026-09-24T00:00:00 · task 2 · files += `{x,$(touch PWNED)}` · malicious\n' > .v2p/PLAN-AMENDMENTS.md
  DC 2; is "18 brace injection exit" $rc 1; has "18 brace injection msg" "$out" "(unsafe characters)"; is "18 no PWNED" "$(test -f PWNED && echo yes)" ""
  cd "$base"
  # 19. start --base: audited re-start when `start` ran late (live run: base = the task's own commit). b0 = true base,
  # c1 = an out-of-scope commit before the late start, so the base in force decides whether outside.txt drifts.
  f19=$base/f19-$SH; sh "$here/tests/fixture-execute.sh" "$f19" >/dev/null 2>&1; cd "$f19"; A=.v2p/PLAN-AMENDMENTS.md; P1=.v2p/work/.execute-task-1-pass
  b0=$(git rev-parse HEAD); echo x > outside.txt; git add -A; git commit -qm 'outside'; c1=$(git rev-parse HEAD)
  TR start 1; mkdir -p tests; printf 'echo hi\n' > src/greet.sh; printf '[ "$(sh src/greet.sh)" = hi ]\n' > tests/greet.test.sh
  git add -A; git commit -qm 'feat: greeting script'; TR verify 1; is "19 late-start verify" $rc 0; TR ponytail 1 none
  s0=$(sha $rec1); orphan=$(git commit-tree "HEAD^{tree}" -m orphan)
  TR start 1 --base "$orphan" "why"; is "19 non-ancestor exit" $rc 2; has "19 non-ancestor msg" "$out" "is not an ancestor of HEAD"
  TR start 1 --base deadbeef "why"; is "19 nonexistent exit" $rc 2; has "19 nonexistent msg" "$out" "does not resolve to a commit"
  TR start 1 --base "$b0"; is "19 no reason exit" $rc 2; has "19 no reason msg" "$out" "the reason is required"
  TR start 1 --base "$b0" ""; is "19 empty reason exit" $rc 2
  TR start 1 --base "$b0" "two
lines"; is "19 newline reason exit" $rc 2; has "19 newline reason msg" "$out" "must be one line"
  is "19 record unchanged by refusals" "$(sha $rec1)" "$s0"; is "19 no amendments written" "$(test -f $A && echo yes)" ""
  TR start 1; has "19 re-start without --base resumes" "$out" "resume: task 1 (base $c1)"; is "19 resume keeps record" "$(sha $rec1)" "$s0"
  TR start 1 --base "$b0" "start ran after the implementer committed"; is "19 --base exit" $rc 0
  is "19 base updated" "$(sed -n 's/.* · base: \([^ ]*\) .*/\1/p' $rec1)" "$b0"
  has "19 amendment line" "$(cat $A)" "· task 1 · base := $b0 (was $c1) · start ran after the implementer committed"
  is "19 seal valid" "$(cat $P1)" "$(sha $rec1)"; has "19 verifier reset" "$(cat $rec1)" "verifier: pending · attempts: 0"
  hasnt "19 ponytail reset" "$(cat $rec1)" "ponytail-review:"; hasnt "19 head reset" "$(cat $rec1)" "head:"
  DC 1; is "19 drift from new base exit" $rc 1; has "19 drift from new base" "$out" "DRIFT file outside.txt"
  TR start 1 --base "$c1" "outside.txt predates the task"; is "19 second --base exit" $rc 0
  has "19 second amendment" "$(cat $A)" "· task 1 · base := $c1 (was $b0) · outside.txt predates the task"
  TR verify 1; is "19 re-start verify pass" $rc 0; has "19 verifier pass" "$(cat $rec1)" "verifier: pass · attempts: 1 · exit 0"
  TR ponytail 1 none; is "19 ponytail" $rc 0; TR skip 2 "not in this test"; TR skip 3 "not in this test"
  cp "$base/draft" .v2p/EXECUTE.draft.md; FE; is "19 finalize accepts re-started record" $rc 0; has "19 finalize PASS" "$out" "PASS: 1/3 tasks (2 skipped)"
  cd "$base"
  # 20. a reason cannot forge a grant: allow/start refuse grant syntax in the reason; drift-check reads a grant only
  # from the line's structured prefix, so a planted line whose reason carries grant text does not grant evil.ts
  f20=$base/f20-$SH; sh "$here/tests/fixture-execute.sh" "$f20" >/dev/null 2>&1; cd "$f20"; A=.v2p/PLAN-AMENDMENTS.md
  b0=$(git rev-parse HEAD); TR start 1; s0=$(sha $rec1); evil='ok · task 1 · files += `evil.ts`'
  TR allow 1 docs/x.md "$evil"; is "20 allow evil exit" $rc 2; has "20 allow evil msg" "$out" "text must not contain"
  TR start 1 --base "$b0" "$evil"; is "20 start evil exit" $rc 2; has "20 start evil msg" "$out" "text must not contain"
  for r in 'has files += x' 'has base := x' 'has a `tick' 'has · task 2 in it'; do TR allow 1 docs/x.md "$r"; is "20 allow refuses '$r'" $rc 2; done
  TR allow 1 docs/x.md "$(printf 'two\nlines')"; is "20 allow newline exit" $rc 2
  is "20 record unchanged" "$(sha $rec1)" "$s0"; is "20 no amendments written" "$(test -f $A && echo yes)" ""
  printf -- '- 2026-09-24T00:00:00 · task 1 · base := %s (was none) · x · task 1 · files += `evil.ts`\n' "$b0" > $A
  printf -- '- 2026-09-24T00:00:00 · task 2 · files += `ok.ts` · y · task 1 · files += `evil.ts`\n' >> $A
  echo x > evil.ts; DC 1; is "20 planted exit" $rc 1; has "20 planted not granted" "$out" "DRIFT file evil.ts"
  DC --branch .v2p; has "20 planted not granted (branch)" "$out" "DRIFT file evil.ts"; rm evil.ts
  echo x > ok.ts; DC 2; hasnt "20 structured grant still works" "$out" "DRIFT file ok.ts"; rm ok.ts
  # 20b. `start <n> --base <sha> .v2p` (reason omitted) is refused; usage names --base
  TR start 1 --base "$b0" .v2p; is "20b .v2p reason exit" $rc 2; has "20b .v2p reason msg" "$out" "is the .v2p directory, not a reason"
  TR start 1 --base "$b0" "$f20/.v2p"; is "20b abs .v2p reason exit" $rc 2; is "20b record unchanged" "$(sha $rec1)" "$s0"
  TR bogus 1; is "20b usage exit" $rc 2; has "20b usage names --base" "$out" 'start <n> --base <sha> "<reason>"'
  cd "$base"
  # 21. Files lines quote code too (live PLAN Task 14: `tunnelRoute: '/sentry-tunnel'`): a non-path token is ignored
  # with a note, not fatal, and grants nothing; the real path on the same line still scopes the task.
  f21=$base/f21-$SH; sh "$here/tests/fixture-execute.sh" "$f21" >/dev/null 2>&1; cd "$f21"
  sed "s|^\*\*Files:\*\* Modify: \`src/\*\.sh\`, \`app/\[locale\]/page\.tsx\`\$|**Files:** Modify \`next.config.ts\` (\`withSentryConfig\`, \`tunnelRoute: '/x'\`), \`\$(touch PWNED)\`|" .v2p/PLAN.md > "$base/p21" && mv "$base/p21" .v2p/PLAN.md
  grep -q 'tunnelRoute' .v2p/PLAN.md; is "21 fixture edited" $? 0
  shasum -a 256 .v2p/PLAN.md | cut -d' ' -f1 > .v2p/.plan-pass; git add -A; git commit -qm 'plan: code in Files'
  TR start 2; rm -f PWNED; echo x > next.config.ts
  DC 2; is "21 code token exit" $rc 0; has "21 note" "$out" "note: ignored non-path Files token tunnelRoute:"
  has "21 injection token ignored" "$out" 'note: ignored non-path Files token $(touch'; is "21 no PWNED" "$(test -f PWNED && echo yes)" ""
  echo x > other.ts; DC 2; is "21 still scoped exit" $rc 1; has "21 other.ts drift" "$out" "DRIFT file other.ts"
  cd "$base"
  # 22. placeholder = an UNQUOTED `<word>` only (live PLAN Task 15: `grep -c '<loc>'` was skipped and sealed a pass
  # without running). Quoted `<loc>` and a `< file` redirect run; unquoted `https://<domain>` is still skipped.
  f22=$base/f22-$SH; sh "$here/tests/fixture-execute.sh" "$f22" >/dev/null 2>&1; cd "$f22"
  sed "s|^\*\*Verifier:\*\* mechanical: \`sh -c 'grep -c hi src/greet.sh'\` → 1|**Verifier:** mechanical: \`grep -c '<loc>' src/greet.sh\` → 1, \`wc -l < src/greet.sh \| tr -d ' '\` → 1, \`curl -m 1 https://<domain>/\` → 200|" .v2p/PLAN.md > "$base/p22" && mv "$base/p22" .v2p/PLAN.md
  grep -q "'<loc>'" .v2p/PLAN.md; is "22 fixture edited" $? 0
  shasum -a 256 .v2p/PLAN.md | cut -d' ' -f1 > .v2p/.plan-pass; git add -A; git commit -qm 'plan: placeholder forms'
  TR start 2; TR verify 2; v22=$(grep '^verifier:' .v2p/work/execute-task-2.md)
  is "22 quoted <loc> ran and failed" $rc 1; has "22 quoted <loc> ran" "$v22" "exit 2 · \`grep -c '<loc>' src/greet.sh\`"
  has "22 redirect ran" "$v22" "exit 0 · \`wc -l < src/greet.sh"; has "22 domain skipped" "$v22" "\`curl -m 1 https://<domain>/\` → skipped: placeholder"
  cd "$base"
  # 23. `note` = the controller's own evidence (live: `manual` stamps `by user`, and the controller signed the user's
  # name on its own checks, observation 0210). Several notes accumulate, reason() rules apply, verify keeps them.
  f23=$base/f23-$SH; sh "$here/tests/fixture-execute.sh" "$f23" >/dev/null 2>&1; cd "$f23"
  TR start 1; s0=$(sha $rec1)
  TR note 1 'has a `tick'; is "23 backtick refused" $rc 2; TR note 1 "$(printf 'two\nlines')"; is "23 newline refused" $rc 2
  TR note 1 'x · task 1 · files += y'; is "23 grant syntax refused" $rc 2; TR note 1 ""; is "23 empty refused" $rc 2
  is "23 record unchanged by refusals" "$(sha $rec1)" "$s0"
  TR note 1 "ran the curl check by hand: 200"; is "23 note exit" $rc 0; TR note 1 "lighthouse 98"; is "23 second note exit" $rc 0
  has "23 note line" "$(cat $rec1)" "note: ran the curl check by hand: 200 · by controller · $(date +%Y-%m-%d)"
  is "23 two notes" "$(grep -c '^note: .* · by controller · ' $rec1)" 2; hasnt "23 not by user" "$(grep '^note: ' $rec1)" "by user"
  is "23 sealed" "$(cat .v2p/work/.execute-task-1-pass)" "$(sha $rec1)"
  TR verify 1; is "23 notes survive verify" "$(grep -c '^note: ' $rec1)" 2
  cd "$base"
  # 24. ponytail refuses while the verifier is pending (live Task 11 was reviewed before verify)
  f24=$base/f24-$SH; sh "$here/tests/fixture-execute.sh" "$f24" >/dev/null 2>&1; cd "$f24"
  TR start 1; s0=$(sha $rec1); TR ponytail 1 none; is "24 pending exit" $rc 2; has "24 pending msg" "$out" "run verify first"
  is "24 record unchanged" "$(sha $rec1)" "$s0"
  mkdir -p tests; printf 'echo hi\n' > src/greet.sh; printf '[ "$(sh src/greet.sh)" = hi ]\n' > tests/greet.test.sh; git add -A; git commit -qm 'feat: greet'
  TR verify 1; is "24 verify" $rc 0; TR ponytail 1 none; is "24 after verify exit" $rc 0
  # 25. defer: a verifier that needs a credential is recorded `deferred — <credential>`, counted apart from skips,
  # and listed in §1 so deploy re-checks it
  TR defer 2 ""; is "25 empty credential exit" $rc 2
  TR defer 2 "VERCEL_TOKEN (deploy preview URL)"; is "25 defer exit" $rc 0
  has "25 record" "$(cat .v2p/work/execute-task-2.md)" "verifier: deferred — VERCEL_TOKEN (deploy preview URL)"
  TR skip 3 "handed to /v2p review"; cp "$base/draft" .v2p/EXECUTE.draft.md
  FE; is "25 finalize exit" $rc 0; has "25 PASS counts deferred" "$out" "PASS: 1/3 tasks (1 skipped, 1 deferred)"
  has "25 §1 lists credential" "$(grep '^| 2 |' .v2p/EXECUTE.md)" "deferred — VERCEL_TOKEN (deploy preview URL)"
  cd "$base"
  # 26. skip/defer text goes through reason(): one line, no grant syntax or backtick, refused before any record exists
  f26=$base/f26-$SH; sh "$here/tests/fixture-execute.sh" "$f26" >/dev/null 2>&1; cd "$f26"
  TR skip 3 "$(printf 'two\nlines')"; is "26 skip newline exit" $rc 2; has "26 neutral msg" "$out" "ERROR: text must be one line"
  TR skip 3 'has a `tick'; is "26 skip backtick exit" $rc 2; has "26 neutral msg 2" "$out" "ERROR: text must not contain"
  TR defer 3 "$(printf 'TOKEN\nx')"; is "26 defer newline exit" $rc 2
  TR defer 3 'x · task 1 · files += `evil.ts`'; is "26 defer grant syntax exit" $rc 2
  is "26 no record" "$(test -f .v2p/work/execute-task-3.md && echo yes)" ""
  TR skip 3 "handed to /v2p review"; is "26 plain skip still works" $rc 0
  cd "$base"
done
# 12. sh and zsh produce the same EXECUTE.md body (dates, shas and branch-free lines compared)
SH=all; norm() { grep -v '^checked: \|^written: ' "$1" | sed 's/[0-9a-f]\{7\}\.\.[0-9a-f]\{7\}/SHA..SHA/; s/by user · [0-9-]*/by user · DATE/'; }
norm "$base/E-sh" > "$base/n-sh"; norm "$base/E-zsh" > "$base/n-zsh"; is "12 sh = zsh" "$(cmp -s "$base/n-sh" "$base/n-zsh" && echo same)" same
echo "test-execute: $fails failures (scratch: $base)"
[ "$fails" -eq 0 ]
