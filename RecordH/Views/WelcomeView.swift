import SwiftUI
import HealthKit

struct WelcomeView: View {
    @EnvironmentObject var healthStore: HealthStore
    @Environment(\.theme) var theme
    @Binding var isPresented: Bool
    
    @State private var currentPage = 0
    @State private var gender: Gender = .male
    @State private var birthday = Calendar.current.date(byAdding: .year, value: -30, to: Date()) ?? Date()
    @State private var height: Double = 170.0
    @State private var location: String = ""
    @State private var showingError = false
    @State private var errorMessage = ""
    @State private var isSettingUp = false
    
    private let pages = [
        WelcomePage(title: "欢迎使用健康记录",
                   subtitle: "记录和追踪您的健康数据",
                   image: "heart.text.square.fill"),
        WelcomePage(title: "数据安全",
                   subtitle: "您的健康数据安全存储在设备中",
                   image: "lock.shield.fill"),
        WelcomePage(title: "智能分析",
                   subtitle: "AI助手帮助您分析健康趋势",
                   image: "brain.head.profile")
    ]
    
    var body: some View {
        VStack {
            if currentPage < pages.count {
                onboardingView
            } else {
                profileSetupView
            }
        }
        .alert("错误", isPresented: $showingError) {
            Button("确定", role: .cancel) { }
        } message: {
            Text(errorMessage)
        }
    }
    
    private var onboardingView: some View {
        VStack {
            TabView(selection: $currentPage) {
                ForEach(0..<pages.count, id: \.self) { index in
                    WelcomePageView(page: pages[index])
                        .tag(index)
                }
            }
            .tabViewStyle(.page)
            .indexViewStyle(.page(backgroundDisplayMode: .always))
            
            HStack {
                if currentPage > 0 {
                    Button("上一步") {
                        withAnimation {
                            currentPage -= 1
                        }
                    }
                }
                
                Spacer()
                
                Button(currentPage == pages.count - 1 ? "开始设置" : "下一步") {
                    withAnimation {
                        if currentPage < pages.count - 1 {
                            currentPage += 1
                        } else {
                            currentPage = pages.count
                        }
                    }
                }
            }
            .padding()
        }
    }
    
    private var profileSetupView: some View {
        ScrollView {
            VStack(spacing: 20) {
                Text("个人信息设置")
                    .font(.title)
                    .padding(.top)
                
                VStack(alignment: .leading) {
                    Text("性别")
                        .font(.headline)
                    
                    Picker("性别", selection: $gender) {
                        Text("男").tag(Gender.male)
                        Text("女").tag(Gender.female)
                        Text("其他").tag(Gender.other)
                    }
                    .pickerStyle(.segmented)
                }
                .padding()
                
                VStack(alignment: .leading) {
                    Text("生日")
                        .font(.headline)
                    
                    DatePicker("生日",
                             selection: $birthday,
                             displayedComponents: .date)
                }
                .padding()
                
                VStack(alignment: .leading) {
                    Text("身高 (cm)")
                        .font(.headline)
                    
                    TextField("身高", value: $height, formatter: NumberFormatter())
                        .keyboardType(.decimalPad)
                        .textFieldStyle(.roundedBorder)
                }
                .padding()
                
                VStack(alignment: .leading) {
                    Text("所在地")
                        .font(.headline)
                    
                    TextField("请输入您的所在地，例如：里水松涛", text: $location)
                        .textFieldStyle(.roundedBorder)
                        .autocorrectionDisabled()
                }
                .padding()
                
                if isSettingUp {
                    VStack(spacing: 10) {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle())
                        Text("正在设置...")
                            .foregroundStyle(.secondary)
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                } else {
                    Button(action: completeSetup) {
                        Text("完成设置")
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(theme.accentColor)
                            .foregroundStyle(.white)
                            .clipShape(RoundedRectangle(cornerRadius: 10))
                    }
                    .padding()
                }
            }
        }
        .disabled(isSettingUp)
    }
    
    private func completeSetup() {
        guard !isSettingUp else { return }
        
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
        
        isSettingUp = true
        
        Task {
            do {
                // Create and save user profile first
                let profile = UserProfile(
                    gender: gender,
                    birthday: birthday,
                    height: height,
                    location: location.isEmpty ? nil : location
                )
                
                await MainActor.run {
                    healthStore.userProfile = profile
                    healthStore.saveData()
                }
                
                // Check HealthKit availability
                guard HKHealthStore.isHealthDataAvailable() else {
                    throw HealthStoreError.healthKitNotAvailable
                }
                
                // Request HealthKit authorization with retry
                try await healthStore.ensureAuthorization()
                
                // Refresh initial data
                await healthStore.refreshData()
                
                // Close welcome screen on success
                await MainActor.run {
                    isPresented = false
                }
            } catch {
                await MainActor.run {
                    if let healthError = error as? HealthStoreError {
                        errorMessage = healthError.localizedDescription
                    } else {
                        errorMessage = "设置过程中出错：\(error.localizedDescription)"
                    }
                    showingError = true
                    isSettingUp = false
                }
            }
        }
    }
}

struct WelcomePage {
    let title: String
    let subtitle: String
    let image: String
}

struct WelcomePageView: View {
    let page: WelcomePage
    @Environment(\.theme) var theme
    
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: page.image)
                .resizable()
                .scaledToFit()
                .frame(width: 100, height: 100)
                .foregroundStyle(theme.accentColor)
            
            Text(page.title)
                .font(.title)
                .bold()
            
            Text(page.subtitle)
                .font(.body)
                .multilineTextAlignment(.center)
                .foregroundStyle(.secondary)
                .padding(.horizontal)
        }
        .padding()
    }
}

#Preview {
    WelcomeView(isPresented: .constant(true))
        .environmentObject(HealthStore.shared)
}
