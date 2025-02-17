import SwiftUI

struct AllNotesView: View {
    @EnvironmentObject var healthStore: HealthStore
    @Environment(\.colorScheme) var colorScheme
    @State private var noteToEdit: DailyNote? = nil
    
    var body: some View {
        List {
            ForEach(healthStore.dailyNotes.sorted(by: { $0.date > $1.date }), id: \.id) { note in
                NavigationLink(destination: NoteDetailView(note: note).environmentObject(healthStore)) {
                    NoteSummaryCard(note: note)
                }
                .listRowInsets(EdgeInsets())
                .listRowSeparator(.hidden)
                .padding(.vertical, 4)
            }
        }
        .listStyle(.plain)
        .background(Theme.gradientBackground(for: colorScheme))
        .navigationTitle("所有笔记")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
        }
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(action: {
                    noteToEdit = DailyNote(content: "", tags: [])
                }) {
                    Image(systemName: "plus")
                }
            }
        }
        .sheet(item: $noteToEdit) { note in
            AddNoteView(noteToEdit: note)
                .environmentObject(healthStore)
        }
        .onDisappear {
            // Reload data when view disappears to ensure list is updated
            healthStore.loadData()
        }
        .onChange(of: noteToEdit) { oldValue, newValue in
            if oldValue != nil && newValue == nil {
                // Note sheet was dismissed, reload data
                healthStore.loadData()
            }
        }
    }
}
