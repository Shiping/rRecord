import Foundation
import HealthKit

extension HealthStore {
    // MARK: - HealthKit Authorization
    @objc public dynamic func requestInitialAuthorization(completion: @escaping (Bool) -> Void) {
        print("requestInitialAuthorization called")
        // First check if HealthKit is available on this device
        guard HKHealthStore.isHealthDataAvailable() else {
            print("HealthKit is not available")
            DispatchQueue.main.async {
                completion(true)
            }
            return
        }

        // Define all required health data types
        guard let stepCountType = HKObjectType.quantityType(forIdentifier: .stepCount),
              let sleepType = HKObjectType.categoryType(forIdentifier: .sleepAnalysis),
              let flightsClimbedType = HKObjectType.quantityType(forIdentifier: .flightsClimbed),
              let activeEnergyType = HKObjectType.quantityType(forIdentifier: .activeEnergyBurned),
              let restingEnergyType = HKObjectType.quantityType(forIdentifier: .basalEnergyBurned),
              let heartRateType = HKObjectType.quantityType(forIdentifier: .heartRate),
              let distanceType = HKObjectType.quantityType(forIdentifier: .distanceWalkingRunning),
              let oxygenSaturationType = HKObjectType.quantityType(forIdentifier: .oxygenSaturation),
              let bodyFatType = HKObjectType.quantityType(forIdentifier: .bodyFatPercentage) else {
            print("Failed to create HealthKit data types")
            DispatchQueue.main.async {
                completion(false)
            }
            return
        }

        let typesToRead: Set<HKSampleType> = [
            stepCountType,
            sleepType,
            flightsClimbedType,
            activeEnergyType,
            restingEnergyType,
            heartRateType,
            distanceType,
            oxygenSaturationType,
            bodyFatType
        ]

        // Request authorization with proper error handling
        print("Requesting HealthKit authorization")
        healthStore.requestAuthorization(toShare: nil, read: typesToRead) { success, error in
            DispatchQueue.main.async {
                if let error = error {
                    print("HealthKit authorization error: \(error.localizedDescription)")
                    completion(false)
                    return
                }

                if success {
                    print("HealthKit authorization successful")
                    completion(true)
                } else {
                    print("HealthKit authorization denied")
                    completion(false)
                }
            }
        }
    }
}
