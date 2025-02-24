import SwiftUI

struct AIConfigView: View {
    @StateObject private var configManager = AIConfigurationManager()
    @State private var isAddingNew = false
    @State private var newName = ""
    @State private var newBaseURL = ""
    @State private var newAPIKey = ""
    @State private var showAlert = false
    @State private var alertMessage = ""
    
    var body: some View {
        List {
            Section {
                ForEach(configManager.configurations) { config in
                    ConfigurationRow(config: config, configManager: configManager)
                }
            } header: {
                Text("AI配置")
            } footer: {
                Text("配置不同的AI模型，可随时切换使用。API密钥将安全存储。")
            }
            
            Section {
                if isAddingNew {
                    TextField("名称", text: $newName)
                    TextField("Base URL", text: $newBaseURL)
                    SecureField("API Key", text: $newAPIKey)
                    
                    HStack {
                        Button("保存") {
                            saveNewConfiguration()
                        }
                        .disabled(newName.isEmpty || newBaseURL.isEmpty || newAPIKey.isEmpty)
                        
                        Spacer()
                        
                        Button("取消") {
                            isAddingNew = false
                            resetNewFields()
                        }
                    }
                } else {
                    Button(action: {
                        isAddingNew = true
                    }) {
                        Label("添加新配置", systemImage: "plus.circle")
                    }
                }
            }
        }
        .navigationTitle("AI设置")
        .alert("提示", isPresented: $showAlert) {
            Button("确定", role: .cancel) {}
        } message: {
            Text(alertMessage)
        }
    }
    
    private func saveNewConfiguration() {
        guard let url = URL(string: newBaseURL) else {
            alertMessage = "请输入有效的URL"
            showAlert = true
            return
        }
        
        let newConfig = AIConfiguration(
            name: newName,
            baseURL: url,
            apiKey: newAPIKey,
            isDefault: configManager.configurations.isEmpty
        )
        
        configManager.addConfiguration(newConfig)
        isAddingNew = false
        resetNewFields()
    }
    
    private func resetNewFields() {
        newName = ""
        newBaseURL = ""
        newAPIKey = ""
    }
}

struct ConfigurationRow: View {
    let config: AIConfiguration
    @ObservedObject var configManager: AIConfigurationManager
    @State private var showDeleteAlert = false
    
    var body: some View {
        HStack {
            VStack(alignment: .leading) {
                Text(config.name)
                    .font(.headline)
                Text(config.baseURL.absoluteString)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            if config.isDefault {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundColor(.accentColor)
            } else {
                Button {
                    configManager.setDefaultConfiguration(config)
                } label: {
                    Image(systemName: "circle")
                        .foregroundColor(.secondary)
                }
            }
            
            if !config.isDefault {
                Button {
                    showDeleteAlert = true
                } label: {
                    Image(systemName: "trash")
                        .foregroundColor(.red)
                }
            }
        }
        .alert("确认删除", isPresented: $showDeleteAlert) {
            Button("删除", role: .destructive) {
                configManager.deleteConfiguration(config)
            }
            Button("取消", role: .cancel) {}
        } message: {
            Text("确定要删除此配置吗？")
        }
    }
}

#Preview {
    NavigationView {
        AIConfigView()
    }
}
