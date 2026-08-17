import SwiftUI

struct HistoryView: View {
    @EnvironmentObject var viewModel: CoughMonitorViewModel

    var body: some View {
        NavigationView {
            Group {
                if viewModel.events.isEmpty {
                    EmptyStateView(isMonitoring: viewModel.isMonitoring)
                } else {
                    List(viewModel.events) { event in
                        EventRowView(event: event, viewModel: viewModel)
                    }
                    .listStyle(.plain)
                }
            }
            .navigationTitle("History")
        }
    }
}
