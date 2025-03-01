import SwiftUI

struct MetricCard: View {
    let metric: HealthMetric
    let record: HealthRecord?
    @Environment(\.theme) var theme
    
    private var records: [HealthRecord] {
        guard let record = record else { return [] }
        return [record]
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(metric.name)
                .font(.headline)
                .foregroundColor(theme.textColor)
            
            if let record = record {
                Text(record.formattedValue)
                    .font(.title2)
                    .foregroundColor(theme.accentColor)
                
                MinimalTrendLine(records: records)
                    .frame(height: 30)
            } else {
                Text("暂无数据")
                    .font(.subheadline)
                    .foregroundColor(theme.secondaryTextColor)
                
                MinimalTrendLine(records: [])
                    .frame(height: 30)
            }
        }
        .padding()
        .background(theme.cardBackground)
        .cornerRadius(12)
    }
}
