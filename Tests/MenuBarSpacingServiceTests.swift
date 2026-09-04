import Testing
@testable import SaneBar

@MainActor
@Suite("MenuBarSpacingService")
struct MenuBarSpacingServiceTests {
    @Test("MAS capability keeps spacing writes off")
    func capabilityDisablesWrites() {
        #expect(AppCapability.menuBarSpacing == false)
    }

    @Test("Setting spacing is a no-op when the capability is off")
    func setSpacingNoOp() throws {
        try MenuBarSpacingService.shared.setSpacing(6)
        #expect(MenuBarSpacingService.shared.currentSpacing() == nil)
    }

    @Test("Out of range values do not throw when the capability is off")
    func setSpacingOutOfRangeNoOp() throws {
        try MenuBarSpacingService.shared.setSpacing(0)
        try MenuBarSpacingService.shared.setSpacing(11)
        try MenuBarSpacingService.shared.setSelectionPadding(0)
        try MenuBarSpacingService.shared.setSelectionPadding(11)
    }

    @Test("Value out of range error has descriptive message")
    func errorMessageDescriptive() {
        let error = MenuBarSpacingError.valueOutOfRange(15)
        #expect(error.localizedDescription.contains("15"))
        #expect(error.localizedDescription.contains("1-10"))
    }

    @Test("Graceful refresh does not throw")
    func gracefulRefreshNoThrow() {
        MenuBarSpacingService.shared.attemptGracefulRefresh()
    }
}
