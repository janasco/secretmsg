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

# --check-only validates the AdMob identifiers and exits without building.
# scripts/build_sideload.sh builds the same artifact with a different signing
# key, and reuses these checks rather than keeping a second copy of the format
# rules that could drift out of agreement with this one.
if [[ "$format" == "--check-only" ]]; then
  format="apk"
  check_only=1
fi

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
# than surfacing later as an unexplained Gradle error. AdMob uses two formats: the
# app id has a ~ and belongs in the manifest, ad unit ids have a / and are used
# in requests. Each slot is checked against its own format.
placeholder_pub="0000000000000000"
app_id_re='^ca-app-pub-([0-9]{16})~[0-9]{6,16}$'
ad_unit_re='^ca-app-pub-([0-9]{16})/[0-9]{6,16}$'

publisher_of() {
  local value="$1"
  if [[ "$value" =~ $app_id_re ]]; then printf '%s' "${BASH_REMATCH[1]}"
  elif [[ "$value" =~ $ad_unit_re ]]; then printf '%s' "${BASH_REMATCH[1]}"
  else printf ''
  fi
}

check() {
  local var="$1" value="${!1:-}" pattern="$2" label="$3"
  if [[ -z "$value" ]]; then
    echo "error: $var is not set." >&2
    echo "       Create the app and ad units in the AdMob console, then export:" >&2
    if [[ "$label" == "app" ]]; then
      echo "         export $var=ca-app-pub-XXXXXXXXXXXXXXXX~YYYYYYYYYY" >&2
    else
      echo "         export $var=ca-app-pub-XXXXXXXXXXXXXXXX/YYYYYYYYYY" >&2
    fi
    exit 78
  fi
  if [[ "$value" == *"$placeholder_pub"* ]]; then
    echo "error: $var still holds the placeholder value." >&2
    exit 78
  fi
  if [[ ! "$value" =~ $pattern ]]; then
    echo "error: $var is not a valid AdMob $label id." >&2
    if [[ "$label" == "app" ]]; then
      echo "       An app id looks like ca-app-pub-1234567890123456~1234567890" >&2
      echo "       (tilde, and it goes in the manifest)." >&2
    else
      echo "       An ad unit id looks like ca-app-pub-1234567890123456/1234567890" >&2
      echo "       (slash, and it is used in ad requests)." >&2
    fi
    exit 78
  fi
}

check ADMOB_APP_ID "$app_id_re" "app"
check ADMOB_BANNER_AD_UNIT_ID "$ad_unit_re" "ad unit"
check ADMOB_REWARDED_AD_UNIT_ID "$ad_unit_re" "ad unit"

# All three must belong to one AdMob account. A unit from another account builds
# fine, serves nothing, and reports no error.
app_pub="$(publisher_of "$ADMOB_APP_ID")"
banner_pub="$(publisher_of "$ADMOB_BANNER_AD_UNIT_ID")"
rewarded_pub="$(publisher_of "$ADMOB_REWARDED_AD_UNIT_ID")"
if [[ "$app_pub" != "$banner_pub" || "$app_pub" != "$rewarded_pub" ]]; then
  echo "error: the three ids come from different AdMob accounts." >&2
  echo "       app      ${ADMOB_APP_ID} -> pub-$app_pub" >&2
  echo "       banner   ${ADMOB_BANNER_AD_UNIT_ID} -> pub-$banner_pub" >&2
  echo "       rewarded ${ADMOB_REWARDED_AD_UNIT_ID} -> pub-$rewarded_pub" >&2
  exit 78
fi

echo "AdMob identifiers present. Building $format."
if [[ "${check_only:-0}" == "1" ]]; then
  echo "(--check-only: identifiers are valid, stopping before the build.)"
  exit 0
fi

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
