import SwiftUI
import HealthKit

struct WelcomeView: View {
    @EnvironmentObject var healthStore: HealthStore
    @Binding var hasGrantedPermission: Bool
    @State private var isAuthorizationInProgress = false
    @State private var showError = false
    @State private var animationScale = 1.0
    @State private var rotationDegrees = 0.0
    @State private var showInitialWelcome = true
    @State private var showHealthPermissionRequest = false
    @State private var rowOffsets: [CGFloat] = Array(repeating: -20, count: 6)

    var body: some View {
        if showInitialWelcome {
            ZStack {
                ScrollView {
                    VStack(spacing: 20) {
                        Image(systemName: "heart.text.square.fill")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 100, height: 100)
                            .foregroundColor(.red)
                            .padding(.top, 20)
                        
                        VStack(spacing: 15) {
                            Text("Mind Ur Meals")
                                .font(.system(size: 32, weight: .bold, design: .rounded))
                                .foregroundStyle(
                                    LinearGradient(
                                        colors: [Color(red: 0.2, green: 0.2, blue: 0.3), Color(red: 0.3, green: 0.2, blue: 0.4)],
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                                .offset(x: showInitialWelcome ? 0 : -100)
                                .opacity(showInitialWelcome ? 1 : 0)
                                .animation(.easeInOut(duration: 1).delay(0.5), value: showInitialWelcome)
                            
                            ZStack {
                                Circle()
                                    .stroke(Color.gray.opacity(0.5), lineWidth: 2)
                                    .frame(width: 60, height: 60)
                                    .rotationEffect(.degrees(rotationDegrees))
                            }
                            
                            Text("Move Ur Feet")
                                .font(.system(size: 32, weight: .bold, design: .rounded))
                                .foregroundStyle(
                                    LinearGradient(
                                        colors: [Color(red: 0.3, green: 0.2, blue: 0.4), Color(red: 0.2, green: 0.2, blue: 0.3)],
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                                .offset(x: showInitialWelcome ? 0 : 100)
                                .opacity(showInitialWelcome ? 1 : 0)
                                .animation(.easeInOut(duration: 1).delay(1.0), value: showInitialWelcome)

                            Text("管住嘴")
                                .font(.system(size: 32, weight: .bold, design: .rounded))
                                .foregroundStyle(
                                    LinearGradient(
                                        colors: [Color(red: 0.2, green: 0.2, blue: 0.3), Color(red: 0.3, green: 0.2, blue: 0.4)],
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                                .offset(y: showInitialWelcome ? 0 : 50)
                                .opacity(showInitialWelcome ? 1 : 0)
                                .animation(.easeInOut(duration: 1).delay(1.5), value: showInitialWelcome)

                            Text("迈开腿")
                                .font(.system(size: 32, weight: .bold, design: .rounded))
                                .foregroundStyle(
                                    LinearGradient(
                                        colors: [Color(red: 0.3, green: 0.2, blue: 0.4), Color(red: 0.2, green: 0.2, blue: 0.3)],
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                                .offset(y: showInitialWelcome ? 0 : 50)
                                .opacity(showInitialWelcome ? 1 : 0)
                                .animation(.easeInOut(duration: 1).delay(2.0), value: showInitialWelcome)
                        }
                        .shadow(color: Color.gray.opacity(0.3), radius: 5, x: 0, y: 0)
                        .scaleEffect(animationScale)
                        .padding(.horizontal)
                        .overlay(
                            RoundedRectangle(cornerRadius: 20)
                                .stroke(
                                    LinearGradient(
                                        colors: [.blue.opacity(0.3), .purple.opacity(0.3)],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    ),
                                    lineWidth: 2
                                )
                                .padding(5)
                        )
                        .onAppear {
                            withAnimation(
                                Animation.easeInOut(duration: 2)
                                    .repeatForever(autoreverses: true)
                            ) {
                                animationScale = 1.05
                            }

                            withAnimation(Animation.linear(duration: 4).repeatForever(autoreverses: false)) {
                                rotationDegrees = 360
                            }
                            
                            // Animate row offsets
                            for index in 0..<rowOffsets.count {
                                withAnimation(.easeInOut(duration: 1).delay(4.0 + Double(index) * 0.2)) {
                                    rowOffsets[index] = 0
                                }
                            }
                        }

                        Text("欢迎使用健康记录")
                            .font(.largeTitle)
                            .bold()
                            .foregroundStyle(
                                LinearGradient(
                                    colors: [Color(red: 0.2, green: 0.2, blue: 0.3), Color(red: 0.3, green: 0.2, blue: 0.4)],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .padding(.vertical)
                            .opacity(showInitialWelcome ? 1 : 0)
                            .animation(.easeInOut(duration: 1).delay(2.5), value: showInitialWelcome)

                        VStack(alignment: .leading, spacing: 15) {
                            Text("健康数据跟踪")
                                .font(.title2)
                                .bold()
                                .foregroundStyle(
                                    LinearGradient(
                                        colors: [Color(red: 0.2, green: 0.2, blue: 0.3), Color(red: 0.3, green: 0.2, blue: 0.4)],
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )

                            Text("此功能将帮助您跟踪以下健康指标：")
                                .font(.body)
                                .foregroundStyle(
                                    LinearGradient(
                                        colors: [Color(red: 0.2, green: 0.2, blue: 0.3), Color(red: 0.3, green: 0.2, blue: 0.4)],
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )

                            VStack(alignment: .leading, spacing: 10) {
                            let items = [
                                ("figure.walk", "步数"),
                                ("bed.double.fill", "睡眠数据"),
                                ("heart.fill", "心率"),
                                ("flame.fill", "活动能量"),
                                ("stairs", "爬楼层数"),
                                ("chart.bar.fill", "体脂率")
                            ]
                                
                                ForEach(Array(items.enumerated()), id: \.offset) { index, item in
                                    PermissionRow(icon: item.0, text: item.1)
                                        .offset(x: showInitialWelcome ? 0 : rowOffsets[index])
                                        .opacity(showInitialWelcome ? 1 : 0)
                                }
                            }
                            .padding(.leading)
                        }
                        .padding()
                        .background(RoundedRectangle(cornerRadius: 12)
                            .fill(Color.gray.opacity(0.1)))
                        
                        // Add padding at the bottom to account for the fixed button
                        Spacer().frame(height: 80)
                    }
                    .padding()
                }
                
                // Fixed button at the bottom
                VStack {
                    Spacer()
                    Button(action: {
                        withAnimation {
                            showInitialWelcome = false
                            showHealthPermissionRequest = true
                        }
                    }) {
                        Text("开始")
                            .font(.headline)
                            .fontWeight(.semibold)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 15)
                            .background(Color.blue)
                            .cornerRadius(12)
                    }
                    .padding(.horizontal)
                    .padding(.bottom, 20)
                }
                .background(
                    LinearGradient(
                        colors: [Color.white.opacity(0), Color.white],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                    .frame(height: 100)
                    .allowsHitTesting(false)
                )
            }
        } else if showHealthPermissionRequest {
            ScrollView {
                VStack(spacing: 30) {
                    Text("授权健康数据")
                        .font(.largeTitle)
                        .bold()
                        .padding(.top, 40)

                    VStack(alignment: .leading, spacing: 20) {
                        Text("您的健康伙伴")
                            .font(.title2)
                            .bold()

                        Text("请允许访问您的健康数据，以便我们为您提供以下服务：")
                            .padding(.bottom, 10)

                        VStack(alignment: .leading, spacing: 15) {
                            PermissionFeature(icon: "chart.bar.fill", title: "数据追踪", description: "记录并分析您的健康数据变化")
                            PermissionFeature(icon: "bell.fill", title: "健康提醒", description: "根据数据变化提供及时提醒")
                            PermissionFeature(icon: "chart.line.uptrend.xyaxis", title: "趋势分析", description: "了解您的健康状况发展趋势")
                            PermissionFeature(icon: "person.fill.checkmark", title: "个性化建议", description: "基于数据提供健康建议")
                        }
                        .padding(.leading, 10)
                    }
                    .padding()
                    .background(RoundedRectangle(cornerRadius: 12)
                        .fill(Color.gray.opacity(0.1)))
                    .padding(.horizontal)

                    if showError {
                        Text("需要健康数据访问权限才能使用此功能。\n您可以在设置中修改权限。")
                            .foregroundColor(.red)
                            .multilineTextAlignment(.center)
                            .padding()
                    }

                    Button(action: requestHealthKitPermission) {
                        HStack(spacing: 8) {
                            if isAuthorizationInProgress {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                    .scaleEffect(0.8)
                            }
                            Text("继续")
                                .font(.headline)
                                .fontWeight(.semibold)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 15)
                    }
                    .foregroundColor(.white)
                    .background(isAuthorizationInProgress ? Color.gray : Color.blue)
                    .cornerRadius(12)
                    .padding(.horizontal)
                    .disabled(isAuthorizationInProgress)
                    .padding(.bottom, 30)
                }
            }
            .transition(.opacity)
        } else {
            DashboardView()
                .transition(.opacity)
        }
    }
    
    private func requestHealthKitPermission() {
        guard !isAuthorizationInProgress else { return }
        
        isAuthorizationInProgress = true
        showError = false
        
        healthStore.requestInitialAuthorization { success in
            DispatchQueue.main.async {
                isAuthorizationInProgress = false
                if success {
                    withAnimation {
                        hasGrantedPermission = true
                        showHealthPermissionRequest = false
                    }
                } else {
                    withAnimation {
                        showError = true
                    }
                }
            }
        }
    }
}

struct PermissionRow: View {
    let icon: String
    let text: String
    
    var body: some View {
        HStack {
            Image(systemName: icon)
                .foregroundColor(.blue)
                .frame(width: 30)
            Text(text)
                .foregroundStyle(
                    LinearGradient(
                        colors: [Color(red: 0.2, green: 0.2, blue: 0.3), Color(red: 0.3, green: 0.2, blue: 0.4)],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
        }
    }
}

struct PermissionFeature: View {
    let icon: String
    let title: String
    let description: String
    
    var body: some View {
        HStack(alignment: .top, spacing: 15) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(.blue)
                .frame(width: 30)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.headline)
                Text(description)
                    .font(.subheadline)
                    .foregroundColor(.gray)
            }
        }
    }
}

struct WelcomeView_Previews: PreviewProvider {
    static var previews: some View {
        WelcomeView(hasGrantedPermission: .constant(false))
            .environmentObject(HealthStore())
    }
}
