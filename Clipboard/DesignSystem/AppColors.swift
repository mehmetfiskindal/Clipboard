import SwiftUI
import AppKit

// MARK: - NSColor Hex Support
extension NSColor {
    convenience init(hex: String) {
        let hex = hex.trimmingCharacters(in: .alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 6: (a, r, g, b) = (255, (int >> 16) & 0xFF, (int >> 8) & 0xFF, int & 0xFF)
        case 8: (a, r, g, b) = ((int >> 24) & 0xFF, (int >> 16) & 0xFF, (int >> 8) & 0xFF, int & 0xFF)
        default: (a, r, g, b) = (255, 0, 0, 0)
        }
        self.init(srgbRed: CGFloat(r) / 255, green: CGFloat(g) / 255, blue: CGFloat(b) / 255, alpha: CGFloat(a) / 255)
    }
}

// MARK: - Dynamic Color (Light / Dark)
extension Color {
    init(hex: String) {
        self.init(NSColor(hex: hex))
    }

    static func dynamic(light: NSColor, dark: NSColor) -> Color {
        Color(nsColor: NSColor(name: nil) { appearance in
            let isDark = appearance.bestMatch(from: [.darkAqua, .aqua]) == .darkAqua
            return isDark ? dark : light
        })
    }

    // MARK: - Backgrounds & Surfaces
    static let appBackground = Color.dynamic(
        light: NSColor(hex: "F5F5F7"),
        dark: NSColor(hex: "1C1C1E")
    )
    static let appSurface = Color.dynamic(
        light: NSColor.white,
        dark: NSColor(hex: "2C2C2E")
    )
    static let appSurfaceSecondary = Color.dynamic(
        light: NSColor(hex: "F2F2F7"),
        dark: NSColor(hex: "3A3A3C")
    )
    static let appSurfaceTertiary = Color.dynamic(
        light: NSColor(hex: "E5E5EA"),
        dark: NSColor(hex: "48484A")
    )

    // MARK: - Text
    static let appTextPrimary = Color.dynamic(
        light: NSColor(hex: "000000"),
        dark: NSColor.white
    )
    static let appTextSecondary = Color.dynamic(
        light: NSColor(hex: "8E8E93"),
        dark: NSColor(hex: "98989E")
    )
    static let appTextTertiary = Color.dynamic(
        light: NSColor(hex: "C7C7CC"),
        dark: NSColor(hex: "636366")
    )

    // MARK: - Borders & Separators
    static let appBorder = Color.dynamic(
        light: NSColor(hex: "D1D1D6"),
        dark: NSColor(hex: "38383A")
    )
    static let appSeparator = Color.dynamic(
        light: NSColor(hex: "C6C6C8"),
        dark: NSColor(hex: "38383A")
    )

    // MARK: - Shadows
    static let appShadow = Color.black.opacity(0.1)
    static let appShadowDark = Color.black.opacity(0.3)

    // MARK: - Accent / Semantic (works in both modes)
    static let appSecondaryText = Color(hex: "A6A6A6")
    static let appSuccess = Color(hex: "21BF73")
    static let semanticText = Color(hex: "59D8FD")
    static let semanticImage = Color(hex: "C577FF")
    static let semanticFile = Color(hex: "FF9500")

    static func semantic(for contentType: String) -> Color {
        switch contentType.lowercased() {
        case "url", "file": return .semanticFile
        case "email": return .semanticImage
        case "code", "text": return .semanticText
        default: return .appSecondaryText
        }
    }
}

// MARK: - ShapeStyle Convenience
extension ShapeStyle where Self == Color {
    static var appBackground: Color { .appBackground }
    static var appSurface: Color { .appSurface }
    static var appSurfaceSecondary: Color { .appSurfaceSecondary }
    static var appSurfaceTertiary: Color { .appSurfaceTertiary }
    static var appTextPrimary: Color { .appTextPrimary }
    static var appTextSecondary: Color { .appTextSecondary }
    static var appTextTertiary: Color { .appTextTertiary }
    static var appBorder: Color { .appBorder }
    static var appSeparator: Color { .appSeparator }
    static var appSecondaryText: Color { .appSecondaryText }
    static var appSuccess: Color { .appSuccess }
    static var semanticText: Color { .semanticText }
    static var semanticImage: Color { .semanticImage }
    static var semanticFile: Color { .semanticFile }
}
