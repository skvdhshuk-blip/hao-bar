import CoreGraphics
import Foundation
import Testing
@testable import SaneBar

struct NotchVisibleOverflowPolicyTests {
    private let safeMinX: CGFloat = 825
    private let screenWidth: CGFloat = 1470

    @Test("No notch means empty overflow and no apply")
    func noNotchMeansNoApply() {
        #expect(NotchVisibleOverflowPolicy.isNotchedScreen(auxiliaryTopRightArea: nil) == false)
        let overflow = NotchVisibleOverflowPolicy.visibleOverflow(
            classified: SearchClassifiedApps(
                visible: [RunningApp(id: "overflow.app", name: "Overflow", icon: nil, xPosition: 700, width: 24)],
                hidden: [],
                alwaysHidden: []
            ),
            notchRightSafeMinX: nil
        )
        #expect(overflow.isEmpty)
        #expect(
            NotchVisibleOverflowPolicy.shouldApply(
                settingsOn: true,
                isNotched: false,
                overflow: overflow,
                recoveryInProgress: false
            ) == false
        )
    }

    @Test("Visible icons left of the notch are overflow")
    func visibleIconsLeftOfNotchAreOverflow() {
        let overflowApp = RunningApp(id: "overflow.app", name: "Overflow", icon: nil, xPosition: 700, width: 24)
        let safeApp = RunningApp(id: "safe.app", name: "Safe", icon: nil, xPosition: 1100, width: 24)
        let overflow = NotchVisibleOverflowPolicy.visibleOverflow(
            classified: SearchClassifiedApps(
                visible: [overflowApp, safeApp],
                hidden: [],
                alwaysHidden: []
            ),
            notchRightSafeMinX: safeMinX
        )
        #expect(overflow.map(\.uniqueId) == [overflowApp.uniqueId])
        #expect(
            abs(
                NotchVisibleOverflowPolicy.separatorPreferredPosition(
                    screenWidth: screenWidth,
                    notchRightSafeMinX: safeMinX
                ) - Double(screenWidth - safeMinX)
            ) < 8
        )
        #expect(
            NotchVisibleOverflowPolicy.shouldApply(
                settingsOn: true,
                isNotched: true,
                overflow: overflow,
                recoveryInProgress: false
            )
        )
    }

    @Test("Icons already in the safe zone do not apply")
    func safeVisibleIconsDoNotApply() {
        let overflow = NotchVisibleOverflowPolicy.visibleOverflow(
            classified: SearchClassifiedApps(
                visible: [RunningApp(id: "safe.app", name: "Safe", icon: nil, xPosition: 1100, width: 24)],
                hidden: [],
                alwaysHidden: []
            ),
            notchRightSafeMinX: safeMinX
        )
        #expect(overflow.isEmpty)
        #expect(
            NotchVisibleOverflowPolicy.shouldApply(
                settingsOn: true,
                isNotched: true,
                overflow: overflow,
                recoveryInProgress: false
            ) == false
        )
    }

    @Test("System extras and HaoBar stay out of overflow")
    func systemExtrasAndHaoBarStayOut() {
        let clock = RunningApp.menuExtraItem(
            ownerBundleId: "com.apple.systemuiserver",
            name: "Clock",
            identifier: "com.apple.menuextra.clock",
            xPosition: 700,
            width: 40
        )
        let controlCenter = RunningApp.menuExtraItem(
            ownerBundleId: "com.apple.controlcenter",
            name: "Control Center",
            identifier: "com.apple.menuextra.controlcenter",
            xPosition: 680,
            width: 24
        )
        let haoBar = RunningApp(id: AppIdentity.productionBundleId, name: "HaoBar", icon: nil, xPosition: 710, width: 24)
        let overflow = NotchVisibleOverflowPolicy.visibleOverflow(
            classified: SearchClassifiedApps(
                visible: [clock, controlCenter, haoBar],
                hidden: [],
                alwaysHidden: []
            ),
            notchRightSafeMinX: safeMinX
        )
        #expect(overflow.isEmpty)
    }

    @Test("Disabled setting does not apply")
    func disabledSettingDoesNotApply() {
        let overflow = [
            RunningApp(id: "overflow.app", name: "Overflow", icon: nil, xPosition: 700, width: 24)
        ]
        #expect(
            NotchVisibleOverflowPolicy.shouldApply(
                settingsOn: false,
                isNotched: true,
                overflow: overflow,
                recoveryInProgress: false
            ) == false
        )
    }

    @Test("Recovery in progress does not apply")
    func recoveryBlocksApply() {
        let overflow = [
            RunningApp(id: "overflow.app", name: "Overflow", icon: nil, xPosition: 700, width: 24)
        ]
        #expect(
            NotchVisibleOverflowPolicy.shouldApply(
                settingsOn: true,
                isNotched: true,
                overflow: overflow,
                recoveryInProgress: true
            ) == false
        )
    }

    @Test("Always Hidden icons are ignored")
    func alwaysHiddenIconsAreIgnored() {
        let overflow = NotchVisibleOverflowPolicy.visibleOverflow(
            classified: SearchClassifiedApps(
                visible: [],
                hidden: [],
                alwaysHidden: [RunningApp(id: "always.app", name: "Always", icon: nil, xPosition: 400, width: 24)]
            ),
            notchRightSafeMinX: safeMinX
        )
        #expect(overflow.isEmpty)
    }

    @Test("Empty or unmeasured Visible icons need a live measure")
    func emptyOrUnmeasuredVisibleNeedsLiveMeasure() {
        #expect(
            NotchVisibleOverflowPolicy.needsLiveMeasure(
                classified: SearchClassifiedApps(visible: [], hidden: [], alwaysHidden: [])
            )
        )
        #expect(
            NotchVisibleOverflowPolicy.needsLiveMeasure(
                classified: SearchClassifiedApps(
                    visible: [RunningApp(id: "unknown.app", name: "Unknown", icon: nil)],
                    hidden: [],
                    alwaysHidden: []
                )
            )
        )
        #expect(
            NotchVisibleOverflowPolicy.needsLiveMeasure(
                classified: SearchClassifiedApps(
                    visible: [RunningApp(id: "safe.app", name: "Safe", icon: nil, xPosition: 1100, width: 24)],
                    hidden: [],
                    alwaysHidden: []
                )
            ) == false
        )
        #expect(
            NotchVisibleOverflowWorkflow.shouldSchedule(
                settingsOn: true,
                isNotched: true,
                overflowCount: 0,
                recoveryInProgress: false,
                isMenuOpen: false,
                isBrowseMoveInProgress: false,
                lastAppliedAt: nil,
                now: Date(),
                needsLiveMeasure: true
            )
        )
    }

    @Test("Workflow stand-down skips menu, browse move, and debounce")
    func workflowStandDown() {
        let now = Date()
        #expect(
            NotchVisibleOverflowWorkflow.shouldSchedule(
                settingsOn: true,
                isNotched: true,
                overflowCount: 1,
                recoveryInProgress: false,
                isMenuOpen: true,
                isBrowseMoveInProgress: false,
                lastAppliedAt: nil,
                now: now
            ) == false
        )
        #expect(
            NotchVisibleOverflowWorkflow.shouldSchedule(
                settingsOn: true,
                isNotched: true,
                overflowCount: 1,
                recoveryInProgress: false,
                isMenuOpen: false,
                isBrowseMoveInProgress: true,
                lastAppliedAt: nil,
                now: now
            ) == false
        )
        #expect(
            NotchVisibleOverflowWorkflow.shouldSchedule(
                settingsOn: true,
                isNotched: true,
                overflowCount: 1,
                recoveryInProgress: false,
                isMenuOpen: false,
                isBrowseMoveInProgress: false,
                lastAppliedAt: now.addingTimeInterval(-0.2),
                now: now
            ) == false
        )
        #expect(
            NotchVisibleOverflowWorkflow.shouldSchedule(
                settingsOn: true,
                isNotched: true,
                overflowCount: 1,
                recoveryInProgress: false,
                isMenuOpen: false,
                isBrowseMoveInProgress: false,
                lastAppliedAt: now.addingTimeInterval(-1.0),
                now: now
            )
        )
    }

    @Test("Separator rewrite is skipped when already near the target")
    func separatorRewriteUsesSlack() {
        #expect(
            NotchVisibleOverflowPolicy.needsSeparatorMove(
                currentPreferred: 645,
                target: 645,
                slack: 8
            ) == false
        )
        #expect(
            NotchVisibleOverflowPolicy.needsSeparatorMove(
                currentPreferred: 900,
                target: 645,
                slack: 8
            )
        )
    }
}
