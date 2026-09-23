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
if printf '%s\n' "$q7" | grep -qi 'not searched'; then
  echo "FAIL: §6 has 'not searched' rows; run the last-30-days search for every subject"; fail=1
fi

[ "$fail" -eq 0 ] || { echo "FAIL: links $ok/$total ok; $out not written"; exit 1; }
sed "s|links: [^ ]* ok|links: $ok/$total ok|" "$draft" > "$out" && rm "$draft"
echo "PASS: links $ok/$total ok -> $out"
