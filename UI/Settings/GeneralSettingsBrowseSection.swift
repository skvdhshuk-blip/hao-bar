import SaneUI
import SwiftUI

struct GeneralSettingsBrowseSection: View {
    @ObservedObject var menuBarManager: MenuBarManager
    @ObservedObject var licenseService: LicenseService
    @Binding var showBrowseRowCustomization: Bool
    let leftClickMode: Binding<GeneralSettingsBrowseLeftClickMode>
    let secondMenuBarPreset: Binding<GeneralSettingsSecondMenuBarPreset>
    let applyBrowseIconsViewSelection: (Bool) -> Void
    let showProUpsell: (ProFeature) -> Void

    private var browseDestinationLabel: String {
        menuBarManager.settings.useSecondMenuBar ? String(localized: "Second Menu Bar") : String(localized: "Icon Panel")
    }

    private var isBasicSecondMenuBar: Bool {
        !licenseService.isPro && menuBarManager.settings.useSecondMenuBar
    }

    private var secondMenuBarRowsSummary: String {
        var rows = [String(localized: "Hidden")]
        if menuBarManager.settings.secondMenuBarShowVisible {
            rows.append(String(localized: "Visible"))
        }
        if menuBarManager.settings.secondMenuBarShowAlwaysHidden {
            rows.append(String(localized: "Always Hidden"))
        }
        return rows.joined(separator: " + ")
    }

    var body: some View {
        CompactSection(String(localized: "Browse Icons")) {
            CompactRow(String(localized: "Browse Icons view")) {
                HStack(spacing: 6) {
                    segmentedChoiceButton(String(localized: "Icon Panel"), isSelected: !menuBarManager.settings.useSecondMenuBar) {
                        applyBrowseIconsViewSelection(false)
                    }
                    .help(browseIconsViewOptionHelp(useSecondMenuBar: false))

                    segmentedChoiceButton(String(localized: "Second Menu Bar"), isSelected: menuBarManager.settings.useSecondMenuBar) {
                        applyBrowseIconsViewSelection(true)
                    }
                    .help(browseIconsViewOptionHelp(useSecondMenuBar: true))
                }
                .fixedSize(horizontal: true, vertical: false)
            }

            if licenseService.isPro, menuBarManager.settings.useSecondMenuBar {
                proSecondMenuBarRows
            } else if isBasicSecondMenuBar {
                CompactDivider()
                CompactRow(String(localized: "Rows shown in Second Menu Bar")) {
                    Text("Hidden + Visible")
                        .font(SaneTypography.label)
                        .foregroundStyle(.white.opacity(0.94))
                }
                CompactDivider()
                proGatedRow(feature: .alwaysHidden, label: String(localized: "Always Hidden row"))
            } else if !licenseService.isPro {
                CompactDivider()
                proGatedRow(feature: .zoneMoves, label: String(localized: "Move icons between Visible, Hidden, and Always Hidden"))
            }

            CompactDivider()
            leftClickRows
        }
    }

    @ViewBuilder
    private var proSecondMenuBarRows: some View {
        CompactDivider()
        CompactRow(String(localized: "Rows shown in Second Menu Bar")) {
            HStack(spacing: 6) {
                ForEach(GeneralSettingsSecondMenuBarPreset.allCases) { preset in
                    segmentedChoiceButton(preset.title, isSelected: secondMenuBarPreset.wrappedValue == preset) {
                        secondMenuBarPreset.wrappedValue = preset
                    }
                    .help(secondMenuBarPresetHelp(preset))
                }
            }
            .fixedSize(horizontal: true, vertical: false)
        }
        .saneHelp(secondMenuBarRowsSummary)

        if secondMenuBarPreset.wrappedValue == .power {
            powerRows
        }
    }

    @ViewBuilder
    private var powerRows: some View {
        CompactDivider()
        CompactRow(String(localized: "Custom rows")) {
            Button(showBrowseRowCustomization ? "Hide" : "Show") {
                withAnimation(.easeInOut(duration: 0.18)) {
                    showBrowseRowCustomization.toggle()
                }
            }
            .buttonStyle(ChromeActionButtonStyle())
            .help("Show or hide row-level options.")
        }

        if showBrowseRowCustomization {
            CompactDivider()
            CompactToggle(label: String(localized: "Show Visible row"), isOn: $menuBarManager.settings.secondMenuBarShowVisible)
                .help("Show the Visible destination row in the Second Menu Bar.")

            CompactDivider()
            CompactToggle(label: String(localized: "Show Always Hidden row"), isOn: $menuBarManager.settings.secondMenuBarShowAlwaysHidden)
                .help("Show the Always Hidden destination row in the Second Menu Bar.")
        }
    }

    private var leftClickRows: some View {
        CompactRow(String(localized: "Left-click HaoBar icon")) {
            HStack(spacing: 6) {
                ForEach(GeneralSettingsBrowseLeftClickMode.allCases) { mode in
                    segmentedChoiceButton(mode.title, isSelected: leftClickMode.wrappedValue == mode) {
                        leftClickMode.wrappedValue = mode
                    }
                    .help(leftClickModeHelp(mode))
                }
            }
            .fixedSize(horizontal: true, vertical: false)
        }
        .saneHelp(String(localized: "Right-click the HaoBar icon to open the app menu."))
    }

    private func segmentedChoiceButton(
        _ title: String,
        isSelected: Bool,
        action: @escaping () -> Void
    ) -> some View {
        ChromeSegmentedChoiceButton(title: title, isSelected: isSelected, action: action)
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

    private func browseIconsViewOptionHelp(useSecondMenuBar: Bool) -> String {
        if useSecondMenuBar {
            if licenseService.isPro {
                return String(localized: "Open a row-based strip under the menu bar.")
            }
            return String(localized: "Open a row-based strip under the menu bar. Basic includes browsing and clicking there. Pro adds moving icons and Always Hidden.")
        }

        if licenseService.isPro {
            return String(localized: "Open the Icon Panel window with search and icon actions.")
        }
        return String(localized: "Open the Icon Panel window with search and icon clicking. Pro adds moving icons and Always Hidden.")
    }

    private func secondMenuBarPresetHelp(_ preset: GeneralSettingsSecondMenuBarPreset) -> String {
        switch preset {
        case .minimal:
            String(localized: "Show only the Hidden row in the Second Menu Bar.")
        case .balanced:
            String(localized: "Show Hidden and Visible rows in the Second Menu Bar.")
        case .power:
            String(localized: "Show Hidden, Visible, and Always Hidden rows in the Second Menu Bar.")
        }
    }

    private func leftClickModeHelp(_ mode: GeneralSettingsBrowseLeftClickMode) -> String {
        switch mode {
        case .showHiddenIconBar:
            return String(localized: "Left-click the HaoBar icon to show hidden icons in a bar under the menu bar.")
        case .toggleHidden:
            return String(localized: "Left-click the HaoBar icon to show or hide icons.")
        case .openBrowseIcons:
            if licenseService.isPro {
                return String(localized: "Left-click the HaoBar icon to open \(browseDestinationLabel).")
            }
            return String(localized: "Left-click the HaoBar icon to open \(browseDestinationLabel) for browsing and clicking icons.")
        }
    }
}
