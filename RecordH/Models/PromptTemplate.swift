import Foundation

public struct PromptTemplate: Identifiable, Codable {
    public var id = UUID()
    public var name: String
    public var description: String
    public var template: String
    public var applicableMetrics: [HealthMetric]
    public var isDefault: Bool
    
    public init(name: String = "", description: String = "", template: String = "", applicableMetrics: [HealthMetric] = [], isDefault: Bool = false) {
        self.name = name
        self.description = description
        self.template = template
        self.applicableMetrics = applicableMetrics
        self.isDefault = isDefault
    }
}
