import Foundation

public struct UserProfile: Codable {
    public var height: Double
    public var birthDate: Date
    public var gender: Gender
    public var name: String
    public var aiSettings: [AIConfiguration]
    public var selectedAIConfigurationId: UUID? // 添加选中的 AI 配置 ID
    
    public init(height: Double, birthDate: Date, gender: Gender, name: String, aiSettings: [AIConfiguration] = [AIConfiguration(name: "默认配置", deepseekApiKey: "", deepseekBaseURL: "https://api.deepseek.com/v1", deepseekModel: "deepseek-chat", enabled: false)]) {
        self.height = height
        self.birthDate = birthDate
        self.gender = gender
        self.name = name
        self.aiSettings = aiSettings
        // 设置默认选中第一个配置的 ID
        self.selectedAIConfigurationId = aiSettings.first?.id
    }
    
    public struct AIConfiguration: Codable, Identifiable {
        public var id: UUID = UUID()
        public let name: String
        public var deepseekApiKey: String
        public var deepseekBaseURL: String
        public var deepseekModel: String
        public var enabled: Bool
        
        public init(name: String, deepseekApiKey: String = "",
             deepseekBaseURL: String = "https://api.deepseek.com/v1",
             deepseekModel: String = "deepseek-chat",
             enabled: Bool = false) {
            self.name = name
            self.deepseekApiKey = deepseekApiKey
            self.deepseekBaseURL = deepseekBaseURL
            self.deepseekModel = deepseekModel
            self.enabled = enabled
        }
    }
    
    public enum Gender: String, Codable {
        case male
        case female
        case other
    }
}

public struct HealthRecord: Identifiable, Codable {
    public let id: UUID
    public let date: Date
    public let type: RecordType
    public let value: Double
    public var secondaryValue: Double?
    public let unit: String
    public var note: String?
    
    public init(id: UUID = UUID(), date: Date, type: RecordType, value: Double, secondaryValue: Double? = nil, unit: String, note: String? = nil) {
        self.id = id
        self.date = date
        self.type = type
        self.value = value
        self.secondaryValue = secondaryValue
        self.unit = unit
        self.note = note
    }
    
    public enum RecordType: String, Codable, CaseIterable {
        case weight
        case bloodSugar
        case bloodPressure
        case bloodLipids
        case uricAcid
        case steps
        case sleep
        case flightsClimbed
        case activeEnergy
        case restingEnergy
        case heartRate
        case distance
        case bloodOxygen
        case bodyFat
        
        public var normalRange: (min: Double?, max: Double?) {
            switch self {
            case .weight:
                return (18.5, 23.9) // BMI
            case .bloodSugar:
                return (3.9, 6.1)
            case .bloodPressure:
                return (90, 120) // Systolic
            case .bloodLipids:
                return (nil, 5.2)
            case .uricAcid:
                return (150, 420)
            case .steps:
                return (10000, nil)
            case .sleep:
                return (6, 8)
            case .flightsClimbed:
                return (10, nil)
            case .activeEnergy:
                return (150, nil)
            case .restingEnergy:
                return (1200, 2400)
            case .heartRate:
                return (60, 100)
            case .distance:
                return (3, nil)
            case .bloodOxygen:
                return (94, 100)
            case .bodyFat:
                return (10, 25)
            }
        }
        
        public var secondaryNormalRange: (min: Double?, max: Double?)? {
            switch self {
            case .bloodPressure:
                return (60, 80)
            default:
                return nil
            }
        }
        
        public var unit: String {
            switch self {
            case .weight: return "kg"
            case .bloodSugar: return "mmol/L"
            case .bloodPressure: return "mmHg"
            case .bloodLipids: return "mmol/L"
            case .uricAcid: return "μmol/L"
            case .steps: return "步"
            case .sleep: return "小时"
            case .flightsClimbed: return "层"
            case .activeEnergy: return "千卡"
            case .restingEnergy: return "千卡"
            case .heartRate: return "次/分"
            case .distance: return "公里"
            case .bloodOxygen: return "%"
            case .bodyFat: return "%"
            }
        }
        
        public var displayName: String {
            switch self {
            case .weight: return "体重"
            case .bloodSugar: return "血糖"
            case .bloodPressure: return "血压"
            case .bloodLipids: return "血脂"
            case .uricAcid: return "尿酸"
            case .steps: return "步数"
            case .sleep: return "睡眠时间"
            case .flightsClimbed: return "爬楼梯"
            case .activeEnergy: return "活动能量"
            case .restingEnergy: return "基础能量"
            case .heartRate: return "心率"
            case .distance: return "运动距离"
            case .bloodOxygen: return "血氧"
            case .bodyFat: return "体脂率"
            }
        }
        
        public var needsSecondaryValue: Bool {
            self == .bloodPressure
        }
        
        public var valueLabel: String {
            switch self {
            case .bloodPressure: return "收缩压"
            default: return displayName
            }
        }
        
        public var secondaryValueLabel: String? {
            switch self {
            case .bloodPressure: return "舒张压"
            default: return nil
            }
        }
    }
}

public struct DailyNote: Identifiable, Codable {
    public let id: UUID
    public let date: Date
    public var content: String
    public var tags: [String]
    public var category: Category
    
    public enum Category: String, Codable {
        case general
        case aiAdvice
        
        public var displayName: String {
            switch self {
            case .general: return "一般记录"
            case .aiAdvice: return "AI建议"
            }
        }
    }
    
    public init(id: UUID = UUID(), date: Date = Date(), content: String, tags: [String] = [], category: Category = .general) {
        self.id = id
        self.date = date
        self.content = content
        self.tags = tags
        self.category = category
    }
}
