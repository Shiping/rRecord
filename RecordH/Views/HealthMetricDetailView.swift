import SwiftUI
import HealthKit

struct HealthMetricDetailView: View {
    let metric: HealthMetric
    @EnvironmentObject var healthStore: HealthStore
    @Environment(\.theme) var theme
    
    private var filteredRecords: [HealthRecord] {
        healthStore.healthRecords
            .filter { $0.metric == metric }
            .sorted { $0.date > $1.date }
    }
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Chart section
                Section {
                    if filteredRecords.isEmpty {
                        Text("暂无数据")
                            .foregroundColor(theme.secondaryTextColor)
                            .padding()
                    } else {
                        ChartSections(records: filteredRecords)
                    }
                } header: {
                    HStack {
                        Text("趋势图")
                            .font(.headline)
                        Spacer()
                    }
                }
                .padding(.horizontal)
                
                // Records list
                Section {
                    ForEach(filteredRecords) { record in
                        RecordRow(record: record)
                            .padding(.horizontal)
                    }
                } header: {
                    HStack {
                        Text("历史记录")
                            .font(.headline)
                        Spacer()
                    }
                    .padding(.horizontal)
                }
            }
            .padding(.vertical)
        }
        .navigationTitle(metric.name)
    }
}

#Preview {
    NavigationView {
        HealthMetricDetailView(metric: .bodyMass)
            .environmentObject(HealthStore.shared)
    }
}
