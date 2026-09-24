#!/bin/sh
# Move approved tidy rows to ~/.v2p-backups/<project>/<ts>/ keeping relative paths. Never deletes.
# Usage: sh tidy-check.sh --tsv | sh quarantine.sh [--apply] [root]     (dry-run without --apply)
# Rows: kind<TAB>path<TAB>action ; only action=quarantine or merge:<dest> are handled.
# Exit 0 = all rows moved (or dry-run plan printed), 1 = at least one row refused/failed, 2 = usage.
apply=no; root=
for a in "$@"; do case $a in --apply) apply=yes ;; -*) echo "usage: quarantine.sh [--apply] [root]" >&2; exit 2 ;; *) root=$a ;; esac; done
[ -n "$root" ] || root=$(git rev-parse --show-toplevel 2>/dev/null) || root=$PWD
root=$(cd "$root" && pwd -P) || exit 2
case $root in /|"$HOME") echo "REFUSE root is $root" >&2; exit 2 ;; esac
cd "$root" || exit 2
git=no; git rev-parse --is-inside-work-tree >/dev/null 2>&1 && git=yes
sha() { shasum -a 256 "$1" 2>/dev/null | cut -d' ' -f1 || sha256sum "$1" | cut -d' ' -f1; }
ts=$(date +%Y-%m-%d-%H%M%S); q="$HOME/.v2p-backups/${root##*/}/$ts"; [ -e "$q" ] && q="$q-$$"   # same-second rerun must not truncate a manifest
man="$q/MANIFEST.tsv"; res="$q/restore.sh"
bad=0; moved=0; tmp=${TMPDIR:-/tmp}/q.$$; trap 'rm -f "$tmp"' EXIT
refuse() { echo "REFUSE $1	$2"; bad=$((bad+1)); }
# one file: returns 0 if allowed
check() { p=$1
  case $p in /*|*/../*|../*|*/..|..|.|"") refuse "outside-or-relative" "$p"; return 1 ;; esac
  [ -e "$p" ] || [ -L "$p" ] || { refuse "missing" "$p"; return 1; }
  [ -L "$p" ] && { refuse "symlink" "$p"; return 1; }
  rp=$(realpath "$p" 2>/dev/null || (cd "$(dirname "$p")" && printf '%s/%s' "$(pwd -P)" "$(basename "$p")"))
  [ "$rp" = "$root/$p" ] || { refuse "symlink-in-path-or-outside" "$p"; return 1; }
  b=${p##*/}
  case $p in .git|.git/*|.v2p|.v2p/*|docs/DECISIONS.md|docs/ARCHITECTURE.md|docs/threat-model.md|README.md|CHANGELOG.md|.env.example|node_modules|node_modules/*|.venv|.venv/*|venv/*|vendor|vendor/*|.claude|.claude/*|.serena/*|.github/*|.vscode/*|.idea/*|data|data/*|uploads|uploads/*|storage|storage/*) refuse "never-touch" "$p"; return 1 ;; esac
  case $b in .env|.env.*|package-lock.json|pnpm-lock.yaml|yarn.lock|bun.lockb|bun.lock|Cargo.lock|poetry.lock|uv.lock|Gemfile.lock|composer.lock|Podfile.lock|go.sum|*.sqlite|*.sqlite3|*.db) refuse "never-touch" "$p"; return 1 ;; esac
  if [ $git = yes ]; then
    git check-ignore -q -- "$p" && { refuse "gitignored" "$p"; return 1; }
    [ -n "$(git status --porcelain -- "$p" | grep -v '^??')" ] && { refuse "uncommitted-changes" "$p"; return 1; }
  fi
  return 0
}
move() { m=$1; reason=$2   # file or empty dir, already checked
  if [ -d "$m" ]; then
    [ $apply = yes ] && { rmdir "$m" || { echo "FAIL rmdir $m"; bad=$((bad+1)); return; }; mkdir -p "$q/$m"; printf '%s\t-\t%s\t%s\tmkdir -p "%s"\n' "$m" "$tr" "$reason" "$root/$m" >> "$man"; printf 'mkdir -p "%s"\n' "$root/$m" >> "$res"; }
    echo "MOVE dir	$m"; moved=$((moved+1)); return; fi
  s1=$(sha "$m")
  if [ $apply = yes ]; then
    mkdir -p "$q/$(dirname "$m")" && mv "$m" "$q/$m" || { echo "FAIL mv $m"; bad=$((bad+1)); return; }
    s2=$(sha "$q/$m"); [ "$s1" = "$s2" ] || { echo "FAIL sha mismatch after move: $m (now at $q/$m)"; bad=$((bad+1)); return; }
    printf '%s\t%s\t%s\t%s\tmkdir -p "%s" && mv "%s" "%s"\n' "$m" "$s1" "$tr" "$reason" "$root/$(dirname "$m")" "$q/$m" "$root/$m" >> "$man"
    printf 'mkdir -p "%s" && mv "%s" "%s"\n' "$root/$(dirname "$m")" "$q/$m" "$root/$m" >> "$res"
  fi
  echo "MOVE $s1	$m"; moved=$((moved+1))
}
[ $apply = yes ] && { mkdir -p "$q" && printf '# root=%s created=%s restore: sh %s\n# path\tsha256\ttracked\treason\trestore\n' "$root" "$ts" "$res" > "$man" && printf '#!/bin/sh\n# restore everything quarantined on %s from %s\nset -e\n' "$ts" "$root" > "$res"; }
while IFS='	' read -r kind p action rest; do
  case $action in quarantine|merge:*) ;; *) continue ;; esac
  case $kind in \#*|kind|"") continue ;; esac
  p=${p#./}
  check "$p" || continue
  # ponytail: tracked for emptied-dir rows reflects git ls-files on the directory, not its files; per-file lookup if that matters
  tr=no; [ $git = yes ] && git ls-files --error-unmatch -- "$p" >/dev/null 2>&1 && tr=yes
  case $action in merge:*) dest=${action#merge:}
    grep -qF "From $p" "$dest" 2>/dev/null || { refuse "not-merged-into-$dest" "$p"; continue; } ;; esac
  if [ -d "$p" ]; then
    find "$p" -type l -print | grep -q . && { refuse "contains-symlink" "$p"; continue; }
    find "$p" -type f -print | sort > "$tmp"
    while IFS= read -r f; do move "$f" "$action"; done < "$tmp"
    find "$p" -depth -type d -print > "$tmp"      # every dir under (and including) p, deepest first
    while IFS= read -r f; do [ -z "$(find "$f" -mindepth 1 -print -quit)" ] && move "$f" "$action"; done < "$tmp"
  else move "$p" "$action"; fi
done
[ $apply = yes ] && echo "manifest: $man" && echo "restore: sh $res" || echo "dry-run: nothing moved; add --apply to move to $q"
echo "moved: $moved refused/failed: $bad"
[ "$bad" -eq 0 ]
