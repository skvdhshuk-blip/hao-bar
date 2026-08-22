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
            CompactSection("Import Settings") {
                CompactRow("Source") {
                    Text("\(plan.sourceKind.rawValue): \(plan.fileName)")
                        .lineLimit(2)
                        .multilineTextAlignment(.trailing)
                }

                if hasRuleDetails {
                    CompactDivider()
                    CompactRow("Show") { Text("\(plan.showItemIds.count) items") }
                    CompactDivider()
                    CompactRow("Hide") { Text("\(plan.hideItemIds.count) items") }
                    CompactDivider()
                    CompactRow("Always Hide") { Text("\(plan.alwaysHideItemIds.count) items") }
                    CompactDivider()
                    CompactRow("All Others") { Text(plan.hideAllOtherItems ? "On" : "Off") }
                } else {
                    CompactDivider()
                    CompactRow("Profile rules") { Text("No visibility rules") }
                }

                if plan.savedProfileCount > 0 {
                    CompactDivider()
                    CompactRow("Saved profiles") { Text("\(plan.savedProfileCount)") }
                }
                if plan.includesLayoutSnapshot {
                    CompactDivider()
                    CompactRow("Layout snapshot") { Text("Included") }
                }
                if plan.includesCustomIconSnapshot {
                    CompactDivider()
                    CompactRow("Custom icon") { Text("Included") }
                }
                if !plan.behavioralSettings.isEmpty {
                    CompactDivider()
                    CompactRow("Settings") { Text("\(plan.behavioralSettings.count) changes") }
                }
                if !plan.missingItemIds.isEmpty {
                    CompactDivider()
                    CompactRow("Missing items") { Text("\(plan.missingItemIds.count)") }
                }
                if !plan.skippedItemIds.isEmpty {
                    CompactDivider()
                    CompactRow("Skipped items") { Text("\(plan.skippedItemIds.count)") }
                }

                if plan.hideAllOtherItems {
                    SaneInlineHelp("This import will keep the shown items visible and hide newly detected menu bar items by default.")
                }
                if enablesScriptTrigger {
                    SaneInlineHelp("This import enables script-based control. Only import files you trust.")
                }
            }

            CompactRow("Actions") {
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
