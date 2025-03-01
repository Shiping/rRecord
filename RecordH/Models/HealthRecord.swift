import Foundation
import HealthKit

public struct HealthRecord: Codable, Identifiable {
    public let id: UUID
    public let metric: HealthMetric
    public let value: Double
    public let date: Date
    public let note: String?
    
    public init(id: UUID = UUID(), metric: HealthMetric, value: Double, date: Date = Date(), note: String? = nil) {
        self.id = id
        self.metric = metric
        self.value = value
        self.date = date
        self.note = note
    }
    
    init?(sample: HKSample, metric: HealthMetric) {
        guard let quantitySample = sample as? HKQuantitySample else { return nil }
        self.id = sample.uuid
        self.metric = metric
        self.value = quantitySample.quantity.doubleValue(for: metric.unit)
        self.date = sample.startDate
        self.note = nil
    }
    
    public var formattedValue: String {
        let formatter = NumberFormatter()
        formatter.maximumFractionDigits = 1
        formatter.minimumFractionDigits = 1
        let formattedNumber = formatter.string(from: NSNumber(value: value)) ?? "\(value)"
        switch metric {
        case .bmi: return formattedNumber
        case .bodyMass: return "\(formattedNumber)kg"
        case .bodyFat: return "\(formattedNumber)%"
        case .bloodGlucose: return "\(formattedNumber)mmol/L"
        case .bloodPressureSystolic, .bloodPressureDiastolic: return "\(formattedNumber)mmHg"
        case .uricAcid: return "\(formattedNumber)mg/dL"
        case .stepCount: return "\(formattedNumber)步"
        case .flightsClimbed: return "\(formattedNumber)层"
        case .sleepHours: return "\(formattedNumber)小时"
        case .activeEnergy: return "\(formattedNumber)千卡"
        case .heartRate: return "\(formattedNumber)次/分"
        case .bodyTemperature: return "\(formattedNumber)°C"
        case .height: return "\(formattedNumber)m"
        }
    }
}
