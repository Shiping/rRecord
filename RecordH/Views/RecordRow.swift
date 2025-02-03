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
            
            HStack(alignment: .firstTextBaseline) {
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
