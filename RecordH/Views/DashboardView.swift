import SwiftUI

struct DashboardView: View {
    @ObservedObject var healthStore: HealthStore
    @Environment(\.colorScheme) var colorScheme
    @State private var showingAddNote = false
    @State private var noteToEdit: DailyNote? = nil
    @State private var isRefreshing = false
    
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
        healthStore.refreshHealthData()
        // Give some time for the refresh animation
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
            isRefreshing = false
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
    
    private let columns = [
        GridItem(.flexible()),
        GridItem(.flexible())
    ]
    
    var body: some View {
        LazyVGrid(columns: columns, spacing: 15) {
            ForEach(HealthRecord.RecordType.allCases, id: \.self) { type in
                NavigationLink(destination: HealthMetricDetailView(healthStore: healthStore, type: type)) {
                    MetricCard(type: type, record: healthStore.getLatestRecord(for: type))
                        .foregroundColor(Theme.color(.text, scheme: colorScheme))
                }
            }
        }
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
        
        if type == .steps {
            isNormal = value >= (type.normalRange.min ?? 0)
        } else if type == .sleep {
            isNormal = value >= (type.normalRange.min ?? 0) && 
                      value <= (type.normalRange.max ?? Double.infinity)
        } else {
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
                    // Display sleep duration in hours and minutes
                    let hours = Int(record.value / 3600)
                    let minutes = Int((record.value.truncatingRemainder(dividingBy: 3600)) / 60)
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
                    
                    if type == .steps || type == .sleep || type == .flightsClimbed {
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

private struct RecentNotesSection: View {
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
    
    var body: some View {
        VStack(alignment: .leading, spacing: 15) {
            Text("今日建议")
                .font(.headline)
                .foregroundColor(Theme.color(.text, scheme: colorScheme))
            
            // 这里可以根据用户的健康数据生成个性化建议
            ForEach(getDailyRecommendations(), id: \.self) { recommendation in
                HStack {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(Theme.color(.accent, scheme: colorScheme))
                    Text(recommendation)
                        .foregroundColor(Theme.color(.text, scheme: colorScheme))
                }
            }
        }
        .frame(maxWidth: .infinity)
        .modernCard()
    }
    
    private func getDailyRecommendations() -> [String] {
        var recommendations = [String]()
        
        // 根据最新的体重数据提供建议
        if healthStore.getLatestRecord(for: .weight) != nil {
            // 这里可以添加更复杂的逻辑来生成建议
            recommendations.append("建议每日步行30分钟")
        }
        
        // 添加一些通用建议
        recommendations.append("保持充足睡眠，建议7-8小时")
        recommendations.append("多喝水，每日建议2000ml")
        
        return recommendations
    }
}

#Preview {
    DashboardView(healthStore: HealthStore())
}
