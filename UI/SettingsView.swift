import AppKit
import SaneUI
import SwiftUI

struct SettingsView: View {
    enum SettingsTab: String, SaneSettingsTab {
        case control = "Control"
        case appearance = "Appearance"
        case health = "Health"
        case advanced = "Advanced"
        case about = "About"

        var title: String {
            switch self {
            case .control: String(localized: "General")
            case .appearance: String(localized: "Appearance")
            case .health: String(localized: "Permissions")
            case .advanced: String(localized: "Advanced")
            case .about: String(localized: "About")
            }
        }

        var icon: String {
            switch self {
            case .control: "gearshape"
            case .appearance: "paintpalette"
            case .health: "lock.shield"
            case .advanced: "slider.horizontal.3"
            case .about: "questionmark.circle"
            }
        }

        var iconColor: Color {
            switch self {
            case .control:
                SaneSettingsIconSemantic.general.color
            case .appearance:
                SaneSettingsIconSemantic.appearance.color
            case .health:
                .green
            case .advanced:
                SaneSettingsIconSemantic.shortcuts.color
            case .about:
                SaneSettingsIconSemantic.about.color
            }
        }
    }

    var defaultTab: SettingsTab = .control

    var body: some View {
        SaneSettingsContainer(defaultTab: defaultTab, windowSizing: .embedded) { tab in
            switch tab {
            case .control:
                GeneralSettingsView()
                    .navigationTitle(String(localized: "General"))
            case .appearance:
                AppearanceSettingsView()
                    .navigationTitle(String(localized: "Appearance"))
            case .health:
                HealthSettingsView()
                    .navigationTitle(String(localized: "Permissions"))
            case .advanced:
                AdvancedSettingsView()
                    .navigationTitle(String(localized: "Advanced"))
            case .about:
                AboutSettingsView()
                    .navigationTitle(String(localized: "About"))
            }
        }
        .overlay(alignment: .bottomTrailing) {
            SaneSettingsResizeGrip()
                .frame(width: 22, height: 22)
                .padding(.trailing, 7)
                .padding(.bottom, 7)
                .saneHelp(String(localized: "Drag the corner to resize Settings."))
        }
    }
}

#Preview {
    SettingsView()
}
