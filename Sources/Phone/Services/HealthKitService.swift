import HealthKit

struct SymptomRecord: Identifiable {
    let id = UUID()
    let name: String
    let date: Date
    let severity: String
}

actor HealthKitService {
    private let store = HKHealthStore()
    
    private var shareTypes: Set<HKSampleType> {
        [
            HKCategoryType(.coughing),
            HKCategoryType(.fever),
            HKCategoryType(.runnyNose),
            HKCategoryType(.soreThroat)
        ]
    }
    
    private var readTypes: Set<HKObjectType> {
        [
            HKCategoryType(.coughing),
            HKCategoryType(.fever),
            HKCategoryType(.runnyNose),
            HKCategoryType(.soreThroat)
        ]
    }
    
    func requestAuthorization() async throws {
        guard HKHealthStore.isHealthDataAvailable() else { return }
        try await store.requestAuthorization(toShare: shareTypes, read: readTypes)
    }
    
    func fetchSymptoms(from startDate: Date, to endDate: Date) async throws -> [SymptomRecord] {
        guard HKHealthStore.isHealthDataAvailable() else { return [] }
        
        let types: [(HKCategoryTypeIdentifier, String)] = [
            (.fever, "Fever"),
            (.runnyNose, "Runny Nose"),
            (.soreThroat, "Sore Throat")
        ]
        
        let predicate = HKQuery.predicateForSamples(
            withStart: startDate,
            end: endDate,
            options: []
        )
        
        var records: [SymptomRecord] = []
        for (identifier, label) in types {
            let categoryType = HKCategoryType(identifier)
            let samples = try await categorySamples(of: categoryType, predicate: predicate)
            for sample in samples {
                records.append(
                    SymptomRecord(
                        name: label,
                        date: sample.startDate,
                        severity: Self.severityDescription(for: sample.value)
                    )
                )
            }
        }
        return records.sorted { $0.date < $1.date }
    }
    
    private func categorySamples(
        of type: HKCategoryType,
        predicate: NSPredicate
    ) async throws -> [HKCategorySample] {
        try await withCheckedThrowingContinuation { continuation in
            let sort = NSSortDescriptor(key: HKSampleSortIdentifierStartDate, ascending: true)
            let query = HKSampleQuery(
                sampleType: type,
                predicate: predicate,
                limit: HKObjectQueryNoLimit,
                sortDescriptors: [sort]
            ) { _, samples, error in
                if let error {
                    continuation.resume(throwing: error)
                    return
                }
                continuation.resume(returning: (samples as? [HKCategorySample]) ?? [])
            }
            store.execute(query)
        }
    }
    
    private static func severityDescription(for value: Int) -> String {
        guard let severity = HKCategoryValueSeverity(rawValue: value) else { return "Present" }
        switch severity {
        case .notPresent: return "Not Present"
        case .mild:       return "Mild"
        case .moderate:   return "Moderate"
        case .severe:     return "Severe"
        case .unspecified: return "Present"
        @unknown default:  return "Present"
        }
    }
}
