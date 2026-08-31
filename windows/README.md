# Create Shareable Region Window for Windows

The Windows application turns an adjustable area of the desktop into a dedicated **Shareable Region Window** for Teams, Zoom, Meet, Discord, or another meeting app.

## Run it

Requires Windows 10/11 and the .NET 10 SDK.

From the repository root:

```powershell
dotnet run --project windows/CreateShareableRegionWindow.csproj
```

## Build a portable release

```powershell
.\scripts\build-portable.ps1
```

The script creates a versioned ZIP under `artifacts/`. Recipients only need to extract the ZIP and run `CreateShareableRegionWindow.exe`; the .NET runtime is included. No installation or administrator access is required.

The portable app stores `settings.json` beside its executable, so moving or removing the folder also moves or removes its settings. Windows SmartScreen may warn about downloaded builds that have not been code-signed.

To build another version or Windows architecture:

```powershell
.\scripts\build-portable.ps1 -Version 1.1.0 -Runtime win-arm64
```

## Use it

1. Click **Select area…** and drag around the part of the desktop to capture. Press Escape to cancel.
2. Optionally enter executable names such as `notepad.exe, teams.exe` under **Hide processes**.
3. Optionally enable **Show a red border around the shared region** to keep the capture boundary visible on your desktop. The border is not included in the shared window.
4. Click **Create**.
5. In the meeting app, share the window named **Shareable Region Window**.
6. Resize the Shareable Region Window freely; the captured image keeps its aspect ratio.

The Shareable Region Window is borderless so window sharing contains only the captured image. Drag anywhere inside it to move it, drag an edge or corner to resize it, and press Escape to close it.

The default capture is 1920×1080 at desktop coordinate 0,0. Coordinates may be negative when a monitor is positioned left of or above the primary monitor.

## About virtual monitors

This app creates a normal shareable window, not a Windows display device. A true additional monitor requires an administrator-installed, signed Indirect Display Driver and can change desktop layout. For the meeting-sharing use case, the Shareable Region Window provides the same shareable output without driver installation or administrator access.

Windows belonging to hidden processes remain visible on your desktop but are omitted from the Shareable Region Window, revealing the windows underneath them. The Shareable Region Window also excludes itself from its captured output.
