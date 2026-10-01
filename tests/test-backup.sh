#!/bin/sh
# Runs backup.sh against the messy fixture under sh and zsh: full archive (.git, untracked, ignored, symlink),
# restore reproduces the tree byte for byte, the project is untouched, unsafe roots are refused.
# Writes only under ${TMPDIR:-/tmp}/v2p-test.<pid>; HOME points there, so the real ~/.v2p-backups is never touched.
# Usage: sh tests/test-backup.sh   (exit 0 = all PASS)
here=$(cd "$(dirname "$0")/.." && pwd -P); S=$here/skills/v2p/scripts
base=$(cd "${TMPDIR:-/tmp}" && pwd -P)/v2p-test.$$; mkdir -p "$base/home"; HOME=$base/home; export HOME
fails=0
is() { if [ "$2" = "$3" ]; then echo "PASS [$SH] $1"; else echo "FAIL [$SH] $1: got '$2' want '$3'"; fails=$((fails+1)); fi; }
has() { case $2 in *"$3"*) echo "PASS [$SH] $1" ;; *) echo "FAIL [$SH] $1: missing '$3'"; fails=$((fails+1)) ;; esac; }
tree() { (cd "$1" && find . | sort && find . -type f -exec shasum -a 256 {} + | sort -k2); }
for SH in sh zsh; do
  fx=$base/proj-$SH; sh "$here/tests/fixture-messy.sh" "$fx" >/dev/null
  before=$(tree "$fx")
  # 1. archive written, verified, under ~/.v2p-backups/<project>/
  out=$($SH "$S/backup.sh" "$fx"); is "1 exit" $? 0
  has "1 BACKUP line" "$out" "BACKUP $HOME/.v2p-backups/proj-$SH/"
  has "1 restore line" "$out" "restore: "
  a=$(printf '%s\n' "$out" | sed -n 's/^BACKUP \([^ ]*\) .*/\1/p')
  is "1 archive exists" "$([ -s "$a" ] && echo yes)" yes
  # 2. project untouched
  is "2 project unchanged" "$(tree "$fx")" "$before"
  # 3. full: .git, untracked, ignored and symlink entries are all in the archive
  list=$(tar -tzf "$a")
  for p in proj-$SH/.git/HEAD proj-$SH/.env proj-$SH/dist/bundle.js proj-$SH/debug.log proj-$SH/link.ts; do
    has "3 contains $p" "$list" "$p"; done
  # 4. the printed restore command rebuilds an identical tree (dirty work, .git and all)
  r=$(printf '%s\n' "$out" | sed -n 's/^restore: //p'); (cd "$base" && eval "$r") >/dev/null 2>&1
  is "4 restored = original" "$(tree "$fx.restored")" "$before"
  is "4 restored git state" "$(git -C "$fx.restored" status --porcelain | grep -c .)" "$(git -C "$fx" status --porcelain | grep -c .)"
  # 5. second run in the same second never overwrites the first archive
  out2=$($SH "$S/backup.sh" "$fx"); a2=$(printf '%s\n' "$out2" | sed -n 's/^BACKUP \([^ ]*\) .*/\1/p')
  is "5 distinct archive" "$([ "$a" != "$a2" ] && [ -s "$a" ] && [ -s "$a2" ] && echo yes)" yes
  # 6. refuses / and $HOME, and a missing root
  $SH "$S/backup.sh" / >/dev/null 2>&1; is "6 refuse /" $? 2
  $SH "$S/backup.sh" "$HOME" >/dev/null 2>&1; is "6 refuse HOME" $? 2
  $SH "$S/backup.sh" "$base/nope" >/dev/null 2>&1; is "6 missing root" $? 2
  # 7. an unreadable file fails the backup and leaves no partial archive behind
  u=$base/unread-$SH; mkdir -p "$u"; echo s > "$u/secret"; chmod 000 "$u/secret"
  $SH "$S/backup.sh" "$u" >/dev/null 2>&1; is "7 unreadable exit" $? 1
  is "7 no partial archive" "$(find "$HOME/.v2p-backups/unread-$SH" -type f 2>/dev/null | grep -c .)" 0
  chmod 600 "$u/secret"
  rm -rf "$fx.restored"
done
echo "test-backup: $fails failures (scratch: $base)"
[ "$fails" = 0 ] && rm -rf "$base"
[ "$fails" = 0 ]
