#!/bin/sh
# Read-only scope gate for execute/review. Usage: sh drift-check.sh <n> [.v2p] | sh drift-check.sh --branch [.v2p]
# Exit 0 clean · 1 drift · 2 usage/no record. Task mode: every path changed since the task's recorded base
# (committed or not, plus untracked) must match the PLAN task's **Files:** tokens, a PLAN-AMENDMENTS.md line
# for that task, `.v2p/*` or a lockfile. Branch mode: same against the union of all tasks (review).
# Also DRIFT branch (checkout switched since start), DRIFT base (rebased), DRIFT tidy (new tidy-check rows).
# Matcher: string equality first (so `app/[locale]/page.tsx` matches itself), then glob via eval (zsh matches
# a case pattern held in a variable literally). `*` crosses `/`: `components/*.tsx` also allows `components/x/y.tsx` (accepted).
skill=$(cd "$(dirname "$0")/.." && pwd -P)
case $1 in --branch) n=; mode=branch ;; ''|*[!0-9]*) echo "usage: drift-check.sh <n>|--branch [.v2p]" >&2; exit 2 ;; *) n=$1; mode=task ;; esac
d=${2:-.v2p}; [ -d "$d" ] || { echo "ERROR: $d not found" >&2; exit 2; }
d=$(cd "$d" && pwd -P); root=$(dirname "$d"); cd "$root" || exit 2
plan=$d/PLAN.md; amend=$d/PLAN-AMENDMENTS.md; [ -f "$plan" ] || { echo "ERROR: $plan missing" >&2; exit 2; }
field() { sed -n "s/.*$1 \([^ ]*\).*/\1/p" | head -n 1; }
if [ "$mode" = task ]; then
  rec=$d/work/execute-task-$n.md; [ -f "$rec" ] || { echo "ERROR: no record $rec (run task-record.sh start $n)" >&2; exit 2; }
  branch=$(grep '^branch: ' "$rec" | field 'branch:'); base=$(grep '^branch: ' "$rec" | field 'base:'); tidy0=$(grep '^branch: ' "$rec" | field 'tidy:')
  tasks=$n
else
  if [ -f "$d/EXECUTE.md" ] && grep -q '^checked: tasks' "$d/EXECUTE.md"; then c=$(grep '^checked: ' "$d/EXECUTE.md"); branch=$(printf '%s\n' "$c" | field ' branch'); base=$(printf '%s\n' "$c" | field ' base')
  else first=$(find "$d/work" -name 'execute-task-*.md' 2>/dev/null | sed 's/.*execute-task-\([0-9]*\)\.md/\1/' | sort -n | head -n 1)
    [ -n "$first" ] || { echo "ERROR: no EXECUTE.md checked: line and no task record" >&2; exit 2; }
    l=$(grep '^branch: ' "$d/work/execute-task-$first.md"); branch=$(printf '%s\n' "$l" | field 'branch:'); base=$(printf '%s\n' "$l" | field 'base:'); fi
  tasks=$(grep -o '^### Task [0-9]*' "$plan" | awk '{print $3}')
fi
[ -n "$base" ] && [ -n "$branch" ] || { echo "ERROR: no base/branch recorded" >&2; exit 2; }
tmp=${TMPDIR:-/tmp}/dc.$$; trap 'rm -f "$tmp" "$tmp.a" "$tmp.b"' EXIT; drift=0
now=$(git rev-parse --abbrev-ref HEAD)
[ "$now" = "$branch" ] || { echo "DRIFT branch $now (recorded $branch)"; drift=1; }
git merge-base --is-ancestor "$base" HEAD 2>/dev/null || { echo "DRIFT base $base not an ancestor of HEAD (rebased?)"; drift=1; }
# allowed = Files tokens (cut at **Interfaces:**; first word; <…> → *) + amendments for the task(s)
: > "$tmp.a"; a=0; printf '%s\n' "$tasks" > "$tmp"
while IFS= read -r t; do
  awk -v n="$t" '$0 ~ "^### Task "n":" {f=1;next} f && /^### / {exit} f && /^\*\*Files:\*\*/ {sub(/\*\*Interfaces:\*\*.*/,""); print; exit}' "$plan" |
    grep -o '`[^`]*`' | tr -d '`' | sed 's/ .*//; s/<[^>]*>/*/g' >> "$tmp.a"
  if [ -f "$amend" ]; then k=$(grep -c "· task $t · files += " "$amend"); a=$((a + k))
    grep "· task $t · files += " "$amend" | sed 's/.*files += `\([^`]*\)`.*/\1/' >> "$tmp.a"; fi
done < "$tmp"
# brace shorthand `src/{A,B}.tsx` → one pattern per alternative, any number of non-nested groups per token.
# Pure string splitting in awk (no eval); the results still go through the allowlist below. Nested or unclosed → fail closed.
: > "$tmp.b"
awk -v out="$tmp.b" '
function ex(s,   i, j, pre, rest, body, post, n, k, alt) {
  i = index(s, "{"); if (!i) { print s > out; return }
  pre = substr(s, 1, i - 1); rest = substr(s, i + 1); j = index(rest, "}")
  if (!j) { print "DRIFT pattern " $0 " (unclosed brace)"; exit 1 }
  body = substr(rest, 1, j - 1); post = substr(rest, j + 1)
  if (index(body, "{")) { print "DRIFT pattern " $0 " (nested braces)"; exit 1 }
  n = split(body, alt, ","); for (k = 1; k <= n; k++) ex(pre alt[k] post)
}
{ ex($0) }' "$tmp.a" || exit 1
mv "$tmp.b" "$tmp.a"
# fail closed: a pattern is later held in a variable and eval'd as a case arm (match, below) — refuse
# anything outside this allowlist before that eval ever sees it, rather than risk shell injection.
while IFS= read -r p; do
  [ -n "$p" ] || continue
  case $p in *[!]A-Za-z0-9._/@+*?[-]*) echo "DRIFT pattern $p (unsafe characters)"; exit 1 ;; esac
done < "$tmp.a"
match() { f=$1; p=$2; [ "$f" = "$p" ] && return 0; case $p in *\**) ;; *) return 1;; esac
  e=$(printf '%s' "$p" | sed 's/\[/\\[/g; s/\]/\\]/g'); eval "case \"\$f\" in $e) return 0;; esac"; return 1; }
{ git diff --name-only --relative --no-renames "$base" -- . 2>/dev/null; git ls-files --others --exclude-standard; } | sort -u > "$tmp"
k=0
while IFS= read -r f; do
  [ -n "$f" ] || continue; k=$((k + 1))
  case $f in .v2p/*) continue ;; esac
  case ${f##*/} in package-lock.json|pnpm-lock.yaml|yarn.lock|bun.lockb|bun.lock|Cargo.lock|poetry.lock|uv.lock|Gemfile.lock|composer.lock|Podfile.lock|go.sum) continue ;; esac
  ok=0
  while IFS= read -r p; do
    [ -n "$p" ] || continue
    case $p in */) case $f in "$p"*) ok=1; break ;; esac ;; esac
    match "$f" "$p" && { ok=1; break; }
  done < "$tmp.a"
  [ "$ok" -eq 1 ] || { echo "DRIFT file $f"; drift=1; }
done < "$tmp"
if [ "$mode" = task ] && [ -n "$tidy0" ]; then
  rows=$(sh "$skill/scripts/tidy-check.sh" --tsv "$root" | grep -c .)
  [ "$rows" -gt "$tidy0" ] && { echo "DRIFT tidy +$((rows - tidy0))"; sh "$skill/scripts/tidy-check.sh" --tsv "$root" | sed 's/^/  /'; drift=1; }
fi
[ "$drift" -eq 0 ] || exit 1
if [ "$mode" = task ]; then echo "OK: $k changed paths within Task $n scope ($a allowed by amendments)"
else echo "OK: $k changed paths within the union of PLAN task scopes ($a allowed by amendments)"; fi
