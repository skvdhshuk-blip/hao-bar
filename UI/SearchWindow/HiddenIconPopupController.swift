import AppKit
import SwiftUI

@MainActor
final class HiddenIconPopupController: NSObject, NSWindowDelegate {
    static let shared = HiddenIconPopupController()

    private var panel: NSPanel?
    private var isVisible: Bool { panel?.isVisible == true }

    func toggle() {
        if isVisible {
            hide()
            return
        }
        Task { await show() }
    }

    func hide() {
        panel?.orderOut(nil)
    }

    private func show() async {
        let manager = MenuBarManager.shared
        if !MenuBarItemCapturePermission.isGranted {
            await MenuBarItemCapturePermission.registerWithTCC()
        }
        if manager.settings.requireAuthToShowHiddenIcons {
            let allowed = await manager.visibilityWorkflow.authenticateForHiddenRevealIfNeeded()
            guard allowed else { return }
        }

        let classified = SearchService.shared.cachedClassifiedApps()
        let screen = manager.currentRecoveryReferenceScreen() ?? NSScreen.main
        let apps = HiddenIconPopupPolicy.apps(
            from: classified,
            notchRightSafeMinX: screen?.auxiliaryTopRightArea?.minX
        )
        if manager.hidingService.state == .expanded {
            await MenuBarItemCaptureService.shared.captureOnScreenHiddenItems(apps: classified.hidden, screen: screen)
        }

        present(apps: apps, screen: screen)
    }

    private func present(apps: [RunningApp], screen: NSScreen?) {
        let view = HiddenIconPopupView(
            apps: apps,
            hasAccessibility: AccessibilityService.shared.isGranted,
            hasScreenCapture: MenuBarItemCapturePermission.isGranted,
            onActivate: { [weak self] app in
                self?.hide()
                Task { @MainActor in
                    await SearchService.shared.activate(app: app, isRightClick: false, origin: .browsePanel)
                }
            },
            onDismiss: { [weak self] in
                self?.hide()
            },
            onOpenScreenRecordingSettings: {
                Task {
                    await MenuBarItemCapturePermission.requestAndOpenSettings()
                }
            }
        )
        .preferredColorScheme(.dark)

        let hostingView = NSHostingView(rootView: view)
        hostingView.setContentHuggingPriority(.defaultHigh, for: .horizontal)
        hostingView.setContentHuggingPriority(.defaultHigh, for: .vertical)

        let panel = self.panel ?? HiddenIconPopupPanel(
            contentRect: NSRect(x: 0, y: 0, width: 280, height: 72),
            styleMask: [.borderless],
            backing: .buffered,
            defer: false
        )
        panel.contentView = hostingView
        panel.backgroundColor = .clear
        panel.isOpaque = false
        panel.level = .floating
        panel.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary, .ignoresCycle]
        panel.isReleasedWhenClosed = false
        panel.delegate = self
        panel.hasShadow = true
        panel.hidesOnDeactivate = false
        panel.acceptsMouseMovedEvents = true
        panel.appearance = NSAppearance(named: .darkAqua)
        hostingView.appearance = panel.appearance

        hostingView.layoutSubtreeIfNeeded()
        let fitting = hostingView.fittingSize
        let size = NSSize(
            width: min(max(fitting.width, 220), 640),
            height: min(max(fitting.height, 64), 160)
        )
        let origin = popupOrigin(size: size, screen: screen)
        panel.setFrame(NSRect(origin: origin, size: size), display: true)
        panel.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
        self.panel = panel
    }

    private func popupOrigin(size: NSSize, screen: NSScreen?) -> NSPoint {
        let target = screen ?? NSScreen.main
        let screenFrame = target?.frame ?? NSRect(x: 0, y: 0, width: 1440, height: 900)
        let visibleFrame = target?.visibleFrame ?? screenFrame
        let menuBarHeight = max(24, screenFrame.maxY - visibleFrame.maxY)
        let rightEdge: CGFloat
        if let button = MenuBarManager.shared.mainStatusItem?.button, let buttonWindow = button.window {
            rightEdge = buttonWindow.frame.maxX
        } else {
            rightEdge = visibleFrame.maxX - 10
        }
        let xPos = max(visibleFrame.minX + 10, rightEdge - size.width)
        let yPos = screenFrame.maxY - menuBarHeight - size.height - 4
        return NSPoint(x: xPos, y: yPos)
    }

    func windowDidResignKey(_: Notification) {
        hide()
    }
}

private final class HiddenIconPopupPanel: NSPanel {
    override var canBecomeKey: Bool { true }
}
