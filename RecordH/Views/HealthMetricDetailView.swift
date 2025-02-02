import SwiftUI
import Charts


struct HealthMetricDetailView: View {
    let type: HealthRecord.RecordType
    @ObservedObject var healthStore: HealthStore
    @State private var showingAddRecord = false
    @State private var recordToEdit: HealthRecord? = nil
    
    var records: [HealthRecord] {
        healthStore.getRecords(for: type)
    }
    
    var body: some View {
        List {
            if type == .weight {
                // Weight and BMI Charts
                VStack(spacing: 20) {
                    // Weight Chart
                    WeightChartSection(records: records)
                        .frame(height: 200)
                    
                    // BMI Chart
                    BMIChartSection(records: records, healthStore: healthStore)
                        .frame(height: 200)
                }
                .listRowBackground(Theme.cardBackground)
                .listRowInsets(EdgeInsets())
                .padding()
            } else {
                // Other metrics Chart
                ChartSection(records: records, type: type, healthStore: healthStore)
                    .frame(height: 200)
                    .listRowBackground(Theme.cardBackground)
                    .listRowInsets(EdgeInsets())
                    .padding()
            }
            
            // Records List
            ForEach(records) { record in
                RecordRow(record: record, type: type, healthStore: healthStore)
                    .listRowBackground(Theme.cardBackground)
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
        .background(Theme.gradientBackground())
        .navigationTitle(type.displayName)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(action: { showingAddRecord = true }) {
                    Image(systemName: "plus.circle.fill")
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
    }
    
    private func editRecord(_ record: HealthRecord) {
        recordToEdit = record
        showingAddRecord = true
    }
}

struct WeightChartSection: View {
    let records: [HealthRecord]
    
    private var chartYDomain: ClosedRange<Double> {
        let values = records.map { $0.value }
        let minValue = values.min() ?? 0
        let maxValue = values.max() ?? 100
        let padding = (maxValue - minValue) * 0.1
        return (minValue - padding)...(maxValue + padding)
    }
    
    var body: some View {
        VStack(alignment: .leading) {
            Text("体重记录")
                .font(.headline)
                .foregroundColor(Theme.text)
                .padding(.leading)
            
            Chart {
                ForEach(records) { record in
                    PointMark(
                        x: .value("日期", record.date),
                        y: .value("体重", record.value)
                    )
                    .foregroundStyle(Theme.accent)
                }
            }
            .chartYScale(domain: chartYDomain)
            .chartYAxis {
                AxisMarks(position: .leading) { value in
                    AxisValueLabel {
                        Text("\(String(format: "%.1f", value.as(Double.self) ?? 0))")
                            .foregroundColor(Theme.text)
                    }
                    AxisGridLine()
                }
            }
            .chartXAxis {
                AxisMarks(values: .stride(by: .day)) { value in
                    AxisGridLine()
                    AxisValueLabel(format: .dateTime.day().month())
                }
            }
        }
    }
}

struct BMIChartSection: View {
    let records: [HealthRecord]
    @ObservedObject var healthStore: HealthStore
    
    private func calculateBMI(weight: Double) -> Double? {
        guard let height = healthStore.userProfile?.height else { return nil }
        let heightInMeters = height / 100
        return weight / (heightInMeters * heightInMeters)
    }
    
    private var chartYDomain: ClosedRange<Double> {
        let values = records.compactMap { calculateBMI(weight: $0.value) }
        let minValue = min(values.min() ?? 18.5, 18.5)
        let maxValue = max(values.max() ?? 23.9, 23.9)
        let padding = (maxValue - minValue) * 0.1
        return (minValue - padding)...(maxValue + padding)
    }
    
    var body: some View {
        VStack(alignment: .leading) {
            Text("BMI记录")
                .font(.headline)
                .foregroundColor(Theme.text)
                .padding(.leading)
            
            Chart {
                // BMI normal range
                RuleMark(y: .value("最小BMI", 18.5))
                    .foregroundStyle(Theme.accent.opacity(0.5))
                    .lineStyle(StrokeStyle(lineWidth: 1, dash: [5, 5]))
                    .annotation(position: .leading) {
                        Text("18.5")
                            .font(.caption)
                            .foregroundColor(Theme.accent)
                    }
                
                RuleMark(y: .value("最大BMI", 23.9))
                    .foregroundStyle(Theme.accent.opacity(0.5))
                    .lineStyle(StrokeStyle(lineWidth: 1, dash: [5, 5]))
                    .annotation(position: .leading) {
                        Text("23.9")
                            .font(.caption)
                            .foregroundColor(Theme.accent)
                    }
                
                ForEach(records) { record in
                    if let bmi = calculateBMI(weight: record.value) {
                        PointMark(
                            x: .value("日期", record.date),
                            y: .value("BMI", bmi)
                        )
                        .foregroundStyle(Theme.accent)
                    }
                }
            }
            .chartYScale(domain: chartYDomain)
            .chartYAxis {
                AxisMarks(position: .leading) { value in
                    AxisValueLabel {
                        Text("\(String(format: "%.1f", value.as(Double.self) ?? 0))")
                            .foregroundColor(Theme.text)
                    }
                    AxisGridLine()
                }
            }
            .chartXAxis {
                AxisMarks(values: .stride(by: .day)) { value in
                    AxisGridLine()
                    AxisValueLabel(format: .dateTime.day().month())
                }
            }
        }
    }
}

struct ChartSection: View {
    let records: [HealthRecord]
    let type: HealthRecord.RecordType
    @ObservedObject var healthStore: HealthStore
    
    private var chartYDomain: ClosedRange<Double> {
        var values: [Double] = []
        
        // Add data points
        values.append(contentsOf: records.map { $0.value })
        if type.needsSecondaryValue {
            values.append(contentsOf: records.compactMap { $0.secondaryValue })
        }
        
        // Add normal range bounds
        if let min = type.normalRange.min {
            values.append(min)
        }
        if let max = type.normalRange.max {
            values.append(max)
        }
        if let secondaryRange = type.secondaryNormalRange {
            if let min = secondaryRange.min {
                values.append(min)
            }
            if let max = secondaryRange.max {
                values.append(max)
            }
        }
        
        // Calculate domain with padding
        let minValue = values.min() ?? 0
        let maxValue = values.max() ?? 100
        let padding = (maxValue - minValue) * 0.1
        
        return (minValue - padding)...(maxValue + padding)
    }
    
    var body: some View {
        Chart {
            // Primary value normal range
            if let min = type.normalRange.min {
                RuleMark(y: .value("最小值", min))
                    .foregroundStyle(Theme.accent.opacity(0.5))
                    .lineStyle(StrokeStyle(lineWidth: 1, dash: [5, 5]))
                    .annotation(position: .leading) {
                        Text("\(String(format: "%.1f", min))")
                            .font(.caption)
                            .foregroundColor(Theme.accent)
                    }
            }
            
            if let max = type.normalRange.max {
                RuleMark(y: .value("最大值", max))
                    .foregroundStyle(Theme.accent.opacity(0.5))
                    .lineStyle(StrokeStyle(lineWidth: 1, dash: [5, 5]))
                    .annotation(position: .leading) {
                        Text("\(String(format: "%.1f", max))")
                            .font(.caption)
                            .foregroundColor(Theme.accent)
                    }
            }
            
            // Secondary value normal range (for blood pressure)
            if let secondaryRange = type.secondaryNormalRange {
                if let min = secondaryRange.min {
                    RuleMark(y: .value("最小值", min))
                        .foregroundStyle(Theme.secondaryText.opacity(0.5))
                        .lineStyle(StrokeStyle(lineWidth: 1, dash: [5, 5]))
                        .annotation(position: .trailing) {
                            Text("\(String(format: "%.1f", min))")
                                .font(.caption)
                                .foregroundColor(Theme.secondaryText)
                        }
                }
                
                if let max = secondaryRange.max {
                    RuleMark(y: .value("最大值", max))
                        .foregroundStyle(Theme.secondaryText.opacity(0.5))
                        .lineStyle(StrokeStyle(lineWidth: 1, dash: [5, 5]))
                        .annotation(position: .trailing) {
                            Text("\(String(format: "%.1f", max))")
                                .font(.caption)
                                .foregroundColor(Theme.secondaryText)
                        }
                }
            }
            
            // Data points
            ForEach(records) { record in
                PointMark(
                    x: .value("日期", record.date),
                    y: .value(type.valueLabel, record.value)
                )
                .foregroundStyle(Theme.accent)
                
                if type.needsSecondaryValue, let secondaryValue = record.secondaryValue {
                    PointMark(
                        x: .value("日期", record.date),
                        y: .value(type.secondaryValueLabel ?? "", secondaryValue)
                    )
                    .foregroundStyle(Theme.secondaryText)
                }
            }
        }
        .chartYScale(domain: chartYDomain)
        .chartYAxis {
            AxisMarks(position: .leading) { value in
                AxisValueLabel("\(value.index)")
                AxisGridLine()
            }
        }
        .chartXAxis {
            AxisMarks(values: .stride(by: .day)) { value in
                AxisGridLine()
                AxisValueLabel(format: .dateTime.day().month())
            }
        }
    }
}

struct RecordRow: View {
    let record: HealthRecord
    let type: HealthRecord.RecordType
    @ObservedObject var healthStore: HealthStore
    
    private func calculateBMI(weight: Double) -> Double? {
        guard let height = healthStore.userProfile?.height else { return nil }
        let heightInMeters = height / 100
        return weight / (heightInMeters * heightInMeters)
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            if type == .weight {
                HStack {
                    Text("\(String(format: "%.1f", record.value)) \(record.unit)")
                        .font(.title3)
                        .foregroundColor(Theme.text)
                    
                    if let bmi = calculateBMI(weight: record.value) {
                        Text("BMI: \(String(format: "%.1f", bmi))")
                            .font(.title3)
                            .foregroundColor(Theme.secondaryText)
                    }
                }
            } else if type == .sleep {
                let hours = Int(record.value / 3600)
                let minutes = Int((record.value.truncatingRemainder(dividingBy: 3600)) / 60)
                Text("\(hours)小时\(minutes)分钟")
                    .font(.title3)
                    .foregroundColor(Theme.text)
            } else if type.needsSecondaryValue, let diastolic = record.secondaryValue {
                Text("\(String(format: "%.0f/%.0f", record.value, diastolic)) \(record.unit)")
                    .font(.title3)
                    .foregroundColor(Theme.text)
            } else {
                Text("\(String(format: "%.1f", record.value)) \(record.unit)")
                    .font(.title3)
                    .foregroundColor(Theme.text)
            }
            
            Text(record.date.formatted(.dateTime.year().month().day().hour().minute()))
                .font(.subheadline)
                .foregroundColor(Theme.secondaryText)
            
            if let note = record.note {
                Text(note)
                    .font(.body)
                    .foregroundColor(Theme.text)
            }
        }
        .padding(.vertical, 8)
    }
}

struct AddRecordSheet: View {
    let type: HealthRecord.RecordType
    @ObservedObject var healthStore: HealthStore
    @Binding var isPresented: Bool
    var editingRecord: HealthRecord?
    
    @State private var value: String = ""
    @State private var secondaryValue: String = ""
    @State private var note: String = ""
    @State private var selectedDate = Date()
    @State private var sleepHours: String = ""
    @State private var sleepMinutes: String = ""
    
    init(type: HealthRecord.RecordType, healthStore: HealthStore, isPresented: Binding<Bool>, editingRecord: HealthRecord? = nil) {
        self.type = type
        self.healthStore = healthStore
        self._isPresented = isPresented
        self.editingRecord = editingRecord
        
        if let record = editingRecord {
            if type == .sleep {
                // Convert seconds to hours and minutes for editing
                let totalSeconds = record.value
                let hours = Int(totalSeconds / 3600)
                let minutes = Int((totalSeconds.truncatingRemainder(dividingBy: 3600)) / 60)
                _sleepHours = State(initialValue: String(hours))
                _sleepMinutes = State(initialValue: String(minutes))
            } else {
                _value = State(initialValue: String(format: "%.1f", record.value))
            }
            _selectedDate = State(initialValue: record.date)
            _note = State(initialValue: record.note ?? "")
            if let secondary = record.secondaryValue {
                _secondaryValue = State(initialValue: String(format: "%.1f", secondary))
            }
        }
    }
    
    private var dateRange: ClosedRange<Date> {
        let calendar = Calendar.current
        let start = calendar.date(byAdding: .year, value: -1, to: Date())!
        let end = Date()
        return start...end
    }
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("记录时间")) {
                    DatePicker(
                        "选择日期时间",
                        selection: $selectedDate,
                        in: dateRange,
                        displayedComponents: [.date, .hourAndMinute]
                    )
                }
                
                Section(header: Text("数值")) {
                    if type == .sleep {
                        HStack {
                            TextField("小时", text: $sleepHours)
                                .keyboardType(.numberPad)
                            Text("小时")
                            
                            TextField("分钟", text: $sleepMinutes)
                                .keyboardType(.numberPad)
                            Text("分钟")
                        }
                    } else {
                        TextField("输入\(type.valueLabel)", text: $value)
                            .keyboardType(.decimalPad)
                        
                        if type.needsSecondaryValue {
                            TextField("输入\(type.secondaryValueLabel ?? "")", text: $secondaryValue)
                                .keyboardType(.decimalPad)
                        }
                    }
                }
                
                Section(header: Text("备注")) {
                    TextField("添加备注", text: $note)
                }
            }
            .navigationTitle("添加\(type.displayName)记录")
            .navigationBarItems(
                leading: Button("取消") {
                    isPresented = false
                },
                trailing: Button("保存") {
                    saveRecord()
                }
            )
        }
    }
    
    private func saveRecord() {
        if type == .sleep {
            guard let hours = Int(sleepHours),
                  let minutes = Int(sleepMinutes),
                  minutes < 60 else { return }
            
            let finalValue = Double(hours * 3600 + minutes * 60)
            saveRecordWithValue(finalValue)
        } else {
            guard let primaryValue = Double(value) else { return }
            let diastolicValue = type.needsSecondaryValue ? Double(secondaryValue) : nil
            
            if type.needsSecondaryValue && diastolicValue == nil {
                return
            }
            
            saveRecordWithValue(primaryValue, secondaryValue: diastolicValue)
        }
    }
    
    private func saveRecordWithValue(_ finalValue: Double, secondaryValue: Double? = nil) {
        
        let record = HealthRecord(
            id: editingRecord?.id ?? UUID(),
            date: selectedDate,
            type: type,
            value: finalValue,
            secondaryValue: secondaryValue,
            unit: type.unit,
            note: note.isEmpty ? nil : note
        )
        
        if editingRecord != nil {
            healthStore.updateHealthRecord(record)
        } else {
            healthStore.addHealthRecord(record)
        }
        isPresented = false
    }
}

#Preview {
    NavigationView {
        HealthMetricDetailView(type: .weight, healthStore: HealthStore())
    }
}
