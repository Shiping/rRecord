//
//  ContentView.swift
//  RecordH
//
//  Created by liushiping on 2025/2/1.
//

import SwiftUI

struct ContentView: View {
    @EnvironmentObject var healthStore: HealthStore
    @State private var showingWelcome = true
    
    var body: some View {
        if showingWelcome {
            WelcomeView(isPresented: $showingWelcome)
                .environmentObject(healthStore)
        } else {
            NavigationStack {
                DashboardView()
                    .environmentObject(healthStore)
            }
        }
    }
}

#Preview {
    ContentView()
        .environmentObject(HealthStore())
}
