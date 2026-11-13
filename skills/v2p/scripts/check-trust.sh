#!/bin/sh
# SPDX-License-Identifier: MIT
# Copyright (c) 2026 Rafael Arciniegas
# Exit 0 only if <PLAN.md>'s sha256 is in this machine's trust ledger, ${XDG_CONFIG_HOME:-$HOME/.config}/v2p/trusted-plans
# (outside every repo: a receipt ships with a clone, trust to run its Verifier commands does not).
# --add records the hash (finalize-plan.sh after it writes PLAN.md; trust-plan.sh --yes after the user reviewed it).
# Usage: sh check-trust.sh .v2p/PLAN.md [--add]
f=$1; L=${XDG_CONFIG_HOME:-$HOME/.config}/v2p/trusted-plans
[ -f "$f" ] || { echo "FAIL: $f missing"; exit 1; }
h=$(shasum -a 256 "$f" | cut -d' ' -f1)
if [ "${2-}" = --add ]; then
  (umask 077; mkdir -p "${L%/*}" && chmod 700 "${L%/*}" && touch "$L" && chmod 600 "$L") || { echo "FAIL: cannot write $L"; exit 1; }
  grep -qxF "$h" "$L" || echo "$h" >> "$L"; echo "trusted: $h"; exit 0
fi
grep -qxF "$h" "$L" 2>/dev/null && exit 0
skill=$(cd "$(dirname "$0")/.." && pwd -P); root=$(cd "$(dirname "$f")/.." && pwd -P)
echo "FAIL: PLAN.md is not trusted on this machine; review its Verifier commands with: sh $skill/scripts/trust-plan.sh $root"; exit 1
