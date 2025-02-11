import SwiftUI

class ThemeManager: ObservableObject {
    @AppStorage("userTheme") private var userTheme: String = "system"
    @Published var colorScheme: ColorScheme?
    @Published var themeAccent: ThemeAccent = .blue
    
    enum ThemeAccent: String, CaseIterable, Identifiable {
        case blue = "blue"
        case lightYellow = "lightYellow"
        case lightOrange = "lightOrange"

        var id: String { rawValue }
    }
    
    var currentTheme: String {
        get { userTheme }
        set {
            userTheme = newValue
            updateTheme()
        }
    }
    
    var currentAccent: ThemeAccent {
        get { themeAccent }
        set {
            themeAccent = newValue
            UserDefaults.standard.set(newValue.rawValue, forKey: "themeAccent")
        }
    }
    
    init() {
        print("Initializing ThemeManager")
        if let savedAccent = UserDefaults.standard.string(forKey: "themeAccent"),
           let accent = ThemeAccent(rawValue: savedAccent) {
            themeAccent = accent
        }
        updateTheme()
    }
    
    private func updateTheme() {
        switch userTheme {
        case "light":
            colorScheme = .light
        case "dark":
            colorScheme = .dark
        default:
            colorScheme = nil // System default
        }
    }
}
