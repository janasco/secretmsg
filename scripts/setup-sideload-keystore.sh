#!/bin/bash
# Generate the SIDELOAD signing keystore and the Flutter sideload release
# signing config.
#
# Why this key is separate from scripts/setup-upload-keystore.sh:
# the Play upload key exists only to hand an artifact to Google Play App
# Signing, which re-signs it with the per-app key it manages. The sideload key
# is the one whose signature the user actually installs. Mixing the two would
# bake a Play-upload secret into every publicly downloadable APK, and signing
# the sideload APKs with the debug key (as v1.6.8/v1.6.9 were) means they can
# never be upgraded onto a Play-installed build without a reinstall.
#
# Read passwords from the gitignored .env.production; never echoes them and
# never places them on a command line (keytool -storepass:env).
set -euo pipefail
set -o pipefail
export PATH="/home/janasco/.local/bin:/opt/flutter/bin:/opt/android-sdk/build-tools/35.0.0:$PATH"

ENV_FILE="/opt/secretmsg/secretmsg-private/.env.production"
ANDROID_DIR="/opt/secretmsg/secretmsg/apps/mobile-flutter/android"
KEYSTORE_OWNER="${KEYSTORE_OWNER:-janasco}"

set -a
# shellcheck disable=SC1090
source "$ENV_FILE"
set +a

: "${SIDELOAD_KEYSTORE_PATH:?SIDELOAD_KEYSTORE_PATH not set in .env.production}"
: "${SIDELOAD_KEYSTORE_KEY_ALIAS:?SIDELOAD_KEYSTORE_KEY_ALIAS not set in .env.production}"
: "${SIDELOAD_KEYSTORE_STORE_PASSWORD:?SIDELOAD_KEYSTORE_STORE_PASSWORD is empty in .env.production}"
KEY_PASSWORD="${SIDELOAD_KEYSTORE_KEY_PASSWORD:-$SIDELOAD_KEYSTORE_STORE_PASSWORD}"

if [ "${#SIDELOAD_KEYSTORE_STORE_PASSWORD}" -lt 6 ]; then
  echo "ERROR: store password must be at least 6 characters." >&2
  exit 1
fi
if [ "$KEY_PASSWORD" != "$SIDELOAD_KEYSTORE_STORE_PASSWORD" ] && [ "${#KEY_PASSWORD}" -lt 6 ]; then
  echo "ERROR: key password must be at least 6 characters." >&2
  exit 1
fi

# PKCS12 protects the private key with the *store* password; keytool prints
# "Different store and key password not supported for PKCS12 KeyStores" and
# silently drops -keypass. The keystore that lands on disk therefore only ever
# opens with the store password, and an android/sideload-key.properties carrying
# a different keyPassword makes Gradle fail at packageRelease with a padding
# error that looks nothing like a password mismatch. Refuse to write that config
# rather than leave a keystore nobody can sign with. (The Play upload key has the
# same constraint; it happens to work today only because its two passwords match.)
if [ "$KEY_PASSWORD" != "$SIDELOAD_KEYSTORE_STORE_PASSWORD" ]; then
  echo "ERROR: SIDELOAD_KEYSTORE_KEY_PASSWORD differs from SIDELOAD_KEYSTORE_STORE_PASSWORD." >&2
  echo "       A PKCS12 keystore has a single password. Set them equal, or switch" >&2
  echo "       -storetype to JKS in this script if you truly need two." >&2
  exit 1
fi

# The upload key must never end up in a sideload build, and this key must never
# end up in a Play upload. Guard both against a mis-set variable.
if [ "${SIDELOAD_KEYSTORE_PATH}" = "${ANDROID_KEYSTORE_PATH:-}" ]; then
  echo "ERROR: SIDELOAD_KEYSTORE_PATH is the upload keystore path." >&2
  echo "       The two keys must stay separate; refusing to continue." >&2
  exit 1
fi

export SIDELOAD_KEYSTORE_STORE_PASSWORD SIDELOAD_KEYSTORE_KEY_PASSWORD="$KEY_PASSWORD"

mkdir -p "$(dirname "$SIDELOAD_KEYSTORE_PATH")"
chmod 700 "$(dirname "$SIDELOAD_KEYSTORE_PATH")"

if [ -f "$SIDELOAD_KEYSTORE_PATH" ]; then
  echo "Keystore already exists at $SIDELOAD_KEYSTORE_PATH — refusing to overwrite."
else
  echo "Generating sideload keystore (alias $SIDELOAD_KEYSTORE_KEY_ALIAS)..."
  # A single password: PKCS12 has no separate key password (see check above).
  #
  # The DN deliberately says "Sideload" and does not match the upload key's DN.
  # `apksigner verify --print-certs` leads with the DN, and two keys that must
  # never be confused are worthless if the only line a human reads looks the
  # same for both.
  keytool -genkeypair -v \
    -keystore "$SIDELOAD_KEYSTORE_PATH" \
    -storetype PKCS12 \
    -keyalg RSA -keysize 2048 -validity 10000 \
    -alias "$SIDELOAD_KEYSTORE_KEY_ALIAS" \
    -storepass:env SIDELOAD_KEYSTORE_STORE_PASSWORD \
    -dname "CN=SecretMsg Sideload, O=SecretMsg, L=Remote, ST=NA, C=US"
  echo "Keystore created."
fi

chmod 600 "$SIDELOAD_KEYSTORE_PATH"
chown "$KEYSTORE_OWNER":"$KEYSTORE_OWNER" "$SIDELOAD_KEYSTORE_PATH" 2>/dev/null || true

echo "Verifying keystore integrity..."
keytool -list -v \
  -keystore "$SIDELOAD_KEYSTORE_PATH" \
  -alias "$SIDELOAD_KEYSTORE_KEY_ALIAS" \
  -storepass:env SIDELOAD_KEYSTORE_STORE_PASSWORD >/dev/null
echo "Keystore opens and contains alias $SIDELOAD_KEYSTORE_KEY_ALIAS."

umask 077
cat > "$ANDROID_DIR/sideload-key.properties" <<EOF
storePassword=$SIDELOAD_KEYSTORE_STORE_PASSWORD
keyPassword=$KEY_PASSWORD
keyAlias=$SIDELOAD_KEYSTORE_KEY_ALIAS
storeFile=$SIDELOAD_KEYSTORE_PATH
EOF
chmod 600 "$ANDROID_DIR/sideload-key.properties"
chown "$KEYSTORE_OWNER":"$KEYSTORE_OWNER" "$ANDROID_DIR/sideload-key.properties" 2>/dev/null || true
echo "Wrote $ANDROID_DIR/sideload-key.properties (mode 600, owner $KEYSTORE_OWNER)."

echo "Keystore SHA-256:"
keytool -list -v \
  -keystore "$SIDELOAD_KEYSTORE_PATH" \
  -alias "$SIDELOAD_KEYSTORE_KEY_ALIAS" \
  -storepass:env SIDELOAD_KEYSTORE_STORE_PASSWORD 2>/dev/null \
  | grep -i "SHA256:" | sed 's/^[[:space:]]*/  /'

cat <<EOF

Build the sideload APKs with this key by opting in explicitly:
  scripts/build_sideload.sh
which passes -PsideloadSigning=true. Without that flag the release build keeps
using the upload key (or the debug key if no upload keystore is present), so the
Play upload path is unchanged.
EOF
