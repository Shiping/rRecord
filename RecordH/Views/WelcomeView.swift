import SwiftUI
import HealthKit

struct WelcomeView: View {
    @ObservedObject var healthStore: HealthStore
    @Binding var hasGrantedPermission: Bool
    
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
                Text("需要访问健康数据")
                    .font(.title2)
                    .bold()
                
                Text("本应用需要访问以下健康数据类型：")
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
                Text("授权访问健康数据")
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.blue)
                    .cornerRadius(10)
            }
            .padding(.horizontal)
            
            Text("您可以随时在系统设置中修改权限")
                .font(.caption)
                .foregroundColor(.gray)
        }
        .padding()
    }
    
    private func requestHealthKitPermission() {
        healthStore.requestInitialAuthorization { success in
            if success {
                hasGrantedPermission = true
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
