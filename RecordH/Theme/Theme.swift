import SwiftUI

enum ThemeColor {
    case background
    case text
    case secondaryText
    case cardBackground
    case accent
    case accentSecondary
    case healthSuccess
    case healthWarning
    case cardBorder
    case gradientStart
    case gradientMid
    case gradientEnd
    
    func color(for colorScheme: ColorScheme) -> Color {
        switch (self, colorScheme) {
        case (.background, .dark):
            return Color(red: 0.08, green: 0.10, blue: 0.18)  // Deep Space Blue
        case (.background, .light):
            return Color(red: 0.98, green: 0.98, blue: 1.0)  // Pure Pearl
            
        case (.text, .dark):
            return Color(red: 0.96, green: 0.96, blue: 0.98)
        case (.text, .light):
            return Color(red: 0.12, green: 0.14, blue: 0.18)
            
        case (.secondaryText, .dark):
            return Color(red: 0.75, green: 0.78, blue: 0.85)
        case (.secondaryText, .light):
            return Color(red: 0.40, green: 0.45, blue: 0.50)
            
        case (.cardBackground, .dark):
            return Color(red: 0.12, green: 0.14, blue: 0.22).opacity(0.85)
        case (.cardBackground, .light):
            return Color.white.opacity(0.85)
            
        case (.accent, .dark):
            return Color(red: 0.38, green: 0.68, blue: 0.92)  // Electric Blue
        case (.accent, .light):
            return Color(red: 0.20, green: 0.55, blue: 0.85)  // Ocean Blue
            
        case (.accentSecondary, .dark):
            return Color(red: 0.62, green: 0.82, blue: 0.98)  // Sky Blue
        case (.accentSecondary, .light):
            return Color(red: 0.45, green: 0.75, blue: 0.95)  // Lake Blue
            
        case (.healthSuccess, .dark):
            return Color(red: 0.45, green: 0.82, blue: 0.58)  // Neon Green
        case (.healthSuccess, .light):
            return Color(red: 0.32, green: 0.75, blue: 0.45)  // Fresh Green
            
        case (.healthWarning, .dark):
            return Color(red: 0.98, green: 0.58, blue: 0.58)  // Bright Coral
        case (.healthWarning, .light):
            return Color(red: 0.95, green: 0.45, blue: 0.45)  // Vibrant Red
            
        case (.cardBorder, .dark):
            return Color.white.opacity(0.15)
        case (.cardBorder, .light):
            return Color.black.opacity(0.08)
            
        case (.gradientStart, .dark):
            return Color(red: 0.15, green: 0.25, blue: 0.45)
        case (.gradientStart, .light):
            return Color(red: 0.85, green: 0.90, blue: 1.0)
            
        case (.gradientMid, .dark):
            return Color(red: 0.20, green: 0.35, blue: 0.55)
        case (.gradientMid, .light):
            return Color(red: 0.90, green: 0.95, blue: 1.0)
            
        case (.gradientEnd, .dark):
            return Color(red: 0.12, green: 0.18, blue: 0.35)
        case (.gradientEnd, .light):
            return Color(red: 0.95, green: 0.98, blue: 1.0)
            
        @unknown default:
            return .blue
        }
    }
}

struct Theme {
    static func color(_ themeColor: ThemeColor, scheme: ColorScheme) -> Color {
        themeColor.color(for: scheme)
    }
    
    static func gradientBackground(for colorScheme: ColorScheme) -> LinearGradient {
        LinearGradient(
            gradient: Gradient(colors: [
                ThemeColor.gradientStart.color(for: colorScheme),
                ThemeColor.gradientMid.color(for: colorScheme),
                ThemeColor.gradientEnd.color(for: colorScheme)
            ]),
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
    
    static func cardGradient(for colorScheme: ColorScheme) -> LinearGradient {
        let baseColor = ThemeColor.cardBackground.color(for: colorScheme)
        let accentColor = ThemeColor.accent.color(for: colorScheme).opacity(0.05)
        return LinearGradient(
            gradient: Gradient(colors: [
                baseColor,
                baseColor.opacity(0.95),
                accentColor
            ]),
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
}

struct ModernCard: ViewModifier {
    @Environment(\.colorScheme) var colorScheme
    
    func body(content: Content) -> some View {
        content
            .padding()
            .background(
                ZStack {
                    RoundedRectangle(cornerRadius: 20)
                        .fill(Theme.cardGradient(for: colorScheme))
                        .overlay(
                            RoundedRectangle(cornerRadius: 20)
                                .stroke(
                                    LinearGradient(
                                        gradient: Gradient(colors: [
                                            Theme.color(.accent, scheme: colorScheme).opacity(0.2),
                                            Theme.color(.accent, scheme: colorScheme).opacity(0.1)
                                        ]),
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    ),
                                    lineWidth: 1.5
                                )
                        )
                }
            )
            .shadow(
                color: Theme.color(.accent, scheme: colorScheme).opacity(colorScheme == .dark ? 0.2 : 0.1),
                radius: colorScheme == .dark ? 12 : 8,
                x: 0,
                y: colorScheme == .dark ? 6 : 4
            )
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
