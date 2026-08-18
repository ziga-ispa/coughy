import SwiftUI

struct AcousticFeedView: View {
    let eventCount: Int

    @State private var samples: [Float] = Array(repeating: 0, count: 80)

    private let waveTimer = Timer.publish(every: 0.05, on: .main, in: .common).autoconnect()

    var body: some View {
        ZStack(alignment: .topTrailing) {
            VStack(alignment: .leading, spacing: 8) {
                Text("ACOUSTIC FEED")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundStyle(Color.brand)
                    .padding(.leading, 2)

                Canvas { context, size in
                    // 4 horizontal grid lines — 320pt wide, centred, evenly spread
                    let lineColor = Color.white.opacity(0.5)
                    let lineLength: CGFloat = 320
                    let startX = (size.width - lineLength) / 2
                    let endX = startX + lineLength
                    let linePositions: [CGFloat] = [0.05, 0.35, 0.65, 0.95]
                    for p in linePositions {
                        let y = size.height * p
                        var linePath = Path()
                        linePath.move(to: CGPoint(x: startX, y: y))
                        linePath.addLine(to: CGPoint(x: endX, y: y))
                        context.stroke(linePath, with: .color(lineColor), lineWidth: 1)
                    }

                    // Red playhead at center
                    var playhead = Path()
                    playhead.move(to: CGPoint(x: size.width / 2, y: 0))
                    playhead.addLine(to: CGPoint(x: size.width / 2, y: size.height))
                    context.stroke(playhead, with: .color(.red.opacity(0.85)), lineWidth: 2)

                    // Waveform
                    let count = samples.count
                    guard count > 1 else { return }
                    let stepX = size.width / CGFloat(count - 1)
                    let midY = size.height / 2
                    var wavePath = Path()
                    wavePath.move(to: CGPoint(x: 0, y: midY - CGFloat(samples[0]) * midY * 0.85))
                    for i in 1..<count {
                        let x = CGFloat(i) * stepX
                        let y = midY - CGFloat(samples[i]) * midY * 0.85
                        wavePath.addLine(to: CGPoint(x: x, y: y))
                    }
                    context.stroke(wavePath, with: .color(.white.opacity(0.9)), lineWidth: 2)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
            .padding(16)

            // Event count badge
            HStack(spacing: 4) {
                Image(systemName: "exclamationmark.triangle.fill")
                    .font(.system(size: 11))
                Text("\(eventCount) Events")
                    .font(.system(size: 11, weight: .semibold))
            }
            .foregroundStyle(.white)
            .frame(width: 101, height: 28)
            .background(Color(hex: "FF9230").opacity(0.38))
            .clipShape(Capsule())
            .padding(.top, 12)
            .padding(.trailing, 12)
        }
        .frame(width: 355, height: 195)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(hex: "D9D9D9").opacity(0.20))
        )
        .overlay(RoundedRectangle(cornerRadius: 16).stroke(Color.white.opacity(0.2), lineWidth: 1))
        .onReceive(waveTimer) { _ in
            samples.removeFirst()
            let newSample = Float.random(in: -0.7...0.7) * Float.random(in: 0.05...1.0)
            samples.append(newSample)
        }
    }
}
