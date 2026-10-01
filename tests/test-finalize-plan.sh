#!/bin/sh
# finalize-plan.sh against a COPY of a bad plan (BRIEF.md + PLAN.md), under sh and zsh: every new check
# must FAIL on the original, then each FAIL must disappear as the copy is fixed one step at a time, ending in PASS.
# Source: $V2P_FP_SRC (default: tests/fixtures/finalize-plan, a synthetic landing plan). The source files are only
# read, never written. A '{{STANDARDS_ROWS}}' line in PLAN.md is replaced by one §4 row per '- [ ]' item of the
# BRIEF §9 standards files, so the fixture follows the live standards.
# Writes only under ${TMPDIR:-/tmp}/v2p-fp-test.<pid>. Usage: sh tests/test-finalize-plan.sh   (exit 0 = all PASS)
here=$(cd "$(dirname "$0")/.." && pwd -P); F=$here/skills/v2p/scripts/finalize-plan.sh
src=${V2P_FP_SRC:-$here/tests/fixtures/finalize-plan}
[ -f "$src/BRIEF.md" ] && [ -f "$src/PLAN.md" ] || { echo "ERROR: $src/{BRIEF,PLAN}.md missing; test did not run"; exit 2; }
sum0=$(cat "$src/BRIEF.md" "$src/PLAN.md" | shasum -a 256)
base=$(cd "${TMPDIR:-/tmp}" && pwd -P)/v2p-fp-test.$$; mkdir -p "$base"
# §4 rows from the BRIEF §9 standards files; nrows is counted from the standards, not from the plan
awk '/^## 9/{f=1;next} /^## /{f=0} f' "$src/BRIEF.md" | grep -oE '[a-z-]+\.md' | sort -u | while IFS= read -r n; do
  sf=$here/skills/v2p/references/standards/$n; [ -f "$sf" ] && sed -n "s/^- \[ \] \(.*\)/| \1 | $n | pending | |/p" "$sf"
done > "$base/rows"; nrows=$(grep -c . "$base/rows")
fails=0
is() { if [ "$2" = "$3" ]; then echo "PASS [$SH] $1"; else echo "FAIL [$SH] $1: got '$2' want '$3'"; fails=$((fails+1)); fi; }
has() { case $2 in *"$3"*) echo "PASS [$SH] $1" ;; *) echo "FAIL [$SH] $1: missing '$3'"; fails=$((fails+1)) ;; esac; }
hasnt() { case $2 in *"$3"*) echo "FAIL [$SH] $1: still has '$3'"; fails=$((fails+1)) ;; *) echo "PASS [$SH] $1" ;; esac; }
# ins <heading-regex> <text>: insert text before the first line matching the regex
ins() { RE=$1 T=$2 awk '!done && $0 ~ ENVIRON["RE"] { print ENVIRON["T"]; done = 1 } { print }' "$P" > "$P.new" && mv "$P.new" "$P"; }
run() { out=$($SH "$F" "$v" 2>&1); rc=$?; nfail=$(printf '%s\n' "$out" | grep -c '^FAIL: [^$]' ); }
M_TOT="§2 has no 'Total monthly at launch"; M_BUD="FAIL: budget:"; M_HR="FAIL: '---' rule"
M_4B="no '## 4b' section"; M_AR="no '## Architecture' section"; M_TM="no '## Threat Model' section"; M_MM="'## Architecture' has no"
for SH in sh zsh; do
  w=$base/$SH; v=$w/.v2p; P=$v/PLAN.draft.md; mkdir -p "$v"
  cp "$src/BRIEF.md" "$v/BRIEF.md"
  R=$base/rows awk '$0 == "{{STANDARDS_ROWS}}" { while ((getline l < ENVIRON["R"]) > 0) print l; next } { print }' "$src/PLAN.md" > "$P"
  ntasks=$(grep -c '^### Task' "$P"); hr0=$(grep -n '^---$' "$P" | cut -d: -f1 | tr '\n' ' ')
  # 0. the original bad plan fails every new check and writes nothing
  run; is "0 exit" $rc 1
  for m in "$M_TOT" "$M_HR" "$M_4B" "$M_AR" "$M_TM"; do has "0 $m" "$out" "$m"; done
  has "0 hr lines" "$out" "lines $hr0"; is "0 no PLAN.md" "$(test -f "$v/PLAN.md" && echo yes)" ""
  n0=$nfail
  # 1. the plan's own launch cost (hosting $20 + Sentry $29) → total present, over the $25 budget
  ins '^## 3\.' 'Total monthly at launch: $49 (20 + 29)'
  run; hasnt "1 total line found" "$out" "$M_TOT"; has "1 budget over" "$out" "total \$49 > BRIEF Budget/month \$25"
  # 2. user override clears the budget failure
  ins '^## 3\.' 'Over budget approved by user: Sentry Team needed for tracing'
  run; hasnt "2 override" "$out" "$M_BUD"
  # 3. no override, total within budget (free tiers)
  grep -v '^Over budget approved by user:' "$P" | sed 's/^Total monthly at launch: \$49 (20 + 29)$/Total monthly at launch: $0/' > "$P.new" && mv "$P.new" "$P"
  run; hasnt "3 within budget" "$out" "$M_BUD"; is "3 one fewer FAIL" $((n0 - nfail)) 1
  # 4. budget parsing edge cases (BRIEF variants; restored afterwards)
  cp "$v/BRIEF.md" "$w/BRIEF.keep"; sed 's/^Total monthly at launch: \$0$/Total monthly at launch: $20/' "$P" > "$P.new" && mv "$P.new" "$P"
  sed 's/Budget\/month: \$25/Budget\/month: 0/' "$w/BRIEF.keep" > "$v/BRIEF.md"; run; has "4 budget 0 vs \$20" "$out" "total \$20 > BRIEF Budget/month \$0"
  cp "$w/BRIEF.keep" "$v/BRIEF.md"; run; hasnt "4 budget \$25 vs \$20" "$out" "$M_BUD"
  sed 's/Budget\/month: \$25/Budget\/month: none/' "$w/BRIEF.keep" > "$v/BRIEF.md"; run; has "4 budget none" "$out" "WARN: BRIEF Budget/month missing"; hasnt "4 none no FAIL" "$out" "$M_BUD"
  sed 's/ · Budget\/month: \$25[^·]*//' "$w/BRIEF.keep" > "$v/BRIEF.md"; run; has "4 budget missing" "$out" "WARN: BRIEF Budget/month missing"
  cp "$w/BRIEF.keep" "$v/BRIEF.md"; sed 's/^Total monthly at launch: \$20$/Total monthly at launch: $0/' "$P" > "$P.new" && mv "$P.new" "$P"
  # 5. --- rules → ***
  sed 's/^---$/***/' "$P" > "$P.new" && mv "$P.new" "$P"
  run; hasnt "5 no ---" "$out" "$M_HR"; is "5 one fewer FAIL" $((n0 - nfail)) 2
  # 6. landing §4b (a table row inside it must not disturb the §4 count)
  ins '^## 5\.' '## 4b. Landing sections
| section | kept / omitted | check |
|---|---|---|
| 1. Hero | kept | landing-10-sections.md §1 |'
  run; hasnt "6 4b" "$out" "$M_4B"; hasnt "6 §4 rows intact" "$out" "§4 rows"
  # 6b. falsifier: a non-landing BRIEF never asks for §4b
  sed 's/^- Profile: landing/- Profile: saas-web/' "$w/BRIEF.keep" > "$v/BRIEF.md"; grep -v '^## 4b' "$P" > "$w/no4b"
  cp "$P" "$w/keep4b"; cp "$w/no4b" "$P"; run; hasnt "6b saas-web no 4b" "$out" "$M_4B"
  cp "$w/keep4b" "$P"; cp "$w/BRIEF.keep" "$v/BRIEF.md"
  # 7. Architecture
  ins '^## 2\.' '## Architecture
Browser → static site → booking form handler → email provider.'
  run; hasnt "7 architecture" "$out" "$M_AR"; has "7 prose only → no diagram" "$out" "$M_MM"
  # 7b. a Mermaid block inside the section satisfies the gate
  ins '^Browser → static site' '```mermaid
flowchart LR
  U[Browser] --> S[static site]
```'
  run; hasnt "7b mermaid" "$out" "$M_MM"; is "7b one FAIL left" $nfail 2
  # 8. Threat Model → PASS
  ins '^## 2\.' '## Threat Model
Assets: contact data. Entry points: booking form. Abuse cases: spam, …'
  run; is "8 exit" $rc 0; has "8 PASS" "$out" "PASS: $ntasks tasks, $nrows standards rows, total \$0/month"
  is "8 draft gone" "$(test -f "$P" && echo yes)" ""
  is "8 receipt" "$(cat "$v/.plan-pass")" "$(shasum -a 256 "$v/PLAN.md" | cut -d' ' -f1)"
  # 10. Verifier lint and Files completeness: each case replaces one line of the passing plan (always the original)
  cp "$v/PLAN.md" "$w/good"; V2='**Verifier:** mechanical: `npm test -- tests/booking.test.ts` → all passed'
  rep() { A=$1 B=$2 C=${3-} D=${4-} awk '$0 == ENVIRON["A"] { print ENVIRON["B"]; next }
    ENVIRON["C"] != "" && $0 == ENVIRON["C"] { print ENVIRON["D"]; next } { print }' "$w/good" > "$P"; run; }
  V1='**Verifier:** mechanical: `npm run build` → exit 0'
  vf() { rep "$V2" "**Verifier:** mechanical: \`$1\` → exit 0"; }
  vf 'test "$(grep -r lorem src | wc -l)" = 0'; is "10 wc exit" $rc 1; has "10 wc" "$out" "FAIL: Task 2 Verifier: raw wc -l"
  vf 'test "$(grep -r lorem src | wc -l | tr -d '"' '"')" = 0'; is "10 wc|tr passes" $rc 0
  vf '! grep -rqE lorem src && test "$(grep -c x a.txt)" -ge 1'; is "10 grep -c passes" $rc 0
  vf 'npm run build && npm run start & sleep 5; curl -m 5 -s localhost:3000'; has "10 bare &" "$out" "FAIL: Task 2 Verifier: bare & backgrounds"
  rep "$V2" '**Verifier:** manual: run `npm run start & sleep 5` and look at the page'; hasnt "10 & in manual ignored" "$out" "bare &"
  vf 'npm run build 2>&1 && npm test >/dev/null 2>&1'; is "10 && and 2>&1 pass" $rc 0
  vf "curl -s http://localhost:3000 | grep -q ok"; has "10 curl no -m" "$out" "FAIL: Task 2 Verifier: curl without -m/--max-time"
  vf "curl -m 5 -s http://a/ && curl -s http://b/"; has "10 second curl no -m" "$out" "curl without -m"
  vf "curl -sm 5 http://a/ | grep -q ok && curl --max-time 5 -s http://b/"; is "10 -sm and --max-time pass" $rc 0
  # 10c. a backtick inside a Verifier command (live Task 19 `grep -c '^| \`src/'`: the parser cut it and ran a fragment)
  vf "grep -c '^| \`src/' docs/x.md"; is "10c inner backtick exit" $rc 1; has "10c inner backtick" "$out" "FAIL: Task 2 Verifier: a Verifier command cannot contain a backtick"
  rep "$V2" '**Verifier:** mechanical: `grep -c a f` → 1, `echo ok` → `ok`, `test -f "x"` → exit 0   |   manual: open `/` → see it'; is "10c several commands pass" $rc 0
  # the manual part's `/` → see it above is prose, never a command: execute, review and deploy extract the mechanical part only
  rep "$V2" '**Verifier:** mechanical: npm test → exit 0   |   manual: open `/` → see it'; is "10c manual pair is not a command exit" $rc 1
  has "10c manual pair is not a command" "$out" "FAIL: Task 2 Verifier: mechanical with no backticked"
  rep "$V2" '**Verifier:** mechanical: `grep -c a f` → 1, `grep -c '"'"'`b'"'"' f` → 2'; has "10c second command backtick" "$out" "cannot contain a backtick"
  rep "$V2" '**Verifier:** manual: read `@x/y` usage, open `/es/gracias`. Sub-check: `npm run e2e` → exit 0'; is "10c prose pairs before the command pass (live Task 7)" $rc 0
  # 10e. a mechanical Verifier with no backticked `command` → expected pair (field test V0: 14 of 14 unbackticked, every
  # record read pass with nothing run) is refused; a manual Verifier without backticks still passes
  rep "$V2" '**Verifier:** mechanical: grep -qE foo bun.lock; echo $? → 0'; is "10e unbackticked exit" $rc 1
  has "10e unbackticked" "$out" "FAIL: Task 2 Verifier: mechanical with no backticked"
  rep "$V2" '**Verifier:** mechanical: npm test → exit 0   |   manual: open `/es` and look'; has "10e manual backticks do not count" "$out" "FAIL: Task 2 Verifier: mechanical with no backticked"
  rep "$V2" '**Verifier:** manual: the reviewer reads the branch diff'; is "10e manual without backticks passes" $rc 0
  # 10h. the other Verifier lints read backticks from the mechanical part only, as 10e does (a `cmd` in the manual part
  # is prose for a person, never run); each FAIL control puts the same command in the mechanical part
  M1='**Verifier:** mechanical: `npm test` → exit 0   |   manual: check `test "$(ls out | wc -l)" = 3` by hand'
  rep "$V2" "$M1"; is "10h wc -l in manual exit" $rc 0; hasnt "10h wc -l in manual" "$out" "raw wc -l"
  rep "$V2" '**Verifier:** mechanical: `test "$(ls out | wc -l)" = 3` → exit 0   |   manual: open `/` and look'; has "10h wc -l in mechanical" "$out" "FAIL: Task 2 Verifier: raw wc -l"
  rep "$V2" '**Verifier:** manual: fetch `curl http://x/` and read it; then mechanical: `npm test` → exit 0'; is "10h curl in manual-first exit" $rc 0; hasnt "10h curl in manual" "$out" "curl without -m"
  rep "$V2" '**Verifier:** mechanical: `curl -s http://x/ | grep -q ok` → exit 0   |   manual: open `/` and look'; has "10h curl in mechanical" "$out" "curl without -m"
  rep "$V2" '**Verifier:** manual: curl the preview and read the headers'; is "10h unbackticked manual-only exit" $rc 0
  rep "$V2" '**Verifier:** mechanical: `npm test` → exit 0   |   manual: run `npm start & open http://x/` and look'; is "10h & in manual exit" $rc 0; hasnt "10h & in manual" "$out" "bare &"
  rep "$V2" '**Verifier:** mechanical: `npm start & sleep 5` → exit 0   |   manual: open `/` and look'; has "10h & in mechanical" "$out" "bare & backgrounds"
  rep "$V2" '**Verifier:** mechanical: `grep -q book src/booking.ts` → exit 0   |   manual: run `npm run dev` and book a slot
**Files:** Create `src/booking.ts`'; has "10h runner word in manual does not count" "$out" "WARN: Task 2 Verifier: Files has code"
  # 10i. manual-first Verifier (`manual: …; then mechanical: …`): mechanical-ness was read from the line start only, so
  # its mechanical part skipped the no-command and bare-& checks; both now apply to the mechanical part wherever it is
  rep "$V2" '**Verifier:** manual: open `/` and look; then mechanical: npm test → exit 0'; is "10i manual-first no command exit" $rc 1
  has "10i manual-first no command" "$out" "FAIL: Task 2 Verifier: mechanical with no backticked"
  rep "$V2" '**Verifier:** manual: open `/` and look; then mechanical: `npm start & sleep 5` → exit 0'; is "10i manual-first bare & exit" $rc 1
  has "10i manual-first bare &" "$out" "FAIL: Task 2 Verifier: bare & backgrounds"
  rep "$V2" '**Verifier:** manual: open `/` and look; then mechanical: `npm test && npm run build 2>&1` → exit 0'; is "10i manual-first valid pair exit" $rc 0
  # 10f. Files is one line (field test V27: the planner wrote bullet lists under **Files:**, which nothing reads)
  rep "$V1" "$V1
**Files:**   "; is "10f empty Files exit" $rc 1; has "10f empty Files" "$out" "FAIL: Task 1 Files: empty after the label"
  rep "$V2" "$V2
**Files:** Create:
- \`src/booking.ts\`"; is "10f bullet Files exit" $rc 1; has "10f bullet Files" "$out" "FAIL: Task 2 Files: a bullet list under **Files:** is not read"
  rep "$V1" "$V1
**Files:** none" "$V2" "$V2
**Files:** Create \`src/booking.ts\`
- [ ] Step 1: write the form"; is "10f none, one line and a following step pass" $rc 0
  # 10g. a command in a table cell needs `\|` for its pipes, and a copied `\|` is a literal pipe in ERE (field test V30:
  # the copied check silently printed 0): a table row with `\|` inside backticks fails; prose `\|` and fenced blocks pass
  rep "$V2" "$V2

| check | command |
|---|---|
| headers | \`curl -m 5 -sI https://x \\| grep -cE 'hsts\\|csp'\` |"; is "10g escaped pipe in a cell exit" $rc 1
  has "10g escaped pipe in a cell" "$out" "FAIL: line $(grep -n '^| headers |' "$P" | cut -d: -f1): table row has \`\\|\` inside backticks"
  rep "$V2" "$V2

| check | note |
|---|---|
| headers | a \\| b, run \`grep -c x f\` |

\`\`\`sh
curl -m 5 -sI https://x | grep -cE 'hsts|csp'
\`\`\`"; is "10g prose pipe and fenced block pass" $rc 0
  # 10d. a Modify path exists now or is Created by this or an earlier task (live Task 17: bare `globals.css`)
  mf() { rep "$V1" "$V1
**Files:** $1" "$V2" "$V2
**Files:** $2"; }
  mf 'Create `src/app/*`' 'Create `src/x.tsx`; Modify `globals.css`'; is "10d bare globals.css exit" $rc 1
  has "10d bare globals.css" "$out" "FAIL: Task 2 Files: Modify \`globals.css\` is neither in the repo nor in a Create of Tasks 1-2"
  mf 'Create `src/app/*`' 'Modify `src/app/globals.css`, `src/app/[locale]/page.tsx`'; is "10d created by an earlier glob" $rc 0
  mf 'Modify `src/app/page.tsx`' 'Create `src/app/*`'; has "10d later Create does not count" "$out" "FAIL: Task 1 Files: Modify \`src/app/page.tsx\`"
  mf 'Create `src/a.ts`, Modify `src/a.ts`' 'Modify `src/a.ts`'; is "10d same-task Create counts" $rc 0
  mkdir -p "$w/src"; echo x > "$w/src/old.ts"; echo x > "$w/next.config.ts"
  mf 'Modify `src/old.ts`' "Modify \`next.config.ts\` (\`withSentryConfig\`, \`tunnelRoute: '/x'\`), \`src/old.ts\` (\`legal.*\`)"; is "10d existing files, code tokens ignored" $rc 0
  mf 'Modify `lib/*.ts`' 'Modify `src/{old,new}.ts`'; has "10d glob matches nothing" "$out" "Modify \`lib/*.ts\` is neither"
  has "10d brace: missing alternative" "$out" "Modify \`src/new.ts\` is neither"; hasnt "10d brace: existing alternative" "$out" "\`src/old.ts\` is neither"
  mf 'Modify `src/*.ts`' 'Create `src/sections/{Hero,Faq}.tsx`; Modify `src/sections/*.tsx`'; is "10d globs match existing / created paths" $rc 0
  rm -r "$w/src" "$w/next.config.ts"
  rep "$V2" "$V2
**Files:** Create \`src/booking.ts\`  **Interfaces:** Produces \`book()\` in \`src/booking/api.ts\`"
  is "10 files exit" $rc 1; has "10 iface path missing" "$out" "FAIL: Task 2 Interfaces names \`src/booking/api.ts\`, absent from the Files of Tasks 1-2"
  rep "$V2" "$V2
**Files:** Create \`src/{booking,other}/api.ts\`  **Interfaces:** Produces \`book()\` in \`src/booking/api.ts\`, posts to \`https://api.example.com/v1/x.json\` and \`/robots.txt\`"
  is "10 brace + URL + route pass" $rc 0
  rep "$V1" "$V1
**Interfaces:** Consumes \`src/app/[locale]/page.tsx\`" "$V2" "$V2
**Files:** Create \`src/app/*\`"; has "10 later task's Files do not count" "$out" "FAIL: Task 1 Interfaces names"
  rep "$V1" "$V1
**Files:** Create \`src/app/*\`" "$V2" "$V2
**Interfaces:** Consumes \`src/app/[locale]/page.tsx\`"; is "10 earlier task's glob counts" $rc 0
  rep "$V1" "$V1
**Files:** Create \`src/app/[locale]/page.tsx\`" "$V2" "$V2
**Interfaces:** Consumes \`src/app/l/page.tsx\`"; has "10 [locale] is literal, not a class" "$out" "Task 2 Interfaces names \`src/app/l/page.tsx\`"
  # 11. provenance (field test V3: PLAN recorded a Qn as an owner decision nobody made): a `Qn` the PLAN cites
  # must be a label in BRIEF §10's item column; quarters (`Q4 2026`) and SCAVENGE's own Qn are not decision labels
  b10() { R=$1 awk '/^## 11/ { print "## 10. Decisions log"; print "| item | status | value |"; print "|---|---|---|"; print ENVIRON["R"]; print "" } { print }' "$w/BRIEF.keep" > "$v/BRIEF.md"; }
  rep "$V2" "$V2
Decision: Q9 (owner chose 30-minute slots)"; is "11 Q9 without §10 exit" $rc 1; has "11 Q9 without §10" "$out" "FAIL: PLAN cites Q9, not a label in BRIEF §10"
  b10 '| Q2 — who / how often | answered | cyclists, weekly |'
  rep "$V2" "$V2
Decision: Q2 (weekly riders first)"; is "11 Q2 in §10 passes" $rc 0
  rep "$V2" "$V2
Decision: Q2 and Q9 (owner chose 30-minute slots)"; is "11 Q9 not in §10 exit" $rc 1; has "11 Q9 named" "$out" "PLAN cites Q9"; hasnt "11 Q2 not named" "$out" "cites Q2"
  R='| Q2 — who / how often | answered | cyclists, weekly |' awk '/^## 9/ { print "- Note: Q9 was never asked" } { print }' "$v/BRIEF.md" > "$v/BRIEF.new" && mv "$v/BRIEF.new" "$v/BRIEF.md"
  rep "$V2" "$V2
Decision: Q9 (owner chose 30-minute slots)"; has "11 Q9 in BRIEF prose only" "$out" "PLAN cites Q9"
  rep "$V2" "$V2
Launch in Q4 2026; providers per SCAVENGE Q3."; is "11 quarter and SCAVENGE Qn pass" $rc 0
  cp "$w/BRIEF.keep" "$v/BRIEF.md"
  # 12. a code task whose mechanical Verifier only greps/tests files is a WARN, not a FAIL (field test V4: a grep for the
  # renamed identifier passed while the behaviour broke; only the project's own test suite caught it)
  M_V4="WARN: Task 2 Verifier: Files has code"
  rep "$V2" '**Verifier:** mechanical: `grep -q book src/booking.ts` → exit 0
**Files:** Create `src/booking.ts`'; is "12 grep-only code task exit" $rc 0; has "12 grep-only code task warns" "$out" "$M_V4"
  rep "$V2" '**Files:** Create `src/booking.ts`, `docs/booking.md`
**Verifier:** mechanical: `test -f src/booking.ts && grep -c book src/booking.ts` → 1'; has "12 Files first, test -f + grep -c warns" "$out" "$M_V4"
  rep "$V2" "$V2
**Files:** Create \`src/booking.ts\`"; hasnt "12 test suite no warn" "$out" "WARN: Task"
  rep "$V2" '**Verifier:** mechanical: `grep -q book src/booking.ts && sh scripts/smoke.sh` → exit 0
**Files:** Create `src/booking.ts`'; hasnt "12 run command no warn" "$out" "WARN: Task"
  rep "$V2" '**Verifier:** mechanical: `grep -q book docs/booking.md` → exit 0
**Files:** Create `docs/booking.md`'; hasnt "12 docs-only no warn" "$out" "WARN: Task"
  rep "$V2" '**Verifier:** manual: the owner books a slot on the preview
**Files:** Create `src/booking.ts`'; hasnt "12 manual no warn" "$out" "WARN: Task"
  # 13. a regular root DESIGN.md is the project's own design doc (adopt: brand kept it, field test V5): a task whose Files
  # name it is a WARN; a root symlink is v2p's own link, no WARN (control)
  M_V5="WARN: Task 2 Files: \`DESIGN.md\` is the project's own design doc"
  printf '# own\n' > "$w/DESIGN.md"; rep "$V2" "$V2
**Files:** Modify \`DESIGN.md\`"; is "13 own root exit" $rc 0; has "13 own root warns" "$out" "$M_V5"
  rep "$V2" "$V2
**Files:** Create \`docs/x.md\`; Modify \`./DESIGN.md\`"; has "13 ./DESIGN.md warns" "$out" "$M_V5"
  rep "$V2" "$V2
**Files:** Modify \`docs/DESIGN.md\`"; hasnt "13 nested DESIGN.md no warn" "$out" "is the project's own design doc"
  rm "$w/DESIGN.md"; echo x > "$v/DESIGN.md"; ln -s .v2p/DESIGN.md "$w/DESIGN.md"; rep "$V2" "$V2
**Files:** Modify \`DESIGN.md\`"; hasnt "13 symlink root no warn" "$out" "is the project's own design doc"
  rm -f "$w/DESIGN.md" "$v/DESIGN.md"
done
# 9. the source was read only
SH=all; is "9 source untouched" "$(cat "$src/BRIEF.md" "$src/PLAN.md" | shasum -a 256)" "$sum0"
echo "test-finalize-plan: $fails failures (scratch: $base)"
# a passing run leaves nothing behind (180 stale scratch dirs had piled up in $TMPDIR); a failing one keeps it to inspect
[ "$fails" -eq 0 ] && rm -rf "$base"
[ "$fails" -eq 0 ]
