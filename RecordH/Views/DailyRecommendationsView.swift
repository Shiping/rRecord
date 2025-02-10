import SwiftUI
import HealthKit

// MARK: - Daily Recommendations

struct DailyRecommendationsView: View {
    @Environment(\.colorScheme) var colorScheme
    @ObservedObject var healthStore: HealthStore
    @State private var isGeneratingAdvice = false
    @State private var adviceText: String? = nil
    @State private var parsedAdviceSections: [HealthAdvisorProvider.AdviceSection] = []
    @State private var userDescription: String = ""
    @State private var showingConfigPicker = false
    
    private var configButton: some View {
        Menu {
            ForEach(healthStore.userProfile?.aiSettings ?? [], id: \.id) { config in
                Button(action: {
                    healthStore.updateSelectedAIConfiguration(config.id)
                    generateAdvice()
                }) {
                    HStack {
                        Text(config.name)
                        if config.id == healthStore.userProfile?.selectedAIConfigurationId {
                            Image(systemName: "checkmark")
                                .foregroundColor(Theme.color(.accent, scheme: colorScheme))
                        }
                    }
                }
            }
        } label: {
            HStack(spacing: 4) {
                Text(currentConfigName)
                    .foregroundColor(Theme.color(.text, scheme: colorScheme))
                Image(systemName: "chevron.down")
                    .foregroundColor(Theme.color(.accent, scheme: colorScheme))
                    .font(.caption)
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(Theme.color(.cardBackground, scheme: colorScheme))
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(Theme.color(.cardBorder, scheme: colorScheme), lineWidth: 1)
                    )
            )
        }
    }
    
    private var currentConfigName: String {
        if let id = healthStore.userProfile?.selectedAIConfigurationId,
           let config = healthStore.userProfile?.aiSettings.first(where: { $0.id == id }) {
            return config.name
        }
        return "默认配置"
    }
    
    var body: some View {
        VStack(spacing: 10) {
            HStack {
                Text("AI4Health")
                    .font(.headline)
                    .foregroundColor(Theme.color(.text, scheme: colorScheme))
                
                Spacer()
                
                configButton
                
                Button(action: generateAdvice) {
                    Image(systemName: "arrow.clockwise")
                        .foregroundColor(Theme.color(.accent, scheme: colorScheme))
                        .rotationEffect(.degrees(isGeneratingAdvice ? 360 : 0))
                        .animation(
                            isGeneratingAdvice ? 
                                Animation.linear(duration: 1).repeatForever(autoreverses: false) : 
                                .default,
                            value: isGeneratingAdvice
                        )
                }
            }
            
            TextField("在此输入您的健康状态描述 (可选)", text: $userDescription)
                .textFieldStyle(PlainTextFieldStyle())
                .padding()
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Theme.color(.cardBackground, scheme: colorScheme))
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(Theme.color(.cardBorder, scheme: colorScheme), lineWidth: 1)
                        )
                )
                .padding(.bottom, 10)
            
            VStack(spacing: 4) {
                Text("医疗建议免责声明")
                    .font(.caption)
                    .foregroundColor(Theme.color(.secondaryText, scheme: colorScheme))
                    .frame(maxWidth: .infinity, alignment: .leading)
                Text("AI提供的健康建议仅供参考，不构成医疗诊断或治疗建议。如有健康问题，请务必咨询专业医疗人员获取个性化的医疗建议。")
                    .font(.caption2)
                    .foregroundColor(Theme.color(.secondaryText, scheme: colorScheme))
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            .padding(.horizontal)
            .padding(.vertical, 8)
            .background(Theme.color(.cardBackground, scheme: colorScheme))
            .cornerRadius(8)
            
            if !parsedAdviceSections.isEmpty {
                ForEach(parsedAdviceSections, id: \.title) { section in
                    AdviceSectionView(adviceSection: section)
                        .padding(.bottom)
                }
            } else if isGeneratingAdvice {
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle())
                    .frame(maxWidth: .infinity)
                    .padding()
            } else {
                Text("点击 ↻ 按钮获取 AI 健康建议")
                    .foregroundColor(.secondary)
                    .padding(.vertical, 8)
            }
        }
        .confirmationDialog("选择 AI 配置", isPresented: $showingConfigPicker, titleVisibility: .visible) {
            ForEach(healthStore.userProfile?.aiSettings ?? []) { config in
                Button(config.name) {
                    healthStore.updateSelectedAIConfiguration(config.id)
                    generateAdvice()
                }
            }
            Button("取消", role: .cancel) {}
        }
    }
    
    private func generateAdvice() {
        isGeneratingAdvice = true
        parsedAdviceSections = []
        
        healthStore.generateHealthAdvice(userDescription: userDescription) { result in
            switch result {
            case .success(let sections):
                parsedAdviceSections = sections
                if let currentConfigId = healthStore.userProfile?.selectedAIConfigurationId {
                    print("AI 建议使用配置: \(currentConfigId)")
                }
            case .failure(let error):
                print("Failed to generate AI advice: \(error.localizedDescription)")
            }
            isGeneratingAdvice = false
        }
    }
}

// MARK: - Advice Views
struct AdviceSectionView: View {
    let adviceSection: HealthAdvisorProvider.AdviceSection
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        VStack(alignment: .leading, spacing: 15) {
            Text(adviceSection.title)
                .font(.headline)
                .foregroundColor(Theme.color(.text, scheme: colorScheme))
            
            ForEach(adviceSection.adviceStatements, id: \.text) { statement in
                AdviceStatementView(statement: statement, references: adviceSection.references)
            }
            
            if !adviceSection.references.isEmpty {
                ReferenceListView(references: adviceSection.references)
            }
        }
        .padding()
        .background(Theme.color(.cardBackground, scheme: colorScheme))
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Theme.color(.cardBorder, scheme: colorScheme), lineWidth: 1)
        )
    }
}

struct AdviceStatementView: View {
    let statement: HealthAdvisorProvider.AdviceStatement
    let references: [HealthAdvisorProvider.Reference]
    @Environment(\.colorScheme) var colorScheme
    
    private var referencesText: String {
        let numbers = statement.referenceNumbers
            .map { String($0) }
            .joined(separator: ",")
        return numbers.isEmpty ? "" : "[\(numbers)]"
    }
    
    var body: some View {
        HStack(alignment: .top, spacing: 4) {
            Text(statement.text)
                .foregroundColor(Theme.color(.text, scheme: colorScheme))
                .textSelection(.enabled)
            
            if !statement.referenceNumbers.isEmpty {
                Text(referencesText)
                    .font(.caption)
                    .foregroundColor(Theme.color(.accent, scheme: colorScheme))
                    .textSelection(.enabled)
            }
        }
    }
}

struct ReferenceListView: View {
    let references: [HealthAdvisorProvider.Reference]
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("参考文献")
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundColor(Theme.color(.accent, scheme: colorScheme))
            
            VStack(alignment: .leading, spacing: 6) {
                ForEach(references, id: \.number) { reference in
                    HStack(alignment: .top, spacing: 4) {
                        Text("\(reference.number).")
                            .foregroundColor(Theme.color(.accent, scheme: colorScheme))
                            .textSelection(.enabled)
                            .frame(width: 20, alignment: .leading)
                        
                        VStack(alignment: .leading, spacing: 2) {
                            Text(reference.linkText)
                                .foregroundColor(Theme.color(.secondaryText, scheme: colorScheme))
                                .textSelection(.enabled)
                            if let url = reference.url {
                                Link(destination: url) {
                                    Text(url.absoluteString)
                                        .foregroundColor(Theme.color(.accent, scheme: colorScheme))
                                        .underline()
                                }
                            }
                        }
                    }
                }
            }
            .font(.caption)
        }
    }
}
