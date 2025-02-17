import SwiftUI
import Charts

enum TimeFilterOption: String, CaseIterable {
    case year = "近一年"
    case month = "近一月"
    case week = "近一周"
    case all = "全部记录"
    
    var days: Int? {
        switch self {
        case .year: return 365
        case .month: return 30
        case .week: return 7
        case .all: return nil
        }
    }
}

struct HealthMetricDetailView: View {
    @EnvironmentObject var healthStore: HealthStore
    let type: HealthRecord.RecordType
    @Environment(\.colorScheme) var colorScheme
    @State private var showingAddRecord = false
    @State private var selectedTimeFilter: TimeFilterOption = .year
    
    var filteredRecords: [HealthRecord] {
        let records = healthStore.getRecords(for: type)
        if let days = selectedTimeFilter.days {
            let calendar = Calendar.current
            let pastDate = calendar.date(byAdding: .day, value: -days, to: Date()) ?? Date.distantPast
            return records.filter { $0.date >= pastDate }
        }
        return records
    }
    
    var body: some View {
        List {
            Section(header: Text("数据图表")) {
                chartSection
            }
            
            Section(header: HStack {
                Text("历史记录")
                Spacer()
                Menu {
                    ForEach(TimeFilterOption.allCases, id: \.self) { option in
                        Button(action: {
                            selectedTimeFilter = option
                        }) {
                            HStack {
                                Text(option.rawValue)
                                if selectedTimeFilter == option {
                                    Image(systemName: "checkmark")
                                }
                            }
                        }
                    }
                } label: {
                    HStack {
                        Text(selectedTimeFilter.rawValue)
                        Image(systemName: "line.3.horizontal.decrease.circle")
                    }
                    .foregroundColor(Theme.color(.accent, scheme: colorScheme))
                }
            }) {
                ForEach(filteredRecords, id: \.id) { record in
                    HStack {
                        Text(record.date.formatted(.dateTime.month().day().hour().minute()))
                        Spacer()
                        if type.needsSecondaryValue {
                            Text("\(String(format: "%.1f", record.value))/\(String(format: "%.1f", record.secondaryValue ?? 0)) \(record.unit)")
                        } else {
                            Text("\(String(format: "%.1f", record.value)) \(record.unit)")
                        }
                    }
                    .swipeActions {
                        Button(role: .destructive) {
                            healthStore.deleteHealthRecord(record.id)
                        } label: {
                            Label("删除", systemImage: "trash")
                        }
                    }
                }
            }
        }
        .navigationTitle(type.displayName)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(action: {
                    showingAddRecord = true
                }) {
                    Image(systemName: "plus")
                }
            }
        }
        .sheet(isPresented: $showingAddRecord) {
            AddRecordSheet(
                type: type,
                isPresented: $showingAddRecord
            )
            .environmentObject(healthStore)
        }
    }

    private var weightCharts: some View {
        VStack(spacing: 20) {
            WeightChartSection(records: filteredRecords)
                .environmentObject(healthStore)
                .frame(height: 200)

            BMIChartSection(records: filteredRecords)
                .environmentObject(healthStore)
                .frame(height: 200)
        }
        .listRowBackground(Theme.color(.cardBackground, scheme: colorScheme))
        .listRowInsets(EdgeInsets())
        .padding()
    }

    private var bloodPressureCharts: some View {
        VStack(spacing: 20) {
            BloodPressureChartSection(
                records: filteredRecords,
                title: "收缩压",
                valueSelector: { $0.value },
                normalRange: type.normalRange,
                color: Theme.color(.accent, scheme: colorScheme)
            )
            .frame(height: 200)

            BloodPressureChartSection(
                records: filteredRecords,
                title: "舒张压",
                valueSelector: { $0.secondaryValue ?? 0 },
                normalRange: type.secondaryNormalRange ?? (min: nil, max: nil),
                color: Theme.color(.secondaryText, scheme: colorScheme)
            )
            .frame(height: 200)
        }
        .listRowBackground(Theme.color(.cardBackground, scheme: colorScheme))
        .listRowInsets(EdgeInsets())
        .padding()
    }

    private var genericChart: some View {
        ChartSection(records: filteredRecords, type: type)
            .environmentObject(healthStore)
            .frame(height: 200)
            .listRowBackground(Theme.color(.cardBackground, scheme: colorScheme))
            .listRowInsets(EdgeInsets())
            .padding()
    }

    @ViewBuilder
    private var chartSection: some View {
        if type == .weight {
            weightCharts
        } else if type == .bloodPressure {
            bloodPressureCharts
        } else {
            genericChart
        }
    }
}

#Preview {
    HealthMetricDetailView(type: .weight)
        .environmentObject(HealthStore())
}
