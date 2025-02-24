import SwiftUI

struct MetricsHistoryView: View {
    @EnvironmentObject var healthStore: HealthStore
    @Environment(\.theme) var theme
    @StateObject private var viewModel = MetricsHistoryViewModel()
    
    var body: some View {
        MyRefreshableScrollView(isRefreshing: viewModel.isRefreshing, onRefresh: {
            await viewModel.refreshData()
        }) {
            LazyVStack(spacing: 16) {
                ForEach(HealthMetric.allCases) { metric in
                    // Only show sections with data
                    if let records = viewModel.groupedRecords[metric],
                       !records.isEmpty {
                        Section(metric: metric, records: records)
                    }
                }
            }
            .padding()
        }
        .background(theme.backgroundColor)
        .onAppear {
            viewModel.healthStore = healthStore
            viewModel.loadData()
        }
    }
}

private struct Section: View {
    let metric: HealthMetric
    let records: [HealthRecord]
    @Environment(\.theme) var theme
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            NavigationLink(destination: SingleMetricHistoryView(
                metric: metric,
                metricRecords: records,
                aiParameters: [:]
            )) {
                HStack {
                    Text(metric.name)
                        .font(.headline)
                        .foregroundColor(theme.textColor)
                    
                    Spacer()
                    
                    Image(systemName: "chevron.right")
                        .foregroundColor(theme.secondaryTextColor)
                }
            }
            
            if let latest = records.first {
                Text(latest.formattedValue)
                    .font(.title2)
                    .foregroundColor(theme.accentColor)
            }
            
            MinimalTrendLine(records: records)
                .frame(height: 40)
            
            ForEach(records.prefix(3)) { record in
                RecordRow(record: record)
            }
            
            if records.count > 3 {
                NavigationLink(destination: SingleMetricHistoryView(
                    metric: metric,
                    metricRecords: records,
                    aiParameters: [:]
                )) {
                    Text("查看全部 \(records.count) 条记录")
                        .font(.subheadline)
                        .foregroundColor(theme.accentColor)
                }
            }
        }
        .padding()
        .background(theme.secondaryBackgroundColor)
        .cornerRadius(12)
    }
}

#Preview {
    NavigationView {
        MetricsHistoryView()
            .environmentObject(HealthStore.shared)
    }
}
