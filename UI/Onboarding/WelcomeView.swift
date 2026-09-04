import AppKit
import SaneUI
import SwiftUI

/// First-run: Welcome → Try hide → Choose view → Accessibility.
public struct WelcomeView: View {
    @State private var currentPage = 0
    @State private var navigateForward = true
    let onComplete: () -> Void
    private let totalPages = 4

    public init(onComplete: @escaping () -> Void) {
        self.onComplete = onComplete
    }

    public var body: some View {
        VStack(spacing: 0) {
            ZStack {
                Group {
                    switch currentPage {
                    case 0: WelcomeIntroPage()
                    case 1: WelcomeActionPage()
                    case 2: ChooseBrowseViewPage()
                    case 3: PermissionPage()
                    default: WelcomeIntroPage()
                    }
                }
                .id(currentPage)
                .transition(pageTransition)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .clipped()

            HStack(spacing: 4) {
                ForEach(0 ..< totalPages, id: \.self) { index in
                    Capsule()
                        .fill(index <= currentPage ? saneAccent : Color.white.opacity(0.15))
                        .frame(height: 4)
                }
            }
            .padding(.horizontal, 60)
            .padding(.bottom, 16)

            HStack {
                if currentPage > 0 {
                    Button(String(localized: "Back")) {
                        navigateForward = false
                        withAnimation(pageAnimation) {
                            currentPage -= 1
                        }
                    }
                    .buttonStyle(.plain)
                    .foregroundStyle(.white.opacity(0.9))
                    .font(.system(size: 14))
                }

                Spacer()

                if currentPage < totalPages - 1 {
                    Button(String(localized: "Next")) {
                        navigateForward = true
                        withAnimation(pageAnimation) {
                            currentPage += 1
                        }
                    }
                    .buttonStyle(OnboardingPrimaryButtonStyle())
                } else {
                    Button(String(localized: "Get Started")) {
                        onComplete()
                    }
                    .buttonStyle(OnboardingPrimaryButtonStyle(cornerRadius: 10, horizontalPadding: 20, verticalPadding: 9))
                }
            }
            .padding(.horizontal, 40)
            .padding(.bottom, 30)
        }
        .frame(width: 700, height: 520)
        .background(OnboardingBackground())
    }

    private var reduceMotion: Bool {
        NSWorkspace.shared.accessibilityDisplayShouldReduceMotion
    }

    private var pageAnimation: Animation {
        reduceMotion
            ? .easeOut(duration: 0.18)
            : .snappy(duration: 0.32, extraBounce: 0)
    }

    private var pageTransition: AnyTransition {
        if reduceMotion {
            return .opacity
        }
        return .asymmetric(
            insertion: .move(edge: navigateForward ? .trailing : .leading).combined(with: .opacity),
            removal: .move(edge: navigateForward ? .leading : .trailing).combined(with: .opacity)
        )
    }
}

struct WelcomeIntroPage: View {
    var body: some View {
        VStack(spacing: 22) {
            if let appIcon = NSApp.applicationIconImage {
                Image(nsImage: appIcon)
                    .resizable()
                    .frame(width: 88, height: 88)
                    .shadow(color: .black.opacity(0.15), radius: 10, x: 0, y: 5)
            }

            Text(String(localized: "Welcome to \(AppIdentity.displayName)"))
                .font(.system(size: 30, weight: .bold, design: .serif))
                .foregroundStyle(.white)

            Text(String(localized: "Hide the menu bar icons you don’t need. Keep the important ones visible."))
                .font(.system(size: 17))
                .foregroundStyle(.white.opacity(0.92))
                .multilineTextAlignment(.center)
                .frame(maxWidth: 480)

            Text(String(localized: "Everything stays on this Mac. No account, no upload."))
                .font(.system(size: 14, weight: .medium))
                .foregroundStyle(.white.opacity(0.8))
        }
        .padding(.horizontal, 40)
    }
}

struct ChooseBrowseViewPage: View {
    @ObservedObject private var menuBarManager = MenuBarManager.shared

    var body: some View {
        VStack(spacing: 18) {
            Text(String(localized: "Choose how you browse hidden icons"))
                .font(.system(size: 26, weight: .bold, design: .serif))
                .foregroundStyle(.white)
                .multilineTextAlignment(.center)

            HStack(alignment: .top, spacing: 18) {
                viewChoice(
                    title: String(localized: "Icon Panel"),
                    detail: String(localized: "A compact floating grid. Best for search and quick open."),
                    selected: !menuBarManager.settings.useSecondMenuBar
                ) {
                    menuBarManager.settings.useSecondMenuBar = false
                }

                viewChoice(
                    title: String(localized: "Second Menu Bar"),
                    detail: String(localized: "A full-width row under the real menu bar. Best when you want more icons at once."),
                    selected: menuBarManager.settings.useSecondMenuBar
                ) {
                    menuBarManager.settings.useSecondMenuBar = true
                }
            }
        }
        .padding(.horizontal, 24)
        .padding(.vertical, 16)
    }

    private func viewChoice(title: String, detail: String, selected: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: 10) {
                Text(title)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(.white)
                Text(detail)
                    .font(.system(size: 13))
                    .foregroundStyle(.white.opacity(0.86))
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding(16)
            .frame(maxWidth: .infinity, minHeight: 140, alignment: .topLeading)
            .background(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(selected ? Color.white.opacity(0.14) : Color.black.opacity(0.28))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .stroke(selected ? saneAccent : Color.white.opacity(0.12), lineWidth: selected ? 2 : 1)
            )
        }
        .buttonStyle(HaoPressButtonStyle())
    }
}
