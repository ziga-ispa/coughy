import SwiftUI

struct EventRowView: View {
    let event: CoughEvent
    let viewModel: CoughMonitorViewModel

    private let timeFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateStyle = .none
        f.timeStyle = .medium
        return f
    }()

    var body: some View {
        HStack(spacing: 12) {
            Text(event.type == .wet ? "Wet" : "Dry")
                .font(.caption.bold())
                .foregroundStyle(.white)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(event.type == .wet ? Color.blue : Color.orange)
                .clipShape(Capsule())

            VStack(alignment: .leading, spacing: 2) {
                Text(timeFormatter.string(from: event.timestamp))
                    .font(.subheadline)
                Text("conf \(Int(event.confidence * 100))%  •  \(viewModel.loudnessLabel(rms: event.peakRMS))")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            Text(viewModel.dbfsString(rms: event.peakRMS))
                .font(.caption.monospacedDigit())
                .foregroundStyle(.secondary)
        }
        .padding(.vertical, 2)
    }
}
