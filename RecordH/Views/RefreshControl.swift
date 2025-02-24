import SwiftUI

struct RefreshControl: View {
    let isRefreshing: Bool
    let onRefresh: () async -> Void
    
    @Environment(\.theme) var theme
    @State private var offset: CGFloat = 0
    @State private var isRefreshTriggered = false
    
    private let threshold: CGFloat = 60
    
    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .center) {
                if isRefreshing {
                    ProgressView()
                        .tint(theme.accentColor)
                } else {
                    Image(systemName: "arrow.clockwise")
                        .foregroundColor(theme.accentColor)
                        .rotationEffect(.degrees(rotationAngle))
                }
            }
            .frame(maxWidth: .infinity)
            .offset(y: -offset)
            .onChange(of: offset) { _, newOffset in
                // Check if we've crossed the threshold and haven't already triggered
                if newOffset > threshold && !isRefreshTriggered && !isRefreshing {
                    isRefreshTriggered = true
                    Task {
                        await onRefresh()
                        isRefreshTriggered = false
                    }
                }
            }
            .onAppear {
                offset = geometry.frame(in: .global).minY
            }
        }
        .frame(height: 50)
    }
    
    private var rotationAngle: Double {
        min(offset / threshold * 180, 180)
    }
}

struct MyRefreshableScrollView<Content: View>: View {
    let content: Content
    let isRefreshing: Bool
    let onRefresh: () async -> Void
    
    init(isRefreshing: Bool = false,
         onRefresh: @escaping () async -> Void,
         @ViewBuilder content: () -> Content) {
        self.isRefreshing = isRefreshing
        self.onRefresh = onRefresh
        self.content = content()
    }
    
    var body: some View {
        ScrollView {
            RefreshControl(isRefreshing: isRefreshing, onRefresh: onRefresh)
            content
        }
    }
}

#Preview {
    MyRefreshableScrollView(isRefreshing: false) {
        try? await Task.sleep(nanoseconds: 2_000_000_000)
    } content: {
        VStack(spacing: 20) {
            ForEach(0..<10) { i in
                Text("Item \(i)")
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.gray.opacity(0.1))
                    .cornerRadius(10)
            }
        }
        .padding()
    }
}
