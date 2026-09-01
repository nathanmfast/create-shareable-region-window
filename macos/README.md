# Create Shareable Region Window for macOS

The macOS application captures an adjustable area of one display and presents it in a dedicated **Shareable Region Window** for Teams, Zoom, Meet, Discord, and other meeting apps. The cross-platform behavior contract is defined in the repository's [root README](../README.md#functional-specification); this document covers macOS setup and platform notes.

## Requirements

- macOS 13 or later.
- Xcode 15 or later.
- Screen Recording permission in **System Settings → Privacy & Security → Screen Recording**.

## Install a downloaded release

The downloadable application uses a free ad-hoc signature; it is not signed with an Apple Developer ID or notarized by Apple. Only override macOS security if you downloaded it from the project's GitHub Releases page and trust the source.

1. Download and expand `CreateShareableRegionWindow-macOS.zip`.
2. Open the resulting **Create Shareable Region Window** folder.
3. Drag `CreateShareableRegionWindow.app` into **Applications**. **Do not open the app from Downloads.**
4. Open the copy in Applications. macOS will display a warning and block this first launch; **this is expected**.
5. Click **Done** on the warning. Do not choose **Move to Trash**. The app will not open yet—continue directly to the next step.
6. Open **System Settings → Privacy & Security**, scroll to **Security**, and click **Open Anyway** next to the message about the app.
7. Authenticate if requested and click **Open** in the confirmation dialog.
8. When the app opens, grant **Screen & System Audio Recording** permission. Quit and reopen the app if macOS requests it.

Always launch the app from Applications, including the first time. Launching the copy in Downloads before moving it can cause macOS to grant Screen Recording permission to the wrong copy.

The ZIP includes these instructions in `INSTALL.txt`. Apple makes **Open Anyway** available for about one hour after the blocked launch; see [Apple's instructions for opening an app from an unknown developer](https://support.apple.com/guide/mac-help/open-a-mac-app-from-an-unknown-developer-mh40616/mac).

If Screen Recording still appears disabled after approval and a relaunch, quit the app and run `tccutil reset ScreenCapture com.nathanfast.CreateShareableRegionWindow` in Terminal. Reopen the app, click **Create**, and approve **Screen & System Audio Recording** again. The permission should persist for that exact build; installing a newer ad-hoc-signed build may require approval again.

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

The `Build macOS app` workflow builds an ad-hoc-signed universal application on a standard GitHub-hosted macOS runner. It runs for macOS changes pushed to `master`, for pull requests that change the macOS application, and on demand from the repository's **Actions** page.

After a successful run, download the `CreateShareableRegionWindow-macOS` artifact from the workflow summary. The artifact is retained for 14 days. A manual run can also attach the ZIP to an existing GitHub Release by supplying its tag as `release_tag`.

Versioned repository releases include the same universal macOS ZIP automatically. The release tag supplies the app's user-facing version, so a `v1.2.3` release reports version `1.2.3` in Finder while GitHub Actions supplies a monotonically increasing bundle build number. Windows and macOS therefore share one cross-platform release version. GitHub Actions applies a free ad-hoc signature so privacy approval can persist across relaunches of the same build. Because the app is not Developer ID signed or notarized, macOS still requires an explicit approval before opening it, and a new build may require Screen Recording approval again.

## Use it

1. Click **Select area…** and drag within one display. Press Escape to cancel.
2. Optionally select running applications under **Hide applications**.
3. Choose whether to include the pointer, keep the output on top, or show the red source border.
4. Click **Create** and grant Screen Recording permission if macOS requests it.
5. Share the window named **Shareable Region Window** in the meeting application.

macOS uses screen points for the source rectangle and captures at the selected display's backing scale. A region must fit entirely on one physical display; select it again after rearranging or disconnecting displays. Application exclusions are stored by bundle identifier and are resolved when capture starts.

For the complete output-window, exclusion, persistence, and source-border requirements, see the [functional specification](../README.md#functional-specification).
