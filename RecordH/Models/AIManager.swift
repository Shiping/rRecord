import Foundation
import Combine

import SwiftUI
import RecordH // Import the PromptTemplate model

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
    @Published public var templates: [PromptTemplate] = []
    
    private init() {
        self.configurationManager = AIConfigurationManager.shared
    }
    
    private func initialize() async {
        // Load templates from UserDefaults or set default templates
        if let savedTemplates = UserDefaults.standard.data(forKey: "promptTemplates"),
           let decoded = try? JSONDecoder().decode([PromptTemplate].self, from: savedTemplates) {
            self.templates = decoded
        } else {
            // Set default templates if none exist
            self.templates = [
                PromptTemplate(
                    name: "健康状况分析",
                    description: "分析健康指标的变化趋势和潜在影响",
                    template: """
                    请分析以下健康数据的变化趋势和可能的健康影响：

                    {metrics}

                    请提供专业的分析和建议。
                    """,
                    applicableMetrics: HealthMetric.allCases,
                    isDefault: true
                )
            ]
            saveTemplates()
        }
    }
    
    private func saveTemplates() {
        if let encoded = try? JSONEncoder().encode(templates) {
            UserDefaults.standard.set(encoded, forKey: "promptTemplates")
        }
    }
    
    public func addTemplate(_ template: PromptTemplate) {
        templates.append(template)
        saveTemplates()
    }
    
    public func updateTemplate(_ template: PromptTemplate) {
        if let index = templates.firstIndex(where: { $0.id == template.id }) {
            templates[index] = template
            saveTemplates()
        }
    }
    
    public func deleteTemplate(_ template: PromptTemplate) {
        templates.removeAll { $0.id == template.id }
        saveTemplates()
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
