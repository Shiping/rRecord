import Foundation

extension DateFormatter {
    static let shared = DateFormatter()
    static let iso8601Full = ISO8601DateFormatter()
    
    static let commonFormatters: [DateFormatter] = {
        let formats = [
            "yyyy-MM-dd'T'HH:mm:ssZ",
            "yyyy-MM-dd HH:mm:ss",
            "yyyy/MM/dd HH:mm:ss",
            "yyyy-MM-dd"
        ]
        
        return formats.map { format in
            let formatter = DateFormatter()
            formatter.dateFormat = format
            formatter.locale = Locale(identifier: "en_US_POSIX")
            formatter.timeZone = TimeZone.current
            return formatter
        }
    }()
    
    static func date(from string: String) -> Date? {
        // First try ISO8601
        if let date = iso8601Full.date(from: string) {
            return date
        }
        
        // Then try common formatters
        for formatter in commonFormatters {
            if let date = formatter.date(from: string) {
                return date
            }
        }
        
        return nil
    }
    
    static func string(from date: Date, format: String) -> String {
        shared.dateFormat = format
        shared.locale = Locale(identifier: "en_US_POSIX")
        shared.timeZone = TimeZone.current
        return shared.string(from: date)
    }
}
