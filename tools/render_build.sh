#!/usr/bin/env bash
# Build the course app + adventure for a Render static site.
#
# Render images have no Flutter, so the pinned SDK is fetched on first build and
# reused from the build cache afterwards. The live classroom multiplayer server's
# WebSocket URL is read from GAME_SERVER_WS_URL; when unset the build still
# succeeds and multiplayer falls back to the labelled local preview.
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
if [ -n "${GAME_SERVER_WS_URL:-}" ]; then
  defines+=("--dart-define=GAME_SERVER_WS_URL=$GAME_SERVER_WS_URL")
  echo "Game server configured: building the live classroom bundle."
else
  echo "No GAME_SERVER_WS_URL set."
  echo "Building the local-preview bundle; phones will not be able to join."
fi

flutter pub get
# CanvasKit is bundled so the page still renders where gstatic.com is blocked.
flutter build web --release \
  --base-href="$BASE_HREF" \
  --no-web-resources-cdn \
  ${defines[@]+"${defines[@]}"}
