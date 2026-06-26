#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
KEYSTORE="$ROOT_DIR/app/upload-keystore.jks"
KEY_PROPERTIES="$ROOT_DIR/key.properties"

if [[ -f "$KEYSTORE" ]]; then
  echo "Keystore already exists at: $KEYSTORE"
  exit 1
fi

KEYTOOL=""
for candidate in \
  "/Applications/Android Studio.app/Contents/jbr/Contents/Home/bin/keytool" \
  "$(command -v keytool || true)"; do
  if [[ -n "$candidate" && -x "$candidate" ]]; then
    KEYTOOL="$candidate"
    break
  fi
done

if [[ -z "$KEYTOOL" ]]; then
  echo "keytool not found. Install Android Studio or a JDK, then rerun this script."
  exit 1
fi

read -rsp "Enter keystore password: " STORE_PASS
echo
read -rsp "Confirm keystore password: " STORE_PASS_CONFIRM
echo

if [[ "$STORE_PASS" != "$STORE_PASS_CONFIRM" ]]; then
  echo "Passwords do not match."
  exit 1
fi

"$KEYTOOL" -genkey -v \
  -keystore "$KEYSTORE" \
  -keyalg RSA -keysize 2048 -validity 10000 \
  -alias upload \
  -storepass "$STORE_PASS" \
  -keypass "$STORE_PASS" \
  -dname "CN=Capital Locums, OU=Mobile, O=Capital Locums, L=London, ST=England, C=GB"

cat > "$KEY_PROPERTIES" <<EOF
storePassword=$STORE_PASS
keyPassword=$STORE_PASS
keyAlias=upload
storeFile=upload-keystore.jks
EOF

chmod 600 "$KEY_PROPERTIES"
echo "Created keystore: $KEYSTORE"
echo "Created signing config: $KEY_PROPERTIES"
echo "Build release AAB with: flutter build appbundle --release"
