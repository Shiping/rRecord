import Foundation

public enum MCPError: Error {
    case networkError(String)
    case serverError(String)
}

@available(macOS 10.13, iOS 15.0, *)
public class HealthAdvisorProvider {
    public struct Configuration {
        public weak var healthStore: HealthStore?

        public init(healthStore: HealthStore?) {
            self.healthStore = healthStore
        }
    }

    public struct AdviceSection {
        public let title: String
        public var adviceStatements: [AdviceStatement] = []
        public var references: [Reference] = []

        public init(title: String, adviceStatements: [AdviceStatement] = [], references: [Reference] = []) {
            self.title = title
            self.adviceStatements = adviceStatements
            self.references = references
        }
    }

    public struct AdviceStatement {
        public let text: String
        public var referenceNumbers: [Int] = []

        public init(text: String, referenceNumbers: [Int] = []) {
            self.text = text
            self.referenceNumbers = referenceNumbers
        }
    }

    public struct Reference {
        public let number: Int
        public let linkText: String
        public let url: URL?

        public init(number: Int, linkText: String, url: URL?) {
            self.number = number
            self.linkText = linkText
            self.url = url
        }
    }

    let config: Configuration

    public init(config: Configuration) {
        self.config = config
    }

    private func generatePrompt(healthData: [String: Any], userDescription: String?, userAge: Int?, userGender: String?) -> String {
        var parts: [String] = []
        var descriptionPart: [String] = []
        var demographicPart: [String] = []

        if let steps = healthData["steps"] as? Int {
            parts.append("今日步数: \(steps)步 (当日数据)")
        }

        if let sleep = healthData["sleep"] as? [String: Any],
           let hours = sleep["hours"] as? Int,
           let minutes = sleep["minutes"] as? Int {
            parts.append("最近睡眠时长: \(hours)小时\(minutes)分钟")
        }

        if let heartRate = healthData["heartRate"] as? Int {
            parts.append("最近心率: \(heartRate)次/分钟 (当日数据)")
        }

        if let activeEnergy = healthData["activeEnergy"] as? Double {
            parts.append("今日活动消耗: \(activeEnergy)千卡 (当日数据)")
        }

        if let restingEnergy = healthData["restingEnergy"] as? Double {
            parts.append("今日静息消耗: \(restingEnergy)千卡 (当日数据)")
        }

        if let distance = healthData["distance"] as? Double {
            parts.append("今日运动距离: \(distance)公里 (当日数据)")
        }

        if let bloodOxygen = healthData["bloodOxygen"] as? Double {
            parts.append("血氧饱和度: \(bloodOxygen)% (当日数据)")
        }

        if let bodyFat = healthData["bodyFat"] as? Double {
            parts.append("体脂率: \(bodyFat)%")
        }
        if let flightsClimbed = healthData["flightsClimbed"] as? Int {
            parts.append("今日爬楼: \(flightsClimbed) 层 (当日数据)")
        }
        if let weight = healthData["weight"] as? Double {
            parts.append("今日体重: \(weight) 公斤 (当日数据)")
        }
        if let bloodPressure = healthData["bloodPressure"] as? [String: Any],
           let systolic = bloodPressure["systolic"] as? Double,
           let diastolic = bloodPressure["diastolic"] as? Double {
            parts.append("今日血压: \(Int(systolic))/\(Int(diastolic)) mmHg (当日数据)")
        }
        if let bloodSugar = healthData["bloodSugar"] as? Double {
            parts.append("今日血糖: \(bloodSugar) mmol/L (当日数据)")
        }
        if let bloodLipids = healthData["bloodLipids"] as? Double {
            parts.append("今日血脂: \(bloodLipids) mg/dL")
        }
        if let uricAcid = healthData["uricAcid"] as? Double {
            parts.append("今日尿酸: \(uricAcid) umol/L")
        }
        if let bmi = healthData["bmi"] as? Double {
            parts.append("最近BMI: \(String(format: "%.1f", bmi))")
        }

        if let userAge = userAge {
            demographicPart.append("用户年龄: \(userAge) 岁")
        }
        if let userGender = userGender {
            demographicPart.append("用户性别: \(userGender)")
        }

        if let userDescription = userDescription, !userDescription.isEmpty {
            descriptionPart.append("用户描述: \(userDescription)")
        }

        let prompt = """
        请基于以下用户\(demographicPart.isEmpty ? "" : "年龄和性别等")信息，并重点考虑用户当日的健康数据\(descriptionPart.isEmpty ? "" : "和用户描述")，给出个性化的健康建议：
        \(demographicPart.isEmpty ? "" : demographicPart.joined(separator: "\\n") + "\\n")
        \(parts.joined(separator: "\\n"))\(descriptionPart.isEmpty ? "" : "\\n" + parts.joined(separator: "\\n"))

        \n
        请从以下几个方面给出建议，**每条建议都请给出权威来源引用**，引用以 **[来源编号]** 的形式放在建议后。**如果可以找到对应参考文献的网页链接，请一并提供，并在文末的来源信息中包含链接地址**。例如：\n
        1. 运动建议 (结合今日步数、活动消耗、运动距离、爬楼等数据，尤其关注当日数据)\n
        2. 睡眠建议 (结合最近睡眠时长)\n
        3. 饮食建议 (结合体重、体脂率、血糖血脂尿酸、BMI等数据)\n
        4. 今日特别注意事项 (综合所有数据，给出今日需要特别关注的健康问题)

        建议要具体可执行，并针对用户数据的特点给出个性化建议。**请确保所有医疗健康建议都有可靠的来源引用，并尽可能提供参考文献的网页链接。**
        """
        return prompt
    }

    public func getHealthAdvice(healthData: [String: Any], userDescription: String?, userAge: Int?, userGender: String?, completion: @escaping (Result<[AdviceSection], Error>) -> Void) {
        guard let aiSettings = config.healthStore?.userProfile?.aiSettings, !aiSettings.isEmpty, aiSettings.first?.enabled == true else {
            completion(.failure(MCPError.networkError("AI功能未启用或未配置")))
            return
        }

        guard let aiSettings = config.healthStore?.userProfile?.aiSettings, !aiSettings.isEmpty, !(aiSettings.first?.deepseekApiKey.isEmpty ?? true) else {
            completion(.failure(MCPError.networkError("Deepseek API 密钥未配置")))
            return
        }

        var formattedHealthData: [String: Any] = [:]

        if let steps = healthData["steps"] as? Int {
            formattedHealthData["steps"] = steps
        }
        if let sleep = healthData["sleep"] as? [String: Any],
           let hours = sleep["hours"] as? Int,
           let minutes = sleep["minutes"] as? Int {
            formattedHealthData["sleep"] = ["hours": hours, "minutes": minutes]
        }
        if let heartRate = healthData["heartRate"] as? Int {
            formattedHealthData["heartRate"] = heartRate
        }
        if let activeEnergy = healthData["activeEnergy"] as? Double {
            formattedHealthData["activeEnergy"] = activeEnergy
        }
        if let restingEnergy = healthData["restingEnergy"] as? Double {
            formattedHealthData["restingEnergy"] = restingEnergy
        }
        if let distance = healthData["distance"] as? Double {
            formattedHealthData["distance"] = distance
        }
        if let bloodOxygen = healthData["bloodOxygen"] as? Double {
            formattedHealthData["bloodOxygen"] = bloodOxygen
        }
        if let bodyFat = healthData["bodyFat"] as? Double {
            formattedHealthData["bodyFat"] = bodyFat
        }

        let url = URL(string: "\(config.healthStore?.userProfile?.aiSettings.first?.deepseekBaseURL ?? "https://api.deepseek.com/v1")/chat/completions")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(config.healthStore?.userProfile?.aiSettings.first?.deepseekApiKey ?? "")", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let prompt = generatePrompt(healthData: healthData, userDescription: userDescription, userAge: userAge, userGender: userGender)
        let requestBody: [String: Any] = [
            "model": config.healthStore?.userProfile?.aiSettings.first?.deepseekModel ?? "deepseek-chat",
            "messages": [
                [
                    "role": "system",
                    "content": "你是一个专业的健康顾问，基于用户的健康数据提供个性化的建议。建议应该具体、可操作、并考虑到用户的各项健康指标。请从运动建议、睡眠建议、饮食建议和今日特别注意事项四个方面来提供建议。"
                ],
                [
                    "role": "user",
                    "content": prompt
                ]
            ],
            "temperature": 0.7,
            "max_tokens": 1500
        ]

        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: requestBody)
        } catch {
            completion(.failure(MCPError.serverError("请求数据序列化失败")))
            return
        }

        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            DispatchQueue.main.async {
                if let error = error {
                    completion(.failure(MCPError.networkError(error.localizedDescription)))
                    return
                }

                guard let data = data else {
                    completion(.failure(MCPError.networkError("无响应数据")))
                    return
                }

                do {
                    if let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
                       let choices = json["choices"] as? [[String: Any]],
                       let firstChoice = choices.first,
                       let message = firstChoice["message"] as? [String: Any],
                       let content = message["content"] as? String {
                        let parsedAdvice = self.parseHealthAdvice(markdownText: content)
                        completion(.success(parsedAdvice))
                    } else {
                        completion(.failure(MCPError.serverError("解析响应失败")))
                    }
                } catch {
                    completion(.failure(MCPError.serverError("解析响应失败：\(error.localizedDescription)")))
                }
            }
        }

        task.resume()
    }

    func parseHealthAdvice(markdownText: String) -> [AdviceSection] {
        var adviceSections: [AdviceSection] = []
        let lines = markdownText.components(separatedBy: .newlines)

        var currentSection: AdviceSection?
        var currentStatement: AdviceStatement?
        var references: [Reference] = []

        for line in lines {
            if line.hasPrefix("###") {
                if let section = currentSection {
                    if !references.isEmpty {
                        var updatedSection = section
                        updatedSection.references = references
                        adviceSections.append(updatedSection)
                        references = []
                    } else {
                        adviceSections.append(section)
                    }
                }
                let title = line.trimmingCharacters(in: CharacterSet(charactersIn: "#").union(.whitespacesAndNewlines))
                currentSection = AdviceSection(title: title)
                currentStatement = nil
            } else if line.hasPrefix("**参老文献:**") {
                if let section = currentSection {
                    currentSection = processReferences(in: lines, startingAfterLine: line, for: section)
                }
                currentStatement = nil
            }
            else if !line.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                if currentStatement == nil {
                    currentStatement = AdviceStatement(text: line)
                } else if var statement = currentStatement {
                    statement = AdviceStatement(text: statement.text + "\n" + line)
                    currentStatement = statement
                }

                if let statement = currentStatement, var section = currentSection {
                    section.adviceStatements.append(statement)
                    currentSection = section
                    currentStatement = nil
                }
            }
        }

        if let section = currentSection {
            if !references.isEmpty {
                var updatedSection = section
                updatedSection.references = references
                adviceSections.append(updatedSection)
            } else {
                adviceSections.append(section)
            }
        }

        return adviceSections
    }

    private func processReferences(in lines: [String], startingAfterLine line: String, for section: AdviceSection?) -> AdviceSection? {
        guard var currentSection = section else { return nil }
        var references: [Reference] = []

        if lines.contains(line) {
            if let index = lines.firstIndex(of: line) {
                for i in (index + 1)..<lines.count {
                    let referenceLine = lines[i]
                    if referenceLine.hasPrefix("###") || referenceLine.hasPrefix("**参老文献:**") {
                        break
                    }

                    let referenceRegex = try! NSRegularExpression(pattern: "\\[(\\d+)\\]\\[(.*?)\\]\\((.*?)\\)", options: [])
                    let range = NSRange(location: 0, length: referenceLine.utf16.count)

                    referenceRegex.enumerateMatches(in: referenceLine, options: [], range: range) { match, _, _ in
                        guard let match = match,
                              let numberRange = Range(match.range(at: 1), in: referenceLine),
                              let linkTextRange = Range(match.range(at: 2), in: referenceLine),
                              let urlRange = Range(match.range(at: 3), in: referenceLine) else {
                            return
                        }

                        let numberStr = String(referenceLine[numberRange])
                        let linkText = String(referenceLine[linkTextRange])
                        let urlStr = String(referenceLine[urlRange])

                        if let number = Int(numberStr), let url = URL(string: urlStr) {
                            references.append(Reference(number: number, linkText: linkText, url: url))
                        }
                    }
                }
            }
        }
        currentSection.references = references
        return currentSection
    }
}
