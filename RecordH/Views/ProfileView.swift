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
    @State private var isICloudSyncEnabled: Bool = UserDefaults.standard.bool(forKey: "iCloudSyncEnabled") // 添加 iCloud 同步开关状态
    @State private var isManualSyncing = false // 添加手动同步状态

    private let dateRange: ClosedRange<Date> = {
        let calendar = Calendar.current
        let start = calendar.date(byAdding: .year, value: -100, to: Date())!
        let end = calendar.date(byAdding: .year, value: 0, to: Date())!
        return start...end
    }()
    
    var body: some View {
        Form {
            Section(header: Text("iCloud 同步"), footer: Text("启用 iCloud 同步后，您的数据将在 iCloud 中备份，并在重新安装应用后自动恢复。")) { // 添加 iCloud 同步 Section 和提示信息
                Toggle("启用 iCloud 同步", isOn: $isICloudSyncEnabled)
                    .onChange(of: isICloudSyncEnabled) { newValue in
                        UserDefaults.standard.set(newValue, forKey: "iCloudSyncEnabled")
                    }

                Button(action: {
                    isManualSyncing = true
                    healthStore.manualSyncToICloud { success in // 调用 HealthStore 的手动同步方法
                        DispatchQueue.main.async {
                            isManualSyncing = false
                            if success {
                                print("手动 iCloud 同步成功") // 可以在此处添加成功提示
                            } else {
                                print("手动 iCloud 同步失败") // 可以在此处添加失败提示
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
                .disabled(!isICloudSyncEnabled || isManualSyncing) // 在未启用 iCloud 或正在同步时禁用按钮
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
                    // Add delay to show sync animation
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
        dismiss()
    }
}

#Preview {
    NavigationView {
        ProfileView(healthStore: HealthStore())
    }
}
