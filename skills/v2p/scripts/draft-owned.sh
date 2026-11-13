#!/bin/sh
# SPDX-License-Identifier: MIT
# Copyright (c) 2026 Rafael Arciniegas
# Provenance of a draft (finalize-plan.sh, finalize-audit.sh): was it written by this session, not shipped by the repo?
# Exit 0: <root> is the top of its own git repo and no index entry is <draft> on disk.
# Exit 1: tracked — some index entry is the same file (-ef: same device and inode, so any spelling on a case-insensitive
#         disk counts), or the index cannot be read, or an entry holds a newline (unreadable line by line): fail closed.
# Exit 2: <root> is not the top of its own git repo (no repo, or a parent repo that never vouches for the draft).
# Usage: sh draft-owned.sh <root> <draft>
root=$(cd "$1" 2>/dev/null && pwd -P) || exit 2; draft=$2
top=$(git -C "$root" rev-parse --show-toplevel 2>/dev/null) && top=$(cd "$top" && pwd -P)
[ -n "$top" ] && [ "$top" = "$root" ] || exit 2
tmp=${TMPDIR:-/tmp}/do.$$; trap 'rm -f "$tmp"' EXIT
git -C "$root" ls-files -z > "$tmp" 2>/dev/null || exit 1
[ "$(tr -cd '\n' < "$tmp" | wc -c)" -eq 0 ] || exit 1
tr '\0' '\n' < "$tmp" | while IFS= read -r e; do if [ "$draft" -ef "$root/$e" ]; then exit 1; fi; done || exit 1
exit 0
