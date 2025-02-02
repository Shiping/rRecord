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
        requestAuthorization()
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
        return healthRecords
            .filter { $0.type == type }
            .sorted { $0.date > $1.date }
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
            
            // Convert to hours and create record
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
