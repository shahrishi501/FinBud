import Combine
import Foundation
import SwiftData

@MainActor
final class FinanceStore: ObservableObject {
    @Published private(set) var profile: UserProfile?
    @Published private(set) var holdings: [AssetHolding] = []
    @Published var transactions: [Transaction] = []
    @Published var goals: [Goal] = []
    @Published private(set) var paymentMethods: [MoneyAccountType] = []
    @Published private(set) var hasCompletedOnboarding = false
    @Published var currencyCode: String = UserDefaults.standard.string(forKey: "AppCurrencyCode") ?? "INR"
    @Published private(set) var savingsStreak: Int = 0
    @Published private(set) var savingsLog: [Int: Double] = [:]   // days-ago → amount

    private let context: ModelContext

    init(container: ModelContainer) {
        self.context = ModelContext(container)
        reload()
    }

    var totalIncome: Double {
        transactions.filter { $0.type == .income }.reduce(0) { $0 + $1.amount }
    }

    var totalExpenses: Double {
        transactions.filter { $0.type == .expense }.reduce(0) { $0 + $1.amount }
    }

    var balance: Double { totalIncome - totalExpenses }
    
    var currentMonthIncome: Double {
        let calendar = Calendar.current
        let comps = calendar.dateComponents([.year, .month], from: .now)
        guard let monthStart = calendar.date(from: comps) else { return 0 }
        return transactions
            .filter { $0.type == .income && $0.date >= monthStart }
            .reduce(0) { $0 + $1.amount }
    }

    var currentMonthExpenses: Double {
        let calendar = Calendar.current
        let comps = calendar.dateComponents([.year, .month], from: .now)
        guard let monthStart = calendar.date(from: comps) else { return 0 }
        return transactions
            .filter { $0.type == .expense && $0.date >= monthStart }
            .reduce(0) { $0 + $1.amount }
    }

    func income(for month: Date) -> Double {
        let (start, end) = monthRange(for: month)
        return transactions
            .filter { $0.type == .income && $0.date >= start && $0.date < end }
            .reduce(0) { $0 + $1.amount }
    }

    func expenses(for month: Date) -> Double {
        let (start, end) = monthRange(for: month)
        return transactions
            .filter { $0.type == .expense && $0.date >= start && $0.date < end }
            .reduce(0) { $0 + $1.amount }
    }
    
    func monthRange(for date: Date) -> (start: Date, end: Date) {
        let calendar = Calendar.current
        let comps = calendar.dateComponents([.year, .month], from: date)
        let start = calendar.date(from: comps) ?? date
        let end = calendar.date(byAdding: .month, value: 1, to: start) ?? date
        return (start, end)
    }

    // Returns all months that have at least one transaction, plus the current month
    var availableMonths: [Date] {
        let calendar = Calendar.current
        var monthSet = Set<DateComponents>()

        // Always include current month
        let nowComps = calendar.dateComponents([.year, .month], from: .now)
        monthSet.insert(nowComps)

        for txn in transactions {
            let comps = calendar.dateComponents([.year, .month], from: txn.date)
            monthSet.insert(comps)
        }

        return monthSet
            .compactMap { calendar.date(from: $0) }
            .sorted(by: >)  // newest first
    }

    func reload() {
        profile       = fetchProfile()
        holdings      = fetchHoldings()
        transactions  = fetchTransactions()
        let commits   = fetchCommits()
        goals         = fetchGoals(commits: commits)
        savingsLog    = buildSavingsLog(from: commits)
        savingsStreak = calcStreak(from: savingsLog)

        let state = fetchOrCreateState()
        hasCompletedOnboarding = state.hasCompletedOnboarding
        // Load currency from UserDefaults (AppStateEntity has no currencyCode field)
        currencyCode = UserDefaults.standard.string(forKey: "AppCurrencyCode") ?? currencyCode
        paymentMethods = state.paymentMethodsRaw
            .split(separator: ",")
            .compactMap { MoneyAccountType(rawValue: String($0)) }
        try? context.save()
    }

    func logSaving(amount: Double, goalIDs: [UUID]) {
        let today = Calendar.current.startOfDay(for: .now)

        // One general commit for the streak grid
        let general = SavingsCommitEntity(date: today, amount: amount, goalID: nil)
        context.insert(general)

        // One commit per goal so each goal tracks its own log
        for gid in goalIDs {
            let goalCommit = SavingsCommitEntity(date: today, amount: amount, goalID: gid)
            context.insert(goalCommit)

            // Update currentAmount on the GoalEntity directly
            let descriptor = FetchDescriptor<GoalEntity>(predicate: #Predicate { $0.id == gid })
            if let entity = try? context.fetch(descriptor).first {
                entity.currentAmount = min(entity.targetAmount, entity.currentAmount + amount)
            }
        }

        try? context.save()
        reload()
    }

    func addGoal(title: String, targetAmount: Double) {
        let cleaned = title.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !cleaned.isEmpty, targetAmount > 0 else { return }
        context.insert(
            GoalEntity(
                title: cleaned,
                subtitle: "Saving toward \(cleaned)",
                currentAmount: 0,
                targetAmount: targetAmount,
                icon: suggestedIcon(for: cleaned),
                tintHex: "#B88CFF",
                kindRaw: GoalKind.savings.rawValue
            )
        )
        try? context.save()
        reload()
    }

    func deleteGoal(id: UUID) {
        let descriptor = FetchDescriptor<GoalEntity>(predicate: #Predicate { $0.id == id })
        if let entity = try? context.fetch(descriptor).first {
            context.delete(entity)
            try? context.save()
            reload()
        }
    }

    func completeOnboarding(
        profile: UserProfile,
        paymentMethods: [MoneyAccountType],
        holdings: [AssetHolding],
        goalTitles: [String],
        starterTransactions: [Transaction],
        currencyCode: String
    ) {
        replaceExisting(of: UserProfileEntity.self)
        replaceExisting(of: AssetHoldingEntity.self)
        replaceExisting(of: GoalEntity.self)
        replaceExisting(of: TransactionEntity.self)

        context.insert(UserProfileEntity(
            name: profile.name, age: profile.age,
            birthDate: profile.birthDate, occupationRaw: profile.occupation.rawValue
        ))

        holdings.forEach {
            context.insert(AssetHoldingEntity(id: $0.id, categoryRaw: $0.category.rawValue, amount: $0.amount))
        }

        goalTitles
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
            .forEach { title in
                context.insert(GoalEntity(
                    title: title,
                    subtitle: "Saving toward \(title)",
                    currentAmount: 0,
                    targetAmount: suggestedTarget(for: title),
                    icon: suggestedIcon(for: title),
                    tintHex: "#B88CFF",
                    kindRaw: GoalKind.savings.rawValue
                ))
            }

        starterTransactions.forEach { context.insert(makeTransactionEntity(from: $0)) }

        let state = fetchOrCreateState()
        state.hasCompletedOnboarding = true
        state.paymentMethodsRaw = paymentMethods.map(\.rawValue).joined(separator: ",")
        self.currencyCode = currencyCode
        UserDefaults.standard.set(currencyCode, forKey: "AppCurrencyCode")

        try? context.save()
        reload()
    }

    // Logout
    func logout() {
        replaceExisting(of: UserProfileEntity.self)
        replaceExisting(of: AssetHoldingEntity.self)
        replaceExisting(of: GoalEntity.self)
        replaceExisting(of: TransactionEntity.self)
        replaceExisting(of: SavingsCommitEntity.self)
        replaceExisting(of: AppStateEntity.self)
        try? context.save()
        reload()
    }

    // Transactions

    func add(transaction: Transaction) {
        context.insert(makeTransactionEntity(from: transaction))
        try? context.save()
        reload()
    }

    func update(transaction: Transaction) {
        let tid = transaction.id
        let descriptor = FetchDescriptor<TransactionEntity>(predicate: #Predicate { $0.id == tid })
        if let existing = try? context.fetch(descriptor).first {
            existing.amount       = transaction.amount
            existing.typeRaw      = transaction.type.rawValue
            existing.categoryRaw  = transaction.category.rawValue
            existing.accountTypeRaw = transaction.accountType.rawValue
            existing.date         = transaction.date
            existing.note         = transaction.note
            existing.merchant     = transaction.merchant
            try? context.save()
            reload()
        }
    }

    func delete(transactionID: UUID) {
        let id = transactionID
        let descriptor = FetchDescriptor<TransactionEntity>(predicate: #Predicate { $0.id == id })
        if let existing = try? context.fetch(descriptor).first {
            context.delete(existing)
            try? context.save()
            reload()
        }
    }

    private func fetchCommits() -> [SavingsCommitEntity] {
        (try? context.fetch(FetchDescriptor<SavingsCommitEntity>())) ?? []
    }

    private func buildSavingsLog(from commits: [SavingsCommitEntity]) -> [Int: Double] {
        let today = Calendar.current.startOfDay(for: .now)
        var log: [Int: Double] = [:]
        // Only general commits (goalID == nil) feed the streak grid
        for commit in commits where commit.goalID == nil {
            let days = Calendar.current.dateComponents([.day], from: commit.date, to: today).day ?? 0
            if days >= 0 && days < 90 {
                log[days, default: 0] += commit.amount
            }
        }
        return log
    }

    private func calcStreak(from log: [Int: Double]) -> Int {
        var streak = 0
        for daysAgo in 0... {
            if (log[daysAgo] ?? 0) > 0 { streak += 1 } else { break }
        }
        return streak
    }

    private func fetchGoals(commits: [SavingsCommitEntity]) -> [Goal] {
        let today = Calendar.current.startOfDay(for: .now)
        let descriptor = FetchDescriptor<GoalEntity>()
        let items = (try? context.fetch(descriptor)) ?? []
        return items.map { entity in
            // Build per-goal commit log from goal-specific commits
            var commitLog: [Int: Double] = [:]
            for commit in commits where commit.goalID == entity.id {
                let days = Calendar.current.dateComponents([.day], from: commit.date, to: today).day ?? 0
                if days >= 0 && days < 90 {
                    commitLog[days, default: 0] += commit.amount
                }
            }
            return Goal(
                id: entity.id,
                title: entity.title,
                subtitle: entity.subtitle,
                currentAmount: entity.currentAmount,
                targetAmount: entity.targetAmount,
                icon: entity.icon,
                tintHex: entity.tintHex,
                kind: GoalKind(rawValue: entity.kindRaw) ?? .savings,
                commitLog: commitLog
            )
        }
    }

    private func fetchProfile() -> UserProfile? {
        guard let e = try? context.fetch(FetchDescriptor<UserProfileEntity>()).first else { return nil }
        return UserProfile(name: e.name, age: e.age, birthDate: e.birthDate,
                           occupation: OccupationType(rawValue: e.occupationRaw) ?? .other)
    }

    private func fetchHoldings() -> [AssetHolding] {
        ((try? context.fetch(FetchDescriptor<AssetHoldingEntity>())) ?? []).map {
            AssetHolding(id: $0.id, category: AssetCategory(rawValue: $0.categoryRaw) ?? .stocks, amount: $0.amount)
        }
    }

    private func fetchTransactions() -> [Transaction] {
        let descriptor = FetchDescriptor<TransactionEntity>(sortBy: [SortDescriptor(\.date, order: .reverse)])
        return ((try? context.fetch(descriptor)) ?? []).map {
            Transaction(id: $0.id, amount: $0.amount,
                        type: TransactionType(rawValue: $0.typeRaw) ?? .expense,
                        category: FinanceCategory(rawValue: $0.categoryRaw) ?? .others,
                        accountType: MoneyAccountType(rawValue: $0.accountTypeRaw) ?? .upi,
                        date: $0.date, note: $0.note, merchant: $0.merchant)
        }
    }

    private func fetchOrCreateState() -> AppStateEntity {
        if let e = try? context.fetch(FetchDescriptor<AppStateEntity>()).first { return e }
        let e = AppStateEntity(); context.insert(e); return e
    }

    private func makeTransactionEntity(from t: Transaction) -> TransactionEntity {
        TransactionEntity(id: t.id, amount: t.amount, typeRaw: t.type.rawValue,
                          categoryRaw: t.category.rawValue, accountTypeRaw: t.accountType.rawValue,
                          date: t.date, note: t.note, merchant: t.merchant)
    }

    private func replaceExisting<T: PersistentModel>(of type: T.Type) {
        ((try? context.fetch(FetchDescriptor<T>())) ?? []).forEach { context.delete($0) }
    }

    private func suggestedTarget(for title: String) -> Double {
        let v = title.lowercased()
        if v.contains("travel") { return 120_000 }
        if v.contains("ps5") || v.contains("playstation") { return 55_000 }
        if v.contains("phone") { return 80_000 }
        return 50_000
    }

    private func suggestedIcon(for title: String) -> String {
        let v = title.lowercased()
        if v.contains("travel") { return "airplane" }
        if v.contains("ps5") || v.contains("playstation") { return "gamecontroller" }
        if v.contains("phone") { return "iphone" }
        return "target"
    }
}

