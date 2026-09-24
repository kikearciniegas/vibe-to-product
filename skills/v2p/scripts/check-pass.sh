#!/bin/sh
# Exit 0 only if <file> is byte-identical to what its finalize script wrote.
# Usage: sh check-pass.sh .v2p/SCAVENGE.md .v2p/.scavenge-pass
f=$1; receipt=$2
[ -f "$f" ] || { echo "FAIL: $f missing"; exit 1; }
[ -f "$receipt" ] || { echo "FAIL: no receipt ($receipt): $f was not written by its finalize script"; exit 1; }
[ "$(shasum -a 256 "$f" | cut -d' ' -f1)" = "$(cat "$receipt")" ] || { echo "FAIL: $f changed after finalize (hash mismatch)"; exit 1; }
echo "OK: $f matches its receipt"
