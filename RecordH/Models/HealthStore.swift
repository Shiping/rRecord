import Foundation
import SwiftUI
import HealthKit

@available(macOS 10.13, iOS 15.0, *)
public class HealthStore: ObservableObject {
    @Published var userProfile: UserProfile?
    @Published var healthRecords: [HealthRecord] = []
    @Published var dailyNotes: [DailyNote] = []

    private let healthStore = HKHealthStore()
    private var healthAdvisorProvider: HealthAdvisorProvider?
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
    
    public init() {
        print("Initializing HealthStore")
        let config = HealthAdvisorProvider.Configuration(healthStore: self)
        healthAdvisorProvider = HealthAdvisorProvider(config: config)
        
        createDirectoryIfNeeded()
        migrateDataIfNeeded()
        loadData()
    }
    
    private func migrateDataIfNeeded() {}
    
    private func createDirectoryIfNeeded() {
        do {
            try fileManager.createDirectory(at: documentsDirectory, withIntermediateDirectories: true, attributes: nil)
        } catch {
            print("Error creating documents directory: \(error.localizedDescription)")
        }
    }
    
    @objc public dynamic func requestInitialAuthorization(completion: @escaping (Bool) -> Void) {
        guard HKHealthStore.isHealthDataAvailable() else {
            completion(false); return
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
        
        let typesToRead: Set<HKSampleType> = [stepCountType, sleepType, flightsClimbedType, activeEnergyType, restingEnergyType, heartRateType, distanceType, oxygenSaturationType, bodyFatType]
        
        healthStore.requestAuthorization(toShare: [], read: typesToRead) { [weak self] success, error in
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
    
    private func loadData() {
        let decoder = JSONDecoder()
        
        if let profileData = try? Data(contentsOf: profileURL),
           let profile = try? decoder.decode(UserProfile.self, from: profileData) {
            userProfile = profile
        }
        
        if let recordsData = try? Data(contentsOf: recordsURL),
           let records = try? decoder.decode([HealthRecord].self, from: recordsData) {
            healthRecords = records
        }
        
        if let notesData = try? Data(contentsOf: notesURL),
           let notes = try? decoder.decode([DailyNote].self, from: notesData) {
            dailyNotes = notes
        }
        
        if isICloudSyncEnabled() {
            let store = NSUbiquitousKeyValueStore.default
            
            if let profileData = store.data(forKey: "userProfile"),
               let iCloudProfile = try? decoder.decode(UserProfile.self, from: profileData) {
                userProfile = iCloudProfile
            }
            
            if let recordsData = store.data(forKey: "healthRecords"),
               let iCloudRecords = try? decoder.decode([HealthRecord].self, from: recordsData) {
                for iCloudRecord in iCloudRecords {
                    if let index = healthRecords.firstIndex(where: { $0.id == iCloudRecord.id }) {
                        healthRecords[index] = iCloudRecord
                    } else {
                        healthRecords.append(iCloudRecord)
                    }
                }

            }
            
            if let notesData = store.data(forKey: "dailyNotes"),
               let iCloudNotes = try? decoder.decode([DailyNote].self, from: notesData) {
                for iCloudNote in iCloudNotes {
                    if let index = dailyNotes.firstIndex(where: { $0.id == iCloudNote.id }) {
                        dailyNotes[index] = iCloudNote
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
        
        do {
            if let profile = userProfile {
                let profileData = try encoder.encode(profile)
                try profileData.write(to: profileURL, options: .atomic)
            }
            
            let recordsData = try encoder.encode(healthRecords)
            try recordsData.write(to: recordsURL, options: .atomic)
            
            let notesData = try encoder.encode(dailyNotes)
            try notesData.write(to: notesURL, options: .atomic)
            
            if isICloudSyncEnabled() {
                let store = NSUbiquitousKeyValueStore.default
                
                if let profile = userProfile,
                   let profileData = try? encoder.encode(profile) {
                    store.set(profileData, forKey: "userProfile")
                }
                
                if let recordsData = try? encoder.encode(healthRecords) {
                    store.set(recordsData, forKey: "healthRecords")
                }
                
                if let notesData = try? encoder.encode(dailyNotes) {
                    store.set(notesData, forKey: "dailyNotes")
                }
                
                store.synchronize()
            }
        } catch {
            print("Error saving data: \(error.localizedDescription)")
        }
    }
    
    @objc public dynamic func isICloudSyncEnabled() -> Bool {
        return UserDefaults.standard.bool(forKey: "iCloudSyncEnabled")
    }
    
    @objc public dynamic func manualSyncToICloud(completion: @escaping (Bool) -> Void) {
        saveData()
        completion(true)
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
    
    public func getLatestRecord(for type: HealthRecord.RecordType) -> HealthRecord? {
        return healthRecords.filter { $0.type == type }.sorted { $0.date > $1.date }.first
    }
    
    public func getRecords(for type: HealthRecord.RecordType, includingToday: Bool = true) -> [HealthRecord] {
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
    
    public func getTodaysNotes() -> [DailyNote] {
        let calendar = Calendar.current
        return dailyNotes.filter { calendar.isDateInToday($0.date) }
    }
    
    @objc public dynamic func generateHealthAdvice(userDescription: String?, completion: @escaping (String?) -> Void) {
        guard let provider = healthAdvisorProvider, // updated provider name
              userProfile?.aiSettings.enabled == true else {
            print("AI建议功能未启用或未配置")
            completion(nil)
            return
        }
        
        guard let aiSettings = userProfile?.aiSettings, !aiSettings.deepseekApiKey.isEmpty else {
            print("Deepseek API 密钥未配置")
            completion(nil)
            return
        }
        
        let healthData = getTodayHealthData()
        
        provider.useHealthAdvisor(healthData: healthData, userDescription: userDescription) { result in // useHealthAdvisor is still valid
            DispatchQueue.main.async {
                switch result {
                case .success(let advice):
                    completion(advice)
                case .failure(let error):
                    print("Failed to generate health advice: \(error.localizedDescription)")
                    completion(nil)
                }
            }
        }
    }
    
    private func queueHealthDataFetch() {
        // TODO: 实现健康数据获取逻辑
        print("健康数据获取已加入队列")
    }
    
    public func getTodayHealthData() -> [String: Any] {
        var data: [String: Any] = [:]
        if let stepsRecord = getLatestRecord(for: .steps) {
            data["steps"] = stepsRecord.value
        }
        if let sleepRecord = getLatestRecord(for: .sleep) {
            data["sleep"] = ["hours": Int(sleepRecord.value), "minutes": Int((sleepRecord.value.truncatingRemainder(dividingBy: 1) * 60).rounded())]
        }
        if let heartRateRecord = getLatestRecord(for: .heartRate) {
            data["heartRate"] = heartRateRecord.value
        }
        if let activeEnergyRecord = getLatestRecord(for: .activeEnergy) {
            data["activeEnergy"] = activeEnergyRecord.value
        }
        if let restingEnergyRecord = getLatestRecord(for: .restingEnergy) {
            data["restingEnergy"] = restingEnergyRecord.value
        }
        if let distanceRecord = getLatestRecord(for: .distance) {
            data["distance"] = distanceRecord.value
        }
        if let bloodOxygenRecord = getLatestRecord(for: .bloodOxygen) {
            data["bloodOxygen"] = bloodOxygenRecord.value
        }
        if let bodyFatRecord = getLatestRecord(for: .bodyFat) {
            data["bodyFat"] = bodyFatRecord.value
        }
        return data
    }
    
    @objc public dynamic func refreshHealthData() {
        queueHealthDataFetch()
    }
}
