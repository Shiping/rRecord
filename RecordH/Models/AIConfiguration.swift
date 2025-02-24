import Foundation

struct AIConfiguration: Codable, Identifiable, Equatable {
    let id: UUID
    var name: String
    var baseURL: URL
    var apiKey: String
    var isDefault: Bool
    
    init(id: UUID = UUID(), name: String, baseURL: URL, apiKey: String, isDefault: Bool = false) {
        self.id = id
        self.name = name
        self.baseURL = baseURL
        self.apiKey = apiKey
        self.isDefault = isDefault
    }
    
    static var deepseekDefault: AIConfiguration {
        AIConfiguration(
            name: "Deepseek",
            baseURL: URL(string: "https://api.deepseek.com/v1/")!,
            apiKey: "",
            isDefault: true
        )
    }
}

// MARK: - Configuration Storage
class AIConfigurationManager: ObservableObject {
    @Published var configurations: [AIConfiguration] = []
    private let defaults = UserDefaults.standard
    private let configKey = "ai_configurations"
    
    init() {
        loadConfigurations()
    }
    
    private func loadConfigurations() {
        if let data = defaults.data(forKey: configKey),
           let configs = try? JSONDecoder().decode([AIConfiguration].self, from: data) {
            configurations = configs
        } else {
            // Initialize with default configuration
            configurations = [.deepseekDefault]
            saveConfigurations()
        }
    }
    
    private func saveConfigurations() {
        if let data = try? JSONEncoder().encode(configurations) {
            defaults.set(data, forKey: configKey)
        }
    }
    
    func addConfiguration(_ config: AIConfiguration) {
        configurations.append(config)
        saveConfigurations()
    }
    
    func updateConfiguration(_ config: AIConfiguration) {
        if let index = configurations.firstIndex(where: { $0.id == config.id }) {
            configurations[index] = config
            saveConfigurations()
        }
    }
    
    func deleteConfiguration(_ config: AIConfiguration) {
        configurations.removeAll { $0.id == config.id }
        saveConfigurations()
    }
    
    func getDefaultConfiguration() -> AIConfiguration? {
        configurations.first { $0.isDefault }
    }
    
    func setDefaultConfiguration(_ config: AIConfiguration) {
        var updatedConfigs = configurations
        for i in 0..<updatedConfigs.count {
            updatedConfigs[i].isDefault = (updatedConfigs[i].id == config.id)
        }
        configurations = updatedConfigs
        saveConfigurations()
    }
}
