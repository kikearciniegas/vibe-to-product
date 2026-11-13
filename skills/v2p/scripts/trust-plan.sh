#!/bin/sh
# SPDX-License-Identifier: MIT
# Copyright (c) 2026 Rafael Arciniegas
# Trust a PLAN.md this machine did not finalize (a fresh clone): print every mechanical Verifier command that
# task-record.sh, finalize-review.sh and finalize-deploy.sh would run, then record PLAN.md's hash and project path in
# the local ledger (check-trust.sh) only with --yes. A command holding a control or non-ASCII byte is never trusted.
# A receipt alone never grants trust: anyone can recompute it.
# Usage: sh trust-plan.sh <project-root> [--yes]   (exit 0 trusted · 1 not trusted / no valid receipt)
skill=$(cd "$(dirname "$0")/.." && pwd -P); root=.; yes=
for a; do case $a in --yes) yes=1 ;; *) root=$a ;; esac; done
root=$(cd "$root" 2>/dev/null && pwd -P) || { echo "FAIL: $1 not found"; exit 1; }
d=$root/.v2p; plan=$d/PLAN.md
sh "$skill/scripts/check-pass.sh" "$plan" "$d/.plan-pass" >/dev/null || { echo "FAIL: PLAN.md has no valid receipt (sh $skill/scripts/check-pass.sh $plan $d/.plan-pass)"; exit 1; }
# same parser as the three runners: the task's **Verifier:** line, mechanical part only, `cmd` → x pairs
tmp=${TMPDIR:-/tmp}/tp.$$; trap 'rm -f "$tmp"' EXIT; : > "$tmp"
for n in $(grep -o '^### Task [0-9]*' "$plan" | awk '{print $3}'); do
  awk -v n="$n" '$0 ~ "^### Task "n":" {f=1;next} f && /^### / {exit} f && /^\*\*Verifier:\*\*/ {print; exit}' "$plan" |
    sed 's/manual:.*mechanical:/mechanical:/; s/manual:.*//' | grep -oE '`[^`]+` *→ *`?[^`,;|]*' |
    sed 's/^`\([^`]*\)`.*/\1/' | while IFS= read -r c; do printf '%s\t%s\n' "$n" "$c"; done >> "$tmp"
done
# a byte outside printable ASCII + tab (an ANSI escape, a CR) could hide the real command in the listing: refuse to trust
bad=$(LC_ALL=C grep -n '[^ -~	]' "$tmp" | head -n 1 | cut -d: -f2 | cut -f1)
[ -z "$bad" ] || { echo "FAIL: task $bad Verifier command has a control or non-ASCII byte that could hide what runs; not trusted (fix PLAN.md and re-run finalize-plan)"; exit 1; }
echo "Verifier commands in $plan (run with sh -c; deploy fills <domain>/<url> with its target):"
# printf, never echo: echo expands a literal `\033[2K\r` (all ASCII, past the byte check) into the ESC/CR it spells
while IFS='	' read -r n c; do printf '  task %s: %s\n' "$n" "$c"; done < "$tmp"
[ -n "$yes" ] || { echo "Not trusted on this machine for $root (trust is per project path: a moved or renamed project needs it again). If every command above is safe to run here: sh $skill/scripts/trust-plan.sh $root --yes"; exit 1; }
sh "$skill/scripts/check-trust.sh" "$plan" --add
