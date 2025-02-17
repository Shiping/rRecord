import SwiftUI

struct RecentNotesSection: View {
    @EnvironmentObject var healthStore: HealthStore
    @Binding var noteToEdit: DailyNote?
    @Environment(\.colorScheme) var colorScheme
    @State private var forceRefresh = false
    
    var body: some View {
        VStack(spacing: 12) {
            if healthStore.dailyNotes.isEmpty {
                Text("点击 + 添加笔记")
                    .foregroundColor(.secondary)
                    .padding(.vertical, 8)
            }
            ForEach(Array(healthStore.dailyNotes.prefix(3)), id: \.id) { note in
                NavigationLink(destination: NoteDetailView(note: note).environmentObject(healthStore)) {
                    NoteSummaryCard(note: note)
                }
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: .init("NotesDidUpdate"))) { _ in
            // Force view to refresh by toggling state
            forceRefresh.toggle()
        }
    }
}

// MARK: - NoteRow
private struct NoteRow: View {
    let note: DailyNote
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        HStack(alignment: .top) {
            Image(systemName: "note.text")
                .foregroundColor(Theme.color(.accent, scheme: colorScheme))
                .font(.title2)
            
            VStack(alignment: .leading) {
                Text(note.date.formatted(.dateTime.month().day().hour().minute()))
                    .font(.caption)
                    .foregroundColor(.secondary)
                Text(note.content)
                    .lineLimit(2)
                    .foregroundColor(Theme.color(.text, scheme: colorScheme))
            }
        }
    }
}
