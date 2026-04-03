import Combine
import Foundation
import SwiftUI

final class GoalsViewModel: ObservableObject {

    @Published private(set) var activeGoals: [Goal] = []
    @Published private(set) var investmentSplit: [InvestmentSplitItem] = []
    @Published private(set) var savingsLog: [Int: Double] = [:]
    @Published private(set) var savingsStreak: Int = 0

    let store: FinanceStore
    private var cancellables = Set<AnyCancellable>()

    init(store: FinanceStore) {
        self.store = store
        bind()
        reload()
    }
    
    func logSaving(amount: Double, goalIDs: [UUID]) {
        store.logSaving(amount: amount, goalIDs: goalIDs)
        reload()
    }

    func addGoal(title: String, targetAmount: Double) {
        store.addGoal(title: title, targetAmount: targetAmount)
        reload()
    }

    func deleteGoal(id: UUID) {
        store.deleteGoal(id: id)
        reload()
    }

    private func bind() {
        store.$goals
            .combineLatest(store.$savingsLog)
            .sink { [weak self] _, _ in self?.reload() }
            .store(in: &cancellables)
    }

    private func reload() {
        savingsLog    = store.savingsLog
        savingsStreak = store.savingsStreak
        activeGoals   = store.goals.filter { $0.kind == .savings }

        investmentSplit = store.holdings.map { holding in
            InvestmentSplitItem(
                title: holding.category.title,
                amount: holding.amount,
                tint: holdingTint(for: holding.category),
                icon: holdingIcon(for: holding.category)
            )
        }
    }

    private func holdingTint(for category: AssetCategory) -> Color {
        switch category {
        case .stocks:      return AppTheme.warning
        case .mutualFunds: return AppTheme.positive
        case .sip:         return AppTheme.accentSoft
        }
    }

    private func holdingIcon(for category: AssetCategory) -> String {
        switch category {
        case .stocks:      return "chart.bar.fill"
        case .mutualFunds: return "building.columns.fill"
        case .sip:         return "arrow.trianglehead.2.clockwise"
        }
    }
}

struct InvestmentSplitItem: Identifiable {
    let id = UUID()
    let title: String
    let amount: Double
    let tint: Color
    let icon: String
}
