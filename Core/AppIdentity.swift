import Foundation

/// Single source for customer-facing product identity.
/// Internal type names stay `SaneBar*` so the move/zone kernel does not rename.
enum AppIdentity {
    static let displayName = "HaoBar"
    static let productionBundleId = "com.haobar.app"
    static let developmentBundleId = "com.haobar.dev"
    static let urlScheme = "haobar"
    static let persistenceFolder = "HaoBar"
    static let logSubsystem = "com.haobar.app"
    static let githubOwner = "skvdhshuk-blip"
    static let githubRepo = "hao-bar"
    static let copyrightHolders = "HaoBar contributors. Original SaneBar © 2025–2026 SaneApps."

    static var githubURL: URL {
        URL(string: "https://github.com/\(githubOwner)/\(githubRepo)")!
    }

    static var privacyPolicyURL: URL {
        URL(string: "https://\(githubOwner).github.io/\(githubRepo)/privacy.html")!
    }

    static var supportURL: URL { githubURL }

    static func isProductionBundle(_ bundleId: String?) -> Bool {
        bundleId == productionBundleId
    }

    static func isDevelopmentBundle(_ bundleId: String?) -> Bool {
        bundleId == developmentBundleId
    }

    /// Display name of the running process.
    static func runningDisplayName(bundle: Bundle = .main) -> String {
        let name = bundle.object(forInfoDictionaryKey: "CFBundleDisplayName") as? String
        if let name, !name.isEmpty {
            return name
        }
        return displayName
    }

    /// Bundle id of the running process so TCC rows can be matched exactly.
    static func runningBundleIdentifier(bundle: Bundle = .main) -> String {
        bundle.bundleIdentifier ?? productionBundleId
    }

    /// Visible identity, e.g. `HaoBar (com.haobar.app)`.
    static func runningIdentityLabel(bundle: Bundle = .main) -> String {
        "\(runningDisplayName(bundle: bundle)) (\(runningBundleIdentifier(bundle: bundle)))"
    }

    /// Customer-facing version line, e.g. `Version 1.0.0 (100)`.
    static func versionLine(bundle: Bundle = .main) -> String {
        let version: String
        if let raw = bundle.infoDictionary?["CFBundleShortVersionString"] as? String, !raw.isEmpty {
            version = raw
        } else {
            version = "1.0.0"
        }
        if let build = bundle.infoDictionary?["CFBundleVersion"] as? String, !build.isEmpty {
            return String(localized: "Version \(version) (\(build))")
        }
        return String(localized: "Version \(version)")
    }
}
