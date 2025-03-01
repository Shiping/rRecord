import SwiftUI
import HealthKit

@main
struct RecordHApp: App {
    @State private var theme: Theme?
    @State private var healthStore: HealthStore?
    @State private var aiManager: AIManager?
    @State private var configManager: AIConfigurationManager?
    
    @State private var showingWelcome = false
    @State private var isInitializing = true
    @Environment(\.scenePhase) private var scenePhase
    
    var body: some Scene {
        WindowGroup {
            Group {
                if isInitializing || theme == nil {
                    ProgressView("初始化中...")
                        .progressViewStyle(CircularProgressViewStyle())
                } else if showingWelcome {
                    WelcomeView(isPresented: $showingWelcome)
                        .environmentObject(healthStore!)
                        .environment(\.theme, theme!)
                        .environmentObject(configManager!)
                } else {
                    NavigationStack {
                        DashboardView()
                            .environmentObject(healthStore!)
                            .environment(\.theme, theme!)
                            .environmentObject(configManager!)
                            .environmentObject(aiManager!)
                    }
                }
            }
            .task {
                // Initialize managers if not already done
                if theme == nil || healthStore == nil || configManager == nil || aiManager == nil {
                    await initializeManagers()
                }
            }
            .onAppear {
                checkFirstLaunch()
            }
            .onChange(of: scenePhase) { _, newPhase in
                Task {
                    switch newPhase {
                    case .active:
                        if !isInitializing, let healthStore = healthStore {
                            let hasPermission = await requestAccess(healthStore)
                            if hasPermission {
                                await healthStore.refreshData()
                            }
                        }
                    case .background:
                        break
                    default:
                        break
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
    
    private func initializeManagers() async {
        // Initialize managers in dependency order
        theme = Theme.shared
        configManager = AIConfigurationManager.shared
        aiManager = AIManager.shared
        healthStore = HealthStore.shared
        
        if HKHealthStore.isHealthDataAvailable(), let healthStore = healthStore {
            _ = await requestAccess(healthStore)
        }
        
        isInitializing = false
    }
    
    private func requestAccess(_ healthStore: HealthStore) async -> Bool {
        do {
            return try await healthStore.requestAccess()
        } catch {
            print("Health access request failed: \(error)")
            return false
        }
    }
}
