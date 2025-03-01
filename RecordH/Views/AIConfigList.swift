import SwiftUI

struct AIConfigList: View {
    @EnvironmentObject private var configManager: AIConfigurationManager
    @State private var showingAddConfig = false
    @State private var showingEditConfig: AIConfiguration?
    @Environment(\.theme) var theme
    
    var body: some View {
        List {
            ForEach(configManager.configurations) { config in
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
                            Text(AIConfigEditor.commonModels[config.modelName] ?? config.modelName)
                                .font(.subheadline)
                                .foregroundColor(theme.secondaryTextColor)
                            Text(config.baseURL.absoluteString)
                                .font(.caption)
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
                AIConfigEditor(config: .deepseekDefault, onSave: { config in
                    configManager.addConfiguration(config)
                    showingAddConfig = false
                })
            }
        }
        .sheet(item: $showingEditConfig) { config in
            NavigationView {
                AIConfigEditor(config: config, onSave: { updatedConfig in
                    configManager.updateConfiguration(updatedConfig)
                    showingEditConfig = nil
                })
            }
        }
    }
    
    private func deleteConfigs(at offsets: IndexSet) {
        for index in offsets {
            let config = configManager.configurations[index]
            if !config.isDefault {
                configManager.deleteConfiguration(config)
            }
        }
    }
}

struct AIConfigEditor: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.theme) var theme
    @State private var editableConfig: AIConfiguration
    let originalConfig: AIConfiguration
    let onSave: (AIConfiguration) -> Void
    
    static let commonModels = [
        "deepseek-chat": "Deepseek Chat",
        "gpt-4": "GPT-4",
        "gpt-3.5-turbo": "GPT-3.5 Turbo",
        "claude-2": "Claude 2",
        "gemini-pro": "Gemini Pro"
    ]
    
    init(config: AIConfiguration, onSave: @escaping (AIConfiguration) -> Void) {
        self.originalConfig = config
        _editableConfig = State(initialValue: config)
        self.onSave = onSave
    }
    
    var body: some View {
        Form {
            Section(header: Text("基本设置"), footer: Text("为AI配置设置基本参数，包括名称、服务地址和访问密钥")) {
                TextField("配置名称", text: $editableConfig.name)
                TextField("Base URL", text: Binding(
                    get: { editableConfig.baseURL.absoluteString },
                    set: { if let url = URL(string: $0) { editableConfig.baseURL = url } }
                ))
                .keyboardType(.URL)
                .autocapitalization(.none)
                SecureField("API Key", text: $editableConfig.apiKey)
                
                Picker("模型", selection: $editableConfig.modelName) {
                    ForEach(Array(Self.commonModels.keys), id: \.self) { key in
                        Text(Self.commonModels[key] ?? key)
                            .tag(key)
                    }
                    if !Self.commonModels.keys.contains(editableConfig.modelName) {
                        Text(editableConfig.modelName)
                            .tag(editableConfig.modelName)
                    }
                }
                
                if !Self.commonModels.keys.contains(editableConfig.modelName) {
                    TextField("自定义模型名称", text: $editableConfig.modelName)
                        .autocapitalization(.none)
                }
                
                if !editableConfig.isDefault {
                    Toggle("设为默认", isOn: $editableConfig.isDefault)
                }
            }
            
            Section(header: Text("模型参数"), footer: Text("调整AI模型的参数以控制输出的创造性和质量")) {
                VStack(alignment: .leading) {
                    HStack {
                        Text("Temperature")
                        Spacer()
                        Text(String(format: "%.2f", editableConfig.temperature))
                    }
                    Slider(value: $editableConfig.temperature, in: 0...2)
                }
                .help("控制输出的随机性：较高的值使输出更有创意，较低的值使输出更确定")
                
                VStack(alignment: .leading) {
                    HStack {
                        Text("最大Tokens")
                        Spacer()
                        Text("\(editableConfig.maxTokens)")
                    }
                    Stepper("", value: $editableConfig.maxTokens, in: 100...8000, step: 100)
                }
                .help("限制AI响应的最大长度")
                
                VStack(alignment: .leading) {
                    HStack {
                        Text("Top P")
                        Spacer()
                        Text(String(format: "%.2f", editableConfig.topP))
                    }
                    Slider(value: $editableConfig.topP, in: 0...1)
                }
                .help("控制输出的多样性：数值越高，生成的文本越多样化")
                
                VStack(alignment: .leading) {
                    HStack {
                        Text("Presence Penalty")
                        Spacer()
                        Text(String(format: "%.2f", editableConfig.presencePenalty))
                    }
                    Slider(value: $editableConfig.presencePenalty, in: -2...2)
                }
                .help("增加模型谈论新话题的可能性")
                
                VStack(alignment: .leading) {
                    HStack {
                        Text("Frequency Penalty")
                        Spacer()
                        Text(String(format: "%.2f", editableConfig.frequencyPenalty))
                    }
                    Slider(value: $editableConfig.frequencyPenalty, in: -2...2)
                }
                .help("降低模型重复使用相同表达的可能性")
            }
        }
        .navigationTitle(editableConfig.name.isEmpty ? "新建配置" : editableConfig.name)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("取消") {
                    dismiss()
                }
            }
            ToolbarItem(placement: .confirmationAction) {
                Button("保存") {
                    onSave(editableConfig)
                    dismiss()
                }
                .disabled(editableConfig.name.isEmpty || editableConfig.apiKey.isEmpty)
            }
        }
    }
}

#Preview {
    NavigationView {
        AIConfigList()
            .environmentObject(AIConfigurationManager.shared)
    }
}
