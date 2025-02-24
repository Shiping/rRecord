import Foundation

struct HealthMetricReference: Codable {
    let lowerBound: Double
    let upperBound: Double
    let unit: String
}

struct MedicalReferences {
    static let references: [HealthMetric: HealthMetricReference] = [
        .bmi: HealthMetricReference(lowerBound: 18.5, upperBound: 24.9, unit: "kg/m2"),
        .bodyMass: HealthMetricReference(lowerBound: 20, upperBound: 200, unit: "kg"),
        .bodyFat: HealthMetricReference(lowerBound: 1, upperBound: 50, unit: "%"),
        .bloodGlucose: HealthMetricReference(lowerBound: 2, upperBound: 20, unit: "mmol/L"),
        .bloodPressureSystolic: HealthMetricReference(lowerBound: 70, upperBound: 200, unit: "mmHg"),
        .bloodPressureDiastolic: HealthMetricReference(lowerBound: 40, upperBound: 130, unit: "mmHg"),
        .uricAcid: HealthMetricReference(lowerBound: 2, upperBound: 10, unit: "mg/dL"),
        .stepCount: HealthMetricReference(lowerBound: 0, upperBound: 100000, unit: "步"),
        .flightsClimbed: HealthMetricReference(lowerBound: 0, upperBound: 1000, unit: "层"),
        .sleepHours: HealthMetricReference(lowerBound: 0, upperBound: 24, unit: "小时"),
        .activeEnergy: HealthMetricReference(lowerBound: 0, upperBound: 10000, unit: "千卡")
    ]
}
