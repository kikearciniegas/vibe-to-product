#!/bin/sh
# Promote .v2p/PLAN.draft.md to .v2p/PLAN.md only if every task has a Verifier line, §4 has one row
# per checklist item of the BRIEF §9 standards files, §2's total fits the BRIEF budget (or carries the
# user's override), no `---` rule exists, `## Architecture` and `## Threat Model` exist, and a landing
# plan has `## 4b`, §6 has an `Order:` line naming only existing tasks, Verifier lines pass the lint below, and Interfaces paths are in some Files line up to that task.# Usage: sh finalize-plan.sh [.v2p dir]
# Run it against the real repo tree (.v2p in the repo root): Modify: paths are checked relative to the repo root, so a
# dry-run in an empty scratch dir false-fails them.
skill=$(cd "$(dirname "$0")/.." && pwd -P); d=${1:-.v2p}; draft="$d/PLAN.draft.md"; out="$d/PLAN.md"; fail=0
[ -f "$draft" ] || { echo "FAIL: $draft missing"; exit 1; }
[ -f "$d/BRIEF.md" ] || { echo "FAIL: $d/BRIEF.md missing"; exit 1; }
tasks=$(grep -c '^### Task' "$draft"); ver=$(grep -c '^\*\*Verifier:\*\*' "$draft")
[ "$tasks" -gt 0 ] && [ "$tasks" -eq "$ver" ] || { echo "FAIL: tasks $tasks / verifiers $ver"; fail=1; }
expected=0; tmp=${TMPDIR:-/tmp}/fp.$$; trap 'rm -f "$tmp" "$tmp.q" "$tmp.qc"' EXIT
awk '/^## 9/{f=1;next} /^## /{f=0} f' "$d/BRIEF.md" | grep -oE '[a-z-]+\.md' | sort -u > "$tmp"
while IFS= read -r n; do sf="$skill/references/standards/$n"; [ -f "$sf" ] && expected=$((expected + $(grep -c '^- \[ \]' "$sf"))); done < "$tmp"
rows=$(awk '/^## 4\./{f=1;next} /^## /{f=0} f && /^\| / && !/^\| item/ && !/^\|---/' "$draft" | grep -c .)
[ "$expected" -gt 0 ] && [ "$rows" -eq "$expected" ] || { echo "FAIL: §4 rows $rows/$expected"; fail=1; }
grep -q '^Next: /v2p execute' "$draft" || { echo "FAIL: no 'Next: /v2p execute' line"; fail=1; }
# Budget: BRIEF "Budget/month: <v>" (first number; none/missing → skip) vs PLAN §2 "Total monthly at launch: $<n>".
num() { sed -n 's/^[^0-9]*\([0-9][0-9,]*\(\.[0-9][0-9]*\)\{0,1\}\).*/\1/p' | tr -d ,; }
budget=$(grep -m1 -o 'Budget/month:[^·]*' "$d/BRIEF.md" | sed 's|^Budget/month:||' | num)
total=$(awk '/^## 2\./{f=1;next} /^## /{f=0} f && /^Total monthly at launch: \$[0-9]/' "$draft" | head -n 1 | num)
if [ -z "$total" ]; then echo "FAIL: §2 has no 'Total monthly at launch: \$<n>' line"; fail=1
elif [ -z "$budget" ]; then echo "WARN: BRIEF Budget/month missing or not a number; budget check skipped"
elif awk -v t="$total" -v b="$budget" 'BEGIN { exit !(t > b) }' &&
  ! grep -qE '^Over budget approved by user: *[^ ]' "$draft"; then
  echo "FAIL: budget: total \$$total > BRIEF Budget/month \$$budget (no 'Over budget approved by user: <reason>' line)"; fail=1
fi
hr=$(grep -n '^---$' "$draft" | cut -d: -f1 | tr '\n' ' ')
[ -z "$hr" ] || { echo "FAIL: '---' rule on lines ${hr% } (use ***)"; fail=1; }
if ! grep -q '^## Architecture' "$draft"; then echo "FAIL: no '## Architecture' section"; fail=1
# the diagram is Mermaid source in the section itself: it renders on GitHub and survives the portable pack
elif ! awk '/^## Architecture/ { a = 1; next } /^## / { a = 0 } a && /^```mermaid/ { m = 1 } END { exit !m }' "$draft"; then
  echo "FAIL: '## Architecture' has no \`\`\`mermaid block"; fail=1; fi
grep -q '^## Threat Model' "$draft" || { echo "FAIL: no '## Threat Model' section"; fail=1; }
# §6 Order: execute runs the tasks in that order: a §6 line holding `Order:` that names every `### Task <n>` number and no other
order=$(awk '/^## 6/ { f = 1; next } /^## / { f = 0 } f && /(^|[^A-Za-z])Order:/ { sub(/.*Order:/, ""); print "x" $0; exit }' "$draft")
if [ -z "$order" ]; then echo "FAIL: §6 has no 'Order:' line (task numbers in run order)"; fail=1
elif ! printf '%s\n' "$order" | grep -q '[0-9]'; then echo "FAIL: §6 Order: names no task number"; fail=1
else for n in $(printf '%s\n' "$order" | grep -oE '[0-9]+' | sort -un); do
  grep -qE "^### Task $n([^0-9]|\$)" "$draft" || { echo "FAIL: §6 Order: names task $n, not a task in §5"; fail=1; }; done
  for n in $(sed -n 's/^### Task \([0-9][0-9]*\).*/\1/p' "$draft"); do
    printf '%s\n' "$order" | grep -qE "(^|[^0-9])$n([^0-9]|\$)" || { echo "FAIL: §6 Order: leaves out task $n"; fail=1; }; done
fi
if grep -qE '^- Profile: *landing([^a-z-]|$)' "$d/BRIEF.md" && ! grep -q '^## 4b' "$draft"; then
  echo "FAIL: profile landing and no '## 4b' section"; fail=1
fi
# Provenance (field test V3: PLAN recorded "Q2"/"Q5" as owner decisions nobody made): every `Qn` word the draft cites
# is a label in BRIEF §10's item column. `Qn 20xx` (a quarter) and `SCAVENGE Qn` are not decision labels.
# ponytail: existence only; a real label cited for the wrong decision still passes (read the row if that recurs).
awk '/^## 10/{f=1;next} /^## /{f=0} f && /^\| /' "$d/BRIEF.md" | cut -d'|' -f2 | tr -c 'A-Za-z0-9_\n' '\n' | grep -xE 'Q[0-9]+' > "$tmp.q"
sed -E 's/SCAVENGE Q[0-9]+//g; s/Q[0-9]+ 20[0-9][0-9]//g' "$draft" | tr -c 'A-Za-z0-9_\n' '\n' | grep -xE 'Q[0-9]+' | sort -u | grep -vxF -f "$tmp.q" > "$tmp.qc"
while IFS= read -r q; do echo "FAIL: PLAN cites $q, not a label in BRIEF §10 (cite a real BRIEF label or BRIEF §n:line, or write inferred)"; fail=1; done < "$tmp.qc"
# Verifier lint (backticked text of the mechanical part, as execute extracts it; single-quoted strings removed): a mechanical Verifier with no backticked `cmd` → x
# pair in its mechanical part (a pair in the manual: part is never run) (field test: 14 of 14 unbackticked, nothing ever ran and every record read pass); raw `wc -l` in a comparison (macOS pads it),
# a bare `&` in a mechanical verifier (backgrounds the whole && chain), `curl` without -m/--max-time; and, on the raw
# line, a backtick inside a command (live Task 19 `grep -c '^| \`src/'` was cut there and ran a fragment): each text
# before a `→`, minus a backticked expected of the previous command, holds an even number of backticks (prose pairs
# in a manual part are fine; an odd count makes the parser open the command at the inner backtick). Two inner
# backticks keep the count even and pass: the rule catches the live shape, not every one.
# A table row (`^|`) with `\|` inside a backticked span fails (field test V30: the copied command kept the backslash,
# a literal pipe in ERE, and silently printed 0): commands go in fenced blocks.
# Files is one line (field test V27: bullet lists under it were never read): empty after the label, or followed by a
# `- ` line that is not a `- [ ]` step, fails.
# Files completeness: a backticked Interfaces path (has `/` and an extension; not a URL or a route) must appear
# in the Files of this task or an earlier one (`{a,b}` and `*` in Files are expanded / matched).
# Modify paths (live Task 17 wrote bare `globals.css` for src/app/globals.css): a token after `Modify`, up to the next
# `Create`/`;`/end, must exist in the repo now or be matched by a Create of Tasks 1-t (any Files text outside a Modify
# segment counts as Create). A code token is skipped: a character drift-check would ignore, or neither `/` nor an
# extension (`withSentryConfig`, `legal.*`). Braces expand; a glob must match one existing or created path.
# WARN only (field test V4: a grep for a renamed identifier passed while the behaviour broke): a task whose Files name a code file
# (.ts .tsx .js .jsx .mjs .cjs .py .go .rs .rb .sh .swift .kt) and whose mechanical Verifier names no runner word
# (npm pnpm yarn bun bunx npx node deno python python3 pytest go cargo make sh bash curl vitest jest playwright).
# ponytail: word list, not a parse; a grep wrapped in `sh -c` passes it.
lint=$(awk -v q="'" '
  function bt(s,   o) { o = ""; while (match(s, /`[^`]*`/)) { o = o substr(s, RSTART + 1, RLENGTH - 2) "\n"; s = substr(s, RSTART + RLENGTH) } return o }
  function expand(t, arr,   pre, mid, post, k, i, p) {
    if (!match(t, /\{[^{}]*\}/)) { arr[++arr[0]] = t; return }
    pre = substr(t, 1, RSTART - 1); mid = substr(t, RSTART + 1, RLENGTH - 2); post = substr(t, RSTART + RLENGTH)
    k = split(mid, p, ","); for (i = 1; i <= k; i++) expand(pre p[i] post, arr) }
  function g2re(g,   i, c, r) { r = "^"; for (i = 1; i <= length(g); i++) { c = substr(g, i, 1)
      if (c == "*") r = r ".*"; else if (c == "?") r = r "."; else if (index("\\^$.[]|()+{}", c)) r = r "\\" c; else r = r c }
    return r "$" }
  function addfiles(s,   k, i, tok, a, j) { k = split(bt(s), tok, "\n")
    for (i = 1; i <= k; i++) { sub(/ .*/, "", tok[i]); gsub(/<[^>]*>/, "*", tok[i]); if (tok[i] == "") continue
      delete a; a[0] = 0; expand(tok[i], a); for (j = 1; j <= a[0]; j++) fre[++nf] = g2re(a[j]) } }
  function addcreated(s,   k, i, tok, a, j) { k = split(bt(s), tok, "\n")
    for (i = 1; i <= k; i++) { sub(/ .*/, "", tok[i]); gsub(/<[^>]*>/, "*", tok[i]); if (tok[i] == "") continue
      delete a; a[0] = 0; expand(tok[i], a); for (j = 1; j <= a[0]; j++) { cl[++nc] = a[j]; cre[nc] = g2re(a[j]) } } }
  function modify(f,   m, rest, k, i, tok, a, j, x, e, ok) { m = ""; rest = ""
    while (match(f, /Modify/)) { rest = rest substr(f, 1, RSTART - 1); f = substr(f, RSTART + RLENGTH)
      if (match(f, /Create|;/)) { m = m substr(f, 1, RSTART - 1) " "; f = substr(f, RSTART) } else { m = m f; f = "" } }
    addcreated(rest f); k = split(bt(m), tok, "\n")
    for (i = 1; i <= k; i++) { sub(/ .*/, "", tok[i]); gsub(/<[^>]*>/, "*", tok[i]); x = tok[i]; gsub(/[A-Za-z0-9._\/@+*?{},-]/, "", x); gsub(/\[|\]/, "", x)
      if (tok[i] == "" || x != "" || tok[i] !~ /\/|\.[A-Za-z0-9]+$/) continue
      delete a; a[0] = 0; expand(tok[i], a)
      for (j = 1; j <= a[0]; j++) { ok = 0; e = g2re(a[j])
        for (x = 1; x <= nc; x++) if (a[j] ~ cre[x] || (a[j] ~ /[*?]/ && cl[x] ~ e)) { ok = 1; break }
        if (!ok) print "MODIFY\t" t "\t" a[j] } } }
  function flush(   i, j, ok) { if (code && vm && !vrun) print "WARN: Task " t " Verifier: Files has code and the mechanical Verifier only greps/tests files; add the test suite or a run command that exercises the behaviour"
    code = 0; vm = 0; vrun = 0
    for (i = 1; i <= ni; i++) { ok = 0
      for (j = 1; j <= nf; j++) if (ip[i] ~ fre[j]) { ok = 1; break }
      if (!ok) print "FAIL: Task " t " Interfaces names `" ip[i] "`, absent from the Files of Tasks 1-" t }
    ni = 0 }
  function addiface(s,   k, i, tok, a, j) { k = split(bt(s), tok, "\n")
    for (i = 1; i <= k; i++) { if (tok[i] ~ /[ \t<>]/ || tok[i] !~ /\// || tok[i] ~ /:\/\// || tok[i] ~ /^\//) continue
      delete a; a[0] = 0; expand(tok[i], a)
      for (j = 1; j <= a[0]; j++) if (a[j] ~ /\/[^\/]*\.[A-Za-z0-9]+$/) ip[++ni] = a[j] } }
  /^### Task / { flush(); t = $3; sub(/:$/, "", t) }
  /^## / { flush() }
  /^\|/ { c = $0; while (match(c, /`[^`]*`/)) { if (index(substr(c, RSTART, RLENGTH), "\\|")) {
        print "FAIL: line " NR ": table row has `\\|` inside backticks (a copied command keeps the backslash: put commands in a fenced block)"; break }
      c = substr(c, RSTART + RLENGTH) } }
  fl && NR == fl + 1 && /^- / && !/^- \[/ { print "FAIL: Task " t " Files: a bullet list under **Files:** is not read (one line: Create `a`, `b`; Modify `c`)" }
  /^\*\*Files:\*\*/ { fl = NR; f = $0; i = index(f, "**Interfaces:**"); if (i) { addiface(substr(f, i)); f = substr(f, 1, i - 1) } addfiles(f); modify(f)
    k = split(bt(f), tok, "\n"); for (i = 1; i <= k; i++) if (tok[i] ~ /\.(ts|tsx|js|jsx|mjs|cjs|py|go|rs|rb|sh|swift|kt)$/) code = 1
    e = f; sub(/^\*\*Files:\*\*[ \t]*/, "", e); if (e == "") print "FAIL: Task " t " Files: empty after the label (one line: Create `a`; Modify `b`; or none)" }
  /^\*\*Interfaces:\*\*/ { addiface($0) }
  /^\*\*Verifier:\*\*/ { mp = $0; sub(/manual:.*mechanical:/, "mechanical:", mp); sub(/manual:.*/, "", mp)
    mech = (mp ~ /mechanical:/)
    s = bt(mp); if (s == "" && !mech) s = mp; gsub(q "[^" q "]*" q, "", s); r = ""
    vm = mech; if (s ~ /(^|[^A-Za-z0-9_.\/-])(npm|pnpm|yarn|bun|bunx|npx|node|deno|python3?|pytest|go|cargo|make|sh|bash|curl|vitest|jest|playwright)( |$)/) vrun = 1
    if (mech && mp !~ /`[^`]+` *→/) r = r "; mechanical with no backticked `command` → expected pair (execute, review and deploy would run nothing)"
    c = s; gsub(/wc -l *\| *tr -d/, "", c)
    if (c ~ /wc -l/ && c ~ /\$\(|(^|[^A-Za-z])test |\[ /) r = r "; raw wc -l in a comparison (macOS pads it: use grep -c, or pipe to tr -d \" \")"
    if (mech) { c = s; gsub(/&&|>&|&>/, "", c)
      if (c ~ /&/) r = r "; bare & backgrounds the chain (start servers from the test runner or a wait-for-port script)" }
    c = s; while (match(c, /(^|[^A-Za-z0-9_-])curl( |$)/)) { c = substr(c, RSTART + RLENGTH); a1 = c; sub(/[|;&)\n].*/, "", a1)
      if (a1 !~ /(^| )-[A-Za-z]*m( |[0-9]|$)|--max-time/) { r = r "; curl without -m/--max-time"; break } }
    k = split($0, sg, "→"); for (i = 1; i < k; i++) { c = sg[i]; if (i > 1) sub(/^ *`[^`]*`/, "", c)
      if (gsub(/`/, "", c) % 2) { r = r "; a Verifier command cannot contain a backtick (the parser cuts there)"; break } }
    if (r != "") print "FAIL: Task " t " Verifier: " substr(r, 3) }
  END { flush() }' "$draft")
mods=$(printf '%s\n' "$lint" | sed -n 's/^MODIFY	//p'); printf '%s\n' "$lint" | grep '^WARN: '; lint=$(printf '%s\n' "$lint" | grep -v -e '^MODIFY	' -e '^WARN: ')
[ -z "$lint" ] || { printf '%s\n' "$lint"; fail=1; }
root=$(dirname "$d")
mf=$(printf '%s\n' "$mods" | while IFS='	' read -r t p; do [ -n "$p" ] || continue
  case $p in (*[*?]*) [ -n "$(find "$root" \( -name node_modules -o -name .git \) -prune -o -path "$root/$p" -print | head -n 1)" ] ;; (*) [ -e "$root/$p" ] ;; esac ||
    echo "FAIL: Task $t Files: Modify \`$p\` is neither in the repo nor in a Create of Tasks 1-$t"; done)
[ -z "$mf" ] || { printf '%s\n' "$mf"; fail=1; }
# WARN only (field test V5): a regular root DESIGN.md is the project's own design doc (adopt; brand kept it, its guards may
# read it); a task whose Files name it would overwrite it. A root symlink is v2p's link to .v2p/DESIGN.md: no WARN.
[ -f "$root/DESIGN.md" ] && [ ! -L "$root/DESIGN.md" ] && awk '/^### Task / { t = $3; sub(/:$/, "", t) }
  /^\*\*Files:\*\*/ && /`(\.\/)?DESIGN\.md`/ { print "WARN: Task " t " Files: `DESIGN.md` is the project'"'"'s own design doc (kept by brand); edit it only on purpose, tokens live in .v2p/DESIGN.md" }' "$draft"
[ "$fail" -eq 0 ] || { echo "FAIL: $out not written"; exit 1; }
mv "$draft" "$out"
# Receipt: execute accepts PLAN.md only if its hash matches this file.
shasum -a 256 "$out" | cut -d" " -f1 > "$d/.plan-pass"
rm -f "$d"/work/mapping-*
echo "PASS: $tasks tasks, $rows standards rows, total \$$total/month -> $out"
