import SwiftUI
import Foundation
struct AIPromptTemplates: View {
    @EnvironmentObject private var aiManager: AIManager
    @State private var showingAddTemplate = false
    @State private var showingEditTemplate: PromptTemplate?
    @Environment(\.theme) var theme
    
    var body: some View {
        List {
            ForEach(aiManager.templates) { template in
                Button(action: {
                    showingEditTemplate = template
                }) {
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text(template.name)
                                .font(.headline)
                            if template.isDefault {
                                Text("默认")
                                    .font(.caption)
                                    .padding(.horizontal, 6)
                                    .padding(.vertical, 2)
                                    .background(theme.accentColor.opacity(0.2))
                                    .cornerRadius(4)
                            }
                            Spacer()
                            Image(systemName: "chevron.right")
                                .foregroundColor(theme.secondaryTextColor)
                        }
                        
                        Text(template.description)
                            .font(.subheadline)
                            .foregroundColor(theme.secondaryTextColor)
                        
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack {
                                ForEach(template.applicableMetrics, id: \.self) { metric in
                                    Text(metric.name)
                                        .font(.caption)
                                        .padding(.horizontal, 8)
                                        .padding(.vertical, 4)
                                        .background(theme.cardBackground)
                                        .cornerRadius(8)
                                }
                            }
                        }
                    }
                }
            }
            .onDelete(perform: deleteTemplates)
        }
        .navigationTitle("分析模板")
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(action: { showingAddTemplate = true }) {
                    Image(systemName: "plus")
                }
            }
        }
        .sheet(isPresented: $showingAddTemplate) {
            NavigationView {
                PromptTemplateEditor(template: PromptTemplate(
                    name: "",
                    description: "",
                    template: "",
                    applicableMetrics: [],
                    isDefault: false
                ), onSave: { template in
                    aiManager.addTemplate(template)
                    showingAddTemplate = false
                })
            }
        }
        .sheet(item: $showingEditTemplate) { template in
            NavigationView {
                PromptTemplateEditor(template: template, onSave: { updatedTemplate in
                    aiManager.updateTemplate(updatedTemplate)
                    showingEditTemplate = nil
                })
            }
        }
    }
    
    private func deleteTemplates(at offsets: IndexSet) {
        for index in offsets {
            let template = aiManager.templates[index]
            aiManager.deleteTemplate(template)
        }
    }
}

struct PromptTemplateEditor: View {
    @Environment(\.dismiss) private var dismiss
    @State private var template: PromptTemplate
    @State private var selectedMetrics = Set<HealthMetric>()
    let onSave: (PromptTemplate) -> Void
    
    init(template: PromptTemplate, onSave: @escaping (PromptTemplate) -> Void) {
        _template = State(initialValue: template)
        self.onSave = onSave
        _selectedMetrics = State(initialValue: Set(template.applicableMetrics))
    }
    
    var body: some View {
        Form {
            Section(header: Text("基本信息")) {
                TextField("模板名称", text: $template.name)
                TextField("模板描述", text: $template.description)
                Toggle("设为默认", isOn: $template.isDefault)
            }
            
            Section(header: Text("适用指标")) {
                ForEach(HealthMetric.allCases) { metric in
                    Toggle(metric.name, isOn: Binding(
                        get: { selectedMetrics.contains(metric) },
                        set: { isSelected in
                            if isSelected {
                                selectedMetrics.insert(metric)
                            } else {
                                selectedMetrics.remove(metric)
                            }
                        }
                    ))
                }
            }
            
            Section(header: Text("提示词模板")) {
                TextEditor(text: $template.template)
                    .frame(height: 200)
            }
        }
        .navigationTitle(template.name.isEmpty ? "新建模板" : template.name)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("取消") {
                    dismiss()
                }
            }
            ToolbarItem(placement: .confirmationAction) {
                Button("保存") {
                    template.applicableMetrics = Array(selectedMetrics)
                    onSave(template)
                    dismiss()
                }
                .disabled(template.name.isEmpty || template.template.isEmpty)
            }
        }
    }
}

#Preview {
    NavigationView {
        AIPromptTemplates()
            .environmentObject(AIManager.shared)
    }
}
