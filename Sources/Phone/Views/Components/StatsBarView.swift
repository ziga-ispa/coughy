import SwiftUI

struct StatsBarView: View {
    let events: [CoughEvent]
    let session: CoughSession?
    let viewModel: CoughMonitorViewModel

    var body: some View {
        let dry = events.filter { $0.type == .dry }.count
        let wet = events.filter { $0.type == .wet }.count
        let total = events.count

        HStack(spacing: 24) {
            statCell(label: "Total", value: "\(total)")
            statCell(label: "Dry", value: "\(dry)", color: .orange)
            statCell(label: "Wet", value: "\(wet)", color: .blue)
            if let session {
                statCell(label: "Duration", value: viewModel.durationString(from: session))
            }
        }
        .padding(.horizontal)
    }

    private func statCell(label: String, value: String, color: Color = .primary) -> some View {
        VStack(spacing: 2) {
            Text(value)
                .font(.title2.bold())
                .foregroundStyle(color)
            Text(label)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }
}
