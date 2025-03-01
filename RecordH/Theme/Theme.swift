import SwiftUI

@MainActor
public final class Theme: ObservableObject {
    @MainActor
    public static let shared: Theme = {
        let instance = Theme()
        return instance
    }()
    
    // MARK: - Colors
    public let accentColor = Color.blue
    public let textColor = Color.primary
    public let secondaryTextColor = Color.secondary
    public let backgroundColor = Color(UIColor.systemBackground)
    public let cardBackground = Color(UIColor.secondarySystemBackground)
    public let goodColor = Color.green
    public let warningColor = Color.yellow
    public let badColor = Color.red
    public let neutralColor = Color.gray
    public let chartLineColor = Color.blue.opacity(0.6)
    public let chartGridColor = Color.gray.opacity(0.2)
    
    // MARK: - Dimensions
    public let cornerRadius: CGFloat = 10
    public let padding: CGFloat = 16
    public let spacing: CGFloat = 8
    
    // MARK: - Animations
    public let defaultAnimation = Animation.easeInOut
    public let quickAnimation = Animation.easeInOut(duration: 0.2)
    
    private init() {
        // Private init for singleton
    }
}

// MARK: - Environment Support
private struct ThemeKey: EnvironmentKey {
    @MainActor
    static var defaultValue: Theme {
        Theme.shared
    }
}

extension EnvironmentValues {
    public var theme: Theme {
        get { self[ThemeKey.self] }
        set { self[ThemeKey.self] = newValue }
    }
}
