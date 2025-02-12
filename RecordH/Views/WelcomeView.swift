import SwiftUI
import HealthKit

struct WelcomeView: View {
    @ObservedObject var healthStore: HealthStore
    @Binding var hasGrantedPermission: Bool
    @State private var isAuthorizationInProgress = false
    @State private var showError = false
    
    var body: some View {
        VStack(spacing: 30) {
            Image(systemName: "heart.text.square.fill")
                .resizable()
                .scaledToFit()
                .frame(width: 100, height: 100)
                .foregroundColor(.red)
            
            Text("欢迎使用健康记录")
                .font(.largeTitle)
                .bold()
            
            VStack(alignment: .leading, spacing: 20) {
                Text("健康数据跟踪")
                    .font(.title2)
                    .bold()
                
                Text("此功能将帮助您跟踪以下健康指标：")
                    .font(.body)
                
                VStack(alignment: .leading, spacing: 10) {
                    PermissionRow(icon: "figure.walk", text: "步数")
                    PermissionRow(icon: "bed.double.fill", text: "睡眠数据")
                    PermissionRow(icon: "heart.fill", text: "心率")
                    PermissionRow(icon: "flame.fill", text: "活动能量")
                    PermissionRow(icon: "stairs", text: "爬楼层数")
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
                    .foregroundColor(.red)
                    .font(.caption)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
            } else {
                Text("此操作将打开权限请求\n您可以随时在设置中修改权限")
                    .font(.caption)
                    .foregroundColor(.gray)
                    .multilineTextAlignment(.center)
            }
        }
        .padding()
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
                .foregroundColor(.primary)
        }
    }
}

#Preview {
    WelcomeView(healthStore: HealthStore(), hasGrantedPermission: .constant(false))
}
