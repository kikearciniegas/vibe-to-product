# Model routing (Claude Code only)

Not included in the portable pack. Read before spawning any agent for a v2p phase.

## Phase → executor → model → skills
| Phase | Executor | Model | Skills |
|---|---|---|---|
| handshake | main thread | whatever `/model` set | none |
| scavenge (stub) | `quick` inventory; `planner` assessment | Sonnet; Fable | none yet |
| mapping (stub) | `planner` | Fable | `superpowers:brainstorming` + `brainstorming-extras`; `superpowers:writing-plans` + `writing-plans-extras` |
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

***
Copyright © 2026 Rafael Arciniegas. Licensed under the MIT License.
