import SwiftUI

struct PermissionsHealthView: View {
    let onNext: () -> Void
    let onSkip: () -> Void

    @State private var isRequesting = false
    private let healthKit = HealthKitService()

    var body: some View {
        VStack(spacing: 0) {
            Spacer()

            Image(systemName: "heart.fill")
                .font(.system(size: 64))
                .foregroundColor(.white)

            Spacer().frame(height: 32)

            Text("Permissions")
                .font(.system(size: 28, weight: .bold))
                .foregroundColor(.white)

            Spacer().frame(height: 20)

            Text("Automatically sync your readings with Apple Health")
                .font(.system(size: 16, weight: .regular))
                .foregroundColor(.white.opacity(0.9))
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)

            Spacer()

            VStack(spacing: 12) {
                Button {
                    Task { await requestHealth() }
                } label: {
                    HStack(spacing: 8) {
                        if isRequesting {
                            ProgressView()
                                .tint(.black)
                        }
                        Text("Sync Health Data")
                            .font(.system(size: 17, weight: .bold))
                            .foregroundColor(.black)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(Color(hex: "E8A4A4"))
                    .clipShape(Capsule())
                }
                .padding(.horizontal, 32)
                .disabled(isRequesting)

                OnboardingSkipButton(action: onSkip)
            }
            .padding(.bottom, 60)
        }
        .modifier(OnboardingBackground())
    }

    private func requestHealth() async {
        isRequesting = true
        try? await healthKit.requestAuthorization()
        isRequesting = false
        onNext()
    }
}
