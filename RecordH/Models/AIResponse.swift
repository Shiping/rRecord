import Foundation
import SwiftUI

struct AIResponse: Codable {
    let content: String
    let usedParameters: [String]
    
    static let disclaimer = """
    免责声明：
    此AI分析仅供参考，不构成任何医疗建议。AI提供的分析仅基于输入的数据进行客观描述，
    不涉及任何医疗诊断、治疗建议或健康指导。如有任何健康问题，请咨询专业医生。
    """
    
    func formattedContent(includeDisclaimer: Bool = true) -> AttributedString {
        var formatted = ""
        
        if includeDisclaimer {
            formatted += AIResponse.disclaimer + "\n\n"
        }
        
        formatted += content
        
        if !usedParameters.isEmpty {
            formatted += "\n\n使用的参数：" + usedParameters.joined(separator: ", ")
        }
        
        var attributedString = try! AttributedString(markdown: formatted)
        
        // Style the disclaimer text
        if includeDisclaimer {
            if let disclaimerRange = attributedString.range(of: AIResponse.disclaimer) {
                attributedString[disclaimerRange].foregroundColor = .secondary
                attributedString[disclaimerRange].font = .footnote
            }
        }
        
        // Style the parameters text
        if !usedParameters.isEmpty {
            if let paramsRange = attributedString.range(of: "使用的参数：" + usedParameters.joined(separator: ", ")) {
                attributedString[paramsRange].foregroundColor = .secondary
                attributedString[paramsRange].font = .caption
            }
        }
        
        return attributedString
    }
}

// MARK: - API Request/Response Types
struct AIRequestBody: Codable {
    let model: String
    let messages: [AIMessage]
    let temperature: Double
    let max_tokens: Int
    let top_p: Double
    let presence_penalty: Double
    let frequency_penalty: Double
}

struct AIMessage: Codable {
    let role: String
    let content: String
}

struct AIResponseBody: Codable {
    let choices: [AIChoice]
}

struct AIChoice: Codable {
    let message: AIMessage
}

// MARK: - Network Service
class AIService: ObservableObject {
    static let shared = AIService()
    private let session = URLSession.shared
    
    func generateResponse(
        config: AIConfiguration,
        prompt: String,
        parameters: [String]
    ) async throws -> AIResponse {
        var request = URLRequest(url: config.baseURL.appendingPathComponent("chat/completions"))
        request.httpMethod = "POST"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.addValue("Bearer \(config.apiKey)", forHTTPHeaderField: "Authorization")
        
        let requestBody = AIRequestBody(
            model: config.modelName,
            messages: [
                AIMessage(
                    role: "system",
                    content: """
                    你是一个数据分析助手。请分析用户提供的个人数据并给出客观描述。
                    - 禁止提供任何医疗建议、运动建议或健康指导
                    - 使用简洁明了的语言
                    - 使用**加粗**标记重要数值和关键发现
                    - 避免过度解读数据
                    """
                ),
                AIMessage(role: "user", content: prompt)
            ],
            temperature: config.temperature,
            max_tokens: config.maxTokens,
            top_p: config.topP,
            presence_penalty: config.presencePenalty,
            frequency_penalty: config.frequencyPenalty
        )
        
        let encoder = JSONEncoder()
        request.httpBody = try encoder.encode(requestBody)
        
        let (data, _) = try await session.data(for: request)
        let response = try JSONDecoder().decode(AIResponseBody.self, from: data)
        
        return AIResponse(
            content: response.choices.first?.message.content ?? "无分析结果",
            usedParameters: parameters
        )
    }
}
