import SwiftUI
import HealthKit

enum TimePeriod: String, CaseIterable {
    case week = "本周"
    case month = "本月"
    case year = "今年"
    case all = "所有"
}

struct SingleMetricHistoryView: View {
    let metric: HealthMetric
    let metricRecords: [HealthRecord]
    let aiParameters: [String: String]
    @Environment(\.theme) var theme
    @EnvironmentObject var healthStore: HealthStore // Add this line
    @State private var selectedPeriod: TimePeriod = .week
    @State private var showingAddRecord = false
    @Environment(\.dismiss) private var dismiss
    @State private var isRefreshing = false
    
    private var filteredRecords: [HealthRecord] {
        let calendar = Calendar.current
        let now = Date()
        
        return metricRecords.filter { record in
            switch selectedPeriod {
            case .week:
                return calendar.isDate(record.date, equalTo: now, toGranularity: .weekOfYear)
            case .month:
                return calendar.isDate(record.date, equalTo: now, toGranularity: .month)
            case .year:
                return calendar.isDate(record.date, equalTo: now, toGranularity: .year)
            case .all:
                return true
            }
        }
    }
    
    var body: some View {
        ScrollView {
            LazyVStack(spacing: 20) {
                // Time period picker
                Picker("时间范围", selection: $selectedPeriod) {
                    ForEach(TimePeriod.allCases, id: \.self) { period in
                        Text(period.rawValue).tag(period)
                    }
                }
                .pickerStyle(.segmented)
                .padding()

                // Chart section
                VStack(alignment: .leading) {
                    HStack {
                        Text("趋势图")
                            .font(.headline)
                            .foregroundColor(theme.textColor)
                        Spacer()
                        Button(action: { showingAddRecord = true }) {
                            Image(systemName: "plus.circle.fill")
                                .foregroundColor(theme.accentColor)
                        }
                    }
                    
                    if filteredRecords.isEmpty {
                        Text("暂无数据")
                            .foregroundColor(theme.secondaryTextColor)
                            .padding()
                    } else {
                        LineChartView(records: filteredRecords)
                            .frame(height: 200)
                            .padding(.vertical)
                    }
                }
                .padding()
                .background(theme.secondaryBackgroundColor)
                .cornerRadius(10)
                .padding(.horizontal)
                
                // Records list
                VStack(alignment: .leading) {
                    Text("历史记录")
                        .font(.headline)
                        .foregroundColor(theme.textColor)
                    
                    ForEach(filteredRecords) { record in
                        RecordRow(record: record)
                            .padding(.vertical, 8)
                            .background(theme.backgroundColor)
                            .cornerRadius(8)
                    }
                }
                .padding()
                .background(theme.secondaryBackgroundColor)
                .cornerRadius(10)
                .padding(.horizontal)
                
                // AI Analysis Section
                if !filteredRecords.isEmpty {
                    VStack(alignment: .leading) {
                        HStack {
                            Text("AI分析")
                                .font(.headline)
                            Spacer()
                            NavigationLink(destination: AIConfigView()) {
                                Image(systemName: "gearshape")
                                    .foregroundColor(theme.secondaryTextColor)
                            }
                        }
                        
                        AIChatView(
                            parameters: aiParameters,
                            contextDescription: "这是\(metric.name)的历史数据分析，共\(metricRecords.count)条记录"
                        )
                    }
                    .padding()
                    .background(theme.secondaryBackgroundColor)
                    .cornerRadius(10)
                    .padding(.horizontal)
                }
            }
            .padding(.vertical)
        }
        .navigationTitle(metric.name)
        .background(theme.backgroundColor)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button {
                    showingAddRecord = true
                } label: {
                    Image(systemName: "plus")
                }
            }
        }
        .sheet(isPresented: $showingAddRecord) {
            AddRecordSheet(metric: metric)
                .environmentObject(healthStore)
        }
    }
    
    private func formatValue(_ value: Double) -> String {
        let formatter = NumberFormatter()
        formatter.maximumFractionDigits = 1
        formatter.minimumFractionDigits = 1
        
        let formattedValue = formatter.string(from: NSNumber(value: value)) ?? "\(value)"
        return "\(formattedValue) \(metric.unit)"
    }
    
    private func calculateTrend(_ values: [Double]) -> String? {
        guard values.count >= 2 else { return nil }
        
        let first = values.suffix(5).first ?? values.first!
        let last = values.prefix(5).last ?? values.last!
        
        let change = ((last - first) / first) * 100
        
        if abs(change) < 5 {
            return "保持稳定"
        } else if change > 0 {
            return "呈上升趋势"
        } else {
            return "呈下降趋势"
        }
    }
}

struct LineChartView: View {
    let records: [HealthRecord]
    @Environment(\.theme) var theme
    
    var body: some View {
        if records.isEmpty {
            EmptyView()
        } else {
            GeometryReader { geometry in
                Path { path in
                    let values = records.map(\.value)
                    let maxY = values.max() ?? 0
                    let minY = values.min() ?? 0
                    let range = maxY - minY
                    
                    let step = geometry.size.width / CGFloat(records.count - 1)
                    let scale = geometry.size.height / CGFloat(range)
                    
                    var x: CGFloat = 0
                    
                    for (index, record) in records.enumerated() {
                        let y = geometry.size.height - CGFloat(record.value - minY) * scale
                        
                        if index == 0 {
                            path.move(to: CGPoint(x: x, y: y))
                        } else {
                            path.addLine(to: CGPoint(x: x, y: y))
                        }
                        
                        x += step
                    }
                }
                .stroke(theme.chartLineColor, lineWidth: 2)
            }
        }
    }
}

#Preview {
    NavigationView {
        SingleMetricHistoryView(metric: .bodyMass, metricRecords: [], aiParameters: [:])
            .environmentObject(HealthStore.shared)
    }
}
