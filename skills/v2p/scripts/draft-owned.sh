#!/bin/sh
# SPDX-License-Identifier: MIT
# Copyright (c) 2026 Rafael Arciniegas
# Provenance of a draft (finalize-plan.sh, finalize-audit.sh): was it written by this session, not shipped by the repo?
# Exit 0: <root> is the top of its own git repo and no index entry is <draft> on disk.
# Exit 1: not this session's, with the reason on stdout: `tracked` (an index entry is the same file: -ef, same device
#         and inode, so any spelling on a case-insensitive disk counts), `nested` (the draft's directory is in another
#         repo, a submodule or a nested .git, whose index the outer one never lists) or `unreadable` (ls-files failed, or
#         an entry holds a newline and cannot be read line by line): every doubt fails closed.
# Exit 2: <root> is not the top of its own git repo (no repo, or a parent repo that never vouches for the draft).
# Usage: sh draft-owned.sh <root> <draft>
root=$(cd "$1" 2>/dev/null && pwd -P) || exit 2; draft=$2
top=$(git -C "$root" rev-parse --show-toplevel 2>/dev/null) && top=$(cd "$top" && pwd -P)
[ -n "$top" ] && [ "$top" = "$root" ] || exit 2
dt=$(git -C "$(dirname "$draft")" rev-parse --show-toplevel 2>/dev/null) && dt=$(cd "$dt" && pwd -P)
[ "$dt" = "$root" ] || { echo nested; exit 1; }
tmp=${TMPDIR:-/tmp}/do.$$; trap 'rm -f "$tmp"' EXIT
git -C "$root" ls-files -z > "$tmp" 2>/dev/null || { echo unreadable; exit 1; }
[ "$(tr -cd '\n' < "$tmp" | wc -c)" -eq 0 ] || { echo unreadable; exit 1; }
tr '\0' '\n' < "$tmp" | while IFS= read -r e; do if [ "$draft" -ef "$root/$e" ]; then echo tracked; exit 1; fi; done || exit 1
exit 0
