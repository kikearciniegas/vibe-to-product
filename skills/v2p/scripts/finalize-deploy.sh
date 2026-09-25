#!/bin/sh
# Promote .v2p/DEPLOY.draft.md to .v2p/DEPLOY.md only if REVIEW.md (and PLAN.md, whose verifiers run here) match their
# receipts; the full claude-security scan stamp covers HEAD (codebase mode, whole repo, effort high|max, verified, clean
# tree, every later commit a §2 fix); every finding is fixed or accepted; gstack's deploy report says DEPLOYED AND
# VERIFIED and its canary HEALTHY; HEAD is merged into origin/<base>; every mechanical PLAN verifier passes against the
# live target (<domain>/<url> from the draft's target:, a charset-checked host equal to CLAUDE.md's Production URL);
# the site answers 200 over https and redirects http; §3 completes REVIEW §3; docs/secrets.md covers .env.example.
# ponytail: shape checks on the draft (rollback line, accepted reasons) are prose gates — the report files, the stamp,
# the merge and the live curls are the mechanical ones. The secret check is a denylist (vendor prefixes + NAME=value
# for .env.example names): a value with no known prefix under a name missing from .env.example passes.
# Usage: sh finalize-deploy.sh [.v2p dir]   (exit 0 PASS · 1 FAIL; expect minutes: verifiers + network)
skill=$(cd "$(dirname "$0")/.." && pwd -P); d=${1:-.v2p}; fail=0
[ -d "$d" ] || { echo "FAIL: $d not found"; exit 1; }
d=$(cd "$d" && pwd -P); root=$(dirname "$d"); cd "$root" || exit 1
draft=$d/DEPLOY.draft.md; out=$d/DEPLOY.md; plan=$d/PLAN.md; ex=$d/EXECUTE.md; rv=$d/REVIEW.md; tmp=${TMPDIR:-/tmp}/fd.$$
trap 'rm -f "$tmp.r" "$tmp.c" "$tmp.st" "$tmp.f" "$tmp.s" "$tmp.fx" "$tmp.rl" "$tmp.p" "$tmp.t" "$tmp.pi" "$tmp.si" "$tmp.n" "$tmp.k" "$tmp.run"' EXIT
# 1. receipts, no earlier DEPLOY.md, a draft to stamp
sh "$skill/scripts/check-pass.sh" "$rv" "$d/.review-pass" >/dev/null || { echo "FAIL: REVIEW.md does not match its receipt (run /v2p review first)"; exit 1; }
sh "$skill/scripts/check-pass.sh" "$plan" "$d/.plan-pass" >/dev/null || { echo "FAIL: PLAN.md does not match its receipt (its verifiers run here)"; exit 1; }
[ -e "$out" ] && { echo "FAIL: DEPLOY.md exists (redeploy: move it aside first)"; exit 1; }
[ -f "$draft" ] || { echo "FAIL: $draft missing"; exit 1; }
grep -q '^checked: ' "$draft" || { echo "FAIL: draft has no 'checked:' line to stamp"; fail=1; }
rows() { awk -v h="$1" 'index($0,h)==1{f=1;next} /^## /{f=0} f && /^\| / && !/^\| (check|item|#) / && !/^\|---/' "$2"; }
trim() { sed 's/^ *//; s/ *$//'; }
w=$(sed -n '/^written: /{p;q;}' "$draft"); fld() { printf '%s\n' "$w" | sed -n "s/.* · $1: \([^ ]*\).*/\1/p"; }
# 2. target: trust boundary — the host is substituted into PLAN verifier commands run by sh -c, so it must be a plain
# hostname (no shell metacharacter can pass this charset; a leading '-' cannot become an option). Invalid → nothing runs.
t=$(fld target); host=${t#https://}; host=${host%/}
if [ "$host" != "$t" ] && printf '%s\n' "$host" | grep -qE '^[A-Za-z0-9][A-Za-z0-9.-]*$' && case $host in *..*) false ;; *) true ;; esac; then :
else echo "FAIL: target host '$host' is not a plain hostname (want 'target: https://<host>' on the written: line)"; fail=1; host=; fi
pr=$(fld pr); base=$(fld base)
printf '%s\n' "$pr" | grep -qE '^#[0-9]+$' && printf '%s\n' "$base" | grep -qE '^[A-Za-z0-9][A-Za-z0-9._/-]*$' || { echo "FAIL: written: line needs 'pr: #<n> · base: <branch>'"; fail=1; base=; }
if [ -f CLAUDE.md ] && grep -q '^## Deploy Configuration' CLAUDE.md; then
  u=$(sed -n '/^## Deploy Configuration/,/^## /p' CLAUDE.md | sed -n 's/^- Production URL: *//p' | head -n 1 | trim); ph=${u#*://}; ph=${ph%%/*}
  [ -z "$host" ] || [ "$ph" = "$host" ] || { echo "FAIL: target $host ≠ CLAUDE.md Deploy Configuration Production URL '$u' (run /setup-deploy)"; fail=1; }
else echo "FAIL: CLAUDE.md has no '## Deploy Configuration' (run /setup-deploy)"; fail=1; fi
# 3. post-brand plans: DESIGN.md still matches its receipt (as finalize-review.sh)
if grep -q '\.v2p/DESIGN\.md' "$plan"; then
  sh "$skill/scripts/check-pass.sh" "$d/DESIGN.md" "$d/.brand-pass" >/dev/null || { echo "FAIL: DESIGN.md does not match its receipt (run /v2p brand again or restore it)"; fail=1; }
fi
# 4. §1 runs: the five rows; the two gstack results are report files whose verdicts are read here
rows '## 1.' "$draft" > "$tmp.r"; fs=0; fx=0
printf '%s\n' security-full strix setup-deploy land-and-deploy canary > "$tmp.c"
while IFS= read -r c; do
  row=$(awk -F'|' -v c="$c" '{s=$2; gsub(/^ +| +$/,"",s); if (s==c) {print; exit}}' "$tmp.r")
  [ -n "$row" ] || { echo "FAIL: §1 missing $c row"; fail=1; continue; }
  run=$(printf '%s\n' "$row" | awk -F'|' '{s=""; for (i=3;i<NF-1;i++) s=s (i>3?"|":"") $i; print s}' | trim)
  res=$(printf '%s\n' "$row" | awk -F'|' '{print $(NF-1)}' | trim)
  [ -n "$run" ] || { echo "FAIL: §1 $c row has no run invocation"; fail=1; continue; }
  case $c in
    security-full) if printf '%s\n' "$res" | grep -qE '^[0-9]+ findings?$'; then fs=${res%% *}
      else echo "FAIL: §1 security-full result '$res' (want '<n> findings')"; fail=1; fi ;;
    strix) if printf '%s\n' "$res" | grep -qE '^[0-9]+ findings?$'; then fx=${res%% *}
      elif ! printf '%s\n' "$res" | grep -qE '^unavailable: .+'; then echo "FAIL: §1 strix result '$res' (want '<n> findings' or 'unavailable: <reason>')"; fail=1; fi ;;
    setup-deploy) case $res in *'Deploy Configuration'*) ;; *) echo "FAIL: §1 setup-deploy result '$res' does not name CLAUDE.md ## Deploy Configuration"; fail=1 ;; esac ;;
    land-and-deploy) if printf '%s\n' "$res" | grep -qE '^\.gstack/deploy-reports/[^/ ]+\.md$' && [ -f "$res" ]; then
        grep -qE '^VERDICT: DEPLOYED AND VERIFIED *$' "$res" || { echo "FAIL: deploy report $res verdict is not DEPLOYED AND VERIFIED"; fail=1; }
      else echo "FAIL: §1 land-and-deploy result '$res' is not an existing .gstack/deploy-reports/<file>.md"; fail=1; fi ;;
    # overall status only: a per-page "HEALTHY" must not pass a DEGRADED/BROKEN run (pages carry their own status)
    canary) if printf '%s\n' "$res" | grep -qE '^\.gstack/canary-reports/[^/ ]+\.json$' && [ -f "$res" ]; then
        grep -qE '"status": *"HEALTHY"' "$res" && ! grep -qE '"status": *"(DEGRADED|BROKEN)"' "$res" || { echo "FAIL: canary report $res status is not HEALTHY"; fail=1; }
      else echo "FAIL: §1 canary result '$res' is not an existing .gstack/canary-reports/<file>.json"; fail=1; fi ;;
  esac
done < "$tmp.c"
# 5. the scan stamp (pretty-printed JSON, `"key": value` per line; nested keys at 4 spaces under their block)
scand=$(fld scan); S=; eff=
sv() { awk -v b="$1" -v k="$2" '/^  "[a-z_]+":/{t=$0; sub(/^  "/,"",t); sub(/".*/,"",t)}
  index($0, (b=="" ? "  " : "    ") "\"" k "\": ")==1 && (b=="" || t==b) {v=substr($0, index($0,": ")+2); sub(/,$/,"",v); gsub(/"/,"",v); print v; exit}' "$st"; }
if ! printf '%s\n' "$scand" | grep -qE '^CLAUDE-SECURITY-[0-9][0-9-]*$' || [ ! -d "$scand" ]; then echo "FAIL: written: line 'scan: $scand' is not a CLAUDE-SECURITY-<ts> directory here"; fail=1
else
  find "$scand" -maxdepth 1 -name 'CLAUDE-SECURITY-REVISION-*.json' > "$tmp.st"
  if [ "$(grep -c . "$tmp.st")" -ne 1 ]; then echo "FAIL: $scand needs exactly one CLAUDE-SECURITY-REVISION-*.json stamp"; fail=1
  else st=$(cat "$tmp.st")
    case ${st##*/} in *-dirty.json|*UNVERSIONED*) echo "FAIL: scan ran on a dirty/unversioned tree (${st##*/})"; fail=1 ;; esac
    m=$(sv '' mode); [ "$m" = scan ] || { echo "FAIL: scan mode '$m' (need a codebase scan)"; fail=1; }
    [ "$(sv '' scope)" = '[]' ] || { echo "FAIL: scan was scoped (need the whole repository)"; fail=1; }
    eff=$(sv '' effort); case $eff in high|max) ;; *) echo "FAIL: scan effort '$eff' (need high or max)"; fail=1 ;; esac
    vs=$(sv verification status); [ "$vs" = verified ] || { echo "FAIL: scan verification '$vs'"; fail=1; }
    S=$(sv revision commit)
    printf '%s\n' "$S" | grep -qE '^[0-9a-f]{7,64}$' && git merge-base --is-ancestor "$S" HEAD 2>/dev/null || { echo "FAIL: scanned commit '$S' is not an ancestor of HEAD"; fail=1; S=; }
    n=$(sv findings total); [ "$n" = "$fs" ] || { echo "FAIL: §1 security-full says $fs, stamp says $n"; fail=1; }
    [ "$(grep -c . "$scand/CLAUDE-SECURITY-RESULTS.jsonl" 2>/dev/null)" = "$n" ] || { echo "FAIL: $scand/CLAUDE-SECURITY-RESULTS.jsonl lines ≠ stamp total $n"; fail=1; }
  fi
fi
# 6. §2: one row per finding, fixed <sha> | accepted: <reason> (no open at deploy); every commit after the scan is a fix
rows '## 2.' "$draft" > "$tmp.f"; nf=$(grep -c . "$tmp.f"); want=$((fs + fx))
[ "$nf" -eq "$want" ] || { echo "FAIL: §2 rows $nf, §1 findings sum $want"; fail=1; }
nsf=$(awk -F'|' '{s=$3; gsub(/^ +| +$/,"",s); if (s=="security-full") n++} END {print n+0}' "$tmp.f")
[ "$nsf" -eq "$fs" ] || { echo "FAIL: §2 security-full rows $nsf, §1 security-full $fs"; fail=1; }
bc=$(awk -F'|' '{s=$3; gsub(/^ +| +$/,"",s); if (s!="security-full" && s!="strix") {print s; exit}}' "$tmp.f")
[ -z "$bc" ] || { echo "FAIL: §2 check '$bc' (deploy findings come from security-full or strix)"; fail=1; }
awk -F'|' '{s=$(NF-1); gsub(/^ +| +$/,"",s); print s}' "$tmp.f" > "$tmp.s"; : > "$tmp.fx"; ax=0; aa=0
while IFS= read -r s; do
  case $s in
    'fixed '*) sha=${s#fixed }
      if printf '%s\n' "$sha" | grep -qE '^[0-9a-f]{7,40}$' && git rev-parse -q --verify "$sha^{commit}" >> "$tmp.fx"; then ax=$((ax + 1))
      else echo "FAIL: §2 fix commit '$sha' not found"; fail=1; fi ;;
    'accepted: '?*) aa=$((aa + 1)) ;;
    *) echo "FAIL: §2 status '$s' (deploy allows fixed <sha> | accepted: <reason>)"; fail=1 ;;
  esac
done < "$tmp.s"
[ -n "$S" ] && git rev-list "$S..HEAD" > "$tmp.rl" && while IFS= read -r c; do
  grep -qx "$c" "$tmp.fx" || { echo "FAIL: commit $c after the scan is not a §2 fix (re-run the scan or account for it)"; fail=1; }
done < "$tmp.rl"
# 7. §3 = REVIEW §3 items; done ⇒ evidence, N/A ⇒ BRIEF §, pending ⇒ post-launch: <trigger and date>
rows '## 3.' "$rv" > "$tmp.p"; rows '## 3.' "$draft" > "$tmp.t"; np=$(grep -c . "$tmp.p"); n3=$(grep -c . "$tmp.t")
[ "$n3" -eq "$np" ] || { echo "FAIL: §3 rows $n3/$np (must equal REVIEW §3)"; fail=1; }
awk -F'|' '{s=$2; gsub(/^ +| +$/,"",s); print s}' "$tmp.p" | sort > "$tmp.pi"; awk -F'|' '{s=$2; gsub(/^ +| +$/,"",s); print s}' "$tmp.t" | sort > "$tmp.si"
[ -z "$(comm -3 "$tmp.pi" "$tmp.si")" ] || { echo "FAIL: §3 items differ from REVIEW §3"; comm -3 "$tmp.pi" "$tmp.si" | head -n 10; fail=1; }
bad=$(awk -F'|' '{st=$4; gsub(/^ +| +$/,"",st); ev=""; for (i=5;i<NF;i++) ev=ev (i>5?"|":"") $i; gsub(/^ +| +$/,"",ev)
  if (st=="done") { if (ev !~ /→|\/|https?:\/\//) print "done without evidence: " substr($0,1,100) }
  else if (st ~ /^N\/A/) { if (index(st ev,"BRIEF §")==0) print "N/A without BRIEF §: " substr($0,1,100) }
  else if (st=="pending") { if (index(ev,"post-launch: ")!=1) print "pending without post-launch: " substr($0,1,100) }
  else print "status not done/pending/N/A: " substr($0,1,100) }' "$tmp.t")
[ -z "$bad" ] || { echo "FAIL: §3"; printf '%s\n' "$bad"; fail=1; }
cnt() { awk -F'|' -v re="$1" '{s=$4; gsub(/^ +| +$/,"",s); if (s ~ re) n++} END {print n+0}' "$tmp.t"; }
sd=$(cnt '^done$'); sa=$(cnt '^N/A'); sp=$(cnt '^pending$')
# 8. rollback rehearsal (user-attributed; shape only)
rb=$(grep '^rollback: ' "$draft" | head -n 1)
printf '%s\n' "$rb" | grep -qE '^rollback: rehearsed [0-9]{4}-[0-9]{2}-[0-9]{2}T[0-9]{2}:[0-9]{2}(:[0-9]{2})?Z? · elapsed [0-9]+s · method: [^ ].* · by user$' || { echo "FAIL: rollback line (want 'rollback: rehearsed <ISO> · elapsed <n>s · method: <text> · by user')"; fail=1; }
rs=$(printf '%s\n' "$rb" | sed -n 's/.* · elapsed \([0-9]*\)s · .*/\1/p')
# 9. secrets register covers .env.example; no value in the draft or the register
sed -n 's/^\([A-Z_][A-Z0-9_]*\)=.*/\1/p' .env.example 2>/dev/null > "$tmp.n"
if [ -f docs/secrets.md ]; then
  while IFS= read -r nm; do grep -qwF -- "$nm" docs/secrets.md || { echo "FAIL: docs/secrets.md does not list $nm"; fail=1; }; done < "$tmp.n"
else echo "FAIL: docs/secrets.md missing (every .env.example name: owner, rotation, where it lives)"; fail=1; fi
re='sb_secret_|pdl_live_apikey_|pdl_sdbx_apikey_|pdl_ntfset_|whsec_|sk_live_|sk_test_|-----BEGIN '
nms=$(tr '\n' '|' < "$tmp.n" | sed 's/|$//'); [ -z "$nms" ] || re="(^|[^A-Za-z0-9_])($nms)=[^ <|]|$re"
for f in "${draft#"$root"/}" docs/secrets.md; do
  [ -f "$f" ] || continue; ln=$(grep -nE -- "$re" "$f" | head -n 1 | cut -d: -f1)
  [ -z "$ln" ] || { echo "FAIL: secret-looking value in ${f}:${ln}"; fail=1; }
done
grep -qE '^secrets: .*values: none$' "$draft" || { echo "FAIL: no 'secrets: docs/secrets.md · <n> names · values: none' line"; fail=1; }
# 10. no --- rule, hand-off line
hr=$(grep -n '^---$' "$draft" | cut -d: -f1 | tr '\n' ' '); [ -z "$hr" ] || { echo "FAIL: '---' rule on lines ${hr% } (use ***)"; fail=1; }
grep -q '^Next: live' "$draft" || { echo "FAIL: no 'Next: live' line"; fail=1; }
# 11. branch, merged into origin/<base> (the scanned + fixed code is what went live), clean tree
xb=$(sed -n 's/^checked: .* · branch \([^ ]*\) .*/\1/p' "$rv"); now=$(git rev-parse --abbrev-ref HEAD); head=$(git rev-parse HEAD)
[ "$now" = "$xb" ] || { echo "FAIL: HEAD is on '$now', REVIEW.md branch is '$xb'"; fail=1; }
if [ -n "$base" ]; then
  if git fetch -q origin "+refs/heads/${base}:refs/remotes/origin/${base}" 2>/dev/null; then
    git merge-base --is-ancestor HEAD "origin/$base" 2>/dev/null || { echo "FAIL: HEAD is not merged into origin/$base (run /land-and-deploy)"; fail=1; }
  else echo "FAIL: cannot fetch origin/$base"; fail=1; fi
fi
pre=$(git rev-parse --show-prefix)
dirty=$(git status --porcelain --untracked-files=all -- . | grep -vE "^.. ${pre}(\.v2p/|\.gstack/|CLAUDE-SECURITY-[^/]*/|strix_runs/)" | cut -c4- | tr '\n' ' ')
[ -z "$dirty" ] || { echo "FAIL: uncommitted: ${dirty% }"; fail=1; }
# 12. re-run every mechanical PLAN verifier against the live target, including the tasks execute handed to deploy
# and the deferred ones (their credential exists now); rulings from REVIEW.md (sealed) and this draft are not re-run
grep -o '^### Task [0-9]*' "$plan" | awk '{print $3}' > "$tmp.k"
skipped=$(rows '## 1.' "$ex" | awk -F'|' '{t=$2; v=$5; gsub(/ /,"",t); gsub(/^ +/,"",v); if (v ~ /^skipped/ && v !~ /handed to \/v2p deploy/) print t}')
bad=$(grep '^ruling:' "$draft" | grep -vE '^ruling: task [0-9]+ · plan defect · [^ ].*')
[ -z "$bad" ] || { echo "FAIL: malformed ruling line(s) (want 'ruling: task <n> · plan defect · <evidence>'):"; printf '%s\n' "$bad"; fail=1; }
dr=$(sed -n 's/^ruling: task \([0-9][0-9]*\) · plan defect · [^ ].*/\1/p' "$draft")
unk=$(printf '%s\n' "$dr" | grep . | grep -vxF -f "$tmp.k")
[ -z "$unk" ] || { echo "FAIL: ruling names task(s) not in PLAN: $(printf '%s' "$unk" | tr '\n' ' ')"; fail=1; }
ruled=$(printf '%s\n%s\n' "$(sed -n 's/^ruling: task \([0-9][0-9]*\) · plan defect · [^ ].*/\1/p' "$rv")" "$dr" | grep . | sort -u)
vt=0; vp=0; nr=0; left=0
[ -n "$host" ] && while IFS= read -r n; do
  printf '%s\n' "$skipped" | grep -qx "$n" && continue
  if printf '%s\n' "$ruled" | grep -qx "$n"; then echo "ruling: task $n verifier not re-run (plan defect)"; nr=$((nr + 1)); continue; fi
  awk -v n="$n" '$0 ~ "^### Task "n":" {f=1;next} f && /^### / {exit} f && /^\*\*Verifier:\*\*/ {print; exit}' "$plan" | grep -oE '`[^`]+` *→ *`?[^`,;|]*' > "$tmp.c"
  while IFS= read -r m; do
    c=$(printf '%s\n' "$m" | sed 's/^`\([^`]*\)`.*/\1/' | sed "s|<domain>|$host|g; s|<url>|https://$host|g"); x=$(printf '%s\n' "$m" | sed 's/^`[^`]*` *→ *//; s/`//g; s/ *$//')
    # same rule as task-record.sh: only an unquoted `<word>` is a placeholder; `'<loc>'` and `< file` run
    if printf '%s\n' "$c" | sed "s/'[^']*'//g; s/\"[^\"]*\"//g" | grep -qE '<[A-Za-z][A-Za-z0-9_-]*>'; then left=$((left + 1)); echo "skip: task $n: $c (placeholder)"; continue; fi
    vt=$((vt + 1)); echo "run: task $n: $c"
    # trust boundary: $c is a Verifier command from PLAN.md (hash-locked, checked above) plus the host validated in step 2
    sh -c "$c" > "$tmp.run" 2>&1 < /dev/null; r=$?; last=$(grep . "$tmp.run" | tail -n 1)
    if [ "$r" -ne 0 ]; then echo "FAIL: verifier of task $n fails on the live target: $c exit $r"; fail=1
    else case $x in ''|*[!0-9]*) vp=$((vp + 1)) ;; *) if [ "$last" = "$x" ]; then vp=$((vp + 1)); else echo "FAIL: verifier of task $n fails on the live target: $c → $last (expected $x)"; fail=1; fi ;; esac; fi
  done < "$tmp.c"
done < "$tmp.k"
# 13. live: 200 over https, http redirects to https (curl from PATH)
if [ -n "$host" ]; then
  code=$(curl -m 10 -sS -o /dev/null -w '%{http_code}' "https://$host/" 2>/dev/null); [ "$code" = 200 ] || { echo "FAIL: https://$host/ → ${code:-no answer} (want 200)"; fail=1; }
  curl -m 10 -sI "http://$host/" 2>/dev/null | grep -qi '^location: https://' || { echo "FAIL: http://$host/ does not redirect to https"; fail=1; }
fi
# 14. stamp, promote, seal
[ "$fail" -eq 0 ] || { echo "FAIL: DEPLOY.md not written"; exit 1; }
s12=$(printf '%s' "$S" | cut -c1-12)
c="checked: scan $eff $s12 · findings $want (fixed $ax · accepted $aa) · verifiers $vp/$vt pass · placeholders left $left · rulings $nr · standards done $sd · N/A $sa · post-launch $sp · live 2/2 · canary HEALTHY · rollback ${rs}s · branch $now · head $head"
awk -v c="$c" '/^checked: /{print c; next} {print}' "$draft" > "$out" && rm "$draft"
# Receipt: /v2p reads DEPLOY.md as live only if its hash matches this file.
shasum -a 256 "$out" | cut -d' ' -f1 > "$d/.deploy-pass"
find "$d/work" -name 'deploy-*' -exec rm -f {} + 2>/dev/null
echo "PASS: scan $eff $s12, findings $want (fixed $ax · accepted $aa), verifiers $vp/$vt, placeholders left $left, rulings $nr, standards done $sd, post-launch $sp, canary HEALTHY -> ${out#"$root"/}"
