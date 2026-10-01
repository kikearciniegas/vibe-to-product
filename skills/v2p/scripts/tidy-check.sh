#!/bin/sh
# Read-only tidy check. Usage: sh tidy-check.sh [--tsv|--probe] [root]
# Exit 0 = clean, 1 = violations, 2 = usage. Runs under sh and zsh (no unquoted word-splitting).
mode=human; root=
for a in "$@"; do case $a in --tsv) mode=tsv ;; --probe) mode=probe ;; -*) echo "usage: tidy-check.sh [--tsv|--probe] [root]" >&2; exit 2 ;; *) root=$a ;; esac; done
# Default root = nearest dir holding a .git entry. Not git rev-parse: git skips an invalid (e.g. empty) .git and resolves a parent repo.
[ -n "$root" ] || { r=$PWD; while [ -n "$r" ] && [ ! -e "$r/.git" ]; do r=${r%/*}; done; root=${r:-$PWD}; }
root=$(cd "$root" && pwd -P) || exit 2
cd "$root" || exit 2
[ -e .git ] && GIT_CEILING_DIRECTORIES=${root%/*} && export GIT_CEILING_DIRECTORIES   # an invalid .git here never falls through to a parent repo
git=none; branch=-; dirty=0
if git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
  branch=$(git symbolic-ref --short -q HEAD) || branch=detached   # unborn: its name; rev-parse printed HEAD, then failed
  dirty=$(git status --porcelain 2>/dev/null | grep -vc '^??'); git=unborn; git rev-parse -q --verify HEAD >/dev/null && git=clean   # no commit yet: not "clean"
  [ "$dirty" -gt 0 ] && git="dirty:$dirty"
fi
gp=$git; [ "$git" = none ] && [ -d .git ] && [ -z "$(find .git -mindepth 1 -print -quit)" ] && gp=empty   # copied without history; $git stays none
code=no
for m in package.json pyproject.toml requirements.txt go.mod Cargo.toml Package.swift pubspec.yaml build.gradle build.gradle.kts Gemfile composer.json; do [ -f "$m" ] && code=yes; done
[ "$code" = no ] && [ -n "$(find . -path ./.git -prune -o -path ./node_modules -prune -o -path ./.v2p -prune -o -type f \( -name '*.ts' -o -name '*.tsx' -o -name '*.js' -o -name '*.jsx' -o -name '*.py' -o -name '*.go' -o -name '*.rs' -o -name '*.swift' -o -name '*.kt' -o -name '*.java' -o -name '*.rb' -o -name '*.php' -o -name '*.dart' -o -name '*.vue' -o -name '*.svelte' \) -print -quit)" ] && code=yes
brief=none; [ -f .v2p/BRIEF.md ] && brief=yes
audit=no; [ -f .v2p/AUDIT.md ] && grep -q '^checked:' .v2p/AUDIT.md && audit=yes
# writable:no = the root is read-only or something within 3 levels belongs to another user (e.g. a copy made with sudo).
w=no; [ -w . ] && [ -z "$(find . -maxdepth 3 ! -user "$(id -un)" -print -quit 2>/dev/null)" ] && w=yes
probe="root:$root code:$code git:$gp branch:$branch brief:$brief audit:$audit writable:$w"
[ "$mode" = probe ] && { echo "$probe"; exit 0; }

# Without git, .gitignore is read directly: each entry is a name or path that hides itself and everything under it, at any depth.
# ponytail: exact names only (leading and trailing / dropped); glob (*) and negation (!) entries are skipped. git check-ignore when git exists.
gi=; [ "$git" = none ] && [ -f .gitignore ] && gi=$(sed -e 's/[[:space:]]*$//' -e 's|^/||' -e 's|/$||' .gitignore | grep -v -e '^#' -e '^!' -e '^$' -e '\*')
ignored() { [ "$git" != none ] && { git check-ignore -q -- "$1"; return; }
  [ -n "$gi" ] || return 1
  while IFS= read -r e; do case /$1/ in */"$e"/*) return 0 ;; esac; done <<EOF
$gi
EOF
  return 1; }
tracked() { [ "$git" != none ] && git ls-files --error-unmatch -- "$1" >/dev/null 2>&1 && echo yes || echo no; }
age() { [ -e "$1" ] || { printf "%s\n" -; return; }; m=$(stat -f %m "$1" 2>/dev/null || stat -c %Y "$1" 2>/dev/null || echo 0); echo $(( ( $(date +%s) - m ) / 86400 )); }
row() { printf '%s\t%s\t%s\t%s\t%s\n' "$1" "$2" "$3" "$(tracked "$2")" "$(age "$2")"; }
# A scattered file other files mention by name (e.g. "see BACKLOG.md") is live, not stray: keep it and show how many files refer to it.
# Not counted: the file itself and `## From <path>` merge headings. ponytail: exact basename match; .git, node_modules, .v2p not searched.
scat() { n=$(grep -rIF --exclude-dir=.git --exclude-dir=node_modules --exclude-dir=.v2p -- "$b" . 2>/dev/null | grep -v '^[^:]*:## From ' | cut -d: -f1 | sort -u | grep -vxF "./$p" | grep -c .)
  if [ "$n" -gt 0 ]; then row scattered "$p" "keep:refs=$n"; else row scattered "$p" "merge:$1"; fi; }
# Decisions destination: with a decisions home, a new file inside it (from-<name>.md, no date so a rerun on another day agrees); else the flat file.
# ponytail: the home's own naming pattern (e.g. 0001-*.md) is not followed; from-<name>.md sorts apart from it.
dd() { if [ -n "$dh" ]; then printf '%s/from-%s.md\n' "$dh" "${b%.*}"; else echo docs/DECISIONS.md; fi; }

{
# 1. canonical files that must exist
# An existing docs/decisions/ or docs/adr*/ folder is the decisions home: no flat docs/DECISIONS.md is required, and the folder is not scattered.
dh=$(find docs -maxdepth 1 -type d \( -name decisions -o -name 'adr*' \) -print -quit 2>/dev/null)
for f in README.md .gitignore CHANGELOG.md .v2p/BRIEF.md docs/ARCHITECTURE.md docs/DECISIONS.md; do [ -e "$f" ] || { [ "$f" = docs/DECISIONS.md ] && [ -n "$dh" ]; } || row missing "$f" create; done
[ -n "$(find . -maxdepth 1 -name '.env*' ! -name '.env.example' -print -quit)" ] && [ ! -f .env.example ] && row missing .env.example create
[ -d node_modules ] && ! ignored node_modules && row gitignore node_modules gitignore
[ "$git" != none ] && [ -f .gitignore ] && ! grep -q '^\.v2p/work/' .gitignore && row gitignore .v2p/work/ gitignore
[ "$git" != none ] && [ -f .gitignore ] && ! grep -q '^\.v2p/\*\.draft\.md' .gitignore && row gitignore '.v2p/*.draft.md' gitignore

# 2. walk (never descends into never-touch dirs; symlinks are skipped, never followed)
find . -mindepth 1 \( -name .git -o -name node_modules -o -name .venv -o -name venv -o -name vendor -o -name .v2p -o -name .claude -o -name .serena -o -name .github -o -name .vscode -o -name .idea -o -type l \) -prune -o -print | sed 's|^\./||' | sort | while IFS= read -r p; do
  ignored "$p" && continue
  b=${p##*/}; d=${p%/*}; [ "$d" = "$p" ] && d=.
  if [ -d "$p" ]; then
    [ "$p" = "$dh" ] && continue
    case $b in
      dist|build|out|.next|.nuxt|.output|.turbo|coverage|__pycache__|.pytest_cache|.mypy_cache|.parcel-cache|.cache) row orphan-build "$p" quarantine; continue ;;
      notes|ideas|adr|adrs|decisions) row scattered "$p" "merge:$(dd)"; continue ;;
    esac
    [ -z "$(find "$p" -mindepth 1 -print -quit)" ] && row empty-dir "$p" quarantine
    continue
  fi
  case $d in dist|build|out|.next|.nuxt|.output|.turbo|coverage|__pycache__|.pytest_cache|.mypy_cache|.parcel-cache|.cache|notes|ideas|adr|adrs|decisions) continue ;; esac  # parent already listed
  case $b in
    .DS_Store|Thumbs.db|desktop.ini|._*|*~|*.swp|*.swo|.#*|*.orig|*.rej|*.bak|*.bak.*|*.backup|*_backup*|*.tmp|*.temp|*.pyc) row debris "$p" quarantine; continue ;;
    *_old.*|*_old|*-old.*|*.old|*_copy.*|*\ copy.*|*\ copy|*_final*|*-final*|*final_v[0-9]*|*_v[0-9].*|*_v[0-9][0-9].*|*\ \([0-9]\).*) row duplicate "$p" quarantine; continue ;;
    *.log|npm-debug.log*|yarn-error.log*|lerna-debug.log*) row log "$p" quarantine; continue ;;
  esac
  case $p in docs/DECISIONS.md|docs/ARCHITECTURE.md|docs/threat-model.md|CHANGELOG.md|README.md|DESIGN.md) continue ;; esac  # root DESIGN.md belongs to brand
  [ -n "$dh" ] && case $p in "$dh"/*) continue ;; esac
  case $b in
    NOTES*|notes*.md|TODO*|todo*.md|IDEAS*|ideas*.md|ROADMAP*|BACKLOG*|SCRATCH*|PLAN*|plan*.md|DECISIONS*|ADR*|*.notes.md|*.notes.txt) scat "$(dd)" ;;
    ARCHITECTURE*|architecture*.md|DESIGN.md|design.md) scat docs/ARCHITECTURE.md ;;
    CHANGES*|HISTORY*) scat CHANGELOG.md ;;
  esac
  [ "$d" = . ] && case $b in README_*|README-*|README.txt|README.old|readme*|Readme*) row dup-readme "$p" merge:README.md ;; esac
done
} > "${TMPDIR:-/tmp}/tidy.$$"
rows=$(grep -vc "	keep:" "${TMPDIR:-/tmp}/tidy.$$"); [ -n "$rows" ] || rows=0   # keep rows are shown, not violations
if [ "$mode" = tsv ]; then cat "${TMPDIR:-/tmp}/tidy.$$"; else
  echo "$probe"; echo "kind	path	action	tracked	age_days"; cat "${TMPDIR:-/tmp}/tidy.$$"; echo "tidy: $rows violations"; fi
rm -f "${TMPDIR:-/tmp}/tidy.$$"
[ "$rows" -eq 0 ]
