import SwiftUI

class Theme: ObservableObject {
    static let shared = Theme()
    
    @Published var accentColor = Color.blue
    @Published var backgroundColor = Color(UIColor.systemBackground)
    @Published var secondaryBackgroundColor = Color(UIColor.secondarySystemBackground)
    @Published var textColor = Color(UIColor.label)
    @Published var secondaryTextColor = Color(UIColor.secondaryLabel)
    
    // Chart colors
    @Published var chartLineColor = Color.blue
    @Published var chartGridColor = Color.gray.opacity(0.2)
    @Published var chartAxisColor = Color.gray
    
    // Status colors
    @Published var goodColor = Color.green
    @Published var warningColor = Color.yellow
    @Published var badColor = Color.red
    @Published var neutralColor = Color.gray
    
    private init() {}
    
    func adaptToColorScheme(_ colorScheme: ColorScheme) {
        backgroundColor = colorScheme == .dark ? Color.black : Color.white
        secondaryBackgroundColor = colorScheme == .dark ? Color(UIColor.systemGray6) : Color(UIColor.systemGray6)
        textColor = colorScheme == .dark ? Color.white : Color.black
        secondaryTextColor = colorScheme == .dark ? Color.gray : Color.gray
        
        chartGridColor = colorScheme == .dark ? Color.gray.opacity(0.3) : Color.gray.opacity(0.2)
        chartAxisColor = colorScheme == .dark ? Color.gray : Color.gray
    }
}

struct ThemeKey: EnvironmentKey {
    static let defaultValue = Theme.shared
}

extension EnvironmentValues {
    var theme: Theme {
        get { self[ThemeKey.self] }
        set { self[ThemeKey.self] = newValue }
    }
}

extension View {
    func theme(_ theme: Theme) -> some View {
        environment(\.theme, theme)
    }
}
