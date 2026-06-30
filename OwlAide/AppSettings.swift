import SwiftUI
import Combine

/// Global accessibility configuration: font size, elder mode, high contrast.
/// Persisted via @AppStorage to maintain user preferences after restart.
class AppSettings: ObservableObject {
    static let shared = AppSettings()

    /// Elder Mode: Enabled by default, suitable for 60+ users.
    @AppStorage("isElderMode") var isElderMode: Bool = true

    /// Font scaling: 1.0=Normal, 1.5=Large (Default), 2.0=Extra Large
    @AppStorage("fontScale") var fontScale: Double = 1.5

    /// User's Name
    @AppStorage("userName") var userName: String = ""

    /// High Contrast Mode
    @AppStorage("highContrast") var highContrast: Bool = false

    /// Remote LLM Config
    @AppStorage("llm_base_url") var llmBaseURL: String = ""
    @AppStorage("llm_api_key") var llmApiKey: String = ""
    @AppStorage("llm_model") var llmModel: String = "gpt-4o"

    // MARK: - Dynamic Font Sizes

    func fontSize(_ base: CGFloat, weight: Font.Weight = .regular) -> Font {
        .system(size: base * fontScale, weight: weight)
    }

    /// Title Font (Orig 20pt → Elder Mode 30pt)
    var titleFont: Font { fontSize(isElderMode ? 20 : 18, weight: .bold) }

    /// Body Font (Orig 14pt → Elder Mode 21pt)
    var bodyFont: Font { fontSize(isElderMode ? 14 : 13, weight: .regular) }

    /// Caption Font (Orig 11pt → Elder Mode 16pt)
    var captionFont: Font { fontSize(isElderMode ? 11 : 10, weight: .regular) }

    /// Button Font
    var buttonFont: Font { fontSize(isElderMode ? 15 : 14, weight: .semibold) }

    // MARK: - High Contrast Colors

    var tealColor: Color {
        highContrast ? Color(hex: "00695C") : AppTheme.teal
    }

    var backgroundColor: Color {
        highContrast ? .white : AppTheme.background
    }
}
