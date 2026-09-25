#!/bin/sh
# Regression for build-portable.sh: the claude-only marker regex must anchor to whole lines, not match
# mid-line prose (e.g. SKILL.md's "Blocks between `<!-- claude-only -->` markers apply..." line), which
# would otherwise open a false skip block and drop SKILL.md's §2 Entry heading and Model guard line.
# Writes only under ${TMPDIR:-/tmp}/v2p-test.<pid>. Usage: sh tests/test-build.sh (exit 0 = all PASS)
here=$(cd "$(dirname "$0")/.." && pwd -P)
base=$(cd "${TMPDIR:-/tmp}" && pwd -P)/v2p-test.$$; mkdir -p "$base"
out="$base/v2p-portable.md"
fails=0
has() { case $2 in *"$3"*) echo "PASS $1" ;; *) echo "FAIL $1: missing '$3'"; fails=$((fails+1)) ;; esac; }
lacks() { case $2 in *"$3"*) echo "FAIL $1: found unwanted '$3'"; fails=$((fails+1)) ;; *) echo "PASS $1" ;; esac; }

sh "$here/build-portable.sh" "$out" >/dev/null

content=$(cat "$out")
has "1 has Entry heading" "$content" "## 2. Entry"
has "1 has Model guard" "$content" "**Model guard:**"
lacks "2 no AskUserQuestion" "$content" "AskUserQuestion"
lacks "2 no subagent_type" "$content" "subagent_type"
lacks "2 no task-record.sh" "$content" "task-record.sh"

for f in $(grep -rl 'claude-only' "$here/skills/v2p"); do
  o=$(grep -c '^<!-- claude-only -->$' "$f")
  c=$(grep -c '^<!-- /claude-only -->$' "$f")
  is="$o=$c"
  if [ "$o" = "$c" ]; then echo "PASS 3 marker balance $f ($is)"; else echo "FAIL 3 marker balance $f: open=$o close=$c"; fails=$((fails+1)); fi
done

echo "$fails failed"
[ "$fails" = 0 ]
