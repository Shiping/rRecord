import SwiftUI

struct AddRecordSheet: View {
    let type: HealthRecord.RecordType
    @ObservedObject var healthStore: HealthStore
    @Binding var isPresented: Bool
    var editingRecord: HealthRecord?
    
    @State private var value: Double
    @State private var secondaryValue: Double
    @State private var note: String = ""
    @State private var date = Date()
    @Environment(\.colorScheme) var colorScheme
    
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
            _value = State(initialValue: editingRecord?.value ?? 0)
            _secondaryValue = State(initialValue: editingRecord?.secondaryValue ?? 0)
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
                        HStack {
                            Text(type.valueLabel)
                            Spacer()
                            TextField("Value", value: $value, formatter: NumberFormatter())
                                .multilineTextAlignment(.trailing)
                                .keyboardType(.decimalPad)
                            Text(editingRecord?.unit ?? (type == .bloodPressure ? "mmHg" : type == .weight ? "kg" : type == .steps ? "步" : ""))
                        }
                        
                        if type.needsSecondaryValue {
                            HStack {
                                Text(type == .bloodPressure ? "舒张压" : "")
                                Spacer()
                                TextField("Value", value: $secondaryValue, formatter: NumberFormatter())
                                    .multilineTextAlignment(.trailing)
                                    .keyboardType(.decimalPad)
                                Text(editingRecord?.unit ?? (type == .bloodPressure ? "mmHg" : type == .weight ? "kg" : type == .steps ? "步" : ""))
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
                        // Validate and constrain values
                        if type == .sleep {
                            value = Double(min(max(Int(value), 0), 23))
                            secondaryValue = Double(min(max(Int(secondaryValue), 0), 59))
                        }
                        saveRecord()
                        isPresented = false
                    }
                }
            }
        }
    }
    
    private func saveRecord() {
        let finalValue = value
        
        if let editingRecord = editingRecord {
            let updatedRecord = HealthRecord(
                id: editingRecord.id,
                date: date,
                type: type,
                value: finalValue,
                secondaryValue: type == .bloodPressure ? secondaryValue : (type == .sleep ? secondaryValue : nil),
                unit: editingRecord.unit,
                note: note
            )
            healthStore.updateHealthRecord(updatedRecord)
        } else {
            let newRecord = HealthRecord(
                id: UUID(),
                date: date,
                type: type,
                value: finalValue,
                secondaryValue: type == .bloodPressure ? secondaryValue : (type == .sleep ? secondaryValue : nil),
                unit: type == .bloodPressure ? "mmHg" : type == .weight ? "kg" : type == .sleep ? "小时" : type == .steps ? "步" : "",
                note: note
            )
            healthStore.addHealthRecord(newRecord)
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
