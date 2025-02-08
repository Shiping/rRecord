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
<<<<<<< Updated upstream
<<<<<<< Updated upstream
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
=======
=======
>>>>>>> Stashed changes
        var records = healthStore.getRecords(for: type)
        if let days = selectedTimeFilter.days {
            let cutoffDate = Calendar.current.date(byAdding: .day, value: -days, to: Date()) ?? Date()
            records = records.filter { $0.date >= cutoffDate }
        }
        return records.reversed() // Show newest records first
<<<<<<< Updated upstream
>>>>>>> Stashed changes
=======
>>>>>>> Stashed changes
    }
    
    var body: some View {
        VStack {
<<<<<<< Updated upstream
<<<<<<< Updated upstream
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
=======
            Picker("时间筛选", selection: $selectedTimeFilter) {
                ForEach(TimeFilterOption.allCases, id: \.self) { option in
                    Text(option.rawValue).tag(option)
                }
=======
            Picker("时间筛选", selection: $selectedTimeFilter) {
                ForEach(TimeFilterOption.allCases, id: \.self) { option in
                    Text(option.rawValue).tag(option)
                }
>>>>>>> Stashed changes
            }
            .pickerStyle(.segmented)
            .padding()
            
            List {
                if type == .weight {
                    // Weight and BMI Charts
                    VStack(spacing: 20) {
                        WeightChartSection(records: filteredRecords)
                            .frame(height: 200)
                        
                        BMIChartSection(records: filteredRecords, healthStore: healthStore)
                            .frame(height: 200)
                    }
                    .listRowBackground(Theme.color(.cardBackground, scheme: colorScheme))
                    .listRowInsets(EdgeInsets())
                    .padding()
                } else if type == .bloodPressure {
                    // Blood Pressure Charts
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
                } else {
                    ChartSection(records: filteredRecords, type: type, healthStore: healthStore)
                        .frame(height: 200)
                        .listRowBackground(Theme.color(.cardBackground, scheme: colorScheme))
                        .listRowInsets(EdgeInsets())
                        .padding()
                }
                
                ForEach(Array(filteredRecords.enumerated()), id: \.element.id) { index, record in
                    RecordRow(record: record, type: type, recordNumber: index + 1, healthStore: healthStore)
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
            .background(Theme.gradientBackground(for: colorScheme))
            .navigationTitle(type.displayName)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    HStack {
                        Image(systemName: "heart.text.square.fill")
                            .foregroundColor(.red)
                        Text("来自HealthKit")
                            .font(.caption)
                            .foregroundColor(Theme.color(.secondaryText, scheme: colorScheme))
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { showingAddRecord = true }) {
                        Image(systemName: "plus.circle.fill")
                            .foregroundColor(Theme.color(.accent, scheme: colorScheme))
                    }
                }
            }
            .sheet(isPresented: $showingAddRecord) {
                AddRecordSheet(
                    type: type,
                    healthStore: healthStore,
                    isPresented: $showingAddRecord,
                    editingRecord: recordToEdit
                )
            }
<<<<<<< Updated upstream
>>>>>>> Stashed changes
=======
>>>>>>> Stashed changes
        }
    }
    
    private func editRecord(_ record: HealthRecord) {
        recordToEdit = record
        showingAddRecord = true
    }
<<<<<<< Updated upstream
<<<<<<< Updated upstream
    private var weightCharts: some View {
        VStack(spacing: 20) {
            WeightChartSection(records: filteredRecords, healthStore: healthStore)
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
=======
}

[Previous content...]
>>>>>>> Stashed changes
=======
}

[Previous content...]
>>>>>>> Stashed changes
