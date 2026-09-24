#!/bin/sh
# Generates dist/v2p-portable.md from skills/v2p. Usage: sh build-portable.sh [output-path]
set -eu
cd "$(dirname "$0")"
out="${1:-dist/v2p-portable.md}"
mkdir -p "$(dirname "$out")"
copyright='Copyright © 2026 Rafael Arciniegas. Licensed under the MIT License.'
{
  printf '# v2p portable pack (generated %s; do not edit)\n\n' "$(date +%Y-%m-%d)"
  for p in SKILL.md phases/handshake.md references/brief-template.md \
    phases/scavenge.md phases/mapping.md references/scavenge-template.md references/plan-template.md \
    phases/adopt.md references/audit-template.md references/tidy-rules.md \
    phases/execute.md phases/review.md references/execute-template.md references/review-template.md \
    references/standards/core.md references/standards/web.md references/standards/landing.md \
    references/standards/saas-web.md references/standards/internal-tool.md references/standards/native-app.md \
    references/landing-10-sections.md references/ux-laws.md \
    references/stack/overview.md references/stack/alternatives.md references/stack/wiring.md references/stack/security.md; do
    printf '<!-- source: %s -->\n' "$p"
    awk '
      NR == 1 && $0 == "---" { fm = 1; next }
      fm { if ($0 == "---") fm = 0; next }
      /<!-- claude-only -->/ { skip = 1; next }
      /<!-- \/claude-only -->/ { skip = 0; next }
      skip { next }
      /^Copyright © 2026 Rafael Arciniegas/ { next }
      { print }
    ' "skills/v2p/$p"
    printf '\n'
  done
  printf '%s\n' "$copyright"
} > "$out"
echo "wrote $out ($(wc -c < "$out" | tr -d ' ') bytes)"
