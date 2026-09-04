import AppKit
import SaneUI
import SwiftUI

// MARK: - Page 6: Permissions

struct PermissionPage: View {
    @ObservedObject private var accessibilityService = AccessibilityService.shared

    var body: some View {
        VStack(spacing: 24) {
            Spacer()

            Image(systemName: "lock.shield.fill")
                .font(.system(size: 48))
                .foregroundStyle(saneAccent)

            Text(String(localized: "Grant Access"))
                .font(.system(size: 28, weight: .bold, design: .serif))
                .foregroundStyle(.white)

            VStack(alignment: .leading, spacing: 12) {
                HStack(spacing: 10) {
                    Image(systemName: "video.slash.fill")
                        .font(.system(size: 20))
                        .foregroundStyle(saneAccent)
                        .frame(width: 28)
                    Text(String(localized: "No screen recording."))
                        .font(.system(size: 17, weight: .medium))
                        .foregroundStyle(.white)
                }
                HStack(spacing: 10) {
                    Image(systemName: "eye.slash.fill")
                        .font(.system(size: 20))
                        .foregroundStyle(saneAccent)
                        .frame(width: 28)
                    Text(String(localized: "No screenshots."))
                        .font(.system(size: 17, weight: .medium))
                        .foregroundStyle(.white)
                }
                HStack(spacing: 10) {
                    Image(systemName: "icloud.slash")
                        .font(.system(size: 20))
                        .foregroundStyle(saneAccent)
                        .frame(width: 28)
                    Text(String(localized: "No menu bar contents uploaded."))
                        .font(.system(size: 17, weight: .medium))
                        .foregroundStyle(.white)
                }
            }

            if accessibilityService.isGranted {
                HStack(spacing: 8) {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(.green)
                    Text(String(localized: "Permission granted — you're all set!"))
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(.green)
                }
                .padding(.top, 8)
            } else {
                Button {
                    _ = accessibilityService.promptAndOpenAccessibilitySettings()
                } label: {
                    HStack(spacing: 8) {
                        Image(systemName: "lock.open.fill")
                            .font(.system(size: 14))
                        Text(String(localized: "Open Accessibility Settings"))
                            .font(.system(size: 15, weight: .semibold))
                    }
                }
                .buttonStyle(OnboardingPrimaryButtonStyle(cornerRadius: 10, horizontalPadding: 18, verticalPadding: 10))

                Text(AccessibilityService.deniedHelpText())
                    .font(.system(size: 13))
                    .foregroundStyle(.white.opacity(0.9))
            }

            Spacer()
        }
        .padding(.horizontal, 40)
        .refreshAccessibilityPermission(using: accessibilityService)
    }
}
