import Foundation
import SwiftUI

enum TransactionType: String, CaseIterable, Codable, Identifiable {
    case income
    case expense

    var id: String { rawValue }
    var title: String { rawValue.capitalized }
    var tint: Color { self == .income ? AppTheme.positive : AppTheme.negative }
}

enum FinanceCategory: String, CaseIterable, Codable, Identifiable {
    case salary
    case freelance
    case food
    case shopping
    case travel
    case entertainment
    case bills
    case subscription
    case health
    case transfer
    case others

    var id: String { rawValue }

    var title: String {
        switch self {
        case .salary: "Salary"
        case .freelance: "Freelance"
        case .food: "Food"
        case .shopping: "Shopping"
        case .travel: "Travel"
        case .entertainment: "Fun"
        case .bills: "Bills"
        case .subscription: "Subscriptions"
        case .health: "Health"
        case .transfer: "Transfer"
        case .others: "Others"
        }
    }

    var icon: String {
        switch self {
        case .salary: "banknote"
        case .freelance: "briefcase"
        case .food: "fork.knife"
        case .shopping: "bag"
        case .travel: "airplane"
        case .entertainment: "gamecontroller"
        case .bills: "bolt"
        case .subscription: "creditcard"
        case .health: "heart"
        case .transfer: "arrow.left.arrow.right"
        case .others: "tray.full"
        }
    }

    var color: Color {
        switch self {
        case .salary: AppTheme.positive
        case .freelance: .cyan
        case .food: .pink
        case .shopping: .orange
        case .travel: .mint
        case .entertainment: .purple
        case .bills: .yellow
        case .subscription: .red
        case .health: .teal
        case .transfer: AppTheme.accentSoft
        case .others: .gray
        }
    }
}

enum MoneyAccountType: String, CaseIterable, Codable, Identifiable {
    case cash
    case upi
    case card

    var id: String { rawValue }

    var title: String {
        switch self {
        case .cash: "Cash"
        case .upi: "UPI"
        case .card: "Card"
        }
    }

    var icon: String {
        switch self {
        case .cash: "banknote"
        case .upi: "iphone.gen3.radiowaves.left.and.right"
        case .card: "creditcard"
        }
    }
}

enum OccupationType: String, CaseIterable, Codable, Identifiable {
    case student
    case workingProfessional
    case freelancer
    case businessOwner
    case other

    var id: String { rawValue }

    var title: String {
        switch self {
        case .student: "Student"
        case .workingProfessional: "Working Professional"
        case .freelancer: "Freelancer"
        case .businessOwner: "Business Owner"
        case .other: "Other"
        }
    }
}

enum AssetCategory: String, CaseIterable, Codable, Identifiable {
    case stocks
    case mutualFunds
    case sip

    var id: String { rawValue }

    var title: String {
        switch self {
        case .stocks: "Stocks"
        case .mutualFunds: "MFs"
        case .sip: "SIP"
        }
    }

    var icon: String {
        switch self {
        case .stocks: "chart.line.uptrend.xyaxis"
        case .mutualFunds: "chart.pie"
        case .sip: "leaf"
        }
    }

    var color: Color {
        switch self {
        case .stocks: AppTheme.warning
        case .mutualFunds: AppTheme.accentSoft
        case .sip: AppTheme.positive
        }
    }
}

struct Transaction: Identifiable, Equatable {
    let id: UUID
    var amount: Double
    var type: TransactionType
    var category: FinanceCategory
    var accountType: MoneyAccountType
    var date: Date
    var note: String
    var merchant: String
}

enum GoalKind: String, Codable, CaseIterable {
    case investment
    case savings
    case challenge
}

struct Goal: Identifiable, Equatable {
    let id: UUID
    var title: String
    var subtitle: String
    var currentAmount: Double
    var targetAmount: Double
    var icon: String
    var tintHex: String
    var kind: GoalKind
    var commitLog: [Int: Double]
}

struct UserProfile: Equatable {
    var name: String
    var age: Int
    var birthDate: Date
    var occupation: OccupationType
}

struct AssetHolding: Identifiable, Equatable {
    let id: UUID
    var category: AssetCategory
    var amount: Double
}

struct AllocationBucket: Identifiable {
    let id = UUID()
    let title: String
    let amount: Double
    let tint: Color
}

struct TrendPoint: Identifiable {
    let id = UUID()
    let label: String
    let value: Double
    let date: Date
}

struct InsightMetric: Identifiable {
    let id = UUID()
    let title: String
    let value: String
    let detail: String
    let icon: String
    let tint: Color
}

struct InsightCard: Identifiable {
    let id = UUID()
    let title: String
    let body: String
    let icon: String
    let tint: Color
}

struct SavingsCommit: Identifiable {
    let id: UUID
    let date: Date
    let amount: Double
    let goalID: UUID?
}

struct OnboardingDraftTransaction: Identifiable {
    let id: UUID
    var merchant: String
    var amountText: String
    var type: TransactionType
    var category: FinanceCategory
    var accountType: MoneyAccountType
    var note: String
    var date: Date

    init(
        id: UUID = UUID(),
        merchant: String = "",
        amountText: String = "",
        type: TransactionType = .expense,
        category: FinanceCategory = .food,
        accountType: MoneyAccountType = .upi,
        note: String = "",
        date: Date = .now
    ) {
        self.id = id
        self.merchant = merchant
        self.amountText = amountText
        self.type = type
        self.category = category
        self.accountType = accountType
        self.note = note
        self.date = date
    }
}
