//
//  ContentView.swift
//  RecordH
//
//  Created by liushiping on 2025/2/1.
//

import SwiftUI

struct ContentView: View {
    @EnvironmentObject private var healthStore: HealthStore
    @EnvironmentObject private var themeManager: ThemeManager
    @AppStorage("hasGrantedHealthKitPermission") private var hasGrantedPermission = false
    
    var body: some View {
        Group {
            if hasGrantedPermission {
                DashboardView()
                    .environmentObject(healthStore)
                    .environmentObject(themeManager)
                    .preferredColorScheme(themeManager.colorScheme)
                    .navigationViewStyle(StackNavigationViewStyle())
            } else {
                WelcomeView(hasGrantedPermission: $hasGrantedPermission)
                    .environmentObject(healthStore)
                    .environmentObject(themeManager)
                    .preferredColorScheme(themeManager.colorScheme)
                    .navigationViewStyle(StackNavigationViewStyle())
            }
        }
    }
}

#Preview {
    ContentView()
        .environmentObject(HealthStore())
        .environmentObject(ThemeManager())
}
