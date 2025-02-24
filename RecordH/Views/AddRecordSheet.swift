import SwiftUI
import HealthKit

struct AddRecordSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.theme) var theme
    @EnvironmentObject var healthStore: HealthStore
    
    let metric: HealthMetric
    @State private var value: Double = 0.0
    @State private var isValid: Bool = true
    @State private var date = Date()
    @State private var showingError = false
    @State private var errorMessage = ""
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 16) {
                    HStack {
                        Text("指标")
                        Spacer()
                        Text(metric.name)
                            .foregroundColor(.secondary)
                    }
                    .padding()
                    .background(Color(UIColor.secondarySystemGroupedBackground))
                    
                    ValueInputWithValidation(
                        metric: metric,
                        value: $value,
                        isValid: $isValid
                    )
                    .padding()
                    .background(Color(UIColor.secondarySystemGroupedBackground))
                    
                    DatePicker("日期", selection: $date, displayedComponents: [.date, .hourAndMinute])
                        .padding()
                        .background(Color(UIColor.secondarySystemGroupedBackground))
                }
                .padding(.vertical)
            }
            .background(Color(UIColor.systemGroupedBackground))
            .navigationTitle("添加记录")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("取消") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("保存") {
                        saveRecord()
                    }
                    .disabled(!isValid)
                }
            }
            .alert("错误", isPresented: $showingError) {
                Button("确定", role: .cancel) { }
            } message: {
                Text(errorMessage)
            }
        }
    }
    
    private func saveRecord() {
        guard isValid else {
            errorMessage = "请输入有效的数值"
            showingError = true
            return
        }
        
        let record = HealthRecord(
            id: UUID(),
            metric: metric,
            value: value,
            date: date
        )
        
        healthStore.addRecord(record)
        dismiss()
    }
}

#Preview {
    AddRecordSheet(metric: .bodyMass)
        .environmentObject(HealthStore.shared)
}
