#!/usr/bin/env bash
# Build the APKs published on the website, signed with the dedicated SIDELOAD key.
#
# Same artifact, same AdMob identifiers, same --dart-define/-P wiring as
# scripts/build_release.sh — the only difference is the signing key. That is the
# whole point: the Play upload key signs an artifact destined for Google Play
# App Signing to re-sign, while these APKs are installed directly by people, so
# the signature on them is a permanent, publicly visible fact about the app.
#
# The distinction is carried by exactly one flag, -PsideloadSigning=true. Without
# it the release build keeps signing with the Play upload key exactly as before,
# so the upload path is untouched. The same flag has a second consequence that is
# deliberately not repeated here: android/app/build.gradle appends
# --dart-define=SECRETMSG_DISTRIBUTION_TRACK=sideload to the dart-defines below
# whenever the flag is set, so the app knows at runtime which track's download
# page the update feed should point it at. Do not pass that define by hand — a
# track that disagrees with the signing key is precisely the failure it exists
# to prevent, and Gradle overwrites a hand-rolled value.
#
#   scripts/build_release.sh aab   -> Play upload artifact (upload key)
#   scripts/build_sideload.sh      -> per-ABI public APKs (sideload key)
#
# AdMob ids are required and are never committed. They are read from the same
# place build_release.sh expects them (environment, or -P overrides):
#   set -a; . /opt/secretmsg/.secrets/admob.env; set +a
#
# Usage:
#   scripts/build_sideload.sh [extra flutter build args...]

set -euo pipefail

app_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")/../apps/mobile-flutter" && pwd)"

flutter_bin="${FLUTTER_BIN:-}"
if [[ -z "$flutter_bin" ]]; then
  if command -v flutter >/dev/null 2>&1; then
    flutter_bin="$(command -v flutter)"
  elif [[ -x /opt/flutter/bin/flutter ]]; then
    flutter_bin=/opt/flutter/bin/flutter
  else
    echo "error: flutter not found. Install it or set FLUTTER_BIN to its path." >&2
    exit 69
  fi
fi

# Reuse build_release.sh's AdMob validation verbatim rather than keeping a second
# copy of the format rules, which would eventually disagree with the first.
bash "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/build_release.sh" --check-only

dart_defines=(
  "--dart-define=ADMOB_APP_ID=$ADMOB_APP_ID"
  "--dart-define=ADMOB_BANNER_AD_UNIT_ID=$ADMOB_BANNER_AD_UNIT_ID"
  "--dart-define=ADMOB_REWARDED_AD_UNIT_ID=$ADMOB_REWARDED_AD_UNIT_ID"
)
gradle_args=(
  "-PadmobAppId=$ADMOB_APP_ID"
  "-PadmobBannerAdUnitId=$ADMOB_BANNER_AD_UNIT_ID"
  "-PadmobRewardedAdUnitId=$ADMOB_REWARDED_AD_UNIT_ID"
  "-PsideloadSigning=true"
)

echo "Building split-per-abi release APKs signed with the sideload key."
cd "$app_dir"
GRADLE_OPTS="${GRADLE_OPTS:--Xmx1G -XX:MaxMetaspaceSize=512m}" \
  "$flutter_bin" build apk --release --split-per-abi \
  "${gradle_args[@]}" "${dart_defines[@]}" "$@"

echo
echo "Built. Confirm the signature is the sideload key, not the upload or debug key:"
echo "  \$ANDROID_HOME/build-tools/<ver>/apksigner verify --print-certs app/build/outputs/flutter-apk/app-*-release.apk"
