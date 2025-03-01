import Foundation
import HealthKit

public enum HealthMetric: String, Codable, CaseIterable, Sendable {
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
    case heartRate = "心率"
    case bodyTemperature = "体温"
    case height = "身高"
}

// Extension to handle Identifiable separately from the main enum
extension HealthMetric: Identifiable {
    public var id: String { rawValue }
}

// Extension for unit handling
public extension HealthMetric {
    var name: String { rawValue }
    
    var unit: HKUnit {
        switch self {
        case .bmi:
            return HKUnit.count()
        case .bodyMass:
            return HKUnit.gramUnit(with: .kilo) // kg
        case .bodyFat:
            return HKUnit.percent() // %
        case .bloodGlucose:
            return HKUnit.moleUnit(with: .milli, molarMass: HKUnitMolarMassBloodGlucose).unitDivided(by: HKUnit.liter()) // mmol/L
        case .bloodPressureSystolic, .bloodPressureDiastolic:
            return HKUnit.millimeterOfMercury() // mmHg
        case .uricAcid:
            return HKUnit(from: "mg/dL") // mg/dL
        case .stepCount:
            return HKUnit.count() // steps
        case .flightsClimbed:
            return HKUnit.count() // count
        case .sleepHours:
            return HKUnit.hour() // hours
        case .activeEnergy:
            return HKUnit.kilocalorie() // kcal
        case .heartRate:
            return HKUnit(from: "count/min") // BPM
        case .bodyTemperature:
            return HKUnit.degreeCelsius() // °C
        case .height:
            return HKUnit.meter() // m
        }
    }
    
    var unitString: String {
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
            return "h"
        case .activeEnergy:
            return "kcal"
        case .heartRate:
            return "BPM"
        case .bodyTemperature:
            return "°C"
        case .height:
            return "m"
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
        case .heartRate:
            return .quantityType(forIdentifier: .heartRate)
        case .bodyTemperature:
            return .quantityType(forIdentifier: .bodyTemperature)
        case .height:
            return .quantityType(forIdentifier: .height)
        }
    }
}
