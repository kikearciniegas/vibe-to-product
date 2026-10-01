#!/bin/sh
# Promote .v2p/EXECUTE.draft.md to .v2p/EXECUTE.md only if PLAN still matches its receipt, every PLAN task has a
# sealed record from task-record.sh (pass, skipped with a reason, or deferred with the missing credential; manual and
# ponytail-review lines where due),
# all records share the current branch, HEAD is the newest recorded head (later commits may touch only .v2p/), the tree
# is clean outside .v2p/, and §2 has the same items as PLAN §4 with
# valid statuses. §1 is generated here from the records, never typed. Usage: sh finalize-execute.sh [.v2p dir]
skill=$(cd "$(dirname "$0")/.." && pwd -P); d=${1:-.v2p}; fail=0
[ -d "$d" ] || { echo "FAIL: $d not found"; exit 1; }
d=$(cd "$d" && pwd -P); root=$(dirname "$d"); cd "$root" || exit 1
draft=$d/EXECUTE.draft.md; out=$d/EXECUTE.md; plan=$d/PLAN.md; tmp=${TMPDIR:-/tmp}/fe.$$; trap 'rm -f "$tmp.t" "$tmp.p" "$tmp.e" "$tmp.pi" "$tmp.ei" "$tmp.s1"' EXIT
sh "$skill/scripts/check-pass.sh" "$plan" "$d/.plan-pass" >/dev/null || { echo "FAIL: PLAN.md does not match its receipt"; exit 1; }
if [ -f "$draft" ]; then grep -q '^checked: ' "$draft" || { echo "FAIL: draft has no 'checked:' line to stamp"; fail=1; }
else echo "FAIL: $draft missing"; fail=1; fi
planpass=$(cat "$d/.plan-pass"); now=$(git rev-parse --abbrev-ref HEAD)
tline() { awk -v n="$1" -v k="$2" '$0 ~ "^### Task "n":" {f=1;next} f && /^### / {exit} f && index($0, "**" k ":**")==1 {print; exit}' "$plan"; }
# 3. one sealed, current record per PLAN task
grep -o '^### Task [0-9]*' "$plan" | awk '{print $3}' > "$tmp.t"; total=$(grep -c . "$tmp.t"); done_n=0; skipped=0; deferred=0
while IFS= read -r n; do
  r=$d/work/execute-task-$n.md; p=$d/work/.execute-task-$n-pass
  [ -f "$r" ] || { echo "FAIL: task $n: no record"; fail=1; continue; }
  [ -f "$p" ] && [ "$(shasum -a 256 "$r" | cut -d' ' -f1)" = "$(cat "$p")" ] || { echo "FAIL: task $n: record changed outside task-record.sh"; fail=1; continue; }
  [ "$(sed -n 's/.* · plan: //p' "$r" | head -n 1)" = "$planpass" ] || { echo "FAIL: task $n: stale record (other PLAN)"; fail=1; continue; }
  b=$(sed -n 's/^branch: \([^ ]*\) .*/\1/p' "$r"); [ "$b" = "$now" ] || { echo "FAIL: task $n: branch $b, HEAD is on $now"; fail=1; }
  v=$(grep '^verifier: ' "$r")
  case $v in
    'verifier: pass'*) done_n=$((done_n + 1))
      man=$(tline "$n" Verifier | sed -n 's/.*manual: *//p' | sed 's/ *$//')
      if { [ -n "$man" ] && [ "$man" != none ]; } || printf '%s\n' "$v" | grep -q 'skipped: placeholder'; then
        grep -q '^manual: ' "$r" || { echo "FAIL: task $n: Verifier has a manual part and the record has no 'manual:' line"; fail=1; }; fi
      grep -q '^ponytail-review: ' "$r" || { echo "FAIL: task $n: no 'ponytail-review:' line"; fail=1; } ;;
    'verifier: skipped — '?*) skipped=$((skipped + 1)) ;;
    'verifier: deferred — '?*) deferred=$((deferred + 1)) ;;
    *) echo "FAIL: task $n: ${v:-no verifier line} (needs pass, skipped with a reason, or deferred with a credential)"; fail=1 ;;
  esac
done < "$tmp.t"
# 5. clean tree outside .v2p/ (porcelain paths are repo-relative; strip this project's prefix)
pre=$(git rev-parse --show-prefix)
dirty=$(git status --porcelain --untracked-files=all -- . | grep -v "^.. ${pre}\.v2p/" | cut -c4- | tr '\n' ' ')
[ -z "$dirty" ] || { echo "FAIL: uncommitted: ${dirty% }"; fail=1; }
# 6. base..head
first=$(head -n 1 "$tmp.t"); base=$(sed -n 's/.* · base: \([^ ]*\) .*/\1/p' "$d/work/execute-task-$first.md" 2>/dev/null); head=$(git rev-parse HEAD)
[ -n "$base" ] && git merge-base --is-ancestor "$base" HEAD 2>/dev/null || { echo "FAIL: task $first base '${base}' is not an ancestor of HEAD"; fail=1; }
# 6b. HEAD is the newest recorded head (only task-record.sh verify writes head:, after drift-check; ponytail/skip/defer
# never do): a commit after the last verify was never checked. A later commit touching only
# .v2p/ passes, as step 5 ignores .v2p/ (with merges the newest is either side: fails closed)
nh=
while IFS= read -r n; do h=$(sed -n 's/^head: //p' "$d/work/execute-task-$n.md" 2>/dev/null); [ -n "$h" ] || continue
  git merge-base --is-ancestor "$h" HEAD 2>/dev/null || { echo "FAIL: task $n head $h is not an ancestor of HEAD (reset or rebased after verify?)"; fail=1; continue; }
  if [ -z "$nh" ] || git merge-base --is-ancestor "$nh" "$h"; then nh=$h; fi
done < "$tmp.t"
if [ -n "$nh" ]; then late=$(git diff --name-only --relative "$nh" HEAD -- . | grep -v '^\.v2p/' | tr '\n' ' ')
  [ -z "$late" ] || { echo "FAIL: commits after the newest recorded head $nh touch ${late% } (re-run task-record.sh verify <n> for the task they belong to)"; fail=1; }; fi
# 7. §2 = PLAN §4 items; statuses done/pending/N/A/not adopted/gap (cells split from the left: item | file | status | evidence…)
rows() { awk -v h="$1" 'index($0,h)==1{f=1;next} /^## /{f=0} f && /^\| / && !/^\| item/ && !/^\|---/' "$2"; }
items() { awk -F'|' '{s=$2; gsub(/^ +| +$/,"",s); print s}' | sort; }
[ -f "$draft" ] || { echo "FAIL: EXECUTE.md not written"; exit 1; }
rows '## 4.' "$plan" > "$tmp.p"; rows '## 2.' "$draft" > "$tmp.e"; np=$(grep -c . "$tmp.p"); ne=$(grep -c . "$tmp.e")
[ "$ne" -eq "$np" ] || { echo "FAIL: §2 rows $ne/$np (must equal PLAN §4)"; fail=1; }
items < "$tmp.p" > "$tmp.pi"; items < "$tmp.e" > "$tmp.ei"; diff_items=$(comm -3 "$tmp.pi" "$tmp.ei")
[ -z "$diff_items" ] || { echo "FAIL: §2 items differ from PLAN §4 (<TAB> = only in draft):"; printf '%s\n' "$diff_items" | head -n 10; fail=1; }
bad=$(awk -F'|' '{st=$4; gsub(/^ +| +$/,"",st); ev=""; for (i=5;i<NF;i++) ev=ev (i>5?"|":"") $i; gsub(/^ +| +$/,"",ev)
  if (st=="done") { if (ev !~ /→|\/|https?:\/\//) print "done without evidence: " substr($0,1,100) }
  else if (st ~ /^N\/A/) { if (index(st ev,"BRIEF §")==0) print "N/A without BRIEF §: " substr($0,1,100) }
  else if (st ~ /^not adopted( |$)/) { r=st; sub(/^not adopted *((—|-) *)?/,"",r); print "ref\t" (r=="" ? ev : r) "\tnot adopted cites no existing path: " substr($0,1,100) }
  else if (st ~ /^gap( |$)/) { r=st; sub(/^gap *((—|-) *)?/,"",r); print "ref\t" (r=="" ? ev : r) "\tgap cites no existing path: " substr($0,1,100) }
  else if (st!="pending") print "status not done/pending/N/A/not adopted/gap: " substr($0,1,100) }' "$tmp.e" | sh "$skill/scripts/check-refs.sh" "$root")
[ -z "$bad" ] || { echo "FAIL: §2"; printf '%s\n' "$bad"; fail=1; }
[ "$fail" -eq 0 ] || { echo "FAIL: EXECUTE.md not written"; exit 1; }
# 9. §1 from the records
cell() { sed 's/|/\\|/g'; }
{ echo '| task | base..head | drift | verifier | manual | ponytail-review |'; echo '|---|---|---|---|---|---|'
while IFS= read -r n; do r=$d/work/execute-task-$n.md
  b=$(sed -n 's/.* · base: \([^ ]*\) .*/\1/p' "$r" | cut -c1-7); h=$(sed -n 's/^head: //p' "$r" | cut -c1-7)
  dr=$(sed -n 's/^drift: //p' "$r"); v=$(sed -n 's/^verifier: //p' "$r" | cell)
  m=$(sed -n 's/^manual: //p' "$r" | cell); pt=$(sed -n 's/^ponytail-review: //p' "$r" | cell)
  printf '| %s | %s..%s | %s | %s | %s | %s |\n' "$n" "$b" "${h:-$b}" "${dr:-—}" "$v" "${m:-—}" "${pt:-—}"
done < "$tmp.t"; } > "$tmp.s1"
sd=$(awk -F'|' '{s=$4; gsub(/^ +| +$/,"",s); if (s=="done") n++} END {print n+0}' "$tmp.e")
sa=$(awk -F'|' '{s=$4; gsub(/^ +| +$/,"",s); if (s ~ /^N\/A/) n++} END {print n+0}' "$tmp.e")
sp=$(awk -F'|' '{s=$4; gsub(/^ +| +$/,"",s); if (s=="pending") n++} END {print n+0}' "$tmp.e")
sx=$(awk -F'|' '{s=$4; gsub(/^ +| +$/,"",s); if (s ~ /^not adopted( |$)/) n++} END {print n+0}' "$tmp.e")
sg=$(awk -F'|' '{s=$4; gsub(/^ +| +$/,"",s); if (s ~ /^gap( |$)/) n++} END {print n+0}' "$tmp.e")
c="checked: tasks $done_n/$total · skipped $skipped · standards done $sd · N/A $sa · not adopted $sx · gap $sg · pending $sp · branch $now · base $base · head $head"
awk -v t="$tmp.s1" -v c="$c" '
  /^checked: /{print c; next}
  /^## 1\./{print; print ""; while ((getline l < t) > 0) print l; print ""; skip=1; next}
  /^## 2\./{skip=0}
  !skip' "$draft" > "$out" && rm "$draft"
# Receipt: review accepts EXECUTE.md only if its hash matches this file.
shasum -a 256 "$out" | cut -d' ' -f1 > "$d/.execute-pass"
find "$d/work" \( -name 'execute-task-*' -o -name '.execute-task-*' \) -exec rm -f {} +
dfr=; [ "$deferred" -eq 0 ] || dfr=", $deferred deferred"
echo "PASS: $done_n/$total tasks ($skipped skipped$dfr), $sd done rows -> $out"
