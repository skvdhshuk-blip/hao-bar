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
                    .navigationTitle("Control")
            case .rules:
                RulesSettingsView()
                    .navigationTitle("Rules")
            case .appearance:
                AppearanceSettingsView()
                    .navigationTitle("Appearance")
            case .shortcuts:
                ShortcutsSettingsView()
                    .navigationTitle("Shortcuts")
            case .health:
                HealthSettingsView()
                    .navigationTitle("Health")
            case .about:
                AboutSettingsView()
                    .navigationTitle("About")
            }
        }
        .overlay(alignment: .bottomTrailing) {
            SaneSettingsResizeGrip()
                .frame(width: 22, height: 22)
                .padding(.trailing, 7)
                .padding(.bottom, 7)
                .saneHelp("Drag the corner to resize Settings.")
        }
    }
}

#Preview {
    SettingsView()
}
