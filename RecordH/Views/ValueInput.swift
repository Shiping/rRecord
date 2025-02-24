import SwiftUI

struct ValueInput: View {
    let metric: HealthMetric
    @Binding var value: Double
    @Environment(\.theme) var theme
    
    private let formatter: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.maximumFractionDigits = 1
        formatter.minimumFractionDigits = 1
        return formatter
    }()
    
    var body: some View {
        HStack {
            TextField("输入\(metric.name)", value: $value, formatter: formatter)
                .keyboardType(.decimalPad)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .multilineTextAlignment(.trailing)
            
            Text(metric.unit)
                .foregroundColor(theme.secondaryTextColor)
        }
        .padding(.horizontal)
    }
}

struct ValueInputWithValidation: View {
    let metric: HealthMetric
    @Binding var value: Double
    @Binding var isValid: Bool
    @Environment(\.theme) var theme
    
    private let range: ClosedRange<Double>
    
    init(metric: HealthMetric, value: Binding<Double>, isValid: Binding<Bool>) {
        self.metric = metric
        self._value = value
        self._isValid = isValid
        
        // Define reasonable ranges for each metric
        switch metric {
        case .bmi:
            range = 10...50
        case .bodyMass:
            range = 20...200
        case .bodyFat:
            range = 1...50
        case .bloodGlucose:
            range = 2...20
        case .bloodPressureSystolic:
            range = 70...200
        case .bloodPressureDiastolic:
            range = 40...130
        case .uricAcid:
            range = 2...10
        case .stepCount:
            range = 0...100000
        case .flightsClimbed:
            range = 0...1000
        case .sleepHours:
            range = 0...24
        case .activeEnergy:
            range = 0...10000
        }
    }
    
    var body: some View {
        VStack(spacing: 4) {
            ValueInput(metric: metric, value: $value)
            
            if !isValid {
                Text("有效范围: \(range.lowerBound.formatted()) - \(range.upperBound.formatted()) \(metric.unit)")
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
