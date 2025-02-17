import SwiftUI

struct MedicalReferencesView: View {
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        List {
            Section(header: Text("健康指标参考来源")) {
                ForEach(HealthRecord.RecordType.allCases.filter { MedicalReferences.references[$0] != nil }, id: \.self) { type in
                    if let reference = MedicalReferences.references[type] {
                        VStack(alignment: .leading, spacing: 8) {
                            Text(type.displayName)
                                .font(.headline)
                                .foregroundColor(Theme.color(.accent, scheme: colorScheme))
                            
                            VStack(alignment: .leading, spacing: 4) {
                                Text("参考数据来源：\(reference.source)")
                                    .font(.subheadline)
                                Text("发布机构：\(reference.organization)")
                                    .font(.subheadline)
                                Text("发布年份：\(reference.year)")
                                    .font(.subheadline)
                                Text("正常范围：\(reference.normalRange)")
                                    .font(.subheadline)
                                Link("查看原文", destination: URL(string: reference.url)!)
                                    .font(.subheadline)
                                    .foregroundColor(Theme.color(.accent, scheme: colorScheme))
                            }
                            .foregroundColor(Theme.color(.text, scheme: colorScheme))
                        }
                        .padding(.vertical, 8)
                    }
                }
            }
            
            Section(header: Text("免责声明")) {
                Text(MedicalReferences.disclaimer)
                    .font(.subheadline)
                    .foregroundColor(Theme.color(.text, scheme: colorScheme))
                    .padding(.vertical, 8)
            }
        }
        .navigationTitle("医学参考")
    }
}

#Preview {
    NavigationView {
        MedicalReferencesView()
    }
}
