# DEPLOY — fixture

Deliberately BAD draft for tests/test-finalize-deploy.sh: the target host carries a shell metacharacter, §1 has no
canary row and the strix result is not a count, §2 leaves a finding open, the first §3 row is pending without a
post-launch trigger, the rollback line is not a rehearsal record, a secret value is pasted, there is a `---` rule and
no hand-off line. The SCAN placeholder of the written: line is filled at test time; the STANDARDS_ROWS placeholder
becomes REVIEW §3, whose first row is pending (deferred to deploy) and is left with empty evidence.

checked: pending
written: 2026-09-25 by v2p deploy · reads: .v2p/REVIEW.md · target: https://fixture.test;rm · scan: {{SCAN}} · pr: #1 · base: main

## 0. Target
host: Vercel Pro · commercial: yes · total monthly: $20 (PLAN §2) · budget: $25 (BRIEF §7) · deploy task: PLAN Task 4 · deferred verifiers: Task 2

## 1. Runs
| check | run (exact command or skill invocation) | result |
|---|---|---|
| security-full | /claude-security scan codebase --effort high | 1 findings |
| strix | strix --target . | maybe |
| setup-deploy | /setup-deploy | CLAUDE.md ## Deploy Configuration (platform vercel) |
| land-and-deploy | /land-and-deploy https://fixture.test | .gstack/deploy-reports/2026-09-25-pr1-deploy.md |

---

## 2. Findings
| # | check | id | severity | path:line | status |
|---|---|---|---|---|---|
| 1 | security-full | F1 | HIGH | src/greet.sh:1 | open: later |
Rows: 1 = §1 security-full + strix counts

## 3. Standards (complete)
| item | file | status | evidence |
|---|---|---|---|
{{STANDARDS_ROWS}}

## 4. Live
rollback: soon
secrets: docs/secrets.md · 1 names · values: none
RESEND_API_KEY=re_abcdefghijklmnopqrstuvwxyz
