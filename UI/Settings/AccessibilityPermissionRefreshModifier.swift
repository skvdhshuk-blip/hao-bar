import AppKit
import SwiftUI

/// Re-reads Accessibility trust when a Health or onboarding surface appears
/// or when the user returns from System Settings.
struct AccessibilityPermissionRefreshModifier: ViewModifier {
    let service: AccessibilityService

    func body(content: Content) -> some View {
        content
            .onAppear {
                service.refreshPermissionStatus()
            }
            .onReceive(NotificationCenter.default.publisher(for: NSApplication.didBecomeActiveNotification)) { _ in
                service.refreshPermissionStatus()
            }
    }
}

extension View {
    func refreshAccessibilityPermission(using service: AccessibilityService) -> some View {
        modifier(AccessibilityPermissionRefreshModifier(service: service))
    }
}
