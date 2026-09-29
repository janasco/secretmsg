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

# Theme/contrast analysis. src/index.css remaps individual Tailwind *class
# tokens* for light mode, so an opacity-modified class (text-amber-200/90 vs
# text-amber-200) silently opts out of the remap and renders the dark-theme
# colour on light paper. That shipped once already and no other check here can
# see it. Default failing mode is `bypass` and findings already present are held
# in scripts/a11y/baseline.json, so this fails on the *next* one and not on
# today's backlog; --strict is opt-in for the whole set.
check "a11y colour remap bypasses + contrast" bash -c "cd '$WEB' && node scripts/a11y-color.mjs"

section "Android (apps/mobile-flutter)"
check "analyze" bash -c "cd '$MOB' && flutter analyze"
check "tests" bash -c "cd '$MOB' && flutter test"

# Theme-blind colour literals and the palette contrast matrix. The Daily Drop
# bug (fixed in 43aa190) was a hardcoded dark gradient in both themes, with
# light-mode text on top of it at 1.06:1 - and `flutter analyze` cannot see it,
# because nothing about that code is ill-typed. This is the check that can.
#
# It is plain Dart and reads the palette out of lib/theme.dart as text, so it
# needs no Flutter toolchain and runs in well under a second against a gate
# that takes ten minutes.
#
# The default strictness, `surface`, fails on a NEW theme-blind surface or
# gradient-stop literal and nothing else. That is deliberate: the defect that
# actually shipped was a surface, and a gate that also failed on the 94
# pre-existing palette shortfalls would be red on day one with no bug to point
# at, and would be switched off. The shortfalls are recorded in
# tool/a11y/a11y_baseline.json with a reason each and stay visible in the
# report on every run. `--strictness=text` widens the gate to text literals,
# `--strictness=strict` also fails on an unrecorded pairing.
check "a11y detector self-test" bash -c "cd '$MOB' && dart run tool/a11y/test/detector_test.dart"
check "a11y theme-blind colours + contrast matrix" bash -c "cd '$MOB' && dart run tool/a11y/lint.dart"
# Fails if a palette value moved without regenerating the recorded pairings.
# Without this, an edit to lib/theme.dart silently invalidates 94 recorded
# exceptions and the next run reports nothing at all.
check "a11y baseline matches the palette" bash -c "cd '$MOB' && dart run tool/a11y/regen_baseline.dart --check"

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
