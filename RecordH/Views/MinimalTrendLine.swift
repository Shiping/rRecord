import SwiftUI

struct MinimalTrendLine: View {
    let records: [HealthRecord]
    let height: CGFloat
    @Environment(\.theme) var theme
    
    init(records: [HealthRecord], height: CGFloat = 50) {
        self.records = records.sorted { $0.date < $1.date }
        self.height = height
    }
    
    var body: some View {
        if records.isEmpty {
            EmptyTrendView(height: height)
        } else {
            GeometryReader { geometry in
                TrendPath(records: records)
                    .stroke(theme.chartLineColor, lineWidth: 2)
                    .frame(height: height)
            }
            .frame(height: height)
        }
    }
}

private struct TrendPath: Shape, @unchecked Sendable {
    let records: [HealthRecord]
    
    func path(in rect: CGRect) -> Path {
        guard !records.isEmpty else { return Path() }
        
        var path = Path()
        let values = records.map(\.value)
        let maxY = values.max() ?? 0
        let minY = values.min() ?? 0
        let range = maxY - minY
        
        let step = rect.width / CGFloat(records.count - 1)
        let scale = rect.height / CGFloat(range > 0 ? range : 1)
        
        var x: CGFloat = 0
        
        for (index, record) in records.enumerated() {
            let y = rect.height - CGFloat(record.value - minY) * scale
            
            if index == 0 {
                path.move(to: CGPoint(x: x, y: y))
            } else {
                path.addLine(to: CGPoint(x: x, y: y))
            }
            
            x += step
        }
        
        return path
    }
}

private struct EmptyTrendView: View {
    let height: CGFloat
    @Environment(\.theme) var theme
    
    var body: some View {
        Path { path in
            path.move(to: CGPoint(x: 0, y: height/2))
            path.addLine(to: CGPoint(x: 100, y: height/2))
        }
        .stroke(theme.chartGridColor, style: StrokeStyle(lineWidth: 1, dash: [5]))
        .frame(height: height)
    }
}

#Preview {
    VStack(spacing: 20) {
        // Empty trend
        MinimalTrendLine(records: [], height: 50)
            .padding()
            .background(Color.gray.opacity(0.1))
        
        // Sample trend
        MinimalTrendLine(
            records: [
                HealthRecord(metric: .bodyMass, value: 70, date: Date().addingTimeInterval(-86400 * 4)),
                HealthRecord(metric: .bodyMass, value: 71, date: Date().addingTimeInterval(-86400 * 3)),
                HealthRecord(metric: .bodyMass, value: 70.5, date: Date().addingTimeInterval(-86400 * 2)),
                HealthRecord(metric: .bodyMass, value: 70.8, date: Date().addingTimeInterval(-86400)),
                HealthRecord(metric: .bodyMass, value: 70.2, date: Date())
            ],
            height: 50
        )
        .padding()
        .background(Color.gray.opacity(0.1))
    }
    .padding()
}
