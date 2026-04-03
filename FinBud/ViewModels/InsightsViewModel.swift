import Charts
import Combine
import Foundation
import SwiftUI

final class InsightsViewModel: ObservableObject {
    @Published private(set) var headlineMetrics: [InsightMetric] = []
    @Published private(set) var categoryBreakdown: [AllocationBucket] = []
    @Published private(set) var monthlyTrend: [TrendPoint] = []
    @Published private(set) var quickInsights: [InsightCard] = []
    @Published var aiNarrative = "Generating your on-device money brief..."
    @Published var isGenerating = false

    let store: FinanceStore
    private let aiService: AIInsightsService
    private var cancellables = Set<AnyCancellable>()

    init(store: FinanceStore, aiService: AIInsightsService) {
        self.store = store
        self.aiService = aiService
        bind()
        reload()
    }

    @MainActor
    func generateAIInsight() async {
        isGenerating = true
        let context = buildContext()
        aiNarrative = await aiService.generateInsight(context: context)
        isGenerating = false
    }

    private func bind() {
        store.$transactions
            .sink { [weak self] _ in
                self?.reload()
            }
            .store(in: &cancellables)
    }

    private func reload() {
        let expenseTransactions = store.transactions.filter { $0.type == .expense }
        let grouped = Dictionary(grouping: expenseTransactions, by: \.category).mapValues { items in
            items.reduce(0) { $0 + $1.amount }
        }
        let sortedCategories = grouped.sorted { $0.value > $1.value }
        let topCategory = sortedCategories.first

        let currentWeek = weeklyExpense(weekOffset: 0)
        let lastWeek = weeklyExpense(weekOffset: -1)
        let delta = lastWeek == 0 ? 0 : ((currentWeek - lastWeek) / lastWeek) * 100
        let savingsRate = max(0, (store.totalIncome - store.totalExpenses) / max(store.totalIncome, 1)) * 100

        headlineMetrics = [
            InsightMetric(title: "Highest spend", value: topCategory?.key.title ?? "None", detail: topCategory?.value.inrCurrency ?? "₹0", icon: "flame.fill", tint: .pink),
            InsightMetric(title: "This vs last week", value: delta.signedPercent, detail: currentWeek.inrCurrency, icon: "arrow.left.arrow.right", tint: AppTheme.warning),
            InsightMetric(title: "Savings rate", value: String(format: "%.0f%%", savingsRate), detail: store.balance.inrCurrency, icon: "sparkles", tint: AppTheme.positive),
            InsightMetric(title: "Frequent type", value: expenseTransactions.count > store.transactions.filter { $0.type == .income }.count ? "Expense" : "Income", detail: "\(expenseTransactions.count) entries", icon: "clock.arrow.circlepath", tint: AppTheme.accentSoft)
        ]

        categoryBreakdown = sortedCategories.prefix(4).map { category, amount in
            AllocationBucket(title: category.title, amount: amount, tint: category.color)
        }

        let calendar = Calendar.current
        monthlyTrend = (0..<6).compactMap { offset in
            guard let date = calendar.date(byAdding: .month, value: -(5 - offset), to: .now) else { return nil }
            let amount = expenseTransactions
                .filter { calendar.isDate($0.date, equalTo: date, toGranularity: .month) }
                .reduce(0) { $0 + $1.amount }
            return TrendPoint(label: date.formatted(.month).prefix(3).uppercased(), value: amount, date: date)
        }

        quickInsights = [
            InsightCard(title: "Spending Pulse", body: "Food and shopping together now form the biggest variable expense cluster.", icon: "waveform.path.ecg", tint: .pink),
            InsightCard(title: "Savings Suggestion", body: "Move one weekend dining budget into your travel goal to hit the next milestone faster.", icon: "leaf.fill", tint: AppTheme.positive)
        ]
    }

    private func weeklyExpense(weekOffset: Int) -> Double {
        let calendar = Calendar.current
        guard let weekDate = calendar.date(byAdding: .weekOfYear, value: weekOffset, to: .now) else { return 0 }
        return store.transactions
            .filter { $0.type == .expense && calendar.isDate($0.date, equalTo: weekDate, toGranularity: .weekOfYear) }
            .reduce(0) { $0 + $1.amount }
    }

    private func buildContext() -> AISummaryContext {
        let topCategory = categoryBreakdown.first?.title ?? "General"
        let currentWeek = weeklyExpense(weekOffset: 0)
        let lastWeek = weeklyExpense(weekOffset: -1)
        let delta = lastWeek == 0 ? 0 : ((currentWeek - lastWeek) / lastWeek) * 100
        let savingsRate = max(0, (store.totalIncome - store.totalExpenses) / max(store.totalIncome, 1)) * 100
        return AISummaryContext(
            balance: store.balance,
            income: store.totalIncome,
            expenses: store.totalExpenses,
            topCategory: topCategory,
            weekDelta: delta,
            savingsRate: savingsRate
        )
    }
}
