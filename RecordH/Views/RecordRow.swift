import SwiftUI

struct RecordRow: View {
    let record: HealthRecord
    let type: HealthRecord.RecordType
    @ObservedObject var healthStore: HealthStore
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(record.date.formatted(date: .abbreviated, time: .shortened))
                    .foregroundColor(Theme.color(.secondaryText, scheme: colorScheme))
                Spacer()
                if let note = record.note, !note.isEmpty {
                    Image(systemName: "note.text")
                        .foregroundColor(Theme.color(.secondaryText, scheme: colorScheme))
                }
            }
            
            HStack(alignment: .firstTextBaseline, spacing: 4) {
                if type == .sleep {
                    Text(formatElapsedTime(record.value, secondaryValue: record.secondaryValue))
                        .font(.title2)
                        .foregroundColor(Theme.color(.text, scheme: colorScheme))
                } else {
                    Text("\(String(format: "%.1f", record.value))")
                        .font(.title2)
                        .foregroundColor(Theme.color(.text, scheme: colorScheme))
                    Text(record.unit)
                        .foregroundColor(Theme.color(.secondaryText, scheme: colorScheme))
                    
                    if type == .weight, let bmi = record.secondaryValue {
                        Text("•")
                            .foregroundColor(Theme.color(.secondaryText, scheme: colorScheme))
                        Text("BMI \(String(format: "%.1f", bmi))")
                            .foregroundColor(Theme.color(.text, scheme: colorScheme))
                        Text(getBMIStatus(bmi))
                            .foregroundColor(getBMIColor(bmi))
                    }
                }
                
                if type.needsSecondaryValue, let secondaryValue = record.secondaryValue {
                    Text("/")
                        .foregroundColor(Theme.color(.secondaryText, scheme: colorScheme))
                    Text("\(String(format: "%.1f", secondaryValue))")
                        .font(.title2)
                        .foregroundColor(Theme.color(.text, scheme: colorScheme))
                    Text(record.unit)
                        .foregroundColor(Theme.color(.secondaryText, scheme: colorScheme))
                }
            }
            
            if let note = record.note, !note.isEmpty {
                Text(note)
                    .foregroundColor(Theme.color(.secondaryText, scheme: colorScheme))
                    .font(.subheadline)
            }
        }
        .padding(.vertical, 8)
    }
    
    private func formatElapsedTime(_ value: Double, secondaryValue: Double?) -> String {
        let hours = Int(value)
        let minutes = Int(secondaryValue ?? 0)
        return "\(hours)小时 \(minutes)分钟"
    }
    
    private func getBMIStatus(_ bmi: Double) -> String {
        switch bmi {
        case ..<18.5:
            return "偏瘦"
        case 18.5..<23.9:
            return "正常"
        case 23.9..<27.9:
            return "偏胖"
        default:
            return "肥胖"
        }
    }
    
    private func getBMIColor(_ bmi: Double) -> Color {
        switch bmi {
        case 18.5..<23.9:
            return .green
        case 23.9..<27.9:
            return .orange
        default:
            return .red
        }
    }
}

#Preview {
    RecordRow(
        record: HealthRecord(
            id: UUID(),
            date: Date(),
            type: .bloodPressure,
            value: 120,
            secondaryValue: 80,
            unit: "mmHg"
        ),
        type: .bloodPressure,
        healthStore: HealthStore()
    )
    .background(Color.white)
    .padding()
}
