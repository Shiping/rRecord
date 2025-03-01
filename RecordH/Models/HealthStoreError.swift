import Foundation

public enum HealthStoreError: LocalizedError {
    // Authorization Errors
    case healthKitNotAvailable
    case authorizationFailed(NSError)
    case unauthorized
    
    // Data Access Errors 
    case unsupportedMetric
    case unsupportedType
    case dataNotAvailable
    case fetchFailed(Error)
    
    // Data Management Errors
    case saveFailed(Error)
    case loadFailed(Error)
    case dataCorrupted(String)
    
    public var errorDescription: String? {
        switch self {
        // Authorization Errors
        case .healthKitNotAvailable:
            return "此设备不支持HealthKit"
        case .authorizationFailed(let error):
            return "健康数据授权失败：\(error.localizedDescription)"
        case .unauthorized:
            return "未获得健康数据访问权限"
            
        // Data Access Errors
        case .unsupportedMetric:
            return "不支持的健康指标"
        case .unsupportedType:
            return "不支持的数据类型"
        case .dataNotAvailable:
            return "数据不可用"
        case .fetchFailed(let error):
            return "获取数据失败：\(error.localizedDescription)"
            
        // Data Management Errors
        case .saveFailed(let error):
            return "保存数据失败：\(error.localizedDescription)"
        case .loadFailed(let error):
            return "加载数据失败：\(error.localizedDescription)"
        case .dataCorrupted(let details):
            return "数据损坏：\(details)"
        }
    }
    
    public var advice: String {
        switch self {
        // Authorization Errors
        case .healthKitNotAvailable:
            return "请检查设备是否支持HealthKit。"
        case .authorizationFailed:
            return "请在设置中检查并授权应用访问健康数据。"
        case .unauthorized:
            return "请在系统设置中允许应用访问健康数据。"
            
        // Data Access Errors
        case .unsupportedMetric:
            return "当前设备或系统版本不支持此健康指标。"
        case .unsupportedType:
            return "此设备可能不支持该类型的健康数据。"
        case .dataNotAvailable:
            return "请确保已在健康App中录入相关数据。"
        case .fetchFailed:
            return "请检查网络连接和权限设置后重试。"
            
        // Data Management Errors
        case .saveFailed:
            return "请重试，如果问题持续存在，请尝试重启应用。"
        case .loadFailed:
            return "可以尝试清除数据并重新同步。"
        case .dataCorrupted:
            return "建议清除数据并重新导入。"
        }
    }
}
