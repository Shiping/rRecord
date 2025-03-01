import Foundation
import Combine

@MainActor
public final class AIManager: ObservableObject {
    @MainActor
    public static let shared: AIManager = {
        let instance = AIManager()
        Task { @MainActor in
            await instance.initialize()
        }
        return instance
    }()
    
    private let configurationManager: AIConfigurationManager
    @Published public private(set) var isProcessing = false
    
    private init() {
        self.configurationManager = AIConfigurationManager.shared
    }
    
    private func initialize() async {
        // Instance is fully initialized here
    }
    
    public func sendMessage(_ message: String) async throws -> String {
        guard !isProcessing else {
            throw AIError.busy
        }
        
        guard let config = configurationManager.getDefaultConfiguration() else {
            throw AIError.noConfiguration
        }
        
        isProcessing = true
        defer { isProcessing = false }
        
        return try await withURLRequest(for: message, with: config) { request in
            let (data, response) = try await URLSession.shared.data(for: request)
            
            guard let httpResponse = response as? HTTPURLResponse else {
                throw AIError.invalidResponse
            }
            
            guard httpResponse.statusCode == 200 else {
                if httpResponse.statusCode == 401 {
                    throw AIError.unauthorized
                }
                throw AIError.serverError(httpResponse.statusCode)
            }
            
            let decodedResponse = try JSONDecoder().decode(AIResponseBody.self, from: data)
            return decodedResponse.choices.first?.message.content ?? "无分析结果"
        }
    }
    
    private func withURLRequest<T>(
        for message: String,
        with config: AIConfiguration,
        perform: (URLRequest) async throws -> T
    ) async throws -> T {
        let url = config.baseURL.appendingPathComponent("chat/completions")
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(config.apiKey)", forHTTPHeaderField: "Authorization")
        
        let requestBody = [
            "model": config.modelName,
            "messages": [
                ["role": "user", "content": message]
            ],
            "temperature": config.temperature,
            "max_tokens": config.maxTokens,
            "top_p": config.topP,
            "presence_penalty": config.presencePenalty,
            "frequency_penalty": config.frequencyPenalty
        ] as [String : Any]
        
        request.httpBody = try JSONSerialization.data(withJSONObject: requestBody)
        
        return try await perform(request)
    }
}

public enum AIError: LocalizedError {
    case noConfiguration
    case invalidResponse
    case unauthorized
    case serverError(Int)
    case busy
    
    public var errorDescription: String? {
        switch self {
        case .noConfiguration:
            return "未配置AI服务"
        case .invalidResponse:
            return "服务器响应无效"
        case .unauthorized:
            return "API密钥无效或已过期"
        case .serverError(let code):
            return "服务器错误（\(code)）"
        case .busy:
            return "正在处理其他请求"
        }
    }
}
