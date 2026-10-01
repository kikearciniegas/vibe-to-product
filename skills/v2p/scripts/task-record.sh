#!/bin/sh
# The only writer of execute's per-task records (.v2p/work/execute-task-<n>.md + receipt .execute-task-<n>-pass)
# and of .v2p/PLAN-AMENDMENTS.md. PLAN.md is never edited: scope granted mid-execute is appended here.
# Usage: sh task-record.sh start|verify|manual|note|ponytail|allow|skip|defer <n> [args] [.v2p]; start <n> --base <sha> "<why>" [.v2p];
#        verify <n> --head <sha> [.v2p]   (exit 0 ok · 1 fail · 2 usage)
#   start <n>                  record base (HEAD), branch, tidy count; resumes if the record matches the PLAN receipt;
#                              start, skip and defer refuse to write a record while .v2p/EXECUTE.draft.md is missing;
#                              a task touching UI files is refused while .v2p/DESIGN.md does not match .v2p/.brand-pass
#   start <n> --base <sha> "<why>"  re-start: replaces any record for <n> (verifier/manual/ponytail reset) with base
#                              <sha> (an ancestor of HEAD); appends `base := <sha> (was <old>)` to PLAN-AMENDMENTS.md
#   verify <n>                 drift-check.sh <n>, then every mechanical Verifier command of the task; writes the result
#   verify <n> --head <sha>    re-verify an earlier task: drift-check.sh <n> --head <sha> (base..<sha> only) and head: <sha>;
#                              the Verifier commands still run on the current tree
#   manual <n> "<text>"        the user's observation for the manual part of the Verifier
#   note <n> "<text>"          the controller's own evidence (`by controller`; repeatable). Never `manual`, which stamps
#                              `by user` (live: the controller signed the user's name on its own checks, obs. 0210)
#   ponytail <n> "<text>"      "none" or "<k> findings, <a> applied, <d> deferred, <r> rejected: <one line>" (a+d+r=k);
#                              run after verify passes on the committed head: also records head: (range base..head).
#                              Refused while verifier: is pending (live Task 11 was reviewed before verify).
#                              Only this writer enforces the format; readers (finalize-execute) accept older lines too.
#   allow <n> <path> "<why>"   scope amendment: appends to .v2p/PLAN-AMENDMENTS.md and the record's files: line
#   skip <n> "<reason>"        task not executed here (only on the user's yes)
#   defer <n> "<credential>"   verifier needs a credential this session lacks (only on the user's yes); deploy re-checks it
# ponytail: expected-output check covers exit code and bare numbers only; `→ passed`/`→ all passed` rely on the
# command's exit code — mapping's Verifier convention asks for self-checking commands.
skill=$(cd "$(dirname "$0")/.." && pwd -P); S=$skill/scripts
usage() { echo "usage: task-record.sh start|verify|manual|note|ponytail|allow|skip|defer <n> [args] [.v2p]; start <n> --base <sha> \"<reason>\" [.v2p]; verify <n> --head <sha> [.v2p]" >&2; exit 2; }
# a reason lands in PLAN-AMENDMENTS.md, which drift-check parses: one line, and none of the grant syntax; note/skip/defer
# text uses the same check (a multi-line skip text was accepted and broke the record's one-line-per-key shape)
reason() { case $1 in *"
"*) echo "ERROR: text must be one line" >&2; exit 2 ;;
  *'files +='*|*'base :='*|*'`'*|*' · task '*) echo "ERROR: text must not contain 'files +=', 'base :=', a backtick or ' · task '" >&2; exit 2 ;; esac; }
cmd=$1; n=$2; nb=; hd=
case $cmd in start|verify) dd=$3 ;; manual|note|ponytail|skip|defer) dd=$4 ;; allow) dd=$5 ;; *) usage ;; esac
case $n in ''|*[!0-9]*) usage ;; esac
if [ "$cmd" = start ] && [ "$3" = --base ]; then nb=$4; why=$5; dd=$6
  [ -n "$nb" ] && [ -n "$why" ] || { echo "ERROR: start <n> --base <sha> \"<reason>\" (the reason is required)" >&2; exit 2; }
  reason "$why"
  case $why in .v2p|*/.v2p) [ -d "$why" ] && { echo "ERROR: '$why' is the .v2p directory, not a reason: start <n> --base <sha> \"<reason>\" [.v2p]" >&2; exit 2; } ;; esac
fi
if [ "$cmd" = verify ] && [ "$3" = --head ]; then hd=$4; dd=$5; [ -n "$hd" ] || usage; fi
d=${dd:-.v2p}; [ -d "$d" ] || { echo "ERROR: $d not found" >&2; exit 2; }
d=$(cd "$d" && pwd -P); root=$(dirname "$d"); cd "$root" || exit 2
plan=$d/PLAN.md; rec=$d/work/execute-task-$n.md; pass=$d/work/.execute-task-$n-pass; amend=$d/PLAN-AMENDMENTS.md
sh "$S/check-pass.sh" "$plan" "$d/.plan-pass" >/dev/null || { echo "ERROR: PLAN has no valid receipt (sh check-pass.sh $plan $d/.plan-pass)" >&2; exit 2; }
[ "$(grep -c "^### Task $n:" "$plan")" -eq 1 ] || { echo "ERROR: PLAN has no single '### Task $n:'" >&2; exit 2; }
mkdir -p "$d/work"; tmp=${TMPDIR:-/tmp}/tr.$$; trap 'rm -f "$tmp" "$tmp.o" "$tmp.run"' EXIT
planpass=$(cat "$d/.plan-pass"); now() { date +%Y-%m-%dT%H:%M:%S; }
seal() { shasum -a 256 "$rec" | cut -d' ' -f1 > "$pass"; }
sealed() { [ -f "$rec" ] && [ -f "$pass" ] && [ "$(shasum -a 256 "$rec" | cut -d' ' -f1)" = "$(cat "$pass")" ]; }
# put <key> <value> [block-file]: replace the key's line (and its indented block) at the end of the record
put() { K=$1 awk 'skip && /^  /{next} {skip=0} index($0, ENVIRON["K"] ": ")==1 || $0==ENVIRON["K"] ":" {skip=1; next} {print}' "$rec" > "$tmp"
  printf '%s: %s\n' "$1" "$2" | sed 's/: $/:/' >> "$tmp"; [ -n "$3" ] && sed 's/^/  /' "$3" >> "$tmp"; mv "$tmp" "$rec"; }
tline() { awk -v n="$n" -v k="$1" '$0 ~ "^### Task "n":" {f=1;next} f && /^### / {exit} f && index($0, "**" k ":**")==1 {print; exit}' "$plan"; }
# the mechanical part of a Verifier line: a `cmd` → x inside its manual: part is prose for a person, never run
mpart() { sed 's/manual:.*mechanical:/mechanical:/; s/manual:.*//'; }
ftoks() { tline Files | sed 's/\*\*Interfaces:\*\*.*//' | grep -o '`[^`]*`' | tr -d '`' | sed 's/ .*//; s/<[^>]*>/*/g'; }
# UI gate: a task whose Files name a UI file starts only while .v2p/DESIGN.md matches its receipt (brand before UI work)
# ponytail: extension heuristic; a .ts styling file (vanilla-extract) passes — extend the list when it bites.
uigate() { ui=$(ftoks | grep -E '\.(tsx|jsx|vue|svelte|css|scss|html|swift|kt|dart)$|(^|/)tailwind\.config\.' | head -n 1)
  [ -z "$ui" ] || sh "$S/check-pass.sh" "$d/DESIGN.md" "$d/.brand-pass" >/dev/null ||
    { echo "ERROR: task $n touches UI files ($ui) and .v2p/DESIGN.md has no valid receipt: run /v2p brand" >&2; exit 2; }; }
# finalize-execute deletes the records (field test V9: `allow` during review then failed with no route): name the route
fin() { [ -f "$d/EXECUTE.md" ] && [ -f "$d/.execute-pass" ] &&
  echo "  execute is finalized (.v2p/EXECUTE.md has its receipt): a scope change during review is a REVIEW §2 scope finding row, not an amendment" >&2; }
# Step 1 copies PLAN §4 into EXECUTE.draft.md before any task (field test V12: skipped, caught only at finalize)
drafted() { [ -f "$d/EXECUTE.draft.md" ] || { echo "ERROR: $d/EXECUTE.draft.md missing: execute Step 1 copies PLAN §4 into it (references/execute-template.md) before any task record" >&2; fin; exit 2; }; }
write_start() { drafted; b=${1:-$(git rev-parse HEAD)}
  title=$(sed -n "s/^### Task $n: //p" "$plan" | head -n 1)
  files=$(ftoks | tr '\n' ' ' | sed 's/ $//')
  tidy=$(sh "$S/tidy-check.sh" --tsv "$root" | grep -c .)
  printf 'written: %s · phase: execute · part: task-%s · plan: %s\ntask: %s · title: %s\nbranch: %s · base: %s · tidy: %s\nfiles: %s\nverifier: pending · attempts: 0\n' \
    "$(now)" "$n" "$planpass" "$n" "$title" "$(git rev-parse --abbrev-ref HEAD)" "$b" "$tidy" "$files" > "$rec"; seal; }
amend_line() { [ -f "$amend" ] || echo '# PLAN amendments — scope granted during execute (PLAN.md itself is never edited)' > "$amend"
  printf -- '- %s · task %s · %s\n' "$(now)" "$n" "$1" >> "$amend"; }
fresh() { [ -f "$rec" ] && [ "$(sed -n 's/.* · plan: //p' "$rec" | head -n 1)" = "$planpass" ]; }
need() { fresh || { echo "ERROR: no current record for task $n (run: task-record.sh start $n)" >&2; fin; exit 2; }
  sealed || { echo "ERROR: $rec changed outside task-record.sh (receipt mismatch)" >&2; exit 2; }; }
case $cmd in
start)
  if [ -n "$nb" ]; then
    b=$(git rev-parse -q --verify "$nb^{commit}") || { echo "ERROR: --base $nb does not resolve to a commit" >&2; exit 2; }
    git merge-base --is-ancestor "$b" HEAD || { echo "ERROR: --base $nb is not an ancestor of HEAD" >&2; exit 2; }
    old=; [ -f "$rec" ] && old=$(sed -n 's/.* · base: \([^ ]*\).*/\1/p' "$rec" | head -n 1)
    uigate; drafted; amend_line "base := $b (was ${old:-none}) · $why"; write_start "$b"; echo "restarted: task $n (base $b, was ${old:-none})"; exit 0; fi
  if fresh; then sealed || { echo "ERROR: $rec changed outside task-record.sh (receipt mismatch)" >&2; exit 2; }
    echo "resume: task $n (base $(sed -n 's/.* · base: \([^ ]*\).*/\1/p' "$rec"))"; exit 0; fi
  uigate; write_start; echo "started: task $n (base $(git rev-parse HEAD))" ;;
verify)
  need; k=$(sed -n 's/^verifier: .*attempts: \([0-9]*\).*/\1/p' "$rec"); k=$(( ${k:-0} + 1 ))
  if [ -n "$hd" ]; then dc=$(sh "$S/drift-check.sh" "$n" --head "$hd" "$d" 2>&1); else dc=$(sh "$S/drift-check.sh" "$n" "$d" 2>&1); fi; rc=$?
  # exit 2 is a usage error (a bad --head, no record), not drift: nothing is written
  [ "$rc" -eq 2 ] && { printf '%s\n' "$dc" >&2; exit 2; }
  if [ "$rc" -ne 0 ]; then printf '%s\n' "$dc" > "$tmp.o"; put verifier "blocked by drift · attempts: $k"; put drift "" "$tmp.o"; seal
    printf '%s\n' "$dc"; echo "FAIL: task $n blocked by drift"; exit 1; fi
  a=$(printf '%s\n' "$dc" | sed -n 's/.*(\([0-9]*\) allowed by amendments).*/\1/p'); [ "${a:-0}" -eq 0 ] && drift=none || drift="allowed $a"
  # strict parse: a command counts only when its closing backtick is followed by →
  tline Verifier | mpart | grep -oE '`[^`]+` *→ *`?[^`,;|]*' > "$tmp"
  ok=1; res=; ran=0; : > "$tmp.o"
  while IFS= read -r m; do
    c=$(printf '%s\n' "$m" | sed 's/^`\([^`]*\)`.*/\1/'); x=$(printf '%s\n' "$m" | sed 's/^`[^`]*` *→ *//; s/`//g; s/ *$//')
    [ -n "$res" ] && sep='; ' || sep=' · '
    # placeholder = an unquoted `<word>` (`https://<domain>`); a quoted one is data (`grep -c '<loc>'`) and `< file` is
    # a redirect — both run. Erring toward running is the safe side: a wrong run fails, a wrong skip passes unseen.
    if printf '%s\n' "$c" | sed "s/'[^']*'//g; s/\"[^\"]*\"//g" | grep -qE '<[A-Za-z][A-Za-z0-9_-]*>'; then
      res="$res$sep\`$c\` → skipped: placeholder"; continue; fi
    # trust boundary: $c is a Verifier command from PLAN.md, which is hash-locked (check-pass.sh above) — by design,
    # not sanitized here; whoever can edit an unsealed PLAN can already run arbitrary commands via this path
    ran=$((ran + 1)); sh -c "$c" > "$tmp.run" 2>&1 < /dev/null; r=$?; last=$(grep . "$tmp.run" | tail -n 1)
    good=0; [ "$r" -eq 0 ] && good=1
    case $x in ''|*[!0-9]*) ;; *) [ "$last" = "$x" ] || good=0 ;; esac
    [ "$good" -eq 1 ] || ok=0
    res="$res${sep}exit $r · \`$c\` → $last"; { echo "\$ $c   (exit $r)"; tail -n 20 "$tmp.run"; } >> "$tmp.o"; rm -f "$tmp.run"
  done < "$tmp"
  # 0 commands extracted from a mechanical Verifier is "not verified", never a pass (field test: 14 vacuous passes)
  if [ ! -s "$tmp" ] && tline Verifier | grep -qE '^\*\*Verifier:\*\* *mechanical:'; then ok=0
    res=" · no backticked \`command\` → expected pair in a mechanical Verifier: nothing ran (fix the PLAN and re-run finalize-plan)"; fi
  # every extracted command a <placeholder>: nothing ran either (finalize-audit's rule: at least one command actually ran)
  if [ -s "$tmp" ] && [ "$ran" -eq 0 ]; then ok=0; res="$res · every command is a <placeholder>: nothing ran (not verified)"; fi
  [ "$ok" -eq 1 ] && v=pass || v=fail
  [ -n "$hd" ] && h=$(git rev-parse "$hd^{commit}") || h=$(git rev-parse HEAD)
  put verifier "$v · attempts: $k${res}"; put head "$h"; put drift "$drift"; put tidy-delta 0; put output "" "$tmp.o"; seal
  echo "verifier: $v · attempts: $k${res}"; [ "$ok" -eq 1 ] ;;
manual)
  need; t=$3; [ -n "$t" ] && [ "$t" != none ] || { echo "ERROR: manual needs the user's observation (what, where, when)" >&2; exit 2; }
  put manual "$t · by user · $(date +%Y-%m-%d)"; seal; echo "manual: recorded for task $n" ;;
note)
  need; t=$3; [ -n "$t" ] || { echo "ERROR: note needs a text" >&2; exit 2; }; reason "$t"
  printf 'note: %s · by controller · %s\n' "$t" "$(date +%Y-%m-%d)" >> "$rec"; seal; echo "note: recorded for task $n" ;;
ponytail)
  need; grep -q '^verifier: pending' "$rec" && { echo "ERROR: task $n verifier is pending: run verify first (task-record.sh verify $n), then ponytail" >&2; exit 2; }
  t=$3; fmt="'none' or '<k> findings, <a> applied, <d> deferred, <r> rejected: <one line>' (a+d+r=k)"
  if [ "$t" != none ]; then
    s=$(printf '%s\n' "$t" | sed -n 's/^\([0-9][0-9]*\) findings, \([0-9][0-9]*\) applied, \([0-9][0-9]*\) deferred, \([0-9][0-9]*\) rejected: *[^ ].*/\1 \2 \3 \4/p' |
      awk 'NR == 1 { print ($2 + $3 + $4 == $1) ? "ok" : $2 " applied + " $3 " deferred + " $4 " rejected != " $1 " findings" }')
    [ -n "$s" ] || { echo "ERROR: expected $fmt; got: $t" >&2; exit 2; }
    [ "$s" = ok ] || { echo "ERROR: $s; expected $fmt" >&2; exit 2; }
  fi
  put ponytail-review "$t"; put head "$(git rev-parse HEAD)"; seal; echo "ponytail-review: recorded for task $n" ;;
allow)
  need; p=$3; why=$4; [ -n "$p" ] && [ -n "$why" ] || { echo "ERROR: allow needs <path> and a reason" >&2; exit 2; }
  reason "$why"
  # this path is later matched as a drift-check pattern (eval'd as a case arm) — keep it relative, traversal-free,
  # and inside the same safe character set drift-check enforces, before it is written anywhere
  case $p in *[!]A-Za-z0-9._/@+*?[-]*) echo "ERROR: unsafe path $p (unsafe characters)" >&2; exit 2 ;; esac
  case $p in /*|..|../*|*/..|*/../*) echo "ERROR: unsafe path $p (must be relative, no .. segment)" >&2; exit 2 ;; esac
  amend_line "files += \`$p\` · $why"
  put files "$(sed -n 's/^files: *//p' "$rec") $p"; seal; echo "allowed: task $n += $p" ;;
skip)
  t=$3; [ -n "$t" ] || { echo "ERROR: skip needs a reason" >&2; exit 2; }; reason "$t"
  fresh || write_start; need
  put verifier "skipped — $t"; put head "$(git rev-parse HEAD)"; seal; echo "skipped: task $n — $t" ;;
defer)
  t=$3; [ -n "$t" ] || { echo "ERROR: defer needs the missing credential" >&2; exit 2; }; reason "$t"
  fresh || write_start; need
  put verifier "deferred — $t"; put head "$(git rev-parse HEAD)"; seal; echo "deferred: task $n — $t" ;;
esac
