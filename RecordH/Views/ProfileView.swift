import SwiftUI
import HealthKit

struct ProfileView: View {
    @ObservedObject var healthStore: HealthStore
    @EnvironmentObject private var themeManager: ThemeManager
    @Environment(\.dismiss) private var dismiss
    
    @State private var name: String = ""
    @State private var height: String = ""
    @State private var birthDate = Date()
    @State private var gender = UserProfile.Gender.other
    @State private var showingAlert = false
    @State private var isSyncing = false
    @State private var isICloudSyncEnabled: Bool = UserDefaults.standard.bool(forKey: "iCloudSyncEnabled")
    @State private var isManualSyncing = false
    @State private var isAIEnabled = false
    @State private var apiKey = ""
    @State private var apiKeyVisible = false
    @State private var selectedConfigurationId: UUID?
    @State private var baseURL = ""
    @State private var modelName = ""
    @State private var showingNewConfigAlert = false
    @State private var newConfigName = ""
    @State private var configName = ""
    @State private var showingConfigPicker = false
    @State private var showingDeleteAlert = false
    @State private var alertMessage = ""

    private let dateRange: ClosedRange<Date> = {
        let calendar = Calendar.current
        let start = calendar.date(byAdding: .year, value: -100, to: Date())!
        let end = calendar.date(byAdding: .year, value: 0, to: Date())!
        return start...end
    }()
    
    private var currentConfigName: String {
        if let id = selectedConfigurationId,
           let config = healthStore.userProfile?.aiSettings.first(where: { $0.id == id }) {
            return config.name
        }
        return "未选择"
    }
    
    private var canDeleteCurrentConfig: Bool {
        guard let aiSettings = healthStore.userProfile?.aiSettings else { return false }
        return aiSettings.count > 1
    }
    
    var body: some View {
        Form {
            Section(header: Text("基本信息")) {
                TextField("姓名", text: $name)
                
                TextField("身高 (cm)", text: $height)
                    .keyboardType(.decimalPad)
                
                DatePicker(
                    "出生日期",
                    selection: $birthDate,
                    in: dateRange,
                    displayedComponents: .date
                )
                
                Picker("性别", selection: $gender) {
                    Text("男").tag(UserProfile.Gender.male)
                    Text("女").tag(UserProfile.Gender.female)
                    Text("其他").tag(UserProfile.Gender.other)
                }
            }
            
            Section(header: Text("外观设置")) {
                Picker("主题", selection: $themeManager.currentTheme) {
                    Text("系统").tag("system")
                    Text("浅色").tag("light")
                    Text("深色").tag("dark")
                }
                
                Picker("主题色调", selection: $themeManager.currentAccent) {
                    Text("蓝色").tag(ThemeManager.ThemeAccent.blue)
                    Text("淡黄色").tag(ThemeManager.ThemeAccent.lightYellow)
                    Text("淡橙色").tag(ThemeManager.ThemeAccent.lightOrange)
                }
            }

            Section(header: Text("iCloud 同步"), footer: Text("启用 iCloud 同步后，您的数据将在 iCloud 中备份，并在重新安装应用后自动恢复。")) {
                Toggle("启用 iCloud 同步", isOn: $isICloudSyncEnabled)
                    .onChange(of: isICloudSyncEnabled) { oldValue, newValue in
                        UserDefaults.standard.set(newValue, forKey: "iCloudSyncEnabled")
                    }

                Button(action: {
                    isManualSyncing = true
                    healthStore.manualSyncToICloud { success in
                        DispatchQueue.main.async {
                            isManualSyncing = false
                            if success {
                                print("手动 iCloud 同步成功")
                            } else {
                                print("手动 iCloud 同步失败")
                            }
                        }
                    }
                }) {
                    HStack {
                        Image(systemName: "icloud.and.arrow.up")
                            .rotationEffect(.degrees(isManualSyncing ? 360 : 0))
                            .animation(isManualSyncing ? Animation.linear(duration: 1).repeatForever(autoreverses: false) : .default, value: isManualSyncing)
                        Text("手动同步 iCloud 数据")
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Theme.color(.accent, scheme: themeManager.colorScheme ?? .light))
                    .foregroundColor(.white)
                    .cornerRadius(10)
                }
                .buttonStyle(PlainButtonStyle())
                .disabled(!isICloudSyncEnabled || isManualSyncing)
            }

            Section(header: Text("HealthKit 集成")) {
                HStack {
                    Image(systemName: "heart.text.square.fill")
                        .foregroundColor(.red)
                    Text("HealthKit 状态")
                    Spacer()
                    Text(HKHealthStore.isHealthDataAvailable() ? "已连接" : "未连接")
                        .foregroundColor(HKHealthStore.isHealthDataAvailable() ? .green : .red)
                }
                
                Button(action: {
                    isSyncing = true
                    healthStore.refreshHealthData()
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                        isSyncing = false
                    }
                }) {
                    HStack {
                        Image(systemName: "arrow.triangle.2.circlepath")
                            .rotationEffect(.degrees(isSyncing ? 360 : 0))
                            .animation(isSyncing ? Animation.linear(duration: 1).repeatForever(autoreverses: false) : .default, value: isSyncing)
                        Text("同步 HealthKit 数据")
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Theme.color(.accent, scheme: themeManager.colorScheme ?? .light))
                    .foregroundColor(.white)
                    .cornerRadius(10)
                }
                .buttonStyle(PlainButtonStyle())
                .disabled(!HKHealthStore.isHealthDataAvailable())
            }
            
            Section(header: HStack {
                Text("AI 助手设置")
                Spacer()
                Button("新增配置") {
                    showingNewConfigAlert = true
                }
            }, footer: Text("启用 AI 助手后，系统将基于您的健康数据提供个性化建议。需要配置 Deepseek API 密钥才能使用此功能。用户可以配置其他模型。")) {
                Toggle("启用 AI 健康建议", isOn: $isAIEnabled)
                
                if isAIEnabled {
                    HStack {
                        Text("当前配置")
                        Spacer()
                        Button(action: {
                            showingConfigPicker = true
                        }) {
                            HStack {
                                Text(currentConfigName)
                                Image(systemName: "chevron.down")
                            }
                        }
                    }
                    
                    if selectedConfigurationId != nil {
                        HStack {
                            TextField("配置名称", text: $configName)
                                .textFieldStyle(RoundedBorderTextFieldStyle())
                            
                            if canDeleteCurrentConfig {
                                Button(action: {
                                    showingDeleteAlert = true
                                }) {
                                    Image(systemName: "trash")
                                        .foregroundColor(.red)
                                }
                            }
                        }
                        
                        HStack {
                            if apiKeyVisible {
                                TextField("Deepseek API 密钥", text: $apiKey)
                            } else {
                                SecureField("Deepseek API 密钥", text: $apiKey)
                            }
                            
                            Button(action: {
                                apiKeyVisible.toggle()
                            }) {
                                Image(systemName: apiKeyVisible ? "eye.slash.fill" : "eye.fill")
                            }
                        }
                        if apiKey.isEmpty {
                            Text("请输入有效的 API 密钥")
                                .font(.caption)
                                .foregroundColor(.red)
                        }
                        
                        VStack(alignment: .leading) {
                            Text("Deepseek API Base URL")
                            TextField("Deepseek API Base URL", text: $baseURL)
                                .textCase(.lowercase)
                        }
                        
                        VStack(alignment: .leading) {
                            Text("Deepseek Model Name")
                            TextField("Deepseek Model Name", text: $modelName)
                                .textCase(.lowercase)
                        }
                    }
                }
            }
            
            Section {
                Button("保存") {
                    saveProfile()
                }
                .frame(maxWidth: .infinity)
                .foregroundColor(Theme.color(.accent, scheme: themeManager.colorScheme ?? .light))
            }
        }
        .navigationTitle("个人信息")
        .onAppear(perform: loadProfile)
        .alert("新增 AI 配置", isPresented: $showingNewConfigAlert) {
            TextField("配置名称", text: $newConfigName)
            Button("取消", role: .cancel) {
                newConfigName = ""
            }
            Button("确定") {
                if !newConfigName.isEmpty {
                    addNewAIConfiguration(name: newConfigName)
                    newConfigName = ""
                }
            }
        } message: {
            Text("请输入配置名称")
        }
        .alert("删除配置", isPresented: $showingDeleteAlert) {
            Button("取消", role: .cancel) {}
            Button("删除", role: .destructive) {
                deleteCurrentConfiguration()
            }
        } message: {
            Text("确定要删除当前配置吗？这将删除该配置的所有设置。")
        }
        .confirmationDialog("选择 AI 配置", isPresented: $showingConfigPicker, titleVisibility: .visible) {
            ForEach(healthStore.userProfile?.aiSettings ?? []) { config in
                Button(config.name) {
                    selectedConfigurationId = config.id
                    apiKey = config.deepseekApiKey
                    baseURL = config.deepseekBaseURL
                    modelName = config.deepseekModel
                    configName = config.name
                }
            }
            Button("取消", role: .cancel) {}
        }
        .alert("提示", isPresented: $showingAlert) {
            Button("确定", role: .cancel) {}
        } message: {
            Text(alertMessage.isEmpty ? "请填写完整的个人信息" : alertMessage)
        }
    }
    
    private func loadProfile() {
        if let profile = healthStore.userProfile, let aiSettings = profile.aiSettings.first {
            name = profile.name
            height = String(format: "%.1f", profile.height)
            birthDate = profile.birthDate
            gender = profile.gender
            isAIEnabled = !profile.aiSettings.isEmpty
            apiKey = aiSettings.deepseekApiKey
            baseURL = aiSettings.deepseekBaseURL
            modelName = aiSettings.deepseekModel
            selectedConfigurationId = aiSettings.id
            configName = aiSettings.name
        } else {
            baseURL = "https://api.deepseek.com/v1"
            modelName = "deepseek-chat"
            isAIEnabled = false
            apiKey = ""
            selectedConfigurationId = nil
            configName = ""
        }
    }
    
    private func saveProfile() {
        guard !name.isEmpty,
              let heightValue = Double(height.replacingOccurrences(of: ",", with: "."))
        else {
            alertMessage = "请填写完整的个人信息"
            showingAlert = true
            return
        }
        
        var aiConfigurations = healthStore.userProfile?.aiSettings ?? []
        if aiConfigurations.isEmpty && isAIEnabled {
            aiConfigurations = [UserProfile.AIConfiguration(name: "默认配置")]
        }
        
        if let selectedId = selectedConfigurationId {
            if let index = aiConfigurations.firstIndex(where: { $0.id == selectedId }) {
                let aiConfiguration = UserProfile.AIConfiguration(
                    name: configName.isEmpty ? aiConfigurations[index].name : configName,
                    deepseekApiKey: apiKey,
                    deepseekBaseURL: baseURL.isEmpty ? "https://api.deepseek.com/v1" : baseURL,
                    deepseekModel: modelName.isEmpty ? "deepseek-chat" : modelName,
                    enabled: isAIEnabled
                )
                aiConfigurations[index] = aiConfiguration
            }
        }
        
        let profile = UserProfile(
            height: heightValue,
            birthDate: birthDate,
            gender: gender,
            name: name,
            aiSettings: isAIEnabled ? aiConfigurations : []
        )
        
        healthStore.updateProfile(profile)
        print("保存 Profile 数据: \(profile)")
        dismiss()
    }
    
    private func addNewAIConfiguration(name: String) {
        let newConfiguration = UserProfile.AIConfiguration(
            name: name,
            deepseekApiKey: "",
            deepseekBaseURL: "https://api.deepseek.com/v1",
            deepseekModel: "deepseek-chat",
            enabled: true
        )
        
        var currentAISettings = healthStore.userProfile?.aiSettings ?? []
        currentAISettings.append(newConfiguration)
        
        if var profile = healthStore.userProfile {
            profile.aiSettings = currentAISettings
            healthStore.updateProfile(profile)
            
            selectedConfigurationId = newConfiguration.id
            apiKey = ""
            baseURL = newConfiguration.deepseekBaseURL
            modelName = newConfiguration.deepseekModel
            configName = name
        }
        
        print("新增 AI 配置: \(newConfiguration)")
    }
    
    private func deleteCurrentConfiguration() {
        guard let selectedId = selectedConfigurationId,
              var aiConfigurations = healthStore.userProfile?.aiSettings,
              aiConfigurations.count > 1,
              let index = aiConfigurations.firstIndex(where: { $0.id == selectedId })
        else {
            alertMessage = "无法删除唯一的配置"
            showingAlert = true
            return
        }
        
        aiConfigurations.remove(at: index)
        
        if var profile = healthStore.userProfile {
            profile.aiSettings = aiConfigurations
            healthStore.updateProfile(profile)
            
            if let firstConfig = aiConfigurations.first {
                selectedConfigurationId = firstConfig.id
                apiKey = firstConfig.deepseekApiKey
                baseURL = firstConfig.deepseekBaseURL
                modelName = firstConfig.deepseekModel // 确保这里是 deepseekModel
                configName = firstConfig.name
            } else {
                selectedConfigurationId = nil
                apiKey = ""
                baseURL = ""
                modelName = ""
                configName = ""
            }
        }
        
        print("删除 AI 配置: \(selectedId)")
    }
}

#Preview {
    NavigationView {
        ProfileView(healthStore: HealthStore())
    }
}
