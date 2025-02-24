import Foundation
import HealthKit

enum HealthMetric: String, Codable, CaseIterable, Identifiable {
    case bmi = "BMI"
    case bodyMass = "体重"
    case bodyFat = "体脂率"
    case bloodGlucose = "血糖"
    case bloodPressureSystolic = "收缩压"
    case bloodPressureDiastolic = "舒张压"
    case uricAcid = "尿酸"
    case stepCount = "步数"
    case flightsClimbed = "爬楼"
    case sleepHours = "睡眠"
    case activeEnergy = "活动量"
    
    var id: String { rawValue }
    
    var name: String { rawValue }
    
    var unit: String {
        switch self {
        case .bmi:
            return ""
        case .bodyMass:
            return "kg"
        case .bodyFat:
            return "%"
        case .bloodGlucose:
            return "mmol/L"
        case .bloodPressureSystolic, .bloodPressureDiastolic:
            return "mmHg"
        case .uricAcid:
            return "mg/dL"
        case .stepCount:
            return "步"
        case .flightsClimbed:
            return "层"
        case .sleepHours:
            return "小时"
        case .activeEnergy:
            return "千卡"
        }
    }
    
    var hkType: HKSampleType? {
        switch self {
        case .bmi:
            return .quantityType(forIdentifier: .bodyMassIndex)
        case .bodyMass:
            return .quantityType(forIdentifier: .bodyMass)
        case .bodyFat:
            return .quantityType(forIdentifier: .bodyFatPercentage)
        case .bloodGlucose:
            return .quantityType(forIdentifier: .bloodGlucose)
        case .bloodPressureSystolic:
            return .quantityType(forIdentifier: .bloodPressureSystolic)
        case .bloodPressureDiastolic:
            return .quantityType(forIdentifier: .bloodPressureDiastolic)
        case .uricAcid:
            return nil // No HKQuantityType for uric acid
        case .stepCount:
            return .quantityType(forIdentifier: .stepCount)
        case .flightsClimbed:
            return .quantityType(forIdentifier: .flightsClimbed)
        case .sleepHours:
            return .categoryType(forIdentifier: .sleepAnalysis)
        case .activeEnergy:
            return .quantityType(forIdentifier: .activeEnergyBurned)
        }
    }
}
