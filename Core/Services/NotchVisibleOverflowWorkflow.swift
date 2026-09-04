import AppKit
import Foundation
import os.log

private let logger = Logger(subsystem: AppIdentity.logSubsystem, category: "NotchVisibleOverflowWorkflow")

@MainActor
final class NotchVisibleOverflowWorkflow {
    nonisolated static let debounceSeconds: TimeInterval = 0.8

    private unowned let manager: MenuBarManager
    private var scheduledTask: Task<Void, Never>?
    private var lastAppliedAt: Date?

    init(manager: MenuBarManager) {
        self.manager = manager
    }

    nonisolated static func isRunningAutomatedTests(
        environment: [String: String] = ProcessInfo.processInfo.environment,
        isRunningTests: Bool = NSClassFromString("XCTestCase") != nil
    ) -> Bool {
        environment["XCTestConfigurationFilePath"] != nil || isRunningTests
    }

    nonisolated static func shouldSchedule(
        settingsOn: Bool,
        isNotched: Bool,
        overflowCount: Int,
        recoveryInProgress: Bool,
        isMenuOpen: Bool,
        isBrowseMoveInProgress: Bool,
        lastAppliedAt: Date?,
        now: Date,
        needsLiveMeasure: Bool = false
    ) -> Bool {
        guard settingsOn, isNotched, !recoveryInProgress else { return false }
        guard overflowCount > 0 || needsLiveMeasure else { return false }
        guard !isMenuOpen, !isBrowseMoveInProgress else { return false }
        if let lastAppliedAt, now.timeIntervalSince(lastAppliedAt) < debounceSeconds {
            return false
        }
        return true
    }

    func scheduleEvaluation() {
        guard !Self.isRunningAutomatedTests() else { return }
        scheduledTask?.cancel()
        scheduledTask = Task { @MainActor [weak self] in
            try? await Task.sleep(nanoseconds: UInt64(Self.debounceSeconds * 1_000_000_000))
            guard !Task.isCancelled else { return }
            await self?.evaluateNow()
        }
    }

    func evaluateNow() async {
        guard !Self.isRunningAutomatedTests() else { return }

        let screen = manager.currentRecoveryReferenceScreen() ?? NSScreen.main
        let safeArea = screen?.auxiliaryTopRightArea
        let isNotched = NotchVisibleOverflowPolicy.isNotchedScreen(auxiliaryTopRightArea: safeArea)
        let safeMinX = safeArea?.minX
        var classified = SearchService.shared.cachedClassifiedApps()
        var overflow = NotchVisibleOverflowPolicy.visibleOverflow(
            classified: classified,
            notchRightSafeMinX: safeMinX
        )
        let needsLiveMeasure = overflow.isEmpty
            && NotchVisibleOverflowPolicy.needsLiveMeasure(classified: classified)
        let browseMoveInProgress = SearchWindowController.shared.isMoveInProgress
        let now = Date()
        guard Self.shouldSchedule(
            settingsOn: manager.settings.keepVisibleIconsRightOfNotch,
            isNotched: isNotched,
            overflowCount: overflow.count,
            recoveryInProgress: manager.isExecutingStatusItemRecovery,
            isMenuOpen: manager.isMenuOpen,
            isBrowseMoveInProgress: browseMoveInProgress,
            lastAppliedAt: lastAppliedAt,
            now: now,
            needsLiveMeasure: needsLiveMeasure
        ) else {
            return
        }

        var didExpandForMeasure = false
        if overflow.isEmpty, needsLiveMeasure {
            if manager.hidingService.state == .hidden {
                await manager.hidingService.show()
                didExpandForMeasure = true
            }
            classified = await SearchService.shared.refreshClassifiedApps()
            overflow = NotchVisibleOverflowPolicy.visibleOverflow(
                classified: classified,
                notchRightSafeMinX: safeMinX
            )
            lastAppliedAt = now
        }

        guard NotchVisibleOverflowPolicy.shouldApply(
            settingsOn: manager.settings.keepVisibleIconsRightOfNotch,
            isNotched: isNotched,
            overflow: overflow,
            recoveryInProgress: manager.isExecutingStatusItemRecovery
        ) else {
            if didExpandForMeasure {
                await manager.hidingService.hide()
            }
            return
        }

        guard let screen, let safeMinX else {
            if didExpandForMeasure {
                await manager.hidingService.hide()
            }
            return
        }
        let target = NotchVisibleOverflowPolicy.separatorPreferredPosition(
            screenWidth: screen.frame.width,
            notchRightSafeMinX: safeMinX
        )
        let currentPreferred = StatusBarPositionDefaultsStore.resolvedPreferredPosition(
            forAutosaveName: StatusBarPositionStore.separatorAutosaveName
        )
        if NotchVisibleOverflowPolicy.needsSeparatorMove(
            currentPreferred: currentPreferred,
            target: target
        ) {
            logger.info(
                "Squeezing \(overflow.count, privacy: .public) visible icon(s) left of the notch into Hidden"
            )
            StatusBarPositionDefaultsStore.applyPreferredPosition(
                target,
                forAutosaveName: StatusBarPositionStore.separatorAutosaveName
            )
        } else {
            logger.info("Notch overflow already has a separator near the safe edge")
        }
        lastAppliedAt = now
        await manager.hidingService.hide()
    }
}
