import Foundation

struct CoughEvent: Identifiable {
    let id: UUID
    let timestamp: Date
    enum CoughType { case dry, wet }
    let type: CoughType
    let dryScore: Double
    let wetScore: Double
    let confidence: Double
    let peakRMS: Float
    let windowCount: Int
}

struct CoughFit {
    var events: [CoughEvent]
}

struct CoughSession {
    let id: UUID
    let startDate: Date
    var events: [CoughEvent]

    var dryCount: Int { events.filter { $0.type == .dry }.count }
    var wetCount: Int { events.filter { $0.type == .wet }.count }
    var duration: TimeInterval { Date().timeIntervalSince(startDate) }
}
