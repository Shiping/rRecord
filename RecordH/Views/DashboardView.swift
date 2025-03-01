import SwiftUI

enum NavigationDestination: Hashable {
    case profile
    case metric(HealthMetric)
    case aiConfig
}

struct DashboardView: View {
    private var profileSection: some View {
        ProfileView()
    }
    
    private var metricsGrid: some View {
        MetricsGridView()
            .environmentObject(healthStore)
    }
    
    private var aiAnalysisSection: some View {
        AIChatView(
            parameters: healthParameters,
            contextDescription: "这是用户的最新健康指标数据"
        )
        .environmentObject(healthStore.configManager)
        .environmentObject(healthStore.aiManager)
    }
    
    private var healthParameters: [String: String] {
        healthStore.currentHealthParameters
    }
    @EnvironmentObject var healthStore: HealthStore
    @State private var showingMetricSelection = false
    @State private var selectedMetric: HealthMetric?
    @State private var showingAIChat = false
    @State private var showingClearDataAlert = false
    
    var body: some View {
        VStack {
            Button(action: {
                showingAIChat = true
            }) {
                HStack {
                    Text("点击生成AI分析")
                        .foregroundColor(.primary)
                    Spacer()
                    Image(systemName: "chevron.right")
                        .foregroundColor(.secondary)
                }
            }
            .padding(.horizontal)
            
            ScrollView {
                LazyVStack(spacing: 20) {
                    // Profile Section
                    profileSection
                    
                    // Metrics Grid
                    metricsGrid
                    
                    // AI Analysis Section
                    if !healthParameters.isEmpty {
                        aiAnalysisSection
                    }
                }
                .padding(.vertical)
            }
        }
        .navigationDestination(for: NavigationDestination.self) { destination in
            switch destination {
            case .profile:
                ProfileView()
            case .metric(let metric):
                SingleMetricHistoryView(
                    metric: metric,
                    metricRecords: healthStore.records(for: metric),
                    aiParameters: healthParameters
                )
            case .aiConfig:
                AIConfigList()
                    .environmentObject(healthStore.configManager)
                    .environmentObject(healthStore.aiManager)
            }
        }
        .refreshable {
            await healthStore.refreshData()
        }
        .navigationTitle("健康概览")
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                NavigationLink(value: NavigationDestination.profile) {
                    HStack {
                        Image(systemName: "person.circle")
                        Text("个人设置")
                    }
                }
            }
            ToolbarItem(placement: .navigationBarTrailing) {
                Button {
                    showingMetricSelection = true
                } label: {
                    Image(systemName: "plus")
                }
            }
        }
        .sheet(isPresented: $showingMetricSelection) {
            MetricSelectionSheet(selectedMetric: $selectedMetric)
        }
        .sheet(item: $selectedMetric) { metric in
            NavigationStack {
                AddRecordSheet(metric: metric)
                    .environmentObject(healthStore)
            }
        }
        .sheet(isPresented: $showingAIChat) {
            NavigationStack {
                AIChatView(
                    parameters: healthParameters,
                    contextDescription: "这是用户的最新健康指标数据"
                )
                .environmentObject(healthStore.configManager)
                .environmentObject(healthStore.aiManager)
                .navigationTitle("AI健康分析")
                .navigationBarTitleDisplayMode(.inline)
            }
        }
        .alert("出现错误", isPresented: .init(
            get: { healthStore.error != nil },
            set: { show in
                if !show {
                    HealthStore.shared.clearError()
                }
            }
        )) {
            Button("确定", role: .cancel) {
                HealthStore.shared.clearError()
            }
            
            if healthStore.error?.localizedDescription.contains("数据加载失败") == true {
                Button("清除所有数据", role: .destructive) {
                    showingClearDataAlert = true 
                }
            }
        } message: {
            if let healthError = healthStore.error as? HealthStoreError {
                Text("\(healthError.localizedDescription)\n\n\(healthError.advice)")
            } else if let error = healthStore.error {
                Text(error.localizedDescription)
            }
        }
        .alert("确认清除数据", isPresented: $showingClearDataAlert) {
            Button("取消", role: .cancel) {
                showingClearDataAlert = false
            }
            Button("确定清除", role: .destructive) {
                healthStore.clearUserDefaultsData()
                showingClearDataAlert = false
                healthStore.clearError()
                
                // Force a refresh after clearing data
                Task {
                    await healthStore.refreshData()
                }
            }
        } message: {
            Text("此操作将清除所有本地保存的数据。这可能有助于解决数据加载问题，但会删除所有已保存的记录。您确定要继续吗？")
        }
    }
}

struct MetricSelectionSheet: View {
    @Environment(\.dismiss) var dismiss
    @Binding var selectedMetric: HealthMetric?
    
    var body: some View {
        NavigationView {
            List(HealthMetric.allCases, id: \.self) { metric in
                Button(action: {
                    selectedMetric = metric
                    dismiss()
                }) {
                    Text(metric.name)
                }
            }
            .navigationTitle("选择指标")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("取消") {
                        dismiss()
                    }
                }
            }
        }
    }
}

#Preview {
    NavigationStack {
        DashboardView()
            .environmentObject(HealthStore.shared)
    }
}
