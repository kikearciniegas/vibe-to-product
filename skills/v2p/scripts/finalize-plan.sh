#!/bin/sh
# Promote .v2p/PLAN.draft.md to .v2p/PLAN.md only if every task has a Verifier line and §4 has one row
# per checklist item of the BRIEF §9 standards files. Usage: sh finalize-plan.sh [.v2p dir]
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
[ "$fail" -eq 0 ] || { echo "FAIL: $out not written"; exit 1; }
mv "$draft" "$out"
# Receipt: execute accepts PLAN.md only if its hash matches this file.
shasum -a 256 "$out" | cut -d" " -f1 > "$d/.plan-pass"
rm -f "$d"/work/mapping-*
echo "PASS: $tasks tasks, $rows standards rows -> $out"
