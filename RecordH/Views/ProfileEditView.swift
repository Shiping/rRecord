import SwiftUI

struct ProfileEditView: View {
    @EnvironmentObject var healthStore: HealthStore
    @Environment(\.theme) var theme
    @Environment(\.dismiss) var dismiss
    
    @State private var gender: Gender
    @State private var birthday: Date
    @State private var height: Double
    @State private var location: String
    @State private var showingError = false
    @State private var errorMessage = ""
    
    init() {
        // Initialize with default values, will be updated in task
        _gender = State(initialValue: .other)
        _birthday = State(initialValue: Date())
        _height = State(initialValue: 170.0)
        _location = State(initialValue: "")
    }
    
    var body: some View {
        Form {
            Section(header: Text("基本信息")) {
                Picker("性别", selection: $gender) {
                    Text("男").tag(Gender.male)
                    Text("女").tag(Gender.female)
                    Text("其他").tag(Gender.other)
                }
                
                DatePicker("生日", selection: $birthday, displayedComponents: .date)
                
                HStack {
                    Text("身高")
                    Spacer()
                    TextField("身高 (cm)", value: $height, formatter: NumberFormatter())
                        .keyboardType(.decimalPad)
                        .multilineTextAlignment(.trailing)
                    Text("cm")
                }
            }
            
            Section(header: Text("所在地")) {
                TextField("请输入您的所在地，例如：里水松涛", text: $location)
            }
            
            Section {
                Button("保存修改") {
                    saveChanges()
                }
                .frame(maxWidth: .infinity)
                .foregroundColor(theme.accentColor)
            }
        }
        .navigationTitle("修改个人信息")
        .navigationBarTitleDisplayMode(.inline)
        .task {
            let profile = healthStore.userProfile
            gender = profile.gender
            birthday = profile.birthday
            height = profile.height ?? 170.0
            location = profile.location ?? ""
        }
        .alert("错误", isPresented: $showingError) {
            Button("确定", role: .cancel) { }
        } message: {
            Text(errorMessage)
        }
    }
    
    private func saveChanges() {
        // Input validation
        guard height >= 100 && height <= 250 else {
            errorMessage = "请输入有效的身高 (100-250 cm)"
            showingError = true
            return
        }
        
        let now = Date()
        let hundredYearsAgo = Calendar.current.date(byAdding: .year, value: -100, to: now) ?? now
        guard birthday > hundredYearsAgo && birthday <= now else {
            errorMessage = "请输入有效的出生日期"
            showingError = true
            return
        }
        
        // Update profile using the new updateUserProfile method
        healthStore.updateUserProfile(
            gender: gender,
            birthday: birthday,
            height: height,
            location: location.isEmpty ? nil : location
        )
        
        // Dismiss view
        dismiss()
    }
}

// Static instance for preview support
extension HealthStore {
    static let preview: HealthStore = {
        HealthStore.shared
    }()
}

#Preview {
    NavigationView {
        ProfileEditView()
            .environmentObject(HealthStore.preview)
    }
}
