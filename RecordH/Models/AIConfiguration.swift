import Foundation

public struct AIConfiguration: Codable, Identifiable {
    public let id: UUID
    public var name: String
    public var baseURL: URL
    public var apiKey: String
    public var isDefault: Bool
    public var modelName: String
    public var temperature: Double
    public var maxTokens: Int
    public var topP: Double
    public var presencePenalty: Double
    public var frequencyPenalty: Double
    
    public init(id: UUID = UUID(), 
                name: String,
                baseURL: URL, 
                apiKey: String,
                isDefault: Bool = false,
                modelName: String = "deepseek-chat",
                temperature: Double = 0.7,
                maxTokens: Int = 2000,
                topP: Double = 0.95,
                presencePenalty: Double = 0.0,
                frequencyPenalty: Double = 0.0) {
        self.id = id
        self.name = name
        self.baseURL = baseURL
        self.apiKey = apiKey
        self.isDefault = isDefault
        self.modelName = modelName
        self.temperature = temperature
        self.maxTokens = maxTokens
        self.topP = topP
        self.presencePenalty = presencePenalty
        self.frequencyPenalty = frequencyPenalty
    }
    
    public static var deepseekDefault: Self {
        AIConfiguration(
            name: "Deepseek Chat",
            baseURL: URL(string: "https://api.deepseek.com/v1")!,
            apiKey: "",
            isDefault: true
        )
    }
}
