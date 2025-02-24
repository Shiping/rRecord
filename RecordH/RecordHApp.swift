import SwiftUI
import HealthKit

@main
struct RecordHApp: App {
    @StateObject private var healthStore = HealthStore.shared
    @StateObject private var theme = Theme.shared
    @StateObject private var aiManager = AIManager.shared
    @Environment(\.scenePhase) private var scenePhase
    @State private var showingWelcome = false
    @State private var isInitializing = true
    
    var body: some Scene {
        WindowGroup {
            ZStack {
                if isInitializing {
                    ProgressView("初始化中...")
                        .progressViewStyle(CircularProgressViewStyle())
                } else if showingWelcome {
                    WelcomeView(isPresented: $showingWelcome)
                        .environmentObject(healthStore)
                        .environment(\.theme, theme)
                } else {
                    NavigationStack {
                        DashboardView()
                            .environmentObject(healthStore)
                            .environment(\.theme, theme)
                            .environmentObject(aiManager)
                    }
                }
            }
            .onAppear {
                checkFirstLaunch()
                Task {
                    await initializeApp()
                }
            }
            .onChange(of: scenePhase) { _, newPhase in
                Task {
                    do {
                        switch newPhase {
                        case .active:
                            if !isInitializing {
                                try await healthStore.ensureAuthorization()
                                await healthStore.refreshData()
                            }
                        case .background:
                            healthStore.saveData()
                        default:
                            break
                        }
                    } catch {
                        print("Scene phase change error: \(error)")
                    }
                }
            }
        }
    }
    
    private func checkFirstLaunch() {
        let hasLaunched = UserDefaults.standard.bool(forKey: "hasLaunched")
        if !hasLaunched {
            showingWelcome = true
            UserDefaults.standard.set(true, forKey: "hasLaunched")
        }
    }
    
    private func initializeApp() async {
        do {
            if HKHealthStore.isHealthDataAvailable() {
                try await healthStore.ensureAuthorization()
            }
            isInitializing = false
        } catch {
            print("Initialization error: \(error)")
            isInitializing = false
        }
    }
}
