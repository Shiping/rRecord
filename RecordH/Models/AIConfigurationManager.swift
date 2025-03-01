import Foundation

@MainActor
public final class AIConfigurationManager: ObservableObject {
    @MainActor
    public static let shared: AIConfigurationManager = {
        let instance = AIConfigurationManager()
        return instance
    }()
    
    @Published public private(set) var configurations: [AIConfiguration] = []
    private let defaults = UserDefaults.standard
    private let configKey = "ai_configurations"
    
    private init() {
        loadConfigurationsFromDefaults()
    }
    
    private func loadConfigurationsFromDefaults() {
        if let data = defaults.data(forKey: configKey) {
            do {
                configurations = try JSONDecoder().decode([AIConfiguration].self, from: data)
            } catch {
                print("Error loading AI configurations: \(error)")
                // Initialize with default if loading fails
                if configurations.isEmpty {
                    configurations = [.deepseekDefault]
                }
            }
        } else if configurations.isEmpty {
            // Initialize with default if no saved configurations
            configurations = [.deepseekDefault]
        }
    }
    
    private func saveConfigurationsToDefaults() {
        do {
            let data = try JSONEncoder().encode(configurations)
            defaults.set(data, forKey: configKey)
        } catch {
            print("Error saving AI configurations: \(error)")
        }
    }
    
    public func addConfiguration(_ configuration: AIConfiguration) {
        var newConfig = configuration
        if newConfig.isDefault {
            configurations = configurations.map { config in
                var updatedConfig = config
                updatedConfig.isDefault = false
                return updatedConfig
            }
        } else if configurations.isEmpty {
            // Make first config default if it's the only one
            newConfig.isDefault = true
        }
        configurations.append(newConfig)
        saveConfigurationsToDefaults()
    }
    
    public func updateConfiguration(_ configuration: AIConfiguration) {
        if let index = configurations.firstIndex(where: { $0.id == configuration.id }) {
            var updatedConfig = configuration
            if configuration.isDefault {
                // If this config is being set as default, unset others
                configurations = configurations.map { config in
                    var config = config
                    config.isDefault = false
                    return config
                }
                updatedConfig.isDefault = true
            } else if configurations[index].isDefault && configurations.count > 1 {
                // If this was the default and is being unset, make another one default
                if let firstOtherIndex = configurations.firstIndex(where: { $0.id != configuration.id }) {
                    configurations[firstOtherIndex].isDefault = true
                }
            }
            configurations[index] = updatedConfig
            saveConfigurationsToDefaults()
        }
    }
    
    public func deleteConfiguration(_ configuration: AIConfiguration) {
        configurations.removeAll { $0.id == configuration.id }
        
        // If we deleted the default and there are other configs, make another one default
        if configuration.isDefault && !configurations.isEmpty {
            configurations[0].isDefault = true
        }
        
        saveConfigurationsToDefaults()
    }
    
    public func getDefaultConfiguration() -> AIConfiguration? {
        configurations.first { $0.isDefault }
    }
}
