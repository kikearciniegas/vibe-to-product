#!/bin/sh
# Full backup of a project before adopt touches it: one tar.gz of the whole root (.git, untracked, ignored files,
# symlinks as links) at ~/.v2p-backups/<project>/<ts>-original.tar.gz, read back once (tar -t). Never modifies the project.
# Usage: sh backup.sh [root]
# Exit 0 = archive written and readable, 1 = failed (partial archive removed), 2 = usage/refused root.
[ $# -le 1 ] || { echo "usage: backup.sh [root]" >&2; exit 2; }
# Default root = nearest dir holding a .git entry. Not git rev-parse: git skips an invalid (e.g. empty) .git and resolves a parent repo.
root=$1; [ -n "$root" ] || { r=$PWD; while [ -n "$r" ] && [ ! -e "$r/.git" ]; do r=${r%/*}; done; root=${r:-$PWD}; }
root=$(cd "$root" 2>/dev/null && pwd -P) || { echo "REFUSE no such directory: $1" >&2; exit 2; }
h=$(cd "$HOME" && pwd -P) || exit 2
case $root in /|"$h") echo "REFUSE root is $root" >&2; exit 2 ;; esac
name=${root##*/}; parent=${root%/*}; [ -n "$parent" ] || parent=/
dir="$h/.v2p-backups/$name"; ts=$(date +%Y-%m-%d-%H%M%S); out="$dir/$ts-original.tar.gz"
[ -e "$out" ] && out="$dir/$ts-$$-original.tar.gz"   # same-second rerun must not overwrite
case $dir/ in "$root"/*) echo "REFUSE backup dir $dir is inside the project" >&2; exit 2 ;; esac
mkdir -p "$dir" || exit 1
tar -czf "$out" -C "$parent" "$name" || { rm -f "$out"; echo "FAIL tar could not archive $root" >&2; exit 1; }
n=$(tar -tzf "$out" | wc -l | tr -d ' '); [ "$n" -gt 0 ] || { rm -f "$out"; echo "FAIL archive unreadable: $out" >&2; exit 1; }
echo "BACKUP $out · $n entries · $(du -h "$out" | cut -f1)"
echo "restore: mkdir -p '$root.restored' && tar -xzf '$out' -C '$root.restored' --strip-components=1"
