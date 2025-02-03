import SwiftUI

struct RefreshControl: View {
    @Binding var isRefreshing: Bool
    @Environment(\.colorScheme) var colorScheme
    let action: () -> Void
    
    var body: some View {
        GeometryReader { geometry in
            if geometry.frame(in: .global).minY > 50 {
                Spacer()
                    .onAppear {
                        if !isRefreshing {
                            action()
                        }
                    }
            }
            HStack {
                Spacer()
                if isRefreshing {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: Theme.color(.accent, scheme: colorScheme)))
                }
                Spacer()
            }
        }
        .frame(height: 50)
    }
}

#Preview {
    RefreshControl(isRefreshing: .constant(true)) {}
}
