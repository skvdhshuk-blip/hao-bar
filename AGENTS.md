# HaoBar Agent Instructions

This repository is a public MIT fork of SaneBar, shipped as HaoBar on the Mac App Store.

## Source Of Truth

- Product behavior: `README.md`
- Development: `DEVELOPMENT.md`
- Architecture of the inherited kernel: `ARCHITECTURE.md`
- Privacy and security: `PRIVACY.md`, `SECURITY.md`
- Identity: `Core/AppIdentity.swift`
- Sandbox capability gates: `Core/AppCapability.swift`

## Workflow

- Prefer `Scripts/SaneMaster.rb` for build, test, and launch.
- Customer-facing name is HaoBar. Internal types may still say `SaneBar*`.
- Do not re-enable Sparkle, Setapp, telemetry, global menu-bar spacing, Focus file reads, Wi-Fi SSID, or script triggers without changing `AppCapability` and the App Store entitlements together.
- Settings and menu items go from the most common need to the most advanced.
- Settings text stays high contrast and at least 13pt.

## Public Repo Hygiene

- Do not track `.build-logs`, `DerivedData`, local IDE folders, `Guidance.md`, or release secrets.
- HaoBar is MIT. Keep the original SaneApps copyright with the HaoBar contributors line.
