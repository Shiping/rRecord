import SwiftUI

struct MedicalReferencesView: View {
    @Environment(\.theme) var theme
    
    private var metricsWithReferences: [HealthMetric] {
        HealthMetric.allCases.filter { 
            MedicalReferences.references[$0] != nil 
        }
    }
    
    var body: some View {
        List {
            Section(header: Text("健康指标参考范围")) {
                ForEach(metricsWithReferences, id: \.self) { metric in
                    let reference = MedicalReferences.references[metric]!
                    VStack(alignment: .leading, spacing: 8) {
                        Text(metric.name)
                            .font(.headline)
                            .foregroundColor(theme.accentColor)
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text("正常范围：\(reference.lowerBound.formatted()) - \(reference.upperBound.formatted()) \(reference.unit)")
                                .font(.subheadline)
                                .foregroundColor(theme.textColor)
                        }
                    }
                    .padding(.vertical, 8)
                }
            }
        }
        .navigationTitle("指标参考")
    }
}

#Preview {
    NavigationView {
        MedicalReferencesView()
    }
}
