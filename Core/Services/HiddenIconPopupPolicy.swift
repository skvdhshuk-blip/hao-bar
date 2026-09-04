import CoreGraphics
import Foundation

enum HiddenIconPopupPolicy {
    static func apps(
        from classified: SearchClassifiedApps,
        notchRightSafeMinX: CGFloat? = nil
    ) -> [RunningApp] {
        let hidden = classified.hidden.filter { !$0.isUnmovableSystemItem }
        let notchStuck = NotchVisibleOverflowPolicy.visibleOverflow(
            classified: classified,
            notchRightSafeMinX: notchRightSafeMinX
        )
        var seen = Set(hidden.map(\.uniqueId))
        var apps = hidden
        for app in notchStuck where seen.insert(app.uniqueId).inserted {
            apps.append(app)
        }
        return apps
    }
}
