import AppKit
import SaneUI
import SwiftUI

@MainActor
final class HealthWizardController: NSObject, NSWindowDelegate {
    static let shared = HealthWizardController()

    private var window: NSWindow?

    func showIfNeeded() {
        let manager = MenuBarManager.shared
        guard !manager.settings.hasCompletedHealthWizard else { return }
        if AccessibilityService.shared.isGranted {
            manager.profileWorkflow.completeHealthWizard()
            return
        }
        show()
    }

    func show() {
        if let window, window.isVisible {
            window.makeKeyAndOrderFront(nil)
            return
        }

        NSApp.activate()

        let wizardView = FirstRunHealthWizardView { [weak self] in
            self?.dismiss()
        }
        let hostingController = NSHostingController(rootView: wizardView)
        hostingController.saneIgnoreIntrinsicWindowSize()

        let window = NSWindow(
            contentRect: NSRect(
                x: 0,
                y: 0,
                width: SaneSettingsWindowDefaults.idealWidth,
                height: SaneSettingsWindowDefaults.idealHeight
            ),
            styleMask: [.titled, .closable, .resizable, .fullSizeContentView],
            backing: .buffered,
            defer: false
        )
        window.appearance = NSAppearance(named: .darkAqua)
        window.title = String(localized: "HaoBar Health")
        window.titleVisibility = .hidden
        window.titlebarAppearsTransparent = true
        window.isMovableByWindowBackground = true
        window.contentViewController = hostingController
        window.saneApplySettingsChrome(preferIdealSize: true)
        window.center()
        window.isReleasedWhenClosed = false
        window.delegate = self

        self.window = window
        window.makeKeyAndOrderFront(nil)
    }

    func dismiss() {
        window?.close()
    }

    func windowWillClose(_: Notification) {
        guard window != nil else { return }
        window = nil
        MenuBarManager.shared.profileWorkflow.completeHealthWizard()
        SaneActivationPolicy.restorePolicy(showDockIcon: MenuBarManager.shared.settings.showDockIcon)
    }
}

private struct FirstRunHealthWizardView: View {
    @ObservedObject private var menuBarManager = MenuBarManager.shared
    @ObservedObject private var accessibilityService = AccessibilityService.shared
    @State private var rescuePointSaved = false
    @State private var repairRan = false
    @State private var rescueMessage = ""
    let onComplete: () -> Void

    var body: some View {
        SaneSettingsPage {
            CompactSection(String(localized: "HaoBar Health"), icon: "stethoscope", iconColor: .green) {
                SaneInlineHelp(String(localized: "Finish setup with a permission check and a saved layout restore point."))
                CompactDivider()
                accessibilityRow
                CompactDivider()
                restorePointRow
                CompactDivider()
                repairRow
                if !rescueMessage.isEmpty {
                    CompactDivider()
                    SaneInlineHelp(rescueMessage)
                }
                CompactDivider()
                CompactRow(String(localized: "Close this check")) {
                    ActionButton("Done", style: .primary, action: onComplete)
                        .saneHelp(String(localized: "Closes this check. Open Settings > Health later if you still need a restore point."))
                }
            }
        }
        .background(
            SaneGradientBackground(
                style: .panel,
                motion: .animated,
                useSystemVibrancy: true
            )
        )
        .groupBoxStyle(GlassGroupBoxStyle())
        .onAppear {
            rescuePointSaved = menuBarManager.settings.layoutRescueRestorePoint != nil
        }
    }

    private var accessibilityRow: some View {
        CompactRow(String(localized: "Accessibility")) {
            HStack(spacing: 8) {
                StatusBadge(
                    accessibilityService.isGranted ? String(localized: "OK") : String(localized: "Needs Action"),
                    color: accessibilityService.isGranted ? .green : .orange,
                    icon: accessibilityService.isGranted ? "checkmark.circle.fill" : "exclamationmark.triangle.fill"
                )
                .saneHelp(accessibilityHelp)

                if !accessibilityService.isGranted {
                    ActionButton("Open", icon: "gearshape", style: .primary) {
                        openAccessibilitySettings()
                    }
                    .controlSize(.small)
                    .saneHelp(String(localized: "Opens macOS Privacy & Security > Accessibility."))
                }
            }
            .fixedSize(horizontal: true, vertical: false)
        }
    }

    private var restorePointRow: some View {
        CompactRow(String(localized: "Layout Restore Point")) {
            HStack(spacing: 8) {
                StatusBadge(
                    rescuePointSaved || menuBarManager.settings.layoutRescueRestorePoint != nil ? String(localized: "Saved") : String(localized: "Not Saved"),
                    color: rescuePointSaved || menuBarManager.settings.layoutRescueRestorePoint != nil ? .green : .orange,
                    icon: "lifepreserver"
                )
                .saneHelp(String(localized: "The first restore point lets HaoBar return to the current known-good layout later."))

                ActionButton("Save", style: .secondary) {
                    saveRestorePoint()
                }
                .controlSize(.small)
                .saneHelp(String(localized: "Saves the current menu bar layout as HaoBar's first rescue point."))
            }
            .fixedSize(horizontal: true, vertical: false)
        }
    }

    private var repairRow: some View {
        CompactRow(String(localized: "Repair Check")) {
            HStack(spacing: 8) {
                StatusBadge(
                    repairRan ? String(localized: "Run") : String(localized: "Ready"),
                    color: repairRan ? .green : .cyan,
                    icon: "wrench.and.screwdriver"
                )
                .saneHelp(String(localized: "Arrange Now uses the same layout rescue path available later in Health."))

                ActionButton("Arrange", style: .secondary) {
                    Task { @MainActor in
                        _ = await menuBarManager.profileWorkflow.repairMenuBarHealth(reason: "health-wizard")
                        repairRan = true
                    }
                }
                .controlSize(.small)
                .saneHelp(String(localized: "Runs an immediate layout repair check."))
            }
            .fixedSize(horizontal: true, vertical: false)
        }
    }

    private var accessibilityHelp: String {
        accessibilityService.isGranted
            ? String(localized: "HaoBar can inspect and arrange menu bar items.")
            : String(localized: "Open Accessibility settings and grant HaoBar before using Browse Icons or Arrange Now.")
    }

    private func saveRestorePoint() {
        rescuePointSaved = menuBarManager.profileWorkflow.createLayoutRescueRestorePoint(reason: "health-wizard")
        rescueMessage = rescuePointSaved
            ? String(localized: "Restore point saved.")
            : String(localized: "Run Arrange Now after Accessibility is granted, then save a restore point.")
    }

    private func openAccessibilitySettings() {
        guard let url = URL(string: AccessibilityService.accessibilitySettingsURLString) else { return }
        NSWorkspace.shared.open(url)
    }
}
