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
        loadData() // Load saved data immediately during initialization
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
              let distanceType = HKObjectType.quantityType(forIdentifier: .distanceWalkingRunning),
              let oxygenSaturationType = HKObjectType.quantityType(forIdentifier: .oxygenSaturation),
              let bodyFatType = HKObjectType.quantityType(forIdentifier: .bodyFatPercentage) else {
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
            distanceType,
            oxygenSaturationType,
            bodyFatType
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
                    self.queueHealthDataFetch() // Only fetch health data after authorization
                    completion(true)
                } else {
                    print("Authorization failed: \(String(describing: error?.localizedDescription))")
                    // Even if health authorization fails, local data is already loaded from init()
                    completion(false)
                }
            }
        }
    }
    
    private func loadData() {
        let decoder = JSONDecoder()
        
        // Load from local storage
        if let profileData = try? Data(contentsOf: profileURL),
           let profile = try? decoder.decode(UserProfile.self, from: profileData) {
            userProfile = profile
        }
        
        if let recordsData = try? Data(contentsOf: recordsURL),
           let records = try? decoder.decode([HealthRecord].self, from: recordsData) {
            healthRecords = records
            recalculateBMI()
        }
        
        // Load daily notes
        if let notesData = try? Data(contentsOf: notesURL),
           let notes = try? decoder.decode([DailyNote].self, from: notesData) {
            dailyNotes = notes
        }
        
        // Load from iCloud if enabled and merge
        if isICloudSyncEnabled() {
            let store = NSUbiquitousKeyValueStore.default
            
            if let profileData = store.data(forKey: "userProfile"),
               let iCloudProfile = try? decoder.decode(UserProfile.self, from: profileData) {
                userProfile = iCloudProfile // Prioritize iCloud data
            }
            
            if let recordsData = store.data(forKey: "healthRecords"),
               let iCloudRecords = try? decoder.decode([HealthRecord].self, from: recordsData) {
                // Merge iCloud records with local records
                for iCloudRecord in iCloudRecords {
                    if let index = healthRecords.firstIndex(where: { $0.id == iCloudRecord.id }) {
                        healthRecords[index] = iCloudRecord // Prioritize iCloud data
                    } else {
                        healthRecords.append(iCloudRecord)
                    }
                }
                recalculateBMI()
            }
            
            if let notesData = store.data(forKey: "dailyNotes"),
               let iCloudNotes = try? decoder.decode([DailyNote].self, from: notesData) {
                // Merge iCloud notes with local notes
                for iCloudNote in iCloudNotes {
                    if let index = dailyNotes.firstIndex(where: { $0.id == iCloudNote.id }) {
                        dailyNotes[index] = iCloudNote // Prioritize iCloud data
                    } else {
                        dailyNotes.append(iCloudNote)
                    }
                }
            }
        }
    }
    
    private func saveData() {
        let encoder = JSONEncoder()
        encoder.outputFormatting = .prettyPrinted
        
        // Save to local storage
        do {
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
        
        // Save to iCloud if enabled
        if isICloudSyncEnabled() {
            let store = NSUbiquitousKeyValueStore.default
            
            // Save user profile
            if let profile = userProfile, let profileData = try? encoder.encode(profile) {
                store.set(profileData, forKey: "userProfile")
            }
            
            // Save health records
            if let recordsData = try? encoder.encode(healthRecords) {
                store.set(recordsData, forKey: "healthRecords")
            }
            
            // Save daily notes
            if let notesData = try? encoder.encode(dailyNotes) {
                store.set(notesData, forKey: "dailyNotes")
            }
            
            store.synchronize()
        }
    }
    
    func isICloudSyncEnabled() -> Bool {
        return UserDefaults.standard.bool(forKey: "iCloudSyncEnabled")
    }
    
    // MARK: - Public Methods
    
    func manualSyncToICloud(completion: @escaping (Bool) -> Void) {
        saveData()
        completion(true) // 假设同步总是成功，可以根据实际情况修改
    }
    
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
    
    func recalculateBMI() {
        guard let height = userProfile?.height else { return }
        
        for index in healthRecords.indices {
            if healthRecords[index].type == .weight {
                let weight = healthRecords[index].value
                let bmi = weight / ((height / 100) * (height / 100))
                healthRecords[index].secondaryValue = bmi
            }
        }
        saveData()
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
            Thread.sleep(forTimeInterval: delay)
            
            self.fetchLatestBloodOxygen()
            Thread.sleep(forTimeInterval: delay)
            
            self.fetchLatestBodyFat()
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
        let calendar = Calendar.current
        
        // Get noon today as the end time to ensure we capture late sleepers
        var components = calendar.dateComponents([.year, .month, .day], from: now)
        components.hour = 12
        components.minute = 0
        components.second = 0
        let endTime = calendar.date(from: components) ?? now
        
        // Get 6:00 PM two days ago as the start time to ensure we capture early sleepers
        let twoDaysAgoComponents = calendar.date(byAdding: .day, value: -2, to: endTime)!
        components = calendar.dateComponents([.year, .month, .day], from: twoDaysAgoComponents)
        components.hour = 18
        components.minute = 0
        components.second = 0
        let startTime = calendar.date(from: components)!
        
        let predicate = HKQuery.predicateForSamples(withStart: startTime, end: endTime, options: .strictStartDate)
        
        print("Fetching sleep data from \(startTime) to \(endTime)")
        
        let query = HKSampleQuery(sampleType: sleepType,
                                predicate: predicate,
                                limit: HKObjectQueryNoLimit,
                                sortDescriptors: [NSSortDescriptor(key: HKSampleSortIdentifierEndDate, ascending: false)]) { [weak self] _, samples, error in
            guard let self = self else { return }
            
            if let error = error {
                print("Error fetching sleep data: \(error.localizedDescription)")
                return
            }
            
            guard let samples = samples as? [HKCategorySample] else {
                print("No sleep samples found")
                return
            }
            
            print("Found \(samples.count) sleep samples")
            
            // Group samples by date to handle sleep segments
            let calendar = Calendar.current
            let groupedSamples = Dictionary(grouping: samples) { sample in
                calendar.startOfDay(for: sample.startDate)
            }
            
            // Find the most recent day with sleep data
            let sortedDays = groupedSamples.keys.sorted(by: >)
            let mostRecentSamples = sortedDays.first.flatMap { groupedSamples[$0] } ?? []
            
            print("Processing sleep data for: \(sortedDays.first?.description ?? "unknown date")")
            
            var totalSleepDuration: TimeInterval = 0
            for sample in mostRecentSamples {
                // Include all sleep states
                if sample.value == HKCategoryValueSleepAnalysis.asleepUnspecified.rawValue ||
                   sample.value == HKCategoryValueSleepAnalysis.asleepCore.rawValue ||
                   sample.value == HKCategoryValueSleepAnalysis.asleepDeep.rawValue ||
                   sample.value == HKCategoryValueSleepAnalysis.asleepREM.rawValue {
                    let duration = sample.endDate.timeIntervalSince(sample.startDate)
                    print("Sleep segment: \(sample.startDate) to \(sample.endDate), duration: \(duration/3600) hours")
                    totalSleepDuration += duration
                }
            }
            
            let sleepHours = totalSleepDuration / 3600
            print("Total sleep duration: \(sleepHours) hours")
            
            // Always create a record, even if sleep hours is 0
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
    
    private func fetchLatestBloodOxygen() {
        guard let oxygenSaturationType = HKObjectType.quantityType(forIdentifier: .oxygenSaturation) else { return }
        
        let now = Date()
        let startOfDay = Calendar.current.startOfDay(for: now)
        let predicate = HKQuery.predicateForSamples(withStart: startOfDay, end: now, options: .strictStartDate)
        
        let query = HKStatisticsQuery(quantityType: oxygenSaturationType,
                                    quantitySamplePredicate: predicate,
                                    options: .discreteAverage) { [weak self] _, result, error in
            guard let self = self,
                  let result = result,
                  let average = result.averageQuantity() else {
                return
            }
            
            let oxygenSaturation = average.doubleValue(for: HKUnit.percent()) * 100 // Convert to percentage
            let record = HealthRecord(id: UUID(),
                                    date: now,
                                    type: .bloodOxygen,
                                    value: oxygenSaturation,
                                    secondaryValue: nil,
                                    unit: "%")
            
            DispatchQueue.main.async {
                self.addHealthRecord(record)
            }
        }
        
        healthStore.execute(query)
    }
    
    private func fetchLatestBodyFat() {
        guard let bodyFatType = HKObjectType.quantityType(forIdentifier: .bodyFatPercentage) else { return }
        
        let now = Date()
        let startOfDay = Calendar.current.startOfDay(for: now)
        let predicate = HKQuery.predicateForSamples(withStart: startOfDay, end: now, options: .strictStartDate)
        
        let query = HKStatisticsQuery(quantityType: bodyFatType,
                                    quantitySamplePredicate: predicate,
                                    options: .discreteAverage) { [weak self] _, result, error in
            guard let self = self,
                  let result = result,
                  let average = result.averageQuantity() else {
                return
            }
            
            let bodyFat = average.doubleValue(for: HKUnit.percent()) * 100 // Convert to percentage
            let record = HealthRecord(id: UUID(),
                                    date: now,
                                    type: .bodyFat,
                                    value: bodyFat,
                                    secondaryValue: nil,
                                    unit: "%")
            
            DispatchQueue.main.async {
                self.addHealthRecord(record)
            }
        }
        
        healthStore.execute(query)
    }
}
