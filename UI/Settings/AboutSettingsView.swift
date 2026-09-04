import SaneUI
import SwiftUI

struct AboutSettingsView: View {
    var body: some View {
        SaneAboutView(
            appName: AppIdentity.displayName,
            githubRepo: AppIdentity.githubRepo,
            diagnosticsService: .shared,
            licenses: licenseEntries,
            feedbackExtraAttachments: [
                ("menubar.rectangle", "Menu bar state snapshot (separator positions and counts)")
            ]
        )
    }

    private var licenseEntries: [SaneAboutView.LicenseEntry] {
        [
            SaneAboutView.LicenseEntry(
                name: "HaoBar",
                url: AppIdentity.githubURL.absoluteString,
                text: """
                HaoBar is a Mac App Store fork of SaneBar.

                Copyright (c) 2026 HaoBar contributors
                Copyright (c) 2025-2026 SaneApps (hi@saneapps.com)

                MIT License. The original SaneBar copyright and permission
                notice are included with this software.
                """
            ),
            SaneAboutView.LicenseEntry(
                name: "SaneBar / SaneUI",
                url: "https://github.com/sane-apps/SaneBar",
                text: """
                MIT License

                Copyright (c) 2025-2026 SaneApps (hi@saneapps.com)

                Permission is hereby granted, free of charge, to any person obtaining a copy
                of this software and associated documentation files (the "Software"), to deal
                in the Software without restriction, including without limitation the rights
                to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
                copies of the Software, and to furnish to persons to whom the Software is
                furnished to do so, subject to the following conditions:

                The above copyright notice and this permission notice shall be included in all
                copies or substantial portions of the Software.
                """
            ),
            SaneAboutView.LicenseEntry(
                name: "KeyboardShortcuts",
                url: "https://github.com/sindresorhus/KeyboardShortcuts",
                text: """
                MIT License (third-party dependency)

                Copyright (c) Sindre Sorhus <sindresorhus@gmail.com> (https://sindresorhus.com)
                """
            )
        ]
    }
}
