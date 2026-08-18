import Foundation

@MainActor
final class HistoryStore: ObservableObject {
    @Published private(set) var sessions: [CoughSession] = []
    private let fileURL: URL

    init() {
        let docs = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        fileURL = docs.appendingPathComponent("coughy_history.json")
        load()
        purgeOldSessions()
    }

    func save(session: CoughSession) {
        sessions.append(session)
        persist()
    }

    func delete(session: CoughSession) {
        sessions.removeAll { $0.id == session.id }
        persist()
    }

    private func purgeOldSessions() {
        let cutoff = Calendar.current.date(byAdding: .day, value: -30, to: Date())!
        let before = sessions.count
        sessions.removeAll { $0.startDate < cutoff }
        if sessions.count != before { persist() }
    }

    private func load() {
        guard let data = try? Data(contentsOf: fileURL) else { return }
        sessions = (try? JSONDecoder().decode([CoughSession].self, from: data)) ?? []
    }

    private func persist() {
        guard let data = try? JSONEncoder().encode(sessions) else { return }
        try? data.write(to: fileURL, options: .atomic)
    }
}
