import SwiftUI

struct RecordRow: View {
    let record: HealthRecord
    @Environment(\.theme) var theme
    
    private let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter
    }()
    
    var body: some View {
        HStack {
            VStack(alignment: .leading) {
                Text(record.metric.name)
                    .font(.headline)
                    .foregroundColor(theme.textColor)
                Text(dateFormatter.string(from: record.date))
                    .font(.subheadline)
                    .foregroundColor(theme.secondaryTextColor)
            }
            
            Spacer()
            
            HStack(alignment: .firstTextBaseline, spacing: 2) {
                Text(String(format: "%.1f", record.value))
                    .font(.title2)
                    .foregroundColor(theme.accentColor)
                Text(record.metric.unitString)
                    .font(.caption)
                    .foregroundColor(theme.secondaryTextColor)
            }
        }
        .padding(.vertical, 8)
    }
}

#Preview {
    RecordRow(
        record: HealthRecord(
            metric: .bodyMass,
            value: 70.5,
            date: Date()
        )
    )
    .padding()
}
