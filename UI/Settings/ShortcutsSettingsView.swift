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
            title: String(localized: "Toggle hidden icons"),
            command: "open \"\(AppIdentity.urlScheme)://toggle\""
        ),
        .init(
            id: "show",
            title: String(localized: "Show hidden icons"),
            command: "open \"\(AppIdentity.urlScheme)://show\""
        ),
        .init(
            id: "hide",
            title: String(localized: "Hide icons"),
            command: "open \"\(AppIdentity.urlScheme)://hide\""
        ),
        .init(
            id: "search",
            title: String(localized: "Open search"),
            command: "open \"\(AppIdentity.urlScheme)://search\""
        ),
        .init(
            id: "search-query",
            title: String(localized: "Search text"),
            command: "open \"\(AppIdentity.urlScheme)://search?q=wifi\""
        ),
        .init(
            id: "settings",
            title: String(localized: "Open settings"),
            command: "open \"\(AppIdentity.urlScheme)://settings\""
        ),
        .init(
            id: "health",
            title: String(localized: "Open health"),
            command: "open \"\(AppIdentity.urlScheme)://health\""
        ),
        .init(
            id: "applescript-toggle",
            title: String(localized: "AppleScript toggle"),
            command: "osascript -e 'tell application \"\(AppIdentity.displayName)\" to toggle'"
        ),
        .init(
            id: "applescript-search",
            title: String(localized: "AppleScript search"),
            command: "osascript -e 'tell application \"\(AppIdentity.displayName)\" to quick search \"wifi\"'"
        ),
        .init(
            id: "applescript-move-before",
            title: String(localized: "AppleScript move before"),
            command: "osascript -e 'tell application \"\(AppIdentity.displayName)\" to move icon before \"SOURCE_ID\" target icon \"TARGET_ID\"'"
        ),
        .init(
            id: "applescript-move-after",
            title: String(localized: "AppleScript move after"),
            command: "osascript -e 'tell application \"\(AppIdentity.displayName)\" to move icon after \"SOURCE_ID\" target icon \"TARGET_ID\"'"
        )
    ]

    var body: some View {
        SaneSettingsPage {
                CompactSection(String(localized: "Global Hotkeys")) {
                    CompactRow(String(localized: "Browse Icons")) {
                        KeyboardShortcuts.Recorder(for: .searchMenuBar)
                            .fixedSize()
                            .help("Open the icon panel or second menu bar")
                    }
                    CompactDivider()
                    CompactRow(String(localized: "Show / Hide icons")) {
                        KeyboardShortcuts.Recorder(for: .toggleHiddenItems)
                            .fixedSize()
                            .help("Toggle hidden icons visible or hidden")
                    }

                    if licenseService.isPro {
                        CompactDivider()
                        CompactRow(String(localized: "Show icons")) {
                            KeyboardShortcuts.Recorder(for: .showHiddenItems)
                                .fixedSize()
                                .help("Reveal hidden menu bar icons")
                        }
                        CompactDivider()
                        CompactRow(String(localized: "Hide icons")) {
                            KeyboardShortcuts.Recorder(for: .hideItems)
                                .fixedSize()
                                .help("Hide menu bar icons again")
                        }
                        CompactDivider()
                        CompactRow(String(localized: "Open Settings")) {
                            KeyboardShortcuts.Recorder(for: .openSettings)
                                .fixedSize()
                                .help("Open the HaoBar settings window")
                        }
                    } else {
                        CompactDivider()
                        proLockedRow(feature: .additionalShortcuts, label: String(localized: "Show icons"))
                        CompactDivider()
                        proLockedRow(feature: .additionalShortcuts, label: String(localized: "Hide icons"))
                        CompactDivider()
                        proLockedRow(feature: .additionalShortcuts, label: String(localized: "Open Settings"))
                    }
                }

                // 2. Automation — Pro
                CompactSection(String(localized: "Automation")) {
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

                CompactSection(String(localized: "App Shortcuts")) {
                    if licenseService.isPro {
                        CompactRow(String(localized: "Actions")) {
                            HStack(spacing: 8) {
                                StatusBadge(String(localized: "Toggle"), color: .cyan, icon: "line.3.horizontal.decrease")
                                StatusBadge(String(localized: "Profiles"), color: .green, icon: "rectangle.stack")
                                StatusBadge(String(localized: "Search"), color: .blue, icon: "magnifyingglass")
                            }
                        }
                    } else {
                        proLockedRow(feature: .appleScript, label: String(localized: "Toggle action"))
                        CompactDivider()
                        proLockedRow(feature: .appleScript, label: String(localized: "Profiles actions"))
                        CompactDivider()
                        proLockedRow(feature: .appleScript, label: String(localized: "Search action"))
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
