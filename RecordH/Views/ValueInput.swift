import SwiftUI

public struct ValueInput: View {
    public let metric: HealthMetric
    @Binding public var value: Double
    @Environment(\.theme) var theme
    
    public init(metric: HealthMetric, value: Binding<Double>) {
        self.metric = metric
        self._value = value
    }
    
    private let formatter: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.maximumFractionDigits = 1
        formatter.minimumFractionDigits = 1
        return formatter
    }()
    
    public var body: some View {
        HStack {
            TextField("输入\(metric.name)", value: $value, formatter: formatter)
                .keyboardType(.decimalPad)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .multilineTextAlignment(.trailing)
            
            Text(metric.unitString)
                .foregroundColor(theme.secondaryTextColor)
        }
        .padding(.horizontal)
    }
}

public struct ValueInputWithValidation: View {
    public let metric: HealthMetric
    @Binding public var value: Double
    @Binding public var isValid: Bool
    @Environment(\.theme) var theme
    
    private var range: ClosedRange<Double> {
        switch metric {
        case .bmi:
            return 10...50
        case .bodyMass:
            return 20...200
        case .bodyFat:
            return 1...50
        case .bloodGlucose:
            return 2...20
        case .bloodPressureSystolic:
            return 70...200
        case .bloodPressureDiastolic:
            return 40...130
        case .uricAcid:
            return 2...10
        case .stepCount:
            return 0...100000
        case .flightsClimbed:
            return 0...1000
        case .sleepHours:
            return 0...24
        case .activeEnergy:
            return 0...10000
        case .heartRate:
            return 30...220
        case .bodyTemperature:
            return 35...42
        case .height:
            return 50...250
        }
    }
    
    public init(metric: HealthMetric, value: Binding<Double>, isValid: Binding<Bool>) {
        self.metric = metric
        self._value = value
        self._isValid = isValid
    }
    
    public var body: some View {
        VStack(spacing: 4) {
            ValueInput(metric: metric, value: $value)
            
            if !isValid {
                Text("有效范围: \(range.lowerBound.formatted()) - \(range.upperBound.formatted()) \(metric.unitString)")
                    .font(.caption)
                    .foregroundColor(theme.badColor)
            }
        }
        .onChange(of: value) { oldValue, newValue in
            isValid = range.contains(newValue)
        }
    }
}

#Preview {
    VStack(spacing: 20) {
        // Simple value input
        ValueInput(
            metric: .bodyMass,
            value: .constant(70.5)
        )
        
        // Value input with validation
        ValueInputWithValidation(
            metric: .bodyMass,
            value: .constant(70.5),
            isValid: .constant(true)
        )
        
        // Invalid value
        ValueInputWithValidation(
            metric: .bodyMass,
            value: .constant(500),
            isValid: .constant(false)
        )
    }
    .padding()
}
