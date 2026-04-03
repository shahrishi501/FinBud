//
//  AccountTypePill.swift
//  FinBud
//
//  Created by Rishi Shah on 04/04/26.
//
import SwiftUI

struct AccountTypePill: View {
    let type: MoneyAccountType

    var body: some View {
        Text(type.title.uppercased())
            .font(.system(size: 10, weight: .bold))
            .padding(.horizontal, 6)
            .padding(.vertical, 2)
            .background(
                Capsule()
                    .fill(backgroundColor)
            )
            .foregroundStyle(textColor)
    }

    private var backgroundColor: Color {
        switch type {
        case .upi:
            return AppTheme.accent.opacity(0.14)
        case .card:
            return Color.gray.opacity(0.18)
        case .cash:
            return AppTheme.warning.opacity(0.18)
        }
    }

    private var textColor: Color {
        switch type {
        case .upi:
            return AppTheme.accent
        case .card:
            return AppTheme.primaryText
        case .cash:
            return AppTheme.warning
        }
    }
}
