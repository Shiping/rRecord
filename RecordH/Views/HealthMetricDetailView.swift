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
    @ObservedObject var healthStore: HealthStore
    @Environment(\.colorScheme) var colorScheme
    let type: HealthRecord.RecordType
    @State private var showingAddRecord = false
    @State private var recordToEdit: HealthRecord? = nil
    @State private var selectedTimeFilter: TimeFilterOption = .year
    
    var filteredRecords: [HealthRecord] {
        let allRecords = healthStore.getRecords(for: type)
        
        // Filter by date if needed
        let dateFilteredRecords: [HealthRecord]
        if let days = selectedTimeFilter.days {
            let cutoffDate = Calendar.current.date(
                byAdding: .day,
                value: -days,
                to: Date()
            ) ?? Date()
            
            dateFilteredRecords = allRecords.filter { record in 
                record.date >= cutoffDate
            }
        } else {
            dateFilteredRecords = allRecords
        }
        
        // Return reversed for newest first
        return dateFilteredRecords.reversed()
    }
    
    private var timeFilterPicker: some View {
        Picker("时间筛选", selection: $selectedTimeFilter) {
            ForEach(TimeFilterOption.allCases, id: \.self) { option in
                Text(option.rawValue).tag(option)
            }
        }
        .pickerStyle(.segmented)
        .padding()
    }
    
    private var recordList: some View {
        ForEach(Array(filteredRecords.enumerated()), id: \.element.id) { index, record in
            RecordRow(record: record, type: type, healthStore: healthStore)
                .listRowBackground(Theme.color(.cardBackground, scheme: colorScheme))
                .swipeActions(edge: .trailing) {
                    Button(role: .destructive) {
                        healthStore.deleteHealthRecord(record.id)
                    } label: {
                        Label("删除", systemImage: "trash")
                    }
                    
                    Button {
                        editRecord(record)
                    } label: {
                        Label("编辑", systemImage: "pencil")
                    }
                    .tint(.orange)
                }
        }
    }
    
    private var toolbarLeadingItem: some View {
        HStack {
            Image(systemName: "heart.text.square.fill")
                .foregroundColor(.red)
            Text("来自HealthKit")
                .font(.caption)
                .foregroundColor(Theme.color(.secondaryText, scheme: colorScheme))
        }
    }
    
    private var toolbarTrailingItem: some View {
        Button(action: { showingAddRecord = true }) {
            Image(systemName: "plus.circle.fill")
                .foregroundColor(Theme.color(.accent, scheme: colorScheme))
        }
    }
    
    private var addRecordSheet: some View {
        AddRecordSheet(
            type: type,
            healthStore: healthStore,
            isPresented: $showingAddRecord,
            editingRecord: recordToEdit
        )
    }
    
    var body: some View {
        VStack {
            timeFilterPicker
            
            List {
                chartSection
                recordList
            }
            .background(Theme.gradientBackground(for: colorScheme))
            .navigationTitle(type.displayName)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    toolbarLeadingItem
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    toolbarTrailingItem
                }
            }
            .sheet(isPresented: $showingAddRecord) {
                addRecordSheet
            }
        }
    }
    
    private func editRecord(_ record: HealthRecord) {
        recordToEdit = record
        showingAddRecord = true
    }
    private var weightCharts: some View {
        VStack(spacing: 20) {
            WeightChartSection(records: filteredRecords)
                .frame(height: 200)
            
            BMIChartSection(records: filteredRecords, healthStore: healthStore)
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
        ChartSection(records: filteredRecords, type: type, healthStore: healthStore)
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
    HealthMetricDetailView(
        healthStore: HealthStore(),
        type: .weight
    )
}
