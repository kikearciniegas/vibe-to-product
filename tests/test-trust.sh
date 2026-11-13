#!/bin/sh
# SPDX-License-Identifier: MIT
# Copyright (c) 2026 Rafael Arciniegas
# The local trust ledger, under sh and zsh: a cloned project that ships PLAN.md plus a matching .plan-pass gets none of
# its Verifier commands run by task-record.sh, finalize-review.sh or finalize-deploy.sh until this machine trusts that
# PLAN (finalize-plan.sh, or trust-plan.sh --yes after the commands were shown). Writes only under
# ${TMPDIR:-/tmp}/v2p-tr.<pid>; HOME and XDG_CONFIG_HOME point there, so the real ledger is never touched.
# Usage: sh tests/test-trust.sh   (exit 0 = all PASS)
here=$(cd "$(dirname "$0")/.." && pwd -P); S=$here/skills/v2p/scripts
base=$(cd "${TMPDIR:-/tmp}" && pwd -P)/v2p-tr.$$; mkdir -p "$base/home" "$base/fk"; HOME=$base/home; export HOME
XDG_CONFIG_HOME=$HOME/.config; export XDG_CONFIG_HOME; L=$XDG_CONFIG_HOME/v2p/trusted-plans
GIT_AUTHOR_NAME=t GIT_AUTHOR_EMAIL=t@t GIT_COMMITTER_NAME=t GIT_COMMITTER_EMAIL=t@t; export GIT_AUTHOR_NAME GIT_AUTHOR_EMAIL GIT_COMMITTER_NAME GIT_COMMITTER_EMAIL
fails=0
is() { if [ "$2" = "$3" ]; then echo "PASS [$SH] $1"; else echo "FAIL [$SH] $1: got '$2' want '$3'"; fails=$((fails+1)); fi; }
has() { case $2 in *"$3"*) echo "PASS [$SH] $1" ;; *) echo "FAIL [$SH] $1: missing '$3' in: $(printf '%s' "$2" | head -c 400)"; fails=$((fails+1)) ;; esac; }
sha() { shasum -a 256 "$1" | cut -d' ' -f1; }
# fake curl: finalize-deploy's live checks never touch the network
printf '#!/bin/sh\nexit 7\n' > "$base/fk/curl"; chmod +x "$base/fk/curl"
pwned() { test -f pwned && echo ran || echo no; }
# a project as a clone ships it: PLAN.md whose Task 1 Verifier is `touch pwned`, its receipt recomputed and committed,
# an EXECUTE.md + REVIEW.md with receipts and both drafts, so review and deploy reach their verifier re-runs
mk() { sh "$here/tests/fixture-execute.sh" "$1" >/dev/null 2>&1; cd "$1" || exit 2
  sed 's/`sh tests\/greet.test.sh` → exit 0/`touch pwned` → exit 0/' .v2p/PLAN.md > .v2p/p && mv .v2p/p .v2p/PLAN.md
  sha .v2p/PLAN.md > .v2p/.plan-pass
  printf '# EXECUTE\nchecked: x · branch %s · y\n' "$(git rev-parse --abbrev-ref HEAD)" > .v2p/EXECUTE.md; sha .v2p/EXECUTE.md > .v2p/.execute-pass
  printf '# REVIEW\nchecked: x\n' > .v2p/REVIEW.md; sha .v2p/REVIEW.md > .v2p/.review-pass
  printf 'checked: pending\n' > .v2p/REVIEW.draft.md
  printf 'written: 2026-11-13 · target: https://example.com · pr: #1 · base: main\nchecked: pending\n' > .v2p/DEPLOY.draft.md
  git add -A; git commit -qm 'clone: plan + receipt'; }
TR() { out=$($SH "$S/task-record.sh" "$@" 2>&1); rc=$?; }
FR() { out=$($SH "$S/finalize-review.sh" .v2p 2>&1); rc=$?; }
FD() { out=$(PATH=$base/fk:$PATH $SH "$S/finalize-deploy.sh" .v2p 2>&1); rc=$?; }
TP() { out=$($SH "$S/trust-plan.sh" "$@" 2>&1); rc=$?; }
for SH in sh zsh; do
  rm -rf "$XDG_CONFIG_HOME"
  # 1. the exploit: a valid shipped receipt, an empty ledger → no runner runs `touch pwned`
  mk "$base/c-$SH"
  is "1 receipt valid" "$(sh "$S/check-pass.sh" .v2p/PLAN.md .v2p/.plan-pass >/dev/null && echo ok)" ok
  TR start 1; TR verify 1; is "1 task-record pwned" "$(pwned)" no; is "1 task-record exit" "$([ $rc -ne 0 ] && echo nonzero)" nonzero
  has "1 task-record msg" "$out" "FAIL: PLAN.md is not trusted on this machine; review its Verifier commands with: sh $here/skills/v2p/scripts/trust-plan.sh $base/c-$SH"
  rm -f pwned; FR; is "1 finalize-review pwned" "$(pwned)" no; is "1 finalize-review exit" $rc 1; has "1 finalize-review msg" "$out" "PLAN.md is not trusted on this machine"
  rm -f pwned; FD; is "1 finalize-deploy pwned" "$(pwned)" no; is "1 finalize-deploy exit" $rc 1; has "1 finalize-deploy msg" "$out" "PLAN.md is not trusted on this machine"
  # 3. trust-plan.sh without --yes: lists the commands, writes nothing, exit 1
  TP "$base/c-$SH"; is "3 no --yes exit" $rc 1; has "3 lists command" "$out" "touch pwned"
  has "3 lists task 2" "$out" "sh -c 'grep -c hi src/greet.sh'"; has "3 names --yes" "$out" "trust-plan.sh $base/c-$SH --yes"
  is "3 no ledger" "$(test -e "$L" && echo yes)" ""; is "3 pwned" "$(pwned)" no
  # 3. an invalid receipt: refused, even with --yes
  cp .v2p/.plan-pass "$base/pp"; echo 0 > .v2p/.plan-pass
  TP "$base/c-$SH" --yes; is "3 bad receipt exit" $rc 1; has "3 bad receipt msg" "$out" "no valid receipt"; is "3 bad receipt no ledger" "$(test -e "$L" && echo yes)" ""
  cp "$base/pp" .v2p/.plan-pass
  # 3. with --yes: the hash is recorded once, and the runner proceeds
  TP "$base/c-$SH" --yes; is "3 --yes exit" $rc 0; is "3 ledger has hash" "$(cat "$L")" "$(sha .v2p/PLAN.md)	$base/c-$SH"
  TP "$base/c-$SH" --yes; is "3 no duplicate line" "$(grep -c . "$L")" 1
  # 5. ledger permissions
  is "5 ledger 0600" "$(ls -l "$L" | cut -c1-10)" "-rw-------"; is "5 dir 0700" "$(ls -ld "${L%/*}" | cut -c1-10)" "drwx------"
  rm -f pwned; TR verify 1; is "3 trusted task-record runs" "$(pwned)" ran; has "3 trusted verifier" "$out" "verifier: pass"
  rm -f pwned; FR; is "3 trusted finalize-review runs" "$(pwned)" ran
  # 4. PLAN edited after trust (receipt resealed by hand): ledger miss → nothing runs
  rm -f pwned; sed 's/`touch pwned`/`touch pwned; true`/' .v2p/PLAN.md > .v2p/p && mv .v2p/p .v2p/PLAN.md; sha .v2p/PLAN.md > .v2p/.plan-pass
  TR start 1; TR verify 1; is "4 edited task-record pwned" "$(pwned)" no; has "4 edited msg" "$out" "not trusted on this machine"
  FR; is "4 edited finalize-review pwned" "$(pwned)" no; FD; is "4 edited finalize-deploy pwned" "$(pwned)" no
  # 2. finalize-plan.sh trusts the PLAN it writes: the runner then runs with no trust-plan step
  rm -rf "$XDG_CONFIG_HOME"; mk "$base/p-$SH"; mv .v2p/PLAN.md .v2p/PLAN.draft.md; rm .v2p/.plan-pass
  mkdir -p 'app/[locale]'; : > 'app/[locale]/page.tsx'  # Task 2 modifies it: finalize-plan wants it to exist
  out=$($SH "$S/finalize-plan.sh" .v2p 2>&1); is "2 finalize-plan exit" $? 0
  is "2 ledger has hash" "$(cat "$L" 2>/dev/null)" "$(sha .v2p/PLAN.md)	$base/p-$SH"; is "2 ledger 0600" "$(ls -l "$L" | cut -c1-10)" "-rw-------"
  git add -A; git commit -qm plan; TR start 1; TR verify 1; is "2 runs after finalize-plan" "$(pwned)" ran
  # H1. finalize-plan auto-trusts only a draft this session wrote: root is its own git toplevel and the draft untracked
  pd() { mk "$1"; mv .v2p/PLAN.md .v2p/PLAN.draft.md; rm .v2p/.plan-pass; mkdir -p 'app/[locale]'; : > 'app/[locale]/page.tsx'; }
  FP() { out=$($SH "$S/finalize-plan.sh" .v2p 2>&1); rc=$?; }
  rm -rf "$XDG_CONFIG_HOME"; pd "$base/h1t-$SH"; git add -f .v2p/PLAN.draft.md; git commit -qm 'clone ships a draft'
  FP; is "H1 tracked draft finalized" $rc 0; is "H1 tracked draft receipt" "$(cat .v2p/.plan-pass)" "$(sha .v2p/PLAN.md)"
  is "H1 tracked draft not trusted" "$(test -e "$L" && echo yes)" ""; has "H1 tracked draft names trust-plan" "$out" "trust-plan.sh $base/h1t-$SH"
  git add -A; git commit -qm plan; TR start 1; TR verify 1; is "H1 tracked draft pwned" "$(pwned)" no
  rm -rf "$XDG_CONFIG_HOME"; pd "$base/h1n-$SH"; rm -rf .git
  FP; is "H1 no git finalized" $rc 0; is "H1 no git not trusted" "$(test -e "$L" && echo yes)" ""; has "H1 no git names trust-plan" "$out" "trust-plan.sh"
  rm -rf "$XDG_CONFIG_HOME"; mkdir -p "$base/h1s-$SH"; pd "$base/h1s-$SH/proj"; rm -rf .git; git -C "$base/h1s-$SH" init -q
  FP; is "H1 subdir of a repo finalized" $rc 0; is "H1 subdir of a repo not trusted" "$(test -e "$L" && echo yes)" ""
  # M2. control or non-ASCII bytes in a Verifier command: trust refused, nothing written, the task named
  esc=$(printf '\033'); cr=$(printf '\r')
  for bad in "$esc[2K" "$cr"; do rm -rf "$XDG_CONFIG_HOME"; mk "$base/m2-$SH"
    B=$bad awk '{ sub(/`touch pwned`/, "`touch pwned" ENVIRON["B"] "true`") } { print }' .v2p/PLAN.md > .v2p/p && mv .v2p/p .v2p/PLAN.md; sha .v2p/PLAN.md > .v2p/.plan-pass
    is "M2 byte is in the PLAN" "$(grep -cF "touch pwned$bad" .v2p/PLAN.md)" 1
    TP "$base/m2-$SH" --yes; is "M2 control byte exit" $rc 1; is "M2 control byte no ledger" "$(test -e "$L" && echo yes)" ""
    has "M2 control byte names task" "$out" "FAIL: task 1 "; cd "$base" || exit 2; done
  # R1. the listing prints each command verbatim: a literal backslash escape (`\033[2K\r`, all ASCII) never becomes ESC/CR
  rm -rf "$XDG_CONFIG_HOME"; mk "$base/r1-$SH"
  sed 's/`touch pwned`/`printf "\\033[2K\\r"; touch pwned`/' .v2p/PLAN.md > .v2p/p && mv .v2p/p .v2p/PLAN.md; sha .v2p/PLAN.md > .v2p/.plan-pass
  is "R1 PLAN holds the literal escape" "$(grep -cF 'printf "\033[2K\r"; touch pwned' .v2p/PLAN.md)" 1
  TP "$base/r1-$SH"; v=$(printf '%s\n' "$out" | cat -v)
  has "R1 listing shows the backslash text" "$v" 'task 1: printf "\033[2K\r"; touch pwned'
  is "R1 no ESC or CR in the listing" "$(printf '%s\n' "$v" | grep -c '\^\[\|\^M')" 0
  # R2. a draft tracked under another case is the same file on a case-insensitive disk: not auto-trusted
  rm -rf "$XDG_CONFIG_HOME"; pd "$base/r2-$SH"
  if [ -f .v2p/plan.draft.md ]; then
    git update-index --add --cacheinfo "100644,$(git hash-object -w .v2p/PLAN.draft.md),.v2p/plan.draft.md"; git commit -qm 'clone ships plan.draft.md'
    FP; is "R2 case-folded tracked draft finalized" $rc 0; is "R2 case-folded tracked draft not trusted" "$(test -e "$L" && echo yes)" ""
    has "R2 case-folded tracked draft names trust-plan" "$out" "trust-plan.sh"
  else echo "SKIP [$SH] R2 case-folded tracked draft: this filesystem is case-sensitive"; fi
  # R4. tracked is decided by file identity from the repo top: any index entry that IS the draft on disk (directory or
  # file name cased differently), and an index entry with a newline (unreadable line by line) fails closed
  for alias in .V2P/plan.draft.md .v2p/PLAN.DRAFT.MD; do rm -rf "$XDG_CONFIG_HOME"; pd "$base/r4-$SH"
    if [ -f "$alias" ]; then
      git update-index --add --cacheinfo "100644,$(git hash-object -w .v2p/PLAN.draft.md),$alias"; git commit -qm "clone ships $alias"
      FP; is "R4 $alias finalized" $rc 0; is "R4 $alias not trusted" "$(test -e "$L" && echo yes)" ""
    else echo "SKIP [$SH] R4 $alias: this filesystem is case-sensitive"; fi
    cd "$base" || exit 2; done
  rm -rf "$XDG_CONFIG_HOME"; pd "$base/r4n-$SH"
  git update-index --add --cacheinfo "100644,$(git hash-object -w README.md),odd
name"; git commit -qm 'an entry with a newline'
  FP; is "R4 newline entry finalized" $rc 0; is "R4 newline entry fails closed" "$(test -e "$L" && echo yes)" ""
  # R4. the normal path still trusts: a draft genuinely untracked in its own repo
  rm -rf "$XDG_CONFIG_HOME"; pd "$base/r4u-$SH"; FP; is "R4 untracked draft finalized" $rc 0
  is "R4 untracked draft trusted" "$(cat "$L" 2>/dev/null)" "$(sha .v2p/PLAN.md)	$base/r4u-$SH"; cd "$base" || exit 2
  # R3. a control character in the project root (newline, tab) is refused and the ledger left byte-identical
  rm -rf "$XDG_CONFIG_HOME"; cd "$base" || exit 2; mk "$base/r3ok-$SH"; TP "$base/r3ok-$SH" --yes; s0=$(sha "$L"); cd "$base" || exit 2
  for nm in "r3
nl-$SH" "r3	tab-$SH"; do mkdir -p "$base/$nm/.v2p"; cp "$base/r3ok-$SH/.v2p/PLAN.md" "$base/$nm/.v2p/PLAN.md"
    out=$(sh "$S/check-trust.sh" "$base/$nm/.v2p/PLAN.md" --add 2>&1); rc=$?
    is "R3 control char in root --add exit" $rc 1; has "R3 control char in root msg" "$out" "FAIL:"; is "R3 ledger unchanged" "$(sha "$L")" "$s0"
    out=$(sh "$S/check-trust.sh" "$base/$nm/.v2p/PLAN.md" 2>&1); is "R3 control char in root check exit" $? 1; done
  # M3. trust is per project path: an identical PLAN in another (or a moved) project is not trusted
  rm -rf "$XDG_CONFIG_HOME"; mk "$base/m3a-$SH"; TP "$base/m3a-$SH" --yes; is "M3 trust A" $rc 0
  cp -R "$base/m3a-$SH" "$base/m3b-$SH"; cd "$base/m3b-$SH" || exit 2; rm -f pwned
  TR start 1; TR verify 1; is "M3 copy not trusted" "$(pwned)" no; has "M3 copy msg" "$out" "not trusted on this machine"
  TP "$base/m3b-$SH"; has "M3 refusal names moved projects" "$out" "moved or renamed project"
  cd "$base" || exit 2
done
echo "test-trust: $fails failures (scratch: $base)"
[ "$fails" -eq 0 ] && rm -rf "$base"
[ "$fails" -eq 0 ]
