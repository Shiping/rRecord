import SwiftUI

struct NoteDetailView: View {
    @EnvironmentObject var healthStore: HealthStore
    @Environment(\.colorScheme) var colorScheme
    @Environment(\.presentationMode) var presentationMode

    let note: DailyNote
    @State private var editedContent: String
    @State private var isEditing = false

    init(note: DailyNote) {
        self.note = note
        _editedContent = State(initialValue: note.content)
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(note.date.formatted(.dateTime.month().day().weekday()))
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(Theme.color(.text, scheme: colorScheme))
                        Text(note.date.formatted(.dateTime.hour().minute()))
                            .font(.subheadline)
                            .foregroundColor(Theme.color(.secondaryText, scheme: colorScheme))
                    }
                    Spacer()

                    if isEditing {
                        Button(action: {
                            var updatedNote = note
                            updatedNote.content = editedContent
                            do {
                                try healthStore.updateDailyNote(updatedNote)
                                isEditing = false
                            } catch {
                                print("Failed to update note: \(error)")
                            }
                        }) {
                            Text("完成")
                        }
                        .foregroundColor(Theme.color(.accent, scheme: colorScheme))
                    } else {
                        Button(action: {
                            isEditing = true
                        }) {
                            Text("编辑")
                        }
                        .foregroundColor(Theme.color(.accent, scheme: colorScheme))
                    }
                }

                if isEditing {
                    TextEditor(text: $editedContent)
                        .frame(minHeight: 100)
                        .padding()
                        .background(Theme.cardGradient(for: colorScheme))
                        .cornerRadius(10)
                } else {
                    Text(editedContent)
                        .padding()
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(Theme.cardGradient(for: colorScheme))
                        .cornerRadius(10)
                }

                if !note.tags.isEmpty {
                    VStack(alignment: .leading) {
                        Text("标签")
                            .font(.headline)
                            .foregroundColor(Theme.color(.secondaryText, scheme: colorScheme))

                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 8) {
                                ForEach(note.tags, id: \.self) { tag in
                                    Text(tag)
                                        .font(.caption)
                                        .padding(.horizontal, 10)
                                        .padding(.vertical, 5)
                                        .background(Capsule().fill(Theme.color(.accent, scheme: colorScheme).opacity(0.2)))
                                        .foregroundColor(Theme.color(.accent, scheme: colorScheme))
                                }
                            }
                        }
                    }
                    .padding(.horizontal)
                }
            }
            .padding()
        }
        .background(Theme.gradientBackground(for: colorScheme))
        .navigationBarTitleDisplayMode(.inline)
    }
}
