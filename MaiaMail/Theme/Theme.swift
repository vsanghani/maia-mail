import SwiftUI

struct AppTheme {

    // MARK: - Colors

    struct Colors {
        static let primary = Color(red: 0.18, green: 0.33, blue: 0.93)           // Bold blue
        static let primaryLight = Color(red: 0.35, green: 0.50, blue: 1.0)
        static let primaryDark = Color(red: 0.10, green: 0.20, blue: 0.65)

        static let accent = Color(red: 0.55, green: 0.35, blue: 1.0)             // Purple accent
        static let accentGradient = LinearGradient(
            colors: [primary, accent],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )

        static let success = Color(red: 0.20, green: 0.78, blue: 0.55)
        static let warning = Color(red: 1.0, green: 0.70, blue: 0.20)
        static let danger = Color(red: 0.95, green: 0.30, blue: 0.35)

        static let starYellow = Color(red: 1.0, green: 0.80, blue: 0.15)

        static let surfaceBackground = Color(UIColor.systemGroupedBackground)
        static let cardBackground = Color(UIColor.secondarySystemGroupedBackground)
        static let textPrimary = Color(UIColor.label)
        static let textSecondary = Color(UIColor.secondaryLabel)
        static let textTertiary = Color(UIColor.tertiaryLabel)
        static let separator = Color(UIColor.separator)

        // Avatar colors
        static let avatarColors: [Color] = [
            Color(red: 0.18, green: 0.33, blue: 0.93),
            Color(red: 0.55, green: 0.35, blue: 1.0),
            Color(red: 0.90, green: 0.30, blue: 0.50),
            Color(red: 0.95, green: 0.55, blue: 0.20),
            Color(red: 0.20, green: 0.78, blue: 0.55),
            Color(red: 0.28, green: 0.73, blue: 0.90),
            Color(red: 0.75, green: 0.25, blue: 0.75),
            Color(red: 0.95, green: 0.40, blue: 0.40),
        ]

        static func avatarColor(for name: String) -> Color {
            let hash = abs(name.hashValue)
            return avatarColors[hash % avatarColors.count]
        }
    }

    // MARK: - Typography

    struct Typography {
        static let largeTitle = Font.system(.largeTitle, design: .rounded).weight(.bold)
        static let title = Font.system(.title2, design: .rounded).weight(.bold)
        static let title3 = Font.system(.title3, design: .rounded).weight(.semibold)
        static let headline = Font.system(.headline, design: .rounded)
        static let body = Font.system(.body, design: .default)
        static let subheadline = Font.system(.subheadline, design: .default)
        static let caption = Font.system(.caption, design: .default)
        static let caption2 = Font.system(.caption2, design: .default)
    }

    // MARK: - Spacing

    struct Spacing {
        static let xs: CGFloat = 4
        static let sm: CGFloat = 8
        static let md: CGFloat = 12
        static let lg: CGFloat = 16
        static let xl: CGFloat = 20
        static let xxl: CGFloat = 24
        static let xxxl: CGFloat = 32
    }

    // MARK: - Corner Radius

    struct Radius {
        static let small: CGFloat = 8
        static let medium: CGFloat = 12
        static let large: CGFloat = 16
        static let xlarge: CGFloat = 20
        static let circle: CGFloat = 999
    }
}

// MARK: - View Modifiers

struct CardModifier: ViewModifier {
    func body(content: Content) -> some View {
        content
            .background(AppTheme.Colors.cardBackground)
            .clipShape(RoundedRectangle(cornerRadius: AppTheme.Radius.medium))
            .shadow(color: .black.opacity(0.05), radius: 5, x: 0, y: 2)
    }
}

struct GlassModifier: ViewModifier {
    func body(content: Content) -> some View {
        content
            .background(.ultraThinMaterial)
            .clipShape(RoundedRectangle(cornerRadius: AppTheme.Radius.large))
            .shadow(color: .black.opacity(0.08), radius: 10, x: 0, y: 4)
    }
}

struct GradientHeaderModifier: ViewModifier {
    func body(content: Content) -> some View {
        content
            .background(
                LinearGradient(
                    colors: [
                        AppTheme.Colors.primary,
                        AppTheme.Colors.primaryLight,
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
    }
}

extension View {
    func cardStyle() -> some View {
        modifier(CardModifier())
    }

    func glassStyle() -> some View {
        modifier(GlassModifier())
    }

    func gradientHeader() -> some View {
        modifier(GradientHeaderModifier())
    }
}
