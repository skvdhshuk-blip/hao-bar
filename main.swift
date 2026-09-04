import AppKit
import Foundation
import ServiceManagement

// Entry point for HaoBar
// Using manual main.swift instead of @main to control initialization timing

let app = NSApplication.shared

// Handle command line arguments
let args = CommandLine.arguments
if args.contains("--unregister") {
    print("[\(AppIdentity.displayName)] Unregistering from background services...")
    do {
        try SMAppService.mainApp.unregister()
        print("[\(AppIdentity.displayName)] Successfully unregistered.")
    } catch {
        print("[\(AppIdentity.displayName)] Failed to unregister: \(error)")
    }
    exit(0)
}

// CRITICAL: Set activation policy to .accessory BEFORE app.run()
// This ensures NSStatusItem windows are created at window layer 25 (status bar layer)
// instead of layer 0 (regular window layer). Setting this in applicationDidFinishLaunching
// is TOO LATE - the window layer is determined when the run loop starts.
app.setActivationPolicy(.accessory)
app.appearance = NSAppearance(named: .darkAqua)

// SAFETY: Debug must not steal the App Store container.
let bundleId = Bundle.main.bundleIdentifier ?? "(unknown)"
#if APP_STORE
    if bundleId != AppIdentity.productionBundleId {
        fatalError("App Store build must use \(AppIdentity.productionBundleId). Found: \(bundleId)")
    }
#elseif DEBUG
    if AppIdentity.isProductionBundle(bundleId) {
        let env = ProcessInfo.processInfo.environment
        if env["HAOBAR_ALLOW_PROD_BUNDLE"] != "1", env["SANEBAR_ALLOW_PROD_BUNDLE"] != "1" {
            fatalError("Debug build is using production bundle ID (\(AppIdentity.productionBundleId)). Use Debug-AppStore or set HAOBAR_ALLOW_PROD_BUNDLE=1.")
        }
    }
#else
    if bundleId != AppIdentity.productionBundleId {
        fatalError("Release build must use \(AppIdentity.productionBundleId). Found: \(bundleId)")
    }
#endif

SaneBarAppDelegate.installNoKeychainAutomationSignalGuardIfNeeded()

let delegate = SaneBarAppDelegate()
app.delegate = delegate
app.run()
