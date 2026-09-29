#!/usr/bin/env bash

set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
CONFIGURATION="${CONFIGURATION:-release}"
APP_NAME="Bye.DS_Store"
APP_BUNDLE="$ROOT_DIR/dist/$APP_NAME.app"
CONTENTS_DIR="$APP_BUNDLE/Contents"
MACOS_DIR="$CONTENTS_DIR/MacOS"
RESOURCES_DIR="$CONTENTS_DIR/Resources"

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

mkdir -p "$MACOS_DIR" "$RESOURCES_DIR"
cp "$BINARY_DIR/DSStoreSweeper" "$MACOS_DIR/DSStoreSweeper"
cp "$ROOT_DIR/Support/Info.plist" "$CONTENTS_DIR/Info.plist"
cp "$ROOT_DIR/Support/AppIcon.icns" "$RESOURCES_DIR/AppIcon.icns"

if [[ -n "${VERSION:-}" ]]; then
    APP_VERSION="${VERSION#v}"
else
    APP_VERSION="$(
        git -C "$ROOT_DIR" describe --tags --match "v[0-9]*" --abbrev=0 2>/dev/null \
            | sed 's/^v//' \
            || true
    )"
fi

if [[ -n "$APP_VERSION" ]]; then
    plutil -replace CFBundleShortVersionString \
        -string "$APP_VERSION" \
        "$CONTENTS_DIR/Info.plist"
    plutil -replace CFBundleVersion \
        -string "$APP_VERSION" \
        "$CONTENTS_DIR/Info.plist"
fi

if [[ -n "${CODESIGN_IDENTITY:-}" ]]; then
    codesign \
        --force \
        --options runtime \
        --sign "$CODESIGN_IDENTITY" \
        "$APP_BUNDLE"
else
    codesign \
        --force \
        --sign - \
        "$APP_BUNDLE"
fi

plutil -lint "$CONTENTS_DIR/Info.plist"
codesign --verify --deep --strict "$APP_BUNDLE"

printf 'Built %s\n' "$APP_BUNDLE"
