import SwiftUI

class ThemeManager: ObservableObject {
    @AppStorage("userTheme") private var userTheme: String = "system"
    @Published var colorScheme: ColorScheme?
    
    var currentTheme: String {
        get { userTheme }
        set {
            userTheme = newValue
            updateTheme()
        }
    }
    
    init() {
    print("Initializing ThemeManager")
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
