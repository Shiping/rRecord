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
        
        var unit: String {
            switch self {
            case .weight: return "kg"
            case .bloodSugar: return "mmol/L"
            case .bloodPressure: return "mmHg"
            case .bloodLipids: return "mmol/L"
            case .uricAcid: return "μmol/L"
            }
        }
        
        var displayName: String {
            switch self {
            case .weight: return "体重"
            case .bloodSugar: return "血糖"
            case .bloodPressure: return "血压"
            case .bloodLipids: return "血脂"
            case .uricAcid: return "尿酸"
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
