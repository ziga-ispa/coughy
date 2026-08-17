import SwiftUI

struct EmptyStateView: View {
    let isMonitoring: Bool

    var body: some View {
        VStack(spacing: 12) {
            Spacer()
            Image(systemName: "waveform.slash")
                .font(.system(size: 48))
                .foregroundStyle(.secondary)
            Text(isMonitoring
                 ? "Listening for coughs…"
                 : "Tap Start Monitoring to begin")
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
            Spacer()
        }
        .padding()
    }
}
