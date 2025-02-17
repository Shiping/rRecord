import Foundation

struct HealthMetricReference {
    let source: String
    let organization: String
    let year: String
    let url: String
    let normalRange: String
}

struct MedicalReferences {
    static let references: [HealthRecord.RecordType: HealthMetricReference] = [
        .steps: HealthMetricReference(
            source: "Physical Activity Guidelines for Americans, 2nd Edition",
            organization: "U.S. Department of Health and Human Services",
            year: "2023",
            url: "https://health.gov/paguidelines",
            normalRange: "7,000-10,000 steps/day for healthy adults"
        ),
        .sleep: HealthMetricReference(
            source: "How Much Sleep Do I Need?",
            organization: "CDC (Centers for Disease Control and Prevention)",
            year: "2023",
            url: "https://www.cdc.gov/sleep/about_sleep/how_much_sleep.html",
            normalRange: "7-9 hours for adults aged 18-64"
        ),
        .heartRate: HealthMetricReference(
            source: "Target Heart Rates Chart",
            organization: "American Heart Association",
            year: "2023",
            url: "https://www.heart.org/en/healthy-living/fitness/fitness-basics/target-heart-rates",
            normalRange: "60-100 bpm at rest for adults"
        ),
        .bloodOxygen: HealthMetricReference(
            source: "Pulse Oximetry",
            organization: "WHO (World Health Organization)",
            year: "2023",
            url: "https://www.who.int/publications",
            normalRange: "95-100% for healthy adults"
        ),
        .activeEnergy: HealthMetricReference(
            source: "Physical Activity Guidelines for Americans, 2nd Edition",
            organization: "U.S. Department of Health and Human Services",
            year: "2023",
            url: "https://health.gov/paguidelines",
            normalRange: "150-300 minutes of moderate activity per week"
        ),
        .bodyFat: HealthMetricReference(
            source: "Body Composition",
            organization: "American Council on Exercise",
            year: "2023",
            url: "https://www.acefitness.org/resources/everyone/blog/112/what-are-the-guidelines-for-percentage-of-body-fat-loss/",
            normalRange: "Men: 14-24%, Women: 21-31%"
        ),
        .distance: HealthMetricReference(
            source: "Physical Activity Guidelines for Americans, 2nd Edition",
            organization: "U.S. Department of Health and Human Services",
            year: "2023",
            url: "https://health.gov/paguidelines",
            normalRange: "3-4 km daily walking for general health"
        ),
        .weight: HealthMetricReference(
            source: "BMI Guidelines",
            organization: "WHO (World Health Organization)",
            year: "2023",
            url: "https://www.who.int/news-room/fact-sheets/detail/obesity-and-overweight",
            normalRange: "BMI 18.5-24.9 kg/m²"
        ),
        .bloodSugar: HealthMetricReference(
            source: "Standards of Medical Care in Diabetes",
            organization: "American Diabetes Association",
            year: "2023",
            url: "https://diabetesjournals.org/care/issue/46/Supplement_1",
            normalRange: "空腹: 3.9-6.1 mmol/L, 餐后2小时: <7.8 mmol/L"
        ),
        .bloodPressure: HealthMetricReference(
            source: "Guideline for the Prevention, Detection, Evaluation, and Management of High Blood Pressure in Adults",
            organization: "American Heart Association",
            year: "2023",
            url: "https://www.heart.org/en/health-topics/high-blood-pressure/understanding-blood-pressure-readings",
            normalRange: "收缩压: <120 mmHg, 舒张压: <80 mmHg"
        ),
        .bloodLipids: HealthMetricReference(
            source: "Guidelines for Management of Dyslipidemia",
            organization: "American College of Cardiology",
            year: "2023",
            url: "https://www.acc.org/guidelines",
            normalRange: "总胆固醇: <5.2 mmol/L, 甘油三酯: <1.7 mmol/L"
        ),
        .uricAcid: HealthMetricReference(
            source: "Gout and Hyperuricemia Guidelines",
            organization: "American College of Rheumatology",
            year: "2023",
            url: "https://www.rheumatology.org/Practice-Quality/Clinical-Support/Clinical-Practice-Guidelines",
            normalRange: "男性: 149-416 μmol/L, 女性: 89-357 μmol/L"
        )
    ]
    
    static let disclaimer = """
    健康建议免责声明：
    本应用提供的健康指标范围和建议仅供参考，基于公开发表的医学研究和权威机构指南。这些建议可能并不适用于所有人，因为每个人的健康状况都是独特的。

    请注意：
    • 这些数据不构成医疗建议
    • 在开始任何新的健康计划前，请咨询您的医疗保健提供者
    • 如果您有任何健康问题或担忧，请立即就医
    """
}
