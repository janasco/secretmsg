#!/bin/bash
# Local verification gate.
#
# This project does NOT use GitHub Actions. There are no workflows in either
# repo, by deliberate decision, to avoid GitHub Actions billing. This script
# runs the equivalent checks locally so the safety net survives that choice.
#
# Usage: bash scripts/verify.sh
# Exits non-zero if any check fails.
set -uo pipefail
export PATH="/home/janasco/.local/bin:/opt/flutter/bin:$PATH"

WEB="/opt/secretmsg/secretmsg/apps/web"
API="/opt/secretmsg/secretmsg-private"
MOB="/opt/secretmsg/secretmsg/apps/mobile-flutter"

failures=0
section() { printf '\n=== %s ===\n' "$1"; }
check() {
  local name="$1"; shift
  if "$@" >/tmp/verify.log 2>&1; then
    printf 'PASS  %s\n' "$name"
  else
    printf 'FAIL  %s\n' "$name"
    tail -15 /tmp/verify.log | sed 's/^/      /'
    failures=$((failures + 1))
  fi
}

section "Web (apps/web)"
check "typecheck" bash -c "cd '$WEB' && npx tsc --noEmit"
check "tests" bash -c "cd '$WEB' && npm test"
check "build + prerender" bash -c "cd '$WEB' && npm run build"
check "blog link integrity" bash -c "cd '$WEB' && node scripts/analyze-links.mjs --emitted | grep -q 'broken emitted /post links: 0'"

section "Android (apps/mobile-flutter)"
check "analyze" bash -c "cd '$MOB' && flutter analyze"
check "tests" bash -c "cd '$MOB' && flutter test"

section "API (secretmsg-private)"
check "tests" bash -c "cd '$API' && npm run api:test"
check "bundle syntax" bash -c "cd '$API' && /opt/secretmsg/node_modules/.bin/esbuild --bundle api/src/index.ts --format=esm --platform=neutral --outfile=/tmp/verify-bundle.js --log-level=warning"
check "admin CLI syntax" bash -c "node --check '$API/admin/manage.js'"

printf '\n'
if [ "$failures" -eq 0 ]; then
  echo "All checks passed."
  exit 0
fi
echo "$failures check(s) failed."
exit 1
