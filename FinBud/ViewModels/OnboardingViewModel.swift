import Combine
import Foundation

@MainActor
final class OnboardingViewModel: ObservableObject {
    enum Step: Int, CaseIterable {
        case profile
        case moneySetup
        case goals
        case starterTransactions

        var title: String {
            switch self {
            case .profile: "Tell us about you"
            case .moneySetup: "How you move money"
            case .goals: "What are you building toward?"
            case .starterTransactions: "Add this month's transactions"
            }
        }

        var subtitle: String {
            switch self {
            case .profile: "We’ll personalize your finance journey from day one."
            case .moneySetup: "Payment modes and investments stay separate from expenses."
            case .goals: "Goals help shape the dashboard and challenges."
            case .starterTransactions: "Add entries from the 1st of this month till today."
            }
        }
    }

    @Published var currentStep: Step = .profile
    @Published var fullName = ""
    @Published var ageText = ""
    @Published var birthDate = Calendar.current.date(byAdding: .year, value: -22, to: .now) ?? .now
    @Published var occupation: OccupationType = .student
    @Published var selectedPaymentMethods: Set<MoneyAccountType> = [.upi]
    @Published var stocksText = ""
    @Published var mutualFundsText = ""
    @Published var sipText = ""
    @Published var currencyCode: String = "INR"
    @Published var goalEntries: [String] = ["Travel", "PS5", ""]
    @Published var starterTransactions: [OnboardingDraftTransaction] = [OnboardingDraftTransaction()]

    var canMoveForward: Bool {
        switch currentStep {
        case .profile:
            return !fullName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
                Int(ageText) != nil
        case .moneySetup:
            return !selectedPaymentMethods.isEmpty
        case .goals:
            return true
        case .starterTransactions:
            return !validatedTransactions.isEmpty
        }
    }

    var progress: Double {
        Double(currentStep.rawValue + 1) / Double(Step.allCases.count)
    }

    var monthStart: Date {
        Calendar.current.date(from: Calendar.current.dateComponents([.year, .month], from: .now)) ?? .now
    }

    func next() {
        guard let nextStep = Step(rawValue: currentStep.rawValue + 1) else { return }
        currentStep = nextStep
    }

    func previous() {
        guard let previousStep = Step(rawValue: currentStep.rawValue - 1) else { return }
        currentStep = previousStep
    }

    func togglePaymentMethod(_ method: MoneyAccountType) {
        if selectedPaymentMethods.contains(method) {
            selectedPaymentMethods.remove(method)
        } else {
            selectedPaymentMethods.insert(method)
        }
    }

    func addGoalField() {
        goalEntries.append("")
    }

    func addStarterTransaction() {
        starterTransactions.append(OnboardingDraftTransaction(date: .now))
    }

    func removeStarterTransaction(id: UUID) {
        guard starterTransactions.count > 1 else { return }
        starterTransactions.removeAll { $0.id == id }
    }

    var builtProfile: UserProfile {
        UserProfile(
            name: fullName.trimmingCharacters(in: .whitespacesAndNewlines),
            age: Int(ageText) ?? 0,
            birthDate: birthDate,
            occupation: occupation
        )
    }

    var builtHoldings: [AssetHolding] {
        [
            makeHolding(.stocks, amountText: stocksText),
            makeHolding(.mutualFunds, amountText: mutualFundsText),
            makeHolding(.sip, amountText: sipText)
        ].compactMap { $0 }
    }

    var validatedTransactions: [Transaction] {
        starterTransactions.compactMap { draft in
            guard
                let amount = Double(draft.amountText),
                amount > 0,
                !draft.merchant.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            else {
                return nil
            }
            return Transaction(
                id: draft.id,
                amount: amount,
                type: draft.type,
                category: draft.category,
                accountType: draft.accountType,
                date: min(max(draft.date, monthStart), .now),
                note: draft.note.isEmpty ? "Onboarding entry" : draft.note,
                merchant: draft.merchant
            )
        }
    }

    private func makeHolding(_ category: AssetCategory, amountText: String) -> AssetHolding? {
        guard let amount = Double(amountText), amount > 0 else { return nil }
        return AssetHolding(id: UUID(), category: category, amount: amount)
    }
}
