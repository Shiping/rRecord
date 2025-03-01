import SwiftUI

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        DashboardView()
            .environmentObject(HealthStore.shared)
            .environmentObject(AIManager.shared)
            .environmentObject(AIConfigurationManager.shared)
            .environment(\.theme, Theme.shared)
    }
}
