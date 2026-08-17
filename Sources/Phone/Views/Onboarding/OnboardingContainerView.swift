import SwiftUI

struct OnboardingContainerView: View {
    @AppStorage("hasCompletedOnboarding") private var done = false
    @State private var page = 0

    private let totalPages = 6

    var body: some View {
        ZStack(alignment: .bottom) {
            LinearGradient(
                colors: [Color(hex: "7CABC5"), Color(hex: "3A6B85")],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()

            Group {
                switch page {
                case 0: WelcomePage1View(onNext: go(1), onSkip: finish)
                case 1: WelcomePage2View(onNext: go(2), onSkip: finish)
                case 2: PermissionsMicView(onNext: go(3), onSkip: finish)
                case 3: PermissionsHealthView(onNext: go(4), onSkip: finish)
                case 4: LimitationsPluggedInView(onNext: go(5), onSkip: finish)
                default: LimitationsPlacementView(onFinish: finish)
                }
            }
            .id(page)
            .transition(.asymmetric(
                insertion: .move(edge: .trailing),
                removal:   .move(edge: .leading)
            ))

            HStack(spacing: 10) {
                ForEach(0..<totalPages, id: \.self) { i in
                    Circle()
                        .fill(i == page ? Color.white : Color.white.opacity(0.35))
                        .frame(width: 8, height: 8)
                }
            }
            .padding(.bottom, 20)
        }
        .ignoresSafeArea()
        .animation(.easeInOut(duration: 0.3), value: page)
    }

    private func go(_ target: Int) -> () -> Void { { page = target } }
    private func finish() { done = true }
}
