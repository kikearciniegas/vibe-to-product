#!/bin/sh
# finalize-brand.sh and archive-cycle.sh against COPIES of tests/fixtures/finalize-brand (a deliberately bad DESIGN draft,
# a good one, a landing BRIEF with a §6 Must-avoid), under sh and zsh: the bad draft FAILs every check and writes
# nothing, each FAIL disappears as the copy is fixed one step at a time (PASS at the end), then one falsifier per check
# on the good file, the lint parser against a fake npx, the receipt, and archive-cycle. Needs @google/design.md 0.4.0
# in the npx cache (exit 2 "did not run" otherwise). The source files are only read.
# Writes only under ${TMPDIR:-/tmp}/v2p-fb-test.<pid>. Usage: sh tests/test-finalize-brand.sh   (exit 0 = all PASS)
here=$(cd "$(dirname "$0")/.." && pwd -P); S=$here/skills/v2p/scripts; F=$S/finalize-brand.sh; src=$here/tests/fixtures/finalize-brand
[ -f "$src/BRIEF.md" ] && [ -f "$src/DESIGN.md" ] && [ -f "$src/DESIGN.good.md" ] || { echo "ERROR: $src/{BRIEF,DESIGN,DESIGN.good}.md missing; test did not run"; exit 2; }
npx --offline -y -p @google/design.md@0.4.0 designmd lint --help >/dev/null 2>&1 || { echo "ERROR: designmd 0.4.0 not in the npx cache; run it once online"; exit 2; }
GIT_AUTHOR_NAME=t GIT_AUTHOR_EMAIL=t@t GIT_COMMITTER_NAME=t GIT_COMMITTER_EMAIL=t@t; export GIT_AUTHOR_NAME GIT_AUTHOR_EMAIL GIT_COMMITTER_NAME GIT_COMMITTER_EMAIL
sum0=$(cat "$src/BRIEF.md" "$src/DESIGN.md" "$src/DESIGN.good.md" | shasum -a 256)
base=$(cd "${TMPDIR:-/tmp}" && pwd -P)/v2p-fb-test.$$; mkdir -p "$base"; fails=0
is() { if [ "$2" = "$3" ]; then echo "PASS [$SH] $1"; else echo "FAIL [$SH] $1: got '$2' want '$3'"; fails=$((fails+1)); fi; }
has() { case $2 in *"$3"*) echo "PASS [$SH] $1" ;; *) echo "FAIL [$SH] $1: missing '$3' in: $(printf '%s' "$2" | head -c 400)"; fails=$((fails+1)) ;; esac; }
hasnt() { case $2 in *"$3"*) echo "FAIL [$SH] $1: still has '$3'"; fails=$((fails+1)) ;; *) echo "PASS [$SH] $1" ;; esac; }
sha() { shasum -a 256 "$1" | cut -d' ' -f1; }
# run [env assignment]: finalize-brand.sh in $w; nfail = FAIL lines other than the final "not written"
run() { out=$(cd "$w" && env ${1:+"$1"} $SH "$F" .v2p 2>&1); rc=$?; nfail=$(printf '%s\n' "$out" | grep '^FAIL: ' | grep -vc 'not written$'); }
# rep <line> <text>: replace every line equal to <line>; ins <regex> <text>: insert before the first match
rep() { A=$1 B=$2 awk '$0 == ENVIRON["A"] { print ENVIRON["B"]; next } { print }' "$P" > "$P.new" && mv "$P.new" "$P"; }
ins() { RE=$1 T=$2 awk '!done && $0 ~ ENVIRON["RE"] { print ENVIRON["T"]; done = 1 } { print }' "$P" > "$P.new" && mv "$P.new" "$P"; }
# good: fresh copy of the good draft in $w (optionally with a root DESIGN.md)
good() { w=$base/g-$SH; rm -rf "$w"; mkdir -p "$w/.v2p/work"; cp "$src/BRIEF.md" "$w/.v2p/BRIEF.md"; P=$w/.v2p/DESIGN.draft.md; cp "$src/DESIGN.good.md" "$P"; }
MA='- BRIEF §6: gradient text, fake testimonials, three-icon-card rows'
for SH in sh zsh; do
  w=$base/$SH; v=$w/.v2p; P=$v/DESIGN.draft.md; mkdir -p "$v/work"
  cp "$src/BRIEF.md" "$v/BRIEF.md"; cp "$src/DESIGN.md" "$P"; echo x > "$v/work/brand-x.md"
  # 0. the bad draft fails every check and writes nothing
  run; is "0 exit" $rc 1
  for m in "lint error broken-ref" "lint warning contrast-ratio" "section 'Colors' appears 2 times" "section 'Voice' appears 0 times" \
    "Must-Avoid first bullet" "Sources is empty" "'---' rule on lines 57" "colors.surface is not 6-digit hex" "frontmatter missing components.page" \
    "no 'Next: /v2p mapping'" "components.button-primary.textColor must be {colors.on-primary}"; do has "0 $m" "$out" "$m"; done
  is "0 no DESIGN.md" "$(test -f "$v/DESIGN.md" && echo yes)" ""; is "0 no receipt" "$(test -f "$v/.brand-pass" && echo yes)" ""
  is "0 no symlink" "$(test -e "$w/DESIGN.md" && echo yes)" ""; n0=$nfail
  # 1. broken ref (also the button-primary pairing); the resolved ref makes button-primary's contrast measurable,
  # so a second contrast-ratio FAIL appears (net one fewer)
  rep '    textColor: "{colors.on-primari}"' '    textColor: "{colors.on-primary}"'
  run; hasnt "1 broken-ref" "$out" "broken-ref"; hasnt "1 pairing" "$out" "textColor must be"; is "1 net one fewer" $((n0 - nfail)) 1
  is "1 contrast now on both components" "$(printf '%s\n' "$out" | grep -c 'lint warning contrast-ratio')" 2
  # 2. contrast: 1.04:1 → orange/white
  rep '  primary: "#f2f2f2"' '  primary: "#C2410C"'; rep '  on-primary: "#eeeeee"' '  on-primary: "#FFFFFF"'
  run; hasnt "2 contrast" "$out" "contrast-ratio"; is "2 two fewer" $((n0 - nfail)) 3
  # 3. the second ## Colors (also the linter's section-order)
  awk '$0 == "## Colors" { n++ } n == 2 && /^## / && $0 != "## Colors" { n = 3 } n != 2 { print }' "$P" > "$P.new" && mv "$P.new" "$P"
  run; hasnt "3 duplicate" "$out" "section 'Colors'"; hasnt "3 section-order" "$out" "section-order"; is "3 two fewer" $((n0 - nfail)) 5
  # 4. Voice
  ins '^## Logo Rules$' '## Voice
- Adjectives: warm, precise, local · register: informal · locales: one
'
  run; hasnt "4 voice" "$out" "section 'Voice'"; is "4 one fewer" $((n0 - nfail)) 6
  # 5. Must-Avoid = BRIEF §6 verbatim
  rep '- BRIEF §6: gradient text' "$MA"; run; hasnt "5 must-avoid" "$out" "Must-Avoid first bullet"; is "5 one fewer" $((n0 - nfail)) 7
  # 6. Sources
  printf '%s\n' '- generated: ui-ux-pro-max 2.13.0 --design-system "warm precise local" · candidate B chosen' '- schema: google-labs-code/design.md spec, linted with @google/design.md 0.4.0' >> "$P"
  run; hasnt "6 sources" "$out" "Sources is empty"; is "6 one fewer" $((n0 - nfail)) 8
  # 7. the body --- rule
  awk '$0 == "---" { n++; if (n == 3) next } { print }' "$P" > "$P.new" && mv "$P.new" "$P"
  run; hasnt "7 rule" "$out" "'---' rule"; is "7 one fewer" $((n0 - nfail)) 9
  # 8. oklch → hex
  rep '  surface: oklch(98% 0.01 80)' '  surface: "#FFF8F1"'; run; hasnt "8 hex" "$out" "not 6-digit hex"; is "8 one fewer" $((n0 - nfail)) 10
  # 9. components.page (the card goes)
  awk '$0 == "  card:" { print "  page:"; print "    backgroundColor: \"{colors.surface}\""; print "    textColor: \"{colors.on-surface}\""; getline; getline; next } { print }' "$P" > "$P.new" && mv "$P.new" "$P"
  run; hasnt "9 page" "$out" "components.page"; is "9 two fewer" $((n0 - nfail)) 12; is "9 one FAIL left" $nfail 1
  # 10. Next line → PASS
  printf '%s\n' '' 'Next: /v2p mapping' >> "$P"
  run; is "10 exit" $rc 0; has "10 PASS" "$out" "PASS: 6 colors, 2 typography roles, 3 components, lint 0 errors / 0 warnings noted, status final"
  is "10 draft gone" "$(test -f "$P" && echo yes)" ""; is "10 receipt" "$(cat "$v/.brand-pass")" "$(sha "$v/DESIGN.md")"
  is "10 symlink" "$(test -L "$w/DESIGN.md" && readlink "$w/DESIGN.md")" ".v2p/DESIGN.md"; is "10 work cleared" "$(test -f "$v/work/brand-x.md" && echo yes)" ""
  # 12. an edit after finalize breaks the receipt
  cp "$v/DESIGN.md" "$base/d-$SH"; echo x >> "$v/DESIGN.md"; has "12 tamper" "$(sh "$S/check-pass.sh" "$v/DESIGN.md" "$v/.brand-pass")" "changed after finalize"; cp "$base/d-$SH" "$v/DESIGN.md"
  # 13. archive-cycle: a reviewed cycle with a passed brand moves into .v2p/cycles/<date>/, receipts still verify there
  day=$(date +%Y-%m-%d); C=$v/cycles/$day
  mk() { for f in PLAN EXECUTE REVIEW; do echo "# $f" > "$v/$f.md"; done; echo '# amendments' > "$v/PLAN-AMENDMENTS.md"
    sha "$v/PLAN.md" > "$v/.plan-pass"; sha "$v/EXECUTE.md" > "$v/.execute-pass"; sha "$v/REVIEW.md" > "$v/.review-pass"; }
  mk; (cd "$w" && git init -q && git add -A && git commit -qm cycle1)
  A=$(cd "$w" && $SH "$S/archive-cycle.sh" .v2p 2>&1); is "13 exit" $? 0; has "13 archived" "$A" "archived: .v2p/cycles/$day (7 files); Next: /v2p mapping (cycle 2)"
  has "13 plan receipt verifies in the archive" "$(sh "$S/check-pass.sh" "$C/PLAN.md" "$C/.plan-pass")" "OK:"
  is "13 REVIEW moved" "$(test -f "$v/REVIEW.md" && echo yes)" ""; is "13 brief + design kept" "$(test -f "$v/BRIEF.md" && test -f "$v/DESIGN.md" && echo yes)" yes
  is "13 git mv (renames staged)" "$(cd "$w" && git diff --cached --name-status | grep -c '^R')" 7
  echo '# REVIEW' > "$v/REVIEW.md"; sha "$v/REVIEW.md" > "$v/.review-pass"
  A=$(cd "$w" && $SH "$S/archive-cycle.sh" .v2p 2>&1); is "13 second run exit" $? 1; has "13 dest exists" "$A" "cycles/$day exists"
  rm -r "$C"; mv "$v/.brand-pass" "$base/bp-$SH"
  A=$(cd "$w" && $SH "$S/archive-cycle.sh" .v2p 2>&1); is "13 no brand receipt exit" $? 1; has "13 no brand receipt" "$A" "DESIGN.md does not match its receipt"
  is "13 nothing moved" "$(test -f "$v/REVIEW.md" && test ! -e "$C" && echo yes)" yes
  # 13b. a placeholder DESIGN.md over a reviewed cycle is kept, not archived (live: it re-recorded the shipped tokens
  # and opened an empty cycle 2)
  sed 's/^description: .*/description: PLACEHOLDER — neutral tokens until brand.pdf arrives/' "$base/d-$SH" > "$v/DESIGN.md"; sha "$v/DESIGN.md" > "$v/.brand-pass"
  A=$(cd "$w" && $SH "$S/archive-cycle.sh" .v2p 2>&1); is "13b placeholder exit" $? 0; has "13b kept" "$A" "kept: DESIGN.md is a placeholder"
  has "13b next deploy" "$A" "Next: /v2p deploy"; is "13b nothing moved" "$(test -f "$v/REVIEW.md" && test ! -e "$C" && echo yes)" yes
  cp "$base/d-$SH" "$v/DESIGN.md"; mv "$base/bp-$SH" "$v/.brand-pass"
  # 11. falsifiers on the good file: each changes one thing and expects the named FAIL (exit 1, nothing written)
  good; run; is "11 good exit" $rc 0; has "11 good PASS" "$out" "PASS: 6 colors, 2 typography roles, 3 components, lint 0 errors"
  nw() { is "11 $1 exit" $rc 1; has "11 $1" "$out" "$2"; is "11 $1 nothing written" "$(test -f "$w/.v2p/DESIGN.md" && echo yes)" ""; }
  good; ins '^## Voice$' '## Motion
- Approach: expressive
'; run; nw "duplicate Motion" "section 'Motion' appears 2 times"
  good; awk '/^## Overview$/{o=1} /^## Colors$/{o=0;c=1} /^## Typography$/{c=0} o{ov=ov $0 "\n";next} c{co=co $0 "\n"; next} /^## Typography$/{printf "%s%s", co, ov} {print}' "$P" > "$P.new" && mv "$P.new" "$P"
  run; nw "Overview after Colors" "lint warning section-order"
  good; rep "$MA" "$MA "; run; nw "trailing space" "Must-Avoid first bullet is '$MA '"
  good; sed 's/ · Must-avoid: .*//' "$src/BRIEF.md" > "$w/.v2p/BRIEF.md"; rep "$MA" '- BRIEF §6: none'; run; is "11 BRIEF without Must-avoid → none exit" $rc 0
  good; rep "$MA" '- BRIEF §6: none'; run; nw "none while BRIEF has one" "Must-Avoid first bullet is '- BRIEF §6: none'"
  good; printf 'pdf bytes\n' > "$w/brand.pdf"; ins '^- schema: ' '- guide: brand.pdf · sha256: 0000000000000000000000000000000000000000000000000000000000000000'
  run; nw "wrong sha" "Sources guide brand.pdf sha256 mismatch"
  good; printf 'pdf bytes\n' > "$w/brand.pdf"; ins '^- schema: ' "- guide: brand.pdf · sha256: $(sha "$w/brand.pdf")"; run; is "11 right sha exit" $rc 0
  good; ins '^- schema: ' '- guide: brand.pdf · sha256: 0000000000000000000000000000000000000000000000000000000000000000'; run; nw "guide file missing" "Sources guide brand.pdf missing"
  good; ins '^- schema: ' '- guide: brand.pdf'; run; nw "guide without sha" "Sources guide brand.pdf has no '· sha256: <hex>'"
  good; ins '^- schema: ' '- guide: https://example.com/brand'; run; is "11 URL guide needs no sha" $rc 0
  good; ins '^- schema: ' '- mood: x'; run; nw "unknown kind" "Sources bullet kind unknown: - mood: x"
  good; ins '^- schema: ' '- inspired: VoltAgent/awesome-design-md/x@abc'; run; nw "inspired is not a kind (reference sites: mood only)" "Sources bullet kind unknown: - inspired:"
  good; awk '/^## Voice$/{v=1} /^## Logo Rules$/{v=0} v' "$P" > "$w/voice"
  awk '/^## Voice$/{v=1} /^## Logo Rules$/{v=0} !v' "$P" | V=$w/voice awk '/^## Do.s and Don.ts$/{while ((getline l < ENVIRON["V"]) > 0) print l} {print}' > "$P.new" && mv "$P.new" "$P"
  run; nw "Voice before Do's" "must follow the eight canonical sections"
  good; rep '  on-surface: "#1E293B"' '  on-surface: "#1E293B"
  unused: "#123456"'; run; is "11 orphan color exit" $rc 0; has "11 orphan NOTE" "$out" "NOTE: lint orphaned-tokens"; has "11 orphan counted" "$out" "/ 1 warnings noted"
  good; rep '  primary: "#C2410C"' '  primary: #C2410C'; run; nw "unquoted hex" "colors.primary is not 6-digit hex (#C2410C)"
  # 16. the error colour pair (a UI error state needs a token; execute never invents one) and its component, which is
  # what makes the linter measure its contrast
  good; rep '  error: "#B91C1C"' ''; run; nw "no colors.error" "frontmatter missing colors.error"
  good; rep '  on-error: "#FFFFFF"' ''; run; nw "no colors.on-error" "frontmatter missing colors.on-error"
  good; rep '    textColor: "{colors.on-error}"' '    textColor: "{colors.on-surface}"'; run; nw "alert-error pairing" "components.alert-error.textColor must be {colors.on-error}"
  good; awk '$0 == "  alert-error:" { getline; getline; next } { print }' "$P" > "$P.new" && mv "$P.new" "$P"; run; nw "no alert-error" "frontmatter missing components.alert-error.backgroundColor"
  good; rep '  error: "#B91C1C"' '  error: "#FCA5A5"'; run; nw "error contrast" "lint warning contrast-ratio"
  good; rep 'name: Pawsley Grooming' 'name:'; run; nw "empty name" "frontmatter missing name"
  good; sed '1d' "$P" > "$P.new" && mv "$P.new" "$P"; run; nw "no opening fence" "FAIL: no frontmatter"
  good; awk '$0 == "## Motion" { skip = 1; next } skip && /^## / { skip = 0 } !skip' "$P" > "$P.new" && mv "$P.new" "$P"; run; is "11 no Motion section passes (optional)" $rc 0
  good; echo x > "$w/DESIGN.md"; run; nw "regular root DESIGN.md" "root DESIGN.md is a regular file"
  # 15. adopt (BRIEF §1 Code: existing): a regular root DESIGN.md is the project's own design doc (field test V5: its guard
  # read it): PASS, kept byte for byte, never linked. Greenfield with the same file still FAILs (control).
  code() { awk -v c="$1" '{ print } /^- Profile: / { print "- Code: " c }' "$src/BRIEF.md" > "$w/.v2p/BRIEF.md"; }
  own() { printf '# Project design system\n- primary: light #2E7D46 / dark #4CAF6A\n' > "$w/DESIGN.md"; ds=$(sha "$w/DESIGN.md"); }
  good; code 'existing at .'; own; run; is "15 adopt exit" $rc 0
  has "15 adopt PASS names it" "$out" "-> $w/.v2p/DESIGN.md, root DESIGN.md: project-owned, kept"; hasnt "15 adopt no symlink claim" "$out" "+ DESIGN.md symlink"
  is "15 adopt root byte for byte" "$(sha "$w/DESIGN.md")" "$ds"; is "15 adopt root not a symlink" "$(test -L "$w/DESIGN.md" && echo yes)" ""
  is "15 adopt receipt" "$(cat "$w/.v2p/.brand-pass")" "$(sha "$w/.v2p/DESIGN.md")"
  good; code greenfield; own; run; nw "greenfield regular root (control)" "root DESIGN.md is a regular file"
  is "15 greenfield root untouched" "$(sha "$w/DESIGN.md")" "$ds"
  good; code 'existing at .'; run; is "15 adopt without a root DESIGN.md exit" $rc 0
  is "15 adopt without a root DESIGN.md links" "$(test -L "$w/DESIGN.md" && readlink "$w/DESIGN.md")" ".v2p/DESIGN.md"
  good; code 'existing at .'; echo old > "$w/.v2p/DESIGN.md"; ln -s .v2p/DESIGN.md "$w/DESIGN.md"; run; is "15 adopt re-run over v2p's link exit" $rc 0
  has "15 adopt link is not project-owned" "$out" "(+ DESIGN.md symlink)"
  # 16. live re-test: the link was an untracked file, so execute Step 0 stopped on it; in a git repo it goes in
  # .git/info/exclude (local, never committed), once. A re-theme's brand-incumbent.md survives for mapping cycle 2.
  good; mkdir -p "$w/sub"; (cd "$w" && git init -q && git add -A && git commit -qm base); mv "$w/.v2p" "$w/sub/.v2p"; w0=$w; w=$w/sub; P=$w/.v2p/DESIGN.draft.md
  echo inc > "$w/.v2p/work/brand-incumbent.md"; echo x > "$w/.v2p/work/brand-x.md"; run; is "16 exit" $rc 0
  is "16 link not untracked" "$(cd "$w0" && git status --porcelain --untracked-files=all -- sub/DESIGN.md)" ""
  is "16 exclude names the link" "$(grep -cx '/sub/DESIGN.md' "$w0/.git/info/exclude")" 1
  is "16 incumbent kept" "$(cat "$w/.v2p/work/brand-incumbent.md" 2>/dev/null)" inc; is "16 other work cleared" "$(test -f "$w/.v2p/work/brand-x.md" && echo yes)" ""
  cp "$src/DESIGN.good.md" "$P"; run; is "16 re-run exclude once" "$(grep -cx '/sub/DESIGN.md' "$w0/.git/info/exclude")" 1
  good; run PATH=/usr/bin:/bin; nw "no npx" "designmd linter unavailable"
  good; rep 'Next: /v2p mapping' 'Next: later'; run PATH=/usr/bin:/bin; has "11 no npx: own checks still run" "$out" "no 'Next: /v2p mapping' (or"
  good; rep 'description: Warm, precise, local — sunlit orange on cream, deep navy text, calm energy' 'description: PLACEHOLDER — neutral tokens until brand.pdf arrives'
  run; is "11 placeholder exit" $rc 0; has "11 placeholder status" "$out" "status placeholder"
  # 14. lint parser against a fake npx (captured real JSON): the rule and severity fields decide, not the exit code alone
  fk=$base/fake-$SH; mkdir -p "$fk"; printf '#!/bin/sh\ncat "$FAKE_JSON"; exit "${FAKE_RC:-0}"\n' > "$fk/npx"; chmod +x "$fk/npx"
  cp "$src/DESIGN.md" "$base/bad-$SH.md"; npx --offline -y -p @google/design.md@0.4.0 designmd lint "$base/bad-$SH.md" --format json > "$fk/real.json" 2>/dev/null
  sed 's/"rule"/"rulx"/' "$fk/real.json" > "$fk/rulx.json"; sed 's/"severity"/"severitx"/' "$fk/real.json" > "$fk/sevx.json"
  good; FAKE_JSON=$fk/real.json FAKE_RC=1; export FAKE_JSON FAKE_RC; run "PATH=$fk:$PATH"
  has "14 control: broken-ref" "$out" "FAIL: lint error broken-ref"; has "14 control: contrast" "$out" "FAIL: lint warning contrast-ratio"
  FAKE_JSON=$fk/rulx.json; run "PATH=$fk:$PATH"; hasnt "14 rulx: no broken-ref" "$out" "broken-ref"; hasnt "14 rulx: contrast not FAIL" "$out" "lint warning contrast-ratio"
  has "14 rulx: error still FAILs by severity, named by path" "$out" "FAIL: lint error components.button-primary"
  FAKE_JSON=$fk/sevx.json; run "PATH=$fk:$PATH"; hasnt "14 sevx: no lint FAIL" "$out" "FAIL: lint"; has "14 sevx: exit belt" "$out" "FAIL: designmd exit 1"
  FAKE_JSON=$fk/real.json; FAKE_RC=0; sed 's/"rule": "broken-ref"/"rule": "x"/; s/"severity": "error"/"severity": "info"/' "$fk/real.json" > "$fk/info.json"; FAKE_JSON=$fk/info.json
  run "PATH=$fk:$PATH"; has "14 info is a NOTE" "$out" "NOTE: lint info x:"
  unset FAKE_JSON FAKE_RC
done
SH=all; is "9 source untouched" "$(cat "$src/BRIEF.md" "$src/DESIGN.md" "$src/DESIGN.good.md" | shasum -a 256)" "$sum0"
echo "test-finalize-brand: $fails failures (scratch: $base)"
# a passing run leaves nothing behind (180 stale scratch dirs had piled up in $TMPDIR); a failing one keeps it to inspect
[ "$fails" -eq 0 ] && rm -rf "$base"
[ "$fails" -eq 0 ]
