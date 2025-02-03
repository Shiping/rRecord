import Foundation
import SwiftUI
import HealthKit

class HealthStore: ObservableObject {
    @Published var userProfile: UserProfile?
    @Published var healthRecords: [HealthRecord] = []
    @Published var dailyNotes: [DailyNote] = []
    
    private let userDefaults = UserDefaults.standard
    private let healthStore = HKHealthStore()
    
    init() {
        loadData()
        convertExistingSleepRecords() // Convert any existing sleep records from hours to seconds
        requestAuthorization()
    }
    
    private func convertExistingSleepRecords() {
        let sleepRecords = healthRecords.filter { $0.type == .sleep }
        for record in sleepRecords {
            // If value is less than 24, it's likely in hours and needs conversion to seconds
            if record.value < 24 {
                let updatedRecord = HealthRecord(
                    id: record.id,
                    date: record.date,
                    type: .sleep,
                    value: record.value * 3600, // Convert hours to seconds
                    secondaryValue: record.secondaryValue,
                    unit: record.unit
                )
                updateHealthRecord(updatedRecord)
            }
        }
    }
    
    private func loadData() {
        if let profileData = userDefaults.data(forKey: "userProfile"),
           let profile = try? JSONDecoder().decode(UserProfile.self, from: profileData) {
            userProfile = profile
        }
        
        if let recordsData = userDefaults.data(forKey: "healthRecords"),
           let records = try? JSONDecoder().decode([HealthRecord].self, from: recordsData) {
            healthRecords = records
        }
        
        if let notesData = userDefaults.data(forKey: "dailyNotes"),
           let notes = try? JSONDecoder().decode([DailyNote].self, from: notesData) {
            dailyNotes = notes
        }
    }
    
    private func saveData() {
        if let profile = userProfile,
           let profileData = try? JSONEncoder().encode(profile) {
            userDefaults.set(profileData, forKey: "userProfile")
        }
        
        if let recordsData = try? JSONEncoder().encode(healthRecords) {
            userDefaults.set(recordsData, forKey: "healthRecords")
        }
        
        if let notesData = try? JSONEncoder().encode(dailyNotes) {
            userDefaults.set(notesData, forKey: "dailyNotes")
        }
    }
    
    func updateProfile(_ profile: UserProfile) {
        userProfile = profile
        saveData()
    }
    
    func addHealthRecord(_ record: HealthRecord) {
        let calendar = Calendar.current
        let recordDate = calendar.startOfDay(for: record.date)
        
        // Check if there's already a record for this day and type
        if let existingIndex = healthRecords.firstIndex(where: { existing in
            let existingDate = calendar.startOfDay(for: existing.date)
            return existing.type == record.type && existingDate == recordDate
        }) {
            // If existing record has a lower value, replace it
            if healthRecords[existingIndex].value < record.value {
                healthRecords[existingIndex] = record
            }
        } else {
            // No record exists for this day and type, add the new record
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
        
        // Group records by day
        let groupedRecords = Dictionary(grouping: filteredRecords) { record in
            calendar.startOfDay(for: record.date)
        }
        
        // Keep only the maximum value for each day
        let dailyMaxRecords = groupedRecords.map { (date, records) -> HealthRecord in
            records.max { a, b in a.value < b.value }!
        }
        
        return dailyMaxRecords.sorted { $0.date > $1.date }
    }
    
    func getTodaysNotes() -> [DailyNote] {
        let calendar = Calendar.current
        return dailyNotes.filter { calendar.isDateInToday($0.date) }
    }
    
    private func requestAuthorization() {
        guard let stepCountType = HKObjectType.quantityType(forIdentifier: .stepCount),
              let sleepType = HKObjectType.categoryType(forIdentifier: .sleepAnalysis) else {
            return
        }
        
        let typesToShare: Set<HKSampleType> = []
        let typesToRead: Set<HKSampleType> = [stepCountType, sleepType]
        
        healthStore.requestAuthorization(toShare: typesToShare, read: typesToRead) { success, error in
            if success {
                print("授权成功")
                self.fetchTodayStepCount()
                self.fetchLastNightSleep()
            } else {
                print("授权失败: \(String(describing: error?.localizedDescription))")
            }
        }
    }
    
    // Public refresh method
func refreshHealthData() {
    fetchTodayStepCount()
    fetchLastNightSleep()
}

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
            
            // Calculate total sleep duration
            var totalSleepDuration: TimeInterval = 0
            for sample in samples {
                if sample.value == HKCategoryValueSleepAnalysis.asleepUnspecified.rawValue {
                    totalSleepDuration += sample.endDate.timeIntervalSince(sample.startDate)
                }
            }
            
            // Store sleep duration in seconds
            let record = HealthRecord(id: UUID(),
                                    date: now,
                                    type: .sleep,
                                    value: totalSleepDuration,
                                    secondaryValue: nil,
                                    unit: "小时")
            
            DispatchQueue.main.async {
                self.addHealthRecord(record)
            }
        }
        
        healthStore.execute(query)
    }
}
