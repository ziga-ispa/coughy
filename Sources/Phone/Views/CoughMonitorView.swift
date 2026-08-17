import SwiftUI

struct CoughMonitorView: View {
    @EnvironmentObject var viewModel: CoughMonitorViewModel

    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // ── Start / Stop button ──────────────────────────────────
                monitorButton
                    .padding(.top, 24)

                // ── Session stats ────────────────────────────────────────
                if !viewModel.events.isEmpty || viewModel.currentSession != nil {
                    StatsBarView(
                        events: viewModel.events,
                        session: viewModel.currentSession,
                        viewModel: viewModel
                    )
                    .padding(.vertical, 12)
                }

                // ── Error banner ─────────────────────────────────────────
                if let err = viewModel.errorMessage {
                    Text(err)
                        .font(.caption)
                        .foregroundStyle(.white)
                        .padding(8)
                        .frame(maxWidth: .infinity)
                        .background(Color.red)
                }

                Divider()

                // ── Event list ───────────────────────────────────────────
                if viewModel.events.isEmpty {
                    EmptyStateView(isMonitoring: viewModel.isMonitoring)
                } else {
                    List(viewModel.events) { event in
                        EventRowView(event: event, viewModel: viewModel)
                    }
                    .listStyle(.plain)
                }
            }
            .navigationTitle("Cough Monitor")
            .navigationBarTitleDisplayMode(.inline)
        }
    }

    private var monitorButton: some View {
        Button {
            if viewModel.isMonitoring { viewModel.stopSession() }
            else { viewModel.startSession() }
        } label: {
            HStack(spacing: 10) {
                Image(systemName: viewModel.isMonitoring ? "stop.circle.fill" : "mic.circle.fill")
                    .font(.title2)
                Text(viewModel.isMonitoring ? "Stop Monitoring" : "Start Monitoring")
                    .font(.headline)
            }
            .foregroundStyle(.white)
            .padding(.horizontal, 32)
            .padding(.vertical, 16)
            .background(viewModel.isMonitoring ? Color.red : Color.blue)
            .clipShape(Capsule())
            .shadow(radius: 4)
        }
    }
}
