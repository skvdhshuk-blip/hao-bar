import Foundation

typealias GeneralSettingsBrowseLeftClickMode = HaoBarLeftClickAction

enum GeneralSettingsSecondMenuBarPreset: String, CaseIterable, Identifiable {
    case minimal
    case balanced
    case power

    var id: String {
        rawValue
    }

    var title: String {
        switch self {
        case .minimal: String(localized: "Hidden Row")
        case .balanced: String(localized: "Hidden + Visible")
        case .power: String(localized: "All Rows")
        }
    }

    static func resolve(showVisible: Bool, showAlwaysHidden: Bool) -> Self {
        switch (showVisible, showAlwaysHidden) {
        case (false, false):
            .minimal
        case (true, false):
            .balanced
        case (true, true), (false, true):
            .power
        }
    }
}
