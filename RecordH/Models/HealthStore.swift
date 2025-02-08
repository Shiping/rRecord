import Foundation
import SwiftUI
import HealthKit

class HealthStore: ObservableObject {
    @Published var userProfile: UserProfile?
    @Published var healthRecords: [HealthRecord] = []
    @Published var dailyNotes: [DailyNote] = []
    
    private let healthStore = HKHealthStore()
    private let fileManager = FileManager.default
    private var documentsDirectory: URL {
        fileManager.urls(for: .documentDirectory, in: .userDomainMask)[0]
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
    
    
    init() {
        print("Initializing HealthStore")
        createDirectoryIfNeeded()
        migrateDataIfNeeded()
        // Defer loadData until after authorization
    }
    
    private func migrateDataIfNeeded() {
        // No migration needed as we're using Documents directory directly
    }
    
    private func createDirectoryIfNeeded() {
        // Documents directory is always available, no need to create it
    }
    
    func requestInitialAuthorization(completion: @escaping (Bool) -> Void) {
        print("Starting authorization request")
        guard HKHealthStore.isHealthDataAvailable() else {
            print("Health data not available")
            print("Failed to create health data types")
            return
        }
        
        guard let stepCountType = HKObjectType.quantityType(forIdentifier: .stepCount),
              let sleepType = HKObjectType.categoryType(forIdentifier: .sleepAnalysis),
              let flightsClimbedType = HKObjectType.quantityType(forIdentifier: .flightsClimbed),
              let activeEnergyType = HKObjectType.quantityType(forIdentifier: .activeEnergyBurned),
              let restingEnergyType = HKObjectType.quantityType(forIdentifier: .basalEnergyBurned),
              let heartRateType = HKObjectType.quantityType(forIdentifier: .heartRate),
              let distanceType = HKObjectType.quantityType(forIdentifier: .distanceWalkingRunning) else {
            completion(false)
            return
        }
        
        let typesToRead: Set<HKSampleType> = [
            stepCountType,
            sleepType,
            flightsClimbedType,
            activeEnergyType,
            restingEnergyType,
            heartRateType,
            distanceType
        ]
        
        print("Requesting authorization for health data types")
        healthStore.requestAuthorization(toShare: [], read: typesToRead) { [weak self] success, error in
            guard let self = self else {
                DispatchQueue.main.async {
                    print("Authorization failed: self is nil")
                    completion(false)
                }
                return
            }
            
            DispatchQueue.main.async {
                if success {
                    print("Authorization successful")
                    self.loadData() // Load saved data first
                    self.queueHealthDataFetch() // Then queue health data fetches
                    completion(true)
                } else {
                    print("Authorization failed: \(String(describing: error?.localizedDescription))")
                    completion(false)
                }
            }
        }
    }
    
    private func loadData() {
        let decoder = JSONDecoder()
        
        // Load user profile
        if let profileData = try? Data(contentsOf: profileURL),
           let profile = try? decoder.decode(UserProfile.self, from: profileData) {
            userProfile = profile
        }
        
        // Load health records
        if let recordsData = try? Data(contentsOf: recordsURL),
           let records = try? decoder.decode([HealthRecord].self, from: recordsData) {
            healthRecords = records
        }
        
        // Load daily notes
        if let notesData = try? Data(contentsOf: notesURL),
           let notes = try? decoder.decode([DailyNote].self, from: notesData) {
            dailyNotes = notes
        }
    }
    
    private func saveData() {
        do {
            let encoder = JSONEncoder()
            encoder.outputFormatting = .prettyPrinted
            
            // Save user profile
            if let profile = userProfile {
                let profileData = try encoder.encode(profile)
                try profileData.write(to: profileURL, options: .atomic)
            }
            
            // Save health records
            let recordsData = try encoder.encode(healthRecords)
            try recordsData.write(to: recordsURL, options: .atomic)
            
            // Save daily notes
            let notesData = try encoder.encode(dailyNotes)
            try notesData.write(to: notesURL, options: .atomic)
            
        } catch {
            print("Error saving data: \(error.localizedDescription)")
        }
    }
    
    // MARK: - Public Methods
    
    func updateProfile(_ profile: UserProfile) {
        userProfile = profile
        saveData()
    }
    
    func addHealthRecord(_ record: HealthRecord) {
        let calendar = Calendar.current
        let recordDate = calendar.startOfDay(for: record.date)
        
        if let existingIndex = healthRecords.firstIndex(where: { existing in
            let existingDate = calendar.startOfDay(for: existing.date)
            return existing.type == record.type && existingDate == recordDate
        }) {
            healthRecords[existingIndex] = record
        } else {
            healthRecords.append(record)
        }
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
    
    func getLatestRecord(for type: HealthRecord.RecordType) -> HealthRecord? {
        return healthRecords
            .filter { $0.type == type }
            .sorted { $0.date > $1.date }
            .first
    }
    
    func getRecords(for type: HealthRecord.RecordType) -> [HealthRecord] {
        let filteredRecords = healthRecords.filter { $0.type == type }
        let calendar = Calendar.current
        
        let groupedRecords = Dictionary(grouping: filteredRecords) { record in
            calendar.startOfDay(for: record.date)
        }
        
        let dailyLatestRecords = groupedRecords.map { (_, records) -> HealthRecord in
            records.max { a, b in a.date < b.date }!
        }
        
        return dailyLatestRecords.sorted { $0.date > $1.date }
    }
    
    func getTodaysNotes() -> [DailyNote] {
        let calendar = Calendar.current
        return dailyNotes.filter { calendar.isDateInToday($0.date) }
    }
    
    func saveUricAcid(_ record: HealthRecord) {
        if record.type == .uricAcid {
            addHealthRecord(record)
        }
    }
    
    // Queue health data fetches with delay between each
    private func queueHealthDataFetch() {
        let fetchQueue = DispatchQueue(label: "com.recordh.healthfetch")
        let delay: TimeInterval = 0.5 // Half second delay between fetches
        
        fetchQueue.async {
            self.fetchTodayStepCount()
            Thread.sleep(forTimeInterval: delay)
            
            self.fetchLastNightSleep()
            Thread.sleep(forTimeInterval: delay)
            
            self.fetchTodayFlightsClimbed()
            Thread.sleep(forTimeInterval: delay)
            
            self.fetchTodayActiveEnergy()
            Thread.sleep(forTimeInterval: delay)
            
            self.fetchTodayRestingEnergy()
            Thread.sleep(forTimeInterval: delay)
            
            self.fetchLatestHeartRate()
            Thread.sleep(forTimeInterval: delay)
            
            self.fetchTodayDistance()
        }
    }
    
    // Public refresh method
    func refreshHealthData() {
        queueHealthDataFetch()
    }
    
    // MARK: - Private HealthKit Methods
    
    private func fetchTodayStepCount() {
        guard let stepCountType = HKObjectType.quantityType(forIdentifier: .stepCount) else { return }
        
        let now = Date()
        let startOfDay = Calendar.current.startOfDay(for: now)
        let predicate = HKQuery.predicateForSamples(withStart: startOfDay, end: now, options: .strictStartDate)
        
        let query = HKStatisticsQuery(quantityType: stepCountType,
                                    quantitySamplePredicate: predicate,
                                    options: .cumulativeSum) { [weak self] _, result, error in
            guard let self = self,
                  let result = result,
                  let sum = result.sumQuantity() else {
                return
            }
            
            let steps = sum.doubleValue(for: HKUnit.count())
            let record = HealthRecord(id: UUID(),
                                    date: now,
                                    type: .steps,
                                    value: steps,
                                    secondaryValue: nil,
                                    unit: "步")
            
            DispatchQueue.main.async {
                self.addHealthRecord(record)
            }
        }
        
        healthStore.execute(query)
    }
    
    private func fetchLastNightSleep() {
        guard let sleepType = HKObjectType.categoryType(forIdentifier: .sleepAnalysis) else { return }
        
        let now = Date()
        let yesterday = Calendar.current.date(byAdding: .day, value: -1, to: now)!
        let predicate = HKQuery.predicateForSamples(withStart: yesterday, end: now, options: .strictStartDate)
        
        let query = HKSampleQuery(sampleType: sleepType,
                                predicate: predicate,
                                limit: HKObjectQueryNoLimit,
                                sortDescriptors: [NSSortDescriptor(key: HKSampleSortIdentifierEndDate, ascending: false)]) { [weak self] _, samples, error in
            guard let self = self,
                  let samples = samples as? [HKCategorySample] else {
                return
            }
            
            var totalSleepDuration: TimeInterval = 0
            for sample in samples {
                if sample.value == HKCategoryValueSleepAnalysis.asleepUnspecified.rawValue {
                    totalSleepDuration += sample.endDate.timeIntervalSince(sample.startDate)
                }
            }
            
            let sleepHours = totalSleepDuration / 3600
            
            guard sleepHours > 0 else {
                print("No valid sleep data found.")
                return
            }
            
            let hours = Int(sleepHours)
            let minutes = Int((sleepHours - Double(hours)) * 60)
            
            let record = HealthRecord(id: UUID(),
                                    date: now,
                                    type: .sleep,
                                    value: Double(hours),
                                    secondaryValue: Double(minutes),
                                    unit: "小时")
            
            DispatchQueue.main.async {
                self.addHealthRecord(record)
            }
        }
        
        healthStore.execute(query)
    }
    
    private func fetchTodayFlightsClimbed() {
        guard let flightsClimbedType = HKObjectType.quantityType(forIdentifier: .flightsClimbed) else { return }
        
        let now = Date()
        let startOfDay = Calendar.current.startOfDay(for: now)
        let predicate = HKQuery.predicateForSamples(withStart: startOfDay, end: now, options: .strictStartDate)
        
        let query = HKStatisticsQuery(quantityType: flightsClimbedType,
                                    quantitySamplePredicate: predicate,
                                    options: .cumulativeSum) { [weak self] _, result, error in
            guard let self = self,
                  let result = result,
                  let sum = result.sumQuantity() else {
                return
            }
            
            let flights = sum.doubleValue(for: HKUnit.count())
            let record = HealthRecord(id: UUID(),
                                    date: now,
                                    type: .flightsClimbed,
                                    value: flights,
                                    secondaryValue: nil,
                                    unit: "层")
            
            DispatchQueue.main.async {
                self.addHealthRecord(record)
            }
        }
        
        healthStore.execute(query)
    }
    
    private func fetchTodayActiveEnergy() {
        guard let activeEnergyType = HKObjectType.quantityType(forIdentifier: .activeEnergyBurned) else { return }
        
        let now = Date()
        let startOfDay = Calendar.current.startOfDay(for: now)
        let predicate = HKQuery.predicateForSamples(withStart: startOfDay, end: now, options: .strictStartDate)
        
        let query = HKStatisticsQuery(quantityType: activeEnergyType,
                                    quantitySamplePredicate: predicate,
                                    options: .cumulativeSum) { [weak self] _, result, error in
            guard let self = self,
                  let result = result,
                  let sum = result.sumQuantity() else {
                return
            }
            
            let calories = sum.doubleValue(for: HKUnit.kilocalorie())
            let record = HealthRecord(id: UUID(),
                                    date: now,
                                    type: .activeEnergy,
                                    value: calories,
                                    secondaryValue: nil,
                                    unit: "千卡")
            
            DispatchQueue.main.async {
                self.addHealthRecord(record)
            }
        }
        
        healthStore.execute(query)
    }
    
    private func fetchTodayRestingEnergy() {
        guard let restingEnergyType = HKObjectType.quantityType(forIdentifier: .basalEnergyBurned) else { return }
        
        let now = Date()
        let startOfDay = Calendar.current.startOfDay(for: now)
        let predicate = HKQuery.predicateForSamples(withStart: startOfDay, end: now, options: .strictStartDate)
        
        let query = HKStatisticsQuery(quantityType: restingEnergyType,
                                    quantitySamplePredicate: predicate,
                                    options: .cumulativeSum) { [weak self] _, result, error in
            guard let self = self,
                  let result = result,
                  let sum = result.sumQuantity() else {
                return
            }
            
            let calories = sum.doubleValue(for: HKUnit.kilocalorie())
            let record = HealthRecord(id: UUID(),
                                    date: now,
                                    type: .restingEnergy,
                                    value: calories,
                                    secondaryValue: nil,
                                    unit: "千卡")
            
            DispatchQueue.main.async {
                self.addHealthRecord(record)
            }
        }
        
        healthStore.execute(query)
    }
    
    private func fetchLatestHeartRate() {
        guard let heartRateType = HKObjectType.quantityType(forIdentifier: .heartRate) else { return }
        
        let now = Date()
        let startOfDay = Calendar.current.startOfDay(for: now)
        let predicate = HKQuery.predicateForSamples(withStart: startOfDay, end: now, options: .strictStartDate)
        
        let query = HKStatisticsQuery(quantityType: heartRateType,
                                    quantitySamplePredicate: predicate,
                                    options: .discreteAverage) { [weak self] _, result, error in
            guard let self = self,
                  let result = result,
                  let average = result.averageQuantity() else {
                return
            }
            
            let heartRate = average.doubleValue(for: HKUnit.count().unitDivided(by: HKUnit.minute()))
            let record = HealthRecord(id: UUID(),
                                    date: now,
                                    type: .heartRate,
                                    value: heartRate,
                                    secondaryValue: nil,
                                    unit: "次/分")
            
            DispatchQueue.main.async {
                self.addHealthRecord(record)
            }
        }
        
        healthStore.execute(query)
    }
    
    private func fetchTodayDistance() {
        guard let distanceType = HKObjectType.quantityType(forIdentifier: .distanceWalkingRunning) else { return }
        
        let now = Date()
        let startOfDay = Calendar.current.startOfDay(for: now)
        let predicate = HKQuery.predicateForSamples(withStart: startOfDay, end: now, options: .strictStartDate)
        
        let query = HKStatisticsQuery(quantityType: distanceType,
                                    quantitySamplePredicate: predicate,
                                    options: .cumulativeSum) { [weak self] _, result, error in
            guard let self = self,
                  let result = result,
                  let sum = result.sumQuantity() else {
                return
            }
            
            let distance = sum.doubleValue(for: HKUnit.meter()) / 1000.0 // Convert to kilometers
            let record = HealthRecord(id: UUID(),
                                    date: now,
                                    type: .distance,
                                    value: distance,
                                    secondaryValue: nil,
                                    unit: "公里")
            
            DispatchQueue.main.async {
                self.addHealthRecord(record)
            }
        }
        
        healthStore.execute(query)
    }
}
