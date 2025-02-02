import SwiftUI

enum Theme {
    static let spaceGray = Color(red: 0.18, green: 0.20, blue: 0.22)
    static let background = spaceGray
    static let accent = Color.blue
    static let text = Color.white
    static let secondaryText = Color.gray
    
    static let cardBackground = Color(red: 0.22, green: 0.24, blue: 0.26)
    
    static func gradientBackground() -> LinearGradient {
        LinearGradient(
            gradient: Gradient(colors: [spaceGray, spaceGray.opacity(0.8)]),
            startPoint: .top,
            endPoint: .bottom
        )
    }
}

struct ModernCard: ViewModifier {
    func body(content: Content) -> some View {
        content
            .padding()
            .background(Theme.cardBackground)
            .cornerRadius(15)
            .shadow(radius: 5)
    }
}

struct ModernButton: ViewModifier {
    func body(content: Content) -> some View {
        content
            .padding()
            .background(Theme.accent)
            .foregroundColor(.white)
            .cornerRadius(10)
            .shadow(radius: 3)
    }
}

extension View {
    func modernCard() -> some View {
        modifier(ModernCard())
    }
    
    func modernButton() -> some View {
        modifier(ModernButton())
    }
}
