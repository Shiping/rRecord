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
        fileManager.urls(for: .cachesDirectory, in: .userDomainMask)[0] // 修改为 cachesDirectory
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

    func updateSelectedAIConfiguration(_ configId: UUID?) {
        if var profile = userProfile {
            profile.selectedAIConfigurationId = configId
            userProfile = profile
            // saveData() // Comment out saveData for now
        }
    }

    @objc public dynamic func generateHealthAdvice(userDescription: String?, completion: @escaping (String?) -> Void) {
        guard let selectedConfigId = userProfile?.selectedAIConfigurationId,
              let config = userProfile?.aiSettings.first(where: { $0.id == selectedConfigId }),
              config.enabled else {
            completion("请先在个人资料中启用 AI 配置")
            return
        }

        guard let provider = healthAdvisorProvider else {
            completion("AI 助手未正确初始化")
            return
        }
        
        // 从健康记录中获取最新的各项数据
        var healthData: [String: Any] = [:]
        
        // 获取用户年龄
        var userAge: Int? = nil
        if let birthDate = userProfile?.birthDate {
            let calendar = Calendar.current
            userAge = calendar.dateComponents([.year], from: birthDate, to: Date()).year
        }
        
        // 获取用户性别
        let userGender = userProfile?.gender.rawValue
        
        // 将各项健康数据添加到字典中
        for recordType in HealthRecord.RecordType.allCases {
            if let record = getLatestRecord(for: recordType) {
                switch recordType {
                case .steps:
                    healthData["steps"] = Int(record.value)
                case .sleep:
                    healthData["sleep"] = [
                        "hours": Int(record.value),
                        "minutes": Int(record.secondaryValue ?? 0)
                    ]
                case .heartRate:
                    healthData["heartRate"] = Int(record.value)
                case .activeEnergy:
                    healthData["activeEnergy"] = record.value
                case .restingEnergy:
                    healthData["restingEnergy"] = record.value
                case .distance:
                    healthData["distance"] = record.value
                case .bloodOxygen:
                    healthData["bloodOxygen"] = record.value
                case .bodyFat:
                    healthData["bodyFat"] = record.value
                case .flightsClimbed:
                    healthData["flightsClimbed"] = Int(record.value)
                case .weight:
                    healthData["weight"] = record.value
                case .bloodPressure:
                    healthData["bloodPressure"] = [
                        "systolic": record.value,
                        "diastolic": record.secondaryValue ?? 0
                    ]
                case .bloodSugar:
                    healthData["bloodSugar"] = record.value
                case .bloodLipids:
                    healthData["bloodLipids"] = record.value
                case .uricAcid:
                    healthData["uricAcid"] = record.value
                }
            }
        }
        
        provider.getHealthAdvice(
            healthData: healthData,
            userDescription: userDescription,
            userAge: userAge,
            userGender: userGender
        ) { result in
            DispatchQueue.main.async {
                switch result {
                case .success(let advice):
                    completion(advice)
                case .failure(let error):
                    completion("生成建议失败: \(error.localizedDescription)")
                }
            }
        }
    }
    
    private func migrateDataIfNeeded() {}

    private func createDirectoryIfNeeded() {
        do {
            try fileManager.createDirectory(at: documentsDirectory, withIntermediateDirectories: true, attributes: nil)
        } catch {
            print("Error creating documents directory: \(error.localizedDescription)")
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
                        dailyNotes.remove(at: index)
                    } else {
                        dailyNotes.append(iCloudNote)
                    }
                }
            }
        }
    }

    @objc public dynamic func isICloudSyncEnabled() -> Bool {
        return UserDefaults.standard.bool(forKey: "iCloudSyncEnabled")
    }

    @objc public dynamic func manualSyncToICloud(completion: @escaping (Bool) -> Void) {
        saveData()
        completion(true)
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
    
    private func queueHealthDataFetch() {
        // TODO: 实现健康数据获取逻辑
        print("健康数据获取已加入队列")
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
    
    public func getTodaysNotes() -> [DailyNote] {
        let calendar = Calendar.current
        return dailyNotes.filter { calendar.isDateInToday($0.date) }
    }
    
    @objc public dynamic func refreshHealthData() {
        print("Refreshing health data...")
        // TODO: Implement actual health data refresh logic
    }
    
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
    
    func deleteHealthRecord(_ id: UUID) {
        healthRecords.removeAll { $0.id == id }
        saveData()
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
}
