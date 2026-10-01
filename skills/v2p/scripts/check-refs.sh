#!/bin/sh
# Filter for the finalize steps' standards-table checks. Every input line passes through unchanged except
# `ref<TAB><cited ref><TAB><message>`, printed as <message> only when the ref is not an existing path in the repo:
# its first word, backticks and a `:line`/`#anchor` suffix dropped, relative to <root>, never absolute or with `..`.
# ponytail: existence only, the cited § or line is not read; check the text if decisions start citing the wrong line.
# Usage: awk … | sh check-refs.sh <root>
root=${1:-.}; T=$(printf '\t')
while IFS= read -r l; do
  case $l in
    "ref$T"*) r=${l#ref"$T"}; msg=${r#*"$T"}; r=${r%%"$T"*}
      p=$(printf '%s\n' "$r" | tr -d '`' | awk '{print $1}' | sed 's/[:#].*//')
      case $p in ''|/*|..|../*|*/..|*/../*) echo "$msg" ;; *) [ -e "$root/$p" ] || echo "$msg" ;; esac ;;
    *) printf '%s\n' "$l" ;;
  esac
done
