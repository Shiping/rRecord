import Foundation
import SwiftUI

public struct DailyNote: Identifiable, Codable {
    public let id: UUID
    public var date: Date
    public var content: String
    private var healthMetrics: [HealthMetric]
    
    enum CodingKeys: String, CodingKey {
        case id, date, content, healthMetrics
    }
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        id = try container.decode(UUID.self, forKey: .id)
        content = try container.decode(String.self, forKey: .content)
        healthMetrics = try container.decode([HealthMetric].self, forKey: .healthMetrics)
        date = try container.decode(Date.self, forKey: .date)
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(content, forKey: .content)
        try container.encode(healthMetrics, forKey: .healthMetrics)
        try container.encode(date, forKey: .date)
    }
    
    public init(date: Date, content: String, id: UUID = UUID()) {
        self.id = id
        self.date = date
        self.content = content
        self.healthMetrics = []
    }
    
    public init(date: Date, content: String, healthMetrics: [HealthMetric], id: UUID = UUID()) {
        self.id = id
        self.date = date
        self.content = content
        self.healthMetrics = healthMetrics
    }
    
    public var metricNames: [String] {
        return healthMetrics.map(\.rawValue)
    }
    
    public var metrics: [HealthMetric] {
        return healthMetrics
    }
    
    public mutating func addMetric(_ name: String) {
        if let metric = HealthMetric.allCases.first(where: { $0.rawValue == name }) {
            healthMetrics.append(metric)
        }
    }
}
