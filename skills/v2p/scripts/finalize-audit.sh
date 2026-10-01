#!/bin/sh
# Promote .v2p/AUDIT.draft.md to .v2p/AUDIT.md only if §2/§3 row counts match the standards files,
# every `done` has evidence (its `cmd` → expected pairs re-run here), every `N/A` cites BRIEF, merges landed, and §4 is
# tidy-check.sh's own output.
# Usage: sh finalize-audit.sh [.v2p dir]
skill=$(cd "$(dirname "$0")/.." && pwd -P); d=${1:-.v2p}; draft="$d/AUDIT.draft.md"; out="$d/AUDIT.md"; brief="$d/BRIEF.md"; fail=0
[ -f "$draft" ] || { echo "FAIL: $draft missing"; exit 1; }
[ -f "$brief" ] || { echo "FAIL: $brief missing"; exit 1; }
root=$(cd "$d/.." && pwd -P); tmp=${TMPDIR:-/tmp}/fa.$$; trap 'rm -f "$tmp" "$tmp.d" "$tmp.c" "$tmp.run"' EXIT
awk '/^## 11/{f=1;next} /^## /{f=0} f && NF {print; exit}' "$brief" | grep -qE '^none( *←.*)?$' || { echo "FAIL: BRIEF §11 is not 'none'"; fail=1; }
# work/ checkpoints are a resume aid, not proof: requiring them made agents write them after the fact.
grep -q '^checked: ' "$draft" || { echo "FAIL: draft has no 'checked:' line to stamp"; fail=1; }

# expected §2 rows = checklist items of the standards files named in BRIEF §9
expected=0
awk '/^## 9/{f=1;next} /^## /{f=0} f' "$brief" | grep -oE '[a-z-]+\.md' | sort -u > "$tmp"
while IFS= read -r n; do sf="$skill/references/standards/$n"; [ -f "$sf" ] && expected=$((expected + $(grep -c '^- \[ \]' "$sf"))); done < "$tmp"
[ "$expected" -gt 0 ] || { echo "FAIL: BRIEF §9 names no standards file"; fail=1; }
modexp=$(awk '/^## Modularity/{f=1;next} /^## /{f=0} f' "$skill/references/standards/core.md" | grep -c '^- \[ \]')

rows() { awk -v h="$1" 'index($0,h)==1{f=1;next} /^## /{f=0} f && /^\| / && !/^\| item/ && !/^\|---/' "$draft"; }
# $1 rows, $2 status field number: statuses exactly done/pending/N/A/not adopted/gap; done needs evidence; N/A cites
# BRIEF § (status or evidence cell: `N/A — BRIEF §n`); not adopted (owner decision) and gap (known, not built) cite an
# existing repo path, in the status or evidence, after `—` or `-`
check() { printf '%s\n' "$1" | awk -F'|' -v s="$2" 'NF {st=$s; gsub(/^ +| +$/,"",st); ev=$(s+1)
  if (st=="done" && ev !~ /→|\/|https?:\/\//) print "done without evidence: " substr($0,1,100)
  else if (st ~ /^N\/A/) { if (index(st ev,"BRIEF §")==0) print "N/A without BRIEF §: " substr($0,1,100) }
  else if (st ~ /^not adopted( |$)/) { r=st; sub(/^not adopted *((—|-) *)?/,"",r); print "ref\t" (r=="" ? ev : r) "\tnot adopted cites no existing path: " substr($0,1,100) }
  else if (st ~ /^gap( |$)/) { r=st; sub(/^gap *((—|-) *)?/,"",r); print "ref\t" (r=="" ? ev : r) "\tgap cites no existing path: " substr($0,1,100) }
  else if (st!="done" && st!="pending") print "status not done/pending/N/A/not adopted/gap: " substr($0,1,100) }' | sh "$skill/scripts/check-refs.sh" "$root"; }
r2=$(rows '## 2.'); rows2=$(printf '%s\n' "$r2" | grep -c .)
[ "$rows2" -eq "$expected" ] || { echo "FAIL: §2 rows $rows2/$expected"; fail=1; }
bad=$(check "$r2" 4); [ -z "$bad" ] || { echo "FAIL: §2"; printf '%s\n' "$bad"; fail=1; }
# §2 done evidence runs here (field test V2: slash-literal `rg` patterns "→ 0" proved nothing). Same strict parser and
# comparison as task-record.sh: exit 0, and a bare-number expected equals the last output line; run in the repo root.
# An evidence with → where no pair ran is "not verified". Lint: with no →/URL a done evidence is a path, and a path word
# holding a quote, pipe, backslash, ^ or $ is a pattern (`[`/`(` stay: `[locale]`, `(group)` are real path parts).
# Absence (→ 0 or `! …`) without `control:` in the cell is only a WARN.
# trust boundary: the draft is unsealed, written by this session (adopt Step 4) and gitignored (`.v2p/*.draft.md`); its
# writer can already run commands. A draft tracked by git came from the repo instead, so nothing from it runs.
vt=0; vp=0
if git -C "$d" ls-files --error-unmatch AUDIT.draft.md >/dev/null 2>&1; then echo "FAIL: $draft is tracked by git (it came from the repo, not this session): its evidence commands are not run"; fail=1
else printf '%s\n' "$r2" | awk -F'|' '{st=$4; gsub(/^ +| +$/,"",st); if (st!="done") next; it=$2; gsub(/^ +| +$/,"",it)
  ev=""; for (i=5;i<NF;i++) ev=ev (i>5?"|":"") $i; print it "\t" ev}' > "$tmp.d"
while IFS='	' read -r it ev; do
  printf '%s\n' "$ev" | grep -oE '`[^`]+` *→ *`?[^`,;|]*' > "$tmp.c"; ran=0; abs=0
  while IFS= read -r m; do
    c=$(printf '%s\n' "$m" | sed 's/^`\([^`]*\)`.*/\1/'); x=$(printf '%s\n' "$m" | sed 's/^`[^`]*` *→ *//; s/`//g; s/ *$//')
    printf '%s\n' "$c" | sed "s/'[^']*'//g; s/\"[^\"]*\"//g" | grep -qE '<[A-Za-z][A-Za-z0-9_-]*>' && continue
    vt=$((vt + 1)); ran=1; case $c in '!'*) abs=1 ;; esac; [ "$x" = 0 ] && abs=1
    (cd "$root" && sh -c "$c") > "$tmp.run" 2>&1 < /dev/null; r=$?; last=$(grep . "$tmp.run" | tail -n 1)
    if [ "$r" -ne 0 ]; then echo "FAIL: §2 $it: \`$c\` exit $r"; fail=1
    else case $x in ''|*[!0-9]*) vp=$((vp + 1)) ;; *) if [ "$last" = "$x" ]; then vp=$((vp + 1)); else echo "FAIL: §2 $it: \`$c\` → $last (expected $x)"; fail=1; fi ;; esac; fi
  done < "$tmp.c"
  case $ev in
    *→*) [ "$ran" -eq 1 ] || { echo "FAIL: §2 $it: done evidence has → but no backticked \`command\` → expected pair; nothing ran (not verified)"; fail=1; }
      [ "$abs" -eq 0 ] || case $ev in *control:*) ;; *) echo "WARN: §2 $it: absence claim (→ 0 or \`! …\`) with no positive control (add · control: \`cmd\` → n)" ;; esac ;;
    *http://*|*https://*) ;;
    *) w=$(printf '%s\n' "$ev" | tr -d '`' | tr ' ' '\n' | grep '/' | grep "[|\\^\$'\"]" | head -n 1)
      [ -z "$w" ] || { echo "FAIL: §2 $it: done evidence '$w' has a quote, pipe or regex character: a pattern, not a path (write \`command\` → expected)"; fail=1; } ;;
  esac
done < "$tmp.d"; fi
r3=$(rows '## 3.'); rows3=$(printf '%s\n' "$r3" | grep -c .)
[ "$rows3" -eq "$modexp" ] || { echo "FAIL: §3 rows $rows3/$modexp"; fail=1; }
bad=$(check "$r3" 3); [ -z "$bad" ] || { echo "FAIL: §3"; printf '%s\n' "$bad"; fail=1; }

# §4: quarantine line + tidy output produced here, never typed
qline=$(grep -E '^quarantine: ' "$draft")
if [ "$(grep -c '^quarantine: ' "$draft")" -ne 1 ] || ! printf '%s\n' "$qline" | grep -qE '^quarantine: (declined|~?/.*/MANIFEST\.tsv)$'; then
  echo "FAIL: §4 needs exactly one 'quarantine: declined|<path>/MANIFEST.tsv' line"; fail=1
else
  qp=${qline#quarantine: }; case $qp in "~/"*) qp="$HOME/${qp#??}" ;; esac
  [ "$qp" = declined ] || [ -f "$qp" ] || { echo "FAIL: $qp not found"; fail=1; }
fi
tidy=$(sh "$skill/scripts/tidy-check.sh" "$root" 2>&1); v=$(printf '%s\n' "$tidy" | sed -n 's/^tidy: \([0-9]*\) violations/\1/p')
[ -n "$v" ] || { echo "FAIL: tidy-check.sh gave no count"; fail=1; }

# §5: every merged source is named in its destination
rows '## 5.' | awk -F'|' 'NF {s=$2; t=$3; gsub(/^ +| +$/,"",s); gsub(/^ +| +$/,"",t); if (s!="source" && s!="none" && s!="") print s "\t" t}' > "$tmp"
while IFS='	' read -r s t; do (cd "$root" && grep -qF "From $s" "$t" 2>/dev/null) || { echo "FAIL: §5 $t has no 'From $s' section"; fail=1; }; done < "$tmp"

[ "$fail" -eq 0 ] || { echo "FAIL: $out not written"; exit 1; }
printf '%s\n%s\n' "$tidy" "$qline" > "$tmp"
awk -v t="$tmp" -v c="checked: $rows2/$expected standards · evidence runs $vp/$vt · $rows3 modularity · tidy $v violations · $qline" '
  /^checked: /{print c; next}
  /^## 4\./{print; print ""; while ((getline l < t) > 0) print l; print ""; skip=1; next}
  /^## 5\./{skip=0}
  !skip' "$draft" > "$out" && rm "$draft"
# Receipt: mapping accepts AUDIT.md only if its hash matches this file.
shasum -a 256 "$out" | cut -d" " -f1 > "$d/.audit-pass"
rm -f "$d"/work/adopt-*
echo "PASS: $rows2/$expected standards, evidence runs $vp/$vt, $rows3 modularity, tidy $v -> $out"
