import SwiftUI
import UIKit

enum AppTheme {
    static let background = Color(uiColor: .systemBackground)
    static let card = Color(uiColor: .secondarySystemBackground)
    static let elevatedCard = Color(uiColor: .tertiarySystemBackground)
    static let accent = Color(hex: "#2E8B57")
    static let accentSoft = Color(hex: "#84C7A5")
    static let positive = Color(hex: "#2E8B57")
    static let negative = Color(hex: "#FF6B6B")
    static let warning = Color(red: 0.98, green: 0.78, blue: 0.34)
    static let primaryText = Color(uiColor: .label)
    static let mutedText = Color(uiColor: .secondaryLabel)
    static let secondaryText = Color(uiColor: .secondaryLabel)
    static let stroke = Color(uiColor: .separator).opacity(0.3)
    static let glow = LinearGradient(
        colors: [accent, accent],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
}
