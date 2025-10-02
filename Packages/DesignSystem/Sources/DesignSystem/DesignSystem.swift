import Foundation
import SharedModels

/// DesignSystem provides a comprehensive UI toolkit for the ScreenTime Rewards application.
///
/// The DesignSystem package includes:
/// - Color, typography, and spacing tokens for consistent styling
/// - Reusable UI components like buttons, cards, and progress indicators
/// - Modifiers for consistent styling
/// - Gamification elements like points displays and achievement badges
public struct DesignSystem {
    public private(set) var text = "Hello, World!"

    public init() {
    }
}

// MARK: - Color Tokens
/// Simple color representation that can be used across platforms
public struct DesignSystemColor {
    public let red: Double
    public let green: Double
    public let blue: Double
    public let alpha: Double
    
    public init(red: Double, green: Double, blue: Double, alpha: Double = 1.0) {
        self.red = red
        self.green = green
        self.blue = blue
        self.alpha = alpha
    }
    
    public static let primaryBrand = DesignSystemColor(red: 0.0, green: 0.478, blue: 1.0)
    public static let secondaryBrand = DesignSystemColor(red: 0.5, green: 0.5, blue: 0.5)
    public static let accent = DesignSystemColor(red: 1.0, green: 0.5, blue: 0.0)
    public static let backgroundPrimary = DesignSystemColor(red: 1.0, green: 1.0, blue: 1.0)
    public static let backgroundSecondary = DesignSystemColor(red: 0.95, green: 0.95, blue: 0.95)
    public static let textPrimary = DesignSystemColor(red: 0.0, green: 0.0, blue: 0.0)
    public static let textSecondary = DesignSystemColor(red: 0.5, green: 0.5, blue: 0.5)
    public static let success = DesignSystemColor(red: 0.0, green: 0.8, blue: 0.0)
    public static let warning = DesignSystemColor(red: 1.0, green: 1.0, blue: 0.0)
    public static let error = DesignSystemColor(red: 1.0, green: 0.0, blue: 0.0)
}

// MARK: - Spacing Tokens
public enum Spacing {
    public static let xxs: CGFloat = 4
    public static let xs: CGFloat = 8
    public static let sm: CGFloat = 12
    public static let md: CGFloat = 16
    public static let lg: CGFloat = 24
    public static let xl: CGFloat = 32
    public static let xxl: CGFloat = 48
}

// MARK: - Simple UI Components
// These are simplified versions that avoid platform-specific SwiftUI features

public struct DSButtonStyle {
    public static let primary = "primary"
    public static let secondary = "secondary"
    public static let destructive = "destructive"
}

public struct DSCardStyle {
    public static let elevated = "elevated"
    public static let filled = "filled"
}

public struct DSPointsDisplayStyle {
    public static let small = "small"
    public static let medium = "medium"
    public static let large = "large"
}

// MARK: - Debug Tools
public enum DesignSystemDebug {
    /// Enable debug mode for DesignSystem components
    public static func enableDebugMode() {
        #if DEBUG
        print("DesignSystem debug mode enabled")
        #endif
    }
}