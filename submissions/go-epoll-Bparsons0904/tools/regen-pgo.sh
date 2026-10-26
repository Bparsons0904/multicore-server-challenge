#!/usr/bin/env bash
# Regenerates default.pgo, the CPU profile the Go compiler uses for profile-guided optimization.
# usage: tools/regen-pgo.sh <profile URL> [seconds]
#   e.g. tools/regen-pgo.sh http://127.0.0.1:6060 60
# The URL is the pprof server of a `-tags lab` build started with CONDUIT_PPROF=127.0.0.1:6060, under load. Re-run it
# after the code changes; a stale profile only costs optimization, never correctness.
set -euo pipefail
cd "$(dirname "$0")/.."
url=${1:?usage: $0 <profile URL> [seconds]}
secs=${2:-60}
GO=/usr/local/go/bin/go
[ -x "$GO" ] || GO=go
tmp=$(mktemp)
trap 'rm -f "$tmp"' EXIT
curl -fsS --max-time $((secs + 30)) "${url%/}/debug/pprof/profile?seconds=$secs" -o "$tmp"
# A usable profile has samples; fail on an empty or non-pprof reply instead of writing it.
"$GO" tool pprof -top -nodecount=1 "$tmp" >/dev/null
mv "$tmp" default.pgo
trap - EXIT
echo "wrote default.pgo ($(wc -c <default.pgo) bytes); rebuild with build.sh"
