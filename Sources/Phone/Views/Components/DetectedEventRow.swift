import SwiftUI
import AVFoundation

struct DetectedEventRow: View {
    let event: CoughEvent
    @StateObject private var player = ClipPlayer()

    private let timeFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateStyle = .none
        f.timeStyle = .short
        return f
    }()

    private var hasClip: Bool {
        guard let name = event.audioClipFilename,
              let url = ClipPlayer.clipURL(name) else { return false }
        return FileManager.default.fileExists(atPath: url.path)
    }

    var body: some View {
        HStack(spacing: 12) {
            // Tombol play/pause sungguhan
            Button {
                player.toggle(filename: event.audioClipFilename)
            } label: {
                ZStack {
                    Circle()
                        .fill(Color(hex: "F19DA7"))
                        .frame(width: 44, height: 44)
                    Image(systemName: hasClip ? (player.isPlaying ? "pause.fill" : "play.fill") : "waveform")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundStyle(.white)
                }
            }
            .buttonStyle(.plain)
            .disabled(!hasClip)

            // Waktu + waveform (bar terisi mengikuti progres, bukan animasi tak berujung)
            VStack(alignment: .leading, spacing: 4) {
                Text(timeFormatter.string(from: event.timestamp))
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(.white)

                HStack(spacing: 3) {
                    let heights = waveformHeights(rms: event.peakRMS)
                    ForEach(heights.indices, id: \.self) { i in
                        let played = player.progress >= Double(i + 1) / Double(heights.count)
                        RoundedRectangle(cornerRadius: 2)
                            .fill(Color(hex: "F19DA7").opacity(player.isPlaying && played ? 1.0 : 0.7))
                            .frame(width: 3, height: heights[i])
                    }
                }
                .animation(.linear(duration: 0.08), value: player.progress)
            }

            Spacer()

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

            Text(durationString)
                .font(.system(size: 14, weight: .regular, design: .monospaced))
                .foregroundStyle(.white.opacity(0.7))
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
        .background(Color(hex: "D9D9D9").opacity(0.15))
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .onDisappear { player.stop() }
    }

    private func waveformHeights(rms: Float) -> [CGFloat] {
        let base = CGFloat(max(4, min(20, Double(rms) * 200)))
        return [0.55, 1.0, 0.75, 0.9, 0.5].map { base * $0 }
    }

    // 0.6 s / window (LogMelProcessor). Satu desimal supaya tak pernah "0:00".
    private var durationString: String {
        let seconds = Double(max(event.windowCount, 1)) * 0.6
        if seconds < 60 { return String(format: "%.1fs", seconds) }
        let total = Int(seconds.rounded())
        return String(format: "%d:%02d", total / 60, total % 60)
    }
}

// MARK: - Pemutar klip

final class ClipPlayer: NSObject, ObservableObject, AVAudioPlayerDelegate {
    @Published var isPlaying = false
    @Published var progress: Double = 0     // 0...1

    private var player: AVAudioPlayer?
    private var timer: Timer?

    func toggle(filename: String?) {
        isPlaying ? pause() : play(filename: filename)
    }

    private func play(filename: String?) {
        if player == nil {
            guard let filename,
                  let url = Self.clipURL(filename),
                  FileManager.default.fileExists(atPath: url.path) else { return }
            do {
                try AVAudioSession.sharedInstance().setCategory(.playback, options: [.duckOthers])
                try AVAudioSession.sharedInstance().setActive(true)
                let p = try AVAudioPlayer(contentsOf: url)
                p.delegate = self
                p.prepareToPlay()
                player = p
            } catch {
                print("ClipPlayer load failed: \(error)")
                return
            }
        }
        player?.play()
        isPlaying = true
        startTimer()
    }

    func pause() {
        player?.pause()
        isPlaying = false
        stopTimer()
    }

    func stop() {
        player?.stop()
        player = nil
        isPlaying = false
        progress = 0
        stopTimer()
    }

    private func startTimer() {
        stopTimer()
        timer = Timer.scheduledTimer(withTimeInterval: 0.05, repeats: true) { [weak self] _ in
            guard let self, let p = self.player, p.duration > 0 else { return }
            self.progress = p.currentTime / p.duration
        }
    }

    private func stopTimer() {
        timer?.invalidate()
        timer = nil
    }

    func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        isPlaying = false
        progress = 0
        stopTimer()
    }

    static func clipURL(_ filename: String) -> URL? {
        let docs = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first
        return docs?
            .appendingPathComponent("CoughClips", isDirectory: true)
            .appendingPathComponent(filename)
    }
}
