import Foundation
import Combine

@MainActor
final class CoughMonitorViewModel: ObservableObject {

    @Published private(set) var isMonitoring = false
    @Published private(set) var currentSession: CoughSession?
    @Published private(set) var events: [CoughEvent] = []
    @Published private(set) var errorMessage: String?
    @Published private(set) var sessionNumber: Int = UserDefaults.standard.integer(forKey: "sessionCount")

    private var engine: CoughDetectionServiceProtocol?

    // MARK: - Session Control

    func startSession() {
        guard !isMonitoring else { return }

        let e = CoughMonitorEngine()
        e.delegate = self
        engine = e

        do {
            try e.start()
            let next = UserDefaults.standard.integer(forKey: "sessionCount") + 1
            UserDefaults.standard.set(next, forKey: "sessionCount")
            sessionNumber = next
            currentSession = CoughSession(id: UUID(), startDate: Date(), events: [])
            events = []
            isMonitoring = true
            errorMessage = nil
        } catch {
            errorMessage = "Could not start monitoring: \(error.localizedDescription)"
            engine = nil
        }
    }

    func stopSession() {
        guard isMonitoring else { return }
        engine?.stop()
        engine = nil
        isMonitoring = false
        if var session = currentSession {
            session.events = events
            currentSession = session
        }
    }

    // MARK: - Formatting (kept out of View layer)

    func dbfsString(rms: Float) -> String {
        let db = 20.0 * log10(max(Double(rms), 1e-10))
        return String(format: "%.1f dBFS", db)
    }

    func loudnessLabel(rms: Float) -> String {
        let db = 20.0 * log10(max(Double(rms), 1e-10))
        switch db {
        case ..<(-40): return "quiet"
        case ..<(-25): return "moderate"
        default:       return "loud"
        }
    }

    func durationString(from session: CoughSession) -> String {
        let seconds = Int(session.duration)
        let m = seconds / 60; let s = seconds % 60
        return String(format: "%d:%02d", m, s)
    }
}

// MARK: - CoughDetectionServiceDelegate

extension CoughMonitorViewModel: CoughDetectionServiceDelegate {
    nonisolated func coughDetectionService(_ service: CoughDetectionServiceProtocol, didDetect event: CoughEvent) {
        Task { @MainActor [weak self] in
            guard let self else { return }
            self.events.insert(event, at: 0)
            self.currentSession?.events = self.events
        }
    }
}
