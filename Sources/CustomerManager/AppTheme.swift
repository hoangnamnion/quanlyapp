import SwiftUI

// MARK: - App Theme (Light)

struct AppTheme {
    // Backgrounds
    static let bg       = Color(red: 0.953, green: 0.953, blue: 0.969)  // #F3F3F7
    static let card     = Color.white
    static let cardAlt  = Color(red: 0.925, green: 0.925, blue: 0.945)  // #ECECF1

    // Accent
    static let accent   = Color(red: 0.545, green: 0.361, blue: 0.969)  // #8B5CF6
    static let accent2  = Color(red: 0.361, green: 0.208, blue: 0.851)  // #5C35D9

    // Text
    static let textPrimary   = Color(red: 0.102, green: 0.102, blue: 0.173)  // #1A1A2C
    static let textSecondary = Color(red: 0.420, green: 0.420, blue: 0.545)  // #6B6B8B
    static let textMuted     = Color(red: 0.627, green: 0.627, blue: 0.710)  // #A0A0B5

    // Status
    static let green  = Color(red: 0.063, green: 0.851, blue: 0.494)  // #10D97E
    static let orange = Color(red: 1.000, green: 0.624, blue: 0.039)  // #FF9F0A
    static let red    = Color(red: 1.000, green: 0.271, blue: 0.227)  // #FF4539

    // Gradient
    static let accentGradient = LinearGradient(
        colors: [AppTheme.accent, AppTheme.accent2],
        startPoint: .leading,
        endPoint: .trailing
    )
}
