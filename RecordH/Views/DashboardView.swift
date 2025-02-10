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
                 VStack { // Wrap content in VStack
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
              .simultaneousGesture(
                 DragGesture()
                     .onEnded { _ in
                         UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
                     }
              )
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
        
        // Access userProfile to trigger SwiftUI update?
        _ = healthStore.userProfile
        
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
    @State private var isHovered = false
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
            color: isNormal ? Theme.color(.healthSuccess, scheme: colorScheme) : Theme.color(.healthWarning, scheme: colorScheme)
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
        VStack(alignment: .leading, spacing: 0) {
            // Header with icon and status
            HStack(spacing: 16) {
                // Icon with animated background
                Image(systemName: iconName)
                    .font(.system(size: 24, weight: .medium))
                    .foregroundColor(Theme.color(.accent, scheme: colorScheme))
                    .frame(width: 48, height: 48)
                    .background(
                        ZStack {
                            Circle()
                                .fill(Theme.color(.accent, scheme: colorScheme).opacity(0.1))
                            Circle()
                                .stroke(
                                    Theme.color(.accent, scheme: colorScheme).opacity(0.2),
                                    lineWidth: 1.5
                                )
                                .scaleEffect(isHovered ? 1.2 : 1.0)
                                .opacity(isHovered ? 0 : 1)
                                .animation(.easeInOut(duration: 1).repeatForever(autoreverses: false), value: isHovered)
                        }
                    )
                    .onAppear { isHovered = true }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(type.displayName)
                        .font(.headline)
                    
                    if let record = record,
                       type == .steps || type == .sleep || type == .activeEnergy || 
                       type == .heartRate || type == .distance || type == .bloodOxygen || 
                       type == .bodyFat {
                        let statusIcon = getStatusIcon(type: type, value: record.value)
                        HStack(spacing: 6) {
                            Image(systemName: statusIcon.icon)
                                .foregroundColor(statusIcon.color)
                                .imageScale(.small)
                            Text(statusIcon.icon == "checkmark.circle.fill" ? "正常" : "注意")
                                .font(.caption)
                                .fontWeight(.medium)
                                .foregroundColor(statusIcon.color)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(
                                    Capsule()
                                        .fill(statusIcon.color.opacity(0.15))
                                )
                        }
                    }
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.bottom, 12)
            
            // Value display section
            if let record = record {
                VStack(alignment: .leading, spacing: 12) {
                    HStack(alignment: .firstTextBaseline, spacing: 4) {
                        if type.needsSecondaryValue, let diastolic = record.secondaryValue {
                            Text("\(String(format: "%.0f/%.0f", record.value, diastolic))")
                                .font(.system(size: 32, weight: .semibold))
                                .foregroundColor(Theme.color(.accent, scheme: colorScheme))
                            Text(record.unit)
                                .font(.headline)
                                .foregroundColor(Theme.color(.text, scheme: colorScheme))
                        } else if type == .sleep {
                            let hours = Int(record.value)
                            let minutes = Int(record.secondaryValue ?? 0)
                            Text("\(hours)小时\(minutes)分钟")
                                .font(.system(size: 32, weight: .semibold))
                                .foregroundColor(Theme.color(.accent, scheme: colorScheme))
                        } else {
                            Text(String(format: type == .steps ? "%.0f" : "%.1f", record.value))
                                .font(.system(size: 32, weight: .semibold))
                                .foregroundColor(Theme.color(.accent, scheme: colorScheme))
                            Text(record.unit)
                                .font(.headline)
                                .foregroundColor(Theme.color(.text, scheme: colorScheme))
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    
                    HStack(spacing: 6) {
                        Image(systemName: "calendar")
                            .font(.caption)
                            .foregroundColor(Theme.color(.accent, scheme: colorScheme))
                        Text(record.date.formatted(.dateTime.day().month()))
                            .font(.caption)
                            .foregroundColor(Theme.color(.secondaryText, scheme: colorScheme))
                    }
                }
            } else {
                HStack(spacing: 8) {
                    Image(systemName: "questionmark.circle")
                        .font(.title2)
                        .foregroundColor(Theme.color(.secondaryText, scheme: colorScheme))
                    Text("暂无数据")
                        .font(.title3)
                        .foregroundColor(Theme.color(.secondaryText, scheme: colorScheme))
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.vertical, 12)
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 16)
        .background(
            ZStack {
                Theme.cardGradient(for: colorScheme)
                
                // Decorative geometric patterns
                GeometryReader { geometry in
                    Path { path in
                        let size = geometry.size
                        path.move(to: CGPoint(x: 0, y: size.height * 0.7))
                        path.addQuadCurve(
                            to: CGPoint(x: size.width, y: size.height * 0.3),
                            control: CGPoint(x: size.width * 0.5, y: size.height * 0.5)
                        )
                    }
                    .stroke(
                        Theme.color(.accent, scheme: colorScheme).opacity(0.05),
                        lineWidth: 2
                    )
                }
            }
        )
        .clipShape(RoundedRectangle(cornerRadius: 20))
        .overlay(
            RoundedRectangle(cornerRadius: 20)
                .stroke(
                    LinearGradient(
                        gradient: Gradient(colors: [
                            Theme.color(.accent, scheme: colorScheme).opacity(0.2),
                            Theme.color(.accent, scheme: colorScheme).opacity(0.1)
                        ]),
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 1.5
                )
        )
        .shadow(
            color: Theme.color(.accent, scheme: colorScheme).opacity(colorScheme == .dark ? 0.2 : 0.1),
            radius: colorScheme == .dark ? 12 : 8,
            x: 0,
            y: colorScheme == .dark ? 6 : 4
        )
    }
}

struct RecentNotesSection: View {
    @ObservedObject var healthStore: HealthStore
    @Binding var showingAddNote: Bool
    @Binding var noteToEdit: DailyNote?
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
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
    @State private var isHovered = false
    let note: DailyNote
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                // Animated note icon
                ZStack {
                    Circle()
                        .fill(Theme.color(.accent, scheme: colorScheme).opacity(0.1))
                        .frame(width: 40, height: 40)
                    
                    Circle()
                        .stroke(
                            Theme.color(.accent, scheme: colorScheme).opacity(0.2),
                            lineWidth: 1.5
                        )
                        .frame(width: 40, height: 40)
                        .scaleEffect(isHovered ? 1.2 : 1.0)
                        .opacity(isHovered ? 0 : 1)
                        .animation(.easeInOut(duration: 1).repeatForever(autoreverses: false), value: isHovered)
                    
                    Image(systemName: "note.text")
                        .font(.system(size: 20))
                        .foregroundColor(Theme.color(.accent, scheme: colorScheme))
                }
                .onAppear { isHovered = true }
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(note.date.formatted(.dateTime.month().day()))
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(Theme.color(.text, scheme: colorScheme))
                    
                    Text(note.date.formatted(.dateTime.hour().minute()))
                        .font(.caption)
                        .foregroundColor(Theme.color(.secondaryText, scheme: colorScheme))
                }
            }
            
            Text(note.content)
                .lineLimit(3)
                .foregroundColor(Theme.color(.text, scheme: colorScheme))
            
            if !note.tags.isEmpty {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(note.tags, id: \.self) { tag in
                            HStack(spacing: 4) {
                                Image(systemName: "tag.fill")
                                    .font(.system(size: 10))
                                Text(tag)
                                    .fontWeight(.medium)
                            }
                            .font(.caption)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 5)
                            .background(
                                Capsule()
                                    .fill(Theme.color(.accent, scheme: colorScheme).opacity(0.15))
                                    .overlay(
                                        Capsule()
                                            .stroke(
                                                LinearGradient(
                                                    colors: [
                                                        Theme.color(.accent, scheme: colorScheme).opacity(0.3),
                                                        Theme.color(.accent, scheme: colorScheme).opacity(0.1)
                                                    ],
                                                    startPoint: .topLeading,
                                                    endPoint: .bottomTrailing
                                                ),
                                                lineWidth: 1
                                            )
                                    )
                            )
                            .foregroundColor(Theme.color(.accent, scheme: colorScheme))
                        }
                    }
                    .padding(.horizontal, 4)
                }
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 16)
        .background(
            ZStack {
                Theme.cardGradient(for: colorScheme)
                
                // Decorative patterns
                GeometryReader { geometry in
                    Path { path in
                        let size = geometry.size
                        path.move(to: CGPoint(x: 0, y: size.height * 0.8))
                        path.addQuadCurve(
                            to: CGPoint(x: size.width, y: size.height * 0.2),
                            control: CGPoint(x: size.width * 0.5, y: size.height * 0.5)
                        )
                    }
                    .stroke(
                        Theme.color(.accent, scheme: colorScheme).opacity(0.05),
                        lineWidth: 1.5
                    )
                }
            }
        )
        .clipShape(RoundedRectangle(cornerRadius: 20))
        .overlay(
            RoundedRectangle(cornerRadius: 20)
                .stroke(
                    LinearGradient(
                        colors: [
                            Theme.color(.accent, scheme: colorScheme).opacity(0.2),
                            Theme.color(.accent, scheme: colorScheme).opacity(0.1)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 1.5
                )
        )
        .shadow(
            color: Theme.color(.accent, scheme: colorScheme).opacity(colorScheme == .dark ? 0.2 : 0.1),
            radius: colorScheme == .dark ? 12 : 8,
            x: 0,
            y: colorScheme == .dark ? 6 : 4
        )
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
    @State private var adviceText: String? = nil
    @State private var userDescription: String = ""
    @State private var showingConfigPicker = false
    
    // 优化配置选择器样式
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
            // Title and Actions
            HStack {
                Text("AI 健康建议")
                    .font(.headline)
                    .foregroundColor(Theme.color(.text, scheme: colorScheme))
                
                Spacer()
                
                configButton
                
                Button(action: generateAdvice) {
                    Image(systemName: "arrow.clockwise")
                        .foregroundColor(Theme.color(.accent, scheme: colorScheme))
                        .rotationEffect(.degrees(isGeneratingAdvice ? 360 : 0))
                        .animation(isGeneratingAdvice ? Animation.linear(duration: 1).repeatForever(autoreverses: false) : .default, value: isGeneratingAdvice)
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

            if let adviceText = adviceText {
                VStack(alignment: .leading, spacing: 20) {
                    // AI Icon and advice
                    HStack(alignment: .top, spacing: 16) {
                        // Animated AI icon with ripple effect
                        ZStack {
                            Circle()
                                .fill(Theme.color(.accent, scheme: colorScheme).opacity(0.1))
                                .frame(width: 48, height: 48)
                            
                            ForEach(0..<3) { index in
                                Circle()
                                    .stroke(
                                        Theme.color(.accent, scheme: colorScheme).opacity(0.2),
                                        lineWidth: 1
                                    )
                                    .frame(width: 48, height: 48)
                                    .scaleEffect(isGeneratingAdvice ? 1.5 : 1.0)
                                    .opacity(isGeneratingAdvice ? 0 : 1)
                                    .animation(
                                        Animation.easeInOut(duration: 1.5)
                                            .repeatForever(autoreverses: false)
                                            .delay(Double(index) * 0.5),
                                        value: isGeneratingAdvice
                                    )
                            }
                            
                            Image(systemName: "brain.head.profile")
                                .font(.system(size: 24))
                                .foregroundColor(Theme.color(.accent, scheme: colorScheme))
                        }
                        
                        // Advice content with creative styling
                        Text(adviceText)
                            .padding()
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(
                                ZStack {
                                    RoundedRectangle(cornerRadius: 16)
                                        .fill(Theme.color(.cardBackground, scheme: colorScheme))
                                    
                                    // Subtle pattern overlay
                                    GeometryReader { geometry in
                                        Path { path in
                                            let size = geometry.size
                                            path.move(to: CGPoint(x: 0, y: size.height * 0.7))
                                            path.addQuadCurve(
                                                to: CGPoint(x: size.width, y: size.height * 0.3),
                                                control: CGPoint(x: size.width * 0.5, y: size.height * 0.5)
                                            )
                                        }
                                        .stroke(
                                            Theme.color(.accent, scheme: colorScheme).opacity(0.05),
                                            lineWidth: 1.5
                                        )
                                    }
                                }
                            )
                            .overlay(
                                RoundedRectangle(cornerRadius: 16)
                                    .stroke(
                                        LinearGradient(
                                            colors: [
                                                Theme.color(.accent, scheme: colorScheme).opacity(0.3),
                                                Theme.color(.accent, scheme: colorScheme).opacity(0.1)
                                            ],
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        ),
                                        lineWidth: 1.5
                                    )
                            )
                    }
                    
                    VStack(alignment: .leading, spacing: 16) {
                        if !userDescription.isEmpty {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("用户描述")
                                    .font(.caption)
                                    .fontWeight(.medium)
                                    .foregroundColor(Theme.color(.accent, scheme: colorScheme))
                                Text(userDescription)
                                    .font(.callout)
                                    .foregroundColor(Theme.color(.secondaryText, scheme: colorScheme))
                            }
                            .padding(.horizontal)
                        }
                        
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Image(systemName: "chart.bar.fill")
                                    .foregroundColor(Theme.color(.accent, scheme: colorScheme))
                                Text("建议生成依据")
                                    .font(.caption)
                                    .fontWeight(.medium)
                                    .foregroundColor(Theme.color(.accent, scheme: colorScheme))
                            }
                    
                            Grid(alignment: .leading, horizontalSpacing: 12, verticalSpacing: 8) {
                                ForEach(HealthRecord.RecordType.allCases, id: \.self) { type in
                                    GridRow {
                                        Text("\(type.displayName):")
                                            .gridColumnAlignment(.leading)
                                            .font(.caption2)
                                            .foregroundColor(.secondary)
                                        
                                        if let record = healthStore.getLatestRecord(for: type) {
                                            HStack(spacing: 4) {
                                                if type.needsSecondaryValue, let secondaryValue = record.secondaryValue {
                                                    Text("\(String(format: "%.1f", record.value))/\(String(format: "%.1f", secondaryValue)) \(record.unit)")
                                                } else if type == .sleep {
                                                    let hours = Int(record.value)
                                                    let minutes = Int(record.secondaryValue ?? 0)
                                                    Text("\(hours)小时\(minutes)分钟")
                                                } else {
                                                    Text("\(String(format: type == .steps ? "%.0f" : "%.1f", record.value)) \(record.unit)")
                                                }
                                                Text("(\(record.date.formatted(.dateTime.month().day())))")
                                            }
                                            .font(.caption2)
                                            .foregroundColor(.secondary)
                                        } else {
                                            Text("暂无数据")
                                                .font(.caption2)
                                                .foregroundColor(.secondary.opacity(0.7))
                                        }
                                    }
                                }
                            }
                            .padding(.vertical, 8)
                        }
                    }
                }
                .padding(.horizontal)
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
                    generateAdvice() // 切换配置后立即刷新建议
                }
            }
            Button("取消", role: .cancel) {}
        }
    }


    private func generateAdvice() {
        isGeneratingAdvice = true
        adviceText = nil // 清空之前的建议
        
        healthStore.generateHealthAdvice(userDescription: userDescription) { advice in
            DispatchQueue.main.async {
                isGeneratingAdvice = false
                if let advice = advice {
                    adviceText = advice
                    
                    if let currentConfigId = healthStore.userProfile?.selectedAIConfigurationId {
                        print("AI 建议使用配置: \(currentConfigId)")
                    }
                    
                } else {
                    adviceText = "Failed to generate AI advice."
                }
            }
        }
    }
}

#Preview {
    DashboardView(healthStore: HealthStore())
}
