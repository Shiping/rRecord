import Foundation
import HealthKit

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
            HKQuantityType.quantityType(forIdentifier: .activeEnergyBurned)!
        ])
    }
    
    var requiredCategoryTypes: Set<HKCategoryType> {
        Set([
            HKCategoryType.categoryType(forIdentifier: .sleepAnalysis)!
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
            error = .healthKitNotAvailable
            return
        }
        
        let hasUnauthorizedTypes = self.requiredTypes.contains { type in
            self.authorizationStatus(for: type) == .notDetermined
        }
        
        self.hasPermission = !hasUnauthorizedTypes
    }
    
    @MainActor
    func ensureAuthorization() async throws {
        guard isHealthKitAvailable else {
            throw HealthStoreError.healthKitNotAvailable
        }

        if hasPermission { return }
        
        // Try authorization with retries
        for attempt in 1...3 {
            do {
                try await tryAuthorizationWithTimeout()
                checkAuthorizationStatus()
                return
            } catch is TimeoutError {
                if attempt == 3 {
                    throw HealthStoreError.authorizationFailed(NSError(
                        domain: "HealthKit",
                        code: -1,
                        userInfo: [NSLocalizedDescriptionKey: "授权请求超时"]
                    ))
                }
                try await Task.sleep(nanoseconds: UInt64(1_000_000_000)) // 1 second delay before retry
            } catch {
                throw error // Propagate other errors immediately
            }
        }
    }
    private func tryAuthorizationWithTimeout() async throws {
        try await withThrowingTaskGroup(of: Void.self) { group in
            // Authorization task
            group.addTask {
                try await self.requestAuthorization()
            }
            
            // Timeout task with 30 seconds
            group.addTask {
                try await Task.sleep(nanoseconds: 30_000_000_000)
                throw TimeoutError()
            }
            
            // Wait for first completion and handle result
            do {
                // If we get here, authorization succeeded
                try await group.next()
                group.cancelAll() // Cancel any remaining tasks
            } catch {
                group.cancelAll() // Ensure cleanup on error
                throw error
            }
        }
    }

    @MainActor
    private func requestAuthorization() async throws {
        // Reset state before attempting authorization
        self.error = nil
        self.hasPermission = false
        
        return try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            let typesToShare = self.requiredTypes
            let typesToRead = self.requiredTypes
            
            self.healthStore.requestAuthorization(toShare: typesToShare, read: typesToRead) { [weak self] success, error in
                guard let self = self else {
                    continuation.resume(throwing: HealthStoreError.authorizationFailed(NSError(
                        domain: "HealthKit",
                        code: -1,
                        userInfo: [NSLocalizedDescriptionKey: "上下文已失效"]
                    )))
                    return
                }

                if let error = error {
                    continuation.resume(throwing: HealthStoreError.authorizationFailed(error))
                    return
                }

                if success {
                    Task { @MainActor in
                        self.hasPermission = true
                        continuation.resume()
                    }
                } else {
                    continuation.resume(throwing: HealthStoreError.authorizationFailed(NSError(
                        domain: "HealthKit",
                        code: -1,
                        userInfo: [NSLocalizedDescriptionKey: "未能获取健康数据访问权限"]
                    )))
                }
            }
        }
    }
}

struct TimeoutError: Error { }
