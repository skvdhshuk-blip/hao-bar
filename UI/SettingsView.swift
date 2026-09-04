import AppKit
import SaneUI
import SwiftUI

struct SettingsView: View {
    enum SettingsTab: String, SaneSettingsTab {
        case control = "Control"
        case appearance = "Appearance"
        case shortcuts = "Shortcuts"
        case rules = "Rules"
        case health = "Health"
        case about = "About"

        var title: String {
            switch self {
            case .control: String(localized: "Control")
            case .appearance: String(localized: "Appearance")
            case .shortcuts: String(localized: "Shortcuts")
            case .rules: String(localized: "Rules")
            case .health: String(localized: "Health")
            case .about: String(localized: "About")
            }
        }

        var icon: String {
            switch self {
            case .control: "switch.2"
            case .appearance: "paintpalette"
            case .shortcuts: "keyboard"
            case .rules: "wand.and.stars"
            case .health: "stethoscope"
            case .about: "questionmark.circle"
            }
        }

        var iconColor: Color {
            switch self {
            case .control:
                SaneSettingsIconSemantic.general.color
            case .appearance:
                SaneSettingsIconSemantic.appearance.color
            case .shortcuts:
                SaneSettingsIconSemantic.shortcuts.color
            case .rules:
                SaneSettingsIconSemantic.rules.color
            case .health:
                .green
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
                    .navigationTitle(String(localized: "Control"))
            case .rules:
                RulesSettingsView()
                    .navigationTitle(String(localized: "Rules"))
            case .appearance:
                AppearanceSettingsView()
                    .navigationTitle(String(localized: "Appearance"))
            case .shortcuts:
                ShortcutsSettingsView()
                    .navigationTitle(String(localized: "Shortcuts"))
            case .health:
                HealthSettingsView()
                    .navigationTitle(String(localized: "Health"))
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
