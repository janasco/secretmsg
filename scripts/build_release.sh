#!/usr/bin/env bash
# Build an upload-ready Android artifact with the real AdMob identifiers.
#
# AdMob ids are never committed. Supply them as environment variables (or the
# matching Gradle properties) and this script feeds the same values to both
# layers that need them:
#
#   * the AndroidManifest.xml APPLICATION_ID, via -PadmobAppId
#   * the Dart ad unit ids, via --dart-define
#
# Keeping one source of truth matters: the app id and the ad unit ids must
# belong to the same AdMob app, and neither layer can see the other's value.
#
# Required:
#   ADMOB_APP_ID               ca-app-pub-XXXXXXXXXXXXXXXX
#   ADMOB_BANNER_AD_UNIT_ID    ca-app-pub-XXXXXXXXXXXXXXXX/YYYYYYYYYY
#   ADMOB_REWARDED_AD_UNIT_ID  ca-app-pub-XXXXXXXXXXXXXXXX/YYYYYYYYYY
#
# Usage:
#   scripts/build_release.sh aab     -> build/app/outputs/bundle/release/
#   scripts/build_release.sh apk     -> build/app/outputs/flutter-apk/
#
# The keystore is configured separately by scripts/setup-upload-keystore.sh.

set -euo pipefail

format="${1:-aab}"
app_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")/../apps/mobile-flutter" && pwd)"

# Resolve the Flutter SDK: PATH first, then $FLUTTER_BIN, then the common
# install location. A clear error beats "flutter: command not found" after
# every check has already passed.
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

if [[ ! "$format" =~ ^(aab|apk)$ ]]; then
  echo "usage: $0 [aab|apk] [extra flutter build args...]" >&2
  exit 64
fi
# Consume the format so "$@" below forwards only the extra flutter build args.
shift

# A placeholder is rejected here so the failure is immediate and obvious rather
# than surfacing later as an unexplained Gradle error.
placeholder="ca-app-pub-0000000000000000"
is_real() {
  [[ "$1" == ca-app-pub-* && "$1" != *"$placeholder"* && "$1" == *"/"* ]]
}

for var in ADMOB_APP_ID ADMOB_BANNER_AD_UNIT_ID ADMOB_REWARDED_AD_UNIT_ID; do
  value="${!var:-}"
  if [[ -z "$value" ]]; then
    echo "error: $var is not set." >&2
    echo "       Create the app and ad units in the AdMob console, then export:" >&2
    if [[ "$var" == ADMOB_APP_ID ]]; then
      echo "         export $var=ca-app-pub-XXXXXXXXXXXXXXXX" >&2
    else
      echo "         export $var=ca-app-pub-XXXXXXXXXXXXXXXX/YYYYYYYYYY" >&2
    fi
    exit 78
  fi
  if [[ "$value" == *"$placeholder"* ]]; then
    echo "error: $var still holds the placeholder value." >&2
    exit 78
  fi
  if [[ "$var" != ADMOB_APP_ID ]] && ! is_real "$value"; then
    echo "error: $var must be a full ad unit id (ca-app-pub-APP/UNIT)." >&2
    exit 78
  fi
done

echo "AdMob identifiers present. Building $format."

# Gradle injects the app id into the manifest; --dart-define reaches Dart.
# Capped daemon memory keeps the build inside a small container.
dart_defines=(
  "--dart-define=ADMOB_APP_ID=$ADMOB_APP_ID"
  "--dart-define=ADMOB_BANNER_AD_UNIT_ID=$ADMOB_BANNER_AD_UNIT_ID"
  "--dart-define=ADMOB_REWARDED_AD_UNIT_ID=$ADMOB_REWARDED_AD_UNIT_ID"
)
gradle_args=(
  "-PadmobAppId=$ADMOB_APP_ID"
  "-PadmobBannerAdUnitId=$ADMOB_BANNER_AD_UNIT_ID"
  "-PadmobRewardedAdUnitId=$ADMOB_REWARDED_AD_UNIT_ID"
)

build_cmd=("$flutter_bin" build)
if [[ "$format" == "aab" ]]; then
  build_cmd+=(appbundle)
else
  build_cmd+=(apk)
fi

cd "$app_dir"
GRADLE_OPTS="${GRADLE_OPTS:--Xmx1G -XX:MaxMetaspaceSize=512m}" \
  "${build_cmd[@]}" --release "${gradle_args[@]}" "${dart_defines[@]}" "$@"

echo
echo "Built $format. Verify the identifiers were actually embedded:"
if [[ "$format" == "aab" ]]; then
  echo "  \$ANDROID_HOME/../../cmdline-tools unzip -p app/build/outputs/bundle/release/*.aab base/manifest/AndroidManifest.xml"
else
  echo "  \$ANDROID_HOME/build-tools/<ver>/aapt2 dump xmltree app-release.apk --file AndroidManifest.xml"
fi
