import Foundation
import SwiftUI
import HealthKit

private enum APIError: Error {
    case notEnabled(String)
    case notInitialized(String)
}

@available(macOS 10.13, iOS 15.0, *)
public class HealthStore: ObservableObject {
    // MARK: - Published Properties
    @Published var userProfile: UserProfile?
    @Published var healthRecords: [HealthRecord] = []
    @Published var dailyNotes: [DailyNote] = []

    // MARK: - Private Properties
    private let healthStore = HKHealthStore()
    private var healthAdvisorProvider: HealthAdvisorProvider?
    private let fileManager = FileManager.default
    
    // MARK: - File Storage URLs
    private var documentsDirectory: URL {
        fileManager.urls(for: .cachesDirectory, in: .userDomainMask)[0]
    }

    private var profileURL: URL {
        documentsDirectory.appendingPathComponent("userProfile.json")
    }

    private var recordsURL: URL {
        documentsDirectory.appendingPathComponent("healthRecords.json")
    }

    private var notesURL: URL {
        documentsDirectory.appendingPathComponent("dailyNotes.json")
    }

    // MARK: - Initialization
    public init() {
        print("Initializing HealthStore")
        let config = HealthAdvisorProvider.Configuration(healthStore: self)
        healthAdvisorProvider = HealthAdvisorProvider(config: config)

        // Initialize storage
        do {
            try createDirectoryIfNeeded()
            loadData()
        } catch {
            print("Error initializing storage: \(error)")
        }
    }

    // MARK: - Storage Management
    private func createDirectoryIfNeeded() throws {
        if !fileManager.fileExists(atPath: documentsDirectory.path) {
            try fileManager.createDirectory(at: documentsDirectory, withIntermediateDirectories: true)
        }
    }

    private func loadData() {
        do {
            if let profileData = try? Data(contentsOf: profileURL) {
                userProfile = try JSONDecoder().decode(UserProfile.self, from: profileData)
            }
            
            if let recordsData = try? Data(contentsOf: recordsURL) {
                healthRecords = try JSONDecoder().decode([HealthRecord].self, from: recordsData)
            }
            
            if let notesData = try? Data(contentsOf: notesURL) {
                dailyNotes = try JSONDecoder().decode([DailyNote].self, from: notesData)
            }
        } catch {
            print("Error loading data: \(error)")
        }
    }

    private func saveData() {
        do {
            if let profile = userProfile {
                let profileData = try JSONEncoder().encode(profile)
                try profileData.write(to: profileURL)
            }
            
            let recordsData = try JSONEncoder().encode(healthRecords)
            try recordsData.write(to: recordsURL)
            
            let notesData = try JSONEncoder().encode(dailyNotes)
            try notesData.write(to: notesURL)
        } catch {
            print("Error saving data: \(error)")
        }
    }

    // MARK: - Health Records Management
    func getLatestRecord(for type: HealthRecord.RecordType) -> HealthRecord? {
        return healthRecords
            .filter { $0.type == type }
            .max { $0.date < $1.date }
    }
    
    func getRecords(for type: HealthRecord.RecordType, limit: Int? = nil) -> [HealthRecord] {
        var records = healthRecords
            .filter { $0.type == type }
            .sorted { $0.date > $1.date }
        
        if let limit = limit {
            records = Array(records.prefix(limit))
        }
        
        return records
    }
    
    func addHealthRecord(_ record: HealthRecord) {
        healthRecords.append(record)
        saveData()
    }
    
    func updateHealthRecord(_ updatedRecord: HealthRecord) {
        if let index = healthRecords.firstIndex(where: { $0.id == updatedRecord.id }) {
            healthRecords[index] = updatedRecord
            saveData()
        }
    }
    
    func deleteHealthRecord(_ id: UUID) {
        healthRecords.removeAll { $0.id == id }
        saveData()
    }

    // MARK: - Notes Management
    func addDailyNote(_ note: DailyNote) {
        dailyNotes.append(note)
        saveData()
    }
    
    func updateDailyNote(_ updatedNote: DailyNote) {
        if let index = dailyNotes.firstIndex(where: { $0.id == updatedNote.id }) {
            dailyNotes[index] = updatedNote
            saveData()
        }
    }
    
    func deleteDailyNote(_ id: UUID) {
        dailyNotes.removeAll { $0.id == id }
        saveData()
    }
    
    public func getTodaysNotes() -> [DailyNote] {
        let calendar = Calendar.current
        return dailyNotes.filter { calendar.isDateInToday($0.date) }
    }
    
    // MARK: - Profile Management
    public func updateProfile(_ newProfile: UserProfile) {
        userProfile = newProfile
        saveData()
    }
    
    public func manualSyncToICloud(completion: @escaping (Bool) -> Void) {
        // Save data first
        saveData()
        
        // Check if iCloud is enabled
        let isICloudEnabled = UserDefaults.standard.bool(forKey: "iCloudSyncEnabled")
        if !isICloudEnabled {
            completion(false)
            return
        }
        
        // Simulate iCloud sync with a delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
            completion(true)
        }
    }
    
    // MARK: - AI Configuration Management
    public func updateSelectedAIConfiguration(_ id: UUID) {
        if var profile = userProfile {
            profile.selectedAIConfigurationId = id
            userProfile = profile
            saveData()
        }
    }
    
    public func generateHealthAdvice(userDescription: String, completion: @escaping (Result<[HealthAdvisorProvider.AdviceSection], Error>) -> Void) {
        guard let provider = healthAdvisorProvider else {
            completion(.failure(APIError.notInitialized("HealthAdvisorProvider not initialized")))
            return
        }
        
        // Only proceed if there's a selected configuration and it's enabled
        guard let selectedId = userProfile?.selectedAIConfigurationId,
              let selectedConfig = userProfile?.aiSettings.first(where: { $0.id == selectedId }),
              selectedConfig.enabled else {
            completion(.failure(APIError.notEnabled("No enabled AI configuration selected")))
            return
        }
        
        // Gather today's health data
        var healthData: [String: Any] = [:]
        
        if let steps = getLatestRecord(for: .steps) {
            healthData["steps"] = Int(steps.value)
        }
        
        if let heartRate = getLatestRecord(for: .heartRate) {
            healthData["heartRate"] = Int(heartRate.value)
        }
        
        if let activeEnergy = getLatestRecord(for: .activeEnergy) {
            healthData["activeEnergy"] = activeEnergy.value
        }
        
        if let restingEnergy = getLatestRecord(for: .restingEnergy) {
            healthData["restingEnergy"] = restingEnergy.value
        }
        
        if let distance = getLatestRecord(for: .distance) {
            healthData["distance"] = distance.value
        }
        
        if let bloodOxygen = getLatestRecord(for: .bloodOxygen) {
            healthData["bloodOxygen"] = bloodOxygen.value
        }
        
        if let bodyFat = getLatestRecord(for: .bodyFat) {
            healthData["bodyFat"] = bodyFat.value
        }
        
        if let flightsClimbed = getLatestRecord(for: .flightsClimbed) {
            healthData["flightsClimbed"] = Int(flightsClimbed.value)
        }
        
        if let weight = getLatestRecord(for: .weight) {
            healthData["weight"] = weight.value
            if let height = userProfile?.height {
                let heightInMeters = height / 100
                let bmi = weight.value / (heightInMeters * heightInMeters)
                healthData["bmi"] = bmi
            }
        }
        
        if let bloodPressure = getLatestRecord(for: .bloodPressure) {
            healthData["bloodPressure"] = [
                "systolic": bloodPressure.value,
                "diastolic": bloodPressure.secondaryValue ?? 0
            ]
        }
        
        if let bloodSugar = getLatestRecord(for: .bloodSugar) {
            healthData["bloodSugar"] = bloodSugar.value
        }
        
        if let bloodLipids = getLatestRecord(for: .bloodLipids) {
            healthData["bloodLipids"] = bloodLipids.value
        }
        
        if let uricAcid = getLatestRecord(for: .uricAcid) {
            healthData["uricAcid"] = uricAcid.value
        }
        
        // Calculate age if birthDate is available
        var age: Int?
        if let birthDate = userProfile?.birthDate {
            let calendar = Calendar.current
            age = calendar.dateComponents([.year], from: birthDate, to: Date()).year
        }
        
        // Get gender
        let gender = userProfile?.gender.rawValue
        
        // Request health advice
        provider.getHealthAdvice(
            healthData: healthData,
            userDescription: userDescription,
            userAge: age,
            userGender: gender,
            completion: completion
        )
    }

    // MARK: - HealthKit Integration
    @objc public dynamic func refreshHealthData(completion: @escaping () -> Void = {}) {
        fetchLatestHealthData(completion: completion)
    }
    
    private func queueHealthDataFetch() {
        DispatchQueue.main.async {
            self.refreshHealthData()
        }
    }

    @objc public dynamic func requestInitialAuthorization(completion: @escaping (Bool) -> Void) {
        guard let stepCountType = HKObjectType.quantityType(forIdentifier: .stepCount),
              let sleepType = HKObjectType.categoryType(forIdentifier: .sleepAnalysis),
              let flightsClimbedType = HKObjectType.quantityType(forIdentifier: .flightsClimbed),
              let activeEnergyType = HKObjectType.quantityType(forIdentifier: .activeEnergyBurned),
              let restingEnergyType = HKObjectType.quantityType(forIdentifier: .basalEnergyBurned),
              let heartRateType = HKObjectType.quantityType(forIdentifier: .heartRate),
              let distanceType = HKObjectType.quantityType(forIdentifier: .distanceWalkingRunning),
              let oxygenSaturationType = HKObjectType.quantityType(forIdentifier: .oxygenSaturation),
              let bodyFatType = HKObjectType.quantityType(forIdentifier: .bodyFatPercentage) else {
            completion(false)
            return
        }
        
        let typesToRead: Set<HKSampleType> = [stepCountType, sleepType, flightsClimbedType, activeEnergyType, restingEnergyType, heartRateType, distanceType, oxygenSaturationType, bodyFatType]
        
        healthStore.requestAuthorization(toShare: nil, read: typesToRead) { [weak self] success, error in
            DispatchQueue.main.async {
                if success {
                    self?.queueHealthDataFetch()
                    completion(true)
                } else {
                    completion(false)
                }
            }
        }
    }

    // MARK: - Health Data Fetching
    private func fetchLatestHealthData(completion: @escaping () -> Void = {}) {
        let calendar = Calendar.current
        // Get data from the last 7 days to ensure we have recent data
        let startDate = calendar.date(byAdding: .day, value: -7, to: Date()) ?? Date()
        let endDate = Date()
        
        let group = DispatchGroup()
        
        // Fetch all available health metrics
        fetchSteps(startDate: startDate, endDate: endDate, group: group)
        fetchHeartRate(startDate: startDate, endDate: endDate, group: group)
        fetchActiveEnergy(startDate: startDate, endDate: endDate, group: group)
        fetchRestingEnergy(startDate: startDate, endDate: endDate, group: group)
        fetchDistance(startDate: startDate, endDate: endDate, group: group)
        fetchBloodOxygen(startDate: startDate, endDate: endDate, group: group)
        fetchFlightsClimbed(startDate: startDate, endDate: endDate, group: group)
        
        group.notify(queue: .main) {
            completion()
        }
    }
    
    private func fetchSteps(startDate: Date, endDate: Date, group: DispatchGroup) {
        print("Fetching steps data...")
        group.enter()
        if let stepType = HKObjectType.quantityType(forIdentifier: .stepCount) {
            let predicate = HKQuery.predicateForSamples(withStart: startDate, end: endDate, options: .strictStartDate)
            let stepsUnit = HKUnit.count()
            
            let query = HKStatisticsCollectionQuery(
                quantityType: stepType,
                quantitySamplePredicate: predicate,
                options: .cumulativeSum,
                anchorDate: startDate,
                intervalComponents: DateComponents(day: 1)
            )
            
            query.initialResultsHandler = { [weak self] query, results, error in
                guard let self = self,
                      let statisticsCollection = results,
                      error == nil else {
                    print("Error fetching steps: \(error?.localizedDescription ?? "Unknown error")")
                    group.leave()
                    return
                }
                
                statisticsCollection.enumerateStatistics(from: startDate, to: endDate) { statistics, stop in
                    guard let quantity = statistics.sumQuantity() else { return }
                    
                    DispatchQueue.main.async {
                        let recordType = HealthRecord.RecordType.steps
                        self.addHealthRecord(HealthRecord(date: statistics.startDate, type: recordType, value: quantity.doubleValue(for: stepsUnit), unit: recordType.unit))
                    }
                }
                group.leave()
            }
            
            healthStore.execute(query)
        } else {
            group.leave()
        }
    }

    private func fetchHeartRate(startDate: Date, endDate: Date, group: DispatchGroup) {
        print("Fetching heart rate data...")
        group.enter()
        if let heartRateType = HKObjectType.quantityType(forIdentifier: .heartRate) {
            let predicate = HKQuery.predicateForSamples(withStart: startDate, end: endDate, options: .strictStartDate)
            let heartRateUnit = HKUnit.count().unitDivided(by: HKUnit.minute())
            
            let query = HKStatisticsCollectionQuery(
                quantityType: heartRateType,
                quantitySamplePredicate: predicate,
                options: .discreteAverage,
                anchorDate: startDate,
                intervalComponents: DateComponents(day: 1)
            )
            
            query.initialResultsHandler = { [weak self] query, results, error in
                guard let self = self,
                      let statisticsCollection = results,
                      error == nil else {
                    print("Error fetching heart rate: \(error?.localizedDescription ?? "Unknown error")")
                    group.leave()
                    return
                }
                
                statisticsCollection.enumerateStatistics(from: startDate, to: endDate) { statistics, stop in
                    guard let quantity = statistics.averageQuantity() else { return }
                    
                    DispatchQueue.main.async {
                        let recordType = HealthRecord.RecordType.heartRate
                        self.addHealthRecord(HealthRecord(date: statistics.startDate, type: recordType, value: quantity.doubleValue(for: heartRateUnit), unit: recordType.unit))
                    }
                }
                group.leave()
            }
            
            healthStore.execute(query)
        } else {
            group.leave()
        }
    }

    private func fetchActiveEnergy(startDate: Date, endDate: Date, group: DispatchGroup) {
        print("Fetching active energy data...")
        group.enter()
        if let energyType = HKObjectType.quantityType(forIdentifier: .activeEnergyBurned) {
            let predicate = HKQuery.predicateForSamples(withStart: startDate, end: endDate, options: .strictStartDate)
            let calorieUnit = HKUnit.kilocalorie()
            
            let query = HKStatisticsCollectionQuery(
                quantityType: energyType,
                quantitySamplePredicate: predicate,
                options: .cumulativeSum,
                anchorDate: startDate,
                intervalComponents: DateComponents(day: 1)
            )
            
            query.initialResultsHandler = { [weak self] query, results, error in
                guard let self = self,
                      let statisticsCollection = results,
                      error == nil else {
                    print("Error fetching active energy: \(error?.localizedDescription ?? "Unknown error")")
                    group.leave()
                    return
                }
                
                statisticsCollection.enumerateStatistics(from: startDate, to: endDate) { statistics, stop in
                    guard let quantity = statistics.sumQuantity() else { return }
                    
                    DispatchQueue.main.async {
                        let recordType = HealthRecord.RecordType.activeEnergy
                        self.addHealthRecord(HealthRecord(date: statistics.startDate, type: recordType, value: quantity.doubleValue(for: calorieUnit), unit: recordType.unit))
                    }
                }
                group.leave()
            }
            
            healthStore.execute(query)
        } else {
            group.leave()
        }
    }

    private func fetchRestingEnergy(startDate: Date, endDate: Date, group: DispatchGroup) {
        print("Fetching resting energy data...")
        group.enter()
        if let energyType = HKObjectType.quantityType(forIdentifier: .basalEnergyBurned) {
            let predicate = HKQuery.predicateForSamples(withStart: startDate, end: endDate, options: .strictStartDate)
            let calorieUnit = HKUnit.kilocalorie()
            
            let query = HKStatisticsCollectionQuery(
                quantityType: energyType,
                quantitySamplePredicate: predicate,
                options: .cumulativeSum,
                anchorDate: startDate,
                intervalComponents: DateComponents(day: 1)
            )
            
            query.initialResultsHandler = { [weak self] query, results, error in
                guard let self = self,
                      let statisticsCollection = results,
                      error == nil else {
                    print("Error fetching resting energy: \(error?.localizedDescription ?? "Unknown error")")
                    group.leave()
                    return
                }
                
                statisticsCollection.enumerateStatistics(from: startDate, to: endDate) { statistics, stop in
                    guard let quantity = statistics.sumQuantity() else { return }
                    
                    DispatchQueue.main.async {
                        let recordType = HealthRecord.RecordType.restingEnergy
                        self.addHealthRecord(HealthRecord(date: statistics.startDate, type: recordType, value: quantity.doubleValue(for: calorieUnit), unit: recordType.unit))
                    }
                }
                group.leave()
            }
            
            healthStore.execute(query)
        } else {
            group.leave()
        }
    }

    private func fetchDistance(startDate: Date, endDate: Date, group: DispatchGroup) {
        print("Fetching distance data...")
        group.enter()
        if let distanceType = HKObjectType.quantityType(forIdentifier: .distanceWalkingRunning) {
            let predicate = HKQuery.predicateForSamples(withStart: startDate, end: endDate, options: .strictStartDate)
            let meterUnit = HKUnit.meter()
            
            let query = HKStatisticsCollectionQuery(
                quantityType: distanceType,
                quantitySamplePredicate: predicate,
                options: .cumulativeSum,
                anchorDate: startDate,
                intervalComponents: DateComponents(day: 1)
            )
            
            query.initialResultsHandler = { [weak self] query, results, error in
                guard let self = self,
                      let statisticsCollection = results,
                      error == nil else {
                    print("Error fetching distance: \(error?.localizedDescription ?? "Unknown error")")
                    group.leave()
                    return
                }
                
                statisticsCollection.enumerateStatistics(from: startDate, to: endDate) { statistics, stop in
                    guard let quantity = statistics.sumQuantity() else { return }
                    
                    DispatchQueue.main.async {
                        let recordType = HealthRecord.RecordType.distance
                        self.addHealthRecord(HealthRecord(date: statistics.startDate, type: recordType, value: quantity.doubleValue(for: meterUnit), unit: recordType.unit))
                    }
                }
                group.leave()
            }
            
            healthStore.execute(query)
        } else {
            group.leave()
        }
    }
    
    private func fetchFlightsClimbed(startDate: Date, endDate: Date, group: DispatchGroup) {
        print("Fetching flights climbed data...")
        group.enter()
        if let flightsType = HKObjectType.quantityType(forIdentifier: .flightsClimbed) {
            let predicate = HKQuery.predicateForSamples(withStart: startDate, end: endDate, options: .strictStartDate)
            let flightsUnit = HKUnit.count()
            
            let query = HKStatisticsCollectionQuery(
                quantityType: flightsType,
                quantitySamplePredicate: predicate,
                options: .cumulativeSum,
                anchorDate: startDate,
                intervalComponents: DateComponents(day: 1)
            )
            
            query.initialResultsHandler = { [weak self] query, results, error in
                guard let self = self,
                      let statisticsCollection = results,
                      error == nil else {
                    print("Error fetching flights climbed: \(error?.localizedDescription ?? "Unknown error")")
                    group.leave()
                    return
                }
                
                statisticsCollection.enumerateStatistics(from: startDate, to: endDate) { statistics, stop in
                    guard let quantity = statistics.sumQuantity() else { return }
                    
                    DispatchQueue.main.async {
                        let recordType = HealthRecord.RecordType.flightsClimbed
                        self.addHealthRecord(HealthRecord(date: statistics.startDate, type: recordType, value: quantity.doubleValue(for: flightsUnit), unit: recordType.unit))
                    }
                }
                group.leave()
            }
            
            healthStore.execute(query)
        } else {
            group.leave()
        }
    }
    
    private func fetchBloodOxygen(startDate: Date, endDate: Date, group: DispatchGroup) {
        print("Fetching blood oxygen data...")
        group.enter()
        if let oxygenType = HKObjectType.quantityType(forIdentifier: .oxygenSaturation) {
            let predicate = HKQuery.predicateForSamples(withStart: startDate, end: endDate, options: .strictStartDate)
            let percentUnit = HKUnit.percent()
            
            let query = HKStatisticsCollectionQuery(
                quantityType: oxygenType,
                quantitySamplePredicate: predicate,
                options: .discreteAverage,
                anchorDate: startDate,
                intervalComponents: DateComponents(day: 1)
            )
            
            query.initialResultsHandler = { [weak self] query, results, error in
                guard let self = self,
                      let statisticsCollection = results,
                      error == nil else {
                    print("Error fetching blood oxygen: \(error?.localizedDescription ?? "Unknown error")")
                    group.leave()
                    return
                }
                
                statisticsCollection.enumerateStatistics(from: startDate, to: endDate) { statistics, stop in
                    guard let quantity = statistics.averageQuantity() else { return }
                    
                    DispatchQueue.main.async {
                        let recordType = HealthRecord.RecordType.bloodOxygen
                        self.addHealthRecord(HealthRecord(date: statistics.startDate, type: recordType, value: quantity.doubleValue(for: percentUnit), unit: recordType.unit))
                    }
                }
                group.leave()
            }
            
            healthStore.execute(query)
        } else {
            group.leave()
        }
    }
}
