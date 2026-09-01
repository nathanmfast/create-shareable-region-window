# Create Shareable Region Window

Create Shareable Region Window turns a selected rectangle of the desktop into a dedicated window that can be shared in Teams, Zoom, Meet, Discord, and other meeting applications. It provides a shareable output window; it does not create a virtual monitor.

## Downloads

Download the latest builds from [GitHub Releases](https://github.com/nathanmfast/create-shareable-region-window/releases/latest). Each version includes portable x64 and ARM64 Windows packages, an ad-hoc-signed universal macOS application, generated release notes, and SHA-256 checksums.

On Windows, extract the appropriate ZIP and run `CreateShareableRegionWindow.exe`; no installation is required.

### Install on macOS

The macOS download uses a free ad-hoc signature; it is not signed with an Apple Developer ID or notarized by Apple. Only override macOS security if you downloaded it from this repository's GitHub Releases page and trust the source.

1. Download and expand `CreateShareableRegionWindow-macOS.zip`.
2. Open the resulting **Create Shareable Region Window** folder.
3. Drag `CreateShareableRegionWindow.app` into **Applications**. **Do not open the app from Downloads.**
4. Open the copy in Applications. macOS will display a warning and block this first launch; **this is expected**.
5. Click **Done** on the warning. Do not choose **Move to Trash**. The app will not open yet—continue directly to the next step.
6. Open **System Settings → Privacy & Security**, scroll to **Security**, and click **Open Anyway** next to the message about the app.
7. Authenticate if requested and click **Open** in the confirmation dialog.
8. When the app opens, grant **Screen & System Audio Recording** permission. Quit and reopen the app if macOS requests it.

Always launch the app from Applications, including the first time. Launching the copy in Downloads before moving it can cause macOS to grant Screen Recording permission to the wrong copy.

The ZIP includes the same instructions in `INSTALL.txt`. Apple makes **Open Anyway** available for about one hour after the blocked launch; see [Apple's instructions for opening an app from an unknown developer](https://support.apple.com/guide/mac-help/open-a-mac-app-from-an-unknown-developer-mh40616/mac).

If Screen Recording still appears disabled after approval and a relaunch, quit the app and run `tccutil reset ScreenCapture com.nathanfast.CreateShareableRegionWindow` in Terminal. Reopen the app, click **Create**, and approve **Screen & System Audio Recording** again. The permission should persist for that exact build; installing a newer ad-hoc-signed build may require approval again.

The repository contains two native applications:

- [`windows/`](windows/) — .NET Windows Forms and the Windows Magnification API.
- [`macos/`](macos/) — SwiftUI and ScreenCaptureKit.

## Functional specification

This section is the source of truth for application behavior. Unless a difference is listed under **Platform-specific behavior**, the Windows and macOS versions are expected to satisfy the same requirements.

### Main workflow

1. The control window lets the user define a source rectangle with **Left**, **Top**, **Width**, and **Height** fields or with **Select area…**.
2. The area selector dims the desktop, draws the current selection and its dimensions, and accepts a drag in any direction. Releasing a selection at least 16 × 16 units accepts it. Enter accepts an existing valid selection; Escape cancels without changing the saved rectangle.
3. **Create** starts a live capture of that fixed source rectangle in a window whose title is exactly **Shareable Region Window**. Meeting software must therefore expose that name in its window picker.
4. At most one output window exists. Selecting **Create** again closes and replaces the previous output window using the current settings.
5. Closing the control application also closes the output window and any source-border overlay.

The source rectangle is fixed for the lifetime of an output window. Changing its coordinates, pointer setting, or exclusions takes effect the next time **Create** is selected. The always-on-top and source-border settings take effect immediately on an existing output window.

### Output window

The Shareable Region Window must:

- show a live image of only the selected desktop rectangle, targeting up to 60 frames per second;
- contain no title bar or other application chrome in the pixels offered for sharing;
- be movable by dragging its contents and resizable from its edges and corners;
- preserve the source aspect ratio at every output size, centering the image on black when the window has a different aspect ratio;
- have a minimum size of 320 × 180;
- initially open centered and sized in proportion to the source, using no more than 75% of the primary screen's available work area unless the minimum size requires more;
- close when Escape is pressed while it has keyboard focus; and
- stop updating and visibly report a capture failure rather than silently displaying stale content.

The **Keep Shareable Region Window on top** option raises the output above ordinary windows. It is off by default.

### Pointer, exclusions, and capture safety

**Include mouse pointer** determines whether the system pointer is rendered in the captured image and is on by default.

The user can exclude applications from the capture. Excluded applications remain visible on the local desktop, but their windows are omitted from the output, exposing capturable content underneath. Exclusions apply to every window owned by the selected process or application, not merely its frontmost window.

The application's own selection UI, control window, output window, and optional source border must not appear in the captured image. This prevents recursive capture and ensures that local controls do not leak into a shared window.

### Source border

**Show a red border around the shared region** displays a four-unit red outline just outside the source rectangle and is off by default. The border is a local, non-interactive, always-visible overlay: it must not take focus, intercept pointer input, appear in the taskbar or Dock, or appear in the Shareable Region Window.

### Settings and defaults

The following values persist between launches:

- source rectangle;
- whether the pointer is included;
- whether the output stays on top;
- excluded processes or applications; and
- whether the red source border is shown.

Missing or unreadable settings must not prevent startup. The default source starts at the top-left of the primary display and is 1920 × 1080 or the largest rectangle, up to those dimensions, that fits the display. The other defaults are pointer included, output not kept on top, no exclusions, and no source border.

### Platform-specific behavior

| Concern | Windows | macOS |
| --- | --- | --- |
| Supported system | Windows 10 or 11 | macOS 13 or later |
| Rectangle units | Desktop pixels | Screen points; capture output uses the display's backing scale |
| Display geometry | A rectangle may use virtual-desktop coordinates, including negative coordinates, and may span displays | A rectangle must fit entirely on one physical display; select it again after that display is rearranged or disconnected |
| Exclusion identity | Case-insensitive executable name; `.exe` is optional and entries may be separated by commas, semicolons, or new lines | Bundle identifier selected from the current list of regular running applications |
| Exclusion refresh | Newly opened windows from an excluded process are discovered while capture runs | The excluded application set is resolved when capture starts |
| Capture permission | No administrator access or capture permission is required | Screen Recording permission is required |
| Settings location | `settings.json` beside the executable | The application's macOS user defaults container |

Platform-specific implementation, build, and packaging details belong in [`windows/README.md`](windows/README.md) and [`macos/README.md`](macos/README.md). A platform limitation should be documented in the table above rather than changing the shared behavior implicitly.

## Non-goals

The application does not create a display device, alter desktop layout, record audio or video, send a stream over the network, or integrate directly with a particular meeting service. A true additional monitor on Windows would require an administrator-installed, signed Indirect Display Driver; that is intentionally outside this project's scope.

## Build

To create the shareable, no-install Windows package, run:

```powershell
.\scripts\build-portable.ps1
```

The portable ZIP is written to `artifacts/`.

## Publish a release

Push a semantic-version tag to GitHub to build and publish a new version automatically:

```powershell
git tag v1.0.0
git push github v1.0.0
```

The release is published only after both Windows packages and the macOS package build successfully.
