import Foundation

enum MCPError: Error {
    case networkError(String)
    case serverError(String)
}

@available(macOS 10.13, iOS 15.0, *)
class HealthAdvisorProvider { // Renamed class
    struct Configuration {
        weak var healthStore: HealthStore?
    }

    let config: Configuration

    public init(config: Configuration) {
        self.config = config
    }

    private func generatePrompt(healthData: [String: Any]) -> String {
        var parts: [String] = []

        if let steps = healthData["steps"] as? Int {
            parts.append("今日步数: \(steps)步")
        }

        if let sleep = healthData["sleep"] as? [String: Any],
           let hours = sleep["hours"] as? Int,
           let minutes = sleep["minutes"] as? Int {
            parts.append("最近睡眠时长: \(hours)小时\(minutes)分钟")
        }

        if let heartRate = healthData["heartRate"] as? Int {
            parts.append("最近心率: \(heartRate)次/分钟")
        }

        if let activeEnergy = healthData["activeEnergy"] as? Double {
            parts.append("今日活动消耗: \(activeEnergy)千卡")
        }

        if let restingEnergy = healthData["restingEnergy"] as? Double {
            parts.append("今日静息消耗: \(restingEnergy)千卡")
        }

        if let distance = healthData["distance"] as? Double {
            parts.append("今日运动距离: \(distance)公里")
        }

        if let bloodOxygen = healthData["bloodOxygen"] as? Double {
            parts.append("血氧饱和度: \(bloodOxygen)%")
        }

        if let bodyFat = healthData["bodyFat"] as? Double {
            parts.append("体脂率: \(bodyFat)%")
        }

        let prompt = """
        基于用户的以下健康数据，请提供具体的健康建议：
        \(parts.joined(separator: "\n"))

        请从以下几个方面给出建议：
        1. 运动建议
        2. 睡眠建议
        3. 饮食建议
        4. 今日特别注意事项

        建议要具体可执行，并针对用户数据的特点给出个性化建议。
        """
        return prompt
    }

    func getHealthAdvice(healthData: [String: Any], completion: @escaping (Result<String, Error>) -> Void) {
        guard let aiSettings = config.healthStore?.userProfile?.aiSettings, aiSettings.enabled else {
            completion(.failure(MCPError.networkError("AI功能未启用或未配置")))
            return
        }

        guard !aiSettings.deepseekApiKey.isEmpty else {
            completion(.failure(MCPError.networkError("Deepseek API 密钥未配置")))
            return
        }

        let prompt = generatePrompt(healthData: healthData)
        let baseURL = aiSettings.deepseekBaseURL.isEmpty ? "https://api.deepseek.com/v1" : aiSettings.deepseekBaseURL
        let model = aiSettings.deepseekModel.isEmpty ? "deepseek-chat" : aiSettings.deepseekModel

        guard let url = URL(string: "\(baseURL)/chat/completions") else {
            completion(.failure(MCPError.networkError("无效的API URL")))
            return
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue("Bearer \(aiSettings.deepseekApiKey)", forHTTPHeaderField: "Authorization")
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")

        let requestBody: [String: Any] = [
            "model": model,
            "messages": [
                ["role": "system", "content": "你是一个专业的健康顾问，基于用户的健康数据提供个性化的建议。建议应该具体、可操作、并考虑到用户的各项健康指标。请从运动建议、睡眠建议、饮食建议和今日特别注意事项四个方面来提供建议。"],
                ["role": "user", "content": prompt]
            ],
            "temperature": 0.7,
            "max_tokens": 1500
        ]

        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: requestBody)
        } catch {
            completion(.failure(MCPError.networkError("请求体序列化失败")))
            return
        }

        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                completion(.failure(MCPError.networkError("网络请求错误: \(error.localizedDescription)")))
                return
            }

            guard let httpResponse = response as? HTTPURLResponse, 200..<300 ~= httpResponse.statusCode else {
                let statusCode = (response as? HTTPURLResponse)?.statusCode ?? 0
                completion(.failure(MCPError.serverError("API请求失败，状态码: \(statusCode)")))
                return
            }

            guard let data = data else {
                completion(.failure(MCPError.serverError("API 响应数据为空")))
                return
            }

            do {
                let jsonResponse = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any]
                if let choices = jsonResponse?["choices"] as? [[String: Any]],
                   let firstChoice = choices.first,
                   let message = firstChoice["message"] as? [String: Any],
                   let content = message["content"] as? String {
                    completion(.success(content))
                } else if let errorDetail = jsonResponse?["error"] as? [String: Any], let errorMessage = errorDetail["message"] as? String {
                    completion(.failure(MCPError.serverError("API 错误: \(errorMessage)")))
                }
                 else {
                    completion(.failure(MCPError.serverError("无效的API响应格式")))
                }
            } catch {
                completion(.failure(MCPError.serverError("JSON 解析失败: \(error.localizedDescription)")))
            }
        }.resume()
    }


    func useHealthAdvisor(healthData: [String: Any], completion: @escaping (Result<String, Error>) -> Void) { // Modified function
        getHealthAdvice(healthData: healthData, completion: completion) // Call the Swift implementation
    }
}
