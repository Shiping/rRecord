import SwiftUI

struct ProfileView: View {
    @EnvironmentObject var healthStore: HealthStore
    @Environment(\.theme) var theme
    @Environment(\.colorScheme) var colorScheme
    
    @State private var showingPrivacyPolicy = false
    @State private var showingProfileEdit = false
    
    var body: some View {
        List {
            // Personal Info Section
            Section {
                Button(action: { showingProfileEdit = true }) {
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            VStack(alignment: .leading) {
                                Text("个人资料")
                                    .font(.headline)
                                Text("\(healthStore.userProfile.gender.rawValue) · \(healthStore.userProfile.age)岁")
                                    .font(.subheadline)
                                    .foregroundColor(theme.secondaryTextColor)
                            }
                            Spacer()
                            Image(systemName: "chevron.right")
                                .foregroundColor(theme.secondaryTextColor)
                        }
                    }
                }
            }
            
            // AI Settings Section
            Section(header: Text("AI 助手")) {
                NavigationLink(destination: AIConfigList()) {
                    HStack {
                        Image(systemName: "list.bullet")
                        Text("AI配置")
                    }
                }
                
                NavigationLink(destination: AIPromptTemplates()) {
                    HStack {
                        Image(systemName: "text.bubble")
                        Text("分析模板")
                    }
                }
            }
            
            // Data Management Section
            Section(header: Text("数据管理")) {
                Button(action: {
                    Task {
                        await healthStore.refreshData()
                    }
                }) {
                    HStack {
                        Image(systemName: "arrow.clockwise")
                        Text("更新数据")
                    }
                }
                
                NavigationLink(destination: MedicalReferencesView(metric: nil)) {
                    HStack {
                        Image(systemName: "cross.case")
                        Text("医学参考")
                    }
                }
            }
            
            // Other Settings Section
            Section(header: Text("其他设置")) {
                Button(action: { showingPrivacyPolicy = true }) {
                    HStack {
                        Image(systemName: "doc.text")
                        Text("隐私政策")
                    }
                }
            }
        }
        .navigationTitle("设置")
        .sheet(isPresented: $showingProfileEdit) {
            NavigationView {
                ProfileEditView()
            }
        }
        .sheet(isPresented: $showingPrivacyPolicy) {
            NavigationView {
                ScrollView {
                    Text("""
                    隐私政策

                    本应用重视用户的隐私保护，我们承诺：

                    1. 所有健康数据均存储在您的设备本地
                    2. 不会将您的健康数据上传到云端
                    3. AI分析功能仅发送必要的数据进行分析
                    4. 您可以随时删除所有数据

                    如有任何问题，请联系我们。
                    """)
                    .padding()
                }
                .navigationTitle("隐私政策")
                .navigationBarItems(trailing: Button("关闭") {
                    showingPrivacyPolicy = false
                })
            }
        }
    }
}

#Preview {
    NavigationView {
        ProfileView()
            .environmentObject(HealthStore.shared)
    }
}
