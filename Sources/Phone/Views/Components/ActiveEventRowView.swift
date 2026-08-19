import SwiftUI

struct ActiveEventRowView: View {
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
            ZStack {
                Circle()
                    .fill(event.type == .dry ? Color.brand : Color.deepNavy)
                    .frame(width: 44, height: 44)
                Image(systemName: event.type == .dry ? "wind" : "speaker.wave.3.fill")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(event.type == .dry ? Color.deepNavy : Color.brand)
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(event.type == .dry ? "Harsh Cough" : "Throat Clear")
                    .font(.system(size: 15, weight: .bold))
                    .foregroundStyle(.white)
                Text(timeFormatter.string(from: event.timestamp))
                    .font(.system(size: 12))
                    .foregroundStyle(.white.opacity(0.6))
            }

            Spacer()

            Text(viewModel.dbfsString(rms: event.peakRMS))
                .font(.system(size: 13, weight: .medium).monospacedDigit())
                .foregroundStyle(.white.opacity(0.75))
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background {
            Color.clear
                .glassEffect(in: RoundedRectangle(cornerRadius: 14))
                .opacity(0.25)
        }
        .overlay(RoundedRectangle(cornerRadius: 14).stroke(Color.white.opacity(0.15), lineWidth: 1))
    }
}
