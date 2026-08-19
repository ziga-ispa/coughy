import Foundation
import Combine

@MainActor
final class CoughMonitorViewModel: ObservableObject {

    @Published private(set) var isMonitoring = false
    @Published private(set) var currentSession: CoughSession?
    @Published private(set) var completedSession: CoughSession?
    @Published private(set) var events: [CoughEvent] = []
    @Published private(set) var errorMessage: String?
    @Published private(set) var sessionNumber: Int = UserDefaults.standard.integer(forKey: "sessionCount")

    private var engine: CoughDetectionServiceProtocol?
    private let historyStore: HistoryStore
    private let healthKit = HealthKitService()
    private let liveActivity = MonitoringLiveActivity()

    init(historyStore: HistoryStore) {
        self.historyStore = historyStore
    }

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
            
            let start = Date()
            currentSession = CoughSession(id: UUID(), startDate: start, events: [])
            events = []
            isMonitoring = true
            errorMessage = nil

            // Live Activity + tombol Stop dari widget
            liveActivity.start(startDate: start)
            MonitoringCoordinator.shared.stopHandler = { [weak self] in
                self?.stopSession()
            }
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
        
        liveActivity.end()
        MonitoringCoordinator.shared.stopHandler = nil
        
        if var session = currentSession {
            session.events = events
            session.endDate = Date()
            currentSession = session
            historyStore.save(session: session)
            completedSession = session
            
            NotificationManager.notifyReportReady()   // report siap
        }
    }
    
    func dismissResult() {
        completedSession = nil
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

            // Otomatis tulis ke Health app setiap ada batuk terdeteksi
            await self.healthKit.saveCough(event)
        }
    }
}
