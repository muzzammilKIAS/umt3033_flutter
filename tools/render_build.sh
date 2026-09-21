#!/usr/bin/env bash
# Build the course app + adventure for a Render static site.
#
# Render images have no Flutter, so the pinned SDK is fetched on first build and
# reused from the build cache afterwards. Firebase web configuration is read from
# the service's environment variables; when none are set the build still succeeds
# and multiplayer falls back to the labelled local preview.
set -euo pipefail

FLUTTER_VERSION="${FLUTTER_VERSION:-3.44.8}"
FLUTTER_DIR="${FLUTTER_DIR:-${XDG_CACHE_HOME:-$HOME/.cache}/flutter-$FLUTTER_VERSION}"
BASE_HREF="${BASE_HREF:-/}"

if [ ! -x "$FLUTTER_DIR/bin/flutter" ]; then
  echo "Fetching Flutter $FLUTTER_VERSION into $FLUTTER_DIR"
  rm -rf "$FLUTTER_DIR"
  git clone --depth 1 --branch "$FLUTTER_VERSION" \
    https://github.com/flutter/flutter.git "$FLUTTER_DIR"
fi
git config --global --add safe.directory "$FLUTTER_DIR" || true
export PATH="$FLUTTER_DIR/bin:$PATH"
flutter --version

defines=()
missing=()
for key in FIREBASE_API_KEY FIREBASE_APP_ID FIREBASE_MESSAGING_SENDER_ID \
  FIREBASE_PROJECT_ID FIREBASE_AUTH_DOMAIN FIREBASE_DATABASE_URL; do
  value="${!key:-}"
  if [ -n "$value" ]; then
    defines+=("--dart-define=$key=$value")
  else
    missing+=("$key")
  fi
done

if [ ${#missing[@]} -eq 0 ]; then
  echo "Firebase configured: building the live classroom bundle."
else
  echo "No Firebase configuration (missing: ${missing[*]})."
  echo "Building the local-preview bundle; phones will not be able to join."
fi

flutter pub get
# CanvasKit is bundled so the page still renders where gstatic.com is blocked.
flutter build web --release \
  --base-href="$BASE_HREF" \
  --no-web-resources-cdn \
  ${defines[@]+"${defines[@]}"}
