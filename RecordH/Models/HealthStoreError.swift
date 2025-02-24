import Foundation

enum HealthStoreError: Error, Equatable {
    
    static func == (lhs: HealthStoreError, rhs: HealthStoreError) -> Bool {
        switch (lhs, rhs) {
        case (.healthKitNotAvailable, .healthKitNotAvailable):
            return true
        case (.authorizationFailed(let lError), .authorizationFailed(let rError)):
            return lError.localizedDescription == rError.localizedDescription
        case (.fetchFailed(let lError), .fetchFailed(let rError)):
            return lError.localizedDescription == rError.localizedDescription
        case (.saveFailed(let lError), .saveFailed(let rError)):
            return lError.localizedDescription == rError.localizedDescription
        case (.loadFailed(let lError), .loadFailed(let rError)):
            return lError.localizedDescription == rError.localizedDescription
        case (.dataNotAvailable, .dataNotAvailable):
            return true
        case (.invalidDataFormat, .invalidDataFormat):
            return true
        case (.unknownError, .unknownError):
            return true
        case (.unsupportedType, .unsupportedType):
            return true
        case (.authorizationTimeout, .authorizationTimeout):
            return true
        default:
            return false
        }
    }
    
    case healthKitNotAvailable
    case authorizationFailed(Error)
    case fetchFailed(Error)
    case saveFailed(Error)
    case dataNotAvailable
    case invalidDataFormat
    case unknownError
    case unsupportedType
    case loadFailed(Error) // Add loadFailed case
    case authorizationTimeout
    
    var localizedDescription: String {
        switch self {
        case .healthKitNotAvailable:
            return "HealthKit 不可用，请确认您的设备支持健康数据"
        case .authorizationFailed(let error):
            return "授权失败: \(error.localizedDescription)"
        case .fetchFailed(let error):
            return "数据获取失败: \(error.localizedDescription)"
        case .saveFailed(let error):
            return "数据保存失败: \(error.localizedDescription)"
        case .loadFailed(let error): // Handle loadFailed case
            return "数据加载失败: \(error.localizedDescription)"
        case .dataNotAvailable:
            return "暂无数据"
        case .invalidDataFormat:
            return "数据格式无效"
        case .unknownError:
            return "未知错误"
        case .unsupportedType:
            return "不支持的数据类型"
        case .authorizationTimeout:
            return "授权请求超时"
        }
    }
    
    var advice: String {
        switch self {
        case .healthKitNotAvailable:
            return "请确认您使用的是支持 HealthKit 的 iOS 设备"
        case .authorizationFailed:
            return "请在系统设置中允许应用访问健康数据"
        case .fetchFailed:
            return "请检查网络连接并重试"
        case .saveFailed:
            return "请确保设备有足够的存储空间"
        case .loadFailed: // Handle loadFailed case
            return "请尝试重启应用，如果问题仍然存在，请尝试重新安装应用"
        case .dataNotAvailable:
            return "请先在健康应用中记录相关数据"
        case .invalidDataFormat:
            return "请尝试重新安装应用"
        case .unknownError:
            return "请重启应用或设备后重试"
        case .unsupportedType:
            return "请确保设备支持该类型的健康数据"
        case .authorizationTimeout:
            return "请检查网络连接并尝试重启应用后重试"
        }
    }
}

extension HealthStoreError: Identifiable {
    var id: String {
        switch self {
        case .healthKitNotAvailable:
            return "healthKitNotAvailable"
        case .authorizationFailed(let error):
            return "authorizationFailed:\(error.localizedDescription)"
        case .fetchFailed(let error):
            return "fetchFailed:\(error.localizedDescription)"
        case .saveFailed(let error):
            return "saveFailed:\(error.localizedDescription)"
        case .dataNotAvailable:
            return "dataNotAvailable"
        case .invalidDataFormat:
            return "invalidDataFormat"
        case .unknownError:
            return "unknownError"
        case .unsupportedType:
            return "unsupportedType"
        case .loadFailed: // Add loadFailed case to Identifiable switch
            return "loadFailed"
        case .authorizationTimeout:
            return "authorizationTimeout"
        }
    }
}
