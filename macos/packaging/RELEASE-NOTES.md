# Download and use

Create Shareable Region Window turns a selected part of your desktop into a dedicated window that you can share in Teams, Zoom, Meet, Discord, and other meeting applications. Download the ZIP for your operating system and processor from the assets below, and use `SHA256SUMS.txt` if you want to verify the download.

Only run a build downloaded from a source you trust. The downloadable apps are not code-signed with a commercial certificate, so your operating system may display a security warning.

## Windows

The Windows build is a portable app: it does not need to be installed, does not require administrator access, and includes the .NET runtime.

1. Download the `win-x64` ZIP for most Intel or AMD Windows computers, or the `win-arm64` ZIP for a Windows on Arm computer.
2. Extract the entire ZIP to any folder.
3. Run `CreateShareableRegionWindow.exe`. If Windows SmartScreen appears, confirm that you trust the download before continuing.
4. Click **Select area…** and drag around the part of the desktop you want to share.
5. Adjust any optional settings, then click **Create**.
6. In your meeting app, share the window named **Shareable Region Window**.

Keep the extracted files together. The app saves `settings.json` beside the executable, so moving or deleting that folder also moves or deletes its settings.

<!-- macos-installation -->
## macOS

macOS requires a special first-launch procedure because this free build uses an ad-hoc signature and is not notarized by Apple. **Move the app to Applications before opening it.** Only override macOS security if you trust the download source.

1. Download and expand `CreateShareableRegionWindow-macOS.zip`.
2. Open the resulting folder and drag `CreateShareableRegionWindow.app` to **Applications**. **Do not open the app from Downloads.**
3. Open the copy in Applications. macOS will display a warning and block this first launch; **this is expected**.
4. Click **Done** on the warning. Do not choose **Move to Trash**. The app will not open yet—continue to the next step.
5. Open **System Settings → Privacy & Security**, scroll to **Security**, and click **Open Anyway**.
6. Authenticate if requested and click **Open** in the confirmation dialog.
7. When the app opens, grant **Screen & System Audio Recording** permission.

Always launch the app from Applications, including the first time. Launching the copy in Downloads before moving it can cause macOS to grant Screen Recording permission to the wrong copy.

The ZIP also contains `INSTALL.txt` with complete installation, troubleshooting, update, and removal instructions. Screen Recording permission should persist when this exact build quits and reopens, but installing a newer ad-hoc-signed build may require approval again.
