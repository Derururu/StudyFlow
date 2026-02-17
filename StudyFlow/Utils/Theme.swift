import SwiftUI

enum Theme {
    // MARK: - Colors
    static let background = Color(hex: "#0F0F1A")
    static let surface = Color(hex: "#1A1A2E")
    static let surfaceLight = Color(hex: "#242440")
    static let accent = Color(hex: "#7C5CFC")
    static let accentSecondary = Color(hex: "#A855F7")
    static let success = Color(hex: "#00C9A7")
    static let warning = Color(hex: "#FFA94D")
    static let danger = Color(hex: "#FF6B6B")
    static let textPrimary = Color.white
    static let textSecondary = Color(hex: "#A0A0B8")
    static let textMuted = Color(hex: "#6B6B80")

    // MARK: - Gradients
    static let accentGradient = LinearGradient(
        colors: [accent, accentSecondary],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    static let cardGradient = LinearGradient(
        colors: [surface, surfaceLight],
        startPoint: .top,
        endPoint: .bottom
    )

    static let focusGradient = LinearGradient(
        colors: [Color(hex: "#7C5CFC"), Color(hex: "#6C63FF")],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    static let breakGradient = LinearGradient(
        colors: [Color(hex: "#00C9A7"), Color(hex: "#00B4D8")],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    // MARK: - Spacing
    static let paddingSm: CGFloat = 8
    static let paddingMd: CGFloat = 16
    static let paddingLg: CGFloat = 24
    static let paddingXl: CGFloat = 32

    static let cornerRadius: CGFloat = 16
    static let cornerRadiusSm: CGFloat = 10

    // MARK: - Ring
    static let ringSize: CGFloat = 240
    static let ringLineWidth: CGFloat = 12
}

struct GlassCard: ViewModifier {
    func body(content: Content) -> some View {
        content
            .background(
                RoundedRectangle(cornerRadius: Theme.cornerRadius)
                    .fill(Theme.surface.opacity(0.7))
                    .overlay(
                        RoundedRectangle(cornerRadius: Theme.cornerRadius)
                            .stroke(Theme.surfaceLight.opacity(0.5), lineWidth: 1)
                    )
            )
    }
}

extension View {
    func glassCard() -> some View {
        modifier(GlassCard())
    }
}
