#!/bin/bash
# Generate the Play upload keystore and the Flutter release signing config.
# Reads passwords from the gitignored .env.production; never echoes them and
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

: "${ANDROID_KEYSTORE_PATH:?ANDROID_KEYSTORE_PATH not set in .env.production}"
: "${ANDROID_KEYSTORE_KEY_ALIAS:?ANDROID_KEYSTORE_KEY_ALIAS not set in .env.production}"
: "${ANDROID_KEYSTORE_STORE_PASSWORD:?ANDROID_KEYSTORE_STORE_PASSWORD is empty in .env.production}"
KEY_PASSWORD="${ANDROID_KEYSTORE_KEY_PASSWORD:-$ANDROID_KEYSTORE_STORE_PASSWORD}"

if [ "${#ANDROID_KEYSTORE_STORE_PASSWORD}" -lt 6 ]; then
  echo "ERROR: store password must be at least 6 characters." >&2
  exit 1
fi
if [ "$KEY_PASSWORD" != "$ANDROID_KEYSTORE_STORE_PASSWORD" ] && [ "${#KEY_PASSWORD}" -lt 6 ]; then
  echo "ERROR: key password must be at least 6 characters." >&2
  exit 1
fi

export ANDROID_KEYSTORE_STORE_PASSWORD ANDROID_KEYSTORE_KEY_PASSWORD="$KEY_PASSWORD"

mkdir -p "$(dirname "$ANDROID_KEYSTORE_PATH")"
chmod 700 "$(dirname "$ANDROID_KEYSTORE_PATH")"

if [ -f "$ANDROID_KEYSTORE_PATH" ]; then
  echo "Keystore already exists at $ANDROID_KEYSTORE_PATH — refusing to overwrite."
else
  echo "Generating upload keystore (alias $ANDROID_KEYSTORE_KEY_ALIAS)..."
  keytool -genkeypair -v \
    -keystore "$ANDROID_KEYSTORE_PATH" \
    -storetype PKCS12 \
    -keyalg RSA -keysize 2048 -validity 10000 \
    -alias "$ANDROID_KEYSTORE_KEY_ALIAS" \
    -storepass:env ANDROID_KEYSTORE_STORE_PASSWORD \
    -keypass:env ANDROID_KEYSTORE_KEY_PASSWORD \
    -dname "CN=SecretMsg, O=SecretMsg, L=Remote, ST=NA, C=US"
  echo "Keystore created."
fi

chmod 600 "$ANDROID_KEYSTORE_PATH"
chown "$KEYSTORE_OWNER":"$KEYSTORE_OWNER" "$ANDROID_KEYSTORE_PATH" 2>/dev/null || true

echo "Verifying keystore integrity..."
keytool -list -v \
  -keystore "$ANDROID_KEYSTORE_PATH" \
  -alias "$ANDROID_KEYSTORE_KEY_ALIAS" \
  -storepass:env ANDROID_KEYSTORE_STORE_PASSWORD >/dev/null
echo "Keystore opens and contains alias $ANDROID_KEYSTORE_KEY_ALIAS."

umask 077
cat > "$ANDROID_DIR/key.properties" <<EOF
storePassword=$ANDROID_KEYSTORE_STORE_PASSWORD
keyPassword=$KEY_PASSWORD
keyAlias=$ANDROID_KEYSTORE_KEY_ALIAS
storeFile=$ANDROID_KEYSTORE_PATH
EOF
chmod 600 "$ANDROID_DIR/key.properties"
chown "$KEYSTORE_OWNER":"$KEYSTORE_OWNER" "$ANDROID_DIR/key.properties" 2>/dev/null || true
echo "Wrote $ANDROID_DIR/key.properties (mode 600, owner $KEYSTORE_OWNER)."

echo "Keystore SHA-256:"
keytool -list -v \
  -keystore "$ANDROID_KEYSTORE_PATH" \
  -alias "$ANDROID_KEYSTORE_KEY_ALIAS" \
  -storepass:env ANDROID_KEYSTORE_STORE_PASSWORD 2>/dev/null \
  | grep -i "SHA256:" | sed 's/^[[:space:]]*/  /'
