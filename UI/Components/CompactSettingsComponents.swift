import SwiftUI
import SaneUI

typealias SaneBarChrome = SaneUI.SanePanelChrome
typealias ChromeGlassRoundedBackground = SaneUI.SaneGlassRoundedBackground
typealias ChromeGlassCapsuleBackground = SaneUI.SaneGlassCapsuleBackground
typealias ChromeGlassCircleBackground = SaneUI.SaneGlassCircleBackground
typealias ChromePressablePlainStyle = SaneUI.SanePressablePlainStyle
typealias ChromeActionButtonStyle = SaneUI.SaneActionButtonStyle
typealias ChromeSegmentedChoiceButton = SaneUI.SaneSegmentedChoiceButton
typealias ChromeBadge = SaneUI.SaneAccentBadge

/// HaoBar card-bottom inset around SaneUI inline help. CompactSection has no
/// content padding; CompactRow supplies 12pt, SaneInlineHelp only 4pt.
struct SettingsInlineHelp: View {
    let text: String

    init(_ text: String) {
        self.text = text
    }

    var body: some View {
        SaneInlineHelp(text)
            .padding(.top, 16)
            .padding(.bottom, 12)
    }
}

typealias HealthInlineHelp = SettingsInlineHelp
