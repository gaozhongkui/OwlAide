import SwiftUI

struct AppTheme {
    static let teal = Color(hex: "1B8A7E")
    static let tealLight = Color(hex: "E8F5F3")
    static let tealMid = Color(hex: "5BB8AD")
    static let warm = Color(hex: "FF7043")
    static let warmLight = Color(hex: "FFF3EF")
    static let background = Color(hex: "F5F7FA")
    static let textMain = Color(hex: "1A1A1A")
    static let textSub = Color(hex: "666666")
    static let cardWhite = Color.white

    // Additional colors from HTML prototype
    static let purple = Color(hex: "7C3AED")
    static let purpleLight = Color(hex: "F3E8FF")
    static let orange = Color(hex: "F59E0B")
    static let orangeLight = Color(hex: "FFF8E1")
    static let warningText = Color(hex: "795548")

    // MARK: - 适老化：动态字号

    /// 标题（原 ~20pt → 长者模式 ~30pt）
    static var titleFont: Font {
        let base: CGFloat = AppSettings.shared.isElderMode ? 20 : 18
        return .system(size: base * AppSettings.shared.fontScale, weight: .bold)
    }

    /// 正文字号（原 ~14pt → 长者模式 ~21pt）
    static var bodyFont: Font {
        let base: CGFloat = AppSettings.shared.isElderMode ? 14 : 13
        return .system(size: base * AppSettings.shared.fontScale)
    }

    /// 小字（原 ~11pt → 长者模式 ~16pt）
    static var captionFont: Font {
        let base: CGFloat = AppSettings.shared.isElderMode ? 11 : 10
        return .system(size: base * AppSettings.shared.fontScale)
    }

    /// 按钮字号
    static var buttonFont: Font {
        let base: CGFloat = AppSettings.shared.isElderMode ? 15 : 14
        return .system(size: base * AppSettings.shared.fontScale, weight: .semibold)
    }
}

extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (1, 1, 1, 0)
        }
        self.init(.sRGB, red: Double(r) / 255, green: Double(g) / 255, blue: Double(b) / 255, opacity: Double(a) / 255)
    }
}
