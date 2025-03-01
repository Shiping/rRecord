import Foundation
import HealthKit

@MainActor
extension HealthStore {
    
    func authorizationStatus(for type: HKSampleType) -> HKAuthorizationStatus {
        healthStore.authorizationStatus(for: type)
    }
    
    var requiredQuantityTypes: Set<HKQuantityType> {
        Set([
            HKQuantityType.quantityType(forIdentifier: .bodyMass)!,
            HKQuantityType.quantityType(forIdentifier: .bodyFatPercentage)!,
            HKQuantityType.quantityType(forIdentifier: .bodyMassIndex)!,
            HKQuantityType.quantityType(forIdentifier: .bloodGlucose)!,
            HKQuantityType.quantityType(forIdentifier: .bloodPressureSystolic)!,
            HKQuantityType.quantityType(forIdentifier: .bloodPressureDiastolic)!,
            HKQuantityType.quantityType(forIdentifier: .stepCount)!,
            HKQuantityType.quantityType(forIdentifier: .flightsClimbed)!,
            HKQuantityType.quantityType(forIdentifier: .activeEnergyBurned)!,
            // Add other quantity types here
            HKQuantityType.quantityType(forIdentifier: .heartRate)!,
            HKQuantityType.quantityType(forIdentifier: .bodyTemperature)!,
            HKQuantityType.quantityType(forIdentifier: .height)!
        ])
    }
    
    var requiredCategoryTypes: Set<HKCategoryType> {
        Set([
            HKCategoryType.categoryType(forIdentifier: .sleepAnalysis)!
            // Add other category types here
        ])
    }
    
    var requiredTypes: Set<HKSampleType> {
        Set(requiredQuantityTypes).union(requiredCategoryTypes)
    }
    
    var isHealthKitAvailable: Bool {
        HKHealthStore.isHealthDataAvailable()
    }
    
    func checkAuthorizationStatus() {
        guard isHealthKitAvailable else {
            authorizeError = .healthKitNotAvailable
            return
        }
        
        let hasUnauthorizedTypes = self.requiredTypes.contains { type in
            self.authorizationStatus(for: type) == .notDetermined
        }
        
        setState(!hasUnauthorizedTypes)
    }
    
    internal func requestAuthorization() async throws {
        // Reset state before attempting authorization
        authorizeError = nil
        setState(false)
        
        return try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            let typesToShare = self.requiredTypes
            let typesToRead = self.requiredTypes
            
            self.healthStore.requestAuthorization(toShare: typesToShare, read: typesToRead) { [weak self] success, error in
                guard let self = self else {
                    continuation.resume(throwing: HealthStoreError.authorizationFailed(NSError(
                        domain: "HealthKit",
                        code: -1,
                        userInfo: [NSLocalizedDescriptionKey: "Context lost"]
                    )))
                    return
                }

                if let error = error {
                    continuation.resume(throwing: HealthStoreError.authorizationFailed(error as NSError))
                    return
                }

                if success {
                    Task { @MainActor in
                        self.setState(true)
                        continuation.resume()
                    }
                } else {
                    continuation.resume(throwing: HealthStoreError.authorizationFailed(NSError(
                        domain: "HealthKit",
                        code: -1,
                        userInfo: [NSLocalizedDescriptionKey: "Failed to get HealthKit authorization"]
                    )))
                }
            }
        }
    }
}

struct TimeoutError: Error { }
