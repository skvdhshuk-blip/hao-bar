import AppKit
import SwiftUI

// MARK: - Zone Classification, Action Factories & Keyboard Navigation

extension MenuBarSearchView {
    // MARK: - Zone Classification (for All tab context menus)

    /// Classify an app's current zone for the All tab. Delegates to
    /// `BrowsePanelZoneClassifier.zoneForAllTab`, which prefers the authoritative
    /// cached classification over (off-screen-fragile) separator geometry.
    func appZone(for app: RunningApp) -> AppZone {
        BrowsePanelZoneClassifier.zoneForAllTab(
            app: app,
            context: BrowsePanelZoneClassifier.AllTabContext(
                classified: service.cachedClassifiedApps(),
                pinnedIds: Set(menuBarManager.settings.alwaysHiddenPinnedItemIds),
                allApps: service.cachedMenuBarApps(),
                separatorRightEdgeX: menuBarManager.geometryResolver.separatorRightEdgeX(),
                separatorOriginX: menuBarManager.geometryResolver.separatorOriginX(),
                alwaysHiddenBoundaryX: menuBarManager.geometryResolver.alwaysHiddenSeparatorBoundaryX(),
                alwaysHiddenOriginX: menuBarManager.geometryResolver.alwaysHiddenSeparatorOriginX()
            )
        )
    }

    // MARK: - Action Factories

    func sourceZone(for app: RunningApp) -> AppZone {
        BrowsePanelIconMoveMenu.sourceZone(mode: mode, resolvedZone: appZone(for: app))
    }

    func makeMoveToVisibleAction(for app: RunningApp) -> (() -> Void)? {
        guard BrowsePanelIconMoveMenu.destinations(
            zone: sourceZone(for: app),
            alwaysHiddenEnabled: isAlwaysHiddenEnabled
        ).toVisible else { return nil }

        return {
            let source = self.sourceZone(for: app)
            guard source != .visible else { return }
            _ = self.queueMoveAfterDrop(app, from: source, to: .visible)
        }
    }

    func makeMoveToHiddenAction(for app: RunningApp) -> (() -> Void)? {
        guard BrowsePanelIconMoveMenu.destinations(
            zone: sourceZone(for: app),
            alwaysHiddenEnabled: isAlwaysHiddenEnabled
        ).toHidden else { return nil }

        return {
            let source = self.sourceZone(for: app)
            guard source != .hidden else { return }
            _ = self.queueMoveAfterDrop(app, from: source, to: .hidden)
        }
    }

    func makeMoveToAlwaysHiddenAction(for app: RunningApp) -> (() -> Void)? {
        guard BrowsePanelIconMoveMenu.destinations(
            zone: sourceZone(for: app),
            alwaysHiddenEnabled: isAlwaysHiddenEnabled
        ).toAlwaysHidden else { return nil }

        return {
            let source = self.sourceZone(for: app)
            guard source != .alwaysHidden else { return }
            _ = self.queueMoveAfterDrop(app, from: source, to: .alwaysHidden)
        }
    }

    private func queueMoveAfterDrop(_ app: RunningApp, from sourceZone: AppZone, to targetZone: AppZone) -> Bool {
        BrowsePanelMoveQueue.queueMoveAfterDrop(
            app: app,
            from: sourceZone,
            to: targetZone,
            context: moveContext
        )
    }

    private func queueReorderAfterDrop(_ sourceApp: RunningApp, targetApp: RunningApp) -> Bool {
        BrowsePanelMoveQueue.queueReorderAfterDrop(
            sourceApp: sourceApp,
            targetApp: targetApp,
            context: moveContext
        )
    }

    private var moveContext: BrowsePanelMoveContext {
        BrowsePanelMoveContext(
            isAlwaysHiddenEnabled: isAlwaysHiddenEnabled,
            manager: menuBarManager,
            setMovingAppID: {
                movingAppId = $0
                // A fresh in-flight move clears any stale failure marker so a
                // retry doesn't keep showing the previous failure affordance.
                if $0 != nil { lastFailedMoveAppId = nil }
            },
            recordFailedMove: { lastFailedMoveAppId = $0 }
        )
    }

    @MainActor
    func activateApp(_ app: RunningApp, isRightClick: Bool = false) {
        Task { @MainActor in
            await service.activate(app: app, isRightClick: isRightClick, origin: .browsePanel)
        }
    }

    func handleGridReorderDrop(_ payloads: [String], targetApp: RunningApp) -> Bool {
        if let feature = BrowsePanelRestrictedAction.upsellFeature(for: .zoneMove, isPro: LicenseService.shared.isPro) {
            proUpsellFeature = feature
            return false
        }

        guard let sourceID = payloads.first else { return false }
        guard sourceID != targetApp.uniqueId else { return false }
        guard let sourceApp = filteredApps.first(where: { $0.uniqueId == sourceID }) else { return false }

        return queueReorderAfterDrop(sourceApp, targetApp: targetApp)
    }

    func handleZoneDrop(_ payloads: [String], targetMode: Mode) -> Bool {
        guard LicenseService.shared.isPro else {
            proUpsellFeature = .zoneMoves
            return false
        }

        guard let sourceID = payloads.first else { return false }

        // Pull from the shared cache so zone drops work regardless of current tab.
        let classified = service.cachedClassifiedApps()
        guard let source = BrowsePanelDropResolver.sourceForDropPayload(
            sourceID,
            classified: classified,
            filteredApps: filteredApps,
            mode: mode,
            zoneForAllMode: { app in self.appZone(for: app) }
        ) else {
            return false
        }

        let sourceApp = source.app
        let sourceZone = source.zone

        switch targetMode {
        case .visible:
            return queueMoveAfterDrop(sourceApp, from: sourceZone, to: .visible)
        case .hidden:
            return queueMoveAfterDrop(sourceApp, from: sourceZone, to: .hidden)
        case .alwaysHidden:
            return queueMoveAfterDrop(sourceApp, from: sourceZone, to: .alwaysHidden)
        case .all:
            return false
        }
    }

    // MARK: - Keyboard Navigation

    /// Whether keyboard navigation should be active (not when modals are open)
    var isKeyboardNavigationActive: Bool {
        hotkeyApp == nil && proUpsellFeature == nil
    }

    func handleKeyPress(_ keyPress: KeyPress) -> KeyPress.Result {
        guard isKeyboardNavigationActive else {
            return .ignored
        }

        return BrowsePanelKeyboardNavigation.handleKeyPress(
            keyPress,
            context: BrowsePanelKeyboardNavigationContext(
                isSearchFieldFocused: isSearchFieldFocused,
                setSearchFieldFocused: { isSearchFieldFocused = $0 },
                selectedAppIndex: selectedAppIndex,
                setSelectedAppIndex: { selectedAppIndex = $0 },
                filteredApps: filteredApps,
                activate: { activateApp($0) },
                showSearchAndFocus: showSearchAndFocus
            )
        )
    }

    func showSearchAndFocus() {
        withAnimation(.easeInOut(duration: 0.12)) {
            isSearchVisible = true
        }
        // Delay focus slightly to ensure field is visible
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
            self.isSearchFieldFocused = true
        }
    }
}
