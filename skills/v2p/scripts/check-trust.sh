#!/bin/sh
# SPDX-License-Identifier: MIT
# Copyright (c) 2026 Rafael Arciniegas
# Exit 0 only if <PLAN.md>'s sha256 AND its project root are in this machine's trust ledger,
# ${XDG_CONFIG_HOME:-$HOME/.config}/v2p/trusted-plans: one `<sha256><TAB><realpath of project root>` per line, outside
# every repo (a receipt ships with a clone, trust to run its Verifier commands does not). Keyed by path too: relative
# commands do different things in another project, so a copied, moved or renamed project needs trust again.
# --add records the entry (finalize-plan.sh for a draft this session wrote; trust-plan.sh --yes after showing it).
# Usage: sh check-trust.sh .v2p/PLAN.md [--add]
f=$1; L=${XDG_CONFIG_HOME:-$HOME/.config}/v2p/trusted-plans
[ -f "$f" ] || { echo "FAIL: $f missing"; exit 1; }
root=$(cd "$(dirname "$f")/.." && pwd -P); h=$(shasum -a 256 "$f" | cut -d' ' -f1)
# a newline or tab in the root would split or forge a ledger line: refuse, never write
case $root in *[[:cntrl:]]*) echo "FAIL: project path has a control character (newline, tab): rename the directory first"; exit 1 ;; esac
# exact field match (not grep -F, whose pattern list a path could extend); ENVIRON, since awk -v expands backslashes
has() { H=$h R=$root awk -F'\t' 'NF == 2 && $1 == ENVIRON["H"] && $2 == ENVIRON["R"] { f = 1 } END { exit !f }' "$L" 2>/dev/null; }
if [ "${2-}" = --add ]; then
  (umask 077; mkdir -p "${L%/*}" && chmod 700 "${L%/*}" && touch "$L" && chmod 600 "$L") || { echo "FAIL: cannot write $L"; exit 1; }
  has || printf '%s\t%s\n' "$h" "$root" >> "$L"; echo "trusted: $h	$root"; exit 0
fi
has && exit 0
skill=$(cd "$(dirname "$0")/.." && pwd -P)
echo "FAIL: PLAN.md is not trusted on this machine; review its Verifier commands with: sh $skill/scripts/trust-plan.sh $root"; exit 1
