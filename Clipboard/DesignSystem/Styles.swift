import SwiftUI

// MARK: - Layout Constants
enum AppLayout {
    static let spacingSmall: CGFloat = 8
    static let spacingMedium: CGFloat = 12
    static let spacingLarge: CGFloat = 16

    static let paddingSmall: CGFloat = 8
    static let paddingMedium: CGFloat = 12
    static let paddingLarge: CGFloat = 16

    static let cornerRadiusSmall: CGFloat = 4
    static let cornerRadiusMedium: CGFloat = 6
    static let cornerRadiusLarge: CGFloat = 8

    static let iconSizeSmall: CGFloat = 20
    static let iconSizeMedium: CGFloat = 24
    static let iconSizeLarge: CGFloat = 64

    static let listRowVertical: CGFloat = 2
    static let minWindowWidth: CGFloat = 700
    static let minWindowHeight: CGFloat = 500
    static let detailMinWidth: CGFloat = 400
    static let detailMinHeight: CGFloat = 300

    static let menuBarWidth: CGFloat = 320
    static let quickSearchWidth: CGFloat = 500
    static let settingsWidth: CGFloat = 400
    static let settingsHeight: CGFloat = 250
}

// MARK: - Content Type
enum ContentType: String {
    case text
    case url
    case email
    case code
    case image
    case file

    init(_ raw: String) {
        switch raw.lowercased() {
        case "url": self = .url
        case "email": self = .email
        case "code": self = .code
        case "image", "photo": self = .image
        case "file": self = .file
        default: self = .text
        }
    }

    var icon: String {
        switch self {
        case .url: return "link"
        case .email: return "envelope"
        case .code: return "chevron.left.forwardslash.chevron.right"
        case .image: return "photo"
        case .file: return "doc"
        case .text: return "doc.text"
        }
    }

    var semanticColor: Color {
        switch self {
        case .url, .file: return .semanticFile
        case .email, .image: return .semanticImage
        case .code, .text: return .semanticText
        }
    }
}

// MARK: - Badge
struct Badge: ViewModifier {
    let color: Color

    func body(content: Content) -> some View {
        content
            .font(.appCaptionBold)
            .padding(.horizontal, 6)
            .padding(.vertical, 2)
            .background(color.opacity(0.2))
            .cornerRadius(AppLayout.cornerRadiusSmall)
    }
}

// MARK: - Keyboard Hint Badge
struct KeyboardHint: ViewModifier {
    func body(content: Content) -> some View {
        content
            .font(.appCaptionBold)
            .padding(.horizontal, 4)
            .padding(.vertical, 2)
            .background(.quaternary.opacity(0.3))
            .cornerRadius(AppLayout.cornerRadiusSmall)
    }
}

// MARK: - Search Bar Style
struct SearchBarStyle: ViewModifier {
    func body(content: Content) -> some View {
        content
            .padding(AppLayout.paddingSmall)
            .background(.quaternary.opacity(0.3))
            .cornerRadius(AppLayout.cornerRadiusLarge)
    }
}

// MARK: - Divider Wrapper
struct AppDivider: ViewModifier {
    func body(content: Content) -> some View {
        content
        Divider()
    }
}

// MARK: - App Link Button
struct AppLinkButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .foregroundStyle(Color.accentColor)
    }
}

// MARK: - App Row (selected state)
struct AppRowSelected: ViewModifier {
    let isSelected: Bool

    func body(content: Content) -> some View {
        content
            .background(isSelected ? Color.accentColor.opacity(0.2) : Color.clear)
            .cornerRadius(AppLayout.cornerRadiusMedium)
    }
}

// MARK: - Code Block
struct CodeBlockStyle: ViewModifier {
    func body(content: Content) -> some View {
        content
            .font(.appMonospaced)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding()
            .background(.quaternary.opacity(0.3))
            .cornerRadius(AppLayout.cornerRadiusLarge)
    }
}

// MARK: - TextEditor Border
struct TextEditorBorderStyle: ViewModifier {
    func body(content: Content) -> some View {
        content
            .overlay(
                RoundedRectangle(cornerRadius: AppLayout.cornerRadiusSmall)
                    .stroke(.quaternary, lineWidth: 1)
            )
    }
}

// MARK: - View Extensions
extension View {
    func badge(_ color: Color) -> some View {
        modifier(Badge(color: color))
    }

    func badge(_ contentType: ContentType) -> some View {
        modifier(Badge(color: contentType.semanticColor))
    }

    func keyboardHint() -> some View {
        modifier(KeyboardHint())
    }

    func searchBarStyle() -> some View {
        modifier(SearchBarStyle())
    }

    func appRowSelected(_ isSelected: Bool) -> some View {
        modifier(AppRowSelected(isSelected: isSelected))
    }

    func codeBlock() -> some View {
        modifier(CodeBlockStyle())
    }

    func textEditorBorder() -> some View {
        modifier(TextEditorBorderStyle())
    }
}
