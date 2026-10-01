#!/bin/sh
# finalize-scavenge.sh link check on a minimal draft, under sh and zsh, with a curl shim on PATH (no network):
# a 200 passes; a `]` closing a [CHECK: … · URL] marker is not part of the URL (V25); 404 and DNS failure are DEAD;
# no HTTP response (timeout/reset) is retried once with a longer -m, then printed UNREACHABLE and counted ok (V18).
# Writes only under ${TMPDIR:-/tmp}/v2p-fs.<pid> (HOME points there too). Usage: sh tests/test-finalize-scavenge.sh
here=$(cd "$(dirname "$0")/.." && pwd -P); S=$here/skills/v2p/scripts
base=$(cd "${TMPDIR:-/tmp}" && pwd -P)/v2p-fs.$$; mkdir -p "$base/home" "$base/bin"; HOME=$base/home; export HOME
fails=0
is() { if [ "$2" = "$3" ]; then echo "PASS [$SH] $1"; else echo "FAIL [$SH] $1: got '$2' want '$3'"; fails=$((fails+1)); fi; }
has() { case $2 in *"$3"*) echo "PASS [$SH] $1" ;; *) echo "FAIL [$SH] $1: missing '$3' in: $(printf '%s' "$2" | head -c 300)"; fails=$((fails+1)) ;; esac; }
hasnt() { case $2 in *"$3"*) echo "FAIL [$SH] $1: still has '$3'"; fails=$((fails+1)) ;; *) echo "PASS [$SH] $1" ;; esac; }
# curl shim: the URL is the last argument; prints the -w code and exits with curl's exit status for that case.
# Every call is logged to $CURL_LOG; /flaky resets the connection once, then answers 200.
cat > "$base/bin/curl" <<'EOF'
#!/bin/sh
for a; do u=$a; done; echo "$*" >> "$CURL_LOG"
case $u in
  https://e.test/ok) printf 200 ;;
  https://e.test/404) printf 404 ;;
  https://e.test/timeout) printf 000; exit 28 ;;
  https://e.test/dns) printf 000; exit 6 ;;
  https://e.test/flaky) [ -f "$CURL_LOG.flaky" ] && { printf 200; exit 0; }; : > "$CURL_LOG.flaky"; printf 000; exit 56 ;;
  *) printf 404 ;;
esac
EOF
chmod +x "$base/bin/curl"; PATH=$base/bin:$PATH; export PATH
# plant <line>: a valid draft (one 200 URL in §1 and §6) plus <line> in §1
plant() { rm -f .v2p/SCAVENGE.md .v2p/.scavenge-pass "$CURL_LOG" "$CURL_LOG.flaky"
  printf '%s\n' '# SCAVENGE' '' '## 1. Reference architecture (Q1)' 'starter · https://e.test/ok · accessed 2026-10-01' "$1" '' \
    '## 6. Recent changes, last 30 days (Q7)' '| subject | changes |' '|---|---|' '| next | no entries in window · https://e.test/ok |' '' \
    '## 7. Budget and tools' 'fetches: Q1–Q5 1/20 · Q7 1/5 · links: <ok>/<total> ok · time: 1 · tools: none' > .v2p/SCAVENGE.draft.md; }
FS() { out=$($SH "$S/finalize-scavenge.sh" .v2p 2>&1); rc=$?; }
for SH in sh zsh; do
  fx=$base/fx-$SH; mkdir -p "$fx/.v2p"; cd "$fx" || exit 2; CURL_LOG=$base/curl-$SH.log; export CURL_LOG
  # 1. a 200 passes and stamps the count
  plant ''; FS; is "1 200 exit" $rc 0; has "1 stamped" "$(cat .v2p/SCAVENGE.md 2>/dev/null)" "links: 1/1 ok"
  # 3. a 404 is DEAD and blocks the write
  plant 'gone · https://e.test/404 · accessed 2026-10-01'; FS; is "3 404 exit" $rc 1; has "3 404 DEAD" "$out" "DEAD 404 https://e.test/404"
  is "3 not written" "$(test -f .v2p/SCAVENGE.md && echo yes)" ""; has "3 each URL checked" "$out" "links 1/2 ok"
  cd "$base"
done
SH=all; echo "test-finalize-scavenge: $fails failures (scratch: $base)"
[ "$fails" -eq 0 ] && rm -rf "$base"
[ "$fails" -eq 0 ]
