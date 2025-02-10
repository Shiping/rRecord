import SwiftUI

struct DashboardView: View {
    @ObservedObject var healthStore: HealthStore
    @Environment(\.colorScheme) var colorScheme
    @State private var showingAddNote = false
    @State private var noteToEdit: DailyNote? = nil
    @State private var isRefreshing = false
    @State private var hasInitiallyLoaded = false
    
    var body: some View {
        NavigationView {
             ScrollView {
                 VStack {
                     RefreshControl(isRefreshing: $isRefreshing) {
                         refreshData()
                     }
                     VStack(spacing: 20) {
                        // Latest Metrics Grid
                        LatestMetricsGrid(healthStore: healthStore)
                            .padding(.horizontal)
                        
                        // Daily Notes Section
                        RecentNotesSection(
                            healthStore: healthStore,
                            showingAddNote: $showingAddNote,
                            noteToEdit: $noteToEdit
                        )
                        .padding()
                        
                        // Daily Recommendations
                        DailyRecommendationsView(healthStore: healthStore)
                            .padding()
                    }
                }
                .simultaneousGesture(
                    DragGesture()
                        .onEnded { _ in
                            UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
                        }
                )
             }
             .background(Theme.gradientBackground(for: colorScheme))
            .navigationTitle("健康记录")
            .onAppear {
                if !hasInitiallyLoaded {
                    refreshData()
                    hasInitiallyLoaded = true
                }
            }
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    HStack {
                        Button(action: refreshData) {
                            Image(systemName: "arrow.clockwise")
                                .foregroundColor(Theme.color(.accent, scheme: colorScheme))
                        }
                        NavigationLink(destination: ProfileView(healthStore: healthStore)) {
                            Image(systemName: "person.circle")
                                .foregroundColor(Theme.color(.accent, scheme: colorScheme))
                        }
                    }
                }
            }
            .sheet(isPresented: $showingAddNote) {
                AddNoteView(healthStore: healthStore, noteToEdit: noteToEdit)
            }
        }
    }
    
    private func refreshData() {
        isRefreshing = true
        _ = healthStore.userProfile
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            healthStore.refreshHealthData()
            DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                isRefreshing = false
            }
        }
    }
}
