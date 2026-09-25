#!/bin/sh
# PreToolUse guard: .v2p final handoff files are produced only by scripts/finalize-*.sh (mv from a .draft.md);
# .v2p/PLAN-AMENDMENTS.md only by scripts/task-record.sh allow / start --base; execute records (.v2p/work/execute-task-*.md) and
# every seal (.v2p/.*-pass, .v2p/work/.*-pass) only by the scripts. A script that refuses is a stop-and-ask, not a workaround.
# stdin: hook JSON; exit 2 = block (stderr goes back to the model). Also blocks shell redirects/copies (> >> tee cp mv
# install dd of= sed -i) to those files. Running the scripts, reads and git add/commit pass.
# Known gaps: sed JSON extraction breaks on paths containing '"'; a Bash command that builds the filename
# indirectly (f=.v2p/PLAN.md; echo x > $f), or writes through another interpreter (python -c, perl -e), passes;
# reads (cat .v2p/PLAN.md) are allowed on purpose; a guarded path after a trigger word in the same command segment
# is blocked even as a source (cp .v2p/.plan-pass /tmp/x) or inside a quoted string. The Bash check greps the whole
# hook JSON, not only the command. Whether subagent tool calls fire this hook is unverified.
# NOT installed by v2p: installing is the user's decision.
in=$(cat)
tool=$(printf '%s' "$in" | sed -n 's/.*"tool_name"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/p' | head -1)
case $tool in
  Write|Edit|MultiEdit)
    f=$(printf '%s' "$in" | sed -n 's/.*"file_path"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/p' | head -1)
    case $f in */.v2p/SCAVENGE.md|*/.v2p/AUDIT.md|*/.v2p/PLAN.md|*/.v2p/EXECUTE.md|*/.v2p/REVIEW.md|*/.v2p/PLAN-AMENDMENTS.md|.v2p/SCAVENGE.md|.v2p/AUDIT.md|.v2p/PLAN.md|.v2p/EXECUTE.md|.v2p/REVIEW.md|.v2p/PLAN-AMENDMENTS.md)
      echo "v2p: $f is written only by its script (finalize-*.sh; PLAN-AMENDMENTS.md by task-record.sh allow / start --base). Write ${f%.md}.draft.md and run the script." >&2; exit 2 ;;
    */.v2p/work/execute-task-*.md|.v2p/work/execute-task-*.md|*/.v2p/.*-pass|.v2p/.*-pass|*/.v2p/work/.*-pass|.v2p/work/.*-pass)
      echo "v2p: $f is written only by task-record.sh / finalize-*.sh. If a script refused, stop and show the user its output; never write or seal a record by hand." >&2; exit 2 ;; esac ;;
  Bash)
    printf '%s' "$in" | grep -qE '(>|tee|cp|mv|install|of=|sed -i)[^;&|]*\.v2p/((SCAVENGE|AUDIT|PLAN|EXECUTE|REVIEW|PLAN-AMENDMENTS)\.md|(work/)?\.[A-Za-z0-9_.-]*-pass|work/execute-task-[0-9]*\.md)' && { echo "v2p: shell writes to the .v2p finals, execute records and .*-pass seals are blocked; use the script. If a script refused, stop and show the user its output." >&2; exit 2; } ;;
esac
exit 0
