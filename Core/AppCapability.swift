import Foundation

/// One capability box for MAS-safe HaoBar.
/// Features that cannot ship in the sandbox stay off in every configuration
/// so Debug matches the store build.
enum AppCapability {
    static var isAppStoreBuild: Bool {
        #if APP_STORE
            true
        #else
            false
        #endif
    }

    static var menuBarSpacing: Bool { false }
    static var focusModeFiles: Bool { false }
    static var wifiSSID: Bool { false }
    static var scriptTrigger: Bool { false }
    static var sparkleUpdates: Bool { false }

    static var simulatedDrag: Bool {
        SimulatedDragState.shared.isEnabled
    }

    static func disableSimulatedDrag() {
        SimulatedDragState.shared.disable()
    }

    static var simulatedDragFallbackMessage: String {
        String(localized: "HaoBar couldn’t move that icon in the sandbox. ⌘-drag it in the menu bar instead.")
    }
}

private final class SimulatedDragState: @unchecked Sendable {
    static let shared = SimulatedDragState()
    private let lock = NSLock()
    private var enabled = true

    var isEnabled: Bool {
        lock.lock()
        defer { lock.unlock() }
        return enabled
    }

    func disable() {
        lock.lock()
        enabled = false
        lock.unlock()
    }
}
