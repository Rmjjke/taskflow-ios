// Color+App.swift
// TaskFlow — Common / Extensions
//
// App-wide Color helpers.
// • `Color(hex:)` initializer used by the Priority enum for flag colors.
// • Named semantic colors that map to Asset Catalog entries (to be added in design phase).

import SwiftUI
import UIKit

extension Color {

    // MARK: - Hex Initializer

    /// Creates a Color from a CSS-style hex string (e.g., "#FF3B30" or "FF3B30").
    /// Used by `Priority.color` (AC-05.2 design spec colors).
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)

        let r, g, b, a: UInt64
        switch hex.count {
        case 6: // RGB (no alpha)
            (r, g, b, a) = ((int >> 16) & 0xFF, (int >> 8) & 0xFF, int & 0xFF, 255)
        case 8: // RGBA
            (r, g, b, a) = ((int >> 24) & 0xFF, (int >> 16) & 0xFF, (int >> 8) & 0xFF, int & 0xFF)
        default:
            (r, g, b, a) = (0, 0, 0, 255)
        }

        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }

    // MARK: - Semantic App Colors

    /// Primary accent color — sourced from Asset Catalog "AccentColor".
    /// Defined here as a fallback; Asset Catalog entry is the canonical source.
    static let appAccent = Color.accentColor

    /// Background color for grouped list content.
    static let groupedBackground = Color(.systemGroupedBackground)

    /// Secondary grouped background (inset list cells).
    static let secondaryGroupedBackground = Color(.secondarySystemGroupedBackground)
}
