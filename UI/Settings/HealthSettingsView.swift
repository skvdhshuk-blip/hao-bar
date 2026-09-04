import AppKit
import SaneUI
import SwiftUI

struct HealthSettingsView: View {
    @ObservedObject private var menuBarManager = MenuBarManager.shared
    @ObservedObject private var accessibilityService = AccessibilityService.shared
    @State private var visibleCount = 0
    @State private var hiddenCount = 0
    @State private var alwaysHiddenCount = 0
    @State private var totalCount = 0
    @State private var lastScanDate: Date?
    @State private var lastRepairDate: Date?
    @State private var copiedDiagnostics = false
    @State private var layoutRescueMessage = ""
    @State private var repairInProgress = false

    private var runtimeSnapshot: MenuBarRuntimeSnapshot {
        menuBarManager.currentRuntimeSnapshot()
    }

    private var geometryLabel: String {
        switch runtimeSnapshot.geometryConfidence {
        case .live: String(localized: "High")
        case .shielded: String(localized: "Protected")
        case .cached: String(localized: "Good")
        case .stale: String(localized: "Needs Check")
        case .missing: String(localized: "Needs Repair")
        }
    }

    private var geometryColor: Color {
        switch runtimeSnapshot.geometryConfidence {
        case .live, .cached: .green
        case .shielded: .cyan
        case .stale: .orange
        case .missing: .red
        }
    }

    private var structureLabel: String {
        if runtimeSnapshot.likelySystemSuppressedStatusItems {
            return String(localized: "Hidden by macOS")
        }
        return switch runtimeSnapshot.structuralState {
        case .ready: String(localized: "Ready")
        case .missingItems: String(localized: "Missing")
        case .invisibleItems: String(localized: "Hidden")
        case .unattachedWindows: String(localized: "Detached")
        }
    }

    private var lastRepairLabel: String {
        lastRepairDate?.formatted(date: .omitted, time: .shortened) ?? String(localized: "Not run")
    }

    private var restorePointLabel: String {
        menuBarManager.settings.layoutRescueRestorePointCreatedAt?.formatted(date: .abbreviated, time: .shortened) ?? String(localized: "Not created")
    }

    private var canRestoreLayout: Bool {
        menuBarManager.settings.layoutRescueRestorePoint != nil
    }

    private var needsGeometryAction: Bool {
        switch runtimeSnapshot.geometryConfidence {
        case .live, .shielded, .cached:
            false
        case .stale, .missing:
            true
        }
    }

    private var needsStructureAction: Bool {
        runtimeSnapshot.structuralState != .ready
    }

    private var accessibilityHelp: String {
        accessibilityService.isGranted
            ? String(localized: "HaoBar has Accessibility permission and can inspect, reveal, and arrange menu bar items.")
            : AccessibilityService.deniedHelpText()
    }

    private var geometryHelp: String {
        switch runtimeSnapshot.geometryConfidence {
        case .live:
            String(localized: "HaoBar has current menu bar anchor positions from the live system.")
        case .shielded:
            String(localized: "HaoBar is protecting the layout while macOS is temporarily hiding or moving menu bar items.")
        case .cached:
            String(localized: "HaoBar has usable saved menu bar anchor positions and will refresh them when needed.")
        case .stale:
            String(localized: "HaoBar can run Arrange Now to refresh older menu bar anchor positions.")
        case .missing:
            String(localized: "HaoBar does not have enough menu bar anchor data. Run Arrange Now to rebuild it.")
        }
    }

    private var structureHelp: String {
        if runtimeSnapshot.likelySystemSuppressedStatusItems {
            return String(localized: "macOS says HaoBar's menu bar items are visible, but their windows are detached. Check System Settings > Menu Bar > Allow in Menu Bar for HaoBar.")
        }
        return switch runtimeSnapshot.structuralState {
        case .ready:
            String(localized: "HaoBar can see the expected visible, hidden, and always-hidden item groups.")
        case .missingItems:
            String(localized: "Some expected menu bar items are not currently visible to HaoBar.")
        case .invisibleItems:
            String(localized: "macOS is reporting some menu bar items as hidden or unavailable right now.")
        case .unattachedWindows:
            String(localized: "Some menu bar windows are detached from their expected anchors. Arrange Now can repair this.")
        }
    }

    private var layoutModeHelp: String {
        switch menuBarManager.settings.layoutMode {
        case .stability:
            String(localized: "Hands-off: HaoBar only fixes its icon layout when it starts or when you click Fix. Good if your setup rarely changes.")
        case .live:
            String(localized: "HaoBar also re-checks the layout after sleep/wake and when displays are connected or disconnected. Good if icons sometimes scramble after wake.")
        }
    }

    var body: some View {
        SaneSettingsPage {
                if runtimeSnapshot.likelySystemSuppressedStatusItems {
                    CompactSection(String(localized: "Icon Missing From the Menu Bar?"), icon: "exclamationmark.triangle.fill", iconColor: .orange) {
                        CompactRow(String(localized: "Menu Bar settings")) {
                            Button("Open Menu Bar Settings") {
                                openMenuBarSettings()
                            }
                            .buttonStyle(ChromeActionButtonStyle(prominent: true))
                            .saneHelp(String(localized: "Opens macOS System Settings so you can manage which icons are allowed in the menu bar."))
                            .accessibilityLabel(String(localized: "Open macOS Menu Bar settings"))
                        }
                        HealthInlineHelp(
                            String(localized: "macOS may be hiding HaoBar's icon behind the notch or because the menu bar is full. macOS doesn't let apps force their own icon back on screen, so this is fixed at the system level: open Menu Bar settings to manage what's shown, remove or reorder other menu-bar icons, or move HaoBar's icon to the immediate left of Control Center.")
                        )
                    }
                }

                CompactSection(String(localized: "Status"), icon: "stethoscope", iconColor: .green) {
                    CompactRow(String(localized: "Accessibility")) {
                        HStack(spacing: 8) {
                            StatusBadge(
                                accessibilityService.isGranted ? String(localized: "OK") : String(localized: "Needs Action"),
                                color: accessibilityService.isGranted ? .green : .orange,
                                icon: accessibilityService.isGranted ? "checkmark.circle.fill" : "exclamationmark.triangle.fill"
                            )
                            .saneHelp(accessibilityHelp)

                            if !accessibilityService.isGranted {
                                Button("Open") {
                                    openAccessibilitySettings()
                                }
                                .buttonStyle(ChromeActionButtonStyle(prominent: true))
                                .saneHelp(String(localized: "Opens Accessibility settings so you can grant HaoBar permission."))
                                .accessibilityLabel(String(localized: "Open Accessibility settings"))

                                Button("Try Again") {
                                    accessibilityService.retryAccessibilityPermission()
                                }
                                .buttonStyle(ChromeActionButtonStyle())
                                .saneHelp(String(localized: "Rechecks this HaoBar copy after you enable the matching switch."))
                            }
                        }
                    }
                    if !accessibilityService.isGranted {
                        HealthInlineHelp(AccessibilityService.deniedHelpText())
                    }
                    CompactDivider()
                    CompactRow(String(localized: "Screen Recording")) {
                        HStack(spacing: 8) {
                            StatusBadge(
                                MenuBarItemCapturePermission.isGranted ? String(localized: "OK") : String(localized: "Needs Action"),
                                color: MenuBarItemCapturePermission.isGranted ? .green : .orange,
                                icon: MenuBarItemCapturePermission.isGranted ? "checkmark.circle.fill" : "exclamationmark.triangle.fill"
                            )
                            .saneHelp(String(localized: "HaoBar captures the menu bar so hidden icons can appear in the popup bar. It does not record video or upload anything."))

                            if !MenuBarItemCapturePermission.isGranted {
                                Button("Open") {
                                    Task {
                                        await MenuBarItemCapturePermission.requestAndOpenSettings()
                                    }
                                }
                                .buttonStyle(ChromeActionButtonStyle(prominent: true))
                                .saneHelp(String(localized: "Opens Screen Recording settings so you can grant HaoBar permission."))
                                .accessibilityLabel(String(localized: "Open Screen Recording settings"))
                            }
                        }
                    }
                    HealthInlineHelp(String(localized: "macOS may show a purple screen-capture indicator while HaoBar snapshots the menu bar."))
                    if !MenuBarItemCapturePermission.isGranted {
                        HealthInlineHelp(String(localized: "Relaunch HaoBar after enabling Screen Recording."))
                    }
                    CompactDivider()
                    CompactRow(String(localized: "Menu Bar Geometry")) {
                        HStack(spacing: 8) {
                            StatusBadge(geometryLabel, color: geometryColor, icon: "point.3.connected.trianglepath.dotted")
                                .saneHelp(geometryHelp)

                            if needsGeometryAction {
                                Button("Fix") {
                                    runRepair(reason: "health-geometry-fix", message: String(localized: "Layout check ran."))
                                }
                                .buttonStyle(ChromeActionButtonStyle(prominent: true))
                                .disabled(repairInProgress)
                                .saneHelp(String(localized: "Runs a layout repair check now."))
                                .accessibilityLabel(String(localized: "Fix menu bar geometry"))
                            }
                        }
                        .fixedSize(horizontal: true, vertical: false)
                    }
                    CompactDivider()
                    CompactRow(String(localized: "HaoBar Items")) {
                        HStack(spacing: 8) {
                            StatusBadge(structureLabel, color: runtimeSnapshot.structuralState == .ready ? .green : .orange, icon: "menubar.rectangle")
                                .saneHelp(structureHelp)

                            if needsStructureAction {
                                Button("Fix") {
                                    runRepair(reason: "health-items-fix", message: String(localized: "Repair check ran."))
                                }
                                .buttonStyle(ChromeActionButtonStyle(prominent: true))
                                .disabled(repairInProgress)
                                .saneHelp(String(localized: "Repairs detached or missing HaoBar item groups."))
                                .accessibilityLabel(String(localized: "Fix HaoBar items"))
                            }
                        }
                        .fixedSize(horizontal: true, vertical: false)
                    }
                    CompactDivider()
                    CompactRow(String(localized: "Layout Mode")) {
                        HStack(spacing: 6) {
                            ChromeSegmentedChoiceButton(
                                title: String(localized: "Stability"),
                                isSelected: menuBarManager.settings.layoutMode == .stability
                            ) {
                                setLayoutMode(.stability)
                            }
                            .saneHelp(String(localized: "Hands-off: HaoBar only fixes its icon layout at startup or when you click Fix."))

                            ChromeSegmentedChoiceButton(
                                title: String(localized: "Live"),
                                isSelected: menuBarManager.settings.layoutMode == .live
                            ) {
                                setLayoutMode(.live)
                            }
                            .saneHelp(String(localized: "HaoBar also re-checks the layout after sleep/wake, display changes, and session changes."))
                        }
                        .fixedSize(horizontal: true, vertical: false)
                    }
                    HealthInlineHelp(layoutModeHelp)
                }

                CompactSection(String(localized: "Layout Rescue"), icon: "lifepreserver", iconColor: .orange) {
                    CompactRow(String(localized: "Restore Point")) {
                        Text(restorePointLabel)
                            .font(SaneTypography.body)
                            .foregroundStyle(.white.opacity(0.94))
                            .saneHelp(String(localized: "The saved known-good layout HaoBar can return to if icons drift after restart, wake, or display changes."))
                    }
                    CompactDivider()
                    CompactRow(String(localized: "Save Current Layout")) {
                        Button("Create") {
                            createRestorePoint()
                        }
                        .buttonStyle(ChromeActionButtonStyle())
                        .saneHelp(String(localized: "Saves the current HaoBar icon, divider, spacer, display-backup, and always-hidden divider positions as the restore point."))
                    }
                    CompactDivider()
                    CompactRow(String(localized: "Restore Last Good Layout")) {
                        Button("Restore") {
                            restoreLayout()
                        }
                        .buttonStyle(ChromeActionButtonStyle())
                        .disabled(!canRestoreLayout)
                        .saneHelp(canRestoreLayout
                            ? String(localized: "Restores the saved layout point, recreates HaoBar's menu bar items, then runs the same repair path as Arrange Now.")
                            : String(localized: "Create a restore point before using layout restore."))
                    }
                    if !layoutRescueMessage.isEmpty {
                        CompactDivider()
                        HealthInlineHelp(layoutRescueMessage)
                    }
                }

                CompactSection(String(localized: "Menu Bar Items"), icon: "rectangle.grid.1x2", iconColor: .cyan) {
                    CompactRow(String(localized: "Detected")) {
                        Text("\(totalCount)")
                            .font(SaneTypography.body)
                            .foregroundStyle(.white)
                    }
                    CompactDivider()
                    CompactRow(String(localized: "Visible / Hidden")) {
                        Text("\(visibleCount) / \(hiddenCount)")
                            .font(SaneTypography.body)
                            .foregroundStyle(.white)
                    }
                    CompactDivider()
                    CompactRow(String(localized: "Always Hidden")) {
                        Text("\(alwaysHiddenCount)")
                            .font(SaneTypography.body)
                            .foregroundStyle(.white)
                    }
                    CompactDivider()
                    CompactRow(String(localized: "Last Scan")) {
                        Text(lastScanDate?.formatted(date: .omitted, time: .shortened) ?? String(localized: "Not run"))
                            .font(SaneTypography.body)
                            .foregroundStyle(.white.opacity(0.94))
                    }
                }

                CompactSection(String(localized: "Repair"), icon: "wrench.and.screwdriver", iconColor: .orange) {
                    if menuBarManager.hasActionableDeferredWakeVisibleAllowListRepair() {
                        HealthInlineHelp(String(localized: "A layout restore after wake was postponed because icon positions could not be confirmed. Click Run to repair it now."))
                        CompactDivider()
                    }
                    CompactRow(String(localized: "Arrange Now")) {
                        Button("Run") {
                            runRepair(reason: "health", message: String(localized: "Repair check ran."))
                        }
                        .buttonStyle(ChromeActionButtonStyle())
                        .disabled(repairInProgress)
                        .saneHelp(String(localized: "Runs an immediate layout check, refreshes menu bar anchor positions, and repairs HaoBar's visible, hidden, and always-hidden groups if needed."))
                    }
                    CompactDivider()
                    CompactRow(String(localized: "Last Repair")) {
                        Text(lastRepairLabel)
                            .font(SaneTypography.body)
                            .foregroundStyle(.white.opacity(0.94))
                    }
                    CompactDivider()
                    CompactRow(String(localized: "Accessibility Settings")) {
                        Button("Open") {
                            openAccessibilitySettings()
                        }
                        .buttonStyle(ChromeActionButtonStyle())
                        .saneHelp(String(localized: "Opens macOS System Settings directly to Privacy & Security > Accessibility so you can grant or repair HaoBar's permission."))
                    }
                }

                CompactSection(String(localized: "Support Report"), icon: "doc.text.magnifyingglass", iconColor: .blue) {
                    CompactRow(String(localized: "Diagnostics")) {
                        Button(copiedDiagnostics ? "Copied" : "Copy Report") {
                            copyDiagnostics()
                        }
                        .buttonStyle(ChromeActionButtonStyle(prominent: copiedDiagnostics))
                        .saneHelp(String(localized: "Copies a support report with current permissions, layout state, item counts, and recent diagnostics to the clipboard."))
                    }
                }
        }
        .refreshAccessibilityPermission(using: accessibilityService)
        .task {
            await refreshCounts()
        }
    }

    private func runRepair(reason: String, message: String? = nil) {
        guard !repairInProgress else { return }
        repairInProgress = true
        layoutRescueMessage = String(localized: "Repairing layout...")
        Task { @MainActor in
            let hadDeferredWakeRepair = menuBarManager.hasActionableDeferredWakeVisibleAllowListRepair()
            let snapshot = await menuBarManager.profileWorkflow.repairMenuBarHealth(reason: reason)
            lastRepairDate = Date()
            if MenuBarProfileWorkflow.canCreateLayoutRescueRestorePoint(from: snapshot) {
                if hadDeferredWakeRepair,
                   menuBarManager.hasActionableDeferredWakeVisibleAllowListRepair() {
                    layoutRescueMessage = String(localized: "Repair is running. HaoBar will clear the wake repair note after the layout restore finishes.")
                } else {
                    layoutRescueMessage = message ?? String(localized: "Repair check finished.")
                }
            } else if snapshot.likelySystemSuppressedStatusItems {
                layoutRescueMessage = String(localized: "macOS may be hiding HaoBar's icons. Check System Settings > Menu Bar > Allow in Menu Bar for HaoBar.")
            } else {
                layoutRescueMessage = String(localized: "Layout still needs attention.")
            }
            await refreshCounts()
            repairInProgress = false
        }
    }

    private func createRestorePoint() {
        if menuBarManager.profileWorkflow.createLayoutRescueRestorePoint(reason: "health") {
            layoutRescueMessage = String(localized: "Restore point saved.")
        } else {
            layoutRescueMessage = MenuBarProfileWorkflow.layoutRescueRestorePointSaveFailureMessage(from: runtimeSnapshot)
        }
    }

    private func restoreLayout() {
        if menuBarManager.profileWorkflow.restoreLayoutRescueRestorePoint(reason: "health") {
            lastRepairDate = Date()
            layoutRescueMessage = String(localized: "Last good layout restored.")
            Task {
                _ = await menuBarManager.profileWorkflow.repairMenuBarHealth(reason: "health-restore-layout")
                await refreshCounts()
            }
        } else {
            layoutRescueMessage = String(localized: "Create a restore point first.")
        }
    }

    private func setLayoutMode(_ mode: SaneBarSettings.LayoutMode) {
        guard menuBarManager.settings.layoutMode != mode else { return }
        Task { @MainActor in
            layoutRescueMessage = mode == .live ? String(localized: "Live checks enabled. Verifying layout...") : ""
            _ = await menuBarManager.profileWorkflow.setLayoutMode(mode, reason: "health")
            if mode == .live {
                lastRepairDate = Date()
                layoutRescueMessage = String(localized: "Live checks enabled.")
            }
            await refreshCounts()
        }
    }

    private func refreshCounts() async {
        let classified = await SearchService.shared.refreshKnownClassifiedApps()
        await MainActor.run {
            visibleCount = classified.visible.count
            hiddenCount = classified.hidden.count
            alwaysHiddenCount = classified.alwaysHidden.count
            totalCount = visibleCount + hiddenCount + alwaysHiddenCount
            lastScanDate = Date()
        }
    }

    private func openAccessibilitySettings() {
        _ = accessibilityService.promptAndOpenAccessibilitySettings()
    }

    private func openMenuBarSettings() {
        // macOS Tahoe manages menu-bar item visibility under Control Center settings.
        // If the deep link can't resolve, NSWorkspace still opens System Settings.
        let url = URL(string: "x-apple.systempreferences:com.apple.ControlCenter-Settings.extension")
            ?? URL(string: "x-apple.systempreferences:")
        guard let url else { return }
        NSWorkspace.shared.open(url)
    }

    private func copyDiagnostics() {
        Task {
            let report = await SaneDiagnosticsService.shared.collectDiagnostics()
            await MainActor.run {
                NSPasteboard.general.clearContents()
                NSPasteboard.general.setString(
                    report.toMarkdown(userDescription: String(localized: "Menu bar health report")),
                    forType: .string
                )
                copiedDiagnostics = true
            }
            try? await Task.sleep(for: .seconds(1.2))
            await MainActor.run {
                copiedDiagnostics = false
            }
        }
    }
}
