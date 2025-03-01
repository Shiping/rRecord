import SwiftUI

struct LatestMetricsGrid: View {
    @EnvironmentObject var healthStore: HealthStore
    @Environment(\.theme) var theme
    
    let columns = [
        GridItem(.flexible()),
        GridItem(.flexible())
    ]
    
    var body: some View {
        LazyVGrid(columns: columns, spacing: 16) {
            ForEach(supportedMetrics) { metric in
                NavigationLink(destination: SingleMetricHistoryView(
                    metric: metric,
                    metricRecords: healthStore.records(for: metric),
                    aiParameters: [:]
                )) {
                    MetricCard(metric: metric, record: latestRecord(for: metric))
                }
            }
        }
        .padding(.horizontal)
    }
    
    private var supportedMetrics: [HealthMetric] = [
        .bodyMass,
        .bloodPressureSystolic,
        .bloodPressureDiastolic,
        .bloodGlucose,
        .stepCount,
        .activeEnergy,
        .heartRate
    ]
    
    private func latestRecord(for metric: HealthMetric) -> HealthRecord? {
        return healthStore.records(for: metric).first
    }
}

#Preview {
    LatestMetricsGrid()
        .environmentObject(HealthStore.shared)
}
