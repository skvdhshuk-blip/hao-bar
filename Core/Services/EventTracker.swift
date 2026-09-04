import Foundation
import os.log

private let eventLogger = Logger(subsystem: AppIdentity.logSubsystem, category: "EventTracker")

/// Historical aggregate event helper. HaoBar does not send telemetry.
/// Payload builders stay for tests; `log` is a no-op.
enum EventTracker {
    static func log(_ event: String) async {
        await log(event, tier: nil, targetVersion: nil, targetBuild: nil)
    }

    static func log(
        _ event: String,
        tier: String? = nil,
        targetVersion: String? = nil,
        targetBuild: String? = nil
    ) async {
        eventLogger.debug("Telemetry disabled; dropped event: \(event, privacy: .public)")
        _ = (tier, targetVersion, targetBuild)
    }

    static func telemetryPayload(
        event: String,
        tier: String?,
        targetVersion: String?,
        targetBuild: String?,
        appVersion: String = appVersion(bundle: .main),
        build: String = buildVersion(bundle: .main),
        osVersion: String = osVersion(),
        channel: String = distributionChannel(bundle: .main)
    ) -> [String: String] {
        var payload = [
            "app": "haobar",
            "event": event,
            "app_version": appVersion,
            "build": build,
            "os_version": osVersion,
            "platform": "macos",
            "channel": channel
        ]

        if let resolvedTier = resolvedTier(explicitTier: tier, event: event) {
            payload["tier"] = resolvedTier
        }
        if let targetVersion, !targetVersion.isEmpty {
            payload["target_version"] = targetVersion
        }
        if let targetBuild, !targetBuild.isEmpty {
            payload["target_build"] = targetBuild
        }

        return payload
    }

    static func queryItems(for payload: [String: String]) -> [URLQueryItem] {
        payload
            .sorted { $0.key < $1.key }
            .map { URLQueryItem(name: $0.key, value: $0.value) }
    }

    static func appVersion(bundle: Bundle) -> String {
        (bundle.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String)?
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .nonEmpty ?? "unknown"
    }

    static func buildVersion(bundle: Bundle) -> String {
        (bundle.object(forInfoDictionaryKey: "CFBundleVersion") as? String)?
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .nonEmpty ?? "unknown"
    }

    static func osVersion() -> String {
        let version = ProcessInfo.processInfo.operatingSystemVersion
        return "\(version.majorVersion).\(version.minorVersion).\(version.patchVersion)"
    }

    static func distributionChannel(bundle _: Bundle) -> String {
        "app_store"
    }

    static func resolvedTier(explicitTier: String?, event: String) -> String? {
        if let explicitTier = explicitTier?.trimmingCharacters(in: .whitespacesAndNewlines).lowercased(),
           !explicitTier.isEmpty {
            return explicitTier
        }

        switch event {
        case "license_activated":
            return "pro"
        case "new_free_user":
            return "free"
        default:
            if event.hasSuffix("_pro") {
                return "pro"
            }
            if event.hasSuffix("_free") {
                return "free"
            }
            return nil
        }
    }
}

private extension String {
    var nonEmpty: String? {
        isEmpty ? nil : self
    }
}
