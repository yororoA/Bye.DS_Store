#!/usr/bin/env bash

set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
CONFIGURATION="${CONFIGURATION:-release}"
APP_NAME="Bye.DS_Store"
APP_BUNDLE="$ROOT_DIR/dist/$APP_NAME.app"
CONTENTS_DIR="$APP_BUNDLE/Contents"
MACOS_DIR="$CONTENTS_DIR/MacOS"

SWIFT_BUILD_ARGS=(
    --package-path "$ROOT_DIR"
    --configuration "$CONFIGURATION"
)

if [[ "${CI:-false}" != "true" ]]; then
    SWIFT_BUILD_ARGS+=(--disable-index-store)
fi

swift build "${SWIFT_BUILD_ARGS[@]}"

BINARY_DIR="$(
    swift build "${SWIFT_BUILD_ARGS[@]}" --show-bin-path
)"

if [[ -d "$APP_BUNDLE" ]]; then
    rm -rf -- "$APP_BUNDLE"
fi

mkdir -p "$MACOS_DIR"
cp "$BINARY_DIR/DSStoreSweeper" "$MACOS_DIR/DSStoreSweeper"
cp "$ROOT_DIR/Support/Info.plist" "$CONTENTS_DIR/Info.plist"

codesign \
    --force \
    --sign - \
    "$APP_BUNDLE"

plutil -lint "$CONTENTS_DIR/Info.plist"
codesign --verify --deep --strict "$APP_BUNDLE"

printf 'Built %s\n' "$APP_BUNDLE"
