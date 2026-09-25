#!/bin/sh
# Promote .v2p/REVIEW.draft.md to .v2p/REVIEW.md only if EXECUTE.md matches its receipt, §1 has every required run,
# §2 accounts for every finding (fix commits exist), §3 completes PLAN §4 (pending only as deferred to deploy),
# the draft covers the current HEAD, the tree is clean on the execute branch, and every mechanical PLAN verifier
# still passes when re-run here (expect minutes). Usage: sh finalize-review.sh [.v2p dir]
skill=$(cd "$(dirname "$0")/.." && pwd -P); d=${1:-.v2p}; fail=0
[ -d "$d" ] || { echo "FAIL: $d not found"; exit 1; }
d=$(cd "$d" && pwd -P); root=$(dirname "$d"); cd "$root" || exit 1
draft=$d/REVIEW.draft.md; out=$d/REVIEW.md; plan=$d/PLAN.md; ex=$d/EXECUTE.md; tmp=${TMPDIR:-/tmp}/fr.$$
trap 'rm -f "$tmp.r" "$tmp.f" "$tmp.s" "$tmp.p" "$tmp.pi" "$tmp.si" "$tmp.t" "$tmp.c" "$tmp.run"' EXIT
sh "$skill/scripts/check-pass.sh" "$ex" "$d/.execute-pass" >/dev/null || { echo "FAIL: EXECUTE.md does not match its receipt (run /v2p execute first)"; exit 1; }
[ -f "$draft" ] || { echo "FAIL: $draft missing"; exit 1; }
grep -q '^checked: ' "$draft" || { echo "FAIL: draft has no 'checked:' line to stamp"; fail=1; }
rows() { awk -v h="$1" 'index($0,h)==1{f=1;next} /^## /{f=0} f && /^\| / && !/^\| (check|item|#) / && !/^\|---/' "$2"; }
trim() { sed 's/^ *//; s/ *$//'; }
# 3. §1 runs: required checks, findings cell "<n> findings" (codex may be "unavailable: <reason>"), run cell non-empty
printf '%s\n' code-review simplify security verification ux-laws codex qa > "$tmp.c"
awk '/^## 9/{f=1;next} /^## /{f=0} f' "$d/BRIEF.md" | grep 'Conditional blocks ON' | grep -q 'i18n' && echo i18n >> "$tmp.c"
rows '## 1.' "$draft" > "$tmp.r"; nreq=0; runs=0; fsum=0
while IFS= read -r c; do nreq=$((nreq + 1))
  row=$(awk -F'|' -v c="$c" '{s=$2; gsub(/^ +| +$/,"",s); if (s==c) {print; exit}}' "$tmp.r")
  [ -n "$row" ] || { echo "FAIL: §1 missing $c row"; fail=1; continue; }
  run=$(printf '%s\n' "$row" | awk -F'|' '{s=""; for (i=3;i<NF-1;i++) s=s (i>3?"|":"") $i; print s}' | trim)
  fc=$(printf '%s\n' "$row" | awk -F'|' '{print $(NF-1)}' | trim)
  [ -n "$run" ] || { echo "FAIL: §1 $c row has no run invocation"; fail=1; continue; }
  if printf '%s\n' "$fc" | grep -qE '^[0-9]+ findings?$'; then fsum=$((fsum + ${fc%% *})); runs=$((runs + 1))
  elif [ "$c" = codex ] && printf '%s\n' "$fc" | grep -qE '^unavailable: .+'; then runs=$((runs + 1))
  else echo "FAIL: §1 $c findings cell '$fc' (want '<n> findings'$( [ "$c" = codex ] && echo " or 'unavailable: <reason>'"))"; fail=1; fi
done < "$tmp.c"
# 4. §2 findings: one row per finding; status fixed <sha> | accepted: … | open: <deploy or BRIEF §>
rows '## 2.' "$draft" > "$tmp.f"; nf=$(grep -c . "$tmp.f")
[ "$nf" -eq "$fsum" ] || { echo "FAIL: §2 rows $nf, §1 findings sum $fsum"; fail=1; }
awk -F'|' '{s=$(NF-1); gsub(/^ +| +$/,"",s); print s}' "$tmp.f" > "$tmp.s"; fx=0; fa=0; fo=0
while IFS= read -r s; do
  case $s in
    'fixed '*) sha=${s#fixed }
      if printf '%s\n' "$sha" | grep -qE '^[0-9a-f]{7,40}$'; then fx=$((fx + 1))
        git cat-file -e "$sha^{commit}" 2>/dev/null || { echo "FAIL: §2 fix commit $sha not found"; fail=1; }
      else echo "FAIL: §2 status '$s' (fixed needs a commit sha)"; fail=1; fi ;;
    'accepted: '?*) fa=$((fa + 1)) ;;
    'open: '?*) fo=$((fo + 1)); case $s in *deploy*|*'BRIEF §'*) ;; *) echo "FAIL: §2 '$s' must name the deploy task or a BRIEF §"; fail=1 ;; esac ;;
    *) echo "FAIL: §2 status '$s' (want fixed <sha> | accepted: <reason> | open: <reason>)"; fail=1 ;;
  esac
done < "$tmp.s"
# 5. §3 standards = PLAN §4 items; done ⇒ evidence, N/A ⇒ BRIEF §, pending ⇒ deferred to deploy: <why>
rows '## 4.' "$plan" > "$tmp.p"; rows '## 3.' "$draft" > "$tmp.t"; np=$(grep -c . "$tmp.p"); n3=$(grep -c . "$tmp.t")
[ "$n3" -eq "$np" ] || { echo "FAIL: §3 rows $n3/$np (must equal PLAN §4)"; fail=1; }
awk -F'|' '{s=$2; gsub(/^ +| +$/,"",s); print s}' "$tmp.p" | sort > "$tmp.pi"; awk -F'|' '{s=$2; gsub(/^ +| +$/,"",s); print s}' "$tmp.t" | sort > "$tmp.si"
[ -z "$(comm -3 "$tmp.pi" "$tmp.si")" ] || { echo "FAIL: §3 items differ from PLAN §4"; comm -3 "$tmp.pi" "$tmp.si" | head -n 10; fail=1; }
bad=$(awk -F'|' '{st=$4; gsub(/^ +| +$/,"",st); ev=""; for (i=5;i<NF;i++) ev=ev (i>5?"|":"") $i; gsub(/^ +| +$/,"",ev)
  if (st=="done") { if (ev !~ /→|\/|https?:\/\//) print "done without evidence: " substr($0,1,100) }
  else if (st ~ /^N\/A/) { if (index(st ev,"BRIEF §")==0) print "N/A without BRIEF §: " substr($0,1,100) }
  else if (st=="pending") { if (index(ev,"deferred to deploy: ")!=1) print "pending without deferred to deploy: " substr($0,1,100) }
  else print "status not done/pending/N/A: " substr($0,1,100) }' "$tmp.t")
[ -z "$bad" ] || { echo "FAIL: §3"; printf '%s\n' "$bad"; fail=1; }
cnt() { awk -F'|' -v re="$1" '{s=$4; gsub(/^ +| +$/,"",s); if (s ~ re) n++} END {print n+0}' "$tmp.t"; }
sd=$(cnt '^done$'); sa=$(cnt '^N/A'); sk=$(cnt '^pending$')
# 6–7. threat model doc, pre-deploy hand-off line, no --- rule
grep -q '^## Threat Model' "$plan" && { [ -f docs/threat-model.md ] || { echo "FAIL: docs/threat-model.md missing (PLAN has ## Threat Model)"; fail=1; }; }
grep -q '^pre-deploy: pending (claude-security full scan + Strix' "$draft" || { echo "FAIL: no 'pre-deploy: pending (claude-security full scan + Strix pentest run by /v2p deploy)' line"; fail=1; }
hr=$(grep -n '^---$' "$draft" | cut -d: -f1 | tr '\n' ' '); [ -z "$hr" ] || { echo "FAIL: '---' rule on lines ${hr% } (use ***)"; fail=1; }
# 8. branch, HEAD coverage, clean tree
xb=$(sed -n 's/^checked: .* · branch \([^ ]*\) .*/\1/p' "$ex"); now=$(git rev-parse --abbrev-ref HEAD); head=$(git rev-parse HEAD)
[ "$now" = "$xb" ] || { echo "FAIL: HEAD is on '$now', EXECUTE.md branch is '$xb'"; fail=1; }
dh=$(sed -n 's/^written: .*diff: [^ ]*\.\.\([0-9a-f]*\).*/\1/p' "$draft" | head -n 1)
[ -n "$dh" ] && case $head in "$dh"*) true ;; *) false ;; esac || { echo "FAIL: draft 'diff: <base>..<head>' head '${dh}' is not HEAD $head (stale review: update it after the last fix commit)"; fail=1; }
pre=$(git rev-parse --show-prefix)
dirty=$(git status --porcelain --untracked-files=all -- . | grep -v "^.. ${pre}\.v2p/" | cut -c4- | tr '\n' ' ')
[ -z "$dirty" ] || { echo "FAIL: uncommitted: ${dirty% }"; fail=1; }
# 9. re-run every mechanical verifier of the tasks EXECUTE §1 did not skip (same strict parser as task-record.sh)
skipped=$(rows '## 1.' "$ex" | awk -F'|' '{t=$2; v=$5; gsub(/ /,"",t); gsub(/^ +/,"",v); if (v ~ /^skipped/) print t}')
vt=0; vp=0
grep -o '^### Task [0-9]*' "$plan" | awk '{print $3}' > "$tmp.r"
while IFS= read -r n; do
  printf '%s\n' "$skipped" | grep -qx "$n" && continue
  awk -v n="$n" '$0 ~ "^### Task "n":" {f=1;next} f && /^### / {exit} f && /^\*\*Verifier:\*\*/ {print; exit}' "$plan" | grep -oE '`[^`]+` *→ *`?[^`,;|]*' > "$tmp.c"
  while IFS= read -r m; do
    c=$(printf '%s\n' "$m" | sed 's/^`\([^`]*\)`.*/\1/'); x=$(printf '%s\n' "$m" | sed 's/^`[^`]*` *→ *//; s/`//g; s/ *$//')
    # same rule as task-record.sh: only an unquoted `<word>` is a placeholder; `'<loc>'` and `< file` run
    printf '%s\n' "$c" | sed "s/'[^']*'//g; s/\"[^\"]*\"//g" | grep -qE '<[A-Za-z][A-Za-z0-9_-]*>' && continue
    vt=$((vt + 1)); echo "run: task $n: $c"
    # trust boundary: $c is a Verifier command from PLAN.md, which is hash-locked (check-pass.sh) — by design,
    # not sanitized here; whoever can edit an unsealed PLAN can already run arbitrary commands via this path
    sh -c "$c" > "$tmp.run" 2>&1 < /dev/null; r=$?; last=$(grep . "$tmp.run" | tail -n 1)
    if [ "$r" -ne 0 ]; then echo "FAIL: verifier of task $n fails after review fixes: $c exit $r"; fail=1
    else case $x in ''|*[!0-9]*) vp=$((vp + 1)) ;; *) if [ "$last" = "$x" ]; then vp=$((vp + 1)); else echo "FAIL: verifier of task $n fails after review fixes: $c → $last (expected $x)"; fail=1; fi ;; esac; fi
  done < "$tmp.c"
done < "$tmp.r"
[ "$fail" -eq 0 ] || { echo "FAIL: REVIEW.md not written"; exit 1; }
c="checked: runs $runs/$nreq · findings $fsum (fixed $fx · accepted $fa · open $fo) · standards done $sd · N/A $sa · deferred $sk · verifiers $vp/$vt pass · branch $now · head $head"
awk -v c="$c" '/^checked: /{print c; next} {print}' "$draft" > "$out" && rm "$draft"
# Receipt: deploy accepts REVIEW.md only if its hash matches this file.
shasum -a 256 "$out" | cut -d' ' -f1 > "$d/.review-pass"
find "$d/work" -name 'review-*' -exec rm -f {} + 2>/dev/null
echo "PASS: runs $runs/$nreq, findings $fsum, standards done $sd, verifiers $vp/$vt -> $out"
