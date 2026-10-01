#!/bin/sh
# Builds a tiny git project with a landing BRIEF, a 3-task PLAN.md + receipt, a passed DESIGN.md + receipt and the
# execute draft (Step 1: PLAN §4 copied into .v2p/EXECUTE.draft.md, untracked), ready for /v2p execute.
# §4 rows come from the live standards files (one per '- [ ]' item of BRIEF §9; '|' in an item becomes '/').
# Usage: sh tests/fixture-execute.sh <dir>
set -eu; here=$(cd "$(dirname "$0")/.." && pwd -P); d=$1; rm -rf "$d"; mkdir -p "$d/.v2p" "$d/docs" "$d/src"; cd "$d"
git init -q; printf '.v2p/work/\n.v2p/*.draft.md\n' > .gitignore
echo '# fixture' > README.md; echo '## Unreleased' > CHANGELOG.md; echo '# Architecture' > docs/ARCHITECTURE.md; echo '# Decisions' > docs/DECISIONS.md
printf 'printf ok\n' > src/hello.sh; cp "$here/tests/fixtures/finalize-plan/BRIEF.md" .v2p/BRIEF.md
rows=$(awk '/^## 9/{f=1;next} /^## /{f=0} f' .v2p/BRIEF.md | grep -oE '[a-z-]+\.md' | sort -u | while IFS= read -r n; do
  sf=$here/skills/v2p/references/standards/$n; [ -f "$sf" ] && sed -n 's/^- \[ \] //p' "$sf" | tr '|' '/' | sed "s/^/| /; s/\$/ | $n | pending | |/"
done)
{ printf '%s\n' '# Fixture Implementation Plan' '' '## Architecture' '```mermaid' 'flowchart LR' '  U[Browser] --> V[static page]' '```' '' '## Threat Model' 'Assets: none. Entry points: none.' '' \
  '## 2. Providers' 'Total monthly at launch: $0' '' '## 4. Standards (pre-filled; execute fills evidence)' '| item | file | status | evidence |' '|---|---|---|---|'
  printf '%s\n' "$rows"
  printf '%s\n' '' '## 4b. Landing sections' '| section | kept / omitted | task |' '|---|---|---|' '| 1. Hero | kept | Task 2 |' '' '## 5. Tasks' \
  '### Task 1: Greeting script' '**Files:** Create: `src/greet.sh`, `tests/greet.test.sh`  **Interfaces:** Produces: `sh src/greet.sh` prints `hi`' \
  '**Verifier:** mechanical: `sh tests/greet.test.sh` → exit 0   |   manual: none' '' \
  '### Task 2: Locale page' '**Files:** Modify: `src/*.sh`, `app/[locale]/page.tsx`' \
  "**Verifier:** mechanical: \`sh -c 'grep -c hi src/greet.sh'\` → 1   |   manual: the user opens it" '' \
  '### Task 3: Review phase' '**Files:** none' '**Verifier:** manual: the reviewer reads the branch diff' '' \
  '## 6. Handoff' 'Tasks: 3 (mechanical 2, manual 1). Order: 1 → 2 → 3' 'Next: /v2p execute'; } > .v2p/PLAN.md
shasum -a 256 .v2p/PLAN.md | cut -d' ' -f1 > .v2p/.plan-pass
# a passed brand (the bytes finalize-brand.sh writes), so Task 2 (a .tsx file) clears task-record's UI gate
cp "$here/tests/fixtures/finalize-brand/DESIGN.good.md" .v2p/DESIGN.md; shasum -a 256 .v2p/DESIGN.md | cut -d' ' -f1 > .v2p/.brand-pass
git add -A; git -c user.email=t@t -c user.name=t commit -qm 'fixture: plan'
{ printf '%s\n' '# EXECUTE — fixture' 'checked: pending' 'written: 2026-09-24 by v2p execute · reads: .v2p/PLAN.md' '' '## 1. Tasks' '' '## 2. Standards' '| item | file | status | evidence |' '|---|---|---|---|'
  printf '%s\n' "$rows" '' 'Next: /v2p review'; } > .v2p/EXECUTE.draft.md
