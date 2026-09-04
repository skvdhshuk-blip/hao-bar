import AppKit
import SaneUI
import SwiftUI

struct AboutSettingsView: View {
    var body: some View {
        SaneSettingsPage {
            VStack(spacing: 14) {
                Image(nsImage: NSApp.applicationIconImage)
                    .resizable()
                    .frame(width: 64, height: 64)
                    .shadow(color: .black.opacity(0.12), radius: 6, x: 0, y: 4)

                VStack(spacing: 6) {
                    Text(AppIdentity.displayName)
                        .font(.system(size: 26, weight: .bold))
                        .foregroundStyle(.white)

                    Text(AppIdentity.versionLine())
                        .font(.system(size: 14, weight: .medium))
                        .foregroundStyle(.white)

                    Text(AppIdentity.runningIdentityLabel())
                        .font(.system(size: 13, weight: .medium))
                        .foregroundStyle(.white.opacity(0.86))
                }

                Text(AppIdentity.copyrightHolders)
                    .font(.system(size: 13))
                    .foregroundStyle(.white.opacity(0.86))
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
                    .frame(maxWidth: 360)
            }
            .frame(maxWidth: .infinity)
            .padding(.top, 28)
            .padding(.bottom, 20)
        }
    }
}
