import SwiftUI

struct RecentNotesSection: View {
    @ObservedObject var healthStore: HealthStore
    @Binding var showingAddNote: Bool
    @Binding var noteToEdit: DailyNote?
    @Environment(\.colorScheme) var colorScheme
    
    @State private var showingHistoryView = false
    
    var body: some View {
        VStack(spacing: 16) {
            // Title and add button
            HStack {
                Button(action: { showingHistoryView = true }) {
                    HStack {
                        Text("今日记录")
                            .font(.headline)
                            .foregroundColor(Theme.color(.text, scheme: colorScheme))
                        Image(systemName: "chevron.right")
                            .font(.system(size: 14))
                            .foregroundColor(Theme.color(.secondaryText, scheme: colorScheme))
                    }
                }
                
                Spacer()
                
                Button(action: {
                    noteToEdit = nil
                    showingAddNote = true
                }) {
                    Image(systemName: "plus.circle.fill")
                        .foregroundColor(Theme.color(.accent, scheme: colorScheme))
                }
            }
            .padding(.horizontal, 16)
            
            let recentNotes = healthStore.dailyNotes.sorted(by: { $0.date > $1.date }).prefix(3)
            
            if !recentNotes.isEmpty {
                VStack(spacing: 12) {
                    ForEach(Array(recentNotes), id: \.id) { note in
                        NoteSummaryCard(note: note)
                            .onTapGesture {
                                noteToEdit = note
                                showingAddNote = true
                            }
                    }
                }
            } else {
                Text("点击 + 添加记录")
                    .foregroundColor(.secondary)
                    .padding(.vertical, 8)
            }
        }
        .sheet(isPresented: $showingHistoryView) {
            NavigationView {
                List(healthStore.dailyNotes.sorted(by: { $0.date > $1.date }), id: \.id) { note in
                    NoteSummaryCard(note: note)
                        .onTapGesture {
                            noteToEdit = note
                            showingAddNote = true
                            showingHistoryView = false
                        }
                        .listRowInsets(EdgeInsets())
                        .listRowSeparator(.hidden)
                        .padding(.vertical, 4)
                }
                .listStyle(.plain)
                .navigationTitle("历史记录")
                .navigationBarTitleDisplayMode(.inline)
            }
        }
    }
}

// MARK: - NoteSummaryCard
private struct NoteSummaryCard: View {
    let note: DailyNote
    @Environment(\.colorScheme) var colorScheme
    @State private var isHovered = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                ZStack {
                    Circle()
                        .fill(Theme.color(.accent, scheme: colorScheme).opacity(0.1))
                        .frame(width: 40, height: 40)
                    
                    Circle()
                        .stroke(Theme.color(.accent, scheme: colorScheme).opacity(0.2), lineWidth: 1.5)
                        .frame(width: 40, height: 40)
                        .scaleEffect(isHovered ? 1.2 : 1.0)
                        .opacity(isHovered ? 0 : 1)
                        .animation(.easeInOut(duration: 1).repeatForever(autoreverses: false), value: isHovered)
                    
                    Image(systemName: "note.text")
                        .font(.system(size: 20))
                        .foregroundColor(Theme.color(.accent, scheme: colorScheme))
                }
                .onAppear { isHovered = true }
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(note.date.formatted(.dateTime.month().day()))
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(Theme.color(.text, scheme: colorScheme))
                    
                    Text(note.date.formatted(.dateTime.hour().minute()))
                        .font(.caption)
                        .foregroundColor(Theme.color(.secondaryText, scheme: colorScheme))
                }
                
                Spacer()
            }
            
            Text(note.content)
                .lineLimit(3)
                .foregroundColor(Theme.color(.text, scheme: colorScheme))
            
            if !note.tags.isEmpty {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(note.tags, id: \.self) { tag in
                            HStack(spacing: 4) {
                                Image(systemName: "tag.fill")
                                    .font(.system(size: 10))
                                Text(tag)
                                    .fontWeight(.medium)
                            }
                            .font(.caption)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 5)
                            .background(
                                Capsule()
                                    .fill(Theme.color(.accent, scheme: colorScheme).opacity(0.15))
                            )
                            .foregroundColor(Theme.color(.accent, scheme: colorScheme))
                        }
                    }
                    .padding(.horizontal, 4)
                }
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity)
        .background(Theme.cardGradient(for: colorScheme))
        .clipShape(RoundedRectangle(cornerRadius: 20))
    }
}
