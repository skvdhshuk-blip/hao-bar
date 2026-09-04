import AppKit
import KeyboardShortcuts
import SaneUI
import SwiftUI

struct ShortcutsSettingsView: View {
    private struct AutomationCommand: Identifiable {
        let id: String
        let title: String
        let command: String
    }

    @ObservedObject private var licenseService = LicenseService.shared
    @State private var proUpsellFeature: ProFeature?
    @State private var copiedAutomationCommandID: String?
    private let automationCommands: [AutomationCommand] = [
        .init(
            id: "toggle",
            title: "Toggle hidden icons",
            command: "open \"\(AppIdentity.urlScheme)://toggle\""
        ),
        .init(
            id: "show",
            title: "Show hidden icons",
            command: "open \"\(AppIdentity.urlScheme)://show\""
        ),
        .init(
            id: "hide",
            title: "Hide icons",
            command: "open \"\(AppIdentity.urlScheme)://hide\""
        ),
        .init(
            id: "search",
            title: "Open search",
            command: "open \"\(AppIdentity.urlScheme)://search\""
        ),
        .init(
            id: "search-query",
            title: "Search text",
            command: "open \"\(AppIdentity.urlScheme)://search?q=wifi\""
        ),
        .init(
            id: "settings",
            title: "Open settings",
            command: "open \"\(AppIdentity.urlScheme)://settings\""
        ),
        .init(
            id: "health",
            title: "Open health",
            command: "open \"\(AppIdentity.urlScheme)://health\""
        ),
        .init(
            id: "applescript-toggle",
            title: "AppleScript toggle",
            command: "osascript -e 'tell application \"\(AppIdentity.displayName)\" to toggle'"
        ),
        .init(
            id: "applescript-search",
            title: "AppleScript search",
            command: "osascript -e 'tell application \"\(AppIdentity.displayName)\" to quick search \"wifi\"'"
        ),
        .init(
            id: "applescript-move-before",
            title: "AppleScript move before",
            command: "osascript -e 'tell application \"\(AppIdentity.displayName)\" to move icon before \"SOURCE_ID\" target icon \"TARGET_ID\"'"
        ),
        .init(
            id: "applescript-move-after",
            title: "AppleScript move after",
            command: "osascript -e 'tell application \"\(AppIdentity.displayName)\" to move icon after \"SOURCE_ID\" target icon \"TARGET_ID\"'"
        )
    ]

    var body: some View {
        SaneSettingsPage {
                CompactSection("Global Hotkeys") {
                    CompactRow("Browse Icons") {
                        KeyboardShortcuts.Recorder(for: .searchMenuBar)
                            .fixedSize()
                            .help("Open the icon panel or second menu bar")
                    }
                    CompactDivider()
                    CompactRow("Show / Hide icons") {
                        KeyboardShortcuts.Recorder(for: .toggleHiddenItems)
                            .fixedSize()
                            .help("Toggle hidden icons visible or hidden")
                    }

                    if licenseService.isPro {
                        CompactDivider()
                        CompactRow("Show icons") {
                            KeyboardShortcuts.Recorder(for: .showHiddenItems)
                                .fixedSize()
                                .help("Reveal hidden menu bar icons")
                        }
                        CompactDivider()
                        CompactRow("Hide icons") {
                            KeyboardShortcuts.Recorder(for: .hideItems)
                                .fixedSize()
                                .help("Hide menu bar icons again")
                        }
                        CompactDivider()
                        CompactRow("Open Settings") {
                            KeyboardShortcuts.Recorder(for: .openSettings)
                                .fixedSize()
                                .help("Open the HaoBar settings window")
                        }
                    } else {
                        CompactDivider()
                        proLockedRow(feature: .additionalShortcuts, label: "Show icons")
                        CompactDivider()
                        proLockedRow(feature: .additionalShortcuts, label: "Hide icons")
                        CompactDivider()
                        proLockedRow(feature: .additionalShortcuts, label: "Open Settings")
                    }
                }

                // 2. Automation — Pro
                CompactSection("Automation") {
                    ForEach(Array(automationCommands.enumerated()), id: \.element.id) { index, item in
                        if licenseService.isPro {
                            CompactRow(item.title) {
                                ActionButton(
                                    copiedAutomationCommandID == item.id ? "Copied" : "Copy",
                                    icon: copiedAutomationCommandID == item.id ? "checkmark" : "doc.on.doc",
                                    style: copiedAutomationCommandID == item.id ? .primary : .secondary
                                ) {
                                    copyToClipboard(item)
                                }
                                .help("Copy command to clipboard")
                            }
                            SaneInlineHelp(item.command)
                        } else {
                            proGatedRow(feature: .appleScript, label: item.title)
                            SaneInlineHelp(item.command)
                        }

                        if index < automationCommands.count - 1 {
                            CompactDivider()
                        }
                    }
                }

                CompactSection("App Shortcuts") {
                    if licenseService.isPro {
                        CompactRow("Actions") {
                            HStack(spacing: 8) {
                                StatusBadge("Toggle", color: .cyan, icon: "line.3.horizontal.decrease")
                                StatusBadge("Profiles", color: .green, icon: "rectangle.stack")
                                StatusBadge("Search", color: .blue, icon: "magnifyingglass")
                            }
                        }
                    } else {
                        proLockedRow(feature: .appleScript, label: "Toggle action")
                        CompactDivider()
                        proLockedRow(feature: .appleScript, label: "Profiles actions")
                        CompactDivider()
                        proLockedRow(feature: .appleScript, label: "Search action")
                    }
                }
        }
        .sheet(item: $proUpsellFeature) { feature in
            ProUpsellView(feature: feature)
        }
    }

    // MARK: - Pro Gating Helper

    private func proGatedRow(feature: ProFeature, label: String) -> some View {
        CompactRow(label) {
            Button {
                proUpsellFeature = feature
            } label: {
                ChromeBadge(title: "Pro", systemImage: "lock.fill")
            }
            .buttonStyle(.plain)
        }
    }

    private func proLockedRow(feature: ProFeature, label: String) -> some View {
        proGatedRow(feature: feature, label: label)
    }

    private func copyToClipboard(_ command: AutomationCommand) {
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(command.command, forType: .string)
        copiedAutomationCommandID = command.id

        Task { @MainActor in
            try? await Task.sleep(for: .seconds(1.2))
            if copiedAutomationCommandID == command.id {
                copiedAutomationCommandID = nil
            }
        }
    }
}
