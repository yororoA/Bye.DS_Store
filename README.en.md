# Bye.DS_Store

Bye.DS_Store is a lightweight macOS menu bar utility that watches the folders currently open in Finder and periodically removes `.DS_Store` files from the relevant locations.

## Project Goals

- [x] Monitor active folders
- [x] Continue monitoring recently active folders for a grace period after they are closed
- [x] Clean `.DS_Store` files in active folders
- [ ] Scan the entire local machine for existing `.DS_Store` files and remove them

The last item is intentionally not implemented yet. Bye.DS_Store currently limits cleanup to folders observed through Finder instead of scanning the whole disk.

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

### Why Include the Parent Folder?

Practical testing on macOS showed that `.DS_Store` is often not created directly in the folder that was opened. It is commonly written to the original folder when a user enters one of its child folders. The default scope therefore covers both the active folder and its direct parent.

## Finder Scope and Limitations

The app uses Finder AppleScript to read the target of each Finder window. It does not monitor directories opened internally by other applications.

macOS exposes the active target of each Finder window, but does not reliably expose inactive tabs inside the same window through the Finder AppleScript interface. As a result, an inactive Finder tab may not be detected until it becomes active.

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

macOS may also request separate file access permissions when cleanup reaches protected locations such as Desktop, Documents, or Downloads. Permission errors are displayed in the app settings.

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
3. Package the app as a zip archive.
4. Generate a SHA-256 checksum file.
5. Create or update the GitHub Release for the pushed tag.

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
