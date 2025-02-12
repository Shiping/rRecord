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
    
    func color(for colorScheme: ColorScheme, accent: ThemeManager.ThemeAccent = .blue) -> Color {
        switch (self, colorScheme, accent) {
        // Light Yellow Theme Colors
        case (.accent, .light, .lightYellow):
            return Color(red: 0.98, green: 0.85, blue: 0.40)  // Light Yellow
        case (.accent, .dark, .lightYellow):
            return Color(red: 0.95, green: 0.82, blue: 0.35)  // Darker Yellow
        case (.accentSecondary, _, .lightYellow):
            return Color(red: 1.0, green: 0.95, blue: 0.70)  // Very Light Yellow
            
        // Light Orange Theme Colors
        case (.accent, .light, .lightOrange):
            return Color(red: 1.0, green: 0.75, blue: 0.45)  // Light Orange
        case (.accent, .dark, .lightOrange):
            return Color(red: 0.95, green: 0.70, blue: 0.40)  // Darker Orange
        case (.accentSecondary, _, .lightOrange):
            return Color(red: 1.0, green: 0.85, blue: 0.70)  // Very Light Orange
            
        // Default Blue Theme Colors
        case (.background, .dark, _):
            return Color(red: 0.08, green: 0.10, blue: 0.18)  // Deep Space Blue
        case (.background, .light, _):
            return Color(red: 0.98, green: 0.98, blue: 1.0)  // Pure Pearl
            
        case (.text, .dark, _):
            return Color(red: 0.96, green: 0.96, blue: 0.98)
        case (.text, .light, _):
            return Color(red: 0.12, green: 0.14, blue: 0.18)
            
        case (.secondaryText, .dark, _):
            return Color(red: 0.75, green: 0.78, blue: 0.85)
        case (.secondaryText, .light, _):
            return Color(red: 0.40, green: 0.45, blue: 0.50)
            
        case (.cardBackground, .dark, _):
            return Color(red: 0.12, green: 0.14, blue: 0.22).opacity(0.85)
        case (.cardBackground, .light, _):
            return Color.white.opacity(0.85)
            
        case (.accent, .dark, .blue):
            return Color(red: 0.38, green: 0.68, blue: 0.92)  // Electric Blue
        case (.accent, .light, .blue):
            return Color(red: 0.20, green: 0.55, blue: 0.85)  // Ocean Blue
            
        case (.accentSecondary, .dark, .blue):
            return Color(red: 0.62, green: 0.82, blue: 0.98)  // Sky Blue
        case (.accentSecondary, .light, .blue):
            return Color(red: 0.45, green: 0.75, blue: 0.95)  // Lake Blue
            
        case (.healthSuccess, .dark, _):
            return Color(red: 0.45, green: 0.82, blue: 0.58)  // Neon Green
        case (.healthSuccess, .light, _):
            return Color(red: 0.32, green: 0.75, blue: 0.45)  // Fresh Green
            
        case (.healthWarning, .dark, _):
            return Color(red: 0.98, green: 0.58, blue: 0.58)  // Bright Coral
        case (.healthWarning, .light, _):
            return Color(red: 0.95, green: 0.45, blue: 0.45)  // Vibrant Red
            
        case (.cardBorder, .dark, _):
            return Color.white.opacity(0.15)
        case (.cardBorder, .light, _):
            return Color.black.opacity(0.08)
            
        // Gradient colors for Light Yellow theme
        case (.gradientStart, .dark, .lightYellow):
            return Color(red: 0.35, green: 0.30, blue: 0.15)
        case (.gradientStart, .light, .lightYellow):
            return Color(red: 1.0, green: 0.95, blue: 0.80)
            
        case (.gradientMid, .dark, .lightYellow):
            return Color(red: 0.40, green: 0.35, blue: 0.20)
        case (.gradientMid, .light, .lightYellow):
            return Color(red: 0.98, green: 0.90, blue: 0.75)
            
        case (.gradientEnd, .dark, .lightYellow):
            return Color(red: 0.30, green: 0.25, blue: 0.10)
        case (.gradientEnd, .light, .lightYellow):
            return Color(red: 0.95, green: 0.85, blue: 0.70)
            
        // Gradient colors for Light Orange theme
        case (.gradientStart, .dark, .lightOrange):
            return Color(red: 0.35, green: 0.25, blue: 0.15)
        case (.gradientStart, .light, .lightOrange):
            return Color(red: 1.0, green: 0.90, blue: 0.80)
            
        case (.gradientMid, .dark, .lightOrange):
            return Color(red: 0.40, green: 0.30, blue: 0.20)
        case (.gradientMid, .light, .lightOrange):
            return Color(red: 0.98, green: 0.85, blue: 0.75)
            
        case (.gradientEnd, .dark, .lightOrange):
            return Color(red: 0.30, green: 0.20, blue: 0.10)
        case (.gradientEnd, .light, .lightOrange):
            return Color(red: 0.95, green: 0.80, blue: 0.70)
            
        // Default Blue theme gradients
        case (.gradientStart, .dark, _):
            return Color(red: 0.15, green: 0.25, blue: 0.45)
        case (.gradientStart, .light, _):
            return Color(red: 0.85, green: 0.90, blue: 1.0)
            
        case (.gradientMid, .dark, _):
            return Color(red: 0.20, green: 0.35, blue: 0.55)
        case (.gradientMid, .light, _):
            return Color(red: 0.90, green: 0.95, blue: 1.0)
            
        case (.gradientEnd, .dark, _):
            return Color(red: 0.12, green: 0.18, blue: 0.35)
        case (.gradientEnd, .light, _):
            return Color(red: 0.95, green: 0.98, blue: 1.0)
            
        @unknown default:
            return .blue
        }
    }
}

class Theme: ObservableObject {
    static let shared = Theme()
    @ObservedObject private var themeManager = ThemeManager()
    
    private init() {
        // Listen for theme changes
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(themeDidChange),
            name: .init("ThemeDidChange"),
            object: nil
        )
    }
    
    @objc private func themeDidChange() {
        DispatchQueue.main.async {
            self.objectWillChange.send()
        }
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    // Static methods for backward compatibility
    static func color(_ themeColor: ThemeColor, scheme: ColorScheme) -> Color {
        shared.color(themeColor, scheme: scheme)
    }
    
    static func gradientBackground(for colorScheme: ColorScheme) -> LinearGradient {
        shared.gradientBackground(for: colorScheme)
    }
    
    static func cardGradient(for colorScheme: ColorScheme) -> LinearGradient {
        shared.cardGradient(for: colorScheme)
    }
    
    // Instance methods
    func color(_ themeColor: ThemeColor, scheme: ColorScheme) -> Color {
        themeColor.color(for: scheme, accent: themeManager.themeAccent)
    }
    
    func gradientBackground(for colorScheme: ColorScheme) -> LinearGradient {
        LinearGradient(
            gradient: Gradient(colors: [
                ThemeColor.gradientStart.color(for: colorScheme, accent: themeManager.themeAccent),
                ThemeColor.gradientMid.color(for: colorScheme, accent: themeManager.themeAccent),
                ThemeColor.gradientEnd.color(for: colorScheme, accent: themeManager.themeAccent)
            ]),
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
    
    func cardGradient(for colorScheme: ColorScheme) -> LinearGradient {
        let baseColor = ThemeColor.cardBackground.color(for: colorScheme, accent: themeManager.themeAccent)
        let accentColor = ThemeColor.accent.color(for: colorScheme, accent: themeManager.themeAccent).opacity(0.05)
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
    @StateObject private var theme = Theme.shared
    
    func body(content: Content) -> some View {
        content
            .padding()
            .background(
                ZStack {
                    RoundedRectangle(cornerRadius: 20)
                        .fill(theme.cardGradient(for: colorScheme))
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
    @StateObject private var theme = Theme.shared
    
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
