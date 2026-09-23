# v2p phase: scavenge

## Purpose
Turn the BRIEF into a short evidence file, `.v2p/SCAVENGE.md`: what already exists (references, docs, blueprints, standards) and, for brownfield, what the current code is.
Nothing is decided here; mapping decides.

## Preconditions
- `.v2p/BRIEF.md` must exist with §11 = `none`. Otherwise print `Run /v2p handshake first.` and stop.
- If `.v2p/SCAVENGE.md` exists: print its `written:` line and offer resume (keep) or re-run.

## Research questions (derived, not invented)
Exactly these, each skipped when its BRIEF source is empty or `none`:

| # | From BRIEF | Question | Preferred source |
|---|---|---|---|
| Q1 | §1 profile + §8 stack | Reference architecture or official starter for `<profile>` on `<stack>` (one, from the framework/provider vendor) | library/SDK docs, official docs |
| Q2 | §3 the one job | Proven implementation pattern for `<the one job>` (checkout flow, booking, upload, etc.): one official guide or one maintained repo | official docs > repo pushed <6 months, not archived |
| Q3 | §8 integrations + money model | One row per integration listed in §8. For each: the exact keys/webhooks needed. If the tool is TBD, compare 2–3 candidates on price vs §7 budget, the §6 locales and the §4 acceptance lines, and name one default. **Look in `references/stack/wiring.md` first; go to the web only for a provider not in the guide.** | stack guide, then official docs |
| Q4 | §7 data sensitivity | The primary legal text that applies to the flags set (personal data, payments, health, minors, EU accessibility) for the audience's jurisdiction. Cite the law/regulator page, not a blog. Never state obligations from memory. | government/regulator or standards body |
| Q5 | §2 audience | Up to 3 adjacent products and what their users complain about in the last 30 days (pain language reused in copy and the FAQ) | social-trends search, then web search |
| Q6 | §1 `Code: existing at <path>` (brownfield only) | Inventory: stack, entry points, env vars referenced, tests present, dependencies with created-date <6 months, TODO/FIXME count, files >200 lines | code search on the repo; no web |

## Source-quality rules
1. Rank: official docs > maintained repos (pushed within 6 months, not archived, >100 stars or vendor-owned) > posts/forums/social. A lower rank never overrides a higher one on a technical fact.
2. Every claim row carries `source URL · accessed YYYY-MM-DD`. No URL → the row is deleted, not kept as "known". The URL must itself show the claim: a claim with no fetched evidence is deleted, never pinned to a nearby source. A deferred question writes only `[OPEN]`, no findings.
3. Social/trend results (Q5) inform copy and FAQ only; never a technical decision.
4. Numbers (limits, prices) are copied verbatim with the page's own wording; if the page did not show it, write `(not on page)`.
5. Disagreement between two official sources → record both, mark `[CONFLICT]`, mapping decides.

## Budget and stop rule
- ≤3 sources per question; stop a question when two official sources agree.
- Hard cap: **25 fetches total** (every page or docs fetch counts) and ~30 minutes wall time. The count is written into SCAVENGE.md §6.
- Q6 is not budgeted by fetches; it is budgeted by files: read ≤40 files, never the whole tree (use search and symbol lookups).
- When the cap hits, unanswered questions are written as `[OPEN: <question> — answer needed by <mapping task>]`, never guessed.

## Tools and degradation
- Use whatever web-reading tool your runtime has; if none, ask the user to paste the pages.
<!-- claude-only -->
- context7 MCP: first choice for library/SDK docs (`resolve-library-id` → `query-docs`).
- WebFetch/WebSearch: default for everything else.
- **Firecrawl: use only if a `firecrawl` / `firecrawl-scrape` skill appears in this session's available-skills list. It is installed in the plugin cache but disabled** (`~/.claude/settings.json` → `firecrawl@claude-plugins-official=false`, verified 2026-09-23), so by default its tools are not loaded. Do not run `npx firecrawl-cli`, do not install, do not enable; write `firecrawl: unavailable` in SCAVENGE.md §6. When it is available, prefer `firecrawl-scrape` over WebFetch for JS-rendered pages only.
- `/last30days` (installed, enabled): Q5 only; runs on the main thread (needs Bash + AskUserQuestion); works without API keys via WebSearch fallback (reported by the skill's own frontmatter).
- gstack `/browse`: only when a page needs a click or login (pricing calculators, dashboards). Never `mcp__claude-in-chrome__*`.
- Perplexity: not installed; do not reference.
- Brownfield Q6: Serena MCP is installed (`~/.claude.json` `mcpServers.serena`); use `find_symbol`/`get_symbols_overview`; fall back to `rg`. Graph tool: code-review-graph if installed (see `references/skills-catalog.md`); not required.
- SCAVENGE.md §6 tools line in Claude Code: `context7 <used|no> · firecrawl: <used|unavailable> · last30days <used|skipped> · browse <used|no>`.
<!-- /claude-only -->

## Execution
Portable: do steps 1–4 yourself in one pass. List the applicable questions, answer them within the budget, fill `references/scavenge-template.md`, write `.v2p/SCAVENGE.md` (or print it in one code block if you cannot write files), then print `Next: /v2p mapping`.

<!-- claude-only -->
### Claude Code
1. Main thread reads BRIEF, lists the applicable questions, prints them (≤6 lines), and asks one closed question via `AskUserQuestion` only if Q5 is applicable: "Run the social-trends scan (uses /last30days, ~2 min)?" default yes.
2. Spawn in parallel: `planner` (Fable) with Q1–Q5 and the rules above; it returns the filled §1–§5 text and its fetch count (planner does not write files). `quick` (Sonnet) with Q6 for brownfield; it returns the §5 inventory text.
3. Main thread runs `/last30days` for Q5 if accepted.
4. Main thread assembles `.v2p/SCAVENGE.md` from `references/scavenge-template.md`, writes it, prints the path and `Next: /v2p mapping`.

`AskUserQuestion` only for the Q5 opt-in and for resume/re-run. Nothing else is asked; open items go to `[OPEN: …]`.
<!-- /claude-only -->

***
Copyright © 2026 Rafael Arciniegas. Licensed under the MIT License.
