import Foundation
import HealthKit
import SwiftUI
import Combine

@MainActor
public class HealthStore: NSObject, ObservableObject {
    public static let shared = HealthStore()
    
    let healthStore = HKHealthStore()
    private var cancellables = Set<AnyCancellable>()
    
    @Published var userProfile: UserProfile?
    @Published var healthRecords: [HealthRecord] = []
    @Published var lastUpdate: Date {
        didSet {
            // Store lastUpdate as timestamp for consistency
            UserDefaults.standard.set(lastUpdate.timeIntervalSince1970, forKey: "lastUpdate")
        }
    }
    @Published var error: HealthStoreError?
    
    @Published var hasPermission = false
    @Published var isFetchingData = false
    
    private let defaults = UserDefaults.standard
    
    override init() {
        // Initialize lastUpdate from stored timestamp or current date
        if let timestamp = UserDefaults.standard.object(forKey: "lastUpdate") as? TimeInterval {
            self.lastUpdate = Date(timeIntervalSince1970: timestamp)
        } else {
            self.lastUpdate = Date()
        }
        
        super.init()
        
        // Try to load data with validation
        if !tryLoadAndValidateData() {
            print("Data validation failed, triggering migration...")
            migrateDataToNewFormat()
        }
        
        checkAuthorizationStatus()
    }
    
    private func tryLoadAndValidateData() -> Bool {
        do {
            // Load and validate health records
            if let data = defaults.data(forKey: "healthRecords") {
                let decoder = JSONDecoder()
                let records = try decoder.decode([HealthRecord].self, from: data)
                
                // Validate dates are within reasonable range
                let now = Date()
                let fiveYearsAgo = Calendar.current.date(byAdding: .year, value: -5, to: now) ?? now
                let oneYearAhead = Calendar.current.date(byAdding: .year, value: 1, to: now) ?? now
                
                self.healthRecords = records.filter { record in
                    let isValid = record.date >= fiveYearsAgo && record.date <= oneYearAhead
                    if !isValid {
                        print("Filtering out record with invalid date: \(record.date)")
                    }
                    return isValid
                }
            }
            
            // Load and validate user profile
            if let data = defaults.data(forKey: "userProfile") {
                let decoder = JSONDecoder()
                let profile = try decoder.decode(UserProfile.self, from: data)
                
                // Validate birthday
                if profile.birthday <= Date() {
                    self.userProfile = profile
                } else {
                    print("Invalid birthday in future: \(profile.birthday)")
                    return false
                }
            }
            
            return true
        } catch {
            print("Error loading or validating data: \(error)")
            return false
        }
    }
    
    private func cleanupCorruptedData() {
        var cleanupPerformed = false
        
        for key in ["healthRecords", "userProfile", "lastUpdate"] {
            if defaults.object(forKey: key) != nil {
                defaults.removeObject(forKey: key)
                cleanupPerformed = true
                print("Cleaned up key: \(key)")
            }
        }
        
        if cleanupPerformed {
            defaults.synchronize()
            print("Data cleanup completed at: \(Date())")
        }
    }
    
    func saveData() {
        do {
            let encoder = JSONEncoder()
            
            // Save health records
            let healthRecordsData = try encoder.encode(healthRecords)
            defaults.set(healthRecordsData, forKey: "healthRecords")
            
            // Save user profile if exists
            if let profile = userProfile {
                let profileData = try encoder.encode(profile)
                defaults.set(profileData, forKey: "userProfile")
            }
            
            defaults.synchronize()
            
        } catch {
            print("Error saving data: \(error)")
            self.error = .saveFailed(error)
        }
    }
    
    func clearUserDefaultsData() {
        // Clear all app-related data
        let allKeys = defaults.dictionaryRepresentation().keys
        for key in allKeys {
            if key.hasPrefix("healthRecords") || 
               key.hasPrefix("userProfile") || 
               key.hasPrefix("lastUpdate") ||
               key.hasPrefix("dailyNotes") {
                defaults.removeObject(forKey: key)
            }
        }
        defaults.synchronize()
        
        // Reset in-memory data
        self.healthRecords = []
        self.userProfile = nil
        self.lastUpdate = Date()
        
        print("All UserDefaults data cleared at: \(Date())")
    }
    
    func migrateDataToNewFormat() {
        clearUserDefaultsData()
        
        self.error = .loadFailed(NSError(
            domain: "com.recordh",
            code: -1,
            userInfo: [
                NSLocalizedDescriptionKey: "数据格式已更新，请重新输入您的信息。",
                NSLocalizedFailureReasonErrorKey: "修复日期格式问题"
            ]
        ))
    }
    
    // MARK: - Health Kit Integration
    
    func refreshData() async {
        guard !isFetchingData else { return }
        await refreshAllData()
    }
    
    func setupBackgroundDelivery() {
        let types = requiredTypes
        startObservingChanges(for: types) { [weak self] in
            Task { @MainActor in
                await self?.refreshData()
            }
        }
    }
    
    // MARK: - Records Management
    
    func addRecord(_ record: HealthRecord) {
        if let index = healthRecords.firstIndex(where: { $0.metric == record.metric }) {
            healthRecords[index] = record
        } else {
            healthRecords.append(record)
        }
        saveData()
    }
    
    func deleteRecord(_ record: HealthRecord) {
        healthRecords.removeAll { $0.id == record.id }
        saveData()
    }
    
    func records(for metric: HealthMetric) -> [HealthRecord] {
        healthRecords
            .filter { $0.metric == metric }
            .sorted { $0.date > $1.date }
    }
    
    func latestRecord(for metric: HealthMetric) -> HealthRecord? {
        records(for: metric).first
    }
    
    // MARK: - Error Handling
    
    func handleError(_ error: Error) {
        if let healthError = error as? HealthStoreError {
            self.error = healthError
        } else {
            self.error = .fetchFailed(error)
        }
    }
}
