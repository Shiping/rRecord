import SwiftUI

import SwiftUI

struct AddNoteView: View {
    @ObservedObject var healthStore: HealthStore
    @Environment(\.colorScheme) var colorScheme
    @Environment(\.dismiss) private var dismiss
    var noteToEdit: DailyNote?
    
    @State private var noteContent: String = ""
    @State private var selectedTags: Set<String> = []
    @State private var newTag: String = ""
    @State private var selectedDate = Date()
    @State private var textEditorHeight: CGFloat = 100 // 默认高度
    @State private var isDragging = false
    
    private let commonTags = ["运动", "饮食", "睡眠", "心情", "灵感", "工作"]
    
    init(healthStore: HealthStore, noteToEdit: DailyNote? = nil) {
        self.healthStore = healthStore
        self.noteToEdit = noteToEdit
        
        if let note = noteToEdit {
            _noteContent = State(initialValue: note.content)
            _selectedTags = State(initialValue: Set(note.tags))
            _selectedDate = State(initialValue: note.date)
        }
    }
    
    private var dateRange: ClosedRange<Date> {
        let calendar = Calendar.current
        let start = calendar.date(byAdding: .year, value: -1, to: Date())!
        let end = Date()
        return start...end
    }
    
    var body: some View {
        NavigationView {
            List {
                Section {
                    DatePicker(
                        "选择日期时间",
                        selection: $selectedDate,
                        in: dateRange,
                        displayedComponents: [.date, .hourAndMinute]
                    )
                } header: {
                    Text("记录时间")
                }
                
                Section {
                    VStack(spacing: 0) {
                        TextEditor(text: $noteContent)
                            .frame(height: textEditorHeight)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Color(.systemBackground))
                            .animation(.easeInOut, value: textEditorHeight)
                        
                        Rectangle()
                            .fill(Color(.systemGray4))
                            .frame(height: 30)
                            .overlay(
                                Image(systemName: "line.horizontal.3")
                                    .foregroundColor(.white)
                                    .font(.system(size: 20, weight: .bold))
                            )
                            .onTapGesture {}
                            .gesture(
                                DragGesture()
                                    .onChanged { value in
                                        isDragging = true
                                        let newHeight = textEditorHeight + value.translation.height
                                        textEditorHeight = max(100, newHeight)
                                    }
                                    .onEnded { _ in
                                        isDragging = false
                                        DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                                            if !isDragging {
                                                withAnimation {
                                                    textEditorHeight = 100
                                                }
                                            }
                                        }
                                    }
                            )
                    }
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(Color(.systemGray4), lineWidth: 1)
                    )
                    .listRowInsets(EdgeInsets())
                    .padding(.horizontal)
                } header: {
                    Text("记录你的想法")
                }
                
                Section(header: Text("添加标签")) {
                    // Common tags
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack {
                            ForEach(commonTags, id: \.self) { tag in
                                TagButton(
                                    tag: tag,
                                    isSelected: selectedTags.contains(tag),
                                    action: {
                                        toggleTag(tag)
                                    }
                                )
                            }
                        }
                        .padding(.vertical, 5)
                    }
                    
                    // Custom tag input
                    HStack {
                        TextField("添加自定义标签", text: $newTag)
                        
                        if !newTag.isEmpty {
                            Button(action: addCustomTag) {
                                Image(systemName: "plus.circle.fill")
                                    .foregroundColor(Theme.color(.accent, scheme: colorScheme))
                            }
                        }
                    }
                }
                
                // Selected tags
                if !selectedTags.isEmpty {
                    Section(header: Text("已选标签")) {
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack {
                                ForEach(Array(selectedTags), id: \.self) { tag in
                                    TagButton(
                                        tag: tag,
                                        isSelected: true,
                                        action: {
                                            toggleTag(tag)
                                        }
                                    )
                                }
                            }
                            .padding(.vertical, 5)
                        }
                    }
                }
            }
            .navigationTitle("添加笔记")
            .navigationBarItems(
                leading: Button("取消") {
                    dismiss()
                },
                trailing: Button("保存") {
                    saveNote()
                }
                .disabled(noteContent.isEmpty)
            )
        }
    }
    
    private func toggleTag(_ tag: String) {
        if selectedTags.contains(tag) {
            selectedTags.remove(tag)
        } else {
            selectedTags.insert(tag)
        }
    }
    
    private func addCustomTag() {
                    let tag = newTag.trimmingCharacters(in: .whitespaces)
        if !tag.isEmpty && !selectedTags.contains(tag) {
            selectedTags.insert(tag)
            newTag = ""
        }
    }
    
    private func saveNote() {
        let note = DailyNote(
            id: noteToEdit?.id ?? UUID(),
            date: selectedDate,
            content: noteContent,
            tags: Array(selectedTags)
        )
        
        if noteToEdit != nil {
            healthStore.updateDailyNote(note)
        } else {
            healthStore.addDailyNote(note)
        }
        dismiss()
    }
}

struct TagButton: View {
    @Environment(\.colorScheme) var colorScheme
    let tag: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(tag)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(isSelected ? Theme.color(.accent, scheme: colorScheme) : Theme.color(.cardBackground, scheme: colorScheme))
                .foregroundColor(isSelected ? .white : Theme.color(.text, scheme: colorScheme))
                .cornerRadius(15)
        }
    }
}

#Preview {
    AddNoteView(healthStore: HealthStore())
}
