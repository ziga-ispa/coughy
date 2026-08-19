import SwiftUI

@main
struct CoughyPhoneApp: App {
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = false
    @StateObject private var historyStore: HistoryStore
    @StateObject private var viewModel: CoughMonitorViewModel
    private let notificationDelegate = NotificationDelegate()

    init() {
        let store = HistoryStore()
        _historyStore = StateObject(wrappedValue: store)
        _viewModel = StateObject(wrappedValue: CoughMonitorViewModel(historyStore: store))
        
        UNUserNotificationCenter.current().delegate = notificationDelegate
        NotificationManager.requestAuthorization()
    }

    var body: some Scene {
        WindowGroup {
            if hasCompletedOnboarding {
                MainTabView()
                    .environmentObject(viewModel)
                    .environmentObject(historyStore)
            } else {
                OnboardingContainerView()
            }
        }
    }
}
