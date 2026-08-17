import SwiftUI

@main
struct CoughyPhoneApp: App {
    var body: some Scene {
        WindowGroup {
            CoughMonitorView()
                .environmentObject(CoughMonitorViewModel())
        }
    }
}
