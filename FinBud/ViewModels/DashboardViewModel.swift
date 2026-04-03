import Combine
import Foundation
import SwiftUI

final class DashboardViewModel: ObservableObject {
    @Published private(set) var profileName: String = "The Liquid Ledger"
    @Published private(set) var balance: Double = 0
    @Published private(set) var income: Double = 0
    @Published private(set) var expenses: Double = 0
    @Published private(set) var savingsProgress: Double = 0
    @Published private(set) var allocation: [AllocationBucket] = []
    @Published private(set) var weeklyTrend: [TrendPoint] = []
    @Published private(set) var monthlyTrend: [TrendPoint] = []
    @Published private(set) var portfolioCards: [Goal] = []
    @Published private(set) var categoryBreakdown: [AllocationBucket] = []

    // Month Selection
    @Published var selectedMonth: Date = {
        let c = Calendar.current
        return c.date(from: c.dateComponents([.year, .month], from: .now)) ?? .now
    }()

    var availableMonths: [Date] { store.availableMonths }

    var selectedMonthLabel: String {
        selectedMonth.formatted(.dateTime.month(.abbreviated).year())
    }

    let store: FinanceStore
    private var cancellables = Set<AnyCancellable>()

    init(store: FinanceStore) {
        self.store = store
        bind()
        reload()
    }

    private func bind() {
        store.$transactions
            .combineLatest(store.$goals, store.$holdings, store.$profile)
            .sink { [weak self] _, _, _, _ in
                guard let self else { return }
                self.reloadWith(month: self.selectedMonth)
                self.reloadCharts()
            }
            .store(in: &cancellables)

        // React to month changes, pass the new value directly
        $selectedMonth
            .dropFirst()
            .sink { [weak self] newMonth in
                self?.reloadWith(month: newMonth)
            }
            .store(in: &cancellables)
    }

    private func reload() {
        reloadWith(month: selectedMonth)
        reloadCharts()
    }
    
    private func reloadCharts() {
        let calendar = Calendar.current

        weeklyTrend = (0..<7).compactMap { offset in
            guard let date = calendar.date(byAdding: .day, value: -(6 - offset), to: .now) else { return nil }
            let dayExpense = store.transactions
                .filter { $0.type == .expense && calendar.isDate($0.date, inSameDayAs: date) }
                .reduce(0) { $0 + $1.amount }
            return TrendPoint(label: date.formatted(.weekday), value: dayExpense, date: date)
        }

        let thirtyDaysAgo = calendar.date(byAdding: .day, value: -29, to: .now) ?? .now
        let monthExpenses = store.transactions
            .filter { $0.type == .expense && $0.date >= thirtyDaysAgo }

        monthlyTrend = (0..<4).compactMap { weekIndex in
            guard let weekStart = calendar.date(byAdding: .day, value: -(3 - weekIndex) * 7, to: .now),
                  let weekEnd   = calendar.date(byAdding: .day, value: 7, to: weekStart)
            else { return nil }
            let total = monthExpenses
                .filter { $0.date >= weekStart && $0.date < weekEnd }
                .reduce(0) { $0 + $1.amount }
            return TrendPoint(label: "W\(weekIndex + 1)", value: total, date: weekStart)
        }
    }

    private func reloadWith(month: Date) {
        profileName = store.profile?.name ?? "The Liquid Ledger"

        balance = store.balance

        income = store.income(for: month)
        expenses = store.expenses(for: month)

        savingsProgress = max(0, min(1, (income - expenses) / max(income, 1)))

        allocation = store.holdings.map {
            AllocationBucket(title: $0.category.title, amount: $0.amount, tint: $0.category.color)
        }
        
        let (monthStart, monthEnd) = store.monthRange(for: month)
        let monthTxns = store.transactions
            .filter { $0.type == .expense && $0.date >= monthStart && $0.date < monthEnd }

        var catTotals: [FinanceCategory: Double] = [:]
        for txn in monthTxns {
            catTotals[txn.category, default: 0] += txn.amount
        }

        categoryBreakdown = catTotals
            .sorted { $0.value > $1.value }
            .map { AllocationBucket(title: $0.key.title, amount: $0.value, tint: $0.key.color) }

        portfolioCards = store.goals.filter { $0.kind != .challenge }.prefix(3).map { $0 }
    }
}
