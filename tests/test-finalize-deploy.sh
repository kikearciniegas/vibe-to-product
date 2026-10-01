#!/bin/sh
# finalize-deploy.sh on the execute fixture after finalize-execute and finalize-review PASS, under sh and zsh, with a
# fake curl (no network), a fake claude-security scan directory, fake gstack reports and a local bare origin: the bad
# draft in tests/fixtures/finalize-deploy/DEPLOY.md must FAIL each named check, each FAIL disappears as the copy is
# fixed one step at a time, and every other check is shown refusing on the good draft — including shell-injection
# payloads in target: that must never reach sh -c. Writes only under ${TMPDIR:-/tmp}/v2p-fd.<pid> (HOME points there
# too). Usage: sh tests/test-finalize-deploy.sh
here=$(cd "$(dirname "$0")/.." && pwd -P); S=$here/skills/v2p/scripts; src=$here/tests/fixtures/finalize-deploy/DEPLOY.md
base=$(cd "${TMPDIR:-/tmp}" && pwd -P)/v2p-fd.$$; mkdir -p "$base/home" "$base/fk"; HOME=$base/home; export HOME
GIT_AUTHOR_NAME=t GIT_AUTHOR_EMAIL=t@t GIT_COMMITTER_NAME=t GIT_COMMITTER_EMAIL=t@t; export GIT_AUTHOR_NAME GIT_AUTHOR_EMAIL GIT_COMMITTER_NAME GIT_COMMITTER_EMAIL
sum0=$(shasum -a 256 < "$src"); fails=0; fk=$base/fk
is() { if [ "$2" = "$3" ]; then echo "PASS [$SH] $1"; else echo "FAIL [$SH] $1: got '$2' want '$3'"; fails=$((fails+1)); fi; }
has() { case $2 in *"$3"*) echo "PASS [$SH] $1" ;; *) echo "FAIL [$SH] $1: missing '$3' in: $(printf '%s' "$2" | head -c 600)"; fails=$((fails+1)) ;; esac; }
hasnt() { case $2 in *"$3"*) echo "FAIL [$SH] $1: still has '$3'"; fails=$((fails+1)) ;; *) echo "PASS [$SH] $1" ;; esac; }
# fake curl: never touches the network; FAKE_DOWN=1 → 500s, FAKE_NOREDIR=1 → http answers without a location
cat > "$fk/curl" <<'EOF'
#!/bin/sh
u=; w=0
for a in "$@"; do case $a in -w) w=1 ;; http://*|https://*) u=$a ;; esac; done
echo "$u" >> "$(dirname "$0")/calls"
if [ "$w" = 1 ]; then if [ -n "$FAKE_DOWN" ]; then printf 500; else printf 200; fi; exit 0; fi
case $u in
  http://*) printf 'HTTP/1.1 301 Moved Permanently\r\n'; [ -n "$FAKE_NOREDIR" ] || printf 'location: https://%s\r\n' "${u#http://}" ;;
  https://*) if [ -n "$FAKE_DOWN" ]; then printf 'HTTP/2 500\r\n'; else printf 'HTTP/2 200\r\n'; fi ;;
esac
EOF
chmod +x "$fk/curl"
FD() { out=$(PATH=$fk:$PATH $SH "$S/finalize-deploy.sh" .v2p 2>&1); rc=$?; }
q() { sh "$S/task-record.sh" "$@" >/dev/null 2>&1 || { echo "ERROR: task-record.sh $* failed; test did not run"; exit 2; }; }
sub() { A=$2 B=$3 awk 'index($0, ENVIRON["A"]) { i = index($0, ENVIRON["A"]); $0 = substr($0, 1, i-1) ENVIRON["B"] substr($0, i+length(ENVIRON["A"])) } { print }' "$1" > "$1.new" && mv "$1.new" "$1"; }
ins() { RE=$1 T=$2 awk '!done && $0 ~ ENVIRON["RE"] { print ENVIRON["T"]; done = 1 } { print }' "$P" > "$P.new" && mv "$P.new" "$P"; }
# no <label> <message>: the gate refuses with <message>, seals nothing; then the good draft is restored
no() { FD; is "$1 exit" "$rc" 1; has "$1" "$out" "$2"; is "$1 no receipt" "$(test -e .v2p/.deploy-pass && echo yes)" ""
  rm -f .v2p/DEPLOY.md .v2p/.deploy-pass; cp "$G" "$P"; }
ok() { FD; is "$1 exit" "$rc" 0; has "$1 PASS" "$out" "PASS: "; rm -f .v2p/DEPLOY.md .v2p/.deploy-pass; cp "$G" "$P"; }
SC=CLAUDE-SECURITY-20260925-120000
stamp() { rm -f "$SC"/CLAUDE-SECURITY-REVISION-*.json
  printf '%s\n' '{' '  "generated_at": "2026-09-25T12:30:00+00:00",' '  "mode": "scan",' '  "scan_prefix": "",' '  "scope": [],' '  "revision": {' \
    '    "versioned": true,' "    \"commit\": \"$1\"," '    "branch": "master",' '    "dirty": false' '  },' '  "model": null,' '  "effort": "high",' \
    '  "run_shape": {' '    "requested_effort": "low"' '  },' '  "findings": {' '    "total": 1,' '    "critical": 0,' '    "high": 1,' '    "medium": 0,' '    "low": 0' '  },' \
    '  "verification": {' '    "status": "verified",' '    "candidates": 3' '  }' '}' > "$SC/CLAUDE-SECURITY-REVISION-$(printf '%s' "$1" | cut -c1-12).json"; }
reports() { printf '%s\n' '# Deploy report' 'Verification: HEALTHY' '' 'VERDICT: DEPLOYED AND VERIFIED' > .gstack/deploy-reports/2026-09-25-pr1-deploy.md
  printf '%s\n' '{"url":"https://fixture.test","status":"HEALTHY","pages":[{"url":"/","status":"HEALTHY"}],"alerts":[]}' > .gstack/canary-reports/2026-09-25-canary.json
  printf '%s\n' '{"id":"F1","severity":"HIGH","file":"src/greet.sh","line":1,"title":"x"}' > "$SC/CLAUDE-SECURITY-RESULTS.jsonl"; }
M1="target host 'fixture.test;rm' is not a plain hostname"; M2="§1 missing canary row"; M3="§1 strix result 'maybe'"; M4="§2 status 'open: later'"
M5="pending without post-launch"; M6="FAIL: rollback line"; M7="secret-looking value in .v2p/DEPLOY.draft.md:"; M8="'---' rule"; M9="no 'Next: live' line"
for SH in sh zsh; do
  fx=$base/fx-$SH; sh "$here/tests/fixture-execute.sh" "$fx" >/dev/null 2>&1; cd "$fx" || exit 2
  # PLAN: a deploy runbook task (its verifier needs the live host) and one whose placeholder deploy cannot fill
  { printf '%s\n' '' '### Task 4: Deploy runbook' '**Files:** Modify: `docs/secrets.md`' \
      "**Verifier:** manual: dashboards; then mechanical: \`curl -m 10 -sI https://<domain> | grep -q 'HTTP/2 200'\` → exit 0" '' \
      '### Task 5: Chunk map' '**Files:** none' '**Verifier:** mechanical: `curl -m 10 -sI https://<domain>/_next/<chunk>.js.map | grep -q 404` → exit 0'; } >> .v2p/PLAN.md
  shasum -a 256 .v2p/PLAN.md | cut -d' ' -f1 > .v2p/.plan-pass; git add -A; git commit -qm 'plan: deploy tasks'
  # execute, the short way: 1 pass, 2 deferred (credential), 3 handed to review, 4 and 5 handed to deploy
  q start 1; mkdir -p tests; printf 'echo hi\n' > src/greet.sh; printf '[ "$(sh src/greet.sh)" = hi ]\n' > tests/greet.test.sh; q verify 1
  git add -A; git commit -qm 'feat: greeting'; q ponytail 1 none
  q defer 2 "VERCEL_TOKEN"; q skip 3 "handed to /v2p review"; q skip 4 "handed to /v2p deploy"; q skip 5 "handed to /v2p deploy"
  { printf '%s\n' '# EXECUTE — fixture' 'checked: pending' 'written: 2026-09-24' '' '## 1. Tasks' '' '## 2. Standards' '| item | file | status | evidence |' '|---|---|---|---|'
    awk '/^## 4\./{f=1;next} /^## /{f=0} f && /^\| / && !/^\| item/' .v2p/PLAN.md; printf '%s\n' '' 'Next: /v2p review'; } > .v2p/EXECUTE.draft.md
  o=$(sh "$S/finalize-execute.sh" .v2p) || { echo "ERROR: finalize-execute did not PASS: $o"; exit 2; }
  base0=$(sed -n 's/^checked: .* · base \([^ ]*\) .*/\1/p' .v2p/EXECUTE.md)
  # review, the short way (test-finalize-review.sh covers its refusals)
  mkdir -p docs; echo '# Threat model: no entry points' > docs/threat-model.md; git add -A; git commit -qm 'docs: threat model'
  { printf '%s\n' '# REVIEW — fixture' 'checked: pending' "written: 2026-09-25 by v2p review · reads: .v2p/EXECUTE.md · diff: $base0..$(git rev-parse HEAD)" '' \
      '## 1. Runs' '| check | run (exact command or skill invocation) | findings |' '|---|---|---|'
    for c in code-review simplify security verification ux-laws codex qa; do printf '| %s | /%s | 0 findings |\n' "$c" "$c"; done
    printf '%s\n' '' '## 2. Findings' '| # | check | path:line | severity | status |' '|---|---|---|---|---|' '' '## 3. Standards evidence (complete)' '| item | file | status | evidence |' '|---|---|---|---|'
    awk '/^## 2\./{f=1;next} /^## /{f=0} f && /^\| / && !/^\| item/' .v2p/EXECUTE.md | awk -F'|' 'NR==1 {print "|" $2 "|" $3 "| pending | deferred to deploy: needs prod URL |"; next} {print "|" $2 "|" $3 "| done | src/greet.sh |"}'
    printf '%s\n' '' '## 4. Pre-deploy' 'pre-deploy: pending (claude-security full scan + Strix pentest run by /v2p deploy)' '' 'Next: /v2p deploy'; } > .v2p/REVIEW.draft.md
  o=$(sh "$S/finalize-review.sh" .v2p) || { echo "ERROR: finalize-review did not PASS: $o"; exit 2; }
  XB=$(git rev-parse --abbrev-ref HEAD)
  # deploy work: secrets register, setup-deploy's CLAUDE.md section, one security fix after the scan, the merge to origin/main
  printf '%s\n' '# Secrets register' '| name | owner | rotation | where it lives |' '|---|---|---|---|' '| RESEND_API_KEY | founder | 90 days | Vercel Sensitive env (production) |' > docs/secrets.md
  printf 'RESEND_API_KEY=\n' > .env.example
  printf '%s\n' '# fixture' '' '## Deploy Configuration (configured by /setup-deploy)' '- Platform: vercel' '- Production URL: https://fixture.test' '- Post-deploy health check: https://fixture.test' '' '## Notes' 'none' > CLAUDE.md
  git add -A; git commit -qm 'chore: deploy config'; SCANC=$(git rev-parse HEAD)
  printf 'hardened\n' >> README.md; git commit -qam 'fix: F1'; FIX=$(git rev-parse --short HEAD)
  git init -q --bare "$base/origin-$SH.git"; git remote add origin "$base/origin-$SH.git"; git push -q origin HEAD:main
  mkdir -p "$SC" .gstack/deploy-reports .gstack/canary-reports; echo '# results' > "$SC/CLAUDE-SECURITY-RESULTS.md"; stamp "$SCANC"; reports
  P=.v2p/DEPLOY.draft.md; G=$base/good-$SH
  awk '/^## 3\./{f=1;next} /^## /{f=0} f && /^\| / && !/^\| item/' .v2p/REVIEW.md | awk -F'|' 'NR==1 {print "|" $2 "|" $3 "| pending | |"; next} {print}' > "$base/rows-$SH"
  R=$base/rows-$SH awk '$0 == "{{STANDARDS_ROWS}}" { while ((getline l < ENVIRON["R"]) > 0) print l; next } { print }' "$src" | sed "s/{{SCAN}}/$SC/" > "$P"
  # 0. the bad draft fails every named check, runs nothing on the bad host, writes nothing
  FD; is "0 exit" "$rc" 1; for m in "$M1" "$M2" "$M3" "$M4" "$M5" "$M6" "$M7" "$M8" "$M9"; do has "0 $m" "$out" "$m"; done
  hasnt "0 no verifier ran on the bad host" "$out" "run: "; is "0 no DEPLOY.md" "$(test -f .v2p/DEPLOY.md && echo yes)" ""
  # 1–9. fix one step at a time
  sub "$P" 'target: https://fixture.test;rm' 'target: https://fixture.test'; FD; hasnt "1 target" "$out" "target host"; has "1 verifiers now run" "$out" "run: task 1:"
  ins '^\| land-and-deploy ' '| canary | /canary https://fixture.test --duration 10m | .gstack/canary-reports/2026-09-25-canary.json |'; FD; hasnt "2 canary row" "$out" "$M2"
  sub "$P" '| strix | strix --target . | maybe |' '| strix | strix --target . | unavailable: docker absent |'; FD; hasnt "3 strix" "$out" "$M3"
  sub "$P" 'open: later' "fixed $FIX"; FD; hasnt "4 fixed" "$out" "$M4"; hasnt "4 fix accounts for the post-scan commit" "$out" "after the scan"
  first=$(head -n 1 "$base/rows-$SH"); sub "$P" "$first" "$(printf '%s\n' "$first" | sed 's/| pending | |$/| pending | post-launch: 28 days of field data, 2026-10-24 |/')"; FD; hasnt "5 post-launch" "$out" "$M5"
  sub "$P" 'rollback: soon' 'rollback: rehearsed 2026-09-26T10:12:00Z · elapsed 41s · method: Vercel promote previous · by user'; FD; hasnt "6 rollback" "$out" "$M6"
  grep -v '^RESEND_API_KEY=' "$P" > "$P.new" && mv "$P.new" "$P"; FD; hasnt "7 secret" "$out" "secret-looking"
  sed 's/^---$/***/' "$P" > "$P.new" && mv "$P.new" "$P"; FD; hasnt "8 rule" "$out" "$M8"
  printf '\nNext: live\n' >> "$P"; mkdir -p .v2p/work; echo "head: x" > .v2p/work/deploy-scan.md
  FD; is "9 exit" "$rc" 0; S12=$(printf '%s' "$SCANC" | cut -c1-12); SD=$(( $(grep -c . "$base/rows-$SH") - 1 ))
  has "9 PASS" "$out" "PASS: scan high $S12, findings 1 (fixed 1 · accepted 0), verifiers 3/3, placeholders left 1, rulings 0, standards done $SD, post-launch 1, canary HEALTHY -> .v2p/DEPLOY.md"
  has "9 deferred task re-run" "$out" "run: task 2:"; has "9 deploy task re-run on the target" "$out" "run: task 4: curl -m 10 -sI https://fixture.test | grep -q 'HTTP/2 200'"
  has "9 unfillable placeholder skipped" "$out" "skip: task 5: curl -m 10 -sI https://fixture.test/_next/<chunk>.js.map"; hasnt "9 review-handed task not run" "$out" "run: task 3"
  is "9 checked" "$(grep '^checked: ' .v2p/DEPLOY.md)" "checked: scan high $S12 · findings 1 (fixed 1 · accepted 0) · verifiers 3/3 pass · placeholders left 1 · rulings 0 · standards done $SD · N/A 0 · post-launch 1 · live 2/2 · canary HEALTHY · rollback 41s · branch $XB · head $(git rev-parse HEAD)"
  is "9 receipt" "$(cat .v2p/.deploy-pass)" "$(shasum -a 256 .v2p/DEPLOY.md | cut -d' ' -f1)"; is "9 draft gone" "$(test -f "$P" && echo yes)" ""
  is "9 checkpoints cleared" "$(test -f .v2p/work/deploy-scan.md && echo yes)" ""
  sed 's/^checked: .*/checked: pending/' .v2p/DEPLOY.md > "$G"; rm .v2p/DEPLOY.md .v2p/.deploy-pass; cp "$G" "$P"
  # 10. falsifiers on the good draft. Receipts and inputs:
  out=$(PATH=$fk:$PATH $SH "$S/finalize-deploy.sh" "$base/none" 2>&1); is "10 no .v2p dir exit" $? 1; has "10 no .v2p dir" "$out" "FAIL: $base/none not found"
  mv .v2p/.review-pass "$base/rp"; no "10 review receipt" "REVIEW.md does not match its receipt"; mv "$base/rp" .v2p/.review-pass
  cp .v2p/PLAN.md "$base/pl"; echo x >> .v2p/PLAN.md; no "10 plan receipt" "PLAN.md does not match its receipt"; cp "$base/pl" .v2p/PLAN.md
  echo x > .v2p/DEPLOY.md; no "10 existing DEPLOY.md" "DEPLOY.md exists (redeploy"
  rm "$P"; no "10 no draft" "DEPLOY.draft.md missing"
  sub "$P" 'checked: pending' 'chkd: pending'; no "10 no checked line" "no 'checked:' line"
  # written: line and CLAUDE.md
  sub "$P" 'target: https://fixture.test' 'target: fixture.test'; no "10 target without scheme" "target host 'fixture.test' is not a plain hostname"
  sub "$P" ' · pr: #1' ''; no "10 pr missing" "written: line needs 'pr: #<n> · base: <branch>'"
  sub "$P" 'base: main' 'base: -x'; no "10 base not a branch name" "written: line needs 'pr: #<n> · base: <branch>'"
  sub "$P" 'base: main' 'base: nope'; no "10 base not fetchable" "cannot fetch origin/nope"
  sub CLAUDE.md 'https://fixture.test' 'https://other.test'; no "10 production url" "target fixture.test ≠ CLAUDE.md Deploy Configuration Production URL 'https://other.test'"; git checkout -q CLAUDE.md
  sub CLAUDE.md '## Deploy Configuration (configured by /setup-deploy)' '## Deploy'; no "10 no deploy config" "CLAUDE.md has no '## Deploy Configuration'"; git checkout -q CLAUDE.md
  # trust boundary: a target carrying shell syntax (and a CLAUDE.md that agrees with it) never reaches sh -c or curl
  for pl in 'https://x.com;touch${IFS}PWNED' 'https://x.com$(touch${IFS}PWNED)' 'https://x.com`touch${IFS}PWNED`' 'https://-x.com' 'https://x..com'; do
    : > "$fk/calls"; sub "$P" 'target: https://fixture.test' "target: $pl"; sub CLAUDE.md '- Production URL: https://fixture.test' "- Production URL: $pl"
    FD; is "10 injection exit: $pl" "$rc" 1; has "10 injection refused: $pl" "$out" "is not a plain hostname"; hasnt "10 injection ran nothing: $pl" "$out" "run: "
    is "10 injection executed nothing: $pl" "$(find . -name PWNED | grep -c .)" 0; is "10 injection curled nothing: $pl" "$(grep -c . "$fk/calls")" 0
    rm -f .v2p/DEPLOY.md .v2p/.deploy-pass; cp "$G" "$P"; git checkout -q CLAUDE.md
  done
  # brand receipt for post-brand plans
  cp .v2p/PLAN.md "$base/pl"; awk '{print} /^# Fixture Implementation Plan$/ {print "**Spec:** .v2p/BRIEF.md · .v2p/DESIGN.md"}' "$base/pl" > .v2p/PLAN.md
  shasum -a 256 .v2p/PLAN.md | cut -d' ' -f1 > .v2p/.plan-pass; mv .v2p/.brand-pass "$base/bp"
  no "10 brand receipt" "DESIGN.md does not match its receipt"; mv "$base/bp" .v2p/.brand-pass; ok "10 brand receipt back"
  cp "$base/pl" .v2p/PLAN.md; shasum -a 256 .v2p/PLAN.md | cut -d' ' -f1 > .v2p/.plan-pass
  # §1 rows and the gstack reports
  sub "$P" '| setup-deploy | /setup-deploy |' '| setup-deploy |  |'; no "10 empty run cell" "§1 setup-deploy row has no run invocation"
  sub "$P" '| 1 findings |' '| some |'; no "10 security-full result" "§1 security-full result 'some'"
  sub "$P" '| strix | strix --target . | unavailable: docker absent |' '| strix | strix --target . | 0 findings |'; ok "10 strix count"
  sub "$P" 'CLAUDE.md ## Deploy Configuration (platform vercel)' 'done'; no "10 setup-deploy result" "§1 setup-deploy result 'done'"
  sub .gstack/deploy-reports/2026-09-25-pr1-deploy.md 'VERDICT: DEPLOYED AND VERIFIED' 'VERDICT: REVERTED'; no "10 verdict" "verdict is not DEPLOYED AND VERIFIED"; reports
  sub .gstack/deploy-reports/2026-09-25-pr1-deploy.md 'VERDICT: DEPLOYED AND VERIFIED' 'VERDICT: DEPLOYED (UNVERIFIED)'; no "10 unverified" "verdict is not DEPLOYED AND VERIFIED"; reports
  sub "$P" '2026-09-25-pr1-deploy.md' '2026-09-24-pr1-deploy.md'; no "10 no deploy report" "§1 land-and-deploy result '.gstack/deploy-reports/2026-09-24-pr1-deploy.md' is not an existing"
  sub .gstack/canary-reports/2026-09-25-canary.json '"status":"HEALTHY","pages"' '"status":"DEGRADED","pages"'; no "10 canary degraded (a page still HEALTHY)" "canary report .gstack/canary-reports/2026-09-25-canary.json status is not HEALTHY"; reports
  sub "$P" '| .gstack/deploy-reports/2026-09-25-pr1-deploy.md |' '| README.md |'; no "10 deploy report outside .gstack" "§1 land-and-deploy result 'README.md' is not an existing"
  sub "$P" '.gstack/canary-reports/2026-09-25-canary.json' '.gstack/deploy-reports/2026-09-25-pr1-deploy.md'; no "10 canary path" "§1 canary result '.gstack/deploy-reports/2026-09-25-pr1-deploy.md' is not an existing"
  sub "$P" '2026-09-25-canary.json' '2026-09-24-canary.json'; no "10 no canary report" "§1 canary result '.gstack/canary-reports/2026-09-24-canary.json' is not an existing"
  printf '%s\n' '{"url":"https://fixture.test","pages":[]}' > .gstack/canary-reports/2026-09-25-canary.json; no "10 canary without status" "status is not HEALTHY"; reports
  # the scan stamp
  sub "$P" " · scan: $SC" ''; no "10 no scan" "written: line 'scan: ' is not a CLAUDE-SECURITY-<ts> directory"
  sub "$P" "scan: $SC" 'scan: .gstack'; no "10 scan not a scan dir" "'scan: .gstack' is not a CLAUDE-SECURITY-<ts> directory here"
  sub "$P" "scan: $SC" 'scan: CLAUDE-SECURITY-20260101-000000'; no "10 scan dir missing" "'scan: CLAUDE-SECURITY-20260101-000000' is not a CLAUDE-SECURITY-<ts> directory here"
  mv "$SC/CLAUDE-SECURITY-REVISION-$S12.json" "$SC/CLAUDE-SECURITY-REVISION-$S12-dirty.json"; no "10 dirty stamp" "scan ran on a dirty/unversioned tree"; stamp "$SCANC"
  cp "$SC/CLAUDE-SECURITY-REVISION-$S12.json" "$SC/CLAUDE-SECURITY-REVISION-000000000000.json"; no "10 two stamps" "needs exactly one CLAUDE-SECURITY-REVISION"; stamp "$SCANC"
  J=$SC/CLAUDE-SECURITY-REVISION-$S12.json
  sub "$J" '"mode": "scan"' '"mode": "changes"'; no "10 mode" "scan mode 'changes' (need a codebase scan)"; stamp "$SCANC"
  sub "$J" '"mode"' '"modx"'; no "11 parser reads the field" "scan mode '' (need a codebase scan)"; stamp "$SCANC"
  sub "$J" '"scope": []' '"scope": ["src"]'; no "10 scope" "scan was scoped"; stamp "$SCANC"
  sub "$J" '"effort": "high"' '"effort": "medium"'; no "10 effort" "scan effort 'medium' (need high or max)"; stamp "$SCANC"
  sub "$J" '"effort": "high"' '"effort": "max"'; ok "10 effort max"; stamp "$SCANC"
  sub "$J" '"status": "verified"' '"status": "unverified"'; no "10 verification" "scan verification 'unverified'"; stamp "$SCANC"
  stamp 1234567890abcdef1234567890abcdef12345678; no "10 scanned commit not in history" "scanned commit '1234567890abcdef1234567890abcdef12345678' is not an ancestor of HEAD"; stamp "$SCANC"
  stamp HEAD; no "10 scanned commit not a sha" "scanned commit 'HEAD' is not an ancestor of HEAD"; stamp "$SCANC"
  rm "$SC/CLAUDE-SECURITY-RESULTS.jsonl"; no "10 no jsonl" "CLAUDE-SECURITY-RESULTS.jsonl lines ≠ stamp total 1"; reports
  sub "$J" '"total": 1' '"total": 2'; no "10 total" "§1 security-full says 1, stamp says 2"; stamp "$SCANC"
  echo '{"id":"F2"}' >> "$SC/CLAUDE-SECURITY-RESULTS.jsonl"; no "10 jsonl" "CLAUDE-SECURITY-RESULTS.jsonl lines ≠ stamp total 1"; reports
  # §2 and commit accounting (good state: scan at the fix's parent, the fix listed)
  echo more >> README.md; git commit -qam 'chore: unrelated'; git push -q origin HEAD:main
  no "10 unaccounted commit" "FAIL: commit $(git rev-parse HEAD) after the scan is not a §2 fix"; git reset -q --hard HEAD~1; git push -qf origin HEAD:main
  sub "$P" "fixed $FIX" 'fixed deadbeef'; no "10 fix sha" "§2 fix commit 'deadbeef' not found"
  sub "$P" "fixed $FIX" 'fixed HEAD'; no "10 fix not a sha" "§2 fix commit 'HEAD' not found"
  sub "$P" "fixed $FIX" 'accepted: constant input, not reachable'; no "10 accepted leaves the fix unaccounted" "after the scan is not a §2 fix"
  stamp "$(git rev-parse HEAD)"; sub "$P" "fixed $FIX" 'accepted: constant input, not reachable'; FD; is "10 accepted exit" "$rc" 0; has "10 accepted counted" "$out" "(fixed 0 · accepted 1)"
  rm -f .v2p/DEPLOY.md .v2p/.deploy-pass; cp "$G" "$P"; stamp "$SCANC"
  sub "$P" '| security-full | F1 |' '| scanner | F1 |'; no "10 check cell" "§2 check 'scanner'"
  sub "$P" '| security-full | F1 |' '| strix | F1 |'; no "10 per-check count" "§2 security-full rows 0, §1 security-full 1"
  ins '^Rows: 1 = ' "| 2 | security-full | F2 | LOW | src/greet.sh:2 | fixed $FIX |"; no "10 row count" "§2 rows 2, §1 findings sum 1"
  # §3
  second=$(sed -n 2p "$base/rows-$SH")
  sub "$P" "$second" "$(printf '%s\n' "$second" | sed 's/| done | src\/greet.sh |$/| done | none |/')"; no "10 done without evidence" "done without evidence"
  sub "$P" "$second" "$(printf '%s\n' "$second" | sed 's/| done | src\/greet.sh |$/| N\/A | not needed |/')"; no "10 N/A without BRIEF" "N/A without BRIEF §"
  sub "$P" "$second" "$(printf '%s\n' "$second" | sed 's/| done | src\/greet.sh |$/| maybe | x |/')"; no "10 status" "status not done/pending/N/A"
  sub "$P" "$second" "| Not A Review Item |$(printf '%s\n' "$second" | cut -d'|' -f3-)"; no "10 §3 items" "§3 items differ from REVIEW §3"
  grep -vxF "$second" "$P" > "$P.new" && mv "$P.new" "$P"; no "10 §3 rows" "§3 rows $SD/$((SD + 1)) (must equal REVIEW §3)"
  # secrets
  cp docs/secrets.md "$base/sec"; grep -v RESEND "$base/sec" > docs/secrets.md; no "10 register misses a name" "docs/secrets.md does not list RESEND_API_KEY"; git checkout -q docs/secrets.md
  echo 'rotation note: sb_secret_abc' >> docs/secrets.md; no "10 value in the register" "secret-looking value in docs/secrets.md:5"; git checkout -q docs/secrets.md
  rm docs/secrets.md; no "10 no register" "docs/secrets.md missing"; git checkout -q docs/secrets.md
  sub "$P" 'values: none' 'values: in 1Password'; no "10 secrets line" "no 'secrets: docs/secrets.md"
  # branch, merge, clean tree
  git checkout -q -b other; no "10 branch" "HEAD is on 'other', REVIEW.md branch is '$XB'"; git checkout -q "$XB"; git branch -q -D other
  git push -qf origin HEAD~1:main; no "10 not merged" "HEAD is not merged into origin/main (run /land-and-deploy)"; git push -qf origin HEAD:main
  mkdir -p .gstack/x strix_runs/r; echo x > .gstack/x/y.md; echo x > strix_runs/r/z.md; ok "10 gstack/strix/scan dirs are not dirt"; rm -rf .gstack/x strix_runs
  mkdir -p src/new; echo x > src/new/a.sh; no "10 dirty" "uncommitted: src/new/a.sh"; rm -rf src/new
  # the live target
  export FAKE_DOWN=1; no "10 down" "https://fixture.test/ → 500 (want 200)"; FD; has "10 down verifier" "$out" "FAIL: verifier of task 4 fails on the live target"; unset FAKE_DOWN; cp "$G" "$P"
  export FAKE_NOREDIR=1; no "10 no redirect" "http://fixture.test/ does not redirect to https"; unset FAKE_NOREDIR
  printf 'echo hi\n# hi\n' > src/greet.sh; git commit -qam 'hi twice'; no "10 bare number" "grep -c hi src/greet.sh' → 2 (expected 1)"; git reset -q --hard HEAD~1
  # rulings: REVIEW.md's (sealed) are honoured; the draft's must be well formed and name a PLAN task
  cp .v2p/REVIEW.md "$base/rv"; printf 'ruling: task 2 · plan defect · x\n' >> .v2p/REVIEW.md; shasum -a 256 .v2p/REVIEW.md | cut -d' ' -f1 > .v2p/.review-pass
  FD; is "10 review ruling exit" "$rc" 0; has "10 review ruling honoured" "$out" "ruling: task 2 verifier not re-run (plan defect)"; hasnt "10 review ruling not run" "$out" "run: task 2:"
  has "10 review ruling counted" "$out" "rulings 1,"; has "10 review ruling in checked" "$(grep '^checked:' .v2p/DEPLOY.md)" "· rulings 1 ·"
  rm -f .v2p/DEPLOY.md .v2p/.deploy-pass; cp "$G" "$P"; cp "$base/rv" .v2p/REVIEW.md; shasum -a 256 .v2p/REVIEW.md | cut -d' ' -f1 > .v2p/.review-pass
  printf 'ruling: task 4 plan defect\n' >> "$P"; no "10 malformed ruling" "FAIL: malformed ruling line"
  printf 'ruling: task 9 · plan defect · x\n' >> "$P"; no "10 unknown ruling" "FAIL: ruling names task(s) not in PLAN: 9"
  printf 'ruling: task 4 · plan defect · DNS not propagated; checked by hand\n' >> "$P"; FD; is "10 draft ruling exit" "$rc" 0; hasnt "10 draft ruling not run" "$out" "run: task 4"
  rm -f .v2p/DEPLOY.md .v2p/.deploy-pass; cp "$G" "$P"
  # a mechanical Verifier with no backticked command (field test V0) ran nothing and counted as verified: now it fails
  cp .v2p/PLAN.md "$base/pl"; sub .v2p/PLAN.md "mechanical: \`sh -c 'grep -c hi src/greet.sh'\` → 1" 'mechanical: grep -c hi src/greet.sh → 1'
  shasum -a 256 .v2p/PLAN.md | cut -d' ' -f1 > .v2p/.plan-pass; grep -q '^\*\*Verifier:\*\* mechanical: grep -c hi' .v2p/PLAN.md; is "10 unbackticked fixture edited" $? 0
  no "10 unbackticked mechanical verifier" "FAIL: verifier of task 2: mechanical with no backticked"
  cp "$base/pl" .v2p/PLAN.md; shasum -a 256 .v2p/PLAN.md | cut -d' ' -f1 > .v2p/.plan-pass
  is "10 curl only ever hit the fixture host" "$(grep -v '://fixture\.test' "$fk/calls" | grep -c .)" 0
  ok "10 good draft still passes"
  cd "$base"
done
SH=all; is "12 source untouched" "$(shasum -a 256 < "$src")" "$sum0"
echo "test-finalize-deploy: $fails failures (scratch: $base)"
# a passing run leaves nothing behind (180 stale scratch dirs had piled up in $TMPDIR); a failing one keeps it to inspect
[ "$fails" -eq 0 ] && rm -rf "$base"
[ "$fails" -eq 0 ]
