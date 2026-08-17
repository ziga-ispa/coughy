import SwiftUI

struct LimitationsPluggedInView: View {
    let onNext: () -> Void
    let onSkip: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            Spacer()

            Image(systemName: "battery.100.bolt")
                .font(.system(size: 80))
                .foregroundColor(.white)

            Spacer().frame(height: 32)

            Text("Limitations")
                .font(.system(size: 28, weight: .bold))
                .foregroundColor(.white)

            Spacer().frame(height: 16)

            Text("Keep device plugged in")
                .font(.system(size: 20, weight: .semibold))
                .foregroundColor(.white)

            Spacer().frame(height: 16)

            Text("Continuous audio monitoring uses significant battery. Keep your device plugged in overnight to ensure Coughie runs all night without interruption.")
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
