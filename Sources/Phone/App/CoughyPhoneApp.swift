import SwiftUI

@main
struct CoughyPhoneApp: App {
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = false

    var body: some Scene {
        WindowGroup {
            // DEV: always show onboarding; remove the `true ||` when ready for production
            if true || hasCompletedOnboarding {
                OnboardingContainerView()
            } else {
                CoughMonitorView()
                    .environmentObject(CoughMonitorViewModel())
            }
        }
    }
}
