import SwiftUI

// MARK: - App Theme
/// Defines the available app themes.
enum AppTheme: String, CaseIterable {
    case system = "System"
    case light = "Light"
    case dark = "Dark"

    /// Maps to SwiftUI's ColorScheme.
    var colorScheme: ColorScheme? {
        switch self {
        case .system: return nil
        case .light: return .light
        case .dark: return .dark
        }
    }

    /// SF Symbol icon for each theme.
    var icon: String {
        switch self {
        case .system: return "circle.lefthalf.filled"
        case .light: return "sun.max.fill"
        case .dark: return "moon.fill"
        }
    }
}

// MARK: - Theme Manager
/// Observable class that persists the user's theme preference.
class ThemeManager: ObservableObject {

    static let shared = ThemeManager()

    @AppStorage("selectedTheme") private var storedTheme: String = AppTheme.system.rawValue

    @Published var currentTheme: AppTheme = .system

    init() {
        currentTheme = AppTheme(rawValue: storedTheme) ?? .system
    }

    func setTheme(_ theme: AppTheme) {
        currentTheme = theme
        storedTheme = theme.rawValue
    }
}

// MARK: - Theme Colors
/// Centralized color palette that adapts to light/dark mode.
enum ThemeColors {
    // Primary gradient
    static let primaryGradient = LinearGradient(
        colors: [Color(hex: "6366F1"), Color(hex: "8B5CF6")],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    // Accent gradient for recording
    static let recordGradient = LinearGradient(
        colors: [Color(hex: "EF4444"), Color(hex: "EC4899")],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    // Success gradient
    static let successGradient = LinearGradient(
        colors: [Color(hex: "10B981"), Color(hex: "34D399")],
        startPoint: .leading,
        endPoint: .trailing
    )

    // AI gradient
    static let aiGradient = LinearGradient(
        colors: [Color(hex: "3B82F6"), Color(hex: "8B5CF6")],
        startPoint: .leading,
        endPoint: .trailing
    )

    // Waveform gradient
    static let waveformGradient = LinearGradient(
        colors: [Color(hex: "06B6D4"), Color(hex: "3B82F6"), Color(hex: "8B5CF6")],
        startPoint: .bottom,
        endPoint: .top
    )

    // Card background — adapts automatically
    static func cardBackground(for scheme: ColorScheme?) -> Color {
        if scheme == .dark {
            return Color(hex: "1E1E2E")
        }
        return Color(hex: "F8F9FA")
    }

    // Surface background
    static func surfaceBackground(for scheme: ColorScheme?) -> Color {
        if scheme == .dark {
            return Color(hex: "11111B")
        }
        return Color(hex: "FFFFFF")
    }

    // Recording background
    static func recordingBackground(for scheme: ColorScheme?) -> Color {
        if scheme == .dark {
            return Color(hex: "0D0D1A")
        }
        return Color(hex: "1A1A2E")
    }
}

// MARK: - Color Hex Extension
extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 6:
            (a, r, g, b) = (255, (int >> 16) & 0xFF, (int >> 8) & 0xFF, int & 0xFF)
        case 8:
            (a, r, g, b) = ((int >> 24) & 0xFF, (int >> 16) & 0xFF, (int >> 8) & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (255, 0, 0, 0)
        }
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}
