import SwiftUI

public struct NoteSummaryCard: View {
    public var dailyNote: DailyNote
    
    public init(dailyNote: DailyNote) {
        self.dailyNote = dailyNote
    }
    
    public var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(dailyNote.date, style: .date)
                .font(.headline)
            Text(dailyNote.content)
                .lineLimit(3)
                .font(.body)
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(10)
        .shadow(radius: 2)
    }
}
