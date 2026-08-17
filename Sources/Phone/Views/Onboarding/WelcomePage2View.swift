import SwiftUI

struct WelcomePage2View: View {
    let onNext: () -> Void
    let onSkip: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            Spacer()

            Text("Welcome to Coughie")
                .font(.system(size: 28, weight: .bold))
                .foregroundColor(.white)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)

            Spacer().frame(height: 24)

            Text("Coughie monitors your coughs while you sleep, helping you track patterns and share insights with your healthcare provider. Just place your phone nearby, plug it in, and let Coughie do the rest.")
                .font(.system(size: 16, weight: .regular))
                .foregroundColor(.white.opacity(0.9))
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)

            Spacer()

            VStack(spacing: 12) {
                OnboardingNextButton(title: "Next", action: onNext)
                OnboardingSkipButton(action: onSkip)
            }
            .padding(.bottom, 60)
        }
        .modifier(OnboardingBackground())
    }
}
