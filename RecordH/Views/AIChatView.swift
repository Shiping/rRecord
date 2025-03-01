import SwiftUI

struct AIChatView: View {
    let parameters: [String: String]
    let contextDescription: String
    
    @EnvironmentObject private var configManager: AIConfigurationManager
    @EnvironmentObject private var aiManager: AIManager
    @State private var userInput = ""
    @State private var isLoading = false
    @State private var response: AIResponse?
    @State private var error: Error?
    @State private var showError = false
    @State private var showingSettings = false
    
    private var combinedPrompt: String {
        var prompt = "基于以下数据进行分析：\n"
        
        // Add context description
        prompt += contextDescription + "\n\n"
        
        // Add parameters
        for (key, value) in parameters {
            prompt += "- \(key): \(value)\n"
        }
        
        // Add user input if any
        if !userInput.isEmpty {
            prompt += "\n用户补充说明：\(userInput)"
        }
        
        return prompt
    }
    
    private var parameterNames: [String] {
        Array(parameters.keys)
    }
    
    var body: some View {
        VStack(spacing: 16) {
            // Disclaimer
            Text(AIResponse.disclaimer)
                .font(.footnote)
                .foregroundColor(.secondary)
                .padding()
                .background(Color.secondary.opacity(0.1))
                .cornerRadius(8)
            
            if let response = response {
                ScrollView {
                    Text(response.formattedContent(includeDisclaimer: false))
                        .padding()
                }
                .background(Color.secondary.opacity(0.05))
                .cornerRadius(8)
            }
            
            HStack {
                TextField("补充描述（可选）", text: $userInput)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                
                Button {
                    Task {
                        await generateResponse()
                    }
                } label: {
                    if isLoading {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle())
                    } else {
                        Image(systemName: "arrow.up.circle.fill")
                            .font(.title2)
                    }
                }
                .disabled(isLoading || configManager.getDefaultConfiguration() == nil)
            }
            .padding(.horizontal)
        }
        .navigationTitle("AI助手")
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button {
                    showingSettings = true
                } label: {
                    Image(systemName: "gear")
                }
            }
        }
        .sheet(isPresented: $showingSettings) {
            NavigationStack {
                AIConfigList()
                    .environmentObject(configManager)
                    .environmentObject(aiManager)
            }
        }
        .alert("错误", isPresented: $showError) {
            Button("确定", role: .cancel) {}
        } message: {
            if let error = error {
                Text(error.localizedDescription)
            }
        }
        .onAppear {
            if response == nil {
                Task {
                    await generateResponse()
                }
            }
        }
    }
    
    private func generateResponse() async {
        isLoading = true
        defer { isLoading = false }
        
        do {
            let content = try await aiManager.sendMessage(combinedPrompt)
            await MainActor.run {
                response = AIResponse(
                    content: content,
                    usedParameters: parameterNames
                )
            }
        } catch AIError.noConfiguration {
            await MainActor.run {
                error = NSError(
                    domain: "AIChat",
                    code: 1,
                    userInfo: [NSLocalizedDescriptionKey: "请先在设置中配置AI"]
                )
                showError = true
            }
        } catch {
            await MainActor.run {
                self.error = error
                self.showError = true
            }
        }
    }
}

// MARK: - Preview
struct AIChatView_Previews: PreviewProvider {
    static var previewParameters: [String: String] = [
        "性别": "男",
        "年龄": "30岁",
        "BMI": "22.5",
        "体重": "70千克",
        "步数": "8000步/天"
    ]
    
    static var previewContext = "这是最近30天的健康数据概览"
    
    static var previews: some View {
        NavigationStack {
            AIChatView(
                parameters: previewParameters,
                contextDescription: previewContext
            )
            .environmentObject(AIConfigurationManager.shared)
            .environmentObject(AIManager.shared)
        }
    }
}
