# HaoBar Security

Report vulnerabilities via a private GitHub security advisory on [hao-bar](https://github.com/skvdhshuk-blip/hao-bar).

## Model

- Sandboxed Mac App Store build
- Accessibility is required for menu bar management
- Touch ID lock is a casual privacy feature, not a security boundary; the flag lives in local settings JSON
- No telemetry, no Sparkle, no third-party crash reporter

## Hardening

- Hardened Runtime
- App Sandbox
- Updates only via the Mac App Store
