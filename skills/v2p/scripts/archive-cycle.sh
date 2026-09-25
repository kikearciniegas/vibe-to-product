#!/bin/sh
# Re-theme (or any post-review iteration): move the finished cycle's PLAN, EXECUTE, REVIEW, DEPLOY, PLAN-AMENDMENTS and their
# receipts into .v2p/cycles/<date>/ (the hashes still verify there), so mapping can write a short cycle-2 PLAN and
# nothing is ever edited under a hash lock. Runs only after the new DESIGN.md passed finalize-brand.sh, so a failed
# brand run leaves the finished cycle intact. Never touches BRIEF, SCAVENGE, AUDIT or DESIGN.
# Usage: sh archive-cycle.sh [.v2p dir]   (exit 0 archived · 1 refused)
skill=$(cd "$(dirname "$0")/.." && pwd -P); d=${1:-.v2p}
[ -d "$d" ] || { echo "FAIL: $d not found"; exit 1; }
d=$(cd "$d" && pwd -P); root=$(dirname "$d"); cd "$root" || exit 1
sh "$skill/scripts/check-pass.sh" "$d/REVIEW.md" "$d/.review-pass" >/dev/null || { echo "FAIL: REVIEW.md does not match its receipt (only a reviewed cycle is archived)"; exit 1; }
sh "$skill/scripts/check-pass.sh" "$d/DESIGN.md" "$d/.brand-pass" >/dev/null || { echo "FAIL: DESIGN.md does not match its receipt (run /v2p brand first: archive only after the new DESIGN.md passes)"; exit 1; }
# a placeholder carries no new tokens (live run: it re-recorded the shipped ones and opened an empty cycle 2) —
# the reviewed cycle stays current until the real guide arrives
if sed -n '2,/^---$/p' "$d/DESIGN.md" | grep -q '^description: *"\{0,1\}PLACEHOLDER'; then
  echo "kept: DESIGN.md is a placeholder, so the reviewed cycle stays current; re-run /v2p brand when the guide arrives; Next: /v2p deploy"; exit 0; fi
dest=$d/cycles/$(date +%Y-%m-%d)
[ -e "$dest" ] && { echo "FAIL: ${dest#"$root"/} exists (one archive per day)"; exit 1; }
mkdir -p "$dest"; k=0
for f in PLAN.md EXECUTE.md REVIEW.md DEPLOY.md PLAN-AMENDMENTS.md .plan-pass .execute-pass .review-pass .deploy-pass; do
  [ -e "$d/$f" ] || continue
  if git ls-files --error-unmatch "$d/$f" >/dev/null 2>&1; then git mv "$d/$f" "$dest/$f"; else mv "$d/$f" "$dest/$f"; fi || { echo "FAIL: could not move $f"; exit 1; }
  k=$((k + 1))
done
echo "archived: ${dest#"$root"/} ($k files); Next: /v2p mapping (cycle 2)"
