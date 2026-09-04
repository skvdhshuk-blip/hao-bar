import AppKit
import CoreGraphics
import Foundation
import os.log
#if canImport(ScreenCaptureKit)
    import ScreenCaptureKit
#endif

private let logger = Logger(subsystem: AppIdentity.logSubsystem, category: "MenuBarItemCapturePermission")

enum MenuBarItemCapturePermission {
    static var isGranted: Bool {
        CGPreflightScreenCaptureAccess()
    }

    /// Screen Recording only appears in System Settings after this process
    /// actually asks TCC. Enumerating shareable content is a preflight on
    /// macOS 26 and can return `TCC Disallow` without creating a Settings row.
    /// A real screenshot capture is what registers the app.
    @MainActor
    static func registerWithTCC() async {
        let preflight = CGPreflightScreenCaptureAccess()
        let requested = CGRequestScreenCaptureAccess()
        logger.info("Screen recording preflight=\(preflight, privacy: .public) request=\(requested, privacy: .public)")
        #if canImport(ScreenCaptureKit)
            do {
                let content = try await SCShareableContent.excludingDesktopWindows(false, onScreenWindowsOnly: true)
                guard let display = content.displays.first else {
                    logger.error("Screen recording registration found no displays")
                    return
                }

                let filter = SCContentFilter(display: display, excludingWindows: [])
                let config = SCStreamConfiguration()
                config.width = 2
                config.height = 2
                config.sourceRect = CGRect(x: 0, y: 0, width: 2, height: 2)
                config.showsCursor = false

                _ = try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<CGImage, Error>) in
                    SCScreenshotManager.captureImage(contentFilter: filter, configuration: config) { image, error in
                        if let error {
                            continuation.resume(throwing: error)
                        } else if let image {
                            continuation.resume(returning: image)
                        } else {
                            continuation.resume(throwing: CancellationError())
                        }
                    }
                }
                logger.info("Screen recording registration captured a probe frame")
            } catch {
                logger.error("Screen recording registration failed: \(error.localizedDescription, privacy: .public)")
            }
        #endif
    }

    @MainActor
    static func requestAndOpenSettings() async {
        await registerWithTCC()
        openSystemSettings()
    }

    static func openSystemSettings() {
        let urls = [
            "x-apple.systempreferences:com.apple.settings.PrivacySecurity.extension?Privacy_ScreenCapture",
            "x-apple.systempreferences:com.apple.preference.security?Privacy_ScreenCapture"
        ]
        for raw in urls {
            if let url = URL(string: raw), NSWorkspace.shared.open(url) {
                return
            }
        }
    }
}
