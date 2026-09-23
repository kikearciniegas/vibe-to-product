#!/bin/sh
# Promote .v2p/SCAVENGE.draft.md to .v2p/SCAVENGE.md only if every link loads
# and every Q7 row was actually searched. Usage: sh finalize-scavenge.sh [.v2p dir]
d=${1:-.v2p}; draft="$d/SCAVENGE.draft.md"; out="$d/SCAVENGE.md"
[ -f "$draft" ] || { echo "FAIL: $draft missing"; exit 1; }

urls=$(grep -oE 'https?://[^ )|`>]+' "$draft" | sed 's/[.,;]$//' | sort -u)
[ -n "$urls" ] || { echo "FAIL: no URLs in draft"; exit 1; }
total=0; ok=0; fail=0
for u in $urls; do
  total=$((total + 1))
  c=$(curl -s -o /dev/null -L -m 20 -w '%{http_code}' "$u")
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

[ "$fail" -eq 0 ] || { echo "FAIL: links $ok/$total ok; $out not written"; exit 1; }
sed -E "s|links: [^ ]+ ok|links: $ok/$total ok|" "$draft" > "$out" && rm "$draft"
echo "PASS: links $ok/$total ok -> $out"
