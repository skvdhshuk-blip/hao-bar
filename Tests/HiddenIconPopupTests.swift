import AppKit
import CoreGraphics
import Testing
@testable import SaneBar

struct HiddenIconPopupTests {
    @Test("Popup lists Hidden only")
    func popupListsHiddenOnly() {
        let visible = RunningApp(id: "visible.app", name: "Visible", icon: nil)
        let hidden = RunningApp(id: "hidden.app", name: "Hidden", icon: nil)
        let alwaysHidden = RunningApp(id: "always.app", name: "Always", icon: nil)
        let classified = SearchClassifiedApps(
            visible: [visible],
            hidden: [hidden],
            alwaysHidden: [alwaysHidden]
        )

        let apps = HiddenIconPopupPolicy.apps(from: classified)
        #expect(apps.map(\.uniqueId) == [hidden.uniqueId])
    }

    @Test("Popup drops unmovable system extras from Hidden")
    func popupDropsUnmovableSystemExtras() {
        let clock = RunningApp.menuExtraItem(
            ownerBundleId: "com.apple.systemuiserver",
            name: "Clock",
            identifier: "com.apple.menuextra.clock"
        )
        let hidden = RunningApp(id: "hidden.app", name: "Hidden", icon: nil)
        let classified = SearchClassifiedApps(
            visible: [],
            hidden: [clock, hidden],
            alwaysHidden: []
        )

        let apps = HiddenIconPopupPolicy.apps(from: classified)
        #expect(apps.map(\.uniqueId) == [hidden.uniqueId])
    }

    @Test("Popup also lists Visible icons stuck left of the notch")
    func popupListsNotchUnsafeVisible() {
        let hidden = RunningApp(id: "hidden.app", name: "Hidden", icon: nil)
        let stuck = RunningApp(id: "stuck.app", name: "Stuck", icon: nil, xPosition: 700, width: 24)
        let safe = RunningApp(id: "safe.app", name: "Safe", icon: nil, xPosition: 1100, width: 24)
        let classified = SearchClassifiedApps(
            visible: [stuck, safe],
            hidden: [hidden],
            alwaysHidden: []
        )

        let apps = HiddenIconPopupPolicy.apps(from: classified, notchRightSafeMinX: 825)
        #expect(apps.map(\.uniqueId) == [hidden.uniqueId, stuck.uniqueId])
    }

    @Test("Default left-click shows the hidden icon bar")
    func defaultLeftClickShowsHiddenBar() {
        #expect(HaoBarLeftClickAction.defaultAction == .showHiddenIconBar)
        #expect(
            HaoBarLeftClickAction.resolved(
                stored: nil,
                legacyOpensBrowseIcons: false
            ) == .showHiddenIconBar
        )
    }

    @Test("Legacy browse-icons flag still opens Browse")
    func legacyBrowseFlagOpensBrowse() {
        #expect(
            HaoBarLeftClickAction.resolved(
                stored: nil,
                legacyOpensBrowseIcons: true
            ) == .openBrowseIcons
        )
    }

    @Test("Stored left-click action wins over the legacy flag")
    func storedActionWinsOverLegacyFlag() {
        #expect(
            HaoBarLeftClickAction.resolved(
                stored: .toggleHidden,
                legacyOpensBrowseIcons: true
            ) == .toggleHidden
        )
    }

    @Test("Image cache keeps a frame after prune of other IDs")
    func imageCacheSurvivesUnrelatedPrune() {
        let cache = MenuBarItemImageCache()
        let image = NSImage(size: NSSize(width: 16, height: 16))
        cache.store(image, for: "hidden.app")
        cache.prune(keeping: ["hidden.app", "other.app"])
        #expect(cache.image(for: "hidden.app") != nil)
        cache.prune(keeping: ["other.app"])
        #expect(cache.image(for: "hidden.app") == nil)
    }

    @Test("Crop math maps a Cocoa item frame into image pixels")
    func cropMapsCocoaFrameIntoImagePixels() {
        let captureRect = CGRect(x: 100, y: 900, width: 200, height: 24)
        let itemFrame = CGRect(x: 140, y: 902, width: 20, height: 20)
        let crop = MenuBarItemCaptureGeometry.pixelCropRect(
            itemFrame: itemFrame,
            captureRect: captureRect,
            imageSize: CGSize(width: 400, height: 48)
        )

        #expect(crop != nil)
        #expect(abs((crop?.minX ?? 0) - 80) < 0.5)
        #expect(abs((crop?.width ?? 0) - 40) < 0.5)
        #expect(abs((crop?.height ?? 0) - 40) < 0.5)
        #expect(abs((crop?.minY ?? 0) - 4) < 0.5)
    }

    @Test("Crop rejects frames that miss the capture band")
    func cropRejectsOffBandFrames() {
        let crop = MenuBarItemCaptureGeometry.pixelCropRect(
            itemFrame: CGRect(x: 10, y: 10, width: 16, height: 16),
            captureRect: CGRect(x: 100, y: 900, width: 200, height: 24),
            imageSize: CGSize(width: 400, height: 48)
        )
        #expect(crop == nil)
    }

    @Test("Left-click titles include the hidden bar")
    func leftClickTitlesIncludeHiddenBar() {
        #expect(HaoBarLeftClickAction.showHiddenIconBar.title == String(localized: "Show Hidden Bar"))
        #expect(HaoBarLeftClickAction.openBrowseIcons.title == String(localized: "Open Browse"))
        #expect(HaoBarLeftClickAction.toggleHidden.title == String(localized: "Toggle Hidden"))
    }
}
