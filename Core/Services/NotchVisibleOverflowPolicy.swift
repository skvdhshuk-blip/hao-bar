import CoreGraphics
import Foundation

enum NotchVisibleOverflowPolicy {
    static let separatorInset: CGFloat = 4

    static func isNotchedScreen(auxiliaryTopRightArea: CGRect?) -> Bool {
        guard let auxiliaryTopRightArea else { return false }
        return auxiliaryTopRightArea.width > 0 && auxiliaryTopRightArea.minX > 0
    }

    static func isOwnStatusItem(_ app: RunningApp) -> Bool {
        AppIdentity.isProductionBundle(app.bundleId) || AppIdentity.isDevelopmentBundle(app.bundleId)
    }

    static func isExcludedFromOverflow(_ app: RunningApp) -> Bool {
        app.isUnmovableSystemItem || isOwnStatusItem(app)
    }

    static func itemMidX(_ app: RunningApp) -> CGFloat? {
        app.preferredCenterX
    }

    static func isVisibleOverflow(_ app: RunningApp, notchRightSafeMinX: CGFloat) -> Bool {
        guard !isExcludedFromOverflow(app), let midX = itemMidX(app) else { return false }
        return midX < notchRightSafeMinX
    }

    static func visibleOverflow(
        classified: SearchClassifiedApps,
        notchRightSafeMinX: CGFloat?
    ) -> [RunningApp] {
        guard let notchRightSafeMinX, notchRightSafeMinX > 0 else { return [] }
        return classified.visible.filter { isVisibleOverflow($0, notchRightSafeMinX: notchRightSafeMinX) }
    }

    static func separatorPreferredPosition(
        screenWidth: CGFloat,
        notchRightSafeMinX: CGFloat
    ) -> Double {
        let separatorX = notchRightSafeMinX + separatorInset
        return max(10, Double(screenWidth - separatorX))
    }

    static func needsLiveMeasure(classified: SearchClassifiedApps) -> Bool {
        if classified.visible.isEmpty,
           classified.hidden.isEmpty,
           classified.alwaysHidden.isEmpty {
            return true
        }
        return classified.visible.contains { app in
            !isExcludedFromOverflow(app) && itemMidX(app) == nil
        }
    }

    static func shouldApply(
        settingsOn: Bool,
        isNotched: Bool,
        overflow: [RunningApp],
        recoveryInProgress: Bool
    ) -> Bool {
        settingsOn && isNotched && !overflow.isEmpty && !recoveryInProgress
    }

    static func needsSeparatorMove(
        currentPreferred: Double?,
        target: Double,
        slack: Double = 8
    ) -> Bool {
        guard let currentPreferred, currentPreferred.isFinite else { return true }
        return abs(currentPreferred - target) > slack
    }
}
