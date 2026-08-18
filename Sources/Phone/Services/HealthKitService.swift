import HealthKit

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
}
