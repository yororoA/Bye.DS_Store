#!/usr/bin/env bash

set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
CONFIGURATION="${CONFIGURATION:-release}"
ARCHITECTURES="${ARCHITECTURES:-$(uname -m)}"
MACOS_DEPLOYMENT_TARGET="${MACOS_DEPLOYMENT_TARGET:-$(
    plutil -extract LSMinimumSystemVersion raw "$ROOT_DIR/Support/Info.plist"
)}"
SDK_PATH="${SDKROOT:-$(xcrun --sdk macosx --show-sdk-path)}"
APP_NAME="Bye.DS_Store"
APP_BUNDLE="$ROOT_DIR/dist/$APP_NAME.app"
CONTENTS_DIR="$APP_BUNDLE/Contents"
MACOS_DIR="$CONTENTS_DIR/MacOS"
RESOURCES_DIR="$CONTENTS_DIR/Resources"

read -r -a REQUESTED_ARCHITECTURES <<< "$ARCHITECTURES"
BUILT_ARCHITECTURE_LIST=""
BUILT_BINARIES=()

for architecture in "${REQUESTED_ARCHITECTURES[@]}"; do
    case "$architecture" in
        arm64|x86_64)
            ;;
        *)
            printf 'Unsupported architecture: %s\n' "$architecture" >&2
            exit 1
            ;;
    esac

    if [[ " $BUILT_ARCHITECTURE_LIST " == *" $architecture "* ]]; then
        continue
    fi

    BUILT_ARCHITECTURE_LIST="${BUILT_ARCHITECTURE_LIST}${architecture} "

    SWIFT_BUILD_ARGS=(
        --package-path "$ROOT_DIR"
        --configuration "$CONFIGURATION"
        --triple "${architecture}-apple-macosx${MACOS_DEPLOYMENT_TARGET}"
        --sdk "$SDK_PATH"
    )

    if [[ "${CI:-false}" != "true" ]]; then
        SWIFT_BUILD_ARGS+=(--disable-index-store)
    fi

    swift build "${SWIFT_BUILD_ARGS[@]}"

    BINARY_DIR="$(
        swift build "${SWIFT_BUILD_ARGS[@]}" --show-bin-path
    )"
    BUILT_BINARIES+=("$BINARY_DIR/DSStoreSweeper")
done

if [[ "${#BUILT_BINARIES[@]}" -eq 0 ]]; then
    printf 'At least one architecture is required.\n' >&2
    exit 1
fi

if [[ -d "$APP_BUNDLE" ]]; then
    rm -rf -- "$APP_BUNDLE"
fi

mkdir -p "$MACOS_DIR" "$RESOURCES_DIR"
if [[ "${#BUILT_BINARIES[@]}" -eq 1 ]]; then
    cp "${BUILT_BINARIES[0]}" "$MACOS_DIR/DSStoreSweeper"
else
    lipo \
        -create \
        "${BUILT_BINARIES[@]}" \
        -output "$MACOS_DIR/DSStoreSweeper"
fi
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

printf 'Architectures: %s\n' "$(
    lipo -archs "$MACOS_DIR/DSStoreSweeper"
)"
printf 'Built %s\n' "$APP_BUNDLE"
