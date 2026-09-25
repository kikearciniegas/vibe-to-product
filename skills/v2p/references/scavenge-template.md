# SCAVENGE template

Copy the block below into `.v2p/SCAVENGE.md` and replace every `<…>`.
Rule: every bullet and row in §1–§6 must contain `http` and `accessed`; a row without both is deleted before writing.

````
# SCAVENGE — <project name>
written: <YYYY-MM-DD> by v2p scavenge · reads: .v2p/BRIEF.md (<written date>)

## 1. Reference architecture (Q1)
- <one starter/architecture> · why it fits BRIEF §1/§8: <one line> · <URL> · accessed <date>

## 2. The one job — proven pattern (Q2)
- <pattern> · source rank: official | repo (pushed <date>, stars) · <URL> · accessed <date>

## 3. Integrations and money (Q3)
| integration | covered by stack guide row | extra source (only if not in guide) |
|---|---|---|
| <name> | W<n> | — |

TBD tool (one table per TBD integration; every cell sourced):
| candidate | price for BRIEF §2 scale | §6 locales supported | meets §4 acceptance lines | URL · accessed |
|---|---|---|---|---|
Default: <candidate> · why: <one line>

## 4. Obligations from data sensitivity (Q4)
| flag (BRIEF §7) | primary text | what it requires (one line) | URL · accessed |
|---|---|---|---|

## 5. Audience and adjacent products (Q5) · Existing code (Q6)
- Adjacent: <product> — <what users complain about, last 30 days> · <URL> · accessed <date>
- Code inventory (brownfield only): stack <…> · entry points <…> · env vars referenced <n> · tests <yes/no, runner> · deps created <6 months: <list|none> · TODO/FIXME <n> · files >200 lines <n>

## 6. Recent changes, last 30 days (Q7)
| subject | last-30-days search (query · results n) | signal | official changelog/news, last 30 days | effect on rows above |
|---|---|---|---|---|
| <name> | <query> · <n> | <change · URL · accessed, or "none found · searched: …"> | <entries in window, or "no entries in window"> · <URL> · accessed <date> | <row updated \| none> |

## 7. Budget and tools
fetches: Q1–Q5 <n>/20 · Q7 <n>/5 · links: <ok>/<total> ok · time: <min> · tools: <names used, or none>
[CONFLICT] rows: <n> · [CHECK] rows: <n> · [OPEN] rows: <n>

## 8. Open
- [OPEN: <question> — answer needed by <mapping task>]   (or: none)

Next: /v2p brand
````

***
Copyright © 2026 Rafael Arciniegas. Licensed under the MIT License.
