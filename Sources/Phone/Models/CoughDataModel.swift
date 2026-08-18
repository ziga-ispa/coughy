import Foundation

struct CoughEvent: Identifiable, Codable {
    let id: UUID
    let timestamp: Date
    enum CoughType: String, Codable { case dry, wet }
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

struct CoughSession: Identifiable, Codable {
    let id: UUID
    let startDate: Date
    var endDate: Date?
    var events: [CoughEvent]
    var notes: String?

    var dryCount: Int { events.filter { $0.type == .dry }.count }
    var wetCount: Int { events.filter { $0.type == .wet }.count }
    var duration: TimeInterval { (endDate ?? Date()).timeIntervalSince(startDate) }
}
