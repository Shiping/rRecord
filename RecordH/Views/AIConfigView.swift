import SwiftUI

@available(*, deprecated, message: "Use AIConfigList instead")
struct AIConfigView: View {
    var body: some View {
        AIConfigList()
    }
}

#Preview {
    NavigationStack {
        AIConfigView()
            .environmentObject(AIConfigurationManager.shared)
            .environmentObject(AIManager.shared)
    }
}
