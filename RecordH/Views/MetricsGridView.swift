import SwiftUI

struct MetricsGridView: View {
    @EnvironmentObject var healthStore: HealthStore
    @Environment(\.theme) var theme
    
    let columns = [
        GridItem(.flexible()),
        GridItem(.flexible())
    ]
    
    private func latestRecord(for metric: HealthMetric) -> HealthRecord? {
        healthStore.healthRecords
            .filter { $0.metric == metric }
            .sorted { $0.date > $1.date }
            .first
    }
    
    var body: some View {
        ScrollView {
            LazyVGrid(columns: columns, spacing: 16) {
                ForEach(HealthMetric.allCases) { metric in
                    NavigationLink(destination: SingleMetricHistoryView(
                        metric: metric,
                        metricRecords: healthStore.healthRecords.filter { $0.metric == metric },
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

private struct MetricCard: View {
    let metric: HealthMetric
    let record: HealthRecord?
    @Environment(\.theme) var theme
    
    private var records: [HealthRecord] {
        guard let record = record else { return [] }
        return [record]
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(metric.name)
                .font(.headline)
                .foregroundColor(theme.textColor)
            
            if let record = record {
                Text(record.formattedValue)
                    .font(.title2)
                    .foregroundColor(theme.accentColor)
                
                MinimalTrendLine(records: records)
                    .frame(height: 30)
            } else {
                Text("暂无数据")
                    .font(.subheadline)
                    .foregroundColor(theme.secondaryTextColor)
                
                MinimalTrendLine(records: [])
                    .frame(height: 30)
            }
        }
        .padding()
        .background(theme.secondaryBackgroundColor)
        .cornerRadius(12)
    }
}

#Preview {
    NavigationView {
        MetricsGridView()
            .environmentObject(HealthStore.shared)
    }
}
