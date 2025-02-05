import SwiftUI
import Charts

struct HealthMetricDetailView: View {
    @ObservedObject var healthStore: HealthStore
    @Environment(\.colorScheme) var colorScheme
    let type: HealthRecord.RecordType
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
                    WeightChartSection(records: records)
                        .frame(height: 200)
                    
                    BMIChartSection(records: records, healthStore: healthStore)
                        .frame(height: 200)
                }
                .listRowBackground(Theme.color(.cardBackground, scheme: colorScheme))
                .listRowInsets(EdgeInsets())
                .padding()
            } else if type == .bloodPressure {
                // Blood Pressure Charts
                VStack(spacing: 20) {
                    BloodPressureChartSection(
                        records: records,
                        title: "收缩压",
                        valueSelector: { $0.value },
                        normalRange: type.normalRange,
                        color: Theme.color(.accent, scheme: colorScheme)
                    )
                    .frame(height: 200)
                    
                    BloodPressureChartSection(
                        records: records,
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
                ChartSection(records: records, type: type, healthStore: healthStore)
                    .frame(height: 200)
                    .listRowBackground(Theme.color(.cardBackground, scheme: colorScheme))
                    .listRowInsets(EdgeInsets())
                    .padding()
            }
            
            ForEach(records) { record in
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
    }
    
    private func editRecord(_ record: HealthRecord) {
        recordToEdit = record
        showingAddRecord = true
    }
}

struct WeightChartSection: View {
    @Environment(\.colorScheme) var colorScheme
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
                .foregroundColor(Theme.color(.text, scheme: colorScheme))
                .padding(.leading)
            
            Chart {
                ForEach(records) { record in
                    LineMark(
                        x: .value("日期", record.date),
                        y: .value("体重", record.value)
                    )
                    .foregroundStyle(Theme.color(.accent, scheme: colorScheme))
                    
                    PointMark(
                        x: .value("日期", record.date),
                        y: .value("体重", record.value)
                    )
                    .foregroundStyle(Theme.color(.accent, scheme: colorScheme))
                }
            }
            .chartYScale(domain: chartYDomain)
            .chartYAxis {
                AxisMarks(position: .leading) { value in
                    AxisValueLabel {
                        Text("\(String(format: "%.1f", value.as(Double.self) ?? 0))")
                            .foregroundColor(Theme.color(.text, scheme: colorScheme))
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
    @Environment(\.colorScheme) var colorScheme
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
                .foregroundColor(Theme.color(.text, scheme: colorScheme))
                .padding(.leading)
            
            Chart {
                RuleMark(y: .value("最小BMI", 18.5))
                    .foregroundStyle(Theme.color(.accent, scheme: colorScheme).opacity(0.5))
                    .lineStyle(StrokeStyle(lineWidth: 1, dash: [5, 5]))
                    .annotation(position: .leading) {
                        Text("18.5")
                            .font(.caption)
                            .foregroundColor(Theme.color(.accent, scheme: colorScheme))
                    }
                
                RuleMark(y: .value("最大BMI", 23.9))
                    .foregroundStyle(Theme.color(.accent, scheme: colorScheme).opacity(0.5))
                    .lineStyle(StrokeStyle(lineWidth: 1, dash: [5, 5]))
                    .annotation(position: .leading) {
                        Text("23.9")
                            .font(.caption)
                            .foregroundColor(Theme.color(.accent, scheme: colorScheme))
                    }
                
                ForEach(records) { record in
                    if let bmi = calculateBMI(weight: record.value) {
                        LineMark(
                            x: .value("日期", record.date),
                            y: .value("BMI", bmi)
                        )
                        .foregroundStyle(Theme.color(.accent, scheme: colorScheme))
                        
                        PointMark(
                            x: .value("日期", record.date),
                            y: .value("BMI", bmi)
                        )
                        .foregroundStyle(Theme.color(.accent, scheme: colorScheme))
                    }
                }
            }
            .chartYScale(domain: chartYDomain)
            .chartYAxis {
                AxisMarks(position: .leading) { value in
                    AxisValueLabel {
                        Text("\(String(format: "%.1f", value.as(Double.self) ?? 0))")
                            .foregroundColor(Theme.color(.text, scheme: colorScheme))
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
    @Environment(\.colorScheme) var colorScheme
    let records: [HealthRecord]
    let type: HealthRecord.RecordType
    @ObservedObject var healthStore: HealthStore
    
    private var chartYDomain: ClosedRange<Double> {
        var values: [Double] = []
        values.append(contentsOf: records.map { $0.value })
        if type.needsSecondaryValue {
            values.append(contentsOf: records.compactMap { $0.secondaryValue })
        }
        
        if let min = type.normalRange.min { values.append(min) }
        if let max = type.normalRange.max { values.append(max) }
        if let secondaryRange = type.secondaryNormalRange {
            if let min = secondaryRange.min { values.append(min) }
            if let max = secondaryRange.max { values.append(max) }
        }
        
        let minValue = values.min() ?? 0
        let maxValue = values.max() ?? 100
        let padding = (maxValue - minValue) * 0.1
        return (minValue - padding)...(maxValue + padding)
    }
    
    var body: some View {
            Chart {
                if let min = type.normalRange.min {
                    RuleMark(y: .value("最小值", min))
                        .foregroundStyle(Theme.color(.accent, scheme: colorScheme).opacity(0.5))
                        .lineStyle(StrokeStyle(lineWidth: 1, dash: [5, 5]))
                        .annotation(position: .leading) {
                            Text("\(String(format: "%.1f", min))")
                                .font(.caption)
                                .foregroundColor(Theme.color(.accent, scheme: colorScheme))
                        }
                }
            
                if let max = type.normalRange.max {
                    RuleMark(y: .value("最大值", max))
                        .foregroundStyle(Theme.color(.accent, scheme: colorScheme).opacity(0.5))
                        .lineStyle(StrokeStyle(lineWidth: 1, dash: [5, 5]))
                        .annotation(position: .leading) {
                            Text("\(String(format: "%.1f", max))")
                                .font(.caption)
                                .foregroundColor(Theme.color(.accent, scheme: colorScheme))
                        }
                }
            
                ForEach(records) { record in
                    if type == .sleep {
                        let totalHours = Double(record.value) + Double(record.secondaryValue ?? 0) / 60.0
                        LineMark(
                            x: .value("日期", record.date),
                            y: .value(type.valueLabel, totalHours)
                        )
                        .foregroundStyle(Theme.color(.accent, scheme: colorScheme))
                        
                        PointMark(
                            x: .value("日期", record.date),
                            y: .value(type.valueLabel, totalHours)
                        )
                        .foregroundStyle(Theme.color(.accent, scheme: colorScheme))
                    } else {
                        LineMark(
                            x: .value("日期", record.date),
                            y: .value(type.valueLabel, record.value)
                        )
                        .foregroundStyle(Theme.color(.accent, scheme: colorScheme))
                        
                        PointMark(
                            x: .value("日期", record.date),
                            y: .value(type.valueLabel, record.value)
                        )
                        .foregroundStyle(Theme.color(.accent, scheme: colorScheme))
                    }
                
                if type.needsSecondaryValue, let secondaryValue = record.secondaryValue {
                    LineMark(
                        x: .value("日期", record.date),
                        y: .value(type.secondaryValueLabel ?? "", secondaryValue)
                    )
                    .foregroundStyle(Theme.color(.secondaryText, scheme: colorScheme))
                    
                    PointMark(
                        x: .value("日期", record.date),
                        y: .value(type.secondaryValueLabel ?? "", secondaryValue)
                    )
                    .foregroundStyle(Theme.color(.secondaryText, scheme: colorScheme))
                }
            }
        }
        .chartYScale(domain: chartYDomain)
        .chartYAxis {
            AxisMarks(position: .leading) { value in
                AxisValueLabel {
                    Text("\(String(format: "%.1f", value.as(Double.self) ?? 0))")
                        .foregroundColor(Theme.color(.text, scheme: colorScheme))
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

struct BloodPressureChartSection: View {
    @Environment(\.colorScheme) var colorScheme
    let records: [HealthRecord]
    let title: String
    let valueSelector: (HealthRecord) -> Double
    let normalRange: (min: Double?, max: Double?)
    let color: Color
    
    private var chartYDomain: ClosedRange<Double> {
        let values = records.map(valueSelector)
        var minValue = values.min() ?? 0
        var maxValue = values.max() ?? 100
        
        if let min = normalRange.min {
            minValue = Swift.min(minValue, min)
        }
        if let max = normalRange.max {
            maxValue = Swift.max(maxValue, max)
        }
        
        let padding = (maxValue - minValue) * 0.1
        return (minValue - padding)...(maxValue + padding)
    }
    
    var body: some View {
        VStack(alignment: .leading) {
            Text(title)
                .font(.headline)
                .foregroundColor(Theme.color(.text, scheme: colorScheme))
            
            Chart {
                ForEach(records) { record in
                    LineMark(
                        x: .value("日期", record.date),
                        y: .value("血压", valueSelector(record))
                    )
                    .foregroundStyle(color)
                    
                    PointMark(
                        x: .value("日期", record.date),
                        y: .value("血压", valueSelector(record))
                    )
                    .foregroundStyle(color)
                }
            }
            .chartYScale(domain: chartYDomain)
            .chartYAxis {
                AxisMarks(position: .leading) { value in
                    AxisValueLabel {
                        Text("\(String(format: "%.1f", value.as(Double.self) ?? 0))")
                            .foregroundColor(Theme.color(.text, scheme: colorScheme))
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

#Preview {
    NavigationView {
        HealthMetricDetailView(
            healthStore: HealthStore(),
            type: .bloodPressure
        )
    }
}
