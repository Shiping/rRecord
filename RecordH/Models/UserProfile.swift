import Foundation

enum Gender: String, Codable {
    case male = "男"
    case female = "女"
    case other = "其他"
}

struct UserProfile: Codable {
    var id: UUID
    var gender: Gender
    var birthday: Date
    var height: Double?
    var location: String?
    var lastUpdated: Date
    
    enum CodingKeys: String, CodingKey {
        case id, gender, birthday, height, location, lastUpdated
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        // First decode non-date properties
        id = try container.decode(UUID.self, forKey: .id)
        gender = try container.decode(Gender.self, forKey: .gender)
        height = try container.decodeIfPresent(Double.self, forKey: .height)
        location = try container.decodeIfPresent(String.self, forKey: .location)
        
        // Decode and validate birthday
        let now = Date()
        let hundredYearsAgo = Calendar.current.date(byAdding: .year, value: -100, to: now) ?? now
        
        let decodedBirthday: Date
        if let timestamp = try? container.decode(TimeInterval.self, forKey: .birthday) {
            decodedBirthday = Date(timeIntervalSince1970: timestamp)
        } else if let dateString = try? container.decode(String.self, forKey: .birthday),
                  let parsedDate = DateFormatter.date(from: dateString) {
            decodedBirthday = parsedDate
        } else {
            throw DecodingError.dataCorruptedError(forKey: .birthday, in: container, debugDescription: "无法解析出生日期格式")
        }
        
        // Validate birthday range
        if decodedBirthday < hundredYearsAgo || decodedBirthday > now {
            throw DecodingError.dataCorruptedError(forKey: .birthday, in: container, debugDescription: "出生日期超出合理范围")
        }
        birthday = decodedBirthday
        
        // Decode and validate lastUpdated with default to current date
        let decodedLastUpdated: Date
        if let timestamp = try? container.decode(TimeInterval.self, forKey: .lastUpdated) {
            decodedLastUpdated = Date(timeIntervalSince1970: timestamp)
        } else if let dateString = try? container.decode(String.self, forKey: .lastUpdated),
                  let parsedDate = DateFormatter.date(from: dateString) {
            decodedLastUpdated = parsedDate
        } else {
            decodedLastUpdated = now // Default to current date if not available
        }
        
        // Validate lastUpdated is not in future
        if decodedLastUpdated > now {
            throw DecodingError.dataCorruptedError(forKey: .lastUpdated, in: container, debugDescription: "更新时间不能在未来")
        }
        lastUpdated = decodedLastUpdated
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(gender, forKey: .gender)
        try container.encodeIfPresent(height, forKey: .height)
        try container.encodeIfPresent(location, forKey: .location)
        
        // Store as timestamps for consistent encoding
        try container.encode(birthday.timeIntervalSince1970, forKey: .birthday)
        try container.encode(lastUpdated.timeIntervalSince1970, forKey: .lastUpdated)
    }
    
    init(id: UUID = UUID(), 
         gender: Gender, 
         birthday: Date, 
         height: Double? = nil,
         location: String? = nil,
         lastUpdated: Date = Date()) {
        self.id = id
        self.gender = gender
        self.birthday = birthday
        self.height = height
        self.location = location
        self.lastUpdated = lastUpdated
    }
    
    var age: Int {
        let calendar = Calendar.current
        let components = calendar.dateComponents([.year], from: birthday, to: Date())
        return components.year ?? 0
    }
    
    mutating func update(gender: Gender? = nil, 
                        birthday: Date? = nil, 
                        height: Double? = nil,
                        location: String? = nil) {
        if let gender = gender {
            self.gender = gender
        }
        if let birthday = birthday {
            self.birthday = birthday
        }
        if let height = height {
            self.height = height
        }
        if let location = location {
            self.location = location
        }
        self.lastUpdated = Date()
    }
}

extension UserProfile {
    static var sample: UserProfile {
        UserProfile(
            gender: .male,
            birthday: Calendar.current.date(byAdding: .year, value: -30, to: Date()) ?? Date(),
            height: 175.0,
            location: "里水松涛" // Add sample location
        )
    }
}
