<!-- macos-installation -->
## macOS installation

1. Download and expand `CreateShareableRegionWindow-macOS.zip`.
2. Open the resulting folder and drag `CreateShareableRegionWindow.app` to **Applications**. **Do not open the app from Downloads.**
3. Open the copy in Applications. macOS will display a warning and block this first launch because the free ad-hoc signature is not an Apple Developer ID; **this is expected**.
4. Click **Done** on the warning. Do not choose **Move to Trash**. The app will not open yet—continue to the next step.
5. Open **System Settings → Privacy & Security**, scroll to **Security**, and click **Open Anyway**.
6. Authenticate if requested and click **Open** in the confirmation dialog.
7. When the app opens, grant **Screen & System Audio Recording** permission.

Always launch the app from Applications, including the first time. Launching the copy in Downloads before moving it can cause macOS to grant Screen Recording permission to the wrong copy.

The ZIP also contains `INSTALL.txt` with complete installation, troubleshooting, update, and removal instructions. Only override macOS security when you trust the download source. Screen Recording permission should persist when this exact build quits and reopens, but installing a newer ad-hoc-signed build may require approval again.
