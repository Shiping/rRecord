import SwiftUI
import SafariServices

struct MedicalReferencesView: View {
    @Environment(\.theme) var theme
    let metric: HealthMetric?
    
    var references: [MedicalReference] {
        if let metric = metric {
            return MedicalReferences.referencesFor(metric: metric)
        }
        return MedicalReferences.references
    }
    
    var body: some View {
        List(references) { reference in
            ReferenceRow(reference: reference)
        }
        .navigationTitle("医学参考")
    }
}

struct ReferenceRow: View {
    let reference: MedicalReference
    @Environment(\.theme) var theme
    @State private var showingSafariView = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(reference.title)
                .font(.headline)
                .foregroundColor(theme.textColor)
            
            Text(reference.description)
                .font(.body)
                .foregroundColor(theme.secondaryTextColor)
                .fixedSize(horizontal: false, vertical: true)
            
            HStack {
                Text(reference.source)
                    .font(.caption)
                    .foregroundColor(theme.secondaryTextColor)
                
                if let url = reference.url {
                    Spacer()
                    Button("查看来源") {
                        showingSafariView = true
                    }
                    .font(.caption)
                    .foregroundColor(theme.accentColor)
                }
            }
        }
        .padding(.vertical, 4)
        .sheet(isPresented: $showingSafariView) {
            if let url = reference.url {
                SafariView(url: url)
            }
        }
    }
}

struct SafariView: UIViewControllerRepresentable {
    let url: URL
    
    func makeUIViewController(context: Context) -> SFSafariViewController {
        SFSafariViewController(url: url)
    }
    
    func updateUIViewController(_ uiViewController: SFSafariViewController, context: Context) {
    }
}

#Preview {
    NavigationStack {
        MedicalReferencesView(metric: nil)
    }
}
