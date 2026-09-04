import SaneUI
import SwiftUI

struct ImportPreviewSheet: View {
    let plan: SaneBarImportPreviewPlan
    let onCancel: () -> Void
    let onImport: () -> Void

    private var hasRuleDetails: Bool {
        plan.hideAllOtherItems ||
            !plan.showItemIds.isEmpty ||
            !plan.hideItemIds.isEmpty ||
            !plan.alwaysHideItemIds.isEmpty
    }

    private var enablesScriptTrigger: Bool {
        plan.behavioralSettings.contains { $0.localizedCaseInsensitiveContains("script trigger") }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 24) {
            CompactSection(String(localized: "Import Settings")) {
                CompactRow(String(localized: "Source")) {
                    Text("\(plan.sourceKind.rawValue): \(plan.fileName)")
                        .lineLimit(2)
                        .multilineTextAlignment(.trailing)
                }

                if hasRuleDetails {
                    CompactDivider()
                    CompactRow(String(localized: "Show")) { Text(String(localized: "\(plan.showItemIds.count) items")) }
                    CompactDivider()
                    CompactRow(String(localized: "Hide")) { Text(String(localized: "\(plan.hideItemIds.count) items")) }
                    CompactDivider()
                    CompactRow(String(localized: "Always Hide")) { Text(String(localized: "\(plan.alwaysHideItemIds.count) items")) }
                    CompactDivider()
                    CompactRow(String(localized: "All Others")) { Text(plan.hideAllOtherItems ? String(localized: "On") : String(localized: "Off")) }
                } else {
                    CompactDivider()
                    CompactRow(String(localized: "Profile rules")) { Text(String(localized: "No visibility rules")) }
                }

                if plan.savedProfileCount > 0 {
                    CompactDivider()
                    CompactRow(String(localized: "Saved profiles")) { Text("\(plan.savedProfileCount)") }
                }
                if plan.includesLayoutSnapshot {
                    CompactDivider()
                    CompactRow(String(localized: "Layout snapshot")) { Text(String(localized: "Included")) }
                }
                if plan.includesCustomIconSnapshot {
                    CompactDivider()
                    CompactRow(String(localized: "Custom icon")) { Text(String(localized: "Included")) }
                }
                if !plan.behavioralSettings.isEmpty {
                    CompactDivider()
                    CompactRow(String(localized: "Settings")) { Text(String(localized: "\(plan.behavioralSettings.count) changes")) }
                }
                if !plan.missingItemIds.isEmpty {
                    CompactDivider()
                    CompactRow(String(localized: "Missing items")) { Text("\(plan.missingItemIds.count)") }
                }
                if !plan.skippedItemIds.isEmpty {
                    CompactDivider()
                    CompactRow(String(localized: "Skipped items")) { Text("\(plan.skippedItemIds.count)") }
                }

                if plan.hideAllOtherItems {
                    SettingsInlineHelp(String(localized: "This import will keep the shown items visible and hide newly detected menu bar items by default."))
                }
                if enablesScriptTrigger {
                    SettingsInlineHelp(String(localized: "This import enables script-based control. Only import files you trust."))
                }
            }

            CompactRow(String(localized: "Actions")) {
                HStack(spacing: 8) {
                    Button("Cancel", action: onCancel)
                        .buttonStyle(ChromeActionButtonStyle())
                    Button("Import", action: onImport)
                        .buttonStyle(ChromeActionButtonStyle(prominent: true))
                        .keyboardShortcut(.defaultAction)
                }
                .fixedSize(horizontal: true, vertical: false)
            }
        }
        .padding(SaneSettingsChrome.gutter)
        .frame(width: 420)
        .background {
            SaneGradientBackground(style: .panel)
        }
    }
}
