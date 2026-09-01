# Create Shareable Region Window for macOS

The macOS application captures an adjustable area of one display and presents it in a dedicated **Shareable Region Window** for Teams, Zoom, Meet, Discord, and other meeting apps. The cross-platform behavior contract is defined in the repository's [root README](../README.md#functional-specification); this document covers macOS setup and platform notes.

## Requirements

- macOS 13 or later.
- Xcode 15 or later.
- Screen Recording permission in **System Settings → Privacy & Security → Screen Recording**.

## Build and run

Open `CreateShareableRegionWindow.xcodeproj` in Xcode, select the **CreateShareableRegionWindow** scheme, choose **My Mac**, and run the application.

From Terminal, an unsigned local build can also be created with:

```bash
xcodebuild -project macos/CreateShareableRegionWindow.xcodeproj \
  -scheme CreateShareableRegionWindow \
  -configuration Debug \
  CODE_SIGNING_ALLOWED=NO build
```

## GitHub Actions

The `Build macOS app` workflow builds an unsigned universal application on a standard GitHub-hosted macOS runner. It runs for macOS changes pushed to `master`, for pull requests that change the macOS application, and on demand from the repository's **Actions** page.

After a successful run, download the `CreateShareableRegionWindow-macOS` artifact from the workflow summary. The artifact is retained for 14 days. A manual run can also attach the ZIP to an existing GitHub Release by supplying its tag as `release_tag`.

Versioned repository releases include the same universal macOS ZIP automatically. The release tag supplies the app's user-facing version, so a `v1.2.3` release reports version `1.2.3` in Finder while GitHub Actions supplies a monotonically increasing bundle build number. Windows and macOS therefore share one cross-platform release version. Because the app is unsigned, macOS requires an explicit approval before opening it; signing and notarization are separate release steps.

## Use it

1. Click **Select area…** and drag within one display. Press Escape to cancel.
2. Optionally select running applications under **Hide applications**.
3. Choose whether to include the pointer, keep the output on top, or show the red source border.
4. Click **Create** and grant Screen Recording permission if macOS requests it.
5. Share the window named **Shareable Region Window** in the meeting application.

macOS uses screen points for the source rectangle and captures at the selected display's backing scale. A region must fit entirely on one physical display; select it again after rearranging or disconnecting displays. Application exclusions are stored by bundle identifier and are resolved when capture starts.

For the complete output-window, exclusion, persistence, and source-border requirements, see the [functional specification](../README.md#functional-specification).
