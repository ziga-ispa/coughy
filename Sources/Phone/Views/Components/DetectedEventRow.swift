import SwiftUI

struct DetectedEventRow: View {
    let event: CoughEvent
    @State private var isPlaying = false
    @State private var animationPhase: CGFloat = 0

    private let timeFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateStyle = .none
        f.timeStyle = .short
        return f
    }()

    var body: some View {
        HStack(spacing: 12) {
            // Play/pause button
            Button {
                isPlaying.toggle()
                if isPlaying {
                    withAnimation(.easeInOut(duration: 0.4).repeatForever(autoreverses: true)) {
                        animationPhase = 1
                    }
                } else {
                    withAnimation(.default) {
                        animationPhase = 0
                    }
                }
            } label: {
                ZStack {
                    Circle()
                        .fill(Color(hex: "F19DA7"))
                        .frame(width: 44, height: 44)
                    if isPlaying {
                        HStack(spacing: 3) {
                            ForEach(0..<4, id: \.self) { i in
                                RoundedRectangle(cornerRadius: 2)
                                    .fill(Color(hex: "F19DA7"))
                                    .frame(width: 3, height: CGFloat([10, 16, 12, 8][i]) * (1 + animationPhase * 0.5))
                                    .animation(
                                        .easeInOut(duration: 0.3 + Double(i) * 0.1).repeatForever(autoreverses: true),
                                        value: animationPhase
                                    )
                            }
                        }
                    } else {
                        Image(systemName: "play.fill")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundStyle(.white)
                    }
                }
            }
            .buttonStyle(.plain)

            // Time + waveform
            VStack(alignment: .leading, spacing: 4) {
                Text(timeFormatter.string(from: event.timestamp))
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(.white)

                HStack(spacing: 3) {
                    let heights: [CGFloat] = waveformHeights(rms: event.peakRMS)
                    ForEach(0..<4, id: \.self) { i in
                        RoundedRectangle(cornerRadius: 2)
                            .fill(Color(hex: "F19DA7").opacity(0.7))
                            .frame(width: 3, height: isPlaying ? heights[i] * (1 + animationPhase * 0.6) : heights[i])
                            .animation(
                                .easeInOut(duration: 0.25 + Double(i) * 0.08).repeatForever(autoreverses: true),
                                value: isPlaying ? animationPhase : 0
                            )
                    }
                }
            }

            Spacer()

            // Type badge
            Text(event.type == .wet ? "Wet" : "Dry")
                .font(.system(size: 12, weight: .bold))
                .foregroundStyle(event.type == .wet ? Color(hex: "A0BB6E") : Color(hex: "BCD2DE"))
                .padding(.horizontal, 10)
                .padding(.vertical, 5)
                .background(
                    event.type == .wet
                        ? Color(hex: "7D8D70").opacity(0.49)
                        : Color(hex: "074D73").opacity(0.41)
                )
                .clipShape(Capsule())

            // Duration
            Text(durationString)
                .font(.system(size: 14, weight: .regular, design: .monospaced))
                .foregroundStyle(.white.opacity(0.7))
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
        .background(Color(hex: "D9D9D9").opacity(0.15))
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    private func waveformHeights(rms: Float) -> [CGFloat] {
        let base = CGFloat(max(4, min(20, Double(rms) * 200)))
        return [base * 0.6, base, base * 0.8, base * 0.5]
    }

    private var durationString: String {
        let seconds = Double(event.windowCount) * 0.05
        let s = Int(seconds) % 60
        let m = Int(seconds) / 60
        return String(format: "%d:%02d", m, s)
    }
}
