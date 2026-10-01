#!/bin/sh
# Promote .v2p/DESIGN.draft.md to .v2p/DESIGN.md only if the frontmatter has name, description and the required
# tokens (components.button-primary/page pair {colors.primary}/{colors.on-primary} and {colors.surface}/{colors.on-surface},
# which is what makes the linter's contrast check fire), every color is quoted 6-digit hex, the pinned linter
# (@google/design.md 0.4.0, offline from the npx cache first) reports no error and none of the warnings that matter,
# the eight canonical sections and the v2p sections appear once each (v2p ones after Do's and Don'ts), Must-Avoid's first
# bullet is BRIEF §6 byte for byte, Sources bullets have a known kind (a local guide's sha256 matches), no `---` rule
# outside the frontmatter fence, a `Next: /v2p mapping` line, and no regular root DESIGN.md unless BRIEF §1 says
# `Code: existing` (adopt: it is the project's own design doc, which its guards may read; kept as is, never linked).
# On PASS: receipt .v2p/.brand-pass and, unless kept, a root symlink DESIGN.md -> .v2p/DESIGN.md (design skills read the root file).
# The linter does not catch duplicated sections, a missing name or `---` rules (measured 2026-09-25): these checks do.
# ponytail: YAML read by indentation (2-space, one key per line — the template's rule), not a YAML parser; a flow-style frontmatter fails check 3 and says so.
# Usage: sh finalize-brand.sh [.v2p dir]   (exit 0 PASS · 1 FAIL)
d=${1:-.v2p}; fail=0
[ -d "$d" ] || { echo "FAIL: $d not found"; exit 1; }
d=$(cd "$d" && pwd -P); root=$(dirname "$d"); draft=$d/DESIGN.draft.md; out=$d/DESIGN.md; tmp=${TMPDIR:-/tmp}/fb.$$
trap 'rm -f "$tmp.t" "$tmp.s"' EXIT
[ -f "$draft" ] || { echo "FAIL: $draft missing"; exit 1; }
[ -f "$d/BRIEF.md" ] || { echo "FAIL: $d/BRIEF.md missing"; exit 1; }
# 2. frontmatter fence (line 1 and the first later `---`) and name/description
close=$(awk 'NR == 1 && $0 != "---" { exit } NR > 1 && $0 == "---" { print NR; exit }' "$draft")
[ -n "$close" ] || { echo "FAIL: no frontmatter (line 1 '---' and a closing '---')"; fail=1; close=1; }
fm=$(awk -v c="$close" 'NR > 1 && NR < c' "$draft")
for k in name description; do printf '%s\n' "$fm" | grep -qE "^$k: *[^ ]" || { echo "FAIL: frontmatter missing $k"; fail=1; }; done
# 3. required tokens by indentation: <group>\t, <group>.<key>\t<value>, <group>.<key>.<prop>\t<value> (quotes stripped)
printf '%s\n' "$fm" | awk '
  function v(s) { sub(/^[^:]*: */, "", s); gsub(/^"|"$/, "", s); return s }
  /^[^ ][^:]*:/ { g = $0; sub(/:.*/, "", g); next }
  /^  [^ ][^:]*:/ { k = substr($0, 3); sub(/:.*/, "", k); print g "." k "\t" v(substr($0, 3)); next }
  /^    [^ ][^:]*:/ { p = substr($0, 5); sub(/:.*/, "", p); print g "." k "." p "\t" v(substr($0, 5)) }' > "$tmp.t"
tok() { awk -F'\t' -v p="$1" '$1 == p { print $2; f = 1; exit } END { exit !f }' "$tmp.t"; }
while IFS=' ' read -r p want; do
  got=$(tok "$p") || { echo "FAIL: frontmatter missing $p"; fail=1; continue; }
  [ -z "$want" ] || [ "$got" = "$want" ] || { echo "FAIL: $p must be $want (got '$got')"; fail=1; }
done <<'EOF'
colors.primary
colors.on-primary
colors.surface
colors.on-surface
typography.display.fontFamily
typography.body.fontFamily
rounded.md
spacing.md
components.button-primary.backgroundColor {colors.primary}
components.button-primary.textColor {colors.on-primary}
components.page.backgroundColor {colors.surface}
components.page.textColor {colors.on-surface}
EOF
# 4. every colors.<k> is a quoted 6-digit hex (unquoted `#…` is a YAML comment)
bad=$(printf '%s\n' "$fm" | awk '/^[^ ]/ { c = ($0 ~ /^colors:/); next }
  c && /^  [^ ]/ && $0 !~ /^  [a-z0-9-]+: "#[0-9a-fA-F]{6}"$/ { k = substr($0, 3); v = k; sub(/:.*/, "", k); sub(/^[^:]*: */, "", v); print "FAIL: colors." k " is not 6-digit hex (" v ")" }')
[ -z "$bad" ] || { printf '%s\n' "$bad"; fail=1; }
# 5. linter: pinned, offline cache first, one online attempt; no JSON → FAIL (never a degraded receipt)
lint() { npx $1 -y -p @google/design.md@0.4.0 designmd lint "$draft" --format json 2>&1; }
lo=$(lint --offline); rc=$?
case $lo in *'"findings"'*) ;; *) lo=$(lint ""); rc=$? ;; esac
nw=0
case $lo in
  *'"findings"'*)
    # one finding per { … } block; a finding without "rule" (e.g. an invalid dimension) is named by its "path"
    lf=$(printf '%s\n' "$lo" | awk '
      function v(s) { sub(/^[^:]*: *"/, "", s); sub(/",? *$/, "", s); return s }
      /^ *\{ *$/ { sev = rule = msg = path = ""; next }
      /^ *"severity":/ { sev = v($0) } /^ *"rule":/ { rule = v($0) } /^ *"message":/ { msg = v($0) } /^ *"path":/ { path = v($0) }
      /^ *\},? *$/ && sev != "" { if (rule == "") rule = path
        if (sev == "error") print "FAIL: lint error " rule ": " msg
        else if (sev == "warning" && rule ~ /^(contrast-ratio|section-order|missing-primary|missing-typography|unknown-key)$/) print "FAIL: lint warning " rule ": " msg
        else print "NOTE: lint " (sev == "warning" ? "" : sev " ") rule ": " msg
        sev = "" }')
    [ -z "$lf" ] || printf '%s\n' "$lf"
    printf '%s\n' "$lf" | grep -q '^FAIL: ' && fail=1
    nw=$(printf '%s\n' "$lf" | grep -c '^NOTE: lint [^ ]*:')
    [ "$rc" -eq 0 ] || printf '%s\n' "$lf" | grep -q '^FAIL: lint error' || { echo "FAIL: designmd exit $rc"; fail=1; } ;;
  *) echo "FAIL: designmd linter unavailable (npx cache has no @google/design.md@0.4.0 and no network): run 'npx -p @google/design.md@0.4.0 designmd --help' once online"; fail=1 ;;
esac
# 6. sections: each once; Motion at most once; the v2p ones after the eight canonical ones (their order is lint's section-order)
while IFS= read -r s; do n=$(grep -cxF "## $s" "$draft")
  [ "$n" -eq 1 ] || { echo "FAIL: section '$s' appears $n times (want 1)"; fail=1; }
done <<'EOF'
Overview
Colors
Typography
Layout
Elevation & Depth
Shapes
Components
Do's and Don'ts
Voice
Logo Rules
Imagery
Must-Avoid
Sources
EOF
n=$(grep -cxF '## Motion' "$draft"); [ "$n" -le 1 ] || { echo "FAIL: section 'Motion' appears $n times (want 0 or 1)"; fail=1; }
dd=$(grep -nxF "## Do's and Don'ts" "$draft" | head -n 1 | cut -d: -f1)
v1=$(grep -nxE '## (Motion|Voice|Logo Rules|Imagery|Must-Avoid|Sources)' "$draft" | head -n 1 | cut -d: -f1)
[ -z "$dd" ] || [ -z "$v1" ] || [ "$v1" -gt "$dd" ] || { echo "FAIL: v2p sections (Motion, Voice, Logo Rules, Imagery, Must-Avoid, Sources) must follow the eight canonical sections"; fail=1; }
# 7. Must-Avoid first bullet = BRIEF §6 Must-avoid, byte for byte
want=$(grep -m1 -o 'Must-avoid:.*' "$d/BRIEF.md" | sed 's/^Must-avoid: *//; s/ *$//')
case $want in ''|'<'*) want=none ;; esac
got=$(awk '$0 == "## Must-Avoid" { f = 1; next } f && NF { print; exit }' "$draft")
[ "$got" = "- BRIEF §6: $want" ] || { echo "FAIL: Must-Avoid first bullet is '$got' (want '- BRIEF §6: $want')"; fail=1; }
# 8. Sources: ≥1 bullet, known kinds; a local guide carries a sha256 that matches the file
awk '$0 == "## Sources" { f = 1; next } f && (/^## / || /^Next:/) { exit } f && NF' "$draft" > "$tmp.s"
[ -s "$tmp.s" ] || { echo "FAIL: Sources is empty"; fail=1; }
while IFS= read -r l; do
  printf '%s\n' "$l" | grep -qE '^- (guide|reference|generated|kit|font|placeholder|schema): ' || { echo "FAIL: Sources bullet kind unknown: $l"; fail=1; continue; }
  case $l in '- guide: http://'*|'- guide: https://'*|'- guide: '*'://'*) continue ;; '- guide: '*) ;; *) continue ;; esac
  g=$(printf '%s\n' "$l" | sed 's/^- guide: //; s/ · .*//'); h=$(printf '%s\n' "$l" | sed -n 's/.* · sha256: \([0-9a-f]*\).*/\1/p')
  if [ -z "$h" ]; then echo "FAIL: Sources guide $g has no '· sha256: <hex>'"; fail=1
  elif [ ! -f "$root/$g" ]; then echo "FAIL: Sources guide $g missing"; fail=1
  elif [ "$(shasum -a 256 "$root/$g" | cut -d' ' -f1)" != "$h" ]; then echo "FAIL: Sources guide $g sha256 mismatch"; fail=1; fi
done < "$tmp.s"
# 9–11. no `---` rule outside the fence; Next line; root DESIGN.md is not a regular file
hr=$(awk -v c="$close" '$0 == "---" && NR != 1 && NR != c { print NR }' "$draft" | tr '\n' ' ')
[ -z "$hr" ] || { echo "FAIL: '---' rule on lines ${hr% } (use ***)"; fail=1; }
grep -qxE 'Next: /v2p (mapping|deploy)' "$draft" || { echo "FAIL: no 'Next: /v2p mapping' (or, placeholder over a reviewed cycle, 'Next: /v2p deploy') line"; fail=1; }
own=; [ -f "$root/DESIGN.md" ] && [ ! -L "$root/DESIGN.md" ] && own=1
[ -n "$own" ] && ! grep -qE '^- Code: *existing' "$d/BRIEF.md" && { echo "FAIL: root DESIGN.md is a regular file; move it aside (it will be a symlink to .v2p/DESIGN.md)"; fail=1; }
[ "$fail" -eq 0 ] || { echo "FAIL: DESIGN.md not written"; exit 1; }
nc=$(grep -c '^colors\.' "$tmp.t"); nt=$(grep -cE '^typography\.[^.]+	' "$tmp.t"); ncp=$(grep -cE '^components\.[^.]+	' "$tmp.t")
st=$(sed -n 's/^Status: \([a-z]*\).*/\1/p' "$draft" | head -n 1)
printf '%s\n' "$fm" | grep -q '^description: *"\{0,1\}PLACEHOLDER' && st=placeholder
mv "$draft" "$out"
# Receipt: mapping, execute's UI gate and review accept DESIGN.md only if its hash matches this file.
shasum -a 256 "$out" | cut -d' ' -f1 > "$d/.brand-pass"
if [ -n "$own" ]; then rd=", root DESIGN.md: project-owned, kept"; else ln -sfn "$(basename "$d")/DESIGN.md" "$root/DESIGN.md"; rd=" (+ DESIGN.md symlink)"; fi
rm -f "$d"/work/brand-*
echo "PASS: $nc colors, $nt typography roles, $ncp components, lint 0 errors / $nw warnings noted, status ${st:-final} -> $out$rd"
