#!/bin/sh
# PreToolUse guard: .v2p final handoff files (SCAVENGE … REVIEW, DEPLOY) are produced only by scripts/finalize-*.sh (mv from a .draft.md);
# .v2p/PLAN-AMENDMENTS.md only by scripts/task-record.sh allow / start --base; execute records (.v2p/work/execute-task-*.md) and
# every seal (.v2p/.*-pass, .v2p/work/.*-pass) only by the scripts; .v2p/DESIGN.md only by finalize-brand.sh, and a root
# DESIGN.md that is a symlink (to it) is not written through. A script that refuses is a stop-and-ask, not a workaround.
# stdin: hook JSON; exit 2 = block (stderr goes back to the model). Also blocks shell writes whose TARGET is one of
# those files (> >> >| destination, tee operand, last cp/mv/install operand, sed -i operand, dd of=); a mention (a
# source, a quoted string, a heredoc body, a comment) passes. Running the scripts, reads and git add/commit pass.
# Known gaps: sed JSON extraction of Write/Edit file_path breaks on paths containing '"'; Bash writes pass when the
# target is built at run time (f=$(…), for f in …, export f=…; a plain f=… earlier in the command IS expanded), sits in
# a directory operand (cp PLAN.md .v2p/, cp -t .v2p x), or goes through another writer (python -c, perl -e, ln,
# touch, rsync, truncate); a non-option word after sudo/xargs is taken as the command (sudo -u x cp … passes).
# Whether subagent tool calls fire this hook is unverified.
# NOT installed by v2p: installing is the user's decision.
in=$(cat)
tool=$(printf '%s' "$in" | sed -n 's/.*"tool_name"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/p' | head -1)
case $tool in
  Write|Edit|MultiEdit)
    f=$(printf '%s' "$in" | sed -n 's/.*"file_path"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/p' | head -1)
    case $f in */.v2p/SCAVENGE.md|*/.v2p/AUDIT.md|*/.v2p/PLAN.md|*/.v2p/EXECUTE.md|*/.v2p/REVIEW.md|*/.v2p/PLAN-AMENDMENTS.md|*/.v2p/DESIGN.md|*/.v2p/DEPLOY.md|.v2p/SCAVENGE.md|.v2p/AUDIT.md|.v2p/PLAN.md|.v2p/EXECUTE.md|.v2p/REVIEW.md|.v2p/PLAN-AMENDMENTS.md|.v2p/DESIGN.md|.v2p/DEPLOY.md)
      echo "v2p: $f is written only by its script (finalize-*.sh; PLAN-AMENDMENTS.md by task-record.sh allow / start --base). Write ${f%.md}.draft.md and run the script." >&2; exit 2 ;;
    */.v2p/work/execute-task-*.md|.v2p/work/execute-task-*.md|*/.v2p/.*-pass|.v2p/.*-pass|*/.v2p/work/.*-pass|.v2p/work/.*-pass)
      echo "v2p: $f is written only by task-record.sh / finalize-*.sh. If a script refused, stop and show the user its output; never write or seal a record by hand." >&2; exit 2 ;;
    */DESIGN.md|DESIGN.md) [ -L "$f" ] && { echo "v2p: $f is a symlink to .v2p/DESIGN.md, written only by finalize-brand.sh (a design skill's offer to write DESIGN.md must be declined)." >&2; exit 2; } ;; esac ;;
  Bash) # decode the JSON "command" string, split it like sh (quotes, ; & | newline, $( ) and `, heredoc bodies skipped),
    # then test only write TARGETS: > >> >| destinations, tee operands, the last cp/mv/install operand, sed -i operands,
    # dd of=; sh/bash/zsh -c and eval strings are re-scanned; $f/${f} expand from earlier f=... words.
    printf '%s\n' "$in" | awk '
function hex(h,  i, v) { v = 0; for (i = 1; i <= 4; i++) v = v * 16 + index("0123456789abcdef", tolower(substr(h, i, 1))) - 1; return v }
function flush() { if (inw) { if (hdw) { HD[++nhd] = w; HS[nhd] = hds; hdw = 0 } else T[++n] = "w" w } w = ""; inw = 0 }
function tok(t) { flush(); T[++n] = t }
function pop() { st = substr(st, 1, length(st) - 1) }
function lex(c,  L, i, ch, nx, top, k, ln, d) {
  n = 0; st = ""; w = ""; inw = 0; nhd = 0; hdw = 0; L = split(c, C, ""); C[L + 1] = ""
  for (i = 1; i <= L; i++) {
    ch = C[i]; nx = C[i + 1]; top = substr(st, length(st))
    if (top == SQ) { if (ch == SQ) pop(); else w = w ch; continue }
    if (ch == "\\") { i++; if (nx == "\n") continue; if (top == "\"" && index("$`\"\\", nx) == 0) w = w ch; w = w nx; inw = 1; continue }
    if (top == "\"") {
      if (ch == "\"") pop(); else if (ch == "$" && nx == "(") { tok("s"); st = st "("; i++ } else if (ch == "`") { tok("s"); st = st "`" } else w = w ch
      continue }
    if (ch == SQ || ch == "\"") { st = st ch; inw = 1 }
    else if (ch == " " || ch == "\t") flush()
    else if (ch == "#" && !inw) { while (i < L && C[i + 1] != "\n") i++ }
    else if (ch == "\n") { tok("s")
      for (k = 1; k <= nhd; k++) while (i < L) { ln = ""; for (d = i + 1; d <= L && C[d] != "\n"; d++) ln = ln C[d]
        i = d; if (HS[k]) sub(/^\t+/, "", ln); if (ln == HD[k]) break }
      nhd = 0 }
    else if (ch == ";" || ch == "&" || ch == "|") tok("s")
    else if (ch == "$" && nx == "(") { tok("s"); st = st "("; i++ }
    else if (ch == "(") { tok("s"); st = st "(" }
    else if (ch == ")") { tok("s"); if (top == "(") pop() }
    else if (ch == "`") { tok("s"); if (top == "`") pop(); else st = st "`" }
    else if (ch == ">" || ch == "<") { if (w ~ /^[0-9]+$/) { w = ""; inw = 0 }
      if (ch == "<" && nx == "<") { i++; if (C[i + 1] == "<") { i++; tok("i") }
        else { hds = C[i + 1] == "-"; i += hds; flush(); hdw = 1 } }
      else { if (nx == ">" || nx == "|" || nx == "&") i++; tok(ch == ">" ? "r" : "i") } }
    else { w = w ch; inw = 1 } }
  flush() }
function chk(x,  v, l) {
  for (v in V) if (match(x, "\\$(\\{" v "\\}|" v "([^A-Za-z0-9_]|$))")) { l = RLENGTH; if (substr(x, RSTART + l - 1, 1) ~ /[^A-Za-z0-9_}]/) l--
    x = substr(x, 1, RSTART - 1) V[v] substr(x, RSTART + l) }
  if (x ~ G) hit = 1 }
function run(c,  j, t, x, A, na, k, m, nm) {
  lex(c); na = 0
  for (j = 1; j <= n + 1; j++) { t = j <= n ? T[j] : "s"
    if (t == "r" || t == "i") { if (j < n && T[j + 1] ~ /^w/) { j++; if (t == "r") chk(substr(T[j], 2)) } continue }
    if (t != "s") { x = substr(t, 2); A[++na] = x; if (x ~ /^[A-Za-z_][A-Za-z0-9_]*=/) V[substr(x, 1, index(x, "=") - 1)] = substr(x, index(x, "=") + 1); continue }
    for (k = 1; k <= na && (A[k] ~ /^[A-Za-z_][A-Za-z0-9_]*=/ || A[k] ~ /^-/ || A[k] ~ PRE); k++) ;
    nm = A[k]; sub(/.*\//, "", nm)
    if (k > na) ;
    else if (nm == "tee") { for (m = k + 1; m <= na; m++) if (A[m] !~ /^-/) chk(A[m]) }
    else if (nm ~ /^(cp|mv|install)$/) { if (na > k) chk(A[na]) }
    else if (nm == "sed") { for (m = k + 1; m <= na; m++) if (A[m] ~ /^(-[A-Za-z]*i|--in-place)/) break
      if (m <= na) for (m = k + 1; m <= na; m++) chk(A[m]) }
    else if (nm == "dd") { for (m = k + 1; m <= na; m++) if (A[m] ~ /^of=/) chk(substr(A[m], 4)) }
    else if (nm ~ /^(ba|z|da|k)?sh$/) { for (m = k + 1; m < na; m++) if (A[m] ~ /^-[A-Za-z]*c$/) Q[++nq] = A[m + 1] }
    else if (nm == "eval") { x = ""; for (m = k + 1; m <= na; m++) x = x " " A[m]; Q[++nq] = x }
    na = 0 } }
BEGIN { SQ = "\047"; PRE = "^(sudo|env|command|builtin|exec|nohup|nice|time|xargs|if|then|else|elif|while|until|do|!|\\{)$"
  G = "(^|/)\\.v2p/((SCAVENGE|AUDIT|PLAN|EXECUTE|REVIEW|PLAN-AMENDMENTS|DESIGN|DEPLOY)\\.md|(work/)?\\.[A-Za-z0-9_.-]*-pass|work/execute-task-[0-9]*\\.md)$" }
{ J = J (NR > 1 ? "\n" : "") $0 }
END { if (!match(J, /[{,][ \t\r\n]*"command"[ \t\r\n]*:[ \t\r\n]*"/)) exit 0
  c = substr(J, RSTART + RLENGTH); gsub(/\\\\/, "\001", c); gsub(/\\"/, "\002", c); c = substr(c, 1, index(c, "\"") - 1)
  gsub(/\\[nr]/, "\n", c); gsub(/\\t/, "\t", c); gsub(/\\[bf]/, " ", c)
  while (match(c, /\\u[0-9A-Fa-f][0-9A-Fa-f][0-9A-Fa-f][0-9A-Fa-f]/)) { v = hex(substr(c, RSTART + 2, 4))
    c = substr(c, 1, RSTART - 1) (v == 10 || v == 13 ? "\n" : v == 9 ? "\t" : v == 92 ? "\001" : v == 34 ? "\002" : v >= 32 && v < 127 ? sprintf("%c", v) : "?") substr(c, RSTART + 6) }
  gsub(/\\/, "", c); gsub(/\001/, "\\", c); gsub(/\002/, "\"", c)
  nq = 1; Q[1] = c; for (q = 1; q <= nq && q <= 20; q++) run(Q[q])
  exit hit ? 2 : 0 }' || { echo "v2p: shell writes to the .v2p finals, execute records and .*-pass seals are blocked; use the script. If a script refused, stop and show the user its output." >&2; exit 2; } ;;
esac
exit 0
