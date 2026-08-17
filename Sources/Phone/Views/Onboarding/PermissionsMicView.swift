import SwiftUI
import AVFoundation

struct PermissionsMicView: View {
    let onNext: () -> Void
    let onSkip: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            Spacer()

            Image(systemName: "mic.fill")
                .font(.system(size: 64))
                .foregroundColor(.white)

            Spacer().frame(height: 32)

            Text("Permissions")
                .font(.system(size: 28, weight: .bold))
                .foregroundColor(.white)

            Spacer().frame(height: 20)

            Text("Coughie needs access to your microphone to listen for coughs while you sleep. Your audio is processed on-device and is never stored or uploaded.")
                .font(.system(size: 16, weight: .regular))
                .foregroundColor(.white.opacity(0.9))
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)

            Spacer()

            VStack(spacing: 12) {
                OnboardingNextButton(title: "Next") {
                    requestMicPermission(then: onNext)
                }
                OnboardingSkipButton(action: onSkip)
            }
            .padding(.bottom, 60)
        }
        .modifier(OnboardingBackground())
    }

    private func requestMicPermission(then next: @escaping () -> Void) {
        AVAudioSession.sharedInstance().requestRecordPermission { _ in
            DispatchQueue.main.async { next() }
        }
    }
}
