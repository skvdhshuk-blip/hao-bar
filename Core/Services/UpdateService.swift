import AppKit
import Foundation
import os.log

private let logger = Logger(subsystem: AppIdentity.logSubsystem, category: "UpdateService")

enum UpdateCheckFrequency: String, CaseIterable, Identifiable {
    case daily
    case weekly

    var id: String { rawValue }

    var title: String {
        switch self {
        case .daily: String(localized: "Daily")
        case .weekly: String(localized: "Weekly")
        }
    }

    var interval: TimeInterval {
        switch self {
        case .daily: 60 * 60 * 24
        case .weekly: 60 * 60 * 24 * 7
        }
    }

    static func resolve(updateCheckInterval: TimeInterval) -> Self {
        let threshold = (Self.daily.interval + Self.weekly.interval) / 2
        return updateCheckInterval >= threshold ? .weekly : .daily
    }

    static func normalizedInterval(from updateCheckInterval: TimeInterval) -> TimeInterval {
        resolve(updateCheckInterval: updateCheckInterval).interval
    }
}

/// App Store builds update through the store. Sparkle is not shipped.
@MainActor
class UpdateService: NSObject, ObservableObject {
    nonisolated static let releaseBundleIdentifier = AppIdentity.productionBundleId
    nonisolated static let scheduledUpdateReminderNotificationID = "com.haobar.app.scheduled-update"

    override init() {
        super.init()
        logger.info("In-app updater disabled; HaoBar updates through the Mac App Store")
    }

    func checkForUpdates() {
        NSSound.beep()
    }

    var automaticallyChecksForUpdates: Bool {
        get { false }
        set { _ = newValue }
    }

    var updateCheckFrequency: UpdateCheckFrequency {
        get { .daily }
        set { _ = newValue }
    }

    var isUpdateChannelEnabled: Bool { AppCapability.sparkleUpdates }

    nonisolated static func supportsSparkleUpdates(bundleIdentifier _: String?) -> Bool {
        false
    }

    nonisolated static func shouldShowScheduledUpdateDockBadge(showDockIcon _: Bool) -> Bool {
        false
    }
}
