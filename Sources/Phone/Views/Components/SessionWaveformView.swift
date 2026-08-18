import SwiftUI

struct SessionWaveformView: View {
    let events: [CoughEvent]
    let startDate: Date
    let duration: TimeInterval

    var body: some View {
        Canvas { ctx, size in
            let baseY = size.height * 0.5
            let maxSpikeHeight = size.height * 0.45
            
            var path = Path()
            
            guard !events.isEmpty, duration > 0 else {
                path.move(to: CGPoint(x: 0, y: baseY))
                path.addLine(to: CGPoint(x: size.width, y: baseY))
                
                var glowCtx = ctx
                glowCtx.addFilter(.shadow(color: .white.opacity(0.8), radius: 4, x: 0, y: 0))
                glowCtx.stroke(path, with: .color(.white), style: StrokeStyle(lineWidth: 2.5, lineCap: .round, lineJoin: .round))
                return
            }

            let maxRMS = events.map(\.peakRMS).max() ?? 1
            let normalizer = maxRMS > 0 ? Double(maxRMS) : 1.0

            path.move(to: CGPoint(x: 0, y: baseY))

            for xVal in stride(from: 0.0, through: Double(size.width), by: 1.0) {
                let x = CGFloat(xVal)
                var amplitude: Double = 0
                
                for (index, event) in events.enumerated() {
                    let elapsed = event.timestamp.timeIntervalSince(startDate)
                    let eventX = CGFloat(elapsed / duration) * size.width
                    let pixelDiff = Double(x - eventX)
                    
                    let normalizedHeight = Double(event.peakRMS) / normalizer
                    let spikeHeight = normalizedHeight * Double(maxSpikeHeight)
                    
                    // Use a Gabor patch to create a nice waveform blip
                    let sigma = 10.0 + Double(index % 3) * 2.0 // Slight variation in width
                    let k = 0.3 + Double(index % 4) * 0.05 // Slight variation in frequency
                    
                    let envelope = exp(-(pixelDiff * pixelDiff) / (2.0 * sigma * sigma))
                    let wave = cos(k * pixelDiff)
                    
                    amplitude += spikeHeight * envelope * wave
                }
                
                path.addLine(to: CGPoint(x: x, y: baseY - CGFloat(amplitude)))
            }

            var glowCtx = ctx
            glowCtx.addFilter(.shadow(color: .white.opacity(0.8), radius: 5, x: 0, y: 0))
            glowCtx.stroke(path, with: .color(.white), style: StrokeStyle(lineWidth: 2.5, lineCap: .round, lineJoin: .round))
        }
        .frame(height: 70)
        .padding(.vertical, 8)
    }
}
