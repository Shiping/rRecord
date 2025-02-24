import SwiftUI

public struct AllNotesView: View {
    @State private var notes: [DailyNote] = []
    @State private var showingAddNote = false
    
    public var body: some View {
        NavigationView {
            List {
                ForEach(notes) { note in
                    NavigationLink(destination: NoteDetailView()) {
                        NoteSummaryCard(dailyNote: note)
                    }
                }
            }
            .navigationTitle("All Notes")
            .navigationBarItems(trailing:
                Button(action: {
                    showingAddNote = true
                }) {
                    Image(systemName: "plus")
                }
            )
            .sheet(isPresented: $showingAddNote) {
                AddNoteView(isPresented: $showingAddNote)
            }
        }
    }
}
