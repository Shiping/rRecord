import SwiftUI

struct LatestMetricsGrid: View {
    @EnvironmentObject var healthStore: HealthStore
    @Environment(\.theme) var theme
    @Binding var navigationPath: NavigationPath
    
    // Get AI parameters from parent
    let aiParameters: [String: String]
    
    // Single column for full width
    let columns = [
        GridItem(.flexible())
    ]
    
    var body: some View {
        VStack(alignment: .leading) {
            Text("最新指标")
                .font(.title2)
                .bold()
                .padding(.horizontal)
            
            LazyVGrid(columns: columns, spacing: 16) {
                ForEach(HealthMetric.allCases) { metric in
                    MetricCard(
                        metric: metric,
                        record: healthStore.latestRecord(for: metric),
                        aiParameters: aiParameters,
                        navigationPath: $navigationPath
                    )
                }
            }
            .padding(.horizontal)
        }
    }
}

private struct MetricCard: View {
    let metric: HealthMetric
    let record: HealthRecord?
    let aiParameters: [String: String]
    @Binding var navigationPath: NavigationPath
    @Environment(\.theme) var theme
    @EnvironmentObject var healthStore: HealthStore
    @State private var showingAddRecord = false
    
    var body: some View {
        ZStack {
            Button(action: {
                navigationPath.append(DashboardView.NavigationDestination.metric(metric))
            }) {
                HStack {
                    VStack(alignment: .leading, spacing: 8) {
                        Text(metric.name)
                            .font(.headline)
                            .foregroundColor(theme.textColor)
                        
                        if let record = record {
                            Text(record.formattedValue)
                                .font(.title2)
                                .foregroundColor(theme.accentColor)
                            
                            MinimalTrendLine(records: [record])
                                .frame(height: 30)
                        } else {
                            Text("暂无数据")
                                .font(.subheadline)
                                .foregroundColor(theme.secondaryTextColor)
                            
                            MinimalTrendLine(records: [])
                                .frame(height: 30)
                        }
                    }
                    Spacer()
                }
            }
            
            // Add record button
            HStack {
                Spacer()
                Button(action: { showingAddRecord = true }) {
                    Image(systemName: "plus.circle.fill")
                        .font(.title2)
                        .foregroundColor(theme.accentColor)
                }
                .padding()
            }
        }
        .padding()
        .background(theme.secondaryBackgroundColor)
        .cornerRadius(12)
        .sheet(isPresented: $showingAddRecord) {
            AddRecordSheet(metric: metric)
                .environmentObject(healthStore)
        }
    }
}

#Preview {
    NavigationStack {
        LatestMetricsGrid(
            navigationPath: .constant(NavigationPath()),
            aiParameters: [:]
        )
        .environmentObject(HealthStore.shared)
    }
}
