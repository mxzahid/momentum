# Installing Momentum

Momentum is a native macOS app that helps you track your coding projects and maintain momentum.

## Download

Choose your preferred format:
- **[Download Momentum.dmg]** (Recommended)
- **[Download Momentum.zip]** (Alternative)

### Verify Download (Optional but Recommended)

To ensure your download is authentic and untampered:

**For DMG:**
```bash
shasum -a 256 ~/Downloads/Momentum.dmg
```
Compare with: `dc03a96a2a92e2344f7ef1ada380bc700b9ca3c25ac8da9f6d8ab1e5826b11db`

**For ZIP:**
```bash
shasum -a 256 ~/Downloads/Momentum.zip
```
Compare with: `8e9ff51c131af16fc29a43cc366f46fb782e83d0c916e8d43b8c803b3a40c093`

## Installation

### Method 1: DMG (Recommended)
1. Open the downloaded `Momentum.dmg` file
2. Drag `Momentum.app` to your Applications folder
3. Eject the DMG

### Method 2: ZIP
1. Double-click `Momentum.zip` to extract
2. Move `Momentum.app` to your Applications folder

## First Launch

Since this app is not notarized with Apple (to keep it free), macOS will show a security warning on first launch. This is normal and safe.

### Option A: Right-Click Method (Easiest)
1. Go to your Applications folder
2. **Right-click** (or Control-click) on `Momentum.app`
3. Click **Open** from the menu
4. Click **Open** again in the dialog that appears
5. The app will launch and this permission is remembered

### Option B: System Settings Method
1. Try to open Momentum normally (it will be blocked)
2. Go to **System Settings** → **Privacy & Security**
3. Scroll down to find the message about Momentum
4. Click **Open Anyway**
5. Click **Open** in the confirmation dialog

### Option C: Terminal Method (Advanced Users)
If you're comfortable with the terminal, you can remove the quarantine attribute:

```bash
xattr -dr com.apple.quarantine /Applications/Momentum.app
```

After running this command, Momentum will open normally without any warnings.

## System Requirements

- macOS 13.0 (Ventura) or later
- Approximately 2 MB of disk space

## Troubleshooting

### "Momentum is damaged and can't be opened"
This happens when the quarantine attribute is set. Use Option C above (Terminal Method) to fix it.

### App won't open after following the steps
Try these in order:
1. Make sure you're running macOS 13.0 or later
2. Restart your Mac and try again
3. Re-download the app (the download may have been corrupted)

### The app opens but crashes immediately
Check Console.app for error messages or open an issue on GitHub with details about your system.

## Uninstalling

To remove Momentum from your Mac:
1. Quit the app if it's running
2. Delete `Momentum.app` from your Applications folder
3. Delete app data (optional):
   ```bash
   rm -rf ~/Library/Application\ Support/Momentum
   rm -rf ~/Library/Caches/Momentum
   ```

## Support

If you encounter any issues:
- Check existing [GitHub Issues](https://github.com/yourusername/momentum/issues)
- Open a new issue with details about your problem
- Include your macOS version and any error messages

## Privacy & Security

Momentum:
- Does not collect any personal data
- Does not send data to external servers (except for optional AI features if configured)
- Runs entirely on your local machine
- Is open source - you can review the code yourself

---

**Note:** This app is distributed for free without an Apple Developer Program membership. If you find it useful and want to support fully notarized releases in the future, consider sponsoring the project or contributing code.

