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
                    let leftOffset: CGFloat = -10 // 增加左偏移量
                    
                    let points = values.enumerated().map { index, value in
                        CGPoint(
                            x: leftOffset + CGFloat(index) * stepX,
                            y: geometry.size.height - CGFloat(value - minValue) * stepY
                        )
                    }
                    
                    path.move(to: points[0])
                    
                    // 使用三次贝塞尔曲线创建更平滑的路径
                    for i in 0..<points.count - 1 {
                        let current = points[i]
                        let next = points[i + 1]
                        
                        let controlPoint1 = CGPoint(
                            x: current.x + (next.x - current.x) * 0.5,
                            y: current.y
                        )
                        let controlPoint2 = CGPoint(
                            x: next.x - (next.x - current.x) * 0.5,
                            y: next.y
                        )
                        
                        path.addCurve(to: next, control1: controlPoint1, control2: controlPoint2)
                    }
                }
                .stroke(accentColor, lineWidth: 3)
            }
        } else {
            EmptyView()
        }
    }
}
