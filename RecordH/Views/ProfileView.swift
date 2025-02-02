import SwiftUI

struct ProfileView: View {
    @ObservedObject var healthStore: HealthStore
    @Environment(\.dismiss) private var dismiss
    
    @State private var name: String = ""
    @State private var height: String = ""
    @State private var birthDate = Date()
    @State private var gender = UserProfile.Gender.other
    @State private var showingAlert = false
    
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
            
            Section {
                Button("保存") {
                    saveProfile()
                }
                .frame(maxWidth: .infinity)
                .foregroundColor(Theme.accent)
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
