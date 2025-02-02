import SwiftUI
import Charts


struct HealthMetricDetailView: View {
    let type: HealthRecord.RecordType
    @ObservedObject var healthStore: HealthStore
    @State private var showingAddRecord = false
    @State private var recordToEdit: HealthRecord? = nil
    
    var records: [HealthRecord] {
        healthStore.getRecords(for: type)
    }
    
    var body: some View {
        List {
            // Chart Section
            ChartSection(records: records, type: type)
                .frame(height: 200)
                .listRowBackground(Theme.cardBackground)
                .listRowInsets(EdgeInsets())
                .padding()
            
            // Records List
            ForEach(records) { record in
                RecordRow(record: record, type: type)
                    .listRowBackground(Theme.cardBackground)
                    .swipeActions(edge: .trailing) {
                        Button(role: .destructive) {
                            healthStore.deleteHealthRecord(record.id)
                        } label: {
                            Label("删除", systemImage: "trash")
                        }
                        
                        Button {
                            editRecord(record)
                        } label: {
                            Label("编辑", systemImage: "pencil")
                        }
                        .tint(.orange)
                    }
            }
        }
        .background(Theme.gradientBackground())
        .navigationTitle(type.displayName)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(action: { showingAddRecord = true }) {
                    Image(systemName: "plus.circle.fill")
                }
            }
        }
        .sheet(isPresented: $showingAddRecord) {
            AddRecordSheet(
                type: type,
                healthStore: healthStore,
                isPresented: $showingAddRecord,
                editingRecord: recordToEdit
            )
        }
    }
    
    private func editRecord(_ record: HealthRecord) {
        recordToEdit = record
        showingAddRecord = true
    }
}

struct ChartSection: View {
    let records: [HealthRecord]
    let type: HealthRecord.RecordType
    
    var body: some View {
        Chart {
            ForEach(records) { record in
                LineMark(
                    x: .value("日期", record.date),
                    y: .value(type.valueLabel, record.value)
                )
                .foregroundStyle(Theme.accent)
                
                PointMark(
                    x: .value("日期", record.date),
                    y: .value(type.valueLabel, record.value)
                )
                .foregroundStyle(Theme.accent)
                
                if type.needsSecondaryValue, let secondaryValue = record.secondaryValue {
                    LineMark(
                        x: .value("日期", record.date),
                        y: .value(type.secondaryValueLabel ?? "", secondaryValue)
                    )
                    .foregroundStyle(Theme.secondaryText)
                    
                    PointMark(
                        x: .value("日期", record.date),
                        y: .value(type.secondaryValueLabel ?? "", secondaryValue)
                    )
                    .foregroundStyle(Theme.secondaryText)
                }
            }
        }
        .chartYAxis {
            AxisMarks(position: .leading) { value in
                AxisValueLabel("\(value.index)")
                AxisGridLine()
            }
        }
        .chartXAxis {
            AxisMarks(values: .stride(by: .day)) { value in
                AxisGridLine()
                AxisValueLabel(format: .dateTime.day().month())
            }
        }
    }
}

struct RecordRow: View {
    let record: HealthRecord
    let type: HealthRecord.RecordType
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            if type.needsSecondaryValue, let diastolic = record.secondaryValue {
                Text("\(String(format: "%.0f/%.0f", record.value, diastolic)) \(record.unit)")
                    .font(.title3)
                    .foregroundColor(Theme.text)
            } else {
                Text("\(String(format: "%.1f", record.value)) \(record.unit)")
                    .font(.title3)
                    .foregroundColor(Theme.text)
            }
            
            Text(record.date.formatted(.dateTime.year().month().day().hour().minute()))
                .font(.subheadline)
                .foregroundColor(Theme.secondaryText)
            
            if let note = record.note {
                Text(note)
                    .font(.body)
                    .foregroundColor(Theme.text)
            }
        }
        .padding(.vertical, 8)
    }
}

struct AddRecordSheet: View {
    let type: HealthRecord.RecordType
    @ObservedObject var healthStore: HealthStore
    @Binding var isPresented: Bool
    var editingRecord: HealthRecord?
    
    @State private var value: String = ""
    @State private var secondaryValue: String = ""
    @State private var note: String = ""
    @State private var selectedDate = Date()
    
    init(type: HealthRecord.RecordType, healthStore: HealthStore, isPresented: Binding<Bool>, editingRecord: HealthRecord? = nil) {
        self.type = type
        self.healthStore = healthStore
        self._isPresented = isPresented
        self.editingRecord = editingRecord
        
        if let record = editingRecord {
            _value = State(initialValue: String(format: "%.1f", record.value))
            _selectedDate = State(initialValue: record.date)
            _note = State(initialValue: record.note ?? "")
            if let secondary = record.secondaryValue {
                _secondaryValue = State(initialValue: String(format: "%.1f", secondary))
            }
        }
    }
    
    private var dateRange: ClosedRange<Date> {
        let calendar = Calendar.current
        let start = calendar.date(byAdding: .year, value: -1, to: Date())!
        let end = Date()
        return start...end
    }
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("记录时间")) {
                    DatePicker(
                        "选择日期时间",
                        selection: $selectedDate,
                        in: dateRange,
                        displayedComponents: [.date, .hourAndMinute]
                    )
                }
                
                Section(header: Text("数值")) {
                    TextField("输入\(type.valueLabel)", text: $value)
                        .keyboardType(.decimalPad)
                    
                    if type.needsSecondaryValue {
                        TextField("输入\(type.secondaryValueLabel ?? "")", text: $secondaryValue)
                            .keyboardType(.decimalPad)
                    }
                }
                
                Section(header: Text("备注")) {
                    TextField("添加备注", text: $note)
                }
            }
            .navigationTitle("添加\(type.displayName)记录")
            .navigationBarItems(
                leading: Button("取消") {
                    isPresented = false
                },
                trailing: Button("保存") {
                    saveRecord()
                }
            )
        }
    }
    
    private func saveRecord() {
        guard let primaryValue = Double(value) else { return }
        let diastolicValue = type.needsSecondaryValue ? Double(secondaryValue) : nil
        
        if type.needsSecondaryValue && diastolicValue == nil {
            return
        }
        
        let record = HealthRecord(
            id: editingRecord?.id ?? UUID(),
            date: selectedDate,
            type: type,
            value: primaryValue,
            secondaryValue: diastolicValue,
            unit: type.unit,
            note: note.isEmpty ? nil : note
        )
        
        if editingRecord != nil {
            healthStore.updateHealthRecord(record)
        } else {
            healthStore.addHealthRecord(record)
        }
        isPresented = false
    }
}

#Preview {
    NavigationView {
        HealthMetricDetailView(type: .weight, healthStore: HealthStore())
    }
}
