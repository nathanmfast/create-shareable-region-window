# Create Shareable Region Window

Create Shareable Region Window turns an adjustable area of the Windows desktop into a dedicated **Shareable Region Window** for Teams, Zoom, Meet, Discord, or another meeting app.

## Run it

Requires Windows 10/11 and the .NET 10 SDK.

```powershell
dotnet run
```

Or create a single-file build:

```powershell
dotnet publish -c Release -r win-x64 --self-contained true -p:PublishSingleFile=true
```

The executable will be under `bin\Release\net10.0-windows\win-x64\publish`.

## Use it

1. Click **Select area…** and drag around the part of the desktop to capture. Press Escape to cancel.
2. Optionally enter executable names such as `notepad.exe, teams.exe` under **Hide processes**.
3. Click **Create**.
4. In the meeting app, share the window named **Shareable Region Window**.
5. Resize the Shareable Region Window freely; the captured image keeps its aspect ratio.

The Shareable Region Window is borderless so window sharing contains only the captured image. Drag anywhere inside it to move it, drag an edge or corner to resize it, and press Escape to close it.

The default capture is 1920×1080 at desktop coordinate 0,0. Coordinates may be negative when a monitor is positioned left of or above the primary monitor.

## About “virtual monitors”

This app creates a normal shareable window, not a Windows display device. A true additional monitor requires an administrator-installed, signed Indirect Display Driver and can change desktop layout. For the meeting-sharing use case, the Shareable Region Window provides the same shareable output without driver installation or administrator access.

Windows belonging to hidden processes remain visible on your desktop but are omitted from the Shareable Region Window, revealing the windows underneath them. The Shareable Region Window also excludes itself from its captured output.
