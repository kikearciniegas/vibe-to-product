# v2p phase: scavenge

## Purpose
Turn the BRIEF into a short evidence file, `.v2p/SCAVENGE.md`: what already exists (references, docs, blueprints, standards) and, for brownfield, what the current code is.
Nothing is decided here; mapping decides.

## Preconditions
- `.v2p/BRIEF.md` must exist with §11 = `none`. Otherwise print `Run /v2p handshake first.` and stop.
- If `.v2p/SCAVENGE.md` exists: print its `written:` line and offer resume (keep) or re-run.
- Checkpoints: list `.v2p/work/scavenge-*`. A file is reusable when its line-1 `written:` date is today and its `brief:` equals the current BRIEF's `written:` date; print "resuming from <files>" and skip the work it already covers. Any other file is stale: overwrite it, never read it. Line 1 of every checkpoint: `written: <YYYY-MM-DDTHH:MM> · phase: scavenge · part: <q1-5|q7> · brief: <BRIEF written date>`.

## Research questions (derived, not invented)
Exactly these, each skipped when its BRIEF source is empty or `none`:

| # | From BRIEF | Question | Preferred source |
|---|---|---|---|
| Q1 | §1 profile + §8 stack | Reference architecture or official starter for `<profile>` on `<stack>` (one, from the framework/provider vendor) | library/SDK docs, official docs |
| Q2 | §3 the one job | Proven implementation pattern for `<the one job>` (checkout flow, booking, upload, etc.): one official guide or one maintained repo | official docs > repo pushed <6 months, not archived |
| Q3 | §8 integrations + money model | One row per integration listed in §8. For each: the exact keys/webhooks needed. If the tool is TBD, compare 2–3 candidates on price vs §7 budget, the §6 locales and the §4 acceptance lines, and name one default. **Look in `references/stack/wiring.md` first; go to the web only for a provider not in the guide.** | stack guide, then official docs |
| Q4 | §7 data sensitivity | The primary legal text that applies to the flags set (personal data, payments, health, minors, EU accessibility) for the audience's jurisdiction. Cite the law/regulator page, not a blog. Never state obligations from memory. | government/regulator or standards body |
| Q5 | §2 audience | Up to 3 adjacent products and what their users complain about in the last 30 days (pain language reused in copy and the FAQ) | social-trends search, then web search |
| Q7 | Q1–Q4 answers | **Always runs.** For each subject named in Q1–Q4 (the starter/framework, each Q3 tool, the Q4 law; max 5): what changed in the last 30 days (pricing or plan limits, deprecations, breaking releases, security advisories, outages, acquisitions or migrations, legal amendments). Two sources per subject: (1) a last-30-days search for community signals, (2) the subject's official changelog, release notes, pricing or regulator news page (for a hosted product, the vendor's product changelog, not an open-source repo's releases), read for entries dated in the last 30 days. A community signal is a lead, not a fact: it changes a row only once the official page confirms it. | last-30-days search + official changelog/news page |
| Q6 | §1 `Code: existing at <path>` (brownfield only) | Brownfield: copy the inventory line from `.v2p/AUDIT.md` §1 (written by adopt). AUDIT missing → print `Run /v2p adopt first.` and stop. | `.v2p/AUDIT.md`; no web, no code search |

## Source-quality rules
1. Rank: official docs > maintained repos (pushed within 6 months, not archived, >100 stars or vendor-owned) > posts/forums/social. A lower rank never overrides a higher one on a technical fact.
2. Every claim row carries `source URL · accessed YYYY-MM-DD`. No URL → the row is deleted, not kept as "known". The URL must itself show the claim: a claim with no fetched evidence is deleted, never pinned to a nearby source. A deferred question writes only `[OPEN]`, no findings.
3. Social/trend results (Q5) inform copy and FAQ only; never a technical decision. Q7 signals change a row only once an official page confirms them; unconfirmed ones are written `[CHECK: <signal> · <URL>]` for mapping.
4. Numbers (limits, prices) are copied verbatim with the page's own wording; if the page did not show it, write `(not on page)`.
5. A "nothing changed / none found" result is written as `none found · searched: <source or query>, last 30 days`, never as "confirmed". A generic landing or index page is not evidence for a specific claim.
6. Findings come only from pages fetched in this run, or from this run's `.v2p/work/` files, in every phase. Never rebuild them from memory, prior-session summaries or observation logs (e.g. claude-mem): those are leads to re-fetch, not evidence.
7. Q5 is about the §2 audience (end users), not developers. If no end-user complaints are found, Q5 writes `[OPEN]`; never substitute issue trackers or PRs.
8. Only three markers exist: `[OPEN]`, `[CONFLICT]`, `[CHECK]`. The counts in §7 must equal the markers in the file.
9. Disagreement between two official sources → record both, mark `[CONFLICT]`, mapping decides.

## Link check (before writing)
Every URL in the draft is opened once more; any that does not load (4xx/5xx, timeout) removes its row, or the row is re-sourced within budget. §7 records `links: <ok>/<total> ok`. A file is written only when the two numbers are equal.
<!-- claude-only -->
In Claude Code the check is a script, not a judgement. Write the draft to `.v2p/SCAVENGE.draft.md` (never `SCAVENGE.md` directly), then run `sh <this skill's dir>/scripts/finalize-scavenge.sh .v2p`. It link-checks every URL (401/403/429 count as present but bot-blocked), refuses any §6 row that says "not searched", stamps `links: n/n ok`, and only then renames the draft to `SCAVENGE.md`. On `FAIL`, fix what it names and run it again; never write `SCAVENGE.md` by hand.
<!-- /claude-only -->

## Budget and stop rule
- ≤3 sources per question; stop a question when two official sources agree.
- Q1–Q5: **20 fetches** (every page or docs fetch counts). Q7: **5 reserved** for the official changelog/news page, one per subject (last-30-days searches are not counted as fetches); Q1–Q5 may never spend them. ~30 minutes wall time. The count is written into SCAVENGE.md §7.
- Q7 runs after Q1–Q4 are answered and before the file is assembled. A community signal that needs a second official page beyond the one reserved fetch is written as `[CHECK]`.
- When the cap hits, unanswered questions are written as `[OPEN: <question> — answer needed by <mapping task>]`, never guessed.

## Tools and degradation
- Use whatever web-reading tool your runtime has; if none, ask the user to paste the pages.
<!-- claude-only -->
- context7 MCP: first choice for library/SDK docs (`resolve-library-id` → `query-docs`).
- WebFetch/WebSearch: default for everything else.
- **Firecrawl: use only if a `firecrawl` / `firecrawl-scrape` skill appears in this session's available-skills list. It is installed in the plugin cache but disabled** (`~/.claude/settings.json` → `firecrawl@claude-plugins-official=false`, verified 2026-09-23), so by default its tools are not loaded. Do not run `npx firecrawl-cli`, do not install, do not enable; write `firecrawl: unavailable` in SCAVENGE.md §7. When it is available, prefer `firecrawl-scrape` over WebFetch for JS-rendered pages only.
- `/last30days` (installed, enabled): Q7 always, Q5 when applicable; runs inside the Q7 subagent (step 3); it asks questions only during its one-time first-run setup, which is already done on this machine; works without API keys via WebSearch fallback (reported by the skill's own frontmatter).
- gstack `/browse`: only when a page needs a click or login (pricing calculators, dashboards). Never `mcp__claude-in-chrome__*`.
- Perplexity: not installed; do not reference.
- SCAVENGE.md §7 tools line in Claude Code: `context7 <used|no> · firecrawl: <used|unavailable> · last30days <used|failed: reason> · browse <used|no>`.
<!-- /claude-only -->

## Execution
Portable: do steps 1–4 yourself in one pass. List the applicable questions, answer them within the budget, fill `references/scavenge-template.md`, write `.v2p/SCAVENGE.md` (or print it in one code block if you cannot write files), then print `Next: /v2p mapping`.

<!-- claude-only -->
### Claude Code
1. Main thread reads BRIEF, lists the applicable questions and prints them (≤7 lines).
2. Spawn in parallel: `planner` (Fable) with Q1–Q5 and the rules above; it returns the filled §1–§5 text and its fetch count (planner does not write files). The main thread writes that result to `.v2p/work/scavenge-q1-5.md` the moment it arrives, before any other action. Brownfield Q6 is copied from `.v2p/AUDIT.md` §1 by the main thread; no subagent.
3. Q7 (and Q5's social search) runs in **one `quick` subagent, never on the main thread**: the `last30days` skill is ~240 KB, and loading it once per subject exhausted the main context in testing. The subagent invokes the `last30days` skill through the Skill tool **once**, for the first subject (topic: `<subject> changes`). For each remaining subject it reruns the exact engine command that first run used, changing only the topic. Before returning, it writes its result to `.v2p/work/scavenge-q7.md` itself. It returns only the §6 table rows: each row has the finding with its URL, or `none found · searched: /last30days "<topic>"`, or, after two failures, `none found · searched: /last30days failed (<error>)`. Then, for each subject, it reads the official changelog/news page (one reserved fetch) and records entries dated in the last 30 days, or `no entries in window · <URL>`. A community signal is marked confirmed only when that page shows it.
4. Main thread assembles `.v2p/SCAVENGE.draft.md` from `references/scavenge-template.md` and runs `scripts/finalize-scavenge.sh` until it prints `PASS`, prints the path and `Next: /v2p mapping`.

`AskUserQuestion` only for resume/re-run. Nothing else is asked; open items go to `[OPEN: …]`.
<!-- /claude-only -->

***
Copyright © 2026 Rafael Arciniegas. Licensed under the MIT License.
