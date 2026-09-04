import Foundation

/// Features gated behind Pro. Each case maps to a user-visible action
/// that free users can see but not perform.
enum ProFeature: String, Identifiable, CaseIterable {
    case iconActivation = "Activate Icons from Panels"
    case rightClickFromPanels = "Right-Click from Panels"
    case zoneMoves = "Move Icons Between Zones"
    case alwaysHidden = "Always Hidden Zone"
    case perIconHotkeys = "Per-Icon Hotkeys"
    case iconGroups = "Custom Icon Groups"
    case advancedTriggers = "Advanced Triggers"
    case gestureCustomization = "Gesture Customization"
    case autoRehideCustomization = "Auto-Rehide Customization"
    case menuBarAppearance = "Menu Bar Appearance"
    case iconSpacing = "Icon Spacing Control"
    case touchIDProtection = "Password / Touch ID Protection"
    case settingsProfiles = "Settings Profiles"
    case exportImport = "Export / Import Settings"
    case competitorImport = "Competitor Import"
    case customIcon = "Custom Menu Bar Icon"
    case spacersConfig = "Spacers Configuration"
    case additionalShortcuts = "Additional Global Shortcuts"
    case appleScript = "AppleScript Automation"

    var id: String { rawValue }

    var description: String {
        switch self {
        case .iconActivation: String(localized: "Click icons directly from the panel to open their menus")
        case .rightClickFromPanels: String(localized: "Right-click icons from the panel for quick actions")
        case .zoneMoves: String(localized: "Drag icons between Visible, Hidden, and Always Hidden zones")
        case .alwaysHidden: String(localized: "A third zone for icons you never want to see")
        case .perIconHotkeys: String(localized: "Assign a unique keyboard shortcut to any icon")
        case .iconGroups: String(localized: "Organize icons into custom named groups")
        case .advancedTriggers: String(localized: "Auto-show icons on Wi-Fi, Focus, battery, app launch, or script")
        case .gestureCustomization: String(localized: "Toggle mode, directional scroll, and more gesture options")
        case .autoRehideCustomization: String(localized: "Custom timing, hide-on-app-change, external monitor rules")
        case .menuBarAppearance: String(localized: "Tint colors, glass effects, borders, corners, and shadows")
        case .iconSpacing: String(localized: "Reduce or increase the space between menu bar icons")
        case .touchIDProtection: String(localized: "Protect hidden icons with Touch ID or your password")
        case .settingsProfiles: String(localized: "Save and load different configurations")
        case .exportImport: String(localized: "Export settings to share or back up, import from file")
        case .competitorImport: String(localized: "Import settings from Bartender or Ice")
        case .customIcon: String(localized: "Use your own image as the HaoBar menu bar icon")
        case .spacersConfig: String(localized: "Add extra visual dividers to organize your menu bar")
        case .additionalShortcuts: String(localized: "Show-only, hide-only, open settings, and more shortcuts")
        case .appleScript: String(localized: "Control HaoBar from scripts and automation tools")
        }
    }

    var icon: String {
        switch self {
        case .iconActivation: "cursorarrow.click"
        case .rightClickFromPanels: "cursorarrow.click.2"
        case .zoneMoves: "arrow.left.arrow.right"
        case .alwaysHidden: "lock.fill"
        case .perIconHotkeys: "keyboard"
        case .iconGroups: "folder"
        case .advancedTriggers: "bolt.fill"
        case .gestureCustomization: "hand.draw"
        case .autoRehideCustomization: "timer"
        case .menuBarAppearance: "paintpalette.fill"
        case .iconSpacing: "arrow.left.and.right"
        case .touchIDProtection: "touchid"
        case .settingsProfiles: "doc.on.doc"
        case .exportImport: "square.and.arrow.up.on.square"
        case .competitorImport: "arrow.down.doc"
        case .customIcon: "photo"
        case .spacersConfig: "line.3.horizontal"
        case .additionalShortcuts: "command"
        case .appleScript: "applescript"
        }
    }
}
