@testable import SaneBar
import XCTest

final class RuntimeGuardHiddenIconPopupXCTests: RuntimeGuardTestCase {
    func testCustomerCopyDoesNotPromiseNoScreenRecording() throws {
        let welcome = try String(
            contentsOf: projectRootURL().appendingPathComponent("UI/Onboarding/WelcomePermissionPage.swift"),
            encoding: .utf8
        )
        let browseChrome = try String(
            contentsOf: projectRootURL().appendingPathComponent("UI/SearchWindow/BrowsePanelChromeViews.swift"),
            encoding: .utf8
        )
        XCTAssertFalse(welcome.contains("No screen recording."))
        XCTAssertFalse(welcome.contains("No screenshots."))
        XCTAssertFalse(browseChrome.contains("No screen recording."))
        XCTAssertFalse(browseChrome.contains("No screenshots."))
        XCTAssertTrue(welcome.contains("Screen Recording — menu bar only."))
        XCTAssertTrue(browseChrome.contains("Screen Recording — menu bar only."))
    }

    func testLeftClickDefaultOpensHiddenIconBar() throws {
        let actionSource = try String(
            contentsOf: projectRootURL().appendingPathComponent("Core/Services/MenuBarActionWorkflow.swift"),
            encoding: .utf8
        )
        XCTAssertTrue(actionSource.contains("case .showHiddenIconBar:"))
        XCTAssertTrue(actionSource.contains("HiddenIconPopupController.shared.toggle()"))
        XCTAssertTrue(AppCapability.menuBarItemCapture)
    }

    func testHideSnapshotsHiddenIconsBeforeCollapse() throws {
        let hideSource = try String(
            contentsOf: projectRootURL().appendingPathComponent("Core/Services/HidingService.swift"),
            encoding: .utf8
        )
        XCTAssertTrue(hideSource.contains("await beforeHide?()"))
        let managerSource = try String(
            contentsOf: projectRootURL().appendingPathComponent("Core/MenuBarManager.swift"),
            encoding: .utf8
        )
        XCTAssertTrue(managerSource.contains("captureOnScreenHiddenItems"))
    }

    func testUsageDescriptionDeclaresMenuBarOnlyCapture() throws {
        let info = try String(
            contentsOf: projectRootURL().appendingPathComponent("SaneBar/Info.plist"),
            encoding: .utf8
        )
        XCTAssertTrue(info.contains("NSScreenCaptureUsageDescription"))
        XCTAssertTrue(info.contains("does not record video"))
    }

    func testScreenRecordingRequestTouchesScreenCaptureKit() throws {
        let permission = try String(
            contentsOf: projectRootURL().appendingPathComponent("Core/Services/MenuBarItemCapturePermission.swift"),
            encoding: .utf8
        )
        XCTAssertTrue(permission.contains("SCShareableContent.excludingDesktopWindows"))
        XCTAssertTrue(permission.contains("SCScreenshotManager.captureImage"))
        XCTAssertTrue(permission.contains("func requestAndOpenSettings()"))
        XCTAssertTrue(permission.contains("func registerWithTCC()"))
    }

    func testHiddenBarRegistersScreenRecordingBeforePresenting() throws {
        let controller = try String(
            contentsOf: projectRootURL().appendingPathComponent("UI/SearchWindow/HiddenIconPopupController.swift"),
            encoding: .utf8
        )
        XCTAssertTrue(controller.contains("registerWithTCC()"))
        XCTAssertTrue(controller.contains("requestAndOpenSettings()"))
        XCTAssertFalse(controller.contains("MenuBarItemCapturePermission.request()"))
    }

    func testScreenRecordingButtonsRegisterThenOpenSettings() throws {
        let health = try String(
            contentsOf: projectRootURL().appendingPathComponent("UI/Settings/HealthSettingsView.swift"),
            encoding: .utf8
        )
        let welcome = try String(
            contentsOf: projectRootURL().appendingPathComponent("UI/Onboarding/WelcomePermissionPage.swift"),
            encoding: .utf8
        )
        XCTAssertTrue(health.contains("requestAndOpenSettings()"))
        XCTAssertTrue(welcome.contains("requestAndOpenSettings()"))
        XCTAssertFalse(health.contains("MenuBarItemCapturePermission.request()"))
        XCTAssertFalse(welcome.contains("MenuBarItemCapturePermission.request()"))
    }

    func testNotchOverflowUsesSeparatorPositionNotDrag() throws {
        let policy = try String(
            contentsOf: projectRootURL().appendingPathComponent("Core/Services/NotchVisibleOverflowPolicy.swift"),
            encoding: .utf8
        )
        let workflow = try String(
            contentsOf: projectRootURL().appendingPathComponent("Core/Services/NotchVisibleOverflowWorkflow.swift"),
            encoding: .utf8
        )
        let persistence = try String(
            contentsOf: projectRootURL().appendingPathComponent("Core/Services/PersistenceService.swift"),
            encoding: .utf8
        )
        XCTAssertTrue(policy.contains("func visibleOverflow("))
        XCTAssertTrue(policy.contains("func separatorPreferredPosition("))
        XCTAssertTrue(workflow.contains("StatusBarPositionDefaultsStore.applyPreferredPosition"))
        XCTAssertTrue(workflow.contains("hidingService.hide()"))
        XCTAssertTrue(workflow.contains("hidingService.show()"))
        XCTAssertTrue(workflow.contains("isRunningAutomatedTests"))
        XCTAssertFalse(workflow.contains("performCmdDrag"))
        XCTAssertFalse(workflow.contains("0x33"))
        XCTAssertFalse(workflow.contains("AccessibilityMenuBarTeleport"))
        XCTAssertFalse(policy.contains("performCmdDrag"))
        XCTAssertTrue(persistence.contains("keepVisibleIconsRightOfNotch"))
        XCTAssertTrue(workflow.contains("keepVisibleIconsRightOfNotch"))
    }
}
