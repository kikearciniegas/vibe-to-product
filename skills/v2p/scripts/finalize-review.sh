#!/bin/sh
# Promote .v2p/REVIEW.draft.md to .v2p/REVIEW.md only if EXECUTE.md and PLAN.md match their receipts, §1 has every
# required run, §2 accounts for every finding (fix commits exist), §3 completes PLAN §4 (pending only as deferred to deploy;
# not adopted/gap cite a repo path), the draft covers the current HEAD, the tree is clean on the execute branch, every mechanical PLAN verifier
# still passes when re-run here (expect minutes), and (post-brand plans) DESIGN.md matches its receipt.
# Usage: sh finalize-review.sh [.v2p dir]
skill=$(cd "$(dirname "$0")/.." && pwd -P); d=${1:-.v2p}; fail=0
[ -d "$d" ] || { echo "FAIL: $d not found"; exit 1; }
d=$(cd "$d" && pwd -P); root=$(dirname "$d"); cd "$root" || exit 1
draft=$d/REVIEW.draft.md; out=$d/REVIEW.md; plan=$d/PLAN.md; ex=$d/EXECUTE.md; tmp=${TMPDIR:-/tmp}/fr.$$
trap 'rm -f "$tmp.r" "$tmp.f" "$tmp.s" "$tmp.p" "$tmp.pi" "$tmp.si" "$tmp.t" "$tmp.c" "$tmp.run"' EXIT
sh "$skill/scripts/check-pass.sh" "$ex" "$d/.execute-pass" >/dev/null || { echo "FAIL: EXECUTE.md does not match its receipt (run /v2p execute first)"; exit 1; }
sh "$skill/scripts/check-pass.sh" "$plan" "$d/.plan-pass" >/dev/null || { echo "FAIL: PLAN.md does not match its receipt (its verifiers run here)"; exit 1; }
[ -f "$draft" ] || { echo "FAIL: $draft missing"; exit 1; }
grep -q '^checked: ' "$draft" || { echo "FAIL: draft has no 'checked:' line to stamp"; fail=1; }
rows() { awk -v h="$1" 'index($0,h)==1{f=1;next} /^## /{f=0} f && /^\| / && !/^\| (check|item|#) / && !/^\|---/' "$2"; }
trim() { sed 's/^ *//; s/ *$//'; }
# 3. §1 runs: required checks, findings cell "<n> findings" (codex, and ux-laws/qa under `preview: none`, may be "unavailable: <reason>"), run cell non-empty
printf '%s\n' code-review simplify security verification ux-laws codex qa > "$tmp.c"
awk '/^## 9/{f=1;next} /^## /{f=0} f' "$d/BRIEF.md" | grep 'Conditional blocks ON' | grep -q 'i18n' && echo i18n >> "$tmp.c"
# 3a. preview: exactly one line, `<URL> · started by <cmd>`, or `none — <reason>` when none can be created;
# only with `none` may ux-laws and qa read "unavailable: <reason>"
pl=$(grep '^preview: ' "$draft"); nopv=no
if [ "$(grep -c '^preview: ' "$draft")" -ne 1 ] || ! printf '%s\n' "$pl" | grep -qE '^preview: (https?://[^ ]+ · started by [^ ].*|none (—|-) [^ ].*)$'; then
  echo "FAIL: no valid 'preview:' line (want exactly one 'preview: <URL> · started by <cmd>' or 'preview: none — <reason>')"; fail=1
else case $pl in "preview: none"*) nopv=yes ;; esac; fi
rows '## 1.' "$draft" > "$tmp.r"; nreq=0; runs=0; fsum=0
while IFS= read -r c; do nreq=$((nreq + 1))
  row=$(awk -F'|' -v c="$c" '{s=$2; gsub(/^ +| +$/,"",s); if (s==c) {print; exit}}' "$tmp.r")
  [ -n "$row" ] || { echo "FAIL: §1 missing $c row"; fail=1; continue; }
  run=$(printf '%s\n' "$row" | awk -F'|' '{s=""; for (i=3;i<NF-1;i++) s=s (i>3?"|":"") $i; print s}' | trim)
  fc=$(printf '%s\n' "$row" | awk -F'|' '{print $(NF-1)}' | trim)
  [ -n "$run" ] || { echo "FAIL: §1 $c row has no run invocation"; fail=1; continue; }
  if printf '%s\n' "$fc" | grep -qE '^[0-9]+ findings?$'; then fsum=$((fsum + ${fc%% *})); runs=$((runs + 1))
  elif { [ "$c" = codex ] || { [ "$nopv" = yes ] && { [ "$c" = ux-laws ] || [ "$c" = qa ]; }; }; } && printf '%s\n' "$fc" | grep -qE '^unavailable: .+'; then runs=$((runs + 1))
  else echo "FAIL: §1 $c findings cell '$fc' (want '<n> findings'$( [ "$c" = codex ] && echo " or 'unavailable: <reason>'"))"; fail=1; fi
done < "$tmp.c"
# 3b. brand: a PLAN whose Spec line names .v2p/DESIGN.md (mapped after /v2p brand; hash-locked, so the mention cannot be
# dropped to dodge this) needs DESIGN.md to match its receipt and the ux-laws run cell to name DESIGN.md. Pre-brand plans skip.
if grep -q '\.v2p/DESIGN\.md' "$plan"; then
  sh "$skill/scripts/check-pass.sh" "$d/DESIGN.md" "$d/.brand-pass" >/dev/null || { echo "FAIL: DESIGN.md does not match its receipt (run /v2p brand again or restore it)"; fail=1; }
  ux=$(awk -F'|' '{s=$2; gsub(/^ +| +$/,"",s); if (s=="ux-laws") {r=""; for (i=3;i<NF-1;i++) r=r $i; print r; exit}}' "$tmp.r")
  case $ux in *DESIGN.md*) ;; *) echo "FAIL: §1 ux-laws run cell does not name DESIGN.md"; fail=1 ;; esac
fi
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
# 5. §3 standards = PLAN §4 items; done ⇒ evidence, N/A ⇒ BRIEF §, pending ⇒ deferred to deploy: <why>,
# not adopted (owner decision) / gap (known, not built) ⇒ an existing repo path
rows '## 4.' "$plan" > "$tmp.p"; rows '## 3.' "$draft" > "$tmp.t"; np=$(grep -c . "$tmp.p"); n3=$(grep -c . "$tmp.t")
[ "$n3" -eq "$np" ] || { echo "FAIL: §3 rows $n3/$np (must equal PLAN §4)"; fail=1; }
awk -F'|' '{s=$2; gsub(/^ +| +$/,"",s); print s}' "$tmp.p" | sort > "$tmp.pi"; awk -F'|' '{s=$2; gsub(/^ +| +$/,"",s); print s}' "$tmp.t" | sort > "$tmp.si"
[ -z "$(comm -3 "$tmp.pi" "$tmp.si")" ] || { echo "FAIL: §3 items differ from PLAN §4"; comm -3 "$tmp.pi" "$tmp.si" | head -n 10; fail=1; }
bad=$(awk -F'|' '{st=$4; gsub(/^ +| +$/,"",st); ev=""; for (i=5;i<NF;i++) ev=ev (i>5?"|":"") $i; gsub(/^ +| +$/,"",ev)
  if (st=="done") { if (ev !~ /→|\/|https?:\/\/|(^|[ `])[A-Za-z0-9_-][A-Za-z0-9_.-]*\.[A-Za-z][A-Za-z0-9]*(:[0-9]+)?([ `]|$)/) print "done without evidence: " substr($0,1,100) }
  else if (st ~ /^N\/A/) { if (index(st ev,"BRIEF §")==0) print "N/A without BRIEF §: " substr($0,1,100) }
  else if (st=="pending") { if (index(ev,"deferred to deploy: ")!=1) print "pending without deferred to deploy: " substr($0,1,100) }
  else if (st ~ /^not adopted( |$)/) { r=st; sub(/^not adopted *((—|-) *)?/,"",r); print "ref\t" (r=="" ? ev : r) "\tnot adopted cites no existing path: " substr($0,1,100) }
  else if (st ~ /^gap( |$)/) { r=st; sub(/^gap *((—|-) *)?/,"",r); print "ref\t" (r=="" ? ev : r) "\tgap cites no existing path: " substr($0,1,100) }
  else print "status not done/pending/N/A/not adopted/gap: " substr($0,1,100) }' "$tmp.t" | sh "$skill/scripts/check-refs.sh" "$root")
[ -z "$bad" ] || { echo "FAIL: §3"; printf '%s\n' "$bad"; fail=1; }
cnt() { awk -F'|' -v re="$1" '{s=$4; gsub(/^ +| +$/,"",s); if (s ~ re) n++} END {print n+0}' "$tmp.t"; }
sd=$(cnt '^done$'); sa=$(cnt '^N/A'); sk=$(cnt '^pending$'); sx=$(cnt '^not adopted( |$)'); sg=$(cnt '^gap( |$)')
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
# 9. re-run every mechanical verifier of the tasks EXECUTE §1 did not skip or defer (same strict parser as task-record.sh);
# a deferred one needs a credential that does not exist until deploy (live incident), and deploy re-checks it
skipped=$(rows '## 1.' "$ex" | awk -F'|' '{t=$2; v=$5; gsub(/ /,"",t); gsub(/^ +/,"",v); if (v ~ /^(skipped|deferred)/) print t}')
vt=0; vp=0; nr=0
grep -o '^### Task [0-9]*' "$plan" | awk '{print $3}' > "$tmp.r"
# a verifier wrong as written (live Task 5: raw `wc -l` padded on macOS) is ruled a plan defect on the user's yes:
# `ruling: task <n> · plan defect · <evidence>`. Not re-run, counted in checked/PASS so it is never silent.
bad=$(grep '^ruling:' "$draft" | grep -vE '^ruling: task [0-9]+ · plan defect · [^ ].*')
[ -z "$bad" ] || { echo "FAIL: malformed ruling line(s) (want 'ruling: task <n> · plan defect · <evidence>'):"; printf '%s\n' "$bad"; fail=1; }
ruled=$(sed -n 's/^ruling: task \([0-9][0-9]*\) · plan defect · [^ ].*/\1/p' "$draft")
unk=$(printf '%s\n' "$ruled" | grep . | grep -vxF -f "$tmp.r")
[ -z "$unk" ] || { echo "FAIL: ruling names task(s) not in PLAN: $(printf '%s' "$unk" | tr '\n' ' ')"; fail=1; }
while IFS= read -r n; do
  printf '%s\n' "$skipped" | grep -qx "$n" && continue
  if printf '%s\n' "$ruled" | grep -qx "$n"; then echo "ruling: task $n verifier not re-run (plan defect)"; nr=$((nr + 1)); continue; fi
  vl=$(awk -v n="$n" '$0 ~ "^### Task "n":" {f=1;next} f && /^### / {exit} f && /^\*\*Verifier:\*\*/ {print; exit}' "$plan")
  # mechanical part only: a `cmd` → x inside the manual: part is prose for a person, never run
  printf '%s\n' "$vl" | sed 's/manual:.*mechanical:/mechanical:/; s/manual:.*//' | grep -oE '`[^`]+` *→ *`?[^`,;|]*' > "$tmp.c"; ran=0
  # 0 commands from a mechanical Verifier is "not verified", never a pass (field test: 14 vacuous passes)
  [ -s "$tmp.c" ] || ! printf '%s\n' "$vl" | grep -qE '^\*\*Verifier:\*\* *mechanical:' ||
    { echo "FAIL: verifier of task $n: mechanical with no backticked \`command\` → expected pair; nothing ran (not verified)"; fail=1; }
  while IFS= read -r m; do
    c=$(printf '%s\n' "$m" | sed 's/^`\([^`]*\)`.*/\1/'); x=$(printf '%s\n' "$m" | sed 's/^`[^`]*` *→ *//; s/`//g; s/ *$//')
    # same rule as task-record.sh: only an unquoted `<word>` is a placeholder; `'<loc>'` and `< file` run
    printf '%s\n' "$c" | sed "s/'[^']*'//g; s/\"[^\"]*\"//g" | grep -qE '<[A-Za-z][A-Za-z0-9_-]*>' && continue
    vt=$((vt + 1)); ran=$((ran + 1)); echo "run: task $n: $c"
    # trust boundary: $c is a Verifier command from PLAN.md, which is hash-locked (check-pass.sh) — by design,
    # not sanitized here; whoever can edit an unsealed PLAN can already run arbitrary commands via this path
    sh -c "$c" > "$tmp.run" 2>&1 < /dev/null; r=$?; last=$(grep . "$tmp.run" | tail -n 1)
    if [ "$r" -ne 0 ]; then echo "FAIL: verifier of task $n fails after review fixes: $c exit $r"; fail=1
    else case $x in ''|*[!0-9]*) vp=$((vp + 1)) ;; *) if [ "$last" = "$x" ]; then vp=$((vp + 1)); else echo "FAIL: verifier of task $n fails after review fixes: $c → $last (expected $x)"; fail=1; fi ;; esac; fi
  done < "$tmp.c"
  # every extracted command a <placeholder>: nothing ran, not verified (finalize-audit's rule)
  [ -s "$tmp.c" ] && [ "$ran" -eq 0 ] && { echo "FAIL: verifier of task $n: every command is a <placeholder>: nothing ran (not verified)"; fail=1; }
done < "$tmp.r"
[ "$fail" -eq 0 ] || { echo "FAIL: REVIEW.md not written"; exit 1; }
c="checked: runs $runs/$nreq · findings $fsum (fixed $fx · accepted $fa · open $fo) · standards done $sd · N/A $sa · not adopted $sx · gap $sg · deferred $sk · verifiers $vp/$vt pass · rulings $nr · branch $now · head $head"
awk -v c="$c" '/^checked: /{print c; next} {print}' "$draft" > "$out" && rm "$draft"
# Receipt: deploy accepts REVIEW.md only if its hash matches this file.
shasum -a 256 "$out" | cut -d' ' -f1 > "$d/.review-pass"
find "$d/work" -name 'review-*' -exec rm -f {} + 2>/dev/null
echo "PASS: runs $runs/$nreq, findings $fsum, standards done $sd, verifiers $vp/$vt, rulings $nr -> $out"
