# Create Shareable Region Window for macOS

The macOS application captures an adjustable area of one display and presents it in a dedicated **Shareable Region Window** for Teams, Zoom, Meet, Discord, and other meeting apps.

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

## Use it

1. Click **Select area…** and drag within one display. Press Escape to cancel.
2. Optionally select running applications under **Hide applications**.
3. Choose whether to include the pointer, keep the output on top, or show the red source border.
4. Click **Create** and grant Screen Recording permission if macOS requests it.
5. Share the window named **Shareable Region Window** in the meeting application.

The output window excludes this application from its source capture, preventing recursive capture and keeping the optional red border out of the shared image. Application exclusions are stored by bundle identifier.

The initial implementation requires a selected region to fit entirely on one physical display. Select the area again after rearranging or disconnecting displays.
