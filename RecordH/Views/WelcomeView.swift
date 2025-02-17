import SwiftUI
import HealthKit

struct WelcomeView: View {
    @EnvironmentObject var healthStore: HealthStore
    @Binding var hasGrantedPermission: Bool
    @State private var isAuthorizationInProgress = false
    @State private var showError = false
    @State private var animationScale = 1.0
    @State private var rotationDegrees = 0.0
    @State private var showWelcomeScreen = true
    @State private var rowOffsets: [CGFloat] = Array(repeating: -20, count: 5)

    var body: some View {
        if showWelcomeScreen {
            VStack(spacing: 30) {
                Image(systemName: "heart.text.square.fill")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 100, height: 100)
                    .foregroundColor(.red)
                
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
                        .offset(x: showWelcomeScreen ? 0 : -100)
                        .opacity(showWelcomeScreen ? 1 : 0)
                        .animation(.easeInOut(duration: 1).delay(0.5), value: showWelcomeScreen)
                    Spacer()
                        .frame(height: 10)
                    ZStack {
                        Circle()
                            .stroke(Color.gray.opacity(0.5), lineWidth: 2)
                            .frame(width: 60, height: 60)
                            .rotationEffect(.degrees(rotationDegrees))
                    }
                    Spacer()
                        .frame(height: 10)
                    Text("Move Ur Feet")
                        .font(.system(size: 32, weight: .bold, design: .rounded))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [Color(red: 0.3, green: 0.2, blue: 0.4), Color(red: 0.2, green: 0.2, blue: 0.3)],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .offset(x: showWelcomeScreen ? 0 : 100)
                        .opacity(showWelcomeScreen ? 1 : 0)
                        .animation(.easeInOut(duration: 1).delay(1.0), value: showWelcomeScreen)

                    Spacer()
                        .frame(height: 30)

                    Spacer()
                        .frame(height: 30)

                    Spacer()
                        .frame(height: 30)
                    
                    Spacer()
                        .frame(height: 30)

                    Text("管住嘴")
                        .font(.system(size: 32, weight: .bold, design: .rounded))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [Color(red: 0.2, green: 0.2, blue: 0.3), Color(red: 0.3, green: 0.2, blue: 0.4)],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .offset(y: showWelcomeScreen ? 0 : 50)
                        .opacity(showWelcomeScreen ? 1 : 0)
                        .animation(.easeInOut(duration: 1).delay(1.5), value: showWelcomeScreen)

                    Text("迈开腿")
                        .font(.system(size: 32, weight: .bold, design: .rounded))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [Color(red: 0.3, green: 0.2, blue: 0.4), Color(red: 0.2, green: 0.2, blue: 0.3)],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .offset(y: showWelcomeScreen ? 0 : 50)
                        .opacity(showWelcomeScreen ? 1 : 0)
                        .animation(.easeInOut(duration: 1).delay(2.0), value: showWelcomeScreen)
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
                    
                    // Delay the transition away from the welcome screen
                    DispatchQueue.main.asyncAfter(deadline: .now() + 7.0) {
                        withAnimation {
                            showWelcomeScreen = false
                        }
                    }
                }

                Spacer()
                    .frame(height: 50)

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
                    .offset(y: showWelcomeScreen ? 0 : 30)
                    .opacity(showWelcomeScreen ? 1 : 0)
                    .animation(.easeInOut(duration: 1).delay(2.5), value: showWelcomeScreen)

                VStack(alignment: .leading, spacing: 20) {
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
                        .offset(y: showWelcomeScreen ? 0 : 20)
                        .opacity(showWelcomeScreen ? 1 : 0)
                        .animation(.easeInOut(duration: 1).delay(3.0), value: showWelcomeScreen)

                    Text("此功能将帮助您跟踪以下健康指标：")
                        .font(.body)
                        .foregroundStyle(
                            LinearGradient(
                                colors: [Color(red: 0.2, green: 0.2, blue: 0.3), Color(red: 0.3, green: 0.2, blue: 0.4)],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .offset(y: showWelcomeScreen ? 0 : 20)
                        .opacity(showWelcomeScreen ? 1 : 0)
                        .animation(.easeInOut(duration: 1).delay(3.5), value: showWelcomeScreen)

                    VStack(alignment: .leading, spacing: 10) {
                        let items = [
                            ("figure.walk", "步数"),
                            ("bed.double.fill", "睡眠数据"),
                            ("heart.fill", "心率"),
                            ("flame.fill", "活动能量"),
                            ("stairs", "爬楼层数")
                        ]
                        
                        ForEach(Array(items.enumerated()), id: \.offset) { index, item in
                            PermissionRow(icon: item.0, text: item.1)
                                .offset(x: showWelcomeScreen ? 0 : rowOffsets[index])
                                .opacity(showWelcomeScreen ? 1 : 0)
                        }
                    }
                    .padding(.leading)
                }
                .padding()
                .background(RoundedRectangle(cornerRadius: 12)
                    .fill(Color.gray.opacity(0.1)))

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
                    .contentShape(Rectangle())
                }
                .foregroundColor(.white)
                .padding(.vertical, 15)
                .padding(.horizontal)
                .background(isAuthorizationInProgress ? Color.gray : Color.blue)
                .cornerRadius(12)
                .shadow(radius: 2)
                .animation(.easeInOut(duration: 0.2), value: isAuthorizationInProgress)
                .disabled(isAuthorizationInProgress)
                .accessibilityLabel("继续")
                .accessibilityHint("点击授权访问健康数据")
                .padding(.horizontal)

                if showError {
                    Text("需要健康数据访问权限才能使用此功能。\n您可以在设置中修改权限。")
                        .foregroundStyle(
                            LinearGradient(
                                colors: [Color.red, Color.red.opacity(0.8)],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .font(.caption)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                } else {
                    Text("此操作将打开权限请求\n您可以随时在设置中修改权限")
                        .font(.caption)
                        .foregroundStyle(
                            LinearGradient(
                                colors: [Color(red: 0.2, green: 0.2, blue: 0.3), Color(red: 0.3, green: 0.2, blue: 0.4)],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .multilineTextAlignment(.center)
                }
            }
            .padding()
        } else {
            if hasGrantedPermission {
                Text("Main App Content")
            } else {
                Text("HealthKit permission not granted.")
            }
        }
    }
    
    private func requestHealthKitPermission() {
        guard !isAuthorizationInProgress else { return }
        
        isAuthorizationInProgress = true
        showError = false
        
        healthStore.requestInitialAuthorization { success in
            DispatchQueue.main.async {
                isAuthorizationInProgress = false
                withAnimation {
                    if success {
                        hasGrantedPermission = true
                    } else {
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

struct WelcomeView_Previews: PreviewProvider {
    static var previews: some View {
        WelcomeView(hasGrantedPermission: .constant(false))
            .environmentObject(HealthStore())
    }
}
