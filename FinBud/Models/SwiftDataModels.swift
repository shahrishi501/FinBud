import Foundation
import SwiftData

@Model
final class UserProfileEntity {
    @Attribute(.unique) var id: UUID
    var name: String
    var age: Int
    var birthDate: Date
    var occupationRaw: String

    init(id: UUID = UUID(), name: String, age: Int, birthDate: Date, occupationRaw: String) {
        self.id = id
        self.name = name
        self.age = age
        self.birthDate = birthDate
        self.occupationRaw = occupationRaw
    }
}

@Model
final class AssetHoldingEntity {
    @Attribute(.unique) var id: UUID
    var categoryRaw: String
    var amount: Double

    init(id: UUID = UUID(), categoryRaw: String, amount: Double) {
        self.id = id
        self.categoryRaw = categoryRaw
        self.amount = amount
    }
}

@Model
final class GoalEntity {
    @Attribute(.unique) var id: UUID
    var title: String
    var subtitle: String
    var currentAmount: Double
    var targetAmount: Double
    var icon: String
    var tintHex: String
    var kindRaw: String

    init(id: UUID = UUID(), title: String, subtitle: String, currentAmount: Double, targetAmount: Double, icon: String, tintHex: String, kindRaw: String) {
        self.id = id
        self.title = title
        self.subtitle = subtitle
        self.currentAmount = currentAmount
        self.targetAmount = targetAmount
        self.icon = icon
        self.tintHex = tintHex
        self.kindRaw = kindRaw
    }
}

@Model
final class SavingsCommitEntity {
    @Attribute(.unique) var id: UUID
    var date: Date
    var amount: Double
    var goalID: UUID?   // nil = general savings, non-nil = also applied to that goal

    init(id: UUID = UUID(), date: Date, amount: Double, goalID: UUID? = nil) {
        self.id = id
        self.date = date
        self.amount = amount
        self.goalID = goalID
    }
}

@Model
final class TransactionEntity {
    @Attribute(.unique) var id: UUID
    var amount: Double
    var typeRaw: String
    var categoryRaw: String
    var accountTypeRaw: String
    var date: Date
    var note: String
    var merchant: String

    init(id: UUID = UUID(), amount: Double, typeRaw: String, categoryRaw: String, accountTypeRaw: String, date: Date, note: String, merchant: String) {
        self.id = id
        self.amount = amount
        self.typeRaw = typeRaw
        self.categoryRaw = categoryRaw
        self.accountTypeRaw = accountTypeRaw
        self.date = date
        self.note = note
        self.merchant = merchant
    }
}

@Model
final class AppStateEntity {
    @Attribute(.unique) var id: UUID
    var hasCompletedOnboarding: Bool
    var noSpendStreak: Int
    var lastNoSpendCheckIn: Date?
    var paymentMethodsRaw: String

    init(
        id: UUID = UUID(),
        hasCompletedOnboarding: Bool = false,
        noSpendStreak: Int = 0,
        lastNoSpendCheckIn: Date? = nil,
        paymentMethodsRaw: String = ""
    ) {
        self.id = id
        self.hasCompletedOnboarding = hasCompletedOnboarding
        self.noSpendStreak = noSpendStreak
        self.lastNoSpendCheckIn = lastNoSpendCheckIn
        self.paymentMethodsRaw = paymentMethodsRaw
    }
}
