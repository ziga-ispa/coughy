import SwiftUI

struct WelcomePage1View: View {
    let onNext: () -> Void
    let onSkip: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            Spacer()

            Image("CoughyLogo")
                .renderingMode(.original)
                .resizable()
                .scaledToFit()
                .frame(maxWidth: 260)
                .padding(.horizontal, 32)

            Spacer().frame(height: 24)

            Text("Nighttime Cough Detection App")
                .font(.system(size: 20, weight: .regular))
                .foregroundColor(.white)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
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
