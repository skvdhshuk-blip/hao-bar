import SaneUI
import SwiftUI

struct HiddenIconPopupView: View {
    let apps: [RunningApp]
    let hasAccessibility: Bool
    let hasScreenCapture: Bool
    let onActivate: (RunningApp) -> Void
    let onDismiss: () -> Void
    let onOpenScreenRecordingSettings: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(String(localized: "Hidden"))
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(.white.opacity(0.94))
                Spacer()
                Button {
                    onDismiss()
                } label: {
                    Image(systemName: "xmark")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundStyle(.white.opacity(0.8))
                }
                .buttonStyle(.plain)
                .help(String(localized: "Close"))
            }

            content
        }
        .padding(12)
        .frame(minWidth: 220, minHeight: 64)
        .background(
            ChromeGlassRoundedBackground(
                cornerRadius: 12,
                tint: SaneBarChrome.panelTint,
                tintStrength: 0.16,
                shadowOpacity: 0.16,
                shadowRadius: 8,
                shadowY: 3
            )
        )
    }

    @ViewBuilder
    private var content: some View {
        if !hasAccessibility {
            Text(AccessibilityService.deniedHelpText())
                .font(.system(size: 13))
                .foregroundStyle(.white.opacity(0.86))
                .fixedSize(horizontal: false, vertical: true)
        } else if apps.isEmpty {
            Text(String(localized: "No hidden icons."))
                .font(.system(size: 13))
                .foregroundStyle(.white.opacity(0.86))
        } else {
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 6) {
                    ForEach(apps) { app in
                        Button {
                            onActivate(app)
                        } label: {
                            Image(nsImage: MenuBarItemCaptureService.shared.image(for: app))
                                .resizable()
                                .interpolation(.high)
                                .aspectRatio(contentMode: .fit)
                                .frame(width: 22, height: 22)
                                .frame(width: 32, height: 32)
                                .background(
                                    RoundedRectangle(cornerRadius: 7)
                                        .fill(Color.white.opacity(0.08))
                                )
                        }
                        .buttonStyle(.plain)
                        .help(app.name)
                    }
                }
            }

            if !hasScreenCapture {
                HStack(spacing: 8) {
                    Text(String(localized: "Screen Recording is required to show icon snapshots."))
                        .font(.system(size: 12))
                        .foregroundStyle(.white.opacity(0.78))
                    Button(String(localized: "Grant Screen Recording"), action: onOpenScreenRecordingSettings)
                        .buttonStyle(ChromeActionButtonStyle())
                }
            }
        }
    }
}
