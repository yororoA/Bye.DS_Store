# Bye.DS_Store

## Automatically keep your Mac folders free of `.DS_Store`

Bye.DS_Store is a free, open-source native macOS menu bar utility. Keep using Finder; it quietly removes unnecessary `.DS_Store` files in the background.

[简体中文](README.md) · [繁體中文](README.zh-Hant.md) · [English](README.en.md) · [日本語](README.ja.md) · [Deutsch](README.de.md) · [Русский](README.ru.md)

[Download the latest Apple Silicon DMG](https://github.com/yororoA/Bye.DS_Store/releases/latest) · [Open the product page](https://bye-dsstore.yororoice.top/) · [View source](https://github.com/yororoA/Bye.DS_Store)

![macOS 14+](https://img.shields.io/badge/macOS-14%2B-0d171c?logo=apple&logoColor=white)
![Swift 6](https://img.shields.io/badge/Swift-6-00a994?logo=swift&logoColor=white)
![GitHub release](https://img.shields.io/github/v/release/yororoA/Bye.DS_Store?display_name=tag&color=f0aa3c)
![MIT License](https://img.shields.io/badge/license-MIT-00a994.svg)

**Built for:**

- Git, Xcode, VS Code, Unity, web projects, NAS folders, and external SSDs where `.DS_Store` keeps returning;
- people who want automatic cleanup without a Dock app or a risky `find / -delete` script;
- developers who want a native Swift utility with visible scan boundaries, failure paths, and permission behavior.

## At a glance

| Question | Bye.DS_Store |
| --- | --- |
| Will it interrupt my workflow? | It stays in the menu bar and follows Finder quietly |
| Can it delete the wrong things? | Background cleanup is Finder-scoped; full-disk scans require confirmation |
| Can I control the scope? | Choose parent folders, disk locations, exclusions, and symbolic-link behavior |
| Can I verify what happened? | Review scanned, removed, and failed counts plus paths |

## Core capabilities

| Capability | What it does |
| --- | --- |
| Finder monitoring | Reads current Finder window targets and deduplicates multiple windows |
| Grace-period cleanup | Keeps a closed folder in the cleanup set for 60 seconds by default |
| Cleanup scope | Covers the monitored folder and its direct parent by default, with an option for the current folder only |
| Full-disk scan | Manually scans the startup disk, external disks, network disks, or all mounted volumes |
| Exclusion rules | Skips folders by name or path, such as `node_modules` or `lib/packages` |
| Safety boundaries | Confirms before scanning, allows cancellation, and exposes failed paths afterward |
| Menu bar workflow | Uses no Dock icon and supports the global shortcut `⌘⌥B` |
| Languages | System detection plus 简体中文, 繁體中文, English, 日本語, Deutsch, and Русский |

## Why include the parent folder?

Testing on macOS showed that `.DS_Store` is often written to the original folder when you enter a child folder, rather than directly to the root of the folder you opened. The default cleanup scope therefore includes:

1. The folder currently monitored through Finder
2. Its direct parent folder

The app does not walk farther upward and does not automatically traverse child folders.

## Full-disk scanning and safety

Full-disk scanning is an explicit, user-triggered operation. It is separate from background polling and:

- skips symbolic links to avoid entering another directory tree twice;
- skips configured exclusions and all of their descendants;
- reports scanned items, discovered files, removed files, and failures;
- records protected or inaccessible locations without stopping the entire scan.

Some system directories may require **Full Disk Access** in macOS Privacy & Security settings.

## Exclusion rules

Enter a folder name or a parent/target path in Settings and press Return:

```text
node_modules
lib/packages
```

Each rule becomes a removable tag. The initial set covers common dependency and build directories:

```text
node_modules, .venv, venv, __pycache__, vendor, Pods, target, .gradle
```

## Requirements

- macOS 14 or later
- Xcode 16 or later
- Swift 6 toolchain

## Run locally

```bash
./scripts/run-app.sh
```

Build only:

```bash
./scripts/build-app.sh
```

Run tests:

```bash
swift test --disable-index-store
```

The built app is written to `dist/Bye.DS_Store.app`.

## First-run permissions

On first launch, macOS asks whether Bye.DS_Store may control Finder. This permission is used only to read the current locations of Finder windows.

If access was denied previously:

```text
System Settings > Privacy & Security > Automation > Bye.DS_Store > Finder
```

Cleaning protected locations such as Desktop, Documents, or Downloads may also require separate file access approval.

## Releases and GitHub Actions

Push a version tag to trigger the release workflow:

```bash
git tag vX.Y.Z
git push origin vX.Y.Z
```

The workflow runs tests, builds the macOS app, creates zip/DMG installers and SHA-256 checksums, and uses Developer ID signing and notarization when Apple Developer secrets are configured.

Release descriptions are stored at:

```text
.github/release-notes/<tag>.md
```

The product page is published through GitHub Pages at [bye-dsstore.yororoice.top](https://bye-dsstore.yororoice.top/). The Pages workflow reads the latest Release during deployment and updates the version label and DMG URL automatically.

## License

This project is distributed under the [MIT License](LICENSE).

## Project structure

```text
Sources/SweeperCore/       Folder tracking, cleanup scope, and .DS_Store removal
Sources/DSStoreSweeper/    Finder integration, menu bar UI, settings, and lifecycle
Tests/SweeperCoreTests/    Core behavior tests
Support/Info.plist         macOS app bundle metadata
scripts/                   Build and launch scripts
site/                      GitHub Pages product page
.github/workflows/         Release and Pages automation
```
