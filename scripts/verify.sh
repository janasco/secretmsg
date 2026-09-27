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
REPO="/opt/secretmsg/secretmsg"

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

section "File ownership"

# Everything here runs as root, so anything built or written is owned by root
# and the human operator cannot edit it in their own editor. This is not only an
# agent-hygiene problem: the web build's prerender step rewrites 215 tracked post
# JSON files plus public/sitemap.xml on every run, so a one-time `chown -R` is
# undone by the next gate run. A reconcile step is therefore necessary, not
# optional.
#
# It runs before the check deliberately, and the check is a real assertion over
# the end state rather than a comment saying the chown happened. The gate is the
# only enforcement point this project has - there is deliberately no CI - so the
# guarantee belongs here.
check "reconcile file ownership" bash -c '
  for repo in "'"$REPO"'" "'"$API"'"; do
    # git -C emits paths relative to the repo root, so the chown has to run from
    # that directory. Running it from the caller cwd silently misses every file
    # in the second repo.
    ( cd "$repo" && git ls-files -z | xargs -0 -r chown janasco:janasco )
  done
'
check "tracked files are owned by janasco" bash -c '
  for repo in "'"$REPO"'" "'"$API"'"; do
    # Same cwd requirement as the reconcile step. Getting this wrong makes stat
    # fail on every path, which would make this check pass unconditionally - a
    # guard that cannot fail is worse than no guard.
    offenders=$( cd "$repo" && git ls-files -z | xargs -0 -r stat -c "%U %n" 2>/dev/null \
      | grep -v "^janasco " || true )
    if [ -n "$offenders" ]; then
      count=$(printf "%s\n" "$offenders" | wc -l)
      echo "$count file(s) in $repo are not owned by janasco:"
      printf "%s\n" "$offenders" | head -10 | sed "s/^/      /"
      echo "      fix with: chown -R janasco:janasco $repo"
      exit 1
    fi
  done
'

printf '\n'
if [ "$failures" -eq 0 ]; then
  echo "All checks passed."
  exit 0
fi
echo "$failures check(s) failed."
exit 1
