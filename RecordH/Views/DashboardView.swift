import SwiftUI

struct DashboardView: View {
    @EnvironmentObject var healthStore: HealthStore
    @Environment(\.colorScheme) var colorScheme
    @State private var noteToEdit: DailyNote? = nil
    @State private var isRefreshing = false
    @State private var hasInitiallyLoaded = false // Tracks if initial data load has occurred
    @State private var isFirstRefresh = true // Tracks first manual refresh

    var body: some View {
        NavigationView {
            ScrollView {
                VStack {
                    RefreshControl(isRefreshing: $isRefreshing) {
                        refreshData()
                    }
                    VStack(spacing: 20) {
                        // Latest Metrics Grid
                        LatestMetricsGrid()
                            .environmentObject(healthStore)
                            .padding(.horizontal)

                        // Daily Notes Section
                        HStack {
                            Text("今日笔记")
                                .font(.title2)
                                .fontWeight(.bold)
                                .foregroundColor(Theme.color(.text, scheme: colorScheme))

                            Spacer()

                            Button(action: {
                                noteToEdit = DailyNote(content: "", tags: [])
                            }) {
                                HStack {
                                    Image(systemName: "plus.circle.fill")
                                    Text("添加笔记")
                                }
                            }
                            .foregroundColor(Theme.color(.accent, scheme: colorScheme))

                            NavigationLink(destination: AllNotesView().environmentObject(healthStore)) {
                                HStack {
                                    Image(systemName: "list.bullet")
                                    Text("查看全部")
                                }
                                .foregroundColor(Theme.color(.accent, scheme: colorScheme))
                            }
                        }
                        .padding(.horizontal)

                        RecentNotesSection(
                            noteToEdit: $noteToEdit
                        )
                        .environmentObject(healthStore)
                        .padding()
                    }
                }
                .sheet(item: $noteToEdit) { note in
                    AddNoteView(noteToEdit: note)
                        .environmentObject(healthStore)
                }
                .onChange(of: noteToEdit) { oldValue, newValue in
                    if oldValue != nil && newValue == nil {
                        // Note sheet was dismissed, refresh data
                        self.refreshData()
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
                // Load data only once when the view first appears
                if !hasInitiallyLoaded {
                    refreshData()
                    hasInitiallyLoaded = true
                }
            }
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    HStack {
                        Button(action: {
                            refreshData()
                        }) {
                            Image(systemName: "arrow.clockwise")
                                .foregroundColor(Theme.color(.accent, scheme: colorScheme))
                        }
                        NavigationLink(destination: ProfileView()) {
                            Image(systemName: "person.circle")
                                .foregroundColor(Theme.color(.accent, scheme: colorScheme))
                        }
                    }
                }
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: .init("NotesDidUpdate"))) { _ in
            // Refresh data when notes are updated
            self.refreshData()
        }
    }

    private func refreshData() {
        // Prevent refresh if already refreshing
        guard !isRefreshing else { return }
        
        // If this isn't the first app launch and we've already done one manual refresh, skip
        if hasInitiallyLoaded && !isFirstRefresh {
            return
        }
        
        isRefreshing = true
        healthStore.refreshHealthData {
            DispatchQueue.main.async {
                self.isRefreshing = false
                self.isFirstRefresh = false // Mark first manual refresh as complete
                print("Data refreshed, notes count: \(self.healthStore.dailyNotes.count)")
            }
        }
    }
}
