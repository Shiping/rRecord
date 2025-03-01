import SwiftUI
import Combine

@MainActor
class MetricsHistoryViewModel: ObservableObject {
    weak var healthStore: HealthStore?
    
    @Published var groupedRecords: [HealthMetric: [HealthRecord]] = [:]
    @Published var isRefreshing = false
    
    private var cancellables = Set<AnyCancellable>()
    
    init() {
        setupPublishers()
    }
    
    private func setupPublishers() {
        NotificationCenter.default.publisher(for: .init("HealthDataDidUpdate"))
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                self?.loadData()
            }
            .store(in: &cancellables)
    }
    
    func loadData() {
        guard let healthStore = healthStore else { return }
        
        // Group records by metric type
        var grouped: [HealthMetric: [HealthRecord]] = [:]
        
        for metric in HealthMetric.allCases {
            let records = healthStore.records(for: metric)
            if !records.isEmpty {
                grouped[metric] = records
            }
        }
        
        groupedRecords = grouped
    }
    
    func refreshData() async {
        guard let healthStore = healthStore else { return }
        
        isRefreshing = true
        await healthStore.refreshData()
        loadData()
        isRefreshing = false
    }
    
    func records(for metric: HealthMetric) -> [HealthRecord] {
        groupedRecords[metric] ?? []
    }
    
    // MARK: - Statistics
    
    func latestValue(for metric: HealthMetric) -> Double? {
        records(for: metric).first?.value
    }
    
    func average(for metric: HealthMetric) -> Double? {
        let records = records(for: metric)
        guard !records.isEmpty else { return nil }
        
        let sum = records.reduce(0) { $0 + $1.value }
        return sum / Double(records.count)
    }
    
    func range(for metric: HealthMetric) -> (min: Double, max: Double)? {
        let records = records(for: metric)
        guard !records.isEmpty else { return nil }
        
        let values = records.map(\.value)
        guard let min = values.min(),
              let max = values.max() else {
            return nil
        }
        
        return (min, max)
    }
    
    func trend(for metric: HealthMetric) -> String? {
        let records = records(for: metric)
        guard records.count >= 2 else { return nil }
        
        let first = records.last?.value ?? 0
        let last = records.first?.value ?? 0
        
        let change = ((last - first) / first) * 100
        
        if abs(change) < 5 {
            return "保持稳定"
        } else if change > 0 {
            return "呈上升趋势"
        } else {
            return "呈下降趋势"
        }
    }
}
