import SwiftUI

struct RefreshableScrollView<Content: View>: View {
    @Binding var isRefreshing: Bool
    let onRefresh: () async -> Void
    let content: Content
    
    init(
        isRefreshing: Binding<Bool>,
        @ViewBuilder content: () -> Content,
        onRefresh: @escaping () async -> Void
    ) {
        self._isRefreshing = isRefreshing
        self.onRefresh = onRefresh
        self.content = content()
    }
    
    var body: some View {
        if #available(iOS 15.0, *) {
            ScrollView {
                content
            }
            .refreshable {
                isRefreshing = true
                await onRefresh()
                isRefreshing = false
            }
        } else {
            ScrollView {
                content
            }
        }
    }
}
