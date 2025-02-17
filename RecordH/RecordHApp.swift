//
//  RecordHApp.swift
//  RecordH
//
//  Created by liushiping on 2025/2/1.
//

import SwiftUI

@main
struct RecordHApp: App {
    @StateObject private var healthStore = HealthStore()
    @StateObject private var themeManager = ThemeManager()
    @State private var showLaunchScreen = true
    
    var body: some Scene {
        WindowGroup {
            Group {
                if showLaunchScreen {
                    LaunchScreenView()
                } else {
                    ContentView()
                        .environmentObject(healthStore)
                        .environmentObject(themeManager)
                }
            }
            .task {
                // Initialize HealthStore
                try? await Task.sleep(nanoseconds: 1_000_000_000) // Show launch screen for 1 second
                healthStore.loadData()
                
                withAnimation {
                    showLaunchScreen = false
                }
            }
        }
    }
}
