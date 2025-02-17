import Foundation
import HealthKit

extension HealthStore {
    // MARK: - Properties
    
    // MARK: - Data Refresh Methods
    @objc public dynamic func refreshHealthData(completion: @escaping () -> Void = {}) {
        print("refreshHealthData called")
        // First refresh today's data
        // Then fetch historical data
        fetchLatestHealthData { [weak self] in
            self?.saveData()
            completion()
        }
    }

    func fetchLatestHealthData(completion: @escaping () -> Void = {}) {
        print("fetchLatestHealthData called")
        let calendar = Calendar.current
        let endDate = Date()
        // Get data since last update, or the last 7 days if no last update
        let startDate = self.lastUpdate ?? calendar.date(byAdding: .day, value: -7, to: endDate) ?? endDate

        let group = DispatchGroup()

        // Move the whole process to a background queue
        DispatchQueue.global(qos: .background).async { [weak self] in
            print("fetchLatestHealthData - inside DispatchQueue.global(qos: .background).async")

            // Fetch all available health metrics
            print("fetchLatestHealthData - calling fetchSteps")
            self?.fetchSteps(startDate: startDate, endDate: endDate, group: group)
            print("fetchLatestHealthData - calling fetchHeartRate")
            self?.fetchHeartRate(startDate: startDate, endDate: endDate, group: group)
            print("fetchLatestHealthData - calling fetchActiveEnergy")
            self?.fetchActiveEnergy(startDate: startDate, endDate: endDate, group: group)
            print("fetchLatestHealthData - calling fetchRestingEnergy")
            self?.fetchRestingEnergy(startDate: startDate, endDate: endDate, group: group)
            print("fetchLatestHealthData - calling fetchDistance")
            self?.fetchDistance(startDate: startDate, endDate: endDate, group: group)
            print("fetchLatestHealthData - calling fetchBloodOxygen")
            self?.fetchBloodOxygen(startDate: startDate, endDate: endDate, group: group)
            print("fetchLatestHealthData - calling fetchFlightsClimbed")
            self?.fetchFlightsClimbed(startDate: startDate, endDate: endDate, group: group)
            print("fetchLatestHealthData - calling fetchSleep")
            self?.fetchSleep(startDate: startDate, endDate: endDate, group: group)

            group.notify(queue: .main) {
                guard let self = self else { return }
self.lastUpdate = endDate
                completion()
            }
        }
    }
}
