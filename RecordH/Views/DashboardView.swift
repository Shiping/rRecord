import SwiftUI

struct DashboardView: View {
    @ObservedObject var healthStore: HealthStore
    @State private var showingAddNote = false
    @State private var noteToEdit: DailyNote? = nil
    
    private let columns = [
        GridItem(.flexible()),
        GridItem(.flexible())
    ]
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    // Latest Metrics Grid
                    LazyVGrid(columns: columns, spacing: 15) {
                        ForEach(HealthRecord.RecordType.allCases, id: \.self) { type in
                            NavigationLink(destination: HealthMetricDetailView(type: type, healthStore: healthStore)) {
                                MetricCard(type: type, record: healthStore.getLatestRecord(for: type))
                                    .foregroundColor(Theme.text)
                            }
                        }
                    }
                    .padding(.horizontal)
                    
                    // Daily Notes Section
                    VStack(alignment: .leading, spacing: 10) {
                        HStack {
                            Text("最近笔记")
                                .font(.headline)
                                .foregroundColor(Theme.text)
                            Spacer()
                            NavigationLink {
                                AllNotesView(healthStore: healthStore)
                            } label: {
                                Text("查看全部")
                                    .font(.subheadline)
                                    .foregroundColor(Theme.accent)
                            }
                        }
                        
                        let recentNotes = healthStore.dailyNotes
                            .sorted(by: { $0.date > $1.date })
                            .prefix(5)
                        
                        if recentNotes.isEmpty {
                            Text("暂无笔记")
                                .font(.subheadline)
                                .foregroundColor(Theme.secondaryText)
                                .padding(.vertical, 8)
                        } else {
                            ForEach(recentNotes) { note in
                                NavigationLink {
                                    NoteDetailView(note: note)
                                } label: {
                                    NoteSummaryCard(note: note)
                                }
                                .buttonStyle(.plain)
                            }
                        }
                        
                        Button(action: { showingAddNote = true }) {
                            Label("添加笔记", systemImage: "plus.circle.fill")
                        }
                        .modernButton()
                    }
                    .padding()
                    
                    // Daily Recommendations
                    DailyRecommendationsView(healthStore: healthStore)
                        .padding()
                }
            }
            .background(Theme.gradientBackground())
            .navigationTitle("健康记录")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    NavigationLink(destination: ProfileView(healthStore: healthStore)) {
                        Image(systemName: "person.circle")
                            .foregroundColor(Theme.accent)
                    }
                }
            }
            .sheet(isPresented: $showingAddNote) {
                AddNoteView(healthStore: healthStore, noteToEdit: noteToEdit)
            }
        }
    }
    
    private func editNote(_ note: DailyNote) {
        noteToEdit = note
        showingAddNote = true
    }
}

struct MetricCard: View {
    let type: HealthRecord.RecordType
    let record: HealthRecord?
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(type.displayName)
                .font(.headline)
            
            if let record = record {
                if type.needsSecondaryValue, let diastolic = record.secondaryValue {
                    Text("\(String(format: "%.0f/%.0f", record.value, diastolic)) \(record.unit)")
                        .font(.title2)
                } else {
                    Text("\(String(format: "%.1f", record.value)) \(record.unit)")
                        .font(.title2)
                }
                
                Text(record.date.formatted(.dateTime.day().month()))
                    .font(.caption)
                    .foregroundColor(Theme.secondaryText)
            } else {
                Text("暂无数据")
                    .font(.title2)
                    .foregroundColor(Theme.secondaryText)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .modernCard()
    }
}

struct NoteSummaryCard: View {
    let note: DailyNote
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(note.content)
                .lineLimit(3)
                .foregroundColor(Theme.text)
            
            HStack {
                Text(note.date.formatted(.dateTime.month().day().hour().minute()))
                    .font(.caption)
                    .foregroundColor(Theme.secondaryText)
                
                if !note.tags.isEmpty {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack {
                            ForEach(note.tags, id: \.self) { tag in
                                Text(tag)
                                    .font(.caption)
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 4)
                                    .background(Theme.accent.opacity(0.2))
                                    .foregroundColor(Theme.text)
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
    @ObservedObject var healthStore: HealthStore
    @State private var showingAddNote = false
    @State private var noteToEdit: DailyNote? = nil
    
    var body: some View {
        List {
            ForEach(healthStore.dailyNotes.sorted(by: { $0.date > $1.date })) { note in
                NoteSummaryCard(note: note)
                    .listRowBackground(Theme.background)
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
        .background(Theme.background)
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
    @ObservedObject var healthStore: HealthStore
    
    var body: some View {
        VStack(alignment: .leading, spacing: 15) {
            Text("今日建议")
                .font(.headline)
                .foregroundColor(Theme.text)
            
            // 这里可以根据用户的健康数据生成个性化建议
            ForEach(getDailyRecommendations(), id: \.self) { recommendation in
                HStack {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(Theme.accent)
                    Text(recommendation)
                        .foregroundColor(Theme.text)
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
