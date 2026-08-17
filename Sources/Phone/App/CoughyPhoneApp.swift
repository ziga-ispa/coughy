import SwiftUI

@main
struct CoughyPhoneApp: App {
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = false

    var body: some Scene {
        WindowGroup {
            if hasCompletedOnboarding {
                MainTabView()
                    .environmentObject(CoughMonitorViewModel())
            } else {
                OnboardingContainerView()
            }
        }
    }
}
