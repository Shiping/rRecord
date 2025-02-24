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
        
        // Initialize all stored properties with safe defaults first
        self.id = try container.decode(UUID.self, forKey: .id)
        self.content = try container.decode(String.self, forKey: .content)
        self.healthMetrics = try container.decode([HealthMetric].self, forKey: .healthMetrics)
        self.date = try Self.decodeAndValidateDate(from: container)
    }
    
    private static func decodeAndValidateDate(from container: KeyedDecodingContainer<CodingKeys>) throws -> Date {
        let now = Date()
        let fiveYearsAgo = Calendar.current.date(byAdding: .year, value: -5, to: now) ?? now
        let oneYearAhead = Calendar.current.date(byAdding: .year, value: 1, to: now) ?? now
        
        if let timestamp = try? container.decode(TimeInterval.self, forKey: .date) {
            let decodedDate = Date(timeIntervalSince1970: timestamp)
            if decodedDate < fiveYearsAgo || decodedDate > oneYearAhead {
                throw DecodingError.dataCorruptedError(
                    forKey: .date,
                    in: container,
                    debugDescription: "日期超出合理范围"
                )
            }
            return decodedDate
        }
        
        if let dateString = try? container.decode(String.self, forKey: .date),
           let parsedDate = DateFormatter.date(from: dateString) {
            if parsedDate < fiveYearsAgo || parsedDate > oneYearAhead {
                throw DecodingError.dataCorruptedError(
                    forKey: .date,
                    in: container,
                    debugDescription: "日期超出合理范围"
                )
            }
            return parsedDate
        }
        
        throw DecodingError.dataCorruptedError(
            forKey: .date,
            in: container,
            debugDescription: "无法解析日期格式"
        )
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(content, forKey: .content)
        try container.encode(healthMetrics, forKey: .healthMetrics)
        try container.encode(date.timeIntervalSince1970, forKey: .date)
    }
    
    public init(date: Date, content: String, id: UUID = UUID()) {
        self.id = id
        self.date = date
        self.content = content
        self.healthMetrics = []
    }
    
    init(date: Date, content: String, healthMetrics: [HealthMetric]) {
        self.id = UUID()
        self.date = date
        self.content = content
        self.healthMetrics = healthMetrics
    }
    
    public func getMetricNames() -> [String] {
        return healthMetrics.map { $0.name }
    }
    
    func getHealthMetrics() -> [HealthMetric] {
        return healthMetrics
    }
    
    public mutating func addMetric(_ metricName: String) {
        if let metric = HealthMetric.allCases.first(where: { $0.name == metricName }) {
            healthMetrics.append(metric)
        }
    }
}
