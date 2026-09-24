# Harbor Street Bike Repair Landing Page Implementation Plan

Deliberately BAD draft for tests/test-finalize-plan.sh: §2 has no total line, `---` rules,
no §4b / Architecture / Threat Model. §4 rows are generated at test time from the live
standards files (the line below the §4 table header).

---

## 2. Providers
| need | provider | plan | $/month |
|---|---|---|---|
| hosting | Vercel | Pro | 20 |
| errors | Sentry | Team | 29 |

---

## 3. Skills
- none

---

## 4. Standards (pre-filled; execute fills evidence)
| item | file | status | evidence |
|---|---|---|---|
{{STANDARDS_ROWS}}

## 5. Tasks
### Task 1: Scaffold the site
**Verifier:** mechanical: `npm run build` → exit 0

### Task 2: Booking form
**Verifier:** mechanical: `npm test -- tests/booking.test.ts` → all passed

Next: /v2p execute
