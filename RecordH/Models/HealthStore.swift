import Foundation
import SwiftUI


class HealthStore: ObservableObject {
    @Published var userProfile: UserProfile?
    @Published var healthRecords: [HealthRecord] = []
    @Published var dailyNotes: [DailyNote] = []
    
    private let userDefaults = UserDefaults.standard
    
    init() {
        loadData()
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
}
