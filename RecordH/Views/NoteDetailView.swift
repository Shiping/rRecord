import SwiftUI

struct NoteDetailView: View {
    @ObservedObject var healthStore: HealthStore
    @Environment(\.colorScheme) var colorScheme
    let note: DailyNote
    @State private var isEditing = false
    @State private var editedContent: String
    @State private var editedTags: [String]
    
    init(healthStore: HealthStore, note: DailyNote) {
        self.healthStore = healthStore
        self.note = note
        _editedContent = State(initialValue: note.content)
        _editedTags = State(initialValue: note.tags)
    }
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                // Content
                if isEditing {
                    TextEditor(text: $editedContent)
                        .font(.body)
                        .foregroundColor(Theme.color(.text, scheme: colorScheme))
                        .frame(minHeight: 100)
                        .padding(.vertical)
                } else {
                    Text(note.content)
                        .font(.body)
                        .foregroundColor(Theme.color(.text, scheme: colorScheme))
                        .padding(.vertical)
                }
                
                // Date
                HStack {
                    Image(systemName: "calendar")
                        .foregroundColor(Theme.color(.secondaryText, scheme: colorScheme))
                    Text(note.date.formatted(.dateTime.year().month().day().hour().minute()))
                        .font(.subheadline)
                        .foregroundColor(Theme.color(.secondaryText, scheme: colorScheme))
                }
                
                // Tags
                Text("标签")
                    .font(.headline)
                    .foregroundColor(Theme.color(.text, scheme: colorScheme))
                    .padding(.top)
                
                if isEditing {
                    TextField("添加标签，用逗号分隔", text: Binding(
                        get: { editedTags.joined(separator: ", ") },
                        set: { newValue in
                            editedTags = newValue.components(separatedBy: ",").map { $0.trimmingCharacters(in: .whitespaces) }.filter { !$0.isEmpty }
                        }
                    ))
                    .textFieldStyle(.roundedBorder)
                    .foregroundColor(Theme.color(.text, scheme: colorScheme))
                } else if !note.tags.isEmpty {
                    FlowLayout(spacing: 8) {
                        ForEach(note.tags, id: \.self) { tag in
                            Text(tag)
                                .font(.subheadline)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 6)
                                .background(Theme.color(.accent, scheme: colorScheme).opacity(0.2))
                                .foregroundColor(Theme.color(.text, scheme: colorScheme))
                                .cornerRadius(8)
                        }
                    }
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding()
        }
        .background(Theme.color(.background, scheme: colorScheme))
        .navigationTitle("笔记详情")
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(action: {
                    if isEditing {
                        // Save changes
                        let updatedNote = DailyNote(
                            id: note.id,
                            date: note.date,
                            content: editedContent,
                            tags: editedTags
                        )
                        healthStore.updateDailyNote(updatedNote)
                    }
                    isEditing.toggle()
                }) {
                    Text(isEditing ? "完成" : "编辑")
                        .foregroundColor(Theme.color(.accent, scheme: colorScheme))
                }
            }
        }
    }
}

struct FlowLayout: Layout {
    var spacing: CGFloat
    
    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let rows = computeRows(proposal: proposal, subviews: subviews)
        
        var height: CGFloat = 0
        for row in rows {
            height += row.maxY
            if row !== rows.last {
                height += spacing
            }
        }
        
        return CGSize(width: proposal.width ?? 0, height: height)
    }
    
    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let rows = computeRows(proposal: proposal, subviews: subviews)
        
        var y = bounds.minY
        for row in rows {
            var x = bounds.minX
            
            for item in row.items {
                let size = item.subview.sizeThatFits(proposal)
                item.subview.place(at: CGPoint(x: x, y: y), proposal: proposal)
                x += size.width + spacing
            }
            
            y += row.maxY
            if row !== rows.last {
                y += spacing
            }
        }
    }
    
    private func computeRows(proposal: ProposedViewSize, subviews: Subviews) -> [Row] {
        var rows: [Row] = []
        var currentRow = Row()
        var x: CGFloat = 0
        let maxWidth = proposal.width ?? 0
        
        for subview in subviews {
            let size = subview.sizeThatFits(proposal)
            
            if x + size.width > maxWidth && !currentRow.items.isEmpty {
                rows.append(currentRow)
                currentRow = Row()
                x = 0
            }
            
            currentRow.items.append(RowItem(subview: subview, size: size))
            x += size.width + spacing
        }
        
        if !currentRow.items.isEmpty {
            rows.append(currentRow)
        }
        
        return rows
    }
    
    private class Row {
        var items: [RowItem] = []
        
        var maxY: CGFloat {
            items.map(\.size.height).max() ?? 0
        }
        
        init(items: [RowItem] = []) {
            self.items = items
        }
    }
    
    private class RowItem {
        let subview: LayoutSubview
        let size: CGSize
        
        init(subview: LayoutSubview, size: CGSize) {
            self.subview = subview
            self.size = size
        }
    }
}

#Preview {
    NavigationView {
        NoteDetailView(
            healthStore: HealthStore(),
            note: DailyNote(
                id: UUID(),
                date: Date(),
                content: "Test note",
                tags: ["测试", "标签"]
            )
        )
    }
}
