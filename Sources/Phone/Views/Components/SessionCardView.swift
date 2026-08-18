import SwiftUI

struct SessionCardView: View {
    let session: CoughSession

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 20)
                .fill(Color(hex: "D9D9D9").opacity(0.2))

            VStack(alignment: .leading, spacing: 12) {
                // Header row
                HStack(alignment: .top) {
                    VStack(alignment: .leading, spacing: 3) {
                        Text(dayAndDate)
                            .font(.system(size: 20, weight: .bold))
                            .foregroundStyle(Color.deepNavy)
                        Text(timeRange)
                            .font(.system(size: 14, weight: .medium))
                            .foregroundStyle(.white)
                    }
                    Spacer()
                    coughBadge
                }

                // Waveform
                SessionWaveformView(
                    events: session.events,
                    startDate: session.startDate,
                    duration: session.duration
                )
                .background(
                    Capsule()
                        .fill(Color(hex: "D9D9D9").opacity(0.2))
                )

                // Notes
                if let notes = session.notes, !notes.isEmpty {
                    HStack(spacing: 6) {
                        Image(systemName: "list.bullet")
                            .font(.caption)
                            .foregroundStyle(.white.opacity(0.85))
                        Text(notes)
                            .font(.caption)
                            .foregroundStyle(.white)
                            .lineLimit(1)
                    }
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
        }
        .frame(width: 355, height: 165)
        .glassEffect(in: RoundedRectangle(cornerRadius: 20))
        .overlay(RoundedRectangle(cornerRadius: 20).stroke(Color.white.opacity(0.15), lineWidth: 1))
    }

    private var coughBadge: some View {
        HStack(spacing: 5) {
            Image(systemName: "lungs.fill")
                .font(.system(size: 13, weight: .semibold))
            Text("\(session.events.count)")
                .font(.system(size: 14, weight: .bold))
        }
        .foregroundStyle(Color.brand)
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(Color(hex: "FF383C").opacity(0.49))
        .clipShape(Capsule())
    }

    private var dayAndDate: String {
        let f = DateFormatter()
        f.dateFormat = "EEE, MMM d"
        return f.string(from: session.startDate)
    }

    private var timeRange: String {
        let f = DateFormatter()
        f.dateStyle = .none
        f.timeStyle = .short
        let start = f.string(from: session.startDate)
        let end = f.string(from: session.endDate ?? Date())
        let dur = durationString(session.duration)
        return "\(start) – \(end) (\(dur))"
    }

    private func durationString(_ interval: TimeInterval) -> String {
        let total = Int(interval)
        let h = total / 3600
        let m = (total % 3600) / 60
        if h > 0 {
            return "\(h)h \(m)m"
        }
        let s = total % 60
        return m > 0 ? "\(m)m \(s)s" : "\(s)s"
    }
}
