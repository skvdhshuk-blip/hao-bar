import SaneUI
import SwiftUI

struct AdvancedSettingsView: View {
    var body: some View {
        SaneSettingsPage {
            ShortcutsSettingsView()
            RulesSettingsView()
        }
    }
}
