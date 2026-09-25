# Model routing (Claude Code only)

Not included in the portable pack. Read before spawning any agent for a v2p phase.

## Phase → executor → model → skills
| Phase | Executor | Model | Skills |
|---|---|---|---|
| handshake | main thread | whatever `/model` set | none |
| adopt | `quick` (Sonnet) scan → writes .v2p/work/adopt-scan.md; main thread derives BRIEF, runs the gate, writes drafts, runs the scripts | Sonnet | none; Serena; code-review-graph if installed |
| scavenge | `planner` (Fable) research Q1–Q5, returns text; brownfield inventory copied from `.v2p/AUDIT.md` §1; one `quick` (Sonnet) subagent runs Q7 (and Q5's social search): `/last30days` loaded once + the official changelog per subject; main thread writes the draft and runs `finalize-scavenge.sh` | Fable; Sonnet | `/last30days` (Q7 always, Q5 when applicable), never on the main thread |
| brand | main thread (the design skills need `AskUserQuestion` and the browser) and runs `finalize-brand.sh` / `archive-cycle.sh`; `quick` may run the ui-ux-pro-max searches into `.v2p/work/brand-candidates.md`; `planner` never | per skill; Sonnet | `/impeccable init` (+ `document` for an org kit's code and in re-theme), ui-ux-pro-max + `ui-ux-pro-max-extras`, `markitdown` (existing guide), `superpowers:brainstorming` + `brainstorming-extras` + `/design-consultation` (to-create), `/design-shotgun` and `banana-claude` (optional, gated on their keys), `make-interfaces-feel-better` + `apple-design` (Motion), `gstack-extras` with any gstack skill (per-case order in `phases/brand.md`) |
| mapping | `planner` (Fable) via `superpowers:writing-plans` + `writing-plans-extras`; brainstorming only if ≥3 architecture-affecting `deferred` rows; main thread asks provider questions and writes the file | Fable | `superpowers:writing-plans` + `writing-plans-extras`; `superpowers:brainstorming` + `brainstorming-extras` only if BRIEF §10 has ≥3 `deferred` rows that affect architecture |
| execute | main thread orchestrates (needs `AskUserQuestion`, Agent tool) and runs the scripts; implementer `builder` when the task's Files include code, `quick` when every Files token is under `docs/` or ends in `.md`; task reviewer `planner` (read-only, has Bash to re-run tests) | Opus; Sonnet; Fable | `superpowers:subagent-driven-development` + `subagent-driven-development-extras` (default; inline `superpowers:executing-plans` on request); `superpowers:test-driven-development` in every implementer dispatch; `superpowers:using-git-worktrees`; `ponytail-review` per task; `/ralph-loop` only for PLAN §6-eligible tasks, always with `--max-iterations`; UI tasks: `/impeccable` + `make-interfaces-feel-better` (quick, also in the task review), `animate` (emil) for animation tasks, `apple-design` for native-app or gesture UI, `img2threejs` only for a 3D object from a photo |
| review | main thread runs the gstack skills; standards-evidence audit by `planner`; fixes by `builder`/`quick`; `/codex` via its skill (review only) | per skill; Fable; OpenAI Codex | gstack `/review` + `requesting-code-review-extras`; `/simplify` + `ponytail-review` → `ponytail-audit`; `/security-review` + `claude-security` (low effort); `/design-review <url>` against DESIGN.md, `/qa` + `gstack-extras`; `make-interfaces-feel-better` (full) on the UI diff; `review-animations` (emil) only when the diff has motion code; `translation-quality` when i18n ON; `superpowers:verification-before-completion` + `verification-before-completion-extras` |
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

## Drift checks — built in slice 4
`ponytail-audit` = repo-wide, `ponytail-review` = diff (measured 2026-09-24 from the two SKILL.md descriptions, plugin 4.9.0).

| Tier | Trigger (who, when) | What runs | Evidence it leaves | Gate that refuses without it |
|---|---|---|---|---|
| every task | main thread, after the implementer commits (against the committed head; a failure → fix commits, re-verify) | `task-record.sh verify <n>` (= `drift-check.sh <n>` + verifier commands + tidy delta + branch check) | record lines `drift:`, `verifier:`, `output:` + receipt | `finalize-execute.sh` step 3 |
| every task | task reviewer (`planner`, SDD) or main thread (inline) | `ponytail-review` on `git diff <base>..HEAD` | `ponytail-review:` line via `task-record.sh ponytail` | `finalize-execute.sh` step 3 |
| every UI task | main thread, `task-record.sh start` | UI gate: `check-pass.sh .v2p/DESIGN.md .v2p/.brand-pass` when the task's Files name a UI file | none (a refusal: run `/v2p brand`) | `task-record.sh start` exit 2 |
| every task | implementer, inside the task | `superpowers:test-driven-development` (red → green) | the verifier's own test files in the commit | reviewer prompt (SDD); not scripted |
| every phase (execute end) | main thread before `finalize-execute.sh` | `superpowers:verification-before-completion` + extras on EXECUTE §2 rows | corrected rows | `finalize-execute.sh` step 7 (shape only) |
| every phase (review) | review Step 1, once over `<base>..HEAD` | `/review` (+extras), `/simplify` + `ponytail-review` → `ponytail-audit`, `/security-review` + `claude-security` (low), `translation-quality` (i18n ON), ux-laws + `/design-review`, `/qa`, `/codex review` | `.v2p/work/review-<check>.md`, REVIEW §1 rows, §2 findings with fix shas | `finalize-review.sh` §1–§2 checks and the verifier re-run |
| before deploy | slice 5 | `claude-security` full scan + Strix pentest (not installed; needs Docker + an LLM key; install only via `installing-third-party-tools` on the user's yes) | none yet | REVIEW §4 line is the hand-off; deploy will require `.review-pass` |

Also available: context7 (API-contract verification), `claude-mem:learn-codebase` (optional, never a source of findings).

***
Copyright © 2026 Rafael Arciniegas. Licensed under the MIT License.
