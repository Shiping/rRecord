import Foundation

@MainActor
class AIManager: ObservableObject {
    static let shared = AIManager()
    
    @Published var configs: [AIConfig] = []
    @Published var templates: [PromptTemplate] = []
    @Published var currentConfig: AIConfig?
    
    private let configsKey = "ai_configs"
    private let templatesKey = "ai_templates"
    private let currentConfigKey = "current_ai_config"
    
    init() {
        loadData()
        
        // 如果没有配置，创建默认配置
        if configs.isEmpty {
            configs = [
                AIConfig(
                    name: "默认配置",
                    model: "gpt-3.5-turbo",
                    temperature: 0.7,
                    maxTokens: 500,
                    systemPrompt: "你是一个专业的健康顾问。",
                    isDefault: true
                )
            ]
            currentConfig = configs[0]
        }
        
        // 如果没有模板，创建默认模板
        if templates.isEmpty {
            templates = [
                PromptTemplate(
                    name: "基础分析",
                    description: "基础的健康数据分析模板",
                    template: """
                    作为一名专业的健康顾问，请根据以下数据提供分析：
                    {metrics}
                    
                    请提供：
                    1. 数据趋势分析
                    2. 是否在正常范围内
                    3. 改善建议（如果需要）
                    """,
                    applicableMetrics: HealthMetric.allCases,
                    isDefault: true
                )
            ]
        }
        
        saveData()
    }
    
    func addConfig(_ config: AIConfig) {
        configs.append(config)
        if config.isDefault {
            setDefaultConfig(config)
        }
        saveData()
    }
    
    func updateConfig(_ config: AIConfig) {
        if let index = configs.firstIndex(where: { $0.id == config.id }) {
            configs[index] = config
            if config.isDefault {
                setDefaultConfig(config)
            }
            saveData()
        }
    }
    
    func deleteConfig(_ config: AIConfig) {
        configs.removeAll { $0.id == config.id }
        saveData()
    }
    
    func setDefaultConfig(_ config: AIConfig) {
        for i in 0..<configs.count {
            configs[i].isDefault = configs[i].id == config.id
        }
        currentConfig = config
        saveData()
    }
    
    func addTemplate(_ template: PromptTemplate) {
        templates.append(template)
        if template.isDefault {
            setDefaultTemplate(template)
        }
        saveData()
    }
    
    func updateTemplate(_ template: PromptTemplate) {
        if let index = templates.firstIndex(where: { $0.id == template.id }) {
            templates[index] = template
            if template.isDefault {
                setDefaultTemplate(template)
            }
            saveData()
        }
    }
    
    func deleteTemplate(_ template: PromptTemplate) {
        templates.removeAll { $0.id == template.id }
        saveData()
    }
    
    func setDefaultTemplate(_ template: PromptTemplate) {
        for i in 0..<templates.count {
            templates[i].isDefault = templates[i].id == template.id
        }
        saveData()
    }
    
    private func loadData() {
        if let configsData = UserDefaults.standard.data(forKey: configsKey),
           let decodedConfigs = try? JSONDecoder().decode([AIConfig].self, from: configsData) {
            configs = decodedConfigs
            currentConfig = configs.first { $0.isDefault }
        }
        
        if let templatesData = UserDefaults.standard.data(forKey: templatesKey),
           let decodedTemplates = try? JSONDecoder().decode([PromptTemplate].self, from: templatesData) {
            templates = decodedTemplates
        }
    }
    
    private func saveData() {
        if let encodedConfigs = try? JSONEncoder().encode(configs) {
            UserDefaults.standard.set(encodedConfigs, forKey: configsKey)
        }
        
        if let encodedTemplates = try? JSONEncoder().encode(templates) {
            UserDefaults.standard.set(encodedTemplates, forKey: templatesKey)
        }
    }
}
