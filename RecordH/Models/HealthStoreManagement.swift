import Foundation

extension HealthStore {
    // MARK: - Data Management Methods
    func getLatestRecord(for type: HealthRecord.RecordType) -> HealthRecord? {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        
        // First try to get today's record
        if let todayRecord = healthRecords
            .filter({ $0.type == type && calendar.isDate(calendar.startOfDay(for: $0.date), inSameDayAs: today) })
            .max(by: { $0.date < $1.date }) {
            return todayRecord
        }
        
        // If no today's record, get the most recent one
        return healthRecords
            .filter { $0.type == type }
            .max { $0.date < $1.date }
    }
    
    func getRecords(for type: HealthRecord.RecordType, limit: Int? = nil) -> [HealthRecord] {
        // Always sort by date in descending order (newest first)
        let sortedRecords = healthRecords
            .filter { $0.type == type }
            .sorted { record1, record2 in
                // For sleep data, compare by date only (ignore time)
                if type == .sleep {
                    let calendar = Calendar.current
                    return calendar.startOfDay(for: record1.date) > calendar.startOfDay(for: record2.date)
                }
                // For other metrics, compare full datetime for most recent first
                return record1.date > record2.date
            }
        
        if let limit = limit {
            return Array(sortedRecords.prefix(limit))
        }
        return sortedRecords
    }

    func addHealthRecord(_ record: HealthRecord) {
        DispatchQueue.main.async {
            // For steps and flights climbed, keep only the latest record for each day
            if record.type == .steps || record.type == .flightsClimbed {
                let calendar = Calendar.current
                let recordDate = calendar.startOfDay(for: record.date)
                
                // Remove existing records of the same type for the same day
                self.healthRecords.removeAll { existingRecord in
                    existingRecord.type == record.type &&
                    calendar.isDate(calendar.startOfDay(for: existingRecord.date), inSameDayAs: recordDate)
                }
            }
            
            self.healthRecords.append(record)
            self.saveData()
            self.objectWillChange.send()
        }
    }
    
    func updateHealthRecord(_ updatedRecord: HealthRecord) {
        DispatchQueue.main.async {
            if let index = self.healthRecords.firstIndex(where: { $0.id == updatedRecord.id }) {
                self.healthRecords[index] = updatedRecord
                self.saveData()
                self.objectWillChange.send()
            }
        }
    }
    
    func deleteHealthRecord(_ id: UUID) {
        DispatchQueue.main.async {
            self.healthRecords.removeAll { $0.id == id }
            self.saveData()
            self.objectWillChange.send()
        }
    }

    // MARK: - Notes Management
    func addDailyNote(_ note: DailyNote) throws {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            self.dailyNotes.append(note)
            self.dailyNotes.sort(by: { $0.date > $1.date })
            self.saveData()
            NotificationCenter.default.post(name: .init("NotesDidUpdate"), object: nil)
            print("Note added: \(note.content), Total notes: \(self.dailyNotes.count)")
        }
    }
    
    func updateDailyNote(_ updatedNote: DailyNote) throws {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            if let index = self.dailyNotes.firstIndex(where: { $0.id == updatedNote.id }) {
                self.dailyNotes[index] = updatedNote
                self.dailyNotes.sort(by: { $0.date > $1.date })
                self.saveData()
                NotificationCenter.default.post(name: .init("NotesDidUpdate"), object: nil)
            }
        }
    }
    
    func deleteDailyNote(_ id: UUID) {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            self.dailyNotes.removeAll { $0.id == id }
            self.dailyNotes.sort(by: { $0.date > $1.date })
            self.saveData()
            NotificationCenter.default.post(name: .init("NotesDidUpdate"), object: nil)
        }
    }
    
    public func getTodaysNotes() -> [DailyNote] {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        return dailyNotes.filter { calendar.isDate(calendar.startOfDay(for: $0.date), inSameDayAs: today) }
    }

    // MARK: - Profile Management
    public func updateProfile(_ newProfile: UserProfile) {
        DispatchQueue.main.async {
            self.userProfile = newProfile
            self.saveData()
            self.objectWillChange.send()
        }
    }
}
