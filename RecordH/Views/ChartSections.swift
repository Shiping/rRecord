import SwiftUI
import Charts

import SwiftUI
import Charts

struct WeightChartSection: View {
    let records: [HealthRecord]
    @EnvironmentObject var healthStore: HealthStore
    
    var body: some View {
        VStack(alignment: .leading) {
            Text("体重趋势")
                .font(.headline)
            
            Chart {
                // Layer 1: Background ranges
                ForEach(records) { _ in
                    if let min = HealthRecord.RecordType.weight.normalRange.min,
                       let max = HealthRecord.RecordType.weight.normalRange.max {
                        RectangleMark(
                            xStart: .value("Start", records.first?.date ?? Date()),
                            xEnd: .value("End", records.last?.date ?? Date()),
                            yStart: .value("Normal Min", min),
                            yEnd: .value("Normal Max", max)
                        )
                        .foregroundStyle(Color.green.opacity(0.1))
                    }
                    
                    if let min = HealthRecord.RecordType.weight.normalRange.min {
                        RectangleMark(
                            xStart: .value("Start", records.first?.date ?? Date()),
                            xEnd: .value("End", records.last?.date ?? Date()),
                            yStart: .value("Min", 0),
                            yEnd: .value("Normal Min", min)
                        )
                        .foregroundStyle(Color.red.opacity(0.05))
                    }
                    
                    if let max = HealthRecord.RecordType.weight.normalRange.max {
                        RectangleMark(
                            xStart: .value("Start", records.first?.date ?? Date()),
                            xEnd: .value("End", records.last?.date ?? Date()),
                            yStart: .value("Normal Max", max),
                            yEnd: .value("Max", records.map { $0.value }.max() ?? max * 1.5)
                        )
                        .foregroundStyle(Color.red.opacity(0.05))
                    }
                }
                .foregroundStyle(.clear)
                
                // Layer 2: Guide lines
                if let min = HealthRecord.RecordType.weight.normalRange.min {
                    RuleMark(y: .value("Min", min))
                        .foregroundStyle(.gray.opacity(0.3))
                        .lineStyle(StrokeStyle(lineWidth: 1, dash: [5, 5]))
                }
                
                if let max = HealthRecord.RecordType.weight.normalRange.max {
                    RuleMark(y: .value("Max", max))
                        .foregroundStyle(.gray.opacity(0.3))
                        .lineStyle(StrokeStyle(lineWidth: 1, dash: [5, 5]))
                }

                // Layer 3: Data lines and points
                ForEach(records) { record in
                    LineMark(
                        x: .value("Date", record.date),
                        y: .value("Weight", record.value)
                    )
                    .foregroundStyle(.blue)
                    .zIndex(1)
                    
                    PointMark(
                        x: .value("Date", record.date),
                        y: .value("Weight", record.value)
                    )
                    .foregroundStyle(.blue)
                    .zIndex(2)
                }
            }
        }
    }
}

struct BMIChartSection: View {
    let records: [HealthRecord]
    @EnvironmentObject var healthStore: HealthStore
    
    var bmiRecords: [(date: Date, bmi: Double)] {
        records.compactMap { record in
            guard let userProfile = healthStore.userProfile else { return nil }
            // Height is in cm, weight in kg
            let heightInMeters = userProfile.height / 100 // Convert height from cm to m
            let bmi = record.value / (heightInMeters * heightInMeters) // weight(kg) / height(m)²
            
            // Debug print for BMI calculation
            print("BMI Calculation:")
            print("Height (cm): \(userProfile.height)")
            print("Height (m): \(heightInMeters)")
            print("Weight (kg): \(record.value)")
            print("BMI: \(bmi)")
            
            return (record.date, bmi)
        }
    }
    
    var body: some View {
        VStack(alignment: .leading) {
            Text("BMI趋势")
                .font(.headline)
            
            if !bmiRecords.isEmpty {
                Chart {
                    // Layer 1: Background ranges
                    ForEach(bmiRecords, id: \.date) { _ in 
                        let normalBMIMin = 18.5
                        let normalBMIMax = 24.9
                        
                        // Normal range background
                        RectangleMark(
                            xStart: .value("Start", bmiRecords.first?.date ?? Date()),
                            xEnd: .value("End", bmiRecords.last?.date ?? Date()),
                            yStart: .value("Normal Min", normalBMIMin),
                            yEnd: .value("Normal Max", normalBMIMax)
                        )
                        .foregroundStyle(Color.green.opacity(0.1))
                        
                        // Underweight range background
                        RectangleMark(
                            xStart: .value("Start", bmiRecords.first?.date ?? Date()),
                            xEnd: .value("End", bmiRecords.last?.date ?? Date()),
                            yStart: .value("Min", 10), // Show some context below
                            yEnd: .value("Normal Min", normalBMIMin)
                        )
                        .foregroundStyle(Color.red.opacity(0.05))
                        
                        // Overweight range background
                        RectangleMark(
                            xStart: .value("Start", bmiRecords.first?.date ?? Date()),
                            xEnd: .value("End", bmiRecords.last?.date ?? Date()),
                            yStart: .value("Normal Max", normalBMIMax),
                            yEnd: .value("Max", 40) // Show some context above
                        )
                        .foregroundStyle(Color.red.opacity(0.05))
                    }
                    .foregroundStyle(.clear)
                    
                    // Layer 2: Guide lines
                    RuleMark(y: .value("Normal Min", 18.5))
                        .foregroundStyle(.gray.opacity(0.3))
                        .lineStyle(StrokeStyle(lineWidth: 1, dash: [5, 5]))
                    
                    RuleMark(y: .value("Normal Max", 24.9))
                        .foregroundStyle(.gray.opacity(0.3))
                        .lineStyle(StrokeStyle(lineWidth: 1, dash: [5, 5]))
                    
                    // Layer 3: Data lines and points
                    ForEach(bmiRecords, id: \.date) { record in
                        LineMark(
                            x: .value("Date", record.date),
                            y: .value("BMI", record.bmi)
                        )
                        .foregroundStyle(.green)
                        .zIndex(1)
                        
                        PointMark(
                            x: .value("Date", record.date),
                            y: .value("BMI", record.bmi)
                        )
                        .foregroundStyle(.green)
                        .zIndex(2)
                    }
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
            
            Chart {
                // Layer 1: Background ranges
                ForEach(records) { _ in
                    if let min = normalRange.min, let max = normalRange.max {
                        RectangleMark(
                            xStart: .value("Start", records.first?.date ?? Date()),
                            xEnd: .value("End", records.last?.date ?? Date()),
                            yStart: .value("Normal Min", min),
                            yEnd: .value("Normal Max", max)
                        )
                        .foregroundStyle(Color.green.opacity(0.1))
                        
                        // Add background for abnormal ranges
                        RectangleMark(
                            xStart: .value("Start", records.first?.date ?? Date()),
                            xEnd: .value("End", records.last?.date ?? Date()),
                            yStart: .value("Min", 0),
                            yEnd: .value("Normal Min", min)
                        )
                        .foregroundStyle(Color.red.opacity(0.05))
                        
                        RectangleMark(
                            xStart: .value("Start", records.first?.date ?? Date()),
                            xEnd: .value("End", records.last?.date ?? Date()),
                            yStart: .value("Normal Max", max),
                            yEnd: .value("Max", max * 1.5)
                        )
                        .foregroundStyle(Color.red.opacity(0.05))
                    }
                }
                .foregroundStyle(.clear)

                // Layer 2: Guide lines
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

                // Layer 3: Data lines and points
                ForEach(records) { record in
                    LineMark(
                        x: .value("Date", record.date),
                        y: .value("Value", valueSelector(record))
                    )
                    .foregroundStyle(color)
                    .zIndex(1)
                    
                    PointMark(
                        x: .value("Date", record.date),
                        y: .value("Value", valueSelector(record))
                    )
                    .foregroundStyle(color)
                    .zIndex(2)
                }
            }
        }
    }
}

struct ChartSection: View {
    let records: [HealthRecord]
    let type: HealthRecord.RecordType
    @EnvironmentObject var healthStore: HealthStore
    
    var body: some View {
        VStack(alignment: .leading) {
            Text("\(type.displayName)趋势")
                .font(.headline)
            
            Chart {
                // Layer 1: Background ranges
                ForEach(records) { _ in
                    if let min = type.normalRange.min, let max = type.normalRange.max {
                        RectangleMark(
                            xStart: .value("Start", records.first?.date ?? Date()),
                            xEnd: .value("End", records.last?.date ?? Date()),
                            yStart: .value("Normal Min", min),
                            yEnd: .value("Normal Max", max)
                        )
                        .foregroundStyle(Color.green.opacity(0.1))
                    }
                    
                    if let min = type.normalRange.min {
                        RectangleMark(
                            xStart: .value("Start", records.first?.date ?? Date()),
                            xEnd: .value("End", records.last?.date ?? Date()),
                            yStart: .value("Min", 0),
                            yEnd: .value("Normal Min", min)
                        )
                        .foregroundStyle(Color.red.opacity(0.05))
                    }
                    
                    if let max = type.normalRange.max {
                        RectangleMark(
                            xStart: .value("Start", records.first?.date ?? Date()),
                            xEnd: .value("End", records.last?.date ?? Date()),
                            yStart: .value("Normal Max", max),
                            yEnd: .value("Max", records.map { $0.value }.max() ?? max * 1.5)
                        )
                        .foregroundStyle(Color.red.opacity(0.05))
                    }
                }
                .foregroundStyle(.clear)

                // Layer 2: Guide lines
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

                // Layer 3: Data lines and points
                ForEach(records) { record in
                    LineMark(
                        x: .value("Date", record.date),
                        y: .value("Value", record.value)
                    )
                    .foregroundStyle(.blue)
                    .zIndex(1)
                    
                    PointMark(
                        x: .value("Date", record.date),
                        y: .value("Value", record.value)
                    )
                    .foregroundStyle(.blue)
                    .zIndex(2)
                }
            }
        }
    }
}
