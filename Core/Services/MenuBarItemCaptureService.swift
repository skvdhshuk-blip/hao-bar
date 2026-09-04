import AppKit
import CoreGraphics
import Foundation
import os.log
#if canImport(ScreenCaptureKit)
    import ScreenCaptureKit
#endif

private let logger = Logger(subsystem: AppIdentity.logSubsystem, category: "MenuBarItemCaptureService")

@MainActor
final class MenuBarItemCaptureService {
    static let shared = MenuBarItemCaptureService()

    let cache = MenuBarItemImageCache()
    private(set) var lastFailureReason: String?

    private init() {}

    func captureOnScreenHiddenItems(
        apps: [RunningApp],
        screen: NSScreen?
    ) async {
        guard AppCapability.menuBarItemCapture else { return }
        guard MenuBarItemCapturePermission.isGranted else {
            lastFailureReason = String(localized: "Screen Recording is required to show icon snapshots.")
            return
        }

        let hiddenApps = HiddenIconPopupPolicy.apps(
            from: SearchClassifiedApps(visible: [], hidden: apps, alwaysHidden: [])
        )
        guard !hiddenApps.isEmpty else {
            cache.prune(keeping: [])
            return
        }

        let targetScreen = screen ?? NSScreen.main
        guard let targetScreen else { return }
        let captureRect = MenuBarItemCaptureGeometry.menuBarCaptureRect(
            screenFrame: targetScreen.frame,
            visibleFrame: targetScreen.visibleFrame
        )

        guard let bandImage = await captureMenuBarBand(screen: targetScreen, captureRect: captureRect) else {
            return
        }

        let imageSize = CGSize(width: bandImage.width, height: bandImage.height)
        var kept = Set<String>()
        for app in hiddenApps {
            guard let itemFrame = MenuBarItemCaptureGeometry.itemFrame(
                xPosition: app.xPosition,
                width: app.width,
                captureRect: captureRect
            ) else { continue }
            guard let crop = MenuBarItemCaptureGeometry.pixelCropRect(
                itemFrame: itemFrame,
                captureRect: captureRect,
                imageSize: imageSize
            ) else { continue }
            let pixelCrop = CGRect(
                x: crop.minX.rounded(.down),
                y: crop.minY.rounded(.down),
                width: max(1, crop.width.rounded(.up)),
                height: max(1, crop.height.rounded(.up))
            )
            guard let cropped = bandImage.cropping(to: pixelCrop) else { continue }
            let snapshot = NSImage(cgImage: cropped, size: NSSize(width: crop.width / 2, height: crop.height / 2))
            cache.store(snapshot, for: app.uniqueId)
            kept.insert(app.uniqueId)
        }
        cache.prune(keeping: Set(hiddenApps.map(\.uniqueId)))
        lastFailureReason = nil
    }

    func image(for app: RunningApp) -> NSImage {
        cache.image(for: app.uniqueId) ?? app.icon ?? NSImage(size: NSSize(width: 18, height: 18))
    }

    private func captureMenuBarBand(screen: NSScreen, captureRect: CGRect) async -> CGImage? {
        #if canImport(ScreenCaptureKit)
            do {
                let content = try await SCShareableContent.excludingDesktopWindows(false, onScreenWindowsOnly: true)
                let screenID = UInt32(screen.deviceDescription[NSDeviceDescriptionKey("NSScreenNumber")] as? Int ?? 0)
                guard let display = content.displays.first(where: { $0.displayID == screenID })
                    ?? content.displays.first
                else {
                    lastFailureReason = String(localized: "HaoBar could not find a display to snapshot.")
                    return nil
                }

                let filter = SCContentFilter(display: display, excludingWindows: [])
                let config = SCStreamConfiguration()
                let scale = screen.backingScaleFactor
                config.width = max(1, Int(captureRect.width * scale))
                config.height = max(1, Int(captureRect.height * scale))
                config.sourceRect = captureRect
                config.showsCursor = false

                return try await withCheckedThrowingContinuation { continuation in
                    SCScreenshotManager.captureImage(contentFilter: filter, configuration: config) { image, error in
                        if let error {
                            continuation.resume(throwing: error)
                        } else {
                            continuation.resume(returning: image)
                        }
                    }
                }
            } catch {
                lastFailureReason = error.localizedDescription
                logger.error("Menu bar capture failed: \(error.localizedDescription, privacy: .public)")
                return nil
            }
        #else
            lastFailureReason = String(localized: "Screen capture is unavailable on this Mac.")
            return nil
        #endif
    }
}
