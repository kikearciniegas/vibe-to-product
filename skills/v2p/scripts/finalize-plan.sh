#!/bin/sh
# Promote .v2p/PLAN.draft.md to .v2p/PLAN.md only if every task has a Verifier line, §4 has one row
# per checklist item of the BRIEF §9 standards files, §2's total fits the BRIEF budget (or carries the
# user's override), no `---` rule exists, `## Architecture` and `## Threat Model` exist, and a landing
# plan has `## 4b`. Usage: sh finalize-plan.sh [.v2p dir]
skill=$(cd "$(dirname "$0")/.." && pwd -P); d=${1:-.v2p}; draft="$d/PLAN.draft.md"; out="$d/PLAN.md"; fail=0
[ -f "$draft" ] || { echo "FAIL: $draft missing"; exit 1; }
[ -f "$d/BRIEF.md" ] || { echo "FAIL: $d/BRIEF.md missing"; exit 1; }
tasks=$(grep -c '^### Task' "$draft"); ver=$(grep -c '^\*\*Verifier:\*\*' "$draft")
[ "$tasks" -gt 0 ] && [ "$tasks" -eq "$ver" ] || { echo "FAIL: tasks $tasks / verifiers $ver"; fail=1; }
expected=0; tmp=${TMPDIR:-/tmp}/fp.$$; trap 'rm -f "$tmp"' EXIT
awk '/^## 9/{f=1;next} /^## /{f=0} f' "$d/BRIEF.md" | grep -oE '[a-z-]+\.md' | sort -u > "$tmp"
while IFS= read -r n; do sf="$skill/references/standards/$n"; [ -f "$sf" ] && expected=$((expected + $(grep -c '^- \[ \]' "$sf"))); done < "$tmp"
rows=$(awk '/^## 4\./{f=1;next} /^## /{f=0} f && /^\| / && !/^\| item/ && !/^\|---/' "$draft" | grep -c .)
[ "$expected" -gt 0 ] && [ "$rows" -eq "$expected" ] || { echo "FAIL: §4 rows $rows/$expected"; fail=1; }
grep -q '^Next: /v2p execute' "$draft" || { echo "FAIL: no 'Next: /v2p execute' line"; fail=1; }
# Budget: BRIEF "Budget/month: <v>" (first number; none/missing → skip) vs PLAN §2 "Total monthly at launch: $<n>".
num() { sed -n 's/^[^0-9]*\([0-9][0-9,]*\(\.[0-9][0-9]*\)\{0,1\}\).*/\1/p' | tr -d ,; }
budget=$(grep -m1 -o 'Budget/month:[^·]*' "$d/BRIEF.md" | sed 's|^Budget/month:||' | num)
total=$(awk '/^## 2\./{f=1;next} /^## /{f=0} f && /^Total monthly at launch: \$[0-9]/' "$draft" | head -n 1 | num)
if [ -z "$total" ]; then echo "FAIL: §2 has no 'Total monthly at launch: \$<n>' line"; fail=1
elif [ -z "$budget" ]; then echo "WARN: BRIEF Budget/month missing or not a number; budget check skipped"
elif awk -v t="$total" -v b="$budget" 'BEGIN { exit !(t > b) }' &&
  ! grep -qE '^Over budget approved by user: *[^ ]' "$draft"; then
  echo "FAIL: budget: total \$$total > BRIEF Budget/month \$$budget (no 'Over budget approved by user: <reason>' line)"; fail=1
fi
hr=$(grep -n '^---$' "$draft" | cut -d: -f1 | tr '\n' ' ')
[ -z "$hr" ] || { echo "FAIL: '---' rule on lines ${hr% } (use ***)"; fail=1; }
grep -q '^## Architecture' "$draft" || { echo "FAIL: no '## Architecture' section"; fail=1; }
grep -q '^## Threat Model' "$draft" || { echo "FAIL: no '## Threat Model' section"; fail=1; }
if grep -qE '^- Profile: *landing([^a-z-]|$)' "$d/BRIEF.md" && ! grep -q '^## 4b' "$draft"; then
  echo "FAIL: profile landing and no '## 4b' section"; fail=1
fi
[ "$fail" -eq 0 ] || { echo "FAIL: $out not written"; exit 1; }
mv "$draft" "$out"
# Receipt: execute accepts PLAN.md only if its hash matches this file.
shasum -a 256 "$out" | cut -d" " -f1 > "$d/.plan-pass"
rm -f "$d"/work/mapping-*
echo "PASS: $tasks tasks, $rows standards rows, total \$$total/month -> $out"
