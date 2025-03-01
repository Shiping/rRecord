import SwiftUI

struct MetricsGridView: View {
    @EnvironmentObject var healthStore: HealthStore
    @Environment(\.theme) var theme
    
    let columns = [
        GridItem(.flexible()),
        GridItem(.flexible())
    ]
    
    private func latestRecord(for metric: HealthMetric) -> HealthRecord? {
        healthStore.records(for: metric).first
    }
    
    var body: some View {
        ScrollView {
            LazyVGrid(columns: columns, spacing: 16) {
                ForEach(HealthMetric.allCases) { metric in
                    NavigationLink(destination: SingleMetricHistoryView(
                        metric: metric,
                        metricRecords: healthStore.records(for: metric),
                        aiParameters: [:]
                    )) {
                        MetricCard(
                            metric: metric,
                            record: latestRecord(for: metric)
                        )
                    }
                }
            }
            .padding()
        }
        .background(theme.backgroundColor)
    }
}


#Preview {
    NavigationView {
        MetricsGridView()
            .environmentObject(HealthStore.shared)
    }
}
