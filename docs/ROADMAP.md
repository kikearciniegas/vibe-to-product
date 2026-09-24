# v2p roadmap

Status as of 2026-09-23. Decisions come from the user; each slice gets a spec in `docs/specs/` before it is built.

## Done
- **Slice 1:** router, handshake, standards by profile, portable pack.
- **Slice 2:** scavenge (with the `finalize-scavenge.sh` gate and Q7 = /last30days + official changelog), mapping, stack guide, skills catalog.

## Slice 3: adopt + tidy (spec in progress)
- **Adopt:** v2p runs in any folder (empty, new, existing, half-built). For existing code it scans the project, derives a BRIEF with every value marked `inferred`, writes an AUDIT, creates the missing files, and merges scattered notes into the standard files.
- **Layout:** `.v2p/` for phase handoffs (BRIEF, SCAVENGE, PLAN, REVIEW, DEPLOY, AUDIT); `docs/` for ARCHITECTURE, DECISIONS and threat-model; README, CHANGELOG and .env.example at the root.
- **Tidy:** a rule set of which files and folders should exist, checked by `tidy-check.sh`. Cleanup goes through `quarantine.sh`: you approve the list, the files move to `~/.v2p-backups/<project>/<timestamp>/` with a manifest and a restore command, and nothing is ever hard-deleted.
- **Modularity:** rules in `core.md` plus an audit section.
- **Code graph:** code-review-graph, with Serena for symbols and `rg` as the fallback.
- **Crash-safe checkpoints:** subagent results are saved to `.v2p/work/` so a re-run resumes instead of starting over.
- **Hook-enforced gates (proposal):** a PreToolUse hook blocks direct writes to the handoff files. Installing it into global settings is a separate decision for you.

## Slice 4: execute + review, with drift checks
Checks run on a tiered cadence:
- **Every task:** the diff against PLAN, plus `ponytail-audit` on the diff.
- **Every phase:** `/code-review`, `/simplify`, `/security-review`, and `/translation-quality` when i18n is on.
- **Before deploy:** a full `claude-security` scan plus a Strix pentest.

Also available: context7 and `claude-mem:learn-codebase`. There is no `/verify` skill; `superpowers:verification-before-completion` is the equivalent.

## Slice 5: deploy
- Pre-deploy audit and provider choice.
- Strix: not installed; it needs Docker and an LLM API key. It is installed through the installing-third-party-tools skill when first needed.

## Cross-cutting
- **Regression suite:** fixture projects (empty, landing brief, messy brownfield) run headless with `claude -p`. They assert that phase files were read, that the `PASS` lines appear, and that the gates hold. This replaces the manual testing done today.
- **Refresh routine:** a monthly scheduled job re-verifies every `(verified: YYYY-MM)` item and the skills catalog, and proposes a diff for you to approve.
- **Plugin packaging:** a versioned plugin that ships the skill, scripts and hooks. It targets:
  - Claude Code
  - other agents that support the open Agent Skills layout (Codex CLI, Gemini CLI, Cursor; support per agent unverified)
  - desktop apps (Claude Desktop / claude.ai skill upload)
  - ChatGPT and Gemini apps, through `dist/v2p-portable.md`

  To keep this possible, the source stays compatible with that layout: relative paths, POSIX sh scripts, and Claude-only behaviour confined to claude-only blocks and hooks.

## Open items
- Brand-creation phase (the brand guide is still pending in the test project).
- A first test of the portable pack in ChatGPT or Gemini (slice-1 check 12).
- The duplicate `agent-reach` in `~/.agents/skills` (managed by `npx skills`), not cleaned up.

***
Copyright © 2026 Rafael Arciniegas. Licensed under the MIT License.
