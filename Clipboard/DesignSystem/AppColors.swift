import SwiftUI

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
        self.init(.sRGB, red: Double(r) / 255, green: Double(g) / 255, blue: Double(b) / 255, opacity: Double(a) / 255)
    }

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

extension ShapeStyle where Self == Color {
    static var appSecondaryText: Color { .appSecondaryText }
    static var appSuccess: Color { .appSuccess }
    static var semanticText: Color { .semanticText }
    static var semanticImage: Color { .semanticImage }
    static var semanticFile: Color { .semanticFile }
}
