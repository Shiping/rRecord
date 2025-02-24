import SwiftUI

struct AIConfig: Identifiable, Codable {
    var id = UUID()
    var name: String
    var model: String
    var temperature: Double
    var maxTokens: Int
    var systemPrompt: String
    var isDefault: Bool
}

struct AIConfigList: View {
    @EnvironmentObject private var aiManager: AIManager
    @State private var showingAddConfig = false
    @State private var showingEditConfig: AIConfig?
    @Environment(\.theme) var theme
    
    var body: some View {
        List {
            ForEach(aiManager.configs) { config in
                Button(action: {
                    showingEditConfig = config
                }) {
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            HStack {
                                Text(config.name)
                                    .font(.headline)
                                if config.isDefault {
                                    Text("默认")
                                        .font(.caption)
                                        .padding(.horizontal, 6)
                                        .padding(.vertical, 2)
                                        .background(theme.accentColor.opacity(0.2))
                                        .cornerRadius(4)
                                }
                            }
                            Text(config.model)
                                .font(.subheadline)
                                .foregroundColor(theme.secondaryTextColor)
                        }
                        Spacer()
                        Image(systemName: "chevron.right")
                            .foregroundColor(theme.secondaryTextColor)
                    }
                }
            }
            .onDelete(perform: deleteConfigs)
        }
        .navigationTitle("AI配置")
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(action: { showingAddConfig = true }) {
                    Image(systemName: "plus")
                }
            }
        }
        .sheet(isPresented: $showingAddConfig) {
            NavigationView {
                AIConfigEditor(config: AIConfig(
                    name: "",
                    model: "gpt-3.5-turbo",
                    temperature: 0.7,
                    maxTokens: 500,
                    systemPrompt: "",
                    isDefault: false
                ), onSave: { config in
                    aiManager.addConfig(config)
                    showingAddConfig = false
                })
            }
        }
        .sheet(item: $showingEditConfig) { config in
            NavigationView {
                AIConfigEditor(config: config, onSave: { updatedConfig in
                    aiManager.updateConfig(updatedConfig)
                    showingEditConfig = nil
                })
            }
        }
    }
    
    private func deleteConfigs(at offsets: IndexSet) {
        for index in offsets {
            let config = aiManager.configs[index]
            aiManager.deleteConfig(config)
        }
    }
}

struct AIConfigEditor: View {
    @Environment(\.dismiss) private var dismiss
    @State private var config: AIConfig
    let onSave: (AIConfig) -> Void
    
    init(config: AIConfig, onSave: @escaping (AIConfig) -> Void) {
        _config = State(initialValue: config)
        self.onSave = onSave
    }
    
    var body: some View {
        Form {
            Section(header: Text("基本设置")) {
                TextField("配置名称", text: $config.name)
                Picker("模型", selection: $config.model) {
                    Text("GPT-3.5").tag("gpt-3.5-turbo")
                    Text("GPT-4").tag("gpt-4")
                }
                Toggle("设为默认", isOn: $config.isDefault)
            }
            
            Section(header: Text("模型参数")) {
                VStack(alignment: .leading) {
                    Text("Temperature: \(config.temperature, specifier: "%.1f")")
                    Slider(value: $config.temperature, in: 0...1)
                }
                
                Stepper("最大Token: \(config.maxTokens)", value: $config.maxTokens, in: 100...2000, step: 100)
            }
            
            Section(header: Text("系统提示词")) {
                TextEditor(text: $config.systemPrompt)
                    .frame(height: 100)
            }
        }
        .navigationTitle(config.name.isEmpty ? "新建配置" : config.name)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("取消") {
                    dismiss()
                }
            }
            ToolbarItem(placement: .confirmationAction) {
                Button("保存") {
                    onSave(config)
                    dismiss()
                }
                .disabled(config.name.isEmpty)
            }
        }
    }
}

#Preview {
    NavigationView {
        AIConfigList()
            .environmentObject(AIManager.shared)
    }
}
