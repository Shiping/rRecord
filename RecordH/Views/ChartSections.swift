import SwiftUI
import Charts

struct WeightChartSection: View {
    let records: [HealthRecord]
    
    var body: some View {
        VStack(alignment: .leading) {
            Text("体重趋势")
                .font(.headline)
            
            Chart(records) { record in
                LineMark(
                    x: .value("Date", record.date),
                    y: .value("Weight", record.value)
                )
                .foregroundStyle(.blue)
                
                PointMark(
                    x: .value("Date", record.date),
                    y: .value("Weight", record.value)
                )
                .foregroundStyle(.blue)
            }
        }
    }
}

struct BMIChartSection: View {
    let records: [HealthRecord]
    let healthStore: HealthStore
    
    var bmiRecords: [(date: Date, bmi: Double)] {
        records.compactMap { record in
            guard let userProfile = healthStore.userProfile else { return nil }
            let bmi = record.value / (userProfile.height * userProfile.height)
            return (record.date, bmi)
        }
    }
    
    var body: some View {
        VStack(alignment: .leading) {
            Text("BMI趋势")
                .font(.headline)
            
            if !bmiRecords.isEmpty {
                Chart(bmiRecords, id: \.date) { record in
                    LineMark(
                        x: .value("Date", record.date),
                        y: .value("BMI", record.bmi)
                    )
                    .foregroundStyle(.green)
                    
                    PointMark(
                        x: .value("Date", record.date),
                        y: .value("BMI", record.bmi)
                    )
                    .foregroundStyle(.green)
                }
            } else {
                Text("请先设置身高以查看BMI")
                    .foregroundColor(.secondary)
            }
        }
    }
}

struct BloodPressureChartSection: View {
    let records: [HealthRecord]
    let title: String
    let valueSelector: (HealthRecord) -> Double
    let normalRange: (min: Double?, max: Double?)
    let color: Color
    
    var body: some View {
        VStack(alignment: .leading) {
            Text(title)
                .font(.headline)
            
            Chart(records) { record in
                LineMark(
                    x: .value("Date", record.date),
                    y: .value("Value", valueSelector(record))
                )
                .foregroundStyle(color)
                
                PointMark(
                    x: .value("Date", record.date),
                    y: .value("Value", valueSelector(record))
                )
                .foregroundStyle(color)
                
                if let min = normalRange.min {
                    RuleMark(y: .value("Min", min))
                        .foregroundStyle(.gray.opacity(0.3))
                        .lineStyle(StrokeStyle(lineWidth: 1, dash: [5, 5]))
                }
                
                if let max = normalRange.max {
                    RuleMark(y: .value("Max", max))
                        .foregroundStyle(.gray.opacity(0.3))
                        .lineStyle(StrokeStyle(lineWidth: 1, dash: [5, 5]))
                }
            }
        }
    }
}

struct ChartSection: View {
    let records: [HealthRecord]
    let type: HealthRecord.RecordType
    let healthStore: HealthStore
    
    var body: some View {
        VStack(alignment: .leading) {
            Text("\(type.displayName)趋势")
                .font(.headline)
            
            Chart(records) { record in
                LineMark(
                    x: .value("Date", record.date),
                    y: .value("Value", record.value)
                )
                .foregroundStyle(.blue)
                
                PointMark(
                    x: .value("Date", record.date),
                    y: .value("Value", record.value)
                )
                .foregroundStyle(.blue)
                
                if let min = type.normalRange.min {
                    RuleMark(y: .value("Min", min))
                        .foregroundStyle(.gray.opacity(0.3))
                        .lineStyle(StrokeStyle(lineWidth: 1, dash: [5, 5]))
                }
                
                if let max = type.normalRange.max {
                    RuleMark(y: .value("Max", max))
                        .foregroundStyle(.gray.opacity(0.3))
                        .lineStyle(StrokeStyle(lineWidth: 1, dash: [5, 5]))
                }
            }
        }
    }
}
