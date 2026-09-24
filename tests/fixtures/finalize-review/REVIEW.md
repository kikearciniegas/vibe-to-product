# REVIEW — fixture

Deliberately BAD draft for tests/test-finalize-review.sh: §1 lacks the security and qa rows and the codex
findings cell is not a count, §2 cites a fix commit that does not exist, §3 has a pending row without
"deferred to deploy:", there is no pre-deploy line, and a `---` rule. The HEAD and BASE placeholders of the
written: line are filled at test time; the STANDARDS_ROWS placeholder becomes EXECUTE §2 with every row done
except the first, left pending.

checked: pending
written: 2026-09-24 by v2p review · reads: .v2p/EXECUTE.md · diff: {{BASE}}..{{HEAD}}

## 1. Runs
| check | run (exact command or skill invocation) | findings |
|---|---|---|
| code-review | /review + requesting-code-review-extras | 1 findings |
| simplify | /simplify; ponytail-review on the diff; ponytail-audit | 0 findings |
| verification | verification-before-completion on EXECUTE §2 | 0 findings |
| ux-laws | references/ux-laws.md + /design-review | 0 findings |
| codex | /codex review | some |

---

## 2. Findings
| # | check | path:line | severity | status |
|---|---|---|---|---|
| 1 | code-review | src/greet.sh:1 | low | fixed deadbeef |
| 2 | codex | src/greet.sh:1 | low | accepted: prints a fixed string by design |
| 3 | codex | tests/greet.test.sh:1 | low | open: needs the production URL, handled by the deploy task |

## 3. Standards evidence (complete)
| item | file | status | evidence |
|---|---|---|---|
{{STANDARDS_ROWS}}

## 4. Pre-deploy

Next: /v2p deploy (not available in this version)
