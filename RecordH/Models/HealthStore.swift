import Foundation
import HealthKit

@MainActor
public final class HealthStore: ObservableObject {
    @MainActor
    public static let shared: HealthStore = {
        let instance = HealthStore()
        Task { @MainActor in
            await instance.initialize()
        }
        return instance
    }()
    
    let healthStore = HKHealthStore()
    private(set) var configManager: AIConfigurationManager!
    private(set) var aiManager: AIManager!
    
    @Published var authorizeError: HealthStoreError?
    @Published private var records: [HealthMetric: [HealthRecord]] = [:]
    @Published private(set) var isAuthorized = false
    @Published private(set) var isLoading = false
    @Published private(set) var isFetchingData = false
    @Published private(set) var lastUpdate: Date?
    @Published private(set) var error: Error?
    @Published public var userProfile = UserProfile.sample
    var hasPermission = false

    private let supportedMetrics: [HealthMetric] = [
        .bodyMass,
        .bloodPressureSystolic,
        .bloodPressureDiastolic,
        .bloodGlucose,
        .stepCount,
        .flightsClimbed,
        .activeEnergy,
        .bodyFat,
        .heartRate,
        .bodyTemperature,
        .height
    ]
    
    private var healthKitTypes: [HealthMetric: HKQuantityType] = [
        .bodyMass: HKQuantityType(.bodyMass),
        .bloodPressureSystolic: HKQuantityType(.bloodPressureSystolic),
        .bloodPressureDiastolic: HKQuantityType(.bloodPressureDiastolic),
        .bloodGlucose: HKQuantityType(.bloodGlucose),
        .stepCount:  HKQuantityType(.stepCount),
        .flightsClimbed: HKQuantityType(.flightsClimbed),
        .activeEnergy: HKQuantityType(.activeEnergyBurned),
        .bodyFat: HKQuantityType(.bodyFatPercentage),
        .heartRate: HKQuantityType(.heartRate),
        .bodyTemperature: HKQuantityType(.bodyTemperature),
        .height: HKQuantityType(.height)
    ]
    
    private init() {}
    
    private func initialize() async {
        setupDefaults()
        // Initialize dependencies
        configManager = AIConfigurationManager.shared
        aiManager = AIManager.shared
        
        // Load user data
        await loadUserProfile()
        try? await setupBackgroundDelivery()
    }
    
    private func setupDefaults() {
        // Setup initial state that doesn't require async
        isAuthorized = false
        isLoading = false
        isFetchingData = false
        hasPermission = false
    }
    
    // MARK: - User Profile Management
    
    public func updateUserProfile(gender: Gender? = nil,
                                birthday: Date? = nil,
                                height: Double? = nil,
                                location: String? = nil) {
        var updatedProfile = userProfile
        updatedProfile.update(gender: gender,
                            birthday: birthday,
                            height: height,
                            location: location)
        userProfile = updatedProfile
        saveUserProfile()
    }
    
    internal func saveUserProfile() {
        if let data = try? JSONEncoder().encode(userProfile) {
            UserDefaults.standard.set(data, forKey: "userProfile")
        }
    }
    
    private func loadUserProfile() async {
        if let data = UserDefaults.standard.data(forKey: "userProfile"),
           let profile = try? JSONDecoder().decode(UserProfile.self, from: data) {
            userProfile = profile
        }
    }
    
    // MARK: - Authorization Management
    
    // MARK: - Data Management
    
    public func requestAccess() async throws -> Bool {
        try await ensureAuthorizationWithRetry()
        return hasPermission
    }
    
    private func ensureAuthorizationWithRetry(retryCount: Int = 3) async throws {
        guard HKHealthStore.isHealthDataAvailable() else {
            setState(false)
            throw HealthStoreError.healthKitNotAvailable
        }
        
        if isAuthorized { return }
        
        for attempt in 1...retryCount {
            do {
                let types = Set(supportedMetrics.compactMap { healthKitTypes[$0] })
                try await healthStore.requestAuthorization(toShare: types, read: types)
                
                let authorized = supportedMetrics.allSatisfy { metric in
                    guard let type = healthKitTypes[metric] else { return false }
                    return healthStore.authorizationStatus(for: type) == .sharingAuthorized
                }
                setState(authorized)
                return
                
            } catch let error {
                if attempt < retryCount {
                    try await Task.sleep(nanoseconds: 1_000_000_000) // 1 second delay
                    continue
                }
                throw error
            }
        }
    }

    public func refreshData() async {
        do {
            try await refreshAllData()
        } catch {
            // Error is already stored in authorizeError
        }
    }

    internal func fetchLatestData() async throws {
        isLoading = true
        defer { isLoading = false }
        
        var newRecords: [HealthMetric: [HealthRecord]] = [:]
        
        for metric in supportedMetrics {
            guard let type = healthKitTypes[metric] else { continue }
            
            let predicate = HKQuery.predicateForSamples(withStart: Date.distantPast, end: Date(), options: .strictEndDate)
            let sortDescriptor = NSSortDescriptor(key: HKSampleSortIdentifierStartDate, ascending: false)
            
            do {
                let samples = try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<[HKSample], Error>) in
                    let query = HKSampleQuery(sampleType: type,
                                            predicate: predicate,
                                            limit: 100,
                                            sortDescriptors: [sortDescriptor]) { _, results, error in
                        if let error = error {
                            continuation.resume(throwing: error)
                        } else {
                            continuation.resume(returning: results ?? [])
                        }
                    }
                    self.healthStore.execute(query)
                }
                
                let healthRecords = samples.compactMap { sample -> HealthRecord? in
                    guard let quantitySample = sample as? HKQuantitySample else { return nil }
                    let value = quantitySample.quantity.doubleValue(for: metric.unit)
                    return HealthRecord(id: sample.uuid, 
                                     metric: metric,
                                     value: value,
                                     date: sample.startDate)
                }
                
                if !healthRecords.isEmpty {
                    newRecords[metric] = healthRecords
                }
            } catch {
                print("Error fetching \(metric): \(error)")
            }
        }
        
        records = newRecords
    }
    
    internal func save(value: Double, for metric: HealthMetric, date: Date = Date()) async throws {
        guard let type = healthKitTypes[metric] else {
            throw HealthStoreError.unsupportedMetric
        }
        
        let quantity = HKQuantity(unit: metric.unit, doubleValue: value)
        let sample = HKQuantitySample(type: type,
                                    quantity: quantity,
                                    start: date,
                                    end: date)
        
        try await healthStore.save(sample)
        try await fetchLatestData()
    }
    
    internal func delete(_ record: HealthRecord) async throws {
        guard let type = healthKitTypes[record.metric] else {
            throw HealthStoreError.unsupportedMetric
        }
        
        let predicate = HKQuery.predicateForObject(with: record.id)
        
        let samples = try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<[HKSample], Error>) in
            let query = HKSampleQuery(sampleType: type,
                                    predicate: predicate,
                                    limit: 1,
                                    sortDescriptors: nil) { _, results, error in
                if let error = error {
                    continuation.resume(throwing: error)
                } else {
                    continuation.resume(returning: results ?? [])
                }
            }
            healthStore.execute(query)
        }
        
        if let sampleToDelete = samples.first {
            try await healthStore.delete(sampleToDelete)
            try await fetchLatestData()
        }
    }
    
    // MARK: - Background Updates
    
    private func setupBackgroundDelivery() async throws {
        for metric in supportedMetrics {
            guard let type = healthKitTypes[metric] else { continue }
            
            let frequency: HKUpdateFrequency = {
                switch metric {
                case .heartRate, .bloodPressureSystolic, .bloodPressureDiastolic:
                    return .hourly
                default:
                    return .immediate
                }
            }()
            
            try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
                healthStore.enableBackgroundDelivery(for: type, frequency: frequency) { _, error in
                    if let error = error {
                        print("Failed to enable background delivery for \(metric): \(error)")
                    }
                    if let error = error {
                        continuation.resume(throwing: error)
                    } else {
                        continuation.resume()
                    }
                }
            }
        }
    }
    
    // MARK: - State Management
    
    internal func setState(_ authorized: Bool) {
        isAuthorized = authorized
        hasPermission = authorized
    }
    
    internal func clearUserDefaultsData() {
        records = [:]
        error = nil
        authorizeError = nil
        isAuthorized = false
        hasPermission = false
        UserDefaults.standard.removeObject(forKey: "userProfile")
        userProfile = UserProfile.sample
    }
    
    internal func refreshMetrics() async throws {
        try await fetchLatestData()
    }
    
    internal func setIsFetchingData(_ value: Bool) {
        isFetchingData = value
    }
    
    internal func setLastUpdate(_ date: Date) {
        lastUpdate = date
    }
    
    internal func setError(_ error: Error?) {
        self.error = error
    }
    
    public func records(for metric: HealthMetric) -> [HealthRecord] {
        return records[metric] ?? []
    }
    
    public func latestRecord(for metric: HealthMetric) -> HealthRecord? {
        return records(for: metric).first
    }
    
    internal func updateRecord(_ record: HealthRecord) {
        var currentRecords = records[record.metric] ?? []
        if let index = currentRecords.firstIndex(where: { $0.id == record.id }) {
            currentRecords[index] = record
        } else {
            currentRecords.append(record)
        }
        records[record.metric] = currentRecords
    }
    
    // MARK: - Data Refresh
    
    internal func refreshAllData() async throws {
        guard !isFetchingData else { return }
        setIsFetchingData(true)
        defer { setIsFetchingData(false) }
        
        do {
            try await ensureAuthorizationWithRetry()
            try await fetchLatestData()
            NotificationCenter.default.post(name: .init("HealthDataDidUpdate"), object: nil)
            setLastUpdate(Date())
        } catch {
            authorizeError = error as? HealthStoreError ?? .fetchFailed(error as NSError)
            throw error
        }
    }
}
