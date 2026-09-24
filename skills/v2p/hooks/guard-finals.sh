#!/bin/sh
# PreToolUse guard: .v2p final handoff files are produced only by scripts/finalize-*.sh (mv from a .draft.md).
# stdin: hook JSON; exit 2 = block (stderr goes back to the model). Also blocks shell redirects/copies to the finals.
# Known gaps: sed JSON extraction breaks on paths containing '"'; a Bash command that builds the filename
# indirectly (f=.v2p/PLAN.md; echo x > $f) passes; reads (cat .v2p/PLAN.md) are allowed on purpose.
# Whether subagent tool calls fire this hook is unverified. NOT installed by v2p: installing is the user's decision.
in=$(cat)
tool=$(printf '%s' "$in" | sed -n 's/.*"tool_name"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/p' | head -1)
case $tool in
  Write|Edit|MultiEdit)
    f=$(printf '%s' "$in" | sed -n 's/.*"file_path"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/p' | head -1)
    case $f in */.v2p/SCAVENGE.md|*/.v2p/AUDIT.md|*/.v2p/PLAN.md|.v2p/SCAVENGE.md|.v2p/AUDIT.md|.v2p/PLAN.md)
      echo "v2p: $f is written only by its finalize script. Write ${f%.md}.draft.md and run scripts/finalize-*.sh." >&2; exit 2 ;; esac ;;
  Bash)
    printf '%s' "$in" | grep -qE '(>|>>|tee|cp|mv|sed -i)[^;&|]*\.v2p/(SCAVENGE|AUDIT|PLAN)\.md' && { echo "v2p: shell writes to .v2p/{SCAVENGE,AUDIT,PLAN}.md are blocked; use the finalize script." >&2; exit 2; } ;;
esac
exit 0
