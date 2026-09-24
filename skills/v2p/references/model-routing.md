# Model routing (Claude Code only)

Not included in the portable pack. Read before spawning any agent for a v2p phase.

## Phase → executor → model → skills
| Phase | Executor | Model | Skills |
|---|---|---|---|
| handshake | main thread | whatever `/model` set | none |
| adopt | `quick` (Sonnet) scan → writes .v2p/work/adopt-scan.md; main thread derives BRIEF, runs the gate, writes drafts, runs the scripts | Sonnet | none; Serena; code-review-graph if installed |
| scavenge | `planner` (Fable) research Q1–Q5, returns text; brownfield inventory copied from `.v2p/AUDIT.md` §1; main thread runs `/last30days` and writes the file | Fable; Sonnet | `/last30days` (Q5 only) |
| mapping | `planner` (Fable) via `superpowers:writing-plans` + `writing-plans-extras`; brainstorming only if ≥3 architecture-affecting `deferred` rows; main thread asks provider questions and writes the file | Fable | `superpowers:writing-plans` + `writing-plans-extras`; `superpowers:brainstorming` + `brainstorming-extras` only if BRIEF §10 has ≥3 `deferred` rows that affect architecture |
| execute (stub) | `builder`; `quick` for mechanical steps | Opus; Sonnet | `superpowers:subagent-driven-development` + `subagent-driven-development-extras`; `/ralph-loop` only for tasks with a mechanical verifier, always with `--max-iterations` |
| review (stub) | gstack `/review`, `/qa`; second opinion `/codex` | per skill; OpenAI Codex | `gstack-extras`; `superpowers:verification-before-completion` + `verification-before-completion-extras` |
| deploy (stub) | gstack `/ship`, `/land-and-deploy`, `/cso` | per skill | none |

## Notes
- `/codex` (OpenAI Codex) is review only: a second opinion, never an author of code or plans.
- `/model-route` (`~/.claude/commands/model-route.md`) only prints a haiku/sonnet/opus tier recommendation and does not know Fable. Ignore it for v2p.
- The main-thread model changes only through the user's `/model`.
- Agent models are fixed in `~/.claude/agents/{planner,builder,quick}.md`; invoke agents by name, never pass a model.
- A fork inherits the parent's model, so Fable reasoning means the `planner` agent, never a fork.
- Load each `*-extras` companion in the same turn as its parent skill.
- `planner` has no Write/Edit tool — every phase's file is written by the main thread or `quick`.
- `quick` has Write — subagent checkpoints are written by the subagent; planner results are written by the main thread on receipt.

## Drift checks — slice-4 contract (not built in slice 3)
| Cadence | Runs | Notes |
|---|---|---|
| every task | `git diff` vs the PLAN task's Files list; `/ponytail-audit` on the diff; `sh scripts/tidy-check.sh` | ponytail plugin enabled (measured 2026-09-23) |
| every phase end | `/code-review` (`~/.claude/commands/code-review.md`, ECC); `/simplify` (code-simplifier plugin cached-disabled; built-in existence unverified — check `/help`); `/security-review` (built-in, verify with `/help`); `/translation-quality` (installed skill) only if BRIEF §9 i18n ON; `superpowers:verification-before-completion` + `verification-before-completion-extras` (there is no `/verify`) | |
| before deploy | claude-security full scan (plugin enabled; command name unverified — `~/.claude/commands/security-scan.md` exists, origin not checked); Strix pentest (not installed; needs Docker + an LLM key; install only via `installing-third-party-tools` on the user's yes) | |

Also available: context7 (API-contract verification), `claude-mem:learn-codebase` (optional, never a source of findings).

***
Copyright © 2026 Rafael Arciniegas. Licensed under the MIT License.
