import SwiftUI
import Combine

/// 全局适老化配置：字号、长者模式、高对比度
/// 通过 @AppStorage 持久化，App 重启后保持用户偏好
class AppSettings: ObservableObject {
    static let shared = AppSettings()

    /// 长者模式：默认开启，适合 60+ 用户
    @AppStorage("isElderMode") var isElderMode: Bool = true

    /// 字号缩放比例：1.0=正常, 1.5=大号（默认）, 2.0=超大
    @AppStorage("fontScale") var fontScale: Double = 1.5

    /// 高对比度模式
    @AppStorage("highContrast") var highContrast: Bool = false

    // MARK: - 动态字号

    func fontSize(_ base: CGFloat, weight: Font.Weight = .regular) -> Font {
        .system(size: base * fontScale, weight: weight)
    }

    /// 标题字号（原 20pt → 长者模式 30pt）
    var titleFont: Font { fontSize(isElderMode ? 20 : 18, weight: .bold) }

    /// 正文字号（原 14pt → 长者模式 21pt）
    var bodyFont: Font { fontSize(isElderMode ? 14 : 13, weight: .regular) }

    /// 小字（原 11pt → 长者模式 16pt）
    var captionFont: Font { fontSize(isElderMode ? 11 : 10, weight: .regular) }

    /// 按钮字号
    var buttonFont: Font { fontSize(isElderMode ? 15 : 14, weight: .semibold) }

    // MARK: - 高对比度配色

    var tealColor: Color {
        highContrast ? Color(hex: "00695C") : AppTheme.teal
    }

    var backgroundColor: Color {
        highContrast ? .white : AppTheme.background
    }
}
