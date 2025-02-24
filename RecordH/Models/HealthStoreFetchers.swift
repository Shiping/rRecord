import Foundation
import HealthKit

extension HealthStore {
    
    func fetchQuantitySamples(for type: HKQuantityType,
                            from startDate: Date,
                            to endDate: Date = Date()) async throws -> [HKQuantitySample] {
        try await withCheckedThrowingContinuation { continuation in
            let predicate = HKQuery.predicateForSamples(withStart: startDate,
                                                       end: endDate)
            
            let query = HKSampleQuery(
                sampleType: type,
                predicate: predicate,
                limit: HKObjectQueryNoLimit,
                sortDescriptors: [NSSortDescriptor(key: HKSampleSortIdentifierStartDate,
                                                 ascending: false)]
            ) { _, samples, error in
                if let error = error {
                    continuation.resume(throwing: error)
                } else {
                    let quantitySamples = samples as? [HKQuantitySample] ?? []
                    continuation.resume(returning: quantitySamples)
                }
            }
            
            healthStore.execute(query)
        }
    }
    
    func fetchCategorySamples(for type: HKCategoryType,
                            from startDate: Date,
                            to endDate: Date = Date()) async throws -> [HKCategorySample] {
        try await withCheckedThrowingContinuation { continuation in
            let predicate = HKQuery.predicateForSamples(withStart: startDate,
                                                       end: endDate)
            
            let query = HKSampleQuery(
                sampleType: type,
                predicate: predicate,
                limit: HKObjectQueryNoLimit,
                sortDescriptors: [NSSortDescriptor(key: HKSampleSortIdentifierStartDate,
                                                 ascending: false)]
            ) { _, samples, error in
                if let error = error {
                    continuation.resume(throwing: error)
                } else {
                    let categorySamples = samples as? [HKCategorySample] ?? []
                    continuation.resume(returning: categorySamples)
                }
            }
            
            healthStore.execute(query)
        }
    }
    
    func fetchSamples(for type: HKSampleType,
                     from startDate: Date,
                     to endDate: Date = Date()) async throws -> [HKSample] {
        if let quantityType = type as? HKQuantityType {
            return try await fetchQuantitySamples(for: quantityType, from: startDate, to: endDate)
        } else if let categoryType = type as? HKCategoryType {
            return try await fetchCategorySamples(for: categoryType, from: startDate, to: endDate)
        }
        throw HealthStoreError.unsupportedType
    }
    
    func fetchLatestSample(for type: HKSampleType) async throws -> HKSample? {
        let samples = try await fetchSamples(for: type, from: Date.distantPast)
        return samples.first
    }
    
    func fetchStatistics(for type: HKQuantityType,
                        from startDate: Date,
                        to endDate: Date = Date(),
                        options: HKStatisticsOptions = .discreteAverage) async throws -> HKStatistics {
        try await withCheckedThrowingContinuation { continuation in
            let predicate = HKQuery.predicateForSamples(withStart: startDate,
                                                       end: endDate)
            
            let query = HKStatisticsQuery(
                quantityType: type,
                quantitySamplePredicate: predicate,
                options: options
            ) { _, statistics, error in
                if let error = error {
                    continuation.resume(throwing: error)
                } else if let statistics = statistics {
                    continuation.resume(returning: statistics)
                } else {
                    continuation.resume(throwing: HealthStoreError.dataNotAvailable)
                }
            }
            
            healthStore.execute(query)
        }
    }
    
    func startObservingChanges(for types: Set<HKSampleType>, updateHandler: @escaping () -> Void) {
        for type in types {
            let query = HKObserverQuery(sampleType: type, predicate: nil) { _, completion, error in
                if let error = error {
                    print("Observer Query Error: \(error.localizedDescription)")
                } else {
                    DispatchQueue.main.async {
                        updateHandler()
                    }
                }
                completion()
            }
            
            healthStore.execute(query)
            if let quantityType = type as? HKQuantityType {
                healthStore.enableBackgroundDelivery(for: quantityType,
                                                   frequency: .immediate) { success, error in
                    if let error = error {
                        print("Background delivery setup failed: \(error.localizedDescription)")
                    }
                }
            }
        }
    }
}
