import SwiftUI

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

struct DashboardView: View {
    @EnvironmentObject var healthStore: HealthStore
    @Environment(\.theme) var theme
    @State private var showingMetricSelection = false
    @State private var showingAddRecord = false
    @State private var selectedMetric: HealthMetric?
    @State private var showingErrorAlert = false
    @State private var showingClearDataAlert = false
    @State private var showingAIChat = false
    
    enum NavigationDestination: Hashable {
        case profile
        case metric(HealthMetric)
        case aiConfig
        
        static func == (lhs: NavigationDestination, rhs: NavigationDestination) -> Bool {
            switch (lhs, rhs) {
            case (.profile, .profile):
                return true
            case (.aiConfig, .aiConfig):
                return true
            case let (.metric(m1), .metric(m2)):
                return m1 == m2
            default:
                return false
            }
        }
        
        func hash(into hasher: inout Hasher) {
            switch self {
            case .profile:
                hasher.combine(0)
            case .aiConfig:
                hasher.combine(1)
            case .metric(let metric):
                hasher.combine(2)
                hasher.combine(metric)
            }
        }
    }
    
    @State private var navigationPath = NavigationPath()
    
    private var healthParameters: [String: String] {
        var params: [String: String] = [:]
        
        // Add user profile data
        if let profile = healthStore.userProfile {
            params["性别"] = profile.gender.rawValue
            params["年龄"] = "\(profile.age)岁"
            if let location = profile.location {
                params["所在地"] = location
            }
        }
        
        // Add health metrics
        for metric in HealthMetric.allCases {
            if let record = healthStore.latestRecord(for: metric) {
                params[metric.name] = record.formattedValue
            }
        }
        
        return params
    }
    
    var body: some View {
        ScrollView {
            LazyVStack(spacing: 20) {
                // Profile Section
                Button(action: { navigationPath.append(NavigationDestination.profile) }) {
                    HStack {
                        VStack(alignment: .leading) {
                            Text("个人设置")
                                .font(.headline)
                                .foregroundColor(.primary)
                            if let profile = healthStore.userProfile {
                                Text("\(profile.gender.rawValue) · \(profile.age)岁")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                            } else {
                                Text("点击设置个人信息")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                            }
                        }
                        Spacer()
                        Image(systemName: "chevron.right")
                            .foregroundColor(.secondary)
                    }
                    .padding()
                    .background(RoundedRectangle(cornerRadius: 12)
                        .fill(Color(UIColor.secondarySystemBackground)))
                }
                .padding(.horizontal)
                
                // Metrics Grid
                LatestMetricsGrid(
                    navigationPath: $navigationPath,
                    aiParameters: healthParameters
                )
                .environmentObject(healthStore)
                
                // AI Analysis Section
                if !healthParameters.isEmpty {
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text("AI分析")
                                .font(.headline)
                            Spacer()
                            Button(action: {
                                navigationPath.append(NavigationDestination.aiConfig)
                            }) {
                                Image(systemName: "gearshape")
                                    .foregroundColor(.secondary)
                            }
                        }
                        
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
                    }
                    .padding(.horizontal)
                }
            }
            .padding(.vertical)
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
                AIConfigView()
            }
        }
        .refreshable {
            await healthStore.refreshData()
        }
        .navigationTitle("健康概览")
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button(action: {
                    navigationPath.append(NavigationDestination.profile)
                }) {
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
                .navigationTitle("AI健康分析")
                .navigationBarTitleDisplayMode(.inline)
            }
        }
        .alert("出现错误", isPresented: .init(
            get: { healthStore.error != nil },
            set: { show in
                if !show {
                    healthStore.error = nil
                }
            }
        )) {
            Button("确定", role: .cancel) {
                healthStore.error = nil
            }
            
            if healthStore.error?.localizedDescription.contains("数据加载失败") == true {
                Button("清除所有数据", role: .destructive) {
                    showingClearDataAlert = true 
                }
            }
        } message: {
            if let error = healthStore.error {
                Text("\(error.localizedDescription)\n\n\(error.advice)")
            }
        }
        .alert("确认清除数据", isPresented: $showingClearDataAlert) {
            Button("取消", role: .cancel) {
                showingClearDataAlert = false
            }
            Button("确定清除", role: .destructive) {
                healthStore.clearUserDefaultsData()
                showingClearDataAlert = false
                healthStore.error = nil // Clear error state
                
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

#Preview {
    NavigationStack {
        DashboardView()
            .environmentObject(HealthStore.shared)
    }
}
