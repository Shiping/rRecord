import Foundation

struct UserProfile: Codable {
    var height: Double
    var birthDate: Date
    var gender: Gender
    var name: String
    
    enum Gender: String, Codable {
        case male
        case female
        case other
    }
}

struct HealthRecord: Identifiable, Codable {
    let id: UUID
    let date: Date
    let type: RecordType
    let value: Double
    let secondaryValue: Double? // For blood pressure's diastolic value
    let unit: String
    var note: String?
    
    enum RecordType: String, Codable, CaseIterable {
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
        
        var normalRange: (min: Double?, max: Double?) {
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
                return (10000, nil) // 最小步数10000，无上限
            case .sleep:
                return (6, 8) // 6-8小时
            case .flightsClimbed:
                return (10, nil) // 每日建议至少10层
            case .activeEnergy:
                return (150, nil) // 最低150千卡
            case .restingEnergy:
                return (1200, 2400) // 基础代谢范围
            case .heartRate:
                return (60, 100) // 正常心率范围
            case .distance:
                return (3, nil) // 建议每天步行3公里以上
            }
        }
        
        var secondaryNormalRange: (min: Double?, max: Double?)? {
            switch self {
            case .bloodPressure:
                return (60, 80) // Diastolic
            default:
                return nil
            }
        }
        
        var unit: String {
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
            }
        }
        
        var displayName: String {
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
            }
        }
        
        var needsSecondaryValue: Bool {
            self == .bloodPressure
        }
        
        var valueLabel: String {
            switch self {
            case .bloodPressure: return "收缩压"
            default: return displayName
            }
        }
        
        var secondaryValueLabel: String? {
            switch self {
            case .bloodPressure: return "舒张压"
            default: return nil
            }
        }
    }
}

struct DailyNote: Identifiable, Codable {
    let id: UUID
    let date: Date
    var content: String
    var tags: [String]
}
