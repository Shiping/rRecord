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

    private let dateRange: ClosedRange<Date> = {
        let calendar = Calendar.current
        let start = calendar.date(byAdding: .year, value: -100, to: Date())!
        let end = calendar.date(byAdding: .year, value: 0, to: Date())!
        return start...end
    }()
    
    var body: some View {
        Form {
            Section(header: Text("外观设置")) {
                Picker("主题", selection: $themeManager.currentTheme) {
                    Text("系统").tag("system")
                    Text("浅色").tag("light")
                    Text("深色").tag("dark")
                }
            }

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

            Section(header: Text("iCloud 同步"), footer: Text("启用 iCloud 同步后，您的数据将在 iCloud 中备份，并在重新安装应用后自动恢复。")) {
                Toggle("启用 iCloud 同步", isOn: $isICloudSyncEnabled)
                    .onChange(of: isICloudSyncEnabled) { newValue in
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
            
            Section(header: Text("AI 助手设置"), footer: Text("启用 AI 助手后，系统将基于您的健康数据提供个性化建议。需要配置 Deepseek API 密钥才能使用此功能。")) {
                Toggle("启用 AI 健康建议", isOn: $isAIEnabled)
                
                if isAIEnabled {
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
        .alert("提示", isPresented: $showingAlert) {
            Button("确定", role: .cancel) {}
        } message: {
            Text("请填写完整的个人信息")
        }
    }
    
    @State private var baseURL = ""
    @State private var modelName = ""

    private func loadProfile() {
        if let profile = healthStore.userProfile {
            name = profile.name
            height = String(format: "%.1f", profile.height)
            birthDate = profile.birthDate
            gender = profile.gender
            isAIEnabled = profile.aiSettings.enabled
            apiKey = profile.aiSettings.deepseekApiKey
            baseURL = profile.aiSettings.deepseekBaseURL
            modelName = profile.aiSettings.deepseekModel
        } else {
            baseURL = "https://api.deepseek.com/v1"
            modelName = "deepseek-chat"
        }
    }
    
    private func saveProfile() {
        guard !name.isEmpty,
              let heightValue = Double(height.replacingOccurrences(of: ",", with: "."))
        else {
            showingAlert = true
            return
        }
        let aiSettings = UserProfile.AISettings(
            deepseekApiKey: apiKey,
            deepseekBaseURL: baseURL.isEmpty ? "https://api.deepseek.com/v1" : baseURL,
            deepseekModel: modelName.isEmpty ? "deepseek-chat" : modelName,
            enabled: isAIEnabled
        )
        
        let profile = UserProfile(
            height: heightValue,
            birthDate: birthDate,
            gender: gender,
            name: name,
            aiSettings: aiSettings
        )
        
        healthStore.updateProfile(profile)
        dismiss()
    }
}

#Preview {
    NavigationView {
        ProfileView(healthStore: HealthStore())
    }
}
