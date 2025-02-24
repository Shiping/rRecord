import SwiftUI

public struct AddNoteView: View {
    @Binding public var isPresented: Bool
    @State private var noteContent: String = ""
    @State private var selectedDate: Date = Date()
    
    public init(isPresented: Binding<Bool>) {
        self._isPresented = isPresented
    }
    
    public var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Note Details")) {
                    DatePicker("Date", selection: $selectedDate, displayedComponents: .date)
                    TextEditor(text: $noteContent)
                        .frame(height: 200)
                }
            }
            .navigationTitle("Add Note")
            .navigationBarItems(
                leading: Button("Cancel") {
                    isPresented = false
                },
                trailing: Button("Save") {
                    // Add save logic here
                    isPresented = false
                }
            )
        }
    }
}
