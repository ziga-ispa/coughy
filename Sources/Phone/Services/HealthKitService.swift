import HealthKit

actor HealthKitService {
    private let store = HKHealthStore()

    private var shareTypes: Set<HKSampleType> {
        [
            HKQuantityType(.heartRate),
            HKQuantityType(.bodyMass)
        ]
    }

    private var readTypes: Set<HKObjectType> {
        [
            HKQuantityType(.heartRate),
            HKQuantityType(.bodyMass)
        ]
    }

    func requestAuthorization() async throws {
        guard HKHealthStore.isHealthDataAvailable() else { return }
        try await store.requestAuthorization(toShare: shareTypes, read: readTypes)
    }
}
