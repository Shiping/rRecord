import SwiftUI
import HealthKit

struct AddRecordSheet: View {
    let type: HealthRecord.RecordType
    @ObservedObject var healthStore: HealthStore
    @Binding var isPresented: Bool
    var editingRecord: HealthRecord?
    
    @State private var value: Double?
    @State private var secondaryValue: Double?
    @State private var isEditingValue = false
    @State private var isEditingSecondaryValue = false
    @State private var note: String = ""
    @State private var date = Date()
    @Environment(\.colorScheme) var colorScheme
    
    var currentBMI: Double? {
        guard type == .weight,
              let weight = value,
              let height = healthStore.userProfile?.height,
              height > 0 else { return nil }
        return weight / ((height / 100) * (height / 100))
    }
    
    init(type: HealthRecord.RecordType, healthStore: HealthStore, isPresented: Binding<Bool>, editingRecord: HealthRecord? = nil) {
        self.type = type
        self.healthStore = healthStore
        self._isPresented = isPresented
        self.editingRecord = editingRecord
        
        // Initialize state with editing record values if present
        if type == .sleep && editingRecord != nil {
            let totalMinutes = editingRecord!.value
            _value = State(initialValue: Double(Int(totalMinutes) / 60))
            _secondaryValue = State(initialValue: Double(Int(totalMinutes.truncatingRemainder(dividingBy: 60))))
        } else {
            _value = State(initialValue: editingRecord?.value)
            _secondaryValue = State(initialValue: editingRecord?.secondaryValue)
        }
        _note = State(initialValue: editingRecord?.note ?? "")
        _date = State(initialValue: editingRecord?.date ?? Date())
    }
    
    var body: some View {
        NavigationView {
            Form {
                Section {
                    if type == .sleep {
                        VStack(spacing: 15) {
                            // Number input fields
                            HStack(spacing: 20) {
                                VStack(alignment: .leading) {
                                    Text("小时")
                                        .font(.caption)
                                        .foregroundColor(.gray)
                                    TextField("0-23", value: $value, format: .number)
                                        .textFieldStyle(.roundedBorder)
                                        .keyboardType(.numberPad)
                                        .frame(width: 80)
                                }
                                
                                VStack(alignment: .leading) {
                                    Text("分钟")
                                        .font(.caption)
                                        .foregroundColor(.gray)
                                    TextField("0-59", value: $secondaryValue, format: .number)
                                        .textFieldStyle(.roundedBorder)
                                        .keyboardType(.numberPad)
                                        .frame(width: 80)
                                }
                            }
                            .padding(.top, 5)
                            
                            // Picker wheels
                            HStack(spacing: 0) {
                                Picker("小时", selection: $value) {
                                    ForEach(0..<24) { hour in
                                        Text("\(hour)小时").tag(Double(hour))
                                    }
                                }
                                .pickerStyle(.wheel)
                                .frame(width: 100)
                                
                                Picker("分钟", selection: $secondaryValue) {
                                    ForEach(0..<60) { minute in
                                        Text("\(minute)分钟").tag(Double(minute))
                                    }
                                }
                                .pickerStyle(.wheel)
                                .frame(width: 100)
                            }
                            .padding(.horizontal, -20)
                        }
                    } else {
                        VStack(spacing: 12) {
                            // Primary value input
                            ValueInputField(
                                label: type.valueLabel,
                                value: $value,
                                isEditing: $isEditingValue,
                                unit: type.unit
                            )
                            
                            // Show BMI for weight input
                            if type == .weight {
                                if let bmi = currentBMI {
                                    HStack {
                                        Text("BMI")
                                            .foregroundColor(Theme.color(.secondaryText, scheme: colorScheme))
                                        Spacer()
                                        HStack(spacing: 8) {
                                            Text(String(format: "%.1f", bmi))
                                                .foregroundColor(Theme.color(.text, scheme: colorScheme))
                                            Text(getBMIStatus(bmi))
                                                .foregroundColor(getBMIColor(bmi))
                                        }
                                    }
                                    .font(.subheadline)
                                    .padding(.horizontal)
                                } else if healthStore.userProfile?.height == nil {
                                    NavigationLink {
                                        ProfileView(healthStore: healthStore)
                                    } label: {
                                        HStack {
                                            Text("需要设置身高才能计算BMI")
                                                .foregroundColor(Theme.color(.secondaryText, scheme: colorScheme))
                                            Spacer()
                                            Image(systemName: "chevron.right")
                                                .foregroundColor(Theme.color(.secondaryText, scheme: colorScheme))
                                        }
                                        .font(.subheadline)
                                        .padding(.horizontal)
                                    }
                                }
                            }
                            
                            // Secondary value input for blood pressure
                            if type.needsSecondaryValue {
                                ValueInputField(
                                    label: "舒张压",
                                    value: $secondaryValue,
                                    isEditing: $isEditingSecondaryValue,
                                    unit: "mmHg"
                                )
                            }
                        }
                    }
                    
                    DatePicker("日期", selection: $date, displayedComponents: [.date, .hourAndMinute])
                }
                
                Section {
                    TextEditor(text: $note)
                        .frame(minHeight: 100)
                } header: {
                    Text("备注")
                }
            }
            .navigationTitle(editingRecord == nil ? "添加记录" : "编辑记录")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("取消") {
                        isPresented = false
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("保存") {
                        if let inputValue = value {
                            // Validate and constrain values
                            if type == .sleep {
                                value = Double(min(max(Int(inputValue), 0), 23))
                                if let secValue = secondaryValue {
                                    secondaryValue = Double(min(max(Int(secValue), 0), 59))
                                }
                            }
                            saveRecord()
                            isPresented = false
                        }
                    }
                    .disabled(value == nil || (type.needsSecondaryValue && secondaryValue == nil))
                }
            }
        }
    }
    
    private func getBMIStatus(_ bmi: Double) -> String {
        switch bmi {
        case ..<18.5:
            return "偏瘦"
        case 18.5..<23.9:
            return "正常"
        case 23.9..<27.9:
            return "偏胖"
        default:
            return "肥胖"
        }
    }
    
    private func getBMIColor(_ bmi: Double) -> Color {
        switch bmi {
        case 18.5..<23.9:
            return .green
        case 23.9..<27.9:
            return .orange
        default:
            return .red
        }
    }
    
    private func saveRecord() {
        guard let finalValue = value else { return }
        
        let record: HealthRecord
        if type == .weight {
            record = HealthRecord(
                id: editingRecord?.id ?? UUID(),
                date: date,
                type: type,
                value: finalValue,
                secondaryValue: currentBMI,
                unit: "kg",
                note: note
            )
        } else {
            record = HealthRecord(
                id: editingRecord?.id ?? UUID(),
                date: date,
                type: type,
                value: finalValue,
                secondaryValue: type == .bloodPressure ? secondaryValue : (type == .sleep ? secondaryValue : nil),
                unit: type == .bloodPressure ? "mmHg" : type == .sleep ? "小时" : type == .steps ? "步" : "",
                note: note
            )
        }
        
        if editingRecord != nil {
            healthStore.updateHealthRecord(record)
        } else {
            healthStore.addHealthRecord(record)
        }
    }
}

#Preview {
    AddRecordSheet(
        type: .bloodPressure,
        healthStore: HealthStore(),
        isPresented: .constant(true)
    )
}
