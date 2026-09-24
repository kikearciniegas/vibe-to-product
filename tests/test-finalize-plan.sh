#!/bin/sh
# finalize-plan.sh against a COPY of a real bad plan (BRIEF.md + PLAN.md), under sh and zsh: every new check
# must FAIL on the original, then each FAIL must disappear as the copy is fixed one step at a time, ending in PASS.
# Source: $V2P_FP_SRC (default: the 2026-09-24 Haiku plan). The source files are only read, never written.
# Writes only under ${TMPDIR:-/tmp}/v2p-fp-test.<pid>. Usage: sh tests/test-finalize-plan.sh   (exit 0 = all PASS)
here=$(cd "$(dirname "$0")/.." && pwd -P); F=$here/skills/v2p/scripts/finalize-plan.sh
src=${V2P_FP_SRC:-/Users/user/SynologyDrive/code/ai/claude/Projects/personal_skills/v2p/.v2p}
[ -f "$src/BRIEF.md" ] && [ -f "$src/PLAN.md" ] || { echo "ERROR: $src/{BRIEF,PLAN}.md missing; test did not run"; exit 2; }
sum0=$(cat "$src/BRIEF.md" "$src/PLAN.md" | shasum -a 256)
base=$(cd "${TMPDIR:-/tmp}" && pwd -P)/v2p-fp-test.$$; mkdir -p "$base"
fails=0
is() { if [ "$2" = "$3" ]; then echo "PASS [$SH] $1"; else echo "FAIL [$SH] $1: got '$2' want '$3'"; fails=$((fails+1)); fi; }
has() { case $2 in *"$3"*) echo "PASS [$SH] $1" ;; *) echo "FAIL [$SH] $1: missing '$3'"; fails=$((fails+1)) ;; esac; }
hasnt() { case $2 in *"$3"*) echo "FAIL [$SH] $1: still has '$3'"; fails=$((fails+1)) ;; *) echo "PASS [$SH] $1" ;; esac; }
# ins <heading-regex> <text>: insert text before the first line matching the regex
ins() { RE=$1 T=$2 awk '!done && $0 ~ ENVIRON["RE"] { print ENVIRON["T"]; done = 1 } { print }' "$P" > "$P.new" && mv "$P.new" "$P"; }
run() { out=$($SH "$F" "$v" 2>&1); rc=$?; nfail=$(printf '%s\n' "$out" | grep -c '^FAIL: [^$]' ); }
M_TOT="§2 has no 'Total monthly at launch"; M_BUD="FAIL: budget:"; M_HR="FAIL: '---' rule"
M_4B="no '## 4b' section"; M_AR="no '## Architecture' section"; M_TM="no '## Threat Model' section"
for SH in sh zsh; do
  w=$base/$SH; v=$w/.v2p; P=$v/PLAN.draft.md; mkdir -p "$v"
  cp "$src/BRIEF.md" "$v/BRIEF.md"; cp "$src/PLAN.md" "$P"
  # 0. the original bad plan fails every new check and writes nothing
  run; is "0 exit" $rc 1
  for m in "$M_TOT" "$M_HR" "$M_4B" "$M_AR" "$M_TM"; do has "0 $m" "$out" "$m"; done
  has "0 hr lines" "$out" "lines 32 46 56 "; is "0 no PLAN.md" "$(test -f "$v/PLAN.md" && echo yes)" ""
  n0=$nfail
  # 1. the plan's own launch cost (Vercel Pro $20 + Sentry $29) → total present, over the $25 budget
  ins '^## 3\.' 'Total monthly at launch: $49 (20 + 29)'
  run; hasnt "1 total line found" "$out" "$M_TOT"; has "1 budget over" "$out" "total \$49 > BRIEF Budget/month \$25"
  # 2. user override clears the budget failure
  ins '^## 3\.' 'Over budget approved by user: Sentry Team needed for tracing'
  run; hasnt "2 override" "$out" "$M_BUD"
  # 3. no override, total within budget (Cloudflare Pages $0 + Sentry Developer $0)
  grep -v '^Over budget approved by user:' "$P" | sed 's/^Total monthly at launch: \$49 (20 + 29)$/Total monthly at launch: $0/' > "$P.new" && mv "$P.new" "$P"
  run; hasnt "3 within budget" "$out" "$M_BUD"; is "3 one fewer FAIL" $((n0 - nfail)) 1
  # 4. budget parsing edge cases (BRIEF variants; restored afterwards)
  cp "$v/BRIEF.md" "$w/BRIEF.keep"; sed 's/^Total monthly at launch: \$0$/Total monthly at launch: $20/' "$P" > "$P.new" && mv "$P.new" "$P"
  sed 's/Budget\/month: \$25 max/Budget\/month: 0/' "$w/BRIEF.keep" > "$v/BRIEF.md"; run; has "4 budget 0 vs \$20" "$out" "total \$20 > BRIEF Budget/month \$0"
  sed 's/Budget\/month: \$25 max/Budget\/month: $25/' "$w/BRIEF.keep" > "$v/BRIEF.md"; run; hasnt "4 budget \$25 vs \$20" "$out" "$M_BUD"
  sed 's/Budget\/month: \$25 max/Budget\/month: none/' "$w/BRIEF.keep" > "$v/BRIEF.md"; run; has "4 budget none" "$out" "WARN: BRIEF Budget/month missing"; hasnt "4 none no FAIL" "$out" "$M_BUD"
  sed 's/ · Budget\/month: \$25 max//' "$w/BRIEF.keep" > "$v/BRIEF.md"; run; has "4 budget missing" "$out" "WARN: BRIEF Budget/month missing"
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
Browser → Cloudflare Pages (Next.js) → Resend; Cal.com embed.'
  run; hasnt "7 architecture" "$out" "$M_AR"; is "7 one FAIL left" $nfail 2
  # 8. Threat Model → PASS
  ins '^## 2\.' '## Threat Model
Assets: contact data. Entry points: form, Cal.com embed. Abuse cases: spam, …'
  run; is "8 exit" $rc 0; has "8 PASS" "$out" "PASS: 9 tasks, 193 standards rows, total \$0/month"
  is "8 draft gone" "$(test -f "$P" && echo yes)" ""
  is "8 receipt" "$(cat "$v/.plan-pass")" "$(shasum -a 256 "$v/PLAN.md" | cut -d' ' -f1)"
done
# 9. the source was read only
SH=all; is "9 source untouched" "$(cat "$src/BRIEF.md" "$src/PLAN.md" | shasum -a 256)" "$sum0"
echo "test-finalize-plan: $fails failures (scratch: $base)"
[ "$fails" -eq 0 ]
