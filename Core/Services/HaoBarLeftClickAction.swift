import Foundation

enum HaoBarLeftClickAction: String, Codable, CaseIterable, Identifiable, Equatable {
    case showHiddenIconBar
    case openBrowseIcons
    case toggleHidden

    static let defaultAction: Self = .showHiddenIconBar

    var id: String { rawValue }

    var title: String {
        switch self {
        case .showHiddenIconBar:
            String(localized: "Show Hidden Bar")
        case .openBrowseIcons:
            String(localized: "Open Browse")
        case .toggleHidden:
            String(localized: "Toggle Hidden")
        }
    }

    static func resolved(stored: Self?, legacyOpensBrowseIcons: Bool) -> Self {
        if let stored {
            return stored
        }
        return legacyOpensBrowseIcons ? .openBrowseIcons : .defaultAction
    }
}
