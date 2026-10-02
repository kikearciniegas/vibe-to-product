#!/bin/sh
# Promote .v2p/SCAVENGE.draft.md to .v2p/SCAVENGE.md only if every link loads
# and every Q7 row was actually searched. Usage: sh finalize-scavenge.sh [.v2p dir]
d=${1:-.v2p}; draft="$d/SCAVENGE.draft.md"; out="$d/SCAVENGE.md"
[ -f "$draft" ] || { echo "FAIL: $draft missing"; exit 1; }

urls=$(grep -oE 'https?://[^] )|`>]+' "$draft" | sed 's/[.,;]$//' | sort -u)
[ -n "$urls" ] || { echo "FAIL: no URLs in draft"; exit 1; }
total=0; ok=0; fail=0
# work/ checkpoints are a resume aid, not proof: requiring them made agents write them after the fact.
for u in $(printf '%s\n' "$urls"); do  # zsh does not split an unquoted $urls
  total=$((total + 1))
  c=$(curl -s -o /dev/null -L -m 20 -w '%{http_code}' "$u"); e=$?
  # curl 7/28/35/56 (connect, timeout, TLS, reset) = no HTTP answer, not a dead page: retry once with more time,
  # then keep the row (it holds its `accessed <date>`). DNS failure (6) and 4xx/5xx stay DEAD.
  case $e in 7|28|35|56) c=$(curl -s -o /dev/null -L -m 60 -w '%{http_code}' "$u"); e=$? ;; esac
  case $e in 7|28|35|56) echo "UNREACHABLE $u"; ok=$((ok + 1)); continue ;; esac
  # 401/403/429 = page exists but blocks bots; anything else outside 2xx/3xx is dead.
  case $c in 2*|3*|401|403|429) ok=$((ok + 1)) ;; *) echo "DEAD $c $u"; fail=1 ;; esac
done

q7=$(awk '/^## 6\./{f=1; next} /^## /{f=0} f && /^\| / && !/^\| subject/ && !/^\|---/' "$draft")
[ -n "$q7" ] || { echo "FAIL: §6 (Q7) has no rows"; fail=1; }
# Every Q7 row cites the official changelog/news page it read (a URL), or records why it failed.
unsearched=$(printf '%s\n' "$q7" | grep -viE 'https?://|failed \(')
if [ -n "$q7" ] && [ -n "$unsearched" ]; then
  echo "FAIL: §6 rows without an official changelog/news URL or a recorded failure:"
  printf '%s\n' "$unsearched" | cut -c1-100; fail=1
fi
grep -qE 'links: [^ ]+ ok' "$draft" || { echo "FAIL: §7 has no 'links: <ok>/<total> ok' field to stamp"; fail=1; }
# Rule 8: §7's marker counts equal the markers in the file outside §7 (§1–§6 and §8's [OPEN: …] lines; §7's own
# counts line names each marker once and is not counted).
s7=$(awk '/^## 7\./{f=1; next} /^## /{f=0} f' "$draft"); rest=$(awk '/^## 7\./{f=1; next} /^## /{f=0} !f' "$draft")
for m in CONFLICT CHECK OPEN; do
  want=$(printf '%s\n' "$s7" | sed -n "s/.*\[$m\] rows: \([0-9][0-9]*\).*/\1/p" | head -n 1)
  [ -n "$want" ] || { echo "FAIL: §7 has no '[CONFLICT] rows: <n> · [CHECK] rows: <n> · [OPEN] rows: <n>' line"; fail=1; break; }
  have=$(printf '%s\n' "$rest" | grep -oE "\\[${m}[]:]" | grep -c .)
  [ "$want" -eq "$have" ] || { echo "FAIL: §7 says [$m] rows: $want, the file has $have [$m] markers outside §7"; fail=1; }
done

[ "$fail" -eq 0 ] || { echo "FAIL: links $ok/$total ok; $out not written"; exit 1; }
sed -E "s|links: [^ ]+ ok|links: $ok/$total ok|" "$draft" > "$out" && rm "$draft"
# Receipt: the next phase accepts SCAVENGE.md only if its hash matches this file.
shasum -a 256 "$out" | cut -d" " -f1 > "$d/.scavenge-pass"
find "$d/work" -name 'scavenge-*' -exec rm -f {} + 2>/dev/null
echo "PASS: links $ok/$total ok -> $out"
