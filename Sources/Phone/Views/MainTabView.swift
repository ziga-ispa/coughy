import SwiftUI

struct MainTabView: View {
    var body: some View {
        TabView {
            HomeRecordView()
                .tabItem {
                    Label("Monitor", systemImage: "mic.fill")
                }

            HistoryView()
                .tabItem {
                    Label("History", systemImage: "clock.fill")
                }

            ProfileView()
                .tabItem {
                    Label("Profile", systemImage: "person.fill")
                }
        }
        .tint(Color.brand)
    }
}
