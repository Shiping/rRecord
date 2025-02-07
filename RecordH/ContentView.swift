//
//  ContentView.swift
//  RecordH
//
//  Created by liushiping on 2025/2/1.
//

import SwiftUI

struct ContentView: View {
    @StateObject private var healthStore = HealthStore()
    @StateObject private var themeManager = ThemeManager()
    @AppStorage("hasGrantedHealthKitPermission") private var hasGrantedPermission = false
    
    var body: some View {
        Group {
            if hasGrantedPermission {
                DashboardView(healthStore: healthStore)
                    .preferredColorScheme(themeManager.colorScheme)
                    .environmentObject(themeManager)
                    // Fix NavigationView style for iPad
                    .navigationViewStyle(StackNavigationViewStyle())
            } else {
                WelcomeView(healthStore: healthStore, hasGrantedPermission: $hasGrantedPermission)
                    .preferredColorScheme(themeManager.colorScheme)
                    .environmentObject(themeManager)
                    // Fix NavigationView style for iPad
                    .navigationViewStyle(StackNavigationViewStyle())
            }
        }
    }
}

#Preview {
    ContentView()
}
