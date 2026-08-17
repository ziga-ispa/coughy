import SwiftUI

struct LimitationsPlacementView: View {
    let onFinish: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            Spacer()

            Text("Max. 30 cm")
                .font(.system(size: 16, weight: .bold))
                .foregroundColor(.white)

            Spacer().frame(height: 8)

            Image("Arrow")
                .resizable()
                .scaledToFit()
                .frame(width: 162, height: 15)

            Spacer().frame(height: 24)

            Image("SleepIllustration")
                .resizable()
                .scaledToFit()
                .frame(width: 359.81, height: 247.34)

            Spacer().frame(height: 40)

            Text("Place device near you")
                .font(.system(size: 24, weight: .bold))
                .foregroundColor(.white)

            Spacer().frame(height: 16)

            Text("To optimally detect coughs, we recommend placing the device on a bedside table near your head within a maximum distance of 30 cm.")
                .font(.system(size: 16, weight: .regular))
                .foregroundColor(.white.opacity(0.9))
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)

            Spacer()

            VStack(spacing: 12) {
                OnboardingNextButton(title: "Next", action: onFinish)
                OnboardingSkipButton(action: onFinish)
            }
                .padding(.bottom, 60)
        }
        .modifier(OnboardingBackground())
    }
}
