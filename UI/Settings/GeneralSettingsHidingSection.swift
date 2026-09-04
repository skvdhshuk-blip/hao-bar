import SaneUI
import SwiftUI

struct GeneralSettingsHidingSection: View {
    @ObservedObject var menuBarManager: MenuBarManager
    @ObservedObject var licenseService: LicenseService
    let showProUpsell: (ProFeature) -> Void
    @State private var hideAllOtherStatusMessage: String?

    private var rehideDelayLabel: String {
        delaySecondsLabel(Int(menuBarManager.settings.rehideDelay))
    }

    private var findIconDelayLabel: String {
        delaySecondsLabel(Int(menuBarManager.settings.findIconRehideDelay))
    }

    private func delaySecondsLabel(_ value: Int) -> String {
        switch value {
        case 1 ... 5:
            String(format: String(localized: "Quick (%ds)"), value)
        case 6 ... 15:
            String(format: String(localized: "Normal (%ds)"), value)
        case 16 ... 30:
            String(format: String(localized: "Leisurely (%ds)"), value)
        default:
            String(format: String(localized: "Extended (%ds)"), value)
        }
    }

    private func delayLabel(_ seconds: Double) -> String {
        let ms = Int(seconds * 1000)
        switch ms {
        case 0 ... 150: return String(localized: "Instant")
        case 151 ... 350: return String(localized: "Quick")
        case 351 ... 600: return String(localized: "Normal")
        default: return String(localized: "Patient")
        }
    }

    private var hideAllOtherMenuBarItemsBinding: Binding<Bool> {
        Binding(
            get: { menuBarManager.settings.hideAllOtherMenuBarItems },
            set: { isEnabled in
                if isEnabled {
                    hideAllOtherStatusMessage = String(localized: "Checking current menu bar...")
                    menuBarManager.hideAllOtherWorkflow.enableFromCurrentLayout { enabled in
                        hideAllOtherStatusMessage = enabled
                            ? nil
                            : String(localized: "HaoBar couldn't turn this on safely. Open Health and repair menu bar detection, then try again.")
                    }
                } else {
                    hideAllOtherStatusMessage = nil
                    menuBarManager.settings.hideAllOtherMenuBarItems = false
                    menuBarManager.saveSettings()
                }
            }
        )
    }

    private var gestureModeSummary: String {
        menuBarManager.settings.gestureMode == .showOnly
            ? String(localized: "Gestures reveal hidden icons.")
            : String(localized: "Scroll up shows icons, scroll down hides icons.")
    }

    var body: some View {
        CompactSection(String(localized: "Hiding Behavior")) {
            CompactToggle(label: String(localized: "Hide icons automatically"), isOn: $menuBarManager.settings.autoRehide)
                .help("Hide revealed icons again after the delay below.")

            if menuBarManager.settings.autoRehide {
                autoRehideRows
            }

            CompactDivider()
            CompactToggle(label: String(localized: "Reveal hidden icons on hover"), isOn: $menuBarManager.settings.showOnHover)
                .help("Hover near the menu bar to reveal hidden icons inline. Click the HaoBar icon to open or toggle manually.")
            if menuBarManager.settings.showOnHover {
                revealDelayRow
            }

            CompactDivider()
            CompactToggle(label: String(localized: "Show when scrolling on menu bar"), isOn: $menuBarManager.settings.showOnScroll)
            if menuBarManager.settings.showOnScroll {
                // Shared reveal delay also governs scroll; show it here only when
                // hover (which already shows it) is off, so it never appears twice.
                if !menuBarManager.settings.showOnHover {
                    revealDelayRow
                }
                scrollGestureRows
            }

            CompactDivider()
            CompactToggle(label: String(localized: "Show when rearranging icons"), isOn: $menuBarManager.settings.showOnUserDrag)

            CompactDivider()
            if licenseService.isPro {
                CompactToggle(label: String(localized: "Always show on external monitors"), isOn: $menuBarManager.settings.disableOnExternalMonitor)
                    .help("Keep icons visible on external displays where menu bar space is less constrained.")
            } else {
                proGatedRow(feature: .autoRehideCustomization, label: String(localized: "Always show on external monitors"))
            }

            CompactDivider()
            CompactToggle(label: String(localized: "Hide app menus during inline reveal"), isOn: $menuBarManager.settings.hideApplicationMenusOnInlineReveal)
                .help("Temporarily hides File/Edit/View if needed to make room in the menu bar. Only affects inline reveal.")

            CompactDivider()
            if licenseService.isPro {
                hideNewUnlistedToggleRow
                    .help("Keep only the explicitly visible items shown; move other detected menu bar items to Hidden.")
                if let hideAllOtherStatusMessage {
                    CompactDivider()
                    SaneInlineHelp(hideAllOtherStatusMessage)
                        .accessibilityIdentifier("sanebar-hide-new-unlisted-status")
                }
            } else {
                proGatedRow(feature: .zoneMoves, label: String(localized: "Hide new/unlisted items by default"))
            }
        }
    }

    private var hideNewUnlistedToggleRow: some View {
        CompactToggle(label: String(localized: "Hide new/unlisted items by default"), isOn: hideAllOtherMenuBarItemsBinding)
            .accessibilityIdentifier("sanebar-hide-new-unlisted-toggle")
    }

    @ViewBuilder
    private var autoRehideRows: some View {
        if licenseService.isPro {
            CompactDivider()
            CompactRow(String(localized: "Wait before hiding")) {
                HStack(spacing: 8) {
                    Text(rehideDelayLabel)
                        .font(SaneTypography.label)
                        .foregroundStyle(SaneTypography.text)
                        .lineLimit(1)
                        .fixedSize(horizontal: true, vertical: false)
                    Stepper("", value: $menuBarManager.settings.rehideDelay, in: 1 ... 60, step: 1)
                        .labelsHidden()
                        .controlSize(.regular)
                }
            }
            CompactDivider()
            CompactRow(String(localized: "Wait after Browse Icons")) {
                HStack(spacing: 8) {
                    Text(findIconDelayLabel)
                        .font(SaneTypography.label)
                        .foregroundStyle(SaneTypography.text)
                        .lineLimit(1)
                        .fixedSize(horizontal: true, vertical: false)
                    Stepper("", value: $menuBarManager.settings.findIconRehideDelay, in: 5 ... 60, step: 5)
                        .labelsHidden()
                        .controlSize(.regular)
                }
            }
            CompactDivider()
            CompactToggle(label: String(localized: "Hide when app changes"), isOn: $menuBarManager.settings.rehideOnAppChange)
        } else {
            CompactDivider()
            proGatedRow(feature: .autoRehideCustomization, label: String(localized: "Customize auto-hide timing"))
        }
    }

    /// One shared dwell for both hover and scroll reveal — keeps the UI uncluttered
    /// while still letting users tune how long they must linger before icons reveal.
    @ViewBuilder
    private var revealDelayRow: some View {
        CompactDivider()
        CompactRow(String(localized: "Reveal delay")) {
            HStack(spacing: 8) {
                Slider(value: $menuBarManager.settings.hoverDelay, in: 0.05 ... 2.0, step: 0.05)
                    .frame(width: 100)
                    .controlSize(.regular)
                Text(delayLabel(menuBarManager.settings.hoverDelay))
                    .font(SaneTypography.label)
                    .foregroundStyle(SaneTypography.text)
                    .lineLimit(1)
                    .fixedSize(horizontal: true, vertical: false)
            }
        }
    }

    @ViewBuilder
    private var scrollGestureRows: some View {
        CompactDivider()
        if licenseService.isPro {
            CompactRow(String(localized: "Gesture behavior")) {
                HStack(spacing: 6) {
                    ForEach(SaneBarSettings.GestureMode.allCases, id: \.self) { mode in
                        ChromeSegmentedChoiceButton(
                            title: mode.localizedTitle,
                            isSelected: menuBarManager.settings.gestureMode == mode
                        ) {
                            menuBarManager.settings.gestureMode = mode
                        }
                        .help(gestureModeHelp(mode))
                    }
                }
                .fixedSize(horizontal: true, vertical: false)
            }
            SaneInlineHelp(gestureModeSummary)
        } else {
            proGatedRow(feature: .gestureCustomization, label: String(localized: "Customize gesture behavior"))
        }
    }

    private func gestureModeHelp(_ mode: SaneBarSettings.GestureMode) -> String {
        switch mode {
        case .showOnly:
            String(localized: "Gestures only reveal hidden icons.")
        case .showAndHide:
            String(localized: "Gestures toggle visibility. Scroll up shows icons, scroll down hides them.")
        }
    }

    private func proGatedRow(feature: ProFeature, label: String) -> some View {
        CompactRow(label) {
            Button {
                showProUpsell(feature)
            } label: {
                ChromeBadge(title: "Pro", systemImage: "lock.fill")
            }
            .buttonStyle(.plain)
        }
    }
}
