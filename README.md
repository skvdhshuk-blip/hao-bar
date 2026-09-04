# HaoBar

Hide the menu bar icons you do not need. Keep the important ones visible.

HaoBar is a Mac App Store fork of [SaneBar](https://github.com/sane-apps/SaneBar) (MIT). The original copyright and license remain in [LICENSE](LICENSE) and the in-app Acknowledgements.

**Requirements:** macOS 14.0+, Apple Silicon.

## What it does

- Click the HaoBar icon to show or hide tucked-away menu bar apps
- Browse hidden apps in the Icon Panel or a Second Menu Bar
- Search by name and open an app with a double-click
- Touch ID to reveal hidden icons
- Local profiles and keyboard shortcuts

The Mac App Store build is sandboxed. System-wide icon spacing, Focus Mode file reads, Wi-Fi SSID triggers, and user-script triggers are not included. If a panel cannot move an icon, ⌘-drag it in the menu bar.

## Privacy

HaoBar stores settings on this Mac. It does not upload menu bar contents, does not require an account, and does not phone home. See [PRIVACY.md](PRIVACY.md) or the [hosted privacy policy](https://skvdhshuk-blip.github.io/hao-bar/privacy.html).

## Build

```bash
./Scripts/SaneMaster.rb verify
./Scripts/SaneMaster.rb test_mode
```

`project.yml` is the XcodeGen source of truth. After adding Swift files:

```bash
xcodegen generate
```

Archive for the store with the `HaoBar` scheme, `Release-AppStore` configuration.

## License

MIT. Copyright (c) 2026 HaoBar contributors. Copyright (c) 2025-2026 SaneApps.
