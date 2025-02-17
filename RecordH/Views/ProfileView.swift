import SwiftUI
import HealthKit

struct ProfileView: View {
    @EnvironmentObject var healthStore: HealthStore
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
    @State private var alertMessage = ""

    private let dateRange: ClosedRange<Date> = {
        let calendar = Calendar.current
        let start = calendar.date(byAdding: .year, value: -100, to: Date())!
        let end = calendar.date(byAdding: .year, value: 0, to: Date())!
        return start...end
    }()
    
    
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
                .onChange(of: themeManager.currentTheme) { oldValue, newValue in
                    withAnimation {
                        themeManager.refreshTheme()
                    }
                }
                
                Picker("主题色调", selection: $themeManager.currentAccent) {
                    Text("蓝色").tag(ThemeManager.ThemeAccent.blue)
                    Text("淡黄色").tag(ThemeManager.ThemeAccent.lightYellow)
                    Text("淡橙色").tag(ThemeManager.ThemeAccent.lightOrange)
                }
                .onChange(of: themeManager.currentAccent) { oldValue, newValue in
                    withAnimation {
                        themeManager.refreshTheme()
                    }
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
                    healthStore.refreshHealthData {
                        DispatchQueue.main.async {
                            isSyncing = false
                        }
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
            Text(alertMessage.isEmpty ? "请填写完整的个人信息" : alertMessage)
        }
    }
    
    private func loadProfile() {
        if let profile = healthStore.userProfile {
            name = profile.name
            height = String(format: "%.1f", profile.height)
            birthDate = profile.birthDate
            gender = profile.gender
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
        
        let profile = UserProfile(
            height: heightValue,
            birthDate: birthDate,
            gender: gender,
            name: name
        )
        
        healthStore.updateProfile(profile)
        print("保存 Profile 数据: \(profile)")
        dismiss()
    }
}

#Preview {
    NavigationView {
        ProfileView()
            .environmentObject(HealthStore())
    }
}
