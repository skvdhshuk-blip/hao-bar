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
        URL(string: "https://\(githubOwner).github.io/\(githubRepo)/")!
    }

    static var supportURL: URL { githubURL }

    static func isProductionBundle(_ bundleId: String?) -> Bool {
        bundleId == productionBundleId
    }

    static func isDevelopmentBundle(_ bundleId: String?) -> Bool {
        bundleId == developmentBundleId
    }
}
