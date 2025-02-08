import SwiftUI

struct DashboardView: View {
    @ObservedObject var healthStore: HealthStore
    @Environment(\.colorScheme) var colorScheme
    @State private var showingAddNote = false
    @State private var noteToEdit: DailyNote? = nil
    @State private var isRefreshing = false
    @State private var hasInitiallyLoaded = false
    
    var body: some View {
        NavigationView {
            ScrollView {
                RefreshControl(isRefreshing: $isRefreshing) {
                    refreshData()
                }
                VStack(spacing: 20) {
                    // Latest Metrics Grid
                    LatestMetricsGrid(healthStore: healthStore)
                        .padding(.horizontal)
                    
                    // Daily Notes Section
                    RecentNotesSection(
                        healthStore: healthStore,
                        showingAddNote: $showingAddNote,
                        noteToEdit: $noteToEdit
                    )
                    .padding()
                    
                    // Daily Recommendations
                    DailyRecommendationsView(healthStore: healthStore)
                        .padding()
                }
            }
            .background(Theme.gradientBackground(for: colorScheme))
            .navigationTitle("健康记录")
            .onAppear {
                if !hasInitiallyLoaded {
                    refreshData()
                    hasInitiallyLoaded = true
                }
            }
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    HStack {
                        Button(action: refreshData) {
                            Image(systemName: "arrow.clockwise")
                                .foregroundColor(Theme.color(.accent, scheme: colorScheme))
                        }
                        NavigationLink(destination: ProfileView(healthStore: healthStore)) {
                            Image(systemName: "person.circle")
                                .foregroundColor(Theme.color(.accent, scheme: colorScheme))
                        }
                    }
                }
            }
            .sheet(isPresented: $showingAddNote) {
                AddNoteView(healthStore: healthStore, noteToEdit: noteToEdit)
            }
        }
    }
    
    private func refreshData() {
        isRefreshing = true
        
        // Delay the heavy operation slightly to let UI become responsive
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            healthStore.refreshHealthData()
            
            // Give some time for the refresh animation
            DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                isRefreshing = false
            }
        }
    }
    
    private func editNote(_ note: DailyNote) {
        noteToEdit = note
        showingAddNote = true
    }
}

private struct LatestMetricsGrid: View {
    @ObservedObject var healthStore: HealthStore
    @Environment(\.colorScheme) var colorScheme
    
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    
    private var columns: [GridItem] {
        // Use 3 columns on iPad in landscape
        if horizontalSizeClass == .regular {
            return [
                GridItem(.flexible()),
                GridItem(.flexible()),
                GridItem(.flexible())
            ]
        }
        // Use 2 columns on iPhone or iPad in portrait
        return [
            GridItem(.flexible()),
            GridItem(.flexible())
        ]
    }
    
    var body: some View {
        VStack(spacing: 10) {
            LazyVGrid(columns: columns, spacing: 15) {
                ForEach(HealthRecord.RecordType.allCases, id: \.self) { type in
                    NavigationLink(destination: HealthMetricDetailView(healthStore: healthStore, type: type)) {
                        MetricCardWrapper(type: type, healthStore: healthStore)
                            .foregroundColor(Theme.color(.text, scheme: colorScheme))
                    }
                }
            }
        }
        // Add some padding for iPad
        .padding(horizontalSizeClass == .regular ? 20 : 0)
    }
}

// Wrapper to optimize rendering and reduce view updates
private struct MetricCardWrapper: View {
    let type: HealthRecord.RecordType
    @ObservedObject var healthStore: HealthStore
    
    var body: some View {
        let record = healthStore.getLatestRecord(for: type)
        MetricCard(type: type, record: record)
    }
}

private struct StatusIcon {
    let icon: String
    let color: Color
}

struct MetricCard: View {
    @Environment(\.colorScheme) var colorScheme
    let type: HealthRecord.RecordType
    let record: HealthRecord?
    
    private func getStatusIcon(type: HealthRecord.RecordType, value: Double) -> StatusIcon {
        let isNormal: Bool
        
        switch type {
        case .steps:
            isNormal = value >= (type.normalRange.min ?? 0)
        case .sleep:
            isNormal = value >= (type.normalRange.min ?? 0) && 
                      value <= (type.normalRange.max ?? Double.infinity)
        case .activeEnergy:
            isNormal = value >= (type.normalRange.min ?? 0)
        case .heartRate:
            isNormal = value >= (type.normalRange.min ?? 0) && 
                      value <= (type.normalRange.max ?? Double.infinity)
        case .distance:
            isNormal = value >= (type.normalRange.min ?? 0)
        case .bloodOxygen:
            isNormal = value >= (type.normalRange.min ?? 0) && 
                      value <= (type.normalRange.max ?? Double.infinity)
        case .bodyFat:
            isNormal = value >= (type.normalRange.min ?? 0) && 
                      value <= (type.normalRange.max ?? Double.infinity)
        default:
            return StatusIcon(icon: "", color: .clear)
        }
        
        return StatusIcon(
            icon: isNormal ? "checkmark.circle.fill" : "exclamationmark.circle.fill",
            color: isNormal ? .green : .red
        )
    }
    
    private var iconName: String {
        switch type {
        case .steps:
            return "figure.walk"
        case .sleep:
            return "bed.double.fill"
        case .flightsClimbed:
            return "stairs"
        case .weight:
            return "scalemass.fill"
        case .bloodPressure:
            return "heart.fill"
        case .bloodSugar:
            return "drop.fill"
        case .bloodLipids:
            return "chart.line.uptrend.xyaxis"
        case .uricAcid:
            return "cross.vial.fill"
        case .activeEnergy:
            return "flame.fill"
        case .restingEnergy:
            return "battery.100"
        case .heartRate:
            return "waveform.path.ecg"
        case .distance:
            return "figure.walk.motion"
        case .bloodOxygen:
            return "lungs.fill"
        case .bodyFat:
            return "figure.arms.open"
        }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: iconName)
                    .foregroundColor(Theme.color(.accent, scheme: colorScheme))
                Text(type.displayName)
                    .font(.headline)
            }
            
            if let record = record {
                if type.needsSecondaryValue, let diastolic = record.secondaryValue {
                    Text("\(String(format: "%.0f/%.0f", record.value, diastolic)) \(record.unit)")
                        .font(.title2)
                } else if type == .sleep {
                    let hours = Int(record.value)
                    let minutes = Int(record.secondaryValue ?? 0)
                    Text("\(hours)小时\(minutes)分钟")
                        .font(.title2)
                } else {
                    Text("\(String(format: type == .steps ? "%.0f" : "%.1f", record.value)) \(record.unit)")
                        .font(.title2)
                }
                
                HStack {
                    Text(record.date.formatted(.dateTime.day().month()))
                        .font(.caption)
                        .foregroundColor(Theme.color(.secondaryText, scheme: colorScheme))
                    
                    if type == .steps || type == .sleep || type == .flightsClimbed ||
                       type == .activeEnergy || type == .heartRate || type == .distance ||
                       type == .bloodOxygen || type == .bodyFat {
                        let statusIcon = getStatusIcon(type: type, value: record.value)
                        Image(systemName: statusIcon.icon)
                            .foregroundColor(statusIcon.color)
                    }
                }
            } else {
                Text("暂无数据")
                    .font(.title2)
                    .foregroundColor(Theme.color(.secondaryText, scheme: colorScheme))
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .modernCard()
    }
}

struct RecentNotesSection: View {
    @ObservedObject var healthStore: HealthStore
    @Binding var showingAddNote: Bool
    @Binding var noteToEdit: DailyNote?
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("最近笔记")
                    .font(.headline)
                    .foregroundColor(Theme.color(.text, scheme: colorScheme))
                Spacer()
                Button(action: { showingAddNote = true }) {
                    Image(systemName: "plus.circle.fill")
                        .foregroundColor(Theme.color(.accent, scheme: colorScheme))
                }
                NavigationLink {
                    AllNotesView(healthStore: healthStore)
                } label: {
                    Text("查看全部")
                        .font(.subheadline)
                        .foregroundColor(Theme.color(.accent, scheme: colorScheme))
                }
            }
            
            let recentNotes = healthStore.dailyNotes
                .sorted(by: { $0.date > $1.date })
                .prefix(5)
            
            if recentNotes.isEmpty {
                Text("暂无笔记")
                    .font(.subheadline)
                    .foregroundColor(Theme.color(.secondaryText, scheme: colorScheme))
                    .padding(.vertical, 8)
            } else {
                ForEach(recentNotes) { note in
                    NavigationLink {
                        NoteDetailView(healthStore: healthStore, note: note)
                    } label: {
                        NoteSummaryCard(note: note)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }
}

private struct NoteSummaryCard: View {
    @Environment(\.colorScheme) var colorScheme
    let note: DailyNote
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(note.content)
                .lineLimit(3)
                .foregroundColor(Theme.color(.text, scheme: colorScheme))
            
            HStack {
                Text(note.date.formatted(.dateTime.month().day().hour().minute()))
                    .font(.caption)
                    .foregroundColor(Theme.color(.secondaryText, scheme: colorScheme))
                
                if !note.tags.isEmpty {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack {
                            ForEach(note.tags, id: \.self) { tag in
                                Text(tag)
                                    .font(.caption)
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 4)
                                    .background(Theme.color(.accent, scheme: colorScheme).opacity(0.2))
                                    .foregroundColor(Theme.color(.text, scheme: colorScheme))
                                    .cornerRadius(8)
                            }
                        }
                    }
                }
            }
        }
        .modernCard()
    }
}

struct AllNotesView: View {
    @Environment(\.colorScheme) var colorScheme
    @ObservedObject var healthStore: HealthStore
    @State private var showingAddNote = false
    @State private var noteToEdit: DailyNote? = nil
    
    var body: some View {
        List {
            ForEach(healthStore.dailyNotes.sorted(by: { $0.date > $1.date })) { note in
                NoteSummaryCard(note: note)
                    .listRowBackground(Theme.color(.background, scheme: colorScheme))
                    .contentShape(Rectangle())
                    .onTapGesture {
                        editNote(note)
                    }
                    .swipeActions(edge: .trailing) {
                        Button(role: .destructive) {
                            healthStore.deleteDailyNote(note.id)
                        } label: {
                            Label("删除", systemImage: "trash")
                        }
                        
                        Button {
                            editNote(note)
                        } label: {
                            Label("编辑", systemImage: "pencil")
                        }
                        .tint(.orange)
                    }
            }
        }
        .background(Theme.color(.background, scheme: colorScheme))
        .navigationTitle("全部笔记")
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(action: { showingAddNote = true }) {
                    Image(systemName: "plus.circle.fill")
                }
            }
        }
        .sheet(isPresented: $showingAddNote) {
            AddNoteView(healthStore: healthStore, noteToEdit: noteToEdit)
        }
    }
    
    private func editNote(_ note: DailyNote) {
        noteToEdit = note
        showingAddNote = true
    }
}

struct DailyRecommendationsView: View {
    @Environment(\.colorScheme) var colorScheme
    @ObservedObject var healthStore: HealthStore
    @State private var isGeneratingAdvice = false
    @State private var adviceContent: String? = nil

    var todaysAdvice: DailyNote? {
        healthStore.dailyNotes
            .filter { Calendar.current.isDateInToday($0.date) && $0.category == .aiAdvice }
            .first
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 15) {
            HStack {
                Text("AI健康建议")
                    .font(.headline)
                    .foregroundColor(Theme.color(.text, scheme: colorScheme))
                Spacer()
                Button(action: generateAdvice) {
                    Image(systemName: "arrow.clockwise")
                        .foregroundColor(Theme.color(.accent, scheme: colorScheme))
                }
                .disabled(isGeneratingAdvice)
            }

            if let content = adviceContent { // 使用 adviceContent
                Text(content)
                    .foregroundColor(Theme.color(.text, scheme: colorScheme))
                    .font(.body)
            } else if isGeneratingAdvice {
                VStack {
                    ProgressView()
                    Text("正在生成建议...")
                        .foregroundColor(Theme.color(.secondaryText, scheme: colorScheme))
                        .font(.subheadline)
                }
                .frame(maxWidth: .infinity)
                .padding()
            } else {
                Text("点击刷新按钮获取AI健康建议")
                    .foregroundColor(Theme.color(.secondaryText, scheme: colorScheme))
                    .font(.subheadline)
            }
        }
        .frame(maxWidth: .infinity)
        .modernCard()
    }

    private func generateAdvice() {
        isGeneratingAdvice = true
        adviceContent = nil // 点击按钮时先清空 adviceContent
        healthStore.generateHealthAdvice { advice in
            isGeneratingAdvice = false
            if let advice = advice {
                adviceContent = advice // 获取到建议后更新 adviceContent
            } else {
                // 如果生成失败，可以在这里添加错误处理逻辑
                print("Failed to generate health advice")
                adviceContent = "生成建议失败，请稍后重试" // 提示用户生成失败
            }
        }
    }
}

#Preview {
    DashboardView(healthStore: HealthStore())
}
