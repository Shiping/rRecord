import Foundation

public enum HealthStoreError: Error {
    case notEnabled(String)
    case notInitialized(String)
}
