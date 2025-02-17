import SwiftUI
#if canImport(UIKit)
import UIKit
#endif

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
            withAnimation {
                updateTheme()
            }
        }
    }
    
    var currentAccent: ThemeAccent {
        get { themeAccent }
        set {
            withAnimation {
                themeAccent = newValue
                UserDefaults.standard.set(newValue.rawValue, forKey: "themeAccent")
                UserDefaults.standard.synchronize()
                
                // Ensure immediate UI update
                objectWillChange.send()
                // Force immediate UI update
                NotificationCenter.default.post(name: .init("ThemeDidChange"), object: nil)
                
                // Force window refresh
                #if os(iOS)
                DispatchQueue.main.async { [weak self] in
                    guard let self = self else { return }
                    self.updateWindowAppearance(with: self.colorScheme)
                    // Force redraw by toggling style
                    if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
                       let window = windowScene.windows.first {
                        let currentStyle = window.overrideUserInterfaceStyle
                        if self.colorScheme == nil {
                            return
                        }
                        window.overrideUserInterfaceStyle = currentStyle == .light ? .dark : .light
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) { [weak self] in
                            guard self != nil else { return }
                            window.overrideUserInterfaceStyle = currentStyle
                        }
                    }
                }
                #endif
            }
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
        let newColorScheme: ColorScheme?
        switch userTheme {
        case "light":
            newColorScheme = .light
        case "dark":
            newColorScheme = .dark
        default:
            newColorScheme = nil
        }
        
        // Apply changes immediately on the main thread
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            
            withAnimation {
                self.colorScheme = newColorScheme
                
                // Force immediate UI update
                self.objectWillChange.send()
                NotificationCenter.default.post(name: .init("ThemeDidChange"), object: nil)
                
                // Update window appearance immediately
                #if os(iOS)
                self.updateWindowAppearance(with: newColorScheme)
                #endif
            }
        }
    }
    
    #if os(iOS)
    private func updateWindowAppearance(with scheme: ColorScheme?) {
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let window = windowScene.windows.first {
            let style: UIUserInterfaceStyle
            if let scheme = scheme {
                style = scheme == .dark ? .dark : .light
            } else {
                style = .unspecified
            }
            window.overrideUserInterfaceStyle = style
        }
    }
    #endif
    
    // Public method to manually refresh theme with animation
    func refreshTheme() {
        withAnimation {
            updateTheme()
        }
    }
}
