import Testing
@testable import SaneBar

@Suite("Browse panel icon move menu")
struct BrowsePanelIconMoveMenuTests {
    @Test("All-tab Visible icon offers Move to Hidden, not Move to Visible")
    func allTabVisibleOffersHide() {
        let destinations = BrowsePanelIconMoveMenu.destinations(
            zone: .visible,
            alwaysHiddenEnabled: true
        )

        #expect(destinations.toHidden)
        #expect(!destinations.toVisible)
        #expect(destinations.toAlwaysHidden)
        #expect(BrowsePanelIconMoveMenu.sourceZone(mode: .all, resolvedZone: .visible) == .visible)
    }

    @Test("All-tab Hidden icon does not offer Move to Hidden")
    func allTabHiddenDoesNotOfferHide() {
        let destinations = BrowsePanelIconMoveMenu.destinations(
            zone: .hidden,
            alwaysHiddenEnabled: true
        )

        #expect(!destinations.toHidden)
        #expect(destinations.toVisible)
        #expect(BrowsePanelIconMoveMenu.sourceZone(mode: .all, resolvedZone: .hidden) == .hidden)
    }

    @Test("All-tab Always Hidden icon offers Move to Hidden from the live AH zone")
    func allTabAlwaysHiddenOffersHideFromAlwaysHidden() {
        let destinations = BrowsePanelIconMoveMenu.destinations(
            zone: .alwaysHidden,
            alwaysHiddenEnabled: true
        )

        #expect(destinations.toHidden)
        #expect(destinations.toVisible)
        #expect(!destinations.toAlwaysHidden)
        #expect(BrowsePanelIconMoveMenu.sourceZone(mode: .all, resolvedZone: .alwaysHidden) == .alwaysHidden)
    }

    @Test("Hidden tab treats the tab as the source zone")
    func hiddenTabSourceIsHidden() {
        #expect(BrowsePanelIconMoveMenu.sourceZone(mode: .hidden, resolvedZone: .visible) == .hidden)
    }

    @Test("A destination that is already current must not get an upsell stand-in")
    func gatedActionIsNilWhenDestinationUnavailable() {
        var invoked = false
        let action = BrowsePanelIconMoveMenu.gatedAction(
            allowed: false,
            isPro: false,
            perform: { invoked = true },
            upsell: { invoked = true }
        )

        #expect(action == nil)
        #expect(!invoked)
    }
}
