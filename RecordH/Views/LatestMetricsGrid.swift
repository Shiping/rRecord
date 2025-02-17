import SwiftUI

// MARK: - MetricsGrid and Cards
struct LatestMetricsGrid: View {
    @EnvironmentObject var healthStore: HealthStore
    @Environment(\.colorScheme) var colorScheme
    
    @State private var showingAddRecord = false
    @State private var selectedType: HealthRecord.RecordType?
    
    var body: some View {
        VStack(spacing: 15) {
            ForEach(HealthRecord.RecordType.allCases, id: \.self) { type in
                ZStack(alignment: .topTrailing) {
                    NavigationLink(destination: HealthMetricDetailView(type: type).environmentObject(healthStore)) {
                        MetricCardWrapper(type: type)
                            .environmentObject(healthStore)
                            .foregroundColor(Theme.color(.text, scheme: colorScheme))
                    }
                    
                    Button(action: {
                        selectedType = type
                        showingAddRecord = true
                    }) {
                        Image(systemName: "plus.circle.fill")
                            .font(.title2)
                            .foregroundColor(Theme.color(.accent, scheme: colorScheme))
                            .background(Circle().fill(Theme.color(.cardBackground, scheme: colorScheme)))
                    }
                    .padding(8)
                    .zIndex(1) // Ensure button is above the NavigationLink
                }
                .frame(maxWidth: .infinity)
            }
        }
        .padding([.horizontal, .top])
        .sheet(isPresented: $showingAddRecord) {
            if let type = selectedType {
                AddRecordSheet(type: type, isPresented: $showingAddRecord)
                    .environmentObject(healthStore)
            }
        }
    }
}

private struct MetricCardWrapper: View {
    let type: HealthRecord.RecordType
    @EnvironmentObject var healthStore: HealthStore
    
    var body: some View {
        let record = healthStore.getLatestRecord(for: type)
        MetricCard(type: type, record: record)
            .environmentObject(healthStore)
    }
}

private struct StatusIcon {
    let icon: String
    let color: Color
}

struct MetricCard: View {
    @EnvironmentObject var healthStore: HealthStore
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
        HStack(spacing: 16) {
            // Icon
            Image(systemName: iconName)
                .font(.system(size: 24, weight: .medium))
                .foregroundColor(Theme.color(.accent, scheme: colorScheme))
                .frame(width: 48, height: 48)
                .background(
                    ZStack {
                        Circle()
                            .fill(Theme.color(.accent, scheme: colorScheme).opacity(0.1))
                        Circle()
                            .stroke(Theme.color(.accent, scheme: colorScheme).opacity(0.2), lineWidth: 1.5)
                            .scaleEffect(isHovered ? 1.2 : 1.0)
                            .opacity(isHovered ? 0 : 1)
                            .animation(.easeInOut(duration: 1).repeatForever(autoreverses: false), value: isHovered)
                    }
                )
                .onAppear { isHovered = true }
            
            // Content
            VStack(alignment: .leading, spacing: 4) {
                // Metric name
                Text(type.displayName)
                    .font(.subheadline)
                    .foregroundColor(Theme.color(.secondaryText, scheme: colorScheme))
                    .textSelection(.enabled)
                
                if let record = record {
                    // Value
                    Group {
                        if type.needsSecondaryValue, let secondaryValue = record.secondaryValue {
                            Text("\(String(format: "%.1f", record.value))/\(String(format: "%.1f", secondaryValue)) \(record.unit)")
                        } else if type == .sleep {
                            let hours = Int(record.value)
                            let minutes = Int(record.secondaryValue ?? 0)
                            Text("\(hours)小时\(minutes)分钟")
                        } else {
                            Text("\(String(format: type == .steps ? "%.0f" : "%.1f", record.value)) \(record.unit)")
                        }
                    }
                    .font(.title3)
                    .fontWeight(.medium)
                    .textSelection(.enabled)
                    
                    // Status
                    if type == .steps || type == .sleep || type == .activeEnergy ||
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
                .textSelection(.enabled)
                        }
                    }
                    
                    // Date
                    Text(record.date.formatted(.dateTime.month().day()))
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .textSelection(.enabled)
                } else {
                    Text("暂无数据")
                        .foregroundColor(.secondary)
                        .textSelection(.enabled)
                }
            }
            
            Spacer()
            
            // Trend visualization
            let records = healthStore.getRecords(for: type, limit: 7)
            if !records.isEmpty {
                MinimalTrendLine(
                    values: Array(records.map { $0.value }.reversed()),
                    accentColor: Theme.color(.accent, scheme: colorScheme).opacity(0.5)
                )
                .frame(width: 60, height: 30)
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity)
        .background(Theme.color(.cardBackground, scheme: colorScheme))
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Theme.color(.cardBorder, scheme: colorScheme), lineWidth: 1)
        )
    }
}
