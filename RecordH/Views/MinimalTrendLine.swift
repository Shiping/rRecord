import SwiftUI

struct MinimalTrendLine: View {
    let values: [Double]
    let accentColor: Color
    
    var body: some View {
        // 确保至少有两个点才显示趋势线
        if values.count >= 2 {
            GeometryReader { geometry in
                Path { path in
                    let maxValue = values.max() ?? 0
                    let minValue = values.min() ?? 0
                    let range = maxValue - minValue
                    
                    let stepX = geometry.size.width / CGFloat(values.count - 1)
                    let stepY = range > 0 ? geometry.size.height / CGFloat(range) : 0
                    
                    path.move(to: CGPoint(
                        x: 0,
                        y: geometry.size.height - CGFloat(values[0] - minValue) * stepY
                    ))
                    
                    for index in 1..<values.count {
                        path.addLine(to: CGPoint(
                            x: CGFloat(index) * stepX,
                            y: geometry.size.height - CGFloat(values[index] - minValue) * stepY
                        ))
                    }
                }
                .stroke(accentColor, lineWidth: 1)
            }
        } else {
            EmptyView()
        }
    }
}
