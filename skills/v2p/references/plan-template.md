# PLAN template

Copy the block below into `.v2p/PLAN.md` and replace every `<…>`. §2–§6 are v2p's additions around the plan method's own task structure.

````
# <project name> Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** <one sentence = BRIEF §3 + §4 90-day metric>
**Architecture:** <2–3 sentences>
**Tech Stack:** <from §2 below>
**Spec:** .v2p/BRIEF.md · .v2p/SCAVENGE.md (<or: scavenge: skipped>) · .v2p/DESIGN.md

## Global Constraints
<one line each, verbatim from BRIEF §5 non-goals, §7 constraints, standards hard rules: no `any`, no secrets in client code>

## Review Focus
<the five uncovered inputs — writing-plans rule; each gets a test in the owning task>

## Architecture
<data flow, one line per hop: client → host → each §2 provider it calls (core.md "Architecture Map")>

## Threat Model
<assets; entry points (one per §2 provider that receives traffic or webhooks); top 5 abuse cases, each with the task that mitigates it; the task that writes docs/threat-model.md (core.md threat-model item)>

## 2. Providers
| provider | plan at launch | $/month | wiring rows | decision |
|---|---|---|---|---|
| <Cloudflare Workers> | <Free (commercial yes) / Vercel Hobby while pre-revenue → Cloudflare Workers at the first commercial use> | <0> | <W… rows> | answered / defaulted: <reason; commercial yet: yes/no> |
Total monthly at launch: $<sum> (<arithmetic shown>)
<only when the total exceeds BRIEF §7 Budget/month and the user approved it:> Over budget approved by user: <reason in the user's words>

## 3. Skills
| skill (installed) | used in task |
|---|---|
Optional, install first: <suggested rows or none>

## 4. Standards (pre-filled; execute fills evidence)
| item | file | status | evidence |
|---|---|---|---|
| <label> | core.md | pending | |
| <label> | landing.md | N/A — <reason citing BRIEF §> | |
Rows: <n> = <core> + <web> + <profile> (measured from BRIEF §9 files)

## 4b. Landing sections (landing profile only; omit the heading otherwise)
| section (references/landing-10-sections.md) | kept / omitted — reason in BRIEF §10 | task that meets its Check |
|---|---|---|

## 5. Tasks
### Task 1: <name>
**Files:** …  **Interfaces:** …
<Files rule: a scaffold/generator task lists the generator's output files (or a glob such as `src/app/*`); every file path named in **Interfaces:** appears in this task's **Files:** or an earlier task's>
**Verifier:** mechanical: `<command>` → `<expected output/exit code>`   |   manual: <who checks what, where>
<Verifier convention: self-checking commands (`test "$(cmd)" = 4`, `grep -q`, `set -e` chains); execute treats exit 0 as pass and compares only bare-number expecteds. Absence: `! grep -rqE '<re>' <path>`. Counts: `grep -c`, or `wc -l | tr -d ' '` — never compare raw `wc -l` (macOS pads it). No bare `&`: a server is started by the test runner (e.g. Playwright `webServer`) or by a script that waits for the port. Every `curl` carries `-m <s>`. Tokens task: `sed -n '/^colors:/,/^[a-z]/p' .v2p/DESIGN.md | grep -oE '#[0-9a-fA-F]{6}' | sort -u | while read -r c; do grep -qi "$c" src/app/globals.css || exit 1; done` → exit 0>
- [ ] Step 1 … (writing-plans step style)

## 6. Handoff
Tasks: <n> (mechanical <m>, manual <k>). `/ralph-loop` eligible: tasks <ids> (mechanical only, `--max-iterations` required).
Next: /v2p execute
````

***
Copyright © 2026 Rafael Arciniegas. Licensed under the MIT License.
