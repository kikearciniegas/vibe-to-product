#!/bin/sh
# Builds the messy sample project used to test tidy-check.sh and quarantine.sh. Usage: sh fixture-messy.sh <dir>
set -eu; d=$1; rm -rf "$d"; mkdir -p "$d/src" "$d/notes" "$d/empty-dir" "$d/dist" "$d/build"; cd "$d"
git init -q; printf 'dist/\n.env\nnode_modules/\n' > .gitignore
echo 'export const x = 1' > src/index.ts; echo 'SECRET=1' > .env; echo 'KEY=' > .env.example
echo '- ship v1' > TODO.md; echo 'idea: dark mode' > notes/ideas.md; echo 'old' > src/index_old.ts; echo 'b' > src/app.ts.bak
echo 'dup readme' > README_final_v2.md; echo 'd' > dist/bundle.js; echo 'o' > build/out.js; : > .DS_Store; echo 'log' > debug.log
ln -s src/index.ts link.ts; echo '{}' > package-lock.json; echo '{"name":"fx"}' > package.json
git add .gitignore src/index.ts README_final_v2.md package-lock.json package.json; git -c user.email=a@b -c user.name=a commit -qm init
echo 'dirty' >> src/index.ts
