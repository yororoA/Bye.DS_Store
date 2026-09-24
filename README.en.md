# Bye.DS_Store

[中文](README.md)

Bye.DS_Store is a lightweight macOS menu bar utility that watches the folders currently open in Finder and periodically removes `.DS_Store` files from the relevant locations.

## Project Goals

- [x] Monitor active folders
- [x] Continue monitoring recently active folders for a grace period after they are closed
- [x] Clean `.DS_Store` files in active folders
- [x] Scan the entire local machine for existing `.DS_Store` files and remove them

The full-disk scan is an explicit, user-triggered operation. It is not part of the periodic active-folder polling loop.

## How It Works

- Finder is queried every 5 seconds by default.
- A folder remains in the cleanup set for 60 seconds after its Finder window is closed or changes location.
- The default cleanup scope includes the monitored folder and its direct parent folder.
- Settings also provide an option to clean only the monitored folder.
- Cleanup never walks upward beyond the direct parent and never recursively scans child folders.
- The same folder opened in multiple Finder windows is processed only once.
- Monitoring can be paused from the menu bar.
- The polling interval and grace period are configurable.
- The app can launch automatically at login.
- The app runs as a menu bar item and does not add a Dock icon.
- A manual full-disk scan can recursively find and remove existing `.DS_Store` files.
- Full-disk scans can be stopped while they are running.
- A confirmation prompt appears before a full-disk scan starts.
- Scan results include counts and a list of inaccessible or failed paths.
- Full-disk scans support folder exclusion rules such as `node_modules` and `lib/packages`.
- Global shortcut: press `⌘⌥B` to open the control panel when the status item is hidden.
- The status popover shows the last cleanup time, recent cleanup count, and shortcut.
- Exclusion rules can be restored to defaults or cleared completely.
- Full-disk scans can target the startup disk, external disks, network disks, or all mounted volumes.
- The UI follows the macOS system language and supports Chinese and English.

### Why Include the Parent Folder?

Practical testing on macOS showed that `.DS_Store` is often not created directly in the folder that was opened. It is commonly written to the original folder when a user enters one of its child folders. The default scope therefore covers both the active folder and its direct parent.

### Full-Disk Scan

The Settings panel and menu bar both provide a manual full-disk scan. It starts at `/`, includes hidden files and package contents, skips symbolic links, and reports the number of scanned items, files removed, and access or deletion failures.

Because macOS protects parts of the file system, a full-disk scan may require Full Disk Access. Inaccessible locations are reported instead of stopping the entire scan.

The scan shows a confirmation dialog before starting. After it finishes, use “View scan details” to inspect failed paths and error messages.

Scan locations can be selected in Settings:

- Startup disk only
- Startup and external disks
- Startup and network disks
- All mounted volumes

### Scan Exclusions

The Settings panel stores exclusion rules as removable tags. Enter a folder name such as `node_modules`, or a parent/target path such as `lib/packages`, then press Return. When the scanner reaches a matching folder, it skips that folder and all of its descendants.

The initial exclusions cover common dependency and generated package directories:

```text
node_modules, .venv, venv, __pycache__, vendor, Pods, target, .gradle
```

## Finder Scope and Limitations

The app uses Finder AppleScript to read the target of each Finder window. It does not monitor directories opened internally by other applications.

macOS exposes the active target of each Finder window, but does not reliably expose inactive tabs inside the same window through the Finder AppleScript interface. As a result, an inactive Finder tab may not be detected until it becomes active.

## Global Shortcut

Press `⌘⌥B` to open the Bye.DS_Store control panel. This works even when the app is not in the foreground, and normally shows the panel beside the status item.

The shortcut uses macOS's native global hot-key registration and does not require additional Accessibility permission.

## Requirements

- macOS 14 or later
- Xcode 16 or later
- Swift 6 toolchain

## Build and Run Locally

Build and launch the menu bar app:

```bash
./scripts/run-app.sh
```

Build only:

```bash
./scripts/build-app.sh
```

Run the test suite:

```bash
swift test --disable-index-store
```

The built app is written to:

```text
dist/Bye.DS_Store.app
```

## Permissions

On first launch, macOS asks whether Bye.DS_Store may control Finder. This permission is required to read the locations of Finder windows.

If access was previously denied, open:

```text
System Settings > Privacy & Security > Automation > Bye.DS_Store > Finder
```

macOS may also request separate file access permissions when cleanup reaches protected locations such as Desktop, Documents, or Downloads. A full-disk scan may require Full Disk Access. Permission errors are displayed in the app settings.

## GitHub Releases

The repository includes a GitHub Actions workflow at `.github/workflows/release.yml`.

Push a version tag to build and publish a release automatically:

```bash
git tag v1.0.0
git push origin v1.0.0
```

The workflow will:

1. Run the Swift test suite.
2. Build and verify `Bye.DS_Store.app` on macOS.
3. Package the app as both a zip archive and a DMG.
4. Generate SHA-256 checksum files for both installers.
5. Sign with Developer ID and notarize the DMG when Apple Developer secrets are configured.
6. Create or update the GitHub Release for the pushed tag.

To enable signing and notarization, configure these GitHub Actions secrets:

```text
APPLE_CERTIFICATE_BASE64
APPLE_CERTIFICATE_PASSWORD
APPLE_KEYCHAIN_PASSWORD
APPLE_DEVELOPER_IDENTITY
APPLE_ID
APPLE_TEAM_ID
APPLE_APP_PASSWORD
```

The generated app is ad hoc signed for local distribution. It is not notarized with an Apple Developer certificate, so macOS may require users to approve the first launch manually.

## Project Structure

```text
Sources/SweeperCore/       Folder tracking, cleanup scope resolution, and deletion logic
Sources/DSStoreSweeper/    Finder integration, menu bar UI, settings, and app lifecycle
Tests/SweeperCoreTests/    Core behavior tests
Support/Info.plist         macOS application bundle metadata
scripts/                   Local build and launch scripts
.github/workflows/         Continuous release automation
```
