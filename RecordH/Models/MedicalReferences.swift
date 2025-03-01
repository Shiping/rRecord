import Foundation

public struct MedicalReference: Identifiable {
    public let id = UUID()
    public let title: String
    public let description: String
    public let source: String
    public let url: URL?
}

public enum MedicalReferences {
    public static let references: [MedicalReference] = [
        MedicalReference(
            title: "血压测量",
            description: "正常血压范围：收缩压90-140mmHg，舒张压60-90mmHg。建议每日固定时间测量。",
            source: "中国高血压防治指南",
            url: URL(string: "http://www.nhc.gov.cn")
        ),
        MedicalReference(
            title: "血糖管理",
            description: "空腹血糖正常范围：3.9-6.1mmol/L。餐后2小时血糖应低于7.8mmol/L。",
            source: "中国2型糖尿病防治指南",
            url: URL(string: "http://www.diabetes.org.cn")
        ),
        MedicalReference(
            title: "体重指数(BMI)",
            description: "BMI = 体重(kg) / 身高²(m²)。正常范围：18.5-23.9。",
            source: "中国成人超重和肥胖预防控制指南",
            url: URL(string: "http://www.cma.org.cn")
        ),
        MedicalReference(
            title: "运动建议",
            description: "每周进行150分钟中等强度或75分钟高强度有氧运动。每天步行8000-10000步。",
            source: "中国居民身体活动指南",
            url: URL(string: "http://www.sport.gov.cn")
        ),
        MedicalReference(
            title: "睡眠指导",
            description: "成年人每天应保证7-9小时睡眠。建议保持规律的作息时间。",
            source: "中国居民睡眠指南",
            url: URL(string: "http://www.sleep.org.cn")
        )
    ]
    
    public static func referencesFor(metric: HealthMetric) -> [MedicalReference] {
        switch metric {
        case .bloodPressureSystolic, .bloodPressureDiastolic:
            return [references[0]]
        case .bloodGlucose:
            return [references[1]]
        case .bmi, .bodyMass:
            return [references[2]]
        case .stepCount, .flightsClimbed, .activeEnergy:
            return [references[3]]
        case .sleepHours:
            return [references[4]]
        default:
            return []
        }
    }
}
