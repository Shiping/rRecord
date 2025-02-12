import SwiftUI

struct RefreshControl: View {
    @Binding var isRefreshing: Bool
    @Environment(\.colorScheme) var colorScheme
    @StateObject private var theme = Theme.shared
    let action: () -> Void
    
    @State private var pullTriggered = false
    
    var body: some View {
        GeometryReader { geometry in
            let pullDistance = geometry.frame(in: .global).minY
            let threshold: CGFloat = 70
            
            if pullDistance > threshold && !pullTriggered {
                Color.clear
                    .preference(key: RefreshPreferenceKey.self, value: true)
                    .onAppear {
                        pullTriggered = true
                        if !isRefreshing {
                            action()
                        }
                    }
            } else if pullDistance <= 0 {
                Color.clear
                    .preference(key: RefreshPreferenceKey.self, value: false)
                    .onAppear {
                        pullTriggered = false
                    }
            }
            
            HStack {
                Spacer()
                if isRefreshing {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: theme.color(.accent, scheme: colorScheme)))
                } else if pullDistance > 0 {
                    Image(systemName: "arrow.down")
                        .foregroundColor(theme.color(.accent, scheme: colorScheme))
                        .rotationEffect(.degrees((min(pullDistance, threshold) / threshold) * 180.0))
                }
                Spacer()
            }
        }
        .frame(height: 50)
    }
}

private struct RefreshPreferenceKey: PreferenceKey {
    static var defaultValue: Bool = false
    
    static func reduce(value: inout Bool, nextValue: () -> Bool) {
        value = nextValue()
    }
}

#Preview {
    RefreshControl(isRefreshing: .constant(true)) {}
}
