import Foundation
import SwiftUI

extension Double {
    var inrCurrency: String {
        let code = UserDefaults.standard.string(forKey: "AppCurrencyCode") ?? "INR"
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = code
        formatter.locale = localeForCurrencyCode(code)
        formatter.maximumFractionDigits = 0
        return formatter.string(from: NSNumber(value: self)) ?? defaultCurrencyString(self, code: code)
    }

    var compactCurrency: String {
        let code = UserDefaults.standard.string(forKey: "AppCurrencyCode") ?? "INR"
        let symbol: String
        switch code {
        case "INR": symbol = "₹"
        case "USD": symbol = "$"
        case "EUR": symbol = "€"
        case "GBP": symbol = "£"
        default: symbol = ""
        }
        if self >= 1_00_00_000 {
            let suffix = code == "INR" ? "Cr" : "M"
            return symbol + String(format: "%.2f", self / (code == "INR" ? 1_00_00_000 : 1_000_000)) + suffix
        }
        if self >= 1_00_000 {
            return symbol + String(format: "%.1f", self / 1_00_000) + "L"
        }
        if self >= 1_000 {
            return symbol + String(format: "%.0f", self / 1_000) + "K"
        }
        return self.inrCurrency
    }

    var signedPercent: String {
        let sign = self >= 0 ? "+" : ""
        return sign + String(format: "%.0f", self) + "%"
    }
}

extension Date {
    func formatted(_ style: DateStyle) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_IN")
        switch style {
        case .dayHeader:
            formatter.dateFormat = "d MMM"
        case .long:
            formatter.dateFormat = "d MMM yyyy"
        case .month:
            formatter.dateFormat = "MMMM"
        case .weekday:
            formatter.dateFormat = "EEE"
        }
        return formatter.string(from: self)
    }

    enum DateStyle {
        case dayHeader
        case long
        case month
        case weekday
    }
}

extension Color {
    init(hex: String) {
        let hex = hex.replacingOccurrences(of: "#", with: "")
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        self.init(
            red: Double((int >> 16) & 0xFF) / 255.0,
            green: Double((int >> 8) & 0xFF) / 255.0,
            blue: Double(int & 0xFF) / 255.0
        )
    }
}
private func localeForCurrencyCode(_ code: String) -> Locale {
    switch code {
    case "INR": return Locale(identifier: "en_IN")
    case "USD": return Locale(identifier: "en_US")
    case "EUR": return Locale(identifier: "de_DE")
    case "GBP": return Locale(identifier: "en_GB")
    default: return Locale.current
    }
}

private func defaultCurrencyString(_ value: Double, code: String) -> String {
    let symbol: String
    switch code {
    case "INR": symbol = "₹"
    case "USD": symbol = "$"
    case "EUR": symbol = "€"
    case "GBP": symbol = "£"
    default: symbol = code + " "
    }
    return symbol + String(format: "%.0f", value)
}

func currentCurrencyCode() -> String {
    UserDefaults.standard.string(forKey: "AppCurrencyCode") ?? "INR"
}
func currentCurrencySymbol() -> String {
    let code = currentCurrencyCode()
    switch code {
    case "INR": return "₹"
    case "USD": return "$"
    case "EUR": return "€"
    case "GBP": return "£"
    default: return Locale(identifier: localeForCurrencyCode(code).identifier).currencySymbol ?? code
    }
}

