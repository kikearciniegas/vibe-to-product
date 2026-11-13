# Field test: adopt mode on a mature existing project (2026-09-30)

v2p ran in adopt mode on a copy of an external, production-grade project that is not part of this repository. Every phase ran through review; review did not finalize (V1) and deploy was not run. The test project is out of scope here: only defects in `skills/v2p` are recorded, by id. Code comments and tests cite them as "field test V<n>".

Status: all 31 fixed on 2026-10-01 (see `docs/ROADMAP.md`, Done lines). None has been exercised in a live run yet.

- **P0** V0 no verifier command ever runs · V1 review Step 3 has no honest status for "not built" / "owner decided otherwise"
- **P1** V2 audit "done" evidence never executed · V3 mapping invents decision provenance, carries unverified gaps as facts · V4 structural verifiers pass while behaviour is broken · V5 brand in adopt mode overwrites the repo's design-system doc
- **P2 execute** V6 commit uses `git add -A` · V7 drift-check counts files untracked before the task · V8 drift-check always measures `base..HEAD`, so re-verifying a finished task shows later tasks as drift · V9 finalize-execute deletes task records · V10 `task-record manual` can't say decision vs observation · V11 no-op task not stopped · V12 draft not enforced at execute start
- **P2 review** V13 named skills disabled for model invocation · V14 claude-security low scan needs a typed command + 60 s confirm · V15 preview URL assumed, never declared
- **P2 research** V16 official legal sites block fetches · V17 scavenged numeric obligations never checked · V18 link check deletes unreachable evidence
- **P3** V19 empty `.git` · V20 tidy-check without git · V21 merge proposals for heavily referenced files · V22 ignores existing decision/changelog homes · V23 probe skips writability · V24 last30days overflows subagent · V25 `]` swallowed by URL regex · V26 source cap vs jurisdictions · V27 Files as bullets · V28 finalize-plan dry-run needs repo tree · V29 guard hook blocks any command that mentions a `.v2p/` final · V30 commands in table cells
