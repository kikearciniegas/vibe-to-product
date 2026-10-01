#!/bin/sh
# hooks/guard-finals.sh fed PreToolUse hook JSON on stdin, under sh and zsh: every write path to a final, an execute
# record or a .*-pass seal is blocked (exit 2 + message); running the scripts, reads and git add/commit pass (exit 0).
# Case 8 is the exact forged seal from the first live execute run. Writes only ${TMPDIR:-/tmp}/v2p-guard.<pid> (a root
# DESIGN.md symlink and a regular root DESIGN.md), removed at the end. Usage: sh tests/test-guard.sh
here=$(cd "$(dirname "$0")/.." && pwd -P); G=$here/skills/v2p/hooks/guard-finals.sh
fails=0
esc() { printf '%s' "$1" | sed 's/\\/\\\\/g; s/"/\\"/g' | awk 'NR > 1 { printf "%s", "\\n" } { printf "%s", $0 }'; }
nl='
'
run() { out=$(printf '%s' "$1" | $SH "$G" 2>&1); rc=$?; }
json() { printf '{"session_id":"s","transcript_path":"/Users/user/.claude/projects/x/s.jsonl","cwd":"/Users/user/tmp/v2p-exec/.worktrees/v2p-execute-2026-09-24","hook_event_name":"PreToolUse","tool_name":"%s","tool_input":%s}' "$1" "$2"; }
check() { # <label> <want exit> <tool> <tool_input json>
  run "$(json "$3" "$4")"
  if [ "$rc" = "$2" ] && { [ "$2" = 0 ] || case $out in v2p:*) true ;; *) false ;; esac; }; then echo "PASS [$SH] $1"
  else echo "FAIL [$SH] $1: exit $rc want $2; stderr: $out"; fails=$((fails+1)); fi; }
B() { check "block Bash: $1" 2 Bash "{\"command\":\"$(esc "$1")\",\"description\":\"d\"}"; }
A() { check "allow Bash: $1" 0 Bash "{\"command\":\"$(esc "$1")\",\"description\":\"d\"}"; }
W() { check "$1 $2: $3" "$1" "$2" "{\"file_path\":\"$(esc "$3")\",\"content\":\"x\"}"; }
S=/Users/user/.claude/skills/v2p/scripts; P=/Users/user/tmp/v2p-exec/.worktrees/v2p-execute-2026-09-24
t=$(cd "${TMPDIR:-/tmp}" && pwd -P)/v2p-guard.$$; mkdir -p "$t/link/.v2p" "$t/plain"; ln -s .v2p/DESIGN.md "$t/link/DESIGN.md"; echo x > "$t/plain/DESIGN.md"
for SH in sh zsh; do
  # block: Write/Edit/MultiEdit on records, seals and finals
  W 2 Write "$P/.v2p/work/execute-task-5.md"; W 2 Edit .v2p/work/execute-task-5.md; W 2 MultiEdit "$P/.v2p/work/execute-task-6.md"
  W 2 Write "$P/.v2p/work/.execute-task-5-pass"; W 2 Edit .v2p/work/.execute-task-6-pass
  W 2 Write "$P/.v2p/.plan-pass"; W 2 Write .v2p/.execute-pass; W 2 Edit "$P/.v2p/.review-pass"
  W 2 Write "$P/.v2p/EXECUTE.md"; W 2 Edit .v2p/PLAN-AMENDMENTS.md
  # block: shell writes
  B "shasum -a 256 .v2p/work/execute-task-5.md | cut -d' ' -f1 > .v2p/work/.execute-task-5-pass"
  B "shasum -a 256 $P/.v2p/work/execute-task-6.md | cut -d' ' -f1 > $P/.v2p/work/.execute-task-6-pass"
  B "echo abc >> .v2p/.plan-pass"
  B "sha256sum .v2p/EXECUTE.md | tee .v2p/.execute-pass"
  B "cp /tmp/rec.md .v2p/work/execute-task-5.md"
  B "mv /tmp/seal .v2p/work/.execute-task-5-pass"
  B "install -m 644 /tmp/seal .v2p/.execute-pass"
  B "dd if=/tmp/seal of=.v2p/work/.execute-task-5-pass"
  B "sed -i '' 's/verifier: fail/verifier: pass/' .v2p/work/execute-task-5.md"
  B "printf 'x\n' > .v2p/work/execute-task-7.md"
  B "echo x > .v2p/PLAN.md"
  # allow: the scripts, reads, git, ordinary files
  A "sh $S/task-record.sh verify 5"
  A "sh $S/task-record.sh start 5"
  A "sh $S/task-record.sh start 8 --base 4960cfc \"start ran after the implementer committed\""
  A "sh $S/task-record.sh allow 5 src/x.tsx \"reviewer asked\""
  A "sh $S/finalize-execute.sh .v2p"
  A "sh $S/drift-check.sh 5"
  A "cat .v2p/work/execute-task-5.md"
  A "cat .v2p/work/.execute-task-5-pass"
  A "shasum -a 256 .v2p/work/execute-task-5.md"
  A "shasum -a 256 .v2p/work/execute-task-5.md > /tmp/check.txt"
  A "grep verifier .v2p/work/execute-task-5.md 2>/dev/null"
  A "[ \"\$(git rev-parse --abbrev-ref HEAD)\" = v2p/execute-2026-09-24 ] && git add -A && git commit -m \"feat: landing sections\""
  A "ls -la .v2p/work/"
  W 0 Write "$P/.v2p/EXECUTE.draft.md"; W 0 Write "$P/src/sections/Hero.tsx"; W 0 Edit .v2p/work/notes.md
  # brand: .v2p/DESIGN.md is finalize-brand.sh's; writing through the root symlink to it is blocked, a regular root file is not
  W 2 Write "$P/.v2p/DESIGN.md"; W 2 Edit .v2p/.brand-pass; W 2 Write "$t/link/DESIGN.md"
  B "mv DESIGN.md .v2p/DESIGN.md"; B "echo x > .v2p/.brand-pass"
  A "sh $S/finalize-brand.sh .v2p"; A "sh $S/archive-cycle.sh .v2p"
  W 0 Write "$P/.v2p/DESIGN.draft.md"; W 0 Write "$t/plain/DESIGN.md"
  # deploy: .v2p/DEPLOY.md is finalize-deploy.sh's; its seal is covered by the -pass rule
  W 2 Write "$P/.v2p/DEPLOY.md"; W 2 Edit .v2p/DEPLOY.md; B "echo x > .v2p/DEPLOY.md"; B "cp /tmp/d.md $P/.v2p/DEPLOY.md"; B "echo x > .v2p/.deploy-pass"
  A "sh $S/finalize-deploy.sh .v2p"; A "cat .v2p/DEPLOY.md"; W 0 Write "$P/.v2p/DEPLOY.draft.md"; A "cp /tmp/d.md .v2p/DEPLOY.draft.md"
  check "allow Read tool" 0 Read "{\"file_path\":\"$P/.v2p/work/.execute-task-5-pass\"}"
  # V29: write TARGETS are blocked, mentions are not (a JSON \n is a command separator, single-quoted text is inert)
  A "cat >> notes.md <<EOF${nl}see .v2p/PLAN.md${nl}EOF"
  A "cp .v2p/PLAN.md /tmp/x/PLAN.md"; A "cp .v2p/.plan-pass /tmp/x"; A "mv $P/.v2p/REVIEW.md /tmp/x/ 2>/dev/null"
  A "printf 'the tee step reads .v2p/PLAN.md\n'"; A "git commit -m 'cp the draft over .v2p/PLAN.md'"
  B "cp /tmp/x .v2p/PLAN.md"; B "mv /tmp/x $P/.v2p/REVIEW.md && echo ok"; B "cp -f /tmp/x '.v2p/PLAN.md' 2>&1"
  B "tee .v2p/PLAN.md"; B "echo x | tee -a notes.md .v2p/PLAN.md >/dev/null"
  B "sed -i '' 's/a/b/' .v2p/PLAN.md"; B "sed -i.bak -e 's/a/b/' $P/.v2p/PLAN.md"
  B "echo ok${nl}echo x > .v2p/PLAN.md"; B "cat > .v2p/PLAN.md <<'EOF'${nl}x${nl}EOF"; B "cp /tmp/x \\${nl}  .v2p/PLAN.md"
  B "echo x > '.v2p/PLAN.md'"; B "dd if=/tmp/x of=\".v2p/PLAN.md\""
  B "f=.v2p/PLAN.md; echo x > \$f"; B "f=.v2p/PLAN.md; cp /tmp/x \"\${f}\""; A "f=.v2p/PLAN.md; cat \$f"
  B "bash -c 'echo x > .v2p/PLAN.md'"; B "eval 'cp /tmp/x .v2p/PLAN.md'"; B "echo \"\$(echo x > .v2p/PLAN.md)\""
  B "sudo cp /tmp/x .v2p/PLAN.md"; B "if true; then cp /tmp/x .v2p/PLAN.md; fi"; B "echo x 2>&1 >.v2p/PLAN.md"
  B "echo ok${nl}cp /tmp/x .v2p/PLAN.md"; A "cp /tmp/a /tmp/b${nl}cat .v2p/PLAN.md"; A "echo 'x > .v2p/PLAN.md'"
  A "cat >> notes.md <<'EOF'${nl}don't echo x > .v2p/PLAN.md${nl}EOF"; B "cat <<-EOF > /tmp/y${nl}	x${nl}	EOF${nl}cp /tmp/y .v2p/PLAN.md"
  A "echo hi # > .v2p/PLAN.md"; A "echo x > .v2p/PLAN.md.bak"; B "echo \"x\\\\\" > .v2p/PLAN.md"; A "echo \"x\\\" > .v2p/PLAN.md\""
done
rm -rf "$t"; echo "test-guard: $fails failures"
[ "$fails" -eq 0 ]
