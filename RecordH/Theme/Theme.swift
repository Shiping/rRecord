import SwiftUI

enum ThemeColor {
    case background
    case text
    case secondaryText
    case cardBackground
    case accent
    
    func color(for colorScheme: ColorScheme) -> Color {
        switch (self, colorScheme) {
        case (.background, .dark):
            return Color(red: 0.18, green: 0.20, blue: 0.22)  // Space Gray
        case (.background, .light):
            return Color(red: 0.95, green: 0.95, blue: 0.97)  // Light Gray
            
        case (.text, .dark):
            return .white
        case (.text, .light):
            return Color(red: 0.1, green: 0.1, blue: 0.1)
            
        case (.secondaryText, .dark):
            return Color.gray
        case (.secondaryText, .light):
            return Color(red: 0.4, green: 0.4, blue: 0.4)
            
        case (.cardBackground, .dark):
            return Color(red: 0.22, green: 0.24, blue: 0.26)
        case (.cardBackground, .light):
            return .white
            
        case (.accent, _):
            return .blue
            
        @unknown default:
            return .blue // Default fallback color
        }
    }
}

struct Theme {
    static func color(_ themeColor: ThemeColor, scheme: ColorScheme) -> Color {
        themeColor.color(for: scheme)
    }
    
    static func gradientBackground(for colorScheme: ColorScheme) -> LinearGradient {
        let baseColor = ThemeColor.background.color(for: colorScheme)
        return LinearGradient(
            gradient: Gradient(colors: [baseColor, baseColor.opacity(0.8)]),
            startPoint: .top,
            endPoint: .bottom
        )
    }
}

struct ModernCard: ViewModifier {
    @Environment(\.colorScheme) var colorScheme
    
    func body(content: Content) -> some View {
        content
            .padding()
            .background(Theme.color(.cardBackground, scheme: colorScheme))
            .cornerRadius(15)
            .shadow(radius: colorScheme == .dark ? 5 : 2)
    }
}

struct ModernButton: ViewModifier {
    @Environment(\.colorScheme) var colorScheme
    
    func body(content: Content) -> some View {
        content
            .padding()
            .background(Theme.color(.accent, scheme: colorScheme))
            .foregroundColor(.white)
            .cornerRadius(10)
            .shadow(radius: colorScheme == .dark ? 3 : 1)
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
