import Foundation
import HealthKit

@MainActor
extension HealthStore {
    
    func refreshAllData() async {
        guard !isFetchingData else { return }
        isFetchingData = true
        defer { isFetchingData = false }
        
        do {
            try await ensureAuthorization()
            try await refreshMetrics()
            saveData()
            NotificationCenter.default.post(name: .init("HealthDataDidUpdate"), object: nil)
            lastUpdate = Date()
        } catch {
            self.error = .fetchFailed(error)
        }
    }
    
    private func refreshMetrics() async throws {
        for metric in HealthMetric.allCases {
            guard let type = metric.hkType else { continue }
            
            let now = Date()
            let past = Calendar.current.date(byAdding: .day, value: -7, to: now) ?? now
            
            let samples = try await fetchSamples(for: type,
                                               from: past,
                                               to: now)
            
            if let latestSample = samples.first,
               let record = HealthRecord(sample: latestSample, metric: metric) {
                updateRecord(record)
            }
        }
    }
    
    private func updateRecord(_ record: HealthRecord) {
        if let index = healthRecords.firstIndex(where: { $0.metric == record.metric }) {
            healthRecords[index] = record
        } else {
            healthRecords.append(record)
        }
    }
    
    func clearData() {
        healthRecords.removeAll()
        saveData()
    }
    
    func markError(_ error: Error) {
        self.error = .fetchFailed(error)
    }
    
    func clearError() {
        error = nil
    }
}

extension HealthStore: @unchecked Sendable {}
