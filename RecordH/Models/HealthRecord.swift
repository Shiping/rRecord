import Foundation
import HealthKit

struct HealthRecord: Identifiable, Codable {
    let id: UUID
    let metric: HealthMetric
    let value: Double
    let date: Date
    
    enum CodingKeys: String, CodingKey {
        case id, metric, value, date
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        // First decode non-date properties
        id = try container.decode(UUID.self, forKey: .id)
        metric = try container.decode(HealthMetric.self, forKey: .metric)
        value = try container.decode(Double.self, forKey: .value)
        
        // Decode and validate date
        let now = Date()
        let fiveYearsAgo = Calendar.current.date(byAdding: .year, value: -5, to: now) ?? now
        let oneHourAhead = Calendar.current.date(byAdding: .hour, value: 1, to: now) ?? now
        
        let decodedDate: Date
        if let timestamp = try? container.decode(TimeInterval.self, forKey: .date) {
            decodedDate = Date(timeIntervalSince1970: timestamp)
        } else if let dateString = try? container.decode(String.self, forKey: .date),
                  let parsedDate = DateFormatter.date(from: dateString) {
            decodedDate = parsedDate
        } else {
            throw DecodingError.dataCorruptedError(forKey: .date, in: container, debugDescription: "无法解析记录日期格式")
        }
        
        // Validate date range - allow an hour into the future for time zone differences
        if decodedDate < fiveYearsAgo || decodedDate > oneHourAhead {
            throw DecodingError.dataCorruptedError(forKey: .date, in: container, debugDescription: "记录日期超出合理范围")
        }
        
        // Set the date only after validation
        date = decodedDate
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(metric, forKey: .metric)
        try container.encode(value, forKey: .value)
        
        // Store as timestamp for consistent encoding
        try container.encode(date.timeIntervalSince1970, forKey: .date)
    }
    
    init(id: UUID = UUID(), metric: HealthMetric, value: Double, date: Date = Date()) {
        self.id = id
        self.metric = metric
        self.value = value
        self.date = date
    }
    
    init?(sample: HKSample, metric: HealthMetric) {
        guard metric.hkType != nil else { return nil }
        
        self.id = UUID()
        self.metric = metric
        self.date = sample.startDate
        
        // Handle different sample types
        if let quantitySample = sample as? HKQuantitySample {
            let unit: HKUnit
            switch metric {
            case .bmi:
                unit = .count()
            case .bodyMass:
                unit = .gramUnit(with: .kilo)
            case .bodyFat:
                unit = .percent()
            case .bloodGlucose:
                unit = HKUnit(from: "mmol/L")
            case .bloodPressureSystolic, .bloodPressureDiastolic:
                unit = .millimeterOfMercury()
            case .uricAcid:
                unit = HKUnit(from: "mg/dL")
            case .stepCount:
                unit = .count()
            case .flightsClimbed:
                unit = .count()
            case .sleepHours:
                unit = .hour()
            case .activeEnergy:
                unit = .kilocalorie()
            }
            self.value = quantitySample.quantity.doubleValue(for: unit)
        } else if let categorySample = sample as? HKCategorySample {
            switch metric {
            case .sleepHours:
                // Convert sleep analysis duration to hours
                let duration = categorySample.endDate.timeIntervalSince(categorySample.startDate)
                self.value = duration / 3600.0 // Convert seconds to hours
            default:
                // For other category types, use the value directly
                self.value = Double(categorySample.value)
            }
        } else {
            return nil
        }
    }
}

// MARK: - Equatable
extension HealthRecord: Equatable {
    static func == (lhs: HealthRecord, rhs: HealthRecord) -> Bool {
        lhs.id == rhs.id
    }
}

// MARK: - Hashable
extension HealthRecord: Hashable {
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}

extension HealthRecord {
    var formattedValue: String {
        let formatter = NumberFormatter()
        formatter.minimumFractionDigits = 0
        formatter.maximumFractionDigits = 1
        
        let valueStr = formatter.string(from: NSNumber(value: value)) ?? "\(value)"
        return "\(valueStr)\(metric.unit)"
    }
}
